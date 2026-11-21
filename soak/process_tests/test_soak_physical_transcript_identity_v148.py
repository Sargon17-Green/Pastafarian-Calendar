#!/usr/bin/env python3
"""v148: forbid one raw transcript masquerading as two engine outputs.

Synthetic three-row JSONL only. No subprocess, native build or F(c,t).
"""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "runner"))
from year_validator import YearCase, compare_years


class PhysicalTranscriptIdentityTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="soak-v148-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.case = YearCase("-15055671", "5000", "-15055671", "-15055669", "a" * 64)
        self.a = self.make("baseline.jsonl")

    def make(self, name, *, month=20, language="a"):
        rows = []
        for index in range(3):
            t = str(-15055671 + index)
            rows.append({
                "calculation_day": "-15055671", "target_day": t,
                "year": "5000", "cutlet_index": 10, "day_in_cutlet": 503 + index,
                "month_index": month if index == 0 else 20,
                "day_in_month": 56 + index,
                "cutlet_name_raw": "כליה" if language == "a" else "kidney",
                "month_name_raw": "חודש" if language == "a" else "month",
                "source_raw_sha256": hashlib.sha256(t.encode()).hexdigest()
            })
        p = self.root / name
        p.write_text("\n".join(json.dumps(row, ensure_ascii=False, separators=(",", ":"))
                               for row in rows) + "\n", encoding="utf-8")
        return p

    def check_invalid_same_file(self, other):
        verdict = compare_years(self.a, other, self.case, "REF-41", "REF-03")
        self.assertEqual(verdict["verdict"], "INVALID_EVIDENCE", verdict)
        self.assertTrue(verdict["halt_new_work"])
        self.assertEqual(verdict["fully_matched_days"], 0)
        self.assertIn("same physical transcript", verdict["error"])

    def test_01_same_exact_path_different_engine_ids_invalid(self):
        self.check_invalid_same_file(self.a)

    def test_02_same_path_reversed_engine_labels_invalid(self):
        result = compare_years(self.a, self.a, self.case, "REF-03", "REF-41")
        self.assertEqual(result["verdict"], "INVALID_EVIDENCE")

    def test_03_hardlink_alias_invalid(self):
        alias = self.root / "hardlink.jsonl"
        try:
            os.link(self.a, alias)
        except (NotImplementedError, OSError) as exc:
            self.skipTest("hardlinks unsupported: " + str(exc))
        self.check_invalid_same_file(alias)

    def test_04_symlink_alias_invalid(self):
        alias = self.root / "symlink.jsonl"
        try:
            alias.symlink_to(self.a)
        except (NotImplementedError, OSError) as exc:
            self.skipTest("symlinks unsupported: " + str(exc))
        self.check_invalid_same_file(alias)

    def test_05_parent_dot_alias_invalid(self):
        alias = self.root / "folder"
        alias.mkdir()
        self.check_invalid_same_file(alias / ".." / "baseline.jsonl")

    def test_06_distinct_files_with_identical_bytes_valid(self):
        b = self.root / "copy.jsonl"
        shutil.copyfile(self.a, b)
        self.assertFalse(os.path.samefile(self.a, b))
        result = compare_years(self.a, b, self.case, "REF-41", "REF-03")
        self.assertEqual((result["verdict"], result["fully_matched_days"]), ("PASS", 3))

    def test_07_independent_quoting_variation_in_json_is_valid(self):
        b = self.root / "spaced.jsonl"
        text = self.a.read_text(encoding="utf-8")
        b.write_text(text.replace('":', '" : '), encoding="utf-8")
        result = compare_years(self.a, b, self.case, "REF-41", "REF-03")
        self.assertEqual(result["verdict"], "PASS")

    def test_08_independent_language_variation_valid(self):
        b = self.make("english.jsonl", language="b")
        result = compare_years(self.a, b, self.case, "REF-41", "REF-03")
        self.assertEqual(result["verdict"], "PASS")

    def test_09_distinct_files_true_numeric_difference_halts(self):
        b = self.make("diverges.jsonl", month=30)
        result = compare_years(self.a, b, self.case, "REF-41", "REF-03")
        self.assertEqual((result["verdict"], result["first_mismatch_target_day"]),
                         ("MISMATCH", "-15055671"))
        self.assertTrue(result["halt_new_work"])

    def test_10_distinct_files_truncated_candidate_invalid(self):
        b = self.make("truncated.jsonl")
        lines = b.read_text(encoding="utf-8").splitlines()
        b.write_text("\n".join(lines[:-1]) + "\n", encoding="utf-8")
        result = compare_years(self.a, b, self.case, "REF-41", "REF-03")
        self.assertEqual(result["verdict"], "INVALID_EVIDENCE")

    def test_11_missing_other_path_invalid(self):
        b = self.root / "absent.jsonl"
        result = compare_years(self.a, b, self.case, "REF-41", "REF-03")
        self.assertEqual(result["verdict"], "INVALID_EVIDENCE")

    def test_12_same_engine_id_cannot_compare(self):
        b = self.make("separate.jsonl")
        with self.assertRaisesRegex(ValueError, "distinct engine identities"):
            compare_years(self.a, b, self.case, "REF-41", "REF-41")


if __name__ == "__main__":
    unittest.main()
