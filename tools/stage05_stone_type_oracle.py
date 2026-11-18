#!/usr/bin/env python3
"""Build the independent Stage 5 direct-table oracle and Native FALSE fixture."""

import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "test" / "stage05_stone_type_13.false"
ROW_VARIABLES = "cdefijlmnoprx"
assert len(ROW_VARIABLES) == 13
CASES = ((1, 1), (1, 5), (2, 2), (12, 5), (13, 3), (14, 1),
         (25, 4), (27, 2), (32, 3), (40, 5), (45, 4), (46, 5), (46, 1))
NEGATIVE = (("row_0", 0, 1, "E_STONE_ROW"),
            ("row_47", 47, 1, "E_STONE_ROW"),
            ("kind_0", 1, 0, "E_STONE_KIND"),
            ("kind_6", 1, 6, "E_STONE_KIND"),
            ("short_kind_4", 13, 4, "E_STONE_KIND"))


def value(pattern, kind):
    if (pattern, kind) == (0, 1):
        return 0
    if (pattern, kind) in ((0, 5), (5, 3), (6, 5), (11, 5)):
        return (-1 if pattern % 2 else 1) * ((1 << 127) + 101 * pattern + kind)
    return (-1 if (pattern + kind) % 2 else 1) * (1_000_003 * (pattern + 1) + 37 * kind)


def cell(n):
    return f"{-n}_" if n < 0 else str(n)


def literal(n, destination):
    assert destination in "suvwy"
    if -(1 << 31) < n < (1 << 31):
        return [f"z;b:{cell(n)}a;!b;0h;!!{destination}:"]
    digits = []
    positive = abs(n)
    while positive:
        digits.append(positive % 512)
        positive //= 512
    digits.reverse()
    out = [f"z;b:{digits[0]}a;!b;0h;!!{destination}:"]
    for digit in digits[1:]:
        out.append(f"z;b:{destination};a;!q;a;!b;14h;!!{destination}:")
        if digit:
            out.append(f"z;b:{digit}a;!b;0h;!!t:")
            out.append(f"z;b:{destination};a;!t;a;!b;9h;!!{destination}:")
    if n < 0:
        out.append(f"z;b:{destination};a;!b;8h;!!{destination}:")
    return out


def prefix():
    lines = ["{ المرحلة 5: جدول اصطناعي مستقل من 46 صفاً و13 نمطاً. }",
             "z;b:512a;!b;0h;!!q: { أساس كتابة الأعداد الكبيرة للاختبار. }"]
    temporaries = "suvwy"
    for pattern, var in enumerate(ROW_VARIABLES):
        kinds = 3 if pattern == 12 else 5
        for kind in range(1, kinds + 1):
            lines.extend(literal(value(pattern, kind), temporaries[kind - 1]))
        lines.append(f"z;{var}:{kinds}a;!" + "".join(f"{v};a;!" for v in temporaries[:kinds]))
    lines.append("z;w:46a;!" + "".join(f"{ROW_VARIABLES[i % 13]};a;!" for i in range(46)))
    lines.append('[~["STAGE5_STONE_FAILURE"10,0 0/]?]y:')
    return lines


def call(row, kind):
    return f"z;b:w;a;!{cell(row)}a;!{cell(kind)}a;!b;21h;!!u:"


def build():
    lines = prefix()
    cases = []
    for index, (row, kind) in enumerate(CASES):
        pattern = (row - 1) % 13
        row_var = ROW_VARIABLES[pattern]
        expected = value(pattern, kind)
        lines.append(f"{{ حالة {index}: row={row}, kind={kind}, value={expected}. }}")
        lines.append(f"{row_var};{kind}+g;!v:")
        lines.append(call(row, kind))
        lines.append("u;v;=y;! { هوية المقبض. }")
        lines.extend(literal(expected, "s"))
        lines.append("z;b:u;a;!s;a;!b;5h;!!0=y;! { المقارنة العددية المستقلة. }")
        lines.append("w;g;!46=y;!" + f"{row_var};g;!{3 if pattern == 12 else 5}=y;!")
        label = f"STAGE5_STONE_CASE_{index:02d}_OK"
        lines.append(f'"{label}"10,')
        cases.append({"index": index, "row": row, "kind": kind,
                      "value": str(expected), "pattern": pattern, "label": label})
    lines.extend(('"STAGE5_STONE_13_VALUES_13_HANDLES_VERIFIED"10,',
                  "[z;0>][%z;1-z:]#"))
    return "\n".join(lines) + "\n", cases


def negative(label):
    match = next(n for n in NEGATIVE if n[0] == label)
    return "\n".join(prefix() + [call(match[1], match[2]),
                                  '"STAGE5_NEGATIVE_WRONGLY_ACCEPTED"10,',
                                  "[z;0>][%z;1-z:]#"]) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    program, cases = build()
    if args.write:
        FIXTURE.write_text(program, encoding="utf-8")
    assert FIXTURE.read_text(encoding="utf-8") == program
    assert len(CASES) == len(set(CASES)) == 13
    assert all(1 <= row <= 46 and 1 <= kind <= (3 if (row - 1) % 13 == 12 else 5)
               for row, kind in CASES)
    print(json.dumps({"project_id": "PC-BRANCH-FALSE-ARABIC", "stage": 5,
                      "native_evidence": False, "row_count": 46, "distinct_row_patterns": 13,
                      "case_count": 13, "value_assertions": 13, "handle_assertions": 13,
                      "structural_assertions": 26, "negative_cases": [list(n) for n in NEGATIVE],
                      "fixture_sha256": hashlib.sha256(program.encode()).hexdigest(),
                      "cases": cases}, indent=2, sort_keys=True, ensure_ascii=False))


if __name__ == "__main__":
    main()
