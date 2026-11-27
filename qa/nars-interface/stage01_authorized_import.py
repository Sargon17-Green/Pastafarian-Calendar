#!/usr/bin/env python3
"""Fail-closed Stage 1 candidate: 95 locked APL functions in five-function ⎕EC chunks.

Generation alone NEVER accepts Stage 1; only an independent native runner
can verify the exact locked test marker after all 19 FX chunk receipts.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys

from chunked_fx_probe import ASSERT_HELPER, marker_write
from lx_workspace_probe import make_canary
from stage01_fx_prefix_probe import PREFIX_HELPER, nested_fx_expression
from stage01_authorized_source import (
    EXPECTED_TOTAL_FUNCTIONS, SOURCE_COMMIT, _codes,
    fx_definition_lines, load_locked_sources,
)

CHUNK_SIZE = 5
TAIL_START = 90
TAIL_CHUNK_SIZE = 1
EXPECTED_CHUNK_BOUNDARIES = tuple(range(CHUNK_SIZE, TAIL_START + 1, CHUNK_SIZE)) + tuple(range(TAIL_START + 1, EXPECTED_TOTAL_FUNCTIONS + 1))
STAGE01_MARKER = (
    "APL_GERMAN_STAGE01_NATIVE_PASS_V1"
    f"|SOURCE={SOURCE_COMMIT}|FILES=5|FX=95|TEST=STAGE01_PASS"
)


def build_stage01_chunked(raw: bytes, root: pathlib.Path, marker: str) -> tuple[bytes, dict]:
    locked = load_locked_sources(root)
    blocks = locked["blocks"]
    manifest = locked["manifest"]
    if len(blocks) != EXPECTED_TOTAL_FUNCTIONS or len(manifest["ordered_files"]) != 5:
        raise ValueError("STAGE01_SOURCE_LOCK_COUNT_INVALID")
    names = [block["name"] for block in blocks]
    if len(set(names)) != EXPECTED_TOTAL_FUNCTIONS or "RunStage01Tests" not in names:
        raise ValueError("STAGE01_LOCKED_FUNCTION_INVENTORY_INVALID")

    base, base_meta = make_canary(raw, marker, mode="display")
    path_obj = pathlib.PureWindowsPath(marker)
    chunk_programs = []
    chunk_records = []
    # The original final five-function expression was 79,231 APL characters.
    # Native evidence confirmed FX=90; it never confirmed FX=95.
    # Isolate each of the final five locked test functions without changing source.
    ranges = [(start, start + CHUNK_SIZE) for start in range(0, TAIL_START, CHUNK_SIZE)]
    ranges.extend((start, start + TAIL_CHUNK_SIZE)
                  for start in range(TAIL_START, EXPECTED_TOTAL_FUNCTIONS, TAIL_CHUNK_SIZE))
    if tuple(after for _, after in ranges) != EXPECTED_CHUNK_BOUNDARIES:
        raise ValueError("STAGE01_CHUNK_BOUNDARIES_CHANGED")
    for start, after in ranges:
        parts = []
        if start == 0:
            parts.extend([
                "⎕FX " + nested_fx_expression(PREFIX_HELPER),
                "⎕FX " + nested_fx_expression(ASSERT_HELPER),
                "Stage01PrefixCount←0",
            ])
        for block in blocks[start:after]:
            parts.append(
                f"(⎕UCS {_codes(block['name'])}) Stage01PrefixFix "
                + nested_fx_expression(fx_definition_lines(block))
            )
        token = (
            f"APL_GERMAN_STAGE01_CHUNK_V1|SOURCE={SOURCE_COMMIT}|FX=95"
            f"|AFTER={after:02d}|NAME={names[after - 1]}"
        )
        path = str(path_obj.with_name(f"{path_obj.stem}_after_{after:02d}.txt"))
        parts.extend([
            f"{after} Stage01ChunkAssert 0",
            marker_write(token, path),
        ])
        inner = " ⋄ ".join(parts)
        chunk_programs.append(inner)
        chunk_records.append({
            "after": after,
            "fx_in_chunk": after - start,
            "name": names[after - 1],
            "marker_path": path,
            "token": token,
            "expected_bytes": len(token.encode("ascii")),
            "token_sha256": hashlib.sha256(token.encode("ascii")).hexdigest(),
            "inner_chars": len(inner),
            "inner_sha256": hashlib.sha256(inner.encode("utf-8")).hexdigest(),
        })

    # Crucial: test execution and final marker must be in the SAME controlled
    # expression. If the original RunStage01Tests signals an APL error, the
    # marker expression that follows it must never execute.
    suite_paths = {name: str(path_obj.with_name(f"{path_obj.stem}_suite_{name}.txt"))
                   for name in ("start", "return", "ec", "et", "payload", "done")}
    start_token = f"APL_GERMAN_STAGE01_START|SOURCE={SOURCE_COMMIT}"
    final_program = ("95 Stage01ChunkAssert 0 ⋄ "
                     + marker_write(start_token, suite_paths["start"])
                     + " ⋄ RunStage01Tests ⋄ "
                     + marker_write(f"APL_GERMAN_STAGE01_RETURN|SOURCE={SOURCE_COMMIT}", suite_paths["return"])
                     + " ⋄ " + marker_write(STAGE01_MARKER, marker))
    def write_expr(expr, path):
        return f"(⍕({expr})) ⎕NAPPEND ((⎕UCS {_codes(path)}) ⎕NCREATE 0)"
    # EC[1] is status, EC[2] error type, EC[3] result OR error payload.
    # Archive the payload as display text, never interpret a successful result as an error.
    # Each receipt is separately controlled: a payload conversion/write error
    # must not suppress the EC status or the final receipt-attempt marker.
    receipt_programs = [
        write_expr("⊃QAS01FinalEC[1]", suite_paths["ec"]),
        write_expr("⊃QAS01FinalEC[2]", suite_paths["et"]),
        write_expr("⊃QAS01FinalEC[3]", suite_paths["payload"]),
        marker_write(f"APL_GERMAN_STAGE01_RECEIPTS_ATTEMPTED|SOURCE={SOURCE_COMMIT}", suite_paths["done"]),
    ]
    programs = chunk_programs + [final_program] + receipt_programs
    # Keep assignment inside a code-point-encoded controlled expression.
    # Only quad and diamond may appear as non-ASCII glyphs in the workspace LX.
    # The original test and final marker remain in the SAME inner EC.
    capture_program = "QAS01FinalEC←⎕EC ⎕UCS " + _codes(final_program)
    outer = " ⋄ ".join(["⎕EC ⎕UCS " + _codes(p) for p in chunk_programs]
                        + ["⎕EC ⎕UCS " + _codes(capture_program)]
                        + ["⎕EC ⎕UCS " + _codes(p) for p in receipt_programs])
    serialized = outer.replace("⎕", "{quad}").replace("⋄", "{diamond}")
    if serialized.replace("{diamond}", "⋄").replace("{quad}", "⎕") != outer:
        raise ValueError("STAGE01_LX_ESCAPE_NOT_REVERSIBLE")
    if not serialized.isascii() or "'" in serialized or '"' in serialized:
        raise ValueError("STAGE01_LX_NOT_ASCII_QUOTE_FREE")

    gid = base_meta["lx_new_global"]
    prefix = f":{gid}=V C "
    lines = base.decode("cp1252").splitlines(keepends=True)
    hits = 0
    for i, line in enumerate(lines):
        if line.startswith(prefix):
            ending = "\r\n" if line.endswith("\r\n") else "\n" if line.endswith("\n") else ""
            lines[i] = f":{gid}=V C {len(outer)} 1 {len(outer)} '{serialized}'" + ending
            hits += 1
    if hits != 1:
        raise ValueError("STAGE01_LX_GLOBAL_NOT_UNIQUE")
    candidate = "".join(lines).encode("cp1252")
    receipt = {
        "schema": "APL_GERMAN_STAGE01_CHUNKED_CANDIDATE_V1",
        "status": "GENERATED_NOT_NATIVE_VALIDATED",
        "native_executed": False,
        "stage01": "NOT_ACCEPTED",
        "source_commit": SOURCE_COMMIT,
        "source_file_count": 5,
        "source_manifest_sha256": manifest["manifest_sha256"],
        "function_count": EXPECTED_TOTAL_FUNCTIONS,
        "unique_function_count": len(set(names)),
        "function_names": names,
        "chunk_size": CHUNK_SIZE,
        "tail_start": TAIL_START,
        "tail_chunk_size": TAIL_CHUNK_SIZE,
        "chunk_count": len(chunk_records),
        "chunk_boundaries": list(EXPECTED_CHUNK_BOUNDARIES),
        "chunk_records": chunk_records,
        "test_entrypoint": "RunStage01Tests",
        "final_expression": "SAME_EC_AFTER_TEST",
        "marker_path": marker,
        "marker_token": STAGE01_MARKER,
        "suite_paths": suite_paths,
        "suite_start_token": start_token,
        "candidate_sha256": hashlib.sha256(candidate).hexdigest(),
        "workspace_source_sha256": base_meta["input_sha256"],
        "outer_lx_chars": len(outer),
        "outer_lx_sha256": hashlib.sha256(outer.encode("utf-8")).hexdigest(),
        "max_chunk_inner_chars": max(len(p) for p in programs),
        "final_inner_sha256": hashlib.sha256(final_program.encode("utf-8")).hexdigest(),
    }
    return candidate, receipt


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=pathlib.Path, required=True)
    parser.add_argument("--source", type=pathlib.Path, required=True)
    parser.add_argument("--candidate", type=pathlib.Path, required=True)
    parser.add_argument("--receipt", type=pathlib.Path, required=True)
    parser.add_argument("--marker", required=True)
    args = parser.parse_args()
    try:
        candidate, receipt = build_stage01_chunked(
            args.source.read_bytes(), args.repo_root.resolve(), args.marker
        )
        args.candidate.parent.mkdir(parents=True, exist_ok=True)
        args.receipt.parent.mkdir(parents=True, exist_ok=True)
        args.candidate.write_bytes(candidate)
        args.receipt.write_bytes((json.dumps(receipt, indent=2, ensure_ascii=False) + "\n").encode("utf-8"))
        print("STAGE01_CHUNKED_CANDIDATE_ONLY", receipt["candidate_sha256"])
        return 0
    except Exception as exc:
        args.receipt.parent.mkdir(parents=True, exist_ok=True)
        failure = {
            "schema": "APL_GERMAN_STAGE01_CHUNKED_CANDIDATE_V1",
            "status": "GENERATION_FAILED",
            "native_executed": False,
            "stage01": "NOT_ACCEPTED",
            "error": f"{type(exc).__name__}:{exc}",
        }
        args.receipt.write_bytes((json.dumps(failure, indent=2, ensure_ascii=False) + "\n").encode("utf-8"))
        print(failure["error"], file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
