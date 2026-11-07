#!/usr/bin/env python3
"""Exact Host oracle for canonical year cutlets and month compositions (S..U,W).

Independent integer rank/unrank algorithms consume only (c,t), the
source-defined year gates, and the mathematical sauce/selection machinery.
Canonical AC.1 answers are used only in *assertions*, never as lookup inputs.

Month-day weaving (V) is NOT implemented in this module. It must be added
before asserting all five calendar output fields or any complete Stage1 PASS.
Pinned source: main README 56bc4173aae4975ded019ef5ab5a36249f1424df.
"""
from __future__ import annotations

from dataclasses import dataclass
from functools import lru_cache
from itertools import combinations, permutations, product
import json
from math import ceil, comb, perm
from pathlib import Path

from test_sm83_stage1_selection_oracle import bowl_answer_flow, select
from test_sm83_stage1_sauce_oracle import compute_sauce
from test_sm83_stage1_year_path_oracle import find_year, gate_at

CUTLET_NAMES = 17
MONTH_NAMES = 47
MONTH_MIN, MONTH_MAX = 4, 123


def choose(n: int, k: int) -> int:
    return comb(n, k) if 0 <= k <= n else 0


def positive_composition_count(total: int, parts: int, mandatory_cut: int | None = None) -> int:
    """Count positive ordered parts, with optional mandatory INTERNAL breakpoint."""
    if parts == 0:
        return int(total == 0 and mandatory_cut is None)
    if total < parts or parts < 1:
        return 0
    if mandatory_cut is None:
        return choose(total - 1, parts - 1)
    if not 0 < mandatory_cut < total:
        return 0
    return choose(total - 2, parts - 2)


def unrank_positive(
    total: int, parts: int, rank: int, mandatory_cut: int | None = None
) -> tuple[int, ...]:
    """Lexicographic unrank using exact binomial completion-block sizes."""
    count = positive_composition_count(total, parts, mandatory_cut)
    if not 1 <= rank <= count:
        raise ValueError("rank outside eligible positive compositions")
    original_cut = mandatory_cut
    remaining, out = total, []
    for number in range(parts, 0, -1):
        found = False
        for candidate in range(1, remaining - number + 2):
            suffix = remaining - candidate
            if mandatory_cut is None:
                next_cut = None
            elif candidate == mandatory_cut:
                next_cut = None
            elif candidate < mandatory_cut:
                next_cut = mandatory_cut - candidate
            else:
                continue
            block = positive_composition_count(suffix, number - 1, next_cut)
            if rank > block:
                rank -= block
                continue
            out.append(candidate)
            remaining = suffix
            mandatory_cut = next_cut
            found = True
            break
        if not found:
            raise AssertionError("positive composition unrank exhausted the rank")
    assert remaining == 0 and mandatory_cut is None and rank == 1
    assert sum(out) == total and len(out) == parts and min(out) >= 1
    if original_cut is not None:
        assert original_cut in tuple(sum(out[:i]) for i in range(1, len(out)))
    return tuple(out)


def unrank_distinct_names(pool: int, take: int, rank: int) -> tuple[int, ...]:
    """Rank 1..P(pool,take), lex order by immutable canonical name indices."""
    if not 0 <= take <= pool or pool < 1 or not 1 <= rank <= perm(pool, take):
        raise ValueError("invalid distinct name unrank")
    available = list(range(1, pool + 1))
    r = rank - 1
    result = []
    for position in range(take):
        block = perm(pool - position - 1, take - position - 1)
        idx, r = divmod(r, block)
        result.append(available.pop(idx))
    assert r == 0 and len(set(result)) == take
    return tuple(result)


@lru_cache(maxsize=3)
def bounded_count_table(total: int, parts: int, lower: int, upper: int) -> tuple[tuple[int, ...], ...]:
    """O(parts*total) exact convolution via sliding sums, arbitrary-size ints."""
    if not 0 <= total <= 5778 or not 0 <= parts <= 47 or not 1 <= lower <= upper:
        raise ValueError("outside Stage1 month composition table contract")
    previous = [0] * (total + 1)
    previous[0] = 1
    rows = [tuple(previous)]
    for _ in range(parts):
        result = [0] * (total + 1)
        window = 0
        for subtotal in range(total + 1):
            if subtotal >= lower:
                window += previous[subtotal - lower]
            if subtotal > upper:
                window -= previous[subtotal - upper - 1]
            result[subtotal] = window
        rows.append(tuple(result))
        previous = result
    return tuple(rows)


def unrank_bounded_lengths(
    total: int, parts: int, lower: int, upper: int, rank: int
) -> tuple[int, ...]:
    """Lex-unrank exactly, without enumerating the exponential length tuples."""
    table = bounded_count_table(total, parts, lower, upper)
    count = table[parts][total]
    if not 1 <= rank <= count:
        raise ValueError("rank outside eligible length compositions")
    remaining, chosen = total, []
    for idx in range(parts):
        left = parts - idx - 1
        for value in range(lower, min(upper, remaining) + 1):
            block = table[left][remaining - value]
            if rank > block:
                rank -= block
                continue
            chosen.append(value)
            remaining -= value
            break
        else:
            raise AssertionError("bounded month unrank exhausted rank")
    assert remaining == 0 and rank == 1
    assert len(chosen) == parts and all(lower <= v <= upper for v in chosen)
    return tuple(chosen)


@dataclass(frozen=True)
class YearStructure:
    year_number: int
    cutlet_gaps: tuple[int, ...]
    cutlet_names: tuple[int, ...]
    cutlet_index: int
    day_in_cutlet: int
    month_lengths: tuple[int, ...]
    month_names: tuple[int, ...]
    month_weave: None
    span_days: int
    cutlet_count: int
    month_count: int


def build_year_structure(c: int, t: int) -> YearStructure:
    """Find year + cutlet/day, month lengths and name permutation.

    The woven target-month identity is intentionally absent, not guessed.
    Every question about the year's structure reuses sauce(c, firstDayOfYear).
    """
    year = find_year(c, t)
    span = year.span
    total, gaps = span.length, span.close_index - span.open_index
    assert gaps >= 6 and total >= gaps * 42
    assert gate_at(span.close_index) == span.close_gate
    assert gate_at(span.open_index) == span.open_gate
    sauce = compute_sauce(c, span.open_gate + 1)

    max_cutlets = min(CUTLET_NAMES, gaps)
    k = 5 + select(bowl_answer_flow(sauce, 2, 20), max_cutlets - 5).rank
    assert 6 <= k <= max_cutlets

    # Only when the calculation day is an internal gate must this exact
    # breakpoint occur in the chosen ordered composition of gate intervals.
    mandatory = next(
        (idx - span.open_index for idx in range(span.open_index + 1, span.close_index)
         if gate_at(idx) == c),
        None,
    )
    count = positive_composition_count(gaps, k, mandatory)
    assert count > 0
    parts_rank = select(bowl_answer_flow(sauce, 2, 21), count).rank
    cutlets = unrank_positive(gaps, k, parts_rank, mandatory)
    labels_count = perm(CUTLET_NAMES, k)
    labels_rank = select(bowl_answer_flow(sauce, 5, 22), labels_count).rank
    cutlet_labels = unrank_distinct_names(CUTLET_NAMES, k, labels_rank)

    end_index = span.open_index
    day_in_cutlet, selected_cutlet = None, None
    for idx, width in enumerate(cutlets):
        beginning = gate_at(end_index)
        end_index += width
        ending = gate_at(end_index)
        assert beginning < ending
        if beginning < t <= ending:
            assert selected_cutlet is None
            selected_cutlet = idx
            day_in_cutlet = t - beginning
    assert end_index == span.close_index
    assert selected_cutlet is not None and day_in_cutlet is not None

    min_months = ceil(total / MONTH_MAX)
    max_months = min(MONTH_NAMES, total // MONTH_MIN)
    assert 3 <= min_months <= max_months <= MONTH_NAMES
    m = min_months - 1 + select(bowl_answer_flow(sauce, 3, 30), max_months - min_months + 1).rank
    month_table = bounded_count_table(total, m, MONTH_MIN, MONTH_MAX)
    length_count = month_table[m][total]
    assert length_count > 0
    length_rank = select(bowl_answer_flow(sauce, 3, 31), length_count).rank
    lengths = unrank_bounded_lengths(total, m, MONTH_MIN, MONTH_MAX, length_rank)
    name_count = perm(MONTH_NAMES, m)
    name_rank = select(bowl_answer_flow(sauce, 5, 33), name_count).rank
    month_labels = unrank_distinct_names(MONTH_NAMES, m, name_rank)
    assert sum(lengths) == span.length
    return YearStructure(
        year.year_number, cutlets, cutlet_labels, cutlet_labels[selected_cutlet],
        day_in_cutlet, lengths, month_labels, None, total, k, m,
    )


def check_stage1_structure_oracle() -> None:
    # Small brute-force cases prevent a shared off-by-one between count and
    # unrank functions, especially around the mandatory internal gate.
    brute_cases = 0
    for total in range(3, 11):
        for parts in range(2, min(total, 6) + 1):
            all_compositions = [
                tuple(pieces) for pieces in product(range(1, total + 1), repeat=parts)
                if sum(pieces) == total
            ]
            for mandatory in (None, *range(1, total)):
                valid = [
                    p for p in all_compositions
                    if mandatory is None or mandatory in {
                        sum(p[:idx]) for idx in range(1, len(p))
                    }
                ]
                count = positive_composition_count(total, parts, mandatory)
                assert count == len(valid), (total, parts, mandatory, count, len(valid))
                for rank, expected in enumerate(valid, 1):
                    assert unrank_positive(total, parts, rank, mandatory) == expected
                    brute_cases += 1

    name_cases = 0
    for pool in range(2, 7):
        for take in range(1, pool + 1):
            ref = list(permutations(range(1, pool + 1), take))
            assert len(ref) == perm(pool, take)
            for i, expected in enumerate(ref, 1):
                assert unrank_distinct_names(pool, take, i) == expected
                name_cases += 1

    bounded_cases = 0
    for lower, upper in ((2, 4), (4, 6)):
        for parts in range(1, 5):
            for total in range(lower * parts, upper * parts + 1):
                ref = sorted(
                    x for x in product(range(lower, upper + 1), repeat=parts)
                    if sum(x) == total
                )
                table = bounded_count_table(total, parts, lower, upper)
                assert table[parts][total] == len(ref)
                for rank, expected in enumerate(ref, 1):
                    assert unrank_bounded_lengths(total, parts, lower, upper, rank) == expected
                    bounded_cases += 1

    fixture = json.loads((Path(__file__).parent / "fixtures/sm83_stage1_canonical_vectors.json").read_text(encoding="utf-8"))
    assert fixture["provenance"]["commit"] == "56bc4173aae4975ded019ef5ab5a36249f1424df"
    validated = 0
    for record in fixture["vectors"]:
        c, t = record["c"], record["t"]
        result = build_year_structure(c, t)
        want = record["expected"]
        assert (result.year_number, result.cutlet_index, result.day_in_cutlet) == (
            want[0], want[1], want[2]
        ), (record["id"], result, want)
        assert result == build_year_structure(c, t)
        assert sum(result.cutlet_gaps) >= 6
        assert len(result.cutlet_names) == result.cutlet_count
        assert len(set(result.cutlet_names)) == result.cutlet_count
        assert len(result.month_names) == result.month_count
        assert len(set(result.month_names)) == result.month_count
        assert sum(result.month_lengths) == result.span_days
        assert result.month_weave is None
        validated += 1
    assert validated == 10
    print(
        "HOST_STAGE1_YEAR_STRUCTURE=PASS "
        f"canonical_cutlet_fields={validated}/10 "
        f"positive_bruteforce_ranks={brute_cases} "
        f"permutation_bruteforce_ranks={name_cases} "
        f"bounded_month_bruteforce_ranks={bounded_cases} "
        "month_counts_lengths_and_names=10/10 "
        "full_month_weave=NOT_IMPLEMENTED "
        "month_fields=NOT_COMPUTED native=NOT_EXECUTED",
        flush=True,
    )


if __name__ == "__main__":
    check_stage1_structure_oracle()
