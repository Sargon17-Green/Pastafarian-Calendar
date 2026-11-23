#!/usr/bin/env python3
"""QA-only paired source-copy regression. Never confers Stage1 acceptance."""
from __future__ import annotations
import argparse
import hashlib
import json
import pathlib
import sys
from chunked_fx_probe import marker_write
from stage01_ec_probe import build_error_code_probe
from stage01_statement_probe import decode_programs
from stage01_fx_prefix_probe import nested_fx_expression
from stage01_import_workspace import SOURCE_COMMIT, _codes, fx_definition_lines, load_locked_sources

SCHEMA = "APL_GERMAN_PAIRED_SOURCE_COPY_CANDIDATE_V1"
FINAL = "APL_GERMAN_PAIRED_SOURCE_COPY_DIAGNOSTIC_V1_COMPLETE_NOT_STAGE01"
CHANGES = (
    ("RunStage01OwnershipTests", "test/stage01_tests.apl", 39,
     "AssertEqual (⊂2) (⊂⍴MonsterBaseSemanticState ctxB0)",
     "AssertEqual (⊂,2) (⊂⍴MonsterBaseSemanticState ctxB0)"),
    ("PostStirSavedSum", "src/normative_oracle.apl", 225,
     "bowls←⊃args[1] ⋄ stir←args[2]",
     "bowls←⊃⊃args[1] ⋄ stir←args[2]"),
)

def source_copies(root):
    loaded = load_locked_sources(pathlib.Path(root).resolve())
    by_name = {b["name"]: b for b in loaded["blocks"]}
    amended = []
    anchors = []
    for name, path, line, original, replacement in CHANGES:
        b = by_name[name]
        if b["path"] != path:
            raise ValueError("SOURCE_COPY_PATH_CHANGED:" + name)
        original_definition = fx_definition_lines(b)
        index = line - b["start_line"]
        if index < 1 or index >= len(original_definition):
            raise ValueError("SOURCE_COPY_LINE_OUTSIDE_FUNCTION:" + name)
        expected_line = original_definition[index]
        if not expected_line.startswith("  " + original):
            raise ValueError("SOURCE_COPY_ANCHOR_CHANGED:" + name)
        if sum(original in s for s in original_definition) != 1:
            raise ValueError("SOURCE_COPY_ANCHOR_NOT_UNIQUE:" + name)
        replacement_line = expected_line.replace(original, replacement, 1)
        if replacement_line == expected_line:
            raise ValueError("SOURCE_COPY_REPLACEMENT_UNCHANGED:" + name)
        definition = list(original_definition)
        definition[index] = replacement_line
        if sum(a != b for a, b in zip(original_definition, definition)) != 1:
            raise ValueError("SOURCE_COPY_CHANGE_COUNT")
        anchors.append(dict(name=name, path=path, line=line,
                            original_sha256=hashlib.sha256(expected_line.encode()).hexdigest(),
                            replacement_sha256=hashlib.sha256(replacement_line.encode()).hexdigest(),
                            original_text=expected_line,replacement_text=replacement_line))
        amended.append((name, definition))
    return amended, anchors, loaded["manifest"]["manifest_sha256"]

def build_paired_copy(raw: bytes, repo_root: pathlib.Path, marker: str):
    root = pathlib.Path(repo_root).resolve()
    source, baseline = build_error_code_probe(raw, root, marker)
    lines, pos, match, original_programs = decode_programs(source)
    if (len(original_programs) != 31 or baseline["source_commit"] != SOURCE_COMMIT or
        baseline["function_count"] != 95 or baseline["chunk_count"] != 23 or
        len(baseline["chunk_records"]) != 23):
        raise ValueError("LOCKED_FX_BASE_INVALID")
    programs = list(original_programs[:23])
    prefix_hashes = [hashlib.sha256(p.encode("utf-8")).hexdigest() for p in programs]
    if prefix_hashes != baseline["import_program_sha256"]:
        raise ValueError("LOCKED_FX_PREFIX_CHANGED")
    modified, anchors, manifest_sha = source_copies(root)
    if manifest_sha != baseline["source_manifest_sha256"]:
        raise ValueError("SOURCE_MANIFEST_MISMATCH")
    wp = pathlib.PureWindowsPath(marker)
    copy_specs = []
    for index, (name, definition) in enumerate(modified, 1):
        path = str(wp.with_name(f"{wp.stem}_copy_{index:02d}.txt"))
        code_path = str(wp.with_name(f"{wp.stem}_copy_{index:02d}_name_code.txt"))
        token = (f"APL_GERMAN_PAIRED_COPY_V1|SOURCE={SOURCE_COMMIT}|"
                 f"INDEX={index:02d}|FUNCTION={name}|PHASE=COMPILED_DIAGNOSTIC")
        var = f"QAPairedFXName{index:02d}"
        compare = f"({var}≡⎕UCS {_codes(name)})"
        program = ("95 Stage01ChunkAssert 0 ⋄ "
                   + f"{var}←⎕FX {nested_fx_expression(definition)}"
                   + f" ⋄ (⍕{compare}) ⎕NAPPEND ((⎕UCS {_codes(code_path)}) ⎕NCREATE 0)"
                   + " ⋄ " + marker_write(token, path))
        programs.append(program)
        copy_specs.append(dict(index=index,name=name,path=path,token=token,
                               name_code_path=code_path,
                               copy_definition_sha256=hashlib.sha256(
                                   "\n".join(definition).encode()).hexdigest(),
                               program_sha256=hashlib.sha256(program.encode()).hexdigest()))
    start_path = str(wp.with_name(wp.stem+"_suite_start.txt"))
    captured_path = str(wp.with_name(wp.stem+"_suite_captured.txt"))
    code_path = str(wp.with_name(wp.stem+"_suite_ec_first.txt"))
    message_path = str(wp.with_name(wp.stem+"_suite_message_codes.txt"))
    start_token = (f"APL_GERMAN_PAIRED_SUITE_V1|SOURCE={SOURCE_COMMIT}|PHASE=START")
    captured_token = (f"APL_GERMAN_PAIRED_SUITE_V1|SOURCE={SOURCE_COMMIT}|PHASE=CAPTURED_NOT_PASS")
    msg_expr = (f"(⍕⎕UCS ⊃QAPairedSuiteEC[3]) ⎕NAPPEND "
                f"((⎕UCS {_codes(message_path)}) ⎕NCREATE 0)")
    suite = ("95 Stage01ChunkAssert 0 ⋄ "
             + marker_write(start_token,start_path)
             + " ⋄ QAPairedSuiteEC←⎕EC ⎕UCS " + _codes("RunStage01Tests")
             + f" ⋄ (⍕QAPairedSuiteEC[1]) ⎕NAPPEND ((⎕UCS {_codes(code_path)}) ⎕NCREATE 0)"
             + f" ⋄ QAPairedMsgEC←⎕EC ⎕UCS {_codes(msg_expr)}"
             + " ⋄ " + marker_write(captured_token,captured_path))
    programs.append(suite)
    programs.append("95 Stage01ChunkAssert 0 ⋄ " + marker_write(FINAL,marker))
    if len(programs) != 27:
        raise ValueError("PAIRED_PROGRAM_COUNT_CHANGED")
    outer = " ⋄ ".join("⎕EC ⎕UCS " + _codes(program) for program in programs)
    serial = outer.replace("⎕","{quad}").replace("⋄","{diamond}")
    if (not serial.isascii() or "'" in serial or '"' in serial or
        serial.replace("{quad}","⎕").replace("{diamond}","⋄") != outer):
        raise ValueError("WORKSPACE_SERIALIZATION_UNSAFE")
    lines[pos] = f"{match['prefix']}{len(outer)} 1 {len(outer)} '{serial}'{match['ending']}"
    candidate = "".join(lines).encode("cp1252")
    receipt = dict(schema=SCHEMA, stage01="NOT_ACCEPTED",
                   status="GENERATED_NOT_NATIVE_VALIDATED",
                   source_commit=SOURCE_COMMIT,source_manifest_sha256=manifest_sha,
                   function_count=95,chunk_count=23,
                   chunk_records=baseline["chunk_records"],import_program_sha256=prefix_hashes,
                   source_anchors=anchors,copies=copy_specs,
                   suite=dict(start_path=start_path,start_token=start_token,
                              captured_path=captured_path,captured_token=captured_token,
                              code_path=code_path,message_path=message_path,
                              program_sha256=hashlib.sha256(suite.encode()).hexdigest()),
                   original_entrypoint_invoked_with_qa_overrides=True,
                   production_source_modified=False,
                   original_unmodified_suite_proven=False,
                   original_stage01_acceptance_token_present=False,
                   marker_path=marker,marker_token=FINAL,program_count=27,
                   candidate_sha256=hashlib.sha256(candidate).hexdigest())
    return candidate, receipt

def main():
    p=argparse.ArgumentParser()
    for field in ("repo-root","source","candidate","receipt","marker"):
        p.add_argument("--"+field,required=True)
    a=p.parse_args()
    dest=pathlib.Path(a.receipt)
    try:
        candidate, rec=build_paired_copy(pathlib.Path(a.source).read_bytes(),
                                         pathlib.Path(a.repo_root),a.marker)
        pathlib.Path(a.candidate).parent.mkdir(parents=True,exist_ok=True)
        dest.parent.mkdir(parents=True,exist_ok=True)
        pathlib.Path(a.candidate).write_bytes(candidate)
        dest.write_text(json.dumps(rec,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
        print("PAIRED_COPY_GENERATED_NOT_NATIVE_VALIDATED",rec["candidate_sha256"])
        return 0
    except Exception as exc:
        dest.parent.mkdir(parents=True,exist_ok=True)
        dest.write_text(json.dumps(dict(stage01="NOT_ACCEPTED",status="GENERATION_FAILED",
                                  error=f"{type(exc).__name__}:{exc}") )+"\n",encoding="utf-8")
        print(f"PAIRED_COPY_GENERATOR_FAILED:{type(exc).__name__}:{exc}",file=sys.stderr)
        return 2
if __name__=="__main__":
    raise SystemExit(main())
