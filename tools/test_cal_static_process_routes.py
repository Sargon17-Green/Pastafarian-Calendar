#!/usr/bin/env python3
"""Offline regression tests: pinned source-only executable launch routes."""
import hashlib
import unittest
from unittest.mock import patch

import cal_source_provenance as provenance
import cal_static_process_routes as scanner


def fixture_sources():
    sources = {filename: [] for filename in provenance.FILES}
    for _, (filename, header, markers) in scanner.ROUTES.items():
        sources[filename].append(header)
        sources[filename].extend(markers)
        sources[filename].append("")
    for _, (filename, statement) in scanner.ENTRY_MARKERS.items():
        sources[filename].append(statement)
    return {name: ("\n".join(lines) + "\n").encode("latin-1")
            for name, lines in sources.items()}


def pins(data):
    expected = {name: (provenance.git_blob_sha1(raw), len(raw))
                for name, raw in data.items()}
    sha256 = {name: hashlib.sha256(raw).hexdigest()
              for name, raw in data.items()}
    return (patch.object(provenance, "EXPECTED", {"release": expected}),
            patch.object(provenance, "EXPECTED_SHA256", {"release": sha256}))


def with_fixture(data):
    class Pinned:
        def __enter__(self):
            self.a, self.b = pins(data)
            self.a.__enter__()
            self.b.__enter__()
            return lambda group, name: data[name]

        def __exit__(self, typ, value, traceback):
            self.b.__exit__(typ, value, traceback)
            self.a.__exit__(typ, value, traceback)
    return Pinned()


class ProcessRouteTests(unittest.TestCase):
    def test_pinned_fixture_reports_both_exe_launch_paths(self):
        data = fixture_sources()
        with with_fixture(data) as reader:
            result = scanner.audit(reader)
        self.assertTrue(result["static_process_route_gate_pass"])
        self.assertEqual(result["verified_text_modules"], 6)
        self.assertEqual(len(result["process_calls_and_apis"]["start_current_process_statement"]), 2)
        self.assertEqual(len(result["process_calls_and_apis"]["stop_current_process_statement"]), 1)
        self.assertEqual(len(result["paths"]), 6)
        self.assertEqual(len(result["menu_and_keyboard_entries"]), 8)

    def test_no_unsafe_execution_or_absence_claim(self):
        data = fixture_sources()
        with with_fixture(data) as reader:
            result = scanner.audit(reader)
        for flag in ("compiler_executed", "observed_execution",
                     "malware_clearance", "stage_zero_verified",
                     "native_qa_99_pass", "full_control_flow_proven",
                     "absence_of_unlisted_execution_paths_proven"):
            self.assertIs(result[flag], False, flag)

    def test_pinned_source_integrity_checked_before_scan(self):
        with self.assertRaisesRegex(ValueError, "Pinned Plain English source mismatch"):
            scanner.audit(lambda group, filename: b"tampered")

    def test_finder_exe_guard_is_required(self):
        data = fixture_sources()
        data["the finder"] = data["the finder"].replace(b'".exe"', b'".txt"')
        with with_fixture(data) as reader:
            with self.assertRaisesRegex(ValueError, "extension is not"):
                scanner.audit(reader)

    def test_editor_must_use_compiled_executable_path(self):
        data = fixture_sources()
        data["the desktop"] = data["the desktop"].replace(
            b"Start the current process given the compiler's exe path.",
            b"Start the current process given the wrong path.")
        with with_fixture(data) as reader:
            with self.assertRaisesRegex(ValueError, "compiler's exe path"):
                scanner.audit(reader)

    def test_process_api_rename_fails_closed(self):
        data = fixture_sources()
        data["the noodle"] = data["the noodle"].replace(
            b'"CreateProcessA"', b'"CreateProcessMaybe"')
        with with_fixture(data) as reader:
            with self.assertRaisesRegex(ValueError, "CreateProcessA"):
                scanner.audit(reader)

    def test_extra_launch_site_requires_review(self):
        data = fixture_sources()
        data["the writer"] += b"Start the current process given an unknown path.\n"
        with with_fixture(data) as reader:
            with self.assertRaisesRegex(ValueError, "start_current_process_statement"):
                scanner.audit(reader)

    def test_menu_run_dispatch_required(self):
        data = fixture_sources()
        data["the desktop"] = data["the desktop"].replace(
            b'If the command\'s handler is "handle run", handle run; exit.',
            b'If the command\'s handler is "handle run", do nothing; exit.')
        with with_fixture(data) as reader:
            with self.assertRaisesRegex(ValueError, "menu/dispatch statement"):
                scanner.audit(reader)

    def test_keyboard_shortcut_editor_required(self):
        data = fixture_sources()
        data["the desktop"] = data["the desktop"].replace(
            b'If the event\'s key is the r-key and the current tab\'s mode is "editor", handle run; exit.',
            b'If the event\'s key is the q-key and the current tab\'s mode is "editor", handle run; exit.')
        with with_fixture(data) as reader:
            with self.assertRaisesRegex(ValueError, "menu/dispatch statement"):
                scanner.audit(reader)

    def test_thread_wait_statement_cannot_disappear(self):
        data = fixture_sources()
        data["the noodle"] = data["the noodle"].replace(
            b'"WaitForSingleObject"', b'"UnwaitForSingleObject"')
        with with_fixture(data) as reader:
            with self.assertRaisesRegex(ValueError, "WaitForSingleObject"):
                scanner.audit(reader)

    def test_routine_headers_prevent_cross_scope_matches(self):
        data = fixture_sources()
        data["the finder"] = data["the finder"].replace(
            b"Start the current process given the nodette's path.",
            b"To unrelated routine:\nStart the current process given the nodette's path.")
        with with_fixture(data) as reader:
            with self.assertRaisesRegex(ValueError, "nodette's path"):
                scanner.audit(reader)

    def test_comments_do_not_count_as_executable_launch_sites(self):
        data = fixture_sources()
        data["the writer"] += b"\\ Start the current process given a comment.\n"
        with with_fixture(data) as reader:
            result = scanner.audit(reader)
        self.assertEqual(len(result["process_calls_and_apis"]["start_current_process_statement"]), 2)


if __name__ == "__main__":
    unittest.main()
