"""v098: strict release approval tests, no converter run or remote action."""
from __future__ import annotations
import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
import approve_third_original_archive_v098 as v


class OriginalMarathiReleaseAdmissionV098(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.before="a"*40
        cls.obj={
            "schema":v.SCHEMA,"release_tag":v.TAG,"source_branch":v.BRANCH,
            "approved_parent_sha":cls.before,"asset":v.exact_asset(),
            "whole_original_years_certified":0,
            "independence_certified":False,"canonical_oracle_certified":False,
        }

    def test_valid_pinned_17_member_witness_is_approvable(self):
        self.assertTrue(v.approve(self.obj,self.before))
        self.assertEqual(self.obj["asset"]["members"],17)

    def test_source_artifact_and_run_are_not_free_form(self):
        self.assertEqual(self.obj["asset"]["artifact_id"],14454273351)
        self.assertEqual(self.obj["asset"]["run_id"],44363057604)

    def test_change_archived_sha_fails_closed(self):
        obj=copy.deepcopy(self.obj)
        obj["asset"]["sha256"]="0"*64
        with self.assertRaises(ValueError):v.approve(obj,self.before)

    def test_change_immutable_source_commit_fails_closed(self):
        obj=copy.deepcopy(self.obj)
        obj["asset"]["source_commits"]["TS-MR"]="0"*40
        with self.assertRaises(ValueError):v.approve(obj,self.before)

    def test_wrong_parent_or_branch_rejected(self):
        for k,x in (("approved_parent_sha","b"*40),("source_branch","main")):
            with self.subTest(k=k),self.assertRaises(ValueError):
                v.approve({**self.obj,k:x},self.before)

    def test_whole_year_self_credit_rejected(self):
        with self.assertRaises(ValueError):
            v.approve({**self.obj,"whole_original_years_certified":1},self.before)

    def test_independence_or_oracle_self_credit_rejected(self):
        for k in ("independence_certified","canonical_oracle_certified"):
            with self.subTest(k=k),self.assertRaises(ValueError):
                v.approve({**self.obj,k:True},self.before)

    def test_extra_field_or_not_a_draft_tag_rejected(self):
        for obj in ({**self.obj,"unknown":123},
                    {**self.obj,"release_tag":"production-release"}):
            with self.assertRaises(ValueError):v.approve(obj,self.before)

    def test_canonical_request_bytes_unique_and_newline(self):
        b=v.canon(self.obj)
        self.assertTrue(b.endswith(b"\n"))
        self.assertEqual(b,v.canon(v.pair_unique(list(self.obj.items()))))

    def test_approved_fresh_retry_request_path(self):
        path="soak/control/original_archive_requests/typescript-marathi-1021-v098-retry01.json"
        self.assertEqual(v.approved_new_request_path("A\t"+path),path)

    def test_multiple_or_modified_request_paths_fail_closed(self):
        bad=("M\tsoak/control/original_archive_requests/typescript-marathi-1021-v098.json",
             "A\tsoak/control/original_archive_requests/wrong.json",
             "A\tsoak/control/original_archive_requests/typescript-marathi-1021-v098-retry001.json",
             "A\tsoak/control/original_archive_requests/typescript-marathi-1021-v098.json\nA\tother")
        for case in bad:
            with self.subTest(case=case),self.assertRaises(ValueError):
                v.approved_new_request_path(case)

    def test_duplicate_json_keys_fails_closed(self):
        with self.assertRaisesRegex(ValueError,"duplicate"):
            v.pair_unique([("a",1),("a",2)])


if __name__=="__main__":
    unittest.main()
