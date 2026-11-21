#!/usr/bin/env python3
"""Independent Python integer visible-i1 oracle; isolated Native379 contract.

Does not derive the candidate's output from ten golden vectors, assembly
instructions, or any previously staged fixture. Prior sauce oracle is used
only for an independent parity crosscheck after calculating the result.
"""
from __future__ import annotations

import random
import re
from pathlib import Path
from test_sm83_stage1_sauce_oracle import FOUNDATION, M, compute_sauce

ROOT = Path(__file__).resolve().parents[1]
ROM = ROOT / "src/tests/calendar_visible1_native_test.asm"
RUNTIME = ROOT / "src/runtime/calendar_visible1.asm"
BOOT = ROOT / "src/boot.asm"
WORKFLOW = ROOT / ".github/workflows/canonical-names-lock.yml"
INITIAL = (17, 29, 43, 71, 101)
GRIND = (
    (3, 5, 7, 11, 0), (5, 7, 11, 13, 1),
    (7, 11, 13, 17, 2), (11, 13, 17, 19, 3),
    (13, 17, 19, 23, 4), (17, 19, 23, 29, 0),
    (19, 23, 29, 31, 1), (23, 29, 31, 37, 2),
    (29, 31, 37, 41, 3), (31, 37, 41, 43, 4),
    (37, 41, 43, 47, 0),
)


def canonical(n: int) -> int:
    return ((n - 1) % M) + 1


def work(c: int, t: int) -> tuple[int, int, int, int, int]:
    assert -(1 << 31) <= c < 1 << 31 and -(1 << 31) <= t < 1 << 31
    a = 2 * abs(c) if c < 0 else 2 * c + 1
    b = 2 * abs(t) if t < 0 else 2 * t + 1
    return (a, b, abs(t - c) + 1, a + b,
            1 if t < c else 2 if c == t else 3)


def old_stones(k: int) -> tuple[int, ...]:
    s = INITIAL
    for iteration in range(2, k + 1):
        wheat, barley, salt, bitter, red = s
        s = tuple(map(canonical, (
            wheat ** 2 + 3 * barley + iteration,
            barley ** 2 + 5 * salt + wheat,
            salt ** 2 + 7 * bitter + barley,
            bitter ** 2 + 11 * red + salt,
            red ** 2 + 13 * wheat + bitter,
        )))
    return s


def hidden(c: int, t: int, k: int) -> int:
    a, b, distance, total, direction = work(c, t)
    stones = old_stones(k)
    x = canonical(a + (2*k+1)*b + (3*k+1)*distance
                  + (4*k+2)*total + (4*k+4)*direction + sum(stones))
    for r in range(1, 8):
        x = canonical(x*x + 3*x + stones[(r-1) % 5] + r)
    return x


def independent_visible1(c: int, t: int) -> tuple[int, tuple[int, int, int]]:
    counts = work(c, t)
    previous = (hidden(c, t, 1), hidden(c, t, 3), hidden(c, t, 7))
    h1, h3, h7 = previous
    value = canonical(sum(stone * count for stone, count in zip(INITIAL, counts))
                      + h1 + 3*h3 + 5*h7 + 1)
    for coeff_x, coeff_h1, coeff_h3, coeff_h7, stone_index in GRIND:
        value = canonical(value*value + coeff_x*value
                          + coeff_h1*h1 + coeff_h3*h3 + coeff_h7*h7
                          + INITIAL[stone_index])
    return value, previous


def parse_db(label: str, source: str) -> bytes:
    m = re.search(r"(?m)^\." + label + r":\s*\n((?:\s*db\s+[^\n]+\n?)+)", source)
    assert m is not None, f"missing {label}"
    return bytes(int(h.strip().removeprefix("$"), 16)
                 for row in m.group(1).splitlines()
                 for h in row.strip().removeprefix("db").split(","))


def main() -> None:
    src = ROM.read_text(encoding="utf-8")
    value, hidden_inputs = independent_visible1(0, 0)
    assert parse_db("expected1", src) == value.to_bytes(16, "little")
    assert parse_db("inputHidden", src) == b"".join(
        v.to_bytes(16, "little") for v in hidden_inputs)
    cases = [(0, 0), (1, 2), (-1, -2), (-2, 1),
             (-(1 << 31), (1 << 31)-1),
             ((1 << 31)-1, -(1 << 31)),
             (-(1 << 31), -(1 << 31)),
             ((1 << 31)-1, (1 << 31)-1)]
    rng = random.Random(0x51B1E1)
    cases.extend((rng.randrange(-(1 << 31), 1 << 31),
                  rng.randrange(-(1 << 31), 1 << 31)) for _ in range(64))
    for c, t in cases:
        x, prior = independent_visible1(c, t)
        assert 1 <= x <= M and len(prior) == 3
        assert compute_sauce(FOUNDATION+c, FOUNDATION+t).first_visible == x, (c, t)
    runtime = RUNTIME.read_text(encoding="utf-8")
    boot = BOOT.read_text(encoding="utf-8")
    workflow = WORKFLOW.read_text(encoding="utf-8")
    assert "CalendarVisibleDrop1::" in runtime
    assert "call CalendarOrdinalValidate" in runtime
    assert "call WorkCountsFromOffsets32" in runtime
    assert "call Mul128x128" in runtime and "call SaveWide256" in runtime
    assert "wCalendarVisibleInputs:: ds 48" in boot
    assert "wCalendarVisibleOutput:: ds 16" in boot
    assert "STAGE1_VISIBLE1_NATIVE_BENCH" in boot
    assert "RunCalendarVisible1Bench::" in src
    assert "ld a, 123" in src and ".checkRejected:" in src
    assert "dmg-visible1-native:" in workflow
    print("HOST_STAGE1_VISIBLE1=PASS independent_pairs=72 "
          "hidden_inputs=3 canonical_foundation_bytes=64 "
          "signed32_endpoints=YES i1_stones=5 source_immutable=STATIC_GUARD "
          "Native379=CI_REQUIRED full_visible46_bowls=NOT_IMPLEMENTED", flush=True)


if __name__ == "__main__":
    main()
