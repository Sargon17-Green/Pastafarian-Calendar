import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.legacy_distance import (
    LegacyDistanceAdapter,
    oldDistance,
    patchedCounts,
)
from pastafari_calendar.monster_bootstrap import MonsterContext
from normative_reference import (
    FOUNDATION_DAY,
    work_counts,
)


class Stage07Patch03Tests(unittest.TestCase):
    def test_patched_counts_match_normative_distance_on_required_edges(self):
        cases = (
            (FOUNDATION_DAY, FOUNDATION_DAY),
            (FOUNDATION_DAY, FOUNDATION_DAY + 1),
            (FOUNDATION_DAY, FOUNDATION_DAY + 3),
            (FOUNDATION_DAY - 1, FOUNDATION_DAY),
            (FOUNDATION_DAY - 3, FOUNDATION_DAY + 3),
            (FOUNDATION_DAY + 9, FOUNDATION_DAY + 2),
            (FOUNDATION_DAY - 9, FOUNDATION_DAY - 2),
        )

        for calculation_day, target_day in cases:
            with self.subTest(
                calculation_day=calculation_day,
                target_day=target_day,
            ):
                self.assertEqual(
                    patchedCounts(
                        calculation_day,
                        target_day,
                    ),
                    work_counts(
                        calculation_day,
                        target_day,
                    ).distance,
                )

    def test_old_distance_remains_physically_wrong(self):
        self.assertEqual(
            oldDistance(
                FOUNDATION_DAY,
                FOUNDATION_DAY,
            ),
            0,
        )
        self.assertEqual(
            oldDistance(
                FOUNDATION_DAY,
                FOUNDATION_DAY + 3,
            ),
            6,
        )
        self.assertEqual(
            oldDistance(
                FOUNDATION_DAY - 3,
                FOUNDATION_DAY + 3,
            ),
            1,
        )

    def test_patch_really_calls_old_distance(self):
        with patch(
            "pastafari_calendar.legacy_distance.oldDistance",
            wraps=oldDistance,
        ) as legacy_call:
            self.assertEqual(
                patchedCounts(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                ),
                4,
            )
            self.assertEqual(
                legacy_call.call_count,
                1,
            )
            self.assertEqual(
                legacy_call.call_args.args,
                (
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                ),
            )

    def test_nonreplacement_branch_still_gets_final_plus_one(self):
        calculation_day = FOUNDATION_DAY - 1
        target_day = FOUNDATION_DAY

        legacy_capture = []
        result = patchedCounts(
            calculation_day,
            target_day,
            legacy_capture,
        )

        self.assertEqual(
            legacy_capture,
            [1],
        )
        self.assertEqual(
            abs(target_day - calculation_day),
            1,
        )
        self.assertEqual(
            result,
            2,
        )

    def test_adapter_keeps_raw_legacy_and_patched_distance_separate(self):
        calculation_day = FOUNDATION_DAY - 3
        target_day = FOUNDATION_DAY + 3

        first = MonsterContext(
            calculation_day,
            target_day,
        )
        second = MonsterContext(
            calculation_day,
            target_day,
        )

        actual = LegacyDistanceAdapter().call(
            first,
            calculation_day,
            target_day,
        )

        self.assertEqual(
            actual,
            7,
        )
        self.assertEqual(
            first.legacy_distance_value,
            1,
        )
        self.assertEqual(
            first.patch03_chronological_distance,
            6,
        )
        self.assertEqual(
            first.patch03_distance_value,
            7,
        )
        self.assertTrue(
            first.patch03_legacy_replaced
        )
        self.assertTrue(
            first.patch03_applied
        )

        self.assertIsNone(
            second.legacy_distance_value
        )
        self.assertIsNone(
            second.patch03_chronological_distance
        )
        self.assertIsNone(
            second.patch03_distance_value
        )
        self.assertFalse(
            second.patch03_legacy_replaced
        )
        self.assertFalse(
            second.patch03_applied
        )

    def test_adapter_marks_equal_legacy_branch_without_replacement(self):
        calculation_day = FOUNDATION_DAY - 1
        target_day = FOUNDATION_DAY

        ctx = MonsterContext(
            calculation_day,
            target_day,
        )

        actual = LegacyDistanceAdapter().call(
            ctx,
            calculation_day,
            target_day,
        )

        self.assertEqual(actual, 2)
        self.assertEqual(
            ctx.legacy_distance_value,
            1,
        )
        self.assertEqual(
            ctx.patch03_chronological_distance,
            1,
        )
        self.assertFalse(
            ctx.patch03_legacy_replaced
        )
        self.assertTrue(
            ctx.patch03_applied
        )

    def test_observability_state_cannot_change_distance_patch(self):
        calculation_day = FOUNDATION_DAY - 5
        target_day = FOUNDATION_DAY + 8

        plain = MonsterContext(
            calculation_day,
            target_day,
        )
        noisy = MonsterContext(
            calculation_day,
            target_day,
        )

        noisy.logs.extend(
            [
                ("önceden", 1),
                ("önceden", 2),
            ]
        )
        noisy.metrics["yalnızca-gözlem"] = 777
        noisy.diagnostics.append(
            (
                "tanı",
                calculation_day,
                target_day,
            )
        )

        adapter = LegacyDistanceAdapter()
        self.assertEqual(
            adapter.call(
                plain,
                calculation_day,
                target_day,
            ),
            adapter.call(
                noisy,
                calculation_day,
                target_day,
            ),
        )


if __name__ == "__main__":
    unittest.main()
