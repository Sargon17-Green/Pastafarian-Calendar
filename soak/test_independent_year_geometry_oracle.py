"""Independent year geometry: exhaustive candidate enumeration and fail-closed tests.

Synthetic gap geometry only. No real TABLETS gap trace and no 3x5 date proof.
"""
from __future__ import annotations
from itertools import product
from pathlib import Path
import sys
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parent))
from independent_year_geometry_oracle import (
    FOUNDATION, GateLedger, IndependentYearGeometry, Year, YearGeometryError,
    MAX_QUESTIONS, MAX_SEGMENT,
)

def synthetic(gaps, *, origin=FOUNDATION):
    """Index-symmetric nonperiodic synthetic widths, explicitly unseeded."""
    def width(i):
        return gaps[(abs(i) - 1) % len(gaps)]
    return GateLedger(origin, -180, 180, width)

def first(_target, _seal, _size):
    return 1

def last(_target, _seal, size):
    return size

class IndependentYearGeometryTests(unittest.TestCase):
    def test_signed_unseeded_ledger_and_exact_gate_search(self):
        calls = []
        g = GateLedger(FOUNDATION, -3, 4, lambda i: calls.append(i) or (41 + abs(i)))
        self.assertEqual(calls, [-1,-2,-3,1,2,3,4])
        self.assertEqual(g.question_count, 7)
        for i in range(-3,5):
            self.assertEqual(g.gate_index(g.day(i)), i)
        self.assertIsNone(g.gate_index(FOUNDATION + 1))

    def test_year5000_candidates_have_ascending_length_then_open(self):
        g = synthetic((42,43,51,61,77,83,91))
        oracle = IndependentYearGeometry(g)
        observed = []
        def chosen(target, seal, size):
            self.assertEqual((target, seal), (FOUNDATION, 10))
            observed.append(size)
            return size
        actual = oracle.year5000(FOUNDATION, chosen)
        possible = []
        for left in range(g.first, g.last + 1):
            for right in range(left + 6, g.last + 1):
                span = g.day(right) - g.day(left)
                if 252 <= span <= 5778 and g.day(left) < FOUNDATION <= g.day(right):
                    possible.append(Year(5000,left,right,g.day(left),g.day(right)))
        possible.sort(key=lambda y: (y.close_day-y.open_day, y.open_day))
        self.assertEqual(observed, [len(possible)])
        self.assertEqual(actual, possible[-1])
        self.assertEqual(oracle.year5000(FOUNDATION, first), possible[0])

    def test_consecutive_forward_backward_years_are_contiguous(self):
        g = synthetic((75, 92, 43, 42))
        x = IndependentYearGeometry(g)
        base = x.year5000(FOUNDATION, first)
        forward = x.next(base, first)
        backward = x.previous(base, last)
        self.assertEqual((forward.open_index, forward.open_day),
                         (base.close_index, base.close_day))
        self.assertEqual((backward.close_index, backward.close_day),
                         (base.open_index, base.open_day))
        self.assertEqual((forward.number, backward.number), (5001, 4999))
        for selected in (forward, backward):
            self.assertGreaterEqual(selected.close_index - selected.open_index, 6)
            self.assertTrue(252 <= selected.close_day - selected.open_day <= 5778)

    def test_find_real_year_transition_boundaries_over_synthetic_gates(self):
        x = IndependentYearGeometry(synthetic((42, 43, 51, 60)), max_transitions=20)
        base = x.year5000(FOUNDATION, first)
        for target in (base.open_day + 1, base.close_day):
            actual, count = x.find(FOUNDATION, target, first)
            self.assertEqual((actual, count), (base,0))
        ahead, count = x.find(FOUNDATION, base.close_day + 1, first)
        self.assertEqual((ahead.number, count), (5001, 1))
        self.assertTrue(ahead.open_day < base.close_day+1 <= ahead.close_day)
        behind, count = x.find(FOUNDATION, base.open_day, first)
        self.assertEqual((behind.number, count), (4999, 1))

    def test_nonuniform_synthetic_shapes_many_selectors(self):
        count = 0
        for sample in ((42,), (963,), (42, 963), (60,90,120), (271,58,375)):
            x = IndependentYearGeometry(synthetic(sample))
            for selector in (first, last):
                year = x.year5000(FOUNDATION, selector)
                x._validate(year)
                self.assertEqual(year.number, 5000)
                self.assertTrue(year.open_day < FOUNDATION <= year.close_day)
                count += 1
        self.assertEqual(count, 10)

    def test_fail_closed_missing_year5000_coverage(self):
        tiny = GateLedger(FOUNDATION, -1, 1, lambda _i: 42)
        with self.assertRaisesRegex(YearGeometryError, 'E_YEAR5000_INCOMPLETE_COVERAGE'):
            IndependentYearGeometry(tiny).year5000(FOUNDATION, first)

    def test_fail_closed_invalid_gap_and_budget(self):
        for bad in (True, 41, 964, '42', 42.0):
            with self.subTest(value=bad), self.assertRaisesRegex(YearGeometryError, 'E_LEDGER_GAP'):
                GateLedger(FOUNDATION, -1, 1, lambda _i: bad)
        for args in ((-1,1,True),(0,100,100),(0,0,2)):
            with self.subTest(args=args), self.assertRaises(YearGeometryError):
                GateLedger(FOUNDATION,args[0],args[1],lambda _i: 42,max_questions=args[2])
        with self.assertRaisesRegex(YearGeometryError, 'E_LEDGER_BUDGET_OR_SHAPE'):
            GateLedger(FOUNDATION,-1,MAX_QUESTIONS,lambda _i: 42)
        with self.assertRaisesRegex(YearGeometryError,'E_LEDGER_BUDGET_OR_SHAPE'):
            GateLedger(FOUNDATION,-1,1,lambda _i: 42,segment_limit=MAX_SEGMENT+1)

    def test_fail_closed_selector_and_exhaustion(self):
        x = IndependentYearGeometry(synthetic((50,)),max_transitions=1)
        for rank in (0, True, 2.0, '1'):
            with self.subTest(rank=rank), self.assertRaisesRegex(YearGeometryError,'E_YEAR_SELECTOR_RANK'):
                x.year5000(FOUNDATION,lambda *_: rank)
        initial = x.year5000(FOUNDATION,first)
        with self.assertRaisesRegex(YearGeometryError,'E_YEAR_TRANSITION_BUDGET'):
            x.find(FOUNDATION,initial.close_day + 10000,first)
        short = IndependentYearGeometry(synthetic((42,)))
        base = short.year5000(FOUNDATION,first)
        # The caller cannot declare the end of a finite ledger to be a year's end.
        bad = Year(5000, 170, 180, short.ledger.day(170),short.ledger.day(180))
        with self.assertRaisesRegex(YearGeometryError,'E_YEAR_FORWARD_LEDGER_INCOMPLETE'):
            short.next(bad,first)

if __name__ == '__main__':
    unittest.main()
