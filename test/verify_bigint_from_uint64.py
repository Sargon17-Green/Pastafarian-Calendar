#!/usr/bin/env python3
"""Independent Python-int reference for Object Pascal UInt64 constructor QA."""
import csv
from collections import Counter
from pathlib import Path

MAX64 = 2**64 - 1
EXPECTED = (
    [("ZERO", 0)]
    + [("SMALL", n) for n in range(1, 16)]
    + [("RADIX", 10**k + delta) for k in range(3, 15) for delta in (-1, 0, 1)]
    + [("POW2", 2**k + delta)
       for k in (20, 24, 31, 32, 40, 48, 53, 63) for delta in (-1, 0, 1)]
    + [("MAX", MAX64 - n) for n in range(20)]
)

def main():
    path = Path(__file__).with_name("bigint_from_uint64_vectors.tsv")
    with path.open(encoding="utf-8", newline="") as handle:
        rows = list(csv.reader(handle, delimiter="\t"))
    assert len(EXPECTED) == len(rows) == 96
    seen = set()
    for i, (row, (wanted_group, wanted)) in enumerate(zip(rows, EXPECTED), 1):
        assert len(row) == 4, f"row {i}: four columns required"
        group, hexadecimal, decimal, successor = row
        assert group == wanted_group, f"row {i}: group"
        assert hexadecimal == format(wanted, "X"), f"row {i}: hex source"
        assert hexadecimal not in seen, f"row {i}: duplicate input"
        seen.add(hexadecimal)
        assert 0 <= wanted <= MAX64, f"row {i}: unsigned range"
        assert int(hexadecimal, 16) == wanted, f"row {i}: hex oracle"
        assert decimal == str(wanted), f"row {i}: decimal oracle"
        assert successor == str(wanted + 1), f"row {i}: successor oracle"
    assert len(seen) == 96
    assert Counter(row[0] for row in rows) == Counter(
        {"ZERO": 1, "SMALL": 15, "RADIX": 36, "POW2": 24, "MAX": 20}
    )
    assert any(int(row[1], 16) == 2**63 for row in rows)
    assert any(int(row[1], 16) == MAX64 for row in rows)
    print("Python-int BigFromUInt64: 96/96 distinct; 1 zero, 15 small, "
          "36 decimal-radix, 24 binary-boundary, 20 UInt64-max; "
          "planned Pascal checks=1152; 0 divergences")

if __name__ == "__main__":
    main()
