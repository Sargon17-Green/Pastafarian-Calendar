#!/usr/bin/env python3
"""v156 20 bounded toy-family/source-byte-lock mutation checks; no native Fct."""
from __future__ import annotations
from itertools import permutations
from math import factorial, prod
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "runner"))
from soak_ada_month_family_divergence_v156 import (
    general_family, two_rail_family, validate_source_files, SOURCE_LOCKS,
    COMPACT_VECTORS, blob_sha
)


class DivergentMonthFamilyTests(unittest.TestCase):
    def test_01_canonical_general_two_months(self):
        self.assertEqual(general_family((2,2)),
                         ((1,1,2,2), (1,2,1,2)))

    def test_02_canonical_ada_two_months(self):
        self.assertEqual(two_rail_family((2,2)), ((1,2,1,2),))

    def test_03_minimal_missing_general_witness(self):
        self.assertEqual(set(general_family((2,2))) -
                         set(two_rail_family((2,2))), {(1,1,2,2)})

    def test_04_general_three_plus_two_expands(self):
        a = set(two_rail_family((3,2)))
        p = set(general_family((3,2)))
        self.assertTrue(a < p)
        self.assertEqual(len(a), 1)

    def test_05_general_two_plus_three_expands(self):
        a = set(two_rail_family((2,3)))
        p = set(general_family((2,3)))
        self.assertTrue(a < p)
        self.assertEqual(len(a), 1)

    def test_06_three_months_expand_beyond_ada(self):
        self.assertTrue(set(two_rail_family((2,2,2))) <
                        set(general_family((2,2,2))))

    def test_07_rail_sequences_have_fixed_open_prefix(self):
        for lengths in COMPACT_VECTORS:
            count=len(lengths)
            rail=tuple(range(1,count+1))
            for seq in two_rail_family(lengths):
                self.assertEqual(seq[:count],rail)

    def test_08_rail_sequences_have_fixed_close_suffix(self):
        for lengths in COMPACT_VECTORS:
            count=len(lengths)
            rail=tuple(range(1,count+1))
            for seq in two_rail_family(lengths):
                self.assertEqual(seq[-count:],rail)

    def test_09_rail_count_matches_multinomial(self):
        for lengths in COMPACT_VECTORS:
            n=sum(lengths)-2*len(lengths)
            count=factorial(n)//prod(factorial(x-2) for x in lengths)
            self.assertEqual(count,len(two_rail_family(lengths)))

    def test_10_rail_is_subset_all_toy_vectors(self):
        for lengths in COMPACT_VECTORS:
            self.assertTrue(set(two_rail_family(lengths)) <
                            set(general_family(lengths)))

    def test_11_general_sequences_preserve_month_multiplicity(self):
        for lengths in COMPACT_VECTORS:
            for seq in general_family(lengths):
                self.assertEqual(tuple(seq.count(i+1) for i in range(len(lengths))),
                                 lengths)

    def test_12_general_sequences_have_ordered_first_occurrences(self):
        for lengths in COMPACT_VECTORS:
            for seq in general_family(lengths):
                first = [seq.index(i+1) for i in range(len(lengths))]
                self.assertEqual(first,sorted(first))

    def test_13_general_sequences_have_ordered_last_occurrences(self):
        for lengths in COMPACT_VECTORS:
            for seq in general_family(lengths):
                last = [len(seq)-1-seq[::-1].index(i+1)
                        for i in range(len(lengths))]
                self.assertEqual(last,sorted(last))

    def test_14_general_zero_day_month_rejected(self):
        with self.assertRaises(ValueError):
            general_family((2,0))

    def test_15_ada_single_day_month_rejected(self):
        with self.assertRaises(ValueError):
            two_rail_family((2,1))

    def test_16_toy_bounded_months_rejected(self):
        with self.assertRaises(ValueError):
            general_family((2,2,2,2))

    def test_17_toy_large_length_rejected(self):
        with self.assertRaises(ValueError):
            two_rail_family((2,10000))

    def test_18_toy_float_length_rejected(self):
        with self.assertRaises(ValueError):
            general_family((2,2.0))

    def test_19_missing_historical_source_rejected(self):
        with self.assertRaises(ValueError):
            validate_source_files({"REF-41": b"fake source"})

    def test_20_consistently_wrong_forged_historical_blob_rejected(self):
        originals={key: b"forged source bytes" for key in SOURCE_LOCKS}
        with self.assertRaisesRegex(ValueError,"historically frozen Git blob"):
            validate_source_files(originals)


if __name__=="__main__":
    unittest.main()
