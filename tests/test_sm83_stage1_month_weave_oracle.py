#!/usr/bin/env python3
"""Exact full five-field Python calendar oracle for the ten canonical inputs.

Implements normative month weaving V as lexicographic unranking of all words
with fixed per-month multiplicities, ascending first appearances and ascending
last appearances. Uses an exact prefix-completion count, *not* enumeration of
the astronomical candidate space, random sampling or a source-output lookup.

Pinned authority: main README 56bc4173aae4975ded019ef5ab5a36249f1424df
sections V, X, AC.1; prior sauce, year, cutlet/month choice modules implement
sections A..U and W. This is Host Python, not SM83 machine-code execution.
"""
from __future__ import annotations

from collections import Counter
from dataclasses import dataclass
from itertools import product
import json
from math import comb
from pathlib import Path

from test_sm83_stage1_sauce_oracle import compute_sauce
from test_sm83_stage1_selection_oracle import bowl_answer_flow, select
from test_sm83_stage1_structure_oracle import build_year_structure
from test_sm83_stage1_year_path_oracle import find_year


class ExactWeave:
    """Exact count/unrank with completed-prefix and introduced-month states.

    Suppose a prefix has introduced months 1..k, some initial subset 1..h
    already has no copies left, and the remaining seen months h+1..k all
    have positive counts. Their *last appearances* must be in ascending
    order. The number of such seen-month suffix arrangements is

      B = product_j C(prefix_sum_j - 1, remaining_j - 1),

    since each successive month's final occurrence must follow all earlier
    final occurrences. If T seen copies remain, unseen months k+1..m
    can be introduced without breaking the first/last orders. H_j(T) is
    their exact insertion count, computed backwards:

      H_(m+1)(T) = 1
      H_j(T) = sum_(s=a_j-1)^(T+a_j-1)
                   C(s-1,a_j-2) H_(j+1)(s).

    The sum is a prefix accumulation, so preprocessing is O(m*L). The
    completion count is B*H_(k+1)(T). Lex unranking uses exact block sizes
    for each permissible next symbol, with rational binomial-factor ratios
    that evaluate to integers. No approximations are made.
    """

    def __init__(self, lengths: tuple[int, ...]):
        if not lengths or len(lengths) > 47 or any(n < 2 for n in lengths):
            raise ValueError("weave requires positive, nontrivial month multiplicities")
        if sum(lengths) > 5778:
            raise ValueError("year exceeds normative maximum")
        self.lengths = tuple(lengths)
        self.months = len(lengths)
        total = sum(lengths)
        sums = [0]
        for a in lengths:
            sums.append(sums[-1] + a)
        self.future: list[list[int] | None] = [None] * (self.months + 2)
        self.future[self.months + 1] = [1] * (total + 1)
        for j in range(self.months, 0, -1):
            a = lengths[j - 1]
            limit = sums[j - 1]
            after = self.future[j + 1]
            assert after is not None
            row = []
            rolling = 0
            for old_count in range(limit + 1):
                s = old_count + a - 1
                rolling += comb(s - 1, a - 2) * after[s]
                row.append(rolling)
            self.future[j] = row
        assert self.future[1] is not None
        self.total_words = self.future[1][0]
        assert self.total_words > 0

    def count_suffix(self, remaining: tuple[int, ...], seen: int) -> int:
        """Independent direct B*H count, used as a small-state check."""
        if len(remaining) != self.months or not 0 <= seen <= self.months:
            raise ValueError("invalid prefix state")
        if tuple(remaining[seen:]) != self.lengths[seen:]:
            raise ValueError("unseen month count changed before first appearance")
        h = 0
        while h < seen and remaining[h] == 0:
            h += 1
        if any(n <= 0 for n in remaining[h:seen]):
            return 0
        total, ways = 0, 1
        for amount in remaining[h:seen]:
            total += amount
            ways *= comb(total - 1, amount - 1)
        tail = self.future[seen + 1]
        assert tail is not None
        return ways * tail[total]

    def unrank(self, rank: int) -> tuple[int, ...]:
        """Stream lex blocks; full word is needed to validate all constraints."""
        if not 1 <= rank <= self.total_words:
            raise ValueError("weave rank outside candidate set")
        remaining = list(self.lengths)
        seen = 0
        active_total = 0
        base_ways = 1
        result: list[int] = []
        for _ in range(sum(self.lengths)):
            active = [i for i in range(seen) if remaining[i] > 0]
            cumul: dict[int, int] = {}
            total = 0
            for j in active:
                total += remaining[j]
                cumul[j] = total
            assert total == active_total
            suffix_num: dict[int, int] = {}
            suffix_den: dict[int, int] = {}
            p, q = 1, 1
            for j in reversed(active):
                suffix_num[j], suffix_den[j] = p, q
                if j != active[0]:
                    p *= cumul[j] - remaining[j]
                    q *= cumul[j] - 1
            candidates = []
            old_future = self.future[seen + 1]
            assert old_future is not None
            for j in active:
                # A higher numbered month cannot finish before a still-live
                # lower numbered month. Such a branch is impossible.
                if remaining[j] == 1 and j != active[0]:
                    continue
                numerator = suffix_num[j] * (remaining[j] - 1 if remaining[j] > 1 else 1)
                denominator = suffix_den[j] * (cumul[j] - 1 if remaining[j] > 1 else 1)
                reduced, remainder = divmod(base_ways * numerator, denominator)
                assert remainder == 0
                block = reduced * old_future[active_total - 1]
                candidates.append((j, block, reduced, active_total - 1, seen))

            if seen < self.months:
                a = remaining[seen]
                after_new = base_ways * comb(active_total + a - 2, a - 2)
                future = self.future[seen + 2]
                assert future is not None
                new_total = active_total + a - 1
                block = after_new * future[new_total]
                candidates.append((seen, block, after_new, new_total, seen + 1))
            assert sum(row[1] for row in candidates) == base_ways * old_future[active_total]
            for j, block, next_base, next_total, next_seen in candidates:
                if rank > block:
                    rank -= block
                else:
                    base_ways, active_total, seen = next_base, next_total, next_seen
                    remaining[j] -= 1
                    result.append(j + 1)
                    break
            else:
                raise AssertionError("no valid lexicographic completion")
        assert not any(remaining) and rank == 1 and seen == self.months
        word = tuple(result)
        assert len(word) == sum(self.lengths)
        assert tuple(word.count(i) for i in range(1, self.months + 1)) == self.lengths
        first = tuple(word.index(i) for i in range(1, self.months + 1))
        last = tuple(len(word) - 1 - word[::-1].index(i) for i in range(1, self.months + 1))
        assert first == tuple(sorted(first)) and last == tuple(sorted(last))
        return word


@dataclass(frozen=True)
class CalendarFields:
    year: int
    cutlet_name_index: int
    day_in_cutlet: int
    month_name_index: int
    day_in_month: int


def compute_five_fields(c: int, t: int) -> CalendarFields:
    """Complete Host calculation for the near-Foundation canonical scope.

    This function never reads any canonical expected output or mutant result.
    Re-uses the selected year's first-day sauce for cutlet/month selection.
    """
    structure = build_year_structure(c, t)
    year = find_year(c, t)
    assert year.year_number == structure.year_number
    assert structure.month_weave is None
    day_offset = t - year.span.open_gate - 1
    assert 0 <= day_offset < structure.span_days
    sauce = compute_sauce(c, year.span.open_gate + 1)
    count = ExactWeave(structure.month_lengths)
    rank = select(bowl_answer_flow(sauce, 4, 32), count.total_words).rank
    word = count.unrank(rank)
    month = word[day_offset]
    day_in_month = word[:day_offset + 1].count(month)
    assert 1 <= day_in_month <= structure.month_lengths[month - 1]
    return CalendarFields(
        year.year_number, structure.cutlet_index, structure.day_in_cutlet,
        structure.month_names[month - 1], day_in_month,
    )


def check_stage1_five_field_oracle() -> None:
    # Cross-check the exact insertion DP and lex blocks against an independent
    # brute-force enumerator over all small words, NOT against itself.
    tested = 0
    for lengths in ((2, 2), (2, 2, 2), (3, 2, 2), (2, 3, 2),
                    (2, 2, 2, 2), (3, 3, 2)):
        m = len(lengths)
        full = [
            word for word in product(range(1, m + 1), repeat=sum(lengths))
            if all(word.count(j + 1) == lengths[j] for j in range(m))
            and tuple(word.index(j) for j in range(1, m + 1))
              == tuple(sorted(word.index(j) for j in range(1, m + 1)))
            and tuple(len(word) - 1 - word[::-1].index(j) for j in range(1, m + 1))
              == tuple(sorted(len(word) - 1 - word[::-1].index(j) for j in range(1, m + 1)))
        ]
        oracle = ExactWeave(lengths)
        assert oracle.total_words == len(full), (lengths, oracle.total_words, len(full))
        assert oracle.count_suffix(tuple(lengths), 0) == len(full)
        for rank, expected in enumerate(full, 1):
            assert oracle.unrank(rank) == expected, (lengths, rank)
            tested += 1

    fixture = json.loads(
        (Path(__file__).parent / "fixtures/sm83_stage1_canonical_vectors.json").read_text(encoding="utf-8")
    )
    assert fixture["provenance"]["commit"] == "56bc4173aae4975ded019ef5ab5a36249f1424df"
    matched = 0
    for record in fixture["vectors"]:
        result = compute_five_fields(record["c"], record["t"])
        expected = tuple(record["expected"])  # ASSERTION ONLY.
        actual = (
            result.year, result.cutlet_name_index, result.day_in_cutlet,
            result.month_name_index, result.day_in_month,
        )
        assert actual == expected, (record["id"], actual, expected)
        matched += 1
    assert matched == 10
    print(
        "HOST_STAGE1_FULL_FIVE_FIELDS=PASS "
        f"golden_vectors={matched}/10 small_weave_bruteforce_ranks={tested} "
        "exact_multiset_first_last_order=YES "
        "lex_rank_unrank=YES arbitrary_integer_counts=YES "
        "canonical_names=INDEX_ONLY source_geez_catalog=UNFROZEN "
        "native_dispatcher=NOT_IMPLEMENTED native=NOT_EXECUTED",
        flush=True,
    )


if __name__ == "__main__":
    check_stage1_five_field_oracle()
