#!/usr/bin/env python3
"""Independent integer oracle for DISCOVERY01 wide-selector liveness.

No WebAssembly dependency, no access to the tested WAT implementation.
Run: python3 tests/stage02_discovery01_forward_liveness_oracle.py
"""

PROJECT_ID = "PC-BRANCH-WAT-SPANISH"
M_PRODUCTION = (1 << 127) - 1


def initial_wide(first: int, step: int, m: int, k: int) -> int:
    assert 1 <= first <= m and step in (-1, 1) and k >= 2
    digits = (((first - 1 + j * step) % m) for j in range(k))
    return 1 + sum(d * m**j for j, d in enumerate(digits))


def params(m: int, n: int, first: int, step: int):
    assert m >= 3 and n > m and 1 <= first <= m and step in (-1, 1)
    space, k = m, 1
    while space < n:
        space *= m
        k += 1
    limit = (space // n) * n
    return space, limit, initial_wide(first, step, m, k)


def bounded_walk(x: int, limit: int, space: int, step: int):
    value, rejected = x, 0
    while value > limit:
        value = 1 + ((value - 1 + step) % space)
        rejected += 1
        assert rejected <= space, "A full cycle must encounter a legal value"
    return value, rejected


def constant_time_accept(x: int, limit: int, step: int):
    if x <= limit:
        return x
    if step == 1:
        return 1  # After wrap from SPACE, 1 is accepted.
    return limit  # Descending from x > LIMIT first reaches LIMIT.


def mathematical_rejection_count(x: int, limit: int, space: int, step: int):
    if x <= limit:
        return 0
    return (space - x + 1) if step == 1 else (x - limit)


def run_exhaustive_small_model():
    cases, rejected_cases, max_rejections = 0, 0, 0
    for m in (3, 5, 7, 11):
        for n in range(m + 1, m**3 + 1):
            for first in range(1, m + 1):
                for step in (-1, 1):
                    space, limit, x = params(m, n, first, step)
                    slow, steps = bounded_walk(x, limit, space, step)
                    fast = constant_time_accept(x, limit, step)
                    analytic_steps = mathematical_rejection_count(x, limit, space, step)
                    assert slow == fast, (m, n, first, step, slow, fast)
                    assert steps == analytic_steps, (m, n, first, step, steps, analytic_steps)
                    assert 1 <= slow <= limit
                    assert 1 <= ((slow - 1) % n) + 1 <= n
                    cases += 1
                    rejected_cases += int(steps > 0)
                    max_rejections = max(max_rejections, steps)
    return cases, rejected_cases, max_rejections


def run_production_proof():
    m = M_PRODUCTION
    n = m*m + 1
    s, limit, x = params(m, n, m-2, 1)
    assert s == m**3
    assert s // n == m-1
    assert x == s-m-2
    assert limit == (m-1)*n
    assert x - limit == m*m - 2*m - 1 > 0
    steps = mathematical_rejection_count(x, limit, s, 1)
    assert steps == m+3 == (1 << 127) + 2
    accepted = constant_time_accept(x, limit, 1)
    assert accepted == 1 and (accepted-1) % n + 1 == 1
    return steps, x-limit


if __name__ == "__main__":
    cases, rejected, worst = run_exhaustive_small_model()
    steps, excess = run_production_proof()
    print(f"PROJECT_ID={PROJECT_ID}")
    print(f"TOY_WIDE_CASES={cases} PASS")
    print(f"TOY_REJECTION_CASES={rejected} PASS")
    print(f"TOY_MAX_REJECTIONS={worst}")
    print(f"PRODUCTION_GAP_X_MINUS_LIMIT={excess}")
    print(f"PRODUCTION_FORWARD_REJECTIONS={steps}")
    print("PRODUCTION_RESULT_RANK=1")
    print("VERDICT=ANALYTICAL_ORACLE_PASS; NATIVE_NOT_RUN; NO_STAGE02_PASS")
