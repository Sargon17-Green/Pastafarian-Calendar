#!/usr/bin/env python3
"""Synthetic gate/date QA only; no real TABLETS certification."""
from __future__ import annotations
from pathlib import Path
import sys
from time import monotonic
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
from tablets_real_independent_five_field_probe import compute, RealProbeError, STATUS

def first(_target, _bowl, _seal, _size):
    return 1

class RealFiveFieldProbeTests(unittest.TestCase):
    def test_full_unseeded_synthetic_three_dates(self):
        requested_a, requested_b = [], []
        def a(index):
            requested_a.append(index)
            return 963
        def b(index):
            requested_b.append(index)
            return 963
        report = compute(a, b, first, deadline=monotonic()+90)
        self.assertEqual(report["status"], STATUS)
        self.assertEqual(report["positive_prefix_questions"], 15345)
        self.assertGreater(report["negative_questions"], 0)
        self.assertGreater(report["forward_extension_questions"], 0)
        self.assertEqual(report["total_unique_gap_questions"], len(requested_a))
        self.assertEqual(requested_a, requested_b)
        self.assertEqual([r["day"] for r in report["rows"]],
                         [-278523,-278522,-278521])
        self.assertTrue(all(len(r["five_fields"]) == 5 for r in report["rows"]))
        self.assertFalse(report["pinned_date_comparison_performed"])
        self.assertFalse(report["full_date_certified"])

    def test_genuine_mismatch_is_rejected_at_first_gate(self):
        with self.assertRaisesRegex(Exception, "MISMATCH_AT_1"):
            compute(lambda _: 963, lambda _: 962, first, deadline=monotonic()+20)

    def test_precondition_fails_closed(self):
        same = lambda _: 963
        with self.assertRaisesRegex(RealProbeError, "E_REAL_PROBE_INPUT"):
            compute(same,same,first,deadline=monotonic()+5)
        with self.assertRaisesRegex(RealProbeError, "E_REAL_PROBE_INPUT"):
            compute(lambda _:963,lambda _:963,first,deadline=monotonic()-1)
        with self.assertRaisesRegex(RealProbeError, "E_REAL_PROBE_INPUT"):
            compute(lambda _:963,lambda _:963,first,deadline=monotonic()+5,
                    segment_limit=8193)

    def test_invalid_rank_not_accepted_as_date(self):
        with self.assertRaises(Exception):
            compute(lambda _: 963,lambda _: 963,lambda *_: 0,
                    deadline=monotonic()+90)

if __name__ == "__main__":
    unittest.main()
