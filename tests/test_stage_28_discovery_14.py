import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.legacy_arithmetic import M_OLD
from pastafari_calendar.legacy_hidden import LegacyHiddenDropAdapter
from pastafari_calendar.legacy_order_memory import LegacyOverwritableOrderMemoryAdapter
from pastafari_calendar.legacy_permutation import LegacyPermutationOrderAdapter
from pastafari_calendar.legacy_selection import (
    LegacyShortOnlySelectionDispatcher,
    buildAnswerRingFromSauceState,
)
from pastafari_calendar.legacy_stones import LegacyStoneBuilderAdapter
from pastafari_calendar.legacy_visible_grinds import LegacyVisibleDropBuilderAdapter
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
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


class Stage28Discovery14Tests(unittest.TestCase):
    def test_short_only_general_dispatcher_is_on_the_real_calendar_path(self):
        with patch(
            "pastafari_calendar.legacy_selection.LegacyShortOnlySelectionDispatcher.call_with_ring",
            autospec=True,
            wraps=LegacyShortOnlySelectionDispatcher.call_with_ring,
        ) as dispatcher_call:
            with patch(
                "pastafari_calendar.final_integration.FinalSpaghettiIntegrationManager.execute",
                return_value=None,
            ):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                )

            self.assertEqual(
                dispatcher_call.call_count,
                1,
            )
            self.assertEqual(
                dispatcher_call.call_args.args[3],
                M_OLD + 1,
            )

    def test_legacy_dispatcher_keeps_unsupported_short_attempt_as_scar(self):
        ctx = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        ring = buildAnswerRingFromSauceState(
            ctx,
            1,
            21,
        )

        actual = LegacyShortOnlySelectionDispatcher().call_with_ring(
            ctx,
            ring,
            M_OLD + 1,
        )

        self.assertIsInstance(
            actual,
            int,
        )
        self.assertTrue(
            ctx.legacy_general_selection_used_short_path,
        )
        self.assertTrue(
            ctx.legacy_wide_selection_unsupported,
        )
        self.assertIsNotNone(
            ctx.legacy_wide_selection_error,
        )
        self.assertEqual(
            ctx.legacy_general_selection_result,
            actual,
        )
        self.assertTrue(
            ctx.patch14_used_wide_path,
        )

    def test_short_family_still_delegates_to_patched_short_path(self):
        ctx = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        ring = buildAnswerRingFromSauceState(
            ctx,
            1,
            21,
        )
        n = M_OLD

        actual = LegacyShortOnlySelectionDispatcher().call_with_ring(
            ctx,
            ring,
            n,
        )

        self.assertIsInstance(
            actual,
            int,
        )
        self.assertGreaterEqual(
            actual,
            1,
        )
        self.assertLessEqual(
            actual,
            n,
        )
        self.assertFalse(
            ctx.legacy_wide_selection_unsupported,
        )

    def test_current_short_only_dispatcher_diverges_from_normative_wide_selection(self):
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
        dispatcher = LegacyShortOnlySelectionDispatcher()

        for n in (
            M_OLD + 1,
            M_OLD * M_OLD,
            M_OLD * M_OLD * M_OLD,
        ):
            with self.subTest(
                n=n,
            ):
                actual = dispatcher.call_with_ring(
                    ctx,
                    ring,
                    n,
                )
                expected = choose_rank_wide(
                    normative_stream,
                    n,
                )

                self.assertEqual(
                    actual,
                    expected,
                    msg="Legacy short-only dispatcher N>M ailesi için normatif wide rank üretemedi",
                )


if __name__ == "__main__":
    unittest.main()
