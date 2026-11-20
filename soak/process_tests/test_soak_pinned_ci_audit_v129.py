"""Synthetic GitHub Actions run/job status oracle. Never launches F(c,t)."""
from __future__ import annotations

import copy
import sys
from pathlib import Path
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/"runner"))
from soak_pinned_ci_audit_v129 import audit, validate_index, CLAIM_SCOPE
from soak_source_census_v129 import census, APIProblem
from test_soak_source_census_v129 import fixture, FakeGitHub, REPO


class FakeWithCI(FakeGitHub):
    def __init__(self):
        super().__init__()
        self.status="completed"
        self.conclusion="success"
        self.event="push"
        self.head="1"*40
        self.job_status="completed"
        self.job_conclusion="success"
        self.step_name="Compile and smoke native wrapper"
        self.step_status="completed"
        self.step_conclusion="success"
        self.access=True

    def get(self,path):
        if not self.access:
            raise APIProblem("NOT_FOUND_OR_NOT_AUTHORIZED")
        if path.endswith("/actions/runs/123"):
            return {
                "id":123,"head_sha":self.head,"event":self.event,
                "status":self.status,"conclusion":self.conclusion,
                "repository":{"full_name":REPO}}
        if path.endswith("/actions/runs/123/jobs?per_page=100"):
            return {"total_count":1,"jobs":[{
                "id":456,"run_id":123,"status":self.job_status,
                "conclusion":self.job_conclusion,
                "steps":[{"name":self.step_name,"status":self.step_status,
                          "conclusion":self.step_conclusion}]}]}
        raise AssertionError("unexpected GH endpoint: "+path)


class PinnedCIStatusTests(unittest.TestCase):
    def setUp(self):
        self.roster,self.prov,self.locks=fixture()
        self.gh=FakeWithCI()
        self.sources=census(self.roster,self.prov,self.locks,self.gh)
        self.index={
            "schema":"PASTAFARI_SOAK_PINNED_SOURCE_CI_JOB_INDEX_V129/1",
            "frozen_source_locks_path":
                "soak/control/pilot_two_engine_source_locks_v001.json",
            "interpretation":"synthetic",
            "claims":[{
                "record_id":"REF-41","repository":REPO,"source_commit":"1"*40,
                "run_id":123,"job_id":456,
                "required_successful_steps":[self.gh.step_name],
                "claim_scope":CLAIM_SCOPE}],
            "full_year_verified":False,
            "native_execution_attested":False,
            "independent_algorithms_certified":False,
        }

    def result(self):
        return audit(self.index,self.locks,self.sources,self.gh)

    def test_completed_source_pinned_ci_is_observed_but_not_soak_ready(self):
        result=self.result()
        self.assertEqual(result["claims_checked"],1)
        obs=result["observations"][0]
        self.assertEqual(obs["ci_status"],"PINNED_COMPLETED_CI_JOB_STEPS_OBSERVED")
        self.assertEqual(obs["combined_source_ci_status"],
                         "SOURCE_LOCK_AND_HISTORICAL_CI_STATUS_OBSERVED")
        self.assertFalse(obs["eligible_for_soak"])
        self.assertFalse(obs["native_full_date_execution_proven"])
        self.assertEqual(result["original_full_years_certified"],0)
        self.assertFalse(result["soak_dispatch_authorized"])

    def test_wrong_run_head_fails_open_looking_ci_success(self):
        self.gh.head="9"*40
        self.assertEqual(self.result()["observations"][0]["ci_status"],
                         "RUN_METADATA_DOES_NOT_MATCH_SOURCE_LOCK")

    def test_skipped_required_ci_job_fails(self):
        self.gh.step_conclusion="skipped"
        self.assertEqual(self.result()["observations"][0]["ci_status"],
                         "REQUIRED_JOB_STEP_MISSING_OR_NOT_SUCCESS")

    def test_non_completed_ci_run_never_counted(self):
        self.gh.status="in_progress"
        self.gh.conclusion=None
        self.assertEqual(self.result()["observations"][0]["ci_status"],
                         "RUN_METADATA_DOES_NOT_MATCH_SOURCE_LOCK")

    def test_job_failure_not_laundered_by_run_success(self):
        self.gh.job_conclusion="failure"
        self.assertEqual(self.result()["observations"][0]["ci_status"],
                         "JOB_NOT_COMPLETED_SUCCESSFULLY")

    def test_wrong_event_not_accepted(self):
        self.gh.event="workflow_dispatch"
        self.assertEqual(self.result()["observations"][0]["ci_status"],
                         "RUN_METADATA_DOES_NOT_MATCH_SOURCE_LOCK")

    def test_github_access_denied_is_incomplete_not_missing_source(self):
        self.gh.access=False
        self.assertEqual(self.result()["observations"][0]["ci_status"],
                         "CI_API_UNAVAILABLE_NOT_FOUND_OR_NOT_AUTHORIZED")

    def test_ci_scope_may_not_claim_original_execution(self):
        self.index["claims"][0]["claim_scope"]="PROVEN_ORIGINAL_SOAK"
        with self.assertRaisesRegex(ValueError,"cannot claim native"):
            self.result()

    def test_ci_source_commit_must_match_frozen_original(self):
        self.index["claims"][0]["source_commit"]="a"*40
        with self.assertRaisesRegex(ValueError,"not locked"):
            self.result()

    def test_census_source_lock_integrity_not_replaced_by_ci_job(self):
        self.sources["records"][0]["frozen_source_lock_status"]="FROZEN_SOURCE_LOCK_MISMATCH"
        obs=self.result()["observations"][0]
        self.assertEqual(obs["ci_status"],"PINNED_COMPLETED_CI_JOB_STEPS_OBSERVED")
        self.assertEqual(obs["combined_source_ci_status"],
                         "INCOMPLETE_SOURCE_OR_CI_EVIDENCE")
        self.assertFalse(obs["eligible_for_soak"])

    def test_untrusted_census_approval_rejected(self):
        self.sources["soak_dispatch_authorized"]=True
        with self.assertRaisesRegex(ValueError,"fail-closed source census"):
            self.result()

    def test_duplicate_index_claim_rejected(self):
        self.index["claims"].append(copy.deepcopy(self.index["claims"][0]))
        with self.assertRaisesRegex(ValueError,"duplicate or unpinned"):
            self.result()

    def test_ci_index_self_attestation_rejected(self):
        self.index["native_execution_attested"]=True
        with self.assertRaisesRegex(ValueError,"self-authorize"):
            self.result()


if __name__=="__main__":
    unittest.main()
