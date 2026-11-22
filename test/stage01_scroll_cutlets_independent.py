#!/usr/bin/env python3
"""Independent Hebrew Scroll cutlet oracle, seals 20/21/22 (not full Stage1).

Transcribed from Megilat_HaItim_Yehuda_FINAL_2026-09-18.md tables 20-21.
No imports from the pinned Python reference, Fortran or their date fixtures.
"""
from __future__ import annotations
import argparse
import hashlib
import itertools
import json
import math

PROJECT_ID = "PC-BRANCH-FORTRAN-ENGLISH"
SOURCE_SHA256 = "7b834f4a444e021bb65164282b851af960a6dbc0be3d458c2412181773b9db7"
CUTLET_NAMES = (
    "ארד", "שועל", "כליה", "לגש", "מחשבה", "ארבעה חלקים מתשעה",
    "פלגורש", "גומא", "אשכול", "עקרב", "אפר", "חיטה",
    "נהר", "צחוק", "אכד", "קרן", "הכד הריק",
)


def compositions_count(total: int, parts: int) -> int:
    if parts == 0:
        return int(total == 0)
    if total < parts or parts < 0:
        return 0
    return math.comb(total - 1, parts - 1)


def count_with_required_gate(total: int, parts: int, gate_steps: int) -> int:
    """Count positive ordered partitions which end a cutlet at the required gate."""
    if gate_steps == 0:
        return compositions_count(total, parts)
    if not 0 < gate_steps < total or parts < 2:
        return 0
    return sum(
        compositions_count(gate_steps, k)
        * compositions_count(total - gate_steps, parts - k)
        for k in range(1, parts)
    )


def unrank_partition(total: int, parts: int, gate_steps: int, rank: int) -> tuple[int, ...]:
    if not 0 <= rank < count_with_required_gate(total, parts, gate_steps):
        raise ValueError("partition rank outside eligible range")
    output = []
    remaining, slots, missing = total, parts, gate_steps
    while slots:
        for candidate in range(1, remaining - slots + 2):
            child_gate = missing - candidate if missing else 0
            count = count_with_required_gate(remaining - candidate, slots - 1, child_gate)
            if rank >= count:
                rank -= count
                continue
            output.append(candidate)
            remaining -= candidate
            slots -= 1
            missing = child_gate
            break
        else:
            raise AssertionError("unrank exhausted choices")
    assert remaining == missing == rank == 0
    return tuple(output)


def permutation_count(n: int, k: int) -> int:
    return math.factorial(n) // math.factorial(n - k) if 0 <= k <= n else 0


def unrank_name_indices(n: int, k: int, rank: int) -> tuple[int, ...]:
    if not 0 <= rank < permutation_count(n, k):
        raise ValueError("name rank outside eligible range")
    available = list(range(n))
    result = []
    for i in range(k):
        block = permutation_count(n - i - 1, k - i - 1)
        index, rank = divmod(rank, block)
        result.append(available.pop(index))
    return tuple(result)


def self_test() -> int:
    """Independent brute oracle enumerates split positions and permutations."""
    checks = 0
    for total in range(6, 11):
        for parts in range(2, min(total, 5) + 1):
            for gate in range(1, total):
                brute = []
                for cuts in itertools.combinations(range(1, total), parts - 1):
                    if gate not in cuts:
                        continue
                    boundaries = (0,) + cuts + (total,)
                    brute.append(tuple(b - a for a, b in zip(boundaries, boundaries[1:])))
                brute.sort()
                assert len(brute) == count_with_required_gate(total, parts, gate)
                checks += 1
                for i, expected in enumerate(brute):
                    assert unrank_partition(total, parts, gate, i) == expected
                    checks += 1
    for n, k in ((3, 2), (4, 3), (5, 4)):
        brute = list(itertools.permutations(range(n), k))
        assert len(brute) == permutation_count(n, k)
        checks += 1
        for i, expected in enumerate(brute):
            assert unrank_name_indices(n, k, i) == expected
            checks += 1
    assert len(CUTLET_NAMES) == len(set(CUTLET_NAMES)) == 17
    checks += 1
    return checks


def foundation_cutlets() -> dict:
    from stage01_scroll_gate_independent import choose_index, foundation_year_5000, gate_window

    year = foundation_year_5000()["year_5000"]
    open_gate, close_gate = year["opening_gate_index"], year["closing_gate_index"]
    steps = close_gate - open_gate
    cut_at = -open_gate  # Foundation Day is itself gate 0, inside this year.
    assert open_gate < 0 < close_gate and 0 < cut_at < steps
    question_day = year["opening_gate_day_offset"] + 1
    choices = tuple(range(6, min(17, steps) + 1))
    assert choices
    n = choices[choose_index(0, question_day, 2, 20, len(choices))]
    eligible = count_with_required_gate(steps, n, cut_at)
    assert eligible > 0
    partition_rank = choose_index(0, question_day, 2, 21, eligible)
    lengths = unrank_partition(steps, n, cut_at, partition_rank)
    names_total = permutation_count(17, n)
    names_rank = choose_index(0, question_day, 5, 22, names_total)
    name_indices = unrank_name_indices(17, n, names_rank)
    gate_dates = dict(gate_window())
    records = []
    cursor = open_gate
    for length, name_index in zip(lengths, name_indices):
        next_gate = cursor + length
        records.append({
            "name": CUTLET_NAMES[name_index],
            "name_index_1based": name_index + 1,
            "gate_steps": length,
            "opening_gate_index": cursor,
            "closing_gate_index": next_gate,
            "first_day_offset": gate_dates[cursor] + 1,
            "last_day_offset": gate_dates[next_gate],
        })
        cursor = next_gate
    assert cursor == close_gate
    assert sum(x["gate_steps"] for x in records) == steps
    assert sum(x["last_day_offset"] - x["first_day_offset"] + 1 for x in records) == year["calendar_day_count"]
    at_foundation = [i for i, x in enumerate(records) if x["last_day_offset"] == 0]
    assert len(at_foundation) == 1
    i = at_foundation[0]
    return {
        "project_id": PROJECT_ID,
        "authority": {"snapshot": "Megilat_HaItim_Yehuda_FINAL_2026-09-18.md", "sha256": SOURCE_SHA256},
        "independent_from_pinned_python": True,
        "scope": "CUTLETS_SEALS_20_21_22_NOT_MONTHS_OR_FULL_DATE",
        "full_stage1_accepted": False,
        "year": 5000,
        "year_days": year["calendar_day_count"],
        "year_gate_steps": steps,
        "cutlet_count": n,
        "partition_eligible_count": str(eligible),
        "partition_rank_zero_based": str(partition_rank),
        "name_permutation_count": str(names_total),
        "name_rank_zero_based": str(names_rank),
        "gate_steps_partition": list(lengths),
        "cutlets": records,
        "foundation_day_partial_date": {
            "year": 5000,
            "cutlet_index_1based": i + 1,
            "cutlet_name": records[i]["name"],
            "day_in_cutlet": -records[i]["first_day_offset"] + 1,
            "month_name": None,
            "day_in_month": None,
        },
    }


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--self-test", action="store_true")
    p.add_argument("--foundation", action="store_true")
    p.add_argument("--output")
    p.add_argument("--scroll-file")
    a = p.parse_args()
    if a.scroll_file:
        with open(a.scroll_file, "rb") as f:
            if hashlib.sha256(f.read()).hexdigest() != SOURCE_SHA256:
                raise SystemExit("Hebrew Scroll SHA256 mismatch")
    if a.self_test:
        count = self_test()
        print(f"STAGE01_SCROLL_CUTLETS_SELFTEST={count}/{count}")
    if a.foundation:
        data = foundation_cutlets()
        if a.output:
            with open(a.output, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2, sort_keys=True)
                f.write("\n")
        print("STAGE01_SCROLL_CUTLETS_FOUNDATION_DIAGNOSTIC=PASS")
        print(f"STAGE01_SCROLL_CUTLETS_COUNT={data['cutlet_count']}")
        print(f"STAGE01_SCROLL_CUTLETS_PARTITION={data['gate_steps_partition']}")
        print("STAGE01_SCROLL_CUTLETS_ONLY_NOT_FULL_STAGE1_ACCEPTANCE")
    if not a.self_test and not a.foundation:
        p.error("specify --self-test and/or --foundation")


if __name__ == "__main__":
    main()
