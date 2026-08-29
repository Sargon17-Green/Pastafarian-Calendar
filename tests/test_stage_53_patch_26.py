import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.legacy_opening_gate_interval import (
    LegacyOpeningGateIntervalAdapter,
    LegacyOpeningGateYear,
    OpeningGateIntervalPatchWrapper,
    correctOpeningGateInterval,
    legacyFindYearClosedOpeningInterval,
)
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from normative_reference import FOUNDATION_DAY


def _previous_year(
    known: LegacyOpeningGateYear,
) -> LegacyOpeningGateYear:
    return LegacyOpeningGateYear(
        number=known.number - 1,
        open_day=known.open_day - 100,
        close_day=known.open_day,
    )


class Stage53Patch26Tests(unittest.TestCase):
    def test_correct_interval_moves_opening_gate_to_previous_year(self):
        year = LegacyOpeningGateYear(
            number=5001,
            open_day=100,
            close_day=200,
        )

        actual, steps = correctOpeningGateInterval(
            year,
            100,
            _previous_year,
        )

        self.assertEqual(
            steps,
            1,
        )
        self.assertEqual(
            actual.number,
            5000,
        )
        self.assertEqual(
            actual.close_day,
            100,
        )
        self.assertTrue(
            actual.open_day
            < 100
            <= actual.close_day
        )

    def test_correct_interval_keeps_interior_and_close_gate_in_current_year(self):
        year = LegacyOpeningGateYear(
            number=5001,
            open_day=100,
            close_day=200,
        )

        for target_day in (
            101,
            150,
            200,
        ):
            with self.subTest(
                target_day=target_day,
            ):
                actual, steps = correctOpeningGateInterval(
                    year,
                    target_day,
                    _previous_year,
                )

                self.assertEqual(
                    steps,
                    0,
                )
                self.assertEqual(
                    actual,
                    year,
                )

    def test_correct_interval_can_walk_multiple_opening_boundaries(self):
        year = LegacyOpeningGateYear(
            number=5001,
            open_day=100,
            close_day=200,
        )

        actual, steps = correctOpeningGateInterval(
            year,
            0,
            _previous_year,
        )

        self.assertEqual(
            steps,
            2,
        )
        self.assertEqual(
            actual.number,
            4999,
        )
        self.assertEqual(
            actual.close_day,
            0,
        )
        self.assertTrue(
            actual.open_day
            < 0
            <= actual.close_day
        )

    def test_adapter_runs_wrong_legacy_interval_before_patch_wrapper(self):
        year = LegacyOpeningGateYear(
            number=5001,
            open_day=100,
            close_day=200,
        )
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

        with patch(
            "pastafari_calendar.legacy_opening_gate_interval.legacyFindYearClosedOpeningInterval",
            wraps=legacyFindYearClosedOpeningInterval,
        ) as legacy_call, patch(
            "pastafari_calendar.legacy_opening_gate_interval.OpeningGateIntervalPatchWrapper.repair",
            autospec=True,
            wraps=OpeningGateIntervalPatchWrapper.repair,
        ) as patch_call:
            actual = LegacyOpeningGateIntervalAdapter().call(
                ctx,
                year,
                100,
                _previous_year,
            )

        self.assertEqual(
            legacy_call.call_count,
            1,
        )
        self.assertEqual(
            patch_call.call_count,
            1,
        )
        self.assertEqual(
            ctx.legacy_opening_interval_result_number,
            5001,
        )
        self.assertEqual(
            ctx.patch26_correct_result_number,
            5000,
        )
        self.assertEqual(
            actual.number,
            5000,
        )

        legacy_position = next(
            index
            for index, entry in enumerate(
                ctx.branch_trace
            )
            if entry[
                0
            ] == "ESKİ_KAPALI_OPENING_GATE_YIL_ARALIĞI"
        )
        patch_position = next(
            index
            for index, entry in enumerate(
                ctx.branch_trace
            )
            if entry[
                0
            ] == "YAMA_26_OPENING_GATE_AÇIK_SOL_ARALIK"
        )

        self.assertLess(
            legacy_position,
            patch_position,
        )

    def test_patch_keeps_wrong_boundary_result_as_scar_but_overwrites_semantics(self):
        year = LegacyOpeningGateYear(
            number=-12,
            open_day=-1000,
            close_day=-500,
        )
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

        actual = LegacyOpeningGateIntervalAdapter().call(
            ctx,
            year,
            -1000,
            _previous_year,
        )

        self.assertEqual(
            ctx.legacy_opening_interval_backward_steps,
            0,
        )
        self.assertEqual(
            ctx.legacy_opening_interval_result_number,
            -12,
        )
        self.assertEqual(
            ctx.patch26_legacy_result_number,
            -12,
        )
        self.assertEqual(
            ctx.patch26_correct_result_number,
            -13,
        )
        self.assertEqual(
            ctx.patch26_backward_steps,
            1,
        )
        self.assertTrue(
            ctx.patch26_open_boundary_hit,
        )
        self.assertFalse(
            ctx.patch26_same_as_legacy,
        )
        self.assertEqual(
            ctx.legacy_opening_interval_semantic_year_number,
            -13,
        )
        self.assertEqual(
            actual.number,
            -13,
        )

    def test_patch_reuses_legacy_result_when_interval_assignment_was_already_correct(self):
        year = LegacyOpeningGateYear(
            number=5001,
            open_day=100,
            close_day=200,
        )
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

        actual = LegacyOpeningGateIntervalAdapter().call(
            ctx,
            year,
            150,
            _previous_year,
        )

        self.assertTrue(
            ctx.patch26_same_as_legacy,
        )
        self.assertFalse(
            ctx.patch26_open_boundary_hit,
        )
        self.assertEqual(
            ctx.patch26_backward_steps,
            0,
        )
        self.assertEqual(
            actual.number,
            5001,
        )
        self.assertEqual(
            ctx.patch26_semantic_year_number,
            5001,
        )

    def test_real_calendar_path_keeps_legacy_zero_step_scar_but_semantic_year_moves_back(self):
        with patch(
            "pastafari_calendar.legacy_opening_gate_interval.OpeningGateIntervalPatchWrapper.repair",
            autospec=True,
            wraps=OpeningGateIntervalPatchWrapper.repair,
        ) as repair_call:
            with patch(
                "pastafari_calendar.final_integration.FinalSpaghettiIntegrationManager.execute",
                return_value=None,
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
            ctx.legacy_opening_interval_backward_steps,
            0,
        )
        self.assertEqual(
            ctx.patch26_backward_steps,
            1,
        )
        self.assertTrue(
            ctx.patch26_open_boundary_hit,
        )
        self.assertEqual(
            ctx.patch26_legacy_result_number,
            ctx.legacy_opening_interval_result_number,
        )
        self.assertEqual(
            ctx.patch26_correct_result_number,
            ctx.legacy_opening_interval_result_number - 1,
        )
        self.assertEqual(
            ctx.legacy_opening_interval_semantic_year_number,
            ctx.patch26_correct_result_number,
        )
        self.assertTrue(
            ctx.patch26_applied,
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
        year = LegacyOpeningGateYear(
            number=5001,
            open_day=100,
            close_day=200,
        )

        LegacyOpeningGateIntervalAdapter().call(
            first,
            year,
            100,
            _previous_year,
        )

        self.assertTrue(
            first.patch26_applied,
        )
        self.assertIsNotNone(
            first.patch26_correct_result_number,
        )

        self.assertFalse(
            second.patch26_applied,
        )
        self.assertIsNone(
            second.patch26_correct_result_number,
        )

    def test_observability_state_cannot_change_correct_interval_result(self):
        year = LegacyOpeningGateYear(
            number=5001,
            open_day=100,
            close_day=200,
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
        ] = 26100
        noisy.diagnostics.append(
            ("tanı", 53)
        )

        plain_result = LegacyOpeningGateIntervalAdapter().call(
            plain,
            year,
            100,
            _previous_year,
        )
        noisy_result = LegacyOpeningGateIntervalAdapter().call(
            noisy,
            year,
            100,
            _previous_year,
        )

        self.assertEqual(
            plain_result,
            noisy_result,
        )
        self.assertEqual(
            plain.patch26_correct_result_number,
            noisy.patch26_correct_result_number,
        )
        self.assertEqual(
            plain.patch26_backward_steps,
            noisy.patch26_backward_steps,
        )


if __name__ == "__main__":
    unittest.main()
