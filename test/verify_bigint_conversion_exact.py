#!/usr/bin/env python3
"""Stage 1 independent oracle for exact Int64 and UInt32 BigInt conversions.

Python arithmetic does not import or replicate the Pascal digit algorithms.
The checked TSV and its row/check counts are locked to this test contract.
Historical October patch provenance is not asserted.
"""
import csv
import re
from collections import Counter
from pathlib import Path

EXPECTED_ROWS = 418
EXPECTED_CHECKS = 752
EXPECTED_DISTRIBUTION = {"Iok": 124, "Ierr": 85, "Uok": 43, "Uerr": 166}
INT64_MIN = -(1 << 63)
INT64_MAX = (1 << 63) - 1
UINT32_MAX = (1 << 32) - 1
SOURCE = Path(__file__).with_name("bigint_conversion_exact_vectors.tsv")

def main():
    counts = Counter()
    seen = set()
    with SOURCE.open("r", encoding="utf-8", newline="") as stream:
        entries = list(csv.reader(stream, delimiter="\t"))
    for n, fields in enumerate(entries, 1):
        if len(fields) != 3:
            raise AssertionError(f"row {n}: 3 TSV fields required")
        kind, decimal, expected = fields
        if kind not in ("I", "U") or re.fullmatch(r"-?[0-9]+", decimal) is None:
            raise AssertionError(f"row {n}: malformed kind or decimal")
        if (kind, decimal) in seen:
            raise AssertionError(f"row {n}: duplicate input")
        seen.add((kind, decimal))
        number = int(decimal)
        valid = (INT64_MIN <= number <= INT64_MAX) if kind == "I" else (0 <= number <= UINT32_MAX)
        expected_from_oracle = str(number) if valid else "ERangeError"
        if expected != expected_from_oracle:
            raise AssertionError(f"row {n}: expected={expected!r}, oracle={expected_from_oracle!r}")
        counts[kind + ("ok" if valid else "err")] += 1
    if len(entries) != EXPECTED_ROWS or dict(counts) != EXPECTED_DISTRIBUTION:
        raise AssertionError(f"count mismatch: {len(entries)}, {dict(counts)}")
    assertions = 3 * (counts["Iok"] + counts["Uok"]) + counts["Ierr"] + counts["Uerr"]
    if assertions != EXPECTED_CHECKS:
        raise AssertionError(f"assertion budget mismatch: {assertions}")
    print(f"Oracle Python conversoes: {len(entries)} vetores; {assertions} verificacoes esperadas; 0 divergencias.")

if __name__ == "__main__":
    main()
