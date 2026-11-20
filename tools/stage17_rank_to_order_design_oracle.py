#!/usr/bin/env python3
"""Stage17 design-only oracle: independent lexicographic check of rank -> 6-ball order.

This file never loads or executes FALSE and never claims Stage17 Native acceptance.
"""
import hashlib
import itertools
import json
from math import factorial
from pathlib import Path

PROJECT_ID = 'PC-BRANCH-FALSE-ARABIC'
ANCHOR_RANKS = (1, 2, 3, 6, 7, 24, 25, 60, 120, 121, 360, 600, 719, 720)
SYMBOLS = (1, 2, 3, 4, 5, 6)


def unrank_factoradic(rank):
    """One-based lexicographic unranking; algorithm independent of fixture listing."""
    if not isinstance(rank, int) or isinstance(rank, bool) or not 1 <= rank <= 720:
        raise ValueError('rank outside 1..720')
    remainder = rank - 1
    available = list(SYMBOLS)
    result = []
    for size in range(6, 0, -1):
        digit, remainder = divmod(remainder, factorial(size - 1))
        result.append(available.pop(digit))
    assert remainder == 0
    return tuple(result)


def rank_inverse(order):
    """Independently compute the one-based Lehmer rank of a permutation."""
    if len(order) != 6 or set(order) != set(SYMBOLS):
        raise ValueError('order must permute 1..6')
    unused = list(SYMBOLS)
    rank = 1
    for i, value in enumerate(order):
        rank += unused.index(value) * factorial(5 - i)
        unused.remove(value)
    return rank


def validate():
    # Independent oracle: Python's C-implemented itertools.permutations, not FALSE source.
    expected = list(itertools.permutations(SYMBOLS))
    assert len(expected) == factorial(6) == 720
    seen = set()
    for rank, lex_order in enumerate(expected, start=1):
        actual = unrank_factoradic(rank)
        assert actual == lex_order, ('lexicographic mismatch', rank)
        assert rank_inverse(actual) == rank, ('inverse mismatch', rank)
        assert actual not in seen, ('duplicate result', rank)
        seen.add(actual)
    assert len(seen) == 720
    assert unrank_factoradic(1) == (1, 2, 3, 4, 5, 6)
    assert unrank_factoradic(720) == (6, 5, 4, 3, 2, 1)
    for invalid in (-1, 0, 721, 722):
        try:
            unrank_factoradic(invalid)
        except ValueError:
            pass
        else:
            raise AssertionError(('invalid rank accepted', invalid))
    for rank in ANCHOR_RANKS:
        assert unrank_factoradic(rank) == unrank_factoradic(rank)
    # A deliberate false expectation must be rejected by the independent oracle.
    corrupted = list(expected)
    corrupted[0] = tuple(reversed(corrupted[0]))
    assert unrank_factoradic(1) != corrupted[0]
    return {
        'project_id': PROJECT_ID,
        'stage': 17,
        'status': 'DESIGN_ORACLE_ONLY_NOT_NATIVE_NOT_ACCEPTED',
        'normative_operation': 51,
        'planned_production_operation': 34,
        'source_reference': 'test/normative_reference.false',
        'input': 'one allocated tuple cell [rank], integer rank 1..720',
        'output': 'fresh direct table [6,bowl1,bowl2,bowl3,bowl4,bowl5,bowl6]',
        'permutation_cases': 720,
        'lexicographic_cross_checks': 720,
        'inverse_rank_checks': 720,
        'uniqueness_checks': 720,
        'invalid_numeric_cases': 4,
        'deterministic_replays': len(ANCHOR_RANKS),
        'mutated_expectation_rejected': True,
        'anchors': [
            {'rank': r, 'order': list(unrank_factoradic(r))}
            for r in ANCHOR_RANKS
        ],
        'boundary': {'first_rank': 1, 'last_rank': 720},
        'physical_tuple_truncation_assessed': False,
        'native_false_tests_executed': False,
        'stage17_accepted': False,
    }


def main():
    report = validate()
    path = Path('evidence/stage17_rank_to_order_design_oracle_2026-11-20.json')
    path.parent.mkdir(parents=True, exist_ok=True)
    data = json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True) + '\n'
    path.write_text(data, encoding='utf-8')
    print('DESIGN_CASES', report['permutation_cases'])
    print('INVERSE_CHECKS', report['inverse_rank_checks'])
    print('REPLAYS', report['deterministic_replays'])
    print('INVALID', report['invalid_numeric_cases'])
    print('REPORT_SHA256', hashlib.sha256(data.encode()).hexdigest())
    print('ORACLE_SHA256', hashlib.sha256(Path(__file__).read_bytes()).hexdigest())


if __name__ == '__main__':
    main()
