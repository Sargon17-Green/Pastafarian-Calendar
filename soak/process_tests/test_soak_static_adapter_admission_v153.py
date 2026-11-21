#!/usr/bin/env python3
"""v153: synthetic mutations to pinned v017 Python/JS adapter control paths.

Reads adapter SOURCE TEXT; imports no original historical calendar module.
The suite must NOT launch interpreters or call F(c,t).
"""
from __future__ import annotations

from pathlib import Path
import sys
import unittest

RUNNER = Path(__file__).resolve().parents[1] / "runner"
sys.path.insert(0, str(RUNNER))
from soak_static_adapter_admission_v153 import (
    check_python_wrapper, check_javascript_wrapper, WRAPPER_GIT_BLOBS
)


class StaticAdapterAdmissionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.py = (RUNNER / WRAPPER_GIT_BLOBS["REF-41"][0]).read_text(encoding="utf8")
        cls.js = (RUNNER / WRAPPER_GIT_BLOBS["REF-24"][0]).read_text(encoding="utf8")

    def py_blocked(self, src, expected=None):
        with self.assertRaises(ValueError) as caught:
            check_python_wrapper(src)
        if expected:
            self.assertIn(expected, str(caught.exception))

    def js_blocked(self, src, expected=None):
        with self.assertRaises(ValueError) as caught:
            check_javascript_wrapper(src)
        if expected:
            self.assertIn(expected, str(caught.exception))

    def substitute(self, text, old, new):
        self.assertIn(old, text, "mutation anchor missing in real frozen adapter")
        return text.replace(old, new, 1)

    def test_01_pinned_python_adapter_static_checkonly_pass(self):
        v = check_python_wrapper(self.py)
        self.assertEqual(v["engine_id"], "REF-41")
        self.assertTrue(v["static_check_only_guard_precedes_resource_admission"])
        self.assertFalse(v["dynamic_original_execution_attested"])

    def test_02_pinned_js_adapter_static_checkonly_pass(self):
        v = check_javascript_wrapper(self.js)
        self.assertEqual(v["engine_id"], "REF-24")
        self.assertTrue(v["static_native_producer_after_resource_admission"])
        self.assertFalse(v["dynamic_original_execution_attested"])

    def test_03_python_not_checkonly_condition_rejected(self):
        self.py_blocked(self.substitute(self.py,"if a.check_only:","if not a.check_only:"),
                        "condition absent")

    def test_04_python_checkonly_return_modified_rejected(self):
        self.py_blocked(self.substitute(self.py, "        return 0\n    if os.environ.get",
                            "        return 1\n    if os.environ.get"),"does not return")

    def test_05_python_calendar_called_in_checkonly_rejected(self):
        self.py_blocked(self.substitute(
            self.py, "    if a.check_only:\n",
            "    if a.check_only:\n        cal.calendar_date_ids(1, 1)\n"),
            "check-only branch attempts")

    def test_06_python_resource_guard_is_deleted_rejected(self):
        self.py_blocked(self.substitute(self.py,
            'os.environ.get("PASTAFARI_SOAK_RESOURCE_ADMITTED")',
            'os.environ.get("SOME_OTHER_VARIABLE")'), "resource admission")

    def test_07_python_produce_called_before_resource_gate_rejected(self):
        self.py_blocked(self.substitute(self.py, "    if a.check_only:\n",
            "    produce(None, None, 0, 0)\n    if a.check_only:\n"),
            "before resource admission")

    def test_08_python_missing_sha_hash_check_rejected(self):
        self.py_blocked(self.substitute(self.py, "(len(data), sha(data), blob(data))",
                            "(len(data), 'forged', blob(data))"), "source/adapter binding")

    def test_09_python_source_loader_does_not_execute_module_rejected(self):
        self.py_blocked(self.substitute(
            self.py, "module_spec.loader.exec_module(module)",
            "pass  # deliberately skip native source"), "source/adapter binding")

    def test_10_python_wrong_raw_line_digest_rejected(self):
        self.py_blocked(self.substitute(self.py, '"source_raw_sha256": sha(raw_line)',
                            '"source_raw_sha256": "0" * 64'), "source/adapter binding")

    def test_11_python_duplicate_main_function_rejected(self):
        self.py_blocked(self.py + "\ndef main():\n    return 0\n", "duplicate")

    def test_12_python_conditional_no_abort_on_missing_admission_rejected(self):
        self.py_blocked(self.substitute(
            self.py, 'raise RuntimeError("Windows resource admission not confirmed by scheduler")',
            'print("unsafe admission")'), "fails to abort")

    def test_13_js_missing_checkonly_condition_rejected(self):
        self.js_blocked(self.substitute(self.js,"if (args['check-only']) {",
                            "if (args['not-check-only']) {"), "check-only or resource guard")

    def test_14_js_checkonly_return_removed_rejected(self):
        self.js_blocked(self.substitute(
            self.js, "    return;\n  }\n  if (process.env.",
            "    console.log('continue');\n  }\n  if (process.env."), "zero-date return")

    def test_15_js_no_resource_gate_rejected(self):
        self.js_blocked(self.substitute(
            self.js, "if (process.env.PASTAFARI_SOAK_RESOURCE_ADMITTED !== '1')",
            "if (process.env.PASTAFARI_SOAK_RESOURCE_ADMITTED !== '0')"), "lacks pinned source")

    def test_16_js_original_calendar_called_pre_admission_rejected(self):
        self.js_blocked(self.substitute(
            self.js, "  if (args['check-only']) {",
            "  entry.native.calendarDate(1n, 1n);\n  if (args['check-only']) {"),
            "before resource admission")

    def test_17_js_original_native_require_bypass_rejected(self):
        self.js_blocked(self.substitute(
            self.js, "const native = require(engineFile);",
            "const native = require('./replacement-module');"), "lacks pinned source")

    def test_18_js_output_sha_byte_link_missing_rejected(self):
        self.js_blocked(self.substitute(self.js,
            "source_raw_sha256: hash(rawLine)",
            "source_raw_sha256: 'f'.repeat(64)"), "lacks pinned source")

    def test_19_js_date_results_no_longer_mapped_by_original_catalog_rejected(self):
        self.js_blocked(self.substitute(self.js,
            "entry.indexFromNative('month', monthName)",
            "parseInt(monthName, 10)"), "lacks pinned source")

    def test_20_js_duplicate_main_function_rejected(self):
        self.js_blocked(self.js + "\nfunction main() { return; }\n",
                        "not uniquely declared")


if __name__=="__main__":
    unittest.main()
