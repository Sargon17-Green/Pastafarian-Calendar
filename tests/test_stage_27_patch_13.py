import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.legacy_arithmetic import M_OLD, regularMod
from pastafari_calendar.legacy_hidden import LegacyHiddenDropAdapter
from pastafari_calendar.legacy_order_memory import LegacyOverwritableOrderMemoryAdapter
from pastafari_calendar.legacy_permutation import LegacyPermutationOrderAdapter
from pastafari_calendar.legacy_selection import (
    LegacyAnswerRing,
    LegacyBiasedSelectionAdapter,
    SelectionRejectionPatchWrapper,
    answerAtRing,
    biasedLegacyPick,
    buildAnswerRingFromSauceState,
)
from pastafari_calendar.legacy_stones import LegacyStoneBuilderAdapter
from pastafari_calendar.legacy_visible_grinds import (
    GRIND_TABLE_WITH_SENTINEL,
    LegacyVisibleDropBuilderAdapter,
)
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
    LegacyOverwritableOrderMemoryAdapter().run(ctx)
    return ctx


def _expected_short_pick(ring: LegacyAnswerRing, n: int) -> tuple[int, int, int]:
    limit = (M_OLD // n) * n
    offset = 0
    while True:
        x = answerAtRing(ring, offset)
        if x <= limit:
            return regularMod(x - 1, n) + 1, offset, x
        offset += 1


class Stage27Patch13Tests(unittest.TestCase):
    def test_biased_legacy_pick_remains_physically_direct_modulo(self):
        self.assertEqual(biasedLegacyPick(101, 10), 1)

    def test_wrapper_calls_old_helper_only_with_accepted_answer(self):
        ctx = _ready_context(FOUNDATION_DAY, FOUNDATION_DAY + 3)
        ring = buildAnswerRingFromSauceState(ctx, 1, 21)
        n = ring.first - 1
        limit = (M_OLD // n) * n
        self.assertGreater(ring.first, limit)

        with patch(
            "pastafari_calendar.legacy_selection.biasedLegacyPick",
            wraps=biasedLegacyPick,
        ) as old_call:
            result = SelectionRejectionPatchWrapper().repair(ctx, ring, n)

        self.assertEqual(old_call.call_count, 1)
        accepted_x, accepted_n = old_call.call_args.args
        self.assertEqual(accepted_n, n)
        self.assertLessEqual(accepted_x, limit)
        self.assertEqual(accepted_x, answerAtRing(ring, 1))
        self.assertEqual(result, biasedLegacyPick(accepted_x, n))

    def test_rejection_walk_stays_on_same_answer_ring(self):
        ctx = _ready_context(FOUNDATION_DAY, FOUNDATION_DAY + 3)
        adapter = LegacyBiasedSelectionAdapter()

        for queried_id, seal in ((1, 21), (5, 21), (2, 31)):
            with self.subTest(queried_id=queried_id, seal=seal):
                ring = buildAnswerRingFromSauceState(ctx, queried_id, seal)
                n = ring.first - 1
                expected_result, expected_offset, expected_x = _expected_short_pick(ring, n)
                actual = adapter.call_with_ring(ctx, ring, n)
                self.assertEqual(actual, expected_result)
                self.assertEqual(ctx.patch13_accepted_offset, expected_offset)
                self.assertEqual(ctx.patch13_accepted_answer, expected_x)
                self.assertEqual(ctx.patch13_rejection_count, expected_offset)

    def test_equal_to_limit_is_accepted_without_extra_step(self):
        n = 17
        limit = (M_OLD // n) * n
        ring = LegacyAnswerRing(first=limit, direction_step=1)
        ctx = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
        result = SelectionRejectionPatchWrapper().repair(ctx, ring, n)
        self.assertEqual(ctx.patch13_accepted_offset, 0)
        self.assertEqual(ctx.patch13_accepted_answer, limit)
        self.assertEqual(result, biasedLegacyPick(limit, n))

    def test_n_one_and_n_m_need_no_rejection(self):
        for n in (1, M_OLD):
            with self.subTest(n=n):
                ring = LegacyAnswerRing(first=M_OLD, direction_step=-1)
                ctx = MonsterContext(FOUNDATION_DAY, FOUNDATION_DAY)
                actual = SelectionRejectionPatchWrapper().repair(ctx, ring, n)
                expected, offset, accepted = _expected_short_pick(ring, n)
                self.assertEqual(actual, expected)
                self.assertEqual(ctx.patch13_accepted_offset, offset)
                self.assertEqual(ctx.patch13_accepted_answer, accepted)

    def test_patch_state_is_invocation_local(self):
        first = _ready_context(FOUNDATION_DAY, FOUNDATION_DAY + 3)
        second = _ready_context(FOUNDATION_DAY, FOUNDATION_DAY + 3)
        ring = buildAnswerRingFromSauceState(first, 1, 21)
        n = ring.first - 1
        LegacyBiasedSelectionAdapter().call_with_ring(first, ring, n)

        self.assertIsNotNone(first.patch13_limit)
        self.assertIsNotNone(first.patch13_accepted_offset)
        self.assertIsNotNone(first.patch13_accepted_answer)
        self.assertTrue(first.patch13_applied)

        self.assertIsNone(second.patch13_limit)
        self.assertIsNone(second.patch13_accepted_offset)
        self.assertIsNone(second.patch13_accepted_answer)
        self.assertEqual(second.patch13_rejection_count, 0)
        self.assertIsNone(second.patch13_legacy_pick_result)
        self.assertFalse(second.patch13_applied)

    def test_stage15_sentinel_is_still_present(self):
        self.assertEqual(len(GRIND_TABLE_WITH_SENTINEL), 12)

    def test_observability_state_cannot_change_rejection_selection(self):
        plain = _ready_context(FOUNDATION_DAY, FOUNDATION_DAY + 3)
        noisy = _ready_context(FOUNDATION_DAY, FOUNDATION_DAY + 3)
        noisy.logs.extend([("önceden", 1), ("önceden", 2)])
        noisy.metrics["yalnızca-gözlem"] = 13100
        noisy.diagnostics.append(("tanı", 27))

        plain_ring = buildAnswerRingFromSauceState(plain, 1, 21)
        noisy_ring = buildAnswerRingFromSauceState(noisy, 1, 21)
        n = plain_ring.first - 1
        adapter = LegacyBiasedSelectionAdapter()

        self.assertEqual(
            adapter.call_with_ring(plain, plain_ring, n),
            adapter.call_with_ring(noisy, noisy_ring, n),
        )


if __name__ == "__main__":
    unittest.main()
