from __future__ import annotations
import hashlib
import json
import pathlib
import tempfile
import unittest
import sys
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "runner"))
from year_validator import YearCase, TranscriptError, compare_years, robust_slow_threshold


class YearValidatorTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = pathlib.Path(self.tmp.name)
        self.case = YearCase("-15055671", "5000", "-15055671", "-15055669", "a" * 64)

    def write(self, name, rows):
        path = self.base / name
        path.write_text("\n".join(json.dumps(r, ensure_ascii=False) for r in rows) + "\n", encoding="utf-8")
        return path

    def make_rows(self, *, language="he", deviation_at=None, missing=None):
        rows = []
        for ix, t in enumerate(range(-15055671, -15055668)):
            if ix == missing:
                continue
            rows.append({
                "calculation_day": "-15055671", "target_day": str(t), "year": "5000",
                "cutlet_index": 10, "day_in_cutlet": 503+ix,
                "month_index": 20 + (1 if ix == deviation_at else 0),
                "day_in_month": 56 + ix,
                "cutlet_name_raw": "כליה" if language == "he" else "kidney",
                "month_name_raw": "חודש" if language == "he" else "month",
                "source_raw_sha256": hashlib.sha256(str(t).encode()).hexdigest(),
            })
        return rows

    def test_all_days_pass_with_different_native_languages(self):
        a = self.write("a.jsonl", self.make_rows())
        b = self.write("b.jsonl", self.make_rows(language="en"))
        result = compare_years(a, b, self.case, "one", "two")
        self.assertEqual((result["verdict"], result["fully_matched_days"]), ("PASS", 3))

    def test_first_mismatch_halts(self):
        a = self.write("a.jsonl", self.make_rows())
        b = self.write("b.jsonl", self.make_rows(deviation_at=1))
        result = compare_years(a, b, self.case, "one", "two")
        self.assertEqual(result["verdict"], "MISMATCH")
        self.assertEqual(result["fully_matched_days"], 1)
        self.assertEqual(result["first_mismatch_target_day"], "-15055670")
        self.assertTrue(result["halt_new_work"])

    def test_missing_day_is_never_pass(self):
        a = self.write("a.jsonl", self.make_rows())
        b = self.write("b.jsonl", self.make_rows(missing=1))
        result = compare_years(a, b, self.case, "one", "two")
        self.assertNotEqual(result["verdict"], "PASS")

    def test_missing_last_day_is_never_pass(self):
        a = self.write("a.jsonl", self.make_rows())
        b = self.write("b.jsonl", self.make_rows(missing=2))
        result = compare_years(a, b, self.case, "one", "two")
        self.assertNotEqual(result["verdict"], "PASS")

    def test_wrong_calc_day_rejected(self):
        a = self.write("a.jsonl", self.make_rows())
        rows = self.make_rows(); rows[1]["calculation_day"] = "-15055670"
        b = self.write("b.jsonl", rows)
        self.assertEqual(compare_years(a, b, self.case, "one", "two")["verdict"], "INVALID_EVIDENCE")

    def test_unverified_year_boundaries_rejected(self):
        case = YearCase("-15055671", "5000", "1", "2", "unknown")
        with self.assertRaises(ValueError):
            case.validate()

    def test_same_engine_cannot_self_certify(self):
        a = self.write("a.jsonl", self.make_rows())
        with self.assertRaises(ValueError):
            compare_years(a, a, self.case, "one", "one")

    def test_dynamic_duration_median_mad_and_no_timeout_on_sparse_history(self):
        self.assertEqual(robust_slow_threshold([0.1, 2.0]), 300.0)
        self.assertGreater(robust_slow_threshold([10, 10, 11, 12, 13]), 30)
        self.assertEqual(robust_slow_threshold([1]*5), 30.0)

    def test_boolean_numeric_field_not_accepted(self):
        a = self.write("a.jsonl", self.make_rows())
        rows = self.make_rows(); rows[0]["month_index"] = True
        b = self.write("b.jsonl", rows)
        self.assertEqual(compare_years(a,b,self.case,"a","b")["verdict"],"INVALID_EVIDENCE")

    def test_first_day_strict_canonical_integer(self):
        case = YearCase("-00", "5000", "1", "2", "a"*64)
        with self.assertRaises(ValueError):case.validate()


if __name__ == "__main__":
    unittest.main()
