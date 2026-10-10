#!/usr/bin/env python3
"""Independent Stage-1 audit of Native PyFunge live-pair interleaving.

Checks ordered evidence, native-only reference consistency, invariants and
hostile report mutations. Does not implement calendar computations in Python.
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
    ("i0", "i3"), ("i1", "i4"), ("i2", "i5")
]

def need(ok, msg):
    if not ok:
        raise AssertionError(msg)

def source_check():
    src = Path("src/interleaved_work_counts.b98").read_bytes()
    digest = hashlib.sha1(b"blob " + str(len(src)).encode("ascii") +
                          b"\0" + src).hexdigest()
    need(digest == PIN, "pinned native QA source was modified")

def verify(data):
    need(data.get("schema") == "befunge-stage1-live-pair-matrix-v1"
         and data.get("source_git_blob") == PIN
         and data.get("status") == "QA_ONLY_STAGE1_OPEN"
         and data.get("interpreter") == "PyFunge-0.5-rc2"
         and data.get("native_pair_runs") == 24
         and data.get("api_ownership_trace_instrumented") is True
         and data.get("native_program_executions") == 48
         and data.get("independent_native_oracle_calls") == 18
         and data.get("stage1_final_acceptance") is False,
         "schema/source/bounded scope or provisional Stage 1 status forged")
    e = data.get("expected_by_label")
    need(isinstance(e, dict) and set(e) ==
         {"v%d" % i for i in range(6)} | {"i%d" % i for i in range(6)},
         "native expected case labels missing")
    for label, values in e.items():
        need(isinstance(values, list) and len(values) == 7 and
             all(isinstance(x, str) for x in values),
             "native seven-field reference malformed")
        if label[0] == "i":
            need(values == ["-1"] * 7,
                 "rejected input oracle contains a non-sentinel")
    rows = data.get("records")
    need(isinstance(rows, list) and len(rows) == 24,
         "native live-pair execution evidence incomplete")
    cross = overlap = steps = gets = puts = 0
    by_label = {}
    for ix, row in enumerate(rows):
        schedule = "AB" if ix < 12 else "BA"
        l, r = PAIRS[ix % 12]
        need(row.get("left") == l and row.get("right") == r and
             row.get("schedule") == schedule and
             row.get("left_output") == e[l] and
             row.get("right_output") == e[r] and
             row.get("terminated") is True and
             row.get("private_programs") is True and
             row.get("private_spaces") is True and
             row.get("private_semantics") is True and
             row.get("private_io") is True and
             row.get("cross_program_state_unchanged") is True and
             row.get("every_api_read_write_owned_by_active_program") is True,
             "native pair order/output/private state invariant violated")
        for field in ("left_steps", "right_steps", "overlap_rounds",
                      "cross_program_checks"):
            need(type(row.get(field)) is int and 0 < row[field] <= 250000,
                 "invalid exact native execution counter")
        need(row["cross_program_checks"] >= 16 and
             row["overlap_rounds"] <= min(row["left_steps"], row["right_steps"]),
             "live parallel overlap or cross-program observations missing")
        if ix >= 12:
            prior = rows[ix - 12]
            need(row["left_output"] == prior["left_output"] and
                 row["right_output"] == prior["right_output"] and
                 row["left_steps"] == prior["left_steps"] and
                 row["right_steps"] == prior["right_steps"],
                 "alternating order unexpectedly changed Native semantics or ticks")
        for label, side in ((l, "left"), (r, "right")):
            nget = row.get(side + "_memory_gets")
            nput = row.get(side + "_memory_puts")
            ndirect = row.get(side + "_direct_p_steps")
            nspace = row.get(side + "_runtime_putspace")
            need(type(nget) is int and nget > 0 and
                 type(nput) is int and nput > 0 and
                 nput == ndirect and nspace == 0,
                 "Native live pair memory API write/read ownership invalid")
            if label in by_label:
                need(by_label[label] == (nget, nput),
                     "Native Program memory API counts changed with schedule/peer")
            else:
                by_label[label] = (nget, nput)
            gets += nget
            puts += nput
        cross += row["cross_program_checks"]
        overlap += row["overlap_rounds"]
        steps += row["left_steps"] + row["right_steps"]
    return {"native_pairs": len(rows), "native_programs": 2 * len(rows),
            "reference_program_invocations": 18,
            "cross_program_state_snapshots": cross,
            "tracked_native_memory_reads": gets,
            "tracked_native_memory_writes": puts,
            "overlap_rounds": overlap, "total_native_steps": steps}

def main(folder):
    source_check()
    path = Path(folder) / "native_live_pair_matrix.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    outcome = verify(data)
    print("NATIVE_LIVE_PAIR_MATRIX_INDEPENDENT_AUDIT_PASS", outcome)
    def reject(name, fn):
        mutant = copy.deepcopy(data)
        fn(mutant)
        try:
            verify(mutant)
        except AssertionError:
            print("NATIVE_LIVE_PAIR_TAMPER_REJECT_PASS", name)
            return name
        raise AssertionError("independent audit accepted forged native evidence: " + name)
    attacks = [
        reject("wrong_source", lambda d: d.__setitem__("source_git_blob", "0"*40)),
        reject("missing_pair", lambda d: d["records"].pop()),
        reject("swapped_schedule", lambda d: d["records"][0].__setitem__("schedule", "BA")),
        reject("swapped_label", lambda d: d["records"][2].__setitem__("right", "i1")),
        reject("forged_output", lambda d: d["records"][0]["left_output"].__setitem__(0, "forged")),
        reject("shared_space", lambda d: d["records"][0].__setitem__("private_spaces", False)),
        reject("shared_input_output", lambda d: d["records"][0].__setitem__("private_io", False)),
        reject("cross_mutation", lambda d: d["records"][0].__setitem__("cross_program_state_unchanged", False)),
        reject("absent_cross_checks", lambda d: d["records"][0].__setitem__("cross_program_checks", 0)),
        reject("forged_native_steps", lambda d: d["records"][12].__setitem__("left_steps", 1)),
        reject("forged_invalid_oracle", lambda d: d["expected_by_label"]["i0"].__setitem__(0, "0")),
        reject("unowned_memory_api", lambda d: d["records"][0].__setitem__("every_api_read_write_owned_by_active_program", False)),
        reject("forged_memory_put", lambda d: d["records"][0].__setitem__("left_memory_puts", 0)),
        reject("putspace_writes", lambda d: d["records"][0].__setitem__("right_runtime_putspace", 1)),
        reject("memory_reads_nondeterministic", lambda d: d["records"][12].__setitem__("left_memory_gets", d["records"][12]["left_memory_gets"] + 1)),
        reject("premature_completion", lambda d: d.__setitem__("stage1_final_acceptance", True)),
    ]
    need(len(attacks) == 16, "missing adversarial audit cases")
    report = {"schema": "befunge-stage1-live-pair-matrix-audit-v2",
              "source_git_blob": PIN, "verified": outcome,
              "negative_reports_rejected": attacks,
              "stage1_final_acceptance": False}
    output = Path(folder) / "native_live_pair_matrix_audit.json"
    output.write_text(json.dumps(report, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    print("NATIVE_LIVE_PAIR_MATRIX_16_HOSTILE_REPORTS_REJECTED_PASS")

if __name__ == "__main__":
    need(len(sys.argv) == 2, "usage: native live-pair evidence folder")
    main(sys.argv[1])
