import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.legacy_visible_grinds import GRIND_TABLE_WITH_SENTINEL
from pastafari_calendar.legacy_year_jump import (
    LegacyYearJumpAdapter,
    LegacyYearJumpAnchor,
    SequentialYearWalkPatchWrapper,
    oldJumpGuess,
)
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
from normative_reference import FOUNDATION_DAY


def _anchor() -> LegacyYearJumpAnchor:
    return LegacyYearJumpAnchor(
        number=5000,
        first_day=1,
        open_day=0,
        close_day=10,
    )


class Stage37Patch18Tests(unittest.TestCase):
    def test_old_jump_guess_still_runs_but_is_telemetry_only(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        anchor = _anchor()

        with patch(
            "pastafari_calendar.legacy_year_jump.oldJumpGuess",
            wraps=oldJumpGuess,
        ) as jump_call:
            actual = LegacyYearJumpAdapter().call(
                ctx,
                anchor,
                anchor.close_day + 1,
            )

        self.assertEqual(
            jump_call.call_count,
            1,
        )
        self.assertEqual(
            ctx.patch18_legacy_guess_telemetry,
            oldJumpGuess(
                anchor,
                anchor.close_day + 1,
            ),
        )
        self.assertFalse(
            ctx.legacy_jump_guess_used_as_semantic,
        )
        self.assertTrue(
            ctx.patch18_guess_ignored_for_semantics,
        )
        self.assertEqual(
            actual,
            5001,
        )
        self.assertNotEqual(
            actual,
            ctx.legacy_jump_guess_number,
        )

    def test_forward_walk_calls_next_year_one_year_at_a_time(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        anchor = _anchor()

        chain = {
            5000: LegacyYearJumpAnchor(
                5001,
                11,
                10,
                20,
            ),
            5001: LegacyYearJumpAnchor(
                5002,
                21,
                20,
                35,
            ),
            5002: LegacyYearJumpAnchor(
                5003,
                36,
                35,
                50,
            ),
        }
        calls: list[int] = []

        def next_year(
            known: LegacyYearJumpAnchor,
        ) -> LegacyYearJumpAnchor:
            calls.append(
                known.number
            )
            return chain[
                known.number
            ]

        def previous_year(
            known: LegacyYearJumpAnchor,
        ) -> LegacyYearJumpAnchor:
            raise AssertionError(
                "Forward witness previousYear çağırmamalıdır"
            )

        actual = LegacyYearJumpAdapter().call(
            ctx,
            anchor,
            40,
            next_year=next_year,
            previous_year=previous_year,
        )

        self.assertEqual(
            calls,
            [
                5000,
                5001,
                5002,
            ],
        )
        self.assertEqual(
            ctx.patch18_walk_visited_numbers,
            (
                5000,
                5001,
                5002,
                5003,
            ),
        )
        self.assertEqual(
            ctx.patch18_forward_steps,
            3,
        )
        self.assertEqual(
            ctx.patch18_backward_steps,
            0,
        )
        self.assertEqual(
            actual,
            5003,
        )

    def test_backward_walk_calls_previous_year_one_year_at_a_time(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        anchor = _anchor()

        chain = {
            5000: LegacyYearJumpAnchor(
                4999,
                -14,
                -15,
                0,
            ),
            4999: LegacyYearJumpAnchor(
                4998,
                -24,
                -25,
                -15,
            ),
        }
        calls: list[int] = []

        def next_year(
            known: LegacyYearJumpAnchor,
        ) -> LegacyYearJumpAnchor:
            raise AssertionError(
                "Backward witness nextYear çağırmamalıdır"
            )

        def previous_year(
            known: LegacyYearJumpAnchor,
        ) -> LegacyYearJumpAnchor:
            calls.append(
                known.number
            )
            return chain[
                known.number
            ]

        actual = LegacyYearJumpAdapter().call(
            ctx,
            anchor,
            -20,
            next_year=next_year,
            previous_year=previous_year,
        )

        self.assertEqual(
            calls,
            [
                5000,
                4999,
            ],
        )
        self.assertEqual(
            ctx.patch18_walk_visited_numbers,
            (
                5000,
                4999,
                4998,
            ),
        )
        self.assertEqual(
            ctx.patch18_forward_steps,
            0,
        )
        self.assertEqual(
            ctx.patch18_backward_steps,
            2,
        )
        self.assertEqual(
            actual,
            4998,
        )

    def test_open_gate_belongs_to_previous_year_and_close_gate_stays_current(self):
        anchor = _anchor()
        adapter = LegacyYearJumpAdapter()

        previous = LegacyYearJumpAnchor(
            4999,
            -9,
            -10,
            0,
        )

        on_open = adapter.call(
            MonsterContext(
                FOUNDATION_DAY,
                FOUNDATION_DAY,
            ),
            anchor,
            anchor.open_day,
            previous_year=lambda known: previous,
        )

        on_close = adapter.call(
            MonsterContext(
                FOUNDATION_DAY,
                FOUNDATION_DAY,
            ),
            anchor,
            anchor.close_day,
        )

        self.assertEqual(
            on_open,
            4999,
        )
        self.assertEqual(
            on_close,
            5000,
        )

    def test_wrapper_rejects_next_year_that_skips_a_number(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

        with self.assertRaises(ValueError):
            SequentialYearWalkPatchWrapper().walk(
                ctx,
                _anchor(),
                15,
                lambda known: LegacyYearJumpAnchor(
                    5002,
                    11,
                    10,
                    20,
                ),
                lambda known: known,
            )

    def test_wrapper_rejects_noncontiguous_next_year_boundary(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

        with self.assertRaises(ValueError):
            SequentialYearWalkPatchWrapper().walk(
                ctx,
                _anchor(),
                15,
                lambda known: LegacyYearJumpAnchor(
                    5001,
                    13,
                    12,
                    20,
                ),
                lambda known: known,
            )

    def test_wrapper_rejects_previous_year_that_skips_a_number(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

        with self.assertRaises(ValueError):
            SequentialYearWalkPatchWrapper().walk(
                ctx,
                _anchor(),
                0,
                lambda known: known,
                lambda known: LegacyYearJumpAnchor(
                    4998,
                    -9,
                    -10,
                    0,
                ),
            )

    def test_real_calendar_path_runs_walk_patch_after_legacy_guess(self):
        with patch(
            "pastafari_calendar.legacy_year_jump.oldJumpGuess",
            wraps=oldJumpGuess,
        ) as guess_call, patch(
            "pastafari_calendar.legacy_year_jump.SequentialYearWalkPatchWrapper.walk",
            autospec=True,
            wraps=SequentialYearWalkPatchWrapper.walk,
        ) as walk_call:
            with self.assertRaises(StageNotIntegratedError):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY + 3,
                )

            self.assertEqual(
                guess_call.call_count,
                1,
            )
            self.assertEqual(
                walk_call.call_count,
                1,
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

        LegacyYearJumpAdapter().call(
            first,
            _anchor(),
            5,
        )

        self.assertTrue(
            first.patch18_applied,
        )
        self.assertTrue(
            first.patch18_guess_ignored_for_semantics,
        )
        self.assertEqual(
            first.patch18_walk_visited_numbers,
            (
                5000,
            ),
        )

        self.assertFalse(
            second.patch18_applied,
        )
        self.assertFalse(
            second.patch18_guess_ignored_for_semantics,
        )
        self.assertIsNone(
            second.patch18_walk_visited_numbers,
        )

    def test_observability_state_cannot_change_walk_result(self):
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
                (
                    "önceden",
                    1,
                ),
                (
                    "önceden",
                    2,
                ),
            ]
        )
        noisy.metrics[
            "yalnızca-gözlem"
        ] = 18100
        noisy.diagnostics.append(
            (
                "tanı",
                37,
            )
        )

        anchor = _anchor()

        plain_result = LegacyYearJumpAdapter().call(
            plain,
            anchor,
            5,
        )

        noisy_result = LegacyYearJumpAdapter().call(
            noisy,
            anchor,
            5,
        )

        self.assertEqual(
            plain_result,
            noisy_result,
        )
        self.assertEqual(
            plain.patch18_walk_visited_numbers,
            noisy.patch18_walk_visited_numbers,
        )

    def test_stage15_sentinel_is_still_present(self):
        self.assertEqual(
            len(
                GRIND_TABLE_WITH_SENTINEL
            ),
            12,
        )


if __name__ == "__main__":
    unittest.main()
