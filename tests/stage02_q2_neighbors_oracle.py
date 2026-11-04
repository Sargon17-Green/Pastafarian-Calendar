#!/usr/bin/env python3
"""Independent integer oracle for DISCOVERY01 q=2 boundary neighbors.

Uses an arithmetic response stream; imports no WAT runtime or selector code.
"""
from __future__ import annotations

import json

PROJECT_ID = "PC-BRANCH-WAT-SPANISH"
MS = [5, 7, 9, 11, 13, 15, 17, 19, 21, (1 << 127) - 1]


def verify(m: int, delta: int) -> dict[str, object]:
    assert m >= 5 and m % 2 == 1 and delta in (-1, 0, 1)
    # first=1, step=-1: the first three responses are 1, M, M-1.
    responses = (1, m, m - 1)
    x = 1 + sum((answer - 1) * m**i for i, answer in enumerate(responses))
    t, remainder = divmod(x, 2)
    assert remainder == 0 and t == ((m - 1) // 2) * (m*m - 1)
    n = t + delta
    space = m**3
    assert m*m < n < space
    q = space // n
    limit = q*n
    assert q == 2 and x == 2*t and x - limit == -2*delta
    accepted = x if x <= limit else limit  # backward step: first acceptance
    rank = ((accepted - 1) % n) + 1
    expected_rank = t - 1 if delta == -1 else t if delta == 0 else t - 1
    assert rank == expected_rank and 1 <= rank <= n
    return {"delta": delta, "q": q, "n": str(n), "rank": str(rank),
            "accepted": "rejected" if x > limit else
                        "equal" if x == limit else "below"}


def main() -> None:
    cases = [verify(m, d) for m in MS for d in (-1, 0, 1)]
    assert len(cases) == 30
    print(json.dumps({"project_id": PROJECT_ID, "cases": len(cases),
                      "passed": len(cases), "failed": 0,
                      "small_models": 27, "production_models": 3,
                      "production": cases[-3:]}, ensure_ascii=False))


if __name__ == "__main__":
    main()
