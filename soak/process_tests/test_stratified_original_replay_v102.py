"""v102 exact 53-member original source ZIP replay plus negative pin guards."""
from __future__ import annotations
import copy
import os
from pathlib import Path
import sys
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
import replay_stratified_original_v102 as v

class OriginalNativeSampleReplayV102(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        path=os.getenv("PASTAFARI_V102_SOURCE_ZIP")
        if not path:raise RuntimeError("genuine frozen native source ZIP mandatory")
        cls.raw=Path(path).read_bytes()
        cls.pin=v.load_pin()

    def test_actual_original_archive_sha_and_all_53_members(self):
        self.assertEqual(len(v.validate_zip(self.raw,self.pin)),53)

    def test_real_four_original_pairs_and_full_perf_replay(self):
        out=v.replay(self.raw,self.pin)
        self.assertEqual(out["pairs_checked"],4)
        self.assertEqual(out["five_fields_checked"],20)
        self.assertEqual(out["zip_members_checked"],53)
        self.assertEqual(out["rows"][0]["canonical_fields"],["5000",10,503,20,56])

    def test_truncated_zip_never_awards_day(self):
        with self.assertRaisesRegex(ValueError,"size/SHA"):
            v.replay(self.raw[:-1],self.pin)

    def test_source_zip_byte_mutation_rejected(self):
        raw=bytearray(self.raw);raw[len(raw)//2]^=1
        with self.assertRaisesRegex(ValueError,"size/SHA"):
            v.replay(bytes(raw),self.pin)

    def test_wrong_original_source_commit_rejected(self):
        pin=copy.deepcopy(self.pin)
        pin["source_commits"]["TS-MR"]="0"*40
        with self.assertRaisesRegex(ValueError,"source pin"):
            v.replay(self.raw,pin)

    def test_original_year_credit_rejected(self):
        pin=copy.deepcopy(self.pin)
        pin["full_original_years_certified"]=1
        with self.assertRaisesRegex(ValueError,"source pin"):
            v.replay(self.raw,pin)

    def test_algorithmic_independence_self_credit_rejected(self):
        pin=copy.deepcopy(self.pin)
        pin["algorithmic_independence_certified"]=True
        with self.assertRaisesRegex(ValueError,"source pin"):
            v.replay(self.raw,pin)

    def test_false_five_part_tuple_rejected(self):
        pin=copy.deepcopy(self.pin)
        pin["rows"][1]["fields"][2]=100
        with self.assertRaisesRegex(ValueError,"five fields"):
            v.replay(self.raw,pin)

    def test_wrong_signed_input_target_rejected(self):
        pin=copy.deepcopy(self.pin)
        pin["ordered_target_days"][1]="-15055657"
        with self.assertRaisesRegex(ValueError,"source pin"):
            v.replay(self.raw,pin)

    def test_source_raw_digest_change_rejected(self):
        pin=copy.deepcopy(self.pin)
        pin["rows"][0]["native_raw_sha256"]["TS-MR"]="0"*64
        with self.assertRaisesRegex(ValueError,"raw engine output"):
            v.replay(self.raw,pin)

if __name__=="__main__":
    unittest.main()
