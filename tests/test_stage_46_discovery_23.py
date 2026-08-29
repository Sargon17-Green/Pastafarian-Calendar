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
from pastafari_calendar.legacy_month_length_materialization import (
    LEGACY_SAFE_MATERIALIZED_WAYS_CAP,
    LegacyAllMonthLengthWaysAPI,
    LegacyMaterializationTooLargeError,
    LegacyMonthLengthMaterializationAdapter,
    proveLegacyMonthLengthFamilyLowerBound,
)
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from normative_reference import (
    BoundedCompositionFamily,
    FOUNDATION_DAY,
)


def _brute_bounded_compositions(
    total_days: int,
    month_count: int,
    minimum: int = 4,
    maximum: int = 123,
) -> tuple[tuple[int, ...], ...]:
    out = []

    for row in itertools.product(
        range(
            minimum,
            maximum + 1,
        ),
        repeat=month_count,
    ):
        if sum(row) == total_days:
            out.append(
                row
            )

    return tuple(
        out
    )


class Stage46Discovery23Tests(unittest.TestCase):
    def test_small_legacy_list_materialization_matches_force_brute_lexicographic_order(self):
        cases = (
            (12, 3, 4, 5),
            (15, 3, 4, 7),
            (20, 4, 4, 6),
        )

        for total_days, month_count, minimum, maximum in cases:
            with self.subTest(
                total_days=total_days,
                month_count=month_count,
                minimum=minimum,
                maximum=maximum,
            ):
                actual = LegacyAllMonthLengthWaysAPI(
                    safe_cap=10_000,
                ).list_all_ways(
                    total_days,
                    month_count,
                    minimum,
                    maximum,
                )
                expected = _brute_bounded_compositions(
                    total_days,
                    month_count,
                    minimum,
                    maximum,
                )

                self.assertEqual(
                    actual,
                    expected,
                )

    def test_python_lower_bound_proves_huge_family_without_materializing_it(self):
        cases = (
            (300, 10),
            (400, 10),
            (1000, 20),
        )

        for total_days, month_count in cases:
            with self.subTest(
                total_days=total_days,
                month_count=month_count,
            ):
                proof = proveLegacyMonthLengthFamilyLowerBound(
                    total_days,
                    month_count,
                )
                exact = BoundedCompositionFamily(
                    total_days,
                    month_count,
                    4,
                    123,
                ).count()

                self.assertGreater(
                    proof.lower_bound,
                    LEGACY_SAFE_MATERIALIZED_WAYS_CAP,
                )
                self.assertLessEqual(
                    proof.lower_bound,
                    exact,
                )

    def test_huge_proof_is_a_real_cartesian_subfamily_of_legal_month_lengths(self):
        proof = proveLegacyMonthLengthFamilyLowerBound(
            300,
            10,
        )

        self.assertEqual(
            proof.independent_prefix_positions,
            9,
        )

        for prefix_value in (
            proof.prefix_low,
            proof.prefix_high,
        ):
            prefix_sum = (
                prefix_value
                * proof.independent_prefix_positions
            )
            last = (
                proof.total_days
                - prefix_sum
            )

            self.assertTrue(
                4
                <= prefix_value
                <= 123
            )
            self.assertTrue(
                4
                <= last
                <= 123
            )

    def test_legacy_concrete_api_refuses_huge_family_before_oom(self):
        proof = proveLegacyMonthLengthFamilyLowerBound(
            300,
            10,
        )

        self.assertGreater(
            proof.lower_bound,
            LEGACY_SAFE_MATERIALIZED_WAYS_CAP,
        )

        with self.assertRaises(
            LegacyMaterializationTooLargeError
        ):
            LegacyAllMonthLengthWaysAPI().list_all_ways(
                300,
                10,
            )

    def test_legacy_materialization_adapter_is_on_real_calendar_path(self):
        with patch(
            "pastafari_calendar.legacy_month_length_materialization.LegacyMonthLengthMaterializationAdapter.call",
            autospec=True,
            wraps=LegacyMonthLengthMaterializationAdapter.call,
        ) as materialize_call:
            with self.assertRaises(
                StageNotIntegratedError
            ):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                )

        self.assertEqual(
            materialize_call.call_count,
            1,
        )
        self.assertEqual(
            materialize_call.call_args.args[2:],
            (
                300,
                10,
            ),
        )

        ctx = materialize_call.call_args.args[1]

        self.assertTrue(
            ctx.legacy_month_length_materialization_blocked,
        )
        self.assertGreater(
            ctx.legacy_month_length_lower_bound,
            LEGACY_SAFE_MATERIALIZED_WAYS_CAP,
        )
        self.assertIsNone(
            ctx.legacy_month_length_concrete_ways,
        )

    def test_materialization_state_is_invocation_local(self):
        first = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        second = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

        attempt = LegacyMonthLengthMaterializationAdapter().call(
            first,
            300,
            10,
        )

        self.assertTrue(
            attempt.blocked,
        )
        self.assertEqual(
            first.legacy_month_length_materialization_calls,
            1,
        )
        self.assertEqual(
            second.legacy_month_length_materialization_calls,
            0,
        )
        self.assertFalse(
            second.legacy_month_length_materialization_blocked,
        )
        self.assertIsNone(
            second.legacy_month_length_lower_bound,
        )

    def test_virtual_legacy_list_backend_is_not_present_in_discovery(self):
        production = (
            ROOT
            / "src"
            / "pastafari_calendar"
            / "legacy_month_length_materialization.py"
        ).read_text(
            encoding="utf-8"
        )

        forbidden = (
            "VirtualLegacyList",
            "itemAt1",
            "exactDpCount",
            "virtual_backend",
            "patch23_applied",
        )

        for token in forbidden:
            self.assertNotIn(
                token,
                production,
            )

    def test_current_legacy_all_ways_api_cannot_expose_huge_family(self):
        cases = (
            (300, 10),
            (400, 10),
            (1000, 20),
        )

        for total_days, month_count in cases:
            with self.subTest(
                total_days=total_days,
                month_count=month_count,
            ):
                ctx = MonsterContext(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY,
                )
                actual = LegacyMonthLengthMaterializationAdapter().call(
                    ctx,
                    total_days,
                    month_count,
                )
                expected_count = BoundedCompositionFamily(
                    total_days,
                    month_count,
                    4,
                    123,
                ).count()

                self.assertFalse(
                    actual.blocked,
                    msg="Legacy bütün-yollar API concrete materialization gerektirdiği için dev aileyi OOM olmadan expose edemedi",
                )
                self.assertEqual(
                    actual.exposed_count,
                    expected_count,
                )


if __name__ == "__main__":
    unittest.main()
