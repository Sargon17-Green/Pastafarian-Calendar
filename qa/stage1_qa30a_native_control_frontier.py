#!/usr/bin/env python3
"""QA30A: physical directed control transitions across 136 signed Native routes.

Read-only reanalysis of original QA20/QA24/QA26 compressed PyFunge STEP data.
An observed transition is not a proof of any unobserved branch's feasibility,
and a fetched runtime opcode is not automatically an original static byte.
"""
import argparse
import collections
import copy
import gzip
import hashlib
import json
from pathlib import Path

import stage1_qa27_native_directed_source_frontier as foundation

SOURCE = foundation.SOURCE
QA18_SHA = foundation.QA18_SHA
EXPECTED_CASES = 136
EXPECTED_STEPS = 4513423
KNOWN_SIX = foundation.OLDER_HITS
# Runtime opcode groups describe observed bytes, not a proof of semantics.
CONTROL = {ord(c): c for c in "xjk#?_|\"><[]w"}
MEMORY = {ord(c): c for c in "gp"}
MAX_NEAREST = 4

def require(ok, message):
    if not ok:
        raise AssertionError(message)

def sha256(raw):
    return hashlib.sha256(raw).hexdigest()

def parse_step(raw, expected_tick):
    parts = raw.rstrip(b"\r\n").split(b"\t")
    require(len(parts) == 7, "Native STEP has wrong number of fields")
    try:
        row = tuple(int(v) for v in parts)
    except ValueError as exc:
        raise AssertionError("non-numeric Native STEP") from exc
    require(row[0] == expected_tick and row[6] in (0, 1)
            and 0 <= row[5] <= 255, "Native tick / stringmode / opcode malformed")
    return row

def directed_edge(before, after):
    require(len(before) == len(after) == 7
            and after[0] == before[0] + 1, "nonconsecutive Native control transition")
    x, y, dx, dy = before[1:5]
    moved = [after[1]-x, after[2]-y]
    nominal = [dx, dy]
    return {
        "tick": before[0],
        "position": [x, y],
        "vector_before": nominal,
        "runtime_opcode": before[5],
        "stringmode_before": before[6],
        "next_tick": after[0],
        "next_position": [after[1], after[2]],
        "vector_after": [after[3], after[4]],
        "next_runtime_opcode": after[5],
        "next_stringmode": after[6],
        "observed_displacement": moved,
        "is_non_nominal": moved != nominal,
        "next_row_differs": after[2] != y,
        "pre_execution_vector_changed": list(after[3:5]) != nominal,
    }

def adversarial_edge_controls(edge, before, after):
    testcases = [
        ("changed-source-position", (1, 1)),
        ("changed-source-vector", (3, 1)),
        ("changed-source-opcode", (5, 1)),
        ("changed-source-stringmode", (6, 1)),
        ("changed-next-position", (1, 1)),
        ("changed-next-vector", (3, 1)),
        ("changed-next-opcode", (5, 1)),
        ("changed-next-stringmode", (6, 1)),
        ("changed-next-tick", (0, 1)),
    ]
    for i, (label, (field, amount)) in enumerate(testcases):
        a = list(before)
        b = list(after)
        if i <= 3:
            a[field] += amount
        else:
            b[field] += amount
        try:
            require(directed_edge(a, b) == edge, "forged directed Native edge")
        except AssertionError:
            pass
        else:
            raise AssertionError("accepted forged control edge " + label)
    # An exact duplicate/omission of a STEP must also be rejected.
    try:
        directed_edge(before, before)
    except AssertionError:
        pass
    else:
        raise AssertionError("accepted duplicate original Native STEP")
    return 10

def take_sample(previous, current, group, shard, name, target):
    edge = directed_edge(previous, current)
    distance = abs(previous[1] - target[0]) + abs(previous[2] - target[1])
    out = dict(edge)
    out["distance_from_target"] = distance
    out["input_group"] = group
    out["shard"] = shard
    out["input_label"] = name
    out["signed_source_byte_matches_runtime"] = False
    return out

def update_nearest(candidates, sample):
    candidates.append(sample)
    candidates.sort(key=lambda p: (
        p["distance_from_target"], p["input_group"],
        p["input_label"], p["tick"]))
    del candidates[MAX_NEAREST:]

def analyze_trace(folder, receipt, group, shard, source_rows, missing):
    label = receipt.get("label")
    require(isinstance(label, str) and label
            and receipt.get("path") == label + ".steps.gz"
            and receipt.get("natural_ip_no_intervention") is True
            and receipt.get("output") == receipt.get("expected")
            and len(receipt.get("output", [])) == 7,
            "original Native source input/output receipt drifted")
    if not receipt["valid"]:
        require(receipt["output"] == ["-1"]*7,
                "original rejected input suddenly produced valid output")
    path = folder / receipt["path"]
    require(path.is_file(), "missing signed original Native gzip " + label)
    packed = path.read_bytes()
    require(sha256(packed) == receipt.get("compressed_trace_sha256")
            and len(packed) == receipt.get("compressed_bytes"),
            "original compressed Native STEP SHA or length mismatch")
    counts = collections.Counter()
    neighbors = {xy: [] for xy in missing}
    previous = None
    step_count = 0
    first_edge = None
    with gzip.open(path, "rb") as stream:
        for raw in stream:
            step_count += 1
            here = parse_step(raw, step_count)
            if previous is not None and previous[6] == 0:
                op = previous[5]
                typ = ("control" if op in CONTROL
                       else "memory" if op in MEMORY else None)
                if typ:
                    char = chr(op)
                    event = directed_edge(previous, here)
                    counts["%s:%s" % (typ, char)] += 1
                    if event["is_non_nominal"]:
                        counts["nonnominal:%s" % char] += 1
                    if event["pre_execution_vector_changed"]:
                        counts["vector_changed:%s" % char] += 1
                    if event["next_row_differs"]:
                        counts["row_changed:%s" % char] += 1
                    if first_edge is None:
                        first_edge = (previous, here, event)
                    # A discovered control transition near one of the 15
                    # candidates is an observed witness, not a reachable edge
                    # into the target.
                    for xy in missing:
                        d = abs(previous[1]-xy[0])+abs(previous[2]-xy[1])
                        if d <= 9:
                            sample = take_sample(previous, here, group, shard, label, xy)
                            sx, sy = previous[1:3]
                            sample["signed_source_byte_matches_runtime"] = (
                                0 <= sy < len(source_rows) and
                                0 <= sx < len(source_rows[sy]) and
                                source_rows[sy][sx] == op)
                            update_nearest(neighbors[xy], sample)
            previous = here
    require(step_count == receipt["steps"] and step_count > 50,
            "original Native trace length mismatch")
    return counts, neighbors, step_count, first_edge

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True)
    parser.add_argument("--qa18", required=True)
    parser.add_argument("--root", required=True)
    parser.add_argument("--output", required=True)
    a = parser.parse_args()
    source_rows = foundation.verified_source(a.source)
    roles = foundation.targets(a.qa18, source_rows)
    missing = sorted(set(roles) - KNOWN_SIX)
    require(len(missing) == 15, "not exactly the frozen 15 candidates")
    totals = collections.Counter()
    global_nearest = {xy: [] for xy in missing}
    bygroup = {}
    seen = set()
    original_step_count = 0
    original_program_count = 0
    controls = 0
    first_edge = None
    for group, (run, expected_cases, expected_steps, per_shard, filename) in foundation.RUNS.items():
        counted_steps = 0
        counted_cases = 0
        for shard in range(4):
            folder = Path(a.root) / group / ("shard%d" % shard)
            manifest = json.loads((folder / filename).read_bytes())
            foundation.receipt_header(manifest, group, shard, set(roles))
            controls += foundation.negative_controls(manifest, group, shard, set(roles))
            for record in manifest["records"]:
                identity = (group, record["label"])
                require(identity not in seen, "duplicate original Native input label")
                seen.add(identity)
                count, nearest, steps, witness = analyze_trace(
                    folder, record, group, shard, source_rows, missing)
                if first_edge is None and witness is not None:
                    first_edge = witness
                counted_cases += 1
                counted_steps += steps
                totals.update(count)
                for target in missing:
                    for item in nearest[target]:
                        update_nearest(global_nearest[target], item)
        require(counted_cases == expected_cases and counted_steps == expected_steps,
                "historical Native origin case/STEP aggregate differs")
        original_program_count += counted_cases
        original_step_count += counted_steps
        bygroup[group] = {"original_run": run, "cases": counted_cases,
                          "steps": counted_steps}
    require(original_program_count == EXPECTED_CASES
            and original_step_count == EXPECTED_STEPS,
            "QA30 incomplete original 136-source Native control coverage")
    require(first_edge is not None and sum(v for k,v in totals.items()
            if k.startswith("control:")) > 0,
            "no original dynamic-control instructions observed")
    controls += adversarial_edge_controls(*(
        (directed_edge(first_edge[0], first_edge[1]), first_edge[0], first_edge[1])
    ))
    require(controls == 70, "QA30 original receipt forgery controls incomplete")
    require(all(global_nearest[xy] for xy in missing),
            "at least one of fifteen candidate controls has no nearby observation")
    result = {
        "schema": "qa30a-136-original-native-dynamic-control-frontier-v1",
        "original_production_git_blob": SOURCE,
        "original_qa18_sha256": QA18_SHA,
        "original_programs_reaudited": original_program_count,
        "original_native_steps_reaudited": original_step_count,
        "original_native_trace_hashes_revalidated": original_program_count,
        "observed_runtime_opcode_counts": dict(sorted(totals.items())),
        "nearest_observed_control_transitions_by_15_source_candidates": {
            "%d,%d" % xy: global_nearest[xy] for xy in missing},
        "original_groups": bygroup,
        "negative_provenance_and_directed_edge_controls_rejected": controls,
        "original_15_source_cells_not_certified_dead": True,
        "runtime_opcode_does_not_prove_static_byte_owner": True,
        "absence_from_sample_not_proof_of_global_unreachability": True,
        "no_forced_ip_relocation_or_program_modification": True,
        "full_geometric_spaghetti_qa_pass": False,
        "full_functional_qa_pass": False,
        "stage1_complete": False,
    }
    Path(a.output).write_text(json.dumps(result, sort_keys=True, indent=2) + "\n")
    print("QA30A_ORIGINAL_136_NATIVE_CONTROL_ROUTE_AUDIT_PASS", original_step_count)
    print("QA30A_NEGATIVE_NATIVE_EDGE_CONTROLS_REJECTED", controls)
    print("QA30A_FIFTEEN_CONTROL_NEIGHBORHOODS_DOCUMENTED_NO_DEAD_CODE_CLAIM")

if __name__ == "__main__":
    main()
