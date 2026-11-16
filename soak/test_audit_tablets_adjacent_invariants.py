#!/usr/bin/env python3
"""Fast mutation tests; frozen CI JSON used as data, not an independent oracle."""
import copy
from pathlib import Path
import unittest
from audit_tablets_adjacent_invariants import (
    AuditError, TARGETS, RECEIPT_SHA256, audit_document,
    load_frozen_receipt,
)

SOURCE = Path(__file__).resolve().parent / "evidence" / "tablets-cache-free-3x5-run43767624423.json"

class AdjacentInvariantTests(unittest.TestCase):
    def setUp(self):
        self.receipt = load_frozen_receipt(SOURCE)
    def fail_with(self, modify):
        obj = copy.deepcopy(self.receipt)
        modify(obj)
        with self.assertRaises(AuditError):
            audit_document(obj)
    def test_01_frozen_evidence_valid(self):
        report = audit_document(self.receipt)
        self.assertEqual(report["checked_real_days"], list(TARGETS))
        self.assertEqual(report["new_real_gap_computations"], 0)
        self.assertFalse(report["full_date_certified"])
    def test_02_frozen_file_digest_lock(self):
        self.assertEqual(len(RECEIPT_SHA256), 64)
        import tempfile
        with tempfile.TemporaryDirectory() as folder:
            modified = Path(folder) / "tampered.json"
            modified.write_bytes(SOURCE.read_bytes() + b" ")
            with self.assertRaises(AuditError):
                load_frozen_receipt(modified)
    def test_03_duplicate_json_key_rejected(self):
        from audit_tablets_adjacent_invariants import unique_pairs
        with self.assertRaises(AuditError):
            unique_pairs([("a", 1), ("a", 2)])
    def test_04_false_certification_rejected(self):
        self.fail_with(lambda d: d.__setitem__("full_date_certified", True))
    def test_05_provenance_change_rejected(self):
        self.fail_with(lambda d: d.__setitem__("signed_transcript_sha256", "0" * 64))
    def test_06_true_integer_alias_rejected(self):
        self.fail_with(lambda d: d.__setitem__("signed_gate_questions", True))
    def test_07_pin_mismatch_rejected(self):
        self.fail_with(lambda d: d["pinned_rows"][1]["five_fields"].__setitem__(4, 100))
    def test_08_same_interval_index_required(self):
        self.fail_with(lambda d: d["structural_brackets"][1].__setitem__("index", 29483))
    def test_09_gate_width_upper_bound(self):
        self.fail_with(lambda d: d["structural_brackets"][0].__setitem__("low", -280000))
    def test_10_gate_coverage_required(self):
        self.fail_with(lambda d: d["structural_brackets"][1].__setitem__("high", TARGETS[1] - 1))
    def test_11_year_rollover_inside_gate_rejected(self):
        def change(d):
            for key in ("candidate_rows", "pinned_rows"):
                d[key][1]["five_fields"][0] += 1
        self.fail_with(change)
    def test_12_cutlet_rollover_inside_gate_rejected(self):
        def change(d):
            for key in ("candidate_rows", "pinned_rows"):
                d[key][1]["five_fields"][1] += 1
        self.fail_with(change)
    def test_13_cutlet_day_delta_required(self):
        def change(d):
            for key in ("candidate_rows", "pinned_rows"):
                d[key][2]["five_fields"][2] += 2
        self.fail_with(change)
    def test_14_type_and_range_rejected(self):
        def change(d):
            for key in ("candidate_rows", "pinned_rows"):
                d[key][0]["five_fields"][4] = True
        self.fail_with(change)
    def test_15_question_count_and_bound_rejected(self):
        self.fail_with(lambda d: d.__setitem__("five_field_comparisons", 14))

if __name__ == "__main__":
    unittest.main()
