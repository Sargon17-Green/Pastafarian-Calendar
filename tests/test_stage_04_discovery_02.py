import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.legacy_day_counts import (
    FOUNDATION_DAY_OLD,
    LegacyDayTagAdapter,
    oldDayTag,
)
from pastafari_calendar.monster_bootstrap import MonsterContext, StageNotIntegratedError
from normative_reference import FOUNDATION_DAY, day_count


class Stage04Discovery02Tests(unittest.TestCase):
    def test_old_day_tag_is_on_the_real_calendar_path(self):
        calculation_day = FOUNDATION_DAY
        target_day = FOUNDATION_DAY + 1

        with patch(
            "pastafari_calendar.legacy_day_counts.oldDayTag",
            wraps=oldDayTag,
        ) as legacy_call:
            with patch(
                "pastafari_calendar.final_integration.FinalSpaghettiIntegrationManager.execute",
                return_value=None,
            ):
                calendar_date_spaghetti(calculation_day, target_day)

            self.assertGreaterEqual(legacy_call.call_count, 2)
            self.assertEqual(
                [call.args for call in legacy_call.call_args_list[:2]],
                [(calculation_day,), (target_day,)],
            )

    def test_legacy_helper_keeps_the_historical_day_tag_formula(self):
        self.assertEqual(FOUNDATION_DAY_OLD, FOUNDATION_DAY)
        self.assertEqual(oldDayTag(FOUNDATION_DAY), 0)
        self.assertEqual(oldDayTag(FOUNDATION_DAY + 1), 2)
        self.assertEqual(oldDayTag(FOUNDATION_DAY + 3), 6)
        self.assertEqual(oldDayTag(FOUNDATION_DAY - 1), 2)
        self.assertEqual(oldDayTag(FOUNDATION_DAY - 3), 6)

    def test_day_tag_adapter_keeps_legacy_state_owned_by_one_invocation(self):
        first = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY + 1)
        second = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY + 1)

        adapter = LegacyDayTagAdapter()
        self.assertEqual(adapter.call(first, FOUNDATION_DAY, "action"), 1)
        self.assertEqual(adapter.call(first, FOUNDATION_DAY + 1, "target"), 3)

        self.assertEqual(first.legacy_action_day_tag_input, FOUNDATION_DAY)
        self.assertEqual(first.legacy_action_day_tag_value, 0)
        self.assertEqual(first.legacy_target_day_tag_input, FOUNDATION_DAY + 1)
        self.assertEqual(first.legacy_target_day_tag_value, 2)

        self.assertIsNone(second.legacy_action_day_tag_input)
        self.assertIsNone(second.legacy_action_day_tag_value)
        self.assertIsNone(second.legacy_target_day_tag_input)
        self.assertIsNone(second.legacy_target_day_tag_value)

    def test_current_day_tag_path_diverges_from_normative_day_count(self):
        cases = (
            FOUNDATION_DAY - 3,
            FOUNDATION_DAY - 1,
            FOUNDATION_DAY,
            FOUNDATION_DAY + 1,
            FOUNDATION_DAY + 3,
        )

        for day in cases:
            with self.subTest(day=day):
                ctx = MonsterContext(day, day)
                actual = LegacyDayTagAdapter().call(ctx, day, "action")
                self.assertEqual(
                    actual,
                    day_count(day),
                    msg="Geçerli gün etiketi yolu normatif gün sayımıyla uyuşmadı",
                )


if __name__ == "__main__":
    unittest.main()
