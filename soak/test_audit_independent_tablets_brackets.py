"""Strict synthetic contracts for the real pinned TABLETS±1 diagnostic."""
import sys
from pathlib import Path
import time
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
from audit_independent_tablets_brackets import (
    STATUS, PROOF_TOTAL_LIMIT, TabletsAuditError, audit_tablets,
)


def constant_gap(_index):
    return 42


def fixture(**kwargs):
    return audit_tablets(
        constant_gap, constant_gap, origin=0, targets=(83, 84, 85),
        max_questions=10, segment_limit=2,
        deadline=time.monotonic() + 5, **kwargs,
    )


class IndependentTabletsBracketTests(unittest.TestCase):
    def test_three_targets_one_unseeded_pass(self):
        r = fixture()
        self.assertEqual(r["status"], STATUS)
        self.assertEqual(r["questions"], 3)
        self.assertEqual([p["gate_index"] for p in r["brackets"]], [2, 2, 3])
        self.assertEqual(len(r["segments"]), 2)
        self.assertEqual([s["end_index"] for s in r["segments"]], [2, 3])
        self.assertFalse(r["checkpoint_seed_used"])
        self.assertFalse(r["full_date_verified"])
        self.assertFalse(r["certifiable"])
        self.assertFalse(r["tablets_date_components_verified"])

    def test_same_gate_brackets_all_three(self):
        r = audit_tablets(constant_gap, constant_gap, origin=0,
                          targets=(1, 2, 3), max_questions=1, segment_limit=1)
        self.assertEqual([p["gate_index"] for p in r["brackets"]], [1, 1, 1])
        self.assertEqual(r["questions"], 1)

    def test_deterministic_trace_and_chain(self):
        a, b = fixture(), fixture()
        self.assertEqual(a["trace_sha256"], b["trace_sha256"])
        self.assertEqual(a["terminal_segment_sha256"],
                         b["terminal_segment_sha256"])
        self.assertEqual(len(a["trace_sha256"]), 64)

    def test_mismatch_fails_closed_at_exact_index(self):
        with self.assertRaisesRegex(TabletsAuditError, "E_TABLETS_MISMATCH_AT_2"):
            audit_tablets(constant_gap, lambda i: 43 if i == 2 else 42,
                          origin=0, targets=(83, 84, 85), max_questions=10)

    def test_invalid_gap_range_fails_closed(self):
        for first, second, error in (
            (lambda i: 41, constant_gap, "E_INDEPENDENT_RANGE_AT_1"),
            (constant_gap, lambda i: 964, "E_SOURCE_RANGE_AT_1"),
            (lambda i: True, constant_gap, "E_INDEPENDENT_RANGE_AT_1"),
        ):
            with self.subTest(error=error):
                with self.assertRaisesRegex(TabletsAuditError, error):
                    audit_tablets(first, second, origin=0, targets=(1, 2, 3))

    def test_insufficient_queries_fail_closed(self):
        with self.assertRaisesRegex(TabletsAuditError, "E_TABLETS_QUERY_BUDGET"):
            audit_tablets(constant_gap, constant_gap, origin=0,
                          targets=(83, 84, 85), max_questions=2)

    def test_geometric_lower_bound_fail_closed(self):
        with self.assertRaisesRegex(TabletsAuditError, "E_TABLETS_GEOMETRY_BUDGET"):
            audit_tablets(constant_gap, constant_gap, origin=0,
                          targets=(999, 1000, 1001), max_questions=1)

    def test_deadline_fail_closed(self):
        with self.assertRaisesRegex(TabletsAuditError, "E_TABLETS_DEADLINE"):
            audit_tablets(constant_gap, constant_gap, origin=0,
                          targets=(1, 2, 3), deadline=time.monotonic() - 1)

    def test_reject_invalid_budget_and_types(self):
        for n in (0, PROOF_TOTAL_LIMIT + 1, True):
            with self.subTest(n=n):
                with self.assertRaisesRegex(TabletsAuditError, "E_TABLETS_BUDGET"):
                    audit_tablets(constant_gap, constant_gap, origin=0,
                                  targets=(1, 2, 3), max_questions=n)
        for size in (0, 8193, True):
            with self.subTest(size=size):
                with self.assertRaisesRegex(TabletsAuditError, "E_TABLETS_BUDGET"):
                    audit_tablets(constant_gap, constant_gap, origin=0,
                                  targets=(1, 2, 3), segment_limit=size)

    def test_reject_ambiguous_targets(self):
        for origin, targets in (
            (True, (1, 2, 3)), (0, [1, 2, 3]), (0, (1, 1, 2)),
            (0, (-1, 1, 2)), (0, (1, 2, True)), (0, (1, 2)),
        ):
            with self.subTest(origin=origin, targets=targets):
                with self.assertRaisesRegex(TabletsAuditError,
                                            "E_TABLETS_TARGET_CONTRACT"):
                    audit_tablets(constant_gap, constant_gap, origin=origin,
                                  targets=targets)


if __name__ == "__main__":
    unittest.main()
