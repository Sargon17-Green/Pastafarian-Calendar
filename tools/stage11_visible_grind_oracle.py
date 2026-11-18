#!/usr/bin/env python3
"""Prime-derived independent 10x5 visible grind oracle and FALSE fixture."""

import argparse
import hashlib
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "test" / "stage11_visible_grind_50.false"
PRIMES = [n for n in range(3, 44)
          if all(n % divisor for divisor in range(2, math.isqrt(n) + 1))]
assert len(PRIMES) == 13 and PRIMES[0] == 3 and PRIMES[-1] == 43


def cell(grind, column):
    assert 1 <= grind <= 10 and 1 <= column <= 5
    if column == 5:
        return (grind - 1) % 5 + 1
    return PRIMES[grind + column - 2]


def build():
    lines = ["{ المرحلة 11: القيم الخمس لكل طحن مرئي. }",
             '[~["STAGE11_VISIBLE_GRIND_FAILURE"10,0 0/]?]e:']
    cases = []
    for grind in range(1, 11):
        for column in range(1, 6):
            value = cell(grind, column)
            lines.append(f"z;d:{grind}a;!{column}a;!d;28h;!!v:")
            lines.append(f"v;{value}=e;!d;g;!{grind}=e;!d;1+g;!{column}=e;!")
            label = f"STAGE11_VISIBLE_CASE_{grind:02d}_{column}_OK"
            lines.append(f'"{label}"10,')
            cases.append({"grind": grind, "column": column, "expected": value, "label": label})
    lines.extend(('"STAGE11_VISIBLE_50_RESULTS_100_INPUTS_VERIFIED"10,',
                  "[z;0>][%z;1-z:]#"))
    return "\n".join(lines) + "\n", cases


def invalid(grind, column):
    assert (grind, column) in ((0, 1), (11, 1), (1, 0), (1, 6))
    return "\n".join(("{ المرحلة 11: رفض فهرس مرئي غير صالح. }",
                      f"z;d:{grind}a;!{column}a;!d;28h;!!v:",
                      '"STAGE11_INVALID_WRONGLY_ACCEPTED"10,',
                      "[z;0>][%z;1-z:]#")) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    program, cases = build()
    if args.write:
        FIXTURE.write_text(program, encoding="utf-8")
    assert FIXTURE.read_text(encoding="utf-8") == program
    assert len(cases) == 50 and len({(c["grind"], c["column"]) for c in cases}) == 50
    assert [cell(1, c) for c in range(1, 6)] == [3, 5, 7, 11, 1]
    assert [cell(10, c) for c in range(1, 6)] == [31, 37, 41, 43, 5]
    for grind in range(1, 10):
        for column in range(1, 4):
            assert cell(grind, column + 1) == cell(grind + 1, column)
    print(json.dumps({"project_id": "PC-BRANCH-FALSE-ARABIC", "stage": 11,
                      "native_evidence": False, "case_count": 50,
                      "result_assertions": 50, "input_assertions": 100,
                      "invalid_indices": [[0, 1], [11, 1], [1, 0], [1, 6]],
                      "fixture_sha256": hashlib.sha256(program.encode()).hexdigest(),
                      "cases": cases}, indent=2, sort_keys=True, ensure_ascii=False))


if __name__ == "__main__":
    main()
