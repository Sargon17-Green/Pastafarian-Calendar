#!/usr/bin/env python3
"""QA09C: source-pinned, calibrated time-bounded Native counterfactuals.

The historical three-second mutant timeout was shorter than an unmodified
successful run (~7s), so it cannot establish causal sensitivity. This QA-only
gate gives sham/unmodified and changed-source runs the SAME 18-second bound.
No result claims unbounded nontermination, final Stage-1 acceptance, or an
unpatched Funge++ native-mode PASS.
"""
from __future__ import annotations
import hashlib
import json
import time
from pathlib import Path

import stage1_spaghetti09_eighty_native as q

BOUND_SECONDS = 18
RECORD = Path("spaghetti09_calibrated_mutant_receipt.json")
QA09_ENGINE_PIN = "cd6d7f005b4fc33b486fcc2380b35406f6125ca4"

def need(ok, error):
    if not ok:
        raise AssertionError(error)

def digest(result):
    return hashlib.sha256(str(result["out"]).encode("ascii")).hexdigest()

def execute(source, seed, mode, label):
    started = time.monotonic()
    outcome = q.native(source, seed, mode=mode, seconds=BOUND_SECONDS)
    seconds = round(time.monotonic() - started, 3)
    record = {
        "case": label, "seed": seed, "mode": mode, "bound_s": BOUND_SECONDS,
        "elapsed_s": seconds, "rc": outcome["rc"],
        "numeric_values": len(outcome["out"]),
        "out_sha256": digest(outcome),
        "source_git_blob": q.gitblob(source),
    }
    print("QA09C_OBSERVATION", json.dumps(record, sort_keys=True), flush=True)
    return outcome, record

def main():
    source = q.SOURCE.read_bytes()
    need(q.gitblob(source) == q.SOURCE_SHA, "unmodified QA09 native source pin changed")
    meta = json.loads(q.MANIFEST.read_text(encoding="utf-8"))
    need(meta["candidate_blob"] == q.SOURCE_SHA and
         meta["fixture_parent_blob"] == q.FIXTURE_SHA and
         meta["stage08_parent_blob"] == q.QA08_SHA and
         meta["dimension_count"] == 17 and
         meta["generated_opcode_count"] == 80 and
         len(meta["stages"]) == 16,
         "source provenance/dimension manifest drift")
    baseline = []
    # Same bound, both inputs and both interpreter thread modes.
    for mode in ("funge", "native"):
        for seed in (1, 2):
            out, row = execute(source, seed, mode, "unmodified")
            need(out["rc"] == 0 and out["out"] == q.expected(seed),
                 "Unmodified program cannot finish under 18-second comparison budget")
            baseline.append(row)

    # Apply the same edit path to a byte-identical sham; only the changed
    # instruction bytes, not the harness or its deadline, differ.
    sham = q.change_block(
        source, lambda h, s: h.startswith("Lines 1,Origin 0:0,"), "t", "t")
    need(sham == source, "same-opcode sham changed the test program")
    shams = []
    for mode in ("funge", "native"):
        out, row = execute(sham, 1, mode, "same-source-sham")
        need(out["rc"] == 0 and out["out"] == q.expected(1),
             "same-source same-bound sham failed")
        shams.append(row)
    print("QA09C_SAME_BOUND_UNMODIFIED_AND_SHAM_PASS", flush=True)

    challenges = [
        ("fork_A", lambda h, s: h.startswith("Lines 1,Origin 0:0,"), "t", "z"),
        ("fork_B", lambda h, s: h.startswith("Lines 1,Origin 1:0,"), "t", "z"),
        ("worker_B_understack", lambda h, s: h.startswith("Lines 1,Origin 1:0,"),
         "u1u-10", "u1uz10"),
        ("worker_B_residue", lambda h, s: h.startswith("Lines 1,Origin 1:0,"),
         "/2:", "/3:"),
    ]
    mutants = []
    for name, match, old, new in challenges:
        changed = q.change_block(source, match, old, new)
        need(changed != source, "shard mutant failed to change actual Native source")
        out, row = execute(changed, 1, "funge", name)
        need(out["rc"] != 0 or out["out"] != q.expected(1),
             "Shard mutant yielded correct complete output under calibrated bound: " + name)
        row["kind"] = "shard"
        mutants.append(row)
    for entry in meta["stages"]:
        axis = entry["axis"]
        changed = q.stage_mutant(source, entry)
        need(changed != source, "stage mutant failed to change source: " + str(axis))
        seed = 1 if axis % 2 else 2
        out, row = execute(changed, seed, "funge", "stage-" + str(axis))
        need(out["rc"] != 0 or out["out"] != q.expected(seed),
             "Dimension mutant produced correct output within calibrated bound: " + str(axis))
        row["kind"] = "dimension"
        row["axis"] = axis
        mutants.append(row)
    need(len(mutants) == 20 and
         sum(x["kind"] == "shard" for x in mutants) == 4 and
         {x["axis"] for x in mutants if x["kind"] == "dimension"} == set(range(1, 17)),
         "Missing calibrated stage/shard challenge")
    doc = {
        "schema": "qa09c-calibrated-native-17d-mutants-v1",
        "pinned_original_engine": QA09_ENGINE_PIN,
        "native_engine_lifecycle_patch": "CI_checkout_only_notify_all",
        "original_source_git_blob": q.SOURCE_SHA,
        "qa08_source_git_blob": q.QA08_SHA,
        "original_fixture_git_blob": q.FIXTURE_SHA,
        "bound_s": BOUND_SECONDS,
        "unmodified_baselines": baseline, "byte_identical_shams": shams,
        "modified_source_challenges": mutants,
        "native_program_source_modified_in_repository": False,
        "unpatched_native_mode_pass": False,
        "proof_of_unbounded_nontermination": False,
        "full_functional_stage1_accepted": False,
        "full_geometric_stage1_accepted": False,
        "last_completed_stage": 0,
    }
    RECORD.write_text(json.dumps(doc, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    print("QA09C_FOUR_UNMODIFIED_AND_TWO_SAME_BYTE_SHAMS_PASS", flush=True)
    print("QA09C_TWENTY_CALIBRATED_CHANGED_SOURCE_CHALLENGES_OBSERVED", flush=True)
    print("QA09C_FINITE_TIMEOUTS_ARE_NOT_NONTERMINATION_PROOFS_STAGE1_OPEN", flush=True)

if __name__ == "__main__":
    main()
