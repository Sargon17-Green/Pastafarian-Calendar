import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.legacy_day_counts import FOUNDATION_DAY_OLD
from pastafari_calendar.legacy_year_candidates import (
    LEGACY_YEAR_MAX,
    LegacyYearCandidate,
    LegacyYearCandidateAdapter,
    legacyYearCandidateAllowed,
)
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from normative_reference import (
    FOUNDATION_DAY,
    YEAR_MAX_DAYS,
)


def _candidate(
    length: int,
) -> LegacyYearCandidate:
    return LegacyYearCandidate(
        label=f"aday-{length}",
        length=length,
        open_day=FOUNDATION_DAY_OLD - length,
        close_day=FOUNDATION_DAY_OLD,
        gate_gap_count=6,
    )


class Stage32Discovery16Tests(unittest.TestCase):
    def test_legacy_year_max_is_exactly_5781_and_used_on_real_calendar_path(self):
        self.assertEqual(
            LEGACY_YEAR_MAX,
            5781,
        )

        with patch(
            "pastafari_calendar.legacy_year_candidates.legacyYearCandidateAllowed",
            wraps=legacyYearCandidateAllowed,
        ) as allowed_call:
            with patch(
                "pastafari_calendar.final_integration.FinalSpaghettiIntegrationManager.execute",
                return_value=None,
            ):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                )

            self.assertEqual(
                allowed_call.call_count,
                4,
            )
            self.assertEqual(
                tuple(
                    call.args[0].length
                    for call in allowed_call.call_args_list
                ),
                (
                    5778,
                    5779,
                    5780,
                    5781,
                ),
            )

    def test_legacy_candidate_helper_accepts_through_5781(self):
        for length in (
            5778,
            5779,
            5780,
            5781,
        ):
            with self.subTest(
                length=length,
            ):
                self.assertTrue(
                    legacyYearCandidateAllowed(
                        _candidate(
                            length,
                        )
                    )
                )

        self.assertFalse(
            legacyYearCandidateAllowed(
                _candidate(
                    5782,
                )
            )
        )

    def test_real_adapter_keeps_all_four_boundary_candidates_in_legacy_scar(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        adapter = LegacyYearCandidateAdapter()

        prepared = adapter.prepare_for_selection(
            ctx,
            (
                _candidate(5778),
                _candidate(5779),
                _candidate(5780),
                _candidate(5781),
            ),
        )

        self.assertEqual(
            ctx.patch16_legacy_accepted_lengths,
            (
                5778,
                5779,
                5780,
                5781,
            ),
        )
        self.assertEqual(
            ctx.patch16_rejected_overlong_lengths,
            (
                5779,
                5780,
                5781,
            ),
        )
        self.assertEqual(
            tuple(
                candidate.length
                for candidate in prepared
            ),
            (
                5778,
            ),
        )
        self.assertEqual(
            ctx.legacy_year_candidate_lengths_before_sort,
            (
                5778,
            ),
        )
        self.assertEqual(
            ctx.legacy_year_candidate_count_for_selection,
            1,
        )

    def test_candidate_state_is_owned_by_one_invocation(self):
        first = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        second = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        adapter = LegacyYearCandidateAdapter()

        adapter.prepare_for_selection(
            first,
            (
                _candidate(5778),
                _candidate(5781),
            ),
        )

        self.assertEqual(
            first.patch16_legacy_accepted_lengths,
            (
                5778,
                5781,
            ),
        )
        self.assertEqual(
            first.patch16_rejected_overlong_lengths,
            (
                5781,
            ),
        )
        self.assertEqual(
            first.legacy_year_candidate_lengths_before_sort,
            (
                5778,
            ),
        )
        self.assertEqual(
            first.legacy_year_candidate_count_for_selection,
            1,
        )

        self.assertIsNone(
            second.legacy_year_candidate_input_lengths,
        )
        self.assertIsNone(
            second.legacy_year_candidate_lengths_before_sort,
        )
        self.assertIsNone(
            second.legacy_year_candidate_lengths_after_sort,
        )
        self.assertIsNone(
            second.legacy_year_candidate_count_for_selection,
        )
        self.assertIsNone(
            second.patch16_legacy_accepted_lengths,
        )
        self.assertIsNone(
            second.patch16_rejected_overlong_lengths,
        )
        self.assertIsNone(
            second.patch16_semantic_accepted_lengths,
        )
        self.assertEqual(
            second.patch16_filter_evaluations,
            0,
        )
        self.assertFalse(
            second.patch16_applied,
        )

    def test_current_5781_ceiling_passes_overlong_candidates_to_sort_selection(self):
        adapter = LegacyYearCandidateAdapter()

        for length in (
            5779,
            5780,
            5781,
        ):
            with self.subTest(
                length=length,
            ):
                ctx = MonsterContext(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY,
                )

                adapter.prepare_for_selection(
                    ctx,
                    (
                        _candidate(5778),
                        _candidate(length),
                    ),
                )

                actual = (
                    length
                    in ctx.legacy_year_candidate_lengths_before_sort
                )
                expected = (
                    length
                    <= YEAR_MAX_DAYS
                )

                self.assertEqual(
                    actual,
                    expected,
                    msg="Legacy 5781 ceiling 5778 üstü adayı sort/selection girişine geçirdi",
                )


if __name__ == "__main__":
    unittest.main()
