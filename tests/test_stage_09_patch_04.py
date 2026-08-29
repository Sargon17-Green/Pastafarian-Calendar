import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.legacy_stones import (
    LegacyStoneBuilderAdapter,
    cloneStoneState,
    getStoneTableThroughLegacyBuilder,
    mutateStonesWrong,
    stonePatch,
)
from pastafari_calendar.monster_bootstrap import MonsterContext
from normative_reference import (
    FOUNDATION_DAY,
    STONES,
)


class Stage09Patch04Tests(unittest.TestCase):
    def test_stone_patch_matches_normative_rows(self):
        state = {
            "w": 17,
            "b": 29,
            "s": 43,
            "m": 71,
            "r": 101,
        }

        for row in range(2, 47):
            state = stonePatch(row, state)
            with self.subTest(row=row):
                self.assertEqual(
                    tuple(state[key] for key in ("w", "b", "s", "m", "r")),
                    STONES[row],
                )

    def test_wrong_mutator_remains_physically_wrong_and_in_place(self):
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
        self.assertEqual(result["w"], STONES[2][0])
        self.assertNotEqual(result["b"], STONES[2][1])
        self.assertNotEqual(result["s"], STONES[2][2])
        self.assertNotEqual(result["m"], STONES[2][3])
        self.assertNotEqual(result["r"], STONES[2][4])

    def test_stone_patch_really_calls_legacy_on_a_clone(self):
        original = {
            "w": 17,
            "b": 29,
            "s": 43,
            "m": 71,
            "r": 101,
        }
        original_before = cloneStoneState(original)

        with patch(
            "pastafari_calendar.legacy_stones.mutateStonesWrong",
            wraps=mutateStonesWrong,
        ) as legacy_call:
            result = stonePatch(2, original)

            self.assertEqual(legacy_call.call_count, 1)
            legacy_arg = legacy_call.call_args.args[1]
            self.assertIsNot(legacy_arg, original)
            self.assertEqual(original, original_before)
            self.assertEqual(
                tuple(result[key] for key in ("w", "b", "s", "m", "r")),
                STONES[2],
            )

    def test_garbage_is_observed_then_all_five_fields_are_overwritten(self):
        initial = {
            "w": 17,
            "b": 29,
            "s": 43,
            "m": 71,
            "r": 101,
        }
        capture = []

        result = stonePatch(
            2,
            initial,
            capture,
        )

        self.assertEqual(len(capture), 1)
        row, old_snapshot, legacy_garbage, committed = capture[0]

        self.assertEqual(row, 2)
        self.assertEqual(
            old_snapshot,
            STONES[1],
        )
        self.assertNotEqual(
            legacy_garbage,
            STONES[2],
        )
        self.assertEqual(
            committed,
            STONES[2],
        )
        self.assertEqual(
            tuple(result[key] for key in ("w", "b", "s", "m", "r")),
            STONES[2],
        )

        differing_fields = [
            index
            for index, (old_value, new_value)
            in enumerate(zip(legacy_garbage, committed))
            if old_value != new_value
        ]
        self.assertEqual(
            differing_fields,
            [1, 2, 3, 4],
        )

    def test_overwrite_reads_only_old_snapshot_not_garbage(self):
        initial = {
            "w": 17,
            "b": 29,
            "s": 43,
            "m": 71,
            "r": 101,
        }
        fake_garbage = {
            "w": 999_001,
            "b": 999_002,
            "s": 999_003,
            "m": 999_004,
            "r": 999_005,
        }

        with patch(
            "pastafari_calendar.legacy_stones.mutateStonesWrong",
            return_value=cloneStoneState(fake_garbage),
        ) as legacy_call:
            result = stonePatch(2, initial)

        self.assertEqual(legacy_call.call_count, 1)
        self.assertEqual(
            tuple(result[key] for key in ("w", "b", "s", "m", "r")),
            STONES[2],
        )

    def test_full_builder_matches_normative_table(self):
        table = getStoneTableThroughLegacyBuilder()

        self.assertEqual(len(table), 47)
        for row in range(1, 47):
            with self.subTest(row=row):
                self.assertEqual(
                    table[row],
                    STONES[row],
                )

    def test_adapter_keeps_patch_scar_state_invocation_local(self):
        first = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        second = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

        table = LegacyStoneBuilderAdapter().call(first)

        self.assertEqual(
            table[46],
            STONES[46],
        )
        self.assertEqual(
            first.patch04_rows_patched,
            45,
        )
        self.assertEqual(
            first.patch04_last_committed_stones,
            STONES[46],
        )
        self.assertIsNotNone(
            first.patch04_last_old_stones,
        )
        self.assertIsNotNone(
            first.patch04_last_legacy_garbage,
        )
        self.assertNotEqual(
            first.patch04_last_legacy_garbage,
            first.patch04_last_committed_stones,
        )

        self.assertEqual(
            second.patch04_rows_patched,
            0,
        )
        self.assertIsNone(
            second.patch04_last_old_stones,
        )
        self.assertIsNone(
            second.patch04_last_legacy_garbage,
        )
        self.assertIsNone(
            second.patch04_last_committed_stones,
        )

    def test_observability_state_cannot_change_stone_patch_result(self):
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
        noisy.metrics["yalnızca-gözlem"] = 4242
        noisy.diagnostics.append(
            ("tanı", 9)
        )

        self.assertEqual(
            LegacyStoneBuilderAdapter().call(plain),
            LegacyStoneBuilderAdapter().call(noisy),
        )


if __name__ == "__main__":
    unittest.main()
