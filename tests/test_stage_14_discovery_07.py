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
from pastafari_calendar.legacy_stones import LegacyStoneBuilderAdapter
from pastafari_calendar.legacy_visible_grinds import (
    GRIND_TABLE_WITH_SENTINEL,
    LEGACY_VISIBLE_GRIND_TABLE,
    SENTINEL_GRIND_ROW,
    LegacyVisibleDropBuilderAdapter,
    legacyGrindRow,
)
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from normative_reference import (
    FOUNDATION_DAY,
    VISIBLE_GRINDS,
    build_hidden_drops,
    build_visible_drops,
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

    return ctx


class Stage14Discovery07Tests(unittest.TestCase):
    def test_legacy_grind_indexing_is_on_the_real_calendar_path(self):
        with patch(
            "pastafari_calendar.legacy_visible_grinds.legacyGrindRow",
            wraps=legacyGrindRow,
        ) as grind_call:
            with self.assertRaises(StageNotIntegratedError):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY,
                )

            self.assertGreater(
                grind_call.call_count,
                0,
            )
            self.assertEqual(
                grind_call.call_args_list[0].args[1],
                1,
            )

    def test_legacy_zero_based_table_remains_and_patch_table_adds_permanent_sentinel(self):
        self.assertEqual(
            len(LEGACY_VISIBLE_GRIND_TABLE),
            11,
        )
        self.assertEqual(
            LEGACY_VISIBLE_GRIND_TABLE[0],
            VISIBLE_GRINDS[0],
        )

        self.assertEqual(
            len(GRIND_TABLE_WITH_SENTINEL),
            12,
        )
        self.assertEqual(
            GRIND_TABLE_WITH_SENTINEL[0],
            SENTINEL_GRIND_ROW,
        )

        for grind in range(1, 12):
            with self.subTest(grind=grind):
                self.assertEqual(
                    legacyGrindRow(
                        GRIND_TABLE_WITH_SENTINEL,
                        grind,
                    ),
                    VISIBLE_GRINDS[grind - 1],
                )

    def test_legacy_visible_drop_state_is_owned_by_one_invocation(self):
        first = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        second = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )

        table = LegacyVisibleDropBuilderAdapter().call(first)

        self.assertIs(
            first.legacy_visible_drop_table,
            table,
        )
        self.assertEqual(
            first.legacy_visible_drop_count,
            46,
        )
        self.assertIsNone(
            first.legacy_grind_missing_index,
        )
        self.assertEqual(
            first.legacy_grind_rows_applied,
            11,
        )
        self.assertTrue(
            first.patch07_sentinel_present,
        )
        self.assertEqual(
            first.patch07_table_length,
            12,
        )
        self.assertTrue(
            first.patch07_applied,
        )

        self.assertIsNone(
            second.legacy_visible_drop_table,
        )
        self.assertEqual(
            second.legacy_visible_drop_count,
            0,
        )
        self.assertIsNone(
            second.legacy_grind_missing_index,
        )
        self.assertEqual(
            second.legacy_grind_rows_applied,
            0,
        )
        self.assertFalse(
            second.patch07_sentinel_present,
        )
        self.assertEqual(
            second.patch07_table_length,
            0,
        )
        self.assertFalse(
            second.patch07_applied,
        )

    def test_current_grind_table_path_diverges_from_normative_visible_drops(self):
        calculation_day = FOUNDATION_DAY
        target_day = FOUNDATION_DAY + 3
        ctx = _ready_context(
            calculation_day,
            target_day,
        )

        actual = LegacyVisibleDropBuilderAdapter().call(ctx)

        counts = work_counts(
            calculation_day,
            target_day,
        )
        hidden = build_hidden_drops(counts)
        expected = build_visible_drops(
            counts,
            hidden,
        )

        for i in (1, 2, 46):
            with self.subTest(i=i):
                self.assertEqual(
                    actual[i],
                    expected[i],
                    msg="Geçerli legacy grind-table yolu normatif görünür damlayla uyuşmadı",
                )


if __name__ == "__main__":
    unittest.main()
