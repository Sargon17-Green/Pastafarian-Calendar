import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.legacy_month_day_position import (
    LegacyContiguousMonthDayAdapter,
    oldContiguousMonthDayGuess,
)
from pastafari_calendar.legacy_month_weaving import LegacyMonthWeavingAdapter
from pastafari_calendar.legacy_structure_sauce import LegacyStructureSauceAdapter
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from normative_reference import FOUNDATION_DAY


class Stage50Discovery25Tests(unittest.TestCase):
    def test_old_contiguous_guess_is_correct_only_when_occurrences_are_contiguous(self):
        weaving = (
            1,
            1,
            1,
            2,
            2,
            3,
        )

        self.assertEqual(
            oldContiguousMonthDayGuess(
                weaving,
                2,
            ),
            2,
        )
        self.assertEqual(
            oldContiguousMonthDayGuess(
                weaving,
                5,
            ),
            2,
        )

    def test_old_contiguous_guess_overcounts_interleaved_month_occurrences(self):
        weaving = (
            1,
            1,
            2,
            1,
            3,
            2,
        )
        target_position = 4
        month_id = weaving[
            target_position - 1
        ]
        actual = oldContiguousMonthDayGuess(
            weaving,
            target_position,
        )
        correct_occurrence_count = sum(
            1
            for seen in weaving[
                :target_position
            ]
            if seen == month_id
        )

        self.assertEqual(
            actual,
            4,
        )
        self.assertEqual(
            correct_occurrence_count,
            3,
        )
        self.assertGreater(
            actual,
            correct_occurrence_count,
        )

    def test_adapter_records_first_position_and_wrong_semantic_day(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        weaving = (
            1,
            1,
            2,
            1,
            3,
            2,
        )

        actual = LegacyContiguousMonthDayAdapter().call(
            ctx,
            weaving,
            4,
        )

        self.assertEqual(
            ctx.legacy_month_day_month_id,
            1,
        )
        self.assertEqual(
            ctx.legacy_month_day_first_position,
            1,
        )
        self.assertEqual(
            ctx.legacy_month_day_guessed_day,
            4,
        )
        self.assertEqual(
            ctx.patch25_wrong_guess,
            ctx.legacy_month_day_guessed_day,
        )
        self.assertEqual(
            ctx.legacy_month_day_semantic_day,
            actual,
        )
        self.assertEqual(
            ctx.patch25_semantic_day_in_month,
            actual,
        )

    def test_contiguous_month_day_guess_is_on_real_calendar_path_after_patch24_weaving(self):
        with patch(
            "pastafari_calendar.legacy_month_day_position.LegacyContiguousMonthDayAdapter.call",
            autospec=True,
            wraps=LegacyContiguousMonthDayAdapter.call,
        ) as month_day_call:
            with patch(
                "pastafari_calendar.final_integration.FinalSpaghettiIntegrationManager.execute",
                return_value=None,
            ):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                )

        self.assertEqual(
            month_day_call.call_count,
            1,
        )
        ctx = month_day_call.call_args.args[
            1
        ]

        self.assertEqual(
            month_day_call.call_args.args[
                2
            ],
            ctx.patch24_semantic_weaving,
        )
        self.assertEqual(
            month_day_call.call_args.args[
                3
            ],
            4,
        )
        self.assertEqual(
            ctx.patch25_wrong_guess,
            ctx.legacy_month_day_guessed_day,
        )
        self.assertEqual(
            ctx.legacy_month_day_semantic_day,
            ctx.patch25_correct_day_in_month,
        )

    def test_month_day_state_is_invocation_local(self):
        first = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        second = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

        LegacyContiguousMonthDayAdapter().call(
            first,
            (
                1,
                1,
                2,
                1,
            ),
            4,
        )

        self.assertEqual(
            first.legacy_month_day_calls,
            1,
        )
        self.assertIsNotNone(
            first.legacy_month_day_guessed_day,
        )

        self.assertEqual(
            second.legacy_month_day_calls,
            0,
        )
        self.assertIsNone(
            second.legacy_month_day_guessed_day,
        )

    def test_patch25_occurrence_count_correction_is_present_and_old_guess_remains(self):
        production = (
            ROOT
            / "src"
            / "pastafari_calendar"
            / "legacy_month_day_position.py"
        ).read_text(
            encoding="utf-8"
        )

        required = (
            "def oldContiguousMonthDayGuess(",
            "def countMonthOccurrencesThroughTarget(",
            "class MonthDayOccurrencePatchWrapper:",
            "correct_day_in_month",
            "patch25_applied",
        )

        for token in required:
            self.assertIn(
                token,
                production,
            )

    def test_patch24_corrected_weaving_can_still_be_non_contiguous_for_one_month(self):
        calculation_day = FOUNDATION_DAY
        original_target_day = FOUNDATION_DAY + 3
        year_first_day = FOUNDATION_DAY + 3
        ctx = MonsterContext(
            calculation_day,
            original_target_day,
        )

        LegacyStructureSauceAdapter().call(
            ctx,
            calculation_day,
            original_target_day,
            year_first_day,
        )
        weaving = LegacyMonthWeavingAdapter().call(
            ctx,
            (
                4,
                4,
                4,
            ),
        )

        positions = tuple(
            index
            for index, month_id in enumerate(
                weaving,
                start=1,
            )
            if month_id == 1
        )

        self.assertEqual(
            positions,
            (
                1,
                2,
                4,
                5,
            ),
        )

    def test_current_contiguous_month_day_guess_diverges_from_occurrence_count(self):
        cases = (
            (
                FOUNDATION_DAY,
                FOUNDATION_DAY + 3,
                FOUNDATION_DAY + 3,
                4,
            ),
            (
                FOUNDATION_DAY + 7,
                FOUNDATION_DAY + 5,
                FOUNDATION_DAY + 107,
                5,
            ),
            (
                FOUNDATION_DAY - 11,
                FOUNDATION_DAY - 6,
                FOUNDATION_DAY - 111,
                4,
            ),
        )

        for (
            calculation_day,
            original_target_day,
            year_first_day,
            target_position,
        ) in cases:
            with self.subTest(
                calculation_day=calculation_day,
                original_target_day=original_target_day,
                year_first_day=year_first_day,
                target_position=target_position,
            ):
                ctx = MonsterContext(
                    calculation_day,
                    original_target_day,
                )

                LegacyStructureSauceAdapter().call(
                    ctx,
                    calculation_day,
                    original_target_day,
                    year_first_day,
                )

                weaving = LegacyMonthWeavingAdapter().call(
                    ctx,
                    (
                        4,
                        4,
                        4,
                    ),
                )

                actual = LegacyContiguousMonthDayAdapter().call(
                    ctx,
                    weaving,
                    target_position,
                )

                month_id = weaving[
                    target_position - 1
                ]
                expected = sum(
                    1
                    for seen in weaving[
                        :target_position
                    ]
                    if seen == month_id
                )

                self.assertGreater(
                    ctx.legacy_month_day_guessed_day,
                    expected,
                    msg="Discovery 25 witness old contiguous guess scar'ının interleaved month occurrence aralarını day-in-month sanmasını göstermelidir",
                )
                self.assertEqual(
                    actual,
                    expected,
                    msg="Legacy contiguous month-day guess occurrence count yerine ilk occurrence mesafesini kullandığı için authoritative day-in-month değerinden ayrıştı",
                )


if __name__ == "__main__":
    unittest.main()
