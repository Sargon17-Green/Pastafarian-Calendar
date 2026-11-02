"""Synthetic, Git-backed subprocess tests: no actual TABLETS oracle."""
import hashlib
from pathlib import Path
import subprocess
import sys
import tempfile
from time import monotonic
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
from tablets_date_module_provenance import DateModule
from tablets_five_field_contract import TARGETS
from tablets_isolated_date_runtime import compare_isolated_dates, IsolationError, STATUS


def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args],
                                   text=True, stderr=subprocess.DEVNULL).strip()


class RuntimeTests(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.roots = []
        for name, code in (
            ("left", "def date_tuple(a,b):\n    x = len('a')\n    return (5000,x,x,x,x)\n"),
            ("right", "def date_tuple(a,b):\n    return tuple([5000] + [1]*4)\n"),
        ):
            root = Path(tmp.name) / name
            root.mkdir()
            git(root, "init", "-q")
            git(root, "config", "user.email", "fixture@example.invalid")
            git(root, "config", "user.name", "Fixture")
            (root / "date.py").write_text(code)
            git(root, "add", "date.py")
            git(root, "commit", "-qm", "fixture")
            self.roots.append(root)

    def module(self, n):
        root = self.roots[n]
        return DateModule(root, "date.py", git(root, "rev-parse", "HEAD"),
                          hashlib.sha256((root / "date.py").read_bytes()).hexdigest(),
                          "date_tuple")

    def run_pair(self):
        with patch("tablets_date_module_provenance.PINNED_SHA",
                   git(self.roots[1], "rev-parse", "HEAD")):
            return compare_isolated_dates(self.module(0), self.module(1),
                                          deadline=monotonic() + 20)

    def replace(self, code):
        root = self.roots[0]
        (root / "date.py").write_text(code)
        git(root, "add", "date.py")
        git(root, "commit", "-qm", "revised fixture")

    def test_three_by_five_distinct_processes_remain_diagnostic(self):
        data = self.run_pair()
        self.assertEqual(data["status"], STATUS)
        self.assertEqual((data["cases"], data["fields_per_case"]), (3, 5))
        self.assertEqual(data["targets"], list(TARGETS))
        self.assertNotEqual(*data["process_pids"])
        self.assertEqual(data["python_flags"], ["-I", "-S", "-B"])
        self.assertFalse(data["full_date_certified"])
        self.assertFalse(data["external_cache_isolation_verified"])
        self.assertFalse(data["algorithmic_independence_certified"])
        self.assertFalse(data["unseeded_gate_replay_verified"])

    def test_single_component_mismatch_fails_closed(self):
        self.replace("def date_tuple(a,b):\n"
                     "    return (5000,1,1,2 if b == -278522 else 1,1)\n")
        with self.assertRaisesRegex(IsolationError, "MISMATCH_-278522:month_index"):
            self.run_pair()

    def test_bad_field_count_fails_closed(self):
        self.replace("def date_tuple(a,b):\n    return (5000,1,1,1)\n")
        with self.assertRaisesRegex(IsolationError, "E_RUNTIME_EXIT"):
            self.run_pair()

    def test_stdout_injection_fails_closed(self):
        self.replace("def date_tuple(a,b):\n    print('debug')\n"
                     "    return (5000,1,1,1,1)\n")
        with self.assertRaisesRegex(IsolationError, "E_RUNTIME_ROW_COUNT"):
            self.run_pair()

    def test_pythonpath_does_not_leak(self):
        self.replace("import os\n"
                     "def date_tuple(a,b):\n"
                     "    assert 'PYTHONPATH' not in os.environ\n"
                     "    return (5000,1,1,1,1)\n")
        with patch.dict("os.environ", {"PYTHONPATH": "MALICIOUS"}):
            self.run_pair()

    def test_dirty_source_is_refused(self):
        (self.roots[0] / "date.py").write_text("def date_tuple(a,b): return (2,2,2,2,2)\n")
        with self.assertRaisesRegex(ValueError, "E_INDEPENDENT_WORKTREE_DIRTY"):
            self.run_pair()

    def test_deadline_required_and_bounded(self):
        with patch("tablets_date_module_provenance.PINNED_SHA",
                   git(self.roots[1], "rev-parse", "HEAD")):
            with self.assertRaisesRegex(IsolationError, "E_RUNTIME_DEADLINE"):
                compare_isolated_dates(self.module(0), self.module(1), deadline=None)
            with self.assertRaisesRegex(IsolationError, "E_RUNTIME_DEADLINE"):
                compare_isolated_dates(self.module(0), self.module(1),
                                       deadline=monotonic() + 200)

    def test_pinned_sha_must_match(self):
        with self.assertRaisesRegex(ValueError, "E_PINNED_COMMIT_LOCK"):
            compare_isolated_dates(self.module(0), self.module(1),
                                   deadline=monotonic() + 20)


if __name__ == "__main__":
    unittest.main()
