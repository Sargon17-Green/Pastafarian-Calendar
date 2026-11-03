#!/usr/bin/env python3
"""Independent reference validation for Object Pascal Stage 1 signed BigInt vectors.

Only Python's built-in arbitrary-precision integers are used. This is not
authentication or reconstruction of either historical October patch.
"""
import csv
from pathlib import Path

VECTORS = Path(__file__).with_name("bigint_signed_arithmetic_vectors.tsv")
EXPECTED_CASES = 64

def main() -> int:
    with VECTORS.open(encoding="utf-8", newline="") as file:
        rows = list(csv.reader(file, delimiter="\t"))
    if len(rows) != EXPECTED_CASES:
        raise SystemExit(f"FALHA: esperado {EXPECTED_CASES} vetores, obtido {len(rows)}")
    seen = set()
    signs = set()
    max_digits = 0
    for index, row in enumerate(rows, 1):
        if len(row) != 6:
            raise SystemExit(f"FALHA: linha {index} contém {len(row)} campos")
        a_text, b_text, expected_add, expected_sub, expected_mul, expected_cmp = row
        a, b = int(a_text), int(b_text)
        if (a_text, b_text) in seen:
            raise SystemExit(f"FALHA: vetor duplicado na linha {index}")
        seen.add((a_text, b_text))
        signs.add((a > 0) - (a < 0))
        signs.add((b > 0) - (b < 0))
        max_digits = max(max_digits, len(a_text.lstrip("-")), len(b_text.lstrip("-")))
        actual = (str(a + b), str(a - b), str(a * b), str((a > b) - (a < b)))
        expected = (expected_add, expected_sub, expected_mul, expected_cmp)
        if actual != expected:
            raise SystemExit(f"FALHA: oracle independente na linha {index}: {actual} != {expected}")
    if signs != {-1, 0, 1} or max_digits < 128:
        raise SystemExit("FALHA: cobertura de sinais ou precisão insuficiente")
    print(f"Oracle Python: {len(rows)} casos; {len(rows) * 4} referências verificadas; 0 falhas.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
