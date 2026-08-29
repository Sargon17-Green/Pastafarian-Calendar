import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.legacy_gate_question import (
    LegacyGateQuestionAdapter,
    NegativeGatePatchWrapper,
    oldGateQuestionDay,
)
from pastafari_calendar.legacy_visible_grinds import GRIND_TABLE_WITH_SENTINEL
from pastafari_calendar.monster_bootstrap import MonsterContext
from normative_reference import FOUNDATION_DAY


class Stage31Patch15Tests(unittest.TestCase):
    def test_old_gate_helper_remains_physically_positive_side(self):
        self.assertEqual(
            oldGateQuestionDay(1),
            FOUNDATION_DAY + 1,
        )
        self.assertEqual(
            oldGateQuestionDay(10),
            FOUNDATION_DAY + 10,
        )

    def test_negative_wrapper_really_calls_old_helper_then_corrects(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

        with patch(
            "pastafari_calendar.legacy_gate_question.oldGateQuestionDay",
            wraps=oldGateQuestionDay,
        ) as old_call:
            result = NegativeGatePatchWrapper().repair(
                ctx,
                -2,
                2,
            )

        self.assertEqual(
            old_call.call_count,
            1,
        )
        self.assertEqual(
            old_call.call_args.args[0],
            2,
        )
        self.assertEqual(
            ctx.patch15_legacy_positive_day,
            FOUNDATION_DAY + 2,
        )
        self.assertEqual(
            ctx.patch15_corrected_day,
            FOUNDATION_DAY - 2,
        )
        self.assertTrue(
            ctx.patch15_used_negative_detour,
        )
        self.assertTrue(
            ctx.patch15_applied,
        )
        self.assertEqual(
            result,
            FOUNDATION_DAY - 2,
        )

    def test_negative_signed_steps_use_foundation_minus_magnitude(self):
        adapter = LegacyGateQuestionAdapter()

        for signed_step in (
            -1,
            -2,
            -10,
            -101,
        ):
            with self.subTest(
                signed_step=signed_step,
            ):
                ctx = MonsterContext(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY,
                )
                self.assertEqual(
                    adapter.call(
                        ctx,
                        signed_step,
                    ),
                    FOUNDATION_DAY
                    - abs(
                        signed_step,
                    ),
                )
                self.assertTrue(
                    ctx.patch15_used_negative_detour,
                )

    def test_zero_and_positive_steps_stay_on_legacy_result(self):
        adapter = LegacyGateQuestionAdapter()

        for signed_step in (
            0,
            1,
            2,
            10,
        ):
            with self.subTest(
                signed_step=signed_step,
            ):
                ctx = MonsterContext(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY,
                )
                expected = oldGateQuestionDay(
                    abs(
                        signed_step,
                    )
                )
                self.assertEqual(
                    adapter.call(
                        ctx,
                        signed_step,
                    ),
                    expected,
                )
                self.assertFalse(
                    ctx.patch15_used_negative_detour,
                )
                self.assertEqual(
                    ctx.patch15_legacy_positive_day,
                    expected,
                )
                self.assertEqual(
                    ctx.patch15_corrected_day,
                    expected,
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

        LegacyGateQuestionAdapter().call(
            first,
            -10,
        )

        self.assertEqual(
            first.patch15_signed_step,
            -10,
        )
        self.assertIsNotNone(
            first.patch15_legacy_positive_day,
        )
        self.assertIsNotNone(
            first.patch15_corrected_day,
        )
        self.assertTrue(
            first.patch15_used_negative_detour,
        )
        self.assertTrue(
            first.patch15_applied,
        )

        self.assertIsNone(
            second.patch15_signed_step,
        )
        self.assertIsNone(
            second.patch15_legacy_positive_day,
        )
        self.assertIsNone(
            second.patch15_corrected_day,
        )
        self.assertFalse(
            second.patch15_used_negative_detour,
        )
        self.assertFalse(
            second.patch15_applied,
        )

    def test_observability_state_cannot_change_negative_gate_result(self):
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
        noisy.metrics["yalnızca-gözlem"] = 15100
        noisy.diagnostics.append(
            ("tanı", 31)
        )

        adapter = LegacyGateQuestionAdapter()

        self.assertEqual(
            adapter.call(
                plain,
                -10,
            ),
            adapter.call(
                noisy,
                -10,
            ),
        )

    def test_stage15_sentinel_is_still_present(self):
        self.assertEqual(
            len(GRIND_TABLE_WITH_SENTINEL),
            12,
        )


if __name__ == "__main__":
    unittest.main()
