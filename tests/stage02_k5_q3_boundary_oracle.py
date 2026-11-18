#!/usr/bin/env python3
"""Independent k=5, q=3 ring-walk boundary oracle (math-only, no WASM)."""
from __future__ import annotations
import json

PROJECT_ID = 'PC-BRANCH-WAT-SPANISH'
M = (1 << 127) - 1
BASES = (31, 34, 37, 40)
CASES = (
    ('forward_exact', 1, 0),
    ('forward_wrap', 1, 1),
    ('backward_exact', -1, 0),
    ('backward_three', -1, 1),
)


def calculate(base: int, step: int, offset: int, walk: bool):
    h = 4 if step == 1 else 3
    first = base - h
    cursor, power, x = first, 1, 1
    for _ in range(5):
        x += (cursor - 1) * power
        cursor = 1 + (cursor - 1 + step) % base
        power *= base
    space = base ** 5
    polynomial = (
        space - (base ** 3 + 2 * base ** 2 + 3 * base + 4)
        if step == 1 else
        space - (7 * base ** 4 + 6 * base ** 3 + 5 * base ** 2 + 4 * base + 3)
    )
    assert x == polynomial and x % 3 == 0
    n = x // 3 - offset
    assert base ** 4 < n < space and space // n == 3
    limit = 3 * n
    assert limit == x - 3 * offset
    accepted = x if offset == 0 else (1 if step == 1 else limit)
    expected_rejections = (
        0 if offset == 0 else (space - x + 1 if step == 1 else 3)
    )
    if walk:
        current, rejections = x, 0
        while current > limit:
            current = 1 + (current - 1 + step) % space
            rejections += 1
            assert rejections <= 100000, 'bounded ring budget exceeded'
        assert (current, rejections) == (accepted, expected_rejections)
    rank = (accepted - 1) % n + 1
    assert rank == (1 if step == 1 and offset else n)
    assert cursor == (1 if step == 1 else base - 8)
    return {'n': str(n), 'rank': str(rank),
            'rejections': str(expected_rejections)}, expected_rejections


def verify():
    bounded, steps = 0, 0
    for base in BASES:
        for _, step, offset in CASES:
            _, rejected = calculate(base, step, offset, True)
            bounded += 1
            steps += rejected
    assert bounded == 16 and steps == 194378
    production = {
        name: calculate(M, step, offset, False)[0]
        for name, step, offset in CASES
    }
    return {'project_id': PROJECT_ID, 'bounded_cases': bounded,
            'bounded_rejection_steps': steps, 'production_cases': production,
            'failed': 0, 'native': 'NOT_EXECUTED_BY_PYTHON'}


if __name__ == '__main__':
    print(json.dumps(verify(), sort_keys=True))
