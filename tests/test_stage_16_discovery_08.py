import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.legacy_hidden import LegacyHiddenDropAdapter
from pastafari_calendar.legacy_permutation import (
    LegacyPermutationOrderAdapter,
    legacyOrderFromDropWrong,
    oldPermutationUnrank0,
    patchedOrderFromDrop,
)
from pastafari_calendar.legacy_stones import LegacyStoneBuilderAdapter
from pastafari_calendar.legacy_visible_grinds import (
    LegacyVisibleDropBuilderAdapter,
)
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from normative_reference import (
    FOUNDATION_DAY,
    bowl_order_from_drop,
    permutation_unrank1,
    work_counts,
)


def _ready_context(
    calculation_day: int,
    target_day: int,
) -> MonsterContext:
    ctx = MonsterContext(
        calculation_day,
        target_day,
    )

    counts = work_counts(
        calculation_day,
        target_day,
    )

    ctx.patch02_action_day_tag_value = counts.action
    ctx.patch02_target_day_tag_value = counts.target
    ctx.patch03_distance_value = counts.distance

    LegacyStoneBuilderAdapter().call(ctx)
    LegacyHiddenDropAdapter().call(ctx)
    LegacyVisibleDropBuilderAdapter().call(ctx)

    return ctx


class Stage16Discovery08Tests(unittest.TestCase):
    def test_old_zero_based_unrank_helper_keeps_its_historical_contract(self):
        self.assertEqual(
            oldPermutationUnrank0(
                0,
            ),
            permutation_unrank1(
                1,
                (1, 2, 3, 4, 5, 6),
            ),
        )
        self.assertEqual(
            oldPermutationUnrank0(
                719,
            ),
            permutation_unrank1(
                720,
                (1, 2, 3, 4, 5, 6),
            ),
        )

        with self.assertRaises(ValueError):
            oldPermutationUnrank0(
                720,
            )

    def test_zero_based_unrank_helper_remains_on_the_real_calendar_path(self):
        with patch(
            "pastafari_calendar.legacy_permutation.oldPermutationUnrank0",
            wraps=oldPermutationUnrank0,
        ) as legacy_unrank:
            with self.assertRaises(StageNotIntegratedError):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY,
                )

            self.assertGreater(
                legacy_unrank.call_count,
                0,
            )

    def test_wrong_path_passes_one_based_number_directly_as_rank0(self):
        drop_value = 1

        with patch(
            "pastafari_calendar.legacy_permutation.oldPermutationUnrank0",
            wraps=oldPermutationUnrank0,
        ) as legacy_unrank:
            actual = legacyOrderFromDropWrong(
                drop_value,
            )

        self.assertEqual(
            legacy_unrank.call_count,
            1,
        )
        self.assertEqual(
            legacy_unrank.call_args.args,
            (1,),
        )
        self.assertNotEqual(
            actual,
            bowl_order_from_drop(
                drop_value,
            ),
        )

    def test_order_table_state_is_owned_by_one_invocation(self):
        first = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        second = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )

        table = LegacyPermutationOrderAdapter().build_order_table(
            first,
            first.legacy_visible_drop_table,
        )

        self.assertIs(
            first.legacy_permutation_order_table,
            table,
        )
        self.assertEqual(
            first.legacy_permutation_order_count,
            46,
        )
        self.assertIsNotNone(
            first.legacy_permutation_last_one_based,
        )

        self.assertIsNone(
            second.legacy_permutation_order_table,
        )
        self.assertEqual(
            second.legacy_permutation_order_count,
            0,
        )
        self.assertIsNone(
            second.legacy_permutation_last_one_based,
        )
        self.assertIsNone(
            second.legacy_permutation_last_order,
        )

    def test_current_permutation_rank_path_diverges_from_normative_order(self):
        calculation_day = FOUNDATION_DAY
        target_day = FOUNDATION_DAY + 3
        ctx = _ready_context(
            calculation_day,
            target_day,
        )

        actual = LegacyPermutationOrderAdapter().build_order_table(
            ctx,
            ctx.legacy_visible_drop_table,
        )

        for i in (1, 2, 46):
            with self.subTest(i=i):
                self.assertEqual(
                    actual[i],
                    bowl_order_from_drop(
                        ctx.legacy_visible_drop_table[i],
                    ),
                    msg="Geçerli legacy permütasyon rank yolu normatif kâse sırasıyla uyuşmadı",
                )


if __name__ == "__main__":
    unittest.main()
