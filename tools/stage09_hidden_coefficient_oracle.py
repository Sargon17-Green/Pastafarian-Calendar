#!/usr/bin/env python3
"""Independent 7x4 coefficient oracle and generated FALSE Native fixture."""

import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "test" / "stage09_hidden_coefficient_28.false"


def expected(k, column):
    assert 1 <= k <= 7 and 1 <= column <= 4
    return (2 * k + 1, 3 * k + 1, 4 * k + 2, 4 * k + 4)[column - 1]


def build():
    lines = ["{ المرحلة 9: جميع معاملات القطرات الخفية السبعة والأعمدة الأربعة. }",
             '[~["STAGE9_HIDDEN_COEFFICIENT_FAILURE"10,0 0/]?]e:']
    cases = []
    for k in range(1, 8):
        for column in range(1, 5):
            value = expected(k, column)
            lines.append(f"z;d:{k}a;!{column}a;!d;26h;!!v:")
            lines.append(f"v;{value}=e;!d;g;!{k}=e;!d;1+g;!{column}=e;!")
            label = f"STAGE9_HIDDEN_CASE_{k}_{column}_OK"
            lines.append(f'"{label}"10,')
            cases.append({"k": k, "column": column, "expected": value, "label": label})
    lines.extend(('"STAGE9_HIDDEN_28_RESULTS_56_INPUTS_VERIFIED"10,',
                  "[z;0>][%z;1-z:]#"))
    return "\n".join(lines) + "\n", cases


def invalid(k, column):
    assert (k, column) in ((0, 1), (8, 1), (1, 0), (1, 5))
    return "\n".join(("{ المرحلة 9: رفض فهرس خارج النطاق. }",
                      f"z;d:{k}a;!{column}a;!d;26h;!!v:",
                      '"STAGE9_INVALID_WRONGLY_ACCEPTED"10,',
                      "[z;0>][%z;1-z:]#")) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    program, cases = build()
    if args.write:
        FIXTURE.write_text(program, encoding="utf-8")
    assert FIXTURE.read_text(encoding="utf-8") == program
    assert len(cases) == 28 and len({(c["k"], c["column"]) for c in cases}) == 28
    assert [expected(1, c) for c in range(1, 5)] == [3, 4, 6, 8]
    assert [expected(7, c) for c in range(1, 5)] == [15, 22, 30, 32]
    for column, difference in enumerate((2, 3, 4, 4), 1):
        for k in range(1, 7):
            assert expected(k + 1, column) - expected(k, column) == difference
    print(json.dumps({"project_id": "PC-BRANCH-FALSE-ARABIC", "stage": 9,
                      "native_evidence": False, "case_count": 28,
                      "result_assertions": 28, "input_assertions": 56,
                      "invalid_indices": [[0, 1], [8, 1], [1, 0], [1, 5]],
                      "fixture_sha256": hashlib.sha256(program.encode()).hexdigest(),
                      "cases": cases}, indent=2, sort_keys=True, ensure_ascii=False))


if __name__ == "__main__":
    main()
