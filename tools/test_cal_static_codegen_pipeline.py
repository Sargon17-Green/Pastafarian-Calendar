#!/usr/bin/env python3
"""Offline regression tests for pinned Intel-to-PE code emission chain."""
import hashlib
import unittest
from unittest.mock import patch

import cal_source_provenance as provenance
import cal_static_codegen_pipeline as codegen


def source_fixture():
    grouped = {}
    for declaration, markers in codegen.STAGE_PINS.values():
        grouped.setdefault(declaration, []).extend(markers)
    raw = "\n".join(
        part for routine, markers in grouped.items()
        for part in (routine, *markers, "")
    ) + "\n"
    data = {name: b"To noop:\n" for name in provenance.FILES}
    data["the compiler"] = raw.encode("latin-1")
    return data


def fake_pins(data):
    e = {name: (provenance.git_blob_sha1(raw), len(raw))
         for name, raw in data.items()}
    hashes = {name: hashlib.sha256(raw).hexdigest()
              for name, raw in data.items()}
    return (patch.object(provenance, "EXPECTED", {"release": e}),
            patch.object(provenance, "EXPECTED_SHA256", {"release": hashes}))


class StaticCodegenPipelineTests(unittest.TestCase):
    def test_expected_18_stages_are_explicitly_pinned(self):
        r = codegen.inspect_compiler(source_fixture()["the compiler"])
        self.assertEqual(len(r["pinned_codegen_stages"]), 18)
        self.assertEqual(set(r["pinned_codegen_stages"]), set(codegen.STAGE_PINS))
        self.assertTrue(r["literal_intel_to_pe_linkage_indicated_by_source"])

    def test_distinguishes_internal_external_and_indirect_calls(self):
        r = codegen.inspect_compiler(source_fixture()["the compiler"])
        emitted = r["generated_call_opcode_prefixes"]
        self.assertEqual(emitted["emit_external_call_ff15"]["hex_opcode_prefix"], "FF15")
        self.assertEqual(emitted["emit_indirect_call_ff12"]["hex_opcode_prefix"], "FF12")
        self.assertEqual(emitted["emit_internal_call_e8"]["hex_opcode_prefix"], "E8")
        self.assertEqual(emitted["emit_external_call_ff15"]["x86_opcode_family"],
                         "indirect_call_opcode")

    def test_explicit_negative_security_claims(self):
        r = codegen.inspect_compiler(source_fixture()["the compiler"])
        for flag in codegen.SAFE_FLAGS:
            self.assertIs(r[flag], False, flag)

    def test_wrong_pinned_source_fails_before_scan(self):
        with self.assertRaisesRegex(ValueError, "Pinned compiler source hash mismatch"):
            codegen.audit(lambda group, name: b"untrusted")

    def test_synthetic_six_source_audit_without_binary(self):
        data = source_fixture()
        a, b = fake_pins(data)
        with a, b:
            r = codegen.audit(lambda group, name: data[name])
        self.assertEqual(r["verified_text_modules"], 6)
        self.assertTrue(r["source_evidence_verified"])
        self.assertFalse(r["output_pe_created"])

    def test_removed_intel_literal_parsing_fails_closed(self):
        data = source_fixture()["the compiler"].replace(
            b"Convert the nibble substring to the fragment's code.",
            b"Ignore the nibble substring.")
        with self.assertRaisesRegex(ValueError, "nibble substring"):
            codegen.inspect_compiler(data)

    def test_deleted_intel_fragment_addressing_fails_closed(self):
        data = source_fixture()["the compiler"].replace(
            b"If the fragment's tag is the intel tag, add the fragment's code's length to the address; exit.",
            b"Do not advance the address.")
        with self.assertRaisesRegex(ValueError, "intel tag"):
            codegen.inspect_compiler(data)

    def test_wrong_external_call_opcode_requires_review(self):
        data = source_fixture()["the compiler"].replace(
            b"Attach $FF15 and the fragment's entry's address",
            b"Attach $FF25 and the fragment's entry's address")
        with self.assertRaisesRegex(ValueError, "FF15"):
            codegen.inspect_compiler(data)

    def test_indirect_call_opcode_needs_pointer_loading(self):
        data = source_fixture()["the compiler"].replace(
            b"Attach address loading code to the fragment's code given the fragment's variable.",
            b"Skip address loading for the fragment.")
        with self.assertRaisesRegex(ValueError, "address loading code"):
            codegen.inspect_compiler(data)

    def test_marker_moved_to_wrong_routine_is_not_accepted(self):
        data = source_fixture()["the compiler"].replace(
            b"Attach $FF12 to the fragment's code.",
            b"To unrelated routine:\nAttach $FF12 to the fragment's code.")
        with self.assertRaisesRegex(ValueError, "FF12"):
            codegen.inspect_compiler(data)

    def test_link_requires_writing_routines_into_image(self):
        data = source_fixture()["the compiler"].replace(
            b"Blurt the routines into the compiler's exe.",
            b"Do not blurt code into image.")
        with self.assertRaisesRegex(ValueError, "Blurt the routines"):
            codegen.inspect_compiler(data)

    def test_startup_exitprocess_is_represented_in_generated_body(self):
        r = codegen.inspect_compiler(source_fixture()["the compiler"])
        lines = r["pinned_codegen_stages"]["synthetic_program_entry"]["source_lines"]
        self.assertEqual(len(lines), 5)
        self.assertEqual(lines, sorted(lines))

    def test_duplicate_compiler_routine_header_is_rejected(self):
        data = source_fixture()["the compiler"] + (
            b"\nTo transmogrify a fragment (call external):\n")
        with self.assertRaisesRegex(ValueError, "Expected one routine declaration"):
            codegen.inspect_compiler(data)

    def test_comment_does_not_count_as_indirect_call_generator(self):
        data = source_fixture()["the compiler"].replace(
            b"Attach $FF12 to the fragment's code.",
            b"\\ Attach $FF12 to the fragment's code.")
        with self.assertRaisesRegex(ValueError, "FF12"):
            codegen.inspect_compiler(data)

    def test_ff_group_call_and_jump_are_distinct(self):
        self.assertEqual(codegen.classify_call_prefix("FF15"), "indirect_call_opcode")
        self.assertEqual(codegen.classify_call_prefix("FF12"), "indirect_call_opcode")
        self.assertEqual(codegen.classify_call_prefix("FF25"), "indirect_jump_opcode")
        self.assertEqual(codegen.classify_call_prefix("FF05"), "other_ff_group_opcode")

    def test_invalid_hex_input_rejected(self):
        for x in ("F", "ZZ", ""):
            with self.subTest(value=x):
                with self.assertRaises(ValueError):
                    codegen.classify_call_prefix(x)


if __name__ == "__main__":
    unittest.main()
