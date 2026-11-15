"""Adversarial v036 source-identity/lineage gates against derivative masquerading.

Synthetic plan data below is TEST-ONLY and does not constitute approval of any
real converter, canonical calendar oracle or algorithmic independence claim.
"""
from __future__ import annotations

import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "runner"))
from recovery_store import CrashStore, CONTRACT, validate_plan
from source_identity_gate_v036 import (
    IDENTITY_SCHEMA, PROVENANCE_CONTRACT, evaluate_plan_identity,
    validate_provenance_v2,
)


def original_engine(engine_id, *, commit, algo, family, sha, source_class="original"):
    method = "unchanged_reference_Fct" if source_class == "reference" else "unchanged_original_Fct"
    return {
        "id": engine_id, "algorithm_id": algo,
        "source_sha256": sha * 64,
        "binary_sha256": ("a" if sha == "1" else "c") * 64,
        "name_map_sha256": "b" * 64,
        "provenance": {
            "schema": IDENTITY_SCHEMA, "source_class": source_class,
            "source_commit": commit, "repository": "Sargon17-Green/Pastafarian-Calendar",
            "source_path": f"tests/{engine_id}.py", "source_family": family,
            "native_entrypoint": f"{engine_id}.F(c,t)", "execution_method": method,
            "derived_from": None, "original_source_sha256": sha * 64,
        }
    }


def sample_plan():
    return {
        "contract": PROVENANCE_CONTRACT,
        "identity_contract": IDENTITY_SCHEMA,
        "soak_purpose": "EXPERIMENTAL_NATIVE_DIFFERENTIAL_UNCERTIFIED",
        "independence_audit_status": "NOT_CERTIFIED",
        "calculation_day": "-15055672",
        "chunk_days": 2,
        "years": [{"year": "5000", "first_target_day": "-15056173",
                   "last_target_day": "-15056172",
                   "boundary_evidence_sha256": "f" * 64}],
        "engines": [
            original_engine("reference-a", commit="1"*40, algo="family-original-a",
                            family="reference-original-a", sha="1", source_class="reference"),
            original_engine("original-b", commit="2"*40, algo="family-original-b",
                            family="original-source-b", sha="2")
        ]
    }


class StrictSourceIdentityTests(unittest.TestCase):
    def test_v2_source_pair_passes_only_structural_gate(self):
        p=sample_plan()
        validate_plan(p)
        x=validate_provenance_v2(p)
        self.assertEqual(x["engine_count"],2)
        self.assertEqual(x["status"],
            "STRUCTURAL_NATIVE_SOURCE_IDENTITY_PASS_NOT_INDEPENDENCE_CERTIFIED")
        self.assertRegex(x["plan_identity_sha256"],r"^[0-9a-f]{64}$")
        self.assertIs(x["independence_certified"],False)
        self.assertIs(x["unchanged_native_execution_proven"],False)
        self.assertEqual(x["official_soak_years_authorized"],0)

    def test_direct_derivative_rejected(self):
        p=sample_plan()
        e=p["engines"][1]["provenance"]
        e["source_class"]="derived"
        with self.assertRaisesRegex(ValueError,"derived/wrapper"):
            validate_plan(p)

    def test_false_class_original_with_derivation_ref_rejected(self):
        p=sample_plan()
        p["engines"][1]["provenance"]["derived_from"]="reference-a"
        with self.assertRaisesRegex(ValueError,"derived_from"):
            validate_plan(p)

    def test_wrapper_method_rejected_even_if_class_original(self):
        p=sample_plan()
        p["engines"][1]["provenance"]["execution_method"]="annual_derived_reuse"
        with self.assertRaisesRegex(ValueError,"method"):
            validate_plan(p)

    def test_swapped_class_and_native_method_rejected(self):
        p=sample_plan()
        p["engines"][0]["provenance"]["source_class"]="original"
        with self.assertRaisesRegex(ValueError,"class-mismatched"):
            validate_plan(p)

    def test_same_underlying_original_lineage_rejected(self):
        p=sample_plan()
        p["engines"][1]["provenance"]["source_family"]="reference-original-a"
        with self.assertRaisesRegex(ValueError,"duplicate source lineage"):
            validate_plan(p)

    def test_two_wrappers_with_distinct_display_names_same_native_entry_rejected(self):
        p=sample_plan()
        second=p["engines"][1]
        first=p["engines"][0]
        second["provenance"]["source_commit"]=first["provenance"]["source_commit"]
        second["provenance"]["source_path"]=first["provenance"]["source_path"]
        second["provenance"]["native_entrypoint"]=first["provenance"]["native_entrypoint"]
        with self.assertRaisesRegex(ValueError,"impersonates"):
            validate_plan(p)

    def test_same_source_sha_with_altered_provenance_rejected(self):
        p=sample_plan()
        p["engines"][1]["provenance"]["original_source_sha256"]="1"*64
        with self.assertRaisesRegex(ValueError,"not equal"):
            validate_plan(p)

    def test_same_source_bytes_rejected_even_with_distinct_lineage_labels(self):
        p=sample_plan()
        e=p["engines"][1]
        e["source_sha256"]=p["engines"][0]["source_sha256"]
        e["provenance"]["original_source_sha256"]=e["source_sha256"]
        with self.assertRaisesRegex(ValueError,"identical source bytes"):
            validate_plan(p)

    def test_same_native_binary_bytes_rejected_even_if_source_ids_change(self):
        p=sample_plan()
        p["engines"][1]["binary_sha256"]=p["engines"][0]["binary_sha256"]
        with self.assertRaisesRegex(ValueError,"identical executable bytes"):
            validate_plan(p)

    def test_fake_independence_claim_rejected(self):
        p=sample_plan()
        p["independence_audit_status"]="INDEPENDENCE_CERTIFIED"
        with self.assertRaisesRegex(ValueError,"self-certified"):
            validate_plan(p)

    def test_official_soak_claim_rejected_even_with_good_source_strings(self):
        p=sample_plan()
        p["soak_purpose"]="ORIGINAL_NATIVE_SOAK"
        with self.assertRaisesRegex(ValueError,"official soak claim"):
            validate_plan(p)

    def test_source_path_traversal_rejected(self):
        p=sample_plan()
        p["engines"][1]["provenance"]["source_path"]="../derived.py"
        with self.assertRaisesRegex(ValueError,"source path"):
            validate_plan(p)

    def test_missing_required_field_rejected(self):
        p=sample_plan()
        del p["engines"][1]["provenance"]["source_commit"]
        with self.assertRaisesRegex(ValueError,"missing/extra"):
            validate_plan(p)

    def test_original_bridge_with_wrong_source_commit_rejected(self):
        p=sample_plan()
        p["engines"][0]["provenance"]["source_commit"]="0"*39
        with self.assertRaisesRegex(ValueError,"commit SHA"):
            validate_plan(p)

    def test_mixing_different_calculation_days_rejected_on_plan_reopen(self):
        p=sample_plan()
        with tempfile.TemporaryDirectory() as t:
            root=Path(t)/"ledger"
            with CrashStore(root,p) as store:
                status=store.progress()
                self.assertFalse(status["independent_source_lineage_certified"])
                self.assertFalse(status["unchanged_native_stdout_proven"])
                self.assertEqual(status["original_native_full_year_soak_passes_certified"],0)
                self.assertTrue(status["technical_comparisons_only"])
                self.assertIn("NOT_INDEPENDENCE_CERTIFIED",status["source_identity_status"])
            p2=copy.deepcopy(p)
            p2["calculation_day"]="-15055671"
            with self.assertRaisesRegex(Exception,"run plan differs"):
                with CrashStore(root,p2):
                    pass

    def test_mutating_external_plan_cannot_change_frozen_native_coordinates(self):
        p=sample_plan()
        with tempfile.TemporaryDirectory() as tmp:
            with CrashStore(Path(tmp)/"frozen",p) as store:
                pinned=store.plan_sha
                p["calculation_day"]="-15055671"
                p["years"][0]["first_target_day"]="-15055670"
                p["years"][0]["boundary_evidence_sha256"]="e"*64
                p["engines"][0]["provenance"]["source_class"]="derived"
                self.assertEqual(store.plan["calculation_day"],"-15055672")
                self.assertEqual(store.years["5000"]["first_target_day"],"-15056173")
                self.assertEqual(store.years["5000"]["boundary_evidence_sha256"],"f"*64)
                self.assertEqual(store.plan["engines"][0]["provenance"]["source_class"],"reference")
                self.assertEqual(store.plan_sha,pinned)
                self.assertEqual(store._case("5000").calculation_day,"-15055672")
                self.assertEqual(store._chunk("reference-a","5000",0).first_day,"-15056173")
                self.assertFalse(store.progress()["independent_source_lineage_certified"])

    def test_tampering_internal_plan_requires_halt_before_any_dispatch_or_progress(self):
        p=sample_plan()
        with tempfile.TemporaryDirectory() as tmp:
            with CrashStore(Path(tmp)/"tamper",p) as store:
                store.plan["calculation_day"]="-15055671"
                with self.assertRaisesRegex(Exception,"in-memory run plan changed"):
                    store.pending_jobs()
                with self.assertRaisesRegex(Exception,"in-memory run plan changed"):
                    store.progress()
                with self.assertRaisesRegex(Exception,"in-memory run plan changed"):
                    store._chunk("reference-a","5000",0)

    def test_legacy_v1_remains_recoverable_but_not_certified(self):
        p=sample_plan()
        p["contract"]=CONTRACT
        for x in ("identity_contract","soak_purpose","independence_audit_status"):
            p.pop(x)
        for engine in p["engines"]:
            engine.pop("provenance")
        validate_plan(p)
        with tempfile.TemporaryDirectory() as tmp:
            with CrashStore(Path(tmp)/"legacy",p) as store:
                s=store.progress()
                self.assertEqual(s["source_identity_status"],
                                 "LEGACY_PLAN_SOURCE_IDENTITY_NOT_VERIFIED")
                self.assertEqual(s["original_native_full_year_soak_passes_certified"],0)
                self.assertTrue(s["technical_comparisons_only"])

    def test_clone_of_plan_changes_identity_digest(self):
        p=sample_plan()
        original=evaluate_plan_identity(p)["plan_identity_sha256"]
        altered=copy.deepcopy(p)
        altered["calculation_day"]="-15055671"
        self.assertNotEqual(evaluate_plan_identity(altered)["plan_identity_sha256"],original)

    def test_source_id_is_not_cryptographic_independence_proof(self):
        p=sample_plan()
        p["engines"][1]["provenance"]["source_family"]="merely-different-label"
        verdict=evaluate_plan_identity(p)
        self.assertEqual(verdict["official_soak_years_authorized"],0)
        self.assertIs(verdict["source_identity_provenance_is_self_declared"],True)


if __name__=="__main__":
    unittest.main()
