import itertools
import sys
import unittest
from math import comb
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.legacy_cutlet_partition import (
    LegacyAllPositiveCutletPartitionFamily,
    LegacyCutletPartitionAdapter,
    buildCutletPartitionAnswerRing,
    legacyCompatibleCutletRank,
)
from pastafari_calendar.legacy_selection import LegacyAnswerRing
from pastafari_calendar.legacy_structure_sauce import LegacyStructureSauceAdapter
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from normative_reference import (
    FOUNDATION_DAY,
    AnswerStream,
    CutletPartitionFamily,
    ask_bowl,
    choose_rank,
    sauce,
)


class Stage42Discovery21Tests(unittest.TestCase):
    def test_legacy_family_contains_every_positive_composition_in_lexicographic_order(self):
        family = LegacyAllPositiveCutletPartitionFamily(
            7,
            3,
        )
        brute = [
            row
            for row in itertools.product(
                range(1, 8),
                repeat=3,
            )
            if sum(row) == 7
        ]

        self.assertEqual(
            family.count(),
            comb(6, 2),
        )
        self.assertEqual(
            [
                family.unrank1(rank)
                for rank in range(
                    1,
                    family.count() + 1,
                )
            ],
            brute,
        )

    def test_cutlet_rank_copy_matches_current_short_selection_semantics(self):
        rings = (
            LegacyAnswerRing(
                first=1,
                direction_step=1,
            ),
            LegacyAnswerRing(
                first=115396237916116191908255373965372069236,
                direction_step=-1,
            ),
            LegacyAnswerRing(
                first=49308796693978539220209909511811324956,
                direction_step=1,
            ),
        )
        family_sizes = (
            1,
            21,
            35,
            56,
            126,
        )

        for ring in rings:
            for family_count in family_sizes:
                with self.subTest(
                    ring=ring,
                    family_count=family_count,
                ):
                    actual = legacyCompatibleCutletRank(
                        ring,
                        family_count,
                    )
                    expected = choose_rank(
                        AnswerStream(
                            ring.first,
                            ring.direction_step,
                        ),
                        family_count,
                    )
                    self.assertEqual(
                        actual,
                        expected,
                    )

    def test_partition_uses_stage20_semantic_structure_sauce_bowl2_seal21(self):
        calculation_day = FOUNDATION_DAY + 7
        original_target_day = FOUNDATION_DAY + 5
        year_first_day = FOUNDATION_DAY + 107
        ctx = MonsterContext(
            calculation_day,
            original_target_day,
        )

        LegacyStructureSauceAdapter().call(
            ctx,
            calculation_day,
            original_target_day,
            year_first_day,
        )

        with patch(
            "pastafari_calendar.legacy_cutlet_partition.buildCutletPartitionAnswerRing",
            wraps=buildCutletPartitionAnswerRing,
        ) as ring_call:
            LegacyCutletPartitionAdapter().call(
                ctx,
                9,
                6,
                4,
            )

        self.assertEqual(
            ring_call.call_count,
            1,
        )
        self.assertEqual(
            ctx.patch20_semantic_target_day,
            year_first_day,
        )
        self.assertIsNotNone(
            ctx.legacy_cutlet_answer_first,
        )
        self.assertIn(
            ctx.legacy_cutlet_answer_direction_step,
            (-1, 1),
        )

    def test_gate_filterless_partition_is_on_real_calendar_path(self):
        with patch(
            "pastafari_calendar.legacy_cutlet_partition.LegacyCutletPartitionAdapter.call",
            autospec=True,
            wraps=LegacyCutletPartitionAdapter.call,
        ) as partition_call:
            with self.assertRaises(StageNotIntegratedError):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                )

        self.assertEqual(
            partition_call.call_count,
            1,
        )
        self.assertEqual(
            partition_call.call_args.args[2:],
            (
                9,
                6,
                4,
            ),
        )

        ctx = partition_call.call_args.args[1]
        selected = ctx.legacy_cutlet_selected_partition

        self.assertIsNotNone(
            selected,
        )
        self.assertTrue(
            ctx.legacy_cutlet_used_all_positive_family,
        )
        self.assertTrue(
            ctx.legacy_cutlet_internal_gate_was_ignored,
        )

        running = 0
        internal_boundary_hit = False

        for value in selected[:-1]:
            running += value
            if running == 4:
                internal_boundary_hit = True

        self.assertFalse(
            internal_boundary_hit,
        )

    def test_cutlet_partition_state_is_invocation_local(self):
        first = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        second = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )

        first.patch20_semantic_bowls = (
            0,
            1,
            2,
            3,
            4,
            5,
            6,
        )
        first.patch20_semantic_order_at_drop_46 = (
            1,
            2,
            3,
            4,
            5,
            6,
        )

        LegacyCutletPartitionAdapter().call(
            first,
            9,
            6,
            4,
        )

        self.assertEqual(
            first.legacy_cutlet_partition_calls,
            1,
        )
        self.assertIsNotNone(
            first.legacy_cutlet_selected_partition,
        )
        self.assertTrue(
            first.legacy_cutlet_internal_gate_was_ignored,
        )

        self.assertEqual(
            second.legacy_cutlet_partition_calls,
            0,
        )
        self.assertIsNone(
            second.legacy_cutlet_selected_partition,
        )
        self.assertFalse(
            second.legacy_cutlet_internal_gate_was_ignored,
        )

    def test_patch21_filter_code_is_not_present_in_production(self):
        production = (
            ROOT
            / "src"
            / "pastafari_calendar"
            / "legacy_cutlet_partition.py"
        ).read_text(
            encoding="utf-8"
        )

        forbidden = (
            "CutletPartitionGatePatchWrapper",
            "filteredLegacyFamily",
            "required_boundary",
            "prefix_sum",
            "patch21_applied",
        )

        for token in forbidden:
            self.assertNotIn(
                token,
                production,
            )

    def test_current_all_positive_cutlet_family_ignores_internal_gate_boundary(self):
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

                LegacyStructureSauceAdapter().call(
                    ctx,
                    calculation_day,
                    original_target_day,
                    year_first_day,
                )

                actual = LegacyCutletPartitionAdapter().call(
                    ctx,
                    9,
                    6,
                    4,
                )

                authoritative_sauce = sauce(
                    calculation_day,
                    year_first_day,
                )
                authoritative_family = CutletPartitionFamily(
                    9,
                    6,
                    4,
                )
                authoritative_rank = choose_rank(
                    ask_bowl(
                        authoritative_sauce,
                        2,
                        21,
                    ),
                    authoritative_family.count(),
                )
                expected = authoritative_family.unrank1(
                    authoritative_rank
                )

                self.assertEqual(
                    actual,
                    expected,
                    msg="Legacy cutlet partition ailesi internal calculation-day gate sınırını filtrelemediği için authoritative filtered family ile ayrıştı",
                )


if __name__ == "__main__":
    unittest.main()
