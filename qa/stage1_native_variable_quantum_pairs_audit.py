#!/usr/bin/env python3
"""Independent Stage-1 verifier for real PyFunge variable-quantum pair logs.

Uses no Python calendar calculation; validates native-only reference outputs,
peer/schedule invariance, bounded instrumentation and hostile-report rejection.
"""
import copy
import hashlib
import json
import sys
from pathlib import Path

PIN = "560d6aa5807a7f766213a33835cce85eab0fa40c"
PAIRS = [
    ("v0", "v1"), ("v2", "v3"), ("v4", "v5"),
    ("v0", "i0"), ("v2", "i3"), ("v4", "i4"),
    ("i1", "v1"), ("i2", "v3"), ("i5", "v5"),
    ("i0", "i3"), ("i1", "i4"), ("i2", "i5"),
]
PROFILES = [
    {"id": "A2_B3", "left_quantum": 2, "right_quantum": 3, "first": "AB"},
    {"id": "B5_A1", "left_quantum": 1, "right_quantum": 5, "first": "BA"},
    {"id": "A97_B61", "left_quantum": 97, "right_quantum": 61, "first": "AB"},
]

def need(ok, msg):
    if not ok:
        raise AssertionError(msg)

def verify(report):
    need(report.get("schema") == "befunge-stage1-variable-quantum-pair-v1"
         and report.get("source_git_blob") == PIN
         and report.get("status") == "QA_ONLY_STAGE1_OPEN"
         and report.get("native_pairs") == 36
         and report.get("native_program_executions") == 72
         and report.get("independent_native_oracle_invocations") == 18
         and report.get("final_stage1_acceptance") is False
         and report.get("variable_schedules") == PROFILES,
         "source/status or declared Native quantum corpus changed")
    refs = report.get("expected_by_label")
    need(isinstance(refs, dict)
         and set(refs) == ({"v%d" % i for i in range(6)} |
                           {"i%d" % i for i in range(6)}),
         "native reference label set changed")
    for label, values in refs.items():
        need(isinstance(values, list) and len(values) == 7
             and all(isinstance(v, str) for v in values)
             and (label[0] != "i" or values == ["-1"] * 7),
             "invalid native reference seven-output vector")
    rows = report.get("records")
    need(isinstance(rows, list) and len(rows) == 36,
         "36 native quantum pair execution records missing")
    signatures = {}
    sums = {"steps": 0, "reads": 0, "writes": 0,
            "peer_snapshots": 0, "overlap_rounds": 0}
    for index, row in enumerate(rows):
        profile = PROFILES[index // 12]
        left, right = PAIRS[index % 12]
        need(row.get("profile") == profile["id"]
             and row.get("left") == left and row.get("right") == right
             and row.get("left_output") == refs[left]
             and row.get("right_output") == refs[right]
             and row.get("first_finished") in (left, right)
             and row.get("output_matches_reference") is True
             and row.get("space_access_owned_by_active_program") is True
             and row.get("peer_state_unchanged_after_every_quantum") is True
             and row.get("terminated") is True,
             "native variable quantum pair label/output/ownership forged")
        for k in ("left_steps", "right_steps", "left_get", "right_get",
                  "left_put", "right_put", "left_direct_p",
                  "right_direct_p", "overlap_rounds",
                  "peer_snapshot_checks", "left_putspace", "right_putspace"):
            need(type(row.get(k)) is int and row[k] >= 0,
                 "native quantum metric malformed " + k)
        need(0 < row["left_steps"] <= 250000
             and 0 < row["right_steps"] <= 250000
             and row["overlap_rounds"] >= 1
             and row["peer_snapshot_checks"] >= 2
             and row["left_get"] > 0 and row["right_get"] > 0
             and row["left_put"] > 0 and row["right_put"] > 0
             and row["left_put"] == row["left_direct_p"]
             and row["right_put"] == row["right_direct_p"]
             and row["left_putspace"] == row["right_putspace"] == 0,
             "real native quantum read/write or termination evidence invalid")
        for label, side in ((left, "left"), (right, "right")):
            signature = (row[side + "_steps"], row[side + "_get"],
                         row[side + "_put"], tuple(row[side + "_output"]))
            if label in signatures:
                need(signatures[label] == signature,
                     "native read/write/steps/output depends on schedule or peer")
            else:
                signatures[label] = signature
            sums["steps"] += row[side + "_steps"]
            sums["reads"] += row[side + "_get"]
            sums["writes"] += row[side + "_put"]
        sums["peer_snapshots"] += row["peer_snapshot_checks"]
        sums["overlap_rounds"] += row["overlap_rounds"]
    need(len(signatures) == 12, "did not cover all twelve input domains")
    sums["unique_inputs"] = len(signatures)
    sums["real_native_pairs"] = 36
    return sums

def main(folder):
    source = Path("src/interleaved_work_counts.b98").read_bytes()
    blob = hashlib.sha1(b"blob " + str(len(source)).encode("ascii") +
                        b"\0" + source).hexdigest()
    need(blob == PIN, "QA production source Git blob no longer pinned")
    original = json.loads((Path(folder) / "native_quantum_pair_matrix.json")
                          .read_text(encoding="utf-8"))
    result = verify(original)
    print("NATIVE_VARIABLE_QUANTUM_INDEPENDENT_AUDIT_PASS", result)
    def reject(name, mutate):
        altered = copy.deepcopy(original)
        mutate(altered)
        try:
            verify(altered)
        except AssertionError:
            print("NATIVE_VARIABLE_QUANTUM_TAMPER_REJECT_PASS", name)
            return name
        raise AssertionError("forged native quantum report accepted: " + name)
    adversaries = [
        reject("source", lambda d: d.__setitem__("source_git_blob", "0" * 40)),
        reject("missing_pair", lambda d: d["records"].pop()),
        reject("quantum_definition", lambda d: d["variable_schedules"][0].__setitem__("left_quantum", 1)),
        reject("pair_order", lambda d: d["records"][12].__setitem__("right", "i0")),
        reject("peer_mutation", lambda d: d["records"][0].__setitem__("peer_state_unchanged_after_every_quantum", False)),
        reject("space_escape", lambda d: d["records"][0].__setitem__("space_access_owned_by_active_program", False)),
        reject("read_count_drift", lambda d: d["records"][12].__setitem__("left_get", d["records"][12]["left_get"] + 1)),
        reject("write_count_drift", lambda d: d["records"][12].__setitem__("right_put", d["records"][12]["right_put"] + 1)),
        reject("direct_p", lambda d: d["records"][0].__setitem__("left_direct_p", 0)),
        reject("putspace", lambda d: d["records"][0].__setitem__("right_putspace", 1)),
        reject("changed_output", lambda d: d["records"][0]["left_output"].__setitem__(0, "forged")),
        reject("changed_native_steps", lambda d: d["records"][24].__setitem__("left_steps", 1)),
        reject("missing_peer_checks", lambda d: d["records"][0].__setitem__("peer_snapshot_checks", 0)),
        reject("incorrect_sentinel", lambda d: d["expected_by_label"]["i0"].__setitem__(0, "0")),
        reject("unearned_completion", lambda d: d.__setitem__("final_stage1_acceptance", True)),
    ]
    need(len(adversaries) == 15, "negative controls missing")
    output = {"schema": "befunge-stage1-variable-quantum-audit-v1",
              "verified": result, "hostile_reports_rejected": adversaries,
              "stage1_final_acceptance": False}
    path = Path(folder) / "native_quantum_pair_matrix_audit.json"
    path.write_text(json.dumps(output, indent=2, sort_keys=True) + "\n",
                    encoding="utf-8")
    print("NATIVE_VARIABLE_QUANTUM_15_NEGATIVE_REPORTS_REJECTED_PASS")

if __name__ == "__main__":
    need(len(sys.argv) == 2, "usage: Native quantum evidence directory")
    main(sys.argv[1])
