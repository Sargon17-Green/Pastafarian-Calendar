#!/usr/bin/env python3
"""Independent bounded year geometry for Kotlin+Cymraeg TABLETS research.

This computes no cutlet, month or five-field date and cannot certify TABLETS.
It reconstructs the signed, unseeded gate ledger from a caller-supplied gap
oracle, enumerates Year-5000 candidates, and navigates selected years.
The caller owns independent sauce/rank provenance; this module never imports
production Kotlin or the pinned-language implementation.
"""
from __future__ import annotations
from dataclasses import dataclass
from time import monotonic
from typing import Callable

FOUNDATION = -15055671
MIN_GAP, MAX_GAP = 42, 963
MIN_YEAR, MAX_YEAR = 252, 5778
MAX_QUESTIONS, MAX_SEGMENT = 32768, 8192

class YearGeometryError(ValueError):
    pass

@dataclass(frozen=True)
class Year:
    number: int
    open_index: int
    close_index: int
    open_day: int
    close_day: int

class GateLedger:
    """Contiguous global signed indices with no imported checkpoint or seed."""
    def __init__(self, origin: int, first: int, last: int,
                 gap: Callable[[int], int], *, max_questions: int = MAX_QUESTIONS,
                 segment_limit: int = 4096, deadline: float | None = None):
        if (type(origin) is not int or type(first) is not int or
            type(last) is not int or not first < 0 < last or
            type(max_questions) is not int or not 1 <= max_questions <= MAX_QUESTIONS or
            type(segment_limit) is not int or not 1 <= segment_limit <= MAX_SEGMENT or
            last - first > max_questions or not callable(gap)):
            raise YearGeometryError('E_LEDGER_BUDGET_OR_SHAPE')
        days = {0: origin}
        # The negative and positive scans both begin at the actual FOUNDATION.
        for sign, count in ((-1, -first), (1, last)):
            pos = origin
            for step in range(1, count + 1):
                if deadline is not None and monotonic() >= deadline:
                    raise YearGeometryError('E_LEDGER_DEADLINE')
                index = sign * step
                width = gap(index)
                if type(width) is not int or not MIN_GAP <= width <= MAX_GAP:
                    raise YearGeometryError(f'E_LEDGER_GAP_AT_{index}')
                pos += sign * width
                days[index] = pos
        self.origin, self.first, self.last = origin, first, last
        self.segment_limit, self.question_count = segment_limit, last - first
        self.segment_count = ((-first + segment_limit - 1)//segment_limit +
                              (last + segment_limit - 1)//segment_limit)
        self._days = days

    def day(self, index: int) -> int:
        if type(index) is not int or not self.first <= index <= self.last:
            raise YearGeometryError('E_LEDGER_INDEX_OUT_OF_BOUNDS')
        return self._days[index]

    def gate_index(self, day: int) -> int | None:
        """Binary-search the exact gate; do not approximate a missing one."""
        if type(day) is not int:
            raise YearGeometryError('E_LEDGER_DAY_TYPE')
        low, high = self.first, self.last
        while low <= high:
            middle = (low + high)//2
            if self.day(middle) == day:
                return middle
            if self.day(middle) < day:
                low = middle + 1
            else:
                high = middle - 1
        return None

class IndependentYearGeometry:
    """Exact year candidate geometry, independent of production DP/navigation."""
    def __init__(self, ledger: GateLedger, *, max_transitions: int = 12000):
        if (not isinstance(ledger, GateLedger) or type(max_transitions) is not int
                or not 1 <= max_transitions <= 12000):
            raise YearGeometryError('E_YEAR_GEOMETRY_INPUT')
        self.ledger, self.max_transitions = ledger, max_transitions

    def _choose(self, selector: Callable[[int, int, int], int],
                target: int, seal: int, options: tuple[Year, ...]) -> Year:
        if not options or not callable(selector):
            raise YearGeometryError('E_YEAR_NO_CANDIDATES')
        selection = selector(target, seal, len(options))
        if type(selection) is not int or not 1 <= selection <= len(options):
            raise YearGeometryError('E_YEAR_SELECTOR_RANK')
        return options[selection - 1]

    def year5000(self, calculation_day: int,
                 selector: Callable[[int, int, int], int]) -> Year:
        if type(calculation_day) is not int:
            raise YearGeometryError('E_YEAR_CALCULATION_DAY')
        d = self.ledger.day
        # The complete candidate set is contained in C +/- 5778.
        if (d(self.ledger.first) > calculation_day - MAX_YEAR or
                d(self.ledger.last) < calculation_day + MAX_YEAR):
            raise YearGeometryError('E_YEAR5000_INCOMPLETE_COVERAGE')
        options = []
        for left in range(self.ledger.first, self.ledger.last - 5):
            start = d(left)
            if start >= calculation_day:
                break
            if start < calculation_day - MAX_YEAR:
                continue
            for right in range(left + 6, self.ledger.last + 1):
                end = d(right)
                span = end - start
                if span > MAX_YEAR:
                    break
                if MIN_YEAR <= span and start < calculation_day <= end:
                    options.append(Year(5000, left, right, start, end))
        # Independent explicit pair enumeration and canonical sorting.
        options.sort(key=lambda y: (y.close_day - y.open_day, y.open_day))
        return self._choose(selector, calculation_day, 10, tuple(options))

    def _validate(self, year: Year) -> None:
        d = self.ledger.day
        if (not isinstance(year, Year) or
                type(year.number) is not int or year.number < 1 or
                year.close_index - year.open_index < 6 or
                year.open_index < self.ledger.first or
                year.close_index > self.ledger.last or
                d(year.open_index) != year.open_day or
                d(year.close_index) != year.close_day or
                not MIN_YEAR <= year.close_day - year.open_day <= MAX_YEAR):
            raise YearGeometryError('E_YEAR_INVALID')

    def next(self, year: Year, selector: Callable[[int, int, int], int]) -> Year:
        self._validate(year)
        d = self.ledger.day
        start = year.close_index
        # An exhausted ledger is NOT evidence of no legal candidate.
        if start + 6 > self.ledger.last or d(self.ledger.last) - d(start) < MAX_YEAR:
            raise YearGeometryError('E_YEAR_FORWARD_LEDGER_INCOMPLETE')
        options = []
        for end in range(start + 6, self.ledger.last + 1):
            span = d(end) - d(start)
            if span > MAX_YEAR:
                break
            if span >= MIN_YEAR:
                options.append(Year(year.number + 1, start, end, d(start), d(end)))
        return self._choose(selector, d(start), 11, tuple(options))

    def previous(self, year: Year, selector: Callable[[int, int, int], int]) -> Year:
        self._validate(year)
        d = self.ledger.day
        end = year.open_index
        if end - 6 < self.ledger.first or d(end) - d(self.ledger.first) < MAX_YEAR:
            raise YearGeometryError('E_YEAR_BACKWARD_LEDGER_INCOMPLETE')
        options = []
        for start in range(end - 6, self.ledger.first - 1, -1):
            span = d(end) - d(start)
            if span > MAX_YEAR:
                break
            if span >= MIN_YEAR:
                options.append(Year(year.number - 1, start, end, d(start), d(end)))
        return self._choose(selector, d(end), 12, tuple(options))

    def find(self, calculation_day: int, target: int,
             selector: Callable[[int, int, int], int], *,
             deadline: float | None = None) -> tuple[Year, int]:
        if type(target) is not int:
            raise YearGeometryError('E_YEAR_TARGET')
        selected = self.year5000(calculation_day, selector)
        transitions = 0
        while not (selected.open_day < target <= selected.close_day):
            if deadline is not None and monotonic() >= deadline:
                raise YearGeometryError('E_YEAR_DEADLINE')
            if transitions >= self.max_transitions:
                raise YearGeometryError('E_YEAR_TRANSITION_BUDGET')
            selected = (self.next(selected, selector) if target > selected.close_day
                        else self.previous(selected, selector))
            transitions += 1
        self._validate(selected)
        return selected, transitions


def independent_sauce_selector(calculation_day: int, *, deadline: float | None = None):
    """Compose independent sauce witness with independent exact rank primitive."""
    from independent_sauce_oracle import evaluate
    from independent_date_combinatorics import rank_from_sauce
    if type(calculation_day) is not int:
        raise YearGeometryError('E_SELECTOR_ORIGIN')
    def select(target: int, seal: int, number: int) -> int:
        if (type(target) is not int or type(seal) is not int or
                type(number) is not int or not 1 <= number):
            raise YearGeometryError('E_SELECTOR_INPUT')
        witness = evaluate(calculation_day, target, deadline=deadline)
        return rank_from_sauce(witness, 1, seal, number)
    return select
