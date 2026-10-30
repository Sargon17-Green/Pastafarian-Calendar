#!/usr/bin/env python3
"""Bounded Appendix-A micro-oracle for five Pastafarian date fields.

This test oracle exhausts multiset permutations, independently filtering
first/last appearance order. It neither imports MATLAB nor uses the
first-position recurrence, production DAG, or normative_oracle.m.

IMPORTANT: These are synthetic micro-years, NOT certified real-year dates.
Passing does NOT certify Stage55, the year-5000 middle rank, or full differential.
"""
from dataclasses import dataclass
from itertools import permutations


@dataclass(frozen=True)
class MicroYear:
    year: int
    open_gate: int
    cutlet_lengths: tuple[int, ...]
    cutlet_names: tuple[str, ...]
    month_lengths: tuple[int, ...]
    month_names: tuple[str, ...]

    def validate(self) -> None:
        assert self.cutlet_lengths and self.month_lengths
        assert all(isinstance(x, int) and x > 0 for x in self.cutlet_lengths + self.month_lengths)
        assert sum(self.cutlet_lengths) == sum(self.month_lengths)
        assert len(self.cutlet_names) == len(self.cutlet_lengths)
        assert len(self.month_names) == len(self.month_lengths)
        assert len(set(self.cutlet_names)) == len(self.cutlet_names)
        assert len(set(self.month_names)) == len(self.month_names)
        assert sum(self.month_lengths) <= 8, "Micro oracle may not enumerate a large year"


def independent_words(lengths: tuple[int, ...]) -> list[tuple[int, ...]]:
    """Brute-force all unique permutations; no state recursion or count recurrence."""
    expanded = tuple(i for i, count in enumerate(lengths) for _ in range(count))
    legal = []
    for word in sorted(set(permutations(expanded))):
        first = [word.index(i) for i in range(len(lengths))]
        last = [len(word) - 1 - word[::-1].index(i) for i in range(len(lengths))]
        if first == sorted(first) and last == sorted(last):
            legal.append(word)
    assert legal and legal == sorted(set(legal))
    return legal


def five_fields(case: MicroYear, rank1: int, target_day: int) -> tuple:
    """Appendix-A result projection: year, cutlet, cutlet day, month, month day."""
    case.validate()
    words = independent_words(case.month_lengths)
    if not 1 <= rank1 <= len(words):
        raise ValueError("Rank outside exhaustive legal family")
    position = target_day - case.open_gate - 1
    if not 0 <= position < sum(case.month_lengths):
        raise ValueError("Target outside synthetic year")

    # Cutlet intervals cover the year in their specified canonical order.
    cutlet_index, start = 0, 0
    for i, size in enumerate(case.cutlet_lengths):
        if position < start + size:
            cutlet_index = i
            break
        start += size

    word = words[rank1 - 1]
    month_index = word[position]
    occurrence_number = sum(letter == month_index for letter in word[:position + 1])
    return (
        case.year,
        case.cutlet_names[cutlet_index],
        position - start + 1,
        case.month_names[month_index],
        occurrence_number,
    )


def check_rejections(case: MicroYear) -> int:
    words = independent_words(case.month_lengths)
    low = case.open_gate + 1
    high = case.open_gate + sum(case.month_lengths)
    rejected = 0
    for rank, day in ((0, low), (len(words) + 1, low), (1, low - 1), (1, high + 1)):
        try:
            five_fields(case, rank, day)
        except ValueError:
            rejected += 1
        else:
            raise AssertionError("Out-of-domain case was accepted")
    return rejected


def main() -> None:
    golden = MicroYear(
        5000, 99, (1, 3), ("brąz", "lis"),
        (2, 2), ("granat", "glina"),
    )
    assert independent_words(golden.month_lengths) == [(0, 0, 1, 1), (0, 1, 0, 1)]
    fixed = {
        (1, 100): (5000, "brąz", 1, "granat", 1),
        (1, 101): (5000, "lis", 1, "granat", 2),
        (1, 102): (5000, "lis", 2, "glina", 1),
        (1, 103): (5000, "lis", 3, "glina", 2),
        (2, 101): (5000, "lis", 1, "glina", 1),
        (2, 102): (5000, "lis", 2, "granat", 2),
    }
    for (rank, day), expected in fixed.items():
        assert five_fields(golden, rank, day) == expected, (rank, day)

    negative = MicroYear(
        -7, -12, (2, 1), ("Lagasz", "lis"),
        (1, 1, 1), ("łokieć", "Eridu", "granat"),
    )
    assert independent_words(negative.month_lengths) == [(0, 1, 2)]
    assert five_fields(negative, 1, -10) == (-7, "Lagasz", 2, "Eridu", 1)

    families = (
        (1,), (2,), (1, 1), (1, 2), (2, 1), (2, 2),
        (1, 1, 1), (1, 2, 1), (2, 1, 2), (2, 2, 2),
        (2, 3, 2), (2, 2, 2, 2),
    )
    names = ("granat", "glina", "łokieć", "Eridu")
    total_words = 0
    five_field_cases = 0
    edge_cases = 0
    for index, lengths in enumerate(families):
        days = sum(lengths)
        cutlets = (days,) if days == 1 else (days // 2, days - days // 2)
        case = MicroYear(
            7000 + index, -15055671 + index, cutlets,
            ("brąz",) if len(cutlets) == 1 else ("brąz", "Lagasz"),
            lengths, names[:len(lengths)],
        )
        case.validate()
        words = independent_words(lengths)
        total_words += len(words)
        for rank, word in enumerate(words, start=1):
            for position, month in enumerate(word):
                result = five_fields(case, rank, case.open_gate + 1 + position)
                assert len(result) == 5
                assert result[0] == case.year
                assert result[3] == case.month_names[month]
                assert result[4] == word[:position + 1].count(month)
                assert 1 <= result[2] <= max(case.cutlet_lengths)
                five_field_cases += 1
        edge_cases += check_rejections(case)

    print(
        "STAGE55_INDEPENDENT_NORMATIVE_MICRO_FIVE_FIELDS_PASS",
        "FAMILIES", len(families),
        "LEGAL_WORDS", total_words,
        "FIVE_FIELD_CASES", five_field_cases,
        "REJECTED_EDGE_CASES", edge_cases,
        "HAND_CHECKED", len(fixed) + 1,
        flush=True,
    )
    print("STAGE55_FULL_YEAR_ORACLE_NOT_VERIFIED", flush=True)


if __name__ == "__main__":
    main()
