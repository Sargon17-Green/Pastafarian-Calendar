#!/usr/bin/env python3
"""Independent bounded k=5, q=4 ring oracle; math-only, never executes WASM."""
from __future__ import annotations

import json

PROJECT_ID = 'PC-BRANCH-WAT-SPANISH'
M = (1 << 127) - 1
FORWARD_BASES = (11, 15, 19, 23)
BACKWARD_BASES = (31, 35, 39)


def verify_case(base: int, step: int, offset: int, walk: bool):
    assert base >= 11 and base % 4 == 3
    assert step in (-1, 1) and offset in (0, 1)
    first = base - (5 if step == 1 else 1)
    space = base ** 5
    x = 1
    # Independent digit assembly from the literal five ring responses.
    for position in range(5):
        answer = 1 + (first - 1 + step * position) % base
        x += (answer - 1) * (base ** position)
    deficit = (
        base ** 4 + 2 * base ** 3 + 3 * base ** 2 + 4 * base + 5
        if step == 1 else
        5 * base ** 4 + 4 * base ** 3 + 3 * base ** 2 + 2 * base + 1
    )
    assert x == space - deficit and x % 4 == 0
    n = x // 4 - offset
    assert base ** 4 < n < space and space // n == 4
    limit = 4 * n
    assert x - limit == 4 * offset
    expected = x if offset == 0 else (1 if step == 1 else limit)
    expected_rejections = (
        0 if offset == 0 else deficit + 1 if step == 1 else 4
    )
    if walk:
        cursor = x
        rejections = 0
        while cursor > limit:
            cursor = 1 + (cursor - 1 + step) % space
            rejections += 1
            assert rejections <= 350000, 'bounded ring limit exceeded'
        assert (cursor, rejections) == (expected, expected_rejections)
    rank = 1 + (expected - 1) % n
    assert rank == (1 if step == 1 and offset else n)
    return {
        'step': step,
        'offset': offset,
        'first': str(first),
        'n': str(n),
        'initial_x': str(x),
        'space': str(space),
        'limit': str(limit),
        'accepted': str(expected),
        'rank': str(rank),
        'rejections': str(expected_rejections),
    }, expected_rejections


def verify():
    cases = 0
    rejections = 0
    for step, bases in ((1, FORWARD_BASES), (-1, BACKWARD_BASES)):
        for base in bases:
            for offset in (0, 1):
                _, count = verify_case(base, step, offset, True)
                cases += 1
                rejections += count
    assert (cases, rejections) == (14, 526908)
    production = {
        ('forward_' if step == 1 else 'backward_') + ('exact' if offset == 0 else 'rejected'):
            verify_case(M, step, offset, False)[0]
        for step in (1, -1) for offset in (0, 1)
    }
    return {
        'project_id': PROJECT_ID,
        'mode': 'independent_python_math_only_not_native',
        'bounded_cases': cases,
        'bounded_rejections': rejections,
        'production_algebraic_cases': production,
        'failed': 0,
        'native': 'NOT_EXECUTED_BY_PYTHON',
    }


if __name__ == '__main__':
    print(json.dumps(verify(), sort_keys=True))
