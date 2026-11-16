#!/usr/bin/env python3
"""Independent k=4 q=1 edge model; exhaustive bounded ring walks, no WASM imports."""
from __future__ import annotations
import json

PROJECT_ID = 'PC-BRANCH-WAT-SPANISH'
KINDS = (
    ('backward_exact', 2, -1, 0),
    ('backward_two', 2, -1, 2),
    ('forward_exact', -3, 1, 0),
    ('forward_skip', -3, 1, 1),
)

def get_x(base: int, first: int, step: int) -> tuple[int, int]:
    cursor, weight, x = first, 1, 1
    for _ in range(4):
        x += (cursor - 1) * weight
        weight *= base
        cursor = 1 + (cursor - 1 + step) % base
    return x, cursor

def walk(space: int, x: int, limit: int, step: int) -> tuple[int, int]:
    cursor, rejects = x, 0
    while cursor > limit:
        cursor = 1 + (cursor - 1 + step) % space
        rejects += 1
        assert rejects < 20000, 'bounded walk budget exceeded'
    return cursor, rejects

def verify() -> dict:
    checked, rejected_total = 0, 0
    for base in range(4, 33):
        space = base ** 4
        for name, first_code, step, offset in KINDS:
            first = first_code if first_code > 0 else base + first_code
            x, after_digits = get_x(base, first, step)
            algebraic_x = (space - base ** 3 - base ** 2 + 2 if step == -1
                           else space - base ** 2 - 2 * base - 3)
            assert x == algebraic_x and 1 <= after_digits <= base, (base, name)
            n = x - offset
            assert base ** 3 < n < space and space // n == 1, (base, name)
            limit = n
            accepted, rejects = walk(space, x, limit, step)
            expected_rejects = (0 if offset == 0 else offset if step == -1
                                else base ** 2 + 2 * base + 4)
            expected = x if offset == 0 else limit if step == -1 else 1
            rank = 1 + (accepted - 1) % n
            assert (accepted, rank, rejects) == (expected, expected, expected_rejects), (base, name)
            checked += 1
            rejected_total += rejects
    assert checked == 116 and rejected_total == 12644
    m = (1 << 127) - 1
    for name, first_code, step, offset in KINDS:
        first = first_code if first_code > 0 else m + first_code
        x, _ = get_x(m, first, step)
        space, n = m ** 4, x - offset
        assert space // n == 1 and m ** 3 < n < space
        predicted = x if offset == 0 else n if step == -1 else 1
        rank = 1 + (predicted - 1) % n
        assert rank == predicted, name
    return {'project_id': PROJECT_ID, 'mode': 'bounded_stepwise_k4_q1_independent',
            'moduli': 29, 'bounded_cases': checked, 'bounded_rejection_steps': rejected_total,
            'production_algebraic_cases': 4, 'failed': 0, 'native': 'NOT_EXECUTED_BY_PYTHON'}

if __name__ == '__main__':
    print(json.dumps(verify(), sort_keys=True))
