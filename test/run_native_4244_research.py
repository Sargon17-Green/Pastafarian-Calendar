#!/usr/bin/env python3
"""Bounded two-process Chapel research attempt; never claims Stage6 acceptance.

Unrank is required to finish before reverse rank starts. Native stdout/stderr,
OS time/RSS, process exit, source and executable SHA are retained. A timeout or
partial result is INCONCLUSIVE, never PASS. Independent dense/FIFO validation
is invoked only after both complete phases and exact witness identification.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time

import weaving_native_median_evidence_gate as oracle

LIMIT_SECONDS = 180.0
LIMIT_RSS_KIB = 524288
DEPTHS = oracle.CHECKPOINTS
sys.set_int_max_str_digits(10000)


def read_rss_kib(pid):
    try:
        for line in Path(f"/proc/{pid}/status").read_text().splitlines():
            if line.startswith("VmRSS:"):
                return int(line.split()[1])
    except (FileNotFoundError, ProcessLookupError):
        pass
    return 0


def direct_children(pid):
    try:
        raw = Path(f"/proc/{pid}/task/{pid}/children").read_text().split()
        return [int(n) for n in raw]
    except (FileNotFoundError, ProcessLookupError):
        return []


def run_native(binary, outdir, direction, word=None, rank_delta=0, rank0=None):
    name = direction
    stdout_path = outdir / (name + ".stdout")
    stderr_path = outdir / (name + ".stderr")
    metrics_path = outdir / (name + ".os-time")
    argv = [str(binary), "--runMode=" + direction]
    if direction == "unrank" and rank_delta:
        argv.append("--rankDelta=" + str(rank_delta))
    if direction in ("selected-unrank", "selected-rank"):
        if rank0 is None:
            raise ValueError("selected Native mode requires rank0")
        argv.append("--rank0Input=" + str(rank0))
    if direction in ("rank", "selected-rank"):
        if word is None:
            raise ValueError("Native rank mode requires a word")
        argv.append("--rankInput=" + ",".join(map(str, word)))
    command = ["/usr/bin/time", "-f", "OS_WALL_SECONDS=%e\\nOS_MAX_RSS_KIB=%M\\nOS_EXIT=%x",
               "-o", str(metrics_path), *argv]
    (outdir / (name + ".command.json")).write_text(
        json.dumps({"argv": argv,
                "witness_sha256": oracle.digest_word(word) if direction in ("rank", "selected-rank") else None,
                "rank0": str(rank0) if rank0 is not None else None,
                "source": "Native Chapel binary"}, ensure_ascii=False) + "\n")
    begin = time.monotonic()
    reason = None
    observed_peak_rss_kib = 0
    observed_depths = set()
    progress_path = outdir / (name + ".progress.jsonl")
    progress_path.write_text("", encoding="utf-8")
    next_progress_sample = begin

    def observe_partial_stdout(elapsed_seconds, rss_kib):
        """Diagnostic-only observation; no partial transcript can grant PASS."""
        try:
            payload = stdout_path.read_bytes()
        except FileNotFoundError:
            return
        checkpoint_key = (b"NATIVE_SELECTED_CHECKPOINT"
                          if direction.startswith("selected-")
                          else b"NATIVE_MEDIAN_CHECKPOINT")
        checkpoint_pattern = (rb"(?m)^" + re.escape(checkpoint_key) +
                              rb"=([1-9][0-9]*);[0-9]+\n")
        for match in re.finditer(checkpoint_pattern, payload):
            depth = int(match.group(1))
            if depth not in DEPTHS or depth in observed_depths:
                continue
            observed_depths.add(depth)
            with progress_path.open("a", encoding="utf-8") as progress:
                progress.write(json.dumps({
                    "checkpoint_depth": depth,
                    "first_observed_wall_seconds": round(elapsed_seconds, 3),
                    "sampled_rss_kib": rss_kib or None,
                    "acceptance": "DIAGNOSTIC_ONLY",
                }, sort_keys=True) + "\n")

    with stdout_path.open("wb") as stdout, stderr_path.open("wb") as stderr:
        process = subprocess.Popen(command, stdout=stdout, stderr=stderr,
                                   start_new_session=True)
        while process.poll() is None:
            elapsed = time.monotonic() - begin
            rss = max((read_rss_kib(c) for c in direct_children(process.pid)),
                      default=0)
            observed_peak_rss_kib = max(observed_peak_rss_kib, rss)
            now = time.monotonic()
            if now >= next_progress_sample:
                observe_partial_stdout(elapsed, rss)
                next_progress_sample = now + 1.0
            if rss > LIMIT_RSS_KIB:
                reason = "INCONCLUSIVE_RSS_LIMIT"
            elif elapsed >= LIMIT_SECONDS:
                reason = "INCONCLUSIVE_TIMEOUT_180S"
            if reason:
                os.killpg(process.pid, signal.SIGKILL)
                break
            time.sleep(0.025)
        exit_code = process.wait()
    wall = time.monotonic() - begin
    observe_partial_stdout(wall, observed_peak_rss_kib)
    metrics = {}
    if metrics_path.exists():
        for line in metrics_path.read_text(errors="replace").splitlines():
            if "=" in line:
                key, value = line.split("=", 1)
                metrics[key] = value
    os_peak_rss_kib = int(metrics.get("OS_MAX_RSS_KIB", "0"))
    measured_peak_rss_kib = max(observed_peak_rss_kib, os_peak_rss_kib) or None
    if not reason and (wall > LIMIT_SECONDS or
                       (measured_peak_rss_kib is not None and
                        measured_peak_rss_kib > LIMIT_RSS_KIB)):
        reason = "INCONCLUSIVE_RESOURCE_LIMIT"
    if not reason and exit_code != 0:
        reason = "NONZERO_NATIVE_EXIT"
    outcome = {"direction": direction, "exit_code": exit_code,
               "wall_seconds": round(wall, 6),
               "peak_rss_kib": measured_peak_rss_kib,
               "rss_source": ("proc_sample_and_os_time" if os_peak_rss_kib and
                              observed_peak_rss_kib else
                              "os_time" if os_peak_rss_kib else
                              "proc_sample" if observed_peak_rss_kib else
                              "unavailable"),
               "last_observed_checkpoint": max(observed_depths, default=0),
               "observed_checkpoints": sorted(observed_depths),
               "status": reason or "COMPLETE", "pid": process.pid}
    (outdir / (name + ".os-result.json")).write_text(
        json.dumps(outcome, sort_keys=True) + "\n")
    return outcome, stdout_path


def parse_trace(path, direction):
    raw = path.read_bytes()
    if not raw.endswith(b"\n") or b"\r" in raw or not raw.isascii():
        raise ValueError("Missing canonical Native stdout")
    lines = raw.decode("ascii").splitlines()
    def single(key):
        values = [line[len(key):] for line in lines if line.startswith(key)]
        if len(values) != 1:
            raise ValueError("missing or repeated " + key)
        return values[0]
    if single("NATIVE_MEDIAN_COMPLETE=") != "1":
        raise ValueError("no complete marker")
    root = int(single("NATIVE_MEDIAN_ROOT="))
    wordstr = single("NATIVE_MEDIAN_WORD=")
    if not re.fullmatch(r"[1-9][0-9]*(,[1-9][0-9]*)*", wordstr):
        raise ValueError("invalid word serialization")
    word = tuple(int(x) for x in wordstr.split(","))
    if len(word) != 4244 or oracle.digest_word(word) != oracle.WITNESS_SHA256:
        raise ValueError("complete witness identity failed")
    oracle.verify_fifo_word(oracle.MONTH_LENGTHS,word)
    entries = []
    for line in lines:
        if line.startswith("NATIVE_MEDIAN_CHECKPOINT="):
            d, count = line.split("=",1)[1].split(";",1)
            d = int(d)
            if not re.fullmatch(r"0|[1-9][0-9]*",count):
                raise ValueError("noncanonical count")
            entries.append({"depth":d, "prefix_sha256":oracle.digest_word(word[:d]),
                            "count":count})
    if tuple(x["depth"] for x in entries) != DEPTHS:
        raise ValueError("missing checkpoint(s)")
    digest = hashlib.sha256(
        root.to_bytes((root.bit_length()+7)//8, "big")).hexdigest()
    if root.bit_length() != 22470 or digest != oracle.ROOT_SHA256:
        raise ValueError("root fingerprint mismatch")
    median = root // 2
    if direction == "unrank":
        if single("NATIVE_MEDIAN_RESIDUAL=") != "0":
            raise ValueError("nonzero residual")
    else:
        if int(single("NATIVE_MEDIAN_RESULT_RANK=")) != median:
            raise ValueError("reverse rank mismatch")
    return root, word, entries


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--binary", type=Path, required=True)
    p.add_argument("--source-sha", required=True)
    p.add_argument("--outdir", type=Path, required=True)
    args = p.parse_args()
    args.outdir.mkdir(parents=True,exist_ok=True)
    binary = args.binary.resolve()
    actual = subprocess.check_output(["git","rev-parse","HEAD"],text=True).strip()
    if actual != args.source_sha or not re.fullmatch(r"[0-9a-f]{40}",actual):
        raise SystemExit("source SHA mismatch")
    version = subprocess.check_output(["chpl","--version"],text=True).splitlines()[0]
    if "2.10.0" not in version:
        raise SystemExit("unexpected Chapel version: "+version)
    digest = hashlib.sha256(binary.read_bytes()).hexdigest()
    provenance = {"source_sha":actual, "binary_sha256":digest,
                  "chapel_version":version,
                  "ubuntu":Path("/etc/os-release").read_text()}
    (args.outdir / "provenance.json").write_text(
        json.dumps(provenance,ensure_ascii=False,sort_keys=True)+"\n")
    records = {}
    for direction in ("unrank","rank"):
        if direction == "rank" and "unrank" not in records:
            raise AssertionError("rank cannot run without complete unrank")
        preceding_word = records["unrank"]["word"] if direction == "rank" else None
        result, path = run_native(binary,args.outdir,direction,preceding_word)
        if result["status"] != "COMPLETE":
            print("NATIVE_MEDIAN_4244_"+direction.upper()+"="+result["status"])
            print("NATIVE_MEDIAN_4244_RESULT=NOT_ACCEPTED")
            return 0 if result["status"].startswith("INCONCLUSIVE") else 1
        root, word, entries = parse_trace(path,direction)
        if direction == "unrank":
            (args.outdir/"median.word").write_text(
                ",".join(map(str,word))+"\n",encoding="ascii")
        record = {"schema":1, "source_sha":actual, "direction":direction,
                  "chapel_version":"2.10.0", "status":"COMPLETE",
                  "elapsed_seconds":result["wall_seconds"],
                  "peak_rss_kib":result["peak_rss_kib"],
                  "root_bits":root.bit_length(),"root_sha256":oracle.ROOT_SHA256,
                  "median_rank":str(root//2),
                  "residual":"0" if direction=="unrank" else None,
                  "result_rank":str(root//2) if direction=="rank" else None,
                  "witness_sha256":oracle.WITNESS_SHA256,
                  "checkpoints":entries,"stage6_acceptance":"NOT_CLAIMED"}
        (args.outdir/(direction+".json")).write_text(
            json.dumps(record,sort_keys=True)+"\n")
        records[direction] = {"record":record,"word":word}
        print("NATIVE_MEDIAN_4244_"+direction.upper()+"=COMPLETE")
    first=records["unrank"]; second=records["rank"]
    if first["word"] != second["word"]:
        raise AssertionError("different direction witnesses")
    checks=oracle.verify_pair(first["record"],second["record"],
          first["word"],actual,oracle.MONTH_LENGTHS,DEPTHS,root,
          oracle.ROOT_SHA256,oracle.WITNESS_SHA256)
    if checks != 24:
        raise AssertionError("independent dense checkpoint coverage")
    print("NATIVE_MEDIAN_4244_INDEPENDENT_CHECKS=24")
    print("NATIVE_MEDIAN_4244_RESULT=PASS_RESEARCH_ONLY")
    print("NATIVE_MEDIAN_STAGE6=NOT_CLAIMED")
    return 0


if __name__=="__main__":
    sys.exit(main())
