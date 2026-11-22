#!/usr/bin/env python3
"""Six source-locked QA-only counterfactual witnesses; NEVER Stage1 acceptance."""
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

SCHEMA = "APL_GERMAN_COUNTERFACTUAL_CANDIDATE_V1"
FINAL = "APL_GERMAN_COUNTERFACTUAL_V1_COMPLETE_DIAGNOSTIC_ONLY"
WITNESSES = (
    ("ownership_original", "2≡⍴MonsterBaseSemanticState QACFCtx", [0]),
    ("ownership_corrected", "(,2)≡⍴MonsterBaseSemanticState QACFCtx", [1]),
    ("poststir_original", "PostStirSavedSum (⊂1 2 3 4 5 6) 1", [150,151,152,153,154,155]),
    ("poststir_corrected", "QACounterfactualSavedSum (⊂1 2 3 4 5 6) 1", [170]),
    ("poststir_original_unboxed_rank", "⍴⍴⊃PostStirSavedSum (⊂1 2 3 4 5 6) 1", [1]),
    ("poststir_corrected_rank", "⍴⍴QACounterfactualSavedSum (⊂1 2 3 4 5 6) 1", [0]),
)
HELPER = [
    "∇ z←QACounterfactualSavedSum args;bowls;stir",
    "  bowls←⊃⊃args[1] ⋄ stir←args[2]",
    "  z←Save ((+/bowls)+(149×stir))",
    "∇",
]

def build_counterfactual(raw: bytes, repo_root: pathlib.Path, marker: str):
    root = pathlib.Path(repo_root).resolve()
    old, base = build_error_code_probe(raw, root, marker)
    lines, pos, match, old_programs = decode_programs(old)
    if len(old_programs) != 31 or len(base["import_program_sha256"]) != 23:
        raise ValueError("ORIGINAL_FX_PREFIX_MISSING")
    if (base["source_commit"] != SOURCE_COMMIT or base["function_count"] != 95
            or base["chunk_count"] != 23 or len(base["chunk_records"]) != 23):
        raise ValueError("SOURCE_OR_FX_LOCK_MISMATCH")
    prefix = old_programs[:23]
    actual_hashes = [hashlib.sha256(p.encode("utf-8")).hexdigest() for p in prefix]
    if actual_hashes != base["import_program_sha256"]:
        raise ValueError("IMMUTABLE_FX_PROGRAMS_MISMATCH")
    blocks = load_locked_sources(root)["blocks"]
    ownership = next(b for b in blocks if b["name"] == "RunStage01OwnershipTests")
    saved = next(b for b in blocks if b["name"] == "PostStirSavedSum")
    def anchored(block, line, needle, expected_path):
        if block["path"] != expected_path:
            raise ValueError("ANCHOR_PATH_CHANGED")
        index = line - block["start_line"]
        if index < 0 or index >= len(block["lines"]) or needle not in block["lines"][index]:
            raise ValueError("ANCHOR_LINE_CHANGED")
        text = block["lines"][index]
        return dict(path=block["path"], name=block["name"], line=line,
                    sha256=hashlib.sha256(text.encode("utf-8")).hexdigest(), text=text)
    anchors = [
        anchored(ownership, 39, "AssertEqual (⊂2) (⊂⍴MonsterBaseSemanticState ctxB0)",
                 "test/stage01_tests.apl"),
        anchored(saved, 225, "bowls←⊃args[1] ⋄ stir←args[2]", "src/normative_oracle.apl"),
        anchored(saved, 226, "z←Save ((+/bowls)+(149×stir))", "src/normative_oracle.apl"),
    ]
    expected_saved = fx_definition_lines(saved)
    if (expected_saved[1] != "  bowls←⊃args[1] ⋄ stir←args[2]"
            or expected_saved[2] != HELPER[2] or HELPER[1] != expected_saved[1].replace(
                "bowls←⊃args[1]", "bowls←⊃⊃args[1]")):
        raise ValueError("COUNTERFACTUAL_DIFFERENCE_NOT_MINIMAL")
    winpath = pathlib.PureWindowsPath(marker)
    init_path = str(winpath.with_name(winpath.stem + "_init.txt"))
    helper_path = str(winpath.with_name(winpath.stem + "_helper.txt"))
    init_token = "APL_GERMAN_COUNTERFACTUAL_V1_INIT_COMPLETE"
    helper_token = "APL_GERMAN_COUNTERFACTUAL_V1_HELPER_COMPILED"
    programs = list(prefix)
    programs.append("95 Stage01ChunkAssert 0 ⋄ SourceLanguageCatalogInit ⋄ "
                    "MonsterBootstrapInit ⋄ OracleInit ⋄ Stage01FixturesInit ⋄ "
                    + marker_write(init_token, init_path))
    programs.append("95 Stage01ChunkAssert 0 ⋄ ⎕FX " +
                    nested_fx_expression(fx_definition_lines(
                        {"name": "QACounterfactualSavedSum", "lines": HELPER}))
                    + " ⋄ " + marker_write(helper_token, helper_path))
    specs = []
    for i, (name, expression, expected) in enumerate(WITNESSES, 1):
        stem = f"{winpath.stem}_cf_{i:02d}"
        paths = {phase + "_path": str(winpath.with_name(stem + "_" + phase + ".txt"))
                 for phase in ("start", "captured", "code", "value", "message")}
        start = f"APL_GERMAN_CF_V1|SOURCE={SOURCE_COMMIT}|INDEX={i:02d}|PHASE=START"
        captured = f"APL_GERMAN_CF_V1|SOURCE={SOURCE_COMMIT}|INDEX={i:02d}|PHASE=CAPTURED_NOT_PASS"
        variable = f"QACFEC{i:02d}"
        expr = "(⍕(" + expression + ")) ⎕NAPPEND ((⎕UCS " + _codes(paths["value_path"]) + ") ⎕NCREATE 0)"
        message_expr = f"(⍕⎕UCS ⊃{variable}[3]) ⎕NAPPEND ((⎕UCS {_codes(paths['message_path'])}) ⎕NCREATE 0)"
        setup = ("QACFCtx←(FOUNDATION_DAY+100) MonsterNewContext FOUNDATION_DAY+120 ⋄ "
                 if i in (1,2) else "")
        program = ("95 Stage01ChunkAssert 0 ⋄ " + setup
                   + marker_write(start, paths["start_path"])
                   + f" ⋄ {variable}←⎕EC ⎕UCS {_codes(expr)}"
                   + f" ⋄ (⍕{variable}[1]) ⎕NAPPEND ((⎕UCS {_codes(paths['code_path'])}) ⎕NCREATE 0)"
                   + f" ⋄ QACFMsg{i:02d}←⎕EC ⎕UCS {_codes(message_expr)}"
                   + " ⋄ " + marker_write(captured, paths["captured_path"]))
        programs.append(program)
        specs.append(dict(index=i,name=name,expression=expression,expected_values=expected,
                          start_token=start,captured_token=captured,
                          sha256=hashlib.sha256(program.encode("utf-8")).hexdigest(),**paths))
    programs.append("95 Stage01ChunkAssert 0 ⋄ " + marker_write(FINAL,marker))
    outer = " ⋄ ".join("⎕EC ⎕UCS " + _codes(program) for program in programs)
    serial = outer.replace("⎕","{quad}").replace("⋄","{diamond}")
    if (not serial.isascii() or "'" in serial or '"' in serial
            or serial.replace("{quad}","⎕").replace("{diamond}","⋄") != outer):
        raise ValueError("UNSAFE_WORKSPACE_SERIALIZATION")
    lines[pos] = f"{match['prefix']}{len(outer)} 1 {len(outer)} '{serial}'{match['ending']}"
    candidate = "".join(lines).encode("cp1252")
    receipt = dict(schema=SCHEMA, status="GENERATED_NOT_NATIVE_VALIDATED",stage01="NOT_ACCEPTED",
        source_commit=SOURCE_COMMIT, source_anchors=anchors,
        function_count=95,chunk_count=23,chunk_records=base["chunk_records"],
        import_program_sha256=actual_hashes, source_manifest_sha256=base["source_manifest_sha256"],
        init_token=init_token,init_path=init_path,helper_token=helper_token,helper_path=helper_path,
        helper_sha256=hashlib.sha256("\n".join(HELPER).encode("utf-8")).hexdigest(),
        probes=specs,program_count=len(programs),marker_token=FINAL,marker_path=marker,
        candidate_sha256=hashlib.sha256(candidate).hexdigest(),
        final_original_stage01_tests_executed=False,
        original_stage01_acceptance_token_present=False)
    if len(programs) != 32 or len(specs) != 6:
        raise ValueError("BOUNDED_PROBE_COUNT_MISMATCH")
    return candidate, receipt

def main():
    p=argparse.ArgumentParser()
    for field in ("repo-root","source","candidate","receipt","marker"):
        p.add_argument("--"+field,required=True)
    a=p.parse_args()
    out=pathlib.Path(a.receipt)
    try:
        candidate, receipt=build_counterfactual(
            pathlib.Path(a.source).read_bytes(), pathlib.Path(a.repo_root), a.marker)
        pathlib.Path(a.candidate).parent.mkdir(parents=True,exist_ok=True)
        out.parent.mkdir(parents=True,exist_ok=True)
        pathlib.Path(a.candidate).write_bytes(candidate)
        out.write_bytes((json.dumps(receipt,ensure_ascii=False,indent=2)+"\n").encode("utf-8"))
        print("COUNTERFACTUAL_GENERATED_NOT_NATIVE",receipt["candidate_sha256"])
        return 0
    except Exception as exc:
        out.parent.mkdir(parents=True,exist_ok=True)
        out.write_text(json.dumps(dict(stage01="NOT_ACCEPTED",status="GENERATION_FAILED",
            error=f"{type(exc).__name__}:{exc}"))+"\n",encoding="utf-8")
        print(f"COUNTERFACTUAL_GENERATION_FAILED:{exc}",file=sys.stderr)
        return 2
if __name__=="__main__":
    raise SystemExit(main())
