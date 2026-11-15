"""Permanent provenance gates for the full 4244-row *derived* agreement."""
import json
from pathlib import Path
import unittest

P=Path(__file__).resolve().parents[1]/"control/annual_two_derived_4244_agreement_v028.json"


class TwoDerivedAnnualAgreementTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.d=json.loads(P.read_text(encoding="utf-8"))

    def test_complete_pair_and_exact_geometry(self):
        d=self.d
        self.assertEqual(d["schema"],"PASTAFARI_TWO_DERIVED_FULL_YEAR_AGREEMENT_V028/1")
        self.assertEqual(d["status"],
            "TWO_DERIVED_4244_ROW_TRANSCRIPTS_MATCH_NOT_NATIVE_YEAR_CERTIFIED")
        self.assertEqual(d["complete_derived_rows_from_each_source"],4244)
        self.assertEqual(d["compared_derived_rows"],4244)
        self.assertEqual(d["compared_total_columns"],7*4244)
        self.assertIsNone(d["first_mismatch"])
        first,last=int(d["first_target_day"]),int(d["last_target_day"])
        self.assertEqual((first,last),(-15057702,-15053459))
        self.assertEqual(last-first+1,4244)
        self.assertEqual(d["calculation_day"],"-15055671")

    def test_both_originals_identified_not_mutated(self):
        d=self.d
        p,k=d["python"],d["kotlin"]
        self.assertEqual(len(p["original_commit"]),40)
        self.assertEqual(len(k["original_commit"]),40)
        self.assertNotEqual(p["original_commit"],k["original_commit"])
        self.assertEqual(k["changed_original_source_files"],0)
        self.assertEqual(k["copied_kotlin_source_files"],63)
        self.assertIs(k["original_dayAt_method_preserved_verbatim"],True)
        self.assertEqual(p["direct_unchanged_native_sample_matches"],14)
        self.assertEqual(k["direct_unchanged_native_sample_matches"],14)

    def test_gibbs_and_receipt_identity(self):
        d=self.d
        for s in (
            d["python"]["derived_transcript_sha256"],
            d["kotlin"]["derived_kotlin_source_sha256"],
            d["kotlin"]["original_dayAt_function_sha256"],
            d["kotlin"]["derived_wholeYearAt_function_sha256"],
            d["kotlin"]["native_output_tsv_sha256"],
            d["evidence"]["archive_sha256"],
        ):
            self.assertRegex(s,r"^[0-9a-f]{64}$")
        self.assertTrue(d["workflow_run"].endswith("/43689273405"))
        self.assertEqual(d["evidence"]["github_actions_artifact_id"],14151792084)
        self.assertGreater(d["kotlin"]["derived_annual_wall_seconds"],0)
        self.assertGreater(d["kotlin"]["derived_annual_peak_resident_kib"],0)

    def test_derived_agreement_never_certifies_native_soak(self):
        d=self.d
        self.assertIs(d["all_4244_original_unmodified_Fct_calls_executed_in_both_languages"],False)
        self.assertIs(d["two_original_untouched_annual_streams_compared"],False)
        self.assertIs(d["original_engine_algorithms_independent_certified"],False)
        self.assertIs(d["canonical_oracle_certified"],False)
        self.assertIs(d["whole_year_soak_accepted"],False)
        self.assertIs(d["actual_long_soak_started"],False)
        self.assertIs(d["main_modified"],False)
        self.assertIs(d["windows_resources_guarded_no_new_processes"],True)
        self.assertEqual(d["verified_full_year_soak_comparisons"],0)


if __name__=="__main__":
    unittest.main()
