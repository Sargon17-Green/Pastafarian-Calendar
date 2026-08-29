import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.legacy_year_candidates import (
    LegacyYearCandidate,
    LegacyYearCandidateAdapter,
    legacyStableSortByLength,
)
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from normative_reference import FOUNDATION_DAY


def _candidate(label: str, length: int, open_day: int) -> LegacyYearCandidate:
    return LegacyYearCandidate(
        label=label,
        length=length,
        open_day=open_day,
        close_day=open_day + length,
        gate_gap_count=6,
    )


def _authoritative_tie_order_test_only(
    candidates: tuple[LegacyYearCandidate, ...],
) -> tuple[LegacyYearCandidate, ...]:
    working = list(candidates)
    working.sort(key=lambda candidate: candidate.length)

    start = 0
    while start < len(working):
        end = start + 1
        while end < len(working) and working[end].length == working[start].length:
            end += 1

        run = working[start:end]
        run.sort(key=lambda candidate: candidate.open_day)
        working[start:end] = run
        start = end

    return tuple(working)


class Stage34Discovery17Tests(unittest.TestCase):
    def test_year5000_tie_adapter_is_on_the_real_calendar_path(self):
        with patch(
            "pastafari_calendar.legacy_year_candidates.LegacyYearCandidateAdapter.sort_year5000_candidates_after_filter",
            autospec=True,
            wraps=LegacyYearCandidateAdapter.sort_year5000_candidates_after_filter,
        ) as tie_call:
            with self.assertRaises(StageNotIntegratedError):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                )

            self.assertEqual(tie_call.call_count, 1)
            self.assertEqual(len(tie_call.call_args.args[3]), 3)

    def test_legacy_helper_really_preserves_equal_length_input_order(self):
        late = _candidate("geç", 5000, FOUNDATION_DAY - 100)
        early = _candidate("erken", 5000, FOUNDATION_DAY - 300)
        middle = _candidate("orta", 5000, FOUNDATION_DAY - 200)

        actual = legacyStableSortByLength((late, early, middle))

        self.assertEqual(
            tuple(candidate.label for candidate in actual),
            ("geç", "erken", "orta"),
        )

    def test_non_tied_lengths_are_still_sorted_shortest_to_longest(self):
        actual = legacyStableSortByLength(
            (
                _candidate("uzun", 5200, FOUNDATION_DAY - 300),
                _candidate("kısa", 4000, FOUNDATION_DAY - 100),
                _candidate("orta", 5000, FOUNDATION_DAY - 200),
            )
        )

        self.assertEqual(
            tuple(candidate.length for candidate in actual),
            (4000, 5000, 5200),
        )

    def test_year5000_tie_state_is_owned_by_one_invocation(self):
        first = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
        second = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
        adapter = LegacyYearCandidateAdapter()

        adapter.sort_year5000_candidates_after_filter(
            first,
            FOUNDATION_DAY,
            (
                _candidate("geç", 5000, FOUNDATION_DAY - 100),
                _candidate("erken", 5000, FOUNDATION_DAY - 300),
            ),
        )

        self.assertEqual(
            first.legacy_year5000_tie_input_labels,
            ("geç", "erken"),
        )
        self.assertEqual(
            first.legacy_year5000_tie_sorted_labels,
            ("geç", "erken"),
        )

        self.assertIsNone(second.legacy_year5000_tie_input_labels)
        self.assertIsNone(second.legacy_year5000_tie_sorted_labels)

    def test_current_year5000_stable_length_sort_keeps_wrong_opening_order(self):
        short = _candidate("kısa", 4000, FOUNDATION_DAY - 50)
        early = _candidate("erken", 5000, FOUNDATION_DAY - 300)
        middle = _candidate("orta", 5000, FOUNDATION_DAY - 200)
        late = _candidate("geç", 5000, FOUNDATION_DAY - 100)
        long = _candidate("uzun", 5200, FOUNDATION_DAY - 400)

        adapter = LegacyYearCandidateAdapter()

        for tied_input in (
            (late, early, middle),
            (middle, late, early),
            (late, middle, early),
        ):
            with self.subTest(
                tied_labels=tuple(candidate.label for candidate in tied_input),
            ):
                ctx = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
                family = (short, *tied_input, long)

                actual = adapter.sort_year5000_candidates_after_filter(
                    ctx,
                    FOUNDATION_DAY,
                    family,
                )
                expected = _authoritative_tie_order_test_only(family)

                self.assertEqual(
                    tuple(candidate.label for candidate in actual),
                    tuple(candidate.label for candidate in expected),
                    msg="Legacy stable length-only sort equal-length run içinde erken gate opening sırasını uygulamadı",
                )


if __name__ == "__main__":
    unittest.main()
