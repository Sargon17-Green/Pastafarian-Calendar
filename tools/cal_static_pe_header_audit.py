#!/usr/bin/env python3
"""Pinned, source-only inspection of CAL's PE32 output-header configuration.

All source files are validated by the existing SHA-256, Git-blob and length
guards before reading source text. No PE/EXE object is generated, loaded,
downloaded, or executed. This does not prove output matches source.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys

import cal_source_provenance as provenance

# These are source expectations, NOT security recommendations.
PE_PINS = {
    "signature": 0x4550,
    "machinetype": 0x014C,
    "numberofsections": 3,
    "sizeofoptionalheaderinbytes": 224,
    "magicnumber": 0x010B,
    "subsystem": 2,
    "code section's characteristics": 0xE0000020,
    "data section's characteristics": 0xC0000040,
    "idata section's characteristics": 0xC0000040,
    "dllcharacteristics": 0,
    "memoryalignment": 4096,
    "filealignment": 4096,
}
DOS_PINS = {
    "signature": 0x5A4D,
    "addressofpeheaderinfile": 256,
}
LINK_PINS = (
    "To compile a directory (write the exe):",
    "Write the compiler's exe to the compiler's exe path.",
    "To link:",
    "Initialize a dos header.",
    "Initialize a pe header.",
    "Blurt the dos header into the compiler's exe.",
    "Blurt the pe header into the compiler's exe.",
    "Blurt the imports into the compiler's exe.",
    "Blurt the routines into the compiler's exe.",
)
PE_ASSIGNMENT = re.compile(
    r"^Put\s+(-?\d+)(?:\s+\[\$([0-9a-fA-F]+)\])?"
    r"\s+into the pe header's\s+(.+)\.$",
    re.I,
)
DOS_ASSIGNMENT = re.compile(
    r"^Put\s+(-?\d+)(?:\s+\[\$([0-9a-fA-F]+)\])?"
    r"\s+into the dos header's\s+(.+)\.$",
    re.I,
)

EXECUTE = 0x20000000
READ = 0x40000000
WRITE = 0x80000000
DYNAMIC_BASE = 0x0040
NX_COMPAT = 0x0100
GUARD_CF = 0x4000


def inspect_source(data: bytes) -> dict:
    """Parse literal initializer assignments, with 32-bit bitfield handling."""
    text = data.decode("latin-1")
    pe, dos = {}, {}
    for index, original in enumerate(text.splitlines(), 1):
        row = original.split("\\", 1)[0].strip()
        if not row or row.startswith("\\"):
            continue
        for pattern, target in ((PE_ASSIGNMENT, pe), (DOS_ASSIGNMENT, dos)):
            match = pattern.fullmatch(row)
            if not match:
                continue
            decimal, hex_value, field = match.groups()
            field = field.strip().lower()
            if field in target:
                raise ValueError("Duplicate header initializer field: " + field)
            # IMAGE_SECTION_HEADER.Characteristics is 32-bit; a negative
            # source decimal can encode the same unsigned 32-bit bits.
            signed = int(decimal)
            if signed < -(1 << 31) or signed > (1 << 32) - 1:
                raise ValueError("Initializer out of 32-bit range: " + field)
            bits = signed & 0xFFFFFFFF
            if hex_value is not None and bits != int(hex_value, 16):
                raise ValueError("Decimal/hex literal mismatch: " + field)
            target[field] = {"line": index, "unsigned_value": bits,
                             "decimal_literal": signed}
    for label, seen, pins in (("PE", pe, PE_PINS), ("DOS", dos, DOS_PINS)):
        for field, expected in pins.items():
            if field not in seen:
                raise ValueError("Missing " + label + " field: " + field)
            actual = seen[field]["unsigned_value"]
            if actual != expected:
                raise ValueError(
                    label + " source header drift: " + field +
                    " (expected 0x%X, found 0x%X)" % (expected, actual))
    # Presence of each link-stage statement is required, including the
    # output writer. The linker markers span different routines.
    proof = {}
    for phrase in LINK_PINS:
        matches = [i for i, line in enumerate(text.splitlines(), 1)
                   if phrase in line and not line.lstrip().startswith("\\")]
        if len(matches) != 1:
            raise ValueError("Expected exactly one PE linker source marker: " + phrase)
        proof[phrase] = matches[0]
    code = pe["code section's characteristics"]["unsigned_value"]
    data_flags = pe["data section's characteristics"]["unsigned_value"]
    imports = pe["idata section's characteristics"]["unsigned_value"]
    dll = pe["dllcharacteristics"]["unsigned_value"]
    return {
        "pe": pe, "dos": dos, "linker_source_lines": proof,
        "static_header_interpretation": {
            "pe32_i386": (pe["magicnumber"]["unsigned_value"] == 0x10B and
                          pe["machinetype"]["unsigned_value"] == 0x14C),
            "code_rwx": (code & (READ | WRITE | EXECUTE)) == (READ | WRITE | EXECUTE),
            "data_read_write": (data_flags & (READ | WRITE)) == (READ | WRITE),
            "imports_read_write": (imports & (READ | WRITE)) == (READ | WRITE),
            "dynamic_base_declared": bool(dll & DYNAMIC_BASE),
            "nx_compat_declared": bool(dll & NX_COMPAT),
            "control_flow_guard_declared": bool(dll & GUARD_CF),
            "dll_characteristics_value": dll,
        },
    }


def audit(reader) -> dict:
    source = {}
    for filename in provenance.FILES:
        blob = reader("release", filename)
        check = provenance.inspect(blob, "release", filename)
        if not check["ok"]:
            raise ValueError("Pinned text source hash mismatch: " + filename)
        source[filename] = blob
    report = inspect_source(source["the compiler"])
    return {
        "kind": "PINNED_SOURCE_ONLY_PE32_HEADER_METADATA_NOT_BINARY_AUDIT",
        "pinned_commit": provenance.COMMIT,
        "verified_text_modules": len(source),
        **report,
        "source_text_gate_pass": True,
        "produced_binary_inspected": False,
        "pe_header_in_output_verified": False,
        "compiler_executed": False,
        "stage_zero_verified": False,
        "malware_clearance": False,
        "native_qa_99_pass": False,
    }


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    input_mode = parser.add_mutually_exclusive_group(required=True)
    input_mode.add_argument("--fetch", action="store_true",
                            help="Fetch six exact pinned texts, never EXE or ZIP")
    input_mode.add_argument("--directory", type=Path,
                            help="Local source root containing release/*")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args(argv)
    reader = (provenance.download_source if args.fetch else
              lambda group, name: provenance.read_directory_source(
                  args.directory, group, name))
    try:
        report = audit(reader)
    except (OSError, ValueError, TypeError) as exc:
        failure = {"kind": "PE_SOURCE_METADATA_AUDIT_FAILED",
                   "source_text_gate_pass": False,
                   "produced_binary_inspected": False,
                   "compiler_executed": False,
                   "malware_clearance": False,
                   "native_qa_99_pass": False,
                   "error": str(exc)}
        if args.output:
            args.output.write_text(json.dumps(failure, indent=2) + "\n",
                                   encoding="utf-8")
        print(json.dumps(failure), file=sys.stderr)
        return 2
    if args.output:
        args.output.write_text(json.dumps(report, indent=2) + "\n",
                               encoding="utf-8")
    print(json.dumps({
        "source_text_gate_pass": True,
        "verified_text_modules": report["verified_text_modules"],
        "static_header_interpretation": report["static_header_interpretation"],
        "produced_binary_inspected": False,
        "compiler_executed": False,
        "native_qa_99_pass": False,
        "malware_clearance": False,
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
