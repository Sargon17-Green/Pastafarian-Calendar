#!/usr/bin/env python3
"""Verify only six pinned CAL plain-text source files; never execute a compiler.

This tool is a provenance aid, NOT an antivirus scan or executable approval.
It deliberately does not request ZIP archives or executable paths.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys
from urllib.error import URLError
from urllib.parse import quote
from urllib.request import urlopen

COMMIT = "2d44defdedf24519bba754114ee66e6d1defff1e"
HOST = "https://raw.githubusercontent.com/elenderg/PAL-1000/"
SOURCES = {
    "release": "recursos/CAL-4700",
    "tutorial_step08": "Documentação/Passo-a-Passo para Compilação/cal-4700 passo08",
}
FILES = ("the compiler", "the desktop", "the editor", "the finder", "the noodle", "the writer")
# SHA-1 of canonical Git blob objects, as reported by the pinned Git tree.
EXPECTED = {
    "release": {
        "the compiler": ("810bdc58ba41e611fc0ba0b53f467d842dcb1bb1", 198054),
        "the desktop": ("15090a299ff82572f9a5e95af2c95a054edb0139", 84112),
        "the editor": ("25df723faf8e65e78b0c8a5bdd28330720907dbd", 31924),
        "the finder": ("660357bcec832f28059a950b264e20381dc997d6", 45063),
        "the noodle": ("571e3624d83fe531e15b76be6e1168d64a06f71f", 598660),
        "the writer": ("460c77888767a49ef6f73f611e82101c04ba09e1", 161468),
    },
    "tutorial_step08": {
        "the compiler": ("d8da5ace27c8131fa152312b4262e5792d0d4898", 199997),
        "the desktop": ("357091dfdbf125222e218b8e5aeb90dc19275ca5", 84111),
        "the editor": ("25df723faf8e65e78b0c8a5bdd28330720907dbd", 31924),
        "the finder": ("660357bcec832f28059a950b264e20381dc997d6", 45063),
        "the noodle": ("336046e46f11bb8fde696d54588071bf86e994a5", 591052),
        "the writer": ("460c77888767a49ef6f73f611e82101c04ba09e1", 161468),
    },
}
# Independent SHA-256 digests of the original source bytes (not decoded text).
EXPECTED_SHA256 = {
    'release': {
        'the compiler': '9c524096c0995bb5205b4fd059001d098f689b3bbeef61889b4e8aa4a22b273d',
        'the desktop': '27a5fcf58116f38d5dac3cd6ca43aec073bd56b9d570e16ae6daba30d9a661a5',
        'the editor': '571f5c3f0174efa7339d775a1e938abe6fb461afb7f1fd691a19ba4464d36c77',
        'the finder': '3eb08dee93d71f7ad8c6146a34cbdebfdea17abf5f6b494aab5095707bbf7c1b',
        'the noodle': '600fd8a5e710657fd44ecaa94dc51fc4314f1a4f738d335bf5bb151bbf60a09c',
        'the writer': '877cfc1de6b159f27d8cf74acc53e28629c531886b21bf774503849470ff1660',
    },
    'tutorial_step08': {
        'the compiler': '790300a2a69541beee2960b433f97e897f34b5376f172e5582e0b9b1a13eb071',
        'the desktop': 'ab88400f69374ac4911abf9a337a9b1dd968801537eca65e6c3126b5e16037b1',
        'the editor': '571f5c3f0174efa7339d775a1e938abe6fb461afb7f1fd691a19ba4464d36c77',
        'the finder': '3eb08dee93d71f7ad8c6146a34cbdebfdea17abf5f6b494aab5095707bbf7c1b',
        'the noodle': '5f5bf6c35fe4adcc5e22df1ee67c6601fe469fe1eb12def20fb13d15e3912289',
        'the writer': '877cfc1de6b159f27d8cf74acc53e28629c531886b21bf774503849470ff1660',
    },
}

MAX_BYTES = 800_000
ACTIVE_ROUTINE = re.compile(r"^\s*To\s+[^\r\n:]+:\s*$", re.IGNORECASE)
COMMENTED_ROUTINE = re.compile(r"^\s*\\+\s*To\s+[^\r\n:]+:\s*$", re.IGNORECASE)


def git_blob_sha1(data: bytes) -> str:
    """Compute Git blob hash, including the blob-length header."""
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()


def approved_source_url(group: str, name: str) -> str:
    if group not in SOURCES or name not in FILES:
        raise ValueError("Only the 12 pinned text-source paths are permitted")
    path = "/".join(quote(part, safe="") for part in (SOURCES[group] + "/" + name).split("/"))
    return HOST + COMMIT + "/" + path


def download_source(group: str, name: str) -> bytes:
    with urlopen(approved_source_url(group, name), timeout=15) as r:
        if r.geturl() != approved_source_url(group, name):
            raise ValueError("Unapproved redirect")
        data = r.read(MAX_BYTES + 1)
    if len(data) > MAX_BYTES:
        raise ValueError("Source file exceeds allowed size")
    return data


def inspect(data: bytes, group: str, name: str) -> dict:
    expected_sha, expected_size = EXPECTED[group][name]
    actual_sha = git_blob_sha1(data)
    actual_sha256 = hashlib.sha256(data).hexdigest()
    expected_sha256 = EXPECTED_SHA256[group][name]
    executable_magic = data.startswith((b"MZ", b"PK\x03\x04"))
    valid = (len(data) == expected_size and actual_sha == expected_sha and
             actual_sha256 == expected_sha256 and not executable_magic)
    lines = data.decode("latin-1").splitlines()  # Preserve original 8-bit source bytes.
    return {
        "sha1_git_blob": actual_sha,
        "sha1_expected": expected_sha,
        "sha256": actual_sha256,
        "sha256_expected": expected_sha256,
        "bytes": len(data),
        "expected_bytes": expected_size,
        "ok": valid,
        "active_routines": sum(bool(ACTIVE_ROUTINE.fullmatch(x)) for x in lines),
        "commented_routines": sum(bool(COMMENTED_ROUTINE.fullmatch(x)) for x in lines),
    }


def audit(read_source) -> dict:
    result = {
        "kind": "SOURCE_PROVENANCE_ONLY_NOT_A_COMPILER_SECURITY_APPROVAL",
        "pinned_repository": "elenderg/PAL-1000",
        "pinned_commit": COMMIT,
        "groups": {},
    }
    for group in SOURCES:
        result["groups"][group] = {}
        for name in FILES:
            item = inspect(read_source(group, name), group, name)
            result["groups"][group][name] = item
            if not item["ok"]:
                raise ValueError(f"Pinned text-source integrity failure: {group}/{name}")
    release = result["groups"]["release"]["the compiler"]
    tutorial = result["groups"]["tutorial_step08"]["the compiler"]
    result["compiler_procedure_difference"] = {
        "release_active": release["active_routines"],
        "tutorial_active": tutorial["active_routines"],
        "tutorial_commented": tutorial["commented_routines"],
    }
    result["all_12_text_sources_verified"] = True
    result["compiler_executed"] = False
    result["native_qa_99_pass"] = False
    return result


def read_directory_source(root: Path, group: str, name: str) -> bytes:
    """Read only an allowed source path and reject links at every component."""
    if group not in SOURCES or name not in FILES:
        raise ValueError("Only the 12 pinned text-source paths are permitted")
    group_dir = root / group
    path = group_dir / name
    for part in (root, group_dir, path):
        if part.is_symlink():
            raise ValueError(f"Refusing symlink in source path: {part}")
    if not path.is_file():
        raise ValueError(f"Refusing missing/non-file source: {path}")
    with path.open("rb") as stream:
        data = stream.read(MAX_BYTES + 1)
    if len(data) > MAX_BYTES:
        raise ValueError("Source file exceeds allowed size")
    return data


def write_report(path: Path, result: dict) -> None:
    path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    choice = parser.add_mutually_exclusive_group(required=True)
    choice.add_argument("--fetch", action="store_true", help="Fetch 12 pinned GitHub TEXT sources only")
    choice.add_argument("--directory", type=Path, help="Read locally mirrored text sources: <dir>/<group>/<name>")
    parser.add_argument("--output", type=Path, help="Write verification report as JSON")
    args = parser.parse_args(argv)
    if args.fetch:
        reader = download_source
    else:
        reader = lambda group, name: read_directory_source(args.directory, group, name)
    try:
        result = audit(reader)
        if args.output:
            write_report(args.output, result)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0
    except (OSError, URLError, ValueError) as exc:
        # Overwrite any stale PASS report at the requested output path.
        failure = {
            "kind": "SOURCE_PROVENANCE_ONLY_NOT_A_COMPILER_SECURITY_APPROVAL",
            "all_12_text_sources_verified": False,
            "compiler_executed": False,
            "native_qa_99_pass": False,
            "error": str(exc),
        }
        if args.output:
            try:
                write_report(args.output, failure)
            except OSError as report_error:
                print("FAILED_TO_WRITE_REPORT: " + str(report_error), file=sys.stderr)
        print("SOURCE_AUDIT_FAILED: " + str(exc), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
