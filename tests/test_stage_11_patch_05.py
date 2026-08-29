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
    buildHiddenWithBackwardStorage,
    countsFromContext,
    hiddenByNearness,
    legacyHiddenDirectByAssumedNearness,
)
from pastafari_calendar.legacy_stones import (
    LegacyStoneBuilderAdapter,
)
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
    return ctx


class Stage11Patch05Tests(unittest.TestCase):
    def test_hidden_by_nearness_matches_normative_hidden_for_all_seven_slots(self):
        calculation_day = FOUNDATION_DAY
        target_day = FOUNDATION_DAY + 3
        ctx = _ready_context(
            calculation_day,
            target_day,
        )

        storage = buildHiddenWithBackwardStorage(
            countsFromContext(ctx),
            ctx.legacy_stone_table,
        )
        normative = build_hidden_drops(
            work_counts(
                calculation_day,
                target_day,
            )
        )

        for k in range(1, 8):
            with self.subTest(k=k):
                self.assertEqual(
                    hiddenByNearness(
                        storage,
                        k,
                    ),
                    normative[k],
                )

    def test_backward_storage_remains_physically_reversed(self):
        calculation_day = FOUNDATION_DAY
        target_day = FOUNDATION_DAY + 3
        ctx = _ready_context(
            calculation_day,
            target_day,
        )

        storage = buildHiddenWithBackwardStorage(
            countsFromContext(ctx),
            ctx.legacy_stone_table,
        )
        normative = build_hidden_drops(
            work_counts(
                calculation_day,
                target_day,
            )
        )

        self.assertEqual(storage[1], normative[7])
        self.assertEqual(storage[2], normative[6])
        self.assertEqual(storage[3], normative[5])
        self.assertEqual(storage[4], normative[4])
        self.assertEqual(storage[5], normative[3])
        self.assertEqual(storage[6], normative[2])
        self.assertEqual(storage[7], normative[1])

    def test_wrong_direct_accessor_remains_physically_wrong(self):
        calculation_day = FOUNDATION_DAY
        target_day = FOUNDATION_DAY + 3
        ctx = _ready_context(
            calculation_day,
            target_day,
        )

        storage = buildHiddenWithBackwardStorage(
            countsFromContext(ctx),
            ctx.legacy_stone_table,
        )
        normative = build_hidden_drops(
            work_counts(
                calculation_day,
                target_day,
            )
        )

        self.assertEqual(
            legacyHiddenDirectByAssumedNearness(
                storage,
                1,
            ),
            normative[7],
        )
        self.assertNotEqual(
            legacyHiddenDirectByAssumedNearness(
                storage,
                1,
            ),
            normative[1],
        )

    def test_patch_wrapper_really_calls_wrong_direct_accessor_before_translation(self):
        calculation_day = FOUNDATION_DAY
        target_day = FOUNDATION_DAY + 3
        ctx = _ready_context(
            calculation_day,
            target_day,
        )
        adapter = LegacyHiddenDropAdapter()
        adapter.call(ctx)

        with patch(
            "pastafari_calendar.legacy_hidden.legacyHiddenDirectByAssumedNearness",
            wraps=legacyHiddenDirectByAssumedNearness,
        ) as legacy_call, patch(
            "pastafari_calendar.legacy_hidden.hiddenByNearness",
            wraps=hiddenByNearness,
        ) as translator_call:
            actual = adapter.read_by_nearness(
                ctx,
                1,
            )

        normative = build_hidden_drops(
            work_counts(
                calculation_day,
                target_day,
            )
        )

        self.assertEqual(
            legacy_call.call_count,
            1,
        )
        self.assertEqual(
            translator_call.call_count,
            1,
        )
        self.assertEqual(
            actual,
            normative[1],
        )
        self.assertEqual(
            ctx.patch05_legacy_direct_value,
            normative[7],
        )
        self.assertEqual(
            ctx.patch05_corrected_value,
            normative[1],
        )
        self.assertEqual(
            ctx.patch05_translated_slot,
            7,
        )
        self.assertTrue(
            ctx.patch05_applied,
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

        adapter = LegacyHiddenDropAdapter()
        adapter.call(first)
        value = adapter.read_by_nearness(
            first,
            2,
        )

        normative = build_hidden_drops(
            work_counts(
                FOUNDATION_DAY,
                FOUNDATION_DAY + 3,
            )
        )

        self.assertEqual(
            value,
            normative[2],
        )
        self.assertEqual(
            first.patch05_requested_k,
            2,
        )
        self.assertEqual(
            first.patch05_translated_slot,
            6,
        )
        self.assertEqual(
            first.patch05_corrected_value,
            normative[2],
        )
        self.assertTrue(
            first.patch05_applied,
        )

        self.assertIsNone(
            second.patch05_requested_k,
        )
        self.assertIsNone(
            second.patch05_translated_slot,
        )
        self.assertIsNone(
            second.patch05_legacy_direct_value,
        )
        self.assertIsNone(
            second.patch05_corrected_value,
        )
        self.assertFalse(
            second.patch05_applied,
        )

    def test_observability_state_cannot_change_hidden_translation(self):
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
        noisy.metrics["yalnızca-gözlem"] = 5151
        noisy.diagnostics.append(
            ("tanı", 11)
        )

        adapter = LegacyHiddenDropAdapter()
        adapter.call(plain)
        adapter.call(noisy)

        self.assertEqual(
            adapter.read_by_nearness(
                plain,
                7,
            ),
            adapter.read_by_nearness(
                noisy,
                7,
            ),
        )


if __name__ == "__main__":
    unittest.main()
