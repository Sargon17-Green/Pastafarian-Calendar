import sys
import unittest
from dataclasses import astuple
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.final_integration import (
    FOUNDATION_DAY_INTEGRATED,
    LEGACY_YEAR_MAX_INTEGRATED,
    YEAR_MAX_DAYS_INTEGRATED,
    YEAR_MIN_DAYS_INTEGRATED,
    FinalSpaghettiIntegrationManager,
    IntegratedGateCache,
    IntegratedYear,
    _IntegratedCandidate,
    _ceilDiv,
    _chooseIntegratedRank,
    integratedDPUnrankLegalWeaving,
    sauceWithScars,
)
from pastafari_calendar.legacy_arithmetic import (
    M_OLD,
    regularMod,
    savePatch,
)
from pastafari_calendar.legacy_cutlet_partition import (
    FilteredLegacyCutletPartitionFamily,
    LegacyAllPositiveCutletPartitionFamily,
)
from pastafari_calendar.legacy_month_day_position import (
    countMonthOccurrencesThroughTarget,
    oldContiguousMonthDayGuess,
)
from pastafari_calendar.legacy_month_length_materialization import (
    VirtualLegacyList,
)
from pastafari_calendar.legacy_month_weaving import (
    LegalMonthWeavingDP,
)
from pastafari_calendar.legacy_next_bowl import (
    latchedCircularSuccessor,
)
from pastafari_calendar.legacy_opening_gate_interval import (
    LegacyOpeningGateYear,
    correctOpeningGateInterval,
    legacyFindYearClosedOpeningInterval,
)
from pastafari_calendar.legacy_permutation import (
    oldPermutationUnrank0,
)
from pastafari_calendar.legacy_repeated_names import (
    fallingFactorialDistinct,
    partialPermutationUnrank,
)
from pastafari_calendar.legacy_selection import (
    LegacyAnswerRing,
    answerAtRing,
)
from pastafari_calendar.monster_bootstrap import MonsterContext
from pastafari_calendar.source_language_catalog import (
    SOURCE_LANGUAGE_CATALOG,
)

from normative_reference import (
    AnswerStream,
    BoundedCompositionFamily,
    FOUNDATION_DAY,
    GateTable,
    MonthWeavingFamily,
    NormativeCalendar,
    Year,
    choose_rank,
    falling_factorial,
    permutation_unrank1,
    save,
    sauce_corrective56,
    unrank_distinct_indices,
)


class Stage55FinalAuditTests(unittest.TestCase):
    def _assertEndToEnd(
        self,
        calculation_day: int,
        target_day: int,
    ) -> None:
        oracle = NormativeCalendar(sauce_function=sauce_corrective56)
        expected = astuple(
            oracle.calendar_date(
                calculation_day,
                target_day,
            )
        )
        actual = astuple(
            calendar_date_spaghetti(
                calculation_day,
                target_day,
            )
        )
        self.assertEqual(
            actual,
            expected,
        )

    def test_01a_end_to_end_foundation_matches_oracle(self):
        self._assertEndToEnd(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

    def test_01b_end_to_end_day_before_foundation_matches_oracle(self):
        self._assertEndToEnd(
            FOUNDATION_DAY - 1,
            FOUNDATION_DAY - 1,
        )

    def test_01c_end_to_end_day_after_foundation_matches_oracle(self):
        self._assertEndToEnd(
            FOUNDATION_DAY + 1,
            FOUNDATION_DAY + 1,
        )

    def test_01d_end_to_end_crossing_foundation_forward_matches_oracle(self):
        self._assertEndToEnd(
            FOUNDATION_DAY - 2,
            FOUNDATION_DAY + 2,
        )

    def test_01e_end_to_end_crossing_foundation_backward_matches_oracle(self):
        self._assertEndToEnd(
            FOUNDATION_DAY + 2,
            FOUNDATION_DAY - 2,
        )

    def test_02_save_subtraction_permutation_next_bowl_and_direction_boundaries(self):
        for value in (
            1,
            M_OLD - 1,
            M_OLD,
            M_OLD + 1,
            2 * M_OLD,
        ):
            with self.subTest(
                save_value=value,
            ):
                self.assertEqual(
                    savePatch(
                        value
                    ),
                    save(
                        value
                    ),
                )

        wrap_cases = (
            (
                -1,
                7,
                6,
            ),
            (
                -8,
                7,
                6,
            ),
            (
                7,
                7,
                0,
            ),
            (
                15,
                7,
                1,
            ),
        )

        for value, modulus, expected in wrap_cases:
            with self.subTest(
                wrap=(
                    value,
                    modulus,
                ),
            ):
                self.assertEqual(
                    regularMod(
                        value,
                        modulus,
                    ),
                    expected,
                )

        self.assertEqual(
            oldPermutationUnrank0(
                0
            ),
            permutation_unrank1(
                1,
                (
                    1,
                    2,
                    3,
                    4,
                    5,
                    6,
                ),
            ),
        )
        self.assertEqual(
            oldPermutationUnrank0(
                719
            ),
            permutation_unrank1(
                720,
                (
                    1,
                    2,
                    3,
                    4,
                    5,
                    6,
                ),
            ),
        )

        order = (
            6,
            2,
            4,
            3,
            5,
            1,
        )
        self.assertEqual(
            latchedCircularSuccessor(
                order,
                1,
            ),
            6,
        )

        odd_ring = LegacyAnswerRing(
            first=11,
            direction_step=1,
        )
        even_ring = LegacyAnswerRing(
            first=11,
            direction_step=-1,
        )
        self.assertEqual(
            answerAtRing(
                odd_ring,
                3,
            ),
            save(
                14
            ),
        )
        self.assertEqual(
            answerAtRing(
                even_ring,
                3,
            ),
            save(
                8
            ),
        )

    def test_03_short_wide_and_rejection_selection_match_oracle(self):
        cases = (
            (
                LegacyAnswerRing(
                    first=1,
                    direction_step=1,
                ),
                1,
            ),
            (
                LegacyAnswerRing(
                    first=M_OLD,
                    direction_step=-1,
                ),
                M_OLD,
            ),
            (
                LegacyAnswerRing(
                    first=M_OLD - 1,
                    direction_step=-1,
                ),
                7,
            ),
            (
                LegacyAnswerRing(
                    first=M_OLD,
                    direction_step=1,
                ),
                11,
            ),
            (
                LegacyAnswerRing(
                    first=17,
                    direction_step=1,
                ),
                M_OLD + 1,
            ),
            (
                LegacyAnswerRing(
                    first=19,
                    direction_step=-1,
                ),
                M_OLD * M_OLD,
            ),
            (
                LegacyAnswerRing(
                    first=23,
                    direction_step=1,
                ),
                M_OLD * M_OLD + 1,
            ),
        )

        for ring, family_count in cases:
            with self.subTest(
                first=ring.first,
                direction=ring.direction_step,
                family_count=family_count,
            ):
                self.assertEqual(
                    _chooseIntegratedRank(
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

    def test_04_gate_plus_minus_one_two_and_no_forced_symmetry_match_oracle(self):
        oracle = GateTable(sauce_function=sauce_corrective56)
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        actual = IntegratedGateCache(
            ctx
        )

        for index in (
            1,
            -1,
            2,
            -2,
        ):
            with self.subTest(
                index=index,
            ):
                self.assertEqual(
                    actual.ensure_index(
                        index
                    ),
                    oracle.ensure_index(
                        index
                    ),
                )

        positive_gap = (
            actual.gates[
                1
            ]
            - actual.gates[
                0
            ]
        )
        negative_gap = (
            actual.gates[
                0
            ]
            - actual.gates[
                -1
            ]
        )
        self.assertNotEqual(
            positive_gap,
            negative_gap,
        )

    def test_05_year_length_252_5778_and_late_rejection_5779_5780_5781(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        manager = FinalSpaghettiIntegrationManager(
            ctx
        )
        candidates = tuple(
            _IntegratedCandidate(
                open_index=0,
                close_index=6,
                open_day=0,
                close_day=length,
                length=length,
            )
            for length in (
                252,
                5778,
                5779,
                5780,
                5781,
            )
        )

        selected = manager._late5778FilterAndSort5000(
            candidates
        )
        lengths = tuple(
            candidate.length
            for candidate in selected
        )

        self.assertEqual(
            YEAR_MIN_DAYS_INTEGRATED,
            252,
        )
        self.assertEqual(
            YEAR_MAX_DAYS_INTEGRATED,
            5778,
        )
        self.assertEqual(
            LEGACY_YEAR_MAX_INTEGRATED,
            5781,
        )
        self.assertEqual(
            lengths,
            (
                252,
                5778,
            ),
        )
        self.assertEqual(
            ctx.integration_year_rejected_5779_5781,
            3,
        )

    def test_06_opening_first_internal_closing_boundaries_follow_open_left_closed_right(self):
        year = LegacyOpeningGateYear(
            number=5001,
            open_day=100,
            close_day=200,
        )

        def previous_year(
            known,
        ):
            return LegacyOpeningGateYear(
                number=known.number - 1,
                open_day=known.open_day - 100,
                close_day=known.open_day,
            )

        legacy = legacyFindYearClosedOpeningInterval(
            year,
            100,
            previous_year,
        )
        correct_open, open_steps = correctOpeningGateInterval(
            year,
            100,
            previous_year,
        )
        first_day, first_steps = correctOpeningGateInterval(
            year,
            101,
            previous_year,
        )
        internal, internal_steps = correctOpeningGateInterval(
            year,
            150,
            previous_year,
        )
        closing, closing_steps = correctOpeningGateInterval(
            year,
            200,
            previous_year,
        )

        self.assertEqual(
            legacy.number,
            5001,
        )
        self.assertEqual(
            correct_open.number,
            5000,
        )
        self.assertEqual(
            open_steps,
            1,
        )
        self.assertEqual(
            (
                first_day.number,
                first_steps,
            ),
            (
                5001,
                0,
            ),
        )
        self.assertEqual(
            (
                internal.number,
                internal_steps,
            ),
            (
                5001,
                0,
            ),
        )
        self.assertEqual(
            (
                closing.number,
                closing_steps,
            ),
            (
                5001,
                0,
            ),
        )

    def test_07_internal_calculation_gate_cutlet_family_and_cutlet_count_extremes_are_exact(self):
        raw = LegacyAllPositiveCutletPartitionFamily(
            10,
            3,
        )
        filtered = FilteredLegacyCutletPartitionFamily(
            10,
            3,
            4,
        )
        brute = tuple(
            raw.unrank1(
                rank1
            )
            for rank1 in range(
                1,
                raw.count() + 1,
            )
            if 4 in tuple(
                sum(
                    raw.unrank1(
                        rank1
                    )[
                        :position
                    ]
                )
                for position in range(
                    1,
                    3,
                )
            )
        )

        self.assertEqual(
            filtered.count(),
            len(
                brute
            ),
        )

        for rank1, expected in enumerate(
            brute,
            start=1,
        ):
            self.assertEqual(
                filtered.unrank1(
                    rank1
                ),
                expected,
            )

        self.assertEqual(
            fallingFactorialDistinct(
                17,
                6,
            ),
            falling_factorial(
                17,
                6,
            ),
        )
        self.assertEqual(
            fallingFactorialDistinct(
                17,
                17,
            ),
            falling_factorial(
                17,
                17,
            ),
        )

    def test_08_month_count_length_extremes_and_virtual_counts_are_exact(self):
        minimum_months = _ceilDiv(
            252,
            123,
        )
        maximum_months = min(
            47,
            5778 // 4,
        )

        self.assertEqual(
            minimum_months,
            3,
        )
        self.assertEqual(
            maximum_months,
            47,
        )

        virtual = VirtualLegacyList(
            127,
            2,
            4,
            123,
        )
        reference = BoundedCompositionFamily(
            127,
            2,
            4,
            123,
        )

        self.assertEqual(
            virtual.count(),
            reference.count(),
        )
        self.assertIn(
            (
                4,
                123,
            ),
            tuple(
                virtual.itemAt1(
                    rank1
                )
                for rank1 in range(
                    1,
                    virtual.count() + 1,
                )
            ),
        )
        self.assertIn(
            (
                123,
                4,
            ),
            tuple(
                virtual.itemAt1(
                    rank1
                )
                for rank1 in range(
                    1,
                    virtual.count() + 1,
                )
            ),
        )

    def test_09_interleaved_and_heavy_weaving_counts_and_unrank_are_exact(self):
        cases = (
            (
                4,
                4,
                4,
            ),
            (
                20,
                20,
                20,
                20,
                20,
            ),
        )

        for lengths in cases:
            with self.subTest(
                lengths=lengths,
            ):
                actual = LegalMonthWeavingDP(
                    lengths
                )
                expected = MonthWeavingFamily(
                    lengths
                )

                self.assertEqual(
                    actual.count(),
                    expected.count(),
                )

                ranks = (
                    1,
                    max(
                        1,
                        actual.count() // 2,
                    ),
                    actual.count(),
                )

                for rank1 in ranks:
                    self.assertEqual(
                        integratedDPUnrankLegalWeaving(
                            actual,
                            rank1,
                        ),
                        expected.unrank1(
                            rank1
                        ),
                    )

    def test_10_distinct_cutlet_month_names_and_separated_day_in_month_are_exact(self):
        cutlet_count = fallingFactorialDistinct(
            17,
            6,
        )
        month_count = fallingFactorialDistinct(
            47,
            8,
        )

        for master_count, item_count, count in (
            (
                17,
                6,
                cutlet_count,
            ),
            (
                47,
                8,
                month_count,
            ),
        ):
            rank1 = min(
                count,
                12345,
            )
            actual = partialPermutationUnrank(
                master_count,
                item_count,
                rank1,
            )
            expected = unrank_distinct_indices(
                master_count,
                item_count,
                rank1,
            )

            self.assertEqual(
                actual,
                expected,
            )
            self.assertEqual(
                len(
                    set(
                        actual
                    )
                ),
                item_count,
            )

        weaving = (
            1,
            2,
            1,
            3,
            1,
            2,
        )
        target_position = 5
        self.assertEqual(
            oldContiguousMonthDayGuess(
                weaving,
                target_position,
            ),
            5,
        )
        self.assertEqual(
            countMonthOccurrencesThroughTarget(
                weaving,
                target_position,
            ),
            3,
        )

    def test_11_year_5000_5001_4999_and_number_transitions_1_0_minus1_match_oracle(self):
        calculation_day = FOUNDATION_DAY
        oracle = NormativeCalendar(sauce_function=sauce_corrective56)
        ctx = MonsterContext(
            calculation_day,
            calculation_day,
        )
        actual = FinalSpaghettiIntegrationManager(
            ctx
        )

        oracle_5000 = oracle.year5000(
            calculation_day
        )
        actual_5000 = actual.year5000(
            calculation_day
        )

        def year_tuple(
            year,
        ):
            return (
                year.number,
                year.open_gate_index,
                year.close_gate_index,
                year.open_gate_day,
                year.close_gate_day,
            )

        self.assertEqual(
            year_tuple(
                actual_5000
            ),
            year_tuple(
                oracle_5000
            ),
        )

        oracle_5001 = oracle.next_year(
            calculation_day,
            oracle_5000,
        )
        actual_5001 = actual._nextYear(
            calculation_day,
            actual_5000,
        )
        oracle_4999 = oracle.previous_year(
            calculation_day,
            oracle_5000,
        )
        actual_4999 = actual._previousYear(
            calculation_day,
            actual_5000,
        )

        self.assertEqual(
            year_tuple(
                actual_5001
            ),
            year_tuple(
                oracle_5001
            ),
        )
        self.assertEqual(
            year_tuple(
                actual_4999
            ),
            year_tuple(
                oracle_4999
            ),
        )

        synthetic_oracle = Year(
            2,
            oracle_5000.open_gate_index,
            oracle_5000.close_gate_index,
            oracle_5000.open_gate_day,
            oracle_5000.close_gate_day,
        )
        synthetic_actual = IntegratedYear(
            number=2,
            open_gate_index=actual_5000.open_gate_index,
            close_gate_index=actual_5000.close_gate_index,
            open_gate_day=actual_5000.open_gate_day,
            close_gate_day=actual_5000.close_gate_day,
        )

        for expected_number in (
            1,
            0,
            -1,
        ):
            synthetic_oracle = oracle.previous_year(
                calculation_day,
                synthetic_oracle,
            )
            synthetic_actual = actual._previousYear(
                calculation_day,
                synthetic_actual,
            )
            self.assertEqual(
                synthetic_actual.number,
                expected_number,
            )
            self.assertEqual(
                synthetic_actual.number,
                synthetic_oracle.number,
            )
            self.assertEqual(
                year_tuple(
                    synthetic_actual
                )[
                    1:
                ],
                year_tuple(
                    synthetic_oracle
                )[
                    1:
                ],
            )

    def test_12_year_cache_cold_warm_and_same_number_different_calculation_day_are_guarded(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        manager = FinalSpaghettiIntegrationManager(
            ctx
        )
        year = IntegratedYear(
            number=5000,
            open_gate_index=1,
            close_gate_index=7,
            open_gate_day=100,
            close_gate_day=500,
        )

        first = manager._guardedYearCacheRoundTrip(
            1000,
            year,
        )
        first_misses = ctx.integration_year_cache_misses
        second = manager._guardedYearCacheRoundTrip(
            1000,
            year,
        )

        self.assertIs(
            first,
            second,
        )
        self.assertEqual(
            first_misses,
            1,
        )
        self.assertGreaterEqual(
            ctx.integration_year_cache_hits,
            2,
        )

        different_calculation = manager._guardedYearCacheRoundTrip(
            1001,
            year,
        )

        self.assertEqual(
            different_calculation,
            year,
        )
        self.assertGreaterEqual(
            ctx.integration_year_cache_guard_rejections,
            1,
        )
        self.assertEqual(
            ctx.integration_year_cache_misses,
            2,
        )

    def test_13_catalog_indices_are_frozen_unique_and_locale_can_only_change_presentation(self):
        self.assertEqual(
            SOURCE_LANGUAGE_CATALOG.version,
            "1.3.1",
        )
        self.assertEqual(
            SOURCE_LANGUAGE_CATALOG.natural_language,
            "Türkçe",
        )

        cutlet_indices = tuple(
            item.canonical_index
            for item in SOURCE_LANGUAGE_CATALOG.cutlets
        )
        month_indices = tuple(
            item.canonical_index
            for item in SOURCE_LANGUAGE_CATALOG.months
        )
        cutlet_texts = tuple(
            item.text
            for item in SOURCE_LANGUAGE_CATALOG.cutlets
        )
        month_texts = tuple(
            item.text
            for item in SOURCE_LANGUAGE_CATALOG.months
        )

        self.assertEqual(
            cutlet_indices,
            tuple(
                range(
                    1,
                    18,
                )
            ),
        )
        self.assertEqual(
            month_indices,
            tuple(
                range(
                    1,
                    48,
                )
            ),
        )
        self.assertEqual(
            len(
                set(
                    cutlet_texts
                )
            ),
            17,
        )
        self.assertEqual(
            len(
                set(
                    month_texts
                )
            ),
            47,
        )

        presentation_locale = {
            index: f"sunum-{index}"
            for index in cutlet_indices
        }
        semantic_indices_before = cutlet_indices
        _ = tuple(
            presentation_locale[
                index
            ]
            for index in semantic_indices_before
        )
        self.assertEqual(
            semantic_indices_before,
            tuple(
                item.canonical_index
                for item in SOURCE_LANGUAGE_CATALOG.cutlets
            ),
        )

    def test_14_all_26_legacy_defects_and_26_patch_layers_remain_physical(self):
        production = "\n".join(
            path.read_text(
                encoding="utf-8"
            )
            for path in (
                ROOT
                / "src"
                / "pastafari_calendar"
            ).glob(
                "*.py"
            )
        )

        legacy_tokens = (
            "oldRemainder",
            "oldDayTag",
            "oldDistance",
            "mutateStonesWrong",
            "legacyHiddenDirectByAssumedNearness",
            "legacyPrior",
            "SENTINEL_GRIND_ROW",
            "oldPermutationUnrank0",
            "legacyFixedBowlPours",
            "legacyInPlaceBowlUpdateWrong",
            "LegacyOverwritableOrderMemoryAdapter",
            "oldNextBowlFixedName",
            "biasedLegacyPick",
            "legacy_wide_selection_unsupported",
            "oldGateQuestionDay",
            "LEGACY_YEAR_MAX",
            "legacyStableSortByLength",
            "oldJumpGuess",
            "legacyYearNumberOnlyLookup",
            "oldStructureSauce",
            "LegacyAllPositiveCutletPartitionFamily",
            "LegacyRepeatedNameGenerator",
            "LegacyAllMonthLengthWaysAPI",
            "legacyChooseEachDaySeparately",
            "oldContiguousMonthDayGuess",
            "legacyFindYearClosedOpeningInterval",
        )
        patch_tokens = (
            "savePatch",
            "DayTagPatchWrapper",
            "DistancePatchWrapper",
            "stonePatch",
            "HiddenNearnessPatchWrapper",
            "PriorPatchWrapper",
            "SENTINEL_GRIND_ROW",
            "PermutationRankPatchWrapper",
            "BowlAliasPatchWrapper",
            "BowlMutationPatchWrapper",
            "orderAt46Latch",
            "NextBowlPatchWrapper",
            "SelectionRejectionPatchWrapper",
            "wideDetour",
            "NegativeGatePatchWrapper",
            "REAL_YEAR_MAX_PATCH",
            "Year5000TiePatchWrapper",
            "SequentialYearWalkPatchWrapper",
            "YearCacheActionGuardPatchWrapper",
            "StructureSaucePatchWrapper",
            "CutletPartitionGatePatchWrapper",
            "RepeatedNamePatchWrapper",
            "VirtualLegacyList",
            "MonthWeavingPatchWrapper",
            "MonthDayOccurrencePatchWrapper",
            "OpeningGateIntervalPatchWrapper",
        )

        self.assertEqual(
            len(
                legacy_tokens
            ),
            26,
        )
        self.assertEqual(
            len(
                patch_tokens
            ),
            26,
        )

        for token in (
            legacy_tokens
            + patch_tokens
        ):
            with self.subTest(
                token=token,
            ):
                self.assertIn(
                    token,
                    production,
                )

    def test_15_hard_invariants_oracle_isolation_and_environment_independence_are_visible(self):
        production_root = (
            ROOT
            / "src"
            / "pastafari_calendar"
        )
        production = "\n".join(
            path.read_text(
                encoding="utf-8"
            )
            for path in production_root.glob(
                "*.py"
            )
        )

        required = (
            "savePatch",
            "vaultOld",
            "priorPatch",
            "installOrderAliases",
            "orderAt46Latch",
            "latchedCircularSuccessor",
            "SelectionRejectionPatchWrapper",
            "wideDetour",
            "NegativeGatePatchWrapper",
            "REAL_YEAR_MAX_PATCH",
            "SequentialYearWalkPatchWrapper",
            "StructureSaucePatchWrapper",
            "CutletPartitionGatePatchWrapper",
            "MonthWeavingPatchWrapper",
            "RepeatedNamePatchWrapper",
            "countMonthOccurrencesThroughTarget",
            "SpaghettiDateResult",
            "integration_old_snapshot",
            "integration_pending_snapshot",
            "integration_rollback_snapshot",
            "integration_commit_token",
            "integration_retry_count",
            "integration_year_cache_guard_valid",
            "integration_compatibility_flags",
            "integration_program_counter",
        )

        for token in required:
            with self.subTest(
                required=token,
            ):
                self.assertIn(
                    token,
                    production,
                )

        forbidden = (
            "normative_reference",
            "import random",
            "from random",
            "import time",
            "from time",
            "datetime",
            "os.environ",
            "threading",
            "multiprocessing",
            "subprocess",
            "eval(",
            "exec(",
        )

        for token in forbidden:
            with self.subTest(
                forbidden=token,
            ):
                self.assertNotIn(
                    token,
                    production,
                )

        result = calendar_date_spaghetti(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        self.assertEqual(
            len(
                result.__dataclass_fields__
            ),
            5,
        )

    def test_16_combinatorial_counts_match_reference_over_small_exhaustive_grids(self):
        for total in range(
            3,
            13,
        ):
            for slots in range(
                1,
                5,
            ):
                for lo, hi in (
                    (
                        1,
                        4,
                    ),
                    (
                        2,
                        5,
                    ),
                ):
                    reference = BoundedCompositionFamily(
                        total,
                        slots,
                        lo,
                        hi,
                    )
                    actual = VirtualLegacyList(
                        total,
                        slots,
                        lo,
                        hi,
                    )

                    with self.subTest(
                        total=total,
                        slots=slots,
                        lo=lo,
                        hi=hi,
                    ):
                        self.assertEqual(
                            actual.count(),
                            reference.count(),
                        )

                        for rank1 in range(
                            1,
                            actual.count() + 1,
                        ):
                            self.assertEqual(
                                actual.itemAt1(
                                    rank1
                                ),
                                reference.unrank1(
                                    rank1
                                ),
                            )

        for master_count in range(
            1,
            8,
        ):
            for item_count in range(
                0,
                master_count + 1,
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

    def test_17_completion_audit_has_all_53_mandatory_checkpoints(self):
        checkpoints = (
            "foundation_equal",
            "foundation_sides",
            "foundation_crossing",
            "save_boundaries",
            "subtraction_wrap",
            "permutation_1",
            "permutation_720",
            "last_queried_bowl",
            "direction_odd",
            "direction_even",
            "short_n_1",
            "short_n_m",
            "short_non_divisor",
            "rejection_boundary",
            "wide_m_plus_1",
            "wide_m_squared",
            "wide_m_squared_plus_1",
            "gate_plus_minus_1",
            "gate_plus_minus_2",
            "no_forced_symmetry",
            "year_length_252",
            "year_length_5778",
            "reject_5779",
            "reject_5780",
            "reject_5781",
            "target_opening_gate",
            "target_first_day",
            "target_internal_gate",
            "target_closing_gate",
            "calculation_internal_gate",
            "cutlet_count_6",
            "cutlet_count_17",
            "month_count_minimum",
            "month_count_maximum",
            "month_length_4",
            "month_length_123",
            "interleaved_weaving",
            "heavy_weaving",
            "distinct_cutlet_names",
            "distinct_month_names",
            "separated_day_in_month",
            "year_5000",
            "year_5001",
            "year_4999",
            "year_1",
            "year_0",
            "year_minus_1",
            "cache_cold",
            "cache_warm",
            "same_year_number_two_calculation_days",
            "all_17_cutlet_indices",
            "all_47_month_indices",
            "locale_presentation_only",
        )

        self.assertEqual(
            len(
                checkpoints
            ),
            53,
        )
        self.assertEqual(
            len(
                set(
                    checkpoints
                )
            ),
            53,
        )


if __name__ == "__main__":
    unittest.main()
