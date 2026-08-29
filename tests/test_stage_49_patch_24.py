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
from pastafari_calendar.legacy_month_weaving import (
    DPUnrankLegalWeaving,
    LegacyMonthWeavingAdapter,
    LegalMonthWeavingDP,
    MonthWeavingPatchWrapper,
    compatibleMonthWeavingRank,
    legacyChooseEachDaySeparately,
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
    MonthWeavingFamily,
    SEAL_MONTH_WEAVING,
    ask_bowl,
    choose_rank,
    sauce,
)


class Stage49Patch24Tests(unittest.TestCase):
    def test_legal_weaving_dp_count_matches_test_only_reference(self):
        cases = (
            (1,),
            (1, 1),
            (2, 1),
            (2, 2),
            (4, 4, 4),
            (2, 3, 1, 2),
        )

        for lengths in cases:
            with self.subTest(
                lengths=lengths,
            ):
                self.assertEqual(
                    LegalMonthWeavingDP(
                        lengths
                    ).count(),
                    MonthWeavingFamily(
                        lengths
                    ).count(),
                )

    def test_dp_unrank_legal_weaving_matches_test_only_reference(self):
        cases = (
            (
                (1,),
                (
                    1,
                ),
            ),
            (
                (2, 2),
                (
                    1,
                    2,
                ),
            ),
            (
                (4, 4, 4),
                (
                    1,
                    2,
                    10,
                    100,
                ),
            ),
            (
                (2, 3, 1, 2),
                (
                    1,
                    2,
                    5,
                ),
            ),
        )

        for lengths, ranks in cases:
            reference = MonthWeavingFamily(
                lengths
            )
            total = reference.count()

            for rank1 in ranks:
                if rank1 > total:
                    continue

                with self.subTest(
                    lengths=lengths,
                    rank1=rank1,
                ):
                    self.assertEqual(
                        DPUnrankLegalWeaving(
                            lengths,
                            rank1,
                        ),
                        reference.unrank1(
                            rank1
                        ),
                    )

    def test_compatible_weaving_rank_matches_current_short_and_wide_selection(self):
        rings = (
            LegacyAnswerRing(
                first=1,
                direction_step=1,
            ),
            LegacyAnswerRing(
                first=49308796693978539220209909511811324956,
                direction_step=1,
            ),
            LegacyAnswerRing(
                first=115396237916116191908255373965372069236,
                direction_step=-1,
            ),
        )
        family_counts = (
            1,
            17,
            123456,
            M_OLD,
            M_OLD + 1,
            M_OLD * M_OLD,
        )

        for ring in rings:
            for family_count in family_counts:
                with self.subTest(
                    ring=ring,
                    family_count=family_count,
                ):
                    self.assertEqual(
                        compatibleMonthWeavingRank(
                            ring,
                            family_count,
                        ),
                        choose_rank(
                            AnswerStream(
                                ring.first,
                                ring.direction_step,
                            ),
                            family_count,
                        ),
                    )

    def test_adapter_runs_day_by_day_ghost_before_patch_wrapper(self):
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
            "pastafari_calendar.legacy_month_weaving.legacyChooseEachDaySeparately",
            wraps=legacyChooseEachDaySeparately,
        ) as ghost_call, patch(
            "pastafari_calendar.legacy_month_weaving.MonthWeavingPatchWrapper.repair",
            autospec=True,
            wraps=MonthWeavingPatchWrapper.repair,
        ) as patch_call:
            actual = LegacyMonthWeavingAdapter().call(
                ctx,
                (
                    4,
                    4,
                    4,
                ),
            )

        self.assertEqual(
            ghost_call.call_count,
            1,
        )
        self.assertEqual(
            patch_call.call_count,
            1,
        )
        self.assertEqual(
            ctx.patch24_ghost,
            ctx.legacy_month_weaving_ghost,
        )
        self.assertEqual(
            actual,
            ctx.patch24_semantic_weaving,
        )

        ghost_position = next(
            index
            for index, entry in enumerate(
                ctx.branch_trace
            )
            if entry[
                0
            ] == "ESKİ_GÜN_GÜN_AY_SEÇİMİ"
        )
        patch_position = next(
            index
            for index, entry in enumerate(
                ctx.branch_trace
            )
            if entry[
                0
            ] == "YAMA_24_LEGAL_AY_ÖRGÜSÜ"
        )

        self.assertLess(
            ghost_position,
            patch_position,
        )

    def test_patch_returns_correct_when_ghost_differs(self):
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

        actual = LegacyMonthWeavingAdapter().call(
            ctx,
            (
                4,
                4,
                4,
            ),
        )

        stream = ask_bowl(
            sauce(
                calculation_day,
                year_first_day,
            ),
            4,
            SEAL_MONTH_WEAVING,
        )
        family = MonthWeavingFamily(
            (
                4,
                4,
                4,
            )
        )
        rank = choose_rank(
            stream,
            family.count(),
        )
        expected = family.unrank1(
            rank
        )

        self.assertFalse(
            ctx.patch24_ghost_equals_correct,
        )
        self.assertFalse(
            ctx.patch24_returned_ghost,
        )
        self.assertEqual(
            actual,
            expected,
        )
        self.assertEqual(
            ctx.patch24_correct_weaving,
            expected,
        )

    def test_patch_returns_same_ghost_object_when_ghost_is_already_correct(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        ring = LegacyAnswerRing(
            first=1,
            direction_step=1,
        )
        ghost = legacyChooseEachDaySeparately(
            (
                1,
            ),
            ring,
        )

        actual = MonthWeavingPatchWrapper().repair(
            ctx,
            (
                1,
            ),
            ring,
            ghost,
        )

        self.assertTrue(
            ctx.patch24_ghost_equals_correct,
        )
        self.assertTrue(
            ctx.patch24_returned_ghost,
        )
        self.assertIs(
            actual,
            ghost,
        )

    def test_wanted_rank_uses_same_ring_and_legal_family_count(self):
        ring = LegacyAnswerRing(
            first=115396237916116191908255373965372069236,
            direction_step=-1,
        )
        lengths = (
            4,
            4,
            4,
        )
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        ghost = legacyChooseEachDaySeparately(
            lengths,
            ring,
        )

        actual = MonthWeavingPatchWrapper().repair(
            ctx,
            lengths,
            ring,
            ghost,
        )

        reference = MonthWeavingFamily(
            lengths
        )
        expected_rank = choose_rank(
            AnswerStream(
                ring.first,
                ring.direction_step,
            ),
            reference.count(),
        )
        expected = reference.unrank1(
            expected_rank
        )

        self.assertEqual(
            ctx.patch24_legal_family_count,
            reference.count(),
        )
        self.assertEqual(
            ctx.patch24_wanted_rank,
            expected_rank,
        )
        self.assertEqual(
            actual,
            expected,
        )

    def test_real_calendar_path_keeps_wrong_ghost_but_semantic_weaving_is_legal(self):
        with patch(
            "pastafari_calendar.legacy_month_weaving.MonthWeavingPatchWrapper.repair",
            autospec=True,
            wraps=MonthWeavingPatchWrapper.repair,
        ) as repair_call:
            with self.assertRaises(
                StageNotIntegratedError
            ):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                )

        self.assertEqual(
            repair_call.call_count,
            1,
        )

        ctx = repair_call.call_args.args[
            1
        ]

        self.assertEqual(
            ctx.patch24_ghost,
            ctx.legacy_month_weaving_ghost,
        )
        self.assertNotEqual(
            ctx.legacy_month_weaving_ghost[
                0
            ],
            1,
        )
        self.assertEqual(
            ctx.patch24_semantic_weaving[
                0
            ],
            1,
        )
        self.assertEqual(
            ctx.legacy_month_weaving_semantic,
            ctx.patch24_semantic_weaving,
        )
        self.assertTrue(
            ctx.patch24_applied,
        )

    def test_patch_state_is_invocation_local(self):
        first = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        second = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        ring = LegacyAnswerRing(
            first=1,
            direction_step=1,
        )
        ghost = legacyChooseEachDaySeparately(
            (
                1,
            ),
            ring,
        )

        MonthWeavingPatchWrapper().repair(
            first,
            (
                1,
            ),
            ring,
            ghost,
        )

        self.assertTrue(
            first.patch24_applied,
        )
        self.assertIsNotNone(
            first.patch24_correct_weaving,
        )

        self.assertFalse(
            second.patch24_applied,
        )
        self.assertIsNone(
            second.patch24_correct_weaving,
        )

    def test_observability_state_cannot_change_correct_weaving(self):
        ring = LegacyAnswerRing(
            first=49308796693978539220209909511811324956,
            direction_step=1,
        )
        lengths = (
            4,
            4,
            4,
        )

        plain = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        noisy = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

        noisy.logs.extend(
            [
                ("önceden", 1),
                ("önceden", 2),
            ]
        )
        noisy.metrics[
            "yalnızca-gözlem"
        ] = 24100
        noisy.diagnostics.append(
            ("tanı", 49)
        )

        plain_ghost = legacyChooseEachDaySeparately(
            lengths,
            ring,
        )
        noisy_ghost = legacyChooseEachDaySeparately(
            lengths,
            ring,
        )

        plain_result = MonthWeavingPatchWrapper().repair(
            plain,
            lengths,
            ring,
            plain_ghost,
        )
        noisy_result = MonthWeavingPatchWrapper().repair(
            noisy,
            lengths,
            ring,
            noisy_ghost,
        )

        self.assertEqual(
            plain_result,
            noisy_result,
        )
        self.assertEqual(
            plain.patch24_wanted_rank,
            noisy.patch24_wanted_rank,
        )


if __name__ == "__main__":
    unittest.main()
