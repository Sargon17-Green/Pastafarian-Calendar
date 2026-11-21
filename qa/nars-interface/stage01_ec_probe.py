#!/usr/bin/env python3
"""QA-only: capture NARS2000 ⎕EC first result for each original Stage1 subtest.

Never runs the original RunStage01Tests entrypoint and never accepts Stage1.
The immutable 95-FX import prefix is copied verbatim from the accepted builder.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import pathlib
import re
import sys
from chunked_fx_probe import marker_write
from stage01_import_workspace import SOURCE_COMMIT, _codes
from stage01_subtest_probe import PROBES, LX_ENTRY, build_diagnostic

FINAL_TOKEN = "APL_GERMAN_STAGE01_ERROR_CODES_RECORDED_DIAGNOSTIC_NOT_STAGE01"


def build_error_code_probe(raw: bytes, root: pathlib.Path, marker: str) -> tuple[bytes, dict]:
    previous, base = build_diagnostic(raw, root, marker)
    lines = previous.decode("cp1252").splitlines(keepends=True)
    found = []
    for i, line in enumerate(lines):
        m = LX_ENTRY.fullmatch(line)
        if m is not None:
            decoded = m["serialized"].replace("{diamond}", "⋄").replace("{quad}", "⎕")
            if len(decoded) == base["outer_lx_chars"] and decoded.count("⎕EC ⎕UCS ") == 31:
                found.append((i, m, decoded))
    if len(found) != 1:
        raise ValueError("ORIGINAL_DIAGNOSTIC_LX_NOT_UNIQUE")
    position, match, outer = found[0]
    units = outer.split(" ⋄ ")
    if len(units) != 31 or any(not unit.startswith("⎕EC ⎕UCS ") for unit in units):
        raise ValueError("ORIGINAL_PROGRAM_COUNT_INVALID")
    original_programs = [
        "".join(chr(int(n)) for n in unit[len("⎕EC ⎕UCS "):].split())
        for unit in units
    ]
    if any("Stage01PrefixFix" not in p for p in original_programs[:23]):
        raise ValueError("ORIGINAL_95FX_PREFIX_MISSING")
    if sum(p.count(" Stage01PrefixFix ") for p in original_programs[:23]) != 95:
        raise ValueError("ORIGINAL_95FX_COUNT_MISMATCH")
    programs = original_programs[:23]
    codes = []
    root_path = pathlib.PureWindowsPath(marker)
    for i, name in enumerate(PROBES, 1):
        previous_probe = base["probes"][i-1]
        original = original_programs[22+i]
        if f" ⋄ {name} ⋄ " not in original or "RunStage01Tests" in original:
            raise ValueError(f"ORIGINAL_PROBE_MISMATCH:{name}")
        ec_path = str(root_path.with_name(f"{root_path.stem}_ec_{i:02d}_code.txt"))
        captured_path = str(root_path.with_name(f"{root_path.stem}_ec_{i:02d}_captured.txt"))
        captured_token = (
            f"APL_GERMAN_STAGE01_EC_V1|SOURCE={SOURCE_COMMIT}"
            f"|INDEX={i:02d}|NAME={name}|PHASE=CAPTURED_NOT_PASS"
        )
        v = f"Stage01EC{i:02d}"
        message_code_path = (
            str(root_path.with_name(f"{root_path.stem}_ec_{i:02d}_message_codes.txt"))
            if i >= 5 else None
        )
        # Error messages are Unicode; store ordinal values as ASCII digits.
        message_capture = (
            f" ⋄ (⍕⎕UCS ⊃{v}[3]) ⎕NAPPEND "
            f"((⎕UCS {_codes(message_code_path)}) ⎕NCREATE 0)"
            if message_code_path is not None else ""
        )
        # Separately catch each ORIGINAL (unchanged) call. Unlike an END marker,
        # CAPTURED signifies only that ⎕EC returned a status, not test success.
        statement = (
            "95 Stage01ChunkAssert 0 ⋄ "
            + marker_write(previous_probe["start_token"], previous_probe["start_path"])
            + f" ⋄ {v}←⎕EC ⎕UCS {_codes(name)}"
            + f" ⋄ (⍕{v}[1]) ⎕NAPPEND ((⎕UCS {_codes(ec_path)}) ⎕NCREATE 0)"
            + message_capture + " ⋄ " + marker_write(captured_token, captured_path)
        )
        programs.append(statement)
        codes.append({
            "index": i, "name": name,
            "start_path": previous_probe["start_path"],
            "start_token": previous_probe["start_token"],
            "captured_path": captured_path,
            "captured_token": captured_token,
            "code_path": ec_path,
            "message_code_path": message_code_path,
            "inner_sha256": hashlib.sha256(statement.encode("utf-8")).hexdigest(),
        })
    final = "95 Stage01ChunkAssert 0 ⋄ " + marker_write(FINAL_TOKEN, marker)
    programs.append(final)
    output_outer = " ⋄ ".join("⎕EC ⎕UCS " + _codes(p) for p in programs)
    serialized = output_outer.replace("⎕", "{quad}").replace("⋄", "{diamond}")
    if not serialized.isascii() or "'" in serialized or '"' in serialized:
        raise ValueError("EC_PROBE_NOT_ASCII_QUOTE_FREE")
    if serialized.replace("{diamond}", "⋄").replace("{quad}", "⎕") != output_outer:
        raise ValueError("EC_PROBE_SERIALIZATION_NOT_REVERSIBLE")
    lines[position] = (
        f"{match['prefix']}{len(output_outer)} 1 {len(output_outer)} "
        f"'{serialized}'{match['ending']}"
    )
    candidate = "".join(lines).encode("cp1252")
    receipt = {
        "schema": "APL_GERMAN_STAGE01_EC_PROBE_CANDIDATE_V1",
        "status": "GENERATED_NOT_NATIVE_VALIDATED",
        "stage01": "NOT_ACCEPTED",
        "source_commit": SOURCE_COMMIT,
        "function_count": 95,
        "chunk_count": 23,
        "chunk_records": base["chunk_records"],
        "probe_count": 7,
        "probes": codes,
        "marker_path": marker,
        "marker_token": FINAL_TOKEN,
        "base_candidate_sha256": base["candidate_sha256"],
        "candidate_sha256": hashlib.sha256(candidate).hexdigest(),
        "source_manifest_sha256": base["source_manifest_sha256"],
        "workspace_source_sha256": base["workspace_source_sha256"],
        "final_original_stage01_tests_executed": False,
        "original_stage01_acceptance_token_present": False,
        "import_program_sha256": [
            hashlib.sha256(p.encode("utf-8")).hexdigest() for p in programs[:23]
        ],
        "outer_lx_chars": len(output_outer),
        "program_count": len(programs),
    }
    return candidate, receipt


def main() -> int:
    p = argparse.ArgumentParser()
    for key in ("repo-root", "source", "candidate", "receipt", "marker"):
        p.add_argument("--" + key, required=True)
    a = p.parse_args()
    candidate = pathlib.Path(a.candidate)
    receipt = pathlib.Path(a.receipt)
    try:
        result, manifest = build_error_code_probe(
            pathlib.Path(a.source).read_bytes(), pathlib.Path(a.repo_root), a.marker
        )
        candidate.parent.mkdir(parents=True, exist_ok=True)
        receipt.parent.mkdir(parents=True, exist_ok=True)
        candidate.write_bytes(result)
        receipt.write_bytes((json.dumps(manifest, indent=2, ensure_ascii=False)+"\n").encode())
        print("EC_DIAGNOSTIC_GENERATED_NOT_NATIVE_VALIDATED", manifest["candidate_sha256"])
        return 0
    except Exception as exc:
        receipt.parent.mkdir(parents=True, exist_ok=True)
        receipt.write_bytes((json.dumps({
            "status": "GENERATION_FAILED", "stage01": "NOT_ACCEPTED",
            "error": f"{type(exc).__name__}:{exc}"
        }, ensure_ascii=False)+"\n").encode())
        print(f"EC_PROBE_GENERATION_FAILED: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
