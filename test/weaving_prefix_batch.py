#!/usr/bin/env python3
"""Research: share transfer-DP states across all next-symbol candidates.

No production imports. Baseline transfer and finite oracle are separate modules.
"""
from itertools import product
from collections import Counter
from time import monotonic
from weaving_prefix_transfer import count_prefix, weight


def specs_for_prefix(lengths, prefix):
    specs = [None, None]
    for month in range(2, len(lengths) + 1):
        gaps = [0]
        for symbol in prefix:
            if symbol > month:
                continue
            if symbol == month:
                gaps[-1] += 1
            else:
                gaps.append(0)
        fixed = gaps[:-1]
        specs.append((len(fixed), sum(fixed),
                      next((i for i, x in enumerate(fixed) if x), -1),
                      gaps[-1]))
    return specs


def extend_spec(spec, month, candidate):
    q, fixed_sum, first_fixed, tail = spec
    if month == candidate:
        return q, fixed_sum, first_fixed, tail + 1
    # For a larger month, the appended candidate becomes an old letter,
    # freezing the old trailing gap and creating a new empty trailing gap.
    if first_fixed < 0 and tail:
        first_fixed = q
    return q + 1, fixed_sum + tail, first_fixed, 0


def transfer(previous, n, k, spec):
    q, fixed_sum, first_fixed, tail = spec
    out = [0] * (n + k + 1)
    summed = 0
    for gap in range(n + 1):
        summed += previous[gap]
        if summed:
            ways = weight(gap, n, k, q, fixed_sum, first_fixed, tail)
            if ways:
                out[gap + 1] = summed * ways
    return out


def candidate_counts(lengths, prefix=()):
    """Exact counts for each possible next symbol; one shared DP prefix chain.

    For candidate c, stages j<c are unchanged. At j=c only the tail
    is extended; at j>c the prior tail is frozen. Baseline states
    through j=c-1 are reused. O(m^2*N) bigint operations worst case.
    """
    m, length = len(lengths), sum(lengths)
    if m == 0 or any(x <= 0 for x in lengths):
        raise ValueError('positive nonempty lengths required')
    if len(prefix) > length or any(
        not isinstance(x, int) or x < 1 or x > m for x in prefix
    ):
        raise ValueError('invalid prefix')
    if len(prefix) == length:
        return (0,) * m
    consumed = Counter(prefix)
    if any(consumed[i] > lengths[i - 1] for i in range(1, m + 1)):
        return (0,) * m
    specs = specs_for_prefix(lengths, prefix)
    sizes = [0] * (m + 1)
    baselines = [None] * (m + 1)
    n = lengths[0]
    base = [0] * (n + 1)
    base[1] = 1
    baselines[1], sizes[1] = base, n
    for j in range(2, m + 1):
        base = transfer(base, n, lengths[j - 1], specs[j])
        n += lengths[j - 1]
        baselines[j], sizes[j] = base, n
    result = []
    first_unopened = next((j for j in range(1, m + 1) if consumed[j] == 0), m + 1)
    for candidate in range(1, m + 1):
        if (consumed[candidate] == lengths[candidate - 1]
                or (consumed[candidate] == 0 and candidate != first_unopened)
                or (consumed[candidate] == lengths[candidate - 1] - 1
                    and any(consumed[j] < lengths[j - 1]
                            for j in range(1, candidate)))):
            result.append(0)
            continue
        dp = baselines[max(1, candidate - 1)]
        start = max(2, candidate)
        for j in range(start, m + 1):
            dp = transfer(dp, sizes[j - 1], lengths[j - 1],
                          extend_spec(specs[j], j, candidate))
        result.append(sum(dp))
    return tuple(result)


def batched_rank(lengths, word):
    if len(word) != sum(lengths) or Counter(word) != Counter({
        j: k for j, k in enumerate(lengths, 1)
    }):
        raise ValueError('invalid multiplicity')
    rank, prefix = 0, ()
    for symbol in word:
        blocks = candidate_counts(lengths, prefix)
        if blocks[symbol - 1] == 0:
            raise ValueError('illegal first/last appearance order')
        rank += sum(blocks[:symbol - 1])
        prefix += (symbol,)
    return rank


def batched_unrank(lengths, rank):
    total = count_prefix(lengths)
    if not 0 <= rank < total:
        raise ValueError('rank out of bounds')
    prefix = ()
    for _ in range(sum(lengths)):
        for symbol, ways in enumerate(candidate_counts(lengths, prefix), 1):
            if rank >= ways:
                rank -= ways
            else:
                prefix += (symbol,)
                break
        else:
            raise AssertionError('no possible continuation')
    assert rank == 0
    return prefix


def test_finite():
    # Direct enumeration of all words, independent of the transfer DP.
    def brute(lengths):
        remain = list(lengths)
        out = []
        first = [None] * len(lengths)
        last = [None] * len(lengths)
        def visit(w):
            if not any(remain):
                if all(first[i] < first[i+1] and last[i] < last[i+1]
                       for i in range(len(lengths)-1)):
                    out.append(tuple(w))
                return
            for i, left in enumerate(remain):
                if left:
                    remain[i] -= 1
                    prev_first, prev_last = first[i], last[i]
                    if first[i] is None:
                        first[i] = len(w)
                    last[i] = len(w)
                    w.append(i + 1)
                    visit(w)
                    w.pop()
                    first[i], last[i] = prev_first, prev_last
                    remain[i] += 1
        visit([])
        return out

    cases = [p for m in range(1, 5) for p in product(range(1, 5), repeat=m)
             if sum(p) <= 8]
    cases += [(2, 2, 2, 2, 2), (2, 3, 2, 2), (3, 2, 3, 2),
              (2, 2, 3, 3), (3, 3, 2, 2), (4, 3, 2),
              (2, 4, 3), (1, 2, 1, 3), (3, 1, 2, 2)]
    cases = list(dict.fromkeys(cases))
    checks = roundtrips = 0
    for lengths in cases:
        accepted = brute(lengths)
        counts = Counter(p for word in accepted for p in
                         (word[:k] for k in range(len(word) + 1)))
        for prefix in counts:
            blocks = candidate_counts(lengths, prefix)
            assert blocks == tuple(counts.get(prefix + (j,), 0)
                                   for j in range(1, len(lengths)+1)), (lengths, prefix)
            assert sum(blocks) == (counts[prefix] if len(prefix) < sum(lengths) else 0)
            checks += len(blocks)
        for r, word in enumerate(accepted):
            assert batched_rank(lengths, word) == r
            assert batched_unrank(lengths, r) == word
            roundtrips += 2
        if len(lengths) >= 2:
            assert candidate_counts(lengths, (len(lengths),)) == (0,) * len(lengths)
            checks += len(lengths)
    assert len(cases) == 137 and roundtrips == 1982
    print('WEAVING_BATCH_CASES=137')
    print(f'WEAVING_BATCH_CANDIDATE_CHECKS={checks}')
    print(f'WEAVING_BATCH_RANK_CHECKS={roundtrips}')
    print('WEAVING_BATCH_FINITE_RESULT=PASS')


def test_year5000_profile():
    """Bound two sampled candidate-count calls, NOT full rank/unrank."""
    from weaving_reachability_oracle import MONTH_LENGTHS
    from resource import getrusage, RUSAGE_SELF

    lengths = MONTH_LENGTHS
    assert len(lengths) == 45 and sum(lengths) == 4244
    started = monotonic()
    short_prefix = (1,)
    blocks = candidate_counts(lengths, short_prefix)
    assert sum(blocks) == count_prefix(lengths, short_prefix)
    assert blocks[0] + blocks[1] == sum(blocks)
    for j in range(2, len(lengths)):
        assert blocks[j] == 0
    opened = tuple(range(1, len(lengths) + 1))
    opened_blocks = candidate_counts(lengths, opened)
    assert all(x > 0 for x in opened_blocks)
    assert sum(opened_blocks) == count_prefix(lengths, opened)
    elapsed = monotonic() - started
    rss_kib = getrusage(RUSAGE_SELF).ru_maxrss
    assert elapsed < 25.0, ("profile time gate exceeded", elapsed)
    assert rss_kib < 512 * 1024, ("RSS gate exceeded", rss_kib)
    print('WEAVING_BATCH_FULL_MONTHS=45')
    print('WEAVING_BATCH_FULL_DAYS=4244')
    print('WEAVING_BATCH_FULL_PROFILES=2')
    print('WEAVING_BATCH_FULL_SECONDS=' + format(elapsed, '.3f'))
    print('WEAVING_BATCH_FULL_MAXRSS_KIB=' + str(rss_kib))
    print('WEAVING_BATCH_FULL_RESULT=PASS')


if __name__ == '__main__':
    test_finite()
    test_year5000_profile()
