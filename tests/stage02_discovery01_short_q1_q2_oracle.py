#!/usr/bin/env python3
"""Independent q=1/q=2 short-path oracle for Stage02 DISCOVERY01.

Small odd moduli: exhaustive ring walk vs closed-form integer derivation.
Production M=2^127-1: four fixed boundary witnesses, each accepting in <=2 steps.
No WAT imports, cross-branch fixtures, or assumed historical defects.
"""
from __future__ import annotations
import json

PROJECT_ID = "PC-BRANCH-WAT-SPANISH"
M = (1 << 127) - 1


def closed(m: int, n: int, first: int, step: int) -> tuple[int, int, int]:
    limit = (m // n) * n
    if first <= limit:
        accepted, rejections = first, 0
    elif step == 1:
        accepted, rejections = 1, m - first + 1
    else:
        accepted, rejections = limit, first - limit
    return (accepted - 1) % n + 1, accepted, rejections


def iterate(m: int, n: int, first: int, step: int, max_steps: int) -> tuple[int, int, int]:
    assert m >= 3 and 1 <= n <= m and 1 <= first <= m and step in (-1, 1)
    x, limit = first, m // n * n
    for rejected in range(max_steps):
        if x <= limit:
            return (x - 1) % n + 1, x, rejected
        x = (1 if x == m else x + 1) if step == 1 else (m if x == 1 else x - 1)
    raise AssertionError("bounded simulation exceeded cap")


def exhaustive() -> tuple[int, int]:
    cases = rejections = 0
    for m in range(3, 64, 2):
        for n in range(1, m + 1):
            for first in range(1, m + 1):
                for step in (-1, 1):
                    a = closed(m, n, first, step)
                    b = iterate(m, n, first, step, m + 1)
                    assert a == b, (m, n, first, step, a, b)
                    cases += 1
                    rejections += b[2]
    return cases, rejections


def production() -> list[dict[str, object]]:
    n2, n1 = (M - 1) // 2, (M + 1) // 2
    specs = [
        ("test_discovery01_short_q2_m_backward_limit", n2, M, -1, n2),
        ("test_discovery01_short_q2_m_forward_wrap", n2, M, 1, 1),
        ("test_discovery01_short_q1_above_half_forward_wrap", n1, M, 1, 1),
        ("test_discovery01_short_q1_above_half_at_limit", n1, n1, -1, n1),
    ]
    result = []
    for name, n, first, step, expected in specs:
        q, limit = M // n, (M // n) * n
        assert q == (2 if n == n2 else 1)
        assert M - limit == (1 if n == n2 else n1 - 1)
        a = closed(M, n, first, step)
        b = iterate(M, n, first, step, 3)
        assert a == b and a[0] == expected and a[2] <= 1
        result.append({"name": name, "q": q, "n": str(n), "first": str(first),
                       "step": step, "limit": str(limit), "rank": str(expected),
                       "rejections": a[2]})
    return result


def main() -> None:
    cases, rejections = exhaustive()
    prod = production()
    assert cases == 87358 and len(prod) == 4
    print(json.dumps({
        "project_id": PROJECT_ID, "mode": "independent_integer_oracle_not_native",
        "small_models": 31, "small_pairs": cases, "small_rejections": rejections,
        "production_cases": prod, "production_passed": 4,
        "failed": 0, "pass": True
    }, sort_keys=True, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
