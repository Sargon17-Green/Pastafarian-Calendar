#!/usr/bin/env python3
"""Independent bigint k=2 oracle and bounded Native373 static ABI contract."""
from __future__ import annotations
import random
import re
from pathlib import Path
from test_sm83_stage1_sauce_oracle import FOUNDATION, M, compute_sauce

ROOT = Path(__file__).resolve().parents[1]
ROM = ROOT / "src/tests/calendar_hidden2_native_test.asm"
RUNTIME = ROOT / "src/runtime/calendar_hidden2.asm"
BOOT = ROOT / "src/boot.asm"
WORKFLOW = ROOT / ".github/workflows/canonical-names-lock.yml"


def save(x: int) -> int:
    return 1 + ((x - 1) % M)


def independent_k2(c: int, t: int) -> tuple[int, tuple[int, ...]]:
    assert -(1 << 31) <= c < 1 << 31
    assert -(1 << 31) <= t < 1 << 31
    a = 2 * abs(c) + (c >= 0)
    b = 2 * abs(t) + (t >= 0)
    distance = abs(t - c) + 1
    direction = 1 if t < c else (2 if t == c else 3)
    first = (17, 29, 43, 71, 101)
    # Direct closed form for exactly the second five-stone state.
    stone = (
        save(first[0] ** 2 + 3 * first[1] + 2),
        save(first[1] ** 2 + 5 * first[2] + first[0]),
        save(first[2] ** 2 + 7 * first[3] + first[1]),
        save(first[3] ** 2 + 11 * first[4] + first[2]),
        save(first[4] ** 2 + 13 * first[0] + first[3]),
    )
    x = save(a + 5*b + 7*distance + 10*(a+b) + 12*direction + sum(stone))
    for r in range(7):
        x = save(x*x + 3*x + stone[r % 5] + r + 1)
    return x, stone


def parse_db(label: str, source: str) -> bytes:
    m = re.search(r"(?m)^\." + label + r":\s*\n((?:\s*db\s+[^\n]+\n?)+)", source)
    assert m, label
    return bytes(
        int(h.strip().removeprefix("$"), 16)
        for row in m.group(1).splitlines()
        for h in row.strip().removeprefix("db").split(",")
    )


def main() -> None:
    source = ROM.read_text(encoding="utf-8")
    output, stones = independent_k2(0, 0)
    assert len(parse_db("expected2", source)) == 16
    assert int.from_bytes(parse_db("expected2", source), "little") == output
    assert parse_db("expected2Stones", source) == b"".join(x.to_bytes(16, "little") for x in stones)
    rng = random.Random(0x5392)
    pairs = [(0, 0), (1, 2), (-1, -2), (-2, 1),
             (-(1 << 31), (1 << 31) - 1),
             ((1 << 31) - 1, -(1 << 31)),
             (-(1 << 31), -(1 << 31)),
             ((1 << 31) - 1, (1 << 31) - 1)]
    pairs.extend((rng.randrange(-(1 << 31), 1 << 31),
                  rng.randrange(-(1 << 31), 1 << 31)) for _ in range(64))
    for c, t in pairs:
        x, stones = independent_k2(c, t)
        assert 1 <= x <= M and all(1 <= s <= M for s in stones)
        assert x == compute_sauce(FOUNDATION+c, FOUNDATION+t).hidden[1], (c, t)
    asm = RUNTIME.read_text(encoding="utf-8")
    assert "CalendarHiddenDrop2::" in asm
    assert "call CalendarOrdinalValidate" in asm
    assert "call WorkCountsFromOffsets32" in asm
    assert "call Mul128x128" in asm and "call SaveWide256" in asm
    assert ".checkStone:" in asm and ".publish:" in asm
    assert "wCalendarStoneOutput:: ds 80" in BOOT.read_text(encoding="utf-8")
    assert "RunCalendarHidden2Bench::" in source
    assert "ld a, 117" in source and ".checkRejected:" in source
    assert "dmg-hidden2-native:" in WORKFLOW.read_text(encoding="utf-8")
    print("HOST_STAGE1_HIDDEN2=PASS independent_pairs=72 "
          "k2_stones=5 fixture_bytes=16 invalid_early_reject=YES "
          "signed32_endpoints=YES PyBoy_Native373=CI_REQUIRED "
          "hidden3_7_and_visible46=NOT_IMPLEMENTED", flush=True)


if __name__ == "__main__":
    main()
