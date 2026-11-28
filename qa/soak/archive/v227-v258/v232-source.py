"""Exact short-rejection arithmetic model. No converter invocation.
Source pins: C++ 32ad50c8177233adc87eed1721c1e6f34f24ced1;
src/monster.cpp a9cb83e67fc962fdf5560ad0b2cdf5354148e6a9
(ringAnswer, biasedLegacyPick, Patch13RejectionWrapper::repair);
include/pastafari/monster.hpp 4c24d36e3704dd10ecf5420e7bc11a3da958d441.
For valid N and d, the rejected interval is [A+1,M]. In the negative
direction its first exit is A, with no wrap. In the positive direction
its first exit is 1 via wrap. The original loop and direct calculation
therefore have identical acceptance limit, answer, offset and rank.
This is a mathematical regression, not evidence that the observed
C++ timeouts are caused by this loop.
"""
from random import Random
import json


def ring(m, x, d, k):
    return 1 + (x - 1 + d * k) % m


def direct(m, n, x, d):
    assert 1 <= n <= m and d in (-1, 1)
    x = ring(m, x, d, 0)
    a = (m // n) * n
    if x <= a:
        k, y = 0, x
    elif d == -1:
        k, y = x - a, a
    else:
        k, y = m - x + 1, 1
    return (a, y, k, (y - 1) % n + 1)


def legacy(m, n, x, d):
    a = (m // n) * n
    k = 0
    while True:
        y = ring(m, x, d, k)
        if y <= a:
            return (a, y, k, (y - 1) % n + 1)
        k += 1


def certificate(m, n, x, d):
    a, y, k, rank = direct(m, n, x, d)
    x = ring(m, x, d, 0)
    assert y == ring(m, x, d, k) and 1 <= y <= a
    assert 1 <= rank <= n
    if k:
        assert x > a and ring(m, x, d, k - 1) > a
        if d == -1:
            assert x - k == a and k <= m - a
        else:
            assert x + k == m + 1 and k <= m - a
    else:
        assert x <= a
    return k


def main():
    small = loop_steps = 0
    for m in range(1, 97):
        for n in range(1, m+1):
            for x in range(1, m+1):
                for d in (-1, 1):
                    got = direct(m, n, x, d)
                    assert got == legacy(m, n, x, d)
                    small += 1
                    loop_steps += got[2]
    m = (1 << 127) - 1
    rng = Random(20261127)
    ns = set(range(1, 124)) | {m, m-1, m//2, m//2+1, m//3, m//3+1}
    ns |= {rng.randrange(1, m+1) for _ in range(10000)}
    large = max_k = 0
    for n in sorted(ns):
        a = m//n*n
        xs = {1, m, a, max(1,a-1), min(m,a+1), rng.randrange(1,m+1)}
        for x in xs:
            for d in (-1,1):
                max_k = max(max_k, certificate(m,n,x,d))
                large += 1
    assert max_k == (m-1)//2
    assert (small, loop_steps, large) == (599072, 1126972, 121492)
    print(json.dumps({'schema':'SHORT_REJECTION_MODEL_V232/1','small_exhaustive_cases':small,'legacy_rejected_iterations':loop_steps,'actual_modulus_certificate_cases':large,'max_exact_rejections':str(max_k),'mismatches':0,'native_calls':0,'whole_year_credit':0,'scope':'arithmetic model; not C++ source runtime evidence'}, sort_keys=True))


if __name__ == '__main__':
    main()
