#!/usr/bin/env python3
"""Synthetic shape/rejection tests; real comparison runs in the workflow."""
import unittest
from production_seven_field_pinned_diagnostic import (
    FOUNDATION, TARGETS, PINNED_SHA, PINNED_MODULE_SHA256,
    SevenFieldError, compare, parse_production, validate_reference,
)


class SevenFieldContractTests(unittest.TestCase):
    def row(self, target=FOUNDATION):
        return f"{FOUNDATION}\t{target}\t8453\t7\t934\t12\t100\n"

    def ref(self, target=FOUNDATION):
        return {"day": target, "five_fields": [8453, 7, 934, 12, 100],
                "reference_commit": PINNED_SHA,
                "module_sha256": PINNED_MODULE_SHA256,
                "isolated": True, "cache_reset": True}

    def test_three_exact_target_days(self):
        self.assertEqual(TARGETS, (FOUNDATION - 1, FOUNDATION, FOUNDATION + 1))

    def test_valid_seven_columns_and_15_comparison_fields(self):
        for target in TARGETS:
            self.assertEqual(parse_production(self.row(target), FOUNDATION, target),
                             [FOUNDATION, target, 8453, 7, 934, 12, 100])
            self.assertTrue(compare(parse_production(self.row(target), FOUNDATION, target),
                                    validate_reference(self.ref(target), target)))

    def test_invalid_echo_is_rejected(self):
        with self.assertRaisesRegex(SevenFieldError, "E_PRODUCTION_INPUT_ECHO"):
            parse_production(self.row(FOUNDATION), FOUNDATION + 1, FOUNDATION)

    def test_malformed_columns_are_rejected(self):
        for row in ("1\t2\n", self.row() + self.row(), self.row().replace("8453", "08")):
            with self.subTest(row=row):
                with self.assertRaises(SevenFieldError):
                    parse_production(row, FOUNDATION, FOUNDATION)

    def test_reference_cache_and_origin_guards(self):
        for key, value in (("cache_reset", False), ("isolated", False),
                           ("reference_commit", "a" * 40),
                           ("module_sha256", "0" * 64), ("day", FOUNDATION + 1)):
            doc = self.ref()
            doc[key] = value
            with self.subTest(key=key):
                with self.assertRaisesRegex(SevenFieldError, "E_REFERENCE_PROVENANCE"):
                    validate_reference(doc, FOUNDATION)

    def test_reference_boolean_field_rejected(self):
        doc = self.ref()
        doc["five_fields"][0] = True
        with self.assertRaisesRegex(SevenFieldError, "E_REFERENCE_FIELDS"):
            validate_reference(doc, FOUNDATION)

    def test_differential_detects_witness_mismatch(self):
        prod = parse_production(self.row(), FOUNDATION, FOUNDATION)
        ref = self.ref()["five_fields"]
        ref[4] += 1
        self.assertFalse(compare(prod, ref))

    def test_noncanonical_decimal_rejected(self):
        for t in ("-0", "+1", "01", " 1", "1 ", "1.0", ""):
            row = self.row().split("\t")
            row[2] = t
            with self.subTest(value=t):
                with self.assertRaises(SevenFieldError):
                    parse_production("\t".join(row), FOUNDATION, FOUNDATION)


if __name__ == "__main__":
    unittest.main()
