"""Aggregate three-year source-classification and evidence arithmetic gates v032.

A complete DERIVED cross-language year is not an original/native 10k-year soak.
"""
import json
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/"control/three_derived_years_13937_cross_source_v032.json"
BOUNDS=ROOT/"control/adjacent_three_original_year_boundaries_v030.json"


class ThreeYearDerivedWitnessTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.r=json.loads(DATA.read_text(encoding="utf8"))
        cls.b=json.loads(BOUNDS.read_text(encoding="utf8"))

    def test_years_contiguous_and_counts_exact(self):
        r=self.r
        self.assertEqual(r["schema"],"PASTAFARI_THREE_YEAR_TWO_SOURCE_DERIVED_AGREEMENT_V032/1")
        self.assertEqual(r["status"],"THREE_DERIVED_YEARS_13937_ROWS_MATCH_SAMPLED_NATIVE_NOT_CERTIFIED")
        self.assertEqual([x["year"] for x in r["years"]],[4999,5000,5001])
        for index,y in enumerate(r["years"]):
            start,finish=int(y["first_target"]),int(y["last_target"])
            self.assertEqual(finish-start+1,y["days"])
            self.assertEqual(y["matched_derived_day_pairs"],y["days"])
            if index:
                self.assertEqual(int(r["years"][index-1]["last_target"])+1,start)
        self.assertEqual(sum(y["days"] for y in r["years"]),13937)
        self.assertEqual(r["full_derived_day_pairs_match"],13937)
        self.assertEqual(r["full_derived_7_column_value_matches"],7*13937)

    def test_original_native_samples_not_conflated_with_derived(self):
        r=self.r
        self.assertEqual(sum(y["original_native_python_sample_matches"] for y in r["years"]),26)
        self.assertEqual(sum(y["original_native_kotlin_sample_matches"] for y in r["years"]),26)
        self.assertEqual(r["original_native_date_sample_matches_per_engine"],26)
        self.assertEqual(r["original_native_date_sample_matches_both_engines"],52)
        self.assertEqual(r["verified_unchanged_original_fct_full_year_comparisons"],0)
        self.assertFalse(r["all_13937_days_individually_verified_via_both_original_fct"])
        self.assertFalse(r["independent_source_lineage_certified"])
        self.assertFalse(r["canonical_oracle_certified"])
        self.assertFalse(r["long_soak_started"])
        self.assertFalse(r["windows_workloads_launched"])
        self.assertFalse(r["main_modified"])

    def test_adjacent_original_boundary_source_agreement_is_not_oracle(self):
        b=self.b
        self.assertEqual(b["schema"],
            "PASTAFARI_THREE_ADJACENT_ORIGINAL_YEAR_BOUNDARY_WITNESS_V030/1")
        self.assertEqual(b["native_boundary_columns_compared"],27)
        self.assertIsNone(b["first_mismatch"])
        self.assertEqual(b["original_full_date_calls"],0)
        self.assertFalse(b["oracle_independent"])
        self.assertFalse(b["algorithmic_independence_certified"])
        self.assertEqual([y["length_days"] for y in b["years"]],[4126,4244,5567])
        self.assertEqual([y["first_target_day"] for y in b["years"]],
            [x["first_target"] for x in self.r["years"]])
        self.assertEqual([y["last_target_day"] for y in b["years"]],
            [x["last_target"] for x in self.r["years"]])

    def test_evidence_sha_and_pinned_commits_have_immutable_shape(self):
        r=self.r
        for x in [r["evidence_artifact_zip_sha256"],
                  r["kotlin_derived_4999_and_5001_combined_tsv_sha256"],
                  r["kotlin_derived_5000_tsv_sha256"],
                  r["kotlin_original_12_sample_tsv_sha256"]]:
            self.assertRegex(x,r"^[0-9a-f]{64}$")
        for y in r["years"]:
            self.assertRegex(y["python_derived_sha256"],r"^[0-9a-f]{64}$")
        a=r["original_reference_commits"]
        self.assertEqual(len(a["python"]),40)
        self.assertEqual(len(a["kotlin"]),40)
        self.assertNotEqual(a["python"],a["kotlin"])


if __name__=="__main__":
    unittest.main()
