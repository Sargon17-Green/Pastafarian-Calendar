#!/usr/bin/env python3
"""Independent rank-path bounds for DISCOVERY24; QA only, no production imports.

The permissive suffix interval [1, multinomial] is globally admissible for
reachable, legal states. An undecidable interval is always UNPROVEN, never PASS.
Exact tiny-family counts come from a separately brute-enumerated word oracle.
"""
from collections import Counter
from math import factorial

PROJECT_ID = 'PC-BRANCH-CLOJURE-DUTCH'
BUDGET = 5_000_000


def independent_words(profile):
    """Brute multiset enumeration with a final first/last-order predicate."""
    counts = list(profile)
    out = []
    n = len(counts)
    def visit(seq):
        if not any(counts):
            last = [max(k for k, v in enumerate(seq) if v == i) for i in range(1, n + 1)]
            first = [seq.index(i) for i in range(1, n + 1)]
            if first == sorted(first) and last == sorted(last):
                out.append(tuple(seq))
            return
        for i in range(n):
            if counts[i] > 0:
                counts[i] -= 1
                visit(seq + [i + 1])
                counts[i] += 1
    visit([])
    return sorted(out)


def candidates(rest, opened, closed):
    for month in range(1, min(len(rest), opened + 1) + 1):
        n = rest[month - 1]
        if n <= 0 or (n == 1 and month != closed + 1):
            continue
        child = list(rest)
        child[month - 1] -= 1
        yield month, tuple(child), max(opened, month), closed + int(n == 1)


def charge_upper(rest, opened):
    # Exact Clojure raming charge, separately derived from the published formula.
    return 1 + (len(rest) - opened + 1) * (1 + sum(rest))


def toevoegen_conj_cells(rest, opened, closed):
    """Only `conj` operations in `toevoegen`, not all allocations/runtime.

    `tel-rest` returns immediately for the zero remainder; otherwise it calls
    toevoegen once for each unopened month. In each call, its loop appends
    t+1 items for t existing active days, then increments t by the new b.
    """
    if not any(rest):
        return 0
    t = sum(rest[closed:opened]) if opened else rest[0]
    start = opened if opened else 1
    work = 0
    for i in range(start, len(rest)):
        work += t + 1
        t += rest[i]
    return work


def bounds(rest):
    """Admissible combinatorial interval; no normative count imported.

    A legal reachable candidate always has at least one completion: append
    the remaining letters in ascending order. Discarding both first/last
    constraints gives the unrestricted multinomial as an upper bound.
    """
    if not any(rest):
        return (1, 1)
    denominator = 1
    for k in rest:
        denominator *= factorial(k)
    top = factorial(sum(rest)) // denominator
    return 1, top


def trace(profile, rank, position, words=None, budget=BUDGET):
    if not (2 <= len(profile) and all(x >= 2 for x in profile)):
        raise ValueError('invalid profile')
    if not (1 <= position <= sum(profile)) or not (1 <= budget <= BUDGET):
        raise ValueError('invalid position or budget')
    total = len(words) if words is not None else None
    if rank < 1 or (total is not None and rank > total):
        raise ValueError('invalid rank')
    rest, opened, closed = tuple(profile), 0, 0
    word, charges, conj_cells, examined = [], 0, 0, 0
    rank_low = rank_high = rank
    for _ in range(position):
        selected = False
        for month, child, no, nc in candidates(rest, opened, closed):
            prefix = tuple(word + [month])
            lo, hi = bounds(child)
            if words is None:
                # Only make a decision if every admissible exact count agrees.
                if rank_low > hi:
                    skip = True
                    # The skipped block is only known to lie in [lo,hi].
                    # Never subtract hi as though it were the exact size.
                    next_rank_interval = (rank_low - hi, rank_high - lo)
                elif rank_high <= lo:
                    skip = False
                    next_rank_interval = (rank_low, rank_high)
                else:
                    return {'status': 'UNPROVEN_SUFFIX_INTERVAL',
                            'position': len(word) + 1, 'month': month,
                            'lower': lo, 'upper': hi,
                            'rank_interval': (rank_low, rank_high),
                            'charged': charges, 'conj_cells': conj_cells}
            else:
                suffix = sum(w[:len(prefix)] == prefix for w in words)
                assert lo <= suffix <= hi, (profile, rank, prefix, suffix, lo, hi)
                skip = rank > suffix
            step = charge_upper(child, no)
            actual = toevoegen_conj_cells(child, no, nc)
            assert 0 <= actual <= step, (profile, prefix, step, actual)
            examined += 1
            if charges + step > budget:
                return {'status': 'REFUSED_BUDGET', 'position': len(word) + 1,
                        'safe': charges, 'proposed': charges + step,
                        'examined': examined}
            charges += step
            conj_cells += actual
            if skip:
                if words is None:
                    rank_low, rank_high = next_rank_interval
                else:
                    rank -= suffix
            else:
                word.append(month)
                rest, opened, closed = child, no, nc
                selected = True
                break
        if not selected:
            raise AssertionError(('no admissible next letter', profile, rank, word))
    return {'status': 'EXACT_TINY' if words is not None else 'INTERVAL_RESOLVED',
            'prefix': tuple(word), 'charged': charges, 'conj_cells': conj_cells,
            'examined': examined}


def self_test():
    profiles = ((2, 2), (2, 3), (3, 2), (2, 2, 2), (3, 3, 2), (4, 4))
    words_seen = checks = safe_rejections = partial_intervals = 0
    counterexample = None
    for p in profiles:
        words = independent_words(p)
        words_seen += len(words)
        for rank, word in enumerate(words, 1):
            for position in range(1, len(word) + 1):
                accepted = trace(p, rank, position, words)
                assert accepted['status'] == 'EXACT_TINY'
                assert accepted['prefix'] == word[:position]
                assert accepted['conj_cells'] <= accepted['charged']
                assert trace(p, rank, position, words,
                             max(1, accepted['charged'] - 1))['status'] == 'REFUSED_BUDGET'
                at_limit = trace(p, rank, position, words, accepted['charged'])
                assert at_limit['status'] == 'EXACT_TINY'
                if counterexample is None and accepted['conj_cells'] < accepted['charged']:
                    counterexample = (p, rank, position, accepted['charged'], accepted['conj_cells'])
                interval = trace(p, rank, position)
                if interval['status'] == 'INTERVAL_RESOLVED':
                    assert interval['prefix'] == word[:position]
                    safe_rejections += 1
                else:
                    assert interval['status'] == 'UNPROVEN_SUFFIX_INTERVAL'
                    partial_intervals += 1
                checks += 1
    assert counterexample is not None and partial_intervals > 0
    assert 4_995_675 <= BUDGET < 5_002_652
    # This is a historical limited accounting assertion, not canonical re-proof.
    for invalid in (((2, 2), 0, 1), ((2, 2), 3, 1)):
        p, r, pos = invalid
        try:
            trace(p, r, pos, independent_words(p))
            raise AssertionError('invalid rank accepted')
        except ValueError:
            pass
    print('PROJECT_ID', PROJECT_ID)
    print('STATIC_QA_PASS profiles', len(profiles), 'words', words_seen,
          'rank_positions', checks, 'interval_resolved', safe_rejections,
          'interval_unproven', partial_intervals)
    print('RAMING_VS_CONJ_COUNTEREXAMPLE', counterexample)
    print('HISTORICAL_P81_P82_LIMITED', 4_995_675, 5_002_652)
    print('CANONICAL_P82_P520', 'UNPROVEN', 'FIVE_FIELD', 'NOT_RUN',
          'NATIVE', 'NOT_RUN', 'STAGE2', 'OPEN')


if __name__ == '__main__':
    self_test()
