#!/usr/bin/env python3
"""v157 synthetic-only tests: output name index is not month ordinal/causal rank."""
from __future__ import annotations
import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
from soak_foundation_causal_observability_v157 import (
    inverse_ambiguity_demo, synthetic_snapshot, verify_snapshot,
    minimal_observed_divergences, validate_source_mapping,
    PARENTS, NEEDED, SYNTHETIC
)


class CausalObservabilityToyTests(unittest.TestCase):
    def setUp(self):
        d = inverse_ambiguity_demo()
        self.a = d["example_a"]
        self.b = d["example_b"]

    def test_01_two_valid_ada_rails_have_same_final_month_tuple(self):
        self.assertEqual((self.a["month_index"],self.a["day_in_month"]),
                         (self.b["month_index"],self.b["day_in_month"]))
        self.assertEqual((self.a["month_index"],self.a["day_in_month"]), (20,2))
        self.assertNotEqual(self.a["month_id"],self.b["month_id"])

    def test_02_same_final_month_index_does_not_prove_same_month_id(self):
        self.assertEqual(self.a["month_id"],1)
        self.assertEqual(self.b["month_id"],2)
        self.assertEqual(self.a["month_name_indices"],[20,30])
        self.assertEqual(self.b["month_name_indices"],[30,20])

    def test_03_two_independent_branches_prevent_single_root_claim(self):
        self.assertEqual(
            set(minimal_observed_divergences(self.a,self.b)),
            {"month_weaving","month_name_indices"})

    def test_04_all_causal_dag_parents_are_earlier_fields(self):
        self.assertEqual(set(NEEDED),set(PARENTS))
        for name,parents in PARENTS.items():
            for p in parents:
                self.assertLess(NEEDED.index(p),NEEDED.index(name))

    def test_05_month_name_is_a_join_node(self):
        self.assertEqual(set(PARENTS["month_index"]),
                         {"month_id","month_name_indices"})

    def test_06_same_snapshot_no_divergent_fields(self):
        self.assertEqual(minimal_observed_divergences(self.a,self.a),[])

    def test_07_different_year_open_boundary_is_a_prior_observed_divergence(self):
        other=copy.deepcopy(self.a)
        other["year_open_day"]=99
        # Synthetic fixture generator always anchors opening=100. Tampering
        # must fail closed instead of inferring causes from unverified data.
        with self.assertRaisesRegex(ValueError,"contradicts"):
            minimal_observed_divergences(self.a,other)

    def test_08_name_index_forgery_rejected(self):
        other=copy.deepcopy(self.a)
        other["month_index"]=30
        with self.assertRaisesRegex(ValueError,"contradicts"):
            verify_snapshot(other)

    def test_09_day_in_month_forgery_rejected(self):
        other=copy.deepcopy(self.a)
        other["day_in_month"]=4
        with self.assertRaisesRegex(ValueError,"contradicts"):
            verify_snapshot(other)

    def test_10_false_real_native_receipt_promotion_rejected(self):
        other=copy.deepcopy(self.a)
        other["scope"]="HISTORICAL_ORIGINAL_ATTESTED"
        with self.assertRaisesRegex(ValueError,"synthetic-only"):
            verify_snapshot(other)

    def test_11_wrong_target_date_rejected(self):
        other=copy.deepcopy(self.a)
        other["target_day"]+=1
        with self.assertRaisesRegex(ValueError,"contradicts"):
            verify_snapshot(other)

    def test_12_duplicate_canonical_month_name_ids_rejected(self):
        with self.assertRaisesRegex(ValueError,"distinct"):
            synthetic_snapshot((4,4),(1,2,1,1,2,2,1,2),
                               (20,20),2,engine="ADA_TWO_RAIL")

    def test_13_ada_nonrail_general_weave_rejected(self):
        with self.assertRaisesRegex(ValueError,"two-rail"):
            synthetic_snapshot((4,4),(1,1,1,1,2,2,2,2),
                               (20,30),2,engine="ADA_TWO_RAIL")

    def test_14_python_general_nonrail_weave_accepted(self):
        x=synthetic_snapshot((4,4),(1,1,1,1,2,2,2,2),
                             (20,30),2,engine="PY_GENERAL")
        self.assertEqual(x["month_index"],20)
        verify_snapshot(x)

    def test_15_invalid_weave_multiplicities_rejected(self):
        with self.assertRaisesRegex(ValueError,"multiplicities"):
            synthetic_snapshot((4,4),(1,2,1,1,2,2,2,2),
                               (20,30),2,engine="ADA_TWO_RAIL")

    def test_16_invalid_open_month_order_rejected(self):
        with self.assertRaisesRegex(ValueError,"opening order"):
            synthetic_snapshot((4,4),(2,1,2,2,1,1,2,1),
                               (20,30),2,engine="PY_GENERAL")

    def test_17_invalid_close_month_order_rejected(self):
        with self.assertRaisesRegex(ValueError,"closing order"):
            synthetic_snapshot((4,4),(1,2,2,2,1,1,2,1),
                               (20,30),2,engine="PY_GENERAL")

    def test_18_wrong_original_source_provenance_rejected(self):
        with self.assertRaises(ValueError):
            validate_source_mapping({"REF-41":b"fake bytes"})

    def test_19_unbounded_toy_offset_rejected(self):
        with self.assertRaisesRegex(ValueError,"offset"):
            synthetic_snapshot((4,4),(1,2,1,1,2,2,1,2),
                               (20,30),100,engine="ADA_TWO_RAIL")

    def test_20_calendar_month_number_not_equivalent_to_name_number(self):
        self.assertEqual(self.a["month_id"],1)
        self.assertEqual(self.a["month_index"],20)
        self.assertNotEqual(self.a["month_id"],self.a["month_index"])


if __name__=="__main__":
    unittest.main()
