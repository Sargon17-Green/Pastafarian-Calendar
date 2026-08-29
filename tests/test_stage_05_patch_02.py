import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.legacy_day_counts import (
    FOUNDATION_DAY_OLD,
    LegacyDayTagAdapter,
    dayTagWithFoundationScar,
    oldDayTag,
)
from pastafari_calendar.monster_bootstrap import MonsterContext
from normative_reference import FOUNDATION_DAY, day_count


class Stage05Patch02Tests(unittest.TestCase):
    def test_day_tag_patch_matches_normative_day_count_on_required_edges(self):
        cases = (
            FOUNDATION_DAY - 9,
            FOUNDATION_DAY - 3,
            FOUNDATION_DAY - 1,
            FOUNDATION_DAY,
            FOUNDATION_DAY + 1,
            FOUNDATION_DAY + 3,
            FOUNDATION_DAY + 9,
        )

        for day in cases:
            with self.subTest(day=day):
                self.assertEqual(
                    dayTagWithFoundationScar(day),
                    day_count(day),
                )

    def test_old_day_tag_remains_physically_wrong(self):
        self.assertEqual(oldDayTag(FOUNDATION_DAY), 0)
        self.assertEqual(oldDayTag(FOUNDATION_DAY + 1), 2)
        self.assertEqual(oldDayTag(FOUNDATION_DAY + 3), 6)

    def test_day_tag_patch_really_calls_old_day_tag(self):
        with patch(
            "pastafari_calendar.legacy_day_counts.oldDayTag",
            wraps=oldDayTag,
        ) as legacy_call:
            self.assertEqual(
                dayTagWithFoundationScar(FOUNDATION_DAY + 1),
                3,
            )
            self.assertEqual(legacy_call.call_count, 1)
            self.assertEqual(
                legacy_call.call_args.args,
                (FOUNDATION_DAY + 1,),
            )

    def test_second_foundation_guard_is_a_real_preserved_scar(self):
        with patch(
            "pastafari_calendar.legacy_day_counts.oldDayTag",
            return_value=9,
        ):
            self.assertEqual(
                dayTagWithFoundationScar(FOUNDATION_DAY),
                1,
            )

    def test_patch_state_and_legacy_state_are_both_invocation_local(self):
        first = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 1,
        )
        second = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 1,
        )

        adapter = LegacyDayTagAdapter()

        self.assertEqual(
            adapter.call(first, FOUNDATION_DAY, "action"),
            1,
        )
        self.assertEqual(
            adapter.call(first, FOUNDATION_DAY + 1, "target"),
            3,
        )

        self.assertEqual(
            first.legacy_action_day_tag_value,
            0,
        )
        self.assertEqual(
            first.patch02_action_day_tag_value,
            1,
        )
        self.assertTrue(first.patch02_action_applied)

        self.assertEqual(
            first.legacy_target_day_tag_value,
            2,
        )
        self.assertEqual(
            first.patch02_target_day_tag_value,
            3,
        )
        self.assertTrue(first.patch02_target_applied)
        self.assertTrue(first.patch02_foundation_guard_seen)

        self.assertIsNone(second.legacy_action_day_tag_value)
        self.assertIsNone(second.patch02_action_day_tag_value)
        self.assertFalse(second.patch02_action_applied)
        self.assertIsNone(second.legacy_target_day_tag_value)
        self.assertIsNone(second.patch02_target_day_tag_value)
        self.assertFalse(second.patch02_target_applied)
        self.assertFalse(second.patch02_foundation_guard_seen)

    def test_observability_state_cannot_change_the_day_tag_patch(self):
        plain = MonsterContext(
            FOUNDATION_DAY + 7,
            FOUNDATION_DAY + 7,
        )
        noisy = MonsterContext(
            FOUNDATION_DAY + 7,
            FOUNDATION_DAY + 7,
        )

        noisy.logs.extend(
            [
                ("önceden", 1),
                ("önceden", 2),
            ]
        )
        noisy.metrics["gözlem"] = 999
        noisy.diagnostics.append(
            ("yalnızca-gözlem", FOUNDATION_DAY + 7)
        )

        adapter = LegacyDayTagAdapter()
        self.assertEqual(
            adapter.call(plain, FOUNDATION_DAY + 7, "action"),
            adapter.call(noisy, FOUNDATION_DAY + 7, "action"),
        )


if __name__ == "__main__":
    unittest.main()
