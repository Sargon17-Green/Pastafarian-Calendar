#!/usr/bin/env python3
"""Independent Python check for bounded, signed Foundation-day deltas.
Host checks do not replace the RGBDS native ROM test.
"""
from random import Random

LO = -(1 << 31)
HI = (1 << 31) - 1

def oracle(delta: int) -> int:
    if not LO <= delta <= HI:
        raise ValueError("outside exact signed 32-bit precondition")
    return 2 * (-delta) if delta < 0 else 2 * delta + 1

def emulated_byte_arithmetic(delta: int) -> bytes:
    """Bytewise independent recurrence matching required 5-byte contract."""
    data = list((delta & 0xFFFFFFFF).to_bytes(4, "little"))
    neg = bool(data[-1] & 0x80)
    if neg:
        carry = 1
        for i in range(4):
            v = (data[i] ^ 0xFF) + carry
            data[i] = v & 255
            carry = v >> 8
    data.append(0)
    carry = 0
    for i, v in enumerate(data):
        t = v * 2 + carry
        data[i] = t & 255
        carry = t >> 8
    assert carry == 0
    if not neg:
        carry = 1
        for i in range(5):
            total = data[i] + carry
            data[i] = total & 255
            carry = total >> 8
        assert carry == 0
    return bytes(data)

def main() -> None:
    boundaries = [LO, LO+1, -65536, -3, -2, -1, 0, 1, 2, 3, 65536, 1 << 30, HI-1, HI]
    rng = Random(0x83F047)
    tested = 0
    for delta in boundaries + [rng.randint(LO,HI) for _ in range(12000)]:
        actual = emulated_byte_arithmetic(delta)
        expected = oracle(delta).to_bytes(5, "little")
        assert actual == expected, (delta,actual.hex(),expected.hex())
        tested += 1
    for delta in [LO-1, HI+1]:
        try:
            oracle(delta)
        except ValueError:
            pass
        else:
            raise AssertionError("out-of-range input was accepted")
    print(f"HOST_DAY_COUNT_DELTA32=PASS cases={tested} min={LO} max={HI}")
    print("NOT_A_NATIVE_ROM_VERIFICATION=YES")

if __name__ == "__main__":
    main()
