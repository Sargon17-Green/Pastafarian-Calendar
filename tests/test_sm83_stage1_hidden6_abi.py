#!/usr/bin/env python3
"""Independent bigint k=5 oracle and bounded Native377 static ABI contract."""
from __future__ import annotations
import random
import re
from pathlib import Path
from test_sm83_stage1_sauce_oracle import FOUNDATION, M, compute_sauce

ROOT = Path(__file__).resolve().parents[1]
ROM = ROOT / "src/tests/calendar_hidden6_native_test.asm"
RUNTIME = ROOT / "src/runtime/calendar_hidden6.asm"
BOOT = ROOT / "src/boot.asm"
WORKFLOW = ROOT / ".github/workflows/canonical-names-lock.yml"


def save(x: int) -> int:
    return 1 + ((x - 1) % M)


def independent_k6(c: int, t: int) -> tuple[int, tuple[int, ...]]:
    assert -(1 << 31) <= c < 1 << 31
    assert -(1 << 31) <= t < 1 << 31
    a = -2*c if c < 0 else 2*c+1
    b = -2*t if t < 0 else 2*t+1
    distance = abs(t-c)+1
    direction = 1 if t < c else 2 if c == t else 3
    state = (17, 29, 43, 71, 101)
    # Independent simultaneous five-state integer recurrence, not ASM or goldens.
    for iteration in range(2, 7):
        w, barley, salt, bitter, red = state
        state = (
            save(w*w + 3*barley + iteration),
            save(barley*barley + 5*salt + w),
            save(salt*salt + 7*bitter + barley),
            save(bitter*bitter + 11*red + salt),
            save(red*red + 13*w + bitter),
        )
    x = save(a + 13*b + 19*distance + 26*(a+b) + 28*direction + sum(state))
    for round_number in range(1, 8):
        x = save(x*x + 3*x + state[(round_number-1) % 5] + round_number)
    return x, state


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
    output, stones = independent_k6(0, 0)
    assert len(parse_db("expected6", source)) == 16
    assert int.from_bytes(parse_db("expected6", source), "little") == output
    assert parse_db("expected6Stones", source) == b"".join(x.to_bytes(16, "little") for x in stones)
    rng = random.Random(0x5396)
    pairs = [(0, 0), (1, 2), (-1, -2), (-2, 1),
             (-(1 << 31), (1 << 31) - 1),
             ((1 << 31) - 1, -(1 << 31)),
             (-(1 << 31), -(1 << 31)),
             ((1 << 31) - 1, (1 << 31) - 1)]
    pairs.extend((rng.randrange(-(1 << 31), 1 << 31),
                  rng.randrange(-(1 << 31), 1 << 31)) for _ in range(64))
    for c, t in pairs:
        x, stones = independent_k6(c, t)
        assert 1 <= x <= M and all(1 <= s <= M for s in stones)
        assert x == compute_sauce(FOUNDATION+c, FOUNDATION+t).hidden[5], (c, t)
    asm = RUNTIME.read_text(encoding="utf-8")
    assert "CalendarHiddenDrop6::" in asm
    assert "call CalendarOrdinalValidate" in asm
    assert "call CalendarStoneTransitionRange" in source
    assert "call WorkCountsFromOffsets32" in asm
    assert "call Mul128x128" in asm and "call SaveWide256" in asm
    assert ".checkStone:" in asm and ".publish:" in asm
    assert "wCalendarStoneOutput:: ds 80" in BOOT.read_text(encoding="utf-8")
    assert "RunCalendarHidden6Bench::" in source
    assert "ld a, 121" in source and ".checkRejected:" in source
    assert "dmg-hidden6-native:" in WORKFLOW.read_text(encoding="utf-8")
    print("HOST_STAGE1_HIDDEN6=PASS independent_pairs=72 "
          "k6_stones=5 fixture_bytes=16 invalid_early_reject=YES "
          "signed32_endpoints=YES PyBoy_Native377=CI_REQUIRED "
          "hidden7_and_visible46=NOT_IMPLEMENTED", flush=True)


if __name__ == "__main__":
    main()
