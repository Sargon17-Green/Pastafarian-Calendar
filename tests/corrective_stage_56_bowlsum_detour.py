"""Kanonik saved-sum post-stir düzeltmesi için hedefli regresyonlar.

Dosya adı, eski CI çağrıları bozulmasın diye tarihsel olarak korunmuştur. Eski
"Düzeltici Aşama 56 raw bowlSum" yorumu 2026-09-11 itibarıyla SUPERSEDED'dir.
"""

import random
import sys
import unittest
from pathlib import Path

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
from pastafari_calendar.post_stir_bowlsum_detour import rawSumMutantPostStir
from normative_reference import FOUNDATION_DAY, sauce


class CanonicalSavedSumPostStirTests(unittest.TestCase):
    @staticmethod
    def _independent_saved_sum_round(
        stir: int,
        bowls: tuple[int, ...],
    ) -> tuple[tuple[int, ...], tuple[int, ...], int]:
        old = tuple(bowls)
        raw_sum = sum(old[1:7])
        saved_sum = savePatch(raw_sum + 149 * stir)
        order = patchedOrderFromDrop(saved_sum)
        pending = [0] * 7

        for position in range(1, 7):
            bowl_id = order[position - 1]
            prev_id = order[(position - 2) % 6]
            next_id = order[position % 6]
            u = (
                old[bowl_id]
                + 3 * old[prev_id]
                + 5 * old[next_id]
                + saved_sum
                + stir
                + position * position
            )
            pending[bowl_id] = savePatch(
                u * u
                + 7 * old[prev_id] * old[next_id]
            )

        return tuple(pending), order, saved_sum

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

    def test_discriminator_kills_raw_sum_mutant(self):
        bowls = (0, 11, 13, 17, 19, 23, 29)
        stir = 1
        canonical, canonical_order, saved_sum = postStirRoundExact(stir, bowls)
        expected, expected_order, expected_saved = self._independent_saved_sum_round(
            stir,
            bowls,
        )
        mutant, mutant_order, raw_sum, mutant_saved = rawSumMutantPostStir(
            stir,
            bowls,
        )

        self.assertNotEqual(raw_sum, saved_sum)
        self.assertEqual(saved_sum, savePatch(raw_sum + 149 * stir))
        self.assertEqual(mutant_saved, saved_sum)
        self.assertEqual(mutant_order, canonical_order)
        self.assertEqual(expected_order, canonical_order)
        self.assertEqual(expected_saved, saved_sum)
        self.assertEqual(canonical, expected)
        self.assertNotEqual(canonical, mutant)

    def test_all_twelve_rounds_match_saved_sum_and_mutant_diverges(self):
        working = (
            0,
            123456789,
            987654321,
            314159265,
            271828182,
            161803398,
            141421356,
        )
        saw_mutant_divergence = False

        for stir in range(1, 13):
            actual, order, saved_sum = postStirRoundExact(stir, working)
            expected, expected_order, expected_saved = self._independent_saved_sum_round(
                stir,
                working,
            )
            mutant, mutant_order, _, mutant_saved = rawSumMutantPostStir(
                stir,
                working,
            )
            self.assertEqual(actual, expected)
            self.assertEqual(order, expected_order)
            self.assertEqual(saved_sum, expected_saved)
            self.assertEqual(mutant_order, order)
            self.assertEqual(mutant_saved, saved_sum)
            saw_mutant_divergence |= mutant != actual
            working = actual

        self.assertTrue(saw_mutant_divergence)

    def test_real_adapter_uses_canonical_round_even_if_historical_flag_is_true(self):
        first = self._prepared_context(FOUNDATION_DAY, FOUNDATION_DAY)
        second = self._prepared_context(FOUNDATION_DAY, FOUNDATION_DAY)
        first.corrective56_raw_bowlsum_enabled = False
        second.corrective56_raw_bowlsum_enabled = True

        first_result = LegacyOverwritableOrderMemoryAdapter().run(first)
        second_result = LegacyOverwritableOrderMemoryAdapter().run(second)

        self.assertEqual(first.legacy_bowls_after_46_drops, second.legacy_bowls_after_46_drops)
        self.assertEqual(first_result, second_result)
        self.assertEqual(first_result, first.legacy_post_stir_final_bowls)
        self.assertEqual(second_result, second.legacy_post_stir_final_bowls)
        self.assertEqual(second.corrective56_post_stir_applied_count, 0)
        self.assertFalse(second.corrective56_post_stir_applied)

    def test_authoritative_sauce_matches_canonical_reference(self):
        cases = (
            (FOUNDATION_DAY, FOUNDATION_DAY),
            (FOUNDATION_DAY, FOUNDATION_DAY + 1),
            (FOUNDATION_DAY, FOUNDATION_DAY - 1),
            (FOUNDATION_DAY - 11, FOUNDATION_DAY + 23),
        )
        for calculation_day, target_day in cases:
            with self.subTest(calculation_day=calculation_day, target_day=target_day):
                actual = sauceWithScars(calculation_day, target_day)
                expected = sauce(calculation_day, target_day)
                self.assertEqual(actual.bowls, expected.bowls)
                self.assertEqual(actual.order_at_drop_46, expected.order_at_drop_46)

    def test_current_structure_sauce_default_is_canonical(self):
        actual = sauceWithCurrentScars(FOUNDATION_DAY, FOUNDATION_DAY)
        expected = sauce(FOUNDATION_DAY, FOUNDATION_DAY)
        self.assertEqual(actual.bowls, expected.bowls)
        self.assertEqual(actual.order_at_drop_46, expected.order_at_drop_46)

    def test_seeded_sauce_corpus_matches_canonical_reference(self):
        rng = random.Random(560911)
        cases = [(FOUNDATION_DAY, FOUNDATION_DAY)]
        for _ in range(12):
            c = FOUNDATION_DAY + rng.randint(-2000, 2000)
            t = c + rng.randint(-2000, 2000)
            cases.append((c, t))

        for calculation_day, target_day in cases:
            with self.subTest(calculation_day=calculation_day, target_day=target_day):
                actual = sauceWithScars(calculation_day, target_day)
                expected = sauce(calculation_day, target_day)
                self.assertEqual(actual.bowls, expected.bowls)
                self.assertEqual(actual.order_at_drop_46, expected.order_at_drop_46)

    def test_raw_mutant_is_isolated_from_production_imports(self):
        production = ROOT / "src" / "pastafari_calendar"
        order_memory = (production / "legacy_order_memory.py").read_text(encoding="utf-8")
        mutant_module = (production / "post_stir_bowlsum_detour.py").read_text(encoding="utf-8")

        self.assertNotIn("post_stir_bowlsum_detour import", order_memory)
        self.assertNotIn("rawSumMutantPostStir(", order_memory)
        self.assertIn("+ saved_stir_sum", order_memory)
        self.assertIn("HISTORICAL — SUPERSEDED", mutant_module)
        self.assertIn("INTENTIONAL MUTANT", mutant_module)


if __name__ == "__main__":
    unittest.main()
