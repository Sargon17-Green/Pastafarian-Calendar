#!/usr/bin/env python3
"""Independent Hebrew Scroll month-count and bounded-length oracle, seals 30/31.

Normative source: Megilat_HaItim_Yehuda_FINAL_2026-09-18.md, table 21.
No imports from the pinned cross-branch Python reference or Fortran.
This component does not establish complete Stage 1 acceptance.
"""
from __future__ import annotations

import argparse
import hashlib
import itertools
import json
import math

PROJECT_ID = "PC-BRANCH-FORTRAN-ENGLISH"
SOURCE_SHA256 = "7b834f4a444e021bb65164282b851af960a6dbc0be3d458c2412181773b9db7b"
MIN_MONTHS, MAX_MONTHS = 3, 47
MIN_DAYS, MAX_DAYS = 4, 123


def admissible_month_counts(days: int) -> tuple[int, ...]:
    if days < MIN_MONTHS * MIN_DAYS:
        return ()
    lo = max(MIN_MONTHS, (days + MAX_DAYS - 1) // MAX_DAYS)
    hi = min(MAX_MONTHS, days // MIN_DAYS)
    return tuple(range(lo, hi + 1)) if lo <= hi else ()


def count_length_books(days: int, months: int,
                       lo: int = MIN_DAYS, hi: int = MAX_DAYS) -> int:
    """Coefficient of x**days in (x**lo + ... + x**hi)**months.

    Inclusion-exclusion counts all ordered bounded compositions exactly.
    """
    if months < 0 or lo < 1 or hi < lo:
        raise ValueError("invalid month count or bounds")
    if months == 0:
        return int(days == 0)
    if not months * lo <= days <= months * hi:
        return 0
    excess = days - months * lo
    width = hi - lo + 1
    return sum(
        (-1 if j % 2 else 1)
        * math.comb(months, j)
        * math.comb(excess - width * j + months - 1, months - 1)
        for j in range(min(months, excess // width) + 1)
    )


def unrank_length_book(days: int, months: int, rank: int,
                       lo: int = MIN_DAYS, hi: int = MAX_DAYS) -> tuple[int, ...]:
    """Zero-based lexicographic rank among ordered bounded length books."""
    total = count_length_books(days, months, lo, hi)
    if not 0 <= rank < total:
        raise ValueError("rank outside eligible month-length books")
    result = []
    remaining = days
    for pos in range(months):
        slots = months - pos - 1
        first = max(lo, remaining - slots * hi)
        last = min(hi, remaining - slots * lo)
        for candidate in range(first, last + 1):
            size = count_length_books(remaining - candidate, slots, lo, hi)
            if rank < size:
                result.append(candidate)
                remaining -= candidate
                break
            rank -= size
        else:
            raise AssertionError("lexicographic unrank exhausted choices")
    if remaining != 0 or rank != 0 or len(result) != months:
        raise AssertionError("month length unrank leftover state")
    return tuple(result)


def self_test() -> int:
    """Independent brute-force enumeration of short books with varied bounds."""
    checks = 0
    for lo, hi in ((1, 2), (2, 4), (4, 6)):
        for months in range(0, 5):
            brute = sorted(itertools.product(range(lo, hi + 1), repeat=months))
            for days in range(max(0, months * lo - 1), months * hi + 2):
                eligible = [book for book in brute if sum(book) == days]
                assert count_length_books(days, months, lo, hi) == len(eligible)
                checks += 1
                for rank, expected in enumerate(eligible):
                    assert unrank_length_book(days, months, rank, lo, hi) == expected
                    checks += 1
                if not eligible:
                    try:
                        unrank_length_book(days, months, 0, lo, hi)
                    except ValueError:
                        checks += 1
                    else:
                        raise AssertionError("invalid rank was accepted")
    for days in range(0, 615):
        expected = tuple(
            n for n in range(MIN_MONTHS, MAX_MONTHS + 1)
            if n * MIN_DAYS <= days <= n * MAX_DAYS
        )
        assert admissible_month_counts(days) == expected
        checks += 1
    assert count_length_books(4399, 36) > 0
    checks += 1
    assert count_length_books(4399, 35) == 0
    checks += 1
    assert admissible_month_counts(4399) == tuple(range(36, 48))
    checks += 1
    return checks


def foundation_months() -> dict:
    from stage01_scroll_gate_independent import choose_index, foundation_year_5000

    year = foundation_year_5000()["year_5000"]
    days = year["calendar_day_count"]
    question_day = year["opening_gate_day_offset"] + 1
    choices = admissible_month_counts(days)
    if not choices:
        raise AssertionError("no legal month count for selected year")
    months = choices[choose_index(0, question_day, 3, 30, len(choices))]
    possibilities = count_length_books(days, months)
    if possibilities <= 0:
        raise AssertionError("chosen month count has zero length books")
    rank = choose_index(0, question_day, 3, 31, possibilities)
    lengths = unrank_length_book(days, months, rank)
    assert len(lengths) == months
    assert sum(lengths) == days
    assert all(MIN_DAYS <= n <= MAX_DAYS for n in lengths)
    return {
        "project_id": PROJECT_ID,
        "authority": {
            "snapshot": "Megilat_HaItim_Yehuda_FINAL_2026-09-18.md",
            "sha256": SOURCE_SHA256,
        },
        "independent_from_pinned_python": True,
        "scope": "MONTHS_SEALS_30_31_ONLY_NOT_WEAVING_OR_FULL_DATE",
        "full_stage1_accepted": False,
        "foundation_year": 5000,
        "year_days": days,
        "calendar_year_first_day_offset": question_day,
        "month_count_choices": list(choices),
        "month_count": months,
        "length_book_count": str(possibilities),
        "length_book_rank_zero_based": str(rank),
        "month_lengths": list(lengths),
        "month_weaving": None,
        "month_name_indices": None,
        "foundation_day_month": None,
        "foundation_day_in_month": None,
    }


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--self-test", action="store_true")
    p.add_argument("--foundation", action="store_true")
    p.add_argument("--output")
    p.add_argument("--scroll-file")
    args = p.parse_args()
    if args.scroll_file:
        with open(args.scroll_file, "rb") as f:
            if hashlib.sha256(f.read()).hexdigest() != SOURCE_SHA256:
                raise SystemExit("Hebrew Scroll SHA256 mismatch")
    if args.self_test:
        count = self_test()
        print(f"STAGE01_SCROLL_MONTHS_SELFTEST={count}/{count}")
    if args.foundation:
        data = foundation_months()
        if args.output:
            with open(args.output, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2, sort_keys=True)
                f.write("\n")
        print("STAGE01_SCROLL_MONTHS_FOUNDATION_DIAGNOSTIC=PASS")
        print(f"STAGE01_SCROLL_MONTHS_COUNT={data['month_count']}")
        print(f"STAGE01_SCROLL_MONTHS_LENGTHS={data['month_lengths']}")
        print("STAGE01_SCROLL_MONTHS_ONLY_NOT_FULL_STAGE1_ACCEPTANCE")
    if not args.self_test and not args.foundation:
        p.error("specify --self-test and/or --foundation")


if __name__ == "__main__":
    main()
