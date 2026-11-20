#!/usr/bin/env python3
"""Independent Python integer reference for i=2..46, Native365..370 sample gate.

ROM fixture values are compared only as postconditions, never lookup inputs.
All generated test states are immutable tuples; no existing Native i=46 claim.
"""
from __future__ import annotations

from pathlib import Path
from test_sm83_stage1_stone_transition_abi import MODULUS, canonical, stones_independent, table

ROOT = Path(__file__).resolve().parents[1]
NATIVE = ROOT / "src/tests/calendar_stone_range_test.asm"
RUNTIME = ROOT / "src/runtime/calendar_stone_transition.asm"
BOOT = ROOT / "src/boot.asm"


def oracle_range(source: tuple[int, ...], target: int) -> tuple[int, ...]:
    assert len(source) == 5
    assert 2 <= target <= 46
    current = tuple(source)
    for i in range(2, target + 1):
        current = stones_independent(current, i)
    return current


def main() -> None:
    assert "CalendarStoneTransitionRange::" in RUNTIME.read_text(encoding="utf-8")
    assert "wCalendarStoneScratch:: ds 80" in BOOT.read_text(encoding="utf-8")
    asm = NATIVE.read_text(encoding="utf-8")
    assert "RunCalendarStoneRangeTests::" in asm
    assert "ld a, 109" in asm and "ld a, 114" in asm
    seed = (17, 29, 43, 71, 101)
    f3 = table(asm, "expected3")
    f5 = table(asm, "expected5")
    assert f3 == oracle_range(seed, 3)
    assert f5 == oracle_range(seed, 5)
    checks = 10
    states = (
        (1,)*5,
        (MODULUS,)*5,
        (MODULUS-1, MODULUS, 1, 2, 3),
        (1 << 126, (1 << 125) + 1, (1 << 64) + 3, (1 << 63) + 5, 7),
    )
    for state in (*states, *(tuple(1 + (n*n*(j+3) + 97*j) % MODULUS
                              for j in range(5)) for n in range(32))):
        before = tuple(state)
        for target in (2, 3, 5, 46):
            result = oracle_range(before, target)
            assert all(1 <= value <= MODULUS for value in result)
            assert before == tuple(state), "source mutated"
            # Verify that the range result equals a separate repeated-step reference.
            direct = before
            for iteration in range(2, target + 1):
                w, b, s, x, r = direct
                direct = tuple(map(canonical, (
                    w*w + 3*b + iteration,
                    b*b + 5*s + w,
                    s*s + 7*x + b,
                    x*x + 11*r + s,
                    r*r + 13*w + x,
                )))
            assert result == direct
            checks += len(result)
    print(
        f"HOST_STAGE1_STONES_RANGE=PASS fixture_fields=10 "
        f"independent_Python_int_checks={checks} "
        "states=36 targets=2,3,5,46 source_immutable=YES "
        "Native365..370=SAMPLED_3_5 i46_NATIVE=NOT_EXECUTED",
        flush=True,
    )


if __name__ == "__main__":
    main()
