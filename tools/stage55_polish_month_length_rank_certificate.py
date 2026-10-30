#!/usr/bin/env python3
"""Stage 55: independent, bounded composition-rank certificate for Year 5000.

This proves the supplied 45-length vector is a legal, uniquely ranked
4..123 bounded composition of 4244 and independently checks its exact rank
and total by inclusion-exclusion and a sliding-window DP. It does NOT prove
that the source-language selector chose that rank, or validate the middle
month-weaving word, cutlet/name selections, or the five-field full-year oracle.
"""
import hashlib
import json
from itertools import product
from math import comb
from pathlib import Path

TOTAL_DAYS = 4244
MONTHS = 45
LOW = 4
HIGH = 123
WIDTH = HIGH - LOW + 1
FIXTURE = Path(__file__).resolve().parents[1] / "tests/fixtures/stage55_year5000_appendix_a_metadata.json"


def count_ie(total: int, slots: int) -> int:
    """Independent inclusion-exclusion formula (zero permitted for out-of-range)."""
    if slots == 0:
        return int(total == 0)
    excess = total - LOW * slots
    if excess < 0:
        return 0
    return sum(
        (-1) ** j * comb(slots, j) * comb(excess - WIDTH * j + slots - 1, slots - 1)
        for j in range(slots + 1)
        if excess >= WIDTH * j
    )


def count_dp_table(total: int, slots: int) -> list[list[int]]:
    """Independent fixed-width sliding window DP, no inclusion-exclusion."""
    table = [[0] * (total + 1) for _ in range(slots + 1)]
    table[0][0] = 1
    for k in range(1, slots + 1):
        previous = table[k - 1]
        current = table[k]
        window = 0
        for remaining in range(total + 1):
            entering = remaining - LOW
            leaving = remaining - HIGH - 1
            if entering >= 0:
                window += previous[entering]
            if leaving >= 0:
                window -= previous[leaving]
            current[remaining] = window
    return table


def rank_of(lengths: tuple[int, ...], count_suffix) -> tuple[int, int]:
    """Exact one-based lexicographic rank, using a supplied count algorithm."""
    rank = 1
    remaining = sum(lengths)
    for index, length in enumerate(lengths):
        slots = len(lengths) - index - 1
        assert LOW <= length <= HIGH
        for candidate in range(LOW, length):
            rank += count_suffix(remaining - candidate, slots)
        remaining -= length
    assert remaining == 0
    return rank, sum(lengths)


def unrank(rank: int, total: int, slots: int, count_suffix) -> tuple[int, ...]:
    result = []
    for i in range(slots):
        following = slots - i - 1
        for candidate in range(LOW, HIGH + 1):
            block = count_suffix(total - candidate, following)
            if rank > block:
                rank -= block
            else:
                result.append(candidate)
                total -= candidate
                break
        else:
            raise AssertionError("Exact rank is outside the composition family")
    assert rank == 1 and total == 0
    return tuple(result)


def verify_small() -> int:
    families = 0
    for n in (1, 2, 3, 4):
        for values in product(range(LOW, LOW + 3), repeat=n):
            total = sum(values)
            brute = sorted(v for v in product(range(LOW, LOW + 3), repeat=n) if sum(v) == total)
            # Verify rank in the FULL 4..123 family; lower-range values are a subset.
            tab = count_dp_table(total, n)
            rank1, _ = rank_of(values, lambda rem, k: tab[k][rem] if 0 <= rem <= total else 0)
            rank2, _ = rank_of(values, count_ie)
            assert rank1 == rank2
            assert unrank(rank1, total, n, count_ie) == values
            assert count_ie(total, n) == tab[n][total]
            assert len(brute) >= 1
            families += 1
    return families


def main() -> None:
    doc = json.loads(FIXTURE.read_text(encoding="utf-8"))
    lengths = tuple(doc["month_lengths"])
    assert doc["year"] == 5000 and doc["months"] == MONTHS
    assert len(lengths) == MONTHS and sum(lengths) == TOTAL_DAYS
    assert all(type(v) is int and LOW <= v <= HIGH for v in lengths)
    assert doc["first_day"] == -15057702 and doc["last_day"] == -15053459
    assert doc["last_day"] - doc["first_day"] + 1 == TOTAL_DAYS

    small = verify_small()
    dp = count_dp_table(TOTAL_DAYS, MONTHS)
    total_ie = count_ie(TOTAL_DAYS, MONTHS)
    total_dp = dp[MONTHS][TOTAL_DAYS]
    assert total_ie == total_dp and total_dp > 1
    independent_dp = lambda rem, k: dp[k][rem] if 0 <= rem <= TOTAL_DAYS else 0
    rank_ie, _ = rank_of(lengths, count_ie)
    rank_dp, _ = rank_of(lengths, independent_dp)
    assert rank_ie == rank_dp and 1 < rank_ie < total_ie
    assert unrank(rank_ie, TOTAL_DAYS, MONTHS, count_ie) == lengths
    assert unrank(rank_dp, TOTAL_DAYS, MONTHS, independent_dp) == lengths
    assert len(str(total_ie)) >= 50
    for idx in (0, 1, 20, 22, 43, 44):
        altered = list(lengths)
        j = idx + 1 if idx < len(altered) - 1 else idx - 1
        if altered[idx] > LOW and altered[j] < HIGH:
            altered[idx] -= 1
            altered[j] += 1
            changed_rank, _ = rank_of(tuple(altered), count_ie)
            assert changed_rank != rank_ie

    fingerprint = hashlib.sha256(",".join(map(str, lengths)).encode("ascii")).hexdigest()
    print(f"STAGE55_MONTH_LENGTH_SMALL_FORMULA_PASS FAMILIES={small}")
    print("STAGE55_YEAR5000_MONTH_LENGTH_COMPOSITION_RANK_PASS",
          f"MONTHS={MONTHS} DAYS={TOTAL_DAYS} LO={LOW} HI={HIGH}",
          "COUNT_METHODS=2 RANK_METHODS=2 ROUNDTRIPS=2")
    print(f"STAGE55_MONTH_LENGTH_LEX_RANK={rank_ie}")
    print(f"STAGE55_MONTH_LENGTH_FAMILY_COUNT={total_ie}")
    print(f"STAGE55_MONTH_LENGTH_VECTOR_SHA256={fingerprint}")
    print("STAGE55_MONTH_LENGTH_CHOSEN_STREAM_RANK_NOT_VERIFIED")
    print("STAGE55_YEAR5000_MIDDLE_WEAVE_AND_FIVE_FIELD_ORACLE_NOT_VERIFIED")
    print("STAGE55_FINAL_STAGE_PASS_NOT_VERIFIED")


if __name__ == "__main__":
    main()
