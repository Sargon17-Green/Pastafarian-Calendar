#!/usr/bin/env python3
"""v164 independent full-family DP for 45x4244 synthetic GMP count verification.

Imports ONLY Python stdlib. Does not import or call any calendar F(c,t) code.
No Python decimal-string conversion of enormous integers is performed.
"""
from __future__ import annotations

from hashlib import sha256
from math import comb
from pathlib import Path
import json
import sys

LENGTHS = (94,) * 44 + (108,)
EXPECTED_HEX_LENGTH = 5684
EXPECTED_SHA256 = "a00e6fcff6333e0f36452c6f69406f152ae3297a16d1e3a6a753bc55bde50736"
EXPECTED_BITS = 22734


def independent_full_count(lengths: tuple[int, ...]) -> int:
    prefix = [0]
    for n in lengths:
        prefix.append(prefix[-1] + n)
    h = [None] * (len(lengths) + 1)
    h[-1] = [1] * (prefix[-1] + 1)
    for i in range(len(lengths) - 1, -1, -1):
        n = lengths[i]
        weighted = 0
        row = [0] * (prefix[i] + 1)
        for y in range(n - 1, prefix[i + 1]):
            weighted += comb(y - 1, n - 2) * h[i + 1][y]
            row[y - n + 1] = weighted
        h[i] = row
    return h[0][0]


def main() -> int:
    if len(sys.argv) != 3:
        raise RuntimeError("usage: checker.py GMP_STDOUT_PATH RECEIPT_PATH")
    source, target = Path(sys.argv[1]), Path(sys.argv[2])
    lines = source.read_text(encoding="utf-8").splitlines()
    marker = "V164_GMP_EXACT_COUNT_HEX="
    values = [x[len(marker):] for x in lines if x.startswith(marker)]
    if len(values) != 1:
        raise RuntimeError("expected exactly one GMP native hex count output")
    raw = values[0]
    if not raw or any(c not in "0123456789abcdef" for c in raw):
        raise RuntimeError("GMP hex output is not canonical lowercase")
    if raw.startswith("0") or len(raw) != EXPECTED_HEX_LENGTH:
        raise RuntimeError("GMP output width/zero padding unexpected")
    counted = independent_full_count(LENGTHS)
    expected = format(counted, "x")
    if counted.bit_length() != EXPECTED_BITS or len(expected) != EXPECTED_HEX_LENGTH:
        raise RuntimeError("independent count bit-size proof changed")
    digest = sha256(raw.encode("ascii")).hexdigest()
    if digest != EXPECTED_SHA256 or expected != raw:
        raise RuntimeError("GMP full-size exact count differs from independent Python DP")
    receipt = {
        "schema": "ISSUE29_V164_INDEPENDENT_45X4244_EXACT_GMP_COUNT_CHECK/1",
        "case": "synthetic only, no calendar date input",
        "month_lengths": "94 repeated 44 times, then 108",
        "months": 45,
        "total_days": sum(LENGTHS),
        "count_bit_length": counted.bit_length(),
        "count_hex_digits": len(raw),
        "count_hex_sha256": digest,
        "exact_integer_equality": True,
        "source_mode": "INDEPENDENT_SOURCE_FREE_PYTHON_INT_DP_VS_NATIVE_ADA_GMP",
        "calendar_F_calls": 0,
        "soak_years": 0,
    }
    target.write_text(json.dumps(receipt, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    print("V164_INDEPENDENT_45x4244_EXACT_GMP_BIG_INTEGER_COUNT_EQUAL")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
