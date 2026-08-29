import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.legacy_hidden import LegacyHiddenDropAdapter
from pastafari_calendar.legacy_permutation import LegacyPermutationOrderAdapter
from pastafari_calendar.legacy_pours import (
    BowlAliasPatchWrapper,
    LegacyPourAdapter,
    aliasedPositionPours,
    bowlByLegacyPosition,
    installOrderAliases,
    legacyFixedBowlPours,
)
from pastafari_calendar.legacy_stones import LegacyStoneBuilderAdapter
from pastafari_calendar.legacy_visible_grinds import (
    GRIND_TABLE_WITH_SENTINEL,
    LegacyVisibleDropBuilderAdapter,
)
from pastafari_calendar.monster_bootstrap import MonsterContext
from normative_reference import (
    BARLEY,
    FOUNDATION_DAY,
    SALT,
    STONES,
    WHEAT,
    bowl_order_from_drop,
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


def _expected_pours(
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


class Stage19Patch09Tests(unittest.TestCase):
    def test_alias_table_maps_every_position_to_current_order_bowl(self):
        order = (
            5,
            4,
            3,
            6,
            2,
            1,
        )

        alias = installOrderAliases(
            order,
        )

        self.assertEqual(
            alias,
            (
                0,
                5,
                4,
                3,
                6,
                2,
                1,
            ),
        )

    def test_all_corrected_bowl_reads_go_through_alias_helper(self):
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
        order = ctx.legacy_permutation_order_table[i]
        alias = installOrderAliases(
            order,
        )

        with patch(
            "pastafari_calendar.legacy_pours.bowlByLegacyPosition",
            wraps=bowlByLegacyPosition,
        ) as alias_read:
            actual = aliasedPositionPours(
                i,
                drop,
                ctx.legacy_stone_table,
                old_bowls,
                alias,
            )

        self.assertEqual(
            alias_read.call_count,
            3,
        )
        self.assertEqual(
            [call.args[2] for call in alias_read.call_args_list],
            [1, 2, 3],
        )
        self.assertEqual(
            actual,
            _expected_pours(
                i,
                drop,
                old_bowls,
            ),
        )

    def test_fixed_bowl_helper_remains_physically_wrong(self):
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

        self.assertNotEqual(
            legacyFixedBowlPours(
                i,
                drop,
                ctx.legacy_stone_table,
                old_bowls,
            ),
            _expected_pours(
                i,
                drop,
                old_bowls,
            ),
        )

    def test_wrapper_really_calls_legacy_fixed_scar_then_alias_correction(self):
        ctx = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        adapter = LegacyPourAdapter()

        with patch(
            "pastafari_calendar.legacy_pours.legacyFixedBowlPours",
            wraps=legacyFixedBowlPours,
        ) as legacy_call, patch(
            "pastafari_calendar.legacy_pours.installOrderAliases",
            wraps=installOrderAliases,
        ) as alias_install, patch(
            "pastafari_calendar.legacy_pours.aliasedPositionPours",
            wraps=aliasedPositionPours,
        ) as corrected_call:
            actual = adapter.call(
                ctx,
                1,
            )

        self.assertEqual(
            legacy_call.call_count,
            1,
        )
        self.assertEqual(
            alias_install.call_count,
            1,
        )
        self.assertEqual(
            corrected_call.call_count,
            1,
        )

        self.assertNotEqual(
            ctx.patch09_legacy_fixed_pours,
            ctx.patch09_corrected_pours,
        )
        self.assertEqual(
            actual,
            ctx.patch09_corrected_pours,
        )
        self.assertTrue(
            ctx.patch09_applied,
        )

    def test_all_46_isolated_pour_sets_match_normative_position_reads(self):
        ctx = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        adapter = LegacyPourAdapter()
        old_bowls = adapter.ensure_initial_bowls(
            ctx,
        )

        for i in range(1, 47):
            with self.subTest(i=i):
                self.assertEqual(
                    adapter.call(
                        ctx,
                        i,
                    ),
                    _expected_pours(
                        i,
                        ctx.legacy_visible_drop_table[i],
                        old_bowls,
                    ),
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

        result = LegacyPourAdapter().call(
            first,
            2,
        )

        self.assertEqual(
            first.patch09_drop_index,
            2,
        )
        self.assertIsNotNone(
            first.patch09_bowl_alias,
        )
        self.assertEqual(
            first.patch09_corrected_pours,
            result,
        )
        self.assertTrue(
            first.patch09_applied,
        )

        self.assertIsNone(
            second.patch09_drop_index,
        )
        self.assertIsNone(
            second.patch09_bowl_alias,
        )
        self.assertIsNone(
            second.patch09_legacy_fixed_pours,
        )
        self.assertIsNone(
            second.patch09_corrected_pours,
        )
        self.assertFalse(
            second.patch09_applied,
        )

    def test_stage15_sentinel_is_still_present(self):
        self.assertEqual(
            len(GRIND_TABLE_WITH_SENTINEL),
            12,
        )

    def test_observability_state_cannot_change_bowl_alias_patch(self):
        plain = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        noisy = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )

        noisy.logs.extend(
            [
                ("önceden", 1),
                ("önceden", 2),
            ]
        )
        noisy.metrics["yalnızca-gözlem"] = 9090
        noisy.diagnostics.append(
            ("tanı", 19)
        )

        adapter = LegacyPourAdapter()

        self.assertEqual(
            adapter.call(
                plain,
                3,
            ),
            adapter.call(
                noisy,
                3,
            ),
        )


if __name__ == "__main__":
    unittest.main()
