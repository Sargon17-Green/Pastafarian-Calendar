#!/usr/bin/env python3
"""Regression for post-fork Native p/g receipt completeness (QA only).

Run from repository root:
  python3 qa/test_stage1_native_four_cell_pg_event_coverage.py
Requires qa/stage1_native_four_cell_full_postfork_trace_audit.py.
"""
import copy
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import stage1_native_four_cell_full_postfork_trace_audit as audit


def fixture():
    # A 514-step postfork trace; both p and g are genuine executed opcodes.
    # The write targets an unvisited Funge-space coordinate to isolate receipt
    # completeness from byte-replay effects at later instruction positions.
    source = [b" " * 10 + b"p" + b" " * 9 + b"g" + b" " * 492 + b"@" + b" " * 107]
    trace = [[i + 2, i, 0, 1, 0, source[0][i], 0] for i in range(514)]
    run = {
        "status": "normal", "remaining_ips": 0, "steps": 515,
        "gate": {"step": 1, "original": 0, "executed": 0},
        "complete_postfork_trace": trace,
        "first_512_motion": [event[1:5] for event in trace[:512]],
        "native_p_history": [{"tick": 12, "coordinate": [700, 0], "value": "7"}],
        "native_g_history": [{"tick": 22, "coordinate": [701, 0],
                              "read_before": "32", "returned": "32"}],
        "total_p_writes": 1, "total_g_reads": 1,
    }
    return source, run


def reject(source, run, label):
    try:
        audit.verify_run(run, source)
    except AssertionError:
        print("EXPECTED_REJECTION", label)
        return
    raise AssertionError("auditor accepted missing/forged physical p/g receipt: " + label)


def main():
    source, good = fixture()
    observed = audit.verify_run(good, source)
    if observed["verified_p_writes"] != 1 or observed["verified_g_reads"] != 1:
        raise AssertionError("valid physical p/g receipts not counted correctly")
    print("POSITIVE_PG_RECEIPTS_PASS")

    no_p = copy.deepcopy(good)
    no_p["native_p_history"] = []
    no_p["total_p_writes"] = 0
    reject(source, no_p, "missing_p_receipt_and_matching_total")

    no_g = copy.deepcopy(good)
    no_g["native_g_history"] = []
    no_g["total_g_reads"] = 0
    reject(source, no_g, "missing_g_receipt_and_matching_total")

    forged = copy.deepcopy(good)
    forged["native_p_history"][0]["tick"] = 13  # blank opcode
    reject(source, forged, "p_receipt_on_blank_opcode")

    in_string = copy.deepcopy(good)
    in_string["complete_postfork_trace"][10][6] = 1
    reject(source, in_string, "p_receipt_in_stringmode")
    # A normal termination claim must be backed by an executed @, not merely
    # by a normal status and zero remaining IPs. This catches regressions
    # where a synthetic trace silently stops after a nonterminating opcode.
    forged_halt = copy.deepcopy(good)
    forged_halt["complete_postfork_trace"][-1][5] = ord(" ")
    # Mutate the physical source too, so the only remaining reason to reject
    # is the absence of an executed terminal @, not source-byte mismatch.
    forged_source = [source[0][:513] + b" " + source[0][514:]]
    # Assert the *specific* terminal invariant, not merely some unrelated
    # validation failure (e.g. a mismatch elsewhere in the receipt).
    try:
        audit.verify_run(forged_halt, forged_source)
    except AssertionError as exc:
        if "Native complete route ended without executed terminating @" not in str(exc):
            raise AssertionError("terminal mutation rejected for wrong reason: " + str(exc)) from exc
    else:
        raise AssertionError("auditor accepted a physically nonterminating final instruction")
    print("POSTFORK_TERMINAL_OPCODE_FORGERY_REJECT_PASS")

    print("POSTFORK_PG_EVENT_COVERAGE_4_NEGATIVE_CONTROLS_PASS")

    # Reentrancy and state ownership: separate Native receipts must not
    # share mutable Funge-space; failures must not poison later checks.
    changed = copy.deepcopy(good)
    changed["native_p_history"][0]["coordinate"] = [702, 0]
    changed["native_g_history"][0]["coordinate"] = [702, 0]
    changed["native_g_history"][0]["read_before"] = "7"
    changed["native_g_history"][0]["returned"] = "7"
    original_good = copy.deepcopy(good)
    original_changed = copy.deepcopy(changed)
    first = audit.verify_run(good, source)
    second = audit.verify_run(changed, source)
    if audit.verify_run(good, source) != first:
        raise AssertionError("auditor control result depends on previous Funge-space")
    if audit.verify_run(changed, source) != second:
        raise AssertionError("auditor read-after-write result depends on call order")
    bad_changed = copy.deepcopy(changed)
    bad_changed["native_g_history"][0]["returned"] = "8"
    reject(source, bad_changed, "bad_read_after_write_does_not_poison_next_call")
    if audit.verify_run(changed, source) != second:
        raise AssertionError("failed verification poisoned subsequent valid call")
    if audit.verify_run(good, source) != first:
        raise AssertionError("failed verification poisoned original control call")
    if good != original_good or changed != original_changed:
        raise AssertionError("auditor mutated caller-owned Native evidence")
    if first["verified_p_writes"] != 1 or second["verified_g_reads"] != 1:
        raise AssertionError("independent Native memory histories not retained")
    print("POSTFORK_PG_STATE_OWNERSHIP_REENTRANCY_PASS")

    # A write recorded BEFORE the fork must seed the post-fork memory replay.
    # The post-fork trace is shifted by one tick; its geometry is unchanged.
    # Pre-fork opcode provenance is outside this auditor's trace scope.
    def prefork_written(value):
        case = copy.deepcopy(good)
        case["steps"] += 1
        case["gate"]["step"] += 1
        for event in case["complete_postfork_trace"]:
            event[0] += 1
        for event in case["native_p_history"] + case["native_g_history"]:
            event["tick"] += 1
        case["native_p_history"].insert(0, {
            "tick": 1, "coordinate": [701, 0], "value": str(value)
        })
        case["total_p_writes"] += 1
        case["native_g_history"][0]["read_before"] = str(value)
        case["native_g_history"][0]["returned"] = str(value)
        return case

    before7 = prefork_written(7)
    before9 = prefork_written(9)
    before7_snapshot = copy.deepcopy(before7)
    before9_snapshot = copy.deepcopy(before9)
    seven_result = audit.verify_run(before7, source)
    nine_result = audit.verify_run(before9, source)
    if seven_result["verified_p_writes"] != 2 or nine_result["verified_p_writes"] != 2:
        raise AssertionError("pre-fork write not counted in Native state replay")
    if audit.verify_run(before9, source) != nine_result:
        raise AssertionError("pre-fork memory history changed across repeated verification")
    if audit.verify_run(before7, source) != seven_result:
        raise AssertionError("pre-fork memory history leaked across input order")

    forged_before = copy.deepcopy(before7)
    forged_before["native_g_history"][0]["returned"] = "9"
    forged_before["native_g_history"][0]["read_before"] = "9"
    reject(source, forged_before, "forged_prefork_write_read_value")
    missing_before = copy.deepcopy(before7)
    missing_before["native_p_history"].pop(0)
    missing_before["total_p_writes"] -= 1
    reject(source, missing_before, "missing_prefork_write_receipt")
    if audit.verify_run(before7, source) != seven_result:
        raise AssertionError("failed pre-fork verification poisoned valid memory history")
    if before7 != before7_snapshot or before9 != before9_snapshot:
        raise AssertionError("pre-fork verification mutated caller-owned Native evidence")
    print("POSTFORK_PG_PREFORK_SEED_ISOLATION_2_NEGATIVE_CONTROLS_PASS")

    # Allow a nonadjacent instruction on the same travel axis: native
    # whitespace scanning must not be mistaken for a forged teleport.
    skipped=copy.deepcopy(good)
    skipped["complete_postfork_trace"][11][1:5]=[91,0,1,0]
    skipped["first_512_motion"][11]=[91,0,1,0]
    skip_result=audit.verify_run(skipped,source)
    if (skip_result["verified_p_writes"]!=1 or
        skip_result["verified_g_reads"]!=1):
        raise AssertionError("legitimate collinear whitespace skip wrongly rejected")
    if skip_result["complete_trace_sha256"]==observed["complete_trace_sha256"]:
        raise AssertionError("changed route geometry not recorded in trace hash")
    print("POSTFORK_PG_COLLINEAR_WHITESPACE_SKIP_ACCEPT_PASS")

    # Funge-98 may skip whitespace, so do not assume that the next
    # executed instruction is exactly one cell away. However p/g cannot
    # rotate the IP or move it off its established directed axis.
    for label,index,motion in (
        ("p_transverse_teleport",11,[91,1,1,0]),
        ("g_forged_velocity_reversal",21,[21,0,-1,0]),
    ):
        forged=copy.deepcopy(good)
        forged["complete_postfork_trace"][index][1:5]=motion
        forged["first_512_motion"][index]=list(motion)
        reject(source, forged, label)
    print("POSTFORK_PG_VECTOR_AXIS_2_NEGATIVE_CONTROLS_PASS")


def prefork_provenance_regression():
    # Two actual opcode bytes at the gate side of a small synthetic fixture;
    # 514 subsequent steps preserve the existing regression corpus.
    source, run = fixture()
    raw = bytearray(source[0])
    raw[600] = ord("p")
    raw[601] = ord("|")
    source = [bytes(raw)]
    run["steps"] += 1
    run["gate"]["step"] += 1
    for item in run["complete_postfork_trace"]:
        item[0] += 1
    for item in run["native_p_history"] + run["native_g_history"]:
        item["tick"] += 1
    run["native_p_history"].insert(0, {
        "tick": 1, "coordinate": [701, 0], "value": "7"
    })
    run["total_p_writes"] += 1
    run["native_g_history"][0]["read_before"] = "7"
    run["native_g_history"][0]["returned"] = "7"
    run["complete_prefork_trace"] = [
        [1, 600, 0, 1, 0, ord("p"), 0],
        [2, 601, 0, 1, 0, ord("|"), 0],
    ]
    positive = audit.verify_run(run, source, require_prefork=True)
    if positive["verified_prefork_executed_steps"] != 2:
        raise AssertionError("Native pre-fork opcode witness not verified")
    original = copy.deepcopy(run)
    probes = (
        ("forged_prefork_p_at_gate", lambda d: (
            d["native_p_history"].insert(1, {
                "tick": 2, "coordinate": [222222, 333333], "value": "99"
            }), d.__setitem__("total_p_writes", d["total_p_writes"] + 1))),
        ("missing_actual_prefork_p", lambda d: (
            d["native_p_history"].pop(0),
            d.__setitem__("total_p_writes", d["total_p_writes"] - 1),
            d["native_g_history"][0].__setitem__("read_before", "32"),
            d["native_g_history"][0].__setitem__("returned", "32"))),
        ("prefork_source_byte_forgery", lambda d:
            d["complete_prefork_trace"][0].__setitem__(5, 32)),
        ("prefork_gate_opcode_forgery", lambda d:
            d["complete_prefork_trace"][1].__setitem__(5, 32)),
        ("missing_new_schema_prefork", lambda d:
            d.pop("complete_prefork_trace")),
        ("truncated_prefork", lambda d:
            d["complete_prefork_trace"].pop(0)),
        ("prefork_out_of_order", lambda d:
            d["complete_prefork_trace"][0].__setitem__(0, 2)),
    )
    for name, corrupt in probes:
        bad = copy.deepcopy(run)
        corrupt(bad)
        try:
            audit.verify_run(bad, source, require_prefork=True)
        except AssertionError:
            print("EXPECTED_REJECTION", name)
        else:
            raise AssertionError("forged Native pre-fork opcode receipt accepted: " + name)
    if run != original:
        raise AssertionError("Native pre-fork auditor modified caller-owned evidence")
    print("NATIVE_PREFORK_ALL_OPCODES_SEVEN_FALSIFICATIONS_REJECT_PASS")



def gate_anchor_regression():
    # Synthetic event fixture, physically anchored to the pinned | cell at
    # (951,1335). Immediately after the downward-to-upward gate branch, a
    # real > turns the IP right. It then executes p, g and finally @ along
    # one contiguous horizontal line, with no invented direction change.
    row0=b" "*10+b"p"+b" "*9+b"g"+b" "*492+b"@"+b" "*107
    row1334=b" "*951+b">>"+b" "*8+b"p"+b" "*9+b"g"+b" "*492+b"@"+b" "*107
    source=[row0]+[b""]*1332+[b" "*951+b">",row1334,b" "*950+b"p||"]
    trace=[[3,951,1334,0,-1,ord(">"),0]]
    trace += [[step+3,951+step,1334,1,0,source[1334][951+step],0]
              for step in range(1,514)]
    run=dict(status="normal",remaining_ips=0,steps=516,
        gate=dict(step=2,original=1,executed=1),
        complete_prefork_trace=[[1,950,1335,1,0,ord("p"),0],
                                [2,951,1335,1,0,ord("|"),0]],
        complete_postfork_trace=trace,
        first_512_motion=[entry[1:5] for entry in trace[:512]],
        native_p_history=[dict(tick=1,coordinate=[701,0],value="7"),
                          dict(tick=13,coordinate=[700,0],value="7")],
        native_g_history=[dict(tick=23,coordinate=[701,0],
                               read_before="7",returned="7")],
        total_p_writes=2,total_g_reads=1)
    preserved=copy.deepcopy(run)
    positive=audit.verify_run(run,source,require_prefork=True,
                               require_gate_anchor=True)
    if positive["verified_prefork_executed_steps"]!=2:
        raise AssertionError("physical gate Native pretrace not verified")
    print("GATE_ANCHOR_STRICT_V2_POSITIVE_PASS")

    # A physical > must set the next IP velocity to east. Do not allow a
    # forged westward velocity to hide behind otherwise correct source bytes.
    wrong_fixed_turn = copy.deepcopy(run)
    wrong_fixed_turn["complete_postfork_trace"][1][3] = -1
    wrong_fixed_turn["first_512_motion"][1][2] = -1
    try:
        audit.verify_run(wrong_fixed_turn, source, require_prefork=True,
                         require_gate_anchor=True)
    except AssertionError as exc:
        if "Native post-fork fixed turn opcode did not set required direction" not in str(exc):
            raise AssertionError("fixed-turn forgery rejected for wrong reason: " + str(exc)) from exc
    else:
        raise AssertionError("forged westward successor to > was accepted")
    print("GATE_ANCHOR_FIXED_TURN_DIRECTION_FORGERY_REJECT_PASS")

    # Test the SAME fixed-turn contract *before* the physical fork.
    # Replacing the physical p with > changes no postfork evidence: the
    # postfork p still writes 7 before g reads it.
    preturn_source=copy.deepcopy(source)
    preturn_row=bytearray(preturn_source[-1])
    preturn_row[950]=ord(">")
    preturn_source[-1]=bytes(preturn_row)
    preturn=copy.deepcopy(run)
    preturn["complete_prefork_trace"][0][5]=ord(">")
    preturn["native_p_history"].pop(0)
    preturn["total_p_writes"]-=1
    audit.verify_run(preturn,preturn_source,require_prefork=True,
                     require_gate_anchor=True)
    forged_preturn=copy.deepcopy(preturn)
    forged_preturn["complete_prefork_trace"][1][3]=-1
    try:
        audit.verify_run(forged_preturn,preturn_source,require_prefork=True,
                         require_gate_anchor=True)
    except AssertionError as exc:
        if "Native pre-fork fixed turn opcode did not set required direction" not in str(exc):
            raise AssertionError("prefork fixed-turn forgery rejected for wrong reason: "+str(exc)) from exc
    else:
        raise AssertionError("forged westward successor to prefork > was accepted")
    print("GATE_ANCHOR_PREFORK_FIXED_TURN_FORGERY_REJECT_PASS")

    def shift_first_x(r):
        r["complete_postfork_trace"][0][1]=952
        r["complete_postfork_trace"][0][5]=ord(">")
    def flip_first_delta(r):
        r["complete_postfork_trace"][0][4]=1
    def flip_gate_operand(r):
        r["gate"]["executed"]=0
    def shift_gate_coordinate(r):
        r["complete_prefork_trace"][-1][1]=952
    def skip_first_cell(r):
        r["complete_postfork_trace"][0][2]=1333
        r["complete_postfork_trace"][0][5]=ord(">")
    for name,mutate in (
        ("wrong_postfork_x",shift_first_x),
        ("wrong_postfork_delta",flip_first_delta),
        ("wrong_branch_operand",flip_gate_operand),
        ("wrong_prefork_gate_x",shift_gate_coordinate),
        ("skipped_physical_first_cell",skip_first_cell)):
        bad=copy.deepcopy(run)
        mutate(bad)
        bad["first_512_motion"][0]=bad["complete_postfork_trace"][0][1:5]
        # Prove rejection comes from the new physical gate invariant.
        audit.verify_run(bad,source,require_prefork=True,
                         require_gate_anchor=False)
        try:
            audit.verify_run(bad,source,require_prefork=True,
                             require_gate_anchor=True)
        except AssertionError:
            print("GATE_ANCHOR_EXPECTED_REJECTION",name)
        else:
            raise AssertionError("forged physical | passed gate anchor: "+name)

    # Legacy evidence without pre-fork instructions must never claim that
    # a p-overwritten physical | was executed, even if its post-route fits.
    legacy=copy.deepcopy(run)
    legacy.pop("complete_prefork_trace")
    legacy["native_p_history"][0]["coordinate"]=[951,1335]
    legacy["native_p_history"][0]["value"]="32"
    legacy["native_g_history"][0]["read_before"]="32"
    legacy["native_g_history"][0]["returned"]="32"
    audit.verify_run(legacy,source,require_prefork=False,
                     require_gate_anchor=False)
    try:
        audit.verify_run(legacy,source,require_prefork=False,
                         require_gate_anchor=True)
    except AssertionError:
        print("GATE_ANCHOR_EXPECTED_REJECTION","legacy_overwritten_gate")
    else:
        raise AssertionError("overwritten physical | passed legacy check")
    if run!=preserved:
        raise AssertionError("physical gate verifier mutated caller-owned data")
    print("GATE_ANCHOR_SIX_TARGETED_FALSIFICATIONS_REJECT_PASS")



def stringmode_continuity_regression():
    # In a legitimate BF98 quote pair, the bytes inside the pair are
    # pushed as literals. An in-string p has NO physical write receipt.
    source, run = fixture()
    row = bytearray(source[0])
    for x, value in ((200, 34), (201, ord("p")), (202, 34)):
        row[x] = value
    source = [bytes(row)]
    for x, mode in ((200, 0), (201, 1), (202, 1)):
        run["complete_postfork_trace"][x][5] = row[x]
        run["complete_postfork_trace"][x][6] = mode
    unchanged = copy.deepcopy(run)
    a = audit.verify_run(run, source)
    if a["verified_p_writes"] != 1 or a["verified_g_reads"] != 1:
        raise AssertionError("genuine quoted BF98 p was not treated as data")
    print("NATIVE_STRINGMODE_REAL_QUOTES_POSITIVE_PASS")

    for index, label in (
        (200, "quote_open_wrong_mode"),
        (201, "in_string_p_wrong_mode"),
        (202, "quote_close_wrong_mode"),
        (203, "stale_stringmode_after_close"),
        (513, "spontaneous_late_stringmode"),
    ):
        bad = copy.deepcopy(run)
        bad["complete_postfork_trace"][index][6] ^= 1
        reject(source, bad, label)
    hidden_p = copy.deepcopy(run)
    hidden_p["complete_postfork_trace"][10][6] = 1
    hidden_p["native_p_history"] = []
    hidden_p["total_p_writes"] = 0
    reject(source, hidden_p, "p_receipt_hidden_using_forged_stringmode")
    hidden_g = copy.deepcopy(run)
    hidden_g["complete_postfork_trace"][20][6] = 1
    hidden_g["native_g_history"] = []
    hidden_g["total_g_reads"] = 0
    reject(source, hidden_g, "g_receipt_hidden_using_forged_stringmode")
    if run != unchanged:
        raise AssertionError("postfork mode verifier mutated caller-owned data")

    before, seeded = fixture()
    physical = bytearray(before[0])
    physical[600:605] = b'"p"p|'
    before = [bytes(physical)]
    seeded["steps"] += 4
    seeded["gate"]["step"] += 4
    for entry in seeded["complete_postfork_trace"]:
        entry[0] += 4
    for entry in seeded["native_p_history"] + seeded["native_g_history"]:
        entry["tick"] += 4
    seeded["native_p_history"].insert(0, {
        "tick": 4, "coordinate": [701, 0], "value": "7"
    })
    seeded["total_p_writes"] += 1
    seeded["native_g_history"][0]["read_before"] = "7"
    seeded["native_g_history"][0]["returned"] = "7"
    seeded["complete_prefork_trace"] = [
        [1, 600, 0, 1, 0, 34, 0],
        [2, 601, 0, 1, 0, ord("p"), 1],
        [3, 602, 0, 1, 0, 34, 1],
        [4, 603, 0, 1, 0, ord("p"), 0],
        [5, 604, 0, 1, 0, ord("|"), 0],
    ]
    original = copy.deepcopy(seeded)
    if audit.verify_run(seeded, before, require_prefork=True)[
            "verified_prefork_executed_steps"] != 5:
        raise AssertionError("genuine prefork quote sequence rejected")
    for index, label in ((0, "spontaneous_initial_prefork_stringmode"),
                         (2, "closing_prefork_quote_forgery")):
        bad = copy.deepcopy(seeded)
        bad["complete_prefork_trace"][index][6] ^= 1
        reject_prefork_mode(before, bad, label)
    if seeded != original:
        raise AssertionError("prefork stringmode verifier mutated input")
    print("NATIVE_STRINGMODE_NINE_MODE_FORGERIES_REJECT_PASS")


def reject_prefork_mode(source, run, label):
    try:
        audit.verify_run(run, source, require_prefork=True)
    except AssertionError:
        print("EXPECTED_REJECTION", label)
        return
    raise AssertionError("accepted pre-fork BF98 stringmode forgery: " + label)

if __name__ == "__main__":
    main()
    prefork_provenance_regression()
    gate_anchor_regression()
    stringmode_continuity_regression()
