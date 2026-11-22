#!/usr/bin/env python3
"""PC-BRANCH-CLOJURE-DUTCH: independent, TEST-ONLY DP feasibility oracle.

Cost is abstract cached states + legal transitions, NOT production insertion cells.
"""
import argparse
import json
import os
import sys
from collections import Counter

LIMIT = 5_000_000
# Python 3.11+ defaults to 4300 decimal digits. The canonical rank has
# 5288 digits; any legal profile has at most 5778 symbols, so its number
# of weavings is bounded by 5778! (< 20000 decimal digits). This is a
# conversion-only ceiling, not an algorithmic work or production budget.
CANONICAL_DECIMAL_DIGIT_CAP = 25_000


def enable_canonical_bigint_conversion():
    setter = getattr(sys, "set_int_max_str_digits", None)
    if setter is not None:
        setter(CANONICAL_DECIMAL_DIGIT_CAP)


class Unproven(Exception):
    def __init__(self, reason="abstract-budget-exceeded", spent=(0, 0),
                 production_work=0, next_cost=0):
        super().__init__(reason)
        self.reason = reason
        self.spent = tuple(spent)
        self.production_work = production_work
        self.next_cost = next_cost


def brute(profile):
    """Enumerate unrestricted multiset words; filter by first/last order."""
    counts = Counter({i + 1: n for i, n in enumerate(profile)})
    size = sum(profile)
    if size > 11:
        raise ValueError("tiny oracle only")
    result = []
    def walk(word):
        if len(word) == size:
            first = [word.index(i) for i in range(1, len(profile) + 1)]
            last = [size - 1 - word[::-1].index(i)
                    for i in range(1, len(profile) + 1)]
            if first == sorted(first) and last == sorted(last):
                result.append(word)
            return
        for i in sorted(counts):
            if counts[i]:
                counts[i] -= 1
                walk(word + (i,))
                counts[i] += 1
    walk(())
    return result


def _unrank(profile, rank, position, budget=LIMIT, production_budget=None):
    """Exact suffix-state DP: f(s)=sum(f(s')) over legal next letters."""
    if not (2 <= len(profile) <= 47 and all(1 <= x <= 123 for x in profile)):
        raise ValueError("invalid profile")
    if not 1 <= budget <= LIMIT or not 1 <= position <= sum(profile):
        raise ValueError("invalid budget or position")
    spent = [0, 0]  # unique states, legal transitions
    production_work = [0]
    month_count = len(profile)

    def production_raming(rest, opened):
        # Exact conservative per-candidate insertion-cell bound used by
        # production maandrang/raming:
        # 1 + (m - opened + 1) * (1 + sum(rest)).
        return 1 + (month_count - opened + 1) * (1 + sum(rest))

    def charge(which, work_cost):
        # Both budgets are charged before the corresponding operation.
        if sum(spent) >= budget:
            raise Unproven("abstract-budget-exceeded", spent,
                           production_work[0], work_cost)
        if (production_budget is not None
                and production_work[0] + work_cost > production_budget):
            raise Unproven("production-equivalent-work-budget-exceeded",
                           spent, production_work[0], work_cost)
        spent[which] += 1
        production_work[0] += work_cost
    def next_states(rest, opened, closed):
        for i in range(1, min(len(rest), opened + 1) + 1):
            n = rest[i - 1]
            if n == 0 or (n == 1 and i != closed + 1):
                continue
            updated = list(rest)
            updated[i - 1] -= 1
            yield i, tuple(updated), max(opened, i), closed + (n == 1)
    # Explicit postorder stack: recursion would fail on canonical year
    # profiles whose suffixes exceed Python's call-stack limit.
    memo = {}
    def count(rest, opened, closed):
        root = (rest, opened, closed)
        if root in memo:
            return memo[root]
        stack = [(root, None)]
        while stack:
            state, edges = stack.pop()
            if state in memo:
                continue
            remaining, opened_count, closed_count = state
            if edges is not None:
                # Every child has been evaluated by depth-first postorder.
                memo[state] = sum((memo[child] for child in edges), 0)
                continue
            charge(0, 1)
            if not any(remaining):
                memo[state] = int(opened_count == closed_count == len(profile))
                continue
            children = []
            for _, updated, new_opened, new_closed in next_states(*state):
                child = (updated, new_opened, new_closed)
                charge(1, production_raming(updated, new_opened))
                children.append(child)
            stack.append((state, children))
            # Preserve lexicographic traversal order; the cache collapses
            # repeated suffix states without consuming further units.
            for child in reversed(children):
                if child not in memo:
                    stack.append((child, None))
        return memo[root]
    rest = (profile[0] - 1,) + profile[1:]
    opened, closed = 1, int(profile[0] == 1)
    total = count(rest, opened, closed)
    if not 1 <= rank <= total:
        raise ValueError("invalid rank")
    prefix = [1]
    while len(prefix) < position:
        for i, updated, new_opened, new_closed in next_states(rest, opened, closed):
            n = count(updated, new_opened, new_closed)
            if rank > n:
                rank -= n
            else:
                prefix.append(i)
                rest, opened, closed = updated, new_opened, new_closed
                break
        else:
            raise AssertionError("no legal suffix")
    return tuple(prefix), total, tuple(spent), production_work[0]


def unrank(profile, rank, position, budget=LIMIT):
    prefix, total, spent, _ = _unrank(profile, rank, position, budget, None)
    return prefix, total, spent


def unrank_diagnostic(profile, rank, position, budget=LIMIT,
                      production_budget=LIMIT):
    return _unrank(profile, rank, position, budget, production_budget)


def run_canonical_diagnostic(input_path, output_path):
    # Set before json.load too, in case a future producer emits JSON numbers.
    enable_canonical_bigint_conversion()
    with open(input_path, "r", encoding="utf-8") as stream:
        data = json.load(stream)
    if data.get("project_id") != "PC-BRANCH-CLOJURE-DUTCH":
        raise ValueError("PROJECT_ID mismatch")
    if (data.get("production_year_matches_normative") is not True
            or data.get("production_profile_matches_normative") is not True
            or data.get("production_rank_matches_normative") is not True):
        raise ValueError("normative/production canonical input cross-check failed")
    source_sha = data.get("source_sha")
    if not isinstance(source_sha, str) or len(source_sha) != 40:
        raise ValueError("missing or malformed source SHA")
    expected_sha = os.environ.get("GITHUB_SHA")
    if expected_sha and expected_sha != source_sha:
        raise ValueError("input SHA does not match checked-out GITHUB_SHA")
    profile = tuple(int(x) for x in data["profile"])
    rank = int(data["weaving_rank"])
    expected_total = int(data["weaving_total"])
    if (not 3 <= len(profile) <= 47
            or any(not 4 <= x <= 123 for x in profile)
            or sum(profile) > 5778 or sum(profile) < 520
            or not 1 <= rank <= expected_total):
        raise ValueError("canonical profile/rank outside the declared domain")

    common = {
        "project_id": data["project_id"],
        "source_sha": source_sha,
        "calculation_day": data["calculation_day"],
        "target_day": data["target_day"],
        "target_year": data["target_year"],
        "search_budget": data["search_budget"],
        "profile": list(profile),
        "month_count": len(profile),
        "weaving_rank": str(rank),
        "production_weaving_total": str(expected_total),
        "abstract_budget": LIMIT,
        "production_equivalent_budget": LIMIT,
        "abstract_cost_model": "unique memo states + legal outgoing transitions",
        "production_equivalent_cost_model": (
            "one unit per unique state plus production_raming(rest, opened) "
            "per legal transition; raming=1+(m-opened+1)*(1+sum(rest))"
        ),
        "production_cost_model_source": "src/pastafari/maandrang.clj:raming",
        "prefix_positions": [82, 520],
        "five_field_differential": False,
        "full_month_weaving_computed": False,
        "stage2_accepted": False,
    }
    try:
        prefix, total, spent, production_work = unrank_diagnostic(
            profile, rank, 520, LIMIT, LIMIT)
        if total != expected_total:
            raise AssertionError(
                f"DP total {total} disagrees with production total {expected_total}")
        if len(prefix) != 520:
            raise AssertionError("DP did not return the complete 520-letter prefix")
        result = dict(common)
        result.update({
            "status": "DP_FEASIBILITY_PROVEN",
            "dp_weaving_total": str(total),
            "abstract_unique_states": spent[0],
            "abstract_legal_transitions": spent[1],
            "abstract_units": sum(spent),
            "production_equivalent_work_upper_bound": production_work,
            "prefix_p82": list(prefix[:82]),
            "prefix_p520": list(prefix),
        })
        exit_code = 0
    except Unproven as exc:
        result = dict(common)
        result.update({
            "status": "DP_FEASIBILITY_UNPROVEN",
            "reason": exc.reason,
            "abstract_unique_states": exc.spent[0],
            "abstract_legal_transitions": exc.spent[1],
            "abstract_units_charged": sum(exc.spent),
            "production_equivalent_work_charged": exc.production_work,
            "next_operation_cost": exc.next_cost,
            "minimum_if_next_operation_is_charged": (
                exc.production_work + exc.next_cost),
            "prefix_p82": None,
            "prefix_p520": None,
            "numeric_witness_emitted": False,
        })
        exit_code = 2
    with open(output_path, "w", encoding="utf-8") as stream:
        json.dump(result, stream, ensure_ascii=False, indent=2, sort_keys=True)
        stream.write("\n")
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    return exit_code


def test():
    profiles = [(2,2), (2,3), (3,2), (3,3), (4,4), (4,5), (5,4),
                (2,2,2), (3,3,2)]
    checks = words = max_spent = 0
    for profile in profiles:
        legal = brute(profile)
        assert legal == sorted(set(legal)) and legal
        words += len(legal)
        for rank, word in enumerate(legal, 1):
            for position in range(1, len(word) + 1):
                prefix, total, spent = unrank(profile, rank, position)
                assert prefix == word[:position] and total == len(legal)
                max_spent = max(max_spent, sum(spent))
                checks += 1
    try:
        unrank((4,4), 1, 4, 1)
        raise AssertionError("missing refusal")
    except Unproven:
        pass
    assert 4_995_675 <= LIMIT < 5_002_652
    assert 5_002_652 - LIMIT == 2_652
    # Long suffixes must fail with an explicit budget refusal, not
    # RecursionError; these are stress fixtures, not canonical date proofs.
    for long_profile in ((123,) * 9, (123,) * 29):
        try:
            unrank(long_profile, 1, 2, 2000)
            raise AssertionError("unexpected long-profile proof")
        except Unproven:
            pass
    # Regression: a genuine 5288-digit canonical-rank-sized decimal must
    # round-trip on Python 3.11+ without changing the 5_000_000 work cap.
    if hasattr(sys, "get_int_max_str_digits"):
        previous_limit = sys.get_int_max_str_digits()
        try:
            enable_canonical_bigint_conversion()
            large_decimal = "9" * 5288
            assert len(str(int(large_decimal))) == 5288
            assert LIMIT == 5_000_000
        finally:
            sys.set_int_max_str_digits(previous_limit)
    print(f"STATIC_QA_PASS profiles={len(profiles)} words={words} "
          f"rank_position_checks={checks} max_abstract_cells={max_spent} "
          f"canonical_bigint_roundtrip_digits=5288")

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--self-test", action="store_true")
    p.add_argument("--profile", default="4,5")
    p.add_argument("--rank", type=int, default=2)
    p.add_argument("--position", type=int, default=5)
    p.add_argument("--budget", type=int, default=LIMIT)
    p.add_argument("--canonical-input")
    p.add_argument("--diagnostic-output")
    a = p.parse_args()
    if a.canonical_input:
        if not a.diagnostic_output:
            p.error("--diagnostic-output is required with --canonical-input")
        raise SystemExit(run_canonical_diagnostic(
            a.canonical_input, a.diagnostic_output))
    if a.self_test:
        test()
    else:
        try:
            print(unrank(tuple(map(int, a.profile.split(","))), a.rank,
                         a.position, a.budget))
        except Unproven:
            print("BOUNDED_DP_UNPROVEN")
            raise SystemExit(2)
