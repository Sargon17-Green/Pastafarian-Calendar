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
from pastafari_calendar.legacy_permutation import LegacyPermutationOrderAdapter
from pastafari_calendar.legacy_pours import (
    LegacyPourAdapter,
    initialBowlsThroughOldFactory,
    legacyFixedBowlPours,
)
from pastafari_calendar.legacy_stones import LegacyStoneBuilderAdapter
from pastafari_calendar.legacy_visible_grinds import LegacyVisibleDropBuilderAdapter
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from normative_reference import (
    BARLEY,
    FOUNDATION_DAY,
    SALT,
    STONES,
    WHEAT,
    bowl_order_from_drop,
    initial_bowls,
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

    return ctx


def _normative_pours_for_old_bowls(
    i: int,
    drop: int,
    old_bowls: tuple[int, ...],
) -> tuple[int, ...]:
    order = bowl_order_from_drop(
        drop,
    )
    pour = [0] * 7

    pour[1] = save(
        drop * drop
        + STONES[i][WHEAT] * old_bowls[order[0]]
        + 3 * i
    )
    pour[2] = save(
        drop * drop
        + STONES[i][BARLEY] * old_bowls[order[1]]
        + 5 * i
    )
    pour[3] = save(
        drop * drop
        + STONES[i][SALT] * old_bowls[order[2]]
        + 7 * i
    )

    return tuple(pour)


class Stage18Discovery09Tests(unittest.TestCase):
    def test_initial_bowl_factory_matches_normative_initial_bowls(self):
        counts = work_counts(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )

        self.assertEqual(
            initialBowlsThroughOldFactory(
                counts,
            ),
            initial_bowls(
                counts,
            ),
        )

    def test_fixed_bowl_pour_is_on_the_real_calendar_path(self):
        with patch(
            "pastafari_calendar.legacy_pours.legacyFixedBowlPours",
            wraps=legacyFixedBowlPours,
        ) as legacy_pour:
            with self.assertRaises(StageNotIntegratedError):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY,
                )

            self.assertEqual(
                legacy_pour.call_count,
                1,
            )
            self.assertEqual(
                legacy_pour.call_args.args[0],
                1,
            )

    def test_legacy_helper_really_reads_fixed_bowls_one_two_three(self):
        ctx = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        adapter = LegacyPourAdapter()
        old_bowls = adapter.ensure_initial_bowls(
            ctx,
        )

        i = 1
        drop = ctx.legacy_visible_drop_table[i]
        actual = legacyFixedBowlPours(
            i,
            drop,
            ctx.legacy_stone_table,
            old_bowls,
        )

        expected_fixed = [0] * 7
        expected_fixed[1] = save(
            drop * drop
            + STONES[i][WHEAT] * old_bowls[1]
            + 3 * i
        )
        expected_fixed[2] = save(
            drop * drop
            + STONES[i][BARLEY] * old_bowls[2]
            + 5 * i
        )
        expected_fixed[3] = save(
            drop * drop
            + STONES[i][SALT] * old_bowls[3]
            + 7 * i
        )

        self.assertEqual(
            actual,
            tuple(expected_fixed),
        )

    def test_legacy_pour_state_is_owned_by_one_invocation(self):
        first = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        second = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )

        result = LegacyPourAdapter().call(
            first,
            1,
        )

        self.assertIsNotNone(
            first.legacy_initial_bowls,
        )
        self.assertEqual(
            first.legacy_pour_last_drop_index,
            1,
        )
        self.assertEqual(
            first.legacy_pour_last_values,
            result,
        )

        self.assertIsNone(
            second.legacy_initial_bowls,
        )
        self.assertIsNone(
            second.legacy_pour_last_drop_index,
        )
        self.assertIsNone(
            second.legacy_pour_last_values,
        )

    def test_current_fixed_bowl_pours_diverge_from_normative_position_reads(self):
        calculation_day = FOUNDATION_DAY
        target_day = FOUNDATION_DAY + 3
        ctx = _ready_context(
            calculation_day,
            target_day,
        )
        adapter = LegacyPourAdapter()
        old_bowls = adapter.ensure_initial_bowls(
            ctx,
        )

        for i in (1, 2, 3):
            with self.subTest(i=i):
                actual = adapter.call(
                    ctx,
                    i,
                )
                expected = _normative_pours_for_old_bowls(
                    i,
                    ctx.legacy_visible_drop_table[i],
                    old_bowls,
                )

                self.assertEqual(
                    actual,
                    expected,
                    msg="Legacy sabit bowl-ID pour yolu normatif order-position bowl okumasıyla uyuşmadı",
                )


if __name__ == "__main__":
    unittest.main()
