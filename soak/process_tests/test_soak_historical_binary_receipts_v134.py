"""Synthetic historical CI metadata negative controls; no native builds/date calls."""
from __future__ import annotations
import copy
import json
from pathlib import Path
import sys
from unittest import TestCase,main
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
import soak_historical_binary_receipts_v134 as target
from soak_historical_binary_receipts_v134 import (
    check_historical,validate,REPO,SHA,SEER,SEER_SHA,EXPECTED)

def fixture():
    base=Path(__file__).resolve().parents[1]/"control"
    index=json.loads((base/"historical_binary_receipts_index_v134.json").read_text())
    old={
       "schema":"PASTAFARI_SOAK_STATIC_BUILD_GRAPH_REPORT_V133/1",
       "native_builds_executed":0,"native_date_calls":0,
       "original_full_years_certified":0,"independent_algorithms_certified":0,
       "soak_dispatch_authorized":False,
       "assembly":{"object_sources":[{}]*8,"extern_symbols":[{}]*36},
       "seer":{"services":[{},{}]}
    }
    return index,old

class FakeGithub:
    def __init__(self):
        self.runs={}
        self.jobs={}
        self.artifacts={}
        self.seer={"total_count":0,"workflow_runs":[]}
        self.urls=[]
        for rid,v in EXPECTED.items():
            self.runs[rid]={"id":rid,"head_sha":SHA,
                "status":"completed","conclusion":"success","event":"push"}
            self.jobs[rid]={"total_count":1,"jobs":[{"id":v["job"],
                "status":"completed","conclusion":"success",
                "steps":[{"name":s,"conclusion":"success"} for s in v["steps"]]}]}
            self.artifacts[rid]={"total_count":0,"artifacts":[]}
    def get(self,url):
        self.urls.append(url)
        if url=="/repos/"+SEER+"/actions/runs?head_sha="+SEER_SHA+"&per_page=100":
            return self.seer
        for rid in EXPECTED:
            prefix="/repos/"+REPO+"/actions/runs/"+str(rid)
            if url==prefix:return self.runs[rid]
            if url==prefix+"/jobs?per_page=100":return self.jobs[rid]
            if url==prefix+"/artifacts?per_page=100":return self.artifacts[rid]
        raise AssertionError("unexpected GitHub API read: "+url)

def checked_blob_fake(gh,repo,commit,path):
    matches=[spec for spec in EXPECTED.values() if spec["path"]==path]
    if not matches:raise AssertionError("unknown workflow path")
    spec=matches[0]
    raw=("\n".join((
      "steps:",
      "  - uses: actions/upload-artifact@v4",
      "    with:",
      "      name: "+spec["artifact_name"],
      "      path: audit_evidence/",
      "      retention-days: 30"
    ))+"\n").encode()
    return raw,{"source_sha256":"2"*64,
                "git_blob_sha1":spec["git_blob_sha1"],"bytes":len(raw)}

class HistoricalReceiptsTests(TestCase):
    def setUp(self):
        self.index,self.prior=fixture()
        self.github=FakeGithub()
        self.patch=patch.object(target,"checked_blob",side_effect=checked_blob_fake)
        self.patch.start()
        self.addCleanup(self.patch.stop)
    def check(self):
        return check_historical(self.index,self.prior,self.github)

    def test_two_completed_historical_builds_but_no_binary_certificate(self):
        r=self.check()
        self.assertEqual(r["coptic"]["historical_completed_success_run_count"],2)
        self.assertTrue(all(x["current_artifact_status"]=="NO_CURRENT_ARTIFACT_RETURNED"
                            for x in r["coptic"]["historical_successful_build_job_receipts"]))
        self.assertEqual(r["seer"]["github_exact_sha_run_search_count"],0)
        self.assertEqual(r["binary_identity_for_scientific_soak_certified"],0)
        self.assertEqual(r["original_full_years_certified"],0)
        self.assertFalse(r["soak_dispatch_authorized"])

    def test_restored_metadata_does_not_certify_binary_or_soak(self):
        rid=35640916185
        spec=EXPECTED[rid]
        self.github.artifacts[rid]={"total_count":1,"artifacts":[{
            "id":spec["artifact_id"],"name":spec["artifact_name"]}]}
        r=self.check()
        x=r["coptic"]["historical_successful_build_job_receipts"][0]
        self.assertTrue(x["pinned_artifact_metadata_currently_returned"])
        self.assertFalse(x["binary_file_sha256_obtained"])
        self.assertEqual(r["binary_identity_for_scientific_soak_certified"],0)

    def test_run_on_different_commit_is_rejected(self):
        self.github.runs[35640916171]["head_sha"]="0"*40
        with self.assertRaisesRegex(ValueError,"frozen SHA"):
            self.check()

    def test_running_job_cannot_be_treated_as_completed(self):
        self.github.jobs[35640916185]["jobs"][0]["status"]="in_progress"
        with self.assertRaisesRegex(ValueError,"not completed/success"):
            self.check()

    def test_queued_run_does_not_get_success(self):
        self.github.runs[35640916171]["status"]="queued"
        with self.assertRaisesRegex(ValueError,"completed success"):
            self.check()

    def test_required_historical_step_was_not_completed(self):
        self.github.jobs[35640916171]["jobs"][0]["steps"][0]["conclusion"]="failure"
        with self.assertRaisesRegex(ValueError,"steps not all successful"):
            self.check()

    def test_historical_job_id_substitution_rejected(self):
        self.github.jobs[35640916185]["jobs"][0]["id"]=777
        with self.assertRaisesRegex(ValueError,"pinned job not in run"):
            self.check()

    def test_no_artifact_total_guessing_if_pagination_over_100(self):
        self.github.artifacts[35640916185]["total_count"]=101
        with self.assertRaisesRegex(ValueError,"artifact metadata missing"):
            self.check()

    def test_workflow_source_sha_lock_must_match(self):
        def wrong(gh,repo,commit,path):
            raw,info=checked_blob_fake(gh,repo,commit,path)
            return raw,{**info,"git_blob_sha1":"0"*40}
        with patch.object(target,"checked_blob",side_effect=wrong):
            with self.assertRaisesRegex(ValueError,"bytes differ"):
                self.check()

    def test_seer_other_commit_run_does_not_satisfy_exact_sha(self):
        self.github.seer={"total_count":1,"workflow_runs":[
            {"id":42423259653,"head_sha":"4716594fc98fa882a9401455ae56f30895518e8c",
             "status":"completed","conclusion":"success"}]}
        r=self.check()
        self.assertEqual(r["seer"]["matching_run_ids"],[])
        self.assertFalse(r["seer"]["frozen_commit_binary_sha256_attested"])

    def test_exact_sha_future_run_still_does_not_certify_binary(self):
        self.github.seer={"total_count":1,"workflow_runs":[
            {"id":9999,"head_sha":SEER_SHA,
             "status":"completed","conclusion":"success"}]}
        r=self.check()
        self.assertEqual(r["seer"]["matching_run_ids"],[9999])
        self.assertEqual(r["seer"]["classification"],
            "EXACT_COMMIT_RUN_METADATA_PRESENT_NOT_BINARY_ATTESTED")
        self.assertEqual(r["binary_identity_for_scientific_soak_certified"],0)

    def test_historic_artifact_ID_is_frozen(self):
        self.index["coptic"]["workflows"][0]["historical_upload_artifact_id"]=9999
        with self.assertRaisesRegex(ValueError,"evidence lock changed"):
            self.check()

    def test_prior_source_report_cannot_claim_native_success(self):
        self.prior["original_full_years_certified"]=1
        with self.assertRaisesRegex(ValueError,"v133 source graph prerequisite"):
            self.check()

    def test_historical_artifact_index_cannot_authorize_native(self):
        self.index["auto_binary_attestation"]=True
        with self.assertRaisesRegex(ValueError,"forbidden escalation"):
            self.check()

    def test_seer_search_is_not_a_404_as_zero(self):
        self.github.seer={"message":"Not Found"}
        with self.assertRaisesRegex(ValueError,"exact-commit action search unavailable"):
            self.check()

if __name__=="__main__":
    main()
