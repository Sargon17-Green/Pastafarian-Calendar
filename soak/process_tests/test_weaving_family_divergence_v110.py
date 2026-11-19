"""v110 mathematical regression: original source admissible month-weave families."""
from __future__ import annotations
from pathlib import Path
import sys
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
import audit_weaving_family_divergence_v110 as v


class StaticOriginalWeaveDivergence(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.ada_month=("function From_Choices\nfunction Canonical_Weave_Count\n"
                       "Output (Pos) := J;\nTotal - 2 * Lengths'Length")
        cls.ada_calendar=("function Choose_Month_Weaving\n"
                          "Month_Weaving.From_Choices (Lengths, Tickets)\n"
                          "Answer_At (Stream, B (I - 1))")
        cls.python=("class MonthWeavingFamily:\ndef _moves(\n"
                    "def choose_month_weaving(\nreturn family.unrank1(rank)")

    def test_two_by_two_python_family_has_two(self):
        self.assertEqual(v.canonical_weaves((2,2)),{(1,1,2,2),(1,2,1,2)})

    def test_two_by_two_ada_rail_only_one(self):
        self.assertEqual(v.ada_rails((2,2)),{(1,2,1,2)})

    def test_four_by_four_python_family_twenty(self):
        self.assertEqual(len(v.canonical_weaves((4,4))),20)

    def test_four_by_four_ada_fixed_rails_six(self):
        self.assertEqual(len(v.ada_rails((4,4))),6)

    def test_ada_fixed_rails_is_strict_subset(self):
        x=v.canonical_weaves((4,4)); y=v.ada_rails((4,4))
        self.assertTrue(y<x)
        self.assertEqual(len(x-y),14)

    def test_open_before_next_close_is_valid_python_not_ada(self):
        seq=(1,1,1,1,2,2,2,2)
        self.assertIn(seq,v.canonical_weaves((4,4)))
        self.assertNotIn(seq,v.ada_rails((4,4)))

    def test_static_source_signature_requires_global_rank(self):
        v.source_contract(self.ada_month,self.ada_calendar,self.python)
        with self.assertRaisesRegex(ValueError,"skeleton"):
            v.source_contract(self.ada_month,self.ada_calendar,
                              self.python.replace("return family.unrank1(rank)","return 0"))

    def test_static_source_signature_requires_local_tickets(self):
        with self.assertRaisesRegex(ValueError,"skeleton"):
            v.source_contract(self.ada_month,self.ada_calendar.replace(
                "Answer_At (Stream, B (I - 1))","Answer_At(Stream,B(0))"),self.python)

    def test_no_year_or_date_mismatch_credit_claimed(self):
        r=v.prove(self.ada_month,self.ada_calendar,self.python)
        self.assertEqual(r["status"],"STATIC_ORIGINAL_SOURCE_MONTH_WEAVING_FAMILIES_NOT_EQUIVALENT")
        self.assertIs(r["caused_foundation_day_specific_mismatch_proven"],False)
        self.assertTrue(r["no_native_converter_call"])
        self.assertTrue(r["stop_new_native_soak_dispatch"])
        self.assertEqual(r["full_years_certified"],0)

    def test_invalid_static_example_rejected(self):
        for case in ((0,2),(2,1),(2,2,2),("4",4)):
            with self.subTest(case=case),self.assertRaises(ValueError):
                v.canonical_weaves(case)

if __name__=="__main__":
    unittest.main()
