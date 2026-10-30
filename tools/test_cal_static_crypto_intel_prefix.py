#!/usr/bin/env python3
"""Offline regression tests for CAL crypto-source path and x86 prefix scan."""
import hashlib
import unittest
from unittest.mock import patch

import cal_source_provenance as provenance
import cal_static_crypto_intel_prefix as tool


def fake_source_set():
    files = {name: b"To noop:\n" for name in provenance.FILES}
    for operation in ("encrypt", "decrypt"):
        for kind, phrases in tool.CRYPTO_PATHS[operation].items():
            filename = "the " + kind
            files[filename] += ("\n".join(phrases) + "\n").encode("latin-1")
    files["the noodle"] += (
        "\n".join(tool.KDF_PINS) + "\n"
    ).encode("latin-1")
    for operation, phrases in tool.MENU_ROUTE_PINS.items():
        files["the desktop"] += ("\n".join(phrases) + "\n").encode("latin-1")
    for stage, phrases in tool.DYNAMIC_RESOLVER_PINS.items():
        files["the noodle"] += ("\n".join(phrases) + "\n").encode("latin-1")
    return files


def mock_pins(source):
    expected = {
        name: (provenance.git_blob_sha1(blob), len(blob))
        for name, blob in source.items()
    }
    sha256 = {name: hashlib.sha256(blob).hexdigest()
              for name, blob in source.items()}
    return (patch.object(provenance, "EXPECTED", {"release": expected}),
            patch.object(provenance, "EXPECTED_SHA256", {"release": sha256}))


class StaticCryptoIntelTests(unittest.TestCase):
    def test_x86_conditional_and_unconditional_branch_prefixes(self):
        self.assertEqual(tool.classify_instruction_prefix("0F8501000000"),
                         "near_conditional_branch_prefix")
        self.assertEqual(tool.classify_instruction_prefix("E9BAFFFFFF"),
                         "near_unconditional_jump_prefix")

    def test_ff_modrm_inc_is_not_a_call(self):
        self.assertEqual(tool.classify_instruction_prefix("FF8314000000"),
                         "ff_group_inc_prefix")
        self.assertEqual(tool.classify_instruction_prefix("FF8308000000"),
                         "ff_group_inc_prefix")

    def test_ff_modrm_indirect_call_and_jump_distinguished(self):
        self.assertEqual(tool.classify_instruction_prefix("FFD0"),
                         "ff_group_indirect_call_prefix")
        self.assertEqual(tool.classify_instruction_prefix("FFE0"),
                         "ff_group_indirect_jump_prefix")

    def test_call_and_os_entry_prefixes(self):
        self.assertEqual(tool.classify_instruction_prefix("E800000000"),
                         "direct_call_prefix")
        for literal in ("CD80", "0F05", "0F34", "CC"):
            with self.subTest(literal=literal):
                self.assertEqual(tool.classify_instruction_prefix(literal),
                                 "interrupt_or_syscall_prefix")

    def test_invalid_hex_fails_closed(self):
        for value in ("ZZ", "A", "", "FF"):
            with self.subTest(value=value):
                with self.assertRaises(ValueError):
                    tool.classify_instruction_prefix(value)

    def test_first_prefix_is_not_full_disassembly(self):
        self.assertEqual(tool.classify_instruction_prefix("8B00E800000000"),
                         "other_prefix")

    def test_source_markers_can_share_one_line(self):
        lines = [(1, 'Call "advapi32.dll" "CryptCreateHash" with [calg_md5].')]
        self.assertEqual(tool.sequential_evidence(lines, (
            'Call "advapi32.dll" "CryptCreateHash"', "[calg_md5]")), [1, 1])

    def test_missing_or_reversed_source_marker_rejected(self):
        with self.assertRaisesRegex(ValueError, "out of order"):
            tool.sequential_evidence([(1, "second"), (2, "first")],
                                     ("first", "second"))

    def test_cross_module_crypto_chain_fixture_and_negative_flags(self):
        originals = fake_source_set()
        a, b = mock_pins(originals)
        with a, b:
            result = tool.audit(lambda group, name: originals[name],
                                strict=False)
        self.assertEqual(result["verified_text_modules"], 6)
        self.assertEqual(set(result["crypto_path_evidence"]), {"encrypt", "decrypt"})
        self.assertEqual(len(result["crypto_kdf_evidence_lines"]),
                         len(tool.KDF_PINS))
        self.assertFalse(result["lexical_gate_pass"])
        for flag, value in tool.FLAG_FIELDS.items():
            self.assertEqual(result[flag], value)

    def test_menu_and_dynamic_dns_routes_are_reported_from_source(self):
        originals = fake_source_set()
        a, b = mock_pins(originals)
        with a, b:
            report = tool.audit(lambda group, name: originals[name],
                                strict=False)
        for operation in ("encrypt", "decrypt"):
            lines = report["menu_route_evidence"][operation]
            self.assertEqual(len(lines), 4)
            self.assertEqual(lines, sorted(lines))
        self.assertEqual(
            len(report["dynamic_resolver_evidence"]["function_pointer_registration"]), 6)
        self.assertEqual(
            len(report["dynamic_resolver_evidence"]["function_pointer_dispatch"]), 4)
        self.assertFalse(report["runtime_reachability_proven"])

    def test_missing_menu_command_dispatch_fails_closed(self):
        originals = fake_source_set()
        originals["the desktop"] = originals["the desktop"].replace(
            b'If the command\'s handler is "handle encrypt", handle encrypt; exit.',
            b'If the command\'s handler is "handle encrypt", do nothing; exit.')
        a, b = mock_pins(originals)
        with a, b:
            with self.assertRaisesRegex(ValueError, "handle encrypt; exit"):
                tool.audit(lambda group, name: originals[name], strict=False)

    def test_missing_indirect_getaddrinfo_dispatch_fails_closed(self):
        originals = fake_source_set()
        originals["the noodle"] = originals["the noodle"].replace(
            b"Call the addrinfo routines' getaddrinfo with",
            b"Do not call the addrinfo routines' getaddrinfo with")
        a, b = mock_pins(originals)
        with a, b:
            with self.assertRaisesRegex(ValueError, "Call the addrinfo routines"):
                tool.audit(lambda group, name: originals[name], strict=False)

    def test_mismatched_source_rejected_before_analysis(self):
        with self.assertRaisesRegex(ValueError, "Pinned release source hash"):
            tool.audit(lambda group, name: b"tampered")

    def test_missing_editor_crypt_call_rejected(self):
        originals = fake_source_set()
        originals["the editor"] = originals["the editor"].replace(
            b"Encrypt the buffer with the answer.",
            b"Do nothing to the buffer.")
        a, b = mock_pins(originals)
        with a, b:
            with self.assertRaisesRegex(ValueError, "Encrypt the buffer"):
                tool.audit(lambda group, name: originals[name], strict=False)

    def test_strict_mode_rejects_changed_intel_surface(self):
        originals = fake_source_set()
        a, b = mock_pins(originals)
        with a, b:
            with self.assertRaisesRegex(ValueError, "unexpected total Intel"):
                tool.audit(lambda group, name: originals[name])

    def test_intel_in_unexpected_module_fails_even_non_strict(self):
        originals = fake_source_set()
        originals["the editor"] += b"\nIntel $9090.\n"
        a, b = mock_pins(originals)
        with a, b:
            result = tool.audit(lambda group, name: originals[name],
                                strict=False)
        self.assertIn("Intel literal in unexpected module",
                      result["violations"])
        self.assertFalse(result["lexical_gate_pass"])


if __name__ == "__main__":
    unittest.main()
