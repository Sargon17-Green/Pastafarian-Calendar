import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.legacy_bowl_updates import (
    BOWL_STIR_STONE_BY_POSITION,
    LegacyBowlUpdateAdapter,
    legacyInPlaceBowlUpdateWrong,
    snapshotBowlUpdatePatched,
)
from pastafari_calendar.legacy_hidden import LegacyHiddenDropAdapter
from pastafari_calendar.legacy_permutation import LegacyPermutationOrderAdapter
from pastafari_calendar.legacy_pours import LegacyPourAdapter
from pastafari_calendar.legacy_stones import LegacyStoneBuilderAdapter
from pastafari_calendar.legacy_visible_grinds import (
    GRIND_TABLE_WITH_SENTINEL,
    LegacyVisibleDropBuilderAdapter,
)
from pastafari_calendar.monster_bootstrap import MonsterContext
from normative_reference import FOUNDATION_DAY, STONES, save, work_counts


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
    LegacyPourAdapter().call(ctx, 1)
    return ctx


def _expected_snapshot_update(i, drop, order, pours, bowls):
    old = bowls
    pending = [0] * 7
    for position in range(1, 7):
        bowl_id = order[position - 1]
        prev_id = order[(position - 2) % 6]
        next_id = order[position % 6]
        kind = BOWL_STIR_STONE_BY_POSITION[position - 1]
        s = (
            old[bowl_id]
            + 2 * old[prev_id]
            + 3 * old[next_id]
            + pours[position]
            + drop
            + STONES[i][kind]
        )
        pending[bowl_id] = save(
            s * s
            + 5 * old[prev_id] * old[next_id]
            + i * position
        )
    return tuple(pending)


class Stage21Patch10Tests(unittest.TestCase):
    def test_wrong_in_place_helper_remains_physically_wrong(self):
        ctx = _ready_context(FOUNDATION_DAY, FOUNDATION_DAY + 3)
        i = 1
        actual = legacyInPlaceBowlUpdateWrong(
            i,
            ctx.legacy_visible_drop_table[i],
            ctx.legacy_permutation_order_table[i],
            ctx.legacy_pour_last_values,
            ctx.legacy_stone_table,
            ctx.legacy_initial_bowls,
        )
        expected = _expected_snapshot_update(
            i,
            ctx.legacy_visible_drop_table[i],
            ctx.legacy_permutation_order_table[i],
            ctx.legacy_pour_last_values,
            ctx.legacy_initial_bowls,
        )
        self.assertNotEqual(actual, expected)

    def test_snapshot_patch_matches_normative_one_drop_result(self):
        ctx = _ready_context(FOUNDATION_DAY, FOUNDATION_DAY + 3)
        i = 1
        actual = snapshotBowlUpdatePatched(
            i,
            ctx.legacy_visible_drop_table[i],
            ctx.legacy_permutation_order_table[i],
            ctx.legacy_pour_last_values,
            ctx.legacy_stone_table,
            ctx.legacy_initial_bowls,
        )
        expected = _expected_snapshot_update(
            i,
            ctx.legacy_visible_drop_table[i],
            ctx.legacy_permutation_order_table[i],
            ctx.legacy_pour_last_values,
            ctx.legacy_initial_bowls,
        )
        self.assertEqual(actual, expected)

    def test_wrapper_really_calls_wrong_scar_then_snapshot_patch(self):
        ctx = _ready_context(FOUNDATION_DAY, FOUNDATION_DAY + 3)
        adapter = LegacyBowlUpdateAdapter()
        with patch(
            "pastafari_calendar.legacy_bowl_updates.legacyInPlaceBowlUpdateWrong",
            wraps=legacyInPlaceBowlUpdateWrong,
        ) as wrong_call, patch(
            "pastafari_calendar.legacy_bowl_updates.snapshotBowlUpdatePatched",
            wraps=snapshotBowlUpdatePatched,
        ) as corrected_call:
            actual = adapter.call(
                ctx,
                1,
                ctx.legacy_initial_bowls,
                ctx.legacy_pour_last_values,
            )
        self.assertEqual(wrong_call.call_count, 1)
        self.assertEqual(corrected_call.call_count, 1)
        self.assertNotEqual(ctx.patch10_legacy_wrong_result, ctx.patch10_corrected_result)
        self.assertEqual(actual, ctx.patch10_corrected_result)
        self.assertTrue(ctx.patch10_commit_after_six)
        self.assertTrue(ctx.patch10_applied)

    def test_vault_old_is_physical_clone_and_pending_is_committed_result(self):
        ctx = _ready_context(FOUNDATION_DAY, FOUNDATION_DAY + 3)
        original = ctx.legacy_initial_bowls
        result = LegacyBowlUpdateAdapter().call(
            ctx,
            1,
            original,
            ctx.legacy_pour_last_values,
        )
        self.assertEqual(ctx.patch10_vaultOld, original)
        self.assertIsNot(ctx.patch10_vaultOld, original)
        self.assertEqual(ctx.patch10_pending, result)
        self.assertEqual(ctx.patch10_corrected_result, result)
        self.assertEqual(original, ctx.legacy_initial_bowls)

    def test_snapshot_patch_commits_all_six_positions_as_one_batch(self):
        ctx = _ready_context(FOUNDATION_DAY, FOUNDATION_DAY + 3)
        result = LegacyBowlUpdateAdapter().call(
            ctx,
            1,
            ctx.legacy_initial_bowls,
            ctx.legacy_pour_last_values,
        )
        expected = _expected_snapshot_update(
            1,
            ctx.legacy_visible_drop_table[1],
            ctx.legacy_permutation_order_table[1],
            ctx.legacy_pour_last_values,
            ctx.legacy_initial_bowls,
        )
        for position in range(1, 7):
            with self.subTest(position=position):
                bowl_id = ctx.legacy_permutation_order_table[1][position - 1]
                self.assertEqual(result[bowl_id], expected[bowl_id])

    def test_patch_state_is_invocation_local(self):
        first = _ready_context(FOUNDATION_DAY, FOUNDATION_DAY + 3)
        second = _ready_context(FOUNDATION_DAY, FOUNDATION_DAY + 3)
        LegacyBowlUpdateAdapter().call(
            first,
            1,
            first.legacy_initial_bowls,
            first.legacy_pour_last_values,
        )
        self.assertEqual(first.patch10_drop_index, 1)
        self.assertIsNotNone(first.patch10_vaultOld)
        self.assertIsNotNone(first.patch10_pending)
        self.assertTrue(first.patch10_applied)
        self.assertIsNone(second.patch10_drop_index)
        self.assertIsNone(second.patch10_vaultOld)
        self.assertIsNone(second.patch10_pending)
        self.assertIsNone(second.patch10_legacy_wrong_result)
        self.assertIsNone(second.patch10_corrected_result)
        self.assertFalse(second.patch10_commit_after_six)
        self.assertFalse(second.patch10_applied)

    def test_stage15_sentinel_is_still_present(self):
        self.assertEqual(len(GRIND_TABLE_WITH_SENTINEL), 12)

    def test_observability_state_cannot_change_snapshot_patch(self):
        plain = _ready_context(FOUNDATION_DAY, FOUNDATION_DAY + 3)
        noisy = _ready_context(FOUNDATION_DAY, FOUNDATION_DAY + 3)
        noisy.logs.extend([("önceden", 1), ("önceden", 2)])
        noisy.metrics["yalnızca-gözlem"] = 10100
        noisy.diagnostics.append(("tanı", 21))
        adapter = LegacyBowlUpdateAdapter()
        self.assertEqual(
            adapter.call(plain, 1, plain.legacy_initial_bowls, plain.legacy_pour_last_values),
            adapter.call(noisy, 1, noisy.legacy_initial_bowls, noisy.legacy_pour_last_values),
        )


if __name__ == "__main__":
    unittest.main()
