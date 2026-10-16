#!/usr/bin/env python3
"""Independent signed Euclidean /u8 model for the native SM83 fixed-width API."""
import random

WIDTH = 4096
LIMIT = 1 << (8 * WIDTH)


def model(magnitude: int, sign: int, divisor: int):
    if magnitude < 0 or magnitude >= LIMIT:
        raise ValueError("magnitude outside 4096-byte domain")
    if sign not in (0, 1) or (sign == 1 and magnitude == 0):
        return (1, 0, 0, 0, 0)
    if divisor == 0:
        return (2, 0, 0, 0, 0)
    if not 1 <= divisor <= 255:
        raise ValueError("divisor outside byte range")
    n = -magnitude if sign else magnitude
    q, r = divmod(n, divisor)
    qmag = abs(q)
    return (0, int(q < 0), qmag, r, (qmag.bit_length() + 7) // 8)


def main() -> None:
    rng = random.Random(0x5EED153)
    magnitudes = [0, 1, 2, 3, 7, 254, 255, 256, 257,
                  65535, 65536, (1 << 32767), LIMIT - 1]
    divisors = [0, 1, 2, 3, 4, 7, 127, 128, 254, 255]
    cases = 0
    for m in magnitudes:
        for s in (0, 1, 2):
            for d in divisors:
                result = model(m, s, d)
                status, qs, qm, r, length = result
                assert status == (1 if s == 2 or (s == 1 and m == 0) else 2 if d == 0 else 0)
                if status == 0:
                    n = -m if s else m
                    q = -qm if qs else qm
                    assert n == q * d + r
                    assert q == n // d
                    assert 0 <= r < d
                    assert length == (qm.bit_length() + 7) // 8
                    assert qm < LIMIT
                    assert qs == int(q < 0)
                else:
                    assert result[1:] == (0, 0, 0, 0)
                cases += 1
    for _ in range(500):
        m = rng.getrandbits(rng.randrange(1, 32769))
        s = rng.randrange(2)
        d = rng.randrange(1, 256)
        status, qs, qm, r, length = model(m, s, d)
        assert status == 0
        n = -m if s else m
        q = -qm if qs else qm
        assert n == q * d + r and q == n // d and 0 <= r < d
        assert qm < LIMIT
        assert length == (qm.bit_length() + 7) // 8
        cases += 1
    print(f"HOST_SIGNED_EUCLIDEAN_U8=PASS cases={cases} width_bytes={WIDTH}")


if __name__ == "__main__":
    main()
