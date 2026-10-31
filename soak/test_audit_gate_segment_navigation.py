"""Synthetic, source-independent arithmetic checks; no production certification."""
from pathlib import Path
import sys
import time
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parent))
from audit_gate_segment_navigation import (
    FOUNDATION, TABLETS, GAP_MAX, PRODUCTION_SEGMENT_LIMIT,
    SegmentProofError, locate_unseeded,
)


def periodic_gap(i: int) -> int:
    return 42 + abs(i) % 3


def wide_gap(i: int) -> int:
    return 500 + abs(i) % 3


def wide_position(n: int) -> int:
    count, remainder = divmod(abs(n), 3)
    displacement = 500 * abs(n) + 3 * count + (0, 1, 3)[remainder]
    return FOUNDATION + (1 if n > 0 else -1) * displacement


def independent_position(n: int) -> int:
    # Closed-form independent of the walk: residues 1,2,0 add 1+2+0.
    count, remainder = divmod(abs(n), 3)
    displacement = 42 * abs(n) + 3 * count + (0, 1, 3)[remainder]
    return FOUNDATION + (1 if n > 0 else -1) * displacement


class SegmentNavigationTests(unittest.TestCase):
    def test_positive_boundary_at_8192(self):
        day = independent_position(8192)
        p = locate_unseeded(day, periodic_gap)
        self.assertEqual((p.bracket_index, p.steps, len(p.segments)), (8192, 8192, 1))
        self.assertEqual(p.segments[0].end_day, day)

    def test_positive_crosses_second_segment(self):
        p = locate_unseeded(independent_position(8193), periodic_gap)
        self.assertEqual((p.steps, len(p.segments)), (8193, 2))
        self.assertEqual([s.questions for s in p.segments], [8192, 1])
        self.assertEqual(p.segments[0].end_day, p.segments[1].start_day)

    def test_negative_crosses_second_segment(self):
        p = locate_unseeded(independent_position(-8193), periodic_gap)
        self.assertEqual((p.bracket_index, len(p.segments), p.direction), (-8193, 2, -1))
        self.assertEqual(p.segments[1].first_index, -8193)

    def test_28672_positive_closed_form(self):
        p = locate_unseeded(independent_position(28672), periodic_gap)
        self.assertEqual(p.steps, 28672)
        self.assertEqual([s.questions for s in p.segments], [8192, 8192, 8192, 4096])

    def test_28672_negative_closed_form(self):
        p = locate_unseeded(independent_position(-28672), periodic_gap)
        self.assertEqual((p.steps, p.bracket_index), (28672, -28672))

    def test_tablets_neighborhood_without_checkpoint_seeds(self):
        for day in (TABLETS-1, TABLETS, TABLETS+1):
            p = locate_unseeded(day, wide_gap)
            self.assertGreater(p.steps, 8192)
            self.assertLessEqual(p.steps, 32768)
            self.assertTrue(p.bracket_low <= day <= p.bracket_high)
            self.assertFalse(p.certified)
            self.assertFalse(p.independent_sauce)
            self.assertEqual(p.anchor_checks, ())
            self.assertEqual(p.bracket_high, wide_position(p.steps))
            self.assertEqual(p.bracket_low, wide_position(p.steps-1))

    def test_anchors_are_comparisons_only(self):
        day = independent_position(8200)
        p = locate_unseeded(day, periodic_gap,
                            expected_anchors={0: FOUNDATION, 8192: independent_position(8192)})
        self.assertEqual(p.anchor_checks, (0, 8192))
        self.assertEqual(p.steps, 8200)
        with self.assertRaisesRegex(SegmentProofError, 'E_ANCHOR_MISMATCH_AT_8192'):
            locate_unseeded(day, periodic_gap,
                            expected_anchors={8192: independent_position(8192) + 1})

    def test_global_signed_indices_not_reset_at_segment(self):
        seen = []
        def counted(i):
            seen.append(i)
            return periodic_gap(i)
        locate_unseeded(independent_position(-10), counted, segment_limit=3)
        self.assertEqual(seen, list(range(-1, -11, -1)))

    def test_chain_is_deterministic_and_sensitive(self):
        a = locate_unseeded(independent_position(9000), periodic_gap)
        b = locate_unseeded(independent_position(9000), periodic_gap)
        c = locate_unseeded(independent_position(9000), periodic_gap, segment_limit=4096)
        self.assertEqual(a.segments[-1].chain_sha256, b.segments[-1].chain_sha256)
        self.assertNotEqual(a.segments[-1].chain_sha256, c.segments[-1].chain_sha256)

    def test_nonrange_gap_fails_closed(self):
        for gap in (lambda _: 41, lambda _: 964, lambda _: True, lambda _: 42.0):
            with self.assertRaisesRegex(SegmentProofError, 'E_GAP_RANGE_AT_1'):
                locate_unseeded(FOUNDATION+100, gap)

    def test_timeout_fails_closed(self):
        with self.assertRaisesRegex(SegmentProofError, 'E_NAV_DEADLINE'):
            locate_unseeded(FOUNDATION+100, periodic_gap, deadline=time.monotonic()-1)

    def test_geometry_budget_early_reject(self):
        called = []
        with self.assertRaisesRegex(SegmentProofError, 'E_GEOMETRY_BUDGET'):
            locate_unseeded(FOUNDATION+GAP_MAX*8193, lambda i: called.append(i) or 42,
                            total_limit=8192)
        self.assertEqual(called, [])

    def test_total_budget_fails_closed(self):
        with self.assertRaisesRegex(SegmentProofError, 'E_NAV_TOTAL_BUDGET'):
            locate_unseeded(FOUNDATION+963*100, lambda _: 42, total_limit=100)

    def test_bad_inputs_and_segment_budget(self):
        for day in (FOUNDATION, True, 1.0):
            with self.assertRaisesRegex(SegmentProofError, 'E_TARGET_DAY'):
                locate_unseeded(day, periodic_gap)
        for limit in (0, 8193, True):
            with self.assertRaisesRegex(SegmentProofError, 'E_NAV_BUDGET'):
                locate_unseeded(FOUNDATION+100, periodic_gap, segment_limit=limit)


if __name__ == '__main__':
    unittest.main()
