"""Finite, synthetic oracle tests; no assertion of production correctness."""
from pathlib import Path
from types import SimpleNamespace
import sys
import time
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parent))
from audit_gate_gap_rank_independence import (
    FOUNDATION_DAY, LIMIT, M, N, ProofError, accepted_answer_closed_form,
    audit, audit_indices, oracle_from_sauce,
)


class PartialRankAuditTests(unittest.TestCase):
    def test_rejection_closed_form_boundary_plus(self):
        self.assertEqual(accepted_answer_closed_form(LIMIT+1, 1), (1, M-LIMIT))
        self.assertEqual(accepted_answer_closed_form(M, 1), (1, 1))

    def test_rejection_closed_form_boundary_minus(self):
        self.assertEqual(accepted_answer_closed_form(LIMIT+1, -1), (LIMIT, 1))
        self.assertEqual(accepted_answer_closed_form(M, -1), (LIMIT, M-LIMIT))

    def test_acceptance_boundary_no_rejections(self):
        self.assertEqual(accepted_answer_closed_form(1, 1), (1, 0))
        self.assertEqual(accepted_answer_closed_form(LIMIT, -1), (LIMIT, 0))

    def test_invalid_ring_rejected(self):
        for args in ((0, 1), (M+1, 1), (1, 0), (True, -1)):
            with self.assertRaises(ProofError):
                accepted_answer_closed_form(*args)

    def test_closed_form_matches_loop_for_small_modulus_analogue(self):
        # Exhaustive independent small-ring proof of the boundary algebra.
        for modulus in (7, 13, 17, 31):
            for size in range(2, modulus):
                limit = modulus//size*size
                for first in range(1, modulus+1):
                    for direction in (-1, 1):
                        a = first
                        k = 0
                        while a > limit:
                            a = 1 + ((a - 1 + direction) % modulus)
                            k += 1
                        if first <= limit:
                            b, j = first, 0
                        elif direction > 0:
                            b, j = 1, modulus-first+1
                        else:
                            b, j = limit, first-limit
                        self.assertEqual((a, k), (b, j))

    def test_oracle_manual_ring_both_successors(self):
        bowls = {i: i*99+7 for i in range(1,7)}
        a = SimpleNamespace(order_at_drop_46=(1,2,3,4,5,6), bowls=bowls)
        b = SimpleNamespace(order_at_drop_46=(4,2,1,6,3,5), bowls=bowls)
        self.assertNotEqual(oracle_from_sauce(a)[0], oracle_from_sauce(b)[0])

    def test_bad_latch_is_fail_closed(self):
        with self.assertRaisesRegex(ProofError, "E_ORACLE_LATCH"):
            oracle_from_sauce(SimpleNamespace(order_at_drop_46=(1,1,2,3,4,5),
                                              bowls={i:10 for i in range(1,7)}))

    def test_negative_index_question_day_direction(self):
        seen = []
        def sauce(foundation, day):
            seen.append((foundation, day))
            return SimpleNamespace(order_at_drop_46=(1,2,3,4,5,6), bowls={i:i+20 for i in range(1,7)})
        gap = oracle_from_sauce(sauce(FOUNDATION_DAY, FOUNDATION_DAY - 7))[0]
        report = audit(lambda i: gap, sauce, (-7,), time.monotonic()+5)
        self.assertEqual(report["negative"], 1)
        self.assertEqual(seen[-1], (FOUNDATION_DAY, FOUNDATION_DAY-7))

    def test_mismatch_raises(self):
        raw = SimpleNamespace(order_at_drop_46=(1,2,3,4,5,6), bowls={i:i+20 for i in range(1,7)})
        expected = oracle_from_sauce(raw)[0]
        with self.assertRaisesRegex(ProofError, "E_GATE_RANK_MISMATCH_AT_1"):
            audit(lambda _: expected+1, lambda _a,_b: raw, (1,), time.monotonic()+5)

    def test_budget_and_timeout(self):
        raw = SimpleNamespace(order_at_drop_46=(1,2,3,4,5,6), bowls={i:i+20 for i in range(1,7)})
        fn = lambda _a,_b: raw
        for ids in ((), (1,1), (0,), (28673,), tuple(range(1,130))):
            with self.assertRaises(ProofError):
                audit(lambda _: 42, fn, ids, time.monotonic()+5)
        with self.assertRaisesRegex(ProofError, "E_ORACLE_TIMEOUT"):
            audit(lambda _: 42, fn, (1,), time.monotonic()-1)

    def test_real_indices_bounded_and_deterministic(self):
        a = audit_indices()
        self.assertTrue(0 < len(a) <= 128)
        self.assertIn(28672, a)
        self.assertIn(-1024, a)
        self.assertEqual(a, audit_indices())


if __name__ == "__main__":
    unittest.main()
