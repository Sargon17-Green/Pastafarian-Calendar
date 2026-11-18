#!/usr/bin/env python3
"""Independent dayCount oracle and deterministic FALSE fixture for Stage 3.

This checks arithmetic and fixture bytes only. Native evidence requires the
original pinned FALSE interpreter to execute the generated fixture.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import random
from pathlib import Path

EPOCH = 15055671
ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "test" / "stage03_daycount_13.false"
ANCHORS = (
    ("EPOCH_MINUS_TWO", EPOCH - 2),
    ("EPOCH_MINUS_ONE", EPOCH - 1),
    ("EPOCH", EPOCH),
    ("EPOCH_PLUS_ONE", EPOCH + 1),
    ("EPOCH_PLUS_TWO", EPOCH + 2),
    ("ZERO_DAY", 0),
    ("NEGATIVE_ONE_DAY", -1),
    ("ONE_DAY", 1),
    ("EPOCH_MINUS_2_31", EPOCH - (1 << 31)),
    ("EPOCH_PLUS_2_31", EPOCH + (1 << 31)),
    ("EPOCH_MINUS_2_127", EPOCH - (1 << 127)),
    ("EPOCH_PLUS_2_127", EPOCH + (1 << 127)),
    ("NEGATIVE_EPOCH", -EPOCH),
)


def count(day: int) -> int:
    offset = day - EPOCH
    return -2 * offset if offset < 0 else 2 * offset + 1


def inverse(rank: int) -> int:
    assert rank >= 1
    return EPOCH + (rank - 1) // 2 if rank & 1 else EPOCH - rank // 2


def literal(value: int, variable: str) -> list[str]:
    """Construct exact BigInt from base-512 digits using Stage 1 primitives."""
    assert variable in {"p", "m"}
    if -(1 << 31) < value < (1 << 31):
        cell = f"{-value}_" if value < 0 else str(value)
        return [f"z;b:{cell}a;!b;0h;!!{variable}:"]
    magnitude = abs(value)
    digits = []
    while magnitude:
        digits.append(magnitude % 512)
        magnitude //= 512
    digits.reverse()
    lines = [f"z;b:{digits[0]}a;!b;0h;!!{variable}:"]
    for digit in digits[1:]:
        lines.append(f"z;b:{variable};a;!x;a;!b;14h;!!{variable}:")
        if digit:
            lines.append(f"z;b:{digit}a;!b;0h;!!e:")
            lines.append(f"z;b:{variable};a;!e;a;!b;9h;!!{variable}:")
    if value < 0:
        lines.append(f"z;b:{variable};a;!b;8h;!!{variable}:")
    return lines


def build() -> tuple[str, list[dict[str, str | int]]]:
    lines = [
        "{ المرحلة 3: تحقق يوم الترتيب من الإنتاج دون تحميل المرجع المعياري. }",
        "{ الفشل يخرج برمز غير صفري قبل علامة الحالة أو علامة النهاية. }",
        '[~["STAGE3_DAYCOUNT_FAILURE"10,0 0/]?]f:',
        "z;b:512a;!b;0h;!!x: { أساس بناء أعداد الاختبار الكبيرة. }",
    ]
    cases: list[dict[str, str | int]] = []
    for index, (name, day) in enumerate(ANCHORS):
        expected = count(day)
        assert expected >= 1 and inverse(expected) == day
        label = f"STAGE3_DAYCOUNT_CASE_{index:02d}_OK"
        lines.append(f"{{ {name}: day={day}, rank={expected}. }}")
        lines.extend(literal(day, "p"))
        lines.extend(literal(expected, "m"))
        lines.append("p;j;!y:z;b:y;a;!m;a;!b;5h;!!0=f;!")
        lines.append(f'"{label}"10,')
        cases.append({"index": index, "name": name, "day": str(day),
                      "expected": str(expected), "label": label})
    lines.extend(('"STAGE3_DAYCOUNT_13_CHECKS_VERIFIED"10,',
                  "{ استعادة الكومة بعد إنجاز كل المقارنات. }",
                  "[z;0>][%z;1-z:]#"))
    return "\n".join(lines) + "\n", cases


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="write the exact fixture")
    args = parser.parse_args()
    program, cases = build()
    if args.write:
        FIXTURE.write_text(program, encoding="utf-8")
    assert FIXTURE.read_text(encoding="utf-8") == program, "fixture byte drift"
    assert len(cases) == len({v for _, v in ANCHORS}) == 13
    rng = random.Random(20261118)
    for i in range(384):
        day = EPOCH + rng.randrange(-(1 << 192), 1 << 192)
        if i % 8 == 0:
            day = EPOCH + (i // 8 - 24) * (1 << 127)
        rank = count(day)
        assert rank >= 1 and inverse(rank) == day
        assert (rank & 1) == int(day >= EPOCH)
    print(json.dumps({
        "project_id": "PC-BRANCH-FALSE-ARABIC",
        "stage": "3_DAYCOUNT",
        "native_evidence": False,
        "epoch": EPOCH,
        "anchor_cases": cases,
        "anchor_count": 13,
        "seeded_property_cases": 384,
        "fixture_sha256": hashlib.sha256(program.encode("utf-8")).hexdigest(),
    }, ensure_ascii=False, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
