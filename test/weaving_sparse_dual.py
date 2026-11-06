#!/usr/bin/env python3
"""DISCOVERY03 research: sparse forward-state and algebraic reverse-adjoint transfer, not Chapel production.

The one-dimensional forward transfer is optimized by sparse interval states\nand an exact binomial recurrence. Its transpose uses a single-gap closed form\nor the same exact recurrence. Finite
acceptance uses the independent complete enumeration / occurrence-poset oracle.
A bounded 6-symbol median-prefix probe does NOT imply full-year rank PASS.
"""
from collections import Counter
from itertools import accumulate, chain, islice, product, repeat
from operator import mul
from time import monotonic
from resource import getrusage, RUSAGE_SELF
from hashlib import sha256

from weaving_prefix_batch import extend_spec
from weaving_prefix_transfer import weight, count_prefix


from dataclasses import dataclass
from functools import lru_cache
from math import comb

@dataclass(frozen=True)
class SparseVector:
    offset: int
    values: tuple

    def total(self):
        return sum(self.values)

    def prefix(self, index):
        upto = min(len(self.values), index - self.offset + 1)
        return sum(self.values[:upto]) if upto > 0 else 0

    def dot(self, dense):
        return sum(value * dense[self.offset + t]
                   for t, value in enumerate(self.values))


@lru_cache(maxsize=96)
def free_gap_coefficients(n, k):
    """Exact C(k+d-2,d) for 1<=d<=n, reused at each prefix transition.

    The d=0 coefficient is one. With k=1, positive distances are
    impossible; the cache is bounded independently of the prefix length.
    """
    if k < 2:
        return (1,) + (0,) * n
    values = [1]
    value = 1
    for distance in range(1, n + 1):
        value = value * (k + distance - 2) // distance
        values.append(value)
    return tuple(values)


def sparse_transfer(previous, n, k, spec):
    """Exact transfer: one admissible gap or a contiguous suffix interval."""
    q, fixed_sum, first_fixed, tail = spec
    if q > n:
        return SparseVector(0, ())
    if fixed_sum or tail:
        i = first_fixed if fixed_sum else q
        if i < 0 or i > n:
            return SparseVector(0, ())
        prefix = previous.prefix(i)
        coefficient = weight(i, n, k, *spec) if prefix else 0
        return SparseVector(i+1, (prefix * coefficient,)) if coefficient else SparseVector(0, ())
    first = max(0, q)
    if first > n:
        return SparseVector(0, ())
    # Assemble the same cumulative prefixes and exact elementwise products
    # using CPython's C-level itertools/operator loops. This is a research-only
    # implementation change, not a truncation, approximation, or change of DP.
    # At i=first the prefix includes previous[first]; later increments are
    # exactly previous[i] (or zero outside its sparse support).
    width = n - first
    begin, stop = first + 1, n + 1
    overlap_begin = max(begin, previous.offset)
    overlap_stop = min(stop, previous.offset + len(previous.values))
    if overlap_begin < overlap_stop:
        updates = chain(
            repeat(0, overlap_begin - begin),
            islice(previous.values, overlap_begin - previous.offset,
                   overlap_stop - previous.offset),
            repeat(0, stop - overlap_stop))
    else:
        updates = repeat(0, width)
    # The reversed coefficient row indexes C(k+n-i-2,n-i), i=first..n.
    coefficients = free_gap_coefficients(n, k)
    out = list(map(mul,
                   accumulate(updates, initial=previous.prefix(first)),
                   reversed(coefficients[:width + 1])))
    start = first+1
    left = 0
    while left < len(out) and out[left] == 0:
        left += 1
    if left == len(out):
        return SparseVector(0, ())
    right = len(out)
    while right > left and out[right-1] == 0:
        right -= 1
    return SparseVector(start+left, tuple(out[left:right]))



def _reference_free_gap_transfer(previous, n, k, spec):
    """Unvectorized pre-optimization recurrence for paired performance QA only.

    This intentionally keeps the original Python loop, as an exact comparator,
    independent of the new accumulate/map implementation. It is not a new
    occurrence-poset oracle and is never used by the production algorithm.
    """
    q, fixed_sum, _, tail = spec
    if fixed_sum or tail:
        raise ValueError("free-gap reference requires zero fixed_sum and tail")
    first = max(0, q)
    if first > n:
        return SparseVector(0, ())
    prefix = previous.prefix(first)
    coefficients = free_gap_coefficients(n, k)
    out = []
    for i in range(first, n + 1):
        if i > first and previous.offset <= i < previous.offset + len(previous.values):
            prefix += previous.values[i - previous.offset]
        out.append(prefix * coefficients[n - i])
    left = 0
    while left < len(out) and out[left] == 0:
        left += 1
    if left == len(out):
        return SparseVector(0, ())
    right = len(out)
    while right > left and out[right - 1] == 0:
        right -= 1
    return SparseVector(first + 1 + left, tuple(out[left:right]))


def sparse_transpose(after, n, k, spec):
    """Exact T^t, closed form for single-gap rows; recurrence otherwise."""
    q, fixed_sum, first_fixed, tail = spec
    if q > n:
        return [0] * (n+1)
    if fixed_sum or tail:
        i = first_fixed if fixed_sum else q
        if i < 0 or i > n:
            return [0] * (n+1)
        coefficient = weight(i,n,k,*spec)
        value = after[i+1] * coefficient
        return [value] * (i+1) + [0] * (n-i)
    result = [0] * (n+1)
    acc = after[n+1]
    result[n] = acc
    coefficient = 0
    for distance in range(1, n-q+1):
        if k >= 2:
            coefficient = k-1 if distance == 1 else coefficient * (k+distance-2) // distance
        i = n-distance
        if after[i+1] and coefficient:
            acc += after[i+1] * coefficient
        result[i] = acc
    if q > 0:
        result[:min(q,n+1)] = [acc]*min(q,n+1)
    return result


class SparseDualWeaving:
    def __init__(self, lengths, observe_transfers=False):
        if not lengths or any(type(x) is not int or x < 1 for x in lengths):
            raise ValueError("positive integer lengths required")
        self.lengths = tuple(lengths)
        self.m = len(lengths)
        self.n = sum(lengths)
        # Opt-in measurement only; neither arithmetic nor state transitions change.
        self.observe_transfers = bool(observe_transfers)
        self.transfer_metrics = {
            phase: {
                "calls": 0, "seconds": 0.0, "free_interval_cells": 0,
                "fixed_calls": 0, "output_cells": 0,
                "per_month_seconds": [0.0] * (self.m + 1),
                "per_month_calls": [0] * (self.m + 1),
            } for phase in ("blocks", "take")
        }
        self.used = [0] * (self.m + 1)
        self.opened = self.closed = self.position = 0
        self.specs = [None, None] + [(0, 0, -1, 0)] * (self.m - 1)
        self.sizes = [0] * (self.m + 1)
        self.states = [None] * (self.m + 1)
        n = lengths[0]
        v = SparseVector(1, (1,))
        self.states[1], self.sizes[1] = v, n
        for j in range(2, self.m + 1):
            v = sparse_transfer(v, n, lengths[j-1], self.specs[j])
            n += lengths[j-1]
            self.states[j], self.sizes[j] = v, n
        self.total = v.total()
        self.cached = None
        # Candidate j's first downstream transfer is already evaluated in
        # blocks(); retain that exact state until take() consumes the choice.
        self.cached_candidate_states = None
        self.reused_candidate_transfers = 0

    def _forward(self, previous, n, k, spec, phase, month):
        """Measure exact transfer without modifying its input or output.

        free_interval_cells counts visited output slots, not multiplications.
        Initial constructor transfers are intentionally excluded.
        """
        if not self.observe_transfers:
            return sparse_transfer(previous, n, k, spec)
        started = monotonic()
        result = sparse_transfer(previous, n, k, spec)
        elapsed = monotonic() - started
        metric = self.transfer_metrics[phase]
        metric["calls"] += 1
        metric["seconds"] += elapsed
        metric["output_cells"] += len(result.values)
        metric["per_month_seconds"][month] += elapsed
        metric["per_month_calls"][month] += 1
        q, fixed_sum, first_fixed, tail = spec
        if q <= n and (fixed_sum or tail):
            metric["fixed_calls"] += 1
        elif q <= n:
            metric["free_interval_cells"] += max(0, n - max(0, q) + 1)
        return result

    def eligible(self, c):
        if not 1 <= c <= self.m:
            return False
        left = self.lengths[c-1] - self.used[c]
        return (left > 0 and c <= self.opened + 1
                and (left != 1 or c == self.closed + 1))

    @staticmethod
    def transpose(after,n,k,spec):
        return sparse_transpose(after,n,k,spec)

    def blocks(self):
        if self.cached is not None:
            return self.cached
        # Stream reverse-adjoint vectors to bound memory. At month j, the
        # suffix only sees the candidate as an older letter for every c<j.
        adj = [1] * (self.n + 1)
        out = [0] * (self.m + 1)
        prepared = [None] * (self.m + 1)
        for j in range(self.m, 1, -1):
            if self.eligible(j):
                own = extend_spec(self.specs[j], j, j)
                v = self._forward(self.states[j-1], self.sizes[j-1],
                                  self.lengths[j-1], own, "blocks", j)
                out[j] = v.dot(adj)
                prepared[j] = v
            older = extend_spec(self.specs[j], j, 1)
            adj = self.transpose(adj, self.sizes[j-1],
                                 self.lengths[j-1], older)
        if self.eligible(1):
            out[1] = self.states[1].dot(adj)
        if sum(out) != self.total:
            raise AssertionError(("candidate partition", self.position))
        self.cached = tuple(out)
        self.cached_candidate_states = tuple(prepared)
        return self.cached

    def take(self, c):
        if not self.eligible(c):
            raise ValueError("illegal next symbol")
        ways = self.blocks()[c]
        if ways <= 0:
            raise ValueError("no valid continuation")
        start = max(2, c)
        prepared = (self.cached_candidate_states[c]
                    if c > 1 and self.cached_candidate_states is not None
                    else None)
        v = self.states[start-1]
        for j in range(start, self.m + 1):
            self.specs[j] = extend_spec(self.specs[j], j, c)
            if j == c and prepared is not None:
                # The same exact transfer from states[c-1] was needed for
                # the candidate partition; avoid recomputing it in take().
                v = prepared
                self.reused_candidate_transfers += 1
            else:
                v = self._forward(v, self.sizes[j-1], self.lengths[j-1],
                                  self.specs[j], "take", j)
            self.states[j] = v
        self.used[c] += 1
        self.position += 1
        if self.used[c] == 1:
            self.opened += 1
        if self.used[c] == self.lengths[c-1]:
            self.closed += 1
        self.total = ways
        self.cached = None
        self.cached_candidate_states = None
        assert self.total == self.states[self.m].total()


def dual_unrank(lengths, rank):
    s = SparseDualWeaving(lengths)
    if type(rank) is not int or not 0 <= rank < s.total:
        raise ValueError("invalid rank")
    word = []
    for _ in range(s.n):
        for c, ways in enumerate(s.blocks()[1:], 1):
            if rank >= ways:
                rank -= ways
            else:
                s.take(c)
                word.append(c)
                break
        else:
            raise AssertionError("no continuation")
    assert rank == 0 and s.total == 1
    return tuple(word)


def dual_rank(lengths, word):
    s = SparseDualWeaving(lengths)
    if len(word) != s.n or Counter(word) != Counter(
            {i+1: k for i, k in enumerate(lengths)}):
        raise ValueError("invalid multiplicity")
    rank = 0
    for c in word:
        rank += sum(s.blocks()[1:c])
        s.take(c)
    assert s.total == 1
    return rank


def test_free_gap_accumulation_differential():
    """Exact old-loop comparison on bounded edge/sparse/large-integer shapes.

    Independent dense/transpose and occurrence-poset checks in CI remain
    mandatory; this test is a *differential regression*, not a standalone
    performance acceptance or an independent combinatorial oracle.
    """
    checks = 0
    for n in (0, 1, 4, 17, 96, 250):
        shapes = (
            SparseVector(0, tuple((i + 3)**4 for i in range(n + 1))),
            SparseVector(n // 4, tuple((i + 1)**9 for i in range(n // 3))),
            SparseVector(n // 2, (0, 0, 7, 0, 12)),
            SparseVector(n + 2, ()),
        )
        for k in (1, 2, 7, 125):
            for q in (-1, 0, 1, n // 2, n, n + 1):
                for previous in shapes:
                    expected = SparseVector(0, ())
                    if q <= n:
                        first = max(0, q)
                        prefix = previous.prefix(first)
                        row = free_gap_coefficients(n, k)
                        values = []
                        for i in range(first, n + 1):
                            if (i > first and previous.offset <= i
                                    < previous.offset + len(previous.values)):
                                prefix += previous.values[i - previous.offset]
                            values.append(prefix * row[n - i])
                        lo = 0
                        while lo < len(values) and values[lo] == 0:
                            lo += 1
                        if lo < len(values):
                            hi = len(values)
                            while hi > lo and values[hi - 1] == 0:
                                hi -= 1
                            expected = SparseVector(first + 1 + lo,
                                                    tuple(values[lo:hi]))
                    observed = sparse_transfer(previous, n, k, (q, 0, -1, 0))
                    assert observed == expected, (n, k, q, previous.offset)
                    checks += 1
    assert checks == 576
    print("WEAVING_SPARSE_ACCUMULATE_DIFFERENTIAL_CHECKS=" + str(checks))
    print("WEAVING_SPARSE_ACCUMULATE_DIFFERENTIAL=PASS")


def test_finite():
    from weaving_small_exact_oracle import brute_words, poset_oracle
    cases = [p for m in range(1, 5)
             for p in product(range(1, 5), repeat=m) if sum(p) <= 8]
    cases += [(2, 2, 2, 2, 2), (2, 3, 2, 2), (3, 2, 3, 2),
              (2, 2, 3, 3), (3, 3, 2, 2), (4, 3, 2),
              (2, 4, 3), (1, 2, 1, 3), (3, 1, 2, 2)]
    cases = list(dict.fromkeys(cases))
    roundtrips = partitions = reused = 0
    for lengths in cases:
        accepted = brute_words(lengths)
        count, oracle_rank, oracle_unrank, _ = poset_oracle(lengths)
        assert SparseDualWeaving(lengths).total == count == len(accepted)
        for i, word in enumerate(accepted):
            assert dual_unrank(lengths, i) == oracle_unrank(i) == word
            assert dual_rank(lengths, word) == oracle_rank(word) == i
            roundtrips += 2
            state = SparseDualWeaving(lengths)
            for symbol in word:
                assert sum(state.blocks()) == state.total
                expected_first = (
                    sparse_transfer(
                        state.states[symbol-1], state.sizes[symbol-1],
                        state.lengths[symbol-1],
                        extend_spec(state.specs[symbol], symbol, symbol))
                    if symbol > 1 else None)
                old_hits = state.reused_candidate_transfers
                state.take(symbol)
                hit = state.reused_candidate_transfers - old_hits
                assert hit == (1 if symbol > 1 else 0)
                if expected_first is not None:
                    assert state.states[symbol] == expected_first
                reused += hit
                partitions += 1
    assert len(cases) == 137 and roundtrips == 1982 and partitions == 8361
    assert 0 < reused < partitions
    # Exact finite-case differential: instrumentation must preserve all states.
    sample = (2, 3, 2)
    word = dual_unrank(sample, 0)
    watched = SparseDualWeaving(sample, observe_transfers=True)
    control = SparseDualWeaving(sample)
    for symbol in word:
        assert watched.blocks() == control.blocks()
        watched.take(symbol)
        control.take(symbol)
        assert watched.states == control.states
    assert watched.reused_candidate_transfers == control.reused_candidate_transfers
    for phase in ("blocks", "take"):
        metric = watched.transfer_metrics[phase]
        assert metric["calls"] > 0 and metric["seconds"] >= 0.0
        assert sum(metric["per_month_calls"]) == metric["calls"]
    test_free_gap_accumulation_differential()
    print("WEAVING_SPARSE_OBSERVABILITY_SMOKE=PASS")
    print("WEAVING_SPARSE_FINITE_REUSED_TRANSFERS=" + str(reused))
    print("WEAVING_SPARSE_FINITE_CASES=137")
    print("WEAVING_SPARSE_FINITE_RANK_ROUNDTRIPS=1982")
    print("WEAVING_SPARSE_FINITE_PARTITIONS=8361")
    print("WEAVING_SPARSE_FINITE_RESULT=PASS")



def test_paired_hot_month_free_gap(state):
    """Compare both exact kernels on identical large integer state, one runner.

    This is diagnostic A/B telemetry, not a cross-run speedup assertion or
    a full-length median rank/unrank acceptance. Order ABBA mitigates drift.
    """
    from statistics import median

    j = state.m  # Month 45; the independently observed hotspot.
    previous, n = state.states[j-1], state.sizes[j-1]
    k, spec = state.lengths[j-1], state.specs[j]
    assert spec[1] == 0 and spec[3] == 0 and spec[0] <= n
    assert len(previous.values) > 0 and previous.total() > 0
    expected = _reference_free_gap_transfer(previous, n, k, spec)
    assert sparse_transfer(previous, n, k, spec) == expected

    samples = {"loop": [], "accumulate": []}
    methods = {"loop": _reference_free_gap_transfer,
               "accumulate": sparse_transfer}
    checks = 1
    # Six samples per kernel, interleaved as ABBA to reduce time drift.
    for _ in range(3):
        for key in ("loop", "accumulate", "accumulate", "loop"):
            started = monotonic()
            result = methods[key](previous, n, k, spec)
            samples[key].append(monotonic() - started)
            assert result == expected
            checks += 1
    assert checks == 13
    old = median(samples["loop"])
    new = median(samples["accumulate"])
    print("WEAVING_SPARSE_HOT_MONTH_AB_MONTH=" + str(j))
    print("WEAVING_SPARSE_HOT_MONTH_AB_N=" + str(n))
    print("WEAVING_SPARSE_HOT_MONTH_AB_INPUT_CELLS=" +
          str(len(previous.values)))
    print("WEAVING_SPARSE_HOT_MONTH_AB_OUTPUT_CELLS=" +
          str(len(expected.values)))
    print("WEAVING_SPARSE_HOT_MONTH_AB_CHECKS=" + str(checks))
    print("WEAVING_SPARSE_HOT_MONTH_AB_LOOP_MEDIAN_SECONDS=" +
          format(old, ".6f"))
    print("WEAVING_SPARSE_HOT_MONTH_AB_ACCUMULATE_MEDIAN_SECONDS=" +
          format(new, ".6f"))
    print("WEAVING_SPARSE_HOT_MONTH_AB_RATIO_NEW_OVER_OLD=" +
          format(new / old, ".4f") if old else
          "WEAVING_SPARSE_HOT_MONTH_AB_RATIO_NEW_OVER_OLD=UNAVAILABLE")
    print("WEAVING_SPARSE_HOT_MONTH_AB_EQUALITY=PASS")
    print("WEAVING_SPARSE_HOT_MONTH_AB_PERFORMANCE_ACCEPTANCE=NOT_TESTED")


def test_median_prefix():
    from weaving_reachability_oracle import MONTH_LENGTHS
    months = MONTH_LENGTHS
    assert len(months) == 45 and sum(months) == 4244
    started = monotonic()
    state = SparseDualWeaving(months)
    root = state.total
    assert root.bit_length() == 22470
    digest = sha256(root.to_bytes((root.bit_length()+7)//8, "big")).hexdigest()
    assert digest == "925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da"
    # This deliberately probes ONLY the first six choices for total//2.
    residual_rank = root // 2
    prefix = []
    for _ in range(6):
        blocks = state.blocks()
        for c in range(1, 46):
            if residual_rank >= blocks[c]:
                residual_rank -= blocks[c]
            else:
                state.take(c)
                prefix.append(c)
                break
        else:
            raise AssertionError("no legal median-prefix transition")
    assert tuple(prefix) == (1, 2, 3, 4, 5, 6)
    assert state.total == count_prefix(months, tuple(prefix))
    elapsed = monotonic() - started
    rss = getrusage(RUSAGE_SELF).ru_maxrss
    assert elapsed < 25.0 and rss < 512*1024, (elapsed, rss)
    print("WEAVING_SPARSE_FULL_MONTHS=45")
    print("WEAVING_SPARSE_FULL_DAYS=4244")
    print("WEAVING_SPARSE_MEDIAN_PREFIX_SYMBOLS=6")
    print("WEAVING_SPARSE_MEDIAN_PREFIX_SECONDS=" + format(elapsed, ".3f"))
    print("WEAVING_SPARSE_MEDIAN_PREFIX_RSS_KIB=" + str(rss))
    print("WEAVING_SPARSE_MEDIAN_PREFIX_RESULT=PASS")
    print("WEAVING_SPARSE_FULL_MEDIAN_RANK_UNRANK=NOT_TESTED")
    test_paired_hot_month_free_gap(state)


if __name__ == "__main__":
    test_finite()
    test_median_prefix()
