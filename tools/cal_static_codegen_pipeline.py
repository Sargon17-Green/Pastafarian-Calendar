#!/usr/bin/env python3
"""Source-only CAL Intel->fragment->PE code-emission provenance.

Reviews only pinned Plain English text. Not a compiler interpreter,
disassembler, executable test, complete static analysis, or malware clearance.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys

import cal_source_provenance as provenance

HEADER = re.compile(r"^To\s+.+[:;](?:\s*\\.*)?$", re.I)

# Each named routine owns its markers. The headings and statements are
# intentionally exact for the pinned upstream revision, not a generic parser.
STAGE_PINS = {
    "intel_literal_lexing": (
        "To compile the next statement given a rider (intel):",
        (
            "If the rider's token is not any hex literal, abort with",
            "Add a fragment given the intel tag.",
            "Put the rider's token into a nibble substring.",
            "Add 1 to the nibble substring's first.",
            "Convert the nibble substring to the fragment's code.",
        ),
    ),
    "intel_statement_dispatch": (
        "To compile the next statement given a rider (other):",
        ('If the rider\'s token is "intel", compile the next statement given the rider (intel); exit.',),
    ),
    "intel_fragment_addressing": (
        "To address a fragment given an address:",
        (
            "Put the image base plus the address into the fragment's address.",
            "If the fragment's tag is the intel tag, add the fragment's code's length to the address; exit.",
        ),
    ),
    "external_call_addressing": (
        "To address a fragment given an address:",
        ("If the fragment's tag is the call external tag, add 6 to the address; exit.",),
    ),
    "indirect_call_addressing": (
        "To address a fragment given an address:",
        ("If the fragment's tag is the call indirect tag, add 8 to the address; exit.",),
    ),
    "transmogrify_dispatch": (
        "To transmogrify a fragment:",
        (
            "If the fragment's tag is the call external tag, transmogrify the fragment (call external); exit.",
            "If the fragment's tag is the call indirect tag, transmogrify the fragment (call indirect); exit.",
        ),
    ),
    "emit_external_call_ff15": (
        "To transmogrify a fragment (call external):",
        ("Attach $FF15 and the fragment's entry's address to the fragment's code.",),
    ),
    "emit_indirect_call_ff12": (
        "To transmogrify a fragment (call indirect):",
        (
            "Attach address loading code to the fragment's code given the fragment's variable.",
            "Attach $FF12 to the fragment's code.",
        ),
    ),
    "emit_internal_call_e8": (
        "To transmogrify a fragment (call internal):",
        ("Attach $E8 and the address to the fragment.",),
    ),
    "transmogrify_routines": (
        "To transmogrify some routines:",
        (
            "Get a routine from the routines.",
            "Transmogrify the routine.",
        ),
    ),
    "compile_transmogrify_stage": (
        "To compile a directory (transmogrify):",
        ("Transmogrify the routines.",),
    ),
    "blurt_fragment_bytes": (
        "To blurt a fragment into a buffer:",
        (
            "If the fragment's code is blank, exit.",
            "Put the fragment's address minus the image base into an address.",
            "Blurt the fragment's code into the buffer at the address.",
        ),
    ),
    "blurt_routine_fragments": (
        "To blurt a routine into a buffer:",
        (
            "If the routine's compiled flag is not set, exit.",
            "Blurt the routine's fragments into the buffer.",
        ),
    ),
    "link_image": (
        "To link:",
        (
            "Initialize a dos header.",
            "Initialize a pe header.",
            "Fill the compiler's exe with the null byte given the compiler's exe size.",
            "Blurt the dos header into the compiler's exe.",
            "Blurt the pe header into the compiler's exe.",
            "Blurt the imports into the compiler's exe.",
            "Blurt the globals into the compiler's exe.",
            "Blurt the literals into the compiler's exe.",
            "Blurt the routines into the compiler's exe.",
        ),
    ),
    "compile_link_stage": (
        "To compile a directory (link):",
        ("Link.",),
    ),
    "write_exe": (
        "To compile a directory (write the exe):",
        (
            "Write the compiler's exe to the compiler's exe path.",
            "If the i/o error is not blank, abort with the i/o error.",
        ),
    ),
    "synthetic_program_entry": (
        "To add and compile the initialize before run and run and finalize after run routine:",
        (
            'Append "initialize before run. " to the routine\'s body string.',
            'Append "run. " to the routine\'s body string.',
            'Append "finalize after run. " to the routine\'s body string.',
            'Append "call ""kernel32.dll"" ""ExitProcess"" with 0. " to the routine\'s body string.',
            "Compile the body of the routine.",
        ),
    ),
    "pe_entry_point_binding": (
        "To initialize a pe header (optional header):",
        (
            'Find a routine given "~initialize before run and run and finalize after run" and the routine index.',
            "Put the routine's address minus the image base into the pe header's addressofentrypointinmemory.",
        ),
    ),
}
CALL_OPCODE_PINS = {
    "emit_external_call_ff15": ("FF15", 2),
    "emit_indirect_call_ff12": ("FF12", 2),
    "emit_internal_call_e8": ("E8", None),
}
SAFE_FLAGS = {
    "compiler_executed": False,
    "output_pe_created": False,
    "pe_binary_inspected": False,
    "all_opcode_streams_disassembled": False,
    "complete_control_flow_proven": False,
    "runtime_reachability_proven": False,
    "malware_clearance": False,
    "stage_zero_verified": False,
    "native_qa_99_pass": False,
}


def active_rows(raw: bytes) -> list[tuple[int, str]]:
    return [(i, row.strip()) for i, row in
            enumerate(raw.decode("latin-1").splitlines(), 1)
            if row.strip() and not row.lstrip().startswith("\\")]


def find_routine(rows: list[tuple[int, str]], declaration: str) -> list[tuple[int, str]]:
    matches = [index for index, (_, row) in enumerate(rows)
               if row == declaration]
    if len(matches) != 1:
        raise ValueError("Expected one routine declaration: " + declaration)
    start = matches[0]
    end = next((i for i in range(start + 1, len(rows))
                if HEADER.match(rows[i][1])), len(rows))
    return rows[start:end]


def locate_in_order(scope: list[tuple[int, str]], fragments: tuple[str, ...]) -> list[int]:
    found = []
    start = 0
    for part in fragments:
        matches = [i for i in range(start, len(scope)) if part in scope[i][1]]
        if not matches:
            raise ValueError("Missing or out-of-order codegen marker: " + part)
        found.append(scope[matches[0]][0])
        start = matches[0] + 1
    return found


def classify_call_prefix(prefix: str) -> str:
    """Decode just a known CALL opcode+ModR/M prefix, not machine code streams."""
    if len(prefix) % 2 or not re.fullmatch("[0-9a-fA-F]+", prefix):
        raise ValueError("Invalid code generation hex prefix")
    code = bytes.fromhex(prefix)
    if code and code[0] == 0xE8:
        return "near_relative_call_opcode"
    if len(code) >= 2 and code[0] == 0xFF:
        group = (code[1] >> 3) & 7
        if group in (2, 3):
            return "indirect_call_opcode"
        if group in (4, 5):
            return "indirect_jump_opcode"
        return "other_ff_group_opcode"
    return "other_opcode"


def inspect_compiler(raw: bytes) -> dict:
    lines = active_rows(raw)
    evidence = {}
    for title, (declaration, fragments) in STAGE_PINS.items():
        evidence[title] = {
            "routine": declaration,
            "source_lines": locate_in_order(find_routine(lines, declaration), fragments),
        }
    emissions = {}
    for stage, (opcode, expected_modrm_group) in CALL_OPCODE_PINS.items():
        family = classify_call_prefix(opcode)
        if family != ("near_relative_call_opcode" if expected_modrm_group is None
                      else "indirect_call_opcode"):
            raise ValueError("Unexpected generated CALL opcode group: " + stage)
        if expected_modrm_group is not None:
            if ((bytes.fromhex(opcode)[1] >> 3) & 7) != expected_modrm_group:
                raise ValueError("Unexpected generated FF ModR/M group: " + stage)
        emissions[stage] = {"hex_opcode_prefix": opcode,
                            "x86_opcode_family": family,
                            "source_line": evidence[stage]["source_lines"][-1]}
    return {
        "pinned_codegen_stages": evidence,
        "generated_call_opcode_prefixes": emissions,
        "literal_intel_to_pe_linkage_indicated_by_source": True,
        "source_evidence_verified": True,
        **SAFE_FLAGS,
    }


def audit(reader) -> dict:
    blobs = {}
    for filename in provenance.FILES:
        raw = reader("release", filename)
        report = provenance.inspect(raw, "release", filename)
        if not report["ok"]:
            raise ValueError("Pinned compiler source hash mismatch: " + filename)
        blobs[filename] = raw
    result = inspect_compiler(blobs["the compiler"])
    return {"kind": "STATIC_CAL_COMPILER_CODEGEN_CHAIN_NOT_EXECUTION",
            "pinned_upstream_commit": provenance.COMMIT,
            "verified_text_modules": len(blobs),
            **result}


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--fetch", action="store_true",
                       help="Fetch pinned text sources only")
    group.add_argument("--directory", type=Path,
                       help="Read root/release/* with provenance symlink guards")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args(argv)
    reader = (provenance.download_source if args.fetch else
              lambda kind, name: provenance.read_directory_source(args.directory, kind, name))
    try:
        report = audit(reader)
    except (OSError, ValueError, TypeError, KeyError) as exc:
        failed = {"source_evidence_verified": False, "compiler_executed": False,
                  "malware_clearance": False, "native_qa_99_pass": False,
                  "error": str(exc)}
        if args.output:
            args.output.write_text(json.dumps(failed, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(failed), file=sys.stderr)
        return 2
    if args.output:
        args.output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({
        "source_evidence_verified": report["source_evidence_verified"],
        "verified_text_modules": report["verified_text_modules"],
        "pinned_codegen_stages": len(report["pinned_codegen_stages"]),
        "generated_call_opcode_prefixes": report["generated_call_opcode_prefixes"],
        **SAFE_FLAGS,
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
