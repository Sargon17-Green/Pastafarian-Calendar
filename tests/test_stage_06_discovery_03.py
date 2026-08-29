import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.legacy_distance import (
    LegacyDistanceAdapter,
    oldDistance,
)
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from normative_reference import (
    FOUNDATION_DAY,
    work_counts,
)


class Stage06Discovery03Tests(unittest.TestCase):
    def test_old_distance_is_on_the_real_calendar_path(self):
        calculation_day = FOUNDATION_DAY - 1
        target_day = FOUNDATION_DAY + 3

        with patch(
            "pastafari_calendar.legacy_distance.oldDistance",
            wraps=oldDistance,
        ) as legacy_call:
            with self.assertRaises(StageNotIntegratedError):
                calendar_date_spaghetti(
                    calculation_day,
                    target_day,
                )

            self.assertEqual(legacy_call.call_count, 1)
            self.assertEqual(
                legacy_call.call_args.args,
                (calculation_day, target_day),
            )

    def test_legacy_helper_keeps_tag_difference_formula(self):
        self.assertEqual(
            oldDistance(FOUNDATION_DAY, FOUNDATION_DAY),
            0,
        )
        self.assertEqual(
            oldDistance(FOUNDATION_DAY, FOUNDATION_DAY + 1),
            2,
        )
        self.assertEqual(
            oldDistance(FOUNDATION_DAY, FOUNDATION_DAY + 3),
            6,
        )
        self.assertEqual(
            oldDistance(FOUNDATION_DAY - 1, FOUNDATION_DAY),
            1,
        )
        self.assertEqual(
            oldDistance(FOUNDATION_DAY - 3, FOUNDATION_DAY + 3),
            1,
        )

    def test_legacy_distance_state_is_owned_by_one_invocation(self):
        first = MonsterContext(
            FOUNDATION_DAY - 1,
            FOUNDATION_DAY + 3,
        )
        second = MonsterContext(
            FOUNDATION_DAY - 1,
            FOUNDATION_DAY + 3,
        )

        adapter = LegacyDistanceAdapter()
        actual = adapter.call(
            first,
            FOUNDATION_DAY - 1,
            FOUNDATION_DAY + 3,
        )

        self.assertEqual(
            actual,
            oldDistance(
                FOUNDATION_DAY - 1,
                FOUNDATION_DAY + 3,
            ),
        )
        self.assertEqual(
            first.legacy_distance_calculation_day,
            FOUNDATION_DAY - 1,
        )
        self.assertEqual(
            first.legacy_distance_target_day,
            FOUNDATION_DAY + 3,
        )
        self.assertEqual(
            first.legacy_distance_value,
            actual,
        )

        self.assertIsNone(
            second.legacy_distance_calculation_day
        )
        self.assertIsNone(
            second.legacy_distance_target_day
        )
        self.assertIsNone(
            second.legacy_distance_value
        )

    def test_current_distance_path_diverges_from_normative_distance(self):
        cases = (
            (FOUNDATION_DAY, FOUNDATION_DAY),
            (FOUNDATION_DAY, FOUNDATION_DAY + 1),
            (FOUNDATION_DAY, FOUNDATION_DAY + 3),
            (FOUNDATION_DAY - 1, FOUNDATION_DAY),
            (FOUNDATION_DAY - 3, FOUNDATION_DAY + 3),
        )

        for calculation_day, target_day in cases:
            with self.subTest(
                calculation_day=calculation_day,
                target_day=target_day,
            ):
                ctx = MonsterContext(
                    calculation_day,
                    target_day,
                )
                actual = LegacyDistanceAdapter().call(
                    ctx,
                    calculation_day,
                    target_day,
                )
                expected = work_counts(
                    calculation_day,
                    target_day,
                ).distance
                self.assertEqual(
                    actual,
                    expected,
                    msg="Geçerli eski mesafe yolu normatif mesafeyle uyuşmadı",
                )


if __name__ == "__main__":
    unittest.main()
