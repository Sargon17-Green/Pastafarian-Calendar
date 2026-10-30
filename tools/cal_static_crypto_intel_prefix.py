#!/usr/bin/env python3
"""Pinned Plain English crypto-path and Intel opcode-prefix STATIC audit.

This validates source-text evidence and x86 instruction *prefixes* only.
Not a disassembler, call-graph proof, machine-code safety analysis or
authorization to run any CAL executable.
"""
from __future__ import annotations

from collections import Counter
import argparse
import json
from pathlib import Path
import sys

import cal_source_provenance as provenance
import cal_static_callsite_intel as lexical

# These are explicit observed statements in pinned source, not generalized
# Plain English syntax or inferred runtime entry points.
CRYPTO_PATHS = {
    "encrypt": {
        "desktop": (
            'To handle encrypt:',
            'If the current tab\'s mode is "editor", handle encrypt given the current tab\'s node\'s source; exit.',
        ),
        "editor": (
            'To handle encrypt given a source:',
            'Ask "Passphrase?".',
            "Extract a buffer from the source's text (selected bytes).",
            "Encrypt the buffer with the answer.",
            "Put the buffer on the windows clipboard.",
        ),
        "noodle": (
            "To encrypt a buffer given a passphrase string:",
            'Call "advapi32.dll" "CryptEncrypt"',
        ),
    },
    "decrypt": {
        "desktop": (
            'To handle decrypt:',
            'If the current tab\'s mode is "editor", handle decrypt given the current tab\'s node\'s source; exit.',
        ),
        "editor": (
            'To handle decrypt given a source:',
            'Ask "Passphrase?".',
            "Extract a buffer from the source's text (selected bytes).",
            "Decrypt the buffer with the answer.",
            "Put the buffer on the windows clipboard.",
        ),
        "noodle": (
            "To decrypt a buffer given a passphrase string:",
            'Call "advapi32.dll" "CryptDecrypt"',
        ),
    },
}
# Explicit menu command labels, dispatch and forwarding into editor mode.
# These are pinned *textual links*, not a runtime execution proof.
MENU_ROUTE_PINS = {
    "encrypt": (
        'If the command\'s handler is "handle encrypt", handle encrypt; exit.',
        'If the current tab\'s mode is "editor", add "Encrypt..." and "handle encrypt" to the submenu.',
        "To handle encrypt:",
        'If the current tab\'s mode is "editor", handle encrypt given the current tab\'s node\'s source; exit.',
    ),
    "decrypt": (
        'If the command\'s handler is "handle decrypt", handle decrypt; exit.',
        'If the current tab\'s mode is "editor", add "Decrypt..." and "handle decrypt" to the submenu.',
        "To handle decrypt:",
        'If the current tab\'s mode is "editor", handle decrypt given the current tab\'s node\'s source; exit.',
    ),
}
# These two groups identify the explicit WinSock dynamic function lookup
# and later pointer dispatch. The grouping is *not* a control-flow proof.
DYNAMIC_RESOLVER_PINS = {
    "function_pointer_registration": (
        "To get some addrinfo routines:",
        'Call "kernel32.dll" "LoadLibraryA" with "ws2_32.dll"',
        'Call "kernel32.dll" "GetProcAddress" with the handle and "getaddrinfo"',
        "Put the pointer into the addrinfo routines' getaddrinfo pointer.",
        'Call "kernel32.dll" "GetProcAddress" with the handle and "freeaddrinfo"',
        "Put the pointer into the addrinfo routines' freeaddrinfo pointer.",
    ),
    "function_pointer_dispatch": (
        "To get a sockaddr given a host string:",
        "Get some addrinfo routines.",
        "Call the addrinfo routines' getaddrinfo with",
        "Call the addrinfo routines' freeaddrinfo with",
    ),
}

KDF_PINS = (
    'To create a crypt session with a passphrase string:',
    'Call "advapi32.dll" "CryptCreateHash"',
    '[calg_md5]',
    'Call "advapi32.dll" "CryptDeriveKey"',
    '[calg_rc4 stream cipher]',
)
EXPECTED_PREFIX_COUNTS = {
    "near_conditional_branch_prefix": 41,
    "near_unconditional_jump_prefix": 4,
    "ff_group_inc_prefix": 2,
    "ff_group_indirect_call_prefix": 0,
    "ff_group_indirect_jump_prefix": 0,
    "direct_call_prefix": 0,
    "interrupt_or_syscall_prefix": 0,
    "other_prefix": 400,
}
FLAG_FIELDS = {
    "binary_downloaded": False,
    "compiler_executed": False,
    "runtime_reachability_proven": False,
    "machine_code_disassembled": False,
    "stage_zero_verified": False,
    "malware_clearance": False,
    "native_qa_99_pass": False,
}


def classify_instruction_prefix(hex_string: str) -> str:
    """Classify *first* x86 opcode only; this is NOT full disassembly.

    A literal may include multiple instructions or operand bytes.
    The classifier never claims that a later byte lacks sensitive opcodes.
    """
    if (not isinstance(hex_string, str) or len(hex_string) < 2 or
            len(hex_string) % 2 or
            any(ch not in "0123456789abcdefABCDEF" for ch in hex_string)):
        raise ValueError("invalid Intel hex literal")
    b = bytes.fromhex(hex_string)
    first = b[0]
    if len(b) >= 6 and first == 0x0F and 0x80 <= b[1] <= 0x8F:
        return "near_conditional_branch_prefix"
    if first == 0xE9 and len(b) >= 5:
        return "near_unconditional_jump_prefix"
    if first == 0xFF:
        if len(b) < 2:
            raise ValueError("FF group missing ModR/M byte")
        group = (b[1] >> 3) & 7
        if group in (0, 1):
            return "ff_group_inc_prefix"
        if group in (2, 3):
            return "ff_group_indirect_call_prefix"
        if group in (4, 5):
            return "ff_group_indirect_jump_prefix"
        return "other_prefix"
    if first in (0xE8, 0x9A):
        return "direct_call_prefix"
    if first in (0xCD, 0xCC, 0xCE, 0xF1) or b.startswith((b"\x0f\x05", b"\x0f\x34")):
        return "interrupt_or_syscall_prefix"
    return "other_prefix"


def active_lines(data: bytes) -> list[tuple[int, str]]:
    return [(i, row.strip()) for i, row in
            enumerate(data.decode("latin-1").splitlines(), 1)
            if row.strip() and not row.lstrip().startswith("\\")]


def sequential_evidence(lines: list[tuple[int, str]], needles: tuple[str, ...]) -> list[int]:
    """Locate markers in non-decreasing line order (some share one line).

    This does not establish lexical scope or actual runtime call order.
    """
    indexes = []
    from_index = 0
    for phrase in needles:
        found = None
        for idx in range(from_index, len(lines)):
            if phrase in lines[idx][1]:
                found = idx
                break
        if found is None:
            raise ValueError("source phrase absent or out of order: " + phrase)
        indexes.append(lines[found][0])
        from_index = found  # allow multiple pinned markers on one source line
    return indexes


def audit(read_source, *, strict: bool = True) -> dict:
    blobs = {}
    for filename in provenance.FILES:
        contents = read_source("release", filename)
        result = provenance.inspect(contents, "release", filename)
        if not result["ok"]:
            raise ValueError("Pinned release source hash mismatch: " + filename)
        blobs[filename] = contents
    path_evidence = {}
    for operation, sections in CRYPTO_PATHS.items():
        path_evidence[operation] = {}
        for kind, phrases in sections.items():
            filename = "the " + kind
            path_evidence[operation][filename] = sequential_evidence(
                active_lines(blobs[filename]), phrases)
    kdf_lines = sequential_evidence(active_lines(blobs["the noodle"]), KDF_PINS)
    menu_route_evidence = {
        operation: sequential_evidence(active_lines(blobs["the desktop"]), pins)
        for operation, pins in MENU_ROUTE_PINS.items()
    }
    resolver_route_evidence = {
        stage: sequential_evidence(active_lines(blobs["the noodle"]), pins)
        for stage, pins in DYNAMIC_RESOLVER_PINS.items()
    }

    all_intel = []
    malformed = []
    for filename, data in blobs.items():
        scan = lexical.scan_text(data, filename)
        malformed.extend((filename, row) for row in scan["invalid_intel"])
        all_intel.extend((filename, row) for row in scan["intel"])
    counts = Counter(classify_instruction_prefix(item["hex"]) for _, item in all_intel)
    counts_with_zeros = {key: counts.get(key, 0) for key in EXPECTED_PREFIX_COUNTS}
    violations = []
    if malformed:
        violations.append("malformed Intel literals")
    if len(all_intel) != 447:
        violations.append("unexpected total Intel literals")
    if any(filename != "the noodle" for filename, _ in all_intel):
        violations.append("Intel literal in unexpected module")
    if counts_with_zeros != EXPECTED_PREFIX_COUNTS:
        violations.append("x86 opcode-prefix category drift")
    if strict and violations:
        raise ValueError("; ".join(violations))
    return {
        "kind": "PINNED_CRYPTO_PATH_AND_X86_PREFIX_SOURCE_ONLY",
        "source_commit": provenance.COMMIT,
        "verified_text_modules": len(blobs),
        "crypto_path_evidence": path_evidence,
        "crypto_kdf_evidence_lines": kdf_lines,
        "menu_route_evidence": menu_route_evidence,
        "dynamic_resolver_evidence": resolver_route_evidence,
        "intel_directives": len(all_intel),
        "intel_prefix_categories": counts_with_zeros,
        "intel_invalid_literals": len(malformed),
        "lexical_gate_pass": not violations,
        "violations": violations,
        "limitations": (
            "Sequential source statements and first x86 opcode prefixes only; "
            "not a complete call graph, instruction decoder or runtime proof."
        ),
        **FLAG_FIELDS,
    }


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    input_mode = parser.add_mutually_exclusive_group(required=True)
    input_mode.add_argument("--fetch", action="store_true",
                            help="Fetch pinned text sources only; no EXE or ZIP")
    input_mode.add_argument("--directory", type=Path,
                            help="Offline source root containing release/*")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args(argv)
    reader = (provenance.download_source if args.fetch else
              lambda group, filename: provenance.read_directory_source(
                  args.directory, group, filename))
    try:
        report = audit(reader)
    except (ValueError, OSError, KeyError, TypeError) as e:
        failed = {"kind": "CRYPTO_PATH_INTEL_PREFIX_AUDIT_FAILED",
                  "lexical_gate_pass": False, "compiler_executed": False,
                  "malware_clearance": False, "native_qa_99_pass": False,
                  "error": str(e)}
        if args.output:
            args.output.write_text(json.dumps(failed, indent=2) + "\n",
                                   encoding="utf-8")
        print(json.dumps(failed), file=sys.stderr)
        return 2
    if args.output:
        args.output.write_text(json.dumps(report, indent=2) + "\n",
                               encoding="utf-8")
    print(json.dumps({key: report[key] for key in (
        "lexical_gate_pass", "verified_text_modules",
        "intel_directives", "intel_prefix_categories",
        "compiler_executed", "runtime_reachability_proven",
        "machine_code_disassembled", "stage_zero_verified",
        "malware_clearance", "native_qa_99_pass")}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
