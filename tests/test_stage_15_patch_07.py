import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.legacy_hidden import LegacyHiddenDropAdapter
from pastafari_calendar.legacy_stones import LegacyStoneBuilderAdapter
from pastafari_calendar.legacy_visible_grinds import (
    GRIND_TABLE_WITH_SENTINEL,
    LEGACY_VISIBLE_GRIND_TABLE,
    SENTINEL_GRIND_ROW,
    LegacyVisibleDropBuilderAdapter,
    legacyGrindRow,
)
from pastafari_calendar.monster_bootstrap import MonsterContext
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


class Stage15Patch07Tests(unittest.TestCase):
    def test_legacy_indexing_function_remains_unchanged(self):
        table = (
            (0, 0, 0, 0, 0),
            (1, 2, 3, 4, 0),
            (5, 6, 7, 8, 1),
        )

        self.assertEqual(
            legacyGrindRow(
                table,
                1,
            ),
            table[1],
        )
        self.assertEqual(
            legacyGrindRow(
                table,
                2,
            ),
            table[2],
        )

    def test_patch_table_keeps_sentinel_at_zero_and_real_rows_at_one_through_eleven(self):
        self.assertEqual(
            len(LEGACY_VISIBLE_GRIND_TABLE),
            11,
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
                    GRIND_TABLE_WITH_SENTINEL[grind],
                    VISIBLE_GRINDS[grind - 1],
                )
                self.assertEqual(
                    legacyGrindRow(
                        GRIND_TABLE_WITH_SENTINEL,
                        grind,
                    ),
                    VISIBLE_GRINDS[grind - 1],
                )

    def test_sentinel_is_never_read_by_normal_one_through_eleven_grinds(self):
        with patch(
            "pastafari_calendar.legacy_visible_grinds.legacyGrindRow",
            wraps=legacyGrindRow,
        ) as grind_call:
            ctx = _ready_context(
                FOUNDATION_DAY,
                FOUNDATION_DAY + 3,
            )
            LegacyVisibleDropBuilderAdapter().call(ctx)

        self.assertGreater(
            grind_call.call_count,
            0,
        )

        used_grinds = {
            call.args[1]
            for call in grind_call.call_args_list
        }

        self.assertNotIn(
            0,
            used_grinds,
        )
        self.assertEqual(
            used_grinds,
            set(range(1, 12)),
        )

    def test_full_visible_drop_builder_matches_normative_visible_drops(self):
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
        expected = build_visible_drops(
            counts,
            build_hidden_drops(counts),
        )

        self.assertEqual(
            len(actual),
            len(expected),
        )

        for i in range(1, 47):
            with self.subTest(i=i):
                self.assertEqual(
                    actual[i],
                    expected[i],
                )

    def test_patch_state_is_invocation_local(self):
        first = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        second = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )

        LegacyVisibleDropBuilderAdapter().call(first)

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
            first.legacy_grind_missing_index,
        )
        self.assertEqual(
            first.legacy_grind_rows_applied,
            11,
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

    def test_observability_state_cannot_change_visible_grind_patch(self):
        calculation_day = FOUNDATION_DAY
        target_day = FOUNDATION_DAY + 3

        plain = _ready_context(
            calculation_day,
            target_day,
        )
        noisy = _ready_context(
            calculation_day,
            target_day,
        )

        noisy.logs.extend(
            [
                ("önceden", 1),
                ("önceden", 2),
            ]
        )
        noisy.metrics["yalnızca-gözlem"] = 7070
        noisy.diagnostics.append(
            ("tanı", 15)
        )

        self.assertEqual(
            LegacyVisibleDropBuilderAdapter().call(plain),
            LegacyVisibleDropBuilderAdapter().call(noisy),
        )


if __name__ == "__main__":
    unittest.main()
