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


# Source-anchored diagnostic only. Each span preserves the original statements,
# including entire control blocks. The three final spans invoke the ORIGINAL
# subtests, so the first unfinished span identifies the next focused probe.
TRACE_GROUPS = (
    (172, 172), (173, 173), (174, 174), (175, 175),
    *((n, n) for n in range(177, 196)),
    (196, 198), (199, 201), (202, 208), (210, 215), (217, 219),
    (221, 223), (225, 228), (230, 230), (231, 231), (233, 244), (246, 250),
    (252, 259), (261, 261), (262, 262), (263, 264), (265, 267),
    (269, 276), (278, 288), (290, 292), (294, 302), (304, 310),
    (312, 316), (318, 321), (323, 323), (324, 324), (325, 325),
    (327, 327),
)
TRACE_HEADER = f"APL_GERMAN_STAGE01_TRACE_V1|SOURCE={SOURCE_COMMIT}|"
TRACE_HELPER = [
    "QAS01T token;unused",
    "  unused←token ⎕NAPPEND QAS01TraceTie",
]


# Diagnostic only: separate native EC receipts for the exact line 231 witness.
POST_STIR_PROBES = (
    ("actual", "PostStirSavedSum (⊂1x 2x 3x 4x 5x 6x) 1"),
    ("rank", "⍴⍴PostStirSavedSum (⊂1x 2x 3x 4x 5x 6x) 1"),
    ("type", "⎕DR PostStirSavedSum (⊂1x 2x 3x 4x 5x 6x) 1"),
    ("match", "FIX_POST_STIR_A1_SUM≡PostStirSavedSum (⊂1x 2x 3x 4x 5x 6x) 1"),
    ("explicit", "PostStirSavedSum ((⊂1x 2x 3x 4x 5x 6x),(⊂1))"),
    ("assert", "AssertEqual (⊂FIX_POST_STIR_A1_SUM) (⊂PostStirSavedSum (⊂1x 2x 3x 4x 5x 6x) 1) (⊂'Die A1-Lesart speichert Summe plus 149 mal Rührnummer als einen einzigen Wert')"),
)
POST_STIR_KEYS = tuple(f"probe_{name}_{slot}" for name, _ in POST_STIR_PROBES for slot in ("ec", "et", "payload"))


def build_trace_definition(block: dict) -> tuple[list[str], list[str]]:
    if (block["name"], block["path"], block["start_line"], block["end_line"]) != (
        "RunStage01Tests", "test/stage01_tests.apl", 171, 328
    ):
        raise ValueError("TRACE_SOURCE_ANCHOR_MISMATCH")
    original = fx_definition_lines(block)
    if not original[0].startswith("RunStage01Tests;"):
        raise ValueError("TRACE_HEADER_MISMATCH")
    starts = {a for a, _ in TRACE_GROUPS}
    ends = {b for _, b in TRACE_GROUPS}
    covered = [n for a, b in TRACE_GROUPS for n in range(a, b + 1)]
    actual = [171 + i for i, line in enumerate(original[1:], 1) if line.strip()]
    if sorted(covered) != actual or len(covered) != len(set(covered)):
        raise ValueError("TRACE_SPAN_COVERAGE_MISMATCH")
    traced = ["QAS01TraceMain" + original[0][len("RunStage01Tests"):]]
    tokens = []
    for n, line in enumerate(original[1:], 172):
        if n in starts:
            token = f"{n:04d}S"
            traced.append(f"  QAS01T '{token}'")
            tokens.append(token)
        traced.append(line)
        if n in ends:
            token = f"{n:04d}E"
            traced.append(f"  QAS01T '{token}'")
            tokens.append(token)
    restored = [original[0]] + [line for line in traced[1:] if not line.startswith("  QAS01T '")]
    if restored != original:
        raise ValueError("TRACE_ORIGINAL_STATEMENT_CHANGED")
    return traced, tokens


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
                   for name in ("start", "return", "ec", "et", "payload", "done",
                                "trace_helper_fx", "trace_main_fx", "trace_run_fx",
                                "trace", "trace_ec", "trace_et", "trace_payload",
                                "trace_def_count", "trace_compile_ec", "trace_compile_et", "trace_compile_payload") + POST_STIR_KEYS}
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
    ]
    # Do not overwrite or modify any original function. Only after original
    # EC=0, run a separately named diagnostic copy with unchanged statements.
    # Its initializers run again; it is not independent acceptance evidence.
    traced, trace_tokens = build_trace_definition(next(b for b in blocks if b["name"] == "RunStage01Tests"))
    # Assemble the exact nested vector in bounded fragments. Compile with a
    # short expression and capture compiler EC separately from invocation EC.
    trace_parts = []
    for i in range(0, len(traced), 16):
        lines = traced[i:i + 16]
        expr = nested_fx_expression(lines)
        if len(lines) == 1:
            expr = "(⊂" + expr + ")"
        trace_parts.append(("QAS01TraceDef←" if i == 0 else
                            "QAS01TraceDef←QAS01TraceDef,") + expr)
    trace_runner = [
        "QAS01TraceRun",
        "  :If 0=⊃QAS01FinalEC[1]",
        f"      QAS01TraceTie←(⎕UCS {_codes(suite_paths['trace'])}) ⎕NCREATE 0",
        f"      QAS01T ⎕UCS {_codes(TRACE_HEADER)}",
        "      :If 'QAS01TraceMain'≡QAS01TraceName",
        "          QAS01DiagEC←⎕EC 'QAS01TraceMain'",
        "      :EndIf",
        "  :EndIf",
    ]
    diagnostic_programs = [
        write_expr("⎕FX " + nested_fx_expression(TRACE_HELPER), suite_paths["trace_helper_fx"]),
        "QAS01TraceName←''",
        *trace_parts,
        write_expr("⍴QAS01TraceDef", suite_paths["trace_def_count"]),
        "QAS01TraceCompileEC←⎕EC 'QAS01TraceName←⎕FX QAS01TraceDef'",
        write_expr("⊃QAS01TraceCompileEC[1]", suite_paths["trace_compile_ec"]),
        write_expr("⊃QAS01TraceCompileEC[2]", suite_paths["trace_compile_et"]),
        write_expr("⊃QAS01TraceCompileEC[3]", suite_paths["trace_compile_payload"]),
        write_expr("QAS01TraceName", suite_paths["trace_main_fx"]),
        write_expr("⎕FX " + nested_fx_expression(trace_runner), suite_paths["trace_run_fx"]),
        "QAS01TraceRun",
        write_expr("⊃QAS01DiagEC[1]", suite_paths["trace_ec"]),
        write_expr("⊃QAS01DiagEC[2]", suite_paths["trace_et"]),
        write_expr("⊃QAS01DiagEC[3]", suite_paths["trace_payload"]),
    ]
    # No probe can write the acceptance marker or alter any locked function.
    # Capture each EC independently, so failure in one witness cannot hide the next.
    probe_programs = []
    for index, (name, expression) in enumerate(POST_STIR_PROBES):
        var = f"QAS01Probe{index}"
        probe_programs.append(var + "←⎕EC ⎕UCS " + _codes(expression))
        for slot, key in enumerate(("ec", "et", "payload"), 1):
            probe_programs.append(write_expr(f"⊃{var}[{slot}]", suite_paths[f"probe_{name}_{key}"]))
    receipt_programs += diagnostic_programs + probe_programs + [
        marker_write(f"APL_GERMAN_STAGE01_RECEIPTS_ATTEMPTED|SOURCE={SOURCE_COMMIT}", suite_paths["done"]),
    ]
    programs = chunk_programs + [final_program] + receipt_programs
    if any(len(program) >= 65000 for program in programs):
        raise ValueError("TRACE_OR_IMPORT_PROGRAM_TOO_LONG")
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
        "trace_header": TRACE_HEADER,
        "trace_tokens": trace_tokens,
        "trace_groups": [list(pair) for pair in TRACE_GROUPS],
        "trace_definition_lines": len(traced),
        "trace_assembly_chunks": len(trace_parts),
        "trace_definition_sha256": hashlib.sha256("\n".join(traced).encode("utf-8")).hexdigest(),
        "trace_diagnostic_only": True,
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
