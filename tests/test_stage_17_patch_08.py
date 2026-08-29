import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.legacy_arithmetic import regularMod
from pastafari_calendar.legacy_hidden import LegacyHiddenDropAdapter
from pastafari_calendar.legacy_permutation import (
    LegacyPermutationOrderAdapter,
    legacyOrderFromDropWrong,
    oldPermutationUnrank0,
    patchedOrderFromDrop,
)
from pastafari_calendar.legacy_stones import LegacyStoneBuilderAdapter
from pastafari_calendar.legacy_visible_grinds import (
    GRIND_TABLE_WITH_SENTINEL,
    LegacyVisibleDropBuilderAdapter,
)
from pastafari_calendar.monster_bootstrap import MonsterContext
from normative_reference import (
    FOUNDATION_DAY,
    bowl_order_from_drop,
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

    return ctx


class Stage17Patch08Tests(unittest.TestCase):
    def test_required_chain_matches_normative_for_all_order_numbers(self):
        for one_based in range(1, 721):
            with self.subTest(one_based=one_based):
                drop_value = one_based
                self.assertEqual(
                    patchedOrderFromDrop(
                        drop_value,
                    ),
                    bowl_order_from_drop(
                        drop_value,
                    ),
                )

    def test_patch_chain_really_passes_one_based_minus_one_to_old_unrank(self):
        drop_value = 570
        expected_one_based = regularMod(
            drop_value - 1,
            720,
        ) + 1

        with patch(
            "pastafari_calendar.legacy_permutation.oldPermutationUnrank0",
            wraps=oldPermutationUnrank0,
        ) as legacy_unrank:
            actual = patchedOrderFromDrop(
                drop_value,
            )

        self.assertEqual(
            legacy_unrank.call_count,
            1,
        )
        self.assertEqual(
            legacy_unrank.call_args.args,
            (expected_one_based - 1,),
        )
        self.assertEqual(
            actual,
            bowl_order_from_drop(
                drop_value,
            ),
        )

    def test_wrong_caller_remains_physically_wrong(self):
        drop_value = 1

        self.assertNotEqual(
            legacyOrderFromDropWrong(
                drop_value,
            ),
            bowl_order_from_drop(
                drop_value,
            ),
        )

    def test_patch_wrapper_really_calls_wrong_caller_then_correct_chain(self):
        ctx = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        adapter = LegacyPermutationOrderAdapter()

        drop_value = ctx.legacy_visible_drop_table[1]

        with patch(
            "pastafari_calendar.legacy_permutation.legacyOrderFromDropWrong",
            wraps=legacyOrderFromDropWrong,
        ) as wrong_call, patch(
            "pastafari_calendar.legacy_permutation.patchedOrderFromDrop",
            wraps=patchedOrderFromDrop,
        ) as corrected_call:
            actual = adapter.order_from_drop(
                ctx,
                1,
                drop_value,
            )

        self.assertEqual(
            wrong_call.call_count,
            1,
        )
        self.assertEqual(
            corrected_call.call_count,
            1,
        )
        self.assertEqual(
            actual,
            bowl_order_from_drop(
                drop_value,
            ),
        )
        self.assertNotEqual(
            ctx.patch08_legacy_wrong_order,
            ctx.patch08_corrected_order,
        )
        self.assertTrue(
            ctx.patch08_applied,
        )

    def test_one_based_720_keeps_wrong_path_error_as_scar_but_corrects_successfully(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        adapter = LegacyPermutationOrderAdapter()

        actual = adapter.order_from_drop(
            ctx,
            1,
            720,
        )

        self.assertEqual(
            ctx.patch08_one_based,
            720,
        )
        self.assertEqual(
            ctx.patch08_legacy_rank0,
            719,
        )
        self.assertIsNone(
            ctx.patch08_legacy_wrong_order,
        )
        self.assertIsNotNone(
            ctx.patch08_legacy_wrong_error,
        )
        self.assertEqual(
            actual,
            bowl_order_from_drop(
                720,
            ),
        )

    def test_full_order_table_matches_normative_orders(self):
        ctx = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )

        actual = LegacyPermutationOrderAdapter().build_order_table(
            ctx,
            ctx.legacy_visible_drop_table,
        )

        for i in range(1, 47):
            with self.subTest(i=i):
                self.assertEqual(
                    actual[i],
                    bowl_order_from_drop(
                        ctx.legacy_visible_drop_table[i],
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

        adapter = LegacyPermutationOrderAdapter()
        value = adapter.order_from_drop(
            first,
            1,
            first.legacy_visible_drop_table[1],
        )

        self.assertEqual(
            first.patch08_corrected_order,
            value,
        )
        self.assertTrue(
            first.patch08_applied,
        )

        self.assertIsNone(
            second.patch08_drop_index,
        )
        self.assertIsNone(
            second.patch08_one_based,
        )
        self.assertIsNone(
            second.patch08_legacy_rank0,
        )
        self.assertIsNone(
            second.patch08_legacy_wrong_order,
        )
        self.assertIsNone(
            second.patch08_legacy_wrong_error,
        )
        self.assertIsNone(
            second.patch08_corrected_order,
        )
        self.assertFalse(
            second.patch08_applied,
        )

    def test_stage15_sentinel_is_still_present(self):
        self.assertEqual(
            len(GRIND_TABLE_WITH_SENTINEL),
            12,
        )

    def test_observability_state_cannot_change_permutation_patch(self):
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
        noisy.metrics["yalnızca-gözlem"] = 8080
        noisy.diagnostics.append(
            ("tanı", 17)
        )

        adapter = LegacyPermutationOrderAdapter()

        self.assertEqual(
            adapter.build_order_table(
                plain,
                plain.legacy_visible_drop_table,
            ),
            adapter.build_order_table(
                noisy,
                noisy.legacy_visible_drop_table,
            ),
        )


if __name__ == "__main__":
    unittest.main()
