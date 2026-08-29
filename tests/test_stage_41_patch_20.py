import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.legacy_structure_sauce import (
    LegacyStructureSauceAdapter,
    LegacyStructureSelectorAdapter,
    StructureSaucePatchWrapper,
    oldStructureSauce,
    sauceWithCurrentScars,
)
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from normative_reference import FOUNDATION_DAY, sauce


class Stage41Patch20Tests(unittest.TestCase):
    def test_old_helper_runs_before_recompute_and_keeps_original_target(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        adapter = LegacyStructureSauceAdapter()
        year_first_day = FOUNDATION_DAY + 107

        with patch(
            "pastafari_calendar.legacy_structure_sauce.oldStructureSauce",
            wraps=oldStructureSauce,
        ) as old_call, patch(
            "pastafari_calendar.legacy_structure_sauce.sauceWithCurrentScars",
            wraps=sauceWithCurrentScars,
        ) as core_call:
            adapter.call(
                ctx,
                FOUNDATION_DAY,
                FOUNDATION_DAY + 3,
                year_first_day,
            )

        self.assertEqual(old_call.call_count, 1)
        self.assertEqual(
            old_call.call_args.args,
            (
                FOUNDATION_DAY,
                FOUNDATION_DAY + 3,
            ),
        )
        self.assertEqual(core_call.call_count, 2)
        self.assertEqual(
            core_call.call_args_list[0].args,
            (
                FOUNDATION_DAY,
                FOUNDATION_DAY + 3,
            ),
        )
        self.assertEqual(
            core_call.call_args_list[1].args,
            (
                FOUNDATION_DAY,
                year_first_day,
            ),
        )

    def test_old_result_is_ghost_and_selector_gets_year_first_day_result(self):
        calculation_day = FOUNDATION_DAY + 7
        original_target_day = FOUNDATION_DAY + 5
        year_first_day = FOUNDATION_DAY + 107
        ctx = MonsterContext(
            calculation_day,
            original_target_day,
        )

        actual = LegacyStructureSauceAdapter().call(
            ctx,
            calculation_day,
            original_target_day,
            year_first_day,
        )

        old_expected = sauce(
            calculation_day,
            original_target_day,
        )
        semantic_expected = sauce(
            calculation_day,
            year_first_day,
        )

        self.assertEqual(
            ctx.patch20_old_ghost_bowls,
            old_expected.bowls,
        )
        self.assertEqual(
            ctx.patch20_old_ghost_order_at_drop_46,
            old_expected.order_at_drop_46,
        )
        self.assertTrue(ctx.patch20_old_ghost_recorded)
        self.assertFalse(ctx.patch20_old_ghost_reached_selector)
        self.assertFalse(ctx.legacy_structure_old_used_by_selector)

        self.assertEqual(
            ctx.legacy_structure_selector_input_target_day,
            year_first_day,
        )
        self.assertEqual(
            ctx.patch20_semantic_bowls,
            semantic_expected.bowls,
        )
        self.assertEqual(
            ctx.patch20_semantic_order_at_drop_46,
            semantic_expected.order_at_drop_46,
        )
        self.assertEqual(
            actual,
            semantic_expected.bowls[2],
        )

    def test_equal_original_target_and_year_first_day_needs_no_second_recompute(self):
        calculation_day = FOUNDATION_DAY
        same_day = FOUNDATION_DAY + 3
        ctx = MonsterContext(
            calculation_day,
            same_day,
        )
        adapter = LegacyStructureSauceAdapter()

        with patch(
            "pastafari_calendar.legacy_structure_sauce.sauceWithCurrentScars",
            wraps=sauceWithCurrentScars,
        ) as core_call:
            actual = adapter.call(
                ctx,
                calculation_day,
                same_day,
                same_day,
            )

        self.assertEqual(core_call.call_count, 1)
        self.assertFalse(ctx.patch20_recompute_needed)
        self.assertFalse(ctx.patch20_authoritative_recomputed)
        self.assertEqual(
            ctx.legacy_structure_semantic_source,
            "original-target-equals-year-first-day",
        )
        self.assertEqual(
            ctx.legacy_structure_selector_input_target_day,
            same_day,
        )
        self.assertEqual(
            actual,
            sauce(
                calculation_day,
                same_day,
            ).bowls[2],
        )

    def test_patch_wrapper_recomputes_exact_year_first_day_sauce(self):
        calculation_day = FOUNDATION_DAY - 11
        original_target_day = FOUNDATION_DAY - 6
        year_first_day = FOUNDATION_DAY - 111
        old_result = sauceWithCurrentScars(
            calculation_day,
            original_target_day,
        )
        ctx = MonsterContext(
            calculation_day,
            original_target_day,
        )

        actual = StructureSaucePatchWrapper().repair(
            ctx,
            old_result,
            calculation_day,
            original_target_day,
            year_first_day,
        )
        expected = sauce(
            calculation_day,
            year_first_day,
        )

        self.assertEqual(actual.target_day, year_first_day)
        self.assertEqual(actual.bowls, expected.bowls)
        self.assertEqual(
            actual.order_at_drop_46,
            expected.order_at_drop_46,
        )

    def test_real_calendar_calls_old_helper_as_ghost_and_selector_sees_year_first_day(self):
        with patch(
            "pastafari_calendar.legacy_structure_sauce.oldStructureSauce",
            wraps=oldStructureSauce,
        ) as old_call, patch(
            "pastafari_calendar.legacy_structure_sauce.LegacyStructureSelectorAdapter.call",
            autospec=True,
            wraps=LegacyStructureSelectorAdapter.call,
        ) as selector_call:
            with self.assertRaises(StageNotIntegratedError):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                )

        self.assertEqual(old_call.call_count, 1)
        self.assertEqual(selector_call.call_count, 1)

        ctx = selector_call.call_args.args[1]
        semantic_result = selector_call.call_args.args[2]

        self.assertTrue(ctx.patch20_old_ghost_recorded)
        self.assertFalse(ctx.patch20_old_ghost_reached_selector)
        self.assertTrue(ctx.patch20_authoritative_recomputed)
        self.assertEqual(
            semantic_result.target_day,
            ctx.legacy_structure_year_first_day,
        )
        self.assertNotEqual(
            semantic_result.target_day,
            ctx.legacy_structure_original_target_day,
        )

    def test_patch_state_is_invocation_local(self):
        first = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        second = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )

        LegacyStructureSauceAdapter().call(
            first,
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
            FOUNDATION_DAY + 107,
        )

        self.assertTrue(first.patch20_applied)
        self.assertTrue(first.patch20_old_ghost_recorded)
        self.assertTrue(first.patch20_authoritative_recomputed)

        self.assertFalse(second.patch20_applied)
        self.assertFalse(second.patch20_old_ghost_recorded)
        self.assertFalse(second.patch20_authoritative_recomputed)
        self.assertIsNone(second.patch20_semantic_bowls)

    def test_observability_state_cannot_change_semantic_result(self):
        calculation_day = FOUNDATION_DAY + 7
        original_target_day = FOUNDATION_DAY + 5
        year_first_day = FOUNDATION_DAY + 107

        plain = MonsterContext(
            calculation_day,
            original_target_day,
        )
        noisy = MonsterContext(
            calculation_day,
            original_target_day,
        )
        noisy.logs.extend(
            [
                ("önceden", 1),
                ("önceden", 2),
            ]
        )
        noisy.metrics["yalnızca-gözlem"] = 20100
        noisy.diagnostics.append(("tanı", 41))

        plain_result = LegacyStructureSauceAdapter().call(
            plain,
            calculation_day,
            original_target_day,
            year_first_day,
        )
        noisy_result = LegacyStructureSauceAdapter().call(
            noisy,
            calculation_day,
            original_target_day,
            year_first_day,
        )

        self.assertEqual(plain_result, noisy_result)
        self.assertEqual(
            plain.patch20_semantic_bowls,
            noisy.patch20_semantic_bowls,
        )

    def test_stage40_witness_family_is_now_exact(self):
        cases = (
            (
                FOUNDATION_DAY,
                FOUNDATION_DAY + 3,
                FOUNDATION_DAY + 4901,
            ),
            (
                FOUNDATION_DAY + 7,
                FOUNDATION_DAY + 5,
                FOUNDATION_DAY + 107,
            ),
            (
                FOUNDATION_DAY - 11,
                FOUNDATION_DAY - 6,
                FOUNDATION_DAY - 111,
            ),
        )

        for calculation_day, original_target_day, year_first_day in cases:
            with self.subTest(
                calculation_day=calculation_day,
                original_target_day=original_target_day,
                year_first_day=year_first_day,
            ):
                actual = LegacyStructureSauceAdapter().call(
                    MonsterContext(
                        calculation_day,
                        original_target_day,
                    ),
                    calculation_day,
                    original_target_day,
                    year_first_day,
                )
                expected = sauce(
                    calculation_day,
                    year_first_day,
                ).bowls[2]
                self.assertEqual(actual, expected)


if __name__ == "__main__":
    unittest.main()
