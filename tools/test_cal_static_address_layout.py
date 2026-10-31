#!/usr/bin/env python3
"""Offline tests for pinned CAL rel32 and PE layout source-derived models."""
import hashlib
import unittest
from unittest.mock import patch

import cal_source_provenance as provenance
import cal_static_address_layout as model


def fixture():
    grouped = {}
    for filename, declaration, markers in model.PINS.values():
        key = filename, declaration
        grouped.setdefault(key, []).extend(markers)
    parts = {filename: [] for filename in provenance.FILES}
    for (filename, declaration), markers in grouped.items():
        parts[filename].extend([declaration, *markers, ""])
    return {filename: ("\n".join(lines) + "\n").encode("latin-1")
            for filename, lines in parts.items()}


def source_pins(blobs):
    hashes = {name: hashlib.sha256(raw).hexdigest()
              for name, raw in blobs.items()}
    expected = {name: (provenance.git_blob_sha1(raw), len(raw))
                for name, raw in blobs.items()}
    return (patch.object(provenance, "EXPECTED", {"release": expected}),
            patch.object(provenance, "EXPECTED_SHA256", {"release": hashes}))


class Rel32AndLayoutTests(unittest.TestCase):
    def test_forward_rel32_e8_is_little_endian(self):
        result = model.rel32_model(0x402000, 0x401000, 0, 1)
        self.assertEqual(result["displacement_signed"], 0xFFB)
        self.assertEqual(result["immediate_le_hex"], "FB0F0000")
        self.assertEqual(result["resolved_target"], 0x402000)

    def test_backwards_rel32_jcc_includes_two_opcode_bytes(self):
        result = model.rel32_model(0x401000, 0x401100, 0, 2)
        self.assertEqual(result["displacement_signed"], -262)
        self.assertEqual(result["immediate_le_hex"], "FAFEFFFF")
        self.assertEqual(result["resolved_target"], 0x401000)

    def test_existing_fragment_code_is_subtracted_from_target(self):
        short = model.rel32_model(0x404000, 0x401000, 0, 1)
        long = model.rel32_model(0x404000, 0x401000, 12, 1)
        self.assertEqual(short["displacement_signed"] -
                         long["displacement_signed"], 12)

    def test_relative_displacement_wraps_at_32bit_eip_boundary(self):
        result = model.rel32_model(4, 0xFFFFFFFC, 0, 1)
        self.assertEqual(result["next_eip"], 1)
        self.assertEqual(result["immediate_le_hex"], "03000000")
        self.assertEqual(result["resolved_target"], 4)

    def test_overflow_input_and_noninstruction_prefix_are_rejected(self):
        for args in ((0x100000000, 1, 0, 1), (0, -1, 0, 1),
                     (0, 0, -1, 1), (0, 0, 0, 3),
                     (0, 0, 0, True)):
            with self.subTest(args=args):
                with self.assertRaises(ValueError):
                    model.rel32_model(*args)

    def test_pe_sections_are_consecutively_4096_aligned(self):
        layout = model.modeled_layout(1000, 4097, 8193)
        self.assertEqual(layout["section_rva"],
                         {"import": 0x1000, "data": 0x2000, "code": 0x4000})
        self.assertEqual(layout["section_rounded_size"],
                         {"import": 4096, "data": 8192, "code": 12288})
        self.assertEqual(layout["modeled_size_of_image"], 0x7000)
        self.assertEqual(layout["modeled_section_raw_offsets"],
                         layout["section_rva"])

    def test_zero_and_exact_page_lengths_are_not_overrounded(self):
        self.assertEqual(model.ceil_page(0), 0)
        self.assertEqual(model.ceil_page(4096), 4096)
        self.assertEqual(model.ceil_page(4097), 8192)

    def test_code_fragment_inside_section_has_matching_file_offset(self):
        layout = model.modeled_layout(1000, 1000, 500)
        start = layout["section_rva"]["code"]
        fragment = model.check_code_fragment(layout, start + 100, 400)
        self.assertEqual(fragment["modeled_raw_offset"], start + 100)
        self.assertEqual(fragment["modeled_virtual_address"],
                         0x400000 + start + 100)

    def test_code_fragment_cannot_cross_unpadded_code_length(self):
        layout = model.modeled_layout(1000, 1000, 500)
        with self.assertRaisesRegex(ValueError, "beyond modeled code section"):
            model.check_code_fragment(layout, layout["section_rva"]["code"] + 499, 2)

    def test_fragment_before_code_section_is_rejected(self):
        layout = model.modeled_layout(1000, 1000, 500)
        with self.assertRaisesRegex(ValueError, "beyond modeled code section"):
            model.check_code_fragment(layout, layout["section_rva"]["data"], 1)

    def test_modeled_image_overflows_32bit_address_space(self):
        with self.assertRaisesRegex(ValueError, "32-bit image address space"):
            model.modeled_layout(0xFFFFFFFF, 4096, 8192)

    def test_pinned_source_fixture_has_eleven_independent_groups(self):
        result = model.inspect_compiler_sources(fixture())
        self.assertEqual(result["source_pin_groups"], 11)
        self.assertTrue(result["model_boundary_checks_pass"])
        self.assertIn("number_to_little_endian_bytes", result["source_pins"])
        self.assertEqual(len(result["source_pins"]["relative_branch_displacement"]
                             ["source_lines"]), 6)

    def test_all_important_negative_runtime_claims_remain_false(self):
        result = model.inspect_compiler_sources(fixture())
        for flag in ("actual_compiler_arithmetic_verified",
                     "actual_pe_section_bounds_verified", "compiled_binary_inspected",
                     "compiler_executed", "stage_zero_verified",
                     "native_qa_99_pass", "malware_clearance"):
            self.assertIs(result[flag], False, flag)

    def test_mutation_of_rel32_subtraction_detected(self):
        blobs = fixture()
        blobs["the compiler"] = blobs["the compiler"].replace(
            b"Subtract 4 from the number.", b"Subtract 8 from the number.")
        with self.assertRaisesRegex(ValueError, "Subtract 4"):
            model.inspect_compiler_sources(blobs)

    def test_reordered_section_addressing_detected(self):
        blobs = fixture()
        blobs["the compiler"] = blobs["the compiler"].replace(
            b"Address the literals given the address.",
            b"Address the other borough given the address.")
        with self.assertRaisesRegex(ValueError, "Address the literals"):
            model.inspect_compiler_sources(blobs)

    def test_source_statement_cannot_be_hidden_in_comment(self):
        blobs = fixture()
        blobs["the compiler"] = blobs["the compiler"].replace(
            b"Put the image base plus the address into the fragment's address.",
            b"\\ Put the image base plus the address into the fragment's address.")
        with self.assertRaisesRegex(ValueError, "image base"):
            model.inspect_compiler_sources(blobs)

    def test_pin_guard_precedes_source_inspection(self):
        with self.assertRaisesRegex(ValueError, "Pinned source hash mismatch"):
            model.audit(lambda group, filename: b"modified")

    def test_all_six_hash_approved_fixture_sources_validate_without_execution(self):
        blobs = fixture()
        a, b = source_pins(blobs)
        with a, b:
            result = model.audit(lambda group, filename: blobs[filename])
        self.assertEqual(result["verified_text_modules"], 6)
        self.assertEqual(result["source_pin_groups"], 11)
        self.assertFalse(result["compiler_executed"])
        self.assertFalse(result["actual_pe_section_bounds_verified"])


if __name__ == "__main__":
    unittest.main()
