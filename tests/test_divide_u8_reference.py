#!/usr/bin/env python3
"""Independent byte-radix division oracle for SM83 /u8.
Host-only mathematical reference, not native execution evidence.
"""
from random import Random

N = 4096


def divide_by_byte(raw: bytes, divisor: int) -> tuple[int, bytes, int, int]:
    if len(raw) != N:
        raise ValueError("4096 little-endian bytes required")
    if not 0 <= divisor <= 255:
        raise ValueError("8-bit divisor required")
    if divisor == 0:
        return 1, bytes(N), 0, 0
    quotient = bytearray(N)
    remainder = 0
    for i in range(N - 1, -1, -1):
        quotient[i], remainder = divmod((remainder << 8) | raw[i], divisor)
    used = len(bytes(quotient).rstrip(b"\\x00"))
    return 0, bytes(quotient), remainder, used


def main() -> None:
    rng = Random(0x83138)
    cases = 0
    bound = (1 << (8 * N)) - 1
    values = [0, 1, 254, 255, 256, 257, 1000, 65535, 1 << (8 * N - 1), bound]
    divisors = [0, 1, 2, 3, 4, 127, 128, 254, 255]
    for n in values:
        for d in divisors:
            original = n.to_bytes(N, "little")
            status, quotient, rem, length = divide_by_byte(original, d)
            assert original == n.to_bytes(N, "little")
            if d == 0:
                assert (status, quotient, rem, length) == (1, bytes(N), 0, 0)
            else:
                q, r = divmod(n, d)
                assert status == 0 and int.from_bytes(quotient, "little") == q
                assert rem == r and 0 <= rem < d
                assert length == (q.bit_length() + 7) // 8
            cases += 1
    for _ in range(512):
        n = rng.getrandbits(rng.randrange(0, 8 * N + 1))
        d = rng.randrange(1, 256)
        status, q, r, length = divide_by_byte(n.to_bytes(N, "little"), d)
        quotient = int.from_bytes(q, "little")
        assert status == 0 and n == quotient * d + r and 0 <= r < d
        assert length == (quotient.bit_length() + 7) // 8
        cases += 1
    print(f"HOST_DIVIDE_U8_REFERENCE=PASS cases={cases} width_bytes={N}")
    print("NOT_A_NATIVE_ROM_VERIFICATION=YES")


if __name__ == "__main__":
    main()
