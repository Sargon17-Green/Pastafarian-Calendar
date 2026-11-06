#!/usr/bin/env python3
"""Bounded tests for source-closure provenance and fail-closed receipt claims."""
from __future__ import annotations

import hashlib
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
from tablets_unseeded_closure_contract import (
    MODULE_BLOBS, ContractError, audit_sources, git_blob_sha,
    inspect_texts, validate_real_receipt, SOURCE_STATUS, TARGETS,
)

ROOT = Path(__file__).resolve().parent.parent


def texts():
    return {m: (ROOT / "soak" / (m + ".py")).read_bytes() for m in MODULE_BLOBS}


def valid_receipt():
    return {
        "status": "PASS_REAL_UNSEEDED_FIVE_FIELDS_PINNED_DATE_NOT_COMPARED_NOT_CERTIFIED",
        "targets": list(TARGETS), "cases": 3, "fields_per_case": 5,
        "positive_prefix_questions": 80, "forward_extension_questions": 12,
        "negative_questions": 10, "total_unique_gap_questions": 102,
        "segment_limit": 4096, "rows": [
            {"day": day, "five_fields": [5001, 1, 1, 1, 1]} for day in TARGETS
        ], "signed_transcript_sha256": "a" * 64,
        "positive_audit_trace_sha256": "b" * 64,
        "checkpoint_seed_used": False,
        "pinned_date_comparison_performed": False,
        "external_cache_independence_certified": False,
        "full_date_certified": False, "certifiable": False,
        "production_gate_limit_unchanged": 8192,
    }


class UnseededClosureContractTests(unittest.TestCase):
    def test_five_real_source_blobs_locked(self):
        self.assertEqual({m: git_blob_sha(raw) for m, raw in texts().items()},
                         MODULE_BLOBS)

    def test_full_closure_reachable(self):
        manifest = audit_sources(ROOT)
        self.assertEqual(manifest["status"], SOURCE_STATUS)
        self.assertEqual(manifest["module_count"], 5)
        self.assertEqual(len(manifest["module_manifest"]), 5)
        self.assertEqual(len(manifest["closure_sha256"]), 64)

    def test_external_seeds_absent_without_claiming_certification(self):
        manifest = audit_sources(ROOT)
        self.assertFalse(manifest["imported_checkpoint_seeds"])
        self.assertFalse(manifest["runtime_cache_isolation_proven"])
        self.assertFalse(manifest["algorithmic_independence_certified"])
        self.assertFalse(manifest["full_date_certified"])
        self.assertEqual(len(manifest["process_local_pure_memoization"]), 1)

    def test_source_blob_drift_fail_closed(self):
        src = texts()
        m = "independent_sauce_oracle"
        src[m] += b"\n# mutation\n"
        with self.assertRaisesRegex(ContractError, "E_CLOSURE_BLOB"):
            inspect_texts(src)

    def test_checkpoint_import_fail_closed_even_when_blob_relocked(self):
        src = texts()
        m = "independent_five_field_date"
        src[m] += b"\nfrom verify_pinned_gate_checkpoints import pinned_source\n"
        locks = dict(MODULE_BLOBS)
        locks[m] = git_blob_sha(src[m])
        with self.assertRaisesRegex(ContractError, "E_CLOSURE_IMPORT"):
            inspect_texts(src, locks)

    def test_dynamic_import_fail_closed_even_when_blob_relocked(self):
        src = texts()
        m = "independent_five_field_date"
        src[m] += b"\nunsafe = __import__('os')\n"
        locks = dict(MODULE_BLOBS)
        locks[m] = git_blob_sha(src[m])
        with self.assertRaisesRegex(ContractError, "E_CLOSURE_DYNAMIC"):
            inspect_texts(src, locks)

    def test_unapproved_reflection_rejected_even_when_blob_relocked(self):
        src = texts()
        m = "independent_date_combinatorics"
        src[m] += b'\nextra = getattr(witness, "secret_checkpoint", None)\n'
        locks = dict(MODULE_BLOBS)
        locks[m] = git_blob_sha(src[m])
        with self.assertRaisesRegex(ContractError, "E_CLOSURE_REFLECTION"):
            inspect_texts(src, locks)

    def test_setattr_rejected_even_when_blob_relocked(self):
        src = texts()
        m = "independent_date_combinatorics"
        src[m] += b'\nsetattr(witness, "order_at_drop_46", None)\n'
        locks = dict(MODULE_BLOBS)
        locks[m] = git_blob_sha(src[m])
        with self.assertRaisesRegex(ContractError, "E_CLOSURE_REFLECTION"):
            inspect_texts(src, locks)

    def test_receipt_only_validates_shape(self):
        result = validate_real_receipt(valid_receipt())
        self.assertEqual(result["typed_cells"], 15)
        self.assertEqual(result["pinned_date_comparisons_proven_here"], 0)
        self.assertFalse(result["full_date_certified"])

    def test_receipt_wrong_target_fail_closed(self):
        r = valid_receipt()
        r["rows"][1]["day"] += 1
        with self.assertRaisesRegex(ContractError, "E_RECEIPT_DAY"):
            validate_real_receipt(r)

    def test_receipt_bool_not_an_integer(self):
        r = valid_receipt()
        r["rows"][0]["five_fields"][0] = True
        with self.assertRaisesRegex(ContractError, "E_RECEIPT_TYPED_FIVE"):
            validate_real_receipt(r)

    def test_receipt_budget_accounting_fail_closed(self):
        r = valid_receipt()
        r["total_unique_gap_questions"] = 32769
        with self.assertRaisesRegex(ContractError, "E_RECEIPT_QUESTION_ACCOUNTING"):
            validate_real_receipt(r)

    def test_receipt_false_seed_independence_claim_rejected(self):
        r = valid_receipt()
        r["checkpoint_seed_used"] = True
        with self.assertRaisesRegex(ContractError, "E_RECEIPT_UNSUPPORTED_CLAIM"):
            validate_real_receipt(r)

    def test_receipt_cannot_claim_certification(self):
        r = valid_receipt()
        r["full_date_certified"] = True
        with self.assertRaisesRegex(ContractError, "E_RECEIPT_UNSUPPORTED_CLAIM"):
            validate_real_receipt(r)

    def test_receipt_invalid_digest_rejected(self):
        r = valid_receipt()
        r["signed_transcript_sha256"] = "not-a-sha"
        with self.assertRaisesRegex(ContractError, "E_RECEIPT_TRANSCRIPT"):
            validate_real_receipt(r)

    def test_receipt_segment_limit_rejected(self):
        r = valid_receipt()
        r["segment_limit"] = 8193
        with self.assertRaisesRegex(ContractError, "E_RECEIPT_SEGMENT"):
            validate_real_receipt(r)


if __name__ == "__main__":
    unittest.main()
