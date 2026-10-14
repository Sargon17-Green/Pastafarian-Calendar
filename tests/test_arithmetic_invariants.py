#!/usr/bin/env python3
"""Independent host-side arithmetic model; NEVER a production implementation.

The model tests algorithmic arithmetic invariants. Only the compiled SM83 ROM
run by PyBoy can verify the production instruction stream.
"""
from __future__ import annotations

from random import Random

M = (1 << 127) - 1


def save_reference(value: int) -> int:
    if value < 0:
        raise ValueError("unsigned inputs only")
    return 1 + ((value - 1) % M)


def save_stream(data: bytes) -> int:
    """Fold each input bit without converting the entire input to an integer."""
    remainder = 0
    for byte in reversed(data):
        for bit in range(7, -1, -1):
            remainder = 2 * remainder + ((byte >> bit) & 1)
            while remainder >> 127:
                remainder = (remainder & M) + (remainder >> 127)
            if remainder == 0:
                remainder = M
    return remainder


def mul_stream(a: bytes, b: bytes) -> bytes:
    """Full-width multiply by bytewise 256-bit shifts and carry addition."""
    if len(a) != 16 or len(b) != 16:
        raise ValueError("two 128-bit operands required")
    out = bytearray(32)
    for byte in reversed(a):
        for bit in range(7, -1, -1):
            carry = 0
            for i in range(32):
                next_value = (out[i] << 1) | carry
                out[i] = next_value & 255
                carry = next_value >> 8
            assert carry == 0, "256-bit multiplication overflow"
            if not (byte & (1 << bit)):
                continue
            carry = 0
            for i in range(16):
                next_value = out[i] + b[i] + carry
                out[i] = next_value & 255
                carry = next_value >> 8
            i = 16
            while carry and i < 32:
                next_value = out[i] + carry
                out[i] = next_value & 255
                carry = next_value >> 8
                i += 1
            assert carry == 0, "256-bit multiplication overflow"
    return bytes(out)


def main() -> None:
    rng = Random(0x5788)
    boundaries = [0, 1, 2, M - 1, M, M + 1, (1 << 128) - 1]
    for a in boundaries:
        for b in boundaries:
            actual = mul_stream(a.to_bytes(16, "little"), b.to_bytes(16, "little"))
            product = a * b
            assert actual == product.to_bytes(32, "little"), (a, b, "product")
            assert save_stream(actual) == save_reference(product), (a, b, "SAVE")

    for _ in range(2048):
        a = rng.getrandbits(128)
        b = rng.getrandbits(128)
        product = mul_stream(a.to_bytes(16, "little"), b.to_bytes(16, "little"))
        assert product == (a * b).to_bytes(32, "little")
        assert save_stream(product) == save_reference(a * b)

    for _ in range(8192):
        n = rng.getrandbits(256)
        assert save_stream(n.to_bytes(32, "little")) == save_reference(n)

    assert save_stream(bytes(32)) == M
    assert save_stream(((1 << 256) - 1).to_bytes(32, "little")) == 3
    print("HOST_ARITHMETIC_MODEL=PASS boundary_pairs=49 multiply_random=2048 save_random=8192")
    print("NOT_A_NATIVE_ROM_VERIFICATION=YES")


if __name__ == "__main__":
    main()
