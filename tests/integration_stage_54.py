import sys
import unittest
from dataclasses import astuple
from unittest.mock import patch
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.final_integration import (
    FinalSpaghettiIntegrationManager,
    SpaghettiDateResult,
    integratedDPUnrankLegalWeaving,
    sauceWithScars,
)
from pastafari_calendar.legacy_month_weaving import LegalMonthWeavingDP
from pastafari_calendar.source_language_catalog import SOURCE_LANGUAGE_CATALOG
from normative_reference import (
    FOUNDATION_DAY,
    NormativeCalendar,
    sauce,
)


class Stage54IntegrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.pairs = (
            (
                FOUNDATION_DAY,
                FOUNDATION_DAY,
            ),
            (
                FOUNDATION_DAY,
                FOUNDATION_DAY + 3,
            ),
        )
        oracle = NormativeCalendar()
        cls.expected = {
            str(
                pair
            ): astuple(
                oracle.calendar_date(
                    *pair
                )
            )
            for pair in cls.pairs
        }
        cls.actual = {}
        captured_contexts = []
        original_init = FinalSpaghettiIntegrationManager.__init__

        def capture_init(
            manager,
            ctx,
        ):
            captured_contexts.append(
                ctx
            )
            original_init(
                manager,
                ctx,
            )

        first_pair = cls.pairs[
            0
        ]

        with patch.object(
            FinalSpaghettiIntegrationManager,
            "__init__",
            autospec=True,
            side_effect=capture_init,
        ):
            cls.actual[
                str(
                    first_pair
                )
            ] = astuple(
                calendar_date_spaghetti(
                    *first_pair
                )
            )

        cls.foundation_context = captured_contexts[
            0
        ]

        for pair in cls.pairs[
            1:
        ]:
            cls.actual[
                str(
                    pair
                )
            ] = astuple(
                calendar_date_spaghetti(
                    *pair
                )
            )

    def test_end_to_end_results_match_local_normative_oracle(self):
        for pair in self.pairs:
            with self.subTest(
                pair=pair,
            ):
                self.assertEqual(
                    self.actual[
                        str(
                            pair
                        )
                    ],
                    self.expected[
                        str(
                            pair
                        )
                    ],
                )

    def test_public_result_has_exactly_five_fields_and_source_language_names(self):
        raw = self.actual[
            str(
                self.pairs[
                    0
                ]
            )
        ]
        result = SpaghettiDateResult(
            *raw
        )

        self.assertIsInstance(
            result,
            SpaghettiDateResult,
        )
        self.assertEqual(
            tuple(
                result.__dataclass_fields__
            ),
            (
                "year_number",
                "cutlet_name",
                "day_in_cutlet",
                "month_name",
                "day_in_month",
            ),
        )
        self.assertIn(
            result.cutlet_name,
            tuple(
                entry.text
                for entry in SOURCE_LANGUAGE_CATALOG.cutlets
            ),
        )
        self.assertIn(
            result.month_name,
            tuple(
                entry.text
                for entry in SOURCE_LANGUAGE_CATALOG.months
            ),
        )

    def test_sauce_with_scars_matches_local_normative_sauce(self):
        cases = (
            (
                FOUNDATION_DAY,
                FOUNDATION_DAY,
            ),
            (
                FOUNDATION_DAY,
                FOUNDATION_DAY + 7,
            ),
            (
                FOUNDATION_DAY - 11,
                FOUNDATION_DAY + 23,
            ),
        )

        for calculation_day, target_day in cases:
            with self.subTest(
                calculation_day=calculation_day,
                target_day=target_day,
            ):
                actual = sauceWithScars(
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

    def test_fast_integration_dp_unrank_is_exact_on_small_families(self):
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
            backend = LegalMonthWeavingDP(
                lengths
            )
            total = backend.count()

            for rank1 in ranks:
                if rank1 > total:
                    continue

                with self.subTest(
                    lengths=lengths,
                    rank1=rank1,
                ):
                    self.assertEqual(
                        integratedDPUnrankLegalWeaving(
                            backend,
                            rank1,
                        ),
                        backend.unrank1(
                            rank1
                        ),
                    )

    def test_real_main_path_runs_integration_state_machine_and_transaction_commits(self):
        ctx = self.foundation_context

        self.assertIsNotNone(
            ctx
        )
        self.assertTrue(
            ctx.integration_started,
        )
        self.assertTrue(
            ctx.integration_completed,
        )
        self.assertEqual(
            ctx.integration_status,
            "GREEN",
        )
        self.assertEqual(
            ctx.integration_program_counter,
            "BİTTİ",
        )
        self.assertEqual(
            ctx.integration_last_committed_phase,
            "YAPI",
        )
        self.assertGreaterEqual(
            ctx.integration_commit_token,
            4,
        )
        self.assertIsNotNone(
            ctx.integration_old_snapshot,
        )
        self.assertIsNone(
            ctx.integration_pending_snapshot,
        )
        self.assertEqual(
            ctx.integration_mode,
            "AUTHORITATIVE",
        )
        self.assertGreaterEqual(
            ctx.integration_hook_calls,
            1,
        )

    def test_real_main_path_runs_gate_year_walk_bad_key_guard_and_structure_ghost(self):
        ctx = self.foundation_context

        self.assertGreater(
            ctx.integration_gate_cache_misses,
            0,
        )
        self.assertGreater(
            ctx.integration_gate_questions,
            0,
        )
        self.assertIsNotNone(
            ctx.integration_legacy_jump_guess,
        )
        self.assertIsNotNone(
            ctx.integration_year_walk_visited,
        )
        self.assertTrue(
            ctx.integration_year_cache_guard_valid,
        )
        self.assertGreaterEqual(
            ctx.integration_year_cache_misses,
            1,
        )
        self.assertGreaterEqual(
            ctx.integration_year_cache_hits,
            1,
        )
        self.assertEqual(
            ctx.integration_structure_ghost_target_day,
            FOUNDATION_DAY,
        )
        self.assertIsNotNone(
            ctx.integration_structure_semantic_target_day,
        )

    def test_real_main_path_runs_partition_name_virtual_weaving_and_month_day_detours(self):
        ctx = self.foundation_context

        self.assertIsNotNone(
            ctx.integration_cutlet_raw_partition,
        )
        self.assertIsNotNone(
            ctx.integration_cutlet_semantic_partition,
        )
        self.assertIsNotNone(
            ctx.integration_cutlet_name_indices,
        )
        self.assertEqual(
            len(
                set(
                    ctx.integration_cutlet_name_indices
                )
            ),
            len(
                ctx.integration_cutlet_name_indices
            ),
        )
        self.assertGreater(
            ctx.integration_structure.month_count,
            0,
        )
        self.assertEqual(
            sum(
                ctx.integration_structure.month_lengths
            ),
            (
                ctx.integration_target_year_close_day
                - ctx.integration_target_year_open_day
            ),
        )
        self.assertIsNotNone(
            ctx.integration_month_weaving_ghost,
        )
        self.assertIsNotNone(
            ctx.integration_month_weaving_semantic,
        )
        self.assertEqual(
            len(
                ctx.integration_month_weaving_semantic
            ),
            sum(
                ctx.integration_structure.month_lengths
            ),
        )
        self.assertEqual(
            len(
                set(
                    ctx.integration_month_name_indices
                )
            ),
            len(
                ctx.integration_month_name_indices
            ),
        )
        self.assertIsNotNone(
            ctx.integration_month_day_legacy_guess,
        )
        self.assertIsNotNone(
            ctx.integration_month_day_occurrence_count,
        )
        self.assertEqual(
            ctx.integration_result_five.day_in_month,
            ctx.integration_month_day_occurrence_count,
        )

    def test_all_26_legacy_scars_and_patch_layers_remain_physical(self):
        production = (
            ROOT
            / "src"
            / "pastafari_calendar"
        )

        text = "\n".join(
            path.read_text(
                encoding="utf-8"
            )
            for path in production.glob(
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

        for token in (
            legacy_tokens
            + patch_tokens
        ):
            with self.subTest(
                token=token,
            ):
                self.assertIn(
                    token,
                    text,
                )

    def test_stage54_required_authoritative_components_are_wired_and_stage55_is_absent(self):
        integration = (
            ROOT
            / "src"
            / "pastafari_calendar"
            / "final_integration.py"
        ).read_text(
            encoding="utf-8"
        )
        calendar = (
            ROOT
            / "src"
            / "pastafari_calendar"
            / "calendar.py"
        ).read_text(
            encoding="utf-8"
        )

        required = (
            "def sauceWithScars(",
            "class IntegratedGateCache:",
            "class FinalSpaghettiIntegrationManager:",
            "def year5000(",
            "def findTargetYear(",
            "def _guardedYearCacheRoundTrip(",
            "def buildStructure(",
            "LegacyAllPositiveCutletPartitionFamily",
            "FilteredLegacyCutletPartitionFamily",
            "VirtualLegacyList",
            "_legacyDayByDayWeavingLocal",
            "integratedDPUnrankLegalWeaving",
            "_legacyRepeatedUnrankLocal",
            "partialPermutationUnrank",
            "integration_month_day_legacy_guess",
            "integration_month_day_occurrence_count",
            "SpaghettiDateResult(",
            'integration_program_counter = "YIL_5000"',
            'integration_program_counter = "CACHE"',
            'integration_program_counter = "YAPI"',
            'integration_program_counter = "SONUÇ"',
        )

        for token in required:
            self.assertIn(
                token,
                integration,
            )

        self.assertIn(
            "FinalSpaghettiIntegrationManager",
            calendar,
        )
        self.assertIn(
            "Otuz dokuzuncu aşamada üretim takvim yolu henüz birleştirilmedi",
            calendar,
        )

        forbidden = (
            "Stage55Audit",
            "AŞAMA_55_DENETİM",
            "FINAL_AUDIT_COMPLETE",
        )

        for token in forbidden:
            self.assertNotIn(
                token,
                integration,
            )

    def test_production_does_not_import_test_only_oracle(self):
        production = (
            ROOT
            / "src"
            / "pastafari_calendar"
        )

        for path in production.glob(
            "*.py"
        ):
            self.assertNotIn(
                "normative_reference",
                path.read_text(
                    encoding="utf-8"
                ),
                msg=str(
                    path
                ),
            )


if __name__ == "__main__":
    unittest.main()
