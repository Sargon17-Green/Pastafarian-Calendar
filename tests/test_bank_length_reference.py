#!/usr/bin/env python3
"""Independent little-endian magnitude length oracle for 8KiB MBC5 SRAM.
Host-side model only; never part of the Game Boy production binary.
"""
from random import Random


def reference_length(raw: bytes) -> int:
    for offset in range(len(raw) - 1, -1, -1):
        if raw[offset]:
            return offset + 1
    return 0


def main() -> None:
    rng = Random(0x83_122)
    checked = 0
    for capacity in (1, 16, 256, 4096, 4097, 8192):
        for used in sorted({0, 1, capacity // 2, capacity - 1, capacity}):
            if not 0 <= used <= capacity:
                continue
            raw = bytearray(capacity)
            if used:
                raw[used - 1] = 0x80
            length = reference_length(raw)
            assert length == used, (capacity, used, length)
            checked += 1
        for _ in range(300):
            raw = bytearray(capacity)
            high = rng.randrange(capacity + 1)
            if high:
                raw[high - 1] = rng.randrange(1, 256)
            for _ in range(6):
                i = rng.randrange(high) if high else 0
                if high:
                    raw[i] = rng.randrange(256)
            assert reference_length(raw) == high, (capacity, high)
            checked += 1
    # A 4096-byte fixed-width input can produce a 4097-byte output.
    full = (1 << (4096 * 8)) - 1
    total = (full + 1).to_bytes(4097, "little")
    assert reference_length(total) == 4097
    assert reference_length(bytes(4097)) == 0
    checked += 2
    print(f"HOST_SRAM_MAGNITUDE_LENGTH=PASS cases={checked}")
    print("NOT_A_NATIVE_ROM_VERIFICATION=YES")


if __name__ == "__main__":
    main()
