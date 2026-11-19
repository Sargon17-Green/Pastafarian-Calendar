#!/usr/bin/env python3
"""Exact month-weave combinatorics without any calendar/date source execution.

Pure portable QA model for Ada-source repair assessment, not a patched
converter and not an independent canonical oracle. All arithmetic uses
unbounded Python integers. Months must first appear and last appear
in ascending order. Rank is one-based and lexicographic in month IDs.

The dynamic suffix table uses an independently justified recurrence:
H[j,x] = H[j,x-1] + C(x+n-2,n-2)*H[j+1,x+n-1] for n>=2.
No full-year or original F(c,t) is computed here.
"""
from __future__ import annotations

import argparse
import json
from math import comb
from pathlib import Path
from typing import Iterator

SCHEMA = "PASTAFARI_PURE_EXACT_MONTH_WEAVE_MODEL_V119/1"


class ExactMonthWeaves:
    def __init__(self, lengths: tuple[int, ...]):
        if (type(lengths) is not tuple or len(lengths) == 0
            or any(type(n) is not int or n < 1 for n in lengths)):
            raise ValueError("month lengths must be a nonempty tuple of positive integers")
        self.lengths = lengths
        self.m = len(lengths)
        self.total = sum(lengths)
        prefix = [0]
        for n in lengths:
            prefix.append(prefix[-1] + n)
        self._h: list[list[int]] = [[] for _ in range(self.m + 1)]
        self._h[self.m] = [1] * (self.total + 1)
        for j in range(self.m - 1, -1, -1):
            n = lengths[j]
            next_row = self._h[j + 1]
            current = []
            for x in range(prefix[j] + 1):
                if n == 1:
                    current.append(next_row[0])
                else:
                    # Prefix difference of the exact combinatorial sum.
                    # x=0 contributes exactly H[j+1,n-1].
                    current.append((current[-1] if x else 0) +
                                   comb(x + n - 2, n - 2) * next_row[x + n - 1])
            self._h[j] = current

    def count(self) -> int:
        return self._h[0][0]

    def _suffix_count(self, remaining: tuple[int, ...],
                      opened: int, closed: int) -> int:
        if opened < closed or opened > self.m:
            return 0
        ways, active_size = 1, 0
        for j in range(closed, opened):
            n = remaining[j]
            if n < 1:
                return 0
            if active_size:
                # Interleave current active month while respecting the
                # ascending order of the last occurrence of each month.
                ways *= comb(n + active_size - 1, active_size)
            active_size += n
        return ways * self._h[opened][active_size]

    def _moves(self, remaining: tuple[int, ...], opened: int,
               closed: int) -> Iterator[tuple[int, tuple[int, ...], int, int]]:
        for j in range(closed, opened):
            n = remaining[j]
            if n < 1 or (n == 1 and j != closed):
                continue
            new = list(remaining)
            new[j] -= 1
            yield j + 1, tuple(new), opened, closed + int(new[j] == 0)
        if opened < self.m:
            j = opened
            new = list(remaining)
            new[j] -= 1
            if new[j] == 0 and j != closed:
                return  # This opening move is illegal; prior active moves remain valid.
            yield j + 1, tuple(new), opened + 1, closed + int(new[j] == 0)

    def unrank1(self, rank1: int) -> tuple[int, ...]:
        if type(rank1) is not int or rank1 < 1 or rank1 > self.count():
            raise ValueError("one-based month weave rank outside range")
        remaining, opened, closed = self.lengths, 0, 0
        result: list[int] = []
        for _ in range(self.total):
            for name, new, new_opened, new_closed in self._moves(
                    remaining, opened, closed):
                block = self._suffix_count(new, new_opened, new_closed)
                if rank1 > block:
                    rank1 -= block
                else:
                    result.append(name)
                    remaining, opened, closed = new, new_opened, new_closed
                    break
            else:
                raise AssertionError("no completion block for valid rank")
        if (rank1 != 1 or any(remaining) or
            opened != self.m or closed != self.m):
            raise AssertionError("unranking left nonfinal state")
        return tuple(result)

    def rank1(self, word: tuple[int, ...]) -> int:
        if type(word) is not tuple or len(word) != self.total:
            raise ValueError("expected complete canonical month weave tuple")
        remaining, opened, closed = self.lengths, 0, 0
        rank = 1
        for required in word:
            if type(required) is not int:
                raise ValueError("invalid month ID")
            for name, new, new_opened, new_closed in self._moves(
                    remaining, opened, closed):
                if name == required:
                    remaining, opened, closed = new, new_opened, new_closed
                    break
                rank += self._suffix_count(new, new_opened, new_closed)
            else:
                raise ValueError("word violates opening/closing order")
        if any(remaining) or opened != self.m or closed != self.m:
            raise ValueError("word did not close all months")
        return rank


def brute_words(lengths: tuple[int, ...]) -> tuple[tuple[int, ...], ...]:
    """Exhaustive independent test oracle; small examples only."""
    if not lengths or sum(lengths) > 12 or any(
            type(n) is not int or n < 1 for n in lengths):
        raise ValueError("brute force restricted to small positive test cases")
    out = []
    def visit(remaining: tuple[int, ...], opened: int, closed: int,
              path: tuple[int, ...]) -> None:
        if not any(remaining):
            if opened != len(lengths) or closed != len(lengths):
                raise AssertionError("bad brute final state")
            out.append(path)
            return
        for j in range(closed, opened):
            n = remaining[j]
            if n < 1 or (n == 1 and j != closed):
                continue
            future = list(remaining)
            future[j] -= 1
            visit(tuple(future), opened, closed + int(future[j] == 0),
                  path + (j + 1,))
        if opened < len(lengths):
            j = opened
            future = list(remaining)
            future[j] -= 1
            if future[j] == 0 and j != closed:
                return  # No legal opening branch; other visited branches are retained.
            visit(tuple(future), opened + 1, closed + int(future[j] == 0),
                  path + (j + 1,))
    visit(lengths, 0, 0, ())
    return tuple(sorted(out))


def pure_verdict() -> dict:
    small = ExactMonthWeaves((4, 4))
    stress = ExactMonthWeaves((123,) * 46 + (120,))
    if small.count() != 20:
        raise AssertionError("two-month full family count is not 20")
    if small.rank1((1, 1, 1, 1, 2, 2, 2, 2)) != 1:
        raise AssertionError("lexicographic first weave changed")
    if stress.count().bit_length() < 10_000:
        raise AssertionError("large exact count was unexpectedly truncated")
    return {
        "schema": SCHEMA,
        "status": "EXACT_COMBINATORIAL_COUNT_AND_SMALL_RANK_UNRANK_NOT_DATE",
        "small_length_pair": [4, 4],
        "small_family_count": 20,
        "large_months": 47,
        "large_total_days": 5778,
        "large_count_bit_length": stress.count().bit_length(),
        "native_calendar_conversion_executed": False,
        "ada_candidate_source_modified": False,
        "ada_original_source_unchanged": True,
        "scientific_source_mismatch_resolved": False,
        "new_native_soak_dispatch_stopped": True,
        "full_original_years_certified": 0,
        "ten_thousand_years_certified": 0,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--verdict-out",required=True,type=Path)
    args = parser.parse_args()
    report = pure_verdict()
    with args.verdict_out.open("x", encoding="utf8") as stream:
        json.dump(report,stream,sort_keys=True,indent=2,ensure_ascii=False)
        stream.write("\n")
    print("V119_EXACT_MONTH_WEAVE_COUNT_47_MONTHS_NO_DATE_PASS")


if __name__ == "__main__":
    main()
