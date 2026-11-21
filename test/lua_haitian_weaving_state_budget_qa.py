#!/usr/bin/env python3
"""Independent, bounded QA of opening/closing-order weaving counts.

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
QA ONLY. No Lua source import and no full-date execution.
Resource exhaustion is INDETERMINATE, never normative invalidity.
"""
from __future__ import annotations

import argparse
import hashlib
import itertools
import json
from pathlib import Path

PROJECT_ID = "PC-BRANCH-LUA-HAITIAN"
NORMATIVE_SOURCE_BLOB = "8fab731dff7011b1a4c3a241c5d1cdefef1c2f1d"
QA_MAX_DAYS = 12
QA_MAX_MONTHS = 4
QA_MAX_STATES = 4096


class StateBudget(Exception):
    pass


def source_blob_digest(source: bytes) -> str:
    prefix = b"blob " + str(len(source)).encode("ascii") + b"\0"
    return hashlib.sha1(prefix + source).hexdigest()


def brute_force_weaving_count(lengths: tuple[int, ...]) -> int:
    """Enumerate every distinct multiset word, then inspect its first/last order.

    This oracle is independent of the DP's state transitions and opening/closing
    counters. Synthetic lengths are intentionally smaller than normative months.
    """
    remaining = list(lengths)
    word: list[int] = []
    total = sum(lengths)
    result = 0

    def visit() -> None:
        nonlocal result
        if len(word) == total:
            first = [word.index(i) for i in range(len(lengths))]
            last = [total - 1 - word[::-1].index(i) for i in range(len(lengths))]
            if first == sorted(first) and last == sorted(last):
                result += 1
            return
        for i in range(len(lengths)):
            if remaining[i]:
                remaining[i] -= 1
                word.append(i)
                visit()
                word.pop()
                remaining[i] += 1

    visit()
    return result


def bounded_state_count(lengths: tuple[int, ...], max_states: int = QA_MAX_STATES) -> dict:
    if (not lengths or any(type(x) is not int or x <= 0 for x in lengths)
            or type(max_states) is not int or max_states <= 0):
        return {"status": "INVALID_QA_INPUT", "count": None, "states": 0}
    if len(lengths) > QA_MAX_MONTHS or sum(lengths) > QA_MAX_DAYS:
        return {"status": "NOT_EVALUATED_QA_DOMAIN", "count": None, "states": 0}

    visited: set[tuple[int, ...]] = set()
    memo: dict[tuple[int, ...], int] = {}

    def solve(remaining: tuple[int, ...]) -> int:
        if remaining in memo:
            return memo[remaining]
        if remaining not in visited:
            if len(visited) >= max_states:
                raise StateBudget
            visited.add(remaining)
        if not any(remaining):
            memo[remaining] = 1
            return 1
        first_opened = sum(r < size for r, size in zip(remaining, lengths))
        first_closed = sum(r == 0 for r in remaining)
        total = 0
        for j, amount in enumerate(remaining):
            if amount == 0:
                continue
            if amount == lengths[j] and j != first_opened:
                continue
            if amount == 1 and j != first_closed:
                continue
            following = list(remaining)
            following[j] -= 1
            total += solve(tuple(following))
        memo[remaining] = total
        return total

    try:
        count = solve(lengths)
        return {"status": "EXACT_SMALL_DOMAIN", "count": count, "states": len(visited)}
    except StateBudget:
        return {"status": "RESOURCE_BUDGET_EXCEEDED", "count": None,
                "states": len(visited)}


def selftest() -> dict:
    tested = 0
    max_states = 0
    fixtures = []
    for nmonths in (1, 2, 3):
        fixtures.extend(itertools.product((1, 2, 3), repeat=nmonths))
    fixtures.extend(((4, 4), (4, 5), (4, 4, 4), (4, 2, 4), (3, 4, 3)))

    for lengths in fixtures:
        expected = brute_force_weaving_count(lengths)
        actual = bounded_state_count(lengths)
        assert actual["status"] == "EXACT_SMALL_DOMAIN", (lengths, actual)
        assert actual["count"] == expected, (lengths, expected, actual)
        assert actual["states"] <= QA_MAX_STATES
        tested += 1
        max_states = max(max_states, actual["states"])

    assert brute_force_weaving_count((2, 2)) == 2
    assert bounded_state_count((3, 3, 3), max_states=1)["status"] == "RESOURCE_BUDGET_EXCEEDED"
    assert bounded_state_count((0, 2))["status"] == "INVALID_QA_INPUT"
    assert bounded_state_count((1, 1), max_states=0)["status"] == "INVALID_QA_INPUT"
    real_feasible_vector = (123,) * 43 + (5,)
    assert len(real_feasible_vector) == 44
    assert sum(real_feasible_vector) == 5294
    assert all(4 <= x <= 123 for x in real_feasible_vector)
    assert bounded_state_count(real_feasible_vector)["status"] == "NOT_EVALUATED_QA_DOMAIN"
    return {"projectId": PROJECT_ID, "oracle": "independent-multiset-exhaustive",
            "smallDomainCases": tested, "smallDomainExact": tested,
            "maxDiscoveredStates": max_states,
            "overBudgetStatus": "RESOURCE_BUDGET_EXCEEDED",
            "realWitnessDays": 5294, "realWitnessMonths": 44,
            "realWitnessStatus": "NOT_EVALUATED_QA_DOMAIN",
            "fullDate": "NOT_RUN", "productionChange": "NONE"}


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--check-source", type=Path, help="optional immutable Lua source blob check")
    args = p.parse_args()
    if args.check_source is not None:
        actual = source_blob_digest(args.check_source.read_bytes())
        if actual != NORMATIVE_SOURCE_BLOB:
            raise SystemExit(f"SOURCE_BLOB_MISMATCH expected={NORMATIVE_SOURCE_BLOB} actual={actual}")
    result = selftest()
    result["sourceLock"] = "MATCH" if args.check_source else "NOT_CHECKED"
    print("WEAVING_SMALL_DOMAIN_EXACT_PASS: {0}/{0}".format(result["smallDomainCases"]))
    print(json.dumps(result, sort_keys=True, ensure_ascii=False))


if __name__ == "__main__":
    main()
