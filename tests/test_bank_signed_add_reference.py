#!/usr/bin/env python3
"""Independent signed-magnitude sum model for 4096-byte SM83 SRAM operands.
This does NOT establish native ROM correctness; native tests remain mandatory.
"""
from itertools import product
from random import Random

BYTES = 4096
LIMIT = 1 << (8 * BYTES)

def signed_sum_reference(a_sign: int, a: bytes, b_sign: int, b: bytes) -> tuple[int,int,bytes]:
    """Return (status, sign, 4097-byte exact magnitude)."""
    if len(a) != BYTES or len(b) != BYTES:
        raise ValueError("expected two 4096-byte magnitudes")
    x = int.from_bytes(a, "little")
    y = int.from_bytes(b, "little")
    if (a_sign not in (0,1) or b_sign not in (0,1)
            or (a_sign == 1 and x == 0)
            or (b_sign == 1 and y == 0)):
        return (1, 0, bytes(BYTES + 1))
    value = (-x if a_sign else x) + (-y if b_sign else y)
    assert -LIMIT < value < LIMIT * 2
    return (0, int(value < 0), abs(value).to_bytes(BYTES+1, "little"))

def main() -> None:
    # Exhaustively compare all combinations of signs and a small boundary set.
    values = [0,1,2,255,256,65535,LIMIT-2,LIMIT-1]
    tested = 0
    for sa,sb,a,b in product(range(3),range(3),values,values):
        actual = signed_sum_reference(sa,a.to_bytes(BYTES,"little"),sb,b.to_bytes(BYTES,"little"))
        bad = sa == 2 or sb == 2 or (sa == 1 and a == 0) or (sb == 1 and b == 0)
        expected_value = ((-a if sa else a) + (-b if sb else b)) if not bad else 0
        expect = (1,0,bytes(BYTES+1)) if bad else (
             0,int(expected_value<0),abs(expected_value).to_bytes(BYTES+1,"little"))
        assert actual == expect, (sa,sb,a,b)
        tested += 1
    rng = Random(0x83A66)
    for _ in range(512):
        sa, sb = rng.randrange(2),rng.randrange(2)
        a,b = rng.getrandbits(BYTES*8),rng.getrandbits(BYTES*8)
        status,sign,result=signed_sum_reference(sa,a.to_bytes(BYTES,"little"),sb,b.to_bytes(BYTES,"little"))
        assert status == 0
        value = (-a if sa else a) + (-b if sb else b)
        assert (-1 if sign else 1)*int.from_bytes(result,"little") == value
        tested += 1
    print(f"HOST_SIGNED_SUM_REFERENCE=PASS cases={tested} capacity_bytes={BYTES}")
    print("NOT_A_NATIVE_ROM_VERIFICATION=YES")

if __name__ == "__main__":
    main()
