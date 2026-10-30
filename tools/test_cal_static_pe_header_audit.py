#!/usr/bin/env python3
"""Offline tests for CAL pinned source-only PE32 output-header metadata."""
import hashlib
import unittest
from unittest.mock import patch

import cal_source_provenance as provenance
import cal_static_pe_header_audit as audit


def compiler_fixture():
    lines = ["To initialize a pe header:"]
    for field, number in audit.PE_PINS.items():
        signed = number if number < 0x80000000 else number - 0x100000000
        lines.append("Put %d [$%08X] into the pe header's %s." %
                     (signed, number, field))
    lines.append("To initialize a dos header:")
    for field, number in audit.DOS_PINS.items():
        lines.append("Put %d [$%08X] into the dos header's %s." %
                     (number, number, field))
    lines.extend(audit.LINK_PINS)
    return ("\n".join(lines) + "\n").encode("latin-1")


def all_sources():
    contents = {name: b"To count:\n" for name in provenance.FILES}
    contents["the compiler"] = compiler_fixture()
    return contents


def pins(content):
    expected = {name: (provenance.git_blob_sha1(blob), len(blob))
                for name, blob in content.items()}
    hashes = {name: hashlib.sha256(blob).hexdigest()
              for name, blob in content.items()}
    return (patch.object(provenance, "EXPECTED", {"release": expected}),
            patch.object(provenance, "EXPECTED_SHA256", {"release": hashes}))


class StaticPEHeaderAuditTests(unittest.TestCase):
    def test_pe32_architecture_and_subsystem_are_decoded(self):
        report = audit.inspect_source(compiler_fixture())
        self.assertTrue(report["static_header_interpretation"]["pe32_i386"])
        self.assertEqual(report["pe"]["subsystem"]["unsigned_value"], 2)
        self.assertEqual(report["pe"]["numberofsections"]["unsigned_value"], 3)

    def test_code_section_is_rwx_and_data_sections_rw(self):
        flags = audit.inspect_source(compiler_fixture())["static_header_interpretation"]
        self.assertTrue(flags["code_rwx"])
        self.assertTrue(flags["data_read_write"])
        self.assertTrue(flags["imports_read_write"])

    def test_hardening_flags_are_absent_in_pinned_source(self):
        flags = audit.inspect_source(compiler_fixture())["static_header_interpretation"]
        self.assertFalse(flags["dynamic_base_declared"])
        self.assertFalse(flags["nx_compat_declared"])
        self.assertFalse(flags["control_flow_guard_declared"])
        self.assertEqual(flags["dll_characteristics_value"], 0)

    def test_negative_decimal_and_unsigned_hex_refer_to_same_bits(self):
        report = audit.inspect_source(compiler_fixture())
        target = report["pe"]["code section's characteristics"]
        self.assertEqual(target["decimal_literal"], -536870880)
        self.assertEqual(target["unsigned_value"], 0xE0000020)

    def test_pinned_source_guards_are_applied_first(self):
        with self.assertRaisesRegex(ValueError, "Pinned text source hash mismatch"):
            audit.audit(lambda group, name: b"changed")

    def test_six_source_fixture_avoids_binary_or_safety_claims(self):
        source = all_sources()
        a, b = pins(source)
        with a, b:
            report = audit.audit(lambda group, name: source[name])
        self.assertTrue(report["source_text_gate_pass"])
        self.assertEqual(report["verified_text_modules"], 6)
        for flag in ("produced_binary_inspected", "pe_header_in_output_verified",
                     "compiler_executed", "stage_zero_verified",
                     "malware_clearance", "native_qa_99_pass"):
            self.assertFalse(report[flag])

    def test_changed_executable_write_permission_requires_review(self):
        source = compiler_fixture().replace(
            b"-536870880 [$E0000020]", b"1610612768 [$60000020]")
        with self.assertRaisesRegex(ValueError, "PE source header drift"):
            audit.inspect_source(source)

    def test_changed_mitigation_flag_requires_review_not_silent_pass(self):
        source = compiler_fixture().replace(
            b"Put 0 [$00000000] into the pe header's dllcharacteristics.",
            b"Put 320 [$00000140] into the pe header's dllcharacteristics.")
        with self.assertRaisesRegex(ValueError, "dllcharacteristics"):
            audit.inspect_source(source)

    def test_header_signed_decimal_hex_mismatch_is_rejected(self):
        source = compiler_fixture().replace(
            b"-536870880 [$E0000020]", b"-536870880 [$E0000040]")
        with self.assertRaisesRegex(ValueError, "Decimal/hex literal mismatch"):
            audit.inspect_source(source)

    def test_duplicate_header_assignment_is_rejected(self):
        source = compiler_fixture() + (
            b"Put 267 [$0000010B] into the pe header's magicnumber.\n")
        with self.assertRaisesRegex(ValueError, "Duplicate header initializer"):
            audit.inspect_source(source)

    def test_missing_output_linker_step_is_rejected(self):
        source = compiler_fixture().replace(
            b"Blurt the routines into the compiler's exe.",
            b"Do not blurt the routines.")
        with self.assertRaisesRegex(ValueError, "linker source marker"):
            audit.inspect_source(source)

    def test_missing_pe32_magic_is_rejected(self):
        source = compiler_fixture().replace(
            b"Put 267 [$0000010B] into the pe header's magicnumber.",
            b"Put 523 [$0000020B] into the pe header's magicnumber.")
        with self.assertRaisesRegex(ValueError, "magicnumber"):
            audit.inspect_source(source)

    def test_values_outside_32bit_range_are_rejected(self):
        source = compiler_fixture().replace(
            b"Put 3 [$00000003] into the pe header's numberofsections.",
            b"Put 4294967296 [$100000000] into the pe header's numberofsections.")
        with self.assertRaisesRegex(ValueError, "out of 32-bit range"):
            audit.inspect_source(source)


if __name__ == "__main__":
    unittest.main()
