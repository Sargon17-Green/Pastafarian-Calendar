import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.legacy_arithmetic import M_OLD, regularMod
from pastafari_calendar.legacy_hidden import LegacyHiddenDropAdapter
from pastafari_calendar.legacy_order_memory import LegacyOverwritableOrderMemoryAdapter
from pastafari_calendar.legacy_permutation import LegacyPermutationOrderAdapter
from pastafari_calendar.legacy_selection import (
    LegacyBiasedSelectionAdapter,
    answerAtRing,
    biasedLegacyPick,
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


def _rejection_pick_test_only(
    ring,
    n: int,
) -> int:
    limit = (M_OLD // n) * n
    k = 0

    while True:
        x = answerAtRing(
            ring,
            k,
        )
        if x <= limit:
            return regularMod(
                x - 1,
                n,
            ) + 1
        k += 1


class Stage26Discovery13Tests(unittest.TestCase):
    def test_biased_pick_is_on_the_real_calendar_path_before_any_rejection(self):
        with patch(
            "pastafari_calendar.legacy_selection.biasedLegacyPick",
            wraps=biasedLegacyPick,
        ) as biased_call:
            with self.assertRaises(StageNotIntegratedError):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                )

            self.assertEqual(
                biased_call.call_count,
                1,
            )

    def test_answer_ring_from_production_state_matches_test_only_normative_stream(self):
        calculation_day = FOUNDATION_DAY
        target_day = FOUNDATION_DAY + 3
        ctx = _ready_context(
            calculation_day,
            target_day,
        )

        actual = buildAnswerRingFromSauceState(
            ctx,
            1,
            21,
        )
        expected = ask_bowl(
            sauce(
                calculation_day,
                target_day,
            ),
            1,
            21,
        )

        self.assertEqual(
            actual.first,
            expected.first,
        )
        self.assertEqual(
            actual.direction_step,
            expected.direction_step,
        )

    def test_old_helper_really_applies_direct_modulo(self):
        x = 101
        n = 10

        self.assertEqual(
            biasedLegacyPick(
                x,
                n,
            ),
            1,
        )

    def test_legacy_selection_state_is_owned_by_one_invocation(self):
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
        n = ring.first - 1

        result = LegacyBiasedSelectionAdapter().call_with_ring(
            first,
            ring,
            n,
        )

        self.assertEqual(
            first.legacy_selection_first_answer,
            ring.first,
        )
        self.assertEqual(
            first.legacy_selection_direction_step,
            ring.direction_step,
        )
        self.assertEqual(
            first.legacy_selection_n,
            n,
        )
        self.assertEqual(
            first.legacy_selection_result,
            result,
        )

        self.assertIsNone(
            second.legacy_selection_first_answer,
        )
        self.assertIsNone(
            second.legacy_selection_direction_step,
        )
        self.assertIsNone(
            second.legacy_selection_n,
        )
        self.assertIsNone(
            second.legacy_selection_result,
        )

    def test_current_biased_modulo_selection_diverges_from_rejection_selection(self):
        ctx = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        adapter = LegacyBiasedSelectionAdapter()

        for queried_id, seal in (
            (1, 21),
            (5, 21),
            (2, 31),
        ):
            with self.subTest(
                queried_id=queried_id,
                seal=seal,
            ):
                ring = buildAnswerRingFromSauceState(
                    ctx,
                    queried_id,
                    seal,
                )

                self.assertEqual(
                    ring.direction_step,
                    -1,
                )
                self.assertGreater(
                    ring.first,
                    M_OLD // 2,
                )

                n = ring.first - 1
                actual = adapter.call_with_ring(
                    ctx,
                    ring,
                    n,
                )
                expected = _rejection_pick_test_only(
                    ring,
                    n,
                )

                self.assertEqual(
                    actual,
                    expected,
                    msg="Legacy doğrudan modulo seçimi rejection uygulanmış aynı-answer-ring seçimiyle uyuşmadı",
                )


if __name__ == "__main__":
    unittest.main()
