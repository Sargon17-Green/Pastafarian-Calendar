"""v096 real pinned cross-archive three-native-engine proof, with negative mutations.

The tests replay immutable raw ZIP witnesses only; no original F(c,t) calls.
"""
from __future__ import annotations
import copy
import os
from pathlib import Path
import sys
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
import verify_three_original_artifacts_v096 as v


class TriangulatedOriginalNativeEvidenceV096(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        t=os.environ.get("PASTAFARI_V096_TS_ZIP")
        k=os.environ.get("PASTAFARI_V096_PY_KT_ZIP")
        if not t or not k:
            raise RuntimeError("both genuine GitHub original source evidence ZIPs mandatory")
        cls.ts=Path(t).read_bytes()
        cls.kotlin=Path(k).read_bytes()
        cls.kpin=v.js(v.KPIN.read_bytes())
        cls.tpin=v.js(v.TPIN.read_bytes())

    def replay(self,ts=None,k=None,kpin=None,tpin=None):
        return v.replay(self.ts if ts is None else ts,
                        self.kotlin if k is None else k,
                        self.kpin if kpin is None else kpin,
                        self.tpin if tpin is None else tpin)

    def test_two_real_three_engine_original_pairs_match(self):
        r=self.replay()
        self.assertEqual(r["matched_target_days"],2)
        self.assertEqual(r["matching_five_field_engine_observations"],6)
        self.assertEqual(r["matching_field_comparisons"],20)
        self.assertEqual([x["canonical_fields"] for x in r["rows"]],
                         [[5000,14,11,1,42],[5000,14,12,42,45]])

    def test_original_kotlin_archive_tamper_refused(self):
        with self.assertRaisesRegex(ValueError,"frozen original source artifacts"):
            self.replay(k=self.kotlin[:-1]+bytes([self.kotlin[-1]^1]))

    def test_original_typescript_archive_tamper_refused(self):
        with self.assertRaisesRegex(ValueError,"frozen original source artifacts"):
            self.replay(ts=self.ts[:-1]+bytes([self.ts[-1]^1]))

    def test_kotlin_pin_changed_original_sha_refused(self):
        p=copy.deepcopy(self.kpin)
        p["original_source_commits"]["REF-41"]="0"*40
        with self.assertRaisesRegex(ValueError,"frozen original source artifacts"):
            self.replay(kpin=p)

    def test_typescript_pin_changed_original_sha_refused(self):
        p=copy.deepcopy(self.tpin)
        p["source_commits"]["TS-MR"]="0"*40
        with self.assertRaisesRegex(ValueError,"frozen original source artifacts"):
            self.replay(tpin=p)

    def test_first_difference_in_first_archive_refused(self):
        p=copy.deepcopy(self.kpin)
        p["comparison"]["first_mismatch"]={"target_day":"-15055660"}
        with self.assertRaisesRegex(ValueError,"frozen original source artifacts"):
            self.replay(kpin=p)

    def test_no_whole_year_or_independence_credit(self):
        result=self.replay()
        self.assertEqual(result["new_unique_days_certified"],0)
        self.assertEqual(result["whole_original_years_certified"],0)
        self.assertFalse(result["algorithmic_independence_certified"])
        self.assertFalse(result["canonical_oracle_certified"])
        self.assertFalse(result["windows_run_started"])


if __name__=="__main__":
    unittest.main()
