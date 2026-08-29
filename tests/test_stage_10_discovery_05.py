import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.calendar import calendar_date_spaghetti
from pastafari_calendar.legacy_hidden import (
    LegacyHiddenDropAdapter,
    buildHiddenWithBackwardStorage,
    countsFromContext,
    legacyHiddenDirectByAssumedNearness,
)
from pastafari_calendar.legacy_stones import (
    LegacyStoneBuilderAdapter,
)
from pastafari_calendar.monster_bootstrap import (
    MonsterContext,
    StageNotIntegratedError,
)
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


class Stage10Discovery05Tests(unittest.TestCase):
    def test_backward_hidden_storage_is_on_the_real_calendar_path(self):
        with patch(
            "pastafari_calendar.legacy_hidden.buildHiddenWithBackwardStorage",
            wraps=buildHiddenWithBackwardStorage,
        ) as builder_call, patch(
            "pastafari_calendar.legacy_hidden.legacyHiddenDirectByAssumedNearness",
            wraps=legacyHiddenDirectByAssumedNearness,
        ) as wrong_read:
            with patch(
                "pastafari_calendar.final_integration.FinalSpaghettiIntegrationManager.execute",
                return_value=None,
            ):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY,
                )

            self.assertEqual(
                builder_call.call_count,
                1,
            )
            self.assertEqual(
                wrong_read.call_count,
                1,
            )
            self.assertEqual(
                wrong_read.call_args.args[1],
                1,
            )

    def test_physical_storage_really_is_hidden7_through_hidden1(self):
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

    def test_hidden_storage_state_is_owned_by_one_invocation(self):
        first = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )
        second = _ready_context(
            FOUNDATION_DAY,
            FOUNDATION_DAY + 3,
        )

        adapter = LegacyHiddenDropAdapter()
        storage = adapter.call(first)
        value = adapter.read_by_nearness(
            first,
            1,
        )

        self.assertIs(
            first.legacy_hidden_storage,
            storage,
        )
        self.assertEqual(
            first.legacy_hidden_count,
            7,
        )
        self.assertEqual(
            first.legacy_hidden_last_requested_k,
            1,
        )
        self.assertEqual(
            first.legacy_hidden_last_returned_value,
            value,
        )

        self.assertIsNone(
            second.legacy_hidden_storage,
        )
        self.assertEqual(
            second.legacy_hidden_count,
            0,
        )
        self.assertIsNone(
            second.legacy_hidden_last_requested_k,
        )
        self.assertIsNone(
            second.legacy_hidden_last_returned_value,
        )

    def test_current_hidden_nearness_access_diverges_from_normative_hidden(self):
        calculation_day = FOUNDATION_DAY
        target_day = FOUNDATION_DAY + 3
        ctx = _ready_context(
            calculation_day,
            target_day,
        )

        adapter = LegacyHiddenDropAdapter()
        adapter.call(ctx)

        normative = build_hidden_drops(
            work_counts(
                calculation_day,
                target_day,
            )
        )

        for k in (1, 2, 4, 6, 7):
            with self.subTest(k=k):
                self.assertEqual(
                    adapter.read_by_nearness(
                        ctx,
                        k,
                    ),
                    normative[k],
                    msg="Geçerli gizli damla near-ness erişimi normatif gizli damlayla uyuşmadı",
                )


if __name__ == "__main__":
    unittest.main()
