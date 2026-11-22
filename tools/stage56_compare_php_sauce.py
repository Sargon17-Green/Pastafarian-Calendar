#!/usr/bin/env python3
"""Stage56 QA: isolate PHP/Python sauce divergence without full-year profiles."""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

PROJECT = "PC-BRANCH-PHP-MALAY"
SOURCE = "cc2cf0b422757a5e7c33218ce30cffa8f99c6786"
TARGETS = {4999: -13340403, 5000: -13336277, 5001: -13332033}
CALCULATION = -13334246


def git(root: Path, *arguments: str) -> str:
    process = subprocess.run(
        ["git", "-C", str(root), *arguments], text=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
    )
    if process.returncode or process.stderr:
        raise ValueError("canonical Git verification failed")
    return process.stdout.strip()


def first_difference(actual: list, expected: list) -> dict | None:
    for index in range(max(len(actual), len(expected))):
        item = actual[index] if index < len(actual) else None
        reference = expected[index] if index < len(expected) else None
        if item != reference:
            return {"index": index, "php": item, "python": reference}
    return None


def compare(probe: dict, canonical: Path) -> dict:
    if not canonical.is_dir() or git(canonical, "rev-parse", "HEAD") != SOURCE:
        raise ValueError("canonical source HEAD is not pinned")
    if git(canonical, "status", "--porcelain", "--untracked-files=all"):
        raise ValueError("canonical checkout is not clean")
    origin = git(canonical, "remote", "get-url", "origin")
    if origin not in (
        "https://github.com/Sargon17-Green/pastafari-calendar",
        "https://github.com/Sargon17-Green/pastafari-calendar.git",
        "git@github.com:Sargon17-Green/pastafari-calendar.git",
    ):
        raise ValueError("canonical repository origin does not match")
    if (probe.get("project_id") != PROJECT or
        probe.get("reference_source_commit") != SOURCE or
        probe.get("calculation_jdn") != CALCULATION or
        probe.get("php_bowl_indexing") != "1..6" or
        probe.get("stage56_accepted") is not False or
        not isinstance(probe.get("branch_sha"), str) or
        len(probe["branch_sha"]) != 40 or
        probe["branch_sha"] != os.environ.get("GITHUB_SHA") or
        not isinstance(probe.get("records"), list) or
        len(probe["records"]) != len(TARGETS)):
        raise ValueError("PHP diagnostic envelope invalid")
    sys.dont_write_bytecode = True
    sys.path.insert(0, str(canonical / "implementations" / "python"))
    from pastafari_calendar.core import response_descriptor, sauce

    rows = []
    for row, (year, target) in zip(probe["records"], TARGETS.items()):
        if (row.get("year"), row.get("target_jdn")) != (year, target):
            raise ValueError("PHP diagnostic year/order/target mismatch")
        state = sauce(CALCULATION, target)
        python_bowls = [str(value) for value in state.bowls]
        php_bowls = row.get("bowls")
        python_order = [value + 1 for value in state.last_drop_permutation]
        php_order = row.get("drop46_order")
        descriptor = response_descriptor(state, 2, 30)  # Python bowl=2 -> PHP bowl=3
        position = state.last_drop_permutation.index(2)
        python_next_bowl = state.last_drop_permutation[(position + 1) % 6] + 1
        differences = {
            "bowls": first_difference(php_bowls, python_bowls)
            if isinstance(php_bowls, list) else {"php": php_bowls, "python": python_bowls},
            "drop46_order": first_difference(php_order, python_order)
            if isinstance(php_order, list) else {"php": php_order, "python": python_order},
            "response_first": None if row.get("response_first") == str(descriptor.first)
            else {"php": row.get("response_first"), "python": str(descriptor.first)},
            "response_step": None if row.get("response_step") == descriptor.step
            else {"php": row.get("response_step"), "python": descriptor.step},
            "next_bowl_id": None if row.get("next_bowl_id") == python_next_bowl
            else {"php": row.get("next_bowl_id"), "python": python_next_bowl},
        }
        mismatches = [name for name, diff in differences.items() if diff is not None]
        rows.append({
            "year": year,
            "target_jdn": target,
            "status": "MISMATCH" if mismatches else "PASS",
            "mismatch_fields": mismatches,
            "first_differences": differences,
        })
    return {
        "project_id": PROJECT,
        "branch_sha": probe["branch_sha"],
        "reference_source_commit": SOURCE,
        "oracle": "PINNED_PYTHON_SAUCE_NOT_IMPORTED_IN_PHP",
        "comparison": "PHP bowls 1..6 vs Python bowls 0..5; PHP bowl 3 vs Python bowl 2",
        "status": "MISMATCH" if any(row["status"] != "PASS" for row in rows) else "PASS",
        "years": rows,
        "stage56_accepted": False,
    }



def compare_shifted(probe: dict, canonical: Path) -> dict:
    """Additional QA only: map both PHP JDNs onto PHP's own foundation."""
    import pastafari_calendar.core as core
    diagnostic = probe.get("foundation_coordinate_diagnostic")
    if not isinstance(diagnostic, dict):
        raise ValueError("Missing source coordinate diagnostic")
    if (core.FOUNDATION_JDN != CALCULATION or
        diagnostic.get("php_origin_jdn") != -15055671 or
        diagnostic.get("reference_origin_jdn") != core.FOUNDATION_JDN or
        diagnostic.get("shift_jdn") != -1721425 or
        diagnostic.get("translated_calculation_jdn") != -15055671 or
        not isinstance(diagnostic.get("translated_records"), list) or
        len(diagnostic["translated_records"]) != len(TARGETS)):
        raise ValueError("Source coordinate diagnostic failed provenance checks")
    translated_probe = dict(probe)
    translated_probe["records"] = diagnostic["translated_records"]
    translated_result = compare(translated_probe, canonical)
    return {
        "status": translated_result["status"],
        "php_coordinate_shift": diagnostic["shift_jdn"],
        "translated_years": translated_result["years"],
        "raw_mismatch_still_fails": True,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--canonical-repo", type=Path, required=True)
    parser.add_argument("--php-input", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    try:
        probe = json.loads(args.php_input.read_text(encoding="utf-8"))
        result = compare(probe, args.canonical_repo.resolve())
        result["foundation_coordinate_diagnostic"] = compare_shifted(probe, args.canonical_repo.resolve())
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f"STAGE56_SAUCE_COMPARE_INPUT_ERROR: {error}", file=sys.stderr)
        return 2
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    for year in result["years"]:
        print(json.dumps(year, ensure_ascii=False, sort_keys=True))
    print("STAGE56_COORDINATE_DIAGNOSTIC status=" + result["foundation_coordinate_diagnostic"]["status"])
    print("STAGE56_SAUCE_COMPARE status=" + result["status"])
    return 0 if result["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
