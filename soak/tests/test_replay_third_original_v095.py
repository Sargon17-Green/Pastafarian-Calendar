"""v095: fail-closed evidence ZIP/pin replay tests, no native converter calls."""
from __future__ import annotations
import copy
import io
from pathlib import Path
import sys
import unittest
import warnings
import zipfile

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
import replay_third_original_v095 as v


def make_zip(rows):
    buffer=io.BytesIO()
    with zipfile.ZipFile(buffer,"w",compression=zipfile.ZIP_DEFLATED) as z:
        for path,body in rows:z.writestr(path,body)
    return buffer.getvalue()


class SourceReplayNegativeTests(unittest.TestCase):
    def setUp(self):
        self.manifest=v.pinned()

    def test_real_17_member_manifest_shape(self):
        v.validate_manifest(self.manifest)
        self.assertEqual(len(self.manifest["member_sha256"]),17)

    def test_pinned_sources_and_original_pair_counts(self):
        self.assertEqual(self.manifest["source_commits"]["TS-MR"],v.TS_COMMIT)
        self.assertEqual(self.manifest["source_commits"]["REF-41"],v.PY_COMMIT)
        self.assertEqual(self.manifest["original_native_pairs_compared"],2)
        self.assertEqual(self.manifest["whole_original_years_certified"],0)

    def test_modified_artifact_sha_refused(self):
        p=copy.deepcopy(self.manifest)
        p["artifact"]["sha256"]="0"*64
        with self.assertRaises(ValueError):
            v.validate_manifest(p)

    def test_wrong_original_source_identity_refused(self):
        p=copy.deepcopy(self.manifest)
        p["source_commits"]["TS-MR"]="0"*40
        with self.assertRaises(ValueError):
            v.validate_manifest(p)

    def test_year_credit_refused(self):
        p=copy.deepcopy(self.manifest)
        p["whole_original_years_certified"]=1
        with self.assertRaises(ValueError):
            v.validate_manifest(p)

    def test_independence_self_attestation_refused(self):
        p=copy.deepcopy(self.manifest)
        p["algorithmic_independence_certified"]=True
        with self.assertRaises(ValueError):
            v.validate_manifest(p)

    def test_wrong_frozen_second_day_refused(self):
        p=copy.deepcopy(self.manifest)
        p["target_days"][-1]="-15055658"
        with self.assertRaises(ValueError):
            v.validate_manifest(p)

    def test_modified_zip_outer_sha_blocked_before_native_replay(self):
        with self.assertRaisesRegex(ValueError,"ZIP SHA/size"):
            v.verify_archive(b"fake original zip",self.manifest,Path("."),Path("."))

    def test_missing_evidence_member_fails_closed(self):
        raw=make_zip([("x.log",b"abc")])
        with self.assertRaisesRegex(ValueError,"member set"):
            v.zip_members(raw,{"x.log":v.sha(b"abc"),"missing":v.sha(b"z")})

    def test_modified_member_content_refused(self):
        raw=make_zip([("x.log",b"abc")])
        with self.assertRaisesRegex(ValueError,"ZIP member changed"):
            v.zip_members(raw,{"x.log":v.sha(b"abd")})

    def test_duplicate_zip_member_refused(self):
        with warnings.catch_warnings():
            warnings.simplefilter("ignore",UserWarning)
            raw=make_zip([("x.log",b"abc"),("x.log",b"abc")])
        with self.assertRaisesRegex(ValueError,"duplicate"):
            v.zip_members(raw,{"x.log":v.sha(b"abc"),"y":v.sha(b"def")})

    def test_duplicate_json_keys_refused(self):
        with self.assertRaisesRegex(ValueError,"duplicate JSON"):
            v.decode(b'{"schema":"first","schema":"second"}')


if __name__=="__main__":
    unittest.main()
