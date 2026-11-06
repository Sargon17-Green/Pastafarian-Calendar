#!/usr/bin/env python3
"""Independent bounded short-route q=4,5 differential QA for WAT+Español.

Mathematical oracle only; does not execute WebAssembly or reuse another branch.
"""
from __future__ import annotations

import json

PROJECT_ID = 'PC-BRANCH-WAT-SPANISH'
M = (1 << 127) - 1


def ring_successor(value: int, direction: int, modulus: int) -> int:
    assert 1 <= value <= modulus and direction in (-1, 1)
    return 1 + ((value - 1 + direction) % modulus)


def independent_stepwise(modulus: int, n: int, first: int, direction: int) -> tuple[int, int, int]:
    quota = modulus // n
    limit = quota * n
    value = first
    for rejected in range(modulus + 1):
        if value <= limit:
            return value, (value - 1) % n + 1, rejected
        value = ring_successor(value, direction, modulus)
    raise AssertionError('full ring exhausted without acceptance')


def arithmetic_candidate(modulus: int, n: int, first: int, direction: int) -> tuple[int, int]:
    quota = modulus // n
    limit = quota * n
    if first <= limit:
        accepted = first
    elif direction == 1:
        accepted = 1
    else:
        accepted = limit
    return accepted, (accepted - 1) % n + 1


def verify() -> dict:
    per_q = {4: {'n': 0, 'pairs': 0, 'rejections': 0},
             5: {'n': 0, 'pairs': 0, 'rejections': 0}}
    max_rejections = 0
    for modulus in range(11, 100, 2):
        for n in range(1, modulus + 1):
            q = modulus // n
            if q not in per_q:
                continue
            per_q[q]['n'] += 1
            for first in range(1, modulus + 1):
                for direction in (-1, 1):
                    expected_value, expected_rank, rejected = independent_stepwise(modulus, n, first, direction)
                    actual_value, actual_rank = arithmetic_candidate(modulus, n, first, direction)
                    assert (actual_value, actual_rank) == (expected_value, expected_rank), (
                        modulus, n, first, direction, (actual_value, actual_rank),
                        (expected_value, expected_rank))
                    assert 1 <= actual_rank <= n
                    assert rejected <= modulus
                    per_q[q]['pairs'] += 1
                    per_q[q]['rejections'] += rejected
                    max_rejections = max(max_rejections, rejected)
    assert per_q == {
        4: {'n': 119, 'pairs': 16162, 'rejections': 8548},
        5: {'n': 87, 'pairs': 11538, 'rejections': 4264},
    }, per_q

    production = []
    for q in (4, 5):
        n = M // (q + 1) + 1
        assert M // n == q
        limit = q * n
        assert limit < M
        for first in (1, limit, limit + 1, M):
            for direction in (-1, 1):
                selected, rank = arithmetic_candidate(M, n, first, direction)
                expected_selected = first if first <= limit else (1 if direction == 1 else limit)
                assert selected == expected_selected and rank == ((selected - 1) % n) + 1
                assert 1 <= rank <= n
                if n > 1:
                    mutant_rank = (rank % n) + 1
                    assert mutant_rank != rank, 'negative control did not alter rank'
                production.append({'q': q, 'first': str(first), 'step': direction,
                                   'n': str(n), 'limit': str(limit),
                                   'accepted': str(selected), 'rank': str(rank),
                                   'native': 'NOT_EXECUTED_BY_PYTHON'})
    assert len(production) == 16
    assert sum(v['pairs'] for v in per_q.values()) == 27700
    assert sum(v['rejections'] for v in per_q.values()) == 12812
    return {
        'project_id': PROJECT_ID,
        'test': 'independent_q4_q5_short_bounded_differential',
        'mode': 'math_python_only_not_native',
        'moduli': 45,
        'by_q': per_q,
        'max_rejections': max_rejections,
        'total_pairs': sum(v['pairs'] for v in per_q.values()),
        'total_rejections': sum(v['rejections'] for v in per_q.values()),
        'production_cases': len(production),
        'production_probes': production,
        'failed': 0,
    }


if __name__ == '__main__':
    print(json.dumps(verify(), ensure_ascii=False, indent=2, sort_keys=True))
