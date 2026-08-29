import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.legacy_hidden import LegacyHiddenDropAdapter
from pastafari_calendar.legacy_next_bowl import (
    LegacyNextBowlAdapter,
    latchedCircularSuccessor,
    oldNextBowlFixedName,
)
from pastafari_calendar.legacy_order_memory import LegacyOverwritableOrderMemoryAdapter
from pastafari_calendar.legacy_permutation import LegacyPermutationOrderAdapter
from pastafari_calendar.legacy_stones import LegacyStoneBuilderAdapter
from pastafari_calendar.legacy_visible_grinds import (
    GRIND_TABLE_WITH_SENTINEL,
    LegacyVisibleDropBuilderAdapter,
)
from pastafari_calendar.monster_bootstrap import MonsterContext
from normative_reference import FOUNDATION_DAY, work_counts


def _ready_context(
    calculation_day: int,
    target_day: int,
) -> MonsterContext:
    ctx = MonsterContext(
        calculation_day,
        target_day,
    )
    counts = work_counts(
        calculation_day,
        target_day,
    )
    ctx.patch02_action_day_tag_value = counts.action
    ctx.patch02_target_day_tag_value = counts.target
    ctx.patch03_distance_value = counts.distance
    LegacyStoneBuilderAdapter().call(ctx)
    LegacyHiddenDropAdapter().call(ctx)
    LegacyVisibleDropBuilderAdapter().call(ctx)
    LegacyPermutationOrderAdapter().build_order_table(
        ctx,
        ctx.legacy_visible_drop_table,
    )
    LegacyOverwritableOrderMemoryAdapter().run(
        ctx,
    )
    return ctx


def _expected_next(
    latch: tuple[int, ...],
    queried_id: int,
) -> int:
    position = latch.index(
        queried_id,
    )
    return latch[
        (position + 1) % 6
    ]


class Stage25Patch12Tests(unittest.TestCase):
    def test_old_fixed_id_helper_remains_physically_wrong(self):
        latch = (
            1,
            2,
            3,
            4,
            6,
            5,
        )

        self.assertNotEqual(
            oldNextBowlFixedName(4),
            _expected_next(
                latch,
                4,
            ),
        )

    def test_latched_circular_successor_matches_all_six_positions(self):
        latch = (
            1,
            2,
            3,
            4,
            6,
            5,
        )

        for queried_id in latch:
            with self.subTest(
                queried_id=queried_id,
            ):
                self.assertEqual(
                    latchedCircularSuccessor(
                        latch,
                        queried_id,
                    ),
                    _expected_next(
                        latch,
                        queried_id,
                    ),
                )

    def test_wrapper_really_calls_old_helper_diagnostic_then_corrects(self):
        ctx = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        adapter = LegacyNextBowlAdapter()

        with patch(
            "pastafari_calendar.legacy_next_bowl.oldNextBowlFixedName",
            wraps=oldNextBowlFixedName,
        ) as old_call, patch(
            "pastafari_calendar.legacy_next_bowl.latchedCircularSuccessor",
            wraps=latchedCircularSuccessor,
        ) as corrected_call:
            result = adapter.call(
                ctx,
                4,
            )

        self.assertEqual(
            old_call.call_count,
            1,
        )
        self.assertEqual(
            corrected_call.call_count,
            1,
        )
        self.assertEqual(
            ctx.patch12_legacy_diagnostic,
            5,
        )
        self.assertEqual(
            ctx.patch12_corrected_result,
            6,
        )
        self.assertEqual(
            result,
            6,
        )
        self.assertTrue(
            ctx.patch12_applied,
        )

    def test_all_six_adapter_queries_follow_latch_circular_order(self):
        ctx = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        adapter = LegacyNextBowlAdapter()

        for queried_id in ctx.orderAt46Latch:
            with self.subTest(
                queried_id=queried_id,
            ):
                self.assertEqual(
                    adapter.call(
                        ctx,
                        queried_id,
                    ),
                    _expected_next(
                        ctx.orderAt46Latch,
                        queried_id,
                    ),
                )

    def test_wraparound_uses_latch_position_not_numeric_id(self):
        ctx = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        adapter = LegacyNextBowlAdapter()

        last_id = ctx.orderAt46Latch[-1]
        first_id = ctx.orderAt46Latch[0]

        self.assertEqual(
            last_id,
            5,
        )
        self.assertEqual(
            first_id,
            1,
        )
        self.assertEqual(
            adapter.call(
                ctx,
                last_id,
            ),
            first_id,
        )
        self.assertNotEqual(
            oldNextBowlFixedName(
                last_id,
            ),
            first_id,
        )

    def test_patch_state_is_invocation_local(self):
        first = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        second = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )

        LegacyNextBowlAdapter().call(
            first,
            6,
        )

        self.assertEqual(
            first.patch12_queried_id,
            6,
        )
        self.assertIsNotNone(
            first.patch12_legacy_diagnostic,
        )
        self.assertIsNotNone(
            first.patch12_corrected_result,
        )
        self.assertTrue(
            first.patch12_applied,
        )

        self.assertIsNone(
            second.patch12_queried_id,
        )
        self.assertIsNone(
            second.patch12_legacy_diagnostic,
        )
        self.assertIsNone(
            second.patch12_corrected_result,
        )
        self.assertFalse(
            second.patch12_applied,
        )

    def test_missing_queried_id_is_rejected_by_corrected_path(self):
        with self.assertRaisesRegex(
            ValueError,
            "bulunamadı",
        ):
            latchedCircularSuccessor(
                (
                    1,
                    2,
                    3,
                    4,
                    5,
                    6,
                ),
                7,
            )

    def test_stage15_sentinel_is_still_present(self):
        self.assertEqual(
            len(GRIND_TABLE_WITH_SENTINEL),
            12,
        )

    def test_observability_state_cannot_change_corrected_next_bowl(self):
        plain = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        noisy = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )

        noisy.logs.extend(
            [
                ("önceden", 1),
                ("önceden", 2),
            ]
        )
        noisy.metrics["yalnızca-gözlem"] = 12100
        noisy.diagnostics.append(
            ("tanı", 25)
        )

        adapter = LegacyNextBowlAdapter()

        self.assertEqual(
            adapter.call(
                plain,
                4,
            ),
            adapter.call(
                noisy,
                4,
            ),
        )


if __name__ == "__main__":
    unittest.main()
