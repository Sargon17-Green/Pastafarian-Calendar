"""Synthetic Git-history contract tests; fixtures do not claim a real Rust legacy RED."""

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from stage04_rust_witness_provenance import ProvenanceError, verify_pin


class TestRustWitnessProvenance(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.repo = Path(self.tmp.name)
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.email", "qa@example.invalid")
        self.git("config", "user.name", "Fixture QA")
        self.a = self.commit({
            "src/lib.rs": "pub fn bootstrap() {}\n",
            "tests/support/normative_oracle.rs": "pub fn day_count() {}\n",
        })
        self.good_blob = self.git("rev-parse", f"{self.a}:src/lib.rs")
        self.test_blob = self.git("rev-parse", f"{self.a}:tests/support/normative_oracle.rs")
        self.b = self.commit({"src/save.rs": "pub fn save() {}\n"})
        self.c = self.commit({"src/discovery02_day_tag_probe.rs": "pub fn probe() {}\n"})
        self.d = self.commit({"DEVELOPMENT_STAGE.md": "CURRENT_STAGE=4\n"})
        self.git("checkout", "-qb", "foreign", self.a)
        self.foreign = self.commit({
            "src/legacy_day_tag.rs": "pub fn legacy() {}\n",
            "src/pastafari_calendar/legacy_day_counts.py": "def oldDayTag(x): return x\n",
        })
        self.foreign_blob = self.git("rev-parse", f"{self.foreign}:src/legacy_day_tag.rs")
        self.python_blob = self.git("rev-parse", f"{self.foreign}:src/pastafari_calendar/legacy_day_counts.py")
        self.git("checkout", "-q", "main")

    def git(self, *args):
        return subprocess.check_output(["git", "-C", str(self.repo), *args],
                                       stderr=subprocess.DEVNULL, text=True, timeout=12).strip()

    def commit(self, files):
        for name, content in files.items():
            path = self.repo / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")
        self.git("add", ".")
        self.git("commit", "-qm", "synthetic test history")
        return self.git("rev-parse", "HEAD")

    def check(self, commit=None, path="src/lib.rs", blob=None, stage3=None,
              stage4=None, head=None):
        return verify_pin(self.repo, commit or self.a, path,
                          blob or self.good_blob, stage3 or self.b,
                          stage4 or self.c, head or self.d)

    def test_valid_source_blob_pin_does_not_imply_runtime_red(self):
        result = self.check()
        self.assertTrue(result["source_pin_eligible"])
        self.assertFalse(result["historical_day_tag_route_proven"])
        self.assertFalse(result["observed_runtime_red"])
        self.assertEqual(result["stage04_closure"], "NOT_CLAIMED")

    def test_rejects_tests_support_oracle(self):
        with self.assertRaises(ProvenanceError):
            self.check(path="tests/support/normative_oracle.rs", blob=self.test_blob)

    def test_rejects_foreign_python_archive(self):
        with self.assertRaises(ProvenanceError):
            self.check(commit=self.foreign, path="src/pastafari_calendar/legacy_day_counts.py", blob=self.python_blob)

    def test_rejects_diverged_rust_commit_even_when_path_is_valid(self):
        with self.assertRaises(ProvenanceError):
            self.check(commit=self.foreign, path="src/legacy_day_tag.rs", blob=self.foreign_blob)

    def test_rejects_first_stage4_introduction(self):
        blob = self.git("rev-parse", f"{self.c}:src/discovery02_day_tag_probe.rs")
        with self.assertRaises(ProvenanceError):
            self.check(commit=self.c, path="src/discovery02_day_tag_probe.rs", blob=blob)

    def test_rejects_wrong_blob_sha(self):
        with self.assertRaises(ProvenanceError):
            self.check(blob=self.test_blob)

    def test_rejects_disconnected_stage_head(self):
        with self.assertRaises(ProvenanceError):
            self.check(head=self.foreign)

    def test_rejects_traversal_path(self):
        with self.assertRaises(ProvenanceError):
            self.check(path="src/../tests/support/normative_oracle.rs")

    def test_rejects_shallow_or_wrong_length_hash(self):
        with self.assertRaises(ProvenanceError):
            self.check(commit="abc123")


if __name__ == "__main__":
    unittest.main()
