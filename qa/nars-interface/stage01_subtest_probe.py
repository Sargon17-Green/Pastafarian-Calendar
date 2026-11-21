#!/usr/bin/env python3
"""Source-locked NARS2000 Stage 1 *subtest* diagnosis; never Stage 1 acceptance.

Reuses the exact 95-function chunk import proven by native markers, but
replaces its final RunStage01Tests call with individually checkpointed,
original, unchanged init/subtest calls. This is a separate diagnostic
candidate and can never emit the original Stage 1 acceptance token.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re
import sys

from chunked_fx_probe import marker_write
from stage01_chunked_import import build_stage01_chunked, STAGE01_MARKER
from stage01_import_workspace import SOURCE_COMMIT, _codes

PROBES = (
    "SourceLanguageCatalogInit",
    "MonsterBootstrapInit",
    "OracleInit",
    "Stage01FixturesInit",
    "RunStage01OwnershipTests",
    "RunStage01OracleStateTests",
    "RunStage01YearTests",
)
FINAL_TOKEN = "APL_GERMAN_SUBTEST_DIAGNOSTIC_EC_ENDED_NOT_STAGE01"
LX_ENTRY = re.compile(
    r"^(?P<prefix>:\d+=V C )(?P<first>\d+) 1 (?P<second>\d+) '(?P<serialized>[^']*)'(?P<ending>\r?\n|)$"
)


def build_diagnostic(raw: bytes, root: pathlib.Path, marker: str) -> tuple[bytes, dict]:
    candidate, receipt = build_stage01_chunked(raw, root, marker)
    if (receipt["source_commit"] != SOURCE_COMMIT or receipt["function_count"] != 95
            or receipt["chunk_count"] != 23 or receipt["marker_token"] != STAGE01_MARKER
            or receipt["final_expression"] != "SAME_EC_AFTER_TEST"):
        raise ValueError("LOCKED_STAGE01_BASE_CANDIDATE_INVALID")
    if not set(PROBES).issubset(set(receipt["function_names"])):
        raise ValueError("SUBTEST_FUNCTIONS_MISSING_FROM_LOCKED_SOURCE")
    lines = candidate.decode("cp1252").splitlines(keepends=True)
    match_pos = None
    original_outer = None
    for index, line in enumerate(lines):
        m = LX_ENTRY.fullmatch(line)
        if m is None:
            continue
        decoded = (m.group("serialized")
                   .replace("{diamond}", "⋄")
                   .replace("{quad}", "⎕"))
        if hashlib.sha256(decoded.encode("utf-8")).hexdigest() == receipt["outer_lx_sha256"]:
            if match_pos is not None:
                raise ValueError("AMBIGUOUS_STAGE01_LX_ENTRY")
            match_pos, original_outer = index, decoded
    if match_pos is None or original_outer is None:
        raise ValueError("STAGE01_LX_ENTRY_NOT_FOUND")
    units = original_outer.split(" ⋄ ")
    if len(units) != 24 or any(not x.startswith("⎕EC ⎕UCS ") for x in units):
        raise ValueError("STAGE01_CHUNKS_NOT_EXACTLY_23")
    if STAGE01_MARKER in original_outer:
        # The token is represented as numeric characters, never plaintext.
        raise ValueError("STAGE01_PLAINTEXT_ACCEPTANCE_TOKEN_UNEXPECTED")
    diagnostic = []
    records = []
    p = pathlib.PureWindowsPath(marker)
    for index, name in enumerate(PROBES, 1):
        tokens = []
        for kind in ("start", "end"):
            token = (f"APL_GERMAN_STAGE01_DIAG_V1|SOURCE={SOURCE_COMMIT}"
                     f"|PROBE={index:02d}|NAME={name}|PHASE={kind.upper()}")
            filename = str(p.with_name(f"{p.stem}_probe_{index:02d}_{kind}.txt"))
            tokens.append((token, filename))
        statement = ("95 Stage01ChunkAssert 0 ⋄ "
                     + marker_write(*tokens[0]) + " ⋄ "
                     + name + " ⋄ "
                     + marker_write(*tokens[1]))
        diagnostic.append("⎕EC ⎕UCS " + _codes(statement))
        rec = {"index": index, "name": name,
               "inner_sha256": hashlib.sha256(statement.encode("utf-8")).hexdigest()}
        for kind, (token, path) in zip(("start", "end"), tokens):
            rec[kind+"_path"] = path
            rec[kind+"_token"] = token
            rec[kind+"_sha256"] = hashlib.sha256(token.encode("ascii")).hexdigest()
        records.append(rec)
    last_program = "95 Stage01ChunkAssert 0 ⋄ " + marker_write(FINAL_TOKEN, marker)
    diagnostic.append("⎕EC ⎕UCS " + _codes(last_program))
    outer = " ⋄ ".join(units[:23] + diagnostic)
    serialized = outer.replace("⎕", "{quad}").replace("⋄", "{diamond}")
    if (not serialized.isascii() or "'" in serialized or '"' in serialized
            or serialized.replace("{diamond}", "⋄").replace("{quad}", "⎕") != outer):
        raise ValueError("DIAGNOSTIC_WORKSPACE_SERIALIZATION_INVALID")
    m = LX_ENTRY.fullmatch(lines[match_pos])
    assert m is not None
    new_line = (f"{m.group('prefix')}{len(outer)} 1 {len(outer)} "
                f"'{serialized}'{m.group('ending')}")
    lines[match_pos] = new_line
    result = "".join(lines).encode("cp1252")
    audit = {
        "schema": "APL_GERMAN_STAGE01_SUBTEST_DIAGNOSTIC_V1",
        "status": "GENERATED_NOT_NATIVE_VALIDATED",
        "stage01": "NOT_ACCEPTED",
        "native_executed": False,
        "source_commit": SOURCE_COMMIT,
        "function_count": 95,
        "chunk_count": 23,
        "chunk_records": receipt["chunk_records"],
        "probes": records,
        "probe_count": len(PROBES),
        "marker_path": marker,
        "marker_token": FINAL_TOKEN,
        "candidate_sha256": hashlib.sha256(result).hexdigest(),
        "base_candidate_sha256": receipt["candidate_sha256"],
        "source_manifest_sha256": receipt["source_manifest_sha256"],
        "workspace_source_sha256": receipt["workspace_source_sha256"],
        "final_original_stage01_tests_executed": False,
        "original_stage01_acceptance_token_present": False,
        "outer_lx_chars": len(outer),
        "program_count": len(units[:23] + diagnostic),
    }
    return result, audit


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--repo-root", type=pathlib.Path, required=True)
    p.add_argument("--source", type=pathlib.Path, required=True)
    p.add_argument("--candidate", type=pathlib.Path, required=True)
    p.add_argument("--receipt", type=pathlib.Path, required=True)
    p.add_argument("--marker", required=True)
    args = p.parse_args()
    try:
        result, audit = build_diagnostic(args.source.read_bytes(),
                                         args.repo_root.resolve(), args.marker)
        args.candidate.parent.mkdir(parents=True, exist_ok=True)
        args.receipt.parent.mkdir(parents=True, exist_ok=True)
        args.candidate.write_bytes(result)
        args.receipt.write_bytes((json.dumps(audit, indent=2, ensure_ascii=False)+"\n").encode("utf-8"))
        print("STAGE01_SUBTEST_DIAG_CANDIDATE_ONLY", audit["candidate_sha256"])
        return 0
    except Exception as exc:
        args.receipt.parent.mkdir(parents=True, exist_ok=True)
        failure = {"schema":"APL_GERMAN_STAGE01_SUBTEST_DIAGNOSTIC_V1",
                   "status":"GENERATION_FAILED","stage01":"NOT_ACCEPTED",
                   "native_executed":False,"error":f"{type(exc).__name__}:{exc}"}
        args.receipt.write_bytes((json.dumps(failure,indent=2,ensure_ascii=False)+"\n").encode("utf-8"))
        print(failure["error"], file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
