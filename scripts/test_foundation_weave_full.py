#!/usr/bin/env python3
"""Test-only exact whole-year Foundation weave oracle.

This is independent mathematical reference software. It is NOT RTL, a
synthesizable converter, or a claim that Stage 1 is accepted.
The algorithm precomputes all suffix insertion multipliers H_s(N).
"""
from __future__ import annotations
import csv
from functools import lru_cache
from hashlib import sha256
from math import comb
from pathlib import Path
from time import perf_counter

LENGTHS = [115, 108, 119, 109, 106, 81, 115, 114, 117, 120, 98, 52, 81, 97, 121, 97, 115, 96, 107, 61, 106, 115, 119, 39, 84, 103, 115, 107, 55, 119, 97, 50, 122, 110, 81, 54, 101, 83, 88, 40, 25, 77, 98, 122, 105]
EXPECTED_ROOT_SHA = "925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da"
EXPECTED_RANK_SHA = "2c447438a567fbc40a79c68fb8b3f27f308cb89a2f59aaba1d2275dd3acf1a06"
EXPECTED_WORD_SHA = "e1a291eafc34153031a0fba5e8ae0bc99a06cf0c59f4a65665c5b027b56c3a29"
BASE = (1 << 127) - 1
BOWL4_A0 = 106458209471735273212934705135928382248
DIRECTION = -1
DIGITS = 177
DAYS = 4244
MONTHS = 45
BE_BYTES = 2809

def digest(data: bytes) -> str:
    return sha256(data).hexdigest()

def minimal_be(number: int) -> bytes:
    return number.to_bytes((number.bit_length() + 7) // 8, "big")

@lru_cache(maxsize=100_000)
def binomial(n: int, k: int) -> int:
    return comb(n, k)

def ordered_last_count(remaining: list[int]) -> int:
    """A(r): old-label suffixes with ascending LAST appearances.

    Exhausted-label zeros must form a leading prefix; otherwise an
    already completed *later* month would precede an uncompleted earlier
    month, violating the canonical last-appearance order.
    """
    count = 1
    total = 0
    saw_positive = False
    for copies in remaining:
        if copies < 0:
            return 0
        if copies == 0:
            if saw_positive:
                return 0
            continue
        saw_positive = True
        total += copies
        if total > copies:
            count *= binomial(total - 1, copies - 1)
    return count

def suffix_tables() -> list[list[int] | None]:
    """H_s(N)=H_s(N-1)+C(N+v-2,N)*H_(s+1)(N+v-1).

    N copies belong to already-started months 1..s, whose last
    occurrences are ordered. v is next fresh month length. Old
    symbols' branches sum to H_s(N-1), and the first fresh symbol
    contributes the binomial times H_(s+1). H_45(N)=1.
    This computes all reachable (s,N) cells once, not 4244
    independent 45-month counts.
    """
    maxima = [0] + [sum(LENGTHS[:s]) - s for s in range(1, MONTHS + 1)]
    table: list[list[int] | None] = [None] * (MONTHS + 1)
    table[MONTHS] = [1] * (maxima[MONTHS] + 1)
    for s in range(MONTHS - 1, 0, -1):
        v = LENGTHS[s]
        next_row = table[s + 1]
        assert next_row is not None
        row: list[int] = []
        binom = 1
        acc = 0
        for n in range(maxima[s] + 1):
            if n:
                numerator = binom * (n + v - 2)
                assert numerator % n == 0
                binom = numerator // n
            acc += binom * next_row[n + v - 1]
            row.append(acc)
        table[s] = row
    return table

def selected_rank(root: int) -> int:
    space = BASE**DIGITS
    digit_value = 1
    place = 1
    for j in range(DIGITS):
        answer_digit = BOWL4_A0 - 1 + DIRECTION * j
        assert 0 <= answer_digit < BASE
        digit_value += answer_digit * place
        place *= BASE
    limit = (space // root) * root
    assert space // root == 555 and digit_value <= limit
    rank = (digit_value - 1) % root + 1
    assert rank.bit_length() == 22469
    assert digest(minimal_be(rank)) == EXPECTED_RANK_SHA
    return rank

def full_unrank(table: list[list[int] | None], rank: int) -> bytes:
    """Unrank every symbol; assert exact partition at EVERY position."""
    active_counts = [LENGTHS[0] - 1]
    started = 1
    old_total = LENGTHS[0] - 1
    old_words = 1
    result = bytearray([1])
    for position in range(2, DAYS + 1):
        row = table[started]
        assert row is not None
        parent = old_words * row[old_total]

        # Calculate EVERY older-label block, including labels after
        # the selected one, to validate the lex partition exhaustively.
        blocks: list[int] = []
        children: list[int] = []
        if old_total:
            for index in range(started):
                if active_counts[index] == 0:
                    blocks.append(0)
                    children.append(0)
                    continue
                active_counts[index] -= 1
                child_count = ordered_last_count(active_counts)
                active_counts[index] += 1
                blocks.append(child_count * row[old_total - 1])
                children.append(child_count)
        else:
            blocks = [0] * started
            children = [0] * started

        fresh_count = parent - sum(blocks)
        assert fresh_count >= 0, ("negative fresh block", position)
        if started == MONTHS:
            assert fresh_count == 0

        ordinal = 0
        for idx, size in enumerate(blocks):
            if rank <= size:
                active_counts[idx] -= 1
                old_words = children[idx]
                old_total -= 1
                ordinal = idx + 1
                break
            rank -= size

        if ordinal == 0:
            assert started < MONTHS and 0 < rank <= fresh_count
            active_counts.append(LENGTHS[started] - 1)
            old_total += LENGTHS[started] - 1
            started += 1
            old_words = ordered_last_count(active_counts)
            next_row = table[started]
            assert next_row is not None
            assert fresh_count == old_words * next_row[old_total]
            ordinal = started
        assert ordinal > 0
        result.append(ordinal)
        if position in (8, 11, 100, 1000, 2032, DAYS):
            print(f"WEAVE_REFERENCE_PROGRESS position={position} started={started} ordinal={ordinal}", flush=True)

    assert len(result) == DAYS and started == MONTHS
    assert all(value == 0 for value in active_counts) and rank == 1
    return bytes(result)

def main() -> None:
    t = perf_counter()
    assert len(LENGTHS) == MONTHS and sum(LENGTHS) == DAYS
    table = suffix_tables()
    row = table[1]
    assert row is not None
    root = row[LENGTHS[0] - 1]
    assert root.bit_length() == 22470
    assert digest(minimal_be(root)) == EXPECTED_ROOT_SHA
    print("STAGE1_FULL_YEAR_TRANSFER_ROOT_SHA256_PASS", flush=True)
    rank = selected_rank(root)
    print("STAGE1_FULL_YEAR_TRANSFER_RANK_SHA256_PASS", flush=True)
    word = full_unrank(table, rank)

    # Independent structural conservation and order checks.
    assert len(word) == DAYS and all(1 <= x <= MONTHS for x in word)
    assert [word.count(i) for i in range(1, MONTHS + 1)] == LENGTHS
    assert [word.index(i) for i in range(1, MONTHS + 1)] == sorted(word.index(i) for i in range(1, MONTHS + 1))
    assert [word.rindex(i) for i in range(1, MONTHS + 1)] == sorted(word.rindex(i) for i in range(1, MONTHS + 1))
    assert list(word[:11]) == [1, 2, 3, 4, 5, 6, 7, 4, 8, 9, 10]
    assert digest(word) == EXPECTED_WORD_SHA

    with Path("docs/FOUNDATION_MONTH_NAME_45_INDICES.csv").open(encoding="utf-8", newline="") as f:
        rows = list(csv.DictReader(f))
    assert len(rows) == MONTHS
    name_indices = [int(x["canonical_name_index"]) for x in rows]
    assert [int(x["month_ordinal"]) for x in rows] == list(range(1, MONTHS + 1))
    assert len(set(name_indices)) == MONTHS and set(range(1, 48)) - set(name_indices) == {21, 47}
    day2032 = word[2031]
    occurrence = word[:2032].count(day2032)
    assert (day2032, name_indices[day2032 - 1], occurrence) == (8, 20, 56)

    out = Path("build")
    out.mkdir(parents=True, exist_ok=True)
    (out / "foundation_weave_all4244.bin").write_bytes(word)
    (out / "foundation_weave_all4244.hex").write_text(
        "".join(f"{x:02x}\n" for x in word), encoding="ascii"
    )
    (out / "foundation_weave_reference_metrics.txt").write_text(
        f"ROOT_BITS={root.bit_length()}\nROOT_SHA256={EXPECTED_ROOT_SHA}\n"
        f"RANK_BITS={rank.bit_length()}\nRANK_SHA256={EXPECTED_RANK_SHA}\n"
        f"YEAR_DAYS={DAYS}\nWORD_SHA256={digest(word)}\n"
        f"FOUNDATION_DAY=2032\nMONTH_ORDINAL={day2032}\n"
        f"MONTH_CANONICAL_INDEX={name_indices[day2032 - 1]}\n"
        f"DAY_IN_MONTH={occurrence}\n",
        encoding="utf-8"
    )
    print(f"STAGE1_FULL_YEAR_REFERENCE_SHA256_PASS days={DAYS} digest={digest(word)}", flush=True)
    print("STAGE1_FULL_YEAR_FOUNDATION_MONTH_PASS ordinal=8 canonicalIndex=20 day=56", flush=True)
    print(f"STAGE1_FULL_YEAR_REFERENCE_RUNTIME_SECONDS={perf_counter()-t:.2f}", flush=True)

if __name__ == "__main__":
    main()
