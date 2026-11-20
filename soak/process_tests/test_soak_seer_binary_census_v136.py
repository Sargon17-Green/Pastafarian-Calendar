"""Synthetic v136 fail-closed CI metadata and prebuilt ZIP provenance tests."""
from __future__ import annotations
import copy
import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
from soak_seer_binary_census_v136 import (
    audit_online,scan_zip,validate,
    HEAD,REPO,PREBUILT_SHA,PREBUILT_NAME,PREBUILT_ID,PREBUILT_RUN,
    EXPERIMENT_SHA,EXPERIMENT_NAME,EXPERIMENT_ID,EXPERIMENT_RUN,
    EXPECTED_ARTIFACTS,RUN_IDS)

def read_manifest():
    path=Path(__file__).resolve().parents[1]/"control"/"seer_binary_candidate_census_v136.json"
    return json.loads(path.read_text(encoding="utf-8"))

class FakeGitHub:
    def __init__(self):
        self.runs={rid:{"id":rid,"head_sha":HEAD,
            "status":"completed","conclusion":"success","name":"Synthetic completed CI"} for rid in RUN_IDS}
        self.items={}
        for rid in RUN_IDS:
            ids=EXPECTED_ARTIFACTS.get(rid,())
            self.items[rid]=[{"id":i,"name":"synthetic other artifact",
              "digest":"sha256:"+"1"*64,"size_in_bytes":77,"expired":False} for i in ids]
        for rid,aid,name,sha,size in [
            (PREBUILT_RUN,PREBUILT_ID,PREBUILT_NAME,PREBUILT_SHA,4900691),
            (EXPERIMENT_RUN,EXPERIMENT_ID,EXPERIMENT_NAME,EXPERIMENT_SHA,206012)]:
            item=next(v for v in self.items[rid] if v["id"]==aid)
            item.update(name=name,digest="sha256:"+sha,size_in_bytes=size)
        self.more_runs=0
    def get(self,path):
        top="/repos/"+REPO+"/actions/runs?head_sha="+HEAD+"&per_page=100"
        if path==top:
            return {"total_count":len(self.runs)+self.more_runs,
                    "workflow_runs":list(self.runs.values())}
        for rid,items in self.items.items():
            if path=="/repos/"+REPO+"/actions/runs/"+str(rid)+"/artifacts?per_page=100":
                return {"total_count":len(items),"artifacts":items}
        raise AssertionError("unexpected GitHub read: "+path)

class V136Cases(unittest.TestCase):
    def setUp(self):
        self.m=read_manifest()
        self.fake=FakeGitHub()
    def online(self):
        return audit_online(self.fake,self.m)
    def test_expected_11_completed_runs_and_14_artifact_ids(self):
        r=self.online()
        self.assertEqual(r["run_count_at_exact_head"],11)
        self.assertEqual(r["listed_artifact_ids"],14)
        self.assertEqual(r["visible_artifact_ids"],14)
        self.assertTrue(r["prebuilt_artifact_from_different_internal_source_commit"])
        self.assertFalse(r["binary_bytes_downloaded_by_this_remote_metadata_scan"])
    def test_queued_is_not_success(self):
        self.fake.runs[RUN_IDS[0]]["status"]="queued"
        with self.assertRaisesRegex(ValueError,"completion"):
            self.online()
    def test_in_progress_is_not_success(self):
        self.fake.runs[RUN_IDS[0]]["status"]="in_progress"
        with self.assertRaisesRegex(ValueError,"completion"):
            self.online()
    def test_failed_is_not_success(self):
        self.fake.runs[RUN_IDS[0]]["conclusion"]="failure"
        with self.assertRaisesRegex(ValueError,"completion"):
            self.online()
    def test_changed_commit_is_not_accepted(self):
        self.fake.runs[RUN_IDS[0]]["head_sha"]="0"*40
        with self.assertRaisesRegex(ValueError,"commit mismatch"):
            self.online()
    def test_one_missing_run_is_rejected(self):
        del self.fake.runs[RUN_IDS[0]]
        with self.assertRaisesRegex(ValueError,"CI runs missing"):
            self.online()
    def test_excessive_run_pagination_rejected(self):
        self.fake.more_runs=100
        with self.assertRaisesRegex(ValueError,"pagination"):
            self.online()
    def test_target_prebuilt_missing_rejected(self):
        self.fake.items[PREBUILT_RUN]=[
            v for v in self.fake.items[PREBUILT_RUN] if v["id"]!=PREBUILT_ID]
        with self.assertRaisesRegex(ValueError,"target artifact unavailable"):
            self.online()
    def test_non_target_artifact_missing_categorized_not_assumed_failure(self):
        rid=42423264010
        self.fake.items[rid]=[]
        r=self.online()
        self.assertEqual(r["visible_artifact_ids"],12)
        self.assertEqual([x["status"] for x in r["artifacts"]
             if x["run_id"]==rid],["NO_LONGER_RETURNED","NO_LONGER_RETURNED"])
    def test_target_stale_digest_rejected(self):
        item=next(x for x in self.fake.items[PREBUILT_RUN] if x["id"]==PREBUILT_ID)
        item["digest"]="sha256:"+"0"*64
        with self.assertRaisesRegex(ValueError,"hash/identity changed"):
            self.online()
    def test_target_expired_rejected(self):
        item=next(x for x in self.fake.items[EXPERIMENT_RUN] if x["id"]==EXPERIMENT_ID)
        item["expired"]=True
        with self.assertRaisesRegex(ValueError,"target artifact unavailable"):
            self.online()
    def test_manifest_cannot_forge_source_commit(self):
        self.m["native_linux_artifact"]["embedded_source_commit"]=HEAD
        with self.assertRaisesRegex(ValueError,"native prebuilt identity"):
            self.online()
    def test_manifest_cannot_swap_experimental_hash(self):
        self.m["historical_trial"]["reported_binary_hashes"]["candidate"]="0"*64
        with self.assertRaisesRegex(ValueError,"Seer Next experimental"):
            self.online()
    def test_manifest_cannot_authorize_original_Fct(self):
        self.m["soak_dispatch_authorized"]=True
        with self.assertRaisesRegex(ValueError,"dispatch or Soak promotion"):
            self.online()
    def test_zip_bytes_not_a_placeholder(self):
        with self.assertRaisesRegex(ValueError,"ZIP bytes do not match"):
            scan_zip(self.m,b"random-not-a-zip")
    def test_fake_binary_not_upgraded_to_scientific_verification(self):
        r=self.online()
        self.assertTrue(all(x["executables_examined"] is False for x in r["artifacts"]))
    def test_experiment_artifact_digest_locked(self):
        item=next(x for x in self.fake.items[EXPERIMENT_RUN] if x["id"]==EXPERIMENT_ID)
        item["digest"]="sha256:"+"f"*64
        with self.assertRaisesRegex(ValueError,"hash/identity changed"):
            self.online()

if __name__=="__main__":
    unittest.main()
