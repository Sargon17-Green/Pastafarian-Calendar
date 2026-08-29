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
    MonthDayOccurrencePatchWrapper,
    countMonthOccurrencesThroughTarget,
    oldContiguousMonthDayGuess,
)
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from normative_reference import FOUNDATION_DAY


class Stage51Patch25Tests(unittest.TestCase):
    def test_occurrence_count_is_inclusive_of_target(self):
        weaving = (
            1,
            2,
            1,
            2,
            1,
        )

        self.assertEqual(
            countMonthOccurrencesThroughTarget(
                weaving,
                1,
            ),
            1,
        )
        self.assertEqual(
            countMonthOccurrencesThroughTarget(
                weaving,
                3,
            ),
            2,
        )
        self.assertEqual(
            countMonthOccurrencesThroughTarget(
                weaving,
                5,
            ),
            3,
        )

    def test_occurrence_count_matches_direct_prefix_count_for_interleaved_patterns(self):
        cases = (
            (
                (
                    1,
                    1,
                    2,
                    1,
                    3,
                    2,
                ),
                4,
            ),
            (
                (
                    1,
                    2,
                    3,
                    1,
                    2,
                    3,
                    1,
                ),
                6,
            ),
            (
                (
                    3,
                    1,
                    3,
                    2,
                    3,
                    1,
                ),
                5,
            ),
        )

        for weaving, target_position in cases:
            with self.subTest(
                weaving=weaving,
                target_position=target_position,
            ):
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

                self.assertEqual(
                    countMonthOccurrencesThroughTarget(
                        weaving,
                        target_position,
                    ),
                    expected,
                )

    def test_adapter_runs_old_guess_before_occurrence_patch(self):
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

        with patch(
            "pastafari_calendar.legacy_month_day_position.oldContiguousMonthDayGuess",
            wraps=oldContiguousMonthDayGuess,
        ) as old_call, patch(
            "pastafari_calendar.legacy_month_day_position.MonthDayOccurrencePatchWrapper.repair",
            autospec=True,
            wraps=MonthDayOccurrencePatchWrapper.repair,
        ) as patch_call:
            actual = LegacyContiguousMonthDayAdapter().call(
                ctx,
                weaving,
                4,
            )

        self.assertEqual(
            old_call.call_count,
            1,
        )
        self.assertEqual(
            patch_call.call_count,
            1,
        )
        self.assertEqual(
            ctx.legacy_month_day_guessed_day,
            4,
        )
        self.assertEqual(
            ctx.patch25_correct_day_in_month,
            3,
        )
        self.assertEqual(
            actual,
            3,
        )

        old_trace_position = next(
            index
            for index, entry in enumerate(
                ctx.branch_trace
            )
            if entry[
                0
            ] == "ESKİ_AY_GÜNÜ_SÜREKLİYMİŞ_GİBİ"
        )
        patch_trace_position = next(
            index
            for index, entry in enumerate(
                ctx.branch_trace
            )
            if entry[
                0
            ] == "YAMA_25_AY_OCCURRENCE_SAYIMI"
        )

        self.assertLess(
            old_trace_position,
            patch_trace_position,
        )

    def test_patch_overwrites_wrong_contiguous_guess(self):
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
            ctx.patch25_wrong_guess,
            4,
        )
        self.assertEqual(
            ctx.patch25_correct_day_in_month,
            3,
        )
        self.assertTrue(
            ctx.patch25_overwrite_needed,
        )
        self.assertEqual(
            ctx.patch25_semantic_day_in_month,
            3,
        )
        self.assertEqual(
            ctx.legacy_month_day_semantic_day,
            3,
        )
        self.assertEqual(
            actual,
            3,
        )

    def test_patch_preserves_correct_value_when_occurrences_are_contiguous(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        weaving = (
            1,
            1,
            1,
            2,
            2,
        )

        actual = LegacyContiguousMonthDayAdapter().call(
            ctx,
            weaving,
            3,
        )

        self.assertEqual(
            ctx.patch25_wrong_guess,
            3,
        )
        self.assertEqual(
            ctx.patch25_correct_day_in_month,
            3,
        )
        self.assertFalse(
            ctx.patch25_overwrite_needed,
        )
        self.assertEqual(
            actual,
            3,
        )

    def test_real_calendar_path_keeps_old_guess_but_semantic_day_is_occurrence_count(self):
        with patch(
            "pastafari_calendar.legacy_month_day_position.MonthDayOccurrencePatchWrapper.repair",
            autospec=True,
            wraps=MonthDayOccurrencePatchWrapper.repair,
        ) as repair_call:
            with self.assertRaises(
                StageNotIntegratedError
            ):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                )

        self.assertEqual(
            repair_call.call_count,
            1,
        )

        ctx = repair_call.call_args.args[
            1
        ]

        self.assertEqual(
            ctx.patch25_wrong_guess,
            ctx.legacy_month_day_guessed_day,
        )
        self.assertEqual(
            ctx.patch25_semantic_day_in_month,
            ctx.legacy_month_day_semantic_day,
        )
        self.assertTrue(
            ctx.patch25_applied,
        )

        weaving = ctx.patch24_semantic_weaving
        target_position = ctx.legacy_month_day_target_position
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

        self.assertEqual(
            ctx.legacy_month_day_semantic_day,
            expected,
        )

    def test_patch_state_is_invocation_local(self):
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

        self.assertTrue(
            first.patch25_applied,
        )
        self.assertIsNotNone(
            first.patch25_correct_day_in_month,
        )

        self.assertFalse(
            second.patch25_applied,
        )
        self.assertIsNone(
            second.patch25_correct_day_in_month,
        )

    def test_observability_state_cannot_change_occurrence_count(self):
        weaving = (
            1,
            2,
            1,
            3,
            1,
            2,
        )

        plain = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        noisy = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

        noisy.logs.extend(
            [
                ("önceden", 1),
                ("önceden", 2),
            ]
        )
        noisy.metrics[
            "yalnızca-gözlem"
        ] = 25100
        noisy.diagnostics.append(
            ("tanı", 51)
        )

        plain_result = LegacyContiguousMonthDayAdapter().call(
            plain,
            weaving,
            5,
        )
        noisy_result = LegacyContiguousMonthDayAdapter().call(
            noisy,
            weaving,
            5,
        )

        self.assertEqual(
            plain_result,
            noisy_result,
        )
        self.assertEqual(
            plain.patch25_correct_day_in_month,
            noisy.patch25_correct_day_in_month,
        )

    def test_patch26_opening_gate_logic_is_not_present(self):
        production = (
            ROOT
            / "src"
            / "pastafari_calendar"
        )

        text = "\n".join(
            path.read_text(
                encoding="utf-8"
            )
            for path in production.glob(
                "*.py"
            )
        )

        forbidden = (
            "OpeningGateIntervalPatchWrapper",
            "patch26_applied",
            "correctOpeningGateInterval",
        )

        for token in forbidden:
            self.assertNotIn(
                token,
                text,
            )


if __name__ == "__main__":
    unittest.main()
