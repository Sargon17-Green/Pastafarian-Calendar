"""Verify frozen 3-day Kotlin native provenance without promoting it to independence."""
import json
from pathlib import Path
import unittest

DATA=Path(__file__).resolve().parents[1]/"control/kotlin_original_production_three_day_candidate_v023.json"


class KotlinOriginalCandidateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.d=json.loads(DATA.read_text(encoding="utf-8"))

    def test_original_production_provenance_and_status(self):
        d=self.d
        self.assertEqual(d["schema"],"PASTAFARI_SOAK_THIRD_ORIGINAL_PRODUCTION_CANDIDATE/1")
        self.assertEqual(d["status"],"THREE_PINNED_KOTLIN_PRODUCTION_DATES_MATCH_NOT_CERTIFIED")
        self.assertEqual(len(d["original_commit"]),40)
        self.assertEqual(len(d["original_python_reference_commit"]),40)
        self.assertNotEqual(d["original_commit"],d["original_python_reference_commit"])
        self.assertFalse(d["original_kotlin_source_was_edited"])
        self.assertFalse(d["algorithmic_independence_certified"])
        self.assertFalse(d["entire_year_tested"])
        self.assertFalse(d["main_changes_permitted"])
        self.assertEqual(d["verified_full_year_comparisons"],0)

    def test_native_rows_are_consecutive_exact(self):
        d=self.d
        rows=d["matched_native_rows"]
        self.assertEqual(len(rows),3)
        c=int(d["calculated_day"])
        for i,row in enumerate(rows):
            with self.subTest(target=i):
                self.assertEqual(len(row),7)
                self.assertEqual([int(x) for x in row[:2]],[c,c+i-1])
                self.assertEqual(int(row[2]),5000)
                self.assertTrue(all(int(v)>0 for v in row[3:]))
        self.assertEqual(d["matched_numeric_date_fields"],15)
        self.assertEqual(d["matched_seven_column_fields"],21)

    def test_evidence_identity_is_explicit(self):
        d=self.d
        self.assertEqual(d["run_url"],
            "https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43647140743")
        for sha in (d["original_python_sha256"], d["locally_compiled_jar_sha256"],
                    d["artifact_zip_sha256"], *d["native_output_hashes"].values()):
            self.assertRegex(sha,r"^[0-9a-f]{64}$")
        self.assertGreater(d["observed_kotlin_max_rss_kib"],0)
        self.assertGreater(d["observed_python_max_rss_kib"],0)


if __name__=="__main__":
    unittest.main()
