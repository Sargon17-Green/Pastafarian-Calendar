"""Synthetic v140 fail-closed static source and original archived receipt controls.

Run no pastafarian calendar engine, no OS process, no compiler, no original F(c,t).
"""
import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
import soak_weave_selector_original_archives_v140 as v

M=Path(__file__).resolve().parents[1]/"control"/"weave_selector_original_archive_v140.json"

class MockGitHub:
    def __init__(self,manifest):
        self.runs={}
        self.artifacts={}
        for row in manifest["archived_original_runs"]:
            run=row["run_id"]
            self.runs[run]={"id":run,"status":"completed","conclusion":"success"}
            self.artifacts[run]={"total_count":1,"artifacts":[{
              "id":row["artifact_id"],"digest":"sha256:"+row["sha256"],
              "expired":False,"name":"original immutable historic ZIP"}]}
    def get(self,path):
        pre="/repos/"+v.REPO+"/actions/runs/"
        for id in self.runs:
            if path==pre+str(id):return self.runs[id]
            if path==pre+str(id)+"/artifacts?per_page=100":
                return self.artifacts[id]
        raise AssertionError("unexpected GitHub query "+path)

class V140Tests(unittest.TestCase):
    def setUp(self):
        self.m=json.loads(M.read_text(encoding="utf-8"))
        self.gh=MockGitHub(self.m)
        self.files={
          "src/normative_oracle.adb":(
            "Shifted : constant Answer_Stream\n"
            "First => Answer_At (Stream, B (I - 1))\n"
            "Choose_Rank (Shifted, B (Slots))\n"
            "Month_Weaving.From_Choices (Lengths, Tickets)\n"
          ).encode(),
          "src/month_weaving.adb":(
            "function From_Choices\nOutput (Pos) := J;\n"
            "Remains (J) := Lengths (J) - 2;\n"
          ).encode(),
          "tests/normative_reference.py":(
            "family = MonthWeavingFamily(month_lengths)\n"
            "rank = choose_rank(ask_bowl(result, 4, SEAL_MONTH_WEAVING), family.count())\n"
            "return family.unrank1(rank)\n"
          ).encode()
        }
        self.sha={(rev,path):sha for rev,path,sha in v.SOURCE_REQUESTS}
        def f(_gh,repo,ref,path):
            self.assertEqual(repo,v.REPO)
            return self.files[path],{"git_blob_sha1":self.sha[(ref,path)]}
        self.mock=patch.object(v,"checked_blob",side_effect=f)
        self.mock.start()
        self.addCleanup(self.mock.stop)
    def test_1_source_contract_is_pinned(self):
        v.validate(self.m)
    def test_2_two_distinct_legal_and_rank_schedule_differences(self):
        x=v.tiny_selector(self.m)
        self.assertEqual((x["family_count_python"],x["family_count_ada"]),(20,6))
        self.assertTrue(x["two_independent_structural_differences"])
        self.assertFalse(x["caused_actual_foundation_mismatch_proven"])
    def test_3_stream_first_one_tickets(self):
        self.assertEqual([v.select_short(1,1,k,n) for k,n in enumerate(range(4,0,-1))],[1,2,1,1])
    def test_4_ada_actual_ticket_order_differs_from_counterfactual_same_family_global_rank(self):
        r=v.tiny_selector(self.m)
        self.assertNotEqual(r["result_ada_tickets"],
                            r["counterfactual_global_rank_in_ada_only_family"])
    def test_5_python_full_family_first_is_11112222(self):
        self.assertEqual(v.tiny_selector(self.m)["result_python_global_rank"],[1,1,1,1,2,2,2,2])
    def test_6_source_three_exact_git_blobs(self):
        self.assertEqual(v.source_check(self.m,self.gh)["pinned_source_blobs"],3)
    def test_7_original_completed_three_run_metadata(self):
        self.assertEqual(len(v.archive_metadata(self.m,self.gh)),3)
    def test_8_zero_native_calls_in_static_full_audit(self):
        r=v.audit(self.m,self.gh)
        self.assertFalse(r["original_archive_bytes_examined_this_execution"])
        self.assertIsNone(r["historical_zip_byte_receipts"])
        self.assertEqual(r["original_native_calls_new"],0)
        self.assertEqual(r["full_original_years_certified"],0)
        self.assertFalse(r["sole_numeric_cause_proven"])
    def test_9_missing_original_native_run_is_rejected(self):
        self.gh.runs[self.m["archived_original_runs"][0]["run_id"]]["status"]="queued"
        with self.assertRaisesRegex(ValueError,"not completed/success"):
            v.archive_metadata(self.m,self.gh)
    def test_10_missing_historical_original_artifact_is_rejected(self):
        id=self.m["archived_original_runs"][0]["run_id"]
        self.gh.artifacts[id]["artifacts"]=[]
        self.gh.artifacts[id]["total_count"]=0
        with self.assertRaisesRegex(ValueError,"missing/stale"):
            v.archive_metadata(self.m,self.gh)
    def test_11_original_archive_digest_substitution_rejected(self):
        id=self.m["archived_original_runs"][2]["run_id"]
        self.gh.artifacts[id]["artifacts"][0]["digest"]="sha256:"+"0"*64
        with self.assertRaisesRegex(ValueError,"missing/stale"):
            v.archive_metadata(self.m,self.gh)
    def test_12_mutating_foundation_results_is_rejected(self):
        self.m["archived_original_runs"][0]["observed"][3]=20
        with self.assertRaisesRegex(ValueError,"historical artifact ID"):
            v.validate(self.m)
    def test_13_native_dispatch_cannot_be_authorized(self):
        self.m["dispatch_authorized"]=True
        with self.assertRaisesRegex(ValueError,"source execution"):
            v.validate(self.m)
    def test_14_original_years_cannot_be_promoted(self):
        self.m["original_soak_10000_years_certified"]=1
        with self.assertRaisesRegex(ValueError,"source execution"):
            v.validate(self.m)
    def test_15_invalid_synthetic_modulus_rejected(self):
        self.m["synthetic_stream"]["modulus_decimal"]="97"
        with self.assertRaisesRegex(ValueError,"synthetic"):
            v.validate(self.m)
    def test_16_source_selector_token_mutation_rejected(self):
        self.files["src/normative_oracle.adb"]=b"old Ada source"
        with self.assertRaisesRegex(ValueError,"shifted rank"):
            v.source_check(self.m,self.gh)
    def test_17_original_python_global_rank_token_mutation_rejected(self):
        self.files["tests/normative_reference.py"]=b"old Python source"
        with self.assertRaisesRegex(ValueError,"global rank"):
            v.source_check(self.m,self.gh)
    def test_18_source_blob_hash_mismatch_rejected(self):
        self.sha[(v.PY,"tests/normative_reference.py")]="0"*40
        with self.assertRaisesRegex(ValueError,"frozen original source"):
            v.source_check(self.m,self.gh)
    def test_19_witness_zip_not_assumed_present_from_metadata(self):
        with tempfile.TemporaryDirectory() as d:
            with self.assertRaisesRegex(ValueError,"original ZIP not mounted"):
                v.read_archives(self.m,Path(d))
    def test_20_empty_fake_archived_zip_cannot_pass_original_byte_gate(self):
        with tempfile.TemporaryDirectory() as d:
            (Path(d)/self.m["archived_original_runs"][0]["file"]).write_bytes(b"not-zip")
            with self.assertRaisesRegex(ValueError,"original ZIP SHA-256"):
                v.read_archives(self.m,Path(d))
    def test_21_historical_fortran_binary_not_assumed_original_ada(self):
        a=[x for x in self.m["archived_original_runs"] if x["role"]=="fortran"][0]
        self.assertIn("binary_sha256",a)
        self.assertNotIn("binary_sha256",self.m["archived_original_runs"][0])
    def test_22_invalid_direction_rejected(self):
        with self.assertRaisesRegex(ValueError,"synthetic selector"):
            v.select_short(1,0,0,4)

if __name__=="__main__":unittest.main()
