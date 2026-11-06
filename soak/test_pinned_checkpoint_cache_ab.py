#!/usr/bin/env python3
"""Ten bounded synthetic checks; real six-process A/B runs in GitHub Actions."""
import unittest
from pinned_checkpoint_cache_ab import (
    AuditError, BLOBS, FOUNDATION, MODES, PASS, PINNED_SHA, TARGETS,
    checked_fields, compare_pair, validate_worker,
)


class CheckpointCacheABTests(unittest.TestCase):
    def doc(self, *, mode="table", day=FOUNDATION, fields=None):
        return {"day": day, "mode": mode,
                "five_fields": fields if fields is not None else [8453, 7, 934, 12, 100],
                "pinned_commit": PINNED_SHA, "isolated": True,
                "cache_reset": True, "static_count_before": 75,
                "static_count_active": 75 if mode == "table" else 0,
                "reanchors": []}

    def test_01_exact_scope(self):
        self.assertEqual(TARGETS, (FOUNDATION - 1, FOUNDATION, FOUNDATION + 1))
        self.assertEqual(MODES, ("table", "empty"))

    def test_02_three_source_blob_locks(self):
        self.assertEqual(len(BLOBS), 3)
        self.assertTrue(all(len(v) == 40 for v in BLOBS.values()))
        self.assertEqual(len(PINNED_SHA), 40)

    def test_03_valid_typed_fields(self):
        self.assertEqual(checked_fields([8453, 7, 934, 12, 100]),
                         [8453, 7, 934, 12, 100])

    def test_04_boolean_is_not_integer(self):
        for i in range(5):
            row = [8453, 7, 934, 12, 100]
            row[i] = True
            with self.subTest(i=i), self.assertRaises(AuditError):
                checked_fields(row)

    def test_05_field_bounds_and_shape(self):
        for row in ([], [1] * 6, [1, 18, 1, 1, 1],
                    [1, 1, 1, 48, 1], [1, 1, 1, 1, 124], [1, 2.0, 1, 1, 1]):
            with self.subTest(row=row), self.assertRaises(AuditError):
                checked_fields(row)

    def test_06_worker_provenance_fail_closed(self):
        for key, value in (("pinned_commit", "0" * 40),
                           ("isolated", False), ("cache_reset", False),
                           ("static_count_before", 74), ("day", FOUNDATION + 1)):
            row = self.doc()
            row[key] = value
            with self.subTest(key=key), self.assertRaises(AuditError):
                validate_worker(row, FOUNDATION, "table")

    def test_07_empty_mode_must_have_zero_static_checkpoints(self):
        row = self.doc(mode="empty")
        row["static_count_active"] = 75
        with self.assertRaises(AuditError):
            validate_worker(row, FOUNDATION, "empty")

    def test_08_empty_mode_reanchor_is_forbidden(self):
        row = self.doc(mode="empty")
        row["reanchors"] = [[1024, FOUNDATION + 525243]]
        with self.assertRaises(AuditError):
            validate_worker(row, FOUNDATION, "empty")

    def test_09_three_equal_pairs_and_15_fields(self):
        self.assertIn("NOT_CERTIFIED", PASS)
        total = 0
        for day in TARGETS:
            a = validate_worker(self.doc(day=day), day, "table")
            b = validate_worker(self.doc(day=day, mode="empty"), day, "empty")
            total += compare_pair(a, b)["typed_field_comparisons"]
        self.assertEqual(total, 15)

    def test_10_real_mismatch_rejected(self):
        a = self.doc()
        b = self.doc(mode="empty", fields=[8453, 7, 934, 12, 99])
        with self.assertRaisesRegex(AuditError, "E_CHECKPOINT_AB_DATE_MISMATCH"):
            compare_pair(a, b)


if __name__ == "__main__":
    unittest.main()
