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

if __name__ == "__main__":
    main()
