#!/usr/bin/env python3
"""Bounded independent five-field date composition for Kotlin+Cymraeg research.

Components were independently implemented in this branch. This adapter does
not call production Kotlin or the pinned Python reference. A caller-supplied
GateLedger is NOT, by itself, proof that real signed gaps were replayed from
FOUNDATION. Synthetic tests are not TABLETS certification.
"""
from __future__ import annotations

from time import monotonic
from typing import Callable

from independent_date_combinatorics import (
    count_bounded_compositions, count_cutlet_partitions,
    unrank_bounded_composition, unrank_cutlet_partition,
    unrank_distinct_names, rank_from_sauce,
)
from independent_month_weaving_oracle import IndependentMonthWeavingOracle
from independent_year_geometry_oracle import (
    FOUNDATION, GateLedger, IndependentYearGeometry,
)
from independent_sauce_oracle import evaluate, gap_from_witness

STATUS = "INDEPENDENT_FIVE_FIELD_DATE_COMPONENT_DIAGNOSTIC_NOT_CERTIFIED"


class IndependentDateError(ValueError):
    pass


def independent_signed_gap(index: int, *, deadline: float | None = None) -> int:
    """Evaluate one signed GLOBAL gate index, with no checkpoint/cache seed."""
    if type(index) is not int or index == 0:
        raise IndependentDateError("E_DATE_GATE_INDEX")
    return gap_from_witness(evaluate(FOUNDATION, FOUNDATION + index, deadline=deadline))


def independent_rank(calculation_day: int, *, deadline: float | None = None):
    """Real independent structural sauce and cyclic rank; no production reads."""
    if type(calculation_day) is not int or calculation_day != FOUNDATION:
        raise IndependentDateError("E_DATE_ORIGIN")

    def choose(target: int, bowl: int, seal: int, count: int) -> int:
        if (any(type(x) is not int for x in (target, bowl, seal, count))
                or not 1 <= bowl <= 6 or not 1 <= seal <= 255 or count < 1):
            raise IndependentDateError("E_DATE_RANK_REQUEST")
        return rank_from_sauce(
            evaluate(calculation_day, target, deadline=deadline), bowl, seal, count
        )
    return choose


def date_from_ledger(
    ledger: GateLedger, calculation_day: int, target_day: int,
    rank: Callable[[int, int, int, int], int], *,
    deadline: float | None = None,
) -> tuple[int, int, int, int, int]:
    """Produce (year, canonical cutlet, day in cutlet, canonical month, day in month).

    rank(target,bowl,seal,size) is an explicit dependency for exhaustive synthetic
    tests. Production comparison must use independent_rank and independently
    replayed signed gaps. Nothing here invokes --certify.
    """
    if (not isinstance(ledger, GateLedger)
            or any(type(x) is not int for x in (calculation_day, target_day))
            or calculation_day != FOUNDATION
            or ledger.origin != calculation_day
            or not callable(rank)
            or (deadline is not None and
                (type(deadline) not in (int, float) or deadline <= monotonic()))):
        raise IndependentDateError("E_DATE_INPUT")

    def check():
        if deadline is not None and monotonic() >= deadline:
            raise IndependentDateError("E_DATE_DEADLINE")

    def choose(day: int, bowl: int, seal: int, count: int) -> int:
        check()
        selected = rank(day, bowl, seal, count)
        if type(selected) is not int or not 1 <= selected <= count:
            raise IndependentDateError("E_DATE_RANK")
        return selected

    year, _transitions = IndependentYearGeometry(ledger).find(
        calculation_day, target_day,
        lambda day, seal, count: choose(day, 1, seal, count),
        deadline=deadline,
    )
    check()
    gaps = year.close_index - year.open_index
    cutlet_choices = tuple(k for k in range(6, 18) if k <= gaps)
    if not cutlet_choices:
        raise IndependentDateError("E_DATE_CUTLET_COUNT")
    cook_day = year.open_day + 1
    cutlet_count = cutlet_choices[choose(cook_day, 2, 20, len(cutlet_choices)) - 1]

    exact = ledger.gate_index(calculation_day)
    boundary = (exact - year.open_index if exact is not None and
                year.open_index < exact < year.close_index else None)
    partition_count = count_cutlet_partitions(gaps, cutlet_count, boundary)
    partition = unrank_cutlet_partition(
        gaps, cutlet_count, boundary, choose(cook_day, 2, 21, partition_count))
    from math import perm
    cutlet_names = unrank_distinct_names(
        17, cutlet_count, choose(cook_day, 5, 22, perm(17, cutlet_count)))

    cursor = year.open_index
    cutlet_result = None
    for width, name in zip(partition, cutlet_names):
        right = cursor + width
        if ledger.day(cursor) < target_day <= ledger.day(right):
            if cutlet_result is not None:
                raise IndependentDateError("E_DATE_CUTLET_OVERLAP")
            cutlet_result = (name, target_day - ledger.day(cursor))
        cursor = right
    if cursor != year.close_index or cutlet_result is None:
        raise IndependentDateError("E_DATE_CUTLET_COVERAGE")

    total = year.close_day - year.open_day
    smallest = (total + 122) // 123
    largest = min(47, total // 4)
    if not 3 <= smallest <= largest:
        raise IndependentDateError("E_DATE_MONTH_COUNT")
    month_count = smallest + choose(cook_day, 3, 30, largest - smallest + 1) - 1
    count_lengths = count_bounded_compositions(total, month_count, 4, 123)
    lengths = unrank_bounded_composition(
        total, month_count, 4, 123,
        choose(cook_day, 3, 31, count_lengths),
    )
    month_names = unrank_distinct_names(
        47, month_count,
        choose(cook_day, 5, 33, perm(47, month_count)),
    )
    check()
    weave = IndependentMonthWeavingOracle(lengths)
    day_offset = target_day - year.open_day - 1
    woven = weave.day_at(choose(cook_day, 4, 32, weave.count_all()), day_offset)
    result = (year.number, cutlet_result[0], cutlet_result[1],
              month_names[woven.ordinal - 1], woven.day_in_month)
    if (any(type(x) is not int for x in result)
            or result[0] < 1 or not 1 <= result[1] <= 17
            or not 1 <= result[2] <= total
            or not 1 <= result[3] <= 47
            or not 1 <= result[4] <= 123):
        raise IndependentDateError("E_DATE_POSTCONDITION")
    return result


def date_with_independent_sauce(
    ledger: GateLedger, target_day: int, *,
    deadline: float | None = None,
) -> tuple[int, int, int, int, int]:
    """Full independent component composition, not a certification or real replay."""
    return date_from_ledger(
        ledger, FOUNDATION, target_day,
        independent_rank(FOUNDATION, deadline=deadline), deadline=deadline
    )
