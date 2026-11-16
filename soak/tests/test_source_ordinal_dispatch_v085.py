"""v085 unit gates: no engine execution; no action if request is untrusted."""
from __future__ import annotations

import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/"runner"))
import source_ordinal_dispatch_v085 as s


class FrozenRequestGate(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        self.control = self.root/"soak/control"
        self.reqdir = self.control/"original_source_dispatch_requests"
        self.reqdir.mkdir(parents=True)
        for i in (1017, 1018, 1019):
            pin = {
                "schema": s.PIN_SCHEMA,
                "original_source_year": {"ordinal": i,
                    "calculation_day": s.C,
                    "boundary_evidence_sha256": s.BOUNDARY},
                "original_source_commits": s.SOURCE_COMMITS,
                "artifact_sha256": "a"*64,
                "comparison": {"first_mismatch": None,
                               "original_year_soak_passes_certified": 0},
            }
            self.write(self.control/f"original_native_chunk{i}_pin_v071.json", pin)
        self.rel = s.REQUEST_DIR+"/ordinal-1020.json"
        self.obj = {"schema": s.SCHEMA, "ordinal": 1020, "year": s.YEAR,
                    "calculation_day": s.C,
                    "first_target_day": "-15055662",
                    "last_target_day": "-15055661",
                    "boundary_evidence_sha256": s.BOUNDARY,
                    "original_source_commits": s.SOURCE_COMMITS}
        self.write(self.root/self.rel, self.obj)

    @staticmethod
    def write(path, obj):
        path.write_text(json.dumps(obj, sort_keys=True, separators=(",", ":"),
                                   ensure_ascii=False)+"\n", encoding="utf-8")

    def check(self, status="A", rel=None):
        return s.validate_request(self.root, [(status, rel or self.rel)])

    def test_next_1020_exact_two_target_days_and_fixed_calculation_day(self):
        v = self.check()
        self.assertEqual((v["ordinal"], v["first_target_day"], v["last_target_day"]),
                         (1020, "-15055662", "-15055661"))
        self.assertEqual(v["full_years_certified"], 0)

    def test_past_or_already_pinned_ordinal_not_repeated(self):
        for number in (1017, 1018, 1019):
            with self.subTest(number=number), self.assertRaises(ValueError):
                self.check(rel=s.REQUEST_DIR+f"/ordinal-{number}.json")

    def test_future_gap_1021_rejected(self):
        self.write(self.reqdir/"ordinal-1021.json", dict(self.obj, ordinal=1021))
        with self.assertRaises(ValueError):
            self.check(rel=s.REQUEST_DIR+"/ordinal-1021.json")

    def test_second_or_modified_change_rejected(self):
        for changes in ([], [("M", self.rel)], [("A", self.rel),("M", "README.md")]):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                s.validate_request(self.root, changes)

    def test_wrong_year_or_calculation_day_is_fatal(self):
        for key, value in (("year", "5001"), ("calculation_day", "-15055670"),
                           ("boundary_evidence_sha256", "0"*64)):
            with self.subTest(key=key):
                self.write(self.root/self.rel, dict(self.obj, **{key:value}))
                with self.assertRaises(ValueError):
                    self.check()
                self.write(self.root/self.rel, self.obj)

    def test_wrong_target_ordinal_fails(self):
        for key, value in (("first_target_day", "-15055661"),
                           ("last_target_day", "-15055660"),
                           ("ordinal", True),("ordinal", 1019)):
            with self.subTest(key=key):
                self.write(self.root/self.rel, dict(self.obj, **{key:value}))
                with self.assertRaises(ValueError):
                    self.check()
                self.write(self.root/self.rel, self.obj)

    def test_source_commit_change_fails(self):
        self.write(self.root/self.rel,
                   dict(self.obj, original_source_commits={
                       **s.SOURCE_COMMITS, "REF-41":"0"*40}))
        with self.assertRaises(ValueError):
            self.check()

    def test_extra_metadata_is_not_allowed(self):
        self.write(self.root/self.rel, dict(self.obj, full_year_pass=True))
        with self.assertRaises(ValueError):
            self.check()

    def test_duplicate_json_keys_rejected(self):
        (self.root/self.rel).write_bytes(
            b'{"ordinal":1020,"ordinal":1020}\n')
        with self.assertRaisesRegex(ValueError, "duplicate JSON"):
            self.check()

    def test_noncanonical_or_malformed_request_rejected(self):
        (self.root/self.rel).write_text(json.dumps(self.obj, indent=2)+"\n")
        with self.assertRaisesRegex(ValueError, "canonical"):
            self.check()

    def test_symlink_request_rejected(self):
        path = self.root/self.rel
        path.unlink()
        path.symlink_to(self.control/"original_native_chunk1019_pin_v071.json")
        with self.assertRaises(ValueError):
            self.check()

    def test_missing_pinned_predecessor_rejected(self):
        (self.control/"original_native_chunk1018_pin_v071.json").unlink()
        with self.assertRaisesRegex(ValueError, "gap"):
            self.check()

    def test_duplicate_previous_source_pin_rejected(self):
        other = self.control/"original_native_chunk1019_pin_v999.json"
        self.write(other, s._read_json_canonical(
            self.control/"original_native_chunk1019_pin_v071.json"))
        with self.assertRaisesRegex(ValueError, "duplicate"):
            self.check()

    def test_bad_filename_and_illegal_status_rejected(self):
        for change in ("A", "R100", "D"):
            with self.subTest(change=change), self.assertRaises(ValueError):
                self.check(status=change, rel=s.REQUEST_DIR+"/ordinal-01020.json")

    def test_pretty_printed_frozen_manifest_remains_valid(self):
        path = self.control/"original_native_chunk1019_pin_v071.json"
        obj = s._read_json_canonical(path)
        path.write_text(json.dumps(obj, indent=2, ensure_ascii=False)+"\n", encoding="utf-8")
        self.assertEqual(self.check()["ordinal"], 1020)

    def test_existing_repository_frozen_manifest_format(self):
        repo = Path(__file__).resolve().parents[2]
        self.assertGreaterEqual(s.pinned_prefix(repo), 1019)

    def test_year_end_2121_formula_is_correct(self):
        self.assertEqual(s.FIRST_DAY+2*2121, -15053460)
        self.assertEqual(s.LAST_NEW, 2121)


if __name__ == "__main__":
    unittest.main()
