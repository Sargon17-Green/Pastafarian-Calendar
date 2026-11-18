#!/usr/bin/env python3
"""Independent Stage 4 five-field workCounts oracle and FALSE fixture builder.

Arithmetic is Python integer arithmetic; the fixture only encodes inputs and
expected results through already accepted Stage 1 BigInt primitives.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import random
from pathlib import Path

EPOCH = 15055671
ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "test" / "stage04_workcounts_13.false"
WIDE = 1 << 127
PAIRS = (
    ("EQUAL_EPOCH", EPOCH, EPOCH),
    ("PREVIOUS_TO_EPOCH", EPOCH - 1, EPOCH),
    ("EPOCH_TO_PREVIOUS", EPOCH, EPOCH - 1),
    ("EPOCH_TO_NEXT", EPOCH, EPOCH + 1),
    ("NEXT_TO_EPOCH", EPOCH + 1, EPOCH),
    ("ZERO_TO_NEG_ONE", 0, -1),
    ("NEG_ONE_TO_ZERO", -1, 0),
    ("CROSS_EPOCH_FORWARD", EPOCH - 2, EPOCH + 2),
    ("CROSS_EPOCH_REVERSE", EPOCH + 2, EPOCH - 2),
    ("WIDE_EQUAL", EPOCH + WIDE, EPOCH + WIDE),
    ("WIDE_FORWARD", EPOCH - WIDE, EPOCH + WIDE),
    ("WIDE_REVERSE", EPOCH + WIDE, EPOCH - WIDE),
    ("WIDE_NEGATIVE_ADJACENT", -WIDE, 1 - WIDE),
)


def day_count(day: int) -> int:
    delta = day - EPOCH
    return -2 * delta if delta < 0 else 2 * delta + 1


def fields(calculation: int, target: int) -> tuple[int, int, int, int, int]:
    first = day_count(calculation)
    second = day_count(target)
    return (first, second, abs(target - calculation) + 1,
            first + second, 1 if target == calculation else 2 if target > calculation else 3)


def cell(n: int) -> str:
    return f"{-n}_" if n < 0 else str(n)


def literal(n: int, destination: str) -> list[str]:
    assert destination in {"u", "w", "s"}
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


def build() -> tuple[str, list[dict[str, object]]]:
    lines = [
        "{ المرحلة 4: فحص خمسة حقول مستقلة لكل زوج من الأيام. }",
        '[~["STAGE4_WORKCOUNTS_FAILURE"10,0 0/]?]e:',
        "z;b:512a;!b;0h;!!q: { أساس بناء القيم الكبيرة للاختبار. }",
    ]
    cases: list[dict[str, object]] = []
    for index, (name, calculation, target) in enumerate(PAIRS):
        expected = fields(calculation, target)
        label = f"STAGE4_WORKCOUNTS_CASE_{index:02d}_OK"
        lines.append(f"{{ {name}: C={calculation}, T={target}. }}")
        lines.extend(literal(calculation, "u"))
        lines.extend(literal(target, "w"))
        lines.append("u;d:w;v: { حفظ مقبضي الإدخال لفحص عدم تغيّرهما. }")
        lines.append("z;b:u;a;!w;a;!b;f;!l:")
        lines.extend(literal(calculation, "s"))
        lines.append("z;b:d;a;!s;a;!b;5h;!!0=e;!")
        lines.extend(literal(target, "s"))
        lines.append("z;b:v;a;!s;a;!b;5h;!!0=e;!")
        for field_index, value in enumerate(expected[:4], 1):
            lines.append(f"z;b:l;a;!{field_index}a;!b;x;!y:")
            lines.extend(literal(value, "s"))
            lines.append("z;b:y;a;!s;a;!b;5h;!!0=e;!")
        lines.append(f"z;b:l;a;!5a;!b;x;!{expected[4]}-0=e;!")
        lines.append(f'"{label}"10,')
        cases.append({"index": index, "name": name, "calculation": str(calculation),
                      "target": str(target), "expected": [str(v) for v in expected], "label": label})
    lines.extend(('"STAGE4_WORKCOUNTS_65_FIELDS_26_INPUTS_VERIFIED"10,',
                  "{ تفريغ الكومة بعد كل الفحوص. }", "[z;0>][%z;1-z:]#"))
    return "\n".join(lines) + "\n", cases


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    program, cases = build()
    if args.write:
        FIXTURE.write_text(program, encoding="utf-8")
    assert FIXTURE.read_text(encoding="utf-8") == program
    assert len(cases) == 13 and len({(c, t) for _, c, t in PAIRS}) == 13
    rng = random.Random(20261118 ^ 4)
    for i in range(384):
        calculation = rng.randrange(-(1 << 192), 1 << 192)
        target = rng.randrange(-(1 << 192), 1 << 192)
        if i % 8 == 0:
            calculation = EPOCH + (i - 192) * WIDE
            target = EPOCH - (i - 192) * WIDE
        a = fields(calculation, target)
        b = fields(target, calculation)
        assert a[0] == b[1] and a[1] == b[0]
        assert a[2:4] == b[2:4]
        assert (a[4], b[4]) in ((1, 1), (2, 3), (3, 2))
        assert a[2] >= 1 and a[3] == a[0] + a[1]
    print(json.dumps({"project_id": "PC-BRANCH-FALSE-ARABIC", "stage": "4_WORKCOUNTS",
                      "native_evidence": False, "epoch": EPOCH, "case_count": 13,
                      "field_assertions": 65, "input_integrity_assertions": 26,
                      "seeded_property_pairs": 384,
                      "fixture_sha256": hashlib.sha256(program.encode()).hexdigest(),
                      "cases": cases}, ensure_ascii=False, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
