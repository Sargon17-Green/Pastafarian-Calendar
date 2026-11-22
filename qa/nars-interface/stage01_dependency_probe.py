#!/usr/bin/env python3
"""Source-locked QA-only Stage1 root-cause probes. Never accepts Stage1."""
from __future__ import annotations
import argparse
import hashlib
import json
import pathlib
import sys
from chunked_fx_probe import marker_write
from stage01_import_workspace import SOURCE_COMMIT, _codes, load_locked_sources
from stage01_statement_probe import build_statement_probe, decode_programs

FINAL = "APL_GERMAN_ROOTCAUSE_DIAGNOSTIC_V4_COMPLETE_NOT_STAGE01"


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

    p = pathlib.PureWindowsPath(marker)

    # Add the actual ⎕EC message capture to the three source-locked test calls.
    # The source test functions themselves remain untouched.
    for offset, call in enumerate(base["calls"]):
        index = int(call["index"])
        message_path = str(p.with_name(f"{p.stem}_stmt_{index:02d}_message_codes.txt"))
        call["message_code_path"] = message_path
        var = f"QAStmtEC{index:02d}"
        message_expression = f"(⍕⎕UCS ⊃{var}[3]) ⎕NAPPEND ((⎕UCS {_codes(message_path)}) ⎕NCREATE 0)"
        statement = (
            "95 Stage01ChunkAssert 0 ⋄ "
            + marker_write(call["start_token"], call["start_path"])
            + f" ⋄ {var}←⎕EC ⎕UCS {_codes(call['alias'])}"
            + f" ⋄ (⍕{var}[1]) ⎕NAPPEND ((⎕UCS {_codes(call['code_path'])}) ⎕NCREATE 0)"
            + f" ⋄ QAMsgStmt{index:02d}←⎕EC ⎕UCS {_codes(message_expression)}"
            + " ⋄ " + marker_write(call["captured_token"], call["captured_path"])
        )
        call["inner_sha256"] = hashlib.sha256(statement.encode("utf-8")).hexdigest()
        programs[30 + offset] = statement

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
        "post_stir_old": anchor(blocks, "PostStir12", "old←bowls"),
        "post_stir_saved": anchor(blocks, "PostStir12", "saved←PostStirSavedSum (⊂old) stir"),
        "post_saved": anchor(blocks, "PostStirSavedSum", "z←Save ((+/bowls)+(149×stir))"),
        "post_stir_rank": anchor(blocks, "PostStir12", "rank←1+(720 RegularMod (saved-1))"),
        "post_stir_order": anchor(blocks, "PostStir12", "order←PermutationUnrank1 rank"),
        "post_stir_id": anchor(blocks, "PostStir12", "id←order[position]"),
        "post_stir_prev": anchor(blocks, "PostStir12", "prev←order[6 Wrap1 (position-1)]"),
        "post_stir_next": anchor(blocks, "PostStir12", "next←order[6 Wrap1 (position+1)]"),
        "post_stir_s": anchor(blocks, "PostStir12", "s←old[id]+(3×old[prev])+(5×old[next])+saved+stir+(position×position)"),
        "post_stir_value": anchor(blocks, "PostStir12", "nextBowls[id]←Save ((s×s)+(7×old[prev]×old[next]))"),
        "post_stir_next_bowls": anchor(blocks, "PostStir12", "nextBowls←6⍴0x"),
        "post_stir_assign": anchor(blocks, "PostStir12", "nextBowls[id]←Save ((s×s)+(7×old[prev]×old[next]))"),
        "post_stir_wrap": anchor(blocks, "Wrap1", "z←1+(size RegularMod (position-1))"),
        "post_stir_save": anchor(blocks, "Save", "z←1+(M RegularMod (x-1))"),
        "post_stir_perm": anchor(blocks, "PermutationUnrank1", "z←result"),
    }
    if [anchors[x]["source_line"] for x in ("ownership", "oracle", "year")] != [39, 108, 147]:
        raise ValueError("TEST_ANCHOR_LINE_CHANGED")

    original_assert = anchors["ownership"]["source_text"].strip()
    if original_assert.count("ctxB0") != 1:
        raise ValueError("OWNERSHIP_ASSERT_SOURCE_CHANGED")
    original_assert = original_assert.replace("ctxB0", "QACTXB")
    new_b = "QACTXB←(FOUNDATION_DAY+100) MonsterNewContext FOUNDATION_DAY+120"

    specs = [
        # Original 13 dependency probes, now with full ⎕EC message capture.
        ("ownership_length", new_b, "⍴MonsterBaseSemanticState QACTXB", "value", "ownership"),
        ("ownership_committed_length", new_b, "⍴⊃QACTXB[CTX_COMMITTED]", "value", "ownership"),
        ("ownership_committed_values", new_b, "⊃QACTXB[CTX_COMMITTED]", "value", "ownership"),
        ("ownership_length_equals_two", new_b, "2≡⍴MonsterBaseSemanticState QACTXB", "value", "ownership"),
        ("ownership_source_assert", new_b, original_assert, "call", "ownership"),
        ("gate_get_zero", "GateReset", "GateGet 0", "value", "get"),
        ("gate_put_one", "GateReset", "GatePut 1 (FOUNDATION_DAY+42)", "call", "put"),
        ("gate_gap_one", "GateReset", "GateGap 1", "value", "gap"),
        ("gate_sauce_one", "", "FOUNDATION_DAY Sauce (FOUNDATION_DAY+1)", "call", "sauce"),
        ("gate_askbowl_one", "",
         "(FOUNDATION_DAY Sauce (FOUNDATION_DAY+1)) AskBowl 1 SEAL_GATE_GAP", "call", "ask"),
        ("gate_choose_rank_one", "",
         "41+((FOUNDATION_DAY Sauce (FOUNDATION_DAY+1)) AskBowl 1 SEAL_GATE_GAP) ChooseRank 922",
         "value", "rank"),
        ("ensure_gate_one", "GateReset", "EnsureGate 1", "call", "ensure"),
        ("ensure_gates_cover", "GateReset",
         "EnsureGatesCover (FOUNDATION_DAY-YEAR_MAX_DAYS) (FOUNDATION_DAY+YEAR_MAX_DAYS)",
         "call", "cover"),

        # Distinguish a value mismatch from a type/rank mismatch in line 39.
        ("ownership_expected_dr", new_b, "⎕DR 2", "value", "ownership"),
        ("ownership_actual_dr", new_b, "⎕DR ⍴MonsterBaseSemanticState QACTXB", "value", "ownership"),
        ("ownership_numeric_equal", new_b, "2=⍴MonsterBaseSemanticState QACTXB", "value", "ownership"),
        ("ownership_expected_rank", new_b, "⍴⍴2", "value", "ownership"),
        ("ownership_actual_rank", new_b, "⍴⍴⍴MonsterBaseSemanticState QACTXB", "value", "ownership"),

        # Isolate the first failing statement inside Sauce, then its consumers.
        ("sauce_work_counts", "", "QASauceCounts←FOUNDATION_DAY WorkCounts (FOUNDATION_DAY+1)", "call", "sauce"),
        ("sauce_build_hidden", "", "QASauceHidden←BuildHidden QASauceCounts", "call", "sauce"),
        ("sauce_build_visible", "", "QASauceVisible←QASauceCounts BuildVisible QASauceHidden", "call", "sauce"),
        ("sauce_initial_bowls", "", "QASauceBowls←InitialBowls QASauceCounts", "call", "sauce"),
        ("sauce_apply_visible", "", "QASaucePair←QASauceBowls ApplyVisible QASauceVisible", "call", "sauce"),
        ("sauce_post_stir", "", "QASauceFinal←PostStir12 ⊃QASaucePair[1]", "call", "sauce"),
        ("sauce_result", "", "QASauce←FOUNDATION_DAY Sauce (FOUNDATION_DAY+1)", "call", "sauce"),
        ("sauce_next_bowl", "", "QASauceNext←QASauce NextBowlInDrop46Order 1", "call", "ask"),
        ("sauce_ask_bowl", "", "QASauceAsk←QASauce AskBowl 1 SEAL_GATE_GAP", "call", "ask"),
        ("sauce_choose_rank", "", "QASauceRank←QASauceAsk ChooseRank 922", "call", "rank"),
        ("ownership_vector_match", new_b, ",2≡⍴MonsterBaseSemanticState QACTXB", "value", "ownership"),
        ("sauce_post_old", "", "QAPostOld←⊃QASaucePair[1]", "call", "post_stir_old"),
        ("sauce_post_saved", "", "QAPostSaved←PostStirSavedSum (⊂QAPostOld) 1", "call", "post_stir_saved"),
        ("sauce_post_saved_value", "", "QAPostSaved", "value", "post_saved"),
        ("sauce_post_rank", "", "QAPostRank←1+(720 RegularMod (QAPostSaved-1))", "call", "post_stir_rank"),
        ("sauce_post_rank_value", "", "QAPostRank", "value", "post_stir_rank"),
        ("sauce_post_order", "", "QAPostOrder←PermutationUnrank1 QAPostRank", "call", "post_stir_order"),
        ("sauce_post_order_value", "", "QAPostOrder", "value", "post_stir_perm"),
        ("sauce_post_first_id", "", "QAPostId←QAPostOrder[1]", "call", "post_stir_id"),
        ("sauce_post_first_prev", "", "QAPostPrev←QAPostOrder[6 Wrap1 (1-1)]", "call", "post_stir_wrap"),
        ("sauce_post_first_next", "", "QAPostNext←QAPostOrder[6 Wrap1 (1+1)]", "call", "post_stir_wrap"),
        ("sauce_post_first_s", "", "QAPostS←QAPostOld[QAPostId]+(3×QAPostOld[QAPostPrev])+(5×QAPostOld[QAPostNext])+QAPostSaved+1+(1×1)", "call", "post_stir_s"),
        ("sauce_post_first_value", "", "QAPostValue←Save ((QAPostS×QAPostS)+(7×QAPostOld[QAPostPrev]×QAPostOld[QAPostNext]))", "call", "post_stir_save"),
        ("sauce_post_next_bowls", "", "QAPostNextBowls←6⍴0x", "call", "post_stir_next_bowls"),
        ("sauce_post_assign_first", "", "QAPostNextBowls[QAPostId]←QAPostValue", "call", "post_stir_assign"),
        ("ownership_vector_match_correct", new_b, "(,2)≡⍴MonsterBaseSemanticState QACTXB", "value", "ownership"),
        ("sauce_post_old_shape", "", "⍴QAPostOld", "value", "post_stir_old"),
        ("sauce_post_old_rank", "", "⍴⍴QAPostOld", "value", "post_stir_old"),
        ("sauce_post_old_sum", "", "+/QAPostOld", "value", "post_stir_old"),
        ("sauce_post_old_value", "", "QAPostOld", "value", "post_stir_old"),
        ("sauce_post_saved_shape", "", "⍴QAPostSaved", "value", "post_stir_saved"),
        ("sauce_post_saved_rank", "", "⍴⍴QAPostSaved", "value", "post_stir_saved"),
        ("sauce_post_saved_known_vector", "", "PostStirSavedSum (⊂1 2 3 4 5 6) 1", "value", "post_saved"),
        ("sauce_post_saved_known_vector_rank", "", "⍴⍴PostStirSavedSum (⊂1 2 3 4 5 6) 1", "value", "post_saved"),
        ("sauce_post_rank_shape", "", "⍴QAPostRank", "value", "post_stir_rank"),
        ("sauce_post_rank_rank", "", "⍴⍴QAPostRank", "value", "post_stir_rank"),
        ("sauce_fixed_fx_exists", "", "⎕NC 'QAFixedPostStirSavedSum'", "value", "post_saved"),
        ("sauce_fixed_saved_known", "", "QAFixedPostStirSavedSum (⊂1 2 3 4 5 6) 1", "value", "post_saved"),
        ("sauce_fixed_saved_actual", "", "QAFixedPostStirSavedSum (⊂QAPostOld) 1", "value", "post_saved"),
        ("sauce_fixed_saved_actual_rank", "", "⍴⍴QAFixedPostStirSavedSum (⊂QAPostOld) 1", "value", "post_saved"),
        ("sauce_fixed_order", "", "QAFixedOrder←PermutationUnrank1 (1+(720 RegularMod (QAFixedPostStirSavedSum (⊂QAPostOld) 1)-1))", "call", "post_stir_order"),
        ("sauce_fixed_poststir12", "", "QAFixedPostStir12 ⊃QASaucePair[1]", "call", "post_stir_old"),
        ("sauce_fixed_poststir12_value", "", "QAFixedPostStir12 ⊃QASaucePair[1]", "value", "post_stir_old"),
    ]
    if len(specs) != 61:
        raise ValueError("ROOTCAUSE_PROBE_COUNT_INVALID")

    entries = []
    programs = programs[:-1]
    post_block = next(b for b in blocks if b["name"] == "PostStir12")
    fixed_post_lines = []
    for source_line in post_block["lines"]:
        fixed_line = source_line
        if fixed_line.lstrip().startswith("∇") and "PostStir12" in fixed_line:
            fixed_line = fixed_line.replace("PostStir12", "QAFixedPostStir12", 1)
        if "PostStirSavedSum (⊂old) stir" in fixed_line:
            fixed_line = fixed_line.replace("PostStirSavedSum", "QAFixedPostStirSavedSum", 1)
        fixed_post_lines.append(fixed_line)
    if not any("QAFixedPostStir12" in x for x in fixed_post_lines):
        raise ValueError("QA_POSTSTIR_COPY_HEADER_MISSING")
    if not any("QAFixedPostStirSavedSum" in x for x in fixed_post_lines):
        raise ValueError("QA_POSTSTIR_COPY_HELPER_MISSING")
    fixed_saved_lines = [
        "∇ z←QAFixedPostStirSavedSum args;bowls;stir",
        "  bowls←⊃⊃args[1] ⋄ stir←args[2]",
        "  z←Save ((+/bowls)+(149×stir))",
        "∇",
    ]
    # Each ⎕FX fixes exactly one function. V4 sent two definitions in one
    # call; native evidence showed ⎕NC=0 for the purported QA helper.
    fx_programs = [
        "QAFixedFXHelper←⎕EC ⎕FX " + " ".join("(⎕UCS " + _codes(x) + ")" for x in fixed_saved_lines),
        "QAFixedFXCopy←⎕EC ⎕FX " + " ".join("(⎕UCS " + _codes(x) + ")" for x in fixed_post_lines),
    ]
    programs.extend(fx_programs)
    fixed_receipt = {
        "source_function": "PostStir12",
        "source_sha256": hashlib.sha256("\n".join(post_block["lines"]).encode("utf-8")).hexdigest(),
        "copy_function": "QAFixedPostStir12",
        "copy_sha256": hashlib.sha256("\n".join(fixed_post_lines).encode("utf-8")).hexdigest(),
        "helper_function": "QAFixedPostStirSavedSum",
        "helper_sha256": hashlib.sha256("\n".join(fixed_saved_lines).encode("utf-8")).hexdigest(),
        "only_logic_change": "PostStirSavedSum (⊂old) stir -> QAFixedPostStirSavedSum (⊂old) stir; helper uses bowls←⊃⊃args[1]",
        "fx_program_sha256s": [hashlib.sha256(x.encode("utf-8")).hexdigest() for x in fx_programs],
    }
    for index, (name, setup, expression, mode, origin) in enumerate(specs, 1):
        prefix = f"APL_GERMAN_ROOT_V4|SOURCE={SOURCE_COMMIT}|INDEX={index:02d}|NAME={name}"
        paths = {phase + "_path": str(p.with_name(f"{p.stem}_dep_{index:02d}_{phase}.txt"))
                 for phase in ("start", "captured", "code", "value", "message")}
        start_token = prefix + "|PHASE=START"
        captured_token = prefix + "|PHASE=CAPTURED_NOT_PASS"
        if mode == "value":
            expression = ("(⍕(" + expression + ")) ⎕NAPPEND ((⎕UCS "
                          + _codes(paths["value_path"]) + ") ⎕NCREATE 0)")
        var = f"QARootEC{index:02d}"
        message_expression = f"(⍕⎕UCS ⊃{var}[3]) ⎕NAPPEND ((⎕UCS {_codes(paths['message_path'])}) ⎕NCREATE 0)"
        code = "95 Stage01ChunkAssert 0"
        if setup:
            code += " ⋄ " + setup
        code += (
            " ⋄ " + marker_write(start_token, paths["start_path"])
            + f" ⋄ {var}←⎕EC ⎕UCS {_codes(expression)}"
            + f" ⋄ (⍕{var}[1]) ⎕NAPPEND ((⎕UCS {_codes(paths['code_path'])}) ⎕NCREATE 0)"
            + f" ⋄ QAMsgDep{index:02d}←⎕EC ⎕UCS {_codes(message_expression)}"
            + " ⋄ " + marker_write(captured_token, paths["captured_path"])
        )
        programs.append(code)
        entries.append(dict(index=index, name=name, setup=setup, expression=expression,
                            mode=mode, start_token=start_token, captured_token=captured_token,
                            program_sha256=hashlib.sha256(code.encode("utf-8")).hexdigest(),
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
    receipt.update(schema="APL_GERMAN_STAGE01_ROOTCAUSE_DIAGNOSTIC_V4",
                   stage01="NOT_ACCEPTED", status="GENERATED_NOT_NATIVE_VALIDATED",
                   source_commit=SOURCE_COMMIT, source_dependency_anchors=anchors,
                   dependency_probes=entries, marker_token=FINAL, marker_path=marker,
                   qa_fixed_poststir=fixed_receipt,
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
        print("ROOTCAUSE_CANDIDATE_ONLY", receipt["candidate_sha256"])
        return 0
    except Exception as e:
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_bytes((json.dumps(dict(stage01="NOT_ACCEPTED",
                 status="GENERATION_FAILED", error=f"{type(e).__name__}:{e}")) + "\n").encode())
        print(f"ROOTCAUSE_GENERATOR_FAILED:{e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
