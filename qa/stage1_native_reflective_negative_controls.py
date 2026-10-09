#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fail-closed adversarial controls over ACTUAL reflective-candidate Native traces.

Not a calendar implementation, interpreter, or simulated replacement evidence.
The normal positive 17-case audit runs first in CI. This script then corrupts
copies of its raw interpreter traces or their independently checked manifest.
A forged digest is recomputed for every corrupted trace, so rejection cannot
be explained merely by a stale SHA-256 manifest entry.
The immutable original traces and production files are never modified.
"""
import copy
import hashlib
import json
import os
import shutil
import sys
import tempfile

import stage1_native_route_graph as geometry
import stage1_native_reflective_crossing_graph_audit as graph

SOURCE = "qa/interleaved_work_counts_reflective_crossing_candidate.b98"
FOCUS = "zero_equal"
PIVOT = (958, 1324)


def require(ok, reason):
    if not ok:
        raise AssertionError(reason)


def assert_rejected(label, action, message):
    try:
        action()
    except AssertionError as error:
        require(message in str(error),
                "wrong rejection reason for %s: %s" % (label, error))
        print("NATIVE_REFLECTIVE_ADVERSARIAL_REJECT_PASS", label, str(error)[:140])
        return {"negative": label, "rejection": str(error)}
    raise AssertionError("adversarial Native evidence was falsely accepted: " + label)


def altered_trace(original_bytes, selector, change):
    lines = original_bytes.decode("ascii").splitlines(True)
    found = 0
    for index, line in enumerate(lines):
        parts = line.rstrip("\n").split("\t")
        if selector(parts):
            change(parts)
            lines[index] = "\t".join(parts) + "\n"
            found += 1
            break
    require(found == 1, "mutation selector missed real Native STEP/g/p data")
    data = "".join(lines).encode("ascii")
    require(data != original_bytes and len(data) > 50000,
            "negative control did not change a substantial Native trace")
    return data


def is_pivot(parts):
    return len(parts) == 9 and parts[0] == "STEP" and (
        int(parts[3]), int(parts[4])) == PIVOT


def change_opcode(parts):
    require(parts[7] == str(ord("[")), "expected original executed [ at pivot")
    parts[7] = str(ord("]"))


def change_velocity(parts):
    require(parts[5:7] == ["0", "-1"],
            "expected first arrival from the south under northward velocity")
    parts[5:7] = ["1", "0"]


def change_read(parts):
    parts[4] = str(int(parts[4]) + 1)


def change_write(parts):
    parts[4] = str(int(parts[4]) + 1)


def change_tick(parts):
    require(parts[1] == "1", "Native trace no longer starts at tick one")
    parts[1] = "2"


def load_inputs(root):
    with open(os.path.join(root, "reflective_candidate_proof.json"),
              "r", encoding="utf-8") as stream:
        proof = json.load(stream)
    require(proof["schema"] ==
            "befunge-stage1-native-reflective-crossing-candidate-v1",
            "wrong native input evidence schema")
    entries = proof["results"]
    require(len(entries) == 17 and entries[0]["case"] == FOCUS and
            entries[0]["branch"] == "up",
            "up-branch real trace corpus order or identity drifted")
    filename = entries[0]["trace_file"]
    require(filename == FOCUS + ".tsv", "unexpected focal native trace path")
    with open(os.path.join(root, filename), "rb") as stream:
        trace = stream.read()
    require(hashlib.sha256(trace).hexdigest() ==
            entries[0]["source_trace_sha256"],
            "native positive evidence SHA already mismatches")
    return proof, trace


def write_evidence_copy(root, proof, trace_override=None):
    """All nonfocus files are read-only symlinks; no original is overwritten."""
    directory = tempfile.mkdtemp(prefix="native-reflective-forgery-")
    for row in proof["results"]:
        name = row["trace_file"]
        require(os.path.basename(name) == name,
                "unsafe Native trace filename in received evidence")
        target = os.path.join(directory, name)
        if row["case"] == FOCUS and trace_override is not None:
            with open(target, "wb") as stream:
                stream.write(trace_override)
        else:
            os.symlink(os.path.abspath(os.path.join(root, name)), target)
    with open(os.path.join(directory, "reflective_candidate_proof.json"),
              "w", encoding="utf-8") as stream:
        json.dump(proof, stream, sort_keys=True)
    return directory


def main(root):
    require(os.path.isdir(root), "writable Native evidence folder missing")
    proof, original = load_inputs(root)
    source = geometry.load_source(SOURCE)
    original_path = os.path.join(root, FOCUS + ".tsv")
    genuine = geometry.analyze(source, original_path)
    nodes = [node for node in genuine["merge_fork_nodes"]
             if (node["x"], node["y"]) == PIVOT]
    require(len(nodes) == 1 and nodes[0]["incoming"] == 2 and
            nodes[0]["outgoing"] == 2,
            "authentic Native control has no real dual-incident pivot")

    tests = [
        ("forged_executable_opcode", is_pivot, change_opcode,
         "executed memory-byte mismatch"),
        ("forged_g_return", lambda p: p[0] == "READ_AFTER",
         change_read, "g returned unexpected cell value"),
        ("forged_p_return", lambda p: p[0] == "WRITE_AFTER",
         change_write, "p after-image mismatched actual value"),
        ("forged_execution_tick", lambda p: p[0] == "STEP",
         change_tick, "nonsequential native STEP tick"),
    ]
    results = []
    with tempfile.TemporaryDirectory(prefix="native-reflective-control-") as tmp:
        for label, selector, change, expected_error in tests:
            changed = altered_trace(original, selector, change)
            file_path = os.path.join(tmp, label + ".tsv")
            with open(file_path, "wb") as stream:
                stream.write(changed)
            results.append(assert_rejected(
                label, lambda path=file_path: geometry.analyze(source, path),
                expected_error))

    # A recomputed SHA means the graph audit must reject the forged
    # direction on semantic evidence, not on mere checksum mismatch.
    changed = altered_trace(original, is_pivot, change_velocity)
    proof_changed = copy.deepcopy(proof)
    proof_changed["results"][0]["source_trace_sha256"] = (
        hashlib.sha256(changed).hexdigest())
    folder = write_evidence_copy(root, proof_changed, changed)
    try:
        results.append(assert_rejected(
            "forged_pivot_arrival_direction", lambda: graph.main(folder),
            "Native instruction bytes/velocity history not genuine"))
    finally:
        shutil.rmtree(folder)

    for label, edit, expected_error in [
        ("forged_branch_report", lambda p: p["results"][0].update(
            {"branch": "down"}), "unselected candidate arm contaminated"),
        ("forged_trace_digest", lambda p: p["results"][0].update(
            {"source_trace_sha256": "0" * 64}), "native IP evidence digest mismatch"),
        ("reordered_case_records", lambda p: p["results"].__setitem__(
            slice(0, 2), [p["results"][1], p["results"][0]]),
         "missing reordered or extra Native corpus cases"),
    ]:
        altered = copy.deepcopy(proof)
        edit(altered)
        folder = write_evidence_copy(root, altered)
        try:
            results.append(assert_rejected(
                label, lambda directory=folder: graph.main(directory),
                expected_error))
        finally:
            shutil.rmtree(folder)

    require(len(results) == 8, "not all native adversarial cases executed")
    report = {"schema": "befunge-stage1-reflective-real-native-negative-controls-v1",
              "source": SOURCE, "focus": FOCUS,
              "status": "QA_ONLY_NOT_STAGE1_ACCEPTANCE",
              "positive_native_trace_sha256": hashlib.sha256(original).hexdigest(),
              "native_trace_mutation_count": 5,
              "manifest_corruption_count": 3,
              "rejected": results}
    with open(os.path.join(root, "reflective_native_negative_controls.json"),
              "w", encoding="utf-8") as stream:
        json.dump(report, stream, sort_keys=True, indent=2)
        stream.write("\n")
    print("NATIVE_REFLECTIVE_REAL_TRACE_NEGATIVE_CONTROLS_PASS",
          len(results), "of", len(results))
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO; only evidence-auditor adversaries")


if __name__ == "__main__":
    require(len(sys.argv) == 2,
            "usage: stage1_native_reflective_negative_controls.py NATIVE_TRACE_DIR")
    main(sys.argv[1])
