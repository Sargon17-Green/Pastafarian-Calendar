"""Synthetic GitHub Git-tree checks for v130; no actual calendar engine calls."""
from __future__ import annotations

import copy
import hashlib
import sys
from pathlib import Path
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
from soak_scope_coverage_v127 import digest
from soak_triage_path_v130 import run,validate,SCHEMA
from soak_source_census_v129 import APIProblem,git_blob_sha1

REPO="Sargon17-Green/Pastafarian-Calendar"
C="PASTAFARI_SOAK_GITHUB_SOURCE_CENSUS_V129/1"


def fixture():
    rows=[]
    observed=[]
    entries=[]
    blobdata={}
    for i in range(91):
        id_="TRIAGE-%02d"%(i+1) if i<10 else "REF-%02d"%i
        branch="Branch-%02d"%i
        head="%040x"%(100+i)
        path=None if i<10 else "src/source_%02d.py"%i
        rows.append({
            "record_id":id_,"repository":REPO,"branch":branch,"source_path":path,
            "source_status_as_of_2026_11_14":"ARCHIVED","source_url":None})
        observed.append({
            "record_id":id_,"repository":REPO,"branch":branch,
            "archived_source_path":path,"observed_head_commit":head,
            "source_observation":("SOURCE_PATH_NOT_DECLARED" if path is None
                                  else "SOURCE_BYTES_VERIFIED_AT_HEAD")})
        if i<10:
            candidate="src/guess_%02d.py"%i
            entries.append({
                "record_id":id_,"source_commit":head,"candidate_path":candidate,
                "candidate_class":"SOURCE_ENTRYPOINT_CANDIDATE_NOT_REVIEWED",
                "candidate_explicitly_not_certified_as_Fct":True,
                "source_identity_audit_required":True,
                "full_date_native_execution_verified":False,
                "immutable_source_dependency_manifest_verified":False})
            blobdata[(REPO,head,candidate)]=("synthetic candidate %d\n"%i).encode()
    provenance={
        "schema":"PASTAFARI_SOAK_ARCHIVED_ROSTER_PROVENANCE_V127/1",
        "source_file":"fixture","source_internal_schema":"fixture",
        "source_created_utc_date":"2026-11-14","source_scope":"fixture",
        "source_counts":{},"records":rows,"caveats":[]}
    census={
        "schema":C,"provenance_sha256":digest(provenance),"record_count":91,
        "records":observed,"native_date_calls":0,"soak_dispatch_authorized":False}
    manifest={
        "schema":SCHEMA,"source_roster":"soak/control/source_roster_archived_v21_v127.json",
        "source_provenance":"soak/control/source_roster_archived_v21_v127_provenance.json",
        "source_census_contract":C,
        "observation_type":"HISTORICAL_COMMIT_PATH_CANDIDATE_NOT_NATIVE_ENTRYPOINT_CERTIFICATION",
        "entries":entries,"safe_to_promote_into_v127_scope":False,
        "all_source_lineage_unassessed":True,"native_soak_dispatch_authorized":False}
    return manifest,provenance,census,blobdata


class FakeGitHub:
    def __init__(self, blobdata):
        self.blobdata=blobdata
        self.truncated=False
        self.missing=None
        self.wrong_tree_sha=None
        self.source_error=None
        self.drift=None
    def get(self,path):
        if "/git/trees/" in path:
            sha=path.split("/git/trees/",1)[1].split("?",1)[0]
            files=[]
            for (_,commit,file),raw in self.blobdata.items():
                if commit==sha and file!=self.missing:
                    files.append({
                        "type":"blob","path":file,"size":len(raw),
                        "sha":self.wrong_tree_sha or git_blob_sha1(raw)})
            return {"sha":"f"*40,"tree":files,"truncated":self.truncated}
        if "/branches/" in path:
            return {"commit":{"sha":self.drift or (
                path.split("Branch-")[1].zfill(40)
                if False else "0"*40)}}
        raise AssertionError("unexpected path "+path)
    def source(self,repo,commit,path):
        if self.source_error:
            raise APIProblem(self.source_error)
        raw=self.blobdata[(repo,commit,path)]
        return {"source_sha256":hashlib.sha256(raw).hexdigest(),
                "git_blob_sha1":git_blob_sha1(raw),"bytes":len(raw)}


class SourceTriageTests(unittest.TestCase):
    def setUp(self):
        self.m,self.p,self.c,self.data=fixture()
        self.github=FakeGitHub(self.data)
    def result(self):
        return run(self.m,self.p,self.c,self.github)

    def test_ten_candidates_are_bytes_verified_but_not_qualified(self):
        result=self.result()
        self.assertEqual(result["candidate_count"],10)
        self.assertEqual(result["observation_counts"],
                         {"CANDIDATE_BYTES_VERIFIED_NOT_EXECUTABLE_CERTIFIED":10})
        self.assertEqual(result["unresolved_native_entrypoints"],10)
        self.assertFalse(result["scientific_soak_10000_pass"])
        self.assertFalse(result["native_dispatch_authorized"])
        self.assertTrue(all(not r["eligible_for_soak"] and
                            not r["candidate_is_verified_original_Fct"]
                            for r in result["records"]))

    def test_branch_move_retains_pinned_source_and_reports_drift(self):
        self.github.drift="9"*40
        result=self.result()
        self.assertTrue(all(r["source_bytes_status"]==
                            "CANDIDATE_BYTES_VERIFIED_NOT_EXECUTABLE_CERTIFIED"
                            and r["current_head_matches_v129"] is False
                            for r in result["records"]))

    def test_git_tree_truncation_fails_closed(self):
        self.github.truncated=True
        result=self.result()
        self.assertEqual(result["observation_counts"],
                         {"SOURCE_LOOKUP_UNAVAILABLE_TREE_INCOMPLETE_OR_INVALID":10})

    def test_missing_candidate_path_not_smuggled_as_verified(self):
        self.github.missing=self.m["entries"][0]["candidate_path"]
        result=self.result()
        self.assertEqual(result["observation_counts"][
            "CANDIDATE_PATH_NOT_IN_FROZEN_GIT_TREE"],1)

    def test_git_tree_and_content_mismatch_detected(self):
        self.github.wrong_tree_sha="e"*40
        result=self.result()
        self.assertEqual(result["observation_counts"]["GIT_TREE_AND_BLOB_SHA_DISAGREE"],10)

    def test_source_api_denial_is_not_native_execution_failure(self):
        self.github.source_error="NOT_FOUND_OR_NOT_AUTHORIZED"
        result=self.result()
        self.assertEqual(result["observation_counts"][
            "SOURCE_LOOKUP_UNAVAILABLE_NOT_FOUND_OR_NOT_AUTHORIZED"],10)

    def test_candidate_commit_forgery_rejected(self):
        self.m["entries"][0]["source_commit"]="a"*40
        with self.assertRaisesRegex(ValueError,"exact historical v129 head"):
            self.result()

    def test_missing_one_candidate_not_accepted(self):
        self.m["entries"].pop()
        with self.assertRaisesRegex(ValueError,"every unmapped"):
            self.result()

    def test_duplicate_candidate_record_rejected(self):
        self.m["entries"][1]["record_id"]=self.m["entries"][0]["record_id"]
        with self.assertRaisesRegex(ValueError,"duplicate/unmapped"):
            self.result()

    def test_nonnative_entrypoint_promotion_rejected(self):
        self.m["entries"][0]["candidate_explicitly_not_certified_as_Fct"]=False
        with self.assertRaisesRegex(ValueError,"illegally promotes"):
            self.result()

    def test_candidate_path_traversal_rejected(self):
        self.m["entries"][0]["candidate_path"]="../../wrapper.py"
        with self.assertRaisesRegex(ValueError,"unsafe source file path"):
            self.result()

    def test_census_receipt_missing_one_record_rejected(self):
        self.c["records"].pop()
        with self.assertRaisesRegex(ValueError,"dropped/added"):
            self.result()

    def test_branch_overlap_disclosed_not_deduplicated_as_algorithm(self):
        self.p["records"][11]["branch"]=self.p["records"][0]["branch"]
        self.c["provenance_sha256"]=digest(self.p)
        result=self.result()
        self.assertIn(self.p["records"][11]["record_id"],
                      result["records"][0]["other_inventory_records_on_same_branch"])
        self.assertFalse(result["records"][0]["independent_algorithm_certified"])


if __name__=="__main__":
    unittest.main()
