"""Synthetic-only tests for v127; never executes any Pastafarian converter."""
from __future__ import annotations
import copy
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "runner"))
from soak_scope_coverage_v127 import analyze, digest, parse_json

SHA = "a" * 64


def fixture(years=3, engines=3):
    records = [
        {"record_id": f"record{i}", "engine_id": f"eng{i}",
         "algorithm_id": f"alg{i}", "source_kind": "reference"}
        for i in range(engines)
    ]
    records.extend([
        {"record_id": "wrapper0", "engine_id": "wrapper0",
         "algorithm_id": "alg0", "source_kind": "wrapper"},
        {"record_id": "triage0", "engine_id": "triage0",
         "algorithm_id": "unknown0", "source_kind": "triage"},
    ])
    inventory = {"schema": "PASTAFARI_SOAK_SOURCE_ROSTER_V127/1",
                 "records": records}
    dispositions = [
        {"record_id": f"record{i}", "decision": "IN_SCOPE",
         "duplicate_of": None, "review_evidence_sha256": None}
        for i in range(engines)
    ]
    dispositions.extend([
        {"record_id": "wrapper0", "decision": "DUPLICATE_OF",
         "duplicate_of": "record0", "review_evidence_sha256": None},
        {"record_id": "triage0", "decision": "NOT_READY",
         "duplicate_of": None, "review_evidence_sha256": None}
    ])
    planned_years = [
        {"year": str(5000 + j), "first_target_day": str(-20 + 2*j),
         "last_target_day": str(-19 + 2*j),
         "boundary_evidence_sha256": digest({"boundary":j})}
        for j in range(years)
    ]
    plan = {"schema": "PASTAFARI_SOAK_SCOPE_PLAN_V127/1",
            "inventory_sha256": digest(inventory),
            "years": planned_years,
            "dispositions": dispositions,
            "incident_status": "OPEN",
            "dispatch_halt": True,
            "independence_audit": "NOT_CERTIFIED"}
    results = [
        {"engine_id": f"eng{i}", "year": y["year"],
         "status": "UPSTREAM_VERIFIED", "days": 2,
         "daystream_sha256": digest({"year": y["year"], "normalized": [5000,1,1,1,1]}),
         "native_receipt_sha256": digest({"engine":i,"year":y["year"]}),
         "boundary_evidence_sha256": y["boundary_evidence_sha256"]}
        for y in planned_years for i in range(engines)
    ]
    evidence = {"schema": "PASTAFARI_SOAK_UPSTREAM_RECEIPTS_V127/1",
                "plan_sha256": digest(plan),
                "engine_years": results}
    return inventory, plan, evidence


def relock(inventory, plan, evidence):
    plan["inventory_sha256"] = digest(inventory)
    evidence["plan_sha256"] = digest(plan)


class SoakScopeCoverageV127(unittest.TestCase):
    def test_incident_keeps_complete_synthetic_evidence_halted(self):
        inv, plan, rec = fixture()
        result = analyze(inv, plan, rec)
        self.assertEqual(result["status"], "INCIDENT_HALT")
        self.assertTrue(result["structural_coverage_complete"])
        self.assertEqual(result["structurally_equal_engine_year_pairs"], 6)
        self.assertEqual(result["contiguous_structurally_equal_years"], 3)
        self.assertFalse(result["official_soak_10000_pass"])

    def test_reviewed_complete_is_still_not_scientific_certification(self):
        inv, plan, rec = fixture()
        plan["incident_status"] = "RESOLVED_WITH_REVIEW"
        plan["dispatch_halt"] = False
        plan["independence_audit"] = "EXTERNALLY_REVIEWED"
        relock(inv, plan, rec)
        result = analyze(inv, plan, rec)
        self.assertEqual(result["status"], "STRUCTURAL_COMPLETE_UNCERTIFIED")
        self.assertEqual(result["official_years_certified_by_this_gate"], 0)
        self.assertFalse(result["input_evidence_authenticity_independently_verified"])
        self.assertFalse(result["ten_thousand_year_target_met"])

    def test_missing_roster_disposition_rejected(self):
        inv, plan, rec = fixture()
        plan["dispositions"].pop()
        relock(inv, plan, rec)
        with self.assertRaisesRegex(ValueError, "inventory incomplete"):
            analyze(inv, plan, rec)

    def test_unplanned_extra_result_rejected(self):
        inv, plan, rec = fixture()
        rec["engine_years"].append(dict(rec["engine_years"][0],engine_id="unknown"))
        with self.assertRaisesRegex(ValueError, "unplanned"):
            analyze(inv, plan, rec)

    def test_duplicate_result_rejected(self):
        inv, plan, rec = fixture()
        rec["engine_years"].append(copy.deepcopy(rec["engine_years"][0]))
        with self.assertRaisesRegex(ValueError, "duplicate"):
            analyze(inv, plan, rec)

    def test_missing_engine_year_does_not_credit_year(self):
        inv, plan, rec = fixture()
        rec["engine_years"].pop(1)
        result = analyze(inv, plan, rec)
        self.assertEqual(result["missing_or_pending_engine_years"], 1)
        self.assertEqual(result["contiguous_structurally_equal_years"], 0)
        self.assertEqual(result["structurally_equal_engine_year_pairs"], 4)
        self.assertFalse(result["structural_coverage_complete"])

    def test_cross_engine_stream_hash_difference_is_failure(self):
        inv, plan, rec = fixture()
        rec["engine_years"][2]["daystream_sha256"] = "b" * 64
        result = analyze(inv, plan, rec)
        self.assertEqual(result["first_problem"]["type"], "DAYSTREAM_HASH_DIFFERENCE")
        self.assertEqual(result["mismatched_engine_years"], 1)
        self.assertEqual(result["contiguous_structurally_equal_years"], 0)

    def test_wrong_full_year_extent_does_not_pass(self):
        inv, plan, rec = fixture()
        rec["engine_years"][0]["days"] = 1
        result = analyze(inv, plan, rec)
        self.assertEqual(result["first_problem"]["type"], "BAD_YEAR_EXTENT_OR_BOUNDARY")
        self.assertEqual(result["invalid_engine_years"], 1)

    def test_wrong_boundary_hash_does_not_pass(self):
        inv, plan, rec = fixture()
        rec["engine_years"][0]["boundary_evidence_sha256"] = "0" * 64
        result = analyze(inv, plan, rec)
        self.assertEqual(result["invalid_engine_years"], 1)

    def test_duplicate_algorithm_identity_rejected(self):
        inv, plan, rec = fixture()
        inv["records"][1]["algorithm_id"] = "alg0"
        relock(inv, plan, rec)
        with self.assertRaisesRegex(ValueError, "duplicate engine or algorithm"):
            analyze(inv, plan, rec)

    def test_wrapper_cannot_be_counted_as_source(self):
        inv, plan, rec = fixture()
        item = plan["dispositions"][-2]
        item.update(decision="IN_SCOPE", duplicate_of=None)
        relock(inv, plan, rec)
        with self.assertRaisesRegex(ValueError, "wrapper"):
            analyze(inv, plan, rec)

    def test_duplicate_reference_must_resolve_to_same_algorithm(self):
        inv, plan, rec = fixture()
        inv["records"][-2]["algorithm_id"] = "different"
        relock(inv, plan, rec)
        with self.assertRaisesRegex(ValueError, "lineage differs"):
            analyze(inv, plan, rec)

    def test_reviewed_exclusion_requires_evidence_digest(self):
        inv, plan, rec = fixture()
        plan["dispositions"][-1]["decision"] = "EXCLUDED_REVIEWED"
        relock(inv, plan, rec)
        with self.assertRaisesRegex(ValueError, "SHA-256"):
            analyze(inv, plan, rec)

    def test_nonconsecutive_full_year_boundaries_rejected(self):
        inv, plan, rec = fixture()
        plan["years"][1]["first_target_day"] = "-17"
        relock(inv, plan, rec)
        with self.assertRaisesRegex(ValueError, "gap or overlap"):
            analyze(inv, plan, rec)

    def test_noncanonical_negative_zero_and_leading_zero_rejected(self):
        for malformed in ("-0", "05001", "+5001"):
            inv, plan, rec = fixture()
            plan["years"][1]["year"] = malformed
            relock(inv, plan, rec)
            with self.subTest(malformed=malformed), self.assertRaisesRegex(ValueError, "noncanonical"):
                analyze(inv, plan, rec)

    def test_invalid_receipts_cannot_smuggle_completion_metadata(self):
        inv, plan, rec = fixture()
        rec["engine_years"][0]["status"] = "INVALID"
        with self.assertRaisesRegex(ValueError, "unverified slot"):
            analyze(inv, plan, rec)

    def test_reject_duplicate_json_keys_and_nonfinite_constants(self):
        for source in (b'{"x":1,"x":2}', b'{"x":NaN}', b'{"x":Infinity}'):
            with self.subTest(source=source),self.assertRaises(ValueError):
                parse_json(source)

    def test_tampered_inventory_digest_rejected(self):
        inv, plan, rec = fixture()
        inv["records"][0]["engine_id"] = "other"
        with self.assertRaisesRegex(ValueError, "inventory contents"):
            analyze(inv, plan, rec)

    def test_tampered_plan_digest_rejected(self):
        inv, plan, rec = fixture()
        plan["independence_audit"] = "EXTERNALLY_REVIEWED"
        with self.assertRaisesRegex(ValueError, "exact plan"):
            analyze(inv, plan, rec)

    def test_exact_10000_synthetic_years_still_certify_zero(self):
        inv, plan, rec = fixture(years=10000,engines=2)
        result = analyze(inv, plan, rec)
        self.assertTrue(result["ten_thousand_year_target_met"])
        self.assertEqual(result["expected_engine_year_receipts"], 20_000)
        self.assertEqual(result["contiguous_structurally_equal_years"], 10_000)
        self.assertEqual(result["structurally_equal_engine_year_pairs"], 10_000)
        self.assertEqual(result["official_years_certified_by_this_gate"], 0)
        self.assertFalse(result["official_soak_10000_pass"])


if __name__ == "__main__":
    unittest.main()
