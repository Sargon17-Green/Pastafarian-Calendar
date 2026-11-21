#!/usr/bin/env python3
"""Independent Python-int oracle for QA-only D21 full-N Logo fixtures.

Reads only the test fixture (no imported production algorithm, no other branch).
Verifies each exact-BI literal, floor quotient/remainder, iterative +/-1 walk,
bounded 0..31 rank/index, unique tags and deterministic case/check counts.
"""
from __future__ import annotations
import re
import sys
from pathlib import Path

M = (1 << 127) - 1  # Appendix-A fixed M, independent encoding of base-10000 Logo digits
BASE = 10000
PAT = re.compile(
    r"^\s*d21a\.case\s+"
    + (r"\(bi\.make 1 \[([0-9 ]+)\]\)\s+") * 2
    + r"(-?1)\s+"
    + (r"\(bi\.make 1 \[([0-9 ]+)\]\)\s+") * 2
    + r"(-?\d+)\s+\(bi\.make 1 \[([0-9 ]+)\]\)\s+\[([A-Za-z0-9_]+)\]$"
)

def from_digits(raw: str) -> int:
    ds = [int(v) for v in raw.split()]
    if not ds or any(d < 0 or d >= BASE for d in ds):
        raise ValueError("invalid base-10000 literal")
    if len(ds) > 1 and ds[-1] == 0:
        raise ValueError("noncanonical leading zero digit")
    return sum(d * (BASE ** i) for i, d in enumerate(ds))

def oracle(first: int, direction: int, n: int) -> tuple[int, int]:
    q, r = divmod(M, n)
    limit = M - r
    x = first
    for k in range(32):
        if x <= limit:
            return k, 1 + (x - 1) % n
        if direction == 1:
            x = 1 if x == M else x + 1
        else:
            x = M if x == 1 else x - 1
    return -1, 1

def run(path: Path) -> None:
    lines = path.read_text(encoding="utf-8").splitlines()
    cases = 0
    checks = 0
    labels: set[str] = set()
    hits = 0
    misses = 0
    for lineno, line in enumerate(lines, 1):
        if not line.lstrip().startswith("d21a.case "):
            continue
        m = PAT.fullmatch(line)
        if not m:
            raise ValueError(f"line {lineno}: fixture syntax not recognized")
        n, first, direction, q, r, k, rank, label = m.groups()
        n, first, q, r, rank = map(from_digits, (n, first, q, r, rank))
        direction, k = int(direction), int(k)
        if not 1 <= n <= M or not 1 <= first <= M or direction not in (-1, 1):
            raise ValueError(f"line {lineno}: invalid input")
        if label in labels:
            raise ValueError(f"line {lineno}: duplicate label {label}")
        labels.add(label)
        oracle_q, oracle_r = divmod(M, n)
        oracle_k, oracle_rank = oracle(first, direction, n)
        if (q, r, k, rank) != (oracle_q, oracle_r, oracle_k, oracle_rank):
            raise ValueError(f"line {lineno}: wrong host-independent oracle {label}")
        cases += 1
        if k < 0:
            checks += 6
            misses += 1
        else:
            checks += 8
            hits += 1
    if cases != 130 or checks != 1010:
        raise ValueError(f"fixture count mismatch {cases}/{checks}")
    if not (hits > 0 and misses > 0):
        raise ValueError("both bounded-hit and bounded-miss cases required")
    print(f"D21_FULLN_HOST_CASES_OK {cases}")
    print(f"D21_FULLN_HOST_CHECKS_OK {checks}")
    print(f"D21_FULLN_HOST_HITS {hits}")
    print(f"D21_FULLN_HOST_MISSES {misses}")
    print("D21_FULLN_HOST_ORACLE=PASS")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: python3 qa/logo_d21_fulln_host_oracle.py <Logo fixture>")
    try:
        run(Path(sys.argv[1]))
    except (ValueError, OSError) as e:
        print(f"D21_FULLN_HOST_ORACLE=FAIL: {e}", file=sys.stderr)
        raise SystemExit(1)
