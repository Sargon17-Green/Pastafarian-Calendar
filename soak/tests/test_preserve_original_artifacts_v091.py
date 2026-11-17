"""v091 tests: archive release authorization never counts a native year."""
from __future__ import annotations
import copy
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "runner"))
import preserve_original_artifacts_v091 as m


class ReleaseArchiveAdmission(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root=Path(__file__).resolve().parents[2]
        cls.entries=m.source_index(cls.root)
        cls.before="a"*40
        cls.valid={
            "schema":m.SCHEMA,
            "release_tag":m.TAG,
            "approved_parent_sha":cls.before,
            "source_branch":m.BRANCH,
            "original_year":"5000",
            "calculation_day":"-15055671",
            "assets":cls.entries,
            "whole_original_years_certified":0,
            "independence_certified":False,
        }

    def test_seven_exact_github_source_zip_ids_and_shas(self):
        self.assertEqual([x["ordinal"] for x in self.entries],list(range(1015,1022)))
        self.assertEqual(self.entries[0]["artifact_id"],14186295655)
        self.assertEqual(self.entries[-1]["artifact_id"],14281261657)
        self.assertTrue(all(len(x["sha256"])==64 for x in self.entries))

    def test_exact_canonical_request_accepted(self):
        self.assertTrue(m.validate_request(self.valid,self.entries,self.before))

    def test_modified_original_artifact_digest_rejected(self):
        bad=copy.deepcopy(self.valid)
        bad["assets"][-1]["sha256"]="0"*64
        with self.assertRaises(ValueError):
            m.validate_request(bad,self.entries,self.before)

    def test_truncated_source_archive_prefix_rejected(self):
        bad=copy.deepcopy(self.valid)
        bad["assets"]=bad["assets"][:-1]
        with self.assertRaises(ValueError):
            m.validate_request(bad,self.entries,self.before)

    def test_unapproved_commit_parent_rejected(self):
        bad=dict(self.valid,approved_parent_sha="b"*40)
        with self.assertRaises(ValueError):
            m.validate_request(bad,self.entries,self.before)

    def test_year_soak_credit_or_independence_claim_rejected(self):
        for field,val in (("whole_original_years_certified",1),
                          ("independence_certified",True)):
            with self.subTest(field=field):
                bad=dict(self.valid,**{field:val})
                with self.assertRaises(ValueError):
                    m.validate_request(bad,self.entries,self.before)

    def test_additional_unknown_request_field_rejected(self):
        with self.assertRaises(ValueError):
            m.validate_request(dict(self.valid,comment="trust me"),self.entries,self.before)

    def test_noncanonical_and_duplicate_request_bytes_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            path=Path(d)/"archive.json"
            path.write_bytes(b'{"schema":"a","schema":"b"}\n')
            with self.assertRaisesRegex(ValueError,"duplicate"):
                m.request_data(path)
            path.write_text('{"b":1,"a":2}\n')
            with self.assertRaisesRegex(ValueError,"canonical"):
                m.request_data(path)

    def test_missing_raw_archive_fails_before_upload(self):
        manifest={
            "schema":m.MANIFEST_SCHEMA,"release_tag":m.TAG,
            "assets":self.entries,"whole_original_years_certified":0,
        }
        with tempfile.TemporaryDirectory() as d:
            with self.assertRaises(ValueError):
                m.verify_archives(self.root,manifest,Path(d),
                                  Path(d),Path(d))

    def test_approved_new_retry_request_file_accepted(self):
        path="soak/control/original_archive_requests/source-1015-1021-v091-retry01.json"
        self.assertEqual(m.check_new_request_path("A\t"+path),path)

    def test_modified_and_wrong_new_request_files_rejected(self):
        for raw in ("M\tsoak/control/original_archive_requests/source-1015-1021-v091-retry01.json",
                    "A\tsoak/control/original_archive_requests/random.json",
                    "A\tsoak/control/original_archive_requests/source-1015-1021-v091-retry999.json",
                    "A\tsoak/control/original_archive_requests/source-1015-1021-v091-retry01.json\nA\textra"):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                m.check_new_request_path(raw)

    def test_archive_tag_and_source_branch_cannot_change(self):
        for k,v in (("release_tag","arbitrary-tag"),
                    ("source_branch","main"),
                    ("original_year","5001")):
            with self.subTest(field=k):
                bad=dict(self.valid,**{k:v})
                with self.assertRaises(ValueError):
                    m.validate_request(bad,self.entries,self.before)


if __name__ == "__main__":
    unittest.main()
