"""Permanent no-cross-c and derived-vs-original certification gates for v034."""
from __future__ import annotations

import json
from pathlib import Path
import unittest

CONTROL = Path(__file__).resolve().parents[1]/"control"
ALT = CONTROL/"alternate_c_3569_derived_full_year_v034.json"
BOUNDS = CONTROL/"alternate_calculation_original_year5000_v033.json"
OLD = CONTROL/"three_derived_years_13937_cross_source_v032.json"


class ChangedCalculationSourceIdentityTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.new=json.loads(ALT.read_text(encoding="utf8"))
        cls.bounds=json.loads(BOUNDS.read_text(encoding="utf8"))
        cls.previous=json.loads(OLD.read_text(encoding="utf8"))

    def test_alternate_calculation_coordinate_not_reused_from_original_c(self):
        n,p=self.new,self.previous
        self.assertEqual(n["calculation_day"],"-15055672")
        self.assertEqual(p["calculation_day"],"-15055671")
        self.assertNotEqual(n["calculation_day"],p["calculation_day"])
        self.assertEqual(n["first_target_day"],"-15056173")
        self.assertEqual(n["last_target_day"],"-15052605")
        self.assertEqual(int(n["last_target_day"])-int(n["first_target_day"])+1,3569)
        self.assertEqual(n["derived_python_rows"],3569)
        self.assertEqual(n["derived_kotlin_rows"],3569)
        self.assertEqual(n["matched_derived_row_pairs"],3569)
        self.assertEqual(n["matched_derived_seven_column_fields"],24983)
        self.assertIsNone(n["first_mismatch"])

    def test_original_year_boundary_witness_for_exact_new_c(self):
        n,b=self.new,self.bounds
        self.assertEqual(b["status"],"THREE_CALCULATION_NATIVE_YEAR_BOUNDS_MATCH_NOT_CERTIFIED")
        self.assertEqual(b["exact_bound_fields_compared"],27)
        self.assertEqual(b["distinct_geometries"],3)
        self.assertIsNone(b["first_mismatch"])
        exact=[r for r in b["cases"] if r["calculation_day"]==n["calculation_day"]]
        self.assertEqual(len(exact),1)
        self.assertEqual(exact[0]["first_target_day"],n["first_target_day"])
        self.assertEqual(exact[0]["last_target_day"],n["last_target_day"])
        self.assertEqual(exact[0]["length_days"],3569)

    def test_two_original_sample_groups_and_hashes(self):
        n=self.new
        self.assertEqual(n["status"],
            "ALTERNATE_C_3569_DERIVED_ROWS_MATCH_SAMPLED_NATIVE_NOT_CERTIFIED")
        self.assertEqual(n["original_python_unchanged_date_sample_matches"],7)
        self.assertEqual(n["original_kotlin_unchanged_date_sample_matches"],7)
        self.assertEqual(len(set(n["sample_targets"])),7)
        self.assertIn(n["calculation_day"],n["sample_targets"])
        self.assertIn(n["first_target_day"],n["sample_targets"])
        self.assertIn(n["last_target_day"],n["sample_targets"])
        self.assertEqual(n["hashes"]["python_derived_year_tsv"],
                         n["hashes"]["kotlin_derived_year_tsv"])
        for digest in n["hashes"].values():
            self.assertRegex(digest,r"^[0-9a-f]{64}$")

    def test_cumulative_derived_and_native_samples_must_be_separate(self):
        n,p=self.new,self.previous
        self.assertEqual(p["full_derived_day_pairs_match"],13937)
        self.assertEqual(n["cumulative_previous_three_year_derived_rows"],13937)
        self.assertEqual(n["cumulative_matched_derived_rows_across_both_calculation_coordinates"],
                         13937+3569)
        self.assertEqual(n["cumulative_original_native_sample_matches_each_engine"],
                         p["original_native_date_sample_matches_per_engine"]+7)
        self.assertEqual(n["verified_original_native_full_year_soak_passes"],0)
        for field in ("all_3569_native_Fct_calls_in_each_engine_executed",
                      "two_unchanged_original_full_year_transcripts_compared",
                      "source_algorithm_independence_certified",
                      "independent_canonical_oracle_certified",
                      "long_soak_started","main_modified"):
            self.assertIs(n[field],False,field)
        self.assertEqual(n["windows_executions_since_blocked_resource_gate"],0)


if __name__=="__main__":
    unittest.main()
