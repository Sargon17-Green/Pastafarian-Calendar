#!/usr/bin/env python3
"""Eight bounded non-certifying tests; real cold workers run in Actions."""
import unittest
from independent_five_field_cache_ab import (
    CacheAuditError, FOUNDATION, MODES, SOURCE_CLOSURE_SHA,
    TARGETS, STATUS, checked_fields, external_bounded_dp,
    small_composition_witness, validate_worker,
)


def fake(mode="cached"):
    return {"mode": mode, "isolated": True, "cache_empty_at_import": True,
            "cache_enabled": mode == "cached",
            "source_closure_sha256": SOURCE_CLOSURE_SHA,
            "dp_digest": "a" * 64, "gate_questions": 360,
            "targets": list(TARGETS), "full_date_certified": False,
            "rows": [{"day": day,
                      "five_fields": [5000, 1, 1, 1, 1]}
                     for day in TARGETS]}


class CacheABTests(unittest.TestCase):
    def test_01_exact_scope(self):
        self.assertEqual(MODES, ("cached", "free"))
        self.assertEqual(TARGETS, (FOUNDATION - 1, FOUNDATION, FOUNDATION + 1))
        self.assertIn("NOT_CERTIFIED", STATUS)

    def test_02_external_dp_small_counts(self):
        self.assertEqual(external_bounded_dp(3, 2, 1, 2), 2)
        self.assertEqual(external_bounded_dp(0, 0, 1, 2), 1)
        self.assertEqual(external_bounded_dp(5, 0, 1, 2), 0)

    def test_03_dp_unsafe_inputs_fail_closed(self):
        for args in ((12, 2, 1, 2), (1, True, 1, 2),
                     (1, 2, 0, 2), (1, 2, 2, 1)):
            with self.subTest(args=args), self.assertRaises(CacheAuditError):
                external_bounded_dp(*args)

    def test_04_dp_vs_inclusion_exclusion(self):
        self.assertEqual(len(small_composition_witness()), 64)

    def test_05_typed_five_fields_no_bool(self):
        checked_fields([5000, 1, 1, 1, 1])
        for row in ([True, 1, 1, 1, 1], [1, 18, 1, 1, 1],
                    [1, 1, 1, 48, 1], [1, 1, 1, 1, 124]):
            with self.subTest(row=row), self.assertRaises(CacheAuditError):
                checked_fields(row)

    def test_06_worker_contract(self):
        for mode in MODES:
            self.assertEqual(validate_worker(fake(mode), mode, "a" * 64)["mode"],
                             mode)

    def test_07_worker_provenance_fails_closed(self):
        for key, value in (("isolated", False), ("cache_empty_at_import", False),
                           ("gate_questions", 359), ("full_date_certified", True),
                           ("source_closure_sha256", "0" * 64)):
            doc = fake()
            doc[key] = value
            with self.subTest(key=key), self.assertRaises(CacheAuditError):
                validate_worker(doc, "cached", "a" * 64)

    def test_08_worker_rows_and_digest_fail_closed(self):
        doc = fake()
        doc["rows"][1]["day"] = FOUNDATION + 50
        with self.assertRaises(CacheAuditError):
            validate_worker(doc, "cached", "a" * 64)
        with self.assertRaises(CacheAuditError):
            validate_worker(fake(), "cached", "b" * 64)


if __name__ == "__main__":
    unittest.main()
