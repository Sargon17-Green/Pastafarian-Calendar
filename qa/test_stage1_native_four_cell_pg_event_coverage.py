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
    source = [b" " * 10 + b"p" + b" " * 9 + b"g" + b" " * 600]
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


if __name__ == "__main__":
    main()
