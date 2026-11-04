#!/usr/bin/env python3
"""Focused synthetic contract tests; never count these as real TABLETS witnesses."""
from __future__ import annotations
from pathlib import Path
import sys
import unittest
from time import monotonic

sys.path.insert(0, str(Path(__file__).resolve().parent))
from independent_year_geometry_oracle import FOUNDATION, GateLedger, YearGeometryError
from independent_five_field_date import (
    IndependentDateError, STATUS, date_from_ledger,
    independent_rank, independent_signed_gap,
)

def first(_day, _bowl, _seal, _count):
    return 1

def last_except_year(_day, bowl, _seal, count):
    return 1 if bowl == 1 else count

def synthetic():
    return GateLedger(FOUNDATION, -220, 220, lambda _i: 42)

class IndependentFiveFieldDateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.ledger = synthetic()

    def test_exact_five_fields_across_cutlet_boundary(self):
        # Shortest Year-5000 interval is exactly 6 gates, open index -5.
        # Earliest lex month lengths for 252 days/3 months are 6,123,123.
        left = date_from_ledger(self.ledger, FOUNDATION, FOUNDATION, first)
        right = date_from_ledger(self.ledger, FOUNDATION, FOUNDATION+1, first)
        self.assertEqual(left, (5000, 5, 42, 3, 81))
        self.assertEqual(right, (5000, 6, 1, 3, 82))
        self.assertEqual(len(left), 5)

    def test_year_boundary_forward_and_backward(self):
        before = date_from_ledger(self.ledger, FOUNDATION, FOUNDATION-210, first)
        after = date_from_ledger(self.ledger, FOUNDATION, FOUNDATION+43, first)
        self.assertEqual(before[0], 4999)
        self.assertEqual(after[0], 5001)
        for output in (before, after):
            self.assertTrue(1 <= output[1] <= 17)
            self.assertTrue(1 <= output[3] <= 47)

    def test_nonfirst_rank_and_component_ranges(self):
        for day in (FOUNDATION-1, FOUNDATION, FOUNDATION+1):
            got = date_from_ledger(self.ledger, FOUNDATION, day, last_except_year)
            self.assertEqual(len(got), 5)
            self.assertTrue(all(type(v) is int for v in got))
            self.assertTrue(1 <= got[1] <= 17 and 1 <= got[3] <= 47)
            self.assertTrue(1 <= got[4] <= 123)

    def test_malformed_rank_rejected(self):
        for bad in (0, True, 1.0, "1", -1):
            with self.subTest(bad=bad), self.assertRaisesRegex(
                IndependentDateError, "E_DATE_RANK"
            ):
                date_from_ledger(self.ledger, FOUNDATION, FOUNDATION,
                                 lambda *_: bad)

    def test_missing_ledger_is_fail_closed(self):
        tiny = GateLedger(FOUNDATION, -1, 1, lambda _i: 42)
        with self.assertRaisesRegex(YearGeometryError, "E_YEAR5000_INCOMPLETE"):
            date_from_ledger(tiny, FOUNDATION, FOUNDATION, first)

    def test_invalid_origin_and_expired_deadline(self):
        with self.assertRaisesRegex(IndependentDateError, "E_DATE_INPUT"):
            date_from_ledger(self.ledger, FOUNDATION+1, FOUNDATION, first)
        with self.assertRaisesRegex(IndependentDateError, "E_DATE_INPUT"):
            date_from_ledger(self.ledger, True, FOUNDATION, first)
        with self.assertRaisesRegex(IndependentDateError, "E_DATE_INPUT"):
            date_from_ledger(self.ledger, FOUNDATION, FOUNDATION, first,
                             deadline=monotonic()-1)

    def test_signed_index_and_explicit_uncertified_contract(self):
        with self.assertRaisesRegex(IndependentDateError, "E_DATE_GATE_INDEX"):
            independent_signed_gap(0)
        with self.assertRaisesRegex(IndependentDateError, "E_DATE_GATE_INDEX"):
            independent_signed_gap(True)
        with self.assertRaisesRegex(IndependentDateError, "E_DATE_ORIGIN"):
            independent_rank(FOUNDATION+1)
        self.assertIn("NOT_CERTIFIED", STATUS)

if __name__ == "__main__":
    unittest.main()
