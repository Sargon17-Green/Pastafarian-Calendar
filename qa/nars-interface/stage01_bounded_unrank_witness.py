#!/usr/bin/env python3
"""Source-locked QA witness for the Stage1 BoundedUnrank DOMAIN ERROR.

This candidate loads the exact 95 locked source functions in 23 native NARS
chunks, then calls BoundedUnrank and a QA-instrumented source copy. It never
runs RunStage01Tests and can never emit the Stage1 acceptance token.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys

from chunked_fx_probe import marker_write
from stage01_chunked_import import build_stage01_chunked
from stage01_fx_prefix_probe import nested_fx_expression
from stage01_import_workspace import (
    SOURCE_COMMIT, _codes, fx_definition_lines, load_locked_sources,
)
from stage01_subtest_probe import LX_ENTRY

ALIAS = "QABoundedUnrankTrace"
FINAL = "APL_GERMAN_BOUNDED_UNRANK_WITNESS_COMPLETE_NOT_STAGE01"
TRACE_STEPS = [
    {"id": 1, "source_line": 389, "phase": "after", "name": "ARGS_ASSIGNED"},
    {"id": 2, "source_line": 390, "phase": "after", "name": "DP_BUILT"},
    {"id": 3, "source_line": 393, "phase": "after", "name": "RANK_GUARD_PASSED"},
    {"id": 4, "source_line": 394, "phase": "after", "name": "OUTPUT_INITIALIZED"},
    {"id": 5, "source_line": 395, "phase": "after", "name": "OUTER_LOOP_ENTERED"},
    {"id": 6, "source_line": 396, "phase": "after", "name": "SUFFIX_SLOTS_SET"},
    {"id": 7, "source_line": 397, "phase": "after", "name": "INNER_LOOP_ENTERED"},
    {"id": 8, "source_line": 400, "phase": "after", "name": "REMAINING_GUARD_PASSED"},
    {"id": 9, "source_line": 401, "phase": "after", "name": "DP_COUNT_READ"},
    {"id": 10, "source_line": 402, "phase": "before", "name": "RANK_COMPARISON"},
    {"id": 11, "source_line": 403, "phase": "after", "name": "RANK_DECREMENTED"},
    {"id": 12, "source_line": 405, "phase": "after", "name": "OUTPUT_APPENDED"},
    {"id": 13, "source_line": 406, "phase": "after", "name": "REMAINING_DECREMENTED"},
    {"id": 14, "source_line": 407, "phase": "before", "name": "BEFORE_LEAVE"},
    {"id": 15, "source_line": 409, "phase": "after", "name": "INNER_LOOP_EXITED"},
    {"id": 16, "source_line": 410, "phase": "after", "name": "OUTER_LOOP_EXITED"},
    {"id": 17, "source_line": 411, "phase": "after", "name": "RESULT_ASSIGNED"},
]
INPUT = [12, 3, 4, 4, 1]
EXPECTED_FIXTURE = "FIX_BOUNDED_444"


def _write_expr(expression: str, path: str) -> str:
    return (
        f"(⍕({expression})) ⎕NAPPEND "
        f"((⎕UCS {_codes(path)}) ⎕NCREATE 0)"
    )


def instrument_bounded_unrank(block: dict) -> tuple[list[str], dict]:
    """Rename the exact locked function and add global trace checkpoints only."""
    if (block.get("name") != "BoundedUnrank"
            or block.get("path") != "src/normative_oracle.apl"
            or block.get("start_line") != 388
            or block.get("end_line") != 412):
        raise ValueError("BOUNDED_UNRANK_SOURCE_LOCATION_CHANGED")

    source = fx_definition_lines(block)
    expected = [
        "z←BoundedUnrank args;total;slots;lo;hi;rank;out;position;x;count;rem;dp;suffixSlots",
        "  total←args[1] ⋄ slots←args[2] ⋄ lo←args[3] ⋄ hi←args[4] ⋄ rank←args[5]",
        "  dp←BuildBoundedDP total slots lo hi",
        "  :If (rank<1)∨rank>dp[slots+1;total+1]",
        "      ⎕ERROR 'Interner Fehler der normativen Stufe-1-Referenz.'",
        "  :EndIf",
        "  out←⍬ ⋄ rem←total",
        "  :For position :In ⍳slots",
        "      suffixSlots←slots-position",
        "      :For x :In (lo-1)+⍳((hi-lo)+1)",
        "          :If rem-x<0",
        "              :Continue",
        "          :EndIf",
        "          count←dp[suffixSlots+1;(rem-x)+1]",
        "          :If rank>count",
        "              rank←rank-count",
        "          :Else",
        "              out←out,x",
        "              rem←rem-x",
        "              :Leave",
        "          :EndIf",
        "      :EndFor",
        "  :EndFor",
        "  z←out",
    ]
    if source != expected:
        raise ValueError("BOUNDED_UNRANK_SOURCE_ANCHOR_CHANGED")

    renamed = list(source)
    renamed[0] = renamed[0].replace("BoundedUnrank", ALIAS, 1)

    after = {
        1: [
            "QABoundedTraceLog←QABoundedTraceLog,1",
            "QABoundedTraceArgs←args",
            "QABoundedTraceRank←rank",
        ],
        2: [
            "QABoundedTraceLog←QABoundedTraceLog,2",
            "QABoundedTraceDPShape←⍴dp",
            "QABoundedTraceDPType←⎕DR dp",
            "QABoundedTraceDPValues←,dp",
        ],
        5: ["QABoundedTraceLog←QABoundedTraceLog,3"],
        6: [
            "QABoundedTraceLog←QABoundedTraceLog,4",
            "QABoundedTraceOut←out",
            "QABoundedTraceRem←rem",
        ],
        7: ["QABoundedTraceLog←QABoundedTraceLog,5"],
        8: [
            "QABoundedTraceLog←QABoundedTraceLog,6",
            "QABoundedTraceLoopState←QABoundedTraceLoopState,position,suffixSlots,rem",
        ],
        9: ["QABoundedTraceLog←QABoundedTraceLog,7"],
        12: ["QABoundedTraceLog←QABoundedTraceLog,8"],
        13: [
            "QABoundedTraceLog←QABoundedTraceLog,9",
            "QABoundedTraceCandidateState←QABoundedTraceCandidateState,position,suffixSlots,rem,x,count,rank",
        ],
        15: [
            "QABoundedTraceLog←QABoundedTraceLog,11",
            "QABoundedTraceRank←rank",
        ],
        17: [
            "QABoundedTraceLog←QABoundedTraceLog,12",
            "QABoundedTraceOut←out",
        ],
        18: [
            "QABoundedTraceLog←QABoundedTraceLog,13",
            "QABoundedTraceRem←rem",
        ],
        21: ["QABoundedTraceLog←QABoundedTraceLog,15"],
        22: ["QABoundedTraceLog←QABoundedTraceLog,16"],
        23: [
            "QABoundedTraceLog←QABoundedTraceLog,17",
            "QABoundedTraceResult←z",
        ],
    }
    before = {
        14: ["QABoundedTraceLog←QABoundedTraceLog,10"],
        19: ["QABoundedTraceLog←QABoundedTraceLog,14"],
    }

    trace: list[str] = []
    inserted: list[str] = []
    for index, line in enumerate(renamed):
        indent = line[:len(line) - len(line.lstrip())]
        for statement in before.get(index, []):
            added = indent + statement
            trace.append(added)
            inserted.append(added)
        trace.append(line)
        for statement in after.get(index, []):
            added = indent + statement
            trace.append(added)
            inserted.append(added)

    remaining = {}
    for line in inserted:
        remaining[line] = remaining.get(line, 0) + 1
    recovered = []
    for line in trace:
        if remaining.get(line, 0):
            remaining[line] -= 1
        else:
            recovered.append(line)
    if recovered != renamed or any(remaining.values()):
        raise ValueError("BOUNDED_UNRANK_TRACE_CHANGED_SOURCE_STATEMENTS")

    metadata = {
        "source_function": "BoundedUnrank",
        "source_path": block["path"],
        "source_lines": [block["start_line"], block["end_line"]],
        "alias": ALIAS,
        "source_definition_sha256": hashlib.sha256(
            "\n".join(source).encode("utf-8")
        ).hexdigest(),
        "trace_definition_sha256": hashlib.sha256(
            "\n".join(trace).encode("utf-8")
        ).hexdigest(),
        "source_statements_preserved": True,
        "instrumentation_count": len(inserted),
        "steps": TRACE_STEPS,
    }
    return trace, metadata


PAREN_ALIAS = "QABoundedUnrankParenProbe"


def parenthesized_probe_definition(block: dict) -> tuple[list[str], dict]:
    """Create a QA-only one-statement counterfactual; never edit source."""
    source = fx_definition_lines(block)
    if (len(source) != 24 or source[10].strip() != ":If rem-x<0"
            or block.get("start_line") != 388 or block.get("end_line") != 412):
        raise ValueError("BOUNDED_UNRANK_PRECEDENCE_PROBE_ANCHOR_CHANGED")
    probe = list(source)
    probe[0] = probe[0].replace("BoundedUnrank", PAREN_ALIAS, 1)
    probe[10] = probe[10].replace(":If rem-x<0", ":If (rem-x)<0", 1)
    normalized = list(probe)
    normalized[0] = source[0]
    changed = [i for i, (left, right) in enumerate(zip(source, normalized)) if left != right]
    if changed != [10]:
        raise ValueError("BOUNDED_UNRANK_PRECEDENCE_PROBE_NOT_ONE_LINE")
    metadata = {
        "source_function": "BoundedUnrank",
        "source_path": block["path"],
        "source_lines": [block["start_line"], block["end_line"]],
        "qa_alias": PAREN_ALIAS,
        "changed_source_line": 398,
        "original_statement": ":If rem-x<0",
        "probe_statement": ":If (rem-x)<0",
        "source_definition_sha256": hashlib.sha256(
            "\n".join(source).encode("utf-8")
        ).hexdigest(),
        "probe_definition_sha256": hashlib.sha256(
            "\n".join(probe).encode("utf-8")
        ).hexdigest(),
        "source_statements_changed": 1,
        "only_semantic_change_is_explicit_parenthesization": True,
        "production_source_modified": False,
    }
    return probe, metadata


def _decode_chunked_candidate(
    data: bytes,
    expected_program_count: int | None = None,
    expected_outer_sha256: str | None = None,
):
    lines = data.decode("cp1252").splitlines(keepends=True)
    found = []
    for index, line in enumerate(lines):
        match = LX_ENTRY.fullmatch(line)
        if match is None:
            continue
        outer = (match["serialized"]
                 .replace("{diamond}", "⋄")
                 .replace("{quad}", "⎕"))
        if (expected_outer_sha256 is not None
                and hashlib.sha256(outer.encode("utf-8")).hexdigest() != expected_outer_sha256):
            continue
        units = outer.split(" ⋄ ")
        if expected_program_count is not None and len(units) != expected_program_count:
            continue
        if expected_program_count is None and expected_outer_sha256 is None and len(units) not in (24, 26):
            continue
        if any(not u.startswith("⎕EC ⎕UCS ") for u in units):
            continue
        found.append((index, match, outer, units))
    if len(found) != 1:
        raise ValueError("LOCKED_95_FX_LX_ENTRY_NOT_UNIQUE")
    pos, match, outer, units = found[0]
    programs = [
        "".join(chr(int(n)) for n in unit[len("⎕EC ⎕UCS "):].split())
        for unit in units
    ]
    return lines, pos, match, programs


def build_bounded_unrank_witness(
    raw: bytes, repo_root: pathlib.Path, marker: str
) -> tuple[bytes, dict]:
    root = pathlib.Path(repo_root).resolve()
    base, base_receipt = build_stage01_chunked(raw, root, marker)
    if (base_receipt["source_commit"] != SOURCE_COMMIT
            or base_receipt["function_count"] != 95
            or base_receipt["chunk_count"] != 23
            or len(base_receipt["chunk_records"]) != 23
            or base_receipt["final_expression"] != "SAME_EC_AFTER_TEST"):
        raise ValueError("LOCKED_95_FX_BASE_INVALID")

    lines, pos, match, old_programs = _decode_chunked_candidate(base, expected_program_count=24, expected_outer_sha256=base_receipt["outer_lx_sha256"])
    for index, chunk in enumerate(base_receipt["chunk_records"]):
        if hashlib.sha256(old_programs[index].encode("utf-8")).hexdigest() != chunk["inner_sha256"]:
            raise ValueError("LOCKED_95_FX_CHUNK_PROGRAM_HASH_MISMATCH")
    if (hashlib.sha256(old_programs[23].encode("utf-8")).hexdigest()
            != base_receipt["final_inner_sha256"]):
        raise ValueError("ORIGINAL_STAGE01_FINAL_PROGRAM_HASH_MISMATCH")
    if "RunStage01Tests" not in old_programs[23]:
        raise ValueError("ORIGINAL_STAGE01_FINAL_PROGRAM_NOT_FOUND")

    locked = load_locked_sources(root)
    blocks = [b for b in locked["blocks"] if b["name"] == "BoundedUnrank"]
    if len(blocks) != 1:
        raise ValueError("BOUNDED_UNRANK_SOURCE_NOT_UNIQUE")
    trace_definition, trace_meta = instrument_bounded_unrank(blocks[0])
    paren_definition, paren_meta = parenthesized_probe_definition(blocks[0])
    manifest_sha = locked["manifest"]["manifest_sha256"]
    if manifest_sha != base_receipt["source_manifest_sha256"]:
        raise ValueError("SOURCE_MANIFEST_MISMATCH")

    p = pathlib.PureWindowsPath(marker)
    paths = {
        key: str(p.with_name(p.stem + "_bounded_unrank_" + suffix + ".txt"))
        for key, suffix in {
            "compile_marker": "compile",
            "compile_name_code": "compile_name_code",
            "paren_compile_marker": "paren_compile",
            "paren_compile_name_code": "paren_compile_name_code",
            "start_marker": "start",
            "captured_marker": "captured",
            "run_ec_code": "run_ec_code",
            "run_ec_message_codes": "run_ec_message_codes",
            "output_ec_code": "output_ec_code",
            "output_ec_message_codes": "output_ec_message_codes",
            "original_ec": "original_ec",
            "original_message_codes": "original_message_codes",
            "paren_ec_code": "paren_ec_code",
            "paren_error_type": "paren_error_type",
            "paren_message_codes": "paren_message_codes",
            "paren_result": "paren_result",
            "trace_ec": "trace_ec",
            "trace_message_codes": "trace_message_codes",
            "expected_values": "expected_values",
            "expected_shape": "expected_shape",
            "expected_rank": "expected_rank",
            "expected_type": "expected_type",
            "count_values": "count_values",
            "count_rank": "count_rank",
            "count_type": "count_type",
            "trace_args": "trace_args",
            "trace_dp_shape": "trace_dp_shape",
            "trace_dp_values": "trace_dp_values",
            "trace_dp_type": "trace_dp_type",
            "trace_log": "trace_log",
            "trace_loop_state": "trace_loop_state",
            "trace_candidate_state": "trace_candidate_state",
            "trace_out": "trace_out",
            "trace_rem": "trace_rem",
            "trace_rank": "trace_rank",
            "trace_result": "trace_result",
        }.items()
    }

    compile_token = (
        f"APL_GERMAN_BOUNDED_UNRANK_V1|SOURCE={SOURCE_COMMIT}"
        f"|FUNCTION={ALIAS}|PHASE=COMPILED_DIAGNOSTIC"
    )
    start_token = (
        f"APL_GERMAN_BOUNDED_UNRANK_V1|SOURCE={SOURCE_COMMIT}"
        "|PHASE=START"
    )
    captured_token = (
        f"APL_GERMAN_BOUNDED_UNRANK_V1|SOURCE={SOURCE_COMMIT}"
        "|PHASE=CAPTURED_NOT_PASS"
    )
    paren_compile_token = (
        f"APL_GERMAN_BOUNDED_UNRANK_V1|SOURCE={SOURCE_COMMIT}"
        f"|FUNCTION={PAREN_ALIAS}|PATCH_LINE=398|PHASE=COMPILED_QA_COUNTERFACTUAL"
    )
    init_names = [
        "SourceLanguageCatalogInit",
        "MonsterBootstrapInit",
        "OracleInit",
        "Stage01FixturesInit",
    ]
    init_markers = []
    for index, name in enumerate(init_names, 1):
        token = (
            f"APL_GERMAN_BOUNDED_UNRANK_V1|SOURCE={SOURCE_COMMIT}"
            f"|INIT={index:02d}|NAME={name}|PHASE=END"
        )
        path = str(p.with_name(f"{p.stem}_bounded_unrank_init_{index:02d}.txt"))
        init_markers.append({"index": index, "name": name, "token": token, "path": path})

    phase_names = [
        "EXPECTED_FIXTURE_CAPTURED",
        "BOUNDED_COUNT_CAPTURED",
        "ORIGINAL_CALL_CAPTURED",
        "TRACE_CALL_CAPTURED",
        "PAREN_CALL_CAPTURED",
    ]
    phase_markers = []
    for index, name in enumerate(phase_names, 1):
        token = (
            f"APL_GERMAN_BOUNDED_UNRANK_V1|SOURCE={SOURCE_COMMIT}"
            f"|PHASE={name}"
        )
        path = str(p.with_name(f"{p.stem}_bounded_unrank_phase_{index:02d}.txt"))
        phase_markers.append({"index": index, "name": name, "token": token, "path": path})

    trace_name_var = "QABoundedTraceName"
    paren_name_var = "QABoundedParenName"
    compile_program = (
        "95 Stage01ChunkAssert 0 ⋄ "
        + f"{trace_name_var}←⎕FX {nested_fx_expression(trace_definition)}"
        + " ⋄ "
        + f"{paren_name_var}←⎕FX {nested_fx_expression(paren_definition)}"
        + " ⋄ "
        + _write_expr(
            f"{trace_name_var}≡⎕UCS {_codes(ALIAS)}",
            paths["compile_name_code"],
        )
        + " ⋄ "
        + _write_expr(
            f"{paren_name_var}≡⎕UCS {_codes(PAREN_ALIAS)}",
            paths["paren_compile_name_code"],
        )
        + " ⋄ "
        + marker_write(compile_token, paths["compile_marker"])
        + " ⋄ "
        + marker_write(paren_compile_token, paths["paren_compile_marker"])
    )

    init = (
        "QABoundedTraceLog←0 ⋄ QABoundedTraceArgs←0 ⋄ "
        "QABoundedTraceDPShape←0 ⋄ QABoundedTraceDPType←0 ⋄ "
        "QABoundedTraceDPValues←0 ⋄ QABoundedTraceLoopState←0 ⋄ "
        "QABoundedTraceCandidateState←0 ⋄ QABoundedTraceOut←0 ⋄ "
        "QABoundedTraceRem←0 ⋄ QABoundedTraceRank←0 ⋄ "
        "QABoundedTraceResult←0 ⋄ QABoundedExpected←0 ⋄ "
        "QABoundedExpectedShape←0 ⋄ QABoundedExpectedRank←0 ⋄ "
        "QABoundedExpectedType←0 ⋄ QABoundedCountProbe←0 ⋄ "
        "QABoundedCountRank←0 ⋄ QABoundedCountType←0 ⋄ "
        "QABoundedOriginalCode←999 ⋄ QABoundedOriginalMessageCodes←0 ⋄ "
        "QABoundedTraceCode←999 ⋄ QABoundedTraceMessageCodes←0 ⋄ "
        "QABoundedParenCode←999 ⋄ QABoundedParenResult←0 ⋄ QABoundedParenMessageCodes←0 ⋄ "
        "QABoundedRunCode←999 ⋄ QABoundedRunMessageCodes←0 ⋄ "
        "QABoundedOutputCode←999 ⋄ QABoundedOutputMessageCodes←0"
    )
    original_call = "BoundedUnrank 12 3 4 4 1"
    trace_call = f"{ALIAS} 12 3 4 4 1"

    run_body_parts = []
    for item in init_markers:
        run_body_parts.append(item["name"])
        run_body_parts.append(marker_write(item["token"], item["path"]))
    run_body_parts.extend([
        "QABoundedTraceLog←0 ⋄ QABoundedTraceArgs←0 ⋄ "
        "QABoundedTraceDPShape←0 ⋄ QABoundedTraceDPType←0 ⋄ "
        "QABoundedTraceDPValues←0 ⋄ QABoundedTraceLoopState←0 ⋄ "
        "QABoundedTraceCandidateState←0 ⋄ QABoundedTraceOut←0 ⋄ "
        "QABoundedTraceRem←0 ⋄ QABoundedTraceRank←0 ⋄ "
        "QABoundedTraceResult←0 ⋄ QABoundedExpected←0 ⋄ "
        "QABoundedExpectedShape←0 ⋄ QABoundedExpectedRank←0 ⋄ "
        "QABoundedExpectedType←0 ⋄ QABoundedCountProbe←0 ⋄ "
        "QABoundedCountRank←0 ⋄ QABoundedCountType←0 ⋄ "
        "QABoundedOriginalCode←999 ⋄ QABoundedOriginalMessageCodes←0 ⋄ "
        "QABoundedTraceCode←999 ⋄ QABoundedTraceMessageCodes←0 ⋄ "
        "QABoundedParenCode←999 ⋄ QABoundedParenResult←0 ⋄ QABoundedParenMessageCodes←0",
        "QABoundedExpected←FIX_BOUNDED_444 ⋄ "
        "QABoundedExpectedShape←⍴FIX_BOUNDED_444 ⋄ "
        "QABoundedExpectedRank←⍴⍴FIX_BOUNDED_444 ⋄ "
        "QABoundedExpectedType←⎕DR FIX_BOUNDED_444",
        marker_write(phase_markers[0]["token"], phase_markers[0]["path"]),
        "QABoundedCountProbe←BoundedCount 12 3 4 4 ⋄ "
        "QABoundedCountRank←⍴⍴QABoundedCountProbe ⋄ "
        "QABoundedCountType←⎕DR QABoundedCountProbe",
        marker_write(phase_markers[1]["token"], phase_markers[1]["path"]),
        f"QABoundedOriginalEC←⎕EC ⎕UCS {_codes(original_call)} ⋄ "
        "QABoundedOriginalCode←QABoundedOriginalEC[1] ⋄ "
        "QABoundedOriginalMessageCodes←⎕UCS ⊃QABoundedOriginalEC[3]",
        marker_write(phase_markers[2]["token"], phase_markers[2]["path"]),
        f"QABoundedTraceEC←⎕EC ⎕UCS {_codes(trace_call)} ⋄ "
        "QABoundedTraceCode←QABoundedTraceEC[1] ⋄ "
        "QABoundedTraceMessageCodes←⎕UCS ⊃QABoundedTraceEC[3]",
        marker_write(phase_markers[3]["token"], phase_markers[3]["path"]),
        f"QABoundedParenEC←⎕EC ⎕UCS {_codes(PAREN_ALIAS + ' 12 3 4 4 1')} ⋄ "
        "QABoundedParenCode←QABoundedParenEC[1] ⋄ "
        "QABoundedParenErrorType←⊃QABoundedParenEC[2] ⋄ "
        "QABoundedParenResult←⊃QABoundedParenEC[3] ⋄ "
        "QABoundedParenMessageCodes←(0=QABoundedParenCode)/⎕UCS ⍕⊃QABoundedParenEC[3]",
        marker_write(phase_markers[4]["token"], phase_markers[4]["path"]),
    ])
    run_body = " ⋄ ".join(run_body_parts)

    output_body_parts = [
        _write_expr("QABoundedRunCode", paths["run_ec_code"]),
        _write_expr("0,QABoundedRunMessageCodes", paths["run_ec_message_codes"]),
        _write_expr("QABoundedOriginalCode", paths["original_ec"]),
        _write_expr("0,QABoundedOriginalMessageCodes", paths["original_message_codes"]),
        _write_expr("QABoundedTraceCode", paths["trace_ec"]),
        _write_expr("0,QABoundedTraceMessageCodes", paths["trace_message_codes"]),
        _write_expr("QABoundedParenCode", paths["paren_ec_code"]),
        _write_expr("0,QABoundedParenErrorType", paths["paren_error_type"]),
        _write_expr("0,QABoundedParenMessageCodes", paths["paren_message_codes"]),
        _write_expr("0,QABoundedParenResult", paths["paren_result"]),
        _write_expr("0,QABoundedExpected", paths["expected_values"]),
        _write_expr("0,QABoundedExpectedShape", paths["expected_shape"]),
        _write_expr("QABoundedExpectedRank", paths["expected_rank"]),
        _write_expr("QABoundedExpectedType", paths["expected_type"]),
        _write_expr("0,QABoundedCountProbe", paths["count_values"]),
        _write_expr("QABoundedCountRank", paths["count_rank"]),
        _write_expr("QABoundedCountType", paths["count_type"]),
        _write_expr("0,QABoundedTraceArgs", paths["trace_args"]),
        _write_expr("0,QABoundedTraceDPShape", paths["trace_dp_shape"]),
        _write_expr("0,QABoundedTraceDPValues", paths["trace_dp_values"]),
        _write_expr("QABoundedTraceDPType", paths["trace_dp_type"]),
        _write_expr("QABoundedTraceLog", paths["trace_log"]),
        _write_expr("QABoundedTraceLoopState", paths["trace_loop_state"]),
        _write_expr("QABoundedTraceCandidateState", paths["trace_candidate_state"]),
        _write_expr("0,QABoundedTraceOut", paths["trace_out"]),
        _write_expr("QABoundedTraceRem", paths["trace_rem"]),
        _write_expr("QABoundedTraceRank", paths["trace_rank"]),
        _write_expr("0,QABoundedTraceResult", paths["trace_result"]),
    ]
    output_body = " ⋄ ".join(output_body_parts)
    run_program = " ⋄ ".join([
        "95 Stage01ChunkAssert 0",
        marker_write(start_token, paths["start_marker"]),
        init,
        f"QABoundedRunEC←⎕EC ⎕UCS {_codes(run_body)}",
        "QABoundedRunCode←QABoundedRunEC[1] ⋄ "
        "QABoundedRunMessageCodes←⎕UCS ⊃QABoundedRunEC[3]",
        f"QABoundedOutputEC←⎕EC ⎕UCS {_codes(output_body)}",
        "QABoundedOutputCode←QABoundedOutputEC[1] ⋄ "
        "QABoundedOutputMessageCodes←⎕UCS ⊃QABoundedOutputEC[3]",
        _write_expr("QABoundedOutputCode", paths["output_ec_code"]),
        _write_expr("0,QABoundedOutputMessageCodes", paths["output_ec_message_codes"]),
        marker_write(captured_token, paths["captured_marker"]),
    ])
    final_program = "95 Stage01ChunkAssert 0 ⋄ " + marker_write(FINAL, marker)
    programs = old_programs[:23] + [compile_program, run_program, final_program]
    if len(programs) != 26:
        raise ValueError("BOUNDED_UNRANK_PROGRAM_COUNT_INVALID")
    if any("RunStage01Tests" in p for p in programs[23:]):
        raise ValueError("STAGE01_ENTRYPOINT_MUST_NOT_RUN_IN_WITNESS")

    outer = " ⋄ ".join("⎕EC ⎕UCS " + _codes(program) for program in programs)
    escaped = outer.replace("⎕", "{quad}").replace("⋄", "{diamond}")
    if (not escaped.isascii() or "'" in escaped or '"' in escaped
            or escaped.replace("{quad}", "⎕").replace("{diamond}", "⋄") != outer):
        raise ValueError("BOUNDED_UNRANK_WORKSPACE_SERIALIZATION_INVALID")

    lines[pos] = (
        f"{match['prefix']}{len(outer)} 1 {len(outer)} "
        f"'{escaped}'{match['ending']}"
    )
    candidate = "".join(lines).encode("cp1252")

    receipt = {
        "schema": "APL_GERMAN_STAGE01_BOUNDED_UNRANK_WITNESS_V1",
        "status": "GENERATED_NOT_NATIVE_VALIDATED",
        "stage01": "NOT_ACCEPTED",
        "native_executed": False,
        "source_commit": SOURCE_COMMIT,
        "source_manifest_sha256": manifest_sha,
        "function_count": 95,
        "chunk_count": 23,
        "chunk_boundaries": base_receipt["chunk_boundaries"],
        "chunk_records": base_receipt["chunk_records"],
        "import_program_sha256": [
            hashlib.sha256(p.encode("utf-8")).hexdigest()
            for p in old_programs[:23]
        ],
        "workspace_source_sha256": base_receipt["workspace_source_sha256"],
        "program_count": len(programs),
        "final_expression": "BOUNDED_UNRANK_WITNESS_ONLY",
        "final_original_stage01_tests_executed": False,
        "original_entrypoint_invoked": False,
        "original_stage01_acceptance_token_present": False,
        "production_source_modified": False,
        "marker_path": marker,
        "marker_token": FINAL,
        "trace": trace_meta,
        "witness": {
            "input": INPUT,
            "expected_fixture": EXPECTED_FIXTURE,
            "original_call": original_call,
            "trace_call": trace_call,
            "compile_token": compile_token,
            "start_token": start_token,
            "captured_token": captured_token,
            "paren_compile_token": paren_compile_token,
            "compile_marker_path": paths["compile_marker"],
            "paren_compile_marker_path": paths["paren_compile_marker"],
            "paren_compile_name_code_path": paths["paren_compile_name_code"],
            "paren_patch": paren_meta,
            "paren_call": f"{PAREN_ALIAS} 12 3 4 4 1",
            "expected_paren_result": [4, 4, 4],
            "start_marker_path": paths["start_marker"],
            "captured_marker_path": paths["captured_marker"],
            "compile_name_code_path": paths["compile_name_code"],
            "init_markers": init_markers,
            "phase_markers": phase_markers,
            "paths": {k: v for k, v in paths.items()
                      if k not in ("compile_marker", "paren_compile_marker", "start_marker", "captured_marker")},
        },
        "prior_v26_run": 45686659807,
        "prior_v26_artifact_id": 15056557607,
        "prior_v26_artifact_sha256": "ef9a79666eb91c09a56518576e41bf191456a0ba870d0b73bf2c5a0a5e08e331",
        "prior_v26_artifact_url": (
            "https://github.com/Sargon17-Green/Pastafarian-Calendar/"
            "actions/runs/45686659807/artifacts/15056557607"
        ),
        "prior_v26_native_summary": {
            "fx_last_contiguous": 95,
            "checkpoint_count": 23,
            "statement_count": 6,
            "statement_started": 6,
            "statement_ended": 5,
            "first_incomplete": {
                "index": 6, "first_line": 262, "last_line": 262,
                "kind": "statement",
            },
            "suite_ec_first": 0,
            "suite_error": "DOMAIN ERROR",
            "status": "RESIDUAL_SUITE_ERROR_DIAGNOSTIC_ONLY",
        },
        "candidate_sha256": hashlib.sha256(candidate).hexdigest(),
        "outer_lx_characters": len(outer),
        "outer_lx_sha256": hashlib.sha256(outer.encode("utf-8")).hexdigest(),
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
    receipt_path = pathlib.Path(args.receipt)
    try:
        candidate, receipt = build_bounded_unrank_witness(
            pathlib.Path(args.source).read_bytes(),
            args.repo_root.resolve(),
            args.marker,
        )
        pathlib.Path(args.candidate).parent.mkdir(parents=True, exist_ok=True)
        receipt_path.parent.mkdir(parents=True, exist_ok=True)
        pathlib.Path(args.candidate).write_bytes(candidate)
        receipt_path.write_text(
            json.dumps(receipt, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        print("BOUNDED_UNRANK_WITNESS_GENERATED_NOT_NATIVE", receipt["candidate_sha256"])
        return 0
    except Exception as exc:
        receipt_path.parent.mkdir(parents=True, exist_ok=True)
        failure = {
            "schema": "APL_GERMAN_STAGE01_BOUNDED_UNRANK_WITNESS_V1",
            "status": "GENERATION_FAILED",
            "stage01": "NOT_ACCEPTED",
            "native_executed": False,
            "source_commit": SOURCE_COMMIT,
            "error": f"{type(exc).__name__}:{exc}",
        }
        receipt_path.write_text(
            json.dumps(failure, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        print(failure["error"], file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
