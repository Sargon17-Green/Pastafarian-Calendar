#!/usr/bin/env python3
"""Independent integer-only oracle for DISCOVERY01 q=3 adjacent boundary.

This module does not import any WAT runtime or implementation code.
"""
from __future__ import annotations

import json

PROJECT_ID = "PC-BRANCH-WAT-SPANISH"
MS = [7, 10, 13, 16, 19, 22, 25, 28, 31, (1 << 127) - 1]


def verify(m: int, delta: int) -> dict[str, object]:
    assert m > 4 and m % 3 == 1
    # Independent response-stream construction: first=1; then M; then M-1.
    responses = (1, m, m - 1)
    x = 1 + sum((digit - 1) * m**i for i, digit in enumerate(responses))
    t = ((m - 1) // 3) * (m * m - 1)
    n = t + delta
    space = m**3
    assert x == 3 * t and m * m < n < space
    q, _ = divmod(space, n)
    limit = q * n
    assert q == 3 and x - limit == -3 * delta
    accepted = min(x, limit)  # step=-1 gives the first accepted predecessor.
    rank = ((accepted - 1) % n) + 1
    expected = {-1: t - 1, 0: t, 1: t - 2}[delta]
    assert rank == expected
    return {"delta": delta, "q": q, "accepted": "rejected" if x > limit else
            "equal" if x == limit else "below", "rank": str(rank)}


def main() -> None:
    results = [verify(m, d) for m in MS for d in (-1, 0, 1)]
    assert len(results) == 30
    print(json.dumps({
        "project_id": PROJECT_ID, "cases": len(results), "passed": len(results),
        "failed": 0, "small_models": 27, "production_models": 3,
        "production": results[-3:],
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()
