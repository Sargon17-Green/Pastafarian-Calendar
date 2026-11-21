#!/usr/bin/env python3
"""Offline, read-only audit of a SQL+Tamil phase-profile GitHub Actions ZIP.

This checks the provenance, ZIP integrity, selected internal source hashes,
and emitted phase markers. An audit PASS is never a PostgreSQL, differential,
or Slice25 acceptance. The ZIP must be supplied by the caller.
"""
from __future__ import annotations

import argparse
import collections
import hashlib
import json
import re
import sys
import zipfile
from pathlib import Path

REQUIRED = {
    "versions.txt", "static.txt", "generator.txt", "oracle-audit.txt",
    "source-sha256.txt", "production-blobs.txt", "phase-overrides.sql",
    "test.sql", "original.sql", "postgres-phase.txt",
}
SHA256_LINE = re.compile(r"^([a-f0-9]{64})  (.+)$")
MARKER = re.compile(r"SQL_TAMIL_PROFILE_(ENTER|EXIT)=([a-z_]+):(.+)$")
NUMERIC_DURATION = re.compile(r"^.+:([0-9]+(?:\.[0-9]+)?)$")


def need(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def audit(path: Path, expected_zip_sha256: str, expected_commit: str) -> dict:
    raw = path.read_bytes()
    archive_sha256 = hashlib.sha256(raw).hexdigest()
    need(archive_sha256 == expected_zip_sha256, "archive SHA256 mismatch")
    with zipfile.ZipFile(path) as archive:
        need(archive.testzip() is None, "CRC or decompression error")
        names = archive.namelist()
        need(len(names) == len(set(names)), "duplicate ZIP names")
        need(REQUIRED.issubset(names), "missing required ZIP files")
        need(all("/" not in name and "\\" not in name for name in names),
             "unexpected directory or path traversal inside ZIP")
        files = {name: archive.read(name) for name in names}
    texts = {name: data.decode("utf-8-sig") for name, data in files.items()}
    versions = dict(line.split("=", 1) for line in texts["versions.txt"].splitlines()
                    if "=" in line)
    need(versions.get("PROJECT_ID") == "PC-BRANCH-SQL-TAMIL", "project mismatch")
    need(versions.get("BRANCH") == "SQL+தமிழ்", "branch mismatch")
    need(versions.get("GITHUB_SHA") == expected_commit, "commit mismatch")
    need(versions.get("CASE") == "prev_3_prev_middle", "case mismatch")
    need("postgres (PostgreSQL) 17." in texts["versions.txt"], "PG17 version absent")
    need("SLICE25_QA_PHASE_STATIC_LOCK=7/7 PASS" in texts["static.txt"],
         "static lock not verified")
    need("SLICE25_QA_PHASE_REVERSIBLE_TRANSFORMS=PASS" in texts["static.txt"],
         "reversibility not verified")
    need("SLICE25_GENERATOR_PREFLIGHT=87/87 PASS" in texts["oracle-audit.txt"],
         "generator preflight not verified")
    need("SLICE25_LOCKED_CASES=29/29 PASS" in texts["oracle-audit.txt"],
         "locked corpus not verified")
    need("SLICE25_LOCKED_YEARS=8/8 PASS" in texts["oracle-audit.txt"],
         "locked year count not verified")
    need("SLICE25_FIELD_EXPECTATIONS=145/145 PRESENT" in texts["oracle-audit.txt"],
         "oracle field count not verified")
    manifest = {}
    for line in texts["source-sha256.txt"].splitlines():
        match = SHA256_LINE.fullmatch(line)
        need(match is not None, "invalid source manifest line")
        digest, source_path = match.groups()
        need(source_path not in manifest, "duplicate manifest source")
        manifest[source_path] = digest
    checked_internal = []
    for source_path, digest in manifest.items():
        if not source_path.startswith("phase-evidence/"):
            continue  # Source bytes are not embedded: never claim verification.
        basename = source_path.removeprefix("phase-evidence/")
        need(basename in files, "missing embedded source: " + source_path)
        need(hashlib.sha256(files[basename]).hexdigest() == digest,
             "embedded source SHA256 mismatch: " + source_path)
        checked_internal.append(basename)
    need(set(checked_internal) == {"phase-overrides.sql", "test.sql", "original.sql"},
         "missing generated-file digest coverage")
    production_blobs = texts["production-blobs.txt"].splitlines()
    need(len(production_blobs) == 28 and all(re.fullmatch(r"[a-f0-9]{40}", s)
                                               for s in production_blobs),
         "28 production blob references absent")
    trace = collections.defaultdict(lambda: {"enter": 0, "exit": 0,
                                              "sum_ms": 0.0, "max_ms": 0.0})
    last_marker = None
    for line in texts["postgres-phase.txt"].splitlines():
        match = MARKER.search(line)
        if not match:
            continue
        event, phase, payload = match.groups()
        last_marker = {"event": event, "phase": phase, "payload": payload}
        trace[phase][event.lower()] += 1
        if event == "EXIT":
            elapsed = NUMERIC_DURATION.fullmatch(payload)
            need(elapsed is not None, "invalid phase duration: " + line)
            duration = float(elapsed.group(1))
            need(duration >= 0, "negative phase duration")
            trace[phase]["sum_ms"] += duration
            trace[phase]["max_ms"] = max(trace[phase]["max_ms"], duration)
    log = texts["postgres-phase.txt"]
    timeout = "ERROR:  canceling statement due to statement timeout" in log
    five_fields = len(re.findall(r"SLICE25_QA_PHASE_FIELD_PASS=prev_3_prev_middle", log))
    native_five_fields = len(re.findall(r"SLICE25_NATIVE_FIELD_PASS=prev_3_prev_middle", log))
    qa_green = "SLICE25_QA_PHASE_GREEN=native:prev_3_prev_middle" in log
    native_green = "SLICE25_MATRIX_GREEN=native:prev_3_prev_middle" in log
    need("SET statement_timeout='12min'" in texts["test.sql"] or
         "set statement_timeout = '12min'" in texts["test.sql"].lower(),
         "12-minute SQL timeout is not source evidenced")
    result = {
        "audit": "PASS (archive/provenance/trace accounting only)",
        "project_id": versions["PROJECT_ID"],
        "commit_sha": versions["GITHUB_SHA"],
        "branch": versions["BRANCH"],
        "case": versions["CASE"],
        "postgres_version": next(line for line in texts["versions.txt"].splitlines()
                                 if line.startswith("postgres (PostgreSQL)")),
        "zip_sha256": archive_sha256,
        "zip_crc": "PASS",
        "zip_entry_count": len(names),
        "manifest_record_count": len(manifest),
        "embedded_sha256_checked": sorted(checked_internal),
        "production_blob_count_recorded": len(production_blobs),
        "source_blob_bytes_in_zip": False,
        "sql_timeout_12min": timeout,
        "qa_field_notices": five_fields,
        "qa_green": qa_green,
        "native_field_notices": native_five_fields,
        "native_green": native_green,
        "profile": dict(sorted(trace.items())),
        "last_profile_marker": last_marker,
        "error_context_negative_gate_gap": 'SQL function "negative_gate_gap" statement 1' in log,
        "status": ("TIMEOUT_NOT_ACCEPTED" if timeout and not qa_green
                   else "QA_GREEN_NEEDS_INDEPENDENT_ORIGINAL" if qa_green
                   else "UNDETERMINED_NOT_ACCEPTED"),
    }
    need(bool(result["profile"]), "no profile markers")
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("archive", type=Path)
    parser.add_argument("--sha256", required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    try:
        result = audit(args.archive, args.sha256, args.commit)
    except (ValueError, OSError, zipfile.BadZipFile, UnicodeError) as exc:
        print(f"SLICE25_PHASE_ZIP_AUDIT=FAIL: {exc}", file=sys.stderr)
        return 2
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print("SLICE25_PHASE_ZIP_AUDIT=PASS")
        print("SLICE25_PG_NATIVE_ACCEPTANCE=" + result["status"])
        for phase, metrics in result["profile"].items():
            print(f"{phase}: {metrics['enter']} ENTER, {metrics['exit']} EXIT, "
                  f"sum={metrics['sum_ms']:.3f}ms")
    return 0


if __name__ == "__main__":
    sys.exit(main())