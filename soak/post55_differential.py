#!/usr/bin/env python3
"""Fail-closed, bounded post-55 cross-implementation differential soak.

The currently supplied Kotlin bridge is TEST-ONLY ORACLE, so its comparison
with an independent Python implementation is diagnostic, not certification.
Use --certify only with an independently implemented Kotlin production CLI.
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

FOUNDATION = -15055671
TABLETS = -278522
DECIMAL = re.compile(r"^-?(?:0|[1-9][0-9]*)$")
FIELDS = ("year_number", "cutlet_index", "day_in_cutlet", "month_index", "day_in_month")


def corpus(count, seed):
    randomizer = random.Random(seed)
    anchors = (FOUNDATION, TABLETS, 0, 739834)
    offsets = (
        (-1, -1), (0, 0), (1, 1), (0, 1), (1, 0),
        (-100, 100), (100, -100), (0, 251), (0, 252),
        (0, 5778), (0, -5778), (5778, 0),
    )
    cases = []
    seen = set()

    def add(c, t):
        pair = (int(c), int(t))
        if pair not in seen:
            seen.add(pair)
            cases.append(pair)

    # Interleave all anchors so even a small smoke run covers every epoch.
    for dx, dy in offsets:
        for base in anchors:
            add(base + dx, base + dy)
    while len(cases) < count:
        base = anchors[randomizer.randrange(len(anchors))]
        c = base + randomizer.randint(-12000, 12000)
        t = c + randomizer.randint(-12000, 12000)
        add(c, t)
    return cases[:count]


def normalized(rows, expected, label):
    lines = rows.splitlines()
    if len(lines) != len(expected):
        raise ValueError(f"E_SOAK_{label}_LINE_COUNT expected={len(expected)} got={len(lines)}")
    result = []
    for i, (line, pair) in enumerate(zip(lines, expected)):
        parts = line.split("\t")
        if len(parts) != 7 or any(not DECIMAL.fullmatch(s) for s in parts):
            raise ValueError(f"E_SOAK_{label}_FORMAT row={i}")
        vals = tuple(int(x) for x in parts)
        if vals[:2] != pair:
            raise ValueError(f"E_SOAK_{label}_PAIR row={i}")
        _, _, year, cutlet, cutday, month, monthday = vals
        if not (1 <= cutlet <= 17 and 1 <= month <= 47 and
                1 <= cutday <= 5778 and 1 <= monthday <= 123):
            raise ValueError(f"E_SOAK_{label}_CANONICAL_RANGE row={i}")
        result.append(vals[2:])
    return result


def invoke(command, pairs, timeout, label):
    argv = shlex.split(command)
    if not argv:
        raise ValueError(f"E_SOAK_{label}_COMMAND_EMPTY")
    data = "".join(f"{c}\t{t}\n" for c, t in pairs)
    env = dict(os.environ)
    env["OMP_NUM_THREADS"] = "1"
    env["OPENBLAS_NUM_THREADS"] = "1"
    env["MKL_NUM_THREADS"] = "1"
    try:
        process = subprocess.run(
            argv, input=data, text=True, capture_output=True,
            timeout=timeout, env=env, check=False,
        )
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError(f"E_SOAK_{label}_TIMEOUT seconds={timeout}") from exc
    if process.returncode != 0:
        detail = process.stderr[-1200:].replace("\n", " ")
        raise RuntimeError(
            f"E_SOAK_{label}_NONZERO exit={process.returncode} stderr={detail}"
        )
    return normalized(process.stdout, pairs, label)


def write_evidence(path, obj):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".partial")
    temporary.write_text(
        json.dumps(obj, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    temporary.replace(path)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--kotlin-command", required=True)
    parser.add_argument("--python-command", required=True)
    parser.add_argument("--cases", type=int, default=96)
    parser.add_argument("--seed", type=int, default=55)
    parser.add_argument("--batch", type=int, default=8)
    parser.add_argument("--timeout-seconds", type=int, default=180)
    parser.add_argument("--kotlin-mode", choices=("oracle", "production"), default="oracle")
    parser.add_argument("--certify", action="store_true")
    parser.add_argument("--kotlin-revision", required=True)
    parser.add_argument("--python-revision", required=True)
    parser.add_argument("--evidence", type=Path, required=True)
    args = parser.parse_args(argv)

    if not 1 <= args.cases <= 1000000:
        parser.error("--cases must be between 1 and 1000000")
    if not 1 <= args.batch <= 64:
        parser.error("--batch must be between 1 and 64")
    if not 1 <= args.timeout_seconds <= 3600:
        parser.error("--timeout-seconds must be between 1 and 3600")
    # A mode string is not provenance. Until an independently audited
    # production bridge exists, --certify must fail even if the caller says
    # --kotlin-mode production. Otherwise a fake/oracle CLI can self-certify.
    if args.certify:
        parser.error(
            "E_SOAK_CERTIFICATION_REQUIRES_AUDITED_KOTLIN_PRODUCTION_BRIDGE"
        )
    if not (re.fullmatch(r"[0-9a-f]{40}", args.kotlin_revision) and
            re.fullmatch(r"[0-9a-f]{40}", args.python_revision)):
        parser.error("both revisions must be pinned full 40-digit Git commit SHAs")

    cases = corpus(args.cases, args.seed)
    canonical_input = "".join(f"{c}\t{t}\n" for c, t in cases)
    evidence = {
        "schema": "pastafarian-cross-soak-v1",
        "kotlin_revision": args.kotlin_revision,
        "python_revision": args.python_revision,
        "kotlin_mode": args.kotlin_mode,
        "certification_requested": args.certify,
        "certifiable": False,  # A CLI flag cannot establish provenance.
        "seed": args.seed,
        "cases": len(cases),
        "batch_size": args.batch,
        "case_sha256": hashlib.sha256(canonical_input.encode("ascii")).hexdigest(),
        "completed": 0,
        "status": "RUNNING",
        "mismatch": None,
        "error": None,
    }
    write_evidence(args.evidence, evidence)
    try:
        for start in range(0, len(cases), args.batch):
            chunk = cases[start : start + args.batch]
            kotlin = invoke(args.kotlin_command, chunk, args.timeout_seconds, "KOTLIN")
            python = invoke(args.python_command, chunk, args.timeout_seconds, "PYTHON")
            for j, pair in enumerate(chunk):
                if kotlin[j] != python[j]:
                    evidence["status"] = "FAIL_MISMATCH"
                    evidence["completed"] = start + j + 1
                    evidence["mismatch"] = {
                        "index": start + j,
                        "calculation_day": str(pair[0]),
                        "target_day": str(pair[1]),
                        "kotlin": dict(zip(FIELDS, map(str, kotlin[j]))),
                        "python": dict(zip(FIELDS, map(str, python[j]))),
                    }
                    write_evidence(args.evidence, evidence)
                    print(f"E_SOAK_MISMATCH at case {start+j}", file=sys.stderr)
                    return 2
            evidence["completed"] = start + len(chunk)
            write_evidence(args.evidence, evidence)
    except (OSError, RuntimeError, ValueError) as exc:
        evidence["status"] = "BLOCKED"
        evidence["error"] = str(exc)
        write_evidence(args.evidence, evidence)
        print(str(exc), file=sys.stderr)
        return 3

    evidence["status"] = "PASS_DIAGNOSTIC_NOT_CERTIFIED"
    write_evidence(args.evidence, evidence)
    print(f"{evidence['status']}: {len(cases)} cases, zero mismatches")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
