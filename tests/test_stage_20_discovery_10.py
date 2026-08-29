import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.legacy_bowl_updates import (
    BOWL_STIR_STONE_BY_POSITION,
    LegacyBowlUpdateAdapter,
    legacyInPlaceBowlUpdateWrong,
)
from pastafari_calendar.legacy_hidden import LegacyHiddenDropAdapter
from pastafari_calendar.legacy_permutation import LegacyPermutationOrderAdapter
from pastafari_calendar.legacy_pours import LegacyPourAdapter
from pastafari_calendar.legacy_stones import LegacyStoneBuilderAdapter
from pastafari_calendar.legacy_visible_grinds import LegacyVisibleDropBuilderAdapter
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from normative_reference import (
    FOUNDATION_DAY,
    STONES,
    save,
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

    LegacyPourAdapter().call(
        ctx,
        1,
    )

    return ctx


def _normative_one_drop_update(
    i: int,
    drop: int,
    order: tuple[int, ...],
    pours: tuple[int, ...],
    bowls: tuple[int, ...],
) -> tuple[int, ...]:
    old = bowls
    next_bowls = [0] * 7

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

        next_bowls[bowl_id] = save(
            s * s
            + 5 * old[prev_id] * old[next_id]
            + i * position
        )

    return tuple(next_bowls)


class Stage20Discovery10Tests(unittest.TestCase):
    def test_in_place_bowl_update_is_on_the_real_calendar_path(self):
        with patch(
            "pastafari_calendar.legacy_bowl_updates.legacyInPlaceBowlUpdateWrong",
            wraps=legacyInPlaceBowlUpdateWrong,
        ) as wrong_update:
            with patch(
                "pastafari_calendar.final_integration.FinalSpaghettiIntegrationManager.execute",
                return_value=None,
            ):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY,
                )

            self.assertGreaterEqual(
                wrong_update.call_count,
                1,
            )
            self.assertEqual(
                wrong_update.call_args_list[0].args[0],
                1,
            )

    def test_legacy_helper_really_uses_updated_working_values_in_later_positions(self):
        ctx = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )

        i = 1
        bowls = ctx.legacy_initial_bowls
        pours = ctx.legacy_pour_last_values
        drop = ctx.legacy_visible_drop_table[i]
        order = ctx.legacy_permutation_order_table[i]

        actual = legacyInPlaceBowlUpdateWrong(
            i,
            drop,
            order,
            pours,
            ctx.legacy_stone_table,
            bowls,
        )

        # İlk position henüz contamination görmez; onun bowl'u normatif değerle aynıdır.
        expected = _normative_one_drop_update(
            i,
            drop,
            order,
            pours,
            bowls,
        )

        first_bowl_id = order[0]
        self.assertEqual(
            actual[first_bowl_id],
            expected[first_bowl_id],
        )

        # En az bir sonraki position, önceki yeni bowl değerini okuyarak ayrışmalıdır.
        later_ids = order[1:]
        self.assertTrue(
            any(
                actual[bowl_id] != expected[bowl_id]
                for bowl_id in later_ids
            )
        )

    def test_legacy_update_state_is_owned_by_one_invocation(self):
        first = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        second = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )

        result = LegacyBowlUpdateAdapter().call(
            first,
            1,
            first.legacy_initial_bowls,
            first.legacy_pour_last_values,
        )

        self.assertEqual(
            first.legacy_bowl_update_last_drop_index,
            1,
        )
        self.assertEqual(
            first.legacy_bowl_update_last_input,
            first.legacy_initial_bowls,
        )
        self.assertEqual(
            first.legacy_bowl_update_last_result,
            result,
        )

        self.assertIsNone(
            second.legacy_bowl_update_last_drop_index,
        )
        self.assertIsNone(
            second.legacy_bowl_update_last_input,
        )
        self.assertIsNone(
            second.legacy_bowl_update_last_result,
        )

    def test_current_in_place_bowl_update_diverges_from_normative_snapshot_update(self):
        ctx = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )

        actual = LegacyBowlUpdateAdapter().call(
            ctx,
            1,
            ctx.legacy_initial_bowls,
            ctx.legacy_pour_last_values,
        )

        expected = _normative_one_drop_update(
            1,
            ctx.legacy_visible_drop_table[1],
            ctx.legacy_permutation_order_table[1],
            ctx.legacy_pour_last_values,
            ctx.legacy_initial_bowls,
        )

        for position in (2, 3, 6):
            with self.subTest(position=position):
                bowl_id = ctx.legacy_permutation_order_table[1][position - 1]
                self.assertEqual(
                    actual[bowl_id],
                    expected[bowl_id],
                    msg="Yerinde legacy bowl update sonraki position okumalarını önceki write ile kirletti",
                )


if __name__ == "__main__":
    unittest.main()
