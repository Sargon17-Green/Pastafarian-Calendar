#!/usr/bin/env python3
"""Stage56 B5: independently fingerprint pinned source and check opt-in JDN parity.

A PASS here is boundary-only. The unshifted PHP comparator remains a failing gate.
No PHP algorithms, canonical source, or year profiles are modified by this probe.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import sys
from pathlib import Path

from stage56_compare_php_sauce import SOURCE, PROJECT, TARGETS, compare, compare_shifted

# Independently observed in the completed, exact-SHA Actions provenance manifest.
# These are constants; neither the PHP probe nor CLI arguments may select them.
SOURCE_FILES = {
    "implementations/python/pastafari_calendar/core.py": "c0f5d18836dc3494affcb8122b863242e35958c7f90928608ccc0f779883a1ef",
    "browser/pastafari-calendar-fast.js": "9855be62ebe9e9e24d301f849dc010e8195fa8cf7857b45c492b60a2bb0c60ef",
    "verification/reference-oracle/reference.mjs": "21c103d3540eb5481445a190cef98f2628de7eb90b7240879fede0d519cf4a95",
}


def check_source_bytes(canonical: Path, manifest: Path) -> None:
    for relative, expected in SOURCE_FILES.items():
        actual = hashlib.sha256((canonical / relative).read_bytes()).hexdigest()
        if actual != expected:
            raise ValueError("STAGE56_SOURCE_BYTES_MISMATCH:" + relative)
    expected_lines = {digest + "  " + path for path, digest in SOURCE_FILES.items()}
    actual_lines = manifest.read_text(encoding="utf-8").splitlines()
    if len(actual_lines) != len(expected_lines) or set(actual_lines) != expected_lines:
        raise ValueError("STAGE56_SOURCE_MANIFEST_MISMATCH")


def prove(probe: dict, canonical: Path, manifest: Path) -> dict:
    check_source_bytes(canonical, manifest)
    # The existing comparator independently verifies exact Git HEAD, cleanliness,
    # remote origin, and GITHUB_SHA before running pinned source Python semantics.
    raw = compare(probe, canonical)
    translated = compare_shifted(probe, canonical)
    if [x["year"] for x in raw["years"]] != list(TARGETS):
        raise ValueError("STAGE56_RAW_YEAR_ORDER")
    if not all(x["status"] == "MISMATCH" for x in raw["years"]):
        raise ValueError("STAGE56_RAW_HISTORICAL_MISMATCH_UNEXPECTED")
    if translated["status"] != "PASS" or not all(
        x["status"] == "PASS" and not x["mismatch_fields"]
        for x in translated["translated_years"]
    ):
        raise ValueError("STAGE56_SOURCE_BOUND_BOUNDARY_MISMATCH")
    return {
        "project_id": PROJECT,
        "php_branch_sha": probe["branch_sha"],
        "pinned_source_commit": SOURCE,
        "pinned_source_sha256": SOURCE_FILES,
        "status": "PASS_BOUNDARY_ONLY",
        "raw_php_legacy_status": "MISMATCH",
        "translated_years": [x["year"] for x in translated["translated_years"]],
        "stage56_accepted": False,
        "real_year_profiles_accepted": False,
    }


def mutation_checks(probe: dict, canonical: Path, manifest: Path) -> int:
    cases = []

    def mutate(label, path, value):
        candidate = copy.deepcopy(probe)
        node = candidate
        for part in path[:-1]:
            node = node[part]
        node[path[-1]] = value
        cases.append((label, candidate))

    mutate("WRONG_PROJECT", ["project_id"], "WRONG")
    mutate("WRONG_COMMIT", ["reference_source_commit"], "0" * 40)
    mutate("WRONG_BRANCH_SHA", ["branch_sha"], "1" * 40)
    mutate("BAD_SHIFT", ["foundation_coordinate_diagnostic", "shift_jdn"], -1721424)
    mutate("BAD_FOUNDATION", ["foundation_coordinate_diagnostic", "reference_origin_jdn"], 0)
    mutate("BAD_TARGET", ["foundation_coordinate_diagnostic", "translated_records", 0, "target_jdn"], 0)
    mutate("BAD_BOWL", ["foundation_coordinate_diagnostic", "translated_records", 0, "bowls"], ["0"] * 6)
    mutate("BAD_ORDER", ["foundation_coordinate_diagnostic", "translated_records", 1, "drop46_order"], [1, 2, 3, 4, 5, 6])
    mutate("BAD_FIRST", ["foundation_coordinate_diagnostic", "translated_records", 2, "response_first"], "0")
    mutate("BAD_STEP", ["foundation_coordinate_diagnostic", "translated_records", 0, "response_step"], 0)
    mutate("BAD_NEXT", ["foundation_coordinate_diagnostic", "translated_records", 0, "next_bowl_id"], 0)
    for name, candidate in cases:
        try:
            prove(candidate, canonical, manifest)
        except (ValueError, KeyError, TypeError):
            continue
        raise ValueError("STAGE56_FAIL_OPEN_MUTATION:" + name)
    forged = manifest.parent / "stage56-source-manifest-corrupted.test"
    try:
        forged.write_text("0" * 64 + "  implementations/python/pastafari_calendar/core.py\n", encoding="utf-8")
        try:
            prove(probe, canonical, forged)
        except ValueError:
            pass
        else:
            raise ValueError("STAGE56_FAIL_OPEN_MUTATION:BAD_MANIFEST")
    finally:
        forged.unlink(missing_ok=True)
    return len(cases) + 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--canonical-repo", type=Path, required=True)
    parser.add_argument("--source-manifest", type=Path, required=True)
    parser.add_argument("--php-input", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--test-mutations", action="store_true")
    args = parser.parse_args()
    try:
        canonical = args.canonical_repo.resolve()
        manifest = args.source_manifest.resolve()
        probe = json.loads(args.php_input.read_text(encoding="utf-8"))
        result = prove(probe, canonical, manifest)
        if args.test_mutations:
            result["fail_closed_mutations"] = mutation_checks(probe, canonical, manifest)
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        print("STAGE56_SOURCE_BOUND_BOUNDARY status=PASS_BOUNDARY_ONLY"
              " raw=MISMATCH stage56_accepted=NO"
              f" mutations={result.get('fail_closed_mutations', 0)}")
        return 0
    except (OSError, ValueError, KeyError, TypeError) as error:
        print("STAGE56_SOURCE_BOUND_BOUNDARY_FAIL: " + str(error), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
