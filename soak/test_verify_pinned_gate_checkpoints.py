"""Synthetic tests for bounded, fail-closed checkpoint replay."""
import sys
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
from verify_pinned_gate_checkpoints import FOUNDATION_DAY, ProofError, replay

def gap(i):
    return 42 + abs(i) % 3

class ReplayTests(unittest.TestCase):
    def test_positive_checkpoint_digest_determinism(self):
        expected = FOUNDATION_DAY + sum(gap(i) for i in range(1, 7))
        a = replay(6, 6, 2, gap, {0: FOUNDATION_DAY, 6: expected})
        b = replay(6, 6, 2, gap, {0: FOUNDATION_DAY, 6: expected})
        self.assertEqual(a["status"], "PASS_GATE_CHECKPOINT_REPLAY_NOT_CERTIFIED")
        self.assertEqual(a["transcript_sha256"], b["transcript_sha256"])
        self.assertEqual(len(a["chunk_ends"]), 3)
        self.assertFalse(a["certifiable"])
    def test_negative_signed_direction(self):
        expected = FOUNDATION_DAY - sum(gap(-i) for i in range(1, 5))
        a = replay(-4, 4, 3, gap, {0: FOUNDATION_DAY, -4: expected})
        self.assertEqual(a["reached_day"], expected)
        self.assertEqual(a["verified_checkpoint_indices"], [0, -4])
    def test_budget_yields_partial(self):
        a = replay(1024, 3, 2, gap, {0: FOUNDATION_DAY, 1024: -1})
        self.assertEqual(a["status"], "PARTIAL_REPLAY_NOT_CERTIFIED")
        self.assertEqual(a["reached_index"], 3)
        self.assertFalse(a["full_date_verified"])
    def test_poisoned_checkpoint_fails(self):
        with self.assertRaisesRegex(ProofError, "E_CHECKPOINT_MISMATCH_AT_3"):
            replay(3, 3, 2, gap, {0: FOUNDATION_DAY, 3: 7})
    def test_bad_gap_and_origin_fail(self):
        with self.assertRaisesRegex(ProofError, "E_GAP_RANGE_AT_1"):
            replay(1, 1, 1, lambda _: 41, {0: FOUNDATION_DAY})
        with self.assertRaisesRegex(ProofError, "E_FOUNDATION_CHECKPOINT"):
            replay(1, 1, 1, gap, {0: 0})
        with self.assertRaisesRegex(ProofError, "E_TARGET_INDEX"):
            replay(0, 1, 1, gap, {0: FOUNDATION_DAY})
    def test_no_reference_no_pass(self):
        a = replay(3, 3, 1, gap, {0: FOUNDATION_DAY})
        self.assertEqual(a["status"], "PARTIAL_REPLAY_NOT_CERTIFIED")
    def test_expired_deadline(self):
        import time
        a = replay(3, 3, 1, gap, {0: FOUNDATION_DAY, 3: 0},
                   deadline=time.monotonic()-1)
        self.assertEqual(a["steps"], 0)
        self.assertEqual(a["status"], "PARTIAL_REPLAY_NOT_CERTIFIED")

if __name__ == "__main__":
    unittest.main()
