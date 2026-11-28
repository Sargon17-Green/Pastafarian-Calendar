#!/usr/bin/env python3
"""Verify the pinned Native profile, route-call counts, and Python BigInt oracle."""
from __future__ import annotations
import hashlib
import json
import pathlib
import sys

EXPECTED_SOURCE = "341927541dccc940bfc5e2b4073c21c647261278"
EXPECTED_BIGINT_BLOB = "86581532df7492a236283c5ee9410ca281e2e6f5"
EXPECTED_GATE_BLOB = "4b774c90f9a2fcdccaa2baac3ef80b0e8e99489e"
ROUTES = [
    "WorkCountsCompatibilityRoute",
    "StoneTableCompatibilityRoute",
    "HiddenCompatibilityRoute",
    "VisibleDropCompatibilityRoute",
    "GrindTableCompatibilityRoute",
    "BowlPourCompatibilityRoute",
    "BowlStirCompatibilityRoute",
    "OrderAt46CompatibilityRoute",
    "GeneralSelectionCompatibilityRoute",
]


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: verify_profile.py OUTPUT_DIRECTORY")
    out = pathlib.Path(sys.argv[1])
    vectors_path = out / "vectors.json"
    manifest_path = out / "vectors_manifest.json"
    profile_path = out / "profile.json"
    watch_path = out / "watch.json"
    for path in (vectors_path, manifest_path, profile_path, watch_path):
        if not path.is_file():
            raise SystemExit(f"missing required evidence: {path.name}")

    vectors_bytes = vectors_path.read_bytes()
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    assert hashlib.sha256(vectors_bytes).hexdigest() == manifest["vectors_sha256"]
    vectors = json.loads(vectors_bytes)
    profile = json.loads(profile_path.read_text(encoding="utf-8"))
    watch = json.loads(watch_path.read_text(encoding="utf-8"))

    assert profile["source_sha"] == EXPECTED_SOURCE
    assert profile["bigint_blob"] == EXPECTED_BIGINT_BLOB
    assert profile["gate_engine_blob"] == EXPECTED_GATE_BLOB
    assert profile["arithmetic_vector_count"] == len(vectors) == manifest["vector_count"]
    assert len(profile["arithmetic_results"]) == len(vectors)
    for index, (vector, actual) in enumerate(zip(vectors, profile["arithmetic_results"]), 1):
        assert actual["q"] == vector["expected_q"], f"quotient mismatch at vector {index}: {vector['tag']}"
        assert actual["r"] == vector["expected_r"], f"remainder mismatch at vector {index}: {vector['tag']}"

    offsets = list(range(-12, 0)) + list(range(1, 13))
    expected_targets = [-15055671 + offset for offset in offsets]
    assert profile["target_offsets"] == offsets
    assert profile["target_days"] == expected_targets
    assert profile["repeat_count"] == 2
    assert profile["gate_engine_profile_calls"] == 48
    assert len(profile["gap_results"]) == 2
    assert all(len(row) == 24 for row in profile["gap_results"])
    assert len(profile["call_seconds"]) == 2
    assert all(len(row) == 24 for row in profile["call_seconds"])

    for route in ROUTES:
        evidence = profile["route_counts"][route]
        assert evidence["calls"] == 48, (route, evidence)
        assert evidence["profile_seconds"] >= 0

    assert profile["divmod_profile"]["calls"] > 0
    assert profile["divmod_profile"]["profile_seconds"] > 0
    assert watch["reason"] is None
    assert watch["samples"] > 0
    assert watch["peak_sampled_matlab_tree_rss_bytes"] <= 3 * 1024**3
    assert watch["seconds"] <= 10000

    print(json.dumps({
        "result": "PROFILE_PASS",
        "stage55_accepted": False,
        "source_sha": profile["source_sha"],
        "arithmetic_vectors": len(vectors),
        "mersenne_127_vectors": manifest["categories"]["mersenne_127"],
        "single_limb_vectors": manifest["categories"]["single_limb"],
        "multi_limb_vectors": manifest["categories"]["multi_limb"],
        "gate_calls": profile["gate_engine_profile_calls"],
        "route_calls_each": 48,
        "total_measured_gate_seconds": profile["total_measured_gate_seconds"],
        "median_gate_call_seconds": profile["median_gate_call_seconds"],
        "p95_gate_call_seconds": profile["p95_gate_call_seconds"],
        "divmod_profile": profile["divmod_profile"],
        "top_functions": profile["top_functions"][:15],
        "peak_sampled_matlab_tree_rss_bytes": watch["peak_sampled_matlab_tree_rss_bytes"],
        "watch_seconds": watch["seconds"],
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
