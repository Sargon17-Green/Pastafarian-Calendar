#!/usr/bin/env python3
"""v147 generic multi-engine full-year JSONL comparator regression tests.

All dates are synthetic strings. No original converter, subprocess, date
oracle, native build, or original-year certification is performed.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "runner"))
from year_validator import YearCase, TranscriptError, compare_years, parse_line


class StrictGenericJsonlTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="soak-v147-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.case = YearCase("-15055671", "5000", "-15055671", "-15055669", "a" * 64)

    @staticmethod
    def row(index=0, *, names="one", month=20):
        target = -15055671 + index
        return {
            "calculation_day": "-15055671", "target_day": str(target),
            "year": "5000", "cutlet_index": 10,
            "day_in_cutlet": 503 + index, "month_index": month,
            "day_in_month": 56 + index,
            "cutlet_name_raw": "כליה" if names == "one" else "kidney",
            "month_name_raw": "חודש" if names == "one" else "month",
            "source_raw_sha256": hashlib.sha256(str(target).encode("ascii")).hexdigest(),
        }

    def lines(self, *, names="one", first_month=20):
        return [json.dumps(self.row(i, names=names, month=first_month if i == 0 else 20),
                           separators=(",", ":"), ensure_ascii=False)
                for i in range(3)]

    def compare(self, a, b=None):
        if b is None:
            b = self.lines(names="other")
        pa, pb = self.root / "a.jsonl", self.root / "b.jsonl"
        pa.write_text("\n".join(a) + "\n", encoding="utf-8")
        pb.write_text("\n".join(b) + "\n", encoding="utf-8")
        return compare_years(pa, pb, self.case, "engine-A", "engine-B")

    @staticmethod
    def append_member(line, member):
        assert line.endswith("}")
        return line[:-1] + "," + member + "}"

    def assert_invalid_row(self, lines, *, row=1, text=None):
        r = self.compare(lines)
        self.assertEqual(r["verdict"], "INVALID_EVIDENCE", r)
        self.assertTrue(r["halt_new_work"])
        self.assertEqual(r["fully_matched_days"], 0)
        if text is not None:
            self.assertIn(text, r["error"])
        self.assertIn("row " + str(row), r["error"])

    def test_01_exact_three_day_pair_passes(self):
        r = self.compare(self.lines())
        self.assertEqual((r["verdict"], r["fully_matched_days"]), ("PASS", 3))
        self.assertFalse(r["halt_new_work"])

    def test_02_different_native_language_names_still_pass(self):
        r = self.compare(self.lines(names="one"), self.lines(names="other"))
        self.assertEqual(r["verdict"], "PASS")

    def test_03_first_numeric_difference_halts(self):
        r = self.compare(self.lines(), self.lines(names="other", first_month=30))
        self.assertEqual((r["verdict"], r["fully_matched_days"],
                          r["first_mismatch_target_day"]),
                         ("MISMATCH", 0, "-15055671"))
        self.assertTrue(r["halt_new_work"])

    def test_04_shadowed_month_index_must_not_false_pass(self):
        baseline = self.lines()
        baseline[0] = self.append_member(baseline[0], '"month_index":30')
        # Before v147, Python's normal json.loads silently took the LAST value,
        # so the ambiguous baseline compared equal to a canonical month=30.
        self.assertEqual(json.loads(baseline[0])["month_index"], 30)
        candidate = self.lines(names="other", first_month=30)
        self.assertEqual(json.loads(candidate[0])["month_index"], 30)
        self.assert_invalid_row(baseline, text="duplicate JSON key: month_index")

    def test_05_shadowed_calculation_day_is_invalid(self):
        rows = self.lines()
        rows[0] = self.append_member(rows[0], '"calculation_day":"-15055671"')
        self.assert_invalid_row(rows, text="duplicate JSON key: calculation_day")

    def test_06_shadowed_target_day_is_invalid(self):
        rows = self.lines()
        rows[0] = self.append_member(rows[0], '"target_day":"-15055671"')
        self.assert_invalid_row(rows, text="duplicate JSON key: target_day")

    def test_07_shadowed_year_is_invalid(self):
        rows = self.lines()
        rows[0] = self.append_member(rows[0], '"year":"5000"')
        self.assert_invalid_row(rows, text="duplicate JSON key: year")

    def test_08_shadowed_raw_sha256_is_invalid(self):
        rows = self.lines()
        rows[0] = self.append_member(rows[0],
                                     '"source_raw_sha256":"' + "b" * 64 + '"')
        self.assert_invalid_row(rows, text="duplicate JSON key: source_raw_sha256")

    def test_09_shadowed_extra_root_field_is_invalid(self):
        rows = self.lines()
        rows[0] = self.append_member(rows[0], '"extra":1,"extra":2')
        self.assert_invalid_row(rows, text="duplicate JSON key: extra")

    def test_10_nested_duplicate_is_invalid(self):
        rows = self.lines()
        rows[0] = self.append_member(rows[0], '"aux":{"sample":1,"sample":2}')
        self.assert_invalid_row(rows, text="duplicate JSON key: sample")

    def test_11_nan_extension_is_invalid(self):
        rows = self.lines()
        rows[0] = self.append_member(rows[0], '"aux":NaN')
        self.assert_invalid_row(rows, text="non-JSON numeric token: NaN")

    def test_12_positive_infinity_is_invalid(self):
        rows = self.lines()
        rows[0] = self.append_member(rows[0], '"aux":Infinity')
        self.assert_invalid_row(rows, text="non-JSON numeric token: Infinity")

    def test_13_negative_infinity_is_invalid(self):
        rows = self.lines()
        rows[0] = self.append_member(rows[0], '"aux":-Infinity')
        self.assert_invalid_row(rows, text="non-JSON numeric token: -Infinity")

    def test_14_nan_required_integer_field_is_invalid(self):
        rows = self.lines()
        rows[0] = rows[0].replace('"month_index":20', '"month_index":NaN', 1)
        self.assert_invalid_row(rows, text="non-JSON numeric token: NaN")

    def test_15_valid_unique_extension_is_allowed(self):
        rows = self.lines()
        rows[0] = self.append_member(rows[0], '"aux":{"trace":1,"label":"ok"}')
        self.assertEqual(self.compare(rows)["verdict"], "PASS")

    def test_16_duplicate_on_second_day_cannot_be_hidden(self):
        rows = self.lines()
        rows[1] = self.append_member(rows[1], '"month_index":20')
        self.assert_invalid_row(rows, row=2, text="duplicate JSON key: month_index")

    def test_17_incomplete_year_cannot_pass(self):
        self.assert_invalid_row(self.lines()[:-1], row=3, text="incomplete year")

    def test_18_missing_middle_day_cannot_pass(self):
        rows = self.lines()
        self.assert_invalid_row([rows[0], rows[2]], row=2, text="missing, duplicated or out-of-order")

    def test_19_duplicate_day_cannot_pass(self):
        rows = self.lines()
        self.assert_invalid_row([rows[0], rows[0], rows[2]], row=2,
                                text="missing, duplicated or out-of-order")

    def test_20_bad_json_syntax_is_invalid(self):
        rows = self.lines()
        rows[0] = rows[0][:-1]
        self.assert_invalid_row(rows, text="invalid JSON")

    def test_21_boolean_numeric_field_is_invalid(self):
        rows = self.lines()
        rows[0] = rows[0].replace('"month_index":20', '"month_index":true', 1)
        self.assert_invalid_row(rows, text="invalid numeric field")

    def test_22_raw_name_absence_is_invalid(self):
        rows = self.lines()
        rows[0] = rows[0].replace('"month_name_raw":"חודש"', '"month_name_raw":""', 1)
        self.assert_invalid_row(rows, text="raw native name missing")

    def test_23_pair_must_use_distinct_engine_ids(self):
        line = self.lines()[0]
        p = self.root / "x.jsonl"
        p.write_text(line + "\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "distinct engine identities"):
            compare_years(p, p, self.case, "same", "same")

    def test_24_literal_parser_reports_exact_row_number(self):
        bad = self.append_member(self.lines()[0], '"year":"5000"')
        with self.assertRaises(TranscriptError) as c:
            parse_line(bad, 7, self.case, -15055671)
        self.assertEqual(c.exception.row, 7)
        self.assertIn("duplicate JSON key: year", c.exception.reason)


if __name__ == "__main__":
    unittest.main()
