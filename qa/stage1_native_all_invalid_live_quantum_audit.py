#!/usr/bin/env python3
"""Independent audit: 21 malformed Native inputs, two simultaneous Programs.

Rechecks exact 64-pair 128-program matrix, source pin, schedule and input
ownership, g/p/get/putspace counts, peer snapshots, input-invariant event
signatures, seven error sentinels and 16 hostile evidence mutations.
No Python calendar arithmetic or substituted execution.
"""
import copy
import hashlib
import json
import sys
from pathlib import Path

PIN = "560d6aa5807a7f766213a33835cce85eab0fa40c"
NUMERIC = ["1 0 0 0", "0 0 1 0", "2 10 0 10",
           "0 10 2 10", "3 2 0 4", "1 0 1 15055671"]
LEXICAL = ["0 -1 0 1", "-0 1 0 1", "0 1 -0 1",
           "0 1 0 -1", "0 -0 0 1", "0 0 0 -0",
           "0 -15055671 0 1", "0 15055671 0 -15055670",
           "0 1 0 1 7", "0 1 0", "0 1 0 x",
           "0 1 0 1/", "", "\n", "0 1 0 +1"]
VALID = ["0 0 0 0", "1 15055672 1 15055670",
         "0 123456789 1 987654321", "1 987654321 0 123456789",
         "0 10 0 20", "0 1 0 2"]
PROFILES = [
    {"id": "A7_B11", "left_quantum": 7,
     "right_quantum": 11, "first": "AB"},
    {"id": "B5_A13", "left_quantum": 13,
     "right_quantum": 5, "first": "BA"},
]
PAIRS = [("i%d" % i, "v%d" % (i % 6)) for i in range(21)]
PAIRS += [("i%d" % i, "i%d" % (20-i)) for i in range(10)]
PAIRS.append(("i0", "i12"))

def need(ok, why):
    if not ok:
        raise AssertionError(why)

def verify(data):
    need(data.get("schema") == "befunge-stage1-full-invalid-concurrent-v1"
         and data.get("status") == "QA_ONLY_STAGE1_OPEN"
         and data.get("source_git_blob") == PIN
         and data.get("invalid_forms") == 21
         and data.get("valid_reference_forms") == 6
         and data.get("native_real_pairs") == 64
         and data.get("native_program_executions") == 128
         and data.get("independent_native_oracle_invocations") == 18
         and data.get("profiles") == PROFILES
         and data.get("stage1_final_acceptance") is False,
         "source/status/profiles/acceptance changed")
    correct_inputs = dict(
        [("i%d" % i, raw) for i, raw in enumerate(NUMERIC + LEXICAL)] +
        [("v%d" % i, raw) for i, raw in enumerate(VALID)])
    need(data.get("input_by_label") == correct_inputs and
         len(correct_inputs) == 27,
         "Native invalid/valid input identifiers drifted")
    refs = data.get("expected_by_label")
    need(isinstance(refs, dict) and set(refs) == set(correct_inputs),
         "Native independent output label set incorrect")
    for key, values in refs.items():
        need(isinstance(values, list) and len(values) == 7 and
             all(type(v) is str for v in values),
             "native seven-column reference absent")
        if key.startswith("i"):
            need(values == ["-1"] * 7,
                 "native invalid sentinel oracle forged")
    items = data.get("records")
    need(isinstance(items, list) and len(items) == 64,
         "64 fully executed pairs missing")
    signatures = {}
    appearances = {k: 0 for k in correct_inputs}
    totals = {"reads": 0, "writes": 0, "steps": 0,
              "peer_snapshots": 0, "overlap_rounds": 0,
              "valid_reference_inputs": 6, "invalid_inputs": 21,
              "actual_native_pairs": 64}
    for i, row in enumerate(items):
        p = PROFILES[i // 32]
        left, right = PAIRS[i % 32]
        need(row.get("profile") == p["id"]
             and row.get("left") == left
             and row.get("right") == right
             and row.get("left_output") == refs[left]
             and row.get("right_output") == refs[right]
             and row.get("first_finished") in (left, right)
             and row.get("output_matches_reference") is True
             and row.get("space_access_owned_by_active_program") is True
             and row.get("peer_state_unchanged_after_every_quantum") is True
             and row.get("terminated") is True,
             "real Native peer/schedule/output invariants broken")
        for key in ("left_steps", "right_steps", "left_get", "right_get",
                    "left_put", "right_put", "left_direct_p",
                    "right_direct_p", "left_putspace", "right_putspace",
                    "overlap_rounds", "peer_snapshot_checks"):
            need(type(row.get(key)) is int and row[key] >= 0,
                 "invalid Native measured metric " + key)
        need(0 < row["left_steps"] <= 250000
             and 0 < row["right_steps"] <= 250000
             and row["left_get"] > 0 and row["right_get"] > 0
             and row["left_put"] > 0 and row["right_put"] > 0
             and row["left_put"] == row["left_direct_p"]
             and row["right_put"] == row["right_direct_p"]
             and row["left_putspace"] == row["right_putspace"] == 0
             and row["overlap_rounds"] > 0
             and row["peer_snapshot_checks"] >= 2,
             "Native state/put/read/snapshot evidence inconsistent")
        for label, side in ((left, "left"), (right, "right")):
            measured = (row[side + "_steps"], row[side + "_get"],
                        row[side + "_put"], tuple(row[side + "_output"]))
            if label in signatures:
                need(signatures[label] == measured,
                     "Native single-input trace depends on live peer or quantum")
            else:
                signatures[label] = measured
            appearances[label] += 1
            totals["reads"] += row[side + "_get"]
            totals["writes"] += row[side + "_put"]
            totals["steps"] += row[side + "_steps"]
        totals["peer_snapshots"] += row["peer_snapshot_checks"]
        totals["overlap_rounds"] += row["overlap_rounds"]
    need(len(signatures) == 27
         and all(appearances["i%d" % i] >= 2 for i in range(21))
         and all(appearances["v%d" % i] >= 2 for i in range(6)),
         "Native 21-invalid by 6-valid peer coverage incomplete")
    totals["distinct_native_input_signatures"] = len(signatures)
    return totals

def main(path):
    content = Path("src/interleaved_work_counts.b98").read_bytes()
    sha = hashlib.sha1(b"blob " + str(len(content)).encode("ascii")
                       + b"\0" + content).hexdigest()
    need(sha == PIN, "Native production source pin mismatch")
    report = json.loads((Path(path) / "native_full_invalid_live_quantum.json")
                        .read_text(encoding="utf-8"))
    totals = verify(report)
    print("NATIVE_ALL_INVALID_LIVE_INDEPENDENT_64_PAIR_PASS", totals)
    def reject(name, mutation):
        item = copy.deepcopy(report)
        mutation(item)
        try:
            verify(item)
        except AssertionError:
            print("NATIVE_ALL_INVALID_LIVE_TAMPER_REJECT_PASS", name)
            return name
        raise AssertionError("forged Native invalid peer evidence admitted: " + name)
    rejected = [
        reject("source_pin", lambda d:d.__setitem__("source_git_blob","0"*40)),
        reject("drop_pair", lambda d:d["records"].pop()),
        reject("profile_quantum", lambda d:d["profiles"][0].__setitem__("left_quantum",1)),
        reject("pair_index", lambda d:d["records"][5].__setitem__("left","i13")),
        reject("invalid_raw", lambda d:d["input_by_label"].__setitem__("i0","0 0 0 0")),
        reject("invalid_sentinel", lambda d:d["expected_by_label"]["i0"].__setitem__(0,"0")),
        reject("valid_ref_length", lambda d:d["expected_by_label"]["v0"].pop()),
        reject("output_tamper", lambda d:d["records"][0]["left_output"].__setitem__(0,"0")),
        reject("cross_program_mutation", lambda d:d["records"][0].__setitem__("peer_state_unchanged_after_every_quantum",False)),
        reject("wrong_space", lambda d:d["records"][0].__setitem__("space_access_owned_by_active_program",False)),
        reject("read_drift", lambda d:d["records"][32].__setitem__("left_get",d["records"][32]["left_get"]+1)),
        reject("write_drift", lambda d:d["records"][32].__setitem__("left_put",d["records"][32]["left_put"]+1)),
        reject("hidden_putspace", lambda d:d["records"][0].__setitem__("left_putspace",1)),
        reject("false_direct_p", lambda d:d["records"][0].__setitem__("right_direct_p",0)),
        reject("no_overlap", lambda d:d["records"][0].__setitem__("overlap_rounds",0)),
        reject("false_final_acceptance", lambda d:d.__setitem__("stage1_final_acceptance",True)),
    ]
    need(len(rejected) == 16,
         "Native concurrent invalid-input negative controls missing")
    outfile = Path(path) / "native_full_invalid_live_quantum_audit.json"
    outfile.write_text(json.dumps({
        "schema":"befunge-stage1-full-invalid-concurrent-audit-v1",
        "verified":totals,
        "adversarial_reports_rejected":rejected,
        "stage1_final_acceptance":False},sort_keys=True,indent=2)+"\n",
        encoding="utf-8")
    print("NATIVE_ALL_21_INVALID_FORMS_16_ADVERSARIES_REJECTED_PASS")

if __name__ == "__main__":
    need(len(sys.argv)==2,"usage: Native full-invalid live evidence directory")
    main(sys.argv[1])
