import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.legacy_visible_grinds import GRIND_TABLE_WITH_SENTINEL
from pastafari_calendar.legacy_year_candidates import (
    LegacyYearCandidate,
    LegacyYearCandidateAdapter,
    Year5000TiePatchWrapper,
    legacyStableSortByLength,
)
from pastafari_calendar.monster_bootstrap import MonsterContext
from normative_reference import FOUNDATION_DAY


def _candidate(label: str, length: int, open_day: int) -> LegacyYearCandidate:
    return LegacyYearCandidate(
        label=label,
        length=length,
        open_day=open_day,
        close_day=open_day + length,
        gate_gap_count=6,
    )


class Stage35Patch17Tests(unittest.TestCase):
    def test_legacy_stable_length_sort_remains_physically_input_stable(self):
        family = (
            _candidate("geç", 5000, FOUNDATION_DAY - 100),
            _candidate("erken", 5000, FOUNDATION_DAY - 300),
            _candidate("orta", 5000, FOUNDATION_DAY - 200),
        )
        actual = legacyStableSortByLength(family)
        self.assertEqual(
            tuple(candidate.label for candidate in actual),
            ("geç", "erken", "orta"),
        )

    def test_wrapper_rejects_family_that_was_not_legacy_length_sorted(self):
        ctx = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
        with self.assertRaises(ValueError):
            Year5000TiePatchWrapper().repair_after_legacy_sort(
                ctx,
                (
                    _candidate("uzun", 5200, FOUNDATION_DAY - 200),
                    _candidate("kısa", 4000, FOUNDATION_DAY - 100),
                ),
            )

    def test_only_equal_length_run_is_reordered_by_earlier_opening(self):
        ctx = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
        legacy_sorted = legacyStableSortByLength(
            (
                _candidate("uzun", 5200, FOUNDATION_DAY - 400),
                _candidate("geç", 5000, FOUNDATION_DAY - 100),
                _candidate("erken", 5000, FOUNDATION_DAY - 300),
                _candidate("kısa", 4000, FOUNDATION_DAY - 50),
                _candidate("orta", 5000, FOUNDATION_DAY - 200),
            )
        )
        actual = Year5000TiePatchWrapper().repair_after_legacy_sort(
            ctx,
            legacy_sorted,
        )

        self.assertEqual(
            tuple(candidate.label for candidate in legacy_sorted),
            ("kısa", "geç", "erken", "orta", "uzun"),
        )
        self.assertEqual(
            tuple(candidate.label for candidate in actual),
            ("kısa", "erken", "orta", "geç", "uzun"),
        )
        self.assertEqual(ctx.patch17_run_boundaries, ((1, 4),))
        self.assertEqual(
            ctx.patch17_run_before_labels,
            (("geç", "erken", "orta"),),
        )
        self.assertEqual(
            ctx.patch17_run_after_labels,
            (("erken", "orta", "geç"),),
        )

    def test_multiple_equal_length_runs_are_repaired_independently(self):
        ctx = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
        legacy_sorted = legacyStableSortByLength(
            (
                _candidate("4000-geç", 4000, FOUNDATION_DAY - 100),
                _candidate("5000-geç", 5000, FOUNDATION_DAY - 100),
                _candidate("4000-erken", 4000, FOUNDATION_DAY - 300),
                _candidate("5000-erken", 5000, FOUNDATION_DAY - 300),
                _candidate("5200-tek", 5200, FOUNDATION_DAY - 200),
            )
        )
        actual = Year5000TiePatchWrapper().repair_after_legacy_sort(
            ctx,
            legacy_sorted,
        )
        self.assertEqual(
            tuple(candidate.label for candidate in actual),
            (
                "4000-erken",
                "4000-geç",
                "5000-erken",
                "5000-geç",
                "5200-tek",
            ),
        )
        self.assertEqual(ctx.patch17_equal_length_run_count, 2)
        self.assertEqual(ctx.patch17_run_boundaries, ((0, 2), (2, 4)))

    def test_actual_adapter_keeps_raw_legacy_state_but_returns_repaired_order(self):
        ctx = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
        adapter = LegacyYearCandidateAdapter()
        actual = adapter.sort_year5000_candidates_after_filter(
            ctx,
            FOUNDATION_DAY,
            (
                _candidate("geç", 5000, FOUNDATION_DAY - 100),
                _candidate("erken", 5000, FOUNDATION_DAY - 300),
                _candidate("orta", 5000, FOUNDATION_DAY - 200),
            ),
        )
        self.assertEqual(
            ctx.legacy_year5000_tie_sorted_labels,
            ("geç", "erken", "orta"),
        )
        self.assertEqual(
            ctx.patch17_legacy_sorted_labels,
            ("geç", "erken", "orta"),
        )
        self.assertEqual(
            tuple(candidate.label for candidate in actual),
            ("erken", "orta", "geç"),
        )
        self.assertEqual(
            ctx.patch17_corrected_labels,
            ("erken", "orta", "geç"),
        )

    def test_adapter_calls_legacy_sort_before_tie_patch_wrapper(self):
        ctx = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
        adapter = LegacyYearCandidateAdapter()
        with patch(
            "pastafari_calendar.legacy_year_candidates.legacyStableSortByLength",
            wraps=legacyStableSortByLength,
        ) as legacy_sort_call, patch.object(
            adapter.tie_patch_wrapper,
            "repair_after_legacy_sort",
            wraps=adapter.tie_patch_wrapper.repair_after_legacy_sort,
        ) as patch_call:
            adapter.sort_year5000_candidates_after_filter(
                ctx,
                FOUNDATION_DAY,
                (
                    _candidate("geç", 5000, FOUNDATION_DAY - 100),
                    _candidate("erken", 5000, FOUNDATION_DAY - 300),
                ),
            )

        self.assertEqual(legacy_sort_call.call_count, 1)
        self.assertEqual(patch_call.call_count, 1)
        self.assertEqual(
            tuple(candidate.label for candidate in patch_call.call_args.args[1]),
            ("geç", "erken"),
        )

    def test_patch_state_is_invocation_local(self):
        first = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
        second = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)

        LegacyYearCandidateAdapter().sort_year5000_candidates_after_filter(
            first,
            FOUNDATION_DAY,
            (
                _candidate("geç", 5000, FOUNDATION_DAY - 100),
                _candidate("erken", 5000, FOUNDATION_DAY - 300),
            ),
        )

        self.assertTrue(first.patch17_applied)
        self.assertEqual(first.patch17_equal_length_run_count, 1)
        self.assertIsNotNone(first.patch17_corrected_labels)

        self.assertFalse(second.patch17_applied)
        self.assertEqual(second.patch17_equal_length_run_count, 0)
        self.assertIsNone(second.patch17_corrected_labels)
        self.assertIsNone(second.patch17_run_boundaries)

    def test_observability_state_cannot_change_tie_repair(self):
        plain = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
        noisy = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
        noisy.logs.extend([("önceden", 1), ("önceden", 2)])
        noisy.metrics["yalnızca-gözlem"] = 17100
        noisy.diagnostics.append(("tanı", 35))

        family = (
            _candidate("geç", 5000, FOUNDATION_DAY - 100),
            _candidate("erken", 5000, FOUNDATION_DAY - 300),
            _candidate("orta", 5000, FOUNDATION_DAY - 200),
        )

        plain_result = LegacyYearCandidateAdapter().sort_year5000_candidates_after_filter(
            plain,
            FOUNDATION_DAY,
            family,
        )
        noisy_result = LegacyYearCandidateAdapter().sort_year5000_candidates_after_filter(
            noisy,
            FOUNDATION_DAY,
            family,
        )

        self.assertEqual(plain_result, noisy_result)
        self.assertEqual(
            plain.patch17_corrected_labels,
            noisy.patch17_corrected_labels,
        )

    def test_stage15_sentinel_is_still_present(self):
        self.assertEqual(len(GRIND_TABLE_WITH_SENTINEL), 12)


if __name__ == "__main__":
    unittest.main()
