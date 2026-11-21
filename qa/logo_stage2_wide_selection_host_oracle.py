#!/usr/bin/env python3
"""Independent finite-domain oracle for Logo+Ido Stage2 wide rank selection.

QA only. This file must not be used as production Logo code or a Native PASS.
"""

MODULI = (3, 4, 5, 7, 11)
PRODUCTION_MODULUS = (1 << 127) - 1


def stepped_digit(first_value: int, direction: int, modulus: int, index: int) -> int:
    """Generate a digit by discrete ±1 steps; no modular-position formula."""
    value = first_value
    for _ in range(index):
        value += direction
        if value > modulus:
            value = 1
        elif value < 1:
            value = modulus
    return value


def wide_first(first_value: int, direction: int, modulus: int) -> int:
    """Build a two-digit 1-based value from explicit stream enumeration."""
    low = stepped_digit(first_value, direction, modulus, 0) - 1
    high = stepped_digit(first_value, direction, modulus, 1) - 1
    return 1 + low + modulus * high


def independent_walk(modulus: int, first_value: int, direction: int, count: int):
    """Enumerate the circle until accepted; only for small test moduli."""
    space = modulus * modulus
    limit = (space // count) * count
    candidate = wide_first(first_value, direction, modulus)
    rejected = 0
    while candidate > limit:
        rejected += 1
        assert rejected <= space, "An accepted point must exist in one cycle"
        candidate += direction
        if candidate > space:
            candidate = 1
        elif candidate < 1:
            candidate = space
    return 1 + ((candidate - 1) % count), rejected


def proposed_fast_result(modulus: int, first_value: int, direction: int, count: int) -> int:
    """Mathematical target for later *independent* Logo implementation."""
    space = modulus * modulus
    limit = (space // count) * count
    candidate = wide_first(first_value, direction, modulus)
    if candidate <= limit:
        return 1 + ((candidate - 1) % count)
    return 1 if direction == 1 else count


def verify() -> None:
    total = rejected_cases = plus_rejected = minus_rejected = 0
    for modulus in MODULI:
        for count in range(modulus + 1, modulus * modulus + 1):
            for first_value in range(1, modulus + 1):
                for direction in (-1, +1):
                    want, skipped = independent_walk(modulus, first_value, direction, count)
                    got = proposed_fast_result(modulus, first_value, direction, count)
                    assert want == got, (modulus, count, first_value, direction, want, got)
                    assert 1 <= want <= count
                    total += 1
                    if skipped:
                        rejected_cases += 1
                        if direction == 1:
                            plus_rejected += 1
                        else:
                            minus_rejected += 1

    assert (total, rejected_cases, plus_rejected, minus_rejected) == (3340, 669, 341, 328)
    modulus = PRODUCTION_MODULUS
    space = modulus * modulus
    half = space // 2 + 1
    fixed = (
        (1, +1, half, modulus + 1),
        (modulus - 2, +1, half, 1),
        (modulus - 2, -1, half, half),
        (modulus, +1, modulus + 1, modulus),
        (1, -1, space, wide_first(1, -1, modulus)),
    )
    for first_value, direction, count, expected in fixed:
        actual = proposed_fast_result(modulus, first_value, direction, count)
        assert actual == expected
        assert 1 <= actual <= count

    print(f"WIDE_HOST_ENUM_CASES {total}")
    print(f"WIDE_HOST_REJECTION_CASES {rejected_cases}")
    print(f"WIDE_HOST_POSITIVE_REJECTION {plus_rejected}")
    print(f"WIDE_HOST_NEGATIVE_REJECTION {minus_rejected}")
    print(f"WIDE_HOST_FULL_MODULUS_VECTORS {len(fixed)}")
    print("WIDE_HOST_MATHEMATICAL_ORACLE=PASS")
    print("WIDE_LOGO_NATIVE=NOT_RUN")


if __name__ == "__main__":
    verify()
