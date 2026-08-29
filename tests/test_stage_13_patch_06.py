import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.legacy_hidden import (
    LegacyHiddenDropAdapter,
    hiddenByNearness,
)
from pastafari_calendar.legacy_prior import (
    LegacyPriorAdapter,
    legacyPrior,
    priorPatch,
)
from pastafari_calendar.legacy_stones import LegacyStoneBuilderAdapter
from pastafari_calendar.monster_bootstrap import MonsterContext
from normative_reference import (
    FOUNDATION_DAY,
    build_hidden_drops,
    work_counts,
)


def _ready_context(
    calculation_day: int,
    target_day: int,
) -> MonsterContext:
    ctx = MonsterContext(calculation_day, target_day)
    counts = work_counts(calculation_day, target_day)
    ctx.patch02_action_day_tag_value = counts.action
    ctx.patch02_target_day_tag_value = counts.target
    ctx.patch03_distance_value = counts.distance
    LegacyStoneBuilderAdapter().call(ctx)
    LegacyHiddenDropAdapter().call(ctx)
    return ctx


class Stage13Patch06Tests(unittest.TestCase):
    def test_prior_patch_preserves_visible_branch_through_legacy_prior(self):
        drop_store = {
            1: 101,
            2: 202,
            3: 303,
        }

        with patch(
            "pastafari_calendar.legacy_prior.legacyPrior",
            wraps=legacyPrior,
        ) as legacy_call, patch(
            "pastafari_calendar.legacy_prior.hiddenByNearness",
            wraps=hiddenByNearness,
        ) as hidden_call:
            self.assertEqual(
                priorPatch(
                    drop_store,
                    None,
                    4,
                    1,
                ),
                303,
            )

        self.assertEqual(legacy_call.call_count, 1)
        self.assertEqual(hidden_call.call_count, 0)

    def test_prior_patch_uses_hidden_k_equal_one_minus_slot(self):
        calculation_day = FOUNDATION_DAY
        target_day = FOUNDATION_DAY + 3
        ctx = _ready_context(calculation_day, target_day)
        normative_hidden = build_hidden_drops(
            work_counts(calculation_day, target_day)
        )

        cases = (
            (1, 1, 1),
            (1, 3, 3),
            (1, 7, 7),
            (2, 3, 2),
            (4, 7, 4),
        )

        for i, back, hidden_k in cases:
            with self.subTest(i=i, back=back, hidden_k=hidden_k):
                self.assertEqual(
                    priorPatch(
                        {},
                        ctx.legacy_hidden_storage,
                        i,
                        back,
                    ),
                    normative_hidden[hidden_k],
                )

    def test_hidden_branch_really_calls_hidden_by_nearness_and_not_legacy_prior(self):
        calculation_day = FOUNDATION_DAY
        target_day = FOUNDATION_DAY + 3
        ctx = _ready_context(calculation_day, target_day)

        with patch(
            "pastafari_calendar.legacy_prior.legacyPrior",
            wraps=legacyPrior,
        ) as legacy_call, patch(
            "pastafari_calendar.legacy_prior.hiddenByNearness",
            wraps=hiddenByNearness,
        ) as hidden_call:
            value = priorPatch(
                {},
                ctx.legacy_hidden_storage,
                1,
                7,
            )

        normative_hidden = build_hidden_drops(
            work_counts(calculation_day, target_day)
        )

        self.assertEqual(legacy_call.call_count, 0)
        self.assertEqual(hidden_call.call_count, 1)
        self.assertEqual(hidden_call.call_args.args[1], 7)
        self.assertEqual(value, normative_hidden[7])

    def test_adapter_records_hidden_branch_state_invocation_locally(self):
        calculation_day = FOUNDATION_DAY
        target_day = FOUNDATION_DAY + 3
        first = _ready_context(calculation_day, target_day)
        second = _ready_context(calculation_day, target_day)

        adapter = LegacyPriorAdapter()
        value = adapter.call(first, {}, 1, 3)

        normative_hidden = build_hidden_drops(
            work_counts(calculation_day, target_day)
        )

        self.assertEqual(value, normative_hidden[3])
        self.assertEqual(first.patch06_slot, -2)
        self.assertTrue(first.patch06_used_hidden)
        self.assertEqual(first.patch06_hidden_k, 3)
        self.assertEqual(first.patch06_value, normative_hidden[3])
        self.assertTrue(first.patch06_applied)

        self.assertIsNone(second.patch06_slot)
        self.assertFalse(second.patch06_used_hidden)
        self.assertIsNone(second.patch06_hidden_k)
        self.assertIsNone(second.patch06_value)
        self.assertFalse(second.patch06_applied)

    def test_adapter_visible_branch_does_not_require_hidden_storage(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

        adapter = LegacyPriorAdapter()
        value = adapter.call(
            ctx,
            {
                1: 111,
                2: 222,
            },
            3,
            1,
        )

        self.assertEqual(value, 222)
        self.assertEqual(ctx.patch06_slot, 2)
        self.assertFalse(ctx.patch06_used_hidden)
        self.assertIsNone(ctx.patch06_hidden_k)
        self.assertEqual(ctx.patch06_value, 222)
        self.assertTrue(ctx.patch06_applied)

    def test_hidden_branch_requires_hidden_storage(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )

        with self.assertRaises(RuntimeError):
            LegacyPriorAdapter().call(
                ctx,
                {},
                1,
                1,
            )

        self.assertEqual(ctx.legacy_prior_slot, 0)
        self.assertIsNone(ctx.legacy_prior_value)

    def test_observability_state_cannot_change_prior_patch(self):
        calculation_day = FOUNDATION_DAY
        target_day = FOUNDATION_DAY + 3

        plain = _ready_context(calculation_day, target_day)
        noisy = _ready_context(calculation_day, target_day)

        noisy.logs.extend(
            [
                ("önceden", 1),
                ("önceden", 2),
            ]
        )
        noisy.metrics["yalnızca-gözlem"] = 6060
        noisy.diagnostics.append(("tanı", 13))

        adapter = LegacyPriorAdapter()

        self.assertEqual(
            adapter.call(plain, {}, 1, 7),
            adapter.call(noisy, {}, 1, 7),
        )


if __name__ == "__main__":
    unittest.main()
