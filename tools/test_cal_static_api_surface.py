#!/usr/bin/env python3
"""Offline tests of the source-only Windows API capability inventory."""
import hashlib
from unittest import TestCase, main
from unittest.mock import patch

import cal_source_provenance as p
import cal_static_api_surface as a


class StaticApiAuditTests(TestCase):
    def test_extract_api_references_with_line_numbers(self):
        lines = (
            b'\\ Call "kernel32.dll" "DeleteFileA" with a path.\n'
            b'To start a process:\n'
            b'Call "kernel32.dll" "CreateProcessA" with a path.\n'
            b'Call "winhttp.dll" "WinHttpSendRequest" with a handle.\n'
        )
        found = a.extract_calls(lines, "the noodle")
        self.assertEqual([(x["line"], x["reference"]) for x in found], [
            (3, "kernel32.dll!CreateProcessA"),
            (4, "winhttp.dll!WinHttpSendRequest"),
        ])

    def test_category_distinguishes_sensitive_capabilities(self):
        self.assertEqual(a.categories("kernel32.dll", "CreateProcessA"),
                         ["process_or_dynamic_loading"])
        self.assertEqual(a.categories("kernel32.dll", "DeleteFileA"),
                         ["filesystem_mutation"])
        self.assertEqual(a.categories("wininet.dll", "InternetReadFile"),
                         ["network"])
        self.assertEqual(a.categories("advapi32.dll", "CryptDeriveKey"),
                         ["legacy_cryptography"])
        self.assertEqual(a.categories("gdi32.dll", "CreateFontA"), [])

    def test_six_source_fixture_has_no_execution_or_safety_claim(self):
        data = {name: b'To count:\n' for name in p.FILES}
        data["the noodle"] = (
            b'Call "kernel32.dll" "CreateProcessA" with 0.\n'
            b'Call "advapi32.dll" "CryptCreateHash" with 0. [calg_md5]\n'
            b'Call "advapi32.dll" "CryptDeriveKey" with 0. [calg_rc4 stream cipher]\n'
            b'To send an email:\n'
            b"Create a socket given the email's smtp server and 25.\n"
        )
        expected = {name: (p.git_blob_sha1(blob), len(blob))
                    for name, blob in data.items()}
        hashes = {name: hashlib.sha256(blob).hexdigest()
                  for name, blob in data.items()}
        with patch.object(p, "EXPECTED", {"release": expected}):
            with patch.object(p, "EXPECTED_SHA256", {"release": hashes}):
                report = a.audit(lambda group, name: data[name],
                                 require_known_surface=False)
        self.assertEqual(report["api_reference_occurrences"], 3)
        self.assertTrue(report["six_text_sources_hash_verified"])
        self.assertTrue(all(report["features"].values()))
        self.assertFalse(report["binary_downloaded"])
        self.assertFalse(report["compiler_executed"])
        self.assertFalse(report["native_qa_99_pass"])
        self.assertFalse(report["stage_zero_verified"])
        self.assertFalse(report["malware_clearance"])
        self.assertFalse(report["execution_reachability_proven"])

    def test_unrecognized_sensitive_api_is_not_silently_accepted(self):
        data = {name: b'To count:\\n' for name in p.FILES}
        data["the noodle"] = (
            b'Call "winhttp.dll" "WinHttpUnlisted" with a handle.\\n'
            b'[calg_md5] [calg_rc4 stream cipher]\\n'
            b'To send an email:\\n'
            b"Create a socket given the email's smtp server and 25.\\n"
        )
        expected = {name: (p.git_blob_sha1(blob), len(blob))
                    for name, blob in data.items()}
        hashes = {name: hashlib.sha256(blob).hexdigest()
                  for name, blob in data.items()}
        with patch.object(p, "EXPECTED", {"release": expected}):
            with patch.object(p, "EXPECTED_SHA256", {"release": hashes}):
                with patch.object(a, "REQUIRED", set()):
                    with self.assertRaisesRegex(ValueError, "WinHttpUnlisted"):
                        a.audit(lambda group, name: data[name])

    def test_missing_expected_api_blocks_strict_audit(self):
        data = {name: b'To count:\n' for name in p.FILES}
        expected = {name: (p.git_blob_sha1(blob), len(blob))
                    for name, blob in data.items()}
        hashes = {name: hashlib.sha256(blob).hexdigest()
                  for name, blob in data.items()}
        with patch.object(p, "EXPECTED", {"release": expected}):
            with patch.object(p, "EXPECTED_SHA256", {"release": hashes}):
                with self.assertRaisesRegex(ValueError, "Sensitive source API audit changed"):
                    a.audit(lambda group, name: data[name])

    def test_hash_mismatch_is_not_reported_as_pass(self):
        with self.assertRaisesRegex(ValueError, "Pinned source byte check failed"):
            a.audit(lambda group, name: b"not the original source",
                    require_known_surface=False)

    def test_crypto_and_smtp_markers_are_exact(self):
        data = b'[calg_md5] [calg_rc4 stream cipher]\nTo send an email:\n'
        calls = a.extract_calls(data, "the noodle")
        self.assertEqual(calls, [])
        self.assertNotIn(b"email's smtp server and 25", data)


if __name__ == "__main__":
    main()
