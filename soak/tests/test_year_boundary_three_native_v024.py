"""Three-original-path year5000 *candidate*, without conferring independence."""
import json
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]/"control"
FILE=ROOT/"foundation_year5000_three_native_candidate_v024.json"
OLD=ROOT/"foundation_year5000_two_native_candidate_v021.json"


class ThreeYearBoundaryCandidateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.d=json.loads(FILE.read_text(encoding="utf8"))
        cls.old=json.loads(OLD.read_text(encoding="utf8"))

    def test_all_original_paths_present_without_derivative(self):
        d=self.d
        self.assertEqual(d["schema"],"PASTAFARI_SOAK_THREE_NATIVE_YEAR5000_BOUNDARY_CANDIDATE/1")
        self.assertEqual(d["status"],"THREE_NATIVE_YEAR5000_CANDIDATES_AGREE_NOT_CERTIFIED")
        self.assertEqual(len(d["sources"]),3)
        self.assertEqual({x["id"] for x in d["sources"]},{"REF-41","REF-24","KOTLIN-CY-PROD"})
        self.assertEqual(len({x["commit"] for x in d["sources"]}),3)
        self.assertTrue(all(len(x["commit"])==40 for x in d["sources"]))
        self.assertFalse(d["derived_js_counted_as_original"])

    def test_exact_geometry_matches_previous_uncertified_candidate(self):
        d,old=self.d,self.old
        for key in ("calculation_day","year","open_gate_index","close_gate_index",
                    "open_gate_day","close_gate_day","first_target_day","last_target_day"):
            self.assertEqual(d[key],old[key],key)
        self.assertEqual(d["candidate_2_source_sha256"],old["candidate_receipt_sha256"])
        self.assertEqual(int(d["year_days"]),
                         int(d["last_target_day"])-int(d["first_target_day"])+1)
        self.assertTrue(int(d["open_gate_day"])<int(d["calculation_day"])<=int(d["close_gate_day"]))

    def test_no_false_independence_or_year_acceptance(self):
        d=self.d
        for key in ("source_independence_certified","independent_canonical_oracle_certified",
                    "comparison_of_all_year_days_completed","main_changes_allowed"):
            self.assertIs(d[key],False)
        self.assertEqual(d["validated_entire_year_count"],0)
        self.assertRegex(d["kotlin_native_output_sha256"],r"^[0-9a-f]{64}$")
        self.assertRegex(d["kotlin_evidence_zip_sha256"],r"^[0-9a-f]{64}$")


if __name__=="__main__":
    unittest.main()
