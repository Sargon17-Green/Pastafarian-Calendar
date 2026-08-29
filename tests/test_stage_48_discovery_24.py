import collections
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.legacy_month_weaving import (
    LegacyMonthWeavingAdapter,
    buildMonthWeavingAnswerRing,
    legacyChooseEachDaySeparately,
    wrapMonth,
)
from pastafari_calendar.legacy_selection import LegacyAnswerRing
from pastafari_calendar.legacy_structure_sauce import LegacyStructureSauceAdapter
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from normative_reference import (
    FOUNDATION_DAY,
    MonthWeavingFamily,
    SEAL_MONTH_WEAVING,
    ask_bowl,
    choose_rank,
    sauce,
)


class Stage48Discovery24Tests(unittest.TestCase):
    def test_wrap_month_uses_one_based_circular_month_ids(self):
        self.assertEqual(
            wrapMonth(
                1,
                3,
            ),
            1,
        )
        self.assertEqual(
            wrapMonth(
                4,
                3,
            ),
            1,
        )
        self.assertEqual(
            wrapMonth(
                5,
                3,
            ),
            2,
        )

    def test_day_by_day_legacy_choice_preserves_only_month_multiplicities(self):
        lengths = (
            2,
            3,
            1,
        )
        actual = legacyChooseEachDaySeparately(
            lengths,
            LegacyAnswerRing(
                first=2,
                direction_step=1,
            ),
        )
        counts = collections.Counter(
            actual
        )

        self.assertEqual(
            len(
                actual
            ),
            sum(
                lengths
            ),
        )
        self.assertEqual(
            tuple(
                counts[
                    month_id
                ]
                for month_id in range(
                    1,
                    4,
                )
            ),
            lengths,
        )

    def test_day_by_day_legacy_choice_can_break_first_occurrence_order(self):
        actual = legacyChooseEachDaySeparately(
            (
                4,
                4,
                4,
            ),
            LegacyAnswerRing(
                first=2,
                direction_step=1,
            ),
        )

        self.assertEqual(
            actual[
                0
            ],
            2,
        )
        self.assertNotEqual(
            actual[
                0
            ],
            1,
        )

    def test_month_weaving_ring_uses_stage20_semantic_sauce_bowl4_seal32(self):
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

        actual = buildMonthWeavingAnswerRing(
            ctx
        )

        expected = ask_bowl(
            sauce(
                calculation_day,
                year_first_day,
            ),
            4,
            SEAL_MONTH_WEAVING,
        )

        self.assertEqual(
            actual.first,
            expected.first,
        )
        self.assertEqual(
            actual.direction_step,
            expected.direction_step,
        )

    def test_day_by_day_weaving_adapter_is_on_real_calendar_path(self):
        with patch(
            "pastafari_calendar.legacy_month_weaving.LegacyMonthWeavingAdapter.call",
            autospec=True,
            wraps=LegacyMonthWeavingAdapter.call,
        ) as weaving_call:
            with self.assertRaises(
                StageNotIntegratedError
            ):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                )

        self.assertEqual(
            weaving_call.call_count,
            1,
        )
        self.assertEqual(
            weaving_call.call_args.args[
                2
            ],
            (
                4,
                4,
                4,
            ),
        )

        ctx = weaving_call.call_args.args[
            1
        ]

        self.assertEqual(
            ctx.legacy_month_weaving_semantic,
            ctx.legacy_month_weaving_ghost,
        )
        self.assertEqual(
            ctx.legacy_month_weaving_calls,
            1,
        )

    def test_month_weaving_state_is_invocation_local(self):
        first = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        second = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

        LegacyStructureSauceAdapter().call(
            first,
            FOUNDATION_DAY,
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

        LegacyMonthWeavingAdapter().call(
            first,
            (
                4,
                4,
                4,
            ),
        )

        self.assertEqual(
            first.legacy_month_weaving_calls,
            1,
        )
        self.assertIsNotNone(
            first.legacy_month_weaving_ghost,
        )

        self.assertEqual(
            second.legacy_month_weaving_calls,
            0,
        )
        self.assertIsNone(
            second.legacy_month_weaving_ghost,
        )

    def test_patch24_dp_unrank_correction_is_not_present_in_production(self):
        production = (
            ROOT
            / "src"
            / "pastafari_calendar"
            / "legacy_month_weaving.py"
        ).read_text(
            encoding="utf-8"
        )

        forbidden = (
            "DPUnrankLegalWeaving",
            "MonthWeavingPatchWrapper",
            "wantedRank",
            "correct_weaving",
            "patch24_applied",
        )

        for token in forbidden:
            self.assertNotIn(
                token,
                production,
            )

    def test_current_day_by_day_month_choice_diverges_from_legal_weaving_rank(self):
        lengths = (
            4,
            4,
            4,
        )
        cases = (
            (
                FOUNDATION_DAY,
                FOUNDATION_DAY + 3,
                FOUNDATION_DAY + 3,
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

                actual = LegacyMonthWeavingAdapter().call(
                    ctx,
                    lengths,
                )

                reference_sauce = sauce(
                    calculation_day,
                    year_first_day,
                )
                reference_stream = ask_bowl(
                    reference_sauce,
                    4,
                    SEAL_MONTH_WEAVING,
                )
                family = MonthWeavingFamily(
                    lengths
                )
                rank = choose_rank(
                    reference_stream,
                    family.count(),
                )
                expected = family.unrank1(
                    rank
                )

                self.assertNotEqual(
                    actual[
                        0
                    ],
                    1,
                    msg="Discovery 24 witness old day-by-day chooser'ın legal first-occurrence sırasını gerçekten bozmalıdır",
                )
                self.assertEqual(
                    actual,
                    expected,
                    msg="Legacy day-by-day month chooser bir bütün legal weaving rank'i seçmediği için authoritative weaving'den ayrıştı",
                )


if __name__ == "__main__":
    unittest.main()
