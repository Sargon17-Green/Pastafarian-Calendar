import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.legacy_hidden import LegacyHiddenDropAdapter
from pastafari_calendar.legacy_order_memory import LegacyOverwritableOrderMemoryAdapter
from pastafari_calendar.legacy_permutation import LegacyPermutationOrderAdapter
from pastafari_calendar.legacy_stones import LegacyStoneBuilderAdapter
from pastafari_calendar.legacy_visible_grinds import GRIND_TABLE_WITH_SENTINEL, LegacyVisibleDropBuilderAdapter
from pastafari_calendar.monster_bootstrap import MonsterContext
from normative_reference import FOUNDATION_DAY, work_counts


def _ready_context(calculation_day: int, target_day: int) -> MonsterContext:
    ctx = MonsterContext(calculation_day, target_day)
    counts = work_counts(calculation_day, target_day)
    ctx.patch02_action_day_tag_value = counts.action
    ctx.patch02_target_day_tag_value = counts.target
    ctx.patch03_distance_value = counts.distance
    LegacyStoneBuilderAdapter().call(ctx)
    LegacyHiddenDropAdapter().call(ctx)
    LegacyVisibleDropBuilderAdapter().call(ctx)
    LegacyPermutationOrderAdapter().build_order_table(ctx, ctx.legacy_visible_drop_table)
    return ctx


class Stage23Patch11Tests(unittest.TestCase):
    def test_latch_equals_drop_46_order_and_is_a_physical_clone(self):
        ctx=_ready_context(FOUNDATION_DAY, FOUNDATION_DAY+3)
        expected=ctx.legacy_permutation_order_table[46]
        LegacyOverwritableOrderMemoryAdapter().run(ctx)
        self.assertEqual(ctx.orderAt46Latch, expected)
        self.assertIsNot(ctx.orderAt46Latch, expected)

    def test_latch_is_written_exactly_once_before_post_stirs(self):
        ctx=_ready_context(FOUNDATION_DAY, FOUNDATION_DAY+3)
        LegacyOverwritableOrderMemoryAdapter().run(ctx)
        self.assertEqual(ctx.patch11_latch_write_count,1)
        self.assertEqual(ctx.patch11_latch_source,("drop",46))
        self.assertTrue(ctx.patch11_applied)
        self.assertEqual(ctx.legacy_order_memory_last_source,("stir",12))

    def test_post_stirs_keep_overwriting_legacy_memory_but_never_latch(self):
        ctx=_ready_context(FOUNDATION_DAY, FOUNDATION_DAY+3)
        adapter=LegacyOverwritableOrderMemoryAdapter()
        adapter.run(ctx)
        expected=ctx.legacy_permutation_order_table[46]
        self.assertEqual(ctx.legacy_order_memory_write_count,58)
        self.assertNotEqual(ctx.legacy_overwritable_order_memory, expected)
        self.assertEqual(ctx.orderAt46Latch, expected)
        self.assertEqual(adapter.query_order(ctx), expected)

    def test_query_order_reads_latch_not_overwritable_memory(self):
        ctx=_ready_context(FOUNDATION_DAY, FOUNDATION_DAY+3)
        adapter=LegacyOverwritableOrderMemoryAdapter()
        adapter.run(ctx)
        ctx.legacy_overwritable_order_memory=(6,5,4,3,2,1)
        self.assertEqual(adapter.query_order(ctx),ctx.orderAt46Latch)
        self.assertNotEqual(adapter.query_order(ctx),ctx.legacy_overwritable_order_memory)

    def test_second_run_on_same_context_rejects_latch_rewrite(self):
        ctx=_ready_context(FOUNDATION_DAY, FOUNDATION_DAY+3)
        adapter=LegacyOverwritableOrderMemoryAdapter()
        adapter.run(ctx)
        with self.assertRaisesRegex(RuntimeError,"yalnızca bir kez"):
            adapter.run(ctx)
        self.assertEqual(ctx.patch11_latch_write_count,1)

    def test_patch_state_is_invocation_local(self):
        first=_ready_context(FOUNDATION_DAY, FOUNDATION_DAY+3)
        second=_ready_context(FOUNDATION_DAY, FOUNDATION_DAY+3)
        LegacyOverwritableOrderMemoryAdapter().run(first)
        self.assertIsNotNone(first.orderAt46Latch)
        self.assertEqual(first.patch11_latch_write_count,1)
        self.assertTrue(first.patch11_applied)
        self.assertIsNone(second.orderAt46Latch)
        self.assertEqual(second.patch11_latch_write_count,0)
        self.assertFalse(second.patch11_applied)

    def test_stage15_sentinel_is_still_present(self):
        self.assertEqual(len(GRIND_TABLE_WITH_SENTINEL),12)

    def test_observability_state_cannot_change_latched_order(self):
        plain=_ready_context(FOUNDATION_DAY, FOUNDATION_DAY+3)
        noisy=_ready_context(FOUNDATION_DAY, FOUNDATION_DAY+3)
        noisy.logs.extend([("önceden",1),("önceden",2)])
        noisy.metrics["yalnızca-gözlem"]=11100
        noisy.diagnostics.append(("tanı",23))
        adapter=LegacyOverwritableOrderMemoryAdapter()
        adapter.run(plain)
        adapter.run(noisy)
        self.assertEqual(adapter.query_order(plain),adapter.query_order(noisy))


if __name__ == "__main__":
    unittest.main()
