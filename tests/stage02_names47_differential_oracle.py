#!/usr/bin/env python3
"""Independent integer oracle for the Stage02 positional rejection contract.

This script never imports WAT implementation logic or its test fixtures.
"""
import hashlib
import json
import sys
from math import factorial
from pathlib import Path

M = 2**127 - 1
NAMES47 = factorial(47)
CANDIDATES = [
    ('short_1', 1),
    ('short_10', 10),
    ('short_m', M),
    ('wide_m_plus_1', M + 1),
    ('wide_47factorial_minus1', NAMES47 - 1),
    ('wide_47factorial', NAMES47),
    ('wide_47factorial_plus1', NAMES47 + 1),
    ('wide_m2_minus_m_minus1', M*M - M - 1),
    ('wide_m2_minus_m', M*M - M),
    ('wide_m2_minus_m_plus1', M*M - M + 1),
    ('wide_m2', M*M),
    ('wide_m2_plus1', M*M + 1),
    ('wide_m3', M**3),
    ('wide_m3_plus1', M**3 + 1),
]

def reference(n: int, direction: int) -> tuple[int, int, bool]:
    space, places = M, 1
    while space < n:
        space *= M
        places += 1
    if places == 1:
        raw_position = 1 if direction == 1 else M
    else:
        # Number represented by consecutive positions on the source ring.
        positions = [((0 if direction == 1 else M - 1) + direction * j) % M
                     for j in range(places)]
        raw_position = 1 + sum(position * M**j for j, position in enumerate(positions))
    limit = (space // n) * n
    rejected = raw_position > limit
    accepted_position = (1 if direction == 1 else limit) if rejected else raw_position
    rank = (accepted_position - 1) % n + 1
    return rank, places, rejected

def main():
    output = {'project': 'PC-BRANCH-WAT-SPANISH',
              'scope': 'independent_integer_differential_for_source_fresh_names47_artifact',
              'native_run': False, 'overall_stage02_accepted': False, 'cases': []}
    for name, n in CANDIDATES:
        for mode, direction in [('forward', 1), ('backward', -1)]:
            rank, k, rejected = reference(n, direction)
            output['cases'].append({
                'case': name, 'mode': mode, 'n': str(n), 'k': k,
                'expected_rank': str(rank), 'expected_sha256': hashlib.sha256(str(rank).encode()).hexdigest(),
                'expected_rejection': rejected
            })
    if len(sys.argv) != 2:
        raise SystemExit('USAGE: python stage02_names47_differential_oracle.py OUTPUT.json')
    Path(sys.argv[1]).write_text(json.dumps(output, indent=2, ensure_ascii=False)+'\n')
    print(json.dumps({'cases': len(output['cases']), 'k_counts': {str(k): sum(c['k']==k for c in output['cases']) for k in (1, 2, 3, 4)},
      'reject_count': sum(c['expected_rejection'] for c in output['cases']), 'names47': str(NAMES47)}, ensure_ascii=False))

if __name__ == '__main__':
    main()
