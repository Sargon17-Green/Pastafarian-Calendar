#!/usr/bin/env python3
"""Independent, finite QA09B receipt audit and adversarial self-test.

Checks pinned source identities and a separately computed numeric oracle for
12 native/cooperative observations; verifies that 20 bounded mutation receipts
are present. This audits receipts, NOT live native execution or causality.
"""
from __future__ import annotations
import argparse
import copy
import hashlib
import json
from pathlib import Path

SOURCE_BLOB = "275cec0add8705565d27da4233860bf42d134a27"
FIXTURE_BLOB = "e22a8b706fb84e3356db6c70aac29b9145642201"
QA08_BLOB = "4ba6902de08cf9483374f43a33f1d4ae7a14e3f6"
FORK_NAMES = {"fork_A", "fork_B", "worker_B_understack", "worker_B_residue"}

def require(condition: bool, error: str) -> None:
    if not condition:
        raise AssertionError(error)

def independently_expected(seed: int) -> list[int]:
    # Strict integer oracle. Every axis has 6 emitted values. No reference to
    # the Befunge runner, source stage compiler, or receipt-derived values.
    values = [31, 33]
    for axis in range(1, 17):
        triangular = axis * (axis + 1) // 2
        r0 = 48 + 10 * ((triangular + seed) % 2)
        r1 = 48 + 10 * ((triangular + seed + 1) % 2)
        values += [r0, 36, r1, 36, 62, axis]
    return values + [136 * seed]

def verify(doc: dict) -> dict:
    require(type(doc) is dict, "receipt is not a JSON object")
    require(doc.get("schema") == "qa09-native-17d-dual-worker-80-opcodes-v1", "schema drift")
    require(doc.get("source_blob") == SOURCE_BLOB and
            doc.get("fixture_blob") == FIXTURE_BLOB and
            doc.get("qa08_blob") == QA08_BLOB, "unpinned Native origin")
    require(type(doc.get("dimension_count")) is int and doc["dimension_count"] == 17 and
            type(doc.get("traps")) is int and doc["traps"] == 80 and
            doc.get("two_native_worker_shards") is True, "source geometry claim drift")
    good = doc.get("valid_runs")
    require(type(good) is list and len(good) == 12, "missing Native observations")
    expected_cases = {(mode, seed, rep) for mode in ("funge", "native")
                      for seed in (1, 2) for rep in range(3)}
    seen = set()
    for row in good:
        require(type(row) is dict and set(row) == {"mode", "seed", "repeat", "out_sha256"},
                "malformed valid Native receipt")
        require(type(row["seed"]) is int and type(row["repeat"]) is int and
                type(row["mode"]) is str and type(row["out_sha256"]) is str,
                "invalid Native receipt field type")
        key = (row["mode"], row["seed"], row["repeat"])
        require(key in expected_cases and key not in seen, "missing/duplicated Native case")
        seen.add(key)
        want = independently_expected(row["seed"])
        require(len(want) == 99, "independent 17D arithmetic shape wrong")
        digest = hashlib.sha256(str(want).encode("ascii")).hexdigest()
        require(row["out_sha256"] == digest, "native/cooperative output violates independent oracle")
    require(seen == expected_cases, "original 12 Native cases incomplete")
    masked = doc.get("masked_runs")
    require(type(masked) is list and len(masked) == 2 and all(
        type(x) is dict and set(x) == {"seed", "source_traps_replaced"} and
        type(x["seed"]) is int and type(x["source_traps_replaced"]) is int and
        x["source_traps_replaced"] == 80 for x in masked) and
        {x["seed"] for x in masked} == {1, 2}, "80 future-source traps not masked twice")
    muts = doc.get("mutants")
    require(type(muts) is list and len(muts) == 20, "adversarial causal controls incomplete")
    seen_names, seen_axes = set(), set()
    for item in muts:
        require(type(item) is dict and "exit" in item and
                type(item["exit"]) is int and item["exit"] != 0,
                "mutant receipt lacks a nonzero termination/timeout observation")
        if set(item) == {"name", "exit"}:
            require(type(item["name"]) is str and
                    item["name"] in FORK_NAMES and item["name"] not in seen_names,
                    "fork/shard sabotage challenge not distinct")
            seen_names.add(item["name"])
        elif set(item) == {"axis", "exit"}:
            require(type(item["axis"]) is int and
                    1 <= item["axis"] <= 16 and item["axis"] not in seen_axes,
                    "dimension-stage sabotage challenge not distinct")
            seen_axes.add(item["axis"])
        else:
            raise AssertionError("unknown mutation proof type")
    require(seen_names == FORK_NAMES and seen_axes == set(range(1, 17)),
            "not all 4 cross-shard + 16 dimension mutations present")
    return {"native_and_cooperative_observations":12,
            "independent_oracle_integer_cells_per_case":99,
            "masked_trap_cases":2, "observed_nonzero_mutant_exits":20,
            "source_git_blob":SOURCE_BLOB, "stage1_complete":False,
            "independent_live_execution_witness":False,
            "all_mutants_proven_semantically_causal":False}

def challenge(doc: dict) -> int:
    attacks = [
        ("fake-source-blob", lambda x:x.__setitem__("source_blob", "0"*40)),
        ("fake-parent-blob", lambda x:x.__setitem__("qa08_blob", "0"*40)),
        ("fake-geometry", lambda x:x.__setitem__("dimension_count", 16)),
        ("fake-two-shard", lambda x:x.__setitem__("two_native_worker_shards", 1)),
        ("missing-observation", lambda x:x["valid_runs"].pop()),
        ("duplicate-observation", lambda x:x["valid_runs"].__setitem__(11, copy.deepcopy(x["valid_runs"][0]))),
        ("fake-output", lambda x:x["valid_runs"][0].__setitem__("out_sha256", "0"*64)),
        ("fake-mode", lambda x:x["valid_runs"][0].__setitem__("mode", "synthetic")),
        ("fake-input", lambda x:x["valid_runs"][0].__setitem__("seed", 3)),
        ("fake-repetition", lambda x:x["valid_runs"][0].__setitem__("repeat", 3)),
        ("wrong-mask-count", lambda x:x["masked_runs"][0].__setitem__("source_traps_replaced", 79)),
        ("missing-mask", lambda x:x["masked_runs"].pop()),
        ("missing-mutant", lambda x:x["mutants"].pop()),
        ("inert-mutant-exit", lambda x:x["mutants"][0].__setitem__("exit", 0)),
        ("fake-duplicate-axis", lambda x:x["mutants"][-1].__setitem__("axis", 1)),
        ("wrong-fork-name", lambda x:x["mutants"][0].__setitem__("name", "forged")),
    ]
    for name, mutation in attacks:
        forged = copy.deepcopy(doc)
        mutation(forged)
        try:
            verify(forged)
        except AssertionError:
            continue
        raise AssertionError("ADVERSARIAL_RECEIPT_ACCEPTED " + name)
    return len(attacks)

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--receipt", required=True)
    ap.add_argument("--output", required=True)
    args = ap.parse_args()
    doc = json.loads(Path(args.receipt).read_text(encoding="utf-8"))
    record = verify(doc)
    controls = challenge(doc)
    require(controls == 16, "negative control count changed")
    record["forged_receipts_rejected"] = controls
    Path(args.output).write_text(json.dumps(record, indent=2, sort_keys=True)+"\n", encoding="utf-8")
    print("QA09B_INDEPENDENT_12_NATIVE_CASE_DIGESTS_MATCH_INT_ORACLE")
    print("QA09B_INDEPENDENT_20_DISTINCT_NONZERO_MUTANT_OUTCOMES")
    print("QA09B_INDEPENDENT_16_FORGED_RECEIPTS_REJECTED")
    print("QA09B_HISTORICAL_UPSTREAM_NATIVE_RED_NOT_WAIVED_STAGE1_OPEN")

if __name__ == "__main__":
    main()
