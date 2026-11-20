"""v137 synthetic fail-closed source, run, ZIP, and 24-executable hash gates."""
from __future__ import annotations
import copy
import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
from soak_seer_cross_run_native_hash_v137 import (
    ARCHIVE_LOCKS,EARLIER,FAILED_NEXT,FROZEN,INNER_COMMITS,LATER,NEXT_RUN,
    REPO,SCHEMA,SUCCESS_RUNS,TARGETS,check_live,scan_zip,validate
)

INDEX=Path(__file__).resolve().parents[1]/"control"/"seer_cross_run_native_hash_v137.json"

def manifest():
    return json.loads(INDEX.read_text(encoding="utf-8"))

class FakeGithub:
    def __init__(self):
        self.runs={id:{
            "id":id,"head_sha":sha,"status":"completed","conclusion":"success"
        } for id,sha in SUCCESS_RUNS.items()}
        self.runs[FAILED_NEXT]={"id":FAILED_NEXT,"head_sha":EARLIER,
                                "status":"completed","conclusion":"failure"}
        self.artifacts={}
        for id,sha in SUCCESS_RUNS.items():
            self.artifacts[id]={"total_count":0,"artifacts":[]}
        for aid,(run_id,size,hashval,platform) in ARCHIVE_LOCKS.items():
            self.artifacts[run_id]["artifacts"].append({
              "id":aid,
              "name":"native-"+platform+"-"+INNER_COMMITS[SUCCESS_RUNS[run_id]],
              "digest":"sha256:"+hashval,
              "size_in_bytes":size,
              "expired":False})
            self.artifacts[run_id]["total_count"]+=1
        self.artifacts[FAILED_NEXT]={"total_count":0,"artifacts":[]}
    def get(self,path):
        stem="/repos/"+REPO+"/actions/runs/"
        for id,run in self.runs.items():
            base=stem+str(id)
            if path==base:return run
            if path==base+"/artifacts?per_page=100":return self.artifacts[id]
        raise AssertionError("unexpected API request "+path)

class V137Test(unittest.TestCase):
    def setUp(self):
        self.m=manifest()
        self.gh=FakeGithub()
    def test_six_archives_four_each_and_16_unique_hashes(self):
        rows=validate(self.m)
        self.assertEqual(len(rows),6)
        hashes=[v for row in rows for v in row["binaries"].values()]
        self.assertEqual(len(hashes),24)
        self.assertEqual(len(set(hashes)),16)
        self.assertFalse(set(hashes)&set(TARGETS.values()))
    def test_two_successful_runs_have_six_archives_and_failed_next_remains_failure(self):
        x=check_live(self.m,self.gh)
        self.assertEqual(x["exact_completed_prebuilt_runs"],2)
        self.assertEqual(x["prebuilt_artifacts_verified"],6)
        self.assertEqual(x["adjacent_seer_next_status"],"completed/failure")
        self.assertFalse(x["binary_bytes_reexamined_in_this_live_metadata_scan"])
    def test_queued_historical_prebuilt_run_is_not_pass(self):
        self.gh.runs[42423263952]["status"]="queued"
        with self.assertRaisesRegex(ValueError,"not completed/success"):
            check_live(self.m,self.gh)
    def test_in_progress_historical_prebuilt_run_is_not_pass(self):
        self.gh.runs[42421325317]["status"]="in_progress"
        with self.assertRaisesRegex(ValueError,"not completed/success"):
            check_live(self.m,self.gh)
    def test_failed_prebuilt_run_is_not_pass(self):
        self.gh.runs[42423263952]["conclusion"]="failure"
        with self.assertRaisesRegex(ValueError,"not completed/success"):
            check_live(self.m,self.gh)
    def test_wrong_prebuilt_head_sha_is_rejected(self):
        self.gh.runs[42421325317]["head_sha"]="0"*40
        with self.assertRaisesRegex(ValueError,"exact source"):
            check_live(self.m,self.gh)
    def test_failing_neighboring_seer_next_run_cannot_be_promoted(self):
        self.gh.runs[FAILED_NEXT]["conclusion"]="success"
        with self.assertRaisesRegex(ValueError,"cannot be converted to PASS"):
            check_live(self.m,self.gh)
    def test_missing_pinned_archive_rejected(self):
        self.gh.artifacts[42423263952]["artifacts"].pop()
        self.gh.artifacts[42423263952]["total_count"]-=1
        with self.assertRaisesRegex(ValueError,"digest or availability"):
            check_live(self.m,self.gh)
    def test_wrong_artifact_zip_digest_rejected(self):
        self.gh.artifacts[42423263952]["artifacts"][0]["digest"]="sha256:"+"0"*64
        with self.assertRaisesRegex(ValueError,"digest or availability"):
            check_live(self.m,self.gh)
    def test_expired_archive_rejected(self):
        self.gh.artifacts[42421325317]["artifacts"][0]["expired"]=True
        with self.assertRaisesRegex(ValueError,"digest or availability"):
            check_live(self.m,self.gh)
    def test_ambiguous_artifact_inventory_pagination_rejected(self):
        self.gh.artifacts[42421325317]["total_count"]=101
        with self.assertRaisesRegex(ValueError,"incomplete"):
            check_live(self.m,self.gh)
    def test_altered_inner_source_commit_rejected(self):
        self.m["artifacts"][0]["inner_source"]=LATER
        with self.assertRaisesRegex(ValueError,"metadata changed"):
            validate(self.m)
    def test_altered_zip_sha_rejected(self):
        self.m["artifacts"][0]["zip_sha256"]="f"*64
        with self.assertRaisesRegex(ValueError,"metadata changed"):
            validate(self.m)
    def test_swapped_linux_binary_sha_between_commits_rejected(self):
        self.m["artifacts"][3]["binaries"]["bin/seer_engine_service"]="f"*64
        with self.assertRaisesRegex(ValueError,"16 unique values"):
            validate(self.m)
    def test_release_binary_must_not_implicitly_equal_seer_next(self):
        self.m["artifacts"][0]["binaries"]["bin/seer_engine_service"]=TARGETS["baseline"]
        with self.assertRaisesRegex(ValueError,"confusable with original trial"):
            validate(self.m)
    def test_forged_original_full_years_rejected(self):
        self.m["original_soak_years_certified"]=6
        with self.assertRaisesRegex(ValueError,"stop gate violated"):
            validate(self.m)
    def test_native_dispatch_authorization_rejected(self):
        self.m["soak_dispatch_authorized"]=True
        with self.assertRaisesRegex(ValueError,"stop gate violated"):
            validate(self.m)
    def test_zip_bytes_cannot_be_inferred_from_metadata(self):
        row=self.m["artifacts"][0]
        with self.assertRaisesRegex(ValueError,"ZIP SHA-256"):
            scan_zip(self.m,row,b"not executable nor zip")
    def test_unknown_duplicate_artifact_rejected(self):
        self.m["artifacts"][1]["artifact_id"]=self.m["artifacts"][0]["artifact_id"]
        with self.assertRaisesRegex(ValueError,"duplicate/unknown"):
            validate(self.m)
    def test_reported_source_lock_frozen_and_not_derived_from_gha_run_head(self):
        self.assertEqual(self.m["original_next_frozen_commit"],FROZEN)
        self.assertNotEqual(INNER_COMMITS[LATER],LATER)
        self.assertNotEqual(INNER_COMMITS[EARLIER],EARLIER)
        self.assertNotEqual(INNER_COMMITS[LATER],INNER_COMMITS[EARLIER])

if __name__=="__main__":unittest.main()
