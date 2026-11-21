#!/usr/bin/env python3
"""Independent arithmetic audit of the actual Year 5000 normative weaving rank.

Research-only bridge, NOT complete weaving generation or Stage 6 acceptance.
"""
import argparse
import hashlib
import json
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path

sys.set_int_max_str_digits(10000)
ROOT = Path(__file__).resolve().parents[1]
from weaving_native_median_evidence_gate import (
    MONTH_LENGTHS, ROOT_SHA256, count_prefix,
)

M = (1 << 127) - 1
FIELDS = (
    "CANONICAL_BRIDGE_YEAR",
    "CANONICAL_BRIDGE_MONTH_LENGTHS",
    "CANONICAL_BRIDGE_STREAM_FIRST",
    "CANONICAL_BRIDGE_STREAM_STEP",
    "CANONICAL_BRIDGE_SELECTED_RANK1",
    "CANONICAL_BRIDGE_STAGE6",
)


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def choose_rank_direct(first, step, n, modulus):
    """Closed-form rejection walk, independent of Chapel's loop implementation."""
    require(1 <= first <= modulus and step in (-1, 1), "invalid answer stream")
    require(n > 0 and modulus > 1, "invalid rank space")
    if n <= modulus:
        space, value = modulus, first
    else:
        space = modulus
        places = 1
        while space < n:
            space *= modulus
            places += 1
        # Positional evaluation of the independent periodic stream.
        value, factor = 1, 1
        for j in range(places):
            digit0 = (first - 1 + step * j) % modulus
            value += digit0 * factor
            factor *= modulus
    limit = (space // n) * n
    # For +/-1 a rejected suffix reaches the accepted interval at 1 or limit.
    # This avoids an unbounded imitation of the normative iterative rejection.
    if value > limit:
        value = 1 if step == 1 else limit
    return (value - 1) % n + 1


def choose_rank_reference(first, step, n, modulus):
    """Intentionally slow state-by-state implementation for small self-tests."""
    if n <= modulus:
        space, value = modulus, first
    else:
        space, places = modulus, 1
        while space < n:
            space *= modulus
            places += 1
        value, factor = 1, 1
        for j in range(places):
            value += ((first - 1 + step * j) % modulus) * factor
            factor *= modulus
    limit = (space // n) * n
    iterations = 0
    while value > limit:
        value = 1 + ((value - 1 + step) % space)
        iterations += 1
        require(iterations <= space, "reference rejection failed to terminate")
    return (value - 1) % n + 1


def parse_native(text, root):
    lines = text.splitlines()
    require(len(lines) == len(FIELDS), "Native field cardinality")
    values = {}
    for line, key in zip(lines, FIELDS):
        require(line.startswith(key + "="), "Native field order: " + key)
        values[key] = line[len(key) + 1:]
    require(values["CANONICAL_BRIDGE_YEAR"] == "5000", "wrong normative year")
    require(values["CANONICAL_BRIDGE_STAGE6"] == "NOT_CLAIMED", "stage boundary")
    actual_lengths = tuple(int(x) for x in values["CANONICAL_BRIDGE_MONTH_LENGTHS"].split(","))
    require(actual_lengths == MONTH_LENGTHS, "canonical year lengths mismatch")
    for k in ("CANONICAL_BRIDGE_STREAM_FIRST", "CANONICAL_BRIDGE_SELECTED_RANK1"):
        require(re.fullmatch(r"[1-9][0-9]*", values[k]) is not None, "noncanonical number: " + k)
    require(values["CANONICAL_BRIDGE_STREAM_STEP"] in ("-1", "1"), "invalid stream direction")
    first = int(values["CANONICAL_BRIDGE_STREAM_FIRST"])
    step = int(values["CANONICAL_BRIDGE_STREAM_STEP"])
    selected1 = int(values["CANONICAL_BRIDGE_SELECTED_RANK1"])
    expected1 = choose_rank_direct(first, step, root, M)
    require(selected1 == expected1 and 1 <= selected1 <= root,
            "normative selection != independent modular-rank oracle")
    return {"first": str(first), "step": step, "rank1": str(selected1),
            "rank0": str(selected1 - 1),
            "is_median": selected1 - 1 == root // 2}


def self_test():
    checks = 0
    for modulus in (5, 7, 11):
        for n in range(1, 3 * modulus * modulus + 1):
            for first in range(1, modulus + 1):
                for step in (-1, 1):
                    direct = choose_rank_direct(first, step, n, modulus)
                    reference = choose_rank_reference(first, step, n, modulus)
                    require(direct == reference and 1 <= direct <= n,
                            "synthetic direct/iterative mismatch")
                    checks += 1
    require(checks == 2 * (5 * 75 + 7 * 147 + 11 * 363),
            "self-test expected count")
    print("CANONICAL_BRIDGE_SELFTEST_CASES=" + str(checks))
    print("CANONICAL_BRIDGE_SELFTEST_RESULT=PASS")
    print("CANONICAL_BRIDGE_NATIVE=NOT_TESTED")
    print("CANONICAL_BRIDGE_STAGE6=NOT_CLAIMED")


def run(args):
    source_sha = subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    require(source_sha == args.source_sha and
            re.fullmatch(r"[0-9a-f]{40}", source_sha) is not None,
            "source SHA mismatch")
    version = subprocess.check_output(["chpl", "--version"], text=True).splitlines()[0]
    require("2.10.0" in version, "Chapel runtime version mismatch")
    root = count_prefix(MONTH_LENGTHS)
    digest = hashlib.sha256(root.to_bytes((root.bit_length() + 7) // 8, "big")).hexdigest()
    require(root.bit_length() == 22470 and digest == ROOT_SHA256,
            "independent full-year root lock mismatch")
    args.outdir.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="chapel-selected-rank-") as tmp:
        binary = Path(tmp) / "selected-rank"
        compile_command = ["chpl", "-M", "src", "-M", "test",
                           "test/weaving_canonical_selected_rank.chpl", "-o", str(binary)]
        compilation = subprocess.run(compile_command, cwd=ROOT, capture_output=True,
                                     text=True, timeout=150, check=False)
        (args.outdir / "compile.stdout").write_text(compilation.stdout)
        (args.outdir / "compile.stderr").write_text(compilation.stderr)
        require(compilation.returncode == 0, "Native Chapel compilation failed")
        binary_digest = hashlib.sha256(binary.read_bytes()).hexdigest()
        metrics_file = args.outdir / "native-time.txt"
        command = ["/usr/bin/time", "-f", "WALL_SECONDS=%e\\nPEAK_RSS_KIB=%M",
                   "-o", str(metrics_file), str(binary), "--rootDecimal=" + str(root)]
        began = time.monotonic()
        result = subprocess.run(command, cwd=ROOT, capture_output=True,
                                text=True, timeout=90, check=False)
        elapsed = time.monotonic() - began
        (args.outdir / "native.stdout").write_text(result.stdout)
        (args.outdir / "native.stderr").write_text(result.stderr)
        require(result.returncode == 0 and elapsed < 90, "Native selected-rank execution incomplete")
        selection = parse_native(result.stdout, root)
        report = {
            "schema": 1, "project_id": "PC-BRANCH-CHAPEL-UKRAINIAN",
            "source_sha": source_sha, "chapel_version": version,
            "binary_sha256": binary_digest,
            "root_bits": root.bit_length(), "root_sha256": digest,
            "selection": selection, "native_exit": result.returncode,
            "native_elapsed_seconds": round(elapsed, 6),
            "native_time_output": metrics_file.read_text(),
            "proof": "NORMATIVE_SELECTION_EQUALS_INDEPENDENT_ARITHMETIC",
            "word_rank_unrank": "NOT_TESTED_FOR_SELECTED_RANK",
            "stage6": "NOT_CLAIMED",
        }
        (args.outdir / "validated.json").write_text(
            json.dumps(report, sort_keys=True, ensure_ascii=False) + "\n")
    print("CANONICAL_BRIDGE_SOURCE_SHA=" + source_sha)
    print("CANONICAL_BRIDGE_ROOT_SHA256=" + digest)
    print("CANONICAL_BRIDGE_RANK0_SHA256=" +
          hashlib.sha256(selection["rank0"].encode("ascii")).hexdigest())
    print("CANONICAL_BRIDGE_EQUALS_MEDIAN=" + str(selection["is_median"]).upper())
    print("CANONICAL_BRIDGE_NATIVE_EXIT=0")
    print("CANONICAL_BRIDGE_WORD_RANK_UNRANK=NOT_TESTED")
    print("CANONICAL_RANK_BRIDGE_RESULT=PASS_RESEARCH_ONLY")
    print("CANONICAL_BRIDGE_STAGE6=NOT_CLAIMED")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--source-sha")
    parser.add_argument("--outdir", type=Path)
    args = parser.parse_args()
    if args.self_test:
        require(not args.source_sha and args.outdir is None,
                "self-test cannot accept live source parameters")
        self_test()
        return
    require(args.source_sha and args.outdir is not None, "missing source or output")
    run(args)


if __name__ == "__main__":
    try:
        main()
    except (AssertionError, ValueError, subprocess.SubprocessError) as exc:
        print("CANONICAL_RANK_BRIDGE_RESULT=NOT_ACCEPTED", file=sys.stderr)
        print("CANONICAL_RANK_BRIDGE_ERROR=" + str(exc), file=sys.stderr)
        raise
