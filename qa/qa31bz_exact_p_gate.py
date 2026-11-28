#!/usr/bin/env python3
"""QA31BZ: fail-closed *preflight* for one proposed Befunge-98 native p splice.

This is NOT a Native run, a signed receipt auditor, or Stage1 acceptance.
The returned stack is a hypothetical pre-execution TOSS; callers must still
run the actual pinned interpreter, verify post-state/physical writes, and
preserve original and changed complete STEP receipts.
Python 3.11+, standard library only.
"""
from __future__ import annotations

import argparse
import copy
import json
from pathlib import Path

PROJECT = "PC-BRANCH-BEFUNGE98-KYRGYZ"
SOURCE_BLOB = "560d6aa5807a7f766213a33835cce85eab0fa40c"
CASE = "pair_30_30"
TICK = 17817
WRITER_IP = (96, 480)
TARGET = (1500, 1860)
OLD = 62
NEW = 118


class GateRejected(ValueError):
    pass


def require(ok: bool, why: str) -> None:
    if not ok:
        raise GateRejected(why)


def pair_of_ints(value: object, key: str) -> tuple[int, int]:
    require(isinstance(value, list) and len(value) == 2, key + " shape")
    require(all(type(n) is int for n in value), key + " integer values")
    return value[0], value[1]


def exact_preflight(snapshot: dict) -> dict:
    """Accept one precise p pre-state, and return its *proposed* one-cell edit.

    Snapshot MUST be captured from a real original source-bound runtime before
    p executes. A synthetic snapshot can test this function, but cannot prove
    that such a runtime state exists or identify an original signed receipt.
    """
    require(type(snapshot) is dict, "snapshot object")
    require(snapshot.get("project_id") == PROJECT, "project mismatch")
    require(snapshot.get("source_git_blob_sha1") == SOURCE_BLOB, "source mismatch")
    require(snapshot.get("case") == CASE, "case mismatch")
    require(type(snapshot.get("tick")) is int and snapshot["tick"] == TICK,
            "physical tick mismatch")
    require(pair_of_ints(snapshot.get("ip"), "ip") == WRITER_IP, "writer IP")
    require(type(snapshot.get("op")) is int and snapshot["op"] == ord("p"),
            "native p opcode")
    require(snapshot.get("string_mode") is False, "not string mode")
    require(type(snapshot.get("ip_count")) is int and snapshot["ip_count"] == 1,
            "unexpected concurrent IP")
    require(type(snapshot.get("stack_depth")) is int
            and snapshot["stack_depth"] == 1, "stack-of-stacks depth")
    require(snapshot.get("queue_mode") is False
            and snapshot.get("invert_mode") is False, "unsupported stack modes")
    so = pair_of_ints(snapshot.get("storage_offset"), "storage offset")
    require(pair_of_ints(snapshot.get("effective_target"), "effective target") == TARGET,
            "reported target")
    pre = snapshot.get("pre_toss")
    require(type(pre) is list and len(pre) >= 3, "p requires three operands")
    require(all(type(x) is int for x in pre), "non-integral stack operand")
    require(pre[-3] == OLD, "original stored value is not 62")
    # Funge-98 p consumes top y, next x, then value. Storage offset applies
    # to the physical FungeSpace address; verify this in actual Native too.
    effective = (pre[-2] + so[0], pre[-1] + so[1])
    require(effective == TARGET, "computed effective address drift")
    patched = pre.copy()
    patched[-3] = NEW
    require(patched[:-3] == pre[:-3] and patched[-2:] == pre[-2:],
            "non-value operand changed")
    return {
        "project_id": PROJECT,
        "qa": "QA31BZ",
        "scope": "STATIC_EXACT_MATCH_P_PREFLIGHT_NOT_NATIVE",
        "source_git_blob_sha1": SOURCE_BLOB,
        "case": CASE,
        "tick": TICK,
        "ip": list(WRITER_IP),
        "storage_offset": list(so),
        "effective_target": list(TARGET),
        "original_pre_toss": pre,
        "proposed_pre_toss": patched,
        "expected_p_post_toss": pre[:-3],
        "old_stored_value": OLD,
        "proposed_stored_value": NEW,
        "native_execution_observed": False,
        "signed_control_verified_by_this_function": False,
        "stage1_accepted": False,
    }


def synthetic_snapshot(so=(0, 0), prefix=()) -> dict:
    """Detached unit fixture, NEVER a signed or observed Native receipt."""
    return {
        "project_id": PROJECT, "source_git_blob_sha1": SOURCE_BLOB,
        "case": CASE, "tick": TICK, "ip": list(WRITER_IP),
        "op": ord("p"), "string_mode": False, "ip_count": 1,
        "stack_depth": 1, "queue_mode": False, "invert_mode": False,
        "storage_offset": list(so), "effective_target": list(TARGET),
        "pre_toss": list(prefix) + [OLD, TARGET[0] - so[0],
                                   TARGET[1] - so[1]],
    }


def selftest() -> dict:
    offsets = [(0, 0), (8, -13), (-1500, -1860), (29, 43)]
    prefixes = [(), (0,), (3, -7), (99, 0, 0)]
    cases = 0
    for so in offsets:
        for prefix in prefixes:
            src = synthetic_snapshot(so, prefix)
            before = copy.deepcopy(src)
            got = exact_preflight(src)
            require(src == before, "gate mutated its input")
            require(got["expected_p_post_toss"] == list(prefix),
                    "p stack consumption")
            require(got["proposed_pre_toss"][-3:] ==
                    [NEW, TARGET[0] - so[0], TARGET[1] - so[1]],
                    "only stored value may change")
            cases += 1

    baseline = synthetic_snapshot()
    attacks = [
        ("project", "project_id", "WRONG"),
        ("source", "source_git_blob_sha1", "0" * 40),
        ("case", "case", "other_case"),
        ("tick", "tick", TICK + 1),
        ("tick_bool", "tick", True),
        ("ip", "ip", [96, 481]),
        ("op", "op", ord("g")),
        ("string", "string_mode", True),
        ("ip_count", "ip_count", 2),
        ("depth", "stack_depth", 2),
        ("queue", "queue_mode", True),
        ("invert", "invert_mode", True),
        ("offset", "storage_offset", [1, 0]),
        ("target", "effective_target", [1501, 1860]),
        ("value", "pre_toss", [63, 1500, 1860]),
        ("x", "pre_toss", [62, 1501, 1860]),
        ("y", "pre_toss", [62, 1500, 1861]),
        ("underflow", "pre_toss", [1500, 1860]),
        ("noninteger", "pre_toss", [62, 1500.0, 1860]),
        ("missing", "pre_toss", None),
    ]
    rejected = []
    for label, key, mutation in attacks:
        tampered = copy.deepcopy(baseline)
        tampered[key] = mutation
        try:
            exact_preflight(tampered)
        except GateRejected:
            rejected.append(label)
        else:
            raise AssertionError("detached hostile accepted: " + label)
    require(cases == 16 and len(rejected) == len(attacks),
            "incomplete detached test matrix")
    return {
        "project_id": PROJECT, "qa": "QA31BZ",
        "status": "STATIC_CONTRACT_SELFTEST_PASS_NOT_NATIVE",
        "synthetic_positive_cases": cases,
        "detached_hostiles_rejected": len(rejected),
        "hostile_names": rejected, "native_runs": 0,
        "ci_runs": 0, "differential_native": False,
        "original_signed_control_replayed": False, "stage1_accepted": False,
    }


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--selftest", action="store_true")
    p.add_argument("--snapshot", type=Path)
    p.add_argument("--out", type=Path)
    a = p.parse_args()
    require(a.selftest != bool(a.snapshot), "choose --selftest OR --snapshot")
    result = (selftest() if a.selftest else exact_preflight(
        json.loads(a.snapshot.read_text(encoding="utf-8"))))
    payload = json.dumps(result, indent=2, sort_keys=True, ensure_ascii=False) + "\n"
    if a.out:
        a.out.write_text(payload, encoding="utf-8")
    print(payload, end="")


if __name__ == "__main__":
    main()
