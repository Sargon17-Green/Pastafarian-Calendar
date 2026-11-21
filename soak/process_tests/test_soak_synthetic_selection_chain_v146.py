"""v146 fail-closed source-only end-to-end synthetic Ada selection test suite."""
from __future__ import annotations

import copy
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/"runner"))
import soak_synthetic_selection_chain_v146 as v

MANIFEST=root/"control"/"ada_synthetic_selection_chain_v146.json"
BOWLS=root/"control"/"ada_rank_stream_source_v145.json"
ADA=root/"ada_chain_v146"/"test_synthetic_selection_chain_v146.adb"

class FakeGH:
    def __init__(self):
        self.runs={
          v.V144_CI:{"id":v.V144_CI,"head_sha":v.V144_HEAD,
                     "status":"completed","conclusion":"success"},
          v.V145_CI:{"id":v.V145_CI,"head_sha":v.V145_HEAD,
                     "status":"completed","conclusion":"success"}}
        self.artifacts={
          v.V144_CI:{"total_count":1,"artifacts":[{"id":v.V144_ART,
            "digest":"sha256:"+v.V144_DIGEST,"expired":False}]},
          v.V145_CI:{"total_count":1,"artifacts":[{"id":v.V145_ART,
            "digest":"sha256:"+v.V145_DIGEST,"expired":False}]}}
        self.issue={"number":29,"state":"open",
                    "body":"CONFIRMED_ORIGINAL_SOURCE_MISMATCH"}
        self.main={"commit":{"sha":"56bc4173aae4975ded019ef5ab5a36249f1424df"}}
    def get(self,path):
        base="/repos/"+v.REPO
        for id in (v.V144_CI,v.V145_CI):
            if path==base+"/actions/runs/"+str(id):return self.runs[id]
            if path==base+"/actions/runs/"+str(id)+"/artifacts?per_page=100":
                return self.artifacts[id]
        if path==base+"/issues/29":return self.issue
        if path==base+"/branches/main":return self.main
        raise AssertionError("Unexpected GitHub read-only API endpoint: "+path)

class V146PureSyntheticTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.m0=json.loads(MANIFEST.read_text(encoding="utf-8"))
        cls.b0=json.loads(BOWLS.read_text(encoding="utf-8"))
        cls.ada0=ADA.read_text(encoding="utf-8")
    def setUp(self):
        self.m=copy.deepcopy(self.m0)
        self.b=copy.deepcopy(self.b0)
        self.code=self.ada0
        self.gh=FakeGH()
    def test_01_scientific_stop_and_complete_cross_product(self):
        v.validate(self.m,self.b)
    def test_02_exact_30_full_sequences_independent_DP(self):
        t=v.compute_expected(self.m,self.b)
        self.assertTrue(t["all_30_complete_sequences_match_independent_pure_math"])
        self.assertEqual(t["exact_full_sequence_checks"],30)
    def test_03_exact_18_wide_global_rank_chains(self):
        t=v.compute_expected(self.m,self.b)
        self.assertEqual(t["wide_family_cases"],18)
        self.assertEqual(t["maximum_synthetic_days"],256)
    def test_04_two4_short_global_rank_pipeline(self):
        t=v.compute_expected(self.m,self.b)
        self.assertEqual(sum(z["id"].startswith("two4_") for z in t["cases"]),6)
    def test_05_one_family_big_integer_over_700_bits(self):
        t=v.compute_expected(self.m,self.b)
        self.assertTrue(any(x["family_count_bits"]==713 for x in t["cases"]))
    def test_06_thirty_embedded_Ada_expected_full_sequences(self):
        t=v.verify_ada_source(self.m,self.b,self.code)
        self.assertEqual(t["Ada_full_sequence_expected_text_literals_exact"],30)
    def test_07_previous_v144_and_v145_CI_receipts_accepted(self):
        t=v.prior_ci(self.gh)
        self.assertTrue(t["v144_completed_success"])
        self.assertTrue(t["v145_completed_success"])
    def test_08_missing_original_issue29_not_accepted(self):
        self.gh.issue["state"]="closed"
        with self.assertRaisesRegex(ValueError,"no longer pinned as open"):
            v.prior_ci(self.gh)
    def test_09_queued_v145_is_not_success(self):
        self.gh.runs[v.V145_CI]["status"]="queued"
        with self.assertRaisesRegex(ValueError,"not completed success"):
            v.prior_ci(self.gh)
    def test_10_wrong_v144_artifact_digest_is_rejected(self):
        self.gh.artifacts[v.V144_CI]["artifacts"][0]["digest"]="sha256:"+"0"*64
        with self.assertRaisesRegex(ValueError,"digest/availability"):
            v.prior_ci(self.gh)
    def test_11_modified_main_is_not_accepted(self):
        self.gh.main["commit"]["sha"]="0"*40
        with self.assertRaisesRegex(ValueError,"original production main"):
            v.prior_ci(self.gh)
    def test_12_misleading_one_original_year_claim_rejected(self):
        self.m["scope_locks"]["original_soak_years_certified"]=1
        with self.assertRaisesRegex(ValueError,"scientific stop"):
            v.validate(self.m,self.b)
    def test_13_real_calendar_call_claim_rejected(self):
        self.m["scope_locks"]["original_Fct_calls"]=1
        with self.assertRaisesRegex(ValueError,"scientific stop"):
            v.validate(self.m,self.b)
    def test_14_a_synthetic_sequence_mutation_fails(self):
        self.m["cases"][0]["expected_sequence"]="1"*8
        with self.assertRaisesRegex(ValueError,"mathematical fixture mismatch"):
            v.compute_expected(self.m,self.b)
    def test_15_one_synthetic_bowl_value_mutation_fails(self):
        self.b["synthetic_bowl_vectors"][0]["bowls"][0]="987654321"
        with self.assertRaisesRegex(ValueError,"mathematical fixture mismatch"):
            v.compute_expected(self.m,self.b)
    def test_16_omitted_case_fails_before_execution(self):
        self.m["cases"].pop()
        with self.assertRaisesRegex(ValueError,"inventory must be 30"):
            v.validate(self.m,self.b)
    def test_17_duplicate_case_id_fails(self):
        self.m["cases"][1]["id"]=self.m["cases"][0]["id"]
        with self.assertRaisesRegex(ValueError,"duplicate malformed"):
            v.validate(self.m,self.b)
    def test_18_ada_full_sequence_literal_edit_fails(self):
        old=self.m["cases"][0]["expected_sequence"]
        self.code=self.code.replace('"'+old+'"','"'+old[:-1]+'9"',1)
        with self.assertRaisesRegex(ValueError,"FULL-SEQUENCE golden fixture differs"):
            v.verify_ada_source(self.m,self.b,self.code)
    def test_19_ada_rank_literal_edit_fails(self):
        old=self.m["cases"][0]
        self.code=self.code.replace(
          'Expected_Rank => "'+old["expected_rank"]+'"',
          'Expected_Rank => "0"',1)
        with self.assertRaisesRegex(ValueError,"Ada literal fixture differs"):
            v.verify_ada_source(self.m,self.b,self.code)
    def test_20_ada_original_converter_import_fails(self):
        self.code="with Normative_Oracle;\n"+self.code
        with self.assertRaisesRegex(ValueError,"imports changed"):
            v.verify_ada_source(self.m,self.b,self.code)
    def test_21_ada_one_missing_fixture_fails(self):
        first=self.m["cases"][0]["id"]
        a="-- V146_FIXTURE_BEGIN "+first
        b="-- V146_FIXTURE_END "+first
        i=self.code.index(a)
        j=self.code.index(b)+len(b)
        self.code=self.code[:i]+self.code[j:]
        with self.assertRaisesRegex(ValueError,"delimiters missing"):
            v.verify_ada_source(self.m,self.b,self.code)
    def test_22_original_source_commit_change_fails(self):
        self.m["original_source_locks"]["ada"]["commit"]="0"*40
        with self.assertRaisesRegex(ValueError,"original source pins"):
            v.validate(self.m,self.b)
    def test_23_wrong_v145_bowl_source_blob_fails(self):
        self.m["golden_bowl_source"]["blob"]="0"*40
        with self.assertRaisesRegex(ValueError,"source pin"):
            v.validate(self.m,self.b)
    def test_24_expected_not_to_compute_original_dates(self):
        self.assertEqual(self.m["scope_locks"]["original_date_inputs_used"],0)
        self.assertEqual(self.m["scope_locks"]["original_native_calendar_compiles"],0)
        self.assertEqual(self.m["scope_locks"]["original_Fct_calls"],0)
        self.assertFalse(self.m["scope_locks"]["production_patch"])

if __name__=="__main__":
    unittest.main()
