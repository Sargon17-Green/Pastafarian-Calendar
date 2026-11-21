#!/usr/bin/env python3
"""QA31CA independent archived-original / Native replay verifier.

Reads archived original bytes, not producer's fixtures or verification helpers.
--preflight proves only archived evidence integrity; --native-dir proves full
original replay and original p receipt. Never authorizes changed-run PASS.
"""
from __future__ import annotations
import argparse
import copy
import gzip
import hashlib
import io
import json
import zipfile
from pathlib import Path

PROJECT = "PC-BRANCH-BEFUNGE98-KYRGYZ"
SOURCE_BLOB = "560d6aa5807a7f766213a33835cce85eab0fa40c"
ORIGINAL_ZIP_SHA256 = "5732cdf515a81c37982c8e79e5c4368e11e7a3b4e35fb1eae82bed2e17e24553"
LABEL = "pair_30_30"
RAW = b"1 0 0 0" + bytes((48, 48))
EXPECTED_IP = [96, 480]
EXPECTED_TARGET = [1500, 1860]
TARGET_TICK = 17817
TRACE_NAME = "qa31g_pair_30_30.jsonl.gz"
CAP = 25000

def need(test: bool, why: str):
    if not test:
        raise AssertionError(why)

def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def blob(data: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()

def integer_pair(value):
    return type(value) is list and len(value) == 2 and all(type(x) is int for x in value)

def signed(archive: Path, source: Path):
    need(blob(source.read_bytes()) == SOURCE_BLOB, "source Git blob")
    zipbytes = archive.read_bytes()
    need(sha(zipbytes) == ORIGINAL_ZIP_SHA256, "original immutable ZIP SHA256")
    with zipfile.ZipFile(io.BytesIO(zipbytes)) as z:
        need(z.testzip() is None, "original ZIP CRC")
        need("qa31v_receipt.json" in z.namelist() and TRACE_NAME in z.namelist(),
             "original ZIP required members")
        m = json.loads(z.read("qa31v_receipt.json"))
        need(m.get("schema") == "qa31v-original-native-two-byte-v1"
             and m.get("source_blob") == SOURCE_BLOB and m.get("shard") == 0
             and m.get("source_modified") is False
             and m.get("ip_relocated") is False
             and m.get("stage1_pass") is False
             and m.get("case_cap_steps") == CAP
             and m.get("completed_native_cases") == 25
             and len(m.get("cases", [])) == 25, "original shard manifest")
        found = [c for c in m["cases"] if c.get("label") == LABEL]
        need(len(found) == 1, "original exact case cardinality")
        c = found[0]
        packed = z.read(TRACE_NAME)
        need(c.get("raw_hex") == RAW.hex() and c.get("raw_sha256") == sha(RAW)
             and c.get("trace") == TRACE_NAME
             and c.get("trace_sha256") == sha(packed)
             and c.get("status") == "HALT" and c.get("error") is None
             and type(c.get("steps")) is int and TARGET_TICK < c["steps"] <= CAP,
             "signed exact raw input/trace/termination")
        rows = [json.loads(line) for line in gzip.decompress(packed).splitlines()]
        need(len(rows) == c["steps"], "original physical STEP row count")
        for n, row in enumerate(rows, 1):
            need(type(row) is dict and row.get("t") == n
                 and integer_pair(row.get("ip"))
                 and integer_pair(row.get("delta"))
                 and type(row.get("op")) is int
                 and type(row.get("pre")) is list
                 and type(row.get("post")) is list
                 and type(row.get("reads")) is list, "original STEP shape/order")
            if n < len(rows):
                need(row.get("next") == rows[n]["ip"]
                     and row.get("next_delta") == rows[n]["delta"],
                     "original physical next-state continuity")
        event = rows[TARGET_TICK - 1]
        need(event["ip"] == EXPECTED_IP and event["op"] == 112
             and event["string"] is False and len(event["pre"]) >= 3
             and event["pre"][-3] == 62, "signed writer anchor")
        return c, rows, packed

def original_witness(report, case, rows):
    need(type(report) is dict, "native receipt object")
    need(report.get("project_id") == PROJECT
         and report.get("qa") == "QA31CA"
         and report.get("case") == LABEL
         and report.get("source_git_blob_sha1") == SOURCE_BLOB
         and report.get("tick") == TARGET_TICK
         and report.get("ip") == EXPECTED_IP
         and report.get("op") == 112
         and report.get("string_mode") is False
         and report.get("ip_count") == 1
         and report.get("stack_depth") == 1
         and report.get("queue_mode") is False
         and report.get("invert_mode") is False
         and report.get("native_execution_observed") is True
         and report.get("changed_native_run_executed") is False
         and report.get("stage1_accepted") is False,
         "Native provenance / exact event / no-change flags")
    so, target = report.get("storage_offset"), report.get("effective_target")
    need(integer_pair(so) and target == EXPECTED_TARGET, "Native SO/target type")
    stack, post = report.get("pre_toss"), report.get("post_toss")
    need(type(stack) is list and len(stack) >= 3
         and all(type(n) is int for n in stack)
         and type(post) is list and post == stack[:-3],
         "Native TOSS and three-operand p consumption")
    need([stack[-2] + so[0], stack[-1] + so[1]] == EXPECTED_TARGET
         and stack[-3] == 62
         and type(report.get("cell_before")) is int
         and report.get("cell_after") == 62, "physical FungeSpace write")
    e = rows[TARGET_TICK - 1]
    need(report.get("delta") == e["delta"]
         and stack == e["pre"] and post == e["post"],
         "signed original complete p stack/delta agreement")
    reads = [r for row in rows for r in row["reads"]]
    need(report.get("read_events") == reads
         and len(reads) == case["reads"]
         and report.get("output") == case["output"]
         and report.get("stdin_hex") == RAW.hex()
         and report.get("raw_sha256") == sha(RAW)
         and report.get("original_signed_trace_sha256") == case["trace_sha256"]
         and report.get("step_count") == case["steps"]
         and report.get("original_full_step_equality") is True,
         "raw/input/output/full-step receipts")
    return {"pre_toss_items": len(stack), "storage_offset": so,
            "cell_before": report["cell_before"], "cell_after": 62,
            "signed_step_count": len(rows), "signed_read_events": len(reads)}

def forgeries(report, case, rows):
    """Distinct detached modifications; same validator as real Native report."""
    edits = [
        ("project", "project_id", "other-project"),
        ("source", "source_git_blob_sha1", "0" * 40),
        ("case", "case", "pair_30_31"),
        ("tick", "tick", TARGET_TICK - 1),
        ("ip", "ip", [96, 481]),
        ("opcode", "op", 103),
        ("string", "string_mode", True),
        ("offset", "storage_offset", [1, 0]),
        ("address", "effective_target", [1501, 1860]),
        ("value", "pre_toss", report["pre_toss"][:-3] + [63] + report["pre_toss"][-2:]),
        ("post", "post_toss", report["post_toss"] + [99]),
        ("cell_before_type", "cell_before", "32"),
        ("cell_after", "cell_after", 118),
        ("read_events", "read_events", []),
        ("stdout", "output", ["forgery"]),
        ("step_count", "step_count", case["steps"] - 1),
        ("signed_hash", "original_signed_trace_sha256", "0" * 64),
        ("changed_claim", "changed_native_run_executed", True),
        ("stage_claim", "stage1_accepted", True),
    ]
    # The original case reads at least once. Reject accidental no-op hostiles.
    need(report.get("read_events") and report.get("output") != ["forgery"],
         "hostile controls must mutate meaningful fields")
    for name, key, value in edits:
        x = copy.deepcopy(report)
        x[key] = value
        try:
            original_witness(x, case, rows)
        except (AssertionError, KeyError, TypeError):
            continue
        raise AssertionError("detached hostile admitted: " + name)
    return len(edits)

def run(archive, source, native_dir, report_file):
    case, signed_rows, signed_packed = signed(archive, source)
    summary = {
        "project_id": PROJECT, "qa": "QA31CA",
        "original_zip_sha256": ORIGINAL_ZIP_SHA256,
        "source_git_blob_sha1": SOURCE_BLOB,
        "raw_hex": RAW.hex(), "raw_sha256": sha(RAW),
        "original_trace_sha256": sha(signed_packed),
        "original_steps_integrity_checked": len(signed_rows),
        "original_signed_control_archive": "PASS",
        "new_native_original_replay": "NOT_RUN",
        "new_native_changed_run": "NOT_RUN",
        "stage1_accepted": False
    }
    if native_dir is not None:
        receipt = json.loads((native_dir / "qa31ca_original_receipt.json").read_bytes())
        replay_packed = (native_dir / "qa31ca_original_replay.jsonl.gz").read_bytes()
        need(receipt.get("replay_trace_file") == "qa31ca_original_replay.jsonl.gz"
             and receipt.get("replay_trace_sha256") == sha(replay_packed),
             "Native original replay compressed SHA256")
        replay_rows = [json.loads(line) for line in gzip.decompress(replay_packed).splitlines()]
        need(len(replay_rows) == len(signed_rows), "Native original full STEP length")
        for i, (a, b) in enumerate(zip(replay_rows, signed_rows), 1):
            need(a == b, "Native original complete STEP mismatch at " + str(i))
        w = original_witness(receipt, case, signed_rows)
        count = forgeries(receipt, case, signed_rows)
        need(count >= 12, "insufficient independently rejected adversarial controls")
        summary.update({
            "new_native_original_replay": "FULL_SIGNED_MATCH_PASS",
            "replayed_steps_verified": len(replay_rows),
            "native_original_witness": w,
            "independent_detached_hostiles_rejected": count
        })
    if report_file is not None:
        report_file.parent.mkdir(parents=True, exist_ok=True)
        report_file.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")
    print(json.dumps(summary, sort_keys=True))
    return summary

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--archive", type=Path, required=True)
    p.add_argument("--source", type=Path, required=True)
    p.add_argument("--native-dir", type=Path)
    p.add_argument("--report", type=Path)
    args = p.parse_args()
    run(args.archive, args.source, args.native_dir, args.report)

if __name__ == "__main__":
    main()
