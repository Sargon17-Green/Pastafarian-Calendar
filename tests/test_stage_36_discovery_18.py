import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.legacy_year_jump import (
    LEGACY_JUMP_AVERAGE_DAYS,
    LegacyYearJumpAdapter,
    LegacyYearJumpAnchor,
    oldJumpGuess,
)
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from normative_reference import FOUNDATION_DAY


def _anchor() -> LegacyYearJumpAnchor:
    open_day = (
        FOUNDATION_DAY
        - 100
    )

    return LegacyYearJumpAnchor(
        number=5000,
        first_day=open_day + 1,
        open_day=open_day,
        close_day=open_day + 5000,
    )


class Stage36Discovery18Tests(unittest.TestCase):
    def test_old_jump_guess_uses_exact_floor_division_by_365(self):
        anchor = _anchor()

        self.assertEqual(
            LEGACY_JUMP_AVERAGE_DAYS,
            365,
        )

        self.assertEqual(
            oldJumpGuess(
                anchor,
                anchor.first_day,
            ),
            5000,
        )

        self.assertEqual(
            oldJumpGuess(
                anchor,
                anchor.first_day + 365,
            ),
            5001,
        )

        self.assertEqual(
            oldJumpGuess(
                anchor,
                anchor.first_day - 1,
            ),
            4999,
        )

    def test_old_jump_guess_is_on_the_real_calendar_path(self):
        with patch(
            "pastafari_calendar.legacy_year_jump.oldJumpGuess",
            wraps=oldJumpGuess,
        ) as jump_call:
            with patch(
                "pastafari_calendar.final_integration.FinalSpaghettiIntegrationManager.execute",
                return_value=None,
            ):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                )

            self.assertEqual(
                jump_call.call_count,
                1,
            )

            anchor = jump_call.call_args.args[0]
            target_day = jump_call.call_args.args[1]

            self.assertEqual(
                anchor.number,
                5000,
            )
            self.assertEqual(
                target_day,
                anchor.close_day + 1,
            )

    def test_jump_guess_state_is_owned_by_one_invocation(self):
        first = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        second = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

        anchor = _anchor()

        actual = LegacyYearJumpAdapter().call(
            first,
            anchor,
            anchor.close_day,
        )

        self.assertEqual(
            first.legacy_jump_anchor_number,
            5000,
        )
        self.assertEqual(
            first.legacy_jump_anchor_first_day,
            anchor.first_day,
        )
        self.assertEqual(
            first.legacy_jump_target_day,
            anchor.close_day,
        )
        self.assertEqual(
            first.legacy_jump_guess_number,
            oldJumpGuess(
                anchor,
                anchor.close_day,
            ),
        )
        self.assertEqual(
            first.legacy_jump_semantic_year_number,
            actual,
        )
        self.assertFalse(
            first.legacy_jump_guess_used_as_semantic,
        )
        self.assertEqual(
            first.legacy_jump_calls,
            1,
        )

        self.assertIsNone(
            second.legacy_jump_anchor_number,
        )
        self.assertIsNone(
            second.legacy_jump_guess_number,
        )
        self.assertIsNone(
            second.legacy_jump_semantic_year_number,
        )
        self.assertFalse(
            second.legacy_jump_guess_used_as_semantic,
        )
        self.assertEqual(
            second.legacy_jump_calls,
            0,
        )

    def test_anchor_contract_requires_first_day_after_open_gate(self):
        with self.assertRaises(ValueError):
            LegacyYearJumpAnchor(
                number=5000,
                first_day=FOUNDATION_DAY,
                open_day=FOUNDATION_DAY,
                close_day=FOUNDATION_DAY + 5000,
            )

    def test_current_365_jump_guess_is_wrong_when_used_as_semantic_year(self):
        anchor = _anchor()
        adapter = LegacyYearJumpAdapter()

        cases = (
            (
                anchor.first_day + 365,
                5000,
            ),
            (
                anchor.close_day,
                5000,
            ),
            (
                anchor.close_day + 1,
                5001,
            ),
        )

        for target_day, expected_year_number in cases:
            with self.subTest(
                target_day=target_day,
            ):
                ctx = MonsterContext(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY,
                )

                actual = adapter.call(
                    ctx,
                    anchor,
                    target_day,
                )

                self.assertEqual(
                    actual,
                    expected_year_number,
                    msg="Legacy /365 year jump tahmini authoritative ardışık yıl semantiği yerine kullanıldı",
                )


if __name__ == "__main__":
    unittest.main()
