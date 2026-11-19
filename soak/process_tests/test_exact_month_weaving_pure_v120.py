"""v120: pure combinatorial rank/unrank, exhaustive and pinned-source tests.

The original Python source module is loaded ONLY for its MonthWeavingFamily
(no F(c,t), no conversion, no original date procedure invoked).
"""
from __future__ import annotations

from itertools import product
import importlib.util
from math import comb
import os
from pathlib import Path
import sys
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
from exact_month_weaving_pure_v119 import ExactMonthWeaves,brute_words,pure_verdict


class FullFamilyPureMathV120(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source=os.getenv("PASTAFARI_V120_ORIGINAL_PYTHON")
        if not source:
            raise RuntimeError("exact pinned original MonthWeavingFamily source path required")
        path=Path(source)
        code=path.read_text(encoding="utf8")
        if ("class MonthWeavingFamily:" not in code or
            "def unrank1(self, rank1: int)" not in code):
            raise ValueError("frozen original source MonthWeavingFamily missing")
        spec=importlib.util.spec_from_file_location("pinned_month_weave_v120",path)
        if spec is None or spec.loader is None:raise ValueError("cannot import original source")
        module=importlib.util.module_from_spec(spec)
        sys.modules[spec.name]=module
        spec.loader.exec_module(module)
        cls.OriginalFamily=module.MonthWeavingFamily
        cls.OriginalBrute=staticmethod(module.brute_weavings)

    def test_minimum_two_month_full_family(self):
        self.assertEqual(ExactMonthWeaves((2,2)).count(),2)
        self.assertEqual(brute_words((2,2)),((1,1,2,2),(1,2,1,2)))

    def test_4_by_4_has_twenty_not_six(self):
        family=ExactMonthWeaves((4,4))
        self.assertEqual(family.count(),20)
        self.assertEqual(family.unrank1(1),(1,1,1,1,2,2,2,2))
        self.assertEqual(family.rank1((1,1,1,1,2,2,2,2)),1)

    def test_exact_two_month_closed_form_all_lengths_one_through_eight(self):
        for a in range(1,9):
            for b in range(1,9):
                with self.subTest(a=a,b=b):
                    self.assertEqual(ExactMonthWeaves((a,b)).count(),
                                     comb(a+b-2,a-1))

    def test_exhaustive_brute_counts_all_short_families(self):
        for m in range(1,5):
            for lengths in product(range(1,4),repeat=m):
                if sum(lengths)>10:continue
                with self.subTest(lengths=lengths):
                    expected=brute_words(lengths)
                    self.assertEqual(ExactMonthWeaves(lengths).count(),len(expected))

    def test_exhaustive_rank_unrank_all_short_families(self):
        for m in range(1,5):
            for lengths in product(range(1,4),repeat=m):
                if sum(lengths)>10:continue
                family=ExactMonthWeaves(lengths)
                for rank,word in enumerate(brute_words(lengths),1):
                    self.assertEqual(family.unrank1(rank),word)
                    self.assertEqual(family.rank1(word),rank)

    def test_original_python_count_matches_pure_math_all_small_arrays(self):
        for lengths in ((2,2),(4,4),(2,3,4),(1,2,3),
                        (4,4,4),(3,3,3,3),(1,1,1,1)):
            with self.subTest(lengths=lengths):
                self.assertEqual(ExactMonthWeaves(lengths).count(),
                                 self.OriginalFamily(lengths).count())

    def test_original_python_unrank_matches_pure_full_family_small(self):
        for lengths in ((4,4),(2,3,4),(1,2,3),(3,3,3,3)):
            with self.subTest(lengths=lengths):
                candidate=ExactMonthWeaves(lengths)
                original=self.OriginalFamily(lengths)
                self.assertEqual(candidate.count(),original.count())
                for rank in (1,(candidate.count()+1)//2,candidate.count()):
                    self.assertEqual(candidate.unrank1(rank),original.unrank1(rank))

    def test_original_brute_source_matches_independent_exhaustive_oracle(self):
        for lengths in ((2,2),(4,4),(2,2,2),(2,3,4)):
            self.assertEqual(brute_words(lengths),self.OriginalBrute(lengths))

    def test_unrank_zero_overflow_and_nonint_rejected(self):
        f=ExactMonthWeaves((4,4))
        for bad in (0,-1,21,1.0,True):
            with self.subTest(rank=bad),self.assertRaises(ValueError):
                f.unrank1(bad)

    def test_invalid_noncanonical_word_rejected(self):
        f=ExactMonthWeaves((4,4))
        for bad in ((2,2,2,2,1,1,1,1),(1,)*8,(1,2,1),
                    tuple("11221122")):
            with self.subTest(word=bad),self.assertRaises(ValueError):
                f.rank1(bad)

    def test_invalid_length_arrays_rejected(self):
        for bad in ((),(0,1),(-2,2),(2,True),(2,2.0),[2,2]):
            with self.subTest(lengths=bad),self.assertRaises(ValueError):
                ExactMonthWeaves(bad)

    def test_47_month_nontrivial_fast_rank_unrank_10_days_each(self):
        f=ExactMonthWeaves((10,)*47)
        rank=f.count()//2
        word=f.unrank1(rank)
        self.assertEqual(f.rank1(word),rank)
        self.assertEqual(len(word),470)
        self.assertGreater(f.count().bit_length(),1000)

    def test_47_month_maximum_5778_days_exact_count_no_truncation(self):
        f=ExactMonthWeaves((123,)*46+(120,))
        self.assertEqual(f.total,5778)
        self.assertEqual(f.m,47)
        self.assertGreater(f.count().bit_length(),10_000)

    def test_verdict_must_not_claim_calendar_or_soak_credit(self):
        v=pure_verdict()
        self.assertEqual(v["schema"],"PASTAFARI_PURE_EXACT_MONTH_WEAVE_MODEL_V119/1")
        self.assertFalse(v["native_calendar_conversion_executed"])
        self.assertFalse(v["scientific_source_mismatch_resolved"])
        self.assertTrue(v["new_native_soak_dispatch_stopped"])
        self.assertEqual(v["full_original_years_certified"],0)
        self.assertEqual(v["ten_thousand_years_certified"],0)


if __name__=="__main__":
    unittest.main()
