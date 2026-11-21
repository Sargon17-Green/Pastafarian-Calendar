#!/usr/bin/env python3
"""Source-locked QA-only Stage1 dependency probes. No Stage1 acceptance."""
from __future__ import annotations
import argparse
import hashlib
import json
import pathlib
import sys
from chunked_fx_probe import marker_write
from stage01_import_workspace import SOURCE_COMMIT, _codes, load_locked_sources
from stage01_statement_probe import build_statement_probe, decode_programs

FINAL = "APL_GERMAN_DEPENDENCY_DIAGNOSTIC_COMPLETE_NOT_STAGE01"


def anchor(blocks, name, needle=None, required_line=None):
    matches = [b for b in blocks if b["name"] == name]
    if len(matches) != 1:
        raise ValueError("SOURCE_NAME_NOT_UNIQUE:" + name)
    b = matches[0]
    hits = [(i, s) for i, s in enumerate(b["lines"])
            if ((needle is None and i == 0) or (needle is not None and needle in s))
            and (required_line is None or b["start_line"] + i == required_line)]
    if len(hits) != 1:
        raise ValueError("SOURCE_ANCHOR_NOT_UNIQUE:" + name)
    i, source_text = hits[0]
    return dict(source_file=b["path"], source_function=name,
                source_line=b["start_line"] + i, source_text=source_text,
                source_sha256=hashlib.sha256(source_text.encode("utf-8")).hexdigest())


def build_dependency_probe(raw, root, marker):
    root = pathlib.Path(root).resolve()
    old, base = build_statement_probe(raw, root, marker)
    lines, position, match, programs = decode_programs(old)
    if len(programs) != 34 or base["source_commit"] != SOURCE_COMMIT:
        raise ValueError("STATEMENT_BASE_NOT_LOCKED")
    if base["function_count"] != 95 or base["chunk_count"] != 23:
        raise ValueError("FX_PREFIX_NOT_LOCKED")
    blocks = load_locked_sources(root)["blocks"]
    anchors = {
        "ownership": anchor(blocks, "RunStage01OwnershipTests",
                            "AssertEqual (⊂2) (⊂⍴MonsterBaseSemanticState ctxB0)"),
        "oracle": anchor(blocks, "RunStage01OracleStateTests", "EnsureGate 1", required_line=108),
        "year": anchor(blocks, "RunStage01YearTests", "anchor←Year5000 FOUNDATION_DAY"),
        "get": anchor(blocks, "GateGet"),
        "put": anchor(blocks, "GatePut"),
        "gap": anchor(blocks, "GateGap"),
        "ensure": anchor(blocks, "EnsureGate"),
        "cover": anchor(blocks, "EnsureGatesCover"),
        "sauce": anchor(blocks, "Sauce"),
        "ask": anchor(blocks, "AskBowl"),
        "rank": anchor(blocks, "ChooseRank"),
    }
    if [anchors[x]["source_line"] for x in ("ownership", "oracle", "year")] != [39, 108, 147]:
        raise ValueError("TEST_ANCHOR_LINE_CHANGED")
    original_assert = anchors["ownership"]["source_text"].strip()
    if original_assert.count("ctxB0") != 1:
        raise ValueError("OWNERSHIP_ASSERT_SOURCE_CHANGED")
    original_assert = original_assert.replace("ctxB0", "QACTXB")
    new_b = "QACTXB←(FOUNDATION_DAY+100) MonsterNewContext FOUNDATION_DAY+120"
    specs = [
        ("ownership_length", new_b, "⍴MonsterBaseSemanticState QACTXB", "value", "ownership"),
        ("ownership_committed_length", new_b, "⍴⊃QACTXB[CTX_COMMITTED]", "value", "ownership"),
        ("ownership_committed_values", new_b, "⊃QACTXB[CTX_COMMITTED]", "value", "ownership"),
        ("ownership_length_equals_two", new_b, "2≡⍴MonsterBaseSemanticState QACTXB", "value", "ownership"),
        ("ownership_source_assert", new_b, original_assert, "call", "ownership"),
        ("gate_get_zero", "GateReset", "GateGet 0", "value", "get"),
        ("gate_put_one", "GateReset", "GatePut 1 (FOUNDATION_DAY+42)", "call", "put"),
        ("gate_gap_one", "GateReset", "GateGap 1", "value", "gap"),
        ("gate_sauce_one", "GateReset", "FOUNDATION_DAY Sauce (FOUNDATION_DAY+1)", "call", "sauce"),
        ("gate_askbowl_one", "GateReset",
         "(FOUNDATION_DAY Sauce (FOUNDATION_DAY+1)) AskBowl 1 SEAL_GATE_GAP", "call", "ask"),
        ("gate_choose_rank_one", "GateReset",
         "41+((FOUNDATION_DAY Sauce (FOUNDATION_DAY+1)) AskBowl 1 SEAL_GATE_GAP) ChooseRank 922",
         "value", "rank"),
        ("ensure_gate_one", "GateReset", "EnsureGate 1", "call", "ensure"),
        ("ensure_gates_cover", "GateReset",
         "EnsureGatesCover (FOUNDATION_DAY-YEAR_MAX_DAYS) (FOUNDATION_DAY+YEAR_MAX_DAYS)",
         "call", "cover"),
    ]
    p = pathlib.PureWindowsPath(marker)
    entries = []
    programs = programs[:-1]
    for index, (name, setup, expression, mode, origin) in enumerate(specs, 1):
        prefix = f"APL_GERMAN_DEP_V1|SOURCE={SOURCE_COMMIT}|INDEX={index:02d}|NAME={name}"
        paths = {phase + "_path": str(p.with_name(f"{p.stem}_dep_{index:02d}_{phase}.txt"))
                 for phase in ("start", "captured", "code", "value")}
        start_token, captured_token = prefix + "|PHASE=START", prefix + "|PHASE=CAPTURED_NOT_PASS"
        if mode == "value":
            expression = "(⍕(" + expression + ")) ⎕NAPPEND ((⎕UCS " + _codes(paths["value_path"]) + ") ⎕NCREATE 0)"
        var = f"QADepEC{index:02d}"
        code = ("95 Stage01ChunkAssert 0 ⋄ " + setup + " ⋄ "
                + marker_write(start_token, paths["start_path"])
                + f" ⋄ {var}←⎕EC ⎕UCS {_codes(expression)}"
                + f" ⋄ (⍕{var}[1]) ⎕NAPPEND ((⎕UCS {_codes(paths['code_path'])}) ⎕NCREATE 0)"
                + " ⋄ " + marker_write(captured_token, paths["captured_path"]))
        programs.append(code)
        entries.append(dict(index=index, name=name, setup=setup, expression=expression,
                            mode=mode, start_token=start_token, captured_token=captured_token,
                            program_sha256=hashlib.sha256(code.encode()).hexdigest(),
                            **paths, **anchors[origin]))
    programs.append("95 Stage01ChunkAssert 0 ⋄ " + marker_write(FINAL, marker))
    outer = " ⋄ ".join("⎕EC ⎕UCS " + _codes(code) for code in programs)
    serial = outer.replace("⎕", "{quad}").replace("⋄", "{diamond}")
    if not serial.isascii() or "'" in serial or '"' in serial or serial.replace(
            "{quad}", "⎕").replace("{diamond}", "⋄") != outer:
        raise ValueError("SERIALIZATION_NOT_REVERSIBLE")
    lines[position] = (f"{match['prefix']}{len(outer)} 1 {len(outer)} "
                       f"'{serial}'{match['ending']}")
    candidate = "".join(lines).encode("cp1252")
    receipt = dict(base)
    receipt.update(schema="APL_GERMAN_STAGE01_DEPENDENCY_DIAGNOSTIC_V1",
                   stage01="NOT_ACCEPTED", status="GENERATED_NOT_NATIVE_VALIDATED",
                   source_commit=SOURCE_COMMIT, source_dependency_anchors=anchors,
                   dependency_probes=entries, marker_token=FINAL, marker_path=marker,
                   program_count=len(programs), prior_candidate_sha256=base["candidate_sha256"],
                   final_original_stage01_tests_executed=False,
                   original_stage01_acceptance_token_present=False,
                   candidate_sha256=hashlib.sha256(candidate).hexdigest())
    return candidate, receipt


def main():
    parser = argparse.ArgumentParser()
    for name in ("repo-root", "source", "candidate", "receipt", "marker"):
        parser.add_argument("--" + name, required=True)
    a = parser.parse_args()
    out = pathlib.Path(a.receipt)
    try:
        candidate, receipt = build_dependency_probe(
            pathlib.Path(a.source).read_bytes(), pathlib.Path(a.repo_root), a.marker)
        out.parent.mkdir(parents=True, exist_ok=True)
        pathlib.Path(a.candidate).parent.mkdir(parents=True, exist_ok=True)
        pathlib.Path(a.candidate).write_bytes(candidate)
        out.write_bytes((json.dumps(receipt, ensure_ascii=False, indent=2) + "\n").encode())
        print("DEP_CANDIDATE_ONLY", receipt["candidate_sha256"])
        return 0
    except Exception as e:
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_bytes((json.dumps(dict(stage01="NOT_ACCEPTED",
                 status="GENERATION_FAILED", error=f"{type(e).__name__}:{e}")) + "\n").encode())
        print(f"DEPENDENCY_GENERATOR_FAILED:{e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
