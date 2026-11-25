#!/usr/bin/env python3
"""QA-only residual Stage01 statement receipts atop independently verified paired-copy prerequisites."""
from __future__ import annotations
import argparse
import hashlib
import json
import pathlib
import sys

from chunked_fx_probe import marker_write
from stage01_paired_copy_probe import build_paired_copy
from stage01_subtest_probe import LX_ENTRY
from stage01_fx_prefix_probe import nested_fx_expression
from stage01_import_workspace import SOURCE_COMMIT, _codes, fx_definition_lines, load_locked_sources

SCHEMA = "APL_GERMAN_STAGE01_RESIDUAL_STATEMENT_DIAGNOSTIC_V1"
ALIAS = "QAStage01ResidualSuite"
FINAL = "APL_GERMAN_RESIDUAL_DIAGNOSTIC_COMPLETE_NOT_STAGE01"

def decode_paired(raw: bytes):
    lines = raw.decode("cp1252").splitlines(keepends=True)
    hits = []
    for i, line in enumerate(lines):
        m = LX_ENTRY.fullmatch(line)
        if m:
            outer = m["serialized"].replace("{diamond}", "⋄").replace("{quad}", "⎕")
            if outer.count("⎕EC ⎕UCS ") == 27:
                hits.append((i, m, outer))
    if len(hits) != 1:
        raise ValueError("PAIRED_LX_NOT_UNIQUE")
    pos, match, outer = hits[0]
    units = outer.split(" ⋄ ")
    if len(units) != 27 or any(not u.startswith("⎕EC ⎕UCS ") for u in units):
        raise ValueError("PAIRED_UNITS_INVALID")
    programs = ["".join(chr(int(n)) for n in u[len("⎕EC ⎕UCS "):].split())
                for u in units]
    return lines, pos, match, programs

def instrument(root: pathlib.Path, marker: str):
    """Instrument bounded original-source spans to avoid 266 native filesystem writes.

    All original statements except the exact line180 and line181 QA-only substitutions remain unchanged.
    Control-flow blocks are indivisible; the evidence is diagnostic only.
    """
    locked = load_locked_sources(root)
    blocks = [b for b in locked["blocks"] if b["name"] == "RunStage01Tests"]
    if len(blocks) != 1 or blocks[0]["path"] != "test/stage01_tests.apl":
        raise ValueError("ORIGINAL_SUITE_SOURCE_NOT_UNIQUE")
    block = blocks[0]
    source = fx_definition_lines(block)
    if not source[0].startswith("RunStage01Tests;"):
        raise ValueError("SUITE_HEADER_CHANGED")
    original_source = source.copy()
    patches = []
    for line_number, value, catalog in ((180, 17, "CUTLET_NAMES"), (181, 47, "MONTH_NAMES")):
        idx = line_number - block["start_line"]
        anchor = f"AssertEqual (⊂{value}) (⊂⍴{catalog}) "
        if not source[idx].strip().startswith(anchor):
            raise ValueError(f"LINE{line_number}_PATCH_ANCHOR_MISMATCH")
        source[idx] = source[idx].replace(f"(⊂{value})", f"(⊂,{value})", 1)
        patches.append(dict(source_line=line_number, original=original_source[idx], counterfactual=source[idx]))
    if [i for i,(a,b) in enumerate(zip(original_source,source)) if a != b] != [n-block["start_line"] for n in (180,181)]:
        raise ValueError("UNEXPECTED_SOURCE_COPY_CHANGE")
    out = [ALIAS + source[0][len("RunStage01Tests"):]]
    wp = pathlib.PureWindowsPath(marker)
    units = []
    i = 1
    while i < len(source):
        line = source[i]
        t = line.strip()
        if not t or t.startswith("⍝"):
            i += 1
            continue
        if t.startswith(":For "):
            first = i
            i += 1
            while i < len(source) and source[i].strip() != ":EndFor":
                if source[i].strip().startswith(":For "):
                    raise ValueError("NESTED_LOOPS_UNSUPPORTED")
                i += 1
            if i >= len(source):
                raise ValueError("UNTERMINATED_FOR_BLOCK")
            units.append((first, i+1, "bounded_for_block"))
            i += 1
            continue
        if t.startswith(":") or "⋄" in line:
            raise ValueError("UNSUPPORTED_SUITE_STATEMENT:" + str(block["start_line"] + i))
        units.append((i, i+1, "statement"))
        i += 1
    spans = []
    pending = []
    def flush():
        if pending:
            spans.append((pending[0][0], pending[-1][1], "statement_span"))
            pending.clear()
    for start, end, kind in units:
        if kind == "bounded_for_block":
            flush()
            spans.append((start, end, kind))
        else:
            pending.append((start, end))
            if len(pending) == 8:
                flush()
    flush()
    # V19: isolate the two catalog loops and the six following source statements.
    # V18 proved lines188-195 complete; reuse the two QA-only counterfactuals at lines180/181.
    focus = [196, 199, 202, 203, 204, 205, 206, 207]
    focused = [(start, end, kind) for start, end, kind in units
               if block["start_line"] + start in focus]
    expected_kinds = ["bounded_for_block", "bounded_for_block"] + ["statement"] * 6
    if ([block["start_line"] + start for start, _, _ in focused] != focus
            or len(focused) != 8
            or [kind for _, _, kind in focused] != expected_kinds
            or any(kind == "statement" and end != start+1 for start, end, kind in focused)):
        raise ValueError("FOCUSED_SOURCE_LINES_CHANGED")
    for (start, end, kind), header in zip(focused[:2], (":For i :In ⍳17", ":For i :In ⍳47")):
        if kind != "bounded_for_block" or source[start].strip() != header or source[end-1].strip() != ":EndFor":
            raise ValueError("CATALOG_LOOP_SOURCE_ANCHOR_CHANGED")
    spans = focused
    before, after, probes = {}, {}, []
    for idx, (start, end, kind) in enumerate(spans, 1):
        first_line = block["start_line"] + start
        last_line = block["start_line"] + end-1
        spath = str(wp.with_name(f"{wp.stem}_statement_{idx:03d}_start.txt"))
        epath = str(wp.with_name(f"{wp.stem}_statement_{idx:03d}_end.txt"))
        stoken = (f"APL_GERMAN_RESIDUAL_V1|SOURCE={SOURCE_COMMIT}|"
                  f"IDX={idx:03d}|LINE={first_line}|PHASE=START")
        etoken = (f"APL_GERMAN_RESIDUAL_V1|SOURCE={SOURCE_COMMIT}|"
                  f"IDX={idx:03d}|LINE={last_line}|PHASE=END")
        indent_s = source[start][:len(source[start])-len(source[start].lstrip())]
        indent_e = source[end-1][:len(source[end-1])-len(source[end-1].lstrip())]
        before[start] = indent_s + marker_write(stoken, spath)
        after[end-1] = indent_e + marker_write(etoken, epath)
        probes.append(dict(index=idx, kind=kind,
                           first_line=first_line, last_line=last_line,
                           source_sha256=hashlib.sha256(
                               "\n".join(source[start:end]).encode()).hexdigest(),
                           start_path=spath, start_token=stoken,
                           end_path=epath, end_token=etoken))
    for i, line in enumerate(source[1:], 1):
        if i in before:
            out.append(before[i])
        out.append(line)
        if i in after:
            out.append(after[i])
    marker_lines = set(before.values()) | set(after.values())
    recovered = [source[0]] + [v for v in out[1:] if v not in marker_lines]
    if recovered != source or len(marker_lines) != 2*len(probes):
        raise ValueError("ORIGINAL_STATEMENTS_CHANGED")
    if not all(probes[i]["index"] == i+1 for i in range(len(probes))):
        raise ValueError("PROBE_INDEX_NOT_MONOTONIC")
    return out, probes, locked["manifest"]["manifest_sha256"], patches


def line181_witness(root, marker):
    """Exact original assertion and independent shape-only counterfactual."""
    locked = load_locked_sources(root)
    block = next(b for b in locked["blocks"] if b["name"] == "RunStage01Tests")
    if block["path"] != "test/stage01_tests.apl":
        raise ValueError("LINE180_PATH_MISMATCH")
    original = fx_definition_lines(block)[181-block["start_line"]].strip()
    anchor = "AssertEqual (⊂47) (⊂⍴MONTH_NAMES)"
    if not original.startswith(anchor + " "):
        raise ValueError("LINE181_ANCHOR_MISMATCH")
    corrected = original.replace("(⊂47)", "(⊂,47)", 1)
    wp = pathlib.PureWindowsPath(marker)
    paths = {k:str(wp.with_name(wp.stem+"_line181_"+k+".txt"))
             for k in ("start","metrics","original_ec","original_message","corrected_ec","corrected_message","captured")}
    start = f"APL_GERMAN_LINE181_V16|SOURCE={SOURCE_COMMIT}|PHASE=START"
    captured = f"APL_GERMAN_LINE181_V16|SOURCE={SOURCE_COMMIT}|PHASE=CAPTURED_NOT_PASS"
    # Layout: expected rank, expected scalar value, actual rank,
    # actual shape dimensions, actual shape values, catalog tally.
    metrics = "(⍴⍴47),47,(⍴⍴⍴MONTH_NAMES),(⍴⍴MONTH_NAMES),(,⍴MONTH_NAMES),(≢MONTH_NAMES)"
    def write(expression, key):
        return f"(⍕({expression})) ⎕NAPPEND ((⎕UCS {_codes(paths[key])}) ⎕NCREATE 0)"
    parts = ["95 Stage01ChunkAssert 0", marker_write(start,paths["start"]),
             write(metrics,"metrics")]
    for key, expression in (("original",original),("corrected",corrected)):
        var = "QALine181"+key.capitalize()+"EC"
        parts += [f"{var}←⎕EC ⎕UCS {_codes(expression)}",
                  write(f"{var}[1]",key+"_ec")]
        msg = write(f"≢,⊃{var}[3]" if key == "corrected" else f"⎕UCS ⊃{var}[3]",key+"_message")
        parts.append(f"⎕EC ⎕UCS {_codes(msg)}")
    parts.append(marker_write(captured,paths["captured"]))
    program = " ⋄ ".join(parts)
    return program, dict(paths=paths,start_token=start,captured_token=captured,
                         source_line=181,original=original,counterfactual=corrected,
                         metrics_expression=metrics,
                         program_sha256=hashlib.sha256(program.encode()).hexdigest())


def build_residual(raw: bytes, repo_root: pathlib.Path, marker: str):
    root = pathlib.Path(repo_root).resolve()
    paired, base = build_paired_copy(raw,root,marker)
    lines, pos, match, programs = decode_paired(paired)
    if (base["source_commit"] != SOURCE_COMMIT or base["function_count"] != 95 or
        base["chunk_count"] != 23 or len(base["copies"]) != 2 or len(programs) != 27 or
        base["stage01"] != "NOT_ACCEPTED" or base["program_count"] != 27):
        raise ValueError("LOCKED_PAIRED_BASE_INVALID")
    before = [hashlib.sha256(x.encode()).hexdigest() for x in programs[:25]]
    if before[:23] != base["import_program_sha256"]:
        raise ValueError("LOCKED_95_FX_PREFIX_CHANGED")
    definition, probes, manifest_sha, patches = instrument(root, marker)
    if manifest_sha != base["source_manifest_sha256"]:
        raise ValueError("SOURCE_MANIFEST_CHANGED")
    wp = pathlib.PureWindowsPath(marker)
    compile_path = str(wp.with_name(wp.stem+"_residual_compiled.txt"))
    compare_path = str(wp.with_name(wp.stem+"_residual_name_code.txt"))
    compile_token = f"APL_GERMAN_RESIDUAL_V1|SOURCE={SOURCE_COMMIT}|FUNCTION={ALIAS}|PHASE=COMPILED"
    var = "QAResidualCompiledName"
    compile_program = ("95 Stage01ChunkAssert 0 ⋄ " +
        f"{var}←⎕FX {nested_fx_expression(definition)}" +
        f" ⋄ (⍕({var}≡⎕UCS {_codes(ALIAS)})) ⎕NAPPEND ((⎕UCS {_codes(compare_path)}) ⎕NCREATE 0)" +
        " ⋄ " + marker_write(compile_token,compile_path))
    target = "QAPairedSuiteEC←⎕EC ⎕UCS " + _codes("RunStage01Tests")
    replacement = "QAPairedSuiteEC←⎕EC ⎕UCS " + _codes(ALIAS)
    if programs[25].count(target) != 1:
        raise ValueError("PAIRED_ENTRYPOINT_NOT_UNIQUE")
    suite_program = programs[25].replace(target,replacement)
    programs = programs[:25] + [compile_program,suite_program,
                "95 Stage01ChunkAssert 0 ⋄ " + marker_write(FINAL,marker)]
    if len(programs) != 28:
        raise ValueError("RESIDUAL_PROGRAM_COUNT_INVALID")
    outer = " ⋄ ".join("⎕EC ⎕UCS "+_codes(x) for x in programs)
    serial = outer.replace("⎕","{quad}").replace("⋄","{diamond}")
    if (not serial.isascii() or "'" in serial or '"' in serial or
        serial.replace("{quad}","⎕").replace("{diamond}","⋄") != outer):
        raise ValueError("UNSAFE_RESIDUAL_SERIALIZATION")
    lines[pos] = f"{match['prefix']}{len(outer)} 1 {len(outer)} '{serial}'{match['ending']}"
    candidate = "".join(lines).encode("cp1252")
    receipt = dict(schema=SCHEMA,stage01="NOT_ACCEPTED",
                   status="GENERATED_NOT_NATIVE_VALIDATED",source_commit=SOURCE_COMMIT,
                   source_manifest_sha256=manifest_sha,function_count=95,chunk_count=23,
                   chunk_records=base["chunk_records"],copies=base["copies"],
                   locked_prerequisite_program_sha256=before,probe_count=len(probes),
                   probes=probes,compiled=dict(path=compile_path,token=compile_token,
                      name_code_path=compare_path,alias=ALIAS,
                      definition_sha256=hashlib.sha256("\n".join(definition).encode()).hexdigest()),
                   suite={**base["suite"],"program_sha256":hashlib.sha256(suite_program.encode()).hexdigest()},
                   original_entrypoint_invoked=False,paired_qa_overrides=True,
                   source_statements_preserved=False,qa_only_patches=patches,
                   instrumentation_mode="loops196_201_plus_statements202_207_after_v18_188_195",
                    outer_lx_chars=len(outer),candidate_bytes=len(candidate),
                    max_program_chars=max(map(len, programs)),production_source_modified=False,
                   original_unmodified_suite_proven=False,
                   original_stage01_acceptance_token_present=False,
                   marker_token=FINAL,marker_path=marker,program_count=28,prior_line181_witness_run=45551684196,
                   prior_v17_run=45658001179,
                   prior_v17_artifact_sha256="ea8b494fac8ea7d4813301df22edd48b60343210afbaa824ec3c5ed5808e7c5e",
                   prior_residual_run=45671179161,
                   prior_residual_artifact_sha256="26fdd18a8a1a2ac32a3f979a966556f98c938edc68c438edd7e6e7593b36ef89",
                   candidate_sha256=hashlib.sha256(candidate).hexdigest())
    return candidate,receipt

def main():
    p=argparse.ArgumentParser()
    for field in ("repo-root","source","candidate","receipt","marker"):
        p.add_argument("--"+field,required=True)
    a=p.parse_args()
    dest=pathlib.Path(a.receipt)
    try:
        data, receipt = build_residual(pathlib.Path(a.source).read_bytes(),
                                       pathlib.Path(a.repo_root),a.marker)
        pathlib.Path(a.candidate).parent.mkdir(parents=True,exist_ok=True)
        dest.parent.mkdir(parents=True,exist_ok=True)
        pathlib.Path(a.candidate).write_bytes(data)
        dest.write_text(json.dumps(receipt,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
        print("RESIDUAL_GENERATED_DIAGNOSTIC_ONLY",receipt["candidate_sha256"])
        return 0
    except Exception as e:
        dest.parent.mkdir(parents=True,exist_ok=True)
        dest.write_text(json.dumps(dict(stage01="NOT_ACCEPTED",status="GENERATION_FAILED",
            error=f"{type(e).__name__}:{e}"))+"\n",encoding="utf-8")
        print("RESIDUAL_GENERATION_FAILED:"+str(e),file=sys.stderr)
        return 2

if __name__ == "__main__":
    raise SystemExit(main())
