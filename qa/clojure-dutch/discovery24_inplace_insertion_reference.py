#!/usr/bin/env python3
"""Run the committed DISCOVERY24 in-place and gap-convolution oracles.

This adapter does not duplicate either algorithm. It imports the pinned
standalone oracle and emits a compact line-oriented result for the Clojure
test-only prototype to compare against.
"""
import argparse
import importlib.util
import json
import os
from hashlib import sha1, sha256
from pathlib import Path
import sys

REFERENCE_BLOB_SHA = "e3a5616acda7c1fd1853e9c6114049efa86d7bd3"
SMALL_PROFILES = (
    (2, 2), (2, 3), (3, 2), (2, 2, 2), (2, 3, 2),
    (3, 2, 2), (2, 2, 2, 2), (4, 4),
)


def git_blob_sha(data):
    header = b"blob " + str(len(data)).encode("ascii") + b"\0"
    return sha1(header + data).hexdigest()


def load_reference():
    path = Path(__file__).with_name("discovery24_inplace_insertion_prefix_qa.py")
    raw = path.read_bytes()
    actual = git_blob_sha(raw)
    if actual != REFERENCE_BLOB_SHA:
        raise AssertionError(
            f"committed Python oracle blob changed: {actual} != {REFERENCE_BLOB_SHA}")
    spec = importlib.util.spec_from_file_location("discovery24_inplace_reference", path)
    if spec is None or spec.loader is None:
        raise RuntimeError("cannot load committed Python oracle")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def small_family_reference(module):
    digest = sha256()
    legal_words = rank_position_checks = 0
    exact_budget_accepts = budget_minus_one_refusals = 0

    for profile in SMALL_PROFILES:
        module.suffix_count_inplace.cache_clear()
        module.tail_factor_inplace.cache_clear()
        module.CELL_WRITES = 0
        module.CELL_LIMIT = module.BUDGET

        words = module.brute_legal_words(profile)
        legal_words += len(words)
        if module.suffix_count_inplace((tuple(profile), 0, 0)) != len(words):
            raise AssertionError(f"root count mismatch for {profile}")

        for rank, word in enumerate(words, 1):
            for position in range(1, len(word) + 1):
                full = module.rank_trace_inplace(profile, rank, position)
                if full["status"] != "PREFIX_CERTIFIED":
                    raise AssertionError(f"unbounded small trace refused: {profile}/{rank}/{position}")
                if tuple(full["prefix"]) != word[:position]:
                    raise AssertionError(f"small prefix mismatch: {profile}/{rank}/{position}")

                line = (
                    ",".join(map(str, profile)) + "|" + str(rank) + "|"
                    + str(position) + "|" + ",".join(map(str, full["prefix"])) + "|"
                    + str(full["total"]) + "|" + str(full["dp_cell_writes"]) + "\n"
                )
                digest.update(line.encode("ascii"))
                rank_position_checks += 1

                exact = module.rank_trace_inplace(
                    profile, rank, position, production_budget=full["billed"])
                if exact["status"] != "PREFIX_CERTIFIED" or exact["prefix"] != full["prefix"]:
                    raise AssertionError(f"exact-budget acceptance mismatch: {profile}/{rank}/{position}")
                exact_budget_accepts += 1

                if full["billed"] > 0:
                    below = module.rank_trace_inplace(
                        profile, rank, position, production_budget=full["billed"] - 1)
                    if below["status"] != "PRODUCTION_BUDGET_REFUSAL":
                        raise AssertionError(f"budget-minus-one did not refuse: {profile}/{rank}/{position}")
                    budget_minus_one_refusals += 1

    return {
        "profiles": len(SMALL_PROFILES),
        "legal_words": legal_words,
        "rank_position_checks": rank_position_checks,
        "exact_budget_accepts": exact_budget_accepts,
        "budget_minus_one_refusals": budget_minus_one_refusals,
        "digest": digest.hexdigest(),
    }


def main():
    if hasattr(sys, "set_int_max_str_digits"):
        sys.set_int_max_str_digits(25000)

    parser = argparse.ArgumentParser()
    parser.add_argument("--canonical-input", required=True)
    args = parser.parse_args()

    with open(args.canonical_input, "r", encoding="utf-8") as stream:
        data = json.load(stream)

    module = load_reference()
    if data.get("project_id") != module.PROJECT_ID:
        raise AssertionError("PROJECT_ID mismatch")
    if data.get("target_year") != "5000":
        raise AssertionError("canonical target year mismatch")
    if data.get("search_budget") != module.SEARCH_BUDGET:
        raise AssertionError("search budget mismatch")
    if (data.get("production_year_matches_normative") is not True
            or data.get("production_profile_matches_normative") is not True
            or data.get("production_rank_matches_normative") is not True):
        raise AssertionError("canonical normative/production cross-check missing")
    expected_sha = os.environ.get("GITHUB_SHA")
    if expected_sha and data.get("source_sha") != expected_sha:
        raise AssertionError("canonical input SHA does not match this CI checkout")

    profile = tuple(int(x) for x in data["profile"])
    rank = int(data["weaving_rank"])
    recorded_total = int(data["weaving_total"])
    if (len(profile), sum(profile), len(data["weaving_rank"])) != (33, 3569, 5288):
        raise AssertionError("canonical profile/rank dimensions changed")

    small = small_family_reference(module)

    module.suffix_count_inplace.cache_clear()
    module.tail_factor_inplace.cache_clear()
    module.CELL_WRITES = 0
    module.CELL_LIMIT = module.BUDGET
    alternative = module.rank_trace_inplace(profile, rank, 520)
    if alternative["status"] != "PREFIX_CERTIFIED":
        raise AssertionError("in-place model did not certify p520")
    if alternative["total"] != recorded_total:
        raise AssertionError("in-place total differs from canonical input")

    module.convolution_count.cache_clear()
    module.gap_factor.cache_clear()
    gap_total, gap_snapshots, gap_work = module.rank_trace_convolution(profile, rank, 520)
    if gap_total != recorded_total:
        raise AssertionError("gap-convolution total differs from canonical input")

    for position in (81, 82, 520):
        left = alternative["snapshots"][position]
        right = gap_snapshots[position]
        for key in ("prefix_sha256", "month_id", "day_in_month", "production_shared_cost"):
            if left[key] != right[key]:
                raise AssertionError(f"gap-convolution mismatch at p{position}: {key}")

    print("RESULT PASS_MODEL_ONLY")
    print(f"SMALL_PROFILES {small['profiles']}")
    print(f"SMALL_LEGAL_WORDS {small['legal_words']}")
    print(f"SMALL_RANK_POSITION_CHECKS {small['rank_position_checks']}")
    print(f"SMALL_EXACT_BUDGET_ACCEPTS {small['exact_budget_accepts']}")
    print(f"SMALL_BUDGET_MINUS_ONE_REFUSALS {small['budget_minus_one_refusals']}")
    print(f"SMALL_DIGEST {small['digest']}")
    print(f"CANONICAL_TOTAL {alternative['total']}")
    print(f"CANONICAL_DP_CELL_WRITES {alternative['dp_cell_writes']}")
    for position in (81, 82, 520):
        snap = alternative["snapshots"][position]
        gap = gap_snapshots[position]
        print(f"P{position}_SHA {snap['prefix_sha256']}")
        print(f"P{position}_MONTH_ID {snap['month_id']}")
        print(f"P{position}_DAY_IN_MONTH {snap['day_in_month']}")
        print(f"P{position}_DP_CELL_WRITES {snap['dp_cell_writes']}")
        print(f"P{position}_SHARED_COST {snap['production_shared_cost']}")
        print(f"GAP_P{position}_SHA {gap['prefix_sha256']}")
        print(f"GAP_P{position}_MONTH_ID {gap['month_id']}")
        print(f"GAP_P{position}_DAY_IN_MONTH {gap['day_in_month']}")
        print(f"GAP_P{position}_SHARED_COST {gap['production_shared_cost']}")
    print(f"GAP_TOTAL {gap_total}")
    print(f"GAP_WORK_TESTED {gap_work['tested']}")
    print(f"GAP_WORK_SKIPPED {gap_work['skipped']}")


if __name__ == "__main__":
    main()
