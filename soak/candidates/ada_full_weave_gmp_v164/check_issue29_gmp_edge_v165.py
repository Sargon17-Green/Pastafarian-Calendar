#!/usr/bin/env python3
"""Independent exact combinatorial count for 1x4, 47x252, 47x5778.

Consumes output of standalone Ada GMP edge test; does NOT import any calendar,
call F(c,t), or use previous converter outputs as a computational oracle.
"""
from __future__ import annotations

from hashlib import sha256
import json
from math import comb
from pathlib import Path
import sys


FAMILIES = {
    "1x4": (4,),
    "47x252": (5,) * 45 + (13, 14),
    "47x5778": (123,) * 44 + (122,) * 3,
}


def independent_count(lengths: tuple[int, ...]) -> int:
    prefix = [0]
    for n in lengths:
        prefix.append(prefix[-1] + n)
    next_row = [1] * (prefix[-1] + 1)
    for i in range(len(lengths) - 1, -1, -1):
        n = lengths[i]
        current = [0] * (prefix[i] + 1)
        weighted = 0
        for y in range(n-1, prefix[i+1]):
            weighted += comb(y-1, n-2) * next_row[y]
            current[y-n+1] = weighted
        next_row = current
    return next_row[0]


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: checker.py ADA_EDGE_STDOUT NEW_RECEIPT_JSON")
    lines = Path(sys.argv[1]).read_text(encoding="utf-8").splitlines()
    if "V165_ALL_THREE_EDGE_FAMILIES_PASS_NO_F" not in lines:
        raise RuntimeError("Ada source-free edge test completion missing")
    successes: dict[str, list[int]] = {}
    counts: dict[str, str] = {}
    for line in lines:
        parts = line.split("|")
        if len(parts) == 4 and parts[0] == "V165_EDGE_PASS":
            _, name, rank_case, days = parts
            successes.setdefault(name, []).append(int(rank_case))
            if int(days) != sum(FAMILIES[name]):
                raise RuntimeError("edge test printed wrong year length")
        if len(parts) == 3 and parts[0] == "V165_EDGE_COUNT_HEX":
            _, name, x = parts
            if name in counts or not x or x.startswith("0") or any(c not in "0123456789abcdef" for c in x):
                raise RuntimeError("bad or duplicate native Ada GMP count")
            counts[name] = x
    if set(counts) != set(FAMILIES) or set(successes) != set(FAMILIES):
        raise RuntimeError("not all three synthetic family sizes were tested")
    receipt = {}
    for name, lengths in FAMILIES.items():
        if sorted(successes[name]) != [1, 2]:
            raise RuntimeError("rank first/last were not both checked: " + name)
        native_hex = counts[name]
        python_exact = independent_count(lengths)
        if format(python_exact, "x") != native_hex:
            raise RuntimeError("native Ada GMP and Python-int counts disagree: " + name)
        receipt[name] = {
            "months": len(lengths),
            "days": sum(lengths),
            "count_bits": python_exact.bit_length(),
            "count_hex_sha256": sha256(native_hex.encode("ascii")).hexdigest(),
            "exact_count_equal_to_independent_python_int": True,
            "rank_first_and_last_validated_by_native_ada": True,
        }
        print("V165_EDGE_INDEPENDENT_COUNT_MATCH", name, python_exact.bit_length(), "bits")
    if receipt["1x4"]["count_bits"] != 1:
        raise RuntimeError("one-month count must be exactly one")
    out = Path(sys.argv[2])
    if out.exists():
        raise RuntimeError("refuse to overwrite edge test receipt")
    out.write_text(json.dumps({
        "schema": "ISSUE29_V165_STANDALONE_ADA_GMP_INDEPENDENT_EDGE_TEST/1",
        "cases": receipt,
        "execution_mode": "SYNTHETIC_MULTISETS_NO_CALENDAR_MODEL",
        "original_calendar_calls": 0,
        "qa_calendar_calls": 0,
        "soak_years": 0,
    }, indent=2, sort_keys=True) + "\n")
    print("V165_EXACT_GMP_EDGE_47x252_AND_47x5778_PASS_NO_F")


if __name__ == "__main__":
    main()
