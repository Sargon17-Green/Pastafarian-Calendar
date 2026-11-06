#!/usr/bin/env python3
"""Independent bounded differential oracle for the patched short-ring selector.

Reference advances one position per rejection. The candidate predicts the exact
first accepted ring position in constant time. No WAT module or other branch is
imported; production-size cases are algebraic only.
"""
import json

M = (1 << 127) - 1


def reference(m, n, first, step):
    limit = (m // n) * n
    current = first
    rejections = 0
    while current > limit:
        current += step
        if current == 0:
            current = m
        elif current == m + 1:
            current = 1
        rejections += 1
        assert rejections <= m
    return current, ((current - 1) % n) + 1, rejections


def candidate(m, n, first, step):
    limit = (m // n) * n
    selected = first if first <= limit else (1 if step > 0 else limit)
    return selected, ((selected - 1) % n) + 1


def main():
    by_q = {q: {"n": 0, "pairs": 0, "rejections": 0} for q in (1, 2, 3)}
    for m in range(11, 100, 2):
        for n in range(1, m + 1):
            q = m // n
            if q not in by_q:
                continue
            tally = by_q[q]
            tally["n"] += 1
            for first in range(1, m + 1):
                for step in (-1, 1):
                    accepted, rank, rejected = reference(m, n, first, step)
                    selected, candidate_rank = candidate(m, n, first, step)
                    assert (accepted, rank) == (selected, candidate_rank), (
                        m, n, q, first, step, accepted, selected, rank, candidate_rank
                    )
                    assert 1 <= rank <= n
                    tally["pairs"] += 1
                    tally["rejections"] += rejected
    expected = {
        1: {"n": 1260, "pairs": 168960, "rejections": 541380},
        2: {"n": 405, "pairs": 54630, "rejections": 78330},
        3: {"n": 214, "pairs": 28640, "rejections": 23470},
    }
    assert by_q == expected, (by_q, expected)

    production = []
    for q, n, first, step in (
        (1, (M + 1) // 2, M, -1),
        (1, (M + 1) // 2, (M + 1) // 2, 1),
        (2, (M + 2) // 3, 2 * ((M + 2) // 3) + 1, 1),
        (2, (M + 2) // 3, (M + 2) // 3 + 1, -1),
        (3, (M + 1) // 4, M, -1),
        (3, (M + 1) // 4, M, 1),
    ):
        assert M // n == q and 1 <= first <= M
        limit = q * n
        selected, rank = candidate(M, n, first, step)
        expected_selected = first if first <= limit else (1 if step == 1 else limit)
        assert selected == expected_selected and rank == ((selected - 1) % n) + 1
        production.append({
            "q": q, "step": step, "n": str(n), "first": str(first),
            "limit": str(limit), "accepted": str(selected),
            "rank": str(rank), "native": "NOT_EXECUTED_BY_PYTHON"
        })

    print(json.dumps({
        "project_id": "PC-BRANCH-WAT-SPANISH",
        "test": "independent_bounded_q1_q2_q3_short_differential",
        "moduli": 45,
        "by_q": {str(k): v for k, v in by_q.items()},
        "exhaustive_pairs": sum(v["pairs"] for v in by_q.values()),
        "simulated_rejections": sum(v["rejections"] for v in by_q.values()),
        "production_algebraic_cases": production,
        "failed": 0
    }, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
