"""Frozen observation contract v046. Hashes are evidence references, NOT an oracle.

Never self-certifies a full-year soak or an independent source lineage.
"""
from __future__ import annotations

import json
from pathlib import Path
import re
import unittest


DATA=Path(__file__).resolve().parents[1]/"control/supervised_one_day_original_py_kotlin_v046.json"


class OneDayObservedOriginalSourcesWitnessTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data=json.loads(DATA.read_text(encoding="utf8"))

    def test_exact_calculation_coordinates_and_five_matching_fields(self):
        d=self.data
        self.assertEqual(d["status"],"ONE_ORIGINAL_FCT_DAY_PER_ENGINE_FIVE_FIELDS_AGREE_NOT_FULL_YEAR")
        self.assertEqual(d["schema"],"PASTAFARI_SUPERVISED_ORIGINAL_PYTHON_KOTLIN_PILOT_V046/1")
        self.assertEqual(d["calculation_day"],"-15055671")
        self.assertEqual(d["target_day"],"-15055671")
        self.assertEqual(d["five_canonical_date_fields"],["5000",10,503,20,56])
        self.assertEqual(d["original_pairwise_date_rows_compared"],1)
        self.assertEqual(d["canonical_date_fields_matched"],5)
        self.assertIsNone(d["first_mismatch"])

    def test_two_real_original_sources_not_synthetic_or_derived(self):
        sources=self.data["originals"]
        self.assertEqual([s["engine"] for s in sources],["REF-41","PROD-KT-CY"])
        self.assertEqual([s["native_date_calls_confirmed"] for s in sources],[1,1])
        self.assertEqual([s["os_process_exit_code"] for s in sources],[0,0])
        self.assertEqual(sources[0]["commit"],"0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4")
        self.assertEqual(sources[1]["commit"],"0c703446d8a3b7435698bd16402ac5fa30e461c9")
        self.assertNotEqual(sources[0]["source_family"],sources[1]["source_family"])
        self.assertEqual(self.data["newly_supervised_full_date_pair_observations"],1)

    def test_all_evidence_hashes_pinned_not_manufactured_approval(self):
        d=self.data
        digests=[
            d["github_artifact_zip_sha256"],
            d["originals"][0]["native_raw_sha256"],
            d["originals"][0]["native_normalized_sha256"],
            d["originals"][1]["native_raw_os_stdout_sha256"],
            d["originals"][1]["compiled_original_jar_sha256"],
        ]
        for digest in digests:
            self.assertRegex(digest,r"^[0-9a-f]{64}$")
        self.assertEqual(d["github_artifact_id"],14181487872)
        self.assertIn("/actions/runs/43765573521",d["github_action_run"])

    def test_v043_javascript_resource_exhaustion_is_not_date_mismatch(self):
        x=self.data["javascript_original_pilot"]
        self.assertEqual(x["engine"],"REF-24")
        self.assertEqual(x["status"],"BLOCKED_HEAP_MEMORY_NO_NATIVE_DATE_RETURNED")
        self.assertEqual([v["heap_mib"] for v in x["attempts"]],[384,1024])
        self.assertEqual(x["original_native_date_comparisons_credited"],0)

    def test_no_false_full_year_or_algorithmic_independence_credit(self):
        d=self.data
        self.assertEqual(d["prior_derived_annual_date_pairs_matched"],17506)
        self.assertEqual(d["prior_original_Fct_samples_per_python_kotlin_engine"],33)
        self.assertEqual(d["original_native_full_year_soak_passes_certified"],0)
        for k in ("canonical_oracle_certified","algorithmic_independence_certified",
                  "ten_thousand_year_soak_started","windows_host_used","main_modified"):
            self.assertIs(d[k],False,k)


if __name__=="__main__":
    unittest.main()
