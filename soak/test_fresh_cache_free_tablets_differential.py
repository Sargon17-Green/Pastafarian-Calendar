#!/usr/bin/env python3
"""Eight fast fail-closed tests; real signed gate replay occurs in CI."""
import unittest
from fresh_cache_free_tablets_differential import (
    TARGETS, CLOSURE, TRACE, QUESTIONS, PASS,
    DiagnosticError, strict_rows, validate_candidate, compare_rows
)

def rows():
    return [{"day": d, "five_fields": [5000, 10, 100, 32, 21]}
            for d in TARGETS]

def valid():
    return {"isolated": True, "cache_free": True,
            "cache_empty_at_import": True, "source_only_unseeded": True,
            "checkpoint_seed_used": False, "pinned_date_compared": False,
            "full_date_certified": False, "source_closure_sha256": CLOSURE,
            "signed_gate_questions": QUESTIONS, "signed_transcript_sha256": TRACE,
            "targets": list(TARGETS), "production_limit_unchanged": 8192,
            "brackets": [{"day": d, "index": i, "low": d-2, "high": d+1}
                         for i, d in enumerate(TARGETS)], "rows": rows()}

class FreshTabletsTests(unittest.TestCase):
    def test_01_scoped_and_non_certifying(self):
        self.assertEqual(TARGETS, (-278523, -278522, -278521))
        self.assertIn("NOT_CERTIFIED", PASS)
    def test_02_valid_candidate_contract(self):
        self.assertEqual(validate_candidate(valid())["signed_gate_questions"], 29523)
    def test_03_cache_and_seed_false_claims_fail(self):
        for key, value in (("cache_free", False), ("cache_empty_at_import", False),
                           ("source_only_unseeded", False),
                           ("checkpoint_seed_used", True),
                           ("pinned_date_compared", True),
                           ("full_date_certified", True)):
            d = valid()
            d[key] = value
            with self.subTest(key=key), self.assertRaises(DiagnosticError):
                validate_candidate(d)
    def test_04_provenance_fail_closed(self):
        for key, value in (("signed_gate_questions", 29522),
                           ("signed_gate_questions", True),
                           ("signed_transcript_sha256", "0"*64),
                           ("source_closure_sha256", "0"*64)):
            d = valid()
            d[key] = value
            with self.subTest(key=key), self.assertRaises(DiagnosticError):
                validate_candidate(d)
    def test_05_row_shape_and_bool_fail_closed(self):
        with self.assertRaises(DiagnosticError):
            strict_rows(rows()[:2])
        d = rows()
        d[1]["five_fields"][0] = True
        with self.assertRaises(DiagnosticError):
            strict_rows(d)
    def test_06_bracket_coverage_fail_closed(self):
        d = valid()
        d["brackets"][1]["low"] = TARGETS[1]
        with self.assertRaises(DiagnosticError):
            validate_candidate(d)
    def test_07_all_fifteen_fields_match(self):
        self.assertEqual(compare_rows(rows(), rows()), 15)
    def test_08_mismatch_and_invalid_reference_fail(self):
        d = rows()
        d[0]["five_fields"][3] = 33
        with self.assertRaises(DiagnosticError):
            compare_rows(rows(), d)
        d = rows()
        d[0]["five_fields"][3] = None
        with self.assertRaises(DiagnosticError):
            compare_rows(rows(), d)

if __name__ == "__main__":
    unittest.main()
