#!/usr/bin/env python3
"""Artifact-free negative controls for the finite QA30B/QA20 storage-offset guard.

Run: python qa/test_stage1_qa31f_qa30b_lineage_guards.py
Native artifacts are NOT exercised here; these are unit-level adversarial checks.
"""
import unittest
from stage1_qa31f_qa30b_live_put_lineage import guard_no_offset_rebase


def step(tick, op, physical=True):
    return (tick, 0, 0, 1, 0, ord(op), 0 if physical else 1)


class StorageOffsetGuardTests(unittest.TestCase):
    def setUp(self):
        self.ok = [step(1, ">"), step(2, "p"), step(3, ">"),
                   step(4, "p"), step(5, "g"), step(6, "j")]

    def test_clean_signed_path(self):
        guard_no_offset_rebase(self.ok, 2, 5)

    def test_left_brace_rejected(self):
        s = list(self.ok); s[2] = step(3, "{")
        with self.assertRaisesRegex(AssertionError, "storage-offset"):
            guard_no_offset_rebase(s, 2, 5)

    def test_right_brace_rejected(self):
        s = list(self.ok); s[2] = step(3, "}")
        with self.assertRaisesRegex(AssertionError, "storage-offset"):
            guard_no_offset_rebase(s, 2, 5)

    def test_stack_stack_u_rejected_conservatively(self):
        s = list(self.ok); s[3] = step(4, "u")
        with self.assertRaisesRegex(AssertionError, "storage-offset"):
            guard_no_offset_rebase(s, 2, 5)

    def test_before_original_put_ignored(self):
        s = list(self.ok); s[0] = step(1, "{")
        guard_no_offset_rebase(s, 2, 5)

    def test_after_gate_ignored(self):
        s = list(self.ok); s[4] = step(5, "{")
        guard_no_offset_rebase(s, 2, 5)

    def test_nonphysical_control_ignored(self):
        s = list(self.ok); s[2] = step(3, "{", False)
        guard_no_offset_rebase(s, 2, 5)

    def test_corrupt_tick_sequence_rejected(self):
        s = list(self.ok); s[2] = step(4, ">")
        with self.assertRaisesRegex(AssertionError, "nonsequential"):
            guard_no_offset_rebase(s, 2, 5)

    def test_invalid_gate_bounds_rejected(self):
        for start, gate in ((0, 5), (5, 5), (3, 2), (2, 99)):
            with self.subTest(start=start, gate=gate):
                with self.assertRaisesRegex(AssertionError, "bounds"):
                    guard_no_offset_rebase(self.ok, start, gate)


if __name__ == "__main__":
    unittest.main()
