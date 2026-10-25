#!/usr/bin/env python3
"""Independent PRODUCTION-component soak: Kotlin selector versus Python selector.

Comparisons cover exact one-based rank, rejected stream answers and gate gap.
The shared input is synthetic first/step/count, not a shared expected result.
It is NOT a full calendar date soak. Evidence records this limitation.
"""
import argparse
import hashlib
import json
import os
import random
import re
import shlex
import subprocess
import sys
from pathlib import Path

M = (1 << 127) - 1
FIELDS = ("kind", "id", "first", "step", "rank1", "gap", "rejections")
DEC = re.compile(r"^-?(?:0|[1-9][0-9]*)$")


def build_cases(seed):
    randomizer = random.Random(seed)
    cases = []
    seen = set()

    def add(kind, ident, first, step):
        if not 1 <= first <= M:
            return
        row = (kind, ident, first, step)
        if row not in seen:
            seen.add(row)
            cases.append(row)

    def values(n):
        upper = (M // n) * n
        return (1, 2, upper - 1, upper, upper + 1, M - 1, M)

    # Gate-gap rank 922; compare both signed gate magnitudes/directions.
    for magnitude in range(1, 33):
        for direction in (-1, 1):
            for gate in (-magnitude, magnitude):
                for first in values(922):
                    add("G", gate, first, direction)

    # Year candidate selection: fixed small/medium/wide families.
    counts = list(range(1, 65)) + list(range(1001, 1129))
    for n in counts:
        for direction in (-1, 1):
            for first in values(n):
                add("Y", n, first, direction)

    # Deterministic additional interior answers (not just boundaries).
    for _ in range(256):
        if randomizer.getrandbits(1):
            add("G", randomizer.choice((-1, 1)) * randomizer.randint(1, 10000),
                randomizer.randint(1, M), randomizer.choice((-1, 1)))
        else:
            add("Y", randomizer.choice(counts), randomizer.randint(1, M),
                randomizer.choice((-1, 1)))
    return cases


def parse_output(raw, cases, label):
    lines = raw.splitlines()
    if len(lines) != len(cases):
        raise ValueError(f"E_COMPONENT_{label}_LINE_COUNT:{len(lines)}!={len(cases)}")
    results = []
    for i, (line, original) in enumerate(zip(lines, cases)):
        p = line.split("\t")
        if len(p) != 7 or p[0] not in ("G", "Y") or any(
            not DEC.fullmatch(v) for v in p[1:]
        ):
            raise ValueError(f"E_COMPONENT_{label}_FORMAT:{i}")
        vals = (p[0], *(int(x) for x in p[1:]))
        if vals[:4] != original:
            raise ValueError(f"E_COMPONENT_{label}_INPUT_ECHO:{i}")
        kind, ident, first, step, rank, gap, rejected = vals
        n = 922 if kind == "G" else ident
        if not (n > 0 and 1 <= rank <= n and
                gap == (41 + rank if kind == "G" else 0) and
                0 <= rejected <= n):
            raise ValueError(f"E_COMPONENT_{label}_RANGE:{i}")
        results.append(vals[4:])
    return results


def run(command, cases, timeout_seconds, label):
    command_parts = shlex.split(command)
    if not command_parts:
        raise ValueError(f"E_COMPONENT_{label}_EMPTY_COMMAND")
    source = "".join("\t".join(map(str, row)) + "\n" for row in cases)
    env = os.environ.copy()
    env.update(OMP_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1", MKL_NUM_THREADS="1")
    try:
        proc = subprocess.run(
            command_parts, input=source, text=True, capture_output=True,
            timeout=timeout_seconds, check=False, env=env,
        )
    except subprocess.TimeoutExpired as e:
        raise RuntimeError(f"E_COMPONENT_{label}_TIMEOUT") from e
    if proc.returncode != 0:
        raise RuntimeError(
            f"E_COMPONENT_{label}_EXIT_{proc.returncode}:" +
            proc.stderr[-1400:].replace("\n", " ")
        )
    return parse_output(proc.stdout, cases, label)


def evidence_to_file(path, report):
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_name(path.name + ".partial")
    temp.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n",
                    encoding="utf-8")
    os.replace(temp, path)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--kotlin-command", required=True)
    parser.add_argument("--python-command", required=True)
    parser.add_argument("--kotlin-revision", required=True)
    parser.add_argument("--python-revision", required=True)
    parser.add_argument("--evidence", type=Path, required=True)
    parser.add_argument("--seed", type=int, default=55)
    parser.add_argument("--timeout-seconds", type=int, default=180)
    options = parser.parse_args(argv)
    if not (re.fullmatch(r"[a-f0-9]{40}", options.kotlin_revision) and
            re.fullmatch(r"[a-f0-9]{40}", options.python_revision)):
        parser.error("E_COMPONENT_REVISION_NOT_PINNED")
    if options.timeout_seconds < 1 or options.timeout_seconds > 3600:
        parser.error("E_COMPONENT_BAD_TIMEOUT")

    cases = build_cases(options.seed)
    source = "".join("\t".join(map(str, row)) + "\n" for row in cases)
    report = {
        "schema": "pastafarian-rank-component-differential-v1",
        "scope": "production rank selection ONLY, not a full calendar soak",
        "certifies_full_calendar": False,
        "kotlin_revision": options.kotlin_revision,
        "python_revision": options.python_revision,
        "seed": options.seed,
        "cases": len(cases),
        "input_sha256": hashlib.sha256(source.encode("ascii")).hexdigest(),
        "completed": 0,
        "status": "RUNNING",
        "mismatch": None,
        "error": None,
    }
    evidence_to_file(options.evidence, report)
    try:
        left = run(options.kotlin_command, cases, options.timeout_seconds, "KOTLIN")
        right = run(options.python_command, cases, options.timeout_seconds, "PYTHON")
        for i, (a, b) in enumerate(zip(left, right)):
            if a != b:
                report["status"] = "FAIL_MISMATCH"
                report["completed"] = i + 1
                report["mismatch"] = {
                    "index": i,
                    "input": list(map(str, cases[i])),
                    "kotlin_rank_gap_rejections": list(a),
                    "python_rank_gap_rejections": list(b),
                }
                evidence_to_file(options.evidence, report)
                print(f"E_COMPONENT_MISMATCH case={i}", file=sys.stderr)
                return 2
            report["completed"] = i + 1
    except (ValueError, RuntimeError, OSError) as e:
        report["status"] = "BLOCKED"
        report["error"] = str(e)
        evidence_to_file(options.evidence, report)
        print(str(e), file=sys.stderr)
        return 3
    report["status"] = "PASS_COMPONENT_ONLY_NOT_FULL_DATE"
    evidence_to_file(options.evidence, report)
    print("STAGE55_COMPONENT_DIFFERENTIAL_GREEN_" + str(len(cases)))
    print("STAGE55_COMPONENT_NOT_FULL_DATE_SOAK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
