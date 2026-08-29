import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.final_integration import sauceWithScars
from pastafari_calendar.legacy_arithmetic import savePatch
from pastafari_calendar.legacy_day_counts import LegacyDayTagAdapter
from pastafari_calendar.legacy_distance import LegacyDistanceAdapter
from pastafari_calendar.legacy_hidden import LegacyHiddenDropAdapter
from pastafari_calendar.legacy_order_memory import (
    LegacyOverwritableOrderMemoryAdapter,
    postStirRoundExact,
)
from pastafari_calendar.legacy_permutation import (
    LegacyPermutationOrderAdapter,
    patchedOrderFromDrop,
)
from pastafari_calendar.legacy_stones import LegacyStoneBuilderAdapter
from pastafari_calendar.legacy_structure_sauce import sauceWithCurrentScars
from pastafari_calendar.legacy_visible_grinds import LegacyVisibleDropBuilderAdapter
from pastafari_calendar.monster_bootstrap import MonsterContext
from pastafari_calendar.post_stir_bowlsum_detour import rawBowlSumPostStirDetour
from normative_reference import (
    FOUNDATION_DAY,
    post_stir12_corrective56,
    sauce,
    sauce_corrective56,
)


class CorrectiveStage56BowlSumDetourTests(unittest.TestCase):
    @staticmethod
    def _independent_raw_sum_round(
        stir: int,
        bowls: tuple[int, ...],
    ) -> tuple[int, ...]:
        old = tuple(bowls)
        raw_bowl_sum = sum(old[1:7])
        order_number = savePatch(raw_bowl_sum + 149 * stir)
        order = patchedOrderFromDrop(order_number)
        pending = [0] * 7

        for position in range(1, 7):
            bowl_id = order[position - 1]
            prev_id = order[(position - 2) % 6]
            next_id = order[position % 6]
            u = (
                old[bowl_id]
                + 3 * old[prev_id]
                + 5 * old[next_id]
                + raw_bowl_sum
                + stir
                + position * position
            )
            pending[bowl_id] = savePatch(
                u * u
                + 7 * old[prev_id] * old[next_id]
            )

        return tuple(pending)

    @staticmethod
    def _prepared_context(calculation_day: int, target_day: int) -> MonsterContext:
        ctx = MonsterContext(
            calculation_day=calculation_day,
            target_day=target_day,
        )
        day_tags = LegacyDayTagAdapter()
        distance = LegacyDistanceAdapter()
        stones = LegacyStoneBuilderAdapter()
        hidden = LegacyHiddenDropAdapter()
        visible = LegacyVisibleDropBuilderAdapter()
        permutation = LegacyPermutationOrderAdapter()

        day_tags.call(ctx, calculation_day, "action")
        day_tags.call(ctx, target_day, "target")
        distance.call(ctx, calculation_day, target_day)
        stones.call(ctx)
        hidden.call(ctx)
        visible.call(ctx)

        if ctx.legacy_visible_drop_table is None:
            raise AssertionError("Görünür damla tablosu hazırlanamadı")

        permutation.build_order_table(
            ctx,
            ctx.legacy_visible_drop_table,
        )
        return ctx

    def test_old_a1_scar_still_diverges_from_raw_bowlsum_detour(self):
        bowls = (0, 11, 13, 17, 19, 23, 29)
        stir = 1
        legacy_wrong, legacy_order, legacy_saved = postStirRoundExact(
            stir,
            bowls,
        )
        corrected, corrected_order, raw_sum, order_number = rawBowlSumPostStirDetour(
            stir,
            bowls,
            legacy_wrong,
            legacy_order,
            legacy_saved,
        )

        self.assertEqual(raw_sum, sum(bowls[1:7]))
        self.assertEqual(order_number, savePatch(raw_sum + 149 * stir))
        self.assertEqual(corrected_order, legacy_order)
        self.assertNotEqual(raw_sum, order_number)
        self.assertNotEqual(legacy_wrong, corrected)
        self.assertEqual(
            corrected,
            self._independent_raw_sum_round(stir, bowls),
        )

    def test_twelve_corrective_rounds_match_local_formula_oracle(self):
        bowls = (
            0,
            123456789,
            987654321,
            314159265,
            271828182,
            161803398,
            141421356,
        )
        working = bowls

        for stir in range(1, 13):
            legacy_wrong, legacy_order, legacy_saved = postStirRoundExact(
                stir,
                working,
            )
            working, _, _, _ = rawBowlSumPostStirDetour(
                stir,
                working,
                legacy_wrong,
                legacy_order,
                legacy_saved,
            )

        self.assertEqual(
            working,
            post_stir12_corrective56(bowls),
        )

    def test_real_adapter_executes_old_scar_then_detour_twelve_times(self):
        ctx = self._prepared_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        ctx.corrective56_raw_bowlsum_enabled = True
        adapter = LegacyOverwritableOrderMemoryAdapter()

        with patch(
            "pastafari_calendar.legacy_order_memory.postStirRoundExact",
            wraps=postStirRoundExact,
        ) as legacy_mock, patch(
            "pastafari_calendar.legacy_order_memory.rawBowlSumPostStirDetour",
            wraps=rawBowlSumPostStirDetour,
        ) as detour_mock:
            result = adapter.run(ctx)

        self.assertEqual(legacy_mock.call_count, 12)
        self.assertEqual(detour_mock.call_count, 12)
        self.assertEqual(ctx.corrective56_post_stir_applied_count, 12)
        self.assertTrue(ctx.corrective56_post_stir_applied)
        self.assertEqual(ctx.corrective56_post_stir_last_stir, 12)
        self.assertEqual(result, ctx.legacy_post_stir_final_bowls)
        self.assertEqual(
            ctx.legacy_post_stir_last_saved_sum,
            ctx.corrective56_post_stir_last_order_number,
        )
        self.assertNotEqual(
            ctx.corrective56_post_stir_last_legacy_wrong_result,
            ctx.corrective56_post_stir_last_corrected_result,
        )
        self.assertEqual(
            sum(
                1
                for item in ctx.branch_trace
                if item[0] == "DÜZELTİCİ_56_HAM_BOWLSUM_DETOUR"
            ),
            12,
        )

    def test_legacy_formula_remains_physical_and_detour_formula_is_separate(self):
        legacy_source = (
            ROOT
            / "src"
            / "pastafari_calendar"
            / "legacy_order_memory.py"
        ).read_text(encoding="utf-8")
        detour_source = (
            ROOT
            / "src"
            / "pastafari_calendar"
            / "post_stir_bowlsum_detour.py"
        ).read_text(encoding="utf-8")

        self.assertIn("+ saved_stir_sum", legacy_source)
        self.assertIn("legacy_wrong_bowls, stir_order, saved_stir_sum = postStirRoundExact", legacy_source)
        self.assertIn("rawBowlSumPostStirDetour(", legacy_source)
        self.assertIn("raw_bowl_sum = sum(old[1:7])", detour_source)
        self.assertIn("+ raw_bowl_sum", detour_source)
        self.assertIn("order_number = savePatch(", detour_source)


    def test_authoritative_sauce_enables_detour_but_historical_default_stays_old(self):
        historical = sauceWithCurrentScars(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        authoritative = sauceWithScars(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        historical_oracle = sauce(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        corrective_oracle = sauce_corrective56(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

        self.assertEqual(historical.bowls, historical_oracle.bowls)
        self.assertEqual(
            historical.order_at_drop_46,
            historical_oracle.order_at_drop_46,
        )
        self.assertEqual(authoritative.bowls, corrective_oracle.bowls)
        self.assertEqual(
            authoritative.order_at_drop_46,
            corrective_oracle.order_at_drop_46,
        )
        self.assertNotEqual(historical.bowls, authoritative.bowls)

    def test_corrective_state_is_owned_per_context(self):
        first = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
        second = MonsterContext(FOUNDATION_DAY + 1, FOUNDATION_DAY + 1)

        first.corrective56_post_stir_applied = True
        first.corrective56_post_stir_applied_count = 12
        first.corrective56_post_stir_last_raw_bowl_sum = 777

        self.assertFalse(second.corrective56_post_stir_applied)
        self.assertEqual(second.corrective56_post_stir_applied_count, 0)
        self.assertIsNone(second.corrective56_post_stir_last_raw_bowl_sum)


if __name__ == "__main__":
    unittest.main()
