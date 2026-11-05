#!/usr/bin/env python3
"""Independent integer feasibility oracle: Stage02 DISCOVERY01, forward q=2/3.

No WebAssembly execution, no selector imports, no reused branch fixtures.
The step=+1 rejection is evaluated on the [1, M^3] circle, not on [1, M].
"""
from __future__ import annotations

import json

PROJECT_ID = "PC-BRANCH-WAT-SPANISH"
SMALL_M = (7, 13, 19, 25, 31)
PRODUCTION_M = (1 << 127) - 1


def initial_value(m: int, first: int) -> int:
    assert m >= 7 and 1 <= first <= m
    # Independent response-stream arithmetic; do not import the selector.
    digits = [((first - 1 + i) % m) for i in range(3)]
    return 1 + sum(digit * (m ** i) for i, digit in enumerate(digits))


def evaluate(m: int, q: int, delta: int) -> dict[str, object]:
    assert m % 6 == 1 and q in (2, 3) and delta in (-1, 0, 1)
    first = m - 2
    x = initial_value(m, first)
    space = m ** 3
    n = x // q + delta
    assert m * m < n < space
    assert space // n == q
    limit = q * n
    chosen = x if x <= limit else 1  # forward to S then wrap to 1
    rank = 1 + (chosen - 1) % n
    difference = x - limit
    if q == 2:
        assert x % 2 == 0
        assert difference == -2 * delta
        expected = 1 if delta == -1 else n if delta == 0 else n - 2
    else:
        assert x % 3 == 1
        assert difference == 1 - 3 * delta
        expected = 1 if delta <= 0 else n - 2
    assert rank == expected and 1 <= rank <= n
    assert chosen == (1 if difference > 0 else x)
    skipped = (space - x + 1) if x > limit else 0
    return {"q": q, "delta": delta, "first": str(first), "n": str(n),
            "space": str(space), "initial_x": str(x), "limit": str(limit),
            "difference": difference, "accepted_x": str(chosen),
            "rank": str(rank), "rejection_steps": str(skipped)}


def exhaustive_small(m: int) -> dict[str, int]:
    assert m in SMALL_M
    space = m ** 3
    rows: dict[str, int] = {}
    for q in (2, 3):
        n_min = max(m * m + 1, space // (q + 1) + 1)
        n_max = space // q
        pairs = 0
        equalities = 0
        for n in range(n_min, n_max + 1):
            assert space // n == q
            limit = q * n
            for first in range(1, m + 1):
                x = initial_value(m, first)
                if x == limit:
                    equalities += 1
                if q == 3:
                    assert x != limit, (m, first, n)
                pairs += 1
        rows[f"q{q}_n"] = n_max - n_min + 1
        rows[f"q{q}_pairs"] = pairs
        rows[f"q{q}_equalities"] = equalities
        if q == 2:
            assert equalities > 0
        else:
            assert equalities == 0
    return rows


def prove_production_moduli(m: int) -> None:
    assert m == PRODUCTION_M and m % 6 == 1
    c = m * m + m + 1
    assert c % 3 == 0 and m * m % 3 == 1
    # For 1<=first<=M-2, x=first*C + M^2, hence x == 1 (mod 3).
    for first in (1, 2, m // 2, m - 2):
        assert initial_value(m, first) == first * c + m * m
        assert initial_value(m, first) % 3 == 1
    # The only wrapped first-values cannot reach a q=3 LIMIT for k=3.
    assert initial_value(m, m - 1) == m * m - 1
    assert initial_value(m, m) == m * m + m
    assert initial_value(m, m) < 3 * (m * m + 1)
    # q2 exact-limit witness is M-2: odd first gives even x.
    assert (m - 2) % 2 == 1
    assert initial_value(m, m - 2) % 2 == 0


def main() -> None:
    small = {str(m): exhaustive_small(m) for m in SMALL_M}
    prove_production_moduli(PRODUCTION_M)
    cases = [evaluate(m, q, d) for m in (*SMALL_M, PRODUCTION_M)
             for q in (2, 3) for d in (-1, 0, 1)]
    assert len(cases) == 36
    print(json.dumps({
        "project_id": PROJECT_ID,
        "mode": "exact_integer_mathematical_oracle_not_native",
        "small_exhaustive_models": small,
        "small_exhaustive_pairs": sum(v[k] for v in small.values()
                                       for k in ("q2_pairs", "q3_pairs")),
        "cases_checked": len(cases), "cases_passed": len(cases), "cases_failed": 0,
        "production_m_bits": PRODUCTION_M.bit_length(),
        "q2_forward_exact_equality": "WITNESS_CONSTRUCTED",
        "q3_forward_exact_equality": "PROVEN_IMPOSSIBLE_FOR_k3",
        "production_witnesses": cases[-6:], "pass": True,
    }, ensure_ascii=False, sort_keys=True, indent=2))


if __name__ == "__main__":
    main()
