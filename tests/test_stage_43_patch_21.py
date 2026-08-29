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
from pastafari_calendar.legacy_arithmetic import M_OLD
from pastafari_calendar.legacy_cutlet_partition import (
    CutletPartitionGatePatchWrapper,
    FilteredLegacyCutletPartitionFamily,
    LegacyAllPositiveCutletPartitionFamily,
    LegacyCutletPartitionAdapter,
    currentCompatibleCutletRank,
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


def _prefix_hits(
    composition: tuple[int, ...],
    boundary: int,
) -> bool:
    running = 0

    for value in composition[:-1]:
        running += value

        if running == boundary:
            return True

    return False


class Stage43Patch21Tests(unittest.TestCase):
    def test_filtered_family_is_exact_lexicographic_subsequence_of_legacy_family(self):
        cases = (
            (7, 3, 2),
            (7, 3, 4),
            (9, 6, 4),
            (10, 4, 7),
        )

        for gate_gap_count, cutlet_count, boundary in cases:
            with self.subTest(
                gate_gap_count=gate_gap_count,
                cutlet_count=cutlet_count,
                boundary=boundary,
            ):
                legacy = LegacyAllPositiveCutletPartitionFamily(
                    gate_gap_count,
                    cutlet_count,
                )
                filtered = FilteredLegacyCutletPartitionFamily(
                    gate_gap_count,
                    cutlet_count,
                    boundary,
                )

                legacy_rows = [
                    legacy.unrank1(rank)
                    for rank in range(
                        1,
                        legacy.count() + 1,
                    )
                ]
                expected = [
                    row
                    for row in legacy_rows
                    if _prefix_hits(
                        row,
                        boundary,
                    )
                ]
                actual = [
                    filtered.unrank1(rank)
                    for rank in range(
                        1,
                        filtered.count() + 1,
                    )
                ]

                self.assertEqual(
                    actual,
                    expected,
                )

    def test_patch_executes_raw_legacy_selection_before_filtered_detour(self):
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
            "pastafari_calendar.legacy_cutlet_partition.LegacyCutletPartitionAdapter.call_with_ring",
            autospec=True,
            wraps=LegacyCutletPartitionAdapter.call_with_ring,
        ) as legacy_call:
            actual = LegacyCutletPartitionAdapter().call(
                ctx,
                9,
                6,
                4,
            )

        self.assertEqual(
            legacy_call.call_count,
            1,
        )
        self.assertEqual(
            ctx.patch21_legacy_selected_partition,
            ctx.legacy_cutlet_selected_partition,
        )
        self.assertTrue(
            ctx.legacy_cutlet_internal_gate_was_ignored,
        )
        self.assertTrue(
            ctx.patch21_filter_applied,
        )
        self.assertTrue(
            ctx.patch21_boundary_hit,
        )
        self.assertEqual(
            actual,
            ctx.patch21_semantic_partition,
        )
        self.assertTrue(
            _prefix_hits(
                actual,
                4,
            )
        )

    def test_no_internal_gate_reuses_legacy_result_without_filter(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        ring = LegacyAnswerRing(
            first=49308796693978539220209909511811324956,
            direction_step=1,
        )
        adapter = LegacyCutletPartitionAdapter()

        legacy = adapter.call_with_ring(
            ctx,
            ring,
            9,
            6,
            None,
        )

        actual = adapter.patch_wrapper.repair(
            ctx,
            ring,
            9,
            6,
            None,
            legacy,
        )

        self.assertEqual(
            actual,
            legacy,
        )
        self.assertFalse(
            ctx.patch21_filter_applied,
        )
        self.assertFalse(
            ctx.patch21_boundary_hit,
        )
        self.assertTrue(
            ctx.patch21_applied,
        )

    def test_stage42_witnesses_match_test_only_filtered_reference(self):
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

                reference_sauce = sauce(
                    calculation_day,
                    year_first_day,
                )
                reference_family = CutletPartitionFamily(
                    9,
                    6,
                    4,
                )
                reference_rank = choose_rank(
                    ask_bowl(
                        reference_sauce,
                        2,
                        21,
                    ),
                    reference_family.count(),
                )
                expected = reference_family.unrank1(
                    reference_rank
                )

                self.assertEqual(
                    actual,
                    expected,
                )

    def test_current_rank_supports_wide_family_sizes(self):
        rings = (
            LegacyAnswerRing(
                first=1,
                direction_step=1,
            ),
            LegacyAnswerRing(
                first=115396237916116191908255373965372069236,
                direction_step=-1,
            ),
        )
        sizes = (
            M_OLD + 1,
            M_OLD * M_OLD,
        )

        for ring in rings:
            for family_count in sizes:
                with self.subTest(
                    ring=ring,
                    family_count=family_count,
                ):
                    actual = currentCompatibleCutletRank(
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

    def test_real_calendar_path_keeps_legacy_scar_and_returns_filtered_semantics(self):
        with patch(
            "pastafari_calendar.legacy_cutlet_partition.CutletPartitionGatePatchWrapper.repair",
            autospec=True,
            wraps=CutletPartitionGatePatchWrapper.repair,
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
            ctx.legacy_cutlet_internal_gate_offset,
            4,
        )
        self.assertTrue(
            ctx.legacy_cutlet_used_all_positive_family,
        )
        self.assertTrue(
            ctx.legacy_cutlet_internal_gate_was_ignored,
        )
        self.assertTrue(
            ctx.patch21_filter_applied,
        )
        self.assertTrue(
            ctx.patch21_boundary_hit,
        )
        self.assertTrue(
            _prefix_hits(
                ctx.patch21_semantic_partition,
                4,
            )
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
        LegacyCutletPartitionAdapter().call(
            first,
            9,
            6,
            4,
        )

        self.assertTrue(
            first.patch21_applied,
        )
        self.assertIsNotNone(
            first.patch21_semantic_partition,
        )

        self.assertFalse(
            second.patch21_applied,
        )
        self.assertIsNone(
            second.patch21_semantic_partition,
        )

    def test_observability_state_cannot_change_filtered_partition(self):
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
        noisy.metrics[
            "yalnızca-gözlem"
        ] = 21100
        noisy.diagnostics.append(
            ("tanı", 43)
        )

        for ctx in (
            plain,
            noisy,
        ):
            LegacyStructureSauceAdapter().call(
                ctx,
                calculation_day,
                original_target_day,
                year_first_day,
            )

        plain_result = LegacyCutletPartitionAdapter().call(
            plain,
            9,
            6,
            4,
        )
        noisy_result = LegacyCutletPartitionAdapter().call(
            noisy,
            9,
            6,
            4,
        )

        self.assertEqual(
            plain_result,
            noisy_result,
        )
        self.assertEqual(
            plain.patch21_filtered_family_count,
            noisy.patch21_filtered_family_count,
        )
        self.assertEqual(
            plain.patch21_semantic_selected_rank,
            noisy.patch21_semantic_selected_rank,
        )


if __name__ == "__main__":
    unittest.main()
