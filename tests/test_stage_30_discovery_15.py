import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.legacy_gate_question import (
    LegacyGateQuestionAdapter,
    oldGateQuestionDay,
)
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from normative_reference import FOUNDATION_DAY


class Stage30Discovery15Tests(unittest.TestCase):
    def test_old_gate_question_day_is_on_the_real_calendar_path(self):
        with patch(
            "pastafari_calendar.legacy_gate_question.oldGateQuestionDay",
            wraps=oldGateQuestionDay,
        ) as old_call:
            with patch(
                "pastafari_calendar.final_integration.FinalSpaghettiIntegrationManager.execute",
                return_value=None,
            ):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                )

            self.assertEqual(
                old_call.call_count,
                1,
            )
            self.assertEqual(
                old_call.call_args.args[0],
                1,
            )

    def test_old_helper_really_asks_positive_side(self):
        self.assertEqual(
            oldGateQuestionDay(0),
            FOUNDATION_DAY,
        )
        self.assertEqual(
            oldGateQuestionDay(1),
            FOUNDATION_DAY + 1,
        )
        self.assertEqual(
            oldGateQuestionDay(10),
            FOUNDATION_DAY + 10,
        )

    def test_positive_signed_steps_remain_compatible_with_legacy_side(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        adapter = LegacyGateQuestionAdapter()

        for signed_step in (
            0,
            1,
            2,
            10,
        ):
            with self.subTest(
                signed_step=signed_step,
            ):
                self.assertEqual(
                    adapter.call(
                        ctx,
                        signed_step,
                    ),
                    FOUNDATION_DAY
                    + abs(
                        signed_step,
                    ),
                )

    def test_gate_question_state_is_owned_by_one_invocation(self):
        first = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        second = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

        result = LegacyGateQuestionAdapter().call(
            first,
            -2,
        )

        self.assertEqual(
            first.legacy_gate_signed_step,
            -2,
        )
        self.assertEqual(
            first.legacy_gate_magnitude,
            2,
        )
        self.assertEqual(
            first.legacy_gate_question_day,
            result,
        )

        self.assertIsNone(
            second.legacy_gate_signed_step,
        )
        self.assertIsNone(
            second.legacy_gate_magnitude,
        )
        self.assertIsNone(
            second.legacy_gate_question_day,
        )

    def test_current_negative_gate_question_asks_positive_side_instead_of_negative_side(self):
        adapter = LegacyGateQuestionAdapter()

        for signed_step in (
            -1,
            -2,
            -10,
        ):
            with self.subTest(
                signed_step=signed_step,
            ):
                ctx = MonsterContext(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY,
                )

                actual = adapter.call(
                    ctx,
                    signed_step,
                )
                expected = (
                    FOUNDATION_DAY
                    - abs(
                        signed_step,
                    )
                )

                self.assertEqual(
                    actual,
                    expected,
                    msg="Legacy gate sorgusu negatif signedStep için Foundation'ın yanlış pozitif tarafını sordu",
                )


if __name__ == "__main__":
    unittest.main()
