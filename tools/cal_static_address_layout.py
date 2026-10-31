#!/usr/bin/env python3
"""Pinned CAL compiler address/relative-displacement and PE layout source audit.

Mathematical models below independently express expected 32-bit x86 / PE
properties. They DO NOT execute the compiler, inspect its output, or prove
that all CAL values remain within the modeled ranges at runtime.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys

import cal_source_provenance as provenance

PAGE = 4096
IMAGE_BASE = 0x00400000
MAX32 = 0xFFFFFFFF

# Pin source statements to owning routine, rather than matching comments or
# similarly named definitions elsewhere. All markers within each routine
# must appear in their actual source order.
PINS = {
    "relative_branch_displacement": ("the compiler",
        "To attach an hex string and an address to a fragment:", (
        "Put the address into a number.",
        "Subtract the fragment's address from the number.",
        "Subtract the fragment's code's length from the number.",
        "Subtract the hex string's length from the number.",
        "Subtract 4 from the number.",
        "Attach the hex string and the number to the fragment's code.",
    )),
    "fragment_address_sizes": ("the compiler",
        "To address a fragment given an address:", (
        "Put the image base plus the address into the fragment's address.",
        "If the fragment's tag is the call internal tag, add 5 to the address; exit.",
        "If the fragment's tag is the intel tag, add the fragment's code's length to the address; exit.",
        "If the fragment's tag is the call external tag, add 6 to the address; exit.",
        "If the fragment's tag is the call indirect tag, add 8 to the address; exit.",
    )),
    "section_address_order": ("the compiler",
        "To compile a directory (address):", (
        "Put 4096 into an address.",
        "Put the address into the import borough's base.",
        "Address the imports given the address.",
        "Put the address minus the import borough's base into the import borough's length.",
        "Round the address up to the nearest multiple of 4096.",
        "Put the address into the data borough's base.",
        "Address the globals given the address.",
        "Address the literals given the address.",
        "Put the address minus the data borough's base into the data borough's length.",
        "Round the address up to the nearest multiple of 4096.",
        "Put the address into the code borough's base.",
        "Address the routines given the address.",
        "Put the address minus the code borough's base into the code borough's length.",
    )),
    "rounded_section_sizes": ("the compiler",
        "To round up borough sizes:", (
        "Put the import borough's length into the import borough's size.",
        "Round the import borough's size up to the nearest multiple of 4096.",
        "Put the data borough's length into the data borough's size.",
        "Round the data borough's size up to the nearest multiple of 4096.",
        "Put the code borough's length into the code borough's size.",
        "Round the code borough's size up to the nearest multiple of 4096.",
    )),
    "total_output_length": ("the compiler",
        "To put the compiler's exe size into a size:", (
        "Put 4096 [section base] into the size.",
        "Add the import borough's size to the size.",
        "Add the data borough's size to the size.",
        "Add the code borough's size to the size.",
    )),
    "fragment_write_rva": ("the compiler",
        "To blurt a fragment into a buffer:", (
        "If the fragment's code is blank, exit.",
        "Put the fragment's address minus the image base into an address.",
        "Blurt the fragment's code into the buffer at the address.",
    )),
    "pe_section_offsets": ("the compiler",
        "To initialize a pe header (code section):", (
        "Put the code borough's base into the pe header's code section's addressinmemory.",
        "Put the code borough's length into the pe header's code section's sizeinfile.",
        "Put the code borough's base into the pe header's code section's addressinfile.",
    )),
    "pe_file_memory_alignment": ("the compiler",
        "To initialize a pe header (optional header):", (
        "Put the image base into the pe header's imagebase.",
        "Put 4096 [$00001000] into the pe header's memoryalignment.",
        "Put 4096 [$00001000] into the pe header's filealignment.",
        "Put the compiler's exe size into the pe header's sizeofimageinmemory.",
        "Put 4096 [section base] into the pe header's sizeofallheadersinfile.",
    )),
    "pe_entry_rva": ("the compiler",
        "To initialize a pe header (optional header):", (
        'Find a routine given "~initialize before run and run and finalize after run" and the routine index.',
        "Put the routine's address minus the image base into the pe header's addressofentrypointinmemory.",
    )),
    "call_and_jump_templates": ("the compiler",
        "To transmogrify a fragment (call internal):", (
        "Get an address given the fragment's routine.",
        "Attach $E8 and the address to the fragment.",
    )),
    "number_to_little_endian_bytes": ("the noodle",
        "To convert a number to a hex string:", (
        "Reassign the hex string's first given the number's magnitude.",
        "Copy bytes from the number's whereabouts to the hex string's first for the number's magnitude.",
        "Put the hex string's first plus the number's magnitude minus 1 into the hex string's last.",
    )),
}

HEADER = re.compile(r"^To\s+", re.IGNORECASE)


def find_owned_markers(raw: bytes, heading: str, expected: tuple[str, ...]) -> list[int]:
    lines = raw.decode("latin-1").splitlines()
    candidates = [i for i, row in enumerate(lines)
                  if row.strip().startswith(heading) and not row.lstrip().startswith("\\")]
    if len(candidates) != 1:
        raise ValueError("Unique source routine header not found: " + heading)
    start = candidates[0]
    finish = next((i for i in range(start + 1, len(lines))
                   if HEADER.match(lines[i])), len(lines))
    body = [(i + 1, lines[i].strip().split("\\", 1)[0].strip())
            for i in range(start, finish) if not lines[i].lstrip().startswith("\\")]
    positions = []
    cursor = 0
    for wanted in expected:
        found = next((i for i in range(cursor, len(body))
                      if wanted in body[i][1]), None)
        if found is None:
            raise ValueError("Absent or reordered source marker in " + heading + ": " + wanted)
        positions.append(body[found][0])
        cursor = found + 1
    return positions


def require_word32(value: int, label: str) -> int:
    if type(value) is not int or not 0 <= value <= MAX32:
        raise ValueError(label + " must be unsigned 32-bit integer")
    return value


def rel32_model(target_va: int, fragment_va: int, existing_bytes: int,
                opcode_byte_count: int) -> dict:
    """x86 rel32 = (target - next EIP) modulo 2^32, serialized little-endian."""
    require_word32(target_va, "target_va")
    require_word32(fragment_va, "fragment_va")
    require_word32(existing_bytes, "existing_bytes")
    if type(opcode_byte_count) is not int or opcode_byte_count not in (1, 2):
        raise ValueError("opcode_byte_count must be 1 (E8/E9) or 2 (0F8x)")
    next_eip = (fragment_va + existing_bytes + opcode_byte_count + 4) & MAX32
    disp_unsigned = (target_va - next_eip) & MAX32
    disp_signed = disp_unsigned if disp_unsigned < 0x80000000 else disp_unsigned - 0x100000000
    return {"next_eip": next_eip, "displacement_signed": disp_signed,
            "displacement_unsigned": disp_unsigned,
            "immediate_le_hex": disp_unsigned.to_bytes(4, "little").hex().upper(),
            "resolved_target": (next_eip + disp_signed) & MAX32}


def ceil_page(length: int) -> int:
    require_word32(length, "section length")
    return ((length + PAGE - 1) // PAGE) * PAGE


def modeled_layout(import_length: int, data_length: int, code_length: int) -> dict:
    """Independent source-derived section layout (not binary output validation)."""
    lengths = {"import": import_length, "data": data_length, "code": code_length}
    size = {name: ceil_page(length) for name, length in lengths.items()}
    rvas = {"import": PAGE}
    rvas["data"] = rvas["import"] + size["import"]
    rvas["code"] = rvas["data"] + size["data"]
    end = rvas["code"] + size["code"]
    if end > MAX32 or IMAGE_BASE + end > MAX32:
        raise ValueError("Modeled PE layout exceeds 32-bit image address space")
    return {"image_base": IMAGE_BASE, "alignment": PAGE,
            "section_rva": rvas, "section_length": lengths,
            "section_rounded_size": size, "modeled_size_of_image": end,
            "modeled_section_raw_offsets": dict(rvas)}


def check_code_fragment(layout: dict, rva: int, length: int) -> dict:
    require_word32(rva, "fragment RVA")
    require_word32(length, "fragment byte length")
    start = layout["section_rva"]["code"]
    limit = start + layout["section_length"]["code"]
    if not (start <= rva <= limit and length <= limit - rva):
        raise ValueError("Fragment extends beyond modeled code section")
    return {"modeled_raw_offset": rva, "modeled_virtual_address": IMAGE_BASE + rva,
            "fragment_length": length}


def inspect_compiler_sources(blobs: dict[str, bytes]) -> dict:
    evidence = {}
    for name, (filename, declaration, markers) in PINS.items():
        evidence[name] = {"filename": filename, "source_lines":
                          find_owned_markers(blobs[filename], declaration, markers)}
    e8 = rel32_model(0x402000, 0x401000, 0, 1)
    jcc = rel32_model(0x401000, 0x401100, 0, 2)
    layout = modeled_layout(1000, 4097, 8193)
    check_code_fragment(layout, layout["section_rva"]["code"], 1)
    return {"source_pins": evidence, "source_pin_groups": len(evidence),
            "reference_rel32_examples": {"forward_e8": e8, "backward_0f8x": jcc},
            "reference_pe_layout": layout,
            "model_boundary_checks_pass": True,
            "actual_compiler_arithmetic_verified": False,
            "actual_pe_section_bounds_verified": False,
            "compiled_binary_inspected": False, "compiler_executed": False,
            "stage_zero_verified": False, "native_qa_99_pass": False,
            "malware_clearance": False}


def audit(reader) -> dict:
    blobs = {}
    for filename in provenance.FILES:
        raw = reader("release", filename)
        report = provenance.inspect(raw, "release", filename)
        if not report["ok"]:
            raise ValueError("Pinned source hash mismatch: " + filename)
        blobs[filename] = raw
    return {"kind": "SOURCE_ONLY_REL32_AND_PE_LAYOUT_MODEL_NOT_RUNTIME_VALIDATION",
            "verified_text_modules": len(blobs), "pinned_commit": provenance.COMMIT,
            **inspect_compiler_sources(blobs)}


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    options = parser.add_mutually_exclusive_group(required=True)
    options.add_argument("--fetch", action="store_true", help="Fetch pinned text only")
    options.add_argument("--directory", type=Path, help="Offline source root")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args(argv)
    reader = (provenance.download_source if args.fetch else
              lambda group, name: provenance.read_directory_source(args.directory, group, name))
    try:
        report = audit(reader)
    except (ValueError, OSError, TypeError, KeyError) as exc:
        failure = {"source_model_gate_pass": False, "compiler_executed": False,
                   "malware_clearance": False, "native_qa_99_pass": False,
                   "error": str(exc)}
        if args.output:
            args.output.write_text(json.dumps(failure, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(failure), file=sys.stderr)
        return 2
    if args.output:
        args.output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"source_model_gate_pass": True,
                      "source_pin_groups": report["source_pin_groups"],
                      "verified_text_modules": report["verified_text_modules"],
                      "reference_rel32_examples": report["reference_rel32_examples"],
                      "reference_pe_layout": report["reference_pe_layout"],
                      "compiler_executed": False,
                      "malware_clearance": False,
                      "native_qa_99_pass": False}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
