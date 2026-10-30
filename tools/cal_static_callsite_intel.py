#!/usr/bin/env python3
"""Read-only CAL direct-call and Intel-literal source inventory.

This is a lexical audit of six exact text files. It does not parse the full
Plain English grammar, prove runtime reachability, disassemble opcodes,
download binary objects, or execute the compiler.
"""
from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path
import re
import sys

import cal_source_provenance as provenance

HEADER = re.compile(r"^To\s+([^:;]+)[:;]", re.I)
INTEL_START = re.compile(r"^\s*Intel\b", re.I)
INTEL_LITERAL = re.compile(r"^\s*Intel\s+\$([0-9A-Fa-f]+)\.", re.I)
DLL_CALL = re.compile(r'\bCall\s+"([a-z0-9_]+\.dll)"\s+"([^"\r\n]+)"', re.I)
API_OWNER_PINS = {
    "kernel32.dll!CreateProcessA": "start a process given a path",
    "kernel32.dll!TerminateProcess": "stop a process",
    "winhttp.dll!WinHttpSendRequest": "send a data string to a winhttp request",
    "wininet.dll!InternetReadFile": "read a url into a buffer",
    "advapi32.dll!CryptDeriveKey": "create a crypt session with a passphrase string",
    "advapi32.dll!CryptEncrypt": "encrypt a buffer given a passphrase string",
    "advapi32.dll!CryptDecrypt": "decrypt a buffer given a passphrase string",
    "kernel32.dll!DeleteFileA": "destroy a path in the file system (file)",
}
EXACT_CALLS = {
    "Send the email.": 4,
    "Get some addrinfo routines.": 1,
    "Create a socket given the email's smtp server and 25.": 1,
}
EXPECTED_INTEL = {
    "source_file": "the noodle",
    "directives": 447,
    "literal_bytes": 1841,
    "unique_hex_sequences": 158,
}


def scan_text(data: bytes, filename: str) -> dict:
    lines = data.decode("latin-1").splitlines()
    owner = None
    intel = []
    dll = []
    call_sites = []
    invalid = []
    for index, row in enumerate(lines, 1):
        stripped = row.strip()
        if not stripped or stripped.startswith("\\"):
            continue
        heading = HEADER.match(row)
        if heading:
            owner = heading.group(1).lower().strip()
        if INTEL_START.match(row):
            token = INTEL_LITERAL.match(row)
            if not token or len(token.group(1)) % 2:
                invalid.append({"line": index, "text": row[:160]})
            else:
                intel.append({"line": index, "owner": owner,
                              "hex": token.group(1).upper()})
        for match in DLL_CALL.finditer(row):
            dll.append({"line": index, "owner": owner,
                        "api": match.group(1).lower() + "!" + match.group(2)})
        if stripped in EXACT_CALLS:
            call_sites.append({"line": index, "owner": owner,
                               "statement": stripped})
    return {"filename": filename, "line_count": len(lines),
            "intel": intel, "invalid_intel": invalid,
            "dll": dll, "direct_statements": call_sites}


def audit(reader, *, strict: bool = True) -> dict:
    scanned = {}
    all_intel = []
    calls = []
    direct = []
    invalid = []
    for filename in provenance.FILES:
        data = reader("release", filename)
        validated = provenance.inspect(data, "release", filename)
        if not validated["ok"]:
            raise ValueError("Source hash check failed: " + filename)
        scan = scan_text(data, filename)
        scanned[filename] = {"lines": scan["line_count"],
                             "sha256": validated["sha256"],
                             "intel_directives": len(scan["intel"])}
        all_intel.extend([{"file": filename, **item} for item in scan["intel"]])
        calls.extend([{"file": filename, **item} for item in scan["dll"]])
        direct.extend([{"file": filename, **item}
                       for item in scan["direct_statements"]])
        invalid.extend([{"file": filename, **item}
                        for item in scan["invalid_intel"]])
    total_bytes = sum(len(row["hex"]) // 2 for row in all_intel)
    unique_literals = len({row["hex"] for row in all_intel})
    observed = {"source_file": "the noodle",
                "directives": len(all_intel),
                "literal_bytes": total_bytes,
                "unique_hex_sequences": unique_literals}
    other_intel = sorted({row["file"] for row in all_intel
                          if row["file"] != "the noodle"})
    direct_counter = Counter(row["statement"] for row in direct)
    anchored = {}
    for api, expected_owner in API_OWNER_PINS.items():
        matches = [row for row in calls if row["api"] == api]
        anchored[api] = {"expected_owner": expected_owner,
                         "sites": matches}
    violations = []
    if invalid:
        violations.append("invalid Intel hex directive")
    if other_intel:
        violations.append("Intel directives outside pinned noodle")
    if observed != EXPECTED_INTEL:
        violations.append("Intel count, byte length or uniqueness drift")
    for api, group in anchored.items():
        if len(group["sites"]) != 1 or group["sites"][0]["owner"] != group["expected_owner"]:
            violations.append("sensitive API ownership drift: " + api)
    for statement, expected_count in EXACT_CALLS.items():
        if direct_counter[statement] != expected_count:
            violations.append("explicit direct statement count drift: " + statement)
    if strict and violations:
        raise ValueError("; ".join(violations))
    return {
        "kind": "SOURCE_ONLY_LEXICAL_CALLSITE_AND_INTEL_INVENTORY",
        "pinned_commit": provenance.COMMIT,
        "verified_source_files": len(scanned),
        "files": scanned,
        "intel": {
            "directives": len(all_intel),
            "literal_bytes": total_bytes,
            "unique_hex_sequences": unique_literals,
            "invalid_directives": invalid,
            "files": dict(Counter(row["file"] for row in all_intel)),
            "routine_examples": all_intel[:8],
        },
        "sensitive_api_routine_owners": anchored,
        "explicit_call_sites": direct,
        "direct_statement_counts": dict(direct_counter),
        "lexical_checks_pass": not violations,
        "violations": violations,
        "binary_downloaded": False,
        "compiler_executed": False,
        "disassembly_performed": False,
        "runtime_reachability_proven": False,
        "stage_zero_verified": False,
        "malware_clearance": False,
        "native_qa_99_pass": False,
    }


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    choice = parser.add_mutually_exclusive_group(required=True)
    choice.add_argument("--fetch", action="store_true",
                        help="Fetch six pinned text files; not binaries")
    choice.add_argument("--directory", type=Path,
                        help="Read safe local mirror root/release/<name>")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args(argv)
    reader = (provenance.download_source if args.fetch else
              lambda group, name: provenance.read_directory_source(
                  args.directory, group, name))
    try:
        report = audit(reader)
    except (OSError, ValueError, TypeError) as exc:
        failure = {"kind": "CALLSITE_INTEL_AUDIT_FAILED",
                   "lexical_checks_pass": False, "compiler_executed": False,
                   "native_qa_99_pass": False, "malware_clearance": False,
                   "error": str(exc)}
        if args.output:
            args.output.write_text(json.dumps(failure, indent=2) + "\n",
                                   encoding="utf-8")
        print(json.dumps(failure), file=sys.stderr)
        return 2
    if args.output:
        args.output.write_text(json.dumps(report, indent=2) + "\n",
                               encoding="utf-8")
    summary = {k: report[k] for k in (
        "lexical_checks_pass", "verified_source_files",
        "direct_statement_counts", "binary_downloaded",
        "compiler_executed", "runtime_reachability_proven",
        "stage_zero_verified", "malware_clearance", "native_qa_99_pass")}
    summary["intel"] = {k: report["intel"][k] for k in (
        "directives", "literal_bytes", "unique_hex_sequences")}
    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
