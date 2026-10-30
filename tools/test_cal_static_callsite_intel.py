#!/usr/bin/env python3
"""Offline tests for Plain English lexical call site and Intel literal mapping."""
import copy
import hashlib
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import cal_source_provenance as provenance
import cal_static_callsite_intel as audittool


class StaticCallsiteIntelTests(unittest.TestCase):
    def test_intel_bytes_are_hex_only_and_annotated_with_owner(self):
        sample = (b"To add a byte to another byte:\n"
                  b"Intel $8B8508000000. \\ mov eax, [ebp+8]\n"
                  b"Intel $0FB600. \\ movzx eax, [eax]\n")
        r = audittool.scan_text(sample, "the noodle")
        self.assertEqual([x["hex"] for x in r["intel"]],
                         ["8B8508000000", "0FB600"])
        self.assertEqual([x["owner"] for x in r["intel"]],
                         ["add a byte to another byte"] * 2)
        self.assertFalse(r["invalid_intel"])

    def test_bad_or_odd_hex_is_reported_not_executed(self):
        r = audittool.scan_text(
            b"To do a thing:\nIntel $ABC.\nIntel $12GG.\n",
            "the noodle")
        self.assertEqual(len(r["invalid_intel"]), 2)
        self.assertFalse(r["intel"])

    def test_comment_is_not_treated_as_live_code(self):
        sample = (b"To do a thing:\n"
                  b"\\ Intel $9090.\n"
                  b'\\ Call "kernel32.dll" "CreateProcessA".\n'
                  b"Intel $90.\n")
        r = audittool.scan_text(sample, "the noodle")
        self.assertEqual(len(r["intel"]), 1)
        self.assertEqual(r["intel"][0]["hex"], "90")
        self.assertEqual(r["dll"], [])

    def test_sensitive_api_owner_is_nearest_routine(self):
        sample = (b"To start a process given a path:\n"
                  b'Call "kernel32.dll" "CreateProcessA" with the path.\n'
                  b"To stop a process:\n"
                  b'Call "kernel32.dll" "TerminateProcess" with it.\n')
        r = audittool.scan_text(sample, "the noodle")
        self.assertEqual([(v["owner"], v["api"]) for v in r["dll"]], [
            ("start a process given a path", "kernel32.dll!CreateProcessA"),
            ("stop a process", "kernel32.dll!TerminateProcess"),
        ])

    def test_literal_email_and_resolver_call_sites(self):
        sample = (b"To get a sockaddr given a host string:\n"
                  b"Get some addrinfo routines.\n"
                  b"To send a message to someone:\nSend the email.\n")
        r = audittool.scan_text(sample, "the noodle")
        self.assertEqual([(v["owner"], v["statement"])
                          for v in r["direct_statements"]], [
            ("get a sockaddr given a host string",
             "Get some addrinfo routines."),
            ("send a message to someone", "Send the email."),
        ])

    def test_source_hash_guard_precedes_lexical_scan(self):
        with self.assertRaisesRegex(ValueError, "Source hash check failed"):
            audittool.audit(lambda group, name: b"wrong bytes")

    def test_mocked_source_inventory_never_claims_execution(self):
        originals = {name: b"To count something:\n"
                     for name in provenance.FILES}
        originals["the noodle"] = (b"To count something:\n"
                                     b"Intel $9090.\n"
                                     b"Send the email.\n")
        expected = {name: (provenance.git_blob_sha1(blob), len(blob))
                    for name, blob in originals.items()}
        sha256 = {name: hashlib.sha256(blob).hexdigest()
                  for name, blob in originals.items()}
        with patch.object(provenance, "EXPECTED", {"release": expected}):
            with patch.object(provenance, "EXPECTED_SHA256",
                              {"release": sha256}):
                r = audittool.audit(
                    lambda group, name: originals[name], strict=False)
        self.assertEqual(r["verified_source_files"], 6)
        self.assertEqual(r["intel"]["directives"], 1)
        self.assertEqual(r["intel"]["literal_bytes"], 2)
        self.assertEqual(r["direct_statement_counts"], {"Send the email.": 1})
        self.assertFalse(r["lexical_checks_pass"])
        for flag in ("binary_downloaded", "compiler_executed",
                     "disassembly_performed", "runtime_reachability_proven",
                     "stage_zero_verified", "malware_clearance",
                     "native_qa_99_pass"):
            self.assertFalse(r[flag])

    def test_strict_audit_rejects_unexpected_intel_surface(self):
        originals = {name: b"To count something:\n"
                     for name in provenance.FILES}
        originals["the noodle"] = b"Intel $90.\n"
        expected = {name: (provenance.git_blob_sha1(blob), len(blob))
                    for name, blob in originals.items()}
        sha256 = {name: hashlib.sha256(blob).hexdigest()
                  for name, blob in originals.items()}
        with patch.object(provenance, "EXPECTED", {"release": expected}):
            with patch.object(provenance, "EXPECTED_SHA256",
                              {"release": sha256}):
                with self.assertRaisesRegex(ValueError, "Intel count"):
                    audittool.audit(lambda group, name: originals[name])

    def test_invalid_hex_in_non_noodle_source_is_not_accepted(self):
        originals = {name: b"To count something:\n"
                     for name in provenance.FILES}
        originals["the writer"] = b"Intel $ABC.\n"
        expected = {name: (provenance.git_blob_sha1(blob), len(blob))
                    for name, blob in originals.items()}
        sha256 = {name: hashlib.sha256(blob).hexdigest()
                  for name, blob in originals.items()}
        with patch.object(provenance, "EXPECTED", {"release": expected}):
            with patch.object(provenance, "EXPECTED_SHA256",
                              {"release": sha256}):
                r = audittool.audit(
                    lambda group, name: originals[name], strict=False)
        self.assertEqual(r["intel"]["invalid_directives"][0]["file"],
                         "the writer")
        self.assertFalse(r["lexical_checks_pass"])


if __name__ == "__main__":
    unittest.main()
