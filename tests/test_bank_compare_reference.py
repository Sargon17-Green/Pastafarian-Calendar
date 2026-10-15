#!/usr/bin/env python3
"""Independent comparison model: runtime assembly is verified separately in PyBoy."""
from random import Random

def reference_bytes(a: bytes, b: bytes) -> int:
    if len(a) != 4096 or len(b) != 4096:
        raise ValueError("exact 4096-byte operands required")
    for x, y in zip(reversed(a), reversed(b)):
        if x > y:
            return 1
        if x < y:
            return 2
    return 0

def main() -> None:
    n = 4096
    scenarios = [
        (0, 0),
        (1, 0),
        (0, 1),
        ((1 << (n * 8)) - 1, (1 << (n * 8)) - 1),
        ((1 << (n * 8)) - 1, (1 << (n * 8)) - 2),
        (1 << ((n - 1) * 8), (1 << ((n - 1) * 8)) - 1),
    ]
    rng = Random(0x83_2026)
    scenarios.extend((rng.getrandbits(n * 8), rng.getrandbits(n * 8)) for _ in range(300))
    for a, b in scenarios:
        outcome = reference_bytes(a.to_bytes(n, "little"), b.to_bytes(n, "little"))
        expected = 0 if a == b else 1 if a > b else 2
        assert outcome == expected, (a, b)
    print(f"HOST_BANKED_COMPARE_REFERENCE_PASS cases={len(scenarios)}")
    print("NOT_A_NATIVE_ROM_VERIFICATION=YES")
    test_signed_reference()


def signed_reference(a_sign: int, a: bytes, b_sign: int, b: bytes) -> int:
    """Compare canonical signed magnitudes. Return 3 on invalid input."""
    if (a_sign not in (0, 1) or b_sign not in (0, 1)
            or (a_sign == 1 and not any(a))
            or (b_sign == 1 and not any(b))):
        return 3
    if a_sign != b_sign:
        return 2 if a_sign else 1
    magnitude = reference_bytes(a, b)
    return magnitude if a_sign == 0 or magnitude == 0 else 3 - magnitude


def test_signed_reference() -> None:
    from itertools import product
    rng = Random(0x5A83)
    n = 4096
    bounds = [0, 1, 2, (1 << (8 * n - 1)), (1 << (8 * n)) - 1]
    cases = 0
    for a_sign, b_sign, a_value, b_value in product(range(3), range(3), bounds, bounds):
        a, b = a_value.to_bytes(n, "little"), b_value.to_bytes(n, "little")
        actual = signed_reference(a_sign, a, b_sign, b)
        bad = a_sign == 2 or b_sign == 2 or (a_sign == 1 and a_value == 0) or (b_sign == 1 and b_value == 0)
        left, right = (-a_value if a_sign else a_value), (-b_value if b_sign else b_value)
        expected = 3 if bad else 0 if left == right else 1 if left > right else 2
        assert actual == expected, (a_sign, b_sign, a_value, b_value)
        cases += 1
    for _ in range(150):
        a_value, b_value = rng.getrandbits(8 * n), rng.getrandbits(8 * n)
        a_sign, b_sign = rng.randrange(2), rng.randrange(2)
        a, b = a_value.to_bytes(n, "little"), b_value.to_bytes(n, "little")
        actual = signed_reference(a_sign, a, b_sign, b)
        left, right = (-a_value if a_sign else a_value), (-b_value if b_sign else b_value)
        expected = 0 if left == right else 1 if left > right else 2
        assert actual == expected
        cases += 1
    print(f"HOST_BANKED_SIGNED_COMPARE_REFERENCE_PASS cases={cases}")
    print("NOT_A_NATIVE_ROM_VERIFICATION=YES")

if __name__ == "__main__":
    main()
