#!/usr/bin/env python3
"""Bounded Native 4244-symbol UNRANK/RANK at the actual Year 5000 selected rank.

Research-only: uses the existing Chapel adjoint kernel, a separate dense
prefix-count oracle, and a separate GMP reverse-rank implementation. It does
not establish Stage 6 acceptance or change normative calendar behavior.
"""
import argparse
import hashlib
import json
import math
import re
import subprocess
import sys
from pathlib import Path

sys.set_int_max_str_digits(10000)

import run_native_4244_research as native
import weaving_native_median_evidence_gate as oracle
from weaving_canonical_rank_bridge import M, choose_rank_direct, choose_rank_reference
from weaving_native_nonmedian_research import independently_rank

LENGTHS = oracle.MONTH_LENGTHS
DEPTHS = oracle.CHECKPOINTS
PROJECT_ID = "PC-BRANCH-CHAPEL-UKRAINIAN"
TIME_LIMIT_SECONDS = native.LIMIT_SECONDS
RSS_LIMIT_KIB = native.LIMIT_RSS_KIB


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def sha256_text(value):
    return hashlib.sha256(value.encode("ascii")).hexdigest()


def one_log_value(lines, key):
    prefix = key + "="
    values = [line[len(prefix):] for line in lines if line.startswith(prefix)]
    require(len(values) == 1, "missing or repeated bridge log field: " + key)
    return values[0]


def load_bridge(bridge_json, bridge_log, source_sha, root, root_digest):
    raw = Path(bridge_json).read_bytes()
    require(raw.endswith(b"\n") and b"\r" not in raw, "noncanonical bridge JSON")
    data = json.loads(raw.decode("utf-8"))
    require(type(data) is dict and data.get("schema") == 1, "bridge schema")
    require(data.get("project_id") == PROJECT_ID, "bridge project id")
    require(data.get("source_sha") == source_sha, "bridge source SHA")
    require("2.10.0" in str(data.get("chapel_version", "")), "bridge Chapel version")
    require(data.get("native_exit") == 0, "bridge Native selection did not exit 0")
    require(data.get("root_bits") == root.bit_length() == 22470, "bridge root bits")
    require(data.get("root_sha256") == root_digest == oracle.ROOT_SHA256,
            "bridge root SHA-256")
    require(data.get("proof") == "NORMATIVE_SELECTION_EQUALS_INDEPENDENT_ARITHMETIC",
            "bridge proof marker")
    elapsed = data.get("native_elapsed_seconds")
    require(type(elapsed) in (int, float) and math.isfinite(elapsed) and
            0 < elapsed <= 90.0, "bridge Native 90-second budget")
    metrics = {}
    for line in str(data.get("native_time_output", "")).splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            metrics[key] = value
    require(float(metrics.get("WALL_SECONDS", "inf")) <= 90.0,
            "bridge OS wall-time budget")
    require(0 < int(metrics.get("PEAK_RSS_KIB", "0")) <= RSS_LIMIT_KIB,
            "bridge OS RSS budget")
    require(re.fullmatch(r"[0-9a-f]{64}", str(data.get("binary_sha256", ""))) is not None,
            "bridge executable digest")

    selection = data.get("selection")
    require(type(selection) is dict, "bridge selection object")
    rank0_text = selection.get("rank0")
    rank1_text = selection.get("rank1")
    require(type(rank0_text) is str and
            re.fullmatch(r"0|[1-9][0-9]*", rank0_text) is not None,
            "selected rank0 decimal syntax")
    require(type(rank1_text) is str and
            re.fullmatch(r"[1-9][0-9]*", rank1_text) is not None,
            "selected rank1 decimal syntax")
    target = int(rank0_text)
    require(int(rank1_text) == target + 1, "selected rank indexing")
    require(0 <= target < root, "selected rank outside exact root")
    first_text = selection.get("first")
    require(type(first_text) is str and
            re.fullmatch(r"[1-9][0-9]*", first_text) is not None,
            "stream first syntax")
    first = int(first_text)
    step = selection.get("step")
    require(type(step) is int and step in (-1, 1), "stream direction")
    require(selection.get("is_median") is False, "expected a nonmedian canonical selection")
    expected_rank1 = choose_rank_direct(first, step, root, M)
    require(expected_rank1 == int(rank1_text) and target == expected_rank1 - 1,
            "selected rank0 does not match independent 1-based rank arithmetic")

    lines = Path(bridge_log).read_text(encoding="utf-8").splitlines()
    require(one_log_value(lines, "CANONICAL_BRIDGE_SOURCE_SHA") == source_sha,
            "bridge log source SHA")
    require(one_log_value(lines, "CANONICAL_BRIDGE_ROOT_SHA256") == root_digest,
            "bridge log root SHA")
    require(one_log_value(lines, "CANONICAL_BRIDGE_RANK0_SHA256") == sha256_text(rank0_text),
            "bridge log selected-rank digest")
    require(one_log_value(lines, "CANONICAL_BRIDGE_EQUALS_MEDIAN") == "FALSE",
            "bridge log median classification")
    require(one_log_value(lines, "CANONICAL_BRIDGE_NATIVE_EXIT") == "0",
            "bridge log Native exit")
    require(one_log_value(lines, "CANONICAL_BRIDGE_WORD_RANK_UNRANK") == "NOT_TESTED",
            "bridge must not claim word rank/unrank")
    require(one_log_value(lines, "CANONICAL_RANK_BRIDGE_RESULT") == "PASS_RESEARCH_ONLY",
            "bridge research result")
    require(one_log_value(lines, "CANONICAL_BRIDGE_STAGE6") == "NOT_CLAIMED",
            "bridge Stage 6 boundary")
    return data, target, hashlib.sha256(raw).hexdigest(), hashlib.sha256(
        Path(bridge_log).read_bytes()).hexdigest()


def parse_trace(raw, direction, target_rank, root, lengths, depths):
    if isinstance(raw, Path):
        raw = raw.read_bytes()
    require(raw.endswith(b"\n") and b"\r" not in raw and raw.isascii(),
            "missing canonical Native stdout")
    lines = raw.decode("ascii").splitlines()
    position = 0
    require(position < len(lines) and lines[position] == "NATIVE_SELECTED_ROOT=" + str(root),
            "Native exact root")
    position += 1
    entries = []
    for depth in depths:
        require(position < len(lines), "missing Native checkpoint")
        prefix = "NATIVE_SELECTED_CHECKPOINT=" + str(depth) + ";"
        require(lines[position].startswith(prefix), "checkpoint order/depth")
        count = lines[position][len(prefix):]
        require(re.fullmatch(r"[1-9][0-9]*", count) is not None,
                "noncanonical checkpoint count")
        entries.append((depth, int(count)))
        position += 1

    if direction == "selected-unrank":
        expected = "NATIVE_SELECTED_RANK0=" + str(target_rank)
    elif direction == "selected-rank":
        expected = "NATIVE_SELECTED_EXPECTED_RANK0=" + str(target_rank)
    else:
        raise AssertionError("unknown selected Native direction")
    require(position < len(lines) and lines[position] == expected,
            "selected rank binding")
    position += 1

    word_prefix = "NATIVE_SELECTED_WORD="
    require(position < len(lines) and lines[position].startswith(word_prefix),
            "missing selected witness")
    encoded = lines[position][len(word_prefix):]
    require(re.fullmatch(r"[1-9][0-9]*(,[1-9][0-9]*)*", encoded) is not None,
            "noncanonical selected witness")
    word = tuple(int(value) for value in encoded.split(","))
    require(len(word) == sum(lengths), "selected witness cardinality")
    require(oracle.verify_fifo_word(lengths, word) == sum(lengths),
            "independent FIFO witness")
    position += 1

    if direction == "selected-unrank":
        require(position < len(lines) and lines[position] == "NATIVE_SELECTED_RESIDUAL=0",
                "selected UNRANK residual")
    else:
        require(position < len(lines) and
                lines[position] == "NATIVE_SELECTED_RESULT_RANK0=" + str(target_rank),
                "selected reverse rank")
    position += 1
    require(position < len(lines) and lines[position] == "NATIVE_SELECTED_COMPLETE=1",
            "selected Native completion marker")
    position += 1
    require(position == len(lines), "unexpected Native output fields")

    for depth, count in entries:
        dense_count = oracle.count_prefix(lengths, word[:depth])
        require(dense_count == count, "independent dense prefix mismatch at " + str(depth))
    require(entries[-1][1] == 1, "terminal unique-completion count")
    return word, entries


def synthetic_trace(direction, word, root, target, lengths, depths):
    lines = ["NATIVE_SELECTED_ROOT=" + str(root)]
    for depth in depths:
        lines.append("NATIVE_SELECTED_CHECKPOINT=" + str(depth) + ";" +
                     str(oracle.count_prefix(lengths, word[:depth])))
    if direction == "selected-unrank":
        lines.extend([
            "NATIVE_SELECTED_RANK0=" + str(target),
            "NATIVE_SELECTED_WORD=" + ",".join(map(str, word)),
            "NATIVE_SELECTED_RESIDUAL=0",
            "NATIVE_SELECTED_COMPLETE=1",
        ])
    else:
        lines.extend([
            "NATIVE_SELECTED_EXPECTED_RANK0=" + str(target),
            "NATIVE_SELECTED_WORD=" + ",".join(map(str, word)),
            "NATIVE_SELECTED_RESULT_RANK0=" + str(target),
            "NATIVE_SELECTED_COMPLETE=1",
        ])
    return ("\n".join(lines) + "\n").encode("ascii")


def self_test():
    lengths = (2, 2)
    word = (1, 2, 1, 2)
    root = oracle.count_prefix(lengths, ())
    bridge_index_cases = 0
    for n in (2, 7, 19):
        for first in range(1, 6):
            for step in (-1, 1):
                rank1 = choose_rank_direct(first, step, n, 5)
                reference1 = choose_rank_reference(first, step, n, 5)
                rank0 = rank1 - 1
                require(rank1 == reference1 and 1 <= rank1 <= n and
                        0 <= rank0 < n and rank0 + 1 == rank1,
                        "bridge rank1/rank0 conversion")
                bridge_index_cases += 1
    require(bridge_index_cases == 30, "bridge index self-test cardinality")
    target = 1
    depths = (1, 2, 3, 4)
    positives = 0
    rejects = 0
    for direction in ("selected-unrank", "selected-rank"):
        raw = synthetic_trace(direction, word, root, target, lengths, depths)
        observed, entries = parse_trace(raw, direction, target, root, lengths, depths)
        require(observed == word and len(entries) == 4, "positive selected trace")
        positives += 1
        variants = [
            raw[:-1],
            raw.replace(b"NATIVE_SELECTED_ROOT=2", b"NATIVE_SELECTED_ROOT=3"),
            raw.replace(b"NATIVE_SELECTED_CHECKPOINT=1;2",
                        b"NATIVE_SELECTED_CHECKPOINT=1;3"),
            raw.replace(b"NATIVE_SELECTED_WORD=1,2,1,2",
                        b"NATIVE_SELECTED_WORD=1,2,1,3"),
            raw.replace(b"NATIVE_SELECTED_COMPLETE=1", b"NATIVE_SELECTED_COMPLETE=0"),
            raw + b"EXTRA=1\n",
            b"\n".join(line for line in raw.splitlines()
                       if not line.startswith(b"NATIVE_SELECTED_CHECKPOINT=2;")) + b"\n",
            raw.replace(b"NATIVE_SELECTED_CHECKPOINT=1;2",
                        b"NATIVE_SELECTED_CHECKPOINT=1;02"),
        ]
        if direction == "selected-unrank":
            variants.extend([
                raw.replace(b"NATIVE_SELECTED_RANK0=1", b"NATIVE_SELECTED_RANK0=0"),
                raw.replace(b"NATIVE_SELECTED_RESIDUAL=0",
                            b"NATIVE_SELECTED_RESIDUAL=1"),
            ])
        else:
            variants.extend([
                raw.replace(b"NATIVE_SELECTED_EXPECTED_RANK0=1",
                            b"NATIVE_SELECTED_EXPECTED_RANK0=0"),
                raw.replace(b"NATIVE_SELECTED_RESULT_RANK0=1",
                            b"NATIVE_SELECTED_RESULT_RANK0=0"),
            ])
        for variant in variants:
            require(variant != raw, "self-test mutation must change transcript")
            try:
                parse_trace(variant, direction, target, root, lengths, depths)
            except (AssertionError, ValueError):
                rejects += 1
            else:
                raise AssertionError("selected Native evidence mutation escaped")
    require(positives == 2 and rejects == 20, "selected trace self-test cardinality")
    print("NATIVE_SELECTED_SELFTEST_POSITIVE=" + str(positives))
    print("NATIVE_SELECTED_SELFTEST_MUTATION_REJECTS=" + str(rejects))
    print("NATIVE_SELECTED_SELFTEST_BRIDGE_INDEX_CASES=" + str(bridge_index_cases))
    print("NATIVE_SELECTED_SELFTEST_RESULT=PASS")
    print("NATIVE_SELECTED_4244=NOT_TESTED")
    print("NATIVE_SELECTED_STAGE6=NOT_CLAIMED")


def execute(args):
    source_sha = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    require(source_sha == args.source_sha and
            re.fullmatch(r"[0-9a-f]{40}", source_sha) is not None,
            "source SHA mismatch")
    version = subprocess.check_output(["chpl", "--version"], text=True).splitlines()[0]
    require("2.10.0" in version, "unexpected Chapel version")
    binary = args.binary.resolve()
    require(binary.is_file(), "Native adjoint binary missing")
    binary_sha = hashlib.sha256(binary.read_bytes()).hexdigest()
    probe_blob_sha = subprocess.check_output(
        ["git", "rev-parse", "HEAD:test/weaving_native_adjoint_probe.chpl"],
        text=True).strip()

    root = oracle.count_prefix(LENGTHS, ())
    root_digest = hashlib.sha256(
        root.to_bytes((root.bit_length() + 7) // 8, "big")).hexdigest()
    require(root.bit_length() == 22470 and root_digest == oracle.ROOT_SHA256,
            "independent exact full-year root lock")
    require(len(LENGTHS) == 45 and sum(LENGTHS) == 4244,
            "canonical 45-month/4244-day shape")

    bridge, target, bridge_json_sha, bridge_log_sha = load_bridge(
        args.bridge_json, args.bridge_log, source_sha, root, root_digest)
    args.outdir.mkdir(parents=True, exist_ok=True)

    import gmpy2
    require(gmpy2.version() == "2.2.1", "unexpected GMP backend version")

    provenance = {
        "schema": 1,
        "project_id": PROJECT_ID,
        "source_sha": source_sha,
        "native_probe_blob_sha": probe_blob_sha,
        "native_adjoint_binary_sha256": binary_sha,
        "chapel_version": version,
        "gmpy2_version": gmpy2.version(),
        "root_bits": root.bit_length(),
        "root_sha256": root_digest,
        "selected_rank0": str(target),
        "selected_rank0_sha256": sha256_text(str(target)),
        "bridge_json_sha256": bridge_json_sha,
        "bridge_log_sha256": bridge_log_sha,
        "bridge_native_binary_sha256": bridge["binary_sha256"],
        "time_limit_seconds_per_native_direction": TIME_LIMIT_SECONDS,
        "rss_limit_kib_per_native_direction": RSS_LIMIT_KIB,
        "stage6_acceptance": "NOT_CLAIMED",
    }
    (args.outdir / "provenance.json").write_text(
        json.dumps(provenance, sort_keys=True, ensure_ascii=False) + "\n",
        encoding="utf-8")

    unrank_result, unrank_path = native.run_native(
        binary, args.outdir, "selected-unrank", rank0=target)
    if unrank_result["status"] != "COMPLETE" or unrank_result["exit_code"] != 0:
        (args.outdir / "failure.json").write_text(
            json.dumps({"phase": "selected-unrank", "result": unrank_result},
                       sort_keys=True) + "\n", encoding="utf-8")
        print("NATIVE_SELECTED_UNRANK=" + unrank_result["status"])
        print("NATIVE_SELECTED_RESULT=NOT_ACCEPTED")
        print("NATIVE_SELECTED_STAGE6=NOT_CLAIMED")
        return 0 if unrank_result["status"].startswith("INCONCLUSIVE") else 1

    word, unrank_entries = parse_trace(
        unrank_path, "selected-unrank", target, root, LENGTHS, DEPTHS)
    word_path = args.outdir / "selected.word"
    word_path.write_text(",".join(map(str, word)) + "\n", encoding="ascii")

    rank_result, rank_path = native.run_native(
        binary, args.outdir, "selected-rank", word=word, rank0=target)
    if rank_result["status"] != "COMPLETE" or rank_result["exit_code"] != 0:
        (args.outdir / "failure.json").write_text(
            json.dumps({"phase": "selected-rank", "result": rank_result},
                       sort_keys=True) + "\n", encoding="utf-8")
        print("NATIVE_SELECTED_UNRANK=COMPLETE")
        print("NATIVE_SELECTED_RANK=" + rank_result["status"])
        print("NATIVE_SELECTED_RESULT=NOT_ACCEPTED")
        print("NATIVE_SELECTED_STAGE6=NOT_CLAIMED")
        return 0 if rank_result["status"].startswith("INCONCLUSIVE") else 1

    ranked_word, rank_entries = parse_trace(
        rank_path, "selected-rank", target, root, LENGTHS, DEPTHS)
    require(word == ranked_word, "Native UNRANK/RANK witnesses differ")

    independent = independently_rank(word, root, target)
    require(independent == target, "independent GMP reverse-rank mismatch")
    dense_checks = len(unrank_entries) + len(rank_entries)
    require(dense_checks == 24, "independent dense checkpoint cardinality")

    def direction_record(result, entries):
        require(result["wall_seconds"] <= TIME_LIMIT_SECONDS,
                "Native direction exceeded wall-time budget")
        require(type(result["peak_rss_kib"]) is int and
                0 < result["peak_rss_kib"] <= RSS_LIMIT_KIB,
                "Native direction exceeded or missed RSS measurement")
        return {
            "status": result["status"],
            "exit_code": result["exit_code"],
            "wall_seconds": result["wall_seconds"],
            "peak_rss_kib": result["peak_rss_kib"],
            "observed_checkpoints": result["observed_checkpoints"],
            "dense_checkpoints": [
                {"depth": depth, "count": str(count)} for depth, count in entries
            ],
        }

    evidence = {
        "schema": 1,
        "project_id": PROJECT_ID,
        "source_sha": source_sha,
        "native_probe_blob_sha": probe_blob_sha,
        "native_adjoint_binary_sha256": binary_sha,
        "chapel_version": version,
        "gmpy2_version": gmpy2.version(),
        "month_count": len(LENGTHS),
        "total_days": sum(LENGTHS),
        "root_bits": root.bit_length(),
        "root_sha256": root_digest,
        "selected_rank0": str(target),
        "selected_rank0_sha256": sha256_text(str(target)),
        "bridge_json_sha256": bridge_json_sha,
        "bridge_log_sha256": bridge_log_sha,
        "witness_symbols": len(word),
        "witness_sha256": oracle.digest_word(word),
        "unrank": direction_record(unrank_result, unrank_entries),
        "rank": direction_record(rank_result, rank_entries),
        "independent_dense_comparisons": dense_checks,
        "independent_gmp_rank": str(independent),
        "independent_gmp_result": "PASS",
        "status": "PASS_RESEARCH_ONLY",
        "stage6_acceptance": "NOT_CLAIMED",
    }
    (args.outdir / "validated.json").write_text(
        json.dumps(evidence, sort_keys=True, ensure_ascii=False) + "\n",
        encoding="utf-8")

    print("NATIVE_SELECTED_SOURCE_SHA=" + source_sha)
    print("NATIVE_SELECTED_ROOT_SHA256=" + root_digest)
    print("NATIVE_SELECTED_RANK0_SHA256=" + sha256_text(str(target)))
    print("NATIVE_SELECTED_UNRANK=COMPLETE")
    print("NATIVE_SELECTED_RANK=COMPLETE")
    print("NATIVE_SELECTED_WORD_SYMBOLS=4244")
    print("NATIVE_SELECTED_DENSE_CHECKS=" + str(dense_checks))
    print("NATIVE_SELECTED_GMP_RANK=PASS")
    print("NATIVE_SELECTED_RESULT=PASS_RESEARCH_ONLY")
    print("NATIVE_SELECTED_STAGE6=NOT_CLAIMED")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--binary", type=Path)
    parser.add_argument("--bridge-json", type=Path)
    parser.add_argument("--bridge-log", type=Path)
    parser.add_argument("--source-sha")
    parser.add_argument("--outdir", type=Path)
    args = parser.parse_args()
    if args.self_test:
        require(not any((args.binary, args.bridge_json, args.bridge_log,
                         args.source_sha, args.outdir)),
                "self-test excludes live Native inputs")
        self_test()
        return 0
    require(all((args.binary, args.bridge_json, args.bridge_log,
                 args.source_sha, args.outdir)),
            "missing selected Native inputs")
    try:
        return execute(args)
    except (AssertionError, ValueError, OSError, subprocess.SubprocessError) as exc:
        print("NATIVE_SELECTED_GATE_FAILURE=" + str(exc), file=sys.stderr)
        print("NATIVE_SELECTED_RESULT=NOT_ACCEPTED")
        print("NATIVE_SELECTED_STAGE6=NOT_CLAIMED")
        return 1


if __name__ == "__main__":
    sys.exit(main())
