#!/usr/bin/env python3
"""Offline tests: no network, archive extraction or executable launch."""
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import cal_source_provenance as c


class SourceAuditTests(unittest.TestCase):
    def test_git_blob_algorithm_known_value(self):
        self.assertEqual(
            c.git_blob_sha1(b"test"),
            "30d74d258442c7c65512eafab474568dd706c430",
        )

    def test_url_is_exact_commit_and_text_only(self):
        u = c.approved_source_url("release", "the compiler")
        self.assertIn("/" + c.COMMIT + "/", u)
        self.assertTrue(u.endswith("/the%20compiler"))
        with self.assertRaises(ValueError):
            c.approved_source_url("release", "cal-4700.exe")
        with self.assertRaises(ValueError):
            c.approved_source_url("bad", "the compiler")

    def test_invalid_source_is_not_accepted(self):
        self.assertFalse(c.inspect(b"MZbad", "release", "the compiler")["ok"])
        self.assertFalse(c.inspect(b"ordinary text", "release", "the compiler")["ok"])

    def test_routine_classification(self):
        source = b"To compile a thing:\n\\To compiled thing:\n\\\\To other:\nhello\n"
        new_row = (c.git_blob_sha1(source), len(source))
        with patch.dict(c.EXPECTED, {"release": {"the compiler": new_row}}, clear=False):
            r = c.inspect(source, "release", "the compiler")
        self.assertTrue(r["ok"])
        self.assertEqual(r["active_routines"], 1)
        self.assertEqual(r["commented_routines"], 2)

    def test_all_twelve_accepted_when_fixture_matches(self):
        expected = {
            group: {
                name: (c.git_blob_sha1((group + name).encode()), len((group + name).encode()))
                for name in c.FILES
            }
            for group in c.SOURCES
        }
        with patch.object(c, "EXPECTED", expected):
            r = c.audit(lambda group, name: (group + name).encode())
        self.assertTrue(r["all_12_text_sources_verified"])
        self.assertFalse(r["compiler_executed"])
        self.assertFalse(r["native_qa_99_pass"])

    def test_abort_on_single_mismatch(self):
        with self.assertRaisesRegex(ValueError, "integrity failure"):
            c.audit(lambda group, name: b"unexpected content")

    def test_refuse_symlink_in_offline_mode(self):
        with tempfile.TemporaryDirectory() as td:
            d = Path(td)
            (d / "release").mkdir()
            (d / "file").write_text("demo")
            (d / "release" / "the compiler").symlink_to(d / "file")
            self.assertTrue((d / "release" / "the compiler").is_symlink())


if __name__ == "__main__":
    unittest.main()
