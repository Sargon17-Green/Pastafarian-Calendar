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
    RepeatedNamePatchWrapper,
    compatibleRepeatedNameRank,
    fallingFactorialDistinct,
    legacyRepeatedNameUnrank1,
    partialPermutationUnrank,
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
    SEAL_CUTLET_NAMES,
    ask_bowl,
    choose_rank,
    falling_factorial,
    sauce,
    unrank_distinct_indices,
)


class Stage45Patch22Tests(unittest.TestCase):
    def test_falling_factorial_distinct_matches_test_only_reference(self):
        cases = (
            (0, 0),
            (1, 1),
            (3, 1),
            (3, 3),
            (17, 6),
            (47, 17),
        )

        for master_count, item_count in cases:
            with self.subTest(
                master_count=master_count,
                item_count=item_count,
            ):
                self.assertEqual(
                    fallingFactorialDistinct(
                        master_count,
                        item_count,
                    ),
                    falling_factorial(
                        master_count,
                        item_count,
                    ),
                )

    def test_partial_permutation_unrank_matches_test_only_reference(self):
        cases = (
            (1, 1, 1),
            (3, 2, 1),
            (3, 2, 6),
            (5, 3, 17),
            (17, 6, 123456),
        )

        for master_count, item_count, rank1 in cases:
            with self.subTest(
                master_count=master_count,
                item_count=item_count,
                rank1=rank1,
            ):
                self.assertEqual(
                    partialPermutationUnrank(
                        master_count,
                        item_count,
                        rank1,
                    ),
                    unrank_distinct_indices(
                        master_count,
                        item_count,
                        rank1,
                    ),
                )

    def test_call_cutlet_names_runs_legacy_bad_generator_before_patch(self):
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
            "pastafari_calendar.legacy_repeated_names.LegacyRepeatedNameGenerator.call_with_ring",
            autospec=True,
            wraps=LegacyRepeatedNameGenerator.call_with_ring,
        ) as bad_call, patch(
            "pastafari_calendar.legacy_repeated_names.RepeatedNamePatchWrapper.repair",
            autospec=True,
            wraps=RepeatedNamePatchWrapper.repair,
        ) as repair_call:
            actual = LegacyRepeatedNameGenerator().call_cutlet_names(
                ctx,
                17,
                6,
            )

        self.assertEqual(
            bad_call.call_count,
            1,
        )
        self.assertEqual(
            repair_call.call_count,
            1,
        )
        self.assertEqual(
            ctx.patch22_bad_indices,
            ctx.legacy_name_candidate_indices,
        )
        self.assertEqual(
            actual,
            ctx.patch22_semantic_indices,
        )

    def test_patch_returns_correct_when_bad_differs(self):
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

        actual = LegacyRepeatedNameGenerator().call_cutlet_names(
            ctx,
            17,
            6,
        )

        expected_stream = ask_bowl(
            sauce(
                calculation_day,
                year_first_day,
            ),
            5,
            SEAL_CUTLET_NAMES,
        )
        expected_count = falling_factorial(
            17,
            6,
        )
        expected_rank = choose_rank(
            expected_stream,
            expected_count,
        )
        expected = unrank_distinct_indices(
            17,
            6,
            expected_rank,
        )

        self.assertFalse(
            ctx.patch22_bad_equals_correct,
        )
        self.assertFalse(
            ctx.patch22_returned_bad,
        )
        self.assertEqual(
            actual,
            expected,
        )
        self.assertEqual(
            ctx.patch22_correct_indices,
            expected,
        )
        self.assertEqual(
            len(
                set(
                    actual
                )
            ),
            len(
                actual
            ),
        )

    def test_patch_returns_bad_when_bad_already_equals_correct(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        ring = LegacyAnswerRing(
            first=1,
            direction_step=1,
        )
        generator = LegacyRepeatedNameGenerator()

        bad = generator.call_with_ring(
            ctx,
            ring,
            17,
            1,
            "köfte",
        )

        actual = RepeatedNamePatchWrapper().repair(
            ctx,
            ring,
            17,
            1,
            "köfte",
            bad,
        )

        self.assertTrue(
            ctx.patch22_bad_equals_correct,
        )
        self.assertTrue(
            ctx.patch22_returned_bad,
        )
        self.assertIs(
            actual,
            bad,
        )

    def test_correct_rank_uses_same_answer_ring_and_distinct_family_count(self):
        ring = LegacyAnswerRing(
            first=115396237916116191908255373965372069236,
            direction_step=-1,
        )
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        bad = legacyRepeatedNameUnrank1(
            17,
            6,
            compatibleRepeatedNameRank(
                ring,
                17 ** 6,
            ),
        )

        actual = RepeatedNamePatchWrapper().repair(
            ctx,
            ring,
            17,
            6,
            "köfte",
            bad,
        )

        expected_count = falling_factorial(
            17,
            6,
        )
        expected_rank = choose_rank(
            AnswerStream(
                ring.first,
                ring.direction_step,
            ),
            expected_count,
        )
        expected = unrank_distinct_indices(
            17,
            6,
            expected_rank,
        )

        self.assertEqual(
            ctx.patch22_distinct_family_count,
            expected_count,
        )
        self.assertEqual(
            ctx.patch22_correct_rank,
            expected_rank,
        )
        self.assertEqual(
            actual,
            expected,
        )

    def test_real_calendar_path_returns_semantic_distinct_indices_but_keeps_bad_scar(self):
        with patch(
            "pastafari_calendar.legacy_repeated_names.RepeatedNamePatchWrapper.repair",
            autospec=True,
            wraps=RepeatedNamePatchWrapper.repair,
        ) as repair_call:
            with self.assertRaises(StageNotIntegratedError):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                )

        self.assertEqual(
            repair_call.call_count,
            1,
        )

        ctx = repair_call.call_args.args[1]

        self.assertEqual(
            ctx.legacy_cutlet_name_indices,
            ctx.patch22_semantic_indices,
        )
        self.assertEqual(
            ctx.patch22_bad_indices,
            ctx.legacy_name_candidate_indices,
        )
        self.assertTrue(
            ctx.patch22_applied,
        )
        self.assertEqual(
            len(
                set(
                    ctx.patch22_semantic_indices
                )
            ),
            len(
                ctx.patch22_semantic_indices
            ),
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

        bad = LegacyRepeatedNameGenerator().call_with_ring(
            first,
            ring,
            17,
            6,
            "köfte",
        )

        RepeatedNamePatchWrapper().repair(
            first,
            ring,
            17,
            6,
            "köfte",
            bad,
        )

        self.assertTrue(
            first.patch22_applied,
        )
        self.assertIsNotNone(
            first.patch22_correct_indices,
        )
        self.assertFalse(
            second.patch22_applied,
        )
        self.assertIsNone(
            second.patch22_correct_indices,
        )

    def test_observability_state_cannot_change_partial_permutation_result(self):
        ring = LegacyAnswerRing(
            first=49308796693978539220209909511811324956,
            direction_step=1,
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
        ] = 22100
        noisy.diagnostics.append(
            ("tanı", 45)
        )

        plain_bad = LegacyRepeatedNameGenerator().call_with_ring(
            plain,
            ring,
            17,
            6,
            "köfte",
        )
        noisy_bad = LegacyRepeatedNameGenerator().call_with_ring(
            noisy,
            ring,
            17,
            6,
            "köfte",
        )

        plain_result = RepeatedNamePatchWrapper().repair(
            plain,
            ring,
            17,
            6,
            "köfte",
            plain_bad,
        )
        noisy_result = RepeatedNamePatchWrapper().repair(
            noisy,
            ring,
            17,
            6,
            "köfte",
            noisy_bad,
        )

        self.assertEqual(
            plain_result,
            noisy_result,
        )
        self.assertEqual(
            plain.patch22_correct_rank,
            noisy.patch22_correct_rank,
        )


if __name__ == "__main__":
    unittest.main()
