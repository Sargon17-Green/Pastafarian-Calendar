#!/usr/bin/env python3
"""Independent host contract tests for native VarAdd8192 (not SM83 execution)."""
from __future__ import annotations
import random

CAP = 8192

def verify(a: bytes, b: bytes) -> None:
    assert len(a) <= CAP and len(b) <= CAP
    assert not a or a[-1] != 0
    assert not b or b[-1] != 0
    lhs = int.from_bytes(a, "little")
    rhs = int.from_bytes(b, "little")
    exact = lhs + rhs
    expected = exact.to_bytes((exact.bit_length() + 7) // 8, "little")
    if len(expected) > CAP:
        assert len(expected) == CAP + 1
        assert exact >= 1 << (8 * CAP)
    else:
        assert len(expected) <= CAP
        assert (not expected or expected[-1] != 0)
        assert int.from_bytes(expected, "little") == lhs + rhs

def main() -> None:
    vectors = [
        (0, 0), (1, 2), (255, 1), (65535, 1),
        ((1 << (8 * CAP - 1)), 0),
        ((1 << (8 * CAP)) - 1, 1),
        ((1 << (8 * CAP)) - 1, 0),
    ]
    for x, y in vectors:
        verify(x.to_bytes((x.bit_length() + 7) // 8, "little"),
               y.to_bytes((y.bit_length() + 7) // 8, "little"))
    rng = random.Random(0x8A83)
    for _ in range(256):
        na = rng.choice((0, 1, 2, 3, 127, 128, 4095, 4096, 8191, 8192))
        nb = rng.choice((0, 1, 2, 3, 127, 128, 4095, 4096, 8191, 8192))
        a = bytearray(rng.randbytes(na))
        b = bytearray(rng.randbytes(nb))
        if a and not a[-1]:
            a[-1] = 1
        if b and not b[-1]:
            b[-1] = 1
        verify(bytes(a), bytes(b))
    print("HOST_VARIABLE_ADD_REFERENCE=PASS cases=263 capacity=8192", flush=True)

if __name__ == "__main__":
    main()
