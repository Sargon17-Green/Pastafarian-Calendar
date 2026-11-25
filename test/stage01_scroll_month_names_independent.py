#!/usr/bin/env python3
"""Hebrew Scroll Table 22: independent month-name lexicographic rank (seal 33)."""
from __future__ import annotations
import argparse
import hashlib
import itertools
import json
import math

PROJECT_ID = "PC-BRANCH-FORTRAN-ENGLISH"
SOURCE_SHA256 = "7b834f4a444e021bb65164282b851af960a6dbc0be3d458c2412181773b9db7b"
MONTH_NAMES = (
    "טין", "רימון", "מרפק", "קנאה", "ארידו", "משחת־שיניים",
    "שלושה חלקים מחמישה", "כַּרְשׁוּמַב", "נמר", "בדיל", "ערפל", "לבונה",
    "כישור", "צלע", "חרוב", "אורוק", "בושה", "גמל", "נחושת", "באר",
    "חלמון", "כוכב", "דבש", "טחול", "אבן־גיר", "שמחה", "תאנה",
    "נינוה", "צפרדע", "זפת", "נר", "הדלת הסגורה", "שומשום", "עורף",
    "כסף", "שושן", "סערה", "חמור", "קמח", "חרטה", "בבל", "לשון",
    "פשתן", "מלח", "אגס", "קשת", "חול",
)


def number_of_name_books(total_names: int, months: int) -> int:
    if total_names < 0 or months < 0 or months > total_names:
        return 0
    return math.factorial(total_names) // math.factorial(total_names - months)


def unrank_names(total_names: int, months: int, rank: int) -> tuple[int, ...]:
    """Return one-based canonical indices in zero-based lexicographic rank order."""
    if not 0 <= rank < number_of_name_books(total_names, months):
        raise ValueError("name-book rank outside admissible range")
    available = list(range(1, total_names + 1))
    result = []
    for position in range(months):
        width = number_of_name_books(total_names - position - 1, months - position - 1)
        index, rank = divmod(rank, width)
        result.append(available.pop(index))
    assert rank == 0
    return tuple(result)


def self_test() -> int:
    checks = 0
    for n in range(1, 7):
        for k in range(n + 1):
            expected = list(itertools.permutations(range(1, n + 1), k))
            assert number_of_name_books(n, k) == len(expected)
            checks += 1
            for i, book in enumerate(expected):
                assert unrank_names(n, k, i) == book
                checks += 1
            for invalid_rank in (-1, len(expected)):
                try:
                    unrank_names(n, k, invalid_rank)
                except ValueError:
                    checks += 1
                else:
                    raise AssertionError("accepted invalid name rank")
    assert len(MONTH_NAMES) == len(set(MONTH_NAMES)) == 47
    checks += 1
    large = number_of_name_books(47, 44)
    for rank in (0, 1, large // 2, large - 2, large - 1):
        ids = unrank_names(47, 44, rank)
        assert len(ids) == 44 and len(set(ids)) == 44
        checks += 1
    return checks


def foundation_names() -> dict:
    from stage01_scroll_gate_independent import choose_index
    from stage01_scroll_months_independent import foundation_months
    months_data = foundation_months()
    n = months_data["month_count"]
    question_day = months_data["calendar_year_first_day_offset"]
    eligible = number_of_name_books(len(MONTH_NAMES), n)
    rank = choose_index(0, question_day, 5, 33, eligible)
    indices = unrank_names(len(MONTH_NAMES), n, rank)
    return {
        "project_id": PROJECT_ID,
        "authority": {"snapshot": "Megilat_HaItim_Yehuda_FINAL_2026-09-18.md", "sha256": SOURCE_SHA256},
        "independent_from_pinned_python": True,
        "scope": "MONTH_NAMES_SEAL_33_ONLY_NOT_WEAVING_OR_FULL_DATE",
        "full_stage1_accepted": False,
        "foundation_year": months_data["foundation_year"],
        "month_count": n,
        "month_name_book_count": str(eligible),
        "month_name_rank_zero_based": str(rank),
        "month_name_indices_1based": list(indices),
        "month_names": [MONTH_NAMES[i - 1] for i in indices],
        "month_weaving": None,
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
        checks = self_test()
        print(f"STAGE01_SCROLL_MONTH_NAMES_SELFTEST={checks}/{checks}")
    if args.foundation:
        data = foundation_names()
        if args.output:
            with open(args.output, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2, sort_keys=True)
                f.write("\n")
        print("STAGE01_SCROLL_MONTH_NAMES_FOUNDATION_DIAGNOSTIC=PASS")
        print(f"STAGE01_SCROLL_MONTH_NAMES_COUNT={data['month_count']}")
        print(f"STAGE01_SCROLL_MONTH_NAMES_INDICES={data['month_name_indices_1based']}")
        print("STAGE01_SCROLL_MONTH_NAMES_ONLY_NOT_FULL_STAGE1_ACCEPTANCE")
    if not args.self_test and not args.foundation:
        p.error("specify --self-test and/or --foundation")


if __name__ == "__main__":
    main()
