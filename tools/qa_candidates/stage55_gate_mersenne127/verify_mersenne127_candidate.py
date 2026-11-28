#!/usr/bin/env python3
"""Verify exact Mersenne candidate semantics and per-call physical route execution."""
from __future__ import annotations
import hashlib
import json
import pathlib
import sys

BASELINE_SOURCE = "341927541dccc940bfc5e2b4073c21c647261278"
BASELINE_BIGINT = "86581532df7492a236283c5ee9410ca281e2e6f5"
GATE_ENGINE = "4b774c90f9a2fcdccaa2baac3ef80b0e8e99489e"
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


def read_json(path: pathlib.Path):
    return json.loads(path.read_text(encoding="utf-8"))


def check_watch(path: pathlib.Path) -> dict:
    watch = read_json(path)
    assert watch["reason"] is None
    assert watch["samples"] > 0
    assert watch["peak_sampled_matlab_tree_rss_bytes"] <= 3 * 1024**3
    assert watch["seconds"] <= 10000
    return watch


def check_profile(profile: dict, expected_blob: str, vectors: list, manifest: dict) -> None:
    assert profile["source_sha"] == BASELINE_SOURCE
    assert profile["bigint_blob"] == expected_blob
    assert profile["gate_engine_blob"] == GATE_ENGINE
    assert profile["arithmetic_vector_count"] == len(vectors) == manifest["vector_count"]
    assert len(profile["arithmetic_results"]) == len(vectors)
    for index, (vector, actual) in enumerate(zip(vectors, profile["arithmetic_results"]), 1):
        assert actual["q"] == vector["expected_q"], f"quotient mismatch {index}: {vector['tag']}"
        assert actual["r"] == vector["expected_r"], f"remainder mismatch {index}: {vector['tag']}"
        assert actual["regular_r"] == vector["expected_r"], f"regularMod mismatch {index}: {vector['tag']}"

    offsets = list(range(-12, 0)) + list(range(1, 13))
    assert profile["target_offsets"] == offsets
    assert profile["target_days"] == [-15055671 + offset for offset in offsets]
    assert profile["profiled_gate_engine_calls"] == 24
    assert len(profile["profile_gap_results"]) == 24
    assert len(profile["gap_results"]) == 48
    assert len(profile["call_seconds"]) == 48
    assert len(profile["pass_seconds"]) == 2
    assert profile["profile_gap_results"] == profile["gap_results"][:24]
    for route in ROUTES:
        assert profile["route_counts"][route]["calls"] == 24, (
            route, profile["route_counts"][route]
        )
    assert profile["total_measured_gate_seconds"] > 0
    assert profile["divmod_profile"]["calls"] > 0


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: verify_mersenne127_candidate.py OUTPUT_DIRECTORY")
    out = pathlib.Path(sys.argv[1])
    vectors_path = out / "vectors.json"
    vectors_manifest_path = out / "vectors_manifest.json"
    candidate_manifest_path = out / "candidate_manifest.json"
    baseline_dir = out / "baseline"
    candidate_dir = out / "candidate"
    required = [
        vectors_path, vectors_manifest_path, candidate_manifest_path,
        baseline_dir / "profile.json", baseline_dir / "watch.json",
        candidate_dir / "profile.json", candidate_dir / "watch.json",
    ]
    for path in required:
        assert path.is_file(), f"missing evidence: {path}"

    vectors_bytes = vectors_path.read_bytes()
    vectors_manifest = read_json(vectors_manifest_path)
    assert hashlib.sha256(vectors_bytes).hexdigest() == vectors_manifest["vectors_sha256"]
    vectors = json.loads(vectors_bytes)
    candidate_manifest = read_json(candidate_manifest_path)

    assert candidate_manifest["source_commit"] == BASELINE_SOURCE
    assert candidate_manifest["original_bigint_blob"] == BASELINE_BIGINT
    assert candidate_manifest["gate_engine_blob_unchanged"] == GATE_ENGINE
    assert candidate_manifest["legacy_remainder_adapter_blob_unchanged"] == (
        "bf7ec0147b9f3492d1e0db311f0f835a48775e85"
    )
    assert candidate_manifest["changed_paths"] == ["src/+pastafari/BigInt.m"]

    baseline = read_json(baseline_dir / "profile.json")
    candidate = read_json(candidate_dir / "profile.json")
    check_profile(baseline, BASELINE_BIGINT, vectors, vectors_manifest)
    check_profile(candidate, candidate_manifest["candidate_git_blob"], vectors, vectors_manifest)
    baseline_watch = check_watch(baseline_dir / "watch.json")
    candidate_watch = check_watch(candidate_dir / "watch.json")

    assert baseline["gap_results"] == candidate["gap_results"], (
        "the candidate changed at least one exact GateQuestionEngine gap"
    )
    baseline_passes = baseline["pass_seconds"]
    candidate_passes = candidate["pass_seconds"]
    pass_speedups = [b / c for b, c in zip(baseline_passes, candidate_passes)]
    total_speedup = baseline["total_measured_gate_seconds"] / candidate["total_measured_gate_seconds"]
    assert min(pass_speedups) >= 1.5, {
        "baseline_passes": baseline_passes,
        "candidate_passes": candidate_passes,
        "pass_speedups": pass_speedups,
    }

    summary = {
        "result": "MERSENNE127_QA_CANDIDATE_PASS",
        "stage55_accepted": False,
        "production_adoption": False,
        "baseline_source": BASELINE_SOURCE,
        "baseline_bigint_blob": BASELINE_BIGINT,
        "candidate_bigint_blob": candidate_manifest["candidate_git_blob"],
        "candidate_bigint_sha256": candidate_manifest["candidate_sha256"],
        "arithmetic_vectors": len(vectors),
        "vector_categories": vectors_manifest["categories"],
        "regularMod_independent_oracle": "PASS",
        "profiled_gate_engine_calls_per_variant": 24,
        "profiled_route_calls_per_route_per_variant": 24,
        "timed_unprofiled_gate_calls_per_variant": 48,
        "gap_outputs_identical": True,
        "baseline_pass_seconds": baseline_passes,
        "candidate_pass_seconds": candidate_passes,
        "pass_speedups": pass_speedups,
        "total_speedup": total_speedup,
        "baseline_divmod_profile": baseline["divmod_profile"],
        "candidate_divmod_profile": candidate["divmod_profile"],
        "baseline_top_functions": baseline["top_functions"][:15],
        "candidate_top_functions": candidate["top_functions"][:15],
        "baseline_watch": baseline_watch,
        "candidate_watch": candidate_watch,
        "public_4249_call_budget": "NOT TESTED; separate bounded public pilot required",
    }
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
