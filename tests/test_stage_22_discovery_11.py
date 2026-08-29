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
from pastafari_calendar.legacy_order_memory import (
    LegacyOverwritableOrderMemoryAdapter,
    postStirRoundExact,
)
from pastafari_calendar.legacy_permutation import LegacyPermutationOrderAdapter
from pastafari_calendar.legacy_stones import LegacyStoneBuilderAdapter
from pastafari_calendar.legacy_visible_grinds import LegacyVisibleDropBuilderAdapter
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from normative_reference import (
    FOUNDATION_DAY,
    apply_visible_drops_to_bowls,
    build_hidden_drops,
    build_visible_drops,
    initial_bowls,
    post_stir12,
    work_counts,
)


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
    return ctx


class Stage22Discovery11Tests(unittest.TestCase):
    def test_full_drop_and_post_stir_path_is_on_the_real_calendar_path(self):
        with patch(
            "pastafari_calendar.legacy_order_memory.postStirRoundExact",
            wraps=postStirRoundExact,
        ) as stir_call:
            with patch(
                "pastafari_calendar.final_integration.FinalSpaghettiIntegrationManager.execute",
                return_value=None,
            ):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY,
                )

            self.assertEqual(
                stir_call.call_count,
                12,
            )

    def test_full_46_drop_and_12_stir_bowls_are_normative(self):
        calculation_day = FOUNDATION_DAY
        target_day = FOUNDATION_DAY + 3
        ctx = _ready_context(
            calculation_day,
            target_day,
        )
        adapter = LegacyOverwritableOrderMemoryAdapter()

        actual_final = adapter.run(ctx)

        counts = work_counts(
            calculation_day,
            target_day,
        )
        hidden = build_hidden_drops(counts)
        visible = build_visible_drops(
            counts,
            hidden,
        )
        initial = initial_bowls(
            counts,
        )
        after_46, _ = apply_visible_drops_to_bowls(
            initial,
            visible,
        )
        expected_final = post_stir12(
            after_46,
        )

        self.assertEqual(
            ctx.legacy_bowls_after_46_drops,
            after_46,
        )
        self.assertEqual(
            actual_final,
            expected_final,
        )
        self.assertEqual(
            ctx.legacy_post_stir_final_bowls,
            expected_final,
        )

    def test_general_order_memory_is_still_overwritten_by_all_post_stirs(self):
        ctx = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        adapter = LegacyOverwritableOrderMemoryAdapter()
        adapter.run(ctx)

        expected_drop_46_order = ctx.legacy_permutation_order_table[46]

        self.assertEqual(
            ctx.legacy_order_memory_write_count,
            58,
        )
        self.assertEqual(
            ctx.legacy_order_memory_last_source,
            ("stir", 12),
        )
        self.assertNotEqual(
            ctx.legacy_overwritable_order_memory,
            expected_drop_46_order,
        )
        self.assertEqual(
            adapter.query_order(ctx),
            expected_drop_46_order,
        )

    def test_order_memory_state_is_owned_by_one_invocation(self):
        first = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        second = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        LegacyOverwritableOrderMemoryAdapter().run(
            first,
        )

        self.assertIsNotNone(
            first.legacy_overwritable_order_memory,
        )
        self.assertEqual(
            first.legacy_order_memory_write_count,
            58,
        )
        self.assertIsNotNone(
            first.legacy_post_stir_final_bowls,
        )
        self.assertIsNotNone(
            first.orderAt46Latch,
        )
        self.assertEqual(
            first.patch11_latch_write_count,
            1,
        )
        self.assertEqual(
            first.patch11_latch_source,
            ("drop", 46),
        )

        self.assertIsNone(
            second.legacy_overwritable_order_memory,
        )
        self.assertEqual(
            second.legacy_order_memory_write_count,
            0,
        )
        self.assertIsNone(
            second.legacy_post_stir_final_bowls,
        )
        self.assertIsNone(
            second.orderAt46Latch,
        )
        self.assertEqual(
            second.patch11_latch_write_count,
            0,
        )
        self.assertIsNone(
            second.patch11_latch_source,
        )
        self.assertFalse(
            second.patch11_applied,
        )

    def test_current_query_order_is_overwritten_instead_of_preserving_drop_46_order(self):
        ctx = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        adapter = LegacyOverwritableOrderMemoryAdapter()
        adapter.run(ctx)

        actual = adapter.query_order(
            ctx,
        )
        expected = ctx.legacy_permutation_order_table[46]

        for position in (1, 2, 6):
            with self.subTest(position=position):
                self.assertEqual(
                    actual[position - 1],
                    expected[position - 1],
                    msg="Eski sorgu order belleği post-stir sırasında drop 46 sırasını ezdi",
                )


if __name__ == "__main__":
    unittest.main()
