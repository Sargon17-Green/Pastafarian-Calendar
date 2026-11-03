#!/usr/bin/env python3
"""Independent mathematical oracle for bounded, end-to-end k=3 rejection.

Only Python arbitrary-precision integers are used. No WAT file or WASM
runtime is imported or executed. All test inputs are valid selector inputs.
"""

M = (1 << 127) - 1
S = M**3


def compute(first: int, step: int, n: int) -> dict:
    assert first in range(1, 3) and step == -1
    assert M**2 < n <= S
    digits = []
    k, space = 1, M
    while space < n:
        space *= M
        k += 1
    assert k == 3 and space == S
    for j in range(k):
        digits.append((first - 1 + j * step) % M)
    x = 1 + sum(d * M**j for j, d in enumerate(digits))
    q, rem = divmod(space, n)
    limit = q * n
    cur, rejected = x, 0
    while cur > limit:
        cur = ((cur - 1 + step) % space) + 1
        rejected += 1
        if rejected > 8:
            raise AssertionError('Unbounded or incorrectly designed test')
    rank = ((cur - 1) % n) + 1
    return dict(k=k, digits=digits, x=x, q=q, rem=rem, limit=limit,
                accepted=cur, rejected=rejected, rank=rank)


def main() -> None:
    x2 = S - M * M + 2
    x1 = S - M * M - M + 1
    cases = [
        ('full_backward_one_rejection', 2, -1, x2 - 1, 1, 1),
        ('full_backward_two_rejections', 2, -1, x2 - 2, 1, 2),
        ('full_backward_three_rejections', 2, -1, x2 - 3, 1, 3),
        ('full_backward_digit_wrap_one_rejection', 1, -1, x1 - 1, 1, 1),
        ('full_backward_q2_two_rejections', 2, -1, ((M - 1)//2) * M * M, 2, 2),
        ('full_backward_q3_two_rejections', 2, -1, ((M - 1)//3) * M * M, 3, 2),
    ]
    assert (M - 1) % 2 == 0 and (M - 1) % 3 == 0
    for name, first, step, n, expected_q, expected_rejects in cases:
        result = compute(first, step, n)
        expected_x = x1 if first == 1 else x2
        assert result['x'] == expected_x, (name, 'initial x', result)
        assert result['q'] == expected_q, (name, 'quotient', result)
        assert result['limit'] == expected_q*n, (name, 'limit', result)
        assert result['rejected'] == expected_rejects, (name, 'rejections', result)
        assert result['accepted'] == result['limit'], (name, 'accepted', result)
        assert result['rank'] == n, (name, 'rank', result)
        print(f"PASS {name}: k={result['k']} q={result['q']} "
              f"rejections={result['rejected']} final_rank_eq_n=True")
    print(f'ORACLE {len(cases)}/{len(cases)} PASS')


if __name__ == '__main__':
    main()
