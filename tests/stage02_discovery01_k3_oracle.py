#!/usr/bin/env python3
"""Independent integer-only oracle for WAT selector k=2 -> k=3 boundary.

No WAT execution, WASM import, or other implementation is used.
"""

M = (1 << 127) - 1


def direct_rank(n: int, first: int, step: int) -> tuple[int, int, int, int]:
    """Compute the normative selector by Python arbitrary-precision arithmetic."""
    assert n > 0 and 1 <= first <= M and step in (-1, 1)
    k = 1
    space = M
    while space < n:
        space *= M
        k += 1
    digits = [1 + ((first - 1 + step * j) % M) for j in range(k)]
    x = 1 + sum((value - 1) * M**j for j, value in enumerate(digits))
    limit = (space // n) * n
    # All selected cases have x <= limit; no long rejection loop is involved.
    assert x <= limit, (n, first, step, x, limit)
    return k, x, limit, (x - 1) % n + 1


def main() -> None:
    n2 = M * M
    n3 = n2 + 1
    assert n2 < n3 <= M**3
    assert (M**3) // n3 == M - 1
    cases = [
        ("k2_at_m_squared", n2, 1, 1, M + 1, 2),
        ("k3_from_one", n3, 1, 1, M - 1, 3),
        ("k3_backward_from_m", n3, M, -1, n3 - 2 * M + 2, 3),
        ("k3_forward_near_limit", n3, M - 3, 1, n3 - 3 * M - 2, 3),
        ("k3_backward_wrap_from_one", n3, 1, -1, n3 - 2 * M + 2, 3),
    ]
    passed = 0
    for name, n, first, step, expected, expected_k in cases:
        k, x, limit, rank = direct_rank(n, first, step)
        assert k == expected_k, (name, k, expected_k)
        assert rank == expected, (name, rank, expected)
        assert 1 <= rank <= n
        assert limit - x >= 0
        passed += 1
        print(f"PASS {name}: k={k} rank={rank} limit_minus_x={limit - x}")
    print(f"ORACLE {passed}/{len(cases)} PASS")


if __name__ == "__main__":
    main()
