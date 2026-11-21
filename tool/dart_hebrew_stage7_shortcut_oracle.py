#!/usr/bin/env python3
"""Stage7 QA-only independent leaf oracle for B's first-active bound.

Run: python3 tool/dart_hebrew_stage7_shortcut_oracle.py
Requires Python >=3.9, stdlib only, from repository root.
Does not call the production counter/unranker. NOT Dart Native or benchmark.

Test purpose: distinguish B's shortcut hits from _expensive_ saved
_unopenedFactor calls. Rank-one hits were already covered by Candidate A.
A B-only expensive hit requires residual_rank>1, unopened>0 and factor>1.
The factor comes from an independent whole-word leaf count, not production
dynamic programming. Small synthetic domains are exhaustive; the oracle
does not extrapolate timings or probabilities to the canonical year.

Distinct future workload candidates (zero-based day):
  [3,3,2] rank13 day2 residual2 C0=2 factor4
  [4,4,3] rank57 day3 residual2 C0=3 factor15
  [4,4,4] rank127 day3 residual2 C0=3 factor35
These are static witness vectors, not performance acceptance.
"""
from collections import defaultdict
import hashlib
import json
from pathlib import Path

DOMAINS = (
    ((2, 2, 1), 2), ((2, 2, 2), 5), ((3, 2, 2), 9),
    ((2, 3, 2), 11), ((1, 2, 2), 2), ((3, 3, 2), 26),
    ((4, 4, 3), 461), ((4, 4, 4), 1301),
)


def leaves(lengths):
    """Enumerate ordinary multiset words, then filter first/last order."""
    remaining = list(lengths)
    chosen = []
    accepted = []

    def walk():
        if not any(remaining):
            word = tuple(chosen)
            first = [word.index(i) for i in range(1, len(lengths) + 1)]
            last = [len(word) - 1 - word[::-1].index(i)
                    for i in range(1, len(lengths) + 1)]
            if first == sorted(first) and last == sorted(last):
                accepted.append(word)
            return
        for i, count in enumerate(remaining):
            if count == 0:
                continue
            remaining[i] -= 1
            chosen.append(i + 1)
            walk()
            chosen.pop()
            remaining[i] += 1

    walk()
    return accepted  # lexicographic from recursion


def active_child_leaves(active):
    """Independent active-only enumeration after consuming first active ID.

    Only last-occurrence order is constrained: first appearances of active
    colors have already occurred. -1 means the first color just closed.
    """
    remaining = list(active)
    remaining[0] -= 1
    suffix = []
    count = 0

    def walk():
        nonlocal count
        if not any(remaining):
            word = tuple(suffix)
            last = [len(word) - 1 - word[::-1].index(i)
                    if i in word else -1 for i in range(len(active))]
            if last == sorted(last):
                count += 1
            return
        for i, quantity in enumerate(remaining):
            if quantity == 0:
                continue
            remaining[i] -= 1
            suffix.append(i)
            walk()
            suffix.pop()
            remaining[i] += 1

    walk()
    return count


def review(lengths, expected_count):
    words = leaves(lengths)
    assert len(words) == expected_count, (lengths, len(words))
    starts = {}
    prefix_counts = defaultdict(int)
    for index, word in enumerate(words):
        for day in range(len(word) + 1):
            prefix = word[:day]
            starts.setdefault(prefix, index)
            prefix_counts[prefix] += 1

    active_cache = {}
    hits = []
    for index, word in enumerate(words):
        remaining = list(lengths)
        opened = closed = 0
        for day, token in enumerate(word):
            active = tuple(remaining[closed:opened])
            if active:
                prefix = word[:day]
                residual_rank = index - starts[prefix] + 1
                if active not in active_cache:
                    active_cache[active] = active_child_leaves(active)
                c0 = active_cache[active]
                first_active = closed + 1
                full_block = prefix_counts[prefix + (first_active,)]
                assert c0 > 0 and full_block % c0 == 0
                factor = full_block // c0  # whole-word leaf count ratio
                assert factor >= 1
                if residual_rank <= c0:
                    assert token == first_active  # independent oracle check
                    hits.append({
                        "rank": index + 1, "day_index": day,
                        "residual_rank": residual_rank, "C0": c0,
                        "factor": factor,
                        "unopened": len(lengths) - opened,
                    })
            if token - 1 == opened:
                opened += 1
            remaining[token - 1] -= 1
            if token - 1 == closed and remaining[token - 1] == 0:
                closed += 1
        assert opened == closed == len(lengths) and not any(remaining)

    beyond_a = [h for h in hits if h["residual_rank"] > 1]
    expensive = [h for h in beyond_a
                 if h["unopened"] > 0 and h["factor"] > 1]
    return {
        "lengths": list(lengths), "valid_words": len(words),
        "b_hits_all": len(hits), "b_only_hits": len(beyond_a),
        "b_only_expensive_hits": len(expensive),
        "b_only_expensive_witnesses": expensive,
    }


def check_source_path():
    source = Path("lib/src/monster_month_weave_planner.dart").read_text(
        encoding="utf-8")
    helper = source.split("static List<int> _unrankWithKnownTotal(", 1)[1]
    helper = helper.split("/// Canonical §V selection", 1)[0]
    shortcut = helper.index("if (ordinal <= childBases[0]) {")
    branch = helper.index("chosen = closed;", shortcut)
    base = helper.index("nextBase = childBases[0];", branch)
    fallback = helper.index("final factor = _unopenedFactor(", base)
    assert shortcut < branch < base < fallback
    assert helper.index("for (var i = 0; i < active.length; i++)", fallback) > fallback
    return "bound_before_factor_fallback"


def main():
    source_path = check_source_path()
    reports = [review(domain, n) for domain, n in DOMAINS]
    by_domain = {tuple(x["lengths"]): x for x in reports}
    assert by_domain[(3, 3, 2)]["b_only_expensive_hits"] == 1
    assert by_domain[(4, 4, 3)]["b_only_expensive_hits"] == 14
    assert by_domain[(4, 4, 4)]["b_only_expensive_hits"] == 14
    witness = by_domain[(4, 4, 3)]["b_only_expensive_witnesses"]
    assert any(x["rank"] == 57 and x["day_index"] == 3
               and x["residual_rank"] == 2 and x["factor"] == 15
               for x in witness)
    result = {
        "project_id": "PC-BRANCH-DART-HEBREW",
        "scope": "STAGE7_QA_ONLY_STATIC_AND_INDEPENDENT_LEAF",
        "native_pass": False, "performance_acceptance": False,
        "source_path": source_path, "domains": reports,
    }
    payload = json.dumps(result, ensure_ascii=False, sort_keys=True,
                         separators=(",", ":"))
    print("STAGE7_SHORTCUT_STATIC_ORACLE_PASS "
          f"domains={len(reports)} valid_words={sum(x['valid_words'] for x in reports)} "
          f"b_only_expensive_443=14 b_only_expensive_444=14")
    print("STAGE7_SHORTCUT_ORACLE_SHA256=" +
          hashlib.sha256(payload.encode("utf-8")).hexdigest())
    print(payload)


if __name__ == "__main__":
    main()
