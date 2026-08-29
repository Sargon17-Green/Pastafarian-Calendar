import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.legacy_month_length_materialization import (
    LEGACY_SAFE_MATERIALIZED_WAYS_CAP,
    LegacyAllMonthLengthWaysAPI,
    LegacyMonthLengthMaterializationAdapter,
    MonthLengthVirtualPatchWrapper,
    VirtualLegacyList,
)
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from normative_reference import (
    BoundedCompositionFamily,
    FOUNDATION_DAY,
)


class Stage47Patch23Tests(unittest.TestCase):
    def test_virtual_count_matches_exact_test_only_dp_for_small_and_huge_families(self):
        cases = (
            (12, 3),
            (300, 10),
            (400, 10),
            (1000, 20),
        )

        for total_days, month_count in cases:
            with self.subTest(
                total_days=total_days,
                month_count=month_count,
            ):
                actual = VirtualLegacyList(
                    total_days,
                    month_count,
                ).count()
                expected = BoundedCompositionFamily(
                    total_days,
                    month_count,
                    4,
                    123,
                ).count()

                self.assertEqual(
                    actual,
                    expected,
                )

    def test_virtual_item_at_1_matches_old_concrete_legacy_order_for_small_space(self):
        total_days = 20
        month_count = 4
        old = LegacyAllMonthLengthWaysAPI(
            safe_cap=10_000,
        ).list_all_ways(
            total_days,
            month_count,
            4,
            6,
        )
        virtual = VirtualLegacyList(
            total_days,
            month_count,
            4,
            6,
        )

        self.assertEqual(
            virtual.count(),
            len(
                old
            ),
        )

        for rank1, expected in enumerate(
            old,
            start=1,
        ):
            with self.subTest(
                rank1=rank1,
            ):
                self.assertEqual(
                    virtual.itemAt1(
                        rank1
                    ),
                    expected,
                )

    def test_virtual_item_at_1_matches_test_only_unrank_for_selected_huge_ranks(self):
        cases = (
            (
                300,
                10,
                (
                    1,
                    2,
                    1000,
                    1_000_000,
                ),
            ),
            (
                400,
                10,
                (
                    1,
                    12345,
                    1_000_000,
                ),
            ),
            (
                1000,
                20,
                (
                    1,
                    2,
                    1000,
                ),
            ),
        )

        for total_days, month_count, ranks in cases:
            virtual = VirtualLegacyList(
                total_days,
                month_count,
            )
            reference = BoundedCompositionFamily(
                total_days,
                month_count,
                4,
                123,
            )

            for rank1 in ranks:
                if rank1 > virtual.count():
                    continue

                with self.subTest(
                    total_days=total_days,
                    month_count=month_count,
                    rank1=rank1,
                ):
                    self.assertEqual(
                        virtual.itemAt1(
                            rank1
                        ),
                        reference.unrank1(
                            rank1
                        ),
                    )

    def test_adapter_runs_old_concrete_materializer_before_virtual_patch(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

        with patch(
            "pastafari_calendar.legacy_month_length_materialization.LegacyAllMonthLengthWaysAPI.list_all_ways",
            autospec=True,
            wraps=LegacyAllMonthLengthWaysAPI.list_all_ways,
        ) as old_call, patch(
            "pastafari_calendar.legacy_month_length_materialization.MonthLengthVirtualPatchWrapper.repair",
            autospec=True,
            wraps=MonthLengthVirtualPatchWrapper.repair,
        ) as patch_call:
            actual = LegacyMonthLengthMaterializationAdapter().call(
                ctx,
                300,
                10,
            )

        self.assertEqual(
            old_call.call_count,
            1,
        )
        self.assertEqual(
            patch_call.call_count,
            1,
        )
        self.assertTrue(
            ctx.legacy_month_length_materialization_blocked,
        )
        self.assertTrue(
            ctx.patch23_legacy_materialization_blocked,
        )
        self.assertFalse(
            actual.blocked,
        )
        self.assertTrue(
            ctx.patch23_virtual_backend_active,
        )

        legacy_position = next(
            index
            for index, entry in enumerate(
                ctx.branch_trace
            )
            if entry[0]
            == "ESKİ_AY_UZUNLUĞU_TÜM_YOLLAR_LISTESİ"
        )
        patch_position = next(
            index
            for index, entry in enumerate(
                ctx.branch_trace
            )
            if entry[0]
            == "YAMA_23_SANAL_LEGACY_LIST"
        )

        self.assertLess(
            legacy_position,
            patch_position,
        )

    def test_semantic_attempt_exposes_exact_count_and_item_without_concrete_list(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        actual = LegacyMonthLengthMaterializationAdapter().call(
            ctx,
            300,
            10,
        )
        expected = BoundedCompositionFamily(
            300,
            10,
            4,
            123,
        )

        self.assertFalse(
            actual.blocked,
        )
        self.assertIsNone(
            actual.concrete_ways,
        )
        self.assertIsInstance(
            actual.virtual_backend,
            VirtualLegacyList,
        )
        self.assertEqual(
            actual.exposed_count,
            expected.count(),
        )

        for rank1 in (
            1,
            2,
            1000,
        ):
            self.assertEqual(
                actual.itemAt1(
                    rank1
                ),
                expected.unrank1(
                    rank1
                ),
            )

    def test_small_family_still_runs_concrete_scar_but_semantic_backend_is_virtual(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        actual = LegacyMonthLengthMaterializationAdapter().call(
            ctx,
            20,
            4,
        )

        self.assertFalse(
            ctx.legacy_month_length_materialization_blocked,
        )
        self.assertIsNotNone(
            ctx.legacy_month_length_concrete_ways,
        )
        self.assertGreater(
            ctx.legacy_month_length_materialized_count,
            0,
        )
        self.assertFalse(
            actual.blocked,
        )
        self.assertIsInstance(
            actual.virtual_backend,
            VirtualLegacyList,
        )
        self.assertEqual(
            actual.exposed_count,
            ctx.legacy_month_length_materialized_count,
        )

        for rank1 in range(
            1,
            min(
                actual.exposed_count,
                10,
            )
            + 1,
        ):
            self.assertEqual(
                actual.itemAt1(
                    rank1
                ),
                ctx.legacy_month_length_concrete_ways[
                    rank1 - 1
                ],
            )

    def test_real_calendar_path_keeps_blocked_legacy_scar_but_virtual_semantics(self):
        with patch(
            "pastafari_calendar.legacy_month_length_materialization.MonthLengthVirtualPatchWrapper.repair",
            autospec=True,
            wraps=MonthLengthVirtualPatchWrapper.repair,
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

        ctx = repair_call.call_args.args[1]

        self.assertTrue(
            ctx.legacy_month_length_materialization_blocked,
        )
        self.assertGreater(
            ctx.legacy_month_length_lower_bound,
            LEGACY_SAFE_MATERIALIZED_WAYS_CAP,
        )
        self.assertTrue(
            ctx.patch23_virtual_backend_active,
        )
        self.assertFalse(
            ctx.patch23_semantic_blocked,
        )
        self.assertGreater(
            ctx.patch23_exact_count,
            ctx.legacy_month_length_lower_bound,
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

        LegacyMonthLengthMaterializationAdapter().call(
            first,
            300,
            10,
        )

        self.assertTrue(
            first.patch23_applied,
        )
        self.assertTrue(
            first.patch23_virtual_backend_active,
        )
        self.assertIsNotNone(
            first.patch23_exact_count,
        )

        self.assertFalse(
            second.patch23_applied,
        )
        self.assertFalse(
            second.patch23_virtual_backend_active,
        )
        self.assertIsNone(
            second.patch23_exact_count,
        )

    def test_observability_state_cannot_change_virtual_count_or_item(self):
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
        ] = 23100
        noisy.diagnostics.append(
            ("tanı", 47)
        )

        plain_result = LegacyMonthLengthMaterializationAdapter().call(
            plain,
            300,
            10,
        )
        noisy_result = LegacyMonthLengthMaterializationAdapter().call(
            noisy,
            300,
            10,
        )

        self.assertEqual(
            plain_result.exposed_count,
            noisy_result.exposed_count,
        )

        for rank1 in (
            1,
            100,
            1000,
        ):
            self.assertEqual(
                plain_result.itemAt1(
                    rank1
                ),
                noisy_result.itemAt1(
                    rank1
                ),
            )

    def test_patch25_legacy_and_occurrence_correction_are_present_but_patch26_is_absent(self):
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

        required = (
            "def legacyChooseEachDaySeparately(",
            "def DPUnrankLegalWeaving(",
            "class MonthWeavingPatchWrapper:",
            "patch24_applied",
            "def oldContiguousMonthDayGuess(",
            "def countMonthOccurrencesThroughTarget(",
            "class MonthDayOccurrencePatchWrapper:",
            "patch25_applied",
        )

        for token in required:
            self.assertIn(
                token,
                text,
            )

        forbidden = (
            "OpeningGateIntervalPatchWrapper",
            "patch26_applied",
        )

        for token in forbidden:
            self.assertNotIn(
                token,
                text,
            )


if __name__ == "__main__":
    unittest.main()
