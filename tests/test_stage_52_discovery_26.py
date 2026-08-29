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
    legacyClosedOpeningContains,
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


class Stage52Discovery26Tests(unittest.TestCase):
    def test_legacy_interval_includes_both_open_and_close_boundaries(self):
        year = LegacyOpeningGateYear(
            number=5001,
            open_day=100,
            close_day=200,
        )

        self.assertTrue(
            legacyClosedOpeningContains(
                year,
                100,
            )
        )
        self.assertTrue(
            legacyClosedOpeningContains(
                year,
                200,
            )
        )
        self.assertFalse(
            legacyClosedOpeningContains(
                year,
                99,
            )
        )

    def test_legacy_backward_search_uses_strict_less_than_open(self):
        year = LegacyOpeningGateYear(
            number=5001,
            open_day=100,
            close_day=200,
        )

        actual_at_open = legacyFindYearClosedOpeningInterval(
            year,
            100,
            _previous_year,
        )
        actual_before_open = legacyFindYearClosedOpeningInterval(
            year,
            99,
            _previous_year,
        )

        self.assertEqual(
            actual_at_open.number,
            5001,
        )
        self.assertEqual(
            actual_before_open.number,
            5000,
        )

    def test_close_gate_still_belongs_to_current_year_in_legacy_interval(self):
        year = LegacyOpeningGateYear(
            number=5001,
            open_day=100,
            close_day=200,
        )

        actual = legacyFindYearClosedOpeningInterval(
            year,
            200,
            _previous_year,
        )

        self.assertEqual(
            actual.number,
            5001,
        )

    def test_legacy_opening_gate_adapter_is_on_real_calendar_path(self):
        with patch(
            "pastafari_calendar.legacy_opening_gate_interval.LegacyOpeningGateIntervalAdapter.call",
            autospec=True,
            wraps=LegacyOpeningGateIntervalAdapter.call,
        ) as interval_call:
            with patch(
                "pastafari_calendar.final_integration.FinalSpaghettiIntegrationManager.execute",
                return_value=None,
            ):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                )

        self.assertEqual(
            interval_call.call_count,
            1,
        )

        ctx = interval_call.call_args.args[
            1
        ]
        anchor = interval_call.call_args.args[
            2
        ]
        boundary_target = interval_call.call_args.args[
            3
        ]

        self.assertEqual(
            boundary_target,
            anchor.open_day,
        )
        self.assertTrue(
            ctx.legacy_opening_interval_closed_open_assumption,
        )
        self.assertEqual(
            ctx.legacy_opening_interval_backward_steps,
            0,
        )
        self.assertEqual(
            ctx.legacy_opening_interval_result_number,
            anchor.number,
        )

    def test_opening_interval_state_is_invocation_local(self):
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

        self.assertEqual(
            first.legacy_opening_interval_calls,
            1,
        )
        self.assertTrue(
            first.legacy_opening_interval_closed_open_assumption,
        )
        self.assertIsNotNone(
            first.legacy_opening_interval_result_number,
        )

        self.assertEqual(
            second.legacy_opening_interval_calls,
            0,
        )
        self.assertFalse(
            second.legacy_opening_interval_closed_open_assumption,
        )
        self.assertIsNone(
            second.legacy_opening_interval_result_number,
        )

    def test_patch26_backward_boundary_correction_is_present_but_legacy_path_remains(self):
        production = (
            ROOT
            / "src"
            / "pastafari_calendar"
            / "legacy_opening_gate_interval.py"
        ).read_text(
            encoding="utf-8"
        )

        required = (
            "def legacyFindYearClosedOpeningInterval(",
            "while target_day < current.open_day:",
            "def correctOpeningGateInterval(",
            "while target_day <= current.open_day:",
            "class OpeningGateIntervalPatchWrapper:",
            "patch26_applied",
        )

        for token in required:
            self.assertIn(
                token,
                production,
            )

    def test_authoritative_interval_rule_is_open_left_closed_right(self):
        year = LegacyOpeningGateYear(
            number=5001,
            open_day=100,
            close_day=200,
        )

        self.assertFalse(
            year.open_day
            < year.open_day
            <= year.close_day
        )
        self.assertTrue(
            year.open_day
            < year.close_day
            <= year.close_day
        )

    def test_current_closed_opening_interval_assigns_open_gate_to_wrong_year(self):
        cases = (
            (
                5001,
                100,
                200,
            ),
            (
                -12,
                -1000,
                -500,
            ),
            (
                9000,
                123456,
                124000,
            ),
        )

        for number, open_day, close_day in cases:
            with self.subTest(
                number=number,
                open_day=open_day,
                close_day=close_day,
            ):
                year = LegacyOpeningGateYear(
                    number=number,
                    open_day=open_day,
                    close_day=close_day,
                )
                ctx = MonsterContext(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY,
                )

                actual = LegacyOpeningGateIntervalAdapter().call(
                    ctx,
                    year,
                    open_day,
                    _previous_year,
                )

                expected = _previous_year(
                    year
                )

                self.assertEqual(
                    ctx.legacy_opening_interval_backward_steps,
                    0,
                    msg="Discovery 26 witness legacy '<' backward condition'ın target==open boundary'sinde gerçekten geri yürümediğini göstermelidir",
                )
                self.assertEqual(
                    actual.number,
                    expected.number,
                    msg="Legacy [open,close] interval opening gate'i current year'a bağladığı için authoritative (open,close] year assignment'tan ayrıştı",
                )


if __name__ == "__main__":
    unittest.main()
