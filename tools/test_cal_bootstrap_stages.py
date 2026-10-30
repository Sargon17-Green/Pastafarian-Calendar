#!/usr/bin/env python3
"""Offline CAL tutorial tree-manifest tests: only JSON metadata is read."""
import copy
import json
import unittest

import cal_bootstrap_stage_inventory as inv


def original():
    return json.loads(inv.MANIFEST.read_text(encoding="utf-8"))


class TutorialInventoryTests(unittest.TestCase):
    def test_exact_pinned_eight_stages_are_consistent(self):
        report = inv.validate(original())
        self.assertTrue(report["stage_metadata_consistent"])
        self.assertEqual(report["tutorial_stages"], 8)
        self.assertEqual(report["distinct_compiler_blobs"], 8)
        self.assertEqual(report["distinct_binary_blob_metadata"], 4)
        self.assertEqual(report["first_stage_with_binary_metadata"], "passo03")
        self.assertFalse(report["binary_downloaded"])
        self.assertFalse(report["compiler_executed"])
        self.assertFalse(report["stage_zero_verified"])
        self.assertFalse(report["native_qa_99_pass"])

    def test_reject_replaced_stage_tree(self):
        data = original()
        data["stages"][4]["tree_sha"] = "a" * 40
        with self.assertRaisesRegex(inv.ManifestError, "upstream stage tree changed"):
            inv.validate(data)

    def test_reject_replaced_compiler_blob(self):
        data = original()
        data["stages"][5]["sources"]["the compiler"]["sha"] = "a" * 40
        with self.assertRaisesRegex(inv.ManifestError, "compiler blob replaced"):
            inv.validate(data)

    def test_reject_replaced_binary_blob(self):
        data = original()
        data["stages"][3]["binary_objects"]["cal-4700's son.exe3"]["sha"] = "a" * 40
        with self.assertRaisesRegex(inv.ManifestError, "binary blob replaced"):
            inv.validate(data)

    def test_reject_early_binary_or_unspecified_entry(self):
        data = original()
        data["stages"][0]["binary_objects"]["cal-4700's son.exe2"] = copy.deepcopy(
            data["stages"][2]["binary_objects"]["cal-4700's son.exe2"]
        )
        with self.assertRaisesRegex(inv.ManifestError, "stage binary list mismatch"):
            inv.validate(data)

    def test_reject_unexpected_runtime_change(self):
        data = original()
        data["stages"][2]["sources"]["the writer"]["sha"] = "a" * 40
        with self.assertRaisesRegex(inv.ManifestError, "runtime source drift"):
            inv.validate(data)

    def test_reject_missing_final_noodle_change(self):
        data = original()
        data["stages"][-1]["sources"]["the noodle"] = copy.deepcopy(
            data["stages"][0]["sources"]["the noodle"]
        )
        with self.assertRaisesRegex(inv.ManifestError, "missing final-stage noodle change"):
            inv.validate(data)

    def test_never_claims_binary_execution_or_native_pass(self):
        for flag in ("binary_downloaded", "compiler_executed",
                     "stage_zero_verified", "native_qa_99_pass"):
            with self.subTest(flag=flag):
                data = original()
                data[flag] = True
                with self.assertRaisesRegex(inv.ManifestError, "unsupported trust claim"):
                    inv.validate(data)

    def test_reject_other_upstream_revision(self):
        data = original()
        data["commit"] = "a" * 40
        with self.assertRaisesRegex(inv.ManifestError, "upstream commit changed"):
            inv.validate(data)


if __name__ == "__main__":
    unittest.main()
