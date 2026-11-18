#!/usr/bin/env python3
"""Independent seven-case grind-kind oracle and FALSE fixture."""

import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "test" / "stage10_hidden_grind_7.false"


def kind(grind):
    assert 1 <= grind <= 7
    return 1 + (grind - 1) % 5


def build():
    lines = ["{ المرحلة 10: أنواع الحجر للعمليات السبع. }",
             '[~["STAGE10_HIDDEN_GRIND_FAILURE"10,0 0/]?]e:']
    cases = []
    for grind in range(1, 8):
        result = kind(grind)
        lines.append(f"z;d:{grind}a;!d;27h;!!v:")
        lines.append(f"v;{result}=e;!d;g;!{grind}=e;!")
        label = f"STAGE10_HIDDEN_GRIND_{grind}_OK"
        lines.append(f'"{label}"10,')
        cases.append({"grind": grind, "kind": result, "label": label})
    lines.extend(('"STAGE10_HIDDEN_GRIND_7_RESULTS_7_INPUTS_VERIFIED"10,',
                  "[z;0>][%z;1-z:]#"))
    return "\n".join(lines) + "\n", cases


def invalid(grind):
    assert grind in (0, 8)
    return "\n".join(("{ المرحلة 10: رفض رقم طحن خارج المجال. }",
                      f"z;d:{grind}a;!d;27h;!!v:",
                      '"STAGE10_INVALID_WRONGLY_ACCEPTED"10,',
                      "[z;0>][%z;1-z:]#")) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    program, cases = build()
    if args.write:
        FIXTURE.write_text(program, encoding="utf-8")
    assert FIXTURE.read_text(encoding="utf-8") == program
    assert [kind(g) for g in range(1, 8)] == [1, 2, 3, 4, 5, 1, 2]
    print(json.dumps({"project_id": "PC-BRANCH-FALSE-ARABIC", "stage": 10,
                      "native_evidence": False, "case_count": 7,
                      "result_assertions": 7, "input_assertions": 7,
                      "invalid_grind": [0, 8],
                      "fixture_sha256": hashlib.sha256(program.encode()).hexdigest(),
                      "cases": cases}, indent=2, sort_keys=True, ensure_ascii=False))


if __name__ == "__main__":
    main()
