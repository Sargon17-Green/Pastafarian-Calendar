#!/usr/bin/env python3
"""Independent exact root-count/middle-rank certificate, Stage55 Year 5000.

This certificate does NOT unrank the full canonical word, establish independent
month-length provenance, perform MATLAB Native, or accept Stage55.
"""
import argparse
import hashlib
import itertools
import json
import math
import sys
from pathlib import Path

sys.set_int_max_str_digits(0)
PROJECT_ID = "PC-BRANCH-MATLAB-POLSKI"
SOURCE_COMMIT_LOCK = "f4871de21a599a4f57e6f2180f174a3cb66db54f"
FIXTURE_GIT_BLOB = "a1383b111a88203b0d652b8f0a0e9af1a8b75f25"
LENGTHS_SHA256 = "6d64022344c04935e6423aa6f96b285098d35b9b5ecb4b8c57a4c7149773a134"
ROOT_COUNT_DECIMAL_SHA256 = "c0c08ac89c8faaaf589d1b3e076fe1e96405f2ad7172a15efa9d028fb43fb6f8"
ROOT_MIDDLE_DECIMAL_SHA256 = "cd5ce4036fc8e99355a4bab5d48c3db473422083d035df5e0af25297be1be3b6"
TINY_FAMILIES = ((1,), (2,), (1, 1), (1, 2), (2, 1), (2, 2),
                 (1, 1, 1), (2, 1, 2), (2, 2, 2), (3, 2),
                 (2, 3), (2, 2, 1), (3, 2, 2), (1, 3, 2))


def sha256_ascii_number(n):
    return hashlib.sha256(str(n).encode("ascii")).hexdigest()


def count_by_suffix_tail(lengths):
    """Forward insertion, tracking suffix length from the newest first symbol.

    The last copy of each newly added symbol is forced to be last; the first
    copy must be after the preceding symbol's first copy. For r old characters
    after its first copy, there are C(r+m-2,m-2) placements for interior copies.
    The eligible old states are exactly the strict suffix tail s>r.
    """
    assert lengths and all(type(m) is int and m > 0 for m in lengths)
    states = {lengths[0]: 1}
    size = lengths[0]
    for m in lengths[1:]:
        if m == 1:
            states = {1: sum(states.values())}
        else:
            next_states = {}
            eligible = 0
            coefficient = math.comb(size + m - 2, m - 2)
            for r in range(size, -1, -1):
                if eligible:
                    next_states[r + m] = eligible * coefficient
                eligible += states.get(r, 0)
                if r:
                    coefficient = coefficient * r // (r + m - 2)
            states = next_states
        size += m
    return sum(states.values())


def count_by_first_position(lengths):
    """Separate forward insertion using absolute first positions, not tails.

    Let f[q] count old words with the largest label's first position q.
    The new first position p can be 2..N+1 and must have q<p.
    The m-2 interior new copies are distributed in
    C(N-p+m-1,m-2) possibilities. The final new copy is last.
    """
    assert lengths and all(type(m) is int and m > 0 for m in lengths)
    first = [0] * (lengths[0] + 1)
    first[1] = 1
    old_size = lengths[0]
    for m in lengths[1:]:
        updated = [0] * (old_size + m + 1)
        if m == 1:
            updated[old_size + 1] = sum(first)
        else:
            cumulative = []
            total = 0
            for n in first:
                total += n
                cumulative.append(total)
            coefficient = 1
            for p in range(old_size + 1, 1, -1):
                updated[p] = cumulative[p - 1] * coefficient
                if p > 2:
                    coefficient = (coefficient * (old_size - p + m)
                                   // (old_size - p + 2))
        first = updated
        old_size += m
    return sum(first)


def brute_legal_count(lengths):
    alphabet = tuple(symbol for symbol, count in enumerate(lengths, 1)
                     for _ in range(count))
    result = 0
    for word in set(itertools.permutations(alphabet)):
        first = [word.index(i) for i in range(1, len(lengths) + 1)]
        last = [len(word) - 1 - word[::-1].index(i)
                for i in range(1, len(lengths) + 1)]
        if all(a < b for a, b in zip(first, first[1:])) and \
           all(a < b for a, b in zip(last, last[1:])):
            result += 1
    return result


def read_fixture(path):
    raw = path.read_bytes()
    blob = hashlib.sha1(b"blob " + str(len(raw)).encode("ascii") +
                        b"\0" + raw).hexdigest()
    assert blob == FIXTURE_GIT_BLOB, ("fixture Git blob changed", blob)
    fixture = json.loads(raw)
    lengths = fixture["month_lengths"]
    assert fixture["year"] == 5000
    assert fixture["first_day"] == -15057702
    assert fixture["last_day"] == -15053459
    assert len(lengths) == 45 and sum(lengths) == 4244
    assert all(type(m) is int and 4 <= m <= 123 for m in lengths)
    digest = hashlib.sha256(",".join(map(str, lengths)).encode("ascii")).hexdigest()
    assert digest == LENGTHS_SHA256
    return fixture, lengths, blob, digest


def certify(fixture_path):
    for family in TINY_FAMILIES:
        exact = brute_legal_count(family)
        left = count_by_suffix_tail(family)
        right = count_by_first_position(family)
        assert exact == left == right, (family, exact, left, right)
    fixture, lengths, blob, digest = read_fixture(fixture_path)
    count1 = count_by_suffix_tail(lengths)
    count2 = count_by_first_position(lengths)
    assert count1 == count2 and count1 > 2
    middle = count1 // 2 + 1  # 1-based, upper middle if even
    assert 1 < middle < count1
    assert len(str(count1)) == 6765
    assert sha256_ascii_number(count1) == ROOT_COUNT_DECIMAL_SHA256
    assert sha256_ascii_number(middle) == ROOT_MIDDLE_DECIMAL_SHA256
    return {
        "project_id": PROJECT_ID,
        "gate": "STAGE55_YEAR5000_EXACT_ROOT_POLICY_AND_COUNT_ONLY",
        "source_commit_lock": SOURCE_COMMIT_LOCK,
        "fixture_git_blob": blob,
        "lengths_sha256": digest,
        "lengths_provenance": "source-derived audited fixture, NOT independently reconstructed",
        "months": len(lengths),
        "days": sum(lengths),
        "tiny_exhaustive_families": len(TINY_FAMILIES),
        "root_count_methods": ["suffix-distance strict-tail insertion DP",
                               "first-position prefix insertion DP"],
        "root_count_decimal": str(count1),
        "root_count_decimal_sha256": sha256_ascii_number(count1),
        "root_count_digits": len(str(count1)),
        "root_rank_policy": "floor(root_count/2)+1; one-based lexicographic",
        "root_middle_rank_decimal": str(middle),
        "root_middle_rank_decimal_sha256": sha256_ascii_number(middle),
        "root_middle_rank_digits": len(str(middle)),
        "root_count_exact": True,
        "full_middle_word_verified": False,
        "full_year_five_field_verified": False,
        "matlab_native_verified_by_this_gate": False,
        "cross_engine_soak_verified": False,
        "stage55_final_accepted": False,
        "last_completed_stage": 54
    }


def main():
    p = argparse.ArgumentParser()
    p.add_argument("fixture", type=Path)
    p.add_argument("--report", type=Path)
    args = p.parse_args()
    result = certify(args.fixture)
    if args.report is not None:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(result, ensure_ascii=False,
                                          indent=2, sort_keys=True) + "\n",
                               encoding="utf-8")
    print("STAGE55_ROOT_DUAL_COUNT_PASS MONTHS=45 DAYS=4244 " +
          "DIGITS=6765 TINY=14 COUNT_SHA256=" + ROOT_COUNT_DECIMAL_SHA256)
    print("STAGE55_ROOT_MIDDLE_RANK_POLICY_PASS " +
          "RANK_SHA256=" + ROOT_MIDDLE_DECIMAL_SHA256)
    print("STAGE55_FULL_MIDDLE_WORD_NOT_VERIFIED")
    print("STAGE55_MATLAB_NATIVE_THIS_GATE_NOT_RUN")
    print("STAGE55_FINAL_STAGE_NOT_ACCEPTED")


if __name__ == "__main__":
    main()
