"""Small, bounded negative/positive evidence before pinned-source CI."""
import sys
from pathlib import Path
import time
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
from audit_independent_gate_segment_real import (
    FOUNDATION, RealSegmentAuditError, STATUS, audit, independent_gap,
)


def synthetic(i):
    return 42 + abs(i) % 3


class IndependentRealSegmentAuditTests(unittest.TestCase):
    def test_small_signed_segments_and_unseeded_reference_anchors(self):
        report = audit(synthetic, synthetic, max_index=9,
                       segment_limit=3, deadline=time.monotonic()+10)
        self.assertEqual(report["status"], STATUS)
        self.assertEqual((report["sample_count"], report["navigation_probes"]),
                         (18, 12))
        self.assertTrue(any(p["segments"] > 1 for p in report["probes"]))
        self.assertFalse(report["checkpoint_seed_used"])
        self.assertFalse(report["certifiable"])

    def test_signed_gap_mismatch_fails_closed(self):
        def corrupted(i):
            return synthetic(i) + int(i == -2)
        with self.assertRaisesRegex(RealSegmentAuditError,
                                    "E_REAL_GAP_MISMATCH_AT_-2"):
            audit(synthetic, corrupted, max_index=9,
                  deadline=time.monotonic()+10)

    def test_out_of_range_gap_fails_closed(self):
        with self.assertRaisesRegex(RealSegmentAuditError,
                                    "E_REAL_GAP_RANGE_AT_-1"):
            audit(lambda i: 41, synthetic, max_index=1,
                  deadline=time.monotonic()+10)

    def test_budget_fails_closed(self):
        for bad in (0, 65, True):
            with self.assertRaisesRegex(RealSegmentAuditError, "E_REAL_AUDIT_BUDGET"):
                audit(synthetic, synthetic, max_index=bad,
                      deadline=time.monotonic()+10)

    def test_deadline_fails_closed(self):
        with self.assertRaisesRegex(RealSegmentAuditError,
                                    "E_REAL_AUDIT_DEADLINE"):
            audit(synthetic, synthetic, max_index=1,
                  deadline=time.monotonic()-1)

    def test_independent_gap_rejects_invalid_signed_indexes(self):
        for bad in (0, 65, -65, True, "1"):
            with self.assertRaisesRegex(RealSegmentAuditError,
                                        "E_REAL_INDEX_BUDGET"):
                independent_gap(bad, deadline=time.monotonic()+1)


if __name__ == "__main__":
    unittest.main()
