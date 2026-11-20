"""Synthetic immutable Seer archive/CI/source guards; original F(c,t) not called."""
from __future__ import annotations
import copy
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
import soak_seer_native_archive_v135 as target

def manifest():
    return json.loads((Path(__file__).resolve().parents[1]/"control"/"seer_native_archive_v135.json").read_text())

class FakeGitHub:
    def __init__(self):
        self.run={"id":target.RUN_ID,"head_sha":target.CI_SHA,
                  "status":"completed","conclusion":"success","event":"push"}
        self.jobs={"total_count":1,"jobs":[{
            "id":target.JOB_ID,"status":"completed","conclusion":"success",
            "steps":[{"name":s,"conclusion":"success"} for s in target.CI_STEPS]}]}
        self.artifact={"total_count":1,"artifacts":[{
            "id":target.ARTIFACT_ID,"name":target.ARTIFACT_NAME,
            "digest":"sha256:"+target.ARTIFACT_SHA,
            "size_in_bytes":206012,"expired":False}]}
        self.old={}
        for i in range(561):self.old["src/synthetic_" + str(i)+".py"]=("deadbeef"+str(i),"100644","blob")
        for i in range(616):
            self.old["research/seer-next/results/historical_"+str(i)+".json"]=("beadbeef"+str(i),"100644","blob")
        self.new=copy.deepcopy(self.old)
        for i in range(38):
            self.new["research/seer-next/results/new_artifact_"+str(i)+".json"]=("aabb"+str(i),"100644","blob")
        self.override=None
    def get(self,path):
        if self.override is not None:return self.override(path)
        stem="/repos/"+target.REPO
        if path==stem+"/actions/runs/"+str(target.RUN_ID):return self.run
        if path==stem+"/actions/runs/"+str(target.RUN_ID)+"/jobs?per_page=100":return self.jobs
        if path==stem+"/actions/runs/"+str(target.RUN_ID)+"/artifacts?per_page=100":return self.artifact
        if path in (stem+"/git/trees/"+target.CI_SHA+"?recursive=1",
                    stem+"/git/trees/"+target.FROZEN+"?recursive=1"):
            source=self.old if target.CI_SHA in path else self.new
            return {"truncated":False,"tree":[
                {"path":k,"sha":v[0],"mode":v[1],"type":v[2]}
                for k,v in source.items()]}
        raise AssertionError("Unexpected API request "+path)

def mock_blob(_gh,_repo,_sha,_path):
    s=("import { createReadStream } from 'node:fs';\n"+
       "import { createHash } from 'node:crypto';\n"+
       "baselineBinarySHA256:await sha256(src)\n"+
       "candidateBinarySHA256:await sha256(candidate)\n").encode()
    return s,{"git_blob_sha1":"d0b3a9e139c5e41b057eafb2e332914a72a189b1"}

class NativeArchiveTests(unittest.TestCase):
    def setUp(self):
        self.m=manifest()
        self.fake=FakeGitHub()
        self.p=patch.object(target,"checked_blob",side_effect=mock_blob)
        self.p.start()
        self.addCleanup(self.p.stop)
    def audit_remote(self):
        return target.verify_remote(self.m,self.fake)

    def test_real_metadata_all_1177_common_blobs_and_zero_binary_bytes(self):
        r=target.audit(self.m,self.fake)
        self.assertEqual(r["read_only_cross_commit_ci_and_archive_metadata"]["source_git_blob_identical_to_CI_for_common_paths"],1177)
        self.assertEqual(r["read_only_cross_commit_ci_and_archive_metadata"]["identical_non_results_repository_files"],561)
        self.assertEqual(r["historical_binary_hashes_recorded_not_binaries_reexamined"],2)
        self.assertFalse(r["original_archive_bytes_examined_in_this_execution"])
        self.assertEqual(r["original_full_years_certified"],0)

    def test_original_archive_bytes_not_guessed_without_archive(self):
        self.assertIsNone(target.audit(self.m,self.fake)["original_archive_zip_byte_report"])

    def test_future_queued_CI_rejected(self):
        self.fake.run["status"]="queued"
        with self.assertRaisesRegex(ValueError,"not completed success"):
            self.audit_remote()

    def test_run_from_unpinned_source_commit_rejected(self):
        self.fake.run["head_sha"]="a"*40
        with self.assertRaisesRegex(ValueError,"not completed success"):
            self.audit_remote()

    def test_native_build_step_failure_rejected(self):
        self.fake.jobs["jobs"][0]["steps"][1]["conclusion"]="failure"
        with self.assertRaisesRegex(ValueError,"stage not successful"):
            self.audit_remote()

    def test_wrong_historical_job_rejected(self):
        self.fake.jobs["jobs"][0]["id"]=555
        with self.assertRaisesRegex(ValueError,"job not complete success"):
            self.audit_remote()

    def test_historical_artifact_expired_rejected(self):
        self.fake.artifact["artifacts"][0]["expired"]=True
        with self.assertRaisesRegex(ValueError,"no longer matches"):
            self.audit_remote()

    def test_wrong_historical_artifact_digest_rejected(self):
        self.fake.artifact["artifacts"][0]["digest"]="sha256:"+"0"*64
        with self.assertRaisesRegex(ValueError,"no longer matches"):
            self.audit_remote()

    def test_wrong_historical_artifact_identity_rejected(self):
        self.fake.artifact["artifacts"][0]["id"]=0
        with self.assertRaisesRegex(ValueError,"no longer matches"):
            self.audit_remote()

    def test_changes_in_original_source_path_rejected(self):
        self.fake.new["src/synthetic_0.py"]=("beef","100644","blob")
        with self.assertRaisesRegex(ValueError,"differs outside"):
            self.audit_remote()

    def test_differences_in_non_results_file_rejected(self):
        self.fake.new["src/new.py"]=("add","100644","blob")
        with self.assertRaisesRegex(ValueError,"differs outside"):
            self.audit_remote()

    def test_truncated_git_tree_rejected(self):
        old=self.fake.get
        def broken(p):
            x=old(p)
            if "/git/trees/" in p:return {**x,"truncated":True}
            return x
        self.fake.override=broken
        with self.assertRaisesRegex(ValueError,"truncated/incomplete"):
            self.audit_remote()

    def test_recorded_binary_hash_promotion_rejected(self):
        self.m["original_full_years_certified"]=6
        with self.assertRaisesRegex(ValueError,"stop state mutated"):
            self.audit_remote()

    def test_static_manifest_replacement_of_reported_binary_sha_rejected(self):
        self.m["files"]["ab.json"]["reported_candidate_binary_sha256"]="0"*64
        with self.assertRaisesRegex(ValueError,"original binary SHA receipt changed"):
            self.audit_remote()

    def test_byte_checker_fails_on_fake_zip_even_if_metadata_valid(self):
        with self.assertRaisesRegex(ValueError,"full ZIP bytes/digest mismatch"):
            target.verify_archive(self.m,b"fake archive")

    def test_source_hashing_script_mismatch_rejected(self):
        with patch.object(target,"checked_blob",return_value=(
            b"createHash('sha256')",{"git_blob_sha1":"0"*40})):
            with self.assertRaisesRegex(ValueError,"reported binary hashes changed"):
                self.audit_remote()

if __name__=="__main__":
    unittest.main()
