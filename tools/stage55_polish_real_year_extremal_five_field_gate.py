#!/usr/bin/env python3
"""Etap 55: independent real-year edge-word and five-field projection gate.

The actual 45-month/4244-day lengths are from the audited Year-5000
structure. Four extremal words are constructed WITHOUT the production
DAG, suffix-count recurrence, first-position recurrence or MATLAB.

The five-field projection is exercised only with explicitly synthetic
cutlet/name metadata: real Year-5000 cutlet/name selections and a
full Appendix-A differential are NOT certified here.
"""
from bisect import bisect_right
from collections import Counter
from itertools import permutations
from math import prod

REAL_LENGTHS = (
    115, 108, 119, 109, 106, 81, 115, 114, 117, 120, 98, 52,
    81, 97, 121, 97, 115, 96, 107, 61, 106, 115, 119, 39,
    84, 103, 115, 107, 55, 119, 97, 50, 122, 110, 81, 54,
    101, 83, 88, 40, 25, 77, 98, 122, 105,
)
EXPECTED_WEIGHTS = (264303486, 264303485, 131812553, 131812552)
EXPECTED_SQUARES = (8847605690, 8847605601, 2927435647, 2927435644)


def construct_edges(lengths):
    """Closed-form lexical endpoints and one adjacent transposition each.

    This deliberately handles only >=2 months each of length >=3.
    The formulas are NOT asserted for the degenerate one-day cases.
    """
    assert len(lengths) >= 2 and all(type(n) is int and n >= 3 for n in lengths)
    k = len(lengths)
    first = [i for i, n in enumerate(lengths, 1) for _ in range(n)]
    last = (
        list(range(1, k + 1))
        + [i for i in range(k, 0, -1) for _ in range(lengths[i - 1] - 2)]
        + list(range(1, k + 1))
    )

    second = first.copy()
    # The latest legal change at the lower endpoint: exchange the last
    # (k-1) with the first k, preserving the last-occurrence ordering.
    p = sum(lengths[:-1]) - 1
    assert second[p:p + 2] == [k - 1, k]
    second[p], second[p + 1] = second[p + 1], second[p]

    penultimate = last.copy()
    # The latest legal decrease at the upper endpoint, for lengths >=3:
    # exchange the last 2 before the run of 1s with the following 1.
    q = max(i for i in range(len(last) - 1)
            if last[i:i + 2] == [2, 1])
    penultimate[q], penultimate[q + 1] = penultimate[q + 1], penultimate[q]
    return tuple(map(tuple, (first, second, penultimate, last)))


def verify_word(word, lengths):
    assert len(word) == sum(lengths)
    assert Counter(word) == dict(enumerate(lengths, 1))
    first = [word.index(i) for i in range(1, len(lengths) + 1)]
    last = [len(word) - 1 - word[::-1].index(i)
            for i in range(1, len(lengths) + 1)]
    assert all(a < b for a, b in zip(first, first[1:]))
    assert all(a < b for a, b in zip(last, last[1:]))


def moments(word):
    return (
        sum(position * month for position, month in enumerate(word, 1)),
        sum(position * month * month
            for position, month in enumerate(word, 1)),
    )


def enumerate_reference(lengths):
    """Small-only brute-force Appendix-A reference, no recurrence."""
    assert sum(lengths) <= 9
    expanded = tuple(i for i, n in enumerate(lengths, 1) for _ in range(n))
    legal = []
    for word in set(permutations(expanded)):
        first = [word.index(i) for i in range(1, len(lengths) + 1)]
        last = [len(word) - 1 - word[::-1].index(i)
                for i in range(1, len(lengths) + 1)]
        if first == sorted(first) and last == sorted(last):
            legal.append(word)
    return sorted(legal)


def independent_occurrence_projection(word, lengths):
    """Check all month/ordinal pairs using independent position buckets."""
    positions = [[] for _ in lengths]
    for pos, month in enumerate(word):
        positions[month - 1].append(pos)
    assert [len(x) for x in positions] == list(lengths)
    seen = [0] * len(lengths)
    checks = 0
    for pos, month in enumerate(word):
        seen[month - 1] += 1
        ordinal = bisect_right(positions[month - 1], pos)
        assert ordinal == seen[month - 1]
        assert positions[month - 1][ordinal - 1] == pos
        checks += 1
    return checks


def five_fields_from_supplied_metadata(
    word, day, year, opening_gate, cutlet_day_lengths,
    cutlet_names, month_names,
):
    """Projection only. Supplied metadata MUST be certified separately.

    In particular, this function cannot independently select actual
    cutlets, their names, or the canonical month-name permutation.
    """
    assert len(cutlet_day_lengths) == len(cutlet_names) >= 1
    assert sum(cutlet_day_lengths) == len(word)
    assert all(type(x) is int and x > 0 for x in cutlet_day_lengths)
    assert len(month_names) >= max(word)
    assert len(set(cutlet_names)) == len(cutlet_names)
    assert len(set(month_names)) == len(month_names)
    position = day - opening_gate - 1
    if not 0 <= position < len(word):
        raise ValueError("Target day outside the supplied year")
    cutlet_start = 0
    for length, name in zip(cutlet_day_lengths, cutlet_names):
        if position < cutlet_start + length:
            cutlet_name = name
            cutlet_day = position - cutlet_start + 1
            break
        cutlet_start += length
    month = word[position]
    month_day = word[:position + 1].count(month)
    return year, cutlet_name, cutlet_day, month_names[month - 1], month_day


def run():
    assert len(REAL_LENGTHS) == 45 and sum(REAL_LENGTHS) == 4244
    assert min(REAL_LENGTHS) == 25 and max(REAL_LENGTHS) == 122

    small_cases = ((3, 3), (3, 4), (4, 3), (4, 4), (3, 3, 3))
    small_words = 0
    for lengths in small_cases:
        reference = enumerate_reference(lengths)
        assert len(reference) >= 4
        edges = construct_edges(lengths)
        assert edges == (reference[0], reference[1],
                         reference[-2], reference[-1])
        for word in edges:
            verify_word(word, lengths)
        small_words += len(reference)
    print("STAGE55_EDGE_CLOSED_FORM_SMALL_ENUMERATION_PASS",
          f"FAMILIES={len(small_cases)} LEGAL_WORDS={small_words}")

    edges = construct_edges(REAL_LENGTHS)
    assert edges == tuple(sorted(edges))
    checked_days = 0
    for i, word in enumerate(edges):
        verify_word(word, REAL_LENGTHS)
        weight, square = moments(word)
        assert (weight, square) == (EXPECTED_WEIGHTS[i], EXPECTED_SQUARES[i])
        checked_days += independent_occurrence_projection(word, REAL_LENGTHS)
    assert checked_days == 4 * 4244
    print("STAGE55_REAL_YEAR_EXTREMAL_INDEPENDENT_PASS",
          "YEAR=5000 MONTHS=45 DAYS=4244 WORDS=4",
          f"MONTH_DAY_PROJECTIONS={checked_days}",
          "SIGNED_MOMENT_PAIRS=4")

    # The following is deliberately NOT the actual Year-5000 cutlet or
    # canonical name mapping. It validates only the five-field consumer
    # and boundary handling, and must never be reported as a real oracle.
    synthetic_cutlets = (1, 4242, 1)
    synthetic_cutlet_names = ("demo-a", "demo-b", "demo-c")
    synthetic_month_names = tuple(f"demo-month-{i}" for i in range(1, 46))
    synthetic_cases = 0
    for word in edges:
        for offset in (1, 4244):
            fields = five_fields_from_supplied_metadata(
                word, 99 + offset, 5000, 99,
                synthetic_cutlets, synthetic_cutlet_names,
                synthetic_month_names,
            )
            assert len(fields) == 5 and fields[0] == 5000
            assert fields[1] == ("demo-a" if offset == 1 else "demo-c")
            assert fields[2] == 1
            assert fields[3] == synthetic_month_names[word[offset - 1] - 1]
            synthetic_cases += 1
        try:
            five_fields_from_supplied_metadata(
                word, 99, 5000, 99, synthetic_cutlets,
                synthetic_cutlet_names, synthetic_month_names)
        except ValueError:
            pass
        else:
            raise AssertionError("Opening gate was incorrectly included")

    assert synthetic_cases == 8
    print("STAGE55_SYNTHETIC_FIVE_FIELD_INTERFACE_PASS",
          f"CASES={synthetic_cases}")
    print("STAGE55_REAL_YEAR_CUTLET_AND_NAME_ORACLE_NOT_VERIFIED")
    print("STAGE55_REAL_YEAR_MIDDLE_RANK_NOT_VERIFIED")
    print("STAGE55_FULL_YEAR_FIVE_FIELD_DIFFERENTIAL_NOT_VERIFIED")
    print("STAGE55_STAGE55_FINAL_PASS_NOT_VERIFIED")


if __name__ == "__main__":
    run()
