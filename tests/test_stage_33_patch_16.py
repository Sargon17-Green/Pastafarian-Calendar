import inspect
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from pastafari_calendar.legacy_day_counts import FOUNDATION_DAY_OLD
from pastafari_calendar.legacy_selection import LegacyAnswerRing
from pastafari_calendar.legacy_visible_grinds import GRIND_TABLE_WITH_SENTINEL
from pastafari_calendar.legacy_year_candidates import (
    LEGACY_YEAR_MAX,
    REAL_YEAR_MAX_PATCH,
    LegacyYearCandidate,
    LegacyYearCandidateAdapter,
    YearMaxPatchWrapper,
    legacyYearCandidateAllowed,
)
from pastafari_calendar.monster_bootstrap import MonsterContext
from normative_reference import FOUNDATION_DAY


def _candidate(
    length: int,
    label: str | None = None,
) -> LegacyYearCandidate:
    return LegacyYearCandidate(
        label=label or f"aday-{length}",
        length=length,
        open_day=FOUNDATION_DAY_OLD - length,
        close_day=FOUNDATION_DAY_OLD,
        gate_gap_count=6,
    )


class Stage33Patch16Tests(unittest.TestCase):
    def test_legacy_5781_constant_remains_and_real_patch_constant_is_5778(self):
        self.assertEqual(
            LEGACY_YEAR_MAX,
            5781,
        )
        self.assertEqual(
            REAL_YEAR_MAX_PATCH,
            5778,
        )

    def test_patch_wrapper_really_calls_legacy_acceptance_before_overlong_reject(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        wrapper = YearMaxPatchWrapper()

        ctx.patch16_legacy_accepted_lengths = ()
        ctx.patch16_rejected_overlong_lengths = ()
        ctx.patch16_semantic_accepted_lengths = ()

        with patch(
            "pastafari_calendar.legacy_year_candidates.legacyYearCandidateAllowed",
            wraps=legacyYearCandidateAllowed,
        ) as legacy_call:
            actual = wrapper.accept_after_legacy(
                ctx,
                _candidate(
                    5781,
                ),
            )

        self.assertEqual(
            legacy_call.call_count,
            1,
        )
        self.assertTrue(
            legacy_call.return_value,
        )
        self.assertFalse(
            actual,
        )
        self.assertEqual(
            ctx.patch16_legacy_accepted_lengths,
            (
                5781,
            ),
        )
        self.assertEqual(
            ctx.patch16_rejected_overlong_lengths,
            (
                5781,
            ),
        )
        self.assertEqual(
            ctx.patch16_semantic_accepted_lengths,
            (),
        )

    def test_boundary_family_is_filtered_before_sort_input(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        adapter = LegacyYearCandidateAdapter()

        prepared = adapter.prepare_for_selection(
            ctx,
            (
                _candidate(5781),
                _candidate(5778),
                _candidate(5780),
                _candidate(5779),
            ),
        )

        self.assertEqual(
            ctx.patch16_legacy_accepted_lengths,
            (
                5781,
                5778,
                5780,
                5779,
            ),
        )
        self.assertEqual(
            ctx.patch16_rejected_overlong_lengths,
            (
                5781,
                5780,
                5779,
            ),
        )
        self.assertEqual(
            ctx.legacy_year_candidate_lengths_before_sort,
            (
                5778,
            ),
        )
        self.assertEqual(
            tuple(
                candidate.length
                for candidate in prepared
            ),
            (
                5778,
            ),
        )

    def test_filter_is_structurally_before_stable_sort(self):
        source = inspect.getsource(
            LegacyYearCandidateAdapter.prepare_for_selection,
        )

        filter_position = source.index(
            "self.patch_wrapper.accept_after_legacy"
        )
        sort_position = source.index(
            "accepted.sort"
        )

        self.assertLess(
            filter_position,
            sort_position,
        )

    def test_selection_never_receives_overlong_candidates(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        adapter = LegacyYearCandidateAdapter()
        ring = LegacyAnswerRing(
            first=1,
            direction_step=1,
        )

        with patch.object(
            adapter.selection,
            "call_with_ring",
            wraps=adapter.selection.call_with_ring,
        ) as selection_call:
            selected = adapter.select(
                ctx,
                ring,
                (
                    _candidate(
                        5781,
                        "çok-uzun",
                    ),
                    _candidate(
                        5778,
                        "gerçek",
                    ),
                    _candidate(
                        5779,
                        "uzun",
                    ),
                ),
            )

        self.assertEqual(
            selection_call.call_count,
            1,
        )
        self.assertEqual(
            selection_call.call_args.args[2],
            1,
        )
        self.assertEqual(
            ctx.legacy_year_candidate_lengths_after_sort,
            (
                5778,
            ),
        )
        self.assertEqual(
            selected.length,
            5778,
        )
        self.assertEqual(
            selected.label,
            "gerçek",
        )

    def test_exact_5778_is_kept_while_5779_is_rejected(self):
        ctx = MonsterContext(
            FOUNDATION_DAY,
            FOUNDATION_DAY,
        )
        adapter = LegacyYearCandidateAdapter()

        prepared = adapter.prepare_for_selection(
            ctx,
            (
                _candidate(5778),
                _candidate(5779),
            ),
        )

        self.assertEqual(
            tuple(
                candidate.length
                for candidate in prepared
            ),
            (
                5778,
            ),
        )
        self.assertEqual(
            ctx.patch16_rejected_overlong_lengths,
            (
                5779,
            ),
        )

    def test_legacy_ceiling_behavior_is_still_physically_observable(self):
        for length in (
            5779,
            5780,
            5781,
        ):
            with self.subTest(
                length=length,
            ):
                self.assertTrue(
                    legacyYearCandidateAllowed(
                        _candidate(
                            length,
                        )
                    )
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

        LegacyYearCandidateAdapter().prepare_for_selection(
            first,
            (
                _candidate(5778),
                _candidate(5781),
            ),
        )

        self.assertEqual(
            first.patch16_legacy_accepted_lengths,
            (
                5778,
                5781,
            ),
        )
        self.assertEqual(
            first.patch16_rejected_overlong_lengths,
            (
                5781,
            ),
        )
        self.assertEqual(
            first.patch16_semantic_accepted_lengths,
            (
                5778,
            ),
        )
        self.assertEqual(
            first.patch16_filter_evaluations,
            2,
        )
        self.assertTrue(
            first.patch16_applied,
        )

        self.assertIsNone(
            second.patch16_legacy_accepted_lengths,
        )
        self.assertIsNone(
            second.patch16_rejected_overlong_lengths,
        )
        self.assertIsNone(
            second.patch16_semantic_accepted_lengths,
        )
        self.assertEqual(
            second.patch16_filter_evaluations,
            0,
        )
        self.assertFalse(
            second.patch16_applied,
        )

    def test_observability_state_cannot_change_year_max_filter(self):
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
        noisy.metrics["yalnızca-gözlem"] = 16100
        noisy.diagnostics.append(
            ("tanı", 33)
        )

        candidates = (
            _candidate(5778),
            _candidate(5779),
            _candidate(5781),
        )

        plain_result = LegacyYearCandidateAdapter().prepare_for_selection(
            plain,
            candidates,
        )
        noisy_result = LegacyYearCandidateAdapter().prepare_for_selection(
            noisy,
            candidates,
        )

        self.assertEqual(
            plain_result,
            noisy_result,
        )
        self.assertEqual(
            plain.patch16_rejected_overlong_lengths,
            noisy.patch16_rejected_overlong_lengths,
        )

    def test_stage15_sentinel_is_still_present(self):
        self.assertEqual(
            len(GRIND_TABLE_WITH_SENTINEL),
            12,
        )


if __name__ == "__main__":
    unittest.main()
