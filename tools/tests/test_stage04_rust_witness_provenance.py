"""Synthetic Git-history contract tests; fixtures do not claim a real Rust legacy RED."""

import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import stage04_rust_witness_provenance as provenance
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
        # The synthetic repository has its own explicitly pinned boundaries.
        self.boundary_patch = patch.multiple(
            provenance, CANONICAL_STAGE3_CLOSURE=self.b,
            CANONICAL_STAGE4_INTRODUCTION=self.c)
        self.boundary_patch.start()
        self.addCleanup(self.boundary_patch.stop)

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

    def test_forged_later_boundaries_cannot_make_post_stage4_source_eligible(self):
        # All Git ancestry and blob checks pass under the old implementation.
        # Only binding the checkpoint identities to their canonical values
        # prevents relabeling a newly added source as historical.
        post4 = self.commit({
            "src/post_stage4.rs": "pub fn fake_old_daytag() {}\n",
        })
        blob = self.git("rev-parse", f"{post4}:src/post_stage4.rs")
        forged_stage3 = self.commit({"forged_stage3.txt": "later checkpoint\n"})
        forged_stage4 = self.commit({"forged_stage4.txt": "later introduction\n"})
        with self.assertRaisesRegex(ProvenanceError, "canonical Stage03/Stage04"):
            self.check(commit=post4, path="src/post_stage4.rs", blob=blob,
                       stage3=forged_stage3, stage4=forged_stage4,
                       head=forged_stage4)

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

    def test_rejects_equal_stage3_and_stage4_boundaries(self):
        # merge-base --is-ancestor returns 0 for identical commits, but
        # Stage4 introduction must be a strictly later Git revision.
        with self.assertRaises(ProvenanceError):
            self.check(stage3=self.c, stage4=self.c)

    def test_allows_stage4_introduction_as_current_head(self):
        # Stage4 may be the current checkout, with no subsequent commit.
        self.git("checkout", "-q", "--detach", self.c)
        self.addCleanup(lambda: self.git("checkout", "-q", "main"))
        result = self.check(head=self.c)
        self.assertTrue(result["source_pin_eligible"])
        self.assertFalse(result["observed_runtime_red"])

    def test_rejects_stale_ancestor_disguised_as_checkout_head(self):
        # c is an ancestor of actual HEAD d, but cannot be claimed as the checkout.
        with self.assertRaises(ProvenanceError):
            self.check(head=self.c)

    def test_rejects_future_descendant_disguised_as_checkout_head(self):
        # Conversely a descendant can exist even while HEAD is at Stage4.
        self.git("checkout", "-q", "--detach", self.c)
        self.addCleanup(lambda: self.git("checkout", "-q", "main"))
        with self.assertRaises(ProvenanceError):
            self.check(head=self.d)

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


    def test_rejects_symlink_git_tree_blob_despite_matching_sha(self):
        # Git mode 120000 is a *blob*, but never a production Rust source file.
        # Construct the entry directly in the index; works without OS symlink rights.
        self.git("checkout", "-qb", "symlink_fixture", self.a)
        self.addCleanup(lambda: self.git("checkout", "-q", "main"))
        pointer = self.repo / "synthetic_symlink_target.txt"
        pointer.write_text("lib.rs", encoding="utf-8")
        link_blob = self.git("hash-object", "-w", "synthetic_symlink_target.txt")
        pointer.unlink()
        self.git("update-index", "--add", "--cacheinfo",
                 f"120000,{link_blob},src/symlink_witness.rs")
        self.git("commit", "-qm", "synthetic pre-stage3 symlink")
        witness = self.git("rev-parse", "HEAD")
        self.assertEqual(self.git("rev-parse", witness + ":src/symlink_witness.rs"), link_blob)
        self.assertEqual(self.git("cat-file", "-t", link_blob), "blob")
        stage3 = self.commit({"SYMLINK_STAGE3.txt": "closure\n"})
        stage4 = self.commit({"SYMLINK_STAGE4.txt": "introduction\n"})
        head = self.commit({"SYMLINK_HEAD.txt": "head\n"})
        with patch.multiple(provenance, CANONICAL_STAGE3_CLOSURE=stage3,
                            CANONICAL_STAGE4_INTRODUCTION=stage4):
            with self.assertRaisesRegex(ProvenanceError, "regular Git tree blob"):
                verify_pin(self.repo, witness, "src/symlink_witness.rs", link_blob,
                           stage3, stage4, head)

    def test_accepts_executable_regular_git_tree_blob(self):
        # 100755 is a regular blob, unlike symlink mode 120000.
        self.git("checkout", "-qb", "executable_fixture", self.a)
        self.addCleanup(lambda: self.git("checkout", "-q", "main"))
        self.git("update-index", "--chmod=+x", "src/lib.rs")
        self.git("commit", "-qm", "synthetic executable regular Rust file")
        witness = self.git("rev-parse", "HEAD")
        blob = self.git("rev-parse", witness + ":src/lib.rs")
        stage3 = self.commit({"EXEC_STAGE3.txt": "closure\n"})
        stage4 = self.commit({"EXEC_STAGE4.txt": "introduction\n"})
        head = self.commit({"EXEC_HEAD.txt": "head\n"})
        with patch.multiple(provenance, CANONICAL_STAGE3_CLOSURE=stage3,
                            CANONICAL_STAGE4_INTRODUCTION=stage4):
            result = verify_pin(self.repo, witness, "src/lib.rs", blob,
                                stage3, stage4, head)
        self.assertTrue(result["source_pin_eligible"])
        self.assertFalse(result["historical_day_tag_route_proven"])
        self.assertFalse(result["observed_runtime_red"])
        self.assertEqual(result["stage04_closure"], "NOT_CLAIMED")


if __name__ == "__main__":
    unittest.main()
