#!/usr/bin/env python3
"""Independent bounded Python-integer oracle for Native358..364 stone ABI.

The two ROM fixture tables are read as *postconditions*, never used to
compute the expected values. No calendar output or full i=2..46 claim.
"""
from __future__ import annotations

import re
from pathlib import Path

MODULUS = (1 << 127) - 1
ASM = Path(__file__).resolve().parents[1] / "src/tests/calendar_stone_transition_test.asm"


def canonical(v: int) -> int:
    return ((v - 1) % MODULUS) + 1


def stones_independent(previous: tuple[int, ...], iteration: int) -> tuple[int, ...]:
    """Five named polynomial evaluations from one immutable tuple."""
    w, b, s, x, r = previous
    expressions = (
        w**2 + 3*b + iteration,
        b**2 + 5*s + w,
        s**2 + 7*x + b,
        x**2 + 11*r + s,
        r**2 + 13*w + x,
    )
    return tuple(canonical(expr) for expr in expressions)


def table(source: str, label: str) -> tuple[int, ...]:
    match = re.search(r"(?m)^\."+label+r":\s*\n((?:\s+db [^\n]+\n){5})", source)
    assert match, f"missing 5-row table {label}"
    values = []
    for row in match.group(1).splitlines():
        data = [int(v.strip().replace("$", ""), 16) for v in row.split("db", 1)[1].split(",")]
        assert len(data) == 16
        values.append(int.from_bytes(bytes(data), "little"))
    return tuple(values)


def main() -> None:
    src = ASM.read_text(encoding="utf-8")
    assert "RunCalendarStoneTransitionTests::" in src
    input_stones = table(src, "initial")
    fixture = table(src, "expected")
    assert input_stones == (17, 29, 43, 71, 101)
    computed = stones_independent(input_stones, 2)
    assert computed == fixture, (computed, fixture)
    assert all(1 <= x <= MODULUS for x in fixture)

    # Exercise full 127-bit residues and distinct secondary/cross terms.
    checks = 5
    cases = [
        (1, 1, 1, 1, 1),
        (MODULUS,)*5,
        (MODULUS-1, MODULUS, 1, 2, 3),
        (2**126, 2**125+1, 2**64+3, 2**63+5, 7),
    ]
    for seed in range(32):
        cases.append(tuple(1 + (seed * seed * (j + 3) + j*97) % MODULUS for j in range(5)))
    for state in cases:
        previous = tuple(state)
        expected = stones_independent(previous, 2)
        assert previous == tuple(state), "input mutated"
        assert len(expected) == 5
        for val in expected:
            assert 1 <= val <= MODULUS
        checks += 5

    # Fail-closed boundary contract is checked in real Native358..364,
    # not falsely represented as executed by this Host-only oracle.
    assert "ld a, 102" in src and "ld a, 108" in src
    assert "call .expectInvalid" in src and "call .expectSentinel" in src
    print(
        f"HOST_STAGE1_STONES_I2=PASS fixture_fields=5 "
        f"independent_Python_int_checks={checks} boundary_states={len(cases)} "
        "native_case_ids=358..364 source_verified=YES "
        "ROM_EXECUTION=CI_REQUIRED full_i2_46=NOT_IMPLEMENTED",
        flush=True,
    )


if __name__ == "__main__":
    main()
