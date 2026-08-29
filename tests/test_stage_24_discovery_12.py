import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.legacy_hidden import LegacyHiddenDropAdapter
from pastafari_calendar.legacy_next_bowl import (
    LegacyNextBowlAdapter,
    oldNextBowlFixedName,
)
from pastafari_calendar.legacy_order_memory import LegacyOverwritableOrderMemoryAdapter
from pastafari_calendar.legacy_permutation import LegacyPermutationOrderAdapter
from pastafari_calendar.legacy_stones import LegacyStoneBuilderAdapter
from pastafari_calendar.legacy_visible_grinds import LegacyVisibleDropBuilderAdapter
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
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


def _normative_next_from_latch(
    latch: tuple[int, ...],
    queried_id: int,
) -> int:
    position = latch.index(
        queried_id,
    )
    return latch[
        (position + 1) % 6
    ]


class Stage24Discovery12Tests(unittest.TestCase):
    def test_fixed_id_next_bowl_is_on_the_real_calendar_path(self):
        with patch(
            "pastafari_calendar.legacy_next_bowl.oldNextBowlFixedName",
            wraps=oldNextBowlFixedName,
        ) as old_call:
            with self.assertRaises(StageNotIntegratedError):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                )

            self.assertEqual(
                old_call.call_count,
                1,
            )

    def test_old_helper_really_uses_numeric_fixed_id_ring(self):
        self.assertEqual(
            tuple(
                oldNextBowlFixedName(i)
                for i in range(1, 7)
            ),
            (
                2,
                3,
                4,
                5,
                6,
                1,
            ),
        )

    def test_legacy_next_bowl_state_is_owned_by_one_invocation(self):
        first = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        second = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )

        result = LegacyNextBowlAdapter().call(
            first,
            4,
        )

        self.assertEqual(
            first.legacy_next_bowl_queried_id,
            4,
        )
        self.assertEqual(
            first.legacy_next_bowl_fixed_result,
            result,
        )

        self.assertIsNone(
            second.legacy_next_bowl_queried_id,
        )
        self.assertIsNone(
            second.legacy_next_bowl_fixed_result,
        )

    def test_current_fixed_id_next_bowl_diverges_from_latched_circular_successor(self):
        ctx = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        adapter = LegacyNextBowlAdapter()

        self.assertEqual(
            ctx.orderAt46Latch,
            (
                1,
                2,
                3,
                4,
                6,
                5,
            ),
        )

        for queried_id in (
            4,
            5,
            6,
        ):
            with self.subTest(queried_id=queried_id):
                actual = adapter.call(
                    ctx,
                    queried_id,
                )
                expected = _normative_next_from_latch(
                    ctx.orderAt46Latch,
                    queried_id,
                )

                self.assertEqual(
                    actual,
                    expected,
                    msg="Legacy sabit ID halkası drop 46 latch içindeki circular successor ile uyuşmadı",
                )


if __name__ == "__main__":
    unittest.main()
