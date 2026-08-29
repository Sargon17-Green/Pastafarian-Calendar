import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.legacy_stones import (
    LegacyStoneBuilderAdapter,
    getStoneTableThroughLegacyBuilder,
    mutateStonesWrong,
)
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from normative_reference import (
    FOUNDATION_DAY,
    STONES,
)


class Stage08Discovery04Tests(unittest.TestCase):
    def test_wrong_stone_mutation_is_on_the_real_calendar_path(self):
        with patch(
            "pastafari_calendar.legacy_stones.getStoneTableThroughLegacyBuilder",
            wraps=getStoneTableThroughLegacyBuilder,
        ) as legacy_builder:
            with self.assertRaises(StageNotIntegratedError):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY,
                )

            self.assertEqual(
                legacy_builder.call_count,
                1,
            )

    def test_mutate_stones_wrong_reuses_new_values_in_place(self):
        state = {
            "w": 17,
            "b": 29,
            "s": 43,
            "m": 71,
            "r": 101,
        }
        same_object = state

        result = mutateStonesWrong(2, state)

        self.assertIs(result, same_object)
        self.assertEqual(
            result["w"],
            STONES[2][0],
        )
        self.assertNotEqual(
            result["b"],
            STONES[2][1],
        )
        self.assertNotEqual(
            result["s"],
            STONES[2][2],
        )
        self.assertNotEqual(
            result["m"],
            STONES[2][3],
        )
        self.assertNotEqual(
            result["r"],
            STONES[2][4],
        )

    def test_legacy_stone_state_is_owned_by_one_invocation(self):
        first = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        second = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

        table = LegacyStoneBuilderAdapter().call(first)

        self.assertIs(
            first.legacy_stone_table,
            table,
        )
        self.assertEqual(
            first.legacy_stone_rows_built,
            46,
        )
        self.assertIsNone(
            second.legacy_stone_table,
        )
        self.assertEqual(
            second.legacy_stone_rows_built,
            0,
        )

    def test_current_stone_builder_path_diverges_from_normative_table(self):
        table = LegacyStoneBuilderAdapter().call(
            MonsterContext(
                FOUNDATION_DAY,
                FOUNDATION_DAY,
            )
        )

        for row in (2, 3, 46):
            with self.subTest(row=row):
                self.assertEqual(
                    table[row],
                    STONES[row],
                    msg="Geçerli eski taş builder yolu normatif taş tablosuyla uyuşmadı",
                )


if __name__ == "__main__":
    unittest.main()
