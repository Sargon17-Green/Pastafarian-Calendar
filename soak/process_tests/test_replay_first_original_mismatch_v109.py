"""v109: read-only first-original-mismatch reproduction / strict pin negative tests."""
from __future__ import annotations
import copy
import os
from pathlib import Path
import sys
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
import replay_first_original_mismatch_v109 as v


class FirstOriginalMismatchV109(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        keys=("PASTAFARI_V109_ADA_ZIP","PASTAFARI_V109_FORTRAN_ZIP",
              "PASTAFARI_V109_REFERENCE_ZIP")
        paths=[os.environ.get(k) for k in keys]
        if not all(paths):
            raise RuntimeError("three real immutable original-source ZIP archives are mandatory")
        cls.ada,cls.fortran,cls.ref=[Path(p).read_bytes() for p in paths]
        cls.lock=v.load_lock()

    def test_current_immutable_sources_show_scientific_fail(self):
        r=v.replay(self.lock,self.ada,self.fortran,self.ref)
        self.assertEqual(r["scientific_status"],"CONFIRMED_DIFFERENTIAL_FAIL")
        self.assertTrue(r["stop_new_native_soak_dispatch"])
        self.assertEqual(r["first_difference"],
                         {"field":"month_index","index":4,"ada":30,"reference":20})

    def test_original_python_ts_and_fortran_same_five_fields(self):
        r=v.replay(self.lock,self.ada,self.fortran,self.ref)
        self.assertEqual(r["python_typescript_fortran_original"],[5000,10,503,20,56])
        self.assertEqual(r["native_engines_observed"],4)
        self.assertEqual(r["successful_whole_years"],0)

    def test_original_ada_remains_divergent_and_unchanged(self):
        r=v.replay(self.lock,self.ada,self.fortran,self.ref)
        self.assertEqual(r["ada_original"],[5000,10,503,30,52])
        self.assertNotEqual(r["ada_original"],r["python_typescript_fortran_original"])

    def test_truncated_ada_source_artifact_rejected(self):
        with self.assertRaisesRegex(ValueError,"size/SHA"):
            v.replay(self.lock,self.ada[:-1],self.fortran,self.ref)

    def test_mutated_fortran_source_artifact_rejected(self):
        data=bytearray(self.fortran)
        data[len(data)//2]^=1
        with self.assertRaisesRegex(ValueError,"size/SHA"):
            v.replay(self.lock,self.ada,bytes(data),self.ref)

    def test_wrong_reference_artifact_sha_rejected(self):
        with self.assertRaisesRegex(ValueError,"size/SHA"):
            v.replay(self.lock,self.ada,self.fortran,self.ref[:-3])

    def test_attempted_halt_interlock_bypass_rejected(self):
        bad=copy.deepcopy(self.lock)
        bad["decision"]="CONTINUE_NATIVE_SOAK"
        with self.assertRaisesRegex(ValueError,"dispatch-halt"):
            v.replay(bad,self.ada,self.fortran,self.ref)

    def test_attempted_all_converter_pass_credit_rejected(self):
        bad=copy.deepcopy(self.lock)
        bad["overall_all_converter_pass"]=True
        with self.assertRaisesRegex(ValueError,"dispatch-halt"):
            v.replay(bad,self.ada,self.fortran,self.ref)

    def test_attempted_year_credit_rejected(self):
        bad=copy.deepcopy(self.lock)
        bad["successful_original_source_full_years"]=1
        with self.assertRaisesRegex(ValueError,"dispatch-halt"):
            v.replay(bad,self.ada,self.fortran,self.ref)

    def test_attempted_first_difference_rewrite_rejected(self):
        bad=copy.deepcopy(self.lock)
        bad["first_difference"]["ada"]=20
        with self.assertRaisesRegex(ValueError,"dispatch-halt"):
            v.replay(bad,self.ada,self.fortran,self.ref)

    def test_identical_native_script_outputs_still_have_distinct_sha(self):
        a=v.archive(self.ada,self.lock["run"]["artifact_sha256"],
                    self.lock["run"]["artifact_bytes"],9)
        f=v.archive(self.fortran,self.lock["independent_fourth_observation"]["artifact_sha256"],
                    self.lock["independent_fourth_observation"]["artifact_bytes"],26)
        self.assertNotEqual(v.sha(a["v103-original-ada-native.log"]),
                            v.sha(f["v106-native-output.log"]))

    def test_original_year_and_main_status_immutable(self):
        r=v.replay(self.lock,self.ada,self.fortran,self.ref)
        self.assertEqual(r["successful_ten_thousand_soak_years"],0)
        self.assertFalse(self.lock["main_changes_permitted"])
        self.assertFalse(r["canonical_oracle_independence_proven"])


if __name__=="__main__":
    unittest.main()
