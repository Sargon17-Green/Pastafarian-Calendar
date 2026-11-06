#!/usr/bin/env python3
"""Bounded independent short-ring liveness oracle. No WebAssembly imports."""
import json

M = (1 << 127) - 1


def iterative(m, n, first, direction):
    """Original mathematical ring specification, independently simulated."""
    upper = (m // n) * n
    x = first
    for attempts in range(m + 1):
        if x <= upper:
            return x, attempts, (x - 1) % n + 1
        x = 1 + ((x - 1 + direction) % m)
    raise AssertionError("accepted point not reached within one revolution")


def direct(m, n, first, direction):
    """Closed form for the first accepted element of the tail rejection set."""
    upper = (m // n) * n
    if first <= upper:
        return first
    return 1 if direction == 1 else upper


def main():
    moduli = pairs = rejected_steps = 0
    for m in range(7, 242, 6):
        n = (m + 2) // 3
        assert m // n == 2 and 2 * n < m
        moduli += 1
        for first in range(1, m + 1):
            for direction in (-1, 1):
                x, attempts, rank = iterative(m, n, first, direction)
                chosen = direct(m, n, first, direction)
                assert x == chosen, (m, n, first, direction)
                assert rank == (chosen - 1) % n + 1
                pairs += 1
                rejected_steps += attempts
    assert (moduli, pairs, rejected_steps) == (40, 9920, 86920)

    n = (M + 2) // 3
    limit = (M // n) * n
    assert M == 3 * n - 2 and limit == 2 * n
    assert M - limit == (M - 1) // 3 - 1
    production = []
    for first in (M, M - 1):
        x = direct(M, n, first, -1)
        rank = (x - 1) % n + 1
        assert (x, rank) == (limit, n)
        production.append({
            "first": str(first), "direction": -1, "q": 2,
            "n": str(n), "limit": str(limit),
            "rejection_steps_avoided": str(first - limit),
            "rank": str(rank)
        })

    print(json.dumps({
        "project_id": "PC-BRANCH-WAT-SPANISH",
        "mode": "independent_bounded_oracle_no_native",
        "moduli": moduli, "exhaustive_pairs": pairs,
        "exhaustive_rejection_steps": rejected_steps,
        "production_algebraic_cases": production,
        "passed": True, "failed": 0
    }, ensure_ascii=False, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
