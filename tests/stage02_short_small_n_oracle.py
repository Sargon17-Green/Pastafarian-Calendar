#!/usr/bin/env python3
"""Independent small-N short-selector oracle; no WebAssembly execution.

PROJECT_ID PC-BRANCH-WAT-SPANISH. Reference is an explicit step-by-step
ring walk, not the branch's skip implementation or another branch.
"""
from __future__ import annotations
import json

PROJECT_ID = 'PC-BRANCH-WAT-SPANISH'
M = (1 << 127) - 1
SIZES = (1, 2, 4, 11)


def reference_walk(modulus: int, n: int, first: int, step: int) -> tuple[int, int, int]:
    limit = (modulus // n) * n
    value, rejected = first, 0
    while value > limit:
        value = 1 + (value - 1 + step) % modulus
        rejected += 1
        assert rejected <= modulus
    return value, 1 + (value - 1) % n, rejected


def arithmetic_prediction(modulus: int, n: int, first: int, step: int) -> tuple[int, int, int]:
    limit = (modulus // n) * n
    if first <= limit:
        accepted, rejected = first, 0
    elif step == 1:
        accepted, rejected = 1, modulus - first + 1
    else:
        accepted, rejected = limit, first - limit
    return accepted, 1 + (accepted - 1) % n, rejected


def verify() -> dict:
    counts = {'moduli': 0, 'pairs': 0, 'rejections': 0, 'nonzero_rejection_pairs': 0}
    for modulus in range(1, 82):
        counts['moduli'] += 1
        for n in range(1, min(12, modulus) + 1):
            for first in range(1, modulus + 1):
                for step in (-1, 1):
                    expected = reference_walk(modulus, n, first, step)
                    predicted = arithmetic_prediction(modulus, n, first, step)
                    assert expected == predicted, (modulus, n, first, step, expected, predicted)
                    assert 1 <= predicted[1] <= n
                    counts['pairs'] += 1
                    counts['rejections'] += expected[2]
                    counts['nonzero_rejection_pairs'] += int(expected[2] != 0)
    assert counts['moduli'] == 81 and counts['pairs'] == 79132
    assert counts['rejections'] == 14908 and counts['nonzero_rejection_pairs'] == 4724
    production = []
    assert [M % n for n in SIZES] == [0, 1, 3, 6]
    for n in SIZES:
        for step in (-1, 1):
            first = M
            accepted, rank, rejected = arithmetic_prediction(M, n, first, step)
            assert 1 <= accepted <= M and 1 <= rank <= n
            assert rejected == (0 if n == 1 else (1 if step == 1 else M % n))
            if n > 1:
                assert (rank % n) + 1 != rank, 'negative-control rank mutation not detected'
            production.append({'n': str(n), 'step': step, 'first': str(first),
                               'limit': str((M // n) * n), 'accepted': str(accepted),
                               'rank': str(rank), 'rejected': str(rejected),
                               'native': 'NOT_EXECUTED_BY_PYTHON'})
    return {'project_id': PROJECT_ID, 'mode': 'independent_stepwise_small_moduli_plus_exact_production',
            'counts': counts, 'production_cases': len(production), 'production': production,
            'failed': 0, 'native': 'NOT_EXECUTED_BY_PYTHON'}

if __name__ == '__main__':
    print(json.dumps(verify(), ensure_ascii=False, sort_keys=True))
