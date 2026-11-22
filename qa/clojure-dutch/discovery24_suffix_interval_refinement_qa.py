#!/usr/bin/env python3
"""Independent, resource-limited combinatorial QA for Clojure+Nederlands.

No production imports, normative-oracle imports, copied fixtures, CI, or Native.
The budget below is the unchanged PRODUCTION accounting ceiling; the separate
`expansion_limit` is a QA investigation limit, never a production budget.
"""
from collections import Counter
from itertools import permutations
from math import factorial

PROJECT_ID = 'PC-BRANCH-CLOJURE-DUTCH'
PRODUCTION_BUDGET = 5_000_000
PROFILES = ((2, 2), (2, 3), (3, 2), (2, 2, 2), (3, 3, 2), (4, 4))


def brute_words(multiplicities):
    """Independent oracle: filter complete multiset permutations by first/last positions."""
    base = tuple(x for i, count in enumerate(multiplicities, 1) for x in (i,) * count)
    valid = []
    for candidate in sorted(set(permutations(base))):
        starts = tuple(candidate.index(i) for i in range(1, len(multiplicities) + 1))
        ends = tuple(len(candidate) - 1 - candidate[::-1].index(i)
                     for i in range(1, len(multiplicities) + 1))
        if starts == tuple(sorted(starts)) and ends == tuple(sorted(ends)):
            valid.append(candidate)
    return valid


def choices(state):
    """One-step grammar independently specified by opening and closing order."""
    remaining, opened, closed = state
    for letter in range(1, min(len(remaining), opened + 1) + 1):
        amount = remaining[letter - 1]
        if amount == 0:
            continue
        if amount == 1 and letter != closed + 1:
            continue
        child = list(remaining)
        child[letter - 1] -= 1
        yield letter, (tuple(child), max(opened, letter), closed + (amount == 1))


def broad_upper(remaining):
    denominator = 1
    for x in remaining:
        denominator *= factorial(x)
    return factorial(sum(remaining)) // denominator


def count_interval(state, expansion_limit):
    """Return certified inclusive [low, high] by expanding at most N states.

    Terminal is exact; an unexpanded feasible state has [1, multinomial].
    Expanded child languages are disjoint because their first symbols differ;
    sum of inclusive bounds remains admissible. This method is independent of
    the polynomial insertion counter used by production.
    """
    if expansion_limit < 0:
        raise ValueError('negative investigation limit')
    cache = {}
    remaining_limit = [expansion_limit]
    def visit(current):
        remaining = current[0]
        if not any(remaining):
            return (1, 1)
        if current in cache:
            return cache[current]
        if remaining_limit[0] == 0:
            return (1, broad_upper(remaining))
        remaining_limit[0] -= 1
        children = [child for _, child in choices(current)]
        if not children:
            raise AssertionError(('reachable state has no completions', current))
        intervals = [visit(child) for child in children]
        result = (sum(z[0] for z in intervals), sum(z[1] for z in intervals))
        # Independent unrestricted upper bound may tighten the disjoint sum.
        result = (result[0], min(result[1], broad_upper(remaining)))
        assert 1 <= result[0] <= result[1]
        cache[current] = result
        return result
    result = visit(state)
    return result, expansion_limit - remaining_limit[0]


def production_charge(child):
    rem, opened, _ = child
    return 1 + (len(rem) - opened + 1) * (1 + sum(rem))


def appends_in_toevoegen(child):
    """Only modeled vector appends, intentionally NOT total allocation cost."""
    rem, opened, closed = child
    if not any(rem):
        return 0
    active = sum(rem[closed:opened]) if opened else rem[0]
    start = opened if opened else 1
    appends = 0
    for index in range(start, len(rem)):
        appends += active + 1
        active += rem[index]
    return appends


def rank_path(profile, ordinal, stop_at, expansion_limit, oracle=None,
              charge_limit=PRODUCTION_BUDGET):
    """Rank decisions use ONLY certified count intervals, never oracle counts.

    oracle, when supplied, is a post-decision assertion, not a decision input.
    """
    if len(profile) < 2 or any(x < 2 for x in profile):
        raise ValueError('profile must contain >=2 months of >=2 occurrences')
    if ordinal < 1 or not (1 <= stop_at <= sum(profile)):
        raise ValueError('invalid ordinal or position')
    if charge_limit < 1 or charge_limit > PRODUCTION_BUDGET:
        raise ValueError('invalid production charge bound')
    if oracle is not None and ordinal > len(oracle):
        raise ValueError('out-of-range ordinal')
    state = (tuple(profile), 0, 0)
    built = ()
    lo_rank = hi_rank = ordinal
    real_rank = ordinal
    billed = appends = tested = skipped = 0
    while len(built) < stop_at:
        advanced = False
        for letter, child in choices(state):
            interval, expanded = count_interval(child, expansion_limit)
            low, high = interval
            if oracle is not None:
                pfx = built + (letter,)
                true_count = sum(w[:len(pfx)] == pfx for w in oracle)
                assert low <= true_count <= high, (profile, pfx, interval, true_count)
                assert lo_rank <= real_rank <= hi_rank
            if lo_rank > high:
                take = False
            elif hi_rank <= low:
                take = True
            else:
                return dict(status='UNPROVEN_SUFFIX_INTERVAL', prefix=built,
                            rank_window=(lo_rank, hi_rank), block_window=interval,
                            candidate=letter, expansions=expanded, billed=billed)
            charge = production_charge(child)
            if billed + charge > charge_limit:
                return dict(status='REFUSED_BUDGET', prefix=built,
                            next_candidate=letter, billed=billed,
                            proposed=billed + charge, tested=tested + 1)
            billed += charge
            tested += 1
            appends += appends_in_toevoegen(child)
            assert appends <= billed
            if not take:
                if oracle is not None:
                    assert real_rank > true_count
                    real_rank -= true_count
                lo_rank, hi_rank = lo_rank - high, hi_rank - low
                assert lo_rank >= 1
                skipped += 1
            else:
                if oracle is not None:
                    assert real_rank <= true_count
                state = child
                built += (letter,)
                advanced = True
                break
        if not advanced:
            raise AssertionError(('no selected letter', profile, ordinal, built))
    assert oracle is None or built == oracle[ordinal - 1][:stop_at]
    return dict(status='CERTIFIED_PREFIX', prefix=built,
                rank_window=(lo_rank, hi_rank), billed=billed,
                appends=appends, tested=tested, skipped=skipped)


def main():
    words_total = pairs = 0
    resolved = Counter()
    no_false_positive = Counter()
    strict_gap = None
    equality = lower_exclusion = 0
    modes = (0, 1, 4, 16, 128, 4096)
    for profile in PROFILES:
        oracle = brute_words(profile)
        words_total += len(oracle)
        for rank, full_word in enumerate(oracle, 1):
            for position in range(1, len(full_word) + 1):
                pairs += 1
                exact = rank_path(profile, rank, position, 4096, oracle)
                assert exact['status'] == 'CERTIFIED_PREFIX'
                assert exact['prefix'] == full_word[:position]
                assert exact['rank_window'][0] == exact['rank_window'][1]
                assert exact['appends'] <= exact['billed']
                if strict_gap is None and exact['appends'] < exact['billed']:
                    strict_gap = (profile, rank, position, exact['billed'], exact['appends'])
                edge = rank_path(profile, rank, position, 4096, oracle,
                                 charge_limit=exact['billed'])
                assert edge['status'] == 'CERTIFIED_PREFIX'
                equality += 1
                if exact['billed'] > 1:
                    below = rank_path(profile, rank, position, 4096, oracle,
                                      charge_limit=exact['billed'] - 1)
                    assert below['status'] == 'REFUSED_BUDGET'
                    assert below['billed'] < below['proposed']
                    lower_exclusion += 1
                for limit in modes:
                    attempt = rank_path(profile, rank, position, limit, oracle)
                    if attempt['status'] == 'CERTIFIED_PREFIX':
                        resolved[limit] += 1
                        assert attempt['prefix'] == full_word[:position]
                        assert attempt['billed'] == exact['billed']
                    else:
                        assert attempt['status'] == 'UNPROVEN_SUFFIX_INTERVAL'
                        no_false_positive[limit] += 1
    assert pairs == 436 and words_total == 59
    assert resolved[0] == 36 and resolved[4096] == pairs
    assert strict_gap and lower_exclusion == equality == pairs
    for limit in modes:
        assert resolved[limit] + no_false_positive[limit] == pairs
    for rank in (0, len(brute_words((2, 2))) + 1):
        try:
            rank_path((2, 2), rank, 1, 4096, brute_words((2, 2)))
            raise AssertionError('invalid ordinal accepted')
        except ValueError:
            pass
    for invalid in (0, PRODUCTION_BUDGET + 1):
        try:
            rank_path((2, 2), 1, 1, 4096, brute_words((2, 2)), invalid)
            raise AssertionError('invalid production budget accepted')
        except ValueError:
            pass
    print('PROJECT_ID', PROJECT_ID)
    print('QA_ONLY', 'production_unchanged', 'search_128N_unchanged',
          'budget_ceiling', PRODUCTION_BUDGET)
    print('PROFILES', len(PROFILES), 'LEGAL_WORDS', words_total,
          'RANK_POSITION_PAIRS', pairs)
    for limit in modes:
        print('EXPANSION_LIMIT', limit, 'CERTIFIED_PREFIX', resolved[limit],
              'UNPROVEN', no_false_positive[limit])
    print('BUDGET_EQUALITY_ACCEPT', equality, 'BUDGET_MINUS_ONE_REFUSED', lower_exclusion)
    print('RAMING_VS_APPEND_STRICT_GAP', strict_gap)
    print('CANONICAL_P82_P520', 'UNPROVEN', 'FIVE_FIELD_DIFFERENTIAL', 'NOT_RUN',
          'NEW_NATIVE', 'NOT_RUN', 'STAGE2', 'OPEN')


if __name__ == '__main__':
    main()
