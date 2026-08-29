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
    oldStructureSauce,
    sauceWithCurrentScars,
)
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from normative_reference import (
    FOUNDATION_DAY,
    sauce,
)


class Stage40Discovery20Tests(unittest.TestCase):
    def test_old_structure_sauce_is_on_real_calendar_path_and_reaches_selector(self):
        with patch(
            "pastafari_calendar.legacy_structure_sauce.oldStructureSauce",
            wraps=oldStructureSauce,
        ) as old_call, patch(
            "pastafari_calendar.legacy_structure_sauce.LegacyStructureSelectorAdapter.call",
            autospec=True,
            wraps=LegacyStructureSelectorAdapter.call,
        ) as selector_call:
            with patch(
                "pastafari_calendar.final_integration.FinalSpaghettiIntegrationManager.execute",
                return_value=None,
            ):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                )

            self.assertEqual(
                old_call.call_count,
                1,
            )
            self.assertEqual(
                old_call.call_args.args,
                (
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                ),
            )
            self.assertEqual(
                selector_call.call_count,
                1,
            )

            ctx = selector_call.call_args.args[1]
            sauce_result = selector_call.call_args.args[2]

            self.assertEqual(
                ctx.legacy_structure_original_target_day,
                FOUNDATION_DAY + 3,
            )
            self.assertNotEqual(
                ctx.legacy_structure_year_first_day,
                ctx.legacy_structure_original_target_day,
            )
            self.assertEqual(
                sauce_result.target_day,
                ctx.legacy_structure_year_first_day,
            )
            self.assertFalse(
                ctx.legacy_structure_old_used_by_selector,
            )
            self.assertTrue(
                ctx.legacy_structure_reused_existing_calendar_sauce,
            )
            self.assertEqual(
                ctx.legacy_structure_semantic_source,
                "year-first-day",
            )
            self.assertTrue(
                ctx.patch20_old_ghost_recorded,
            )
            self.assertFalse(
                ctx.patch20_old_ghost_reached_selector,
            )

    def test_current_line_structure_sauce_core_matches_test_only_reference(self):
        cases = (
            (
                FOUNDATION_DAY,
                FOUNDATION_DAY + 3,
            ),
            (
                FOUNDATION_DAY + 7,
                FOUNDATION_DAY - 2,
            ),
            (
                FOUNDATION_DAY - 11,
                FOUNDATION_DAY + 9,
            ),
        )

        for calculation_day, target_day in cases:
            with self.subTest(
                calculation_day=calculation_day,
                target_day=target_day,
            ):
                actual = sauceWithCurrentScars(
                    calculation_day,
                    target_day,
                )
                expected = sauce(
                    calculation_day,
                    target_day,
                )

                self.assertEqual(
                    actual.bowls,
                    expected.bowls,
                )
                self.assertEqual(
                    actual.order_at_drop_46,
                    expected.order_at_drop_46,
                )

    def test_old_helper_uses_original_target_not_year_first_day(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        adapter = LegacyStructureSauceAdapter()
        year_first_day = (
            FOUNDATION_DAY
            + 4901
        )

        with patch(
            "pastafari_calendar.legacy_structure_sauce.sauceWithCurrentScars",
            wraps=sauceWithCurrentScars,
        ) as core_call:
            adapter.call(
                ctx,
                FOUNDATION_DAY,
                FOUNDATION_DAY + 3,
                year_first_day,
            )

        self.assertEqual(
            core_call.call_count,
            2,
        )
        self.assertEqual(
            core_call.call_args_list[0].args,
            (
                FOUNDATION_DAY,
                FOUNDATION_DAY + 3,
            ),
        )
        self.assertNotEqual(
            core_call.call_args_list[0].args[1],
            year_first_day,
        )
        self.assertEqual(
            core_call.call_args_list[1].args,
            (
                FOUNDATION_DAY,
                year_first_day,
            ),
        )
        self.assertEqual(
            ctx.patch20_old_ghost_target_day,
            FOUNDATION_DAY + 3,
        )
        self.assertEqual(
            ctx.legacy_structure_selector_input_target_day,
            year_first_day,
        )

    def test_structure_sauce_state_is_invocation_local(self):
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
            FOUNDATION_DAY + 4901,
        )

        self.assertEqual(
            first.legacy_structure_calls,
            1,
        )
        self.assertFalse(
            first.legacy_structure_old_used_by_selector,
        )
        self.assertTrue(
            first.patch20_old_ghost_recorded,
        )
        self.assertIsNotNone(
            first.legacy_structure_selector_token,
        )

        self.assertEqual(
            second.legacy_structure_calls,
            0,
        )
        self.assertFalse(
            second.legacy_structure_old_used_by_selector,
        )
        self.assertIsNone(
            second.legacy_structure_selector_token,
        )

    def test_current_original_target_structure_sauce_diverges_from_year_first_day_selector_input(self):
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

                authoritative = sauce(
                    calculation_day,
                    year_first_day,
                )

                expected = authoritative.bowls[
                    2
                ]

                self.assertEqual(
                    actual,
                    expected,
                    msg="Structure selector original target sauce kullandığı için year.firstDay sauce selector inputundan ayrıştı",
                )


if __name__ == "__main__":
    unittest.main()
