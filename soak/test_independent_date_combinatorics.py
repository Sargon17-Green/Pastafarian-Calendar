"""Independent date combinatorics: brute-force enumeration and boundary tests."""
from __future__ import annotations
import itertools
from math import comb, perm
from pathlib import Path
import sys
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parent))
from independent_date_combinatorics import (
    DateCombinatoricsError, count_bounded_compositions,
    unrank_bounded_composition, count_cutlet_partitions,
    unrank_cutlet_partition, unrank_distinct_names, cyclic_rank,
    rank_from_sauce, MODULUS,
)

def positive_compositions(total, slots):
    if slots == 1:
        yield (total,)
    else:
        for first in range(1, total - slots + 2):
            for tail in positive_compositions(total - first, slots - 1):
                yield (first,) + tail

class IndependentDateCombinatoricsTests(unittest.TestCase):
    def test_bounded_coefficients_against_enumeration(self):
        cases = 0
        for count in range(1, 5):
            for lo, hi in ((1, 3), (2, 4)):
                for total in range(count * lo, count * hi + 1):
                    brute = [x for x in itertools.product(range(lo, hi + 1), repeat=count)
                             if sum(x) == total]
                    self.assertEqual(count_bounded_compositions(total, count, lo, hi), len(brute))
                    for rank, expected in enumerate(brute, 1):
                        self.assertEqual(unrank_bounded_composition(total, count, lo, hi, rank), expected)
                        cases += 1
        self.assertGreater(cases, 150)

    def test_cutlet_boundary_against_bruteforce(self):
        cases = 0
        for total in range(4, 12):
            for slots in range(2, min(5, total) + 1):
                brute = list(positive_compositions(total, slots))
                for boundary in (None, 1, total // 2, total - 1):
                    valid = [x for x in brute if boundary is None
                             or boundary in tuple(itertools.accumulate(x[:-1]))]
                    self.assertEqual(count_cutlet_partitions(total, slots, boundary), len(valid))
                    for rank, expected in enumerate(valid, 1):
                        self.assertEqual(unrank_cutlet_partition(total, slots, boundary, rank), expected)
                        cases += 1
        self.assertGreater(cases, 200)

    def test_distinct_names_against_short_permutations(self):
        for n in range(1, 7):
            for k in range(min(n, 4) + 1):
                values = list(itertools.permutations(range(1, n + 1), k))
                self.assertEqual(len(values), perm(n, k))
                for rank, expected in enumerate(values, 1):
                    self.assertEqual(unrank_distinct_names(n, k, rank), expected)

    def test_large_year_5778_and_47_months(self):
        total = count_bounded_compositions(5778, 47, 4, 123)
        self.assertEqual(total, comb(49, 3))
        for rank in (1, total):
            lengths = unrank_bounded_composition(5778, 47, 4, 123, rank)
            self.assertEqual(len(lengths), 47)
            self.assertEqual(sum(lengths), 5778)
            self.assertTrue(all(4 <= v <= 123 for v in lengths))

    def test_cycle_matches_small_modulus_exhaustive_stepping(self):
        comparisons = 0
        for m in range(3, 12):
            for first in range(1, m + 1):
                for step in (-1, 1):
                    for size in range(1, m * m + 1):
                        width, digits = m, 1
                        while width < size:
                            width *= m
                            digits += 1
                        value = 1 + sum(((first - 1 + step * i) % m) * m ** i
                                        for i in range(digits))
                        accepted = (width // size) * size
                        while value > accepted:
                            value = 1 + ((value - 1 + step) % width)
                        self.assertEqual(cyclic_rank(first, step, m, size),
                                         ((value - 1) % size) + 1)
                        comparisons += 1
        self.assertGreater(comparisons, 3000)

    def test_witness_rank_is_deterministic(self):
        class Witness:
            order_at_drop_46 = (3, 1, 4, 2, 6, 5)
            bowls = (0, 11, 17, 23, 29, 31, 37)
        for n in (1, 2, 17, 922, MODULUS - 1, MODULUS, MODULUS + 1):
            a = rank_from_sauce(Witness(), 4, 33, n)
            self.assertEqual(a, rank_from_sauce(Witness(), 4, 33, n))
            self.assertTrue(1 <= a <= n)

    def test_invalid_inputs_fail_closed_even_with_cache(self):
        count_bounded_compositions(10, 1, 1, 2)
        for args in ((-1, 4, 1, 2), (10, 4, 0, 2), (10, True, 1, 2)):
            with self.assertRaises(DateCombinatoricsError):
                count_bounded_compositions(*args)
        with self.assertRaises(DateCombinatoricsError):
            unrank_cutlet_partition(10, 4, 5, 10 ** 8)
        with self.assertRaises(DateCombinatoricsError):
            unrank_distinct_names(47, 47, 0)
        with self.assertRaises(DateCombinatoricsError):
            cyclic_rank(1, True, 17, 3)
        with self.assertRaises(DateCombinatoricsError):
            rank_from_sauce(object(), 1, 10, 7)

if __name__ == "__main__":
    unittest.main()
