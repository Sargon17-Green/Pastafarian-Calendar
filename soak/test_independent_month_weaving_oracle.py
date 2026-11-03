"""Independent month weaving: exhaustive enumeration and boundary checks."""
from __future__ import annotations
from itertools import product
from math import comb
from pathlib import Path
import sys
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parent))
from independent_month_weaving_oracle import (
    IndependentMonthWeavingOracle, MonthWeavingOracleError, MonthDay,
)

def exhaustive(lengths):
    count = sum(lengths)
    good = []
    for word in product(range(1, len(lengths) + 1), repeat=count):
        if any(word.count(i + 1) != size for i, size in enumerate(lengths)):
            continue
        first = [word.index(i + 1) for i in range(len(lengths))]
        last = [len(word) - 1 - word[::-1].index(i + 1) for i in range(len(lengths))]
        if first == sorted(first) and last == sorted(last):
            good.append(word)
    return good

class MonthWeavingTests(unittest.TestCase):
    def test_exhaustive_lexicographic_and_days(self):
        cases = ((1,), (2,), (1,1), (1,2), (2,1), (2,2),
                 (3,2), (2,3), (1,1,1), (1,2,1), (2,1,2),
                 (2,2,2), (3,1,2), (1,3,1), (3,2,1))
        checked = 0
        for lengths in cases:
            oracle = IndependentMonthWeavingOracle(lengths)
            words = exhaustive(lengths)
            self.assertEqual(oracle.count_all(), len(words), lengths)
            for rank, word in enumerate(words, 1):
                self.assertEqual(oracle.full_word(rank), word, (lengths, rank))
                for offset, expected_id in enumerate(word):
                    actual = oracle.day_at(rank, offset)
                    self.assertEqual(actual.ordinal, expected_id)
                    self.assertEqual(actual.day_in_month, word[:offset+1].count(expected_id))
                    checked += 1
        self.assertGreater(checked, 40)

    def test_two_months_exact_binomial_identity(self):
        for a in (1, 2, 3, 7, 16, 123):
            for b in (1, 2, 5, 11, 123):
                oracle = IndependentMonthWeavingOracle((a, b))
                self.assertEqual(oracle.count_all(), comb(a+b-2, a-1), (a,b))
                for rank in (1, oracle.count_all()):
                    self.assertEqual(oracle.day_at(rank, 0), MonthDay(1,1))
                    self.assertEqual(oracle.day_at(rank, a+b-1), MonthDay(2,b))

    def test_many_months_and_large_bound(self):
        lengths = (123,) * 46 + (120,)
        self.assertEqual(sum(lengths), 5778)
        oracle = IndependentMonthWeavingOracle(lengths)
        self.assertGreater(oracle.count_all(), 1)
        self.assertEqual(oracle.day_at(1, 0), MonthDay(1,1))
        self.assertEqual(len(oracle._suffix), 48)
        self.assertEqual(IndependentMonthWeavingOracle((1,)*47).count_all(), 1)

    def test_47_short_months_first_last_rank(self):
        oracle = IndependentMonthWeavingOracle((4,)*47)
        self.assertGreater(oracle.count_all(), 1)
        self.assertEqual(oracle.day_at(1, 0), MonthDay(1,1))
        self.assertEqual(oracle.day_at(oracle.count_all(), 0), MonthDay(1,1))

    def test_rejection_budgets_and_types(self):
        for values in ((), (True,2), [2,3], (124,), (123,)*47,
                       (0,2), ("2",3)):
            with self.assertRaises(MonthWeavingOracleError):
                IndependentMonthWeavingOracle(values)
        with self.assertRaises(MonthWeavingOracleError):
            IndependentMonthWeavingOracle((2,2),max_states=1)
        instance = IndependentMonthWeavingOracle((2,2),max_branches=1)
        with self.assertRaises(MonthWeavingOracleError):
            instance.day_at(1,3)
        instance = IndependentMonthWeavingOracle((2,2))
        for rank, day in ((0,1),(True,1),(1000,1),(1,-1),(1,True)):
            with self.assertRaises(MonthWeavingOracleError):
                instance.day_at(rank,day)
        with self.assertRaises(MonthWeavingOracleError):
            IndependentMonthWeavingOracle((4,)*47).full_word(1)

if __name__ == "__main__":
    unittest.main()
