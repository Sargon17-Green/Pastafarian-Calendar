"""v145 pure synthetic rank rejection source-loop and metadata fail-closed tests."""
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
import soak_rank_stream_source_proof_v145 as v

MANIFEST=Path(__file__).resolve().parents[1]/"control"/"ada_rank_stream_source_v145.json"

class FakeGH:
    def __init__(self):
        self.run={"id":v.V144_RUN,"head_sha":v.V144_HEAD,
                  "status":"completed","conclusion":"success"}
        self.art={"total_count":1,"artifacts":[{
          "id":v.V144_ART,"digest":"sha256:"+v.V144_DIGEST,
          "expired":False}]}
        self.issue={"number":29,"state":"open",
                    "body":"CONFIRMED_ORIGINAL_SOURCE_MISMATCH"}
        self.main={"commit":{"sha":"56bc4173aae4975ded019ef5ab5a36249f1424df"}}
    def get(self,path):
        root="/repos/"+v.REPO
        mapping={
          root+"/actions/runs/"+str(v.V144_RUN):self.run,
          root+"/actions/runs/"+str(v.V144_RUN)+"/artifacts?per_page=100":self.art,
          root+"/issues/29":self.issue,
          root+"/branches/main":self.main
        }
        return mapping[path]

class V145SourceTests(unittest.TestCase):
    def setUp(self):
        self.m=json.loads(MANIFEST.read_text(encoding="utf-8"))
        self.gh=FakeGH()
    def test_01_manifest_is_still_synthetic_and_stop_preserved(self):
        v.validate(self.m)
    def test_02_all_26_direct_stream_rank_goldens_recomputed(self):
        x=v.golden_checks(self.m)
        self.assertEqual(x["direct_golden_vectors"],26)
        self.assertGreaterEqual(x["direct_initial_rejected_cases"],8)
    def test_03_six_bowl_first_and_step_and_wide_goldens_recomputed(self):
        x=v.golden_checks(self.m)
        self.assertEqual(x["synthetic_bowl_vectors"],6)
        self.assertTrue(x["both_directions_covered"])
    def test_04_full_literal_cyclic_walk_equals_endpoint_3564_cases(self):
        x=v.toy_exhaustive()
        self.assertEqual(x["total_exact_literal_walk_checks"],3564)
        self.assertFalse(x["original_modulus_full_state_exhaustively_checked"])
    def test_05_short_rejected_upward_wraps_to_one(self):
        self.assertEqual(v.choose_closed_form(v.M,1,2)["rank"],1)
    def test_06_short_rejected_downward_enters_acceptance_limit(self):
        self.assertEqual(v.choose_closed_form(v.M,-1,2)["rank"],2)
    def test_07_wide_positive_rejection_reaches_one(self):
        x=v.choose_closed_form(v.M-1,1,v.M*v.M//2+1)
        self.assertTrue(x["rejected"])
        self.assertEqual((x["rank"],x["places"]),(1,2))
    def test_08_wide_negative_rejection_exact_limit(self):
        x=v.choose_closed_form(1,-1,v.M*v.M//2+1)
        self.assertTrue(x["rejected"])
        self.assertGreater(x["rank"],1)
    def test_09_original_large_rank_cases_have_eight_M_digits(self):
        x=v.golden_checks(self.m)
        self.assertIn(8,x["tested_base_M_places"])
    def test_10_prior_completed_v144_GNAT_evidence_is_required(self):
        self.assertTrue(v.prior_check(self.gh)["v144_completed_success_at_exact_SHA"])
    def test_11_future_native_soak_claim_rejected(self):
        self.m["scientific_gates"]["original_full_years_accepted"]=1
        with self.assertRaisesRegex(ValueError,"dispatch stop improperly lifted"):
            v.validate(self.m)
    def test_12_issue29_close_rejected(self):
        self.gh.issue["state"]="closed"
        with self.assertRaisesRegex(ValueError,"no longer open"):
            v.prior_check(self.gh)
    def test_13_main_SHA_change_rejected(self):
        self.gh.main["commit"]["sha"]="0"*40
        with self.assertRaisesRegex(ValueError,"main original source"):
            v.prior_check(self.gh)
    def test_14_queued_not_success(self):
        self.gh.run["status"]="queued"
        with self.assertRaisesRegex(ValueError,"not completed/success"):
            v.prior_check(self.gh)
    def test_15_wrong_v144_artifact_SHA_rejected(self):
        self.gh.art["artifacts"][0]["digest"]="sha256:"+"0"*64
        with self.assertRaisesRegex(ValueError,"unavailable or wrong"):
            v.prior_check(self.gh)
    def test_16_direct_rank_mutation_rejected(self):
        self.m["direct_vectors"][0]["rank"]="9"
        with self.assertRaisesRegex(ValueError,"source rank golden"):
            v.golden_checks(self.m)
    def test_17_bowl_stream_mutation_rejected(self):
        self.m["synthetic_bowl_vectors"][0]["first"]="2"
        with self.assertRaisesRegex(ValueError,"Ask_Bowl"):
            v.golden_checks(self.m)
    def test_18_frozen_modulus_mutation_rejected(self):
        self.m["modulus_decimal"]="37"
        with self.assertRaisesRegex(ValueError,"contract changed"):
            v.validate(self.m)
    def test_19_direction_zero_rejected(self):
        with self.assertRaisesRegex(ValueError,"invalid source-defined synthetic stream"):
            v.choose_closed_form(1,0,37)
    def test_20_out_of_scope_integer_bit_width_rejected(self):
        with self.assertRaisesRegex(ValueError,"family N outside QA bound"):
            v.choose_closed_form(1,1,2**1024)
    def test_21_invalid_bowl_order_rejected(self):
        with self.assertRaisesRegex(ValueError,"invalid synthetic bowl"):
            v.bowl_math([1]*6,[1]*6,4,32)
    def test_22_zero_original_execution_claims(self):
        self.assertTrue(self.m["scientific_gates"]["STOP_NEW_NATIVE_SOAK_DISPATCH"])
        self.assertEqual(self.m["scientific_gates"]["original_Fct_calls"],0)
        self.assertFalse(self.m["scientific_gates"]["production_patch"])

if __name__=="__main__":
    unittest.main()
