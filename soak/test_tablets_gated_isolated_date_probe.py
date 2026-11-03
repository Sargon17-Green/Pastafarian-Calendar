"""Synthetic contract tests; no real independent TABLETS date algorithm."""
from __future__ import annotations
import hashlib
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.path.insert(0, str(Path(__file__).resolve().parent))
from tablets_date_module_provenance import DateModule
from tablets_five_field_contract import FOUNDATION, TARGETS
from tablets_gated_isolated_date_probe import ProbeError, STATUS, run_probe

def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args], text=True,
                                   stderr=subprocess.DEVNULL, timeout=10).strip()

def gap_a(_index):
    return 963

def gap_b(_index):
    return 963

class ProbeTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.roots = []
        for i in range(2):
            root = Path(temp.name) / ("ind" if i == 0 else "pin")
            root.mkdir()
            git(root, "init", "-q")
            git(root, "config", "user.email", "fixture@example.invalid")
            git(root, "config", "user.name", "Fixture")
            body = ("def date_tuple(a,b):\n    return (5000,1,1,1,1)\n"
                    if i == 0 else
                    "def date_tuple(a,b):\n    return tuple((5000,1,1,1,1))\n")
            (root / "date.py").write_text(body, encoding="utf-8")
            git(root, "add", "date.py")
            git(root, "commit", "-qm", "fixture")
            self.roots.append(root)

    def module(self, i):
        root = self.roots[i]
        return DateModule(root, "date.py", git(root, "rev-parse", "HEAD"),
                          hashlib.sha256((root / "date.py").read_bytes()).hexdigest(),
                          "date_tuple")

    def run_case(self, left=gap_a, right=gap_b, **kwargs):
        with patch("tablets_date_module_provenance.PINNED_SHA",
                   git(self.roots[1], "rev-parse", "HEAD")):
            return run_probe(self.module(0), self.module(1), left, right, **kwargs)

    def test_all_synthetic_global_indices_then_three_by_five(self):
        data = self.run_case()
        self.assertEqual(data["status"], STATUS)
        self.assertEqual(data["gate_questions"], (TARGETS[-1] - FOUNDATION + 962)//963)
        self.assertGreater(data["gate_questions"], 8192)
        self.assertEqual((data["cases"], data["fields_per_case"]), (3, 5))
        self.assertNotEqual(*data["date_process_pids"])
        self.assertEqual(len(data["cross_layer_receipt_sha256"]), 64)
        self.assertFalse(data["checkpoint_seed_used"])
        for key in ("full_date_certified", "certifiable",
                    "algorithmic_independence_certified",
                    "independent_gap_mathematics_verified_here",
                    "independent_date_mathematics_verified_here",
                    "source_cache_independence_verified_here"):
            self.assertFalse(data[key], key)
        self.assertEqual(data["production_gate_limit_unchanged"], 8192)

    def test_late_gate_mismatch_is_red(self):
        def wrong(index):
            return 962 if index == 15000 else 963
        with self.assertRaisesRegex(ValueError, "E_TABLETS_MISMATCH_AT_15000"):
            self.run_case(left=wrong)

    def test_middle_date_field_mismatch_is_red(self):
        root = self.roots[0]
        (root / "date.py").write_text(
            "def date_tuple(a,b):\n    return (5000,1,1,2 if b == -278522 else 1,1)\n")
        git(root, "add", "date.py")
        git(root, "commit", "-qm", "mismatch")
        with self.assertRaisesRegex(ValueError, "E_RUNTIME_MISMATCH_-278522:month_index"):
            self.run_case()

    def test_same_gap_callable_rejected(self):
        with self.assertRaisesRegex(ProbeError, "E_PROBE_TWO_GAP_FUNCTIONS"):
            self.run_case(left=gap_a, right=gap_a)

    def test_budget_contract(self):
        for kwargs in ({"max_questions": True}, {"segment_limit": 0},
                       {"gate_seconds": 601}, {"date_seconds": 0}):
            with self.subTest(kwargs=kwargs):
                with self.assertRaisesRegex(ProbeError, "E_PROBE_BUDGET"):
                    self.run_case(**kwargs)

    def test_dirty_source_rejected_before_gate_walk(self):
        (self.roots[0] / "date.py").write_text("def date_tuple(a,b): return (1,1,1,1,1)\n")
        with self.assertRaisesRegex(ValueError, "E_INDEPENDENT_WORKTREE_DIRTY"):
            self.run_case()

    def test_insufficient_global_budget_fails_closed(self):
        with self.assertRaisesRegex(ValueError, "E_TABLETS_GEOMETRY_BUDGET"):
            self.run_case(max_questions=8192)

if __name__ == "__main__":
    unittest.main()
