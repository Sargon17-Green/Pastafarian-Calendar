#!/usr/bin/env python3
"""CAL source-only audit of Windows API references; NOT malware clearance.

Input is six pinned *text* files from one source set, never EXE or ZIP.
The scan describes potential capabilities, not reachability or runtime use.
"""
from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path
import re
import sys

import cal_source_provenance as provenance

API = re.compile(r'\bCall\s+"([a-z0-9_]+\.dll)"\s+"([^"\r\n]+)"', re.I)
REQUIRED = {
    "kernel32.dll!CreateProcessA", "kernel32.dll!TerminateProcess",
    "kernel32.dll!CreateThread", "kernel32.dll!LoadLibraryA",
    "kernel32.dll!GetProcAddress", "kernel32.dll!CreateFileA",
    "kernel32.dll!WriteFile", "kernel32.dll!DeleteFileA",
    "kernel32.dll!CopyFileA", "kernel32.dll!MoveFileA",
    "wininet.dll!InternetOpenUrlA", "wininet.dll!InternetReadFile",
    "winhttp.dll!WinHttpSendRequest", "winhttp.dll!WinHttpReadData",
    "ws2_32.dll!socket", "ws2_32.dll!connect",
    "ws2_32.dll!send", "ws2_32.dll!recv",
    "advapi32.dll!CryptCreateHash", "advapi32.dll!CryptDeriveKey",
    "advapi32.dll!CryptEncrypt", "advapi32.dll!CryptDecrypt",
}
NETWORK_DLLS = frozenset({"wininet.dll", "winhttp.dll", "ws2_32.dll"})
CRYPTO_DLLS = frozenset({"advapi32.dll"})
PROCESS_APIS = frozenset({
    "CreateProcessA", "TerminateProcess", "CreateThread",
    "LoadLibraryA", "GetProcAddress",
})
FILESYSTEM_APIS = frozenset({
    "CreateFileA", "WriteFile", "DeleteFileA", "CopyFileA",
    "MoveFileA", "RemoveDirectoryA",
})
SENSITIVE_DLLS = NETWORK_DLLS | CRYPTO_DLLS
SOURCE_SET = "release"
NATIVE_TESTS_CONFIRMED = False


def extract_calls(data: bytes, filename: str) -> list[dict]:
    """Read bytes through reversible latin-1; do not execute the source."""
    calls = []
    for row_number, line in enumerate(data.decode("latin-1").splitlines(), 1):
        if line.lstrip().startswith("\\"):  # Plain English comment
            continue
        for match in API.finditer(line):
            dll = match.group(1).lower()
            name = match.group(2)
            calls.append({"source_file": filename, "line": row_number,
                          "dll": dll, "function": name,
                          "reference": dll + "!" + name})
    return calls


def categories(dll: str, name: str) -> list[str]:
    result = []
    if dll in NETWORK_DLLS:
        result.append("network")
    if dll in CRYPTO_DLLS and name.startswith("Crypt"):
        result.append("legacy_cryptography")
    if dll == "kernel32.dll" and name in PROCESS_APIS:
        result.append("process_or_dynamic_loading")
    if dll == "kernel32.dll" and name in FILESYSTEM_APIS:
        result.append("filesystem_mutation")
    return result


def audit(read_source, *, require_known_surface: bool = True) -> dict:
    calls = []
    sources = {}
    source_bytes = {}
    for filename in provenance.FILES:
        data = read_source(SOURCE_SET, filename)
        check = provenance.inspect(data, SOURCE_SET, filename)
        if not check["ok"]:
            raise ValueError("Pinned source byte check failed: " + filename)
        source_bytes[filename] = data
        entries = extract_calls(data, filename)
        calls.extend(entries)
        sources[filename] = {"bytes": len(data), "sha256": check["sha256"],
                             "api_references": len(entries)}
    by_api = Counter(item["reference"] for item in calls)
    missing = sorted(REQUIRED - set(by_api))
    unexpected_sensitive = sorted(
        ref for ref in by_api
        if ref.split("!", 1)[0] in SENSITIVE_DLLS
        and ref not in REQUIRED
        and not (
            ref.startswith("wininet.dll!Internet")
            or ref.startswith("winhttp.dll!WinHttp")
            or ref.startswith("ws2_32.dll!")
            or ref.startswith("advapi32.dll!Crypt")
        )
    )
    noodle = source_bytes["the noodle"].decode("latin-1")
    features = {
        "md5_password_hash_kdf": "[calg_md5]" in noodle,
        "rc4_derived_key": "[calg_rc4 stream cipher]" in noodle,
        "smtp_port_25": (
            "To send an email:" in noodle and
            "email's smtp server and 25" in noodle
        ),
    }
    if require_known_surface and (missing or unexpected_sensitive or
                                  not all(features.values())):
        raise ValueError("Sensitive source API audit changed: " +
                         repr({"missing": missing,
                               "unexpected_sensitive": unexpected_sensitive,
                               "missing_features": [k for k, v in features.items() if not v]}))
    findings = []
    for item in calls:
        kinds = categories(item["dll"], item["function"])
        if kinds:
            findings.append({"source_file": item["source_file"],
                             "line": item["line"], "api": item["reference"],
                             "categories": kinds})
    return {
        "kind": "STATIC_TEXT_WINDOWS_API_CAPABILITY_INVENTORY_NOT_MALWARE_CLEARANCE",
        "pinned_source_repo": "elenderg/PAL-1000",
        "pinned_commit": provenance.COMMIT,
        "source_set": SOURCE_SET,
        "six_text_sources_hash_verified": True,
        "sources": sources,
        "api_reference_occurrences": len(calls),
        "unique_referenced_apis": len(by_api),
        "sensitive_api_references": findings,
        "features": features,
        "missing_required_sensitive_api": missing,
        "unexpected_sensitive_api": unexpected_sensitive,
        "binary_downloaded": False,
        "compiler_executed": False,
        "native_qa_99_pass": NATIVE_TESTS_CONFIRMED,
        "malware_clearance": False,
        "execution_reachability_proven": False,
        "stage_zero_verified": False,
    }


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--fetch", action="store_true",
                       help="Fetch six hash-pinned release text files only")
    group.add_argument("--directory", type=Path,
                       help="Read from ROOT/release/<name>, with symlink guard")
    parser.add_argument("--output", type=Path, help="JSON report file")
    args = parser.parse_args(argv)
    if args.fetch:
        reader = provenance.download_source
    else:
        reader = lambda group, name: provenance.read_directory_source(
            args.directory, group, name)
    try:
        result = audit(reader)
    except (OSError, ValueError) as error:
        print("STATIC_SOURCE_AUDIT_FAILED: " + str(error), file=sys.stderr)
        if args.output:
            args.output.write_text(json.dumps({
                "kind": "STATIC_SOURCE_AUDIT_FAILED",
                "api_audit_pass": False, "compiler_executed": False,
                "malware_clearance": False, "error": str(error),
            }, indent=2) + "\n", encoding="utf-8")
        return 2
    if args.output:
        args.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    # Brief CI output; full evidence is available in optional JSON report.
    print(json.dumps({
        "api_audit_pass": True,
        "api_reference_occurrences": result["api_reference_occurrences"],
        "unique_referenced_apis": result["unique_referenced_apis"],
        "sensitive_reference_count": len(result["sensitive_api_references"]),
        "features": result["features"],
        "binary_downloaded": False,
        "compiler_executed": False,
        "malware_clearance": False,
        "native_qa_99_pass": False,
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
