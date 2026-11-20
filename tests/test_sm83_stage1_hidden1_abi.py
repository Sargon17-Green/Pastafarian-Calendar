#!/usr/bin/env python3
"""Independent mathematical reference for first hidden drop, Native372 candidate.

Only k=1; no assertion that k=2..7 or visible drops are implemented.
Expected ROM bytes are observations, not inputs to either reference oracle.
"""
from __future__ import annotations
import random
import re
from pathlib import Path
from test_sm83_stage1_sauce_oracle import compute_sauce, FOUNDATION

M = (1 << 127) - 1
ROOT = Path(__file__).resolve().parents[1]
ROM_TEST = ROOT / "src/tests/calendar_hidden1_native_test.asm"
RUNTIME = ROOT / "src/runtime/calendar_hidden1.asm"
BOOT = ROOT / "src/boot.asm"
WORKFLOW = ROOT / ".github/workflows/canonical-names-lock.yml"
STONES = (17, 29, 43, 71, 101)


def independently_compute(offset_c: int, offset_t: int) -> int:
    """Closed expression of step E for k=1, evaluated with Python big integers."""
    assert -(2**31) <= offset_c < 2**31
    assert -(2**31) <= offset_t < 2**31
    a = 2 * abs(offset_c) + (offset_c >= 0)
    b = 2 * abs(offset_t) + (offset_t >= 0)
    direction = 1 if offset_t < offset_c else (2 if offset_t == offset_c else 3)
    counts = (a, b, abs(offset_t - offset_c) + 1, a + b, direction)
    polynomial = sum(p*q for p, q in zip((1, 3, 4, 6, 8), counts))
    current = (polynomial + sum(STONES) - 1) % M + 1
    for r in range(1, 8):
        chosen = STONES[(r - 1) % 5]
        current = (pow(current, 2, M) + 3*current + chosen + r - 1) % M + 1
    return current


def main() -> None:
    source = ROM_TEST.read_text(encoding="utf-8")
    match = re.search(r"(?m)^\.expected1:\s*\n\s*db\s+([^\n]+)", source)
    assert match is not None, "missing Native output postcondition"
    raw = bytes(int(s.strip().removeprefix("$"), 16) for s in match.group(1).split(","))
    assert len(raw) == 16
    expected = independently_compute(0, 0)
    assert int.from_bytes(raw, "little") == expected, "independent fixture mismatch"
    assert 1 <= expected <= M
    pairs = [(0, 0), (1, 2), (-1, -2), (-2, 1),
             (-2**31, 2**31-1), (2**31-1, -2**31),
             (-2**31, -2**31), (2**31-1, 2**31-1)]
    rng = random.Random(0x5391)
    pairs.extend((rng.randrange(-2**31, 2**31),
                  rng.randrange(-2**31, 2**31)) for _ in range(64))
    for c, t in pairs:
        actual = independently_compute(c, t)
        assert 1 <= actual <= M
        assert actual == compute_sauce(FOUNDATION+c, FOUNDATION+t).hidden[0], (c,t)
    asm = RUNTIME.read_text(encoding="utf-8")
    assert "CalendarHiddenDrop1::" in asm
    assert "call CalendarOrdinalValidate" in asm
    assert "call WorkCountsFromOffsets32" in asm
    assert "call Mul128x128" in asm and "call SaveWide256" in asm
    assert ".publish:" in asm and ".stoneSeed:" in asm
    assert "wCalendarHiddenOutput:: ds 16" in BOOT.read_text(encoding="utf-8")
    assert "RunCalendarHidden1Bench::" in source
    assert "ld a, 116" in source and ".checkIdleOutput:" in source
    assert "dmg-hidden1-native:" in WORKFLOW.read_text(encoding="utf-8")
    print("HOST_STAGE1_HIDDEN1=PASS independent_cases=72 fixture_bytes=16 "
          "signed32_edges=YES floor_mod_M=YES count_direction=CHECKED "
          "Native372=CI_REQUIRED later_hidden6_and_visible46=NOT_IMPLEMENTED",
          flush=True)


if __name__ == "__main__":
    main()
