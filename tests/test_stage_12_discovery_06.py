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
)
from pastafari_calendar.legacy_prior import (
    LegacyPriorAdapter,
    legacyPrior,
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
    LegacyHiddenDropAdapter().call(ctx)

    return ctx


class Stage12Discovery06Tests(unittest.TestCase):
    def test_legacy_prior_is_on_the_real_calendar_path(self):
        with patch(
            "pastafari_calendar.legacy_prior.legacyPrior",
            wraps=legacyPrior,
        ) as legacy_call:
            with self.assertRaises(StageNotIntegratedError):
                calendar_date_spaghetti(
                    FOUNDATION_DAY,
                    FOUNDATION_DAY,
                )

            self.assertEqual(
                legacy_call.call_count,
                1,
            )
            self.assertEqual(
                legacy_call.call_args.args[1:],
                (2, 1),
            )

    def test_legacy_prior_still_reads_valid_visible_slots(self):
        drop_store = {
            1: 101,
            2: 202,
            3: 303,
        }
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        adapter = LegacyPriorAdapter()

        self.assertEqual(
            adapter.call(
                ctx,
                drop_store,
                4,
                1,
            ),
            303,
        )
        self.assertEqual(
            adapter.call(
                ctx,
                drop_store,
                4,
                3,
            ),
            101,
        )

    def test_missing_hidden_history_leaves_legacy_state_on_nonpositive_slot(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        adapter = LegacyPriorAdapter()

        with self.assertRaises(KeyError):
            adapter.call(
                ctx,
                {},
                1,
                1,
            )

        self.assertEqual(
            ctx.legacy_prior_i,
            1,
        )
        self.assertEqual(
            ctx.legacy_prior_back,
            1,
        )
        self.assertEqual(
            ctx.legacy_prior_slot,
            0,
        )
        self.assertIsNone(
            ctx.legacy_prior_value,
        )

    def test_current_prior_path_diverges_when_history_should_come_from_hidden(self):
        calculation_day = FOUNDATION_DAY
        target_day = FOUNDATION_DAY + 3
        ctx = _ready_context(
            calculation_day,
            target_day,
        )
        adapter = LegacyPriorAdapter()
        normative_hidden = build_hidden_drops(
            work_counts(
                calculation_day,
                target_day,
            )
        )

        cases = (
            (1, 1, 1),
            (1, 3, 3),
            (1, 7, 7),
        )

        for i, back, hidden_k in cases:
            with self.subTest(
                i=i,
                back=back,
                hidden_k=hidden_k,
            ):
                try:
                    actual = adapter.call(
                        ctx,
                        {},
                        i,
                        back,
                    )
                except KeyError:
                    actual = None

                self.assertEqual(
                    actual,
                    normative_hidden[hidden_k],
                    msg="Geçerli history yolu nonpositive slot için normatif hidden geçmişini bulamadı",
                )


if __name__ == "__main__":
    unittest.main()
