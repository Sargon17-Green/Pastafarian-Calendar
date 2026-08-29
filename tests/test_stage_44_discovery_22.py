import itertools
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.legacy_repeated_names import (
    LegacyRepeatedNameGenerator,
    buildCutletNameAnswerRing,
    compatibleRepeatedNameRank,
    legacyRepeatedNameFamilyCount,
    legacyRepeatedNameUnrank1,
)
from pastafari_calendar.legacy_selection import LegacyAnswerRing
from pastafari_calendar.legacy_structure_sauce import LegacyStructureSauceAdapter
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from pastafari_calendar.source_language_catalog import SOURCE_LANGUAGE_CATALOG
from normative_reference import (
    FOUNDATION_DAY,
    AnswerStream,
    SEAL_CUTLET_NAMES,
    ask_bowl,
    choose_rank,
    falling_factorial,
    sauce,
    unrank_distinct_indices,
)


class Stage44Discovery22Tests(unittest.TestCase):
    def test_legacy_generator_family_is_all_lexicographic_sequences_with_repeats(self):
        expected = list(
            itertools.product(
                (1, 2, 3),
                repeat=2,
            )
        )

        self.assertEqual(
            legacyRepeatedNameFamilyCount(
                3,
                2,
            ),
            9,
        )
        self.assertEqual(
            [
                legacyRepeatedNameUnrank1(
                    3,
                    2,
                    rank,
                )
                for rank in range(
                    1,
                    10,
                )
            ],
            expected,
        )

    def test_legacy_generator_rank_matches_current_selection_for_bad_family_size(self):
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

        for ring in rings:
            with self.subTest(
                ring=ring,
            ):
                actual = compatibleRepeatedNameRank(
                    ring,
                    17 ** 6,
                )
                expected = choose_rank(
                    AnswerStream(
                        ring.first,
                        ring.direction_step,
                    ),
                    17 ** 6,
                )

                self.assertEqual(
                    actual,
                    expected,
                )

    def test_legacy_generator_can_actually_return_repeated_indices(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        actual = LegacyRepeatedNameGenerator().call_with_ring(
            ctx,
            LegacyAnswerRing(
                first=1,
                direction_step=1,
            ),
            3,
            3,
            "köfte",
        )

        self.assertEqual(
            actual,
            (
                1,
                1,
                1,
            ),
        )
        self.assertTrue(
            ctx.legacy_name_candidate_has_repeats,
        )

    def test_cutlet_name_ring_uses_stage20_semantic_sauce_bowl5_seal22(self):
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

        actual = buildCutletNameAnswerRing(
            ctx
        )

        expected = ask_bowl(
            sauce(
                calculation_day,
                year_first_day,
            ),
            5,
            SEAL_CUTLET_NAMES,
        )

        self.assertEqual(
            actual.first,
            expected.first,
        )
        self.assertEqual(
            actual.direction_step,
            expected.direction_step,
        )

    def test_repeated_cutlet_name_generator_is_on_real_calendar_path(self):
        with patch(
            "pastafari_calendar.legacy_repeated_names.LegacyRepeatedNameGenerator.call_cutlet_names",
            autospec=True,
            wraps=LegacyRepeatedNameGenerator.call_cutlet_names,
        ) as name_call:
            with self.assertRaises(StageNotIntegratedError):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                )

        self.assertEqual(
            name_call.call_count,
            1,
        )

        ctx = name_call.call_args.args[1]

        self.assertEqual(
            name_call.call_args.args[2],
            len(
                SOURCE_LANGUAGE_CATALOG.cutlets
            ),
        )
        self.assertEqual(
            name_call.call_args.args[3],
            ctx.legacy_cutlet_count,
        )
        self.assertEqual(
            ctx.legacy_cutlet_name_indices,
            ctx.legacy_name_candidate_indices,
        )
        self.assertEqual(
            ctx.legacy_name_semantic_indices,
            ctx.legacy_name_candidate_indices,
        )
        self.assertEqual(
            ctx.legacy_name_source_kind,
            "köfte",
        )

    def test_name_state_is_invocation_local_and_uses_only_canonical_indices(self):
        first = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        second = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

        actual = LegacyRepeatedNameGenerator().call_with_ring(
            first,
            LegacyAnswerRing(
                first=1,
                direction_step=1,
            ),
            17,
            6,
            "köfte",
        )

        self.assertEqual(
            first.legacy_name_generation_calls,
            1,
        )
        self.assertTrue(
            all(
                type(index) is int
                and 1 <= index <= 17
                for index in actual
            ),
        )
        self.assertEqual(
            second.legacy_name_generation_calls,
            0,
        )
        self.assertIsNone(
            second.legacy_name_candidate_indices,
        )

    def test_patch22_partial_permutation_correction_is_not_present_in_production(self):
        production = (
            ROOT
            / "src"
            / "pastafari_calendar"
            / "legacy_repeated_names.py"
        ).read_text(
            encoding="utf-8"
        )

        forbidden = (
            "RepeatedNamePatchWrapper",
            "partialPermutationUnrank",
            "unrankDistinctIndices",
            "fallingFactorialDistinct",
            "correct_name_indices",
            "patch22_applied",
        )

        for token in forbidden:
            self.assertNotIn(
                token,
                production,
            )

    def test_current_repeated_name_generator_diverges_from_partial_permutation_unrank(self):
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

                actual = LegacyRepeatedNameGenerator().call_cutlet_names(
                    ctx,
                    17,
                    6,
                )

                reference_sauce = sauce(
                    calculation_day,
                    year_first_day,
                )
                reference_stream = ask_bowl(
                    reference_sauce,
                    5,
                    SEAL_CUTLET_NAMES,
                )
                reference_count = falling_factorial(
                    17,
                    6,
                )
                reference_rank = choose_rank(
                    reference_stream,
                    reference_count,
                )
                expected = unrank_distinct_indices(
                    17,
                    6,
                    reference_rank,
                )

                self.assertLess(
                    len(
                        set(
                            actual
                        )
                    ),
                    len(
                        actual
                    ),
                    msg="Discovery 22 witness eski generator'ın gerçekten tekrarlı canonicalIndex üretmesini göstermelidir",
                )
                self.assertEqual(
                    actual,
                    expected,
                    msg="Legacy repeated-name generator 17^K ailesinden seçtiği için partial-permutation unrank sonucundan ayrıştı",
                )


if __name__ == "__main__":
    unittest.main()
