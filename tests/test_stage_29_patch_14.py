import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.legacy_arithmetic import M_OLD
from pastafari_calendar.legacy_hidden import LegacyHiddenDropAdapter
from pastafari_calendar.legacy_order_memory import LegacyOverwritableOrderMemoryAdapter
from pastafari_calendar.legacy_permutation import LegacyPermutationOrderAdapter
from pastafari_calendar.legacy_selection import (
    LegacyAnswerRing,
    LegacyBiasedSelectionAdapter,
    LegacyShortOnlySelectionDispatcher,
    answerAtRing,
    buildAnswerRingFromSauceState,
    wideDetour,
)
from pastafari_calendar.legacy_stones import LegacyStoneBuilderAdapter
from pastafari_calendar.legacy_visible_grinds import (
    GRIND_TABLE_WITH_SENTINEL,
    LegacyVisibleDropBuilderAdapter,
)
from pastafari_calendar.monster_bootstrap import MonsterContext
from normative_reference import (
    FOUNDATION_DAY,
    ask_bowl,
    choose_rank_wide,
    sauce,
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
    LegacyOverwritableOrderMemoryAdapter().run(
        ctx,
    )
    return ctx


class Stage29Patch14Tests(unittest.TestCase):
    def test_short_path_still_uses_stage27_selection(self):
        ctx = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        ring = buildAnswerRingFromSauceState(
            ctx,
            1,
            21,
        )
        dispatcher = LegacyShortOnlySelectionDispatcher()

        with patch.object(
            dispatcher.short_adapter,
            "call_with_ring",
            wraps=dispatcher.short_adapter.call_with_ring,
        ) as short_call, patch(
            "pastafari_calendar.legacy_selection.wideDetour",
            wraps=wideDetour,
        ) as wide_call:
            actual = dispatcher.call_with_ring(
                ctx,
                ring,
                M_OLD,
            )

        self.assertEqual(
            short_call.call_count,
            1,
        )
        self.assertEqual(
            wide_call.call_count,
            0,
        )
        self.assertFalse(
            ctx.patch14_used_wide_path,
        )
        self.assertGreaterEqual(
            actual,
            1,
        )
        self.assertLessEqual(
            actual,
            M_OLD,
        )

    def test_wide_path_really_hits_old_short_scar_then_detours(self):
        ctx = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        ring = buildAnswerRingFromSauceState(
            ctx,
            1,
            21,
        )
        dispatcher = LegacyShortOnlySelectionDispatcher()

        with patch.object(
            dispatcher.short_adapter,
            "call_with_ring",
            wraps=dispatcher.short_adapter.call_with_ring,
        ) as short_call, patch(
            "pastafari_calendar.legacy_selection.wideDetour",
            wraps=wideDetour,
        ) as wide_call:
            actual = dispatcher.call_with_ring(
                ctx,
                ring,
                M_OLD + 1,
            )

        self.assertEqual(
            short_call.call_count,
            1,
        )
        self.assertEqual(
            wide_call.call_count,
            1,
        )
        self.assertTrue(
            ctx.legacy_wide_selection_unsupported,
        )
        self.assertIsNotNone(
            ctx.legacy_wide_selection_error,
        )
        self.assertTrue(
            ctx.patch14_used_wide_path,
        )
        self.assertEqual(
            ctx.patch14_result,
            actual,
        )

    def test_wide_detour_matches_normative_for_real_sauce_streams(self):
        calculation_day = FOUNDATION_DAY
        target_day = FOUNDATION_DAY + 3
        ctx = _ready_context(
            calculation_day,
            target_day,
        )
        ring = buildAnswerRingFromSauceState(
            ctx,
            1,
            21,
        )
        normative_stream = ask_bowl(
            sauce(
                calculation_day,
                target_day,
            ),
            1,
            21,
        )

        for n in (
            M_OLD + 1,
            M_OLD * M_OLD,
            M_OLD * M_OLD * M_OLD,
        ):
            with self.subTest(
                n=n,
            ):
                self.assertEqual(
                    wideDetour(
                        ctx,
                        ring,
                        n,
                    ),
                    choose_rank_wide(
                        normative_stream,
                        n,
                    ),
                )

    def test_places_are_minimal_for_wide_space(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        ring = LegacyAnswerRing(
            first=1,
            direction_step=1,
        )

        cases = (
            (
                M_OLD + 1,
                2,
                M_OLD * M_OLD,
            ),
            (
                M_OLD * M_OLD,
                2,
                M_OLD * M_OLD,
            ),
            (
                M_OLD * M_OLD + 1,
                3,
                M_OLD * M_OLD * M_OLD,
            ),
        )

        for n, expected_places, expected_space in cases:
            with self.subTest(
                n=n,
            ):
                wideDetour(
                    ctx,
                    ring,
                    n,
                )
                self.assertEqual(
                    ctx.patch14_places,
                    expected_places,
                )
                self.assertEqual(
                    ctx.patch14_space,
                    expected_space,
                )

    def test_rejection_does_not_generate_new_digits_direction_minus_one(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        ring = LegacyAnswerRing(
            first=M_OLD,
            direction_step=-1,
        )

        initial_wide = (
            M_OLD * M_OLD
            - M_OLD
        )
        n = initial_wide - 1

        with patch(
            "pastafari_calendar.legacy_selection.answerAtRing",
            wraps=answerAtRing,
        ) as answer_call:
            actual = wideDetour(
                ctx,
                ring,
                n,
            )

        self.assertEqual(
            ctx.patch14_places,
            2,
        )
        self.assertEqual(
            answer_call.call_count,
            2,
        )
        self.assertEqual(
            ctx.patch14_initial_wide,
            initial_wide,
        )
        self.assertEqual(
            ctx.patch14_acceptance_limit,
            n,
        )
        self.assertEqual(
            ctx.patch14_rejection_count,
            1,
        )
        self.assertEqual(
            ctx.patch14_accepted_wide,
            initial_wide - 1,
        )
        self.assertEqual(
            actual,
            n,
        )

    def test_rejection_moves_wide_number_with_wrap_direction_plus_one(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        ring = LegacyAnswerRing(
            first=M_OLD - 1,
            direction_step=1,
        )

        initial_wide = (
            M_OLD * M_OLD
            - 1
        )
        n = initial_wide - 1

        with patch(
            "pastafari_calendar.legacy_selection.answerAtRing",
            wraps=answerAtRing,
        ) as answer_call:
            actual = wideDetour(
                ctx,
                ring,
                n,
            )

        self.assertEqual(
            ctx.patch14_places,
            2,
        )
        self.assertEqual(
            answer_call.call_count,
            2,
        )
        self.assertEqual(
            ctx.patch14_initial_wide,
            initial_wide,
        )
        self.assertEqual(
            ctx.patch14_rejection_count,
            2,
        )
        self.assertEqual(
            ctx.patch14_accepted_wide,
            1,
        )
        self.assertEqual(
            actual,
            1,
        )

    def test_digits_are_recorded_once_in_little_endian_base_m_order(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        ring = LegacyAnswerRing(
            first=7,
            direction_step=1,
        )
        n = M_OLD + 1

        wideDetour(
            ctx,
            ring,
            n,
        )

        self.assertEqual(
            ctx.patch14_places,
            2,
        )
        self.assertEqual(
            ctx.patch14_digits,
            (
                6,
                7,
            ),
        )
        self.assertEqual(
            ctx.patch14_initial_wide,
            1
            + 6
            + 7 * M_OLD,
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
        ring = buildAnswerRingFromSauceState(
            first,
            1,
            21,
        )

        LegacyShortOnlySelectionDispatcher().call_with_ring(
            first,
            ring,
            M_OLD + 1,
        )

        self.assertTrue(
            first.patch14_applied,
        )
        self.assertIsNotNone(
            first.patch14_places,
        )
        self.assertIsNotNone(
            first.patch14_digits,
        )
        self.assertIsNotNone(
            first.patch14_result,
        )

        self.assertFalse(
            second.patch14_applied,
        )
        self.assertIsNone(
            second.patch14_places,
        )
        self.assertIsNone(
            second.patch14_digits,
        )
        self.assertIsNone(
            second.patch14_result,
        )

    def test_stage15_sentinel_is_still_present(self):
        self.assertEqual(
            len(GRIND_TABLE_WITH_SENTINEL),
            12,
        )


if __name__ == "__main__":
    unittest.main()
