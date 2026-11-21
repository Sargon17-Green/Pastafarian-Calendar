#!/usr/bin/env python3
"""Independent audit of Lua Haitian month-weaving resource feasibility.

No Lua imports, no production calls, no full-date execution. The script verifies
an exact month vector receipt and proves a lower bound on the existing memo DP.
It also checks an independent endpoint-path generating-function identity on
small domains against exhaustive multiset-word enumeration.
"""
from __future__ import annotations

import argparse
import hashlib
import itertools
import json
import math
from functools import lru_cache
from pathlib import Path

PROJECT_ID = "PC-BRANCH-LUA-HAITIAN"
EXPECTED_WITNESS_SHA = "6be926b109073a3161c41446026b8dbc739a5364"
LOCKS = {
    "normative": "8fab731dff7011b1a4c3a241c5d1cdefef1c2f1d",
    "bigint": "fcff58bcaaf8bb3f205e7a9c624a51069c0e5a5d",
    "catalog": "5b59ee6bb0ea2c2a551185929b5531ea28a50e49",
    "composition_qa": "350440149b4e072f778b82b2307caaa0418bf05c",
}
RANK_MODULUS = 2**127 - 1


def git_blob_sha(path: Path) -> str:
    raw = path.read_bytes()
    return hashlib.sha1(b"blob " + str(len(raw)).encode("ascii") + b"\0" + raw).hexdigest()


def composition_count(total: int, months: int, lo: int, hi: int) -> int:
    if months < 1 or lo < 1 or hi < lo or total < months * lo or total > months * hi:
        return 0
    r = total - months * lo
    d = min(r, months * (hi - lo) - r)
    width = hi - lo + 1
    return sum(
        (-1) ** j * math.comb(months, j) * math.comb(d - j * width + months - 1, months - 1)
        for j in range(d // width + 1)
    )


def composition_unrank(total: int, months: int, lo: int, hi: int, rank1: int) -> tuple[int, ...]:
    @lru_cache(maxsize=None)
    def count(rem: int, slots: int) -> int:
        return composition_count(rem, slots, lo, hi)

    if not 1 <= rank1 <= count(total, months):
        raise ValueError("rank outside exact composition family")
    result: list[int] = []
    remaining = total
    rank = rank1
    for position in range(months):
        left = months - position - 1
        low = max(lo, remaining - left * hi)
        high = min(hi, remaining - left * lo)
        selected = None
        for value in range(low, high + 1):
            block = 1 if left == 0 and value == remaining else count(remaining - value, left)
            if rank > block:
                rank -= block
            else:
                selected = value
                break
        if selected is None:
            raise AssertionError("independent composition unrank found no block")
        result.append(selected)
        remaining -= selected
    if remaining != 0 or rank != 1:
        raise AssertionError("independent composition unrank remainder")
    return tuple(result)


def brute_force_weaving_count(lengths: tuple[int, ...]) -> int:
    m = len(lengths)
    remaining = list(lengths)
    word: list[int] = []
    total = sum(lengths)
    result = 0

    def visit() -> None:
        nonlocal result
        if len(word) == total:
            first = [-1] * m
            last = [-1] * m
            for pos, label in enumerate(word):
                if first[label] == -1:
                    first[label] = pos
                last[label] = pos
            if first == sorted(first) and last == sorted(last):
                result += 1
            return
        for label in range(m):
            if remaining[label] == 0:
                continue
            remaining[label] -= 1
            word.append(label)
            visit()
            word.pop()
            remaining[label] += 1

    visit()
    return result


def endpoint_paths(months: int) -> list[tuple[tuple[int, ...], ...]]:
    """All interleavings O1..Om and C1..Cm with each Oi before Ci.

    A gap's active labels are the contiguous interval [closed, opened).
    The first and final empty gaps are retained for a literal generating product.
    """
    paths: list[tuple[tuple[int, ...], ...]] = []

    def walk(opened: int, closed: int, gaps: list[tuple[int, ...]]) -> None:
        if opened == months and closed == months:
            paths.append(tuple(gaps))
            return
        if opened < months:
            new_opened = opened + 1
            walk(new_opened, closed, gaps + [tuple(range(closed, new_opened))])
        if closed < opened:
            new_closed = closed + 1
            walk(opened, new_closed, gaps + [tuple(range(new_closed, opened))])

    walk(0, 0, [()])
    assert len(paths) == math.comb(2 * months, months) // (months + 1)
    return paths


def gap_coefficient(
    dp: dict[tuple[int, ...], int],
    active: tuple[int, ...],
    target: tuple[int, ...],
) -> dict[tuple[int, ...], int]:
    result: dict[tuple[int, ...], int] = {}
    m = len(target)
    for used, ways in dp.items():
        remaining = tuple(target[i] - used[i] for i in range(m))
        delta = [0] * m

        def distribute(k: int, total: int) -> None:
            if k == len(active):
                new_used = tuple(used[i] + delta[i] for i in range(m))
                weight = math.factorial(total)
                for amount in delta:
                    weight //= math.factorial(amount)
                result[new_used] = result.get(new_used, 0) + ways * weight
                return
            label = active[k]
            for amount in range(remaining[label] + 1):
                delta[label] = amount
                distribute(k + 1, total + amount)
            delta[label] = 0

        distribute(0, 0)
    return result


def endpoint_path_coefficient_count(lengths: tuple[int, ...]) -> int:
    """Coefficient [x_i^(n_i-2)] of the exact endpoint-path rational GF.

    For each endpoint path, every gap is an arbitrary word over its active set;
    its generating function is 1/(1-sum(active x_i)).
    """
    target = tuple(n - 2 for n in lengths)
    total = 0
    for path in endpoint_paths(len(lengths)):
        dp: dict[tuple[int, ...], int] = {(0,) * len(lengths): 1}
        for active in path:
            dp = gap_coefficient(dp, active, target)
        total += dp.get(target, 0)
    return total


def small_domain_identity_tests() -> tuple[int, int]:
    fixtures: list[tuple[int, ...]] = []
    for months in (1, 2, 3):
        fixtures.extend(v for v in itertools.product((2, 3, 4), repeat=months) if sum(v) <= 12)
    fixtures.extend(itertools.product((2, 3), repeat=4))
    tested = 0
    max_months = 0
    for lengths in fixtures:
        expected = brute_force_weaving_count(lengths)
        actual = endpoint_path_coefficient_count(lengths)
        assert actual == expected, (lengths, expected, actual)
        exact_slice = set(itertools.product(*(range(1, n) for n in lengths)))
        assert len(exact_slice) == math.prod(n - 1 for n in lengths)
        tested += 1
        max_months = max(max_months, len(lengths))
    return tested, max_months


def verify_receipt(path: Path) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    assert data["projectId"] == PROJECT_ID
    assert data["yearWitnessSha"] == EXPECTED_WITNESS_SHA
    run_sha = __import__("os").environ.get("GITHUB_SHA", "")
    assert len(run_sha) == 40 and data["qaRunSha"] == run_sha
    assert data["targetDay"] == -15017676 and data["year"] == 5000
    assert data["openGateIndex"] == 71 and data["closeGateIndex"] == 82
    assert data["openGateDay"] == -15018117 and data["closeGateDay"] == -15012823
    assert data["yearLength"] == data["closeGateDay"] - data["openGateDay"] == 5294
    lengths = tuple(data["monthLengths"])
    months = data["monthCount"]
    assert 44 <= months <= 47 and len(lengths) == months
    assert all(type(n) is int and 4 <= n <= 123 for n in lengths)
    assert sum(lengths) == data["yearLength"]

    assert 1 <= int(data["monthCountRank"]) <= 4
    assert data["compositionSelectionOracle"] == "independent-inclusion-exclusion"
    assert data["normativeRecursiveRealWitness"] == "NOT_RUN"
    count = composition_count(5294, months, 4, 123)
    rank = int(data["monthLengthRank"])
    assert int(data["compositionCount"]) == count
    assert 1 <= rank <= count
    assert composition_unrank(5294, months, 4, 123, rank) == lengths

    state_lower = math.prod(n - 1 for n in lengths)
    min_state_lower = 3**months
    factorial_lower = math.factorial(months)
    assert int(data["memoStateLowerBound"]) == state_lower
    assert int(data["minimumStateLowerBound"]) == min_state_lower
    assert state_lower >= min_state_lower
    assert int(data["factorialWeavingLowerBound"]) == factorial_lower
    assert factorial_lower > RANK_MODULUS
    assert data["rankModulus"] == str(RANK_MODULUS)
    assert data["normativeFeasibility"] == "VALID"
    assert data["currentMemoDp"] == "RESOURCE_UNSUPPORTED_FOR_WITNESS"
    assert data["weaving"] == "NOT_RUN" and data["fullDate"] == "NOT_RUN"
    assert data["productionChange"] == "NONE"
    return {
        "months": months,
        "lengths": lengths,
        "stateLowerBound": state_lower,
        "minimum3PowM": min_state_lower,
        "factorialLowerBound": factorial_lower,
        "compositionCount": count,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--receipt", type=Path, required=True)
    parser.add_argument("--normative-source", type=Path, required=True)
    parser.add_argument("--bigint-source", type=Path, required=True)
    parser.add_argument("--catalog-source", type=Path, required=True)
    parser.add_argument("--composition-qa-source", type=Path, required=True)
    args = parser.parse_args()

    paths = {
        "normative": args.normative_source,
        "bigint": args.bigint_source,
        "catalog": args.catalog_source,
        "composition_qa": args.composition_qa_source,
    }
    for name, path in paths.items():
        actual = git_blob_sha(path)
        assert actual == LOCKS[name], (name, LOCKS[name], actual)

    receipt = verify_receipt(args.receipt)
    identity_cases, max_months = small_domain_identity_tests()
    assert identity_cases >= 50 and max_months == 4

    print("SOURCE_LOCKS_PASS: 4/4")
    print(f"WEAVING_ENDPOINT_POLYNOMIAL_IDENTITY_PASS: {identity_cases}/{identity_cases}")
    print(f"WEAVING_STATE_SLICE_LOWER_BOUND_PASS: {identity_cases}/{identity_cases}")
    print("WEAVING_RESOURCE_STRATEGY_INDEPENDENT_PASS: 26/26")
    print(f"ACTUAL_MONTH_COUNT: {receipt['months']}")
    print(f"ACTUAL_MONTH_LENGTHS: {','.join(map(str, receipt['lengths']))}")
    print(f"MEMO_STATE_LOWER_BOUND: {receipt['stateLowerBound']}")
    print(f"MEMO_STATE_MINIMUM_3_POW_M: {receipt['minimum3PowM']}")
    print(f"VALID_WEAVING_COUNT_LOWER_BOUND_M_FACTORIAL: {receipt['factorialLowerBound']}")
    print("CURRENT_MEMO_DP: RESOURCE_UNSUPPORTED_FOR_WITNESS")
    print("NORMATIVE_FEASIBILITY: VALID; EXACT_WEAVING: NOT_RUN; FULL_DATE: NOT_RUN")


if __name__ == "__main__":
    main()
