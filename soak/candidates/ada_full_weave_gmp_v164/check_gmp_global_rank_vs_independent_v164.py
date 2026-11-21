#!/usr/bin/env python3
"""Independent exact Python-int synthetic wide rank and complete 4244-slot weave.

No imports from any original calendar or production converter. No F(c,t),
no target date, no native soak. Reads Ada GMP stdout from synthetic runner.
"""
from __future__ import annotations

from hashlib import sha256
import json
from math import comb
from pathlib import Path
import sys

M = (1 << 127) - 1
LENGTHS = (94,) * 44 + (108,)
EXPECTED_RANK_HEX_SHA256 = "78fffb65d80a90ddc06ce28d9e4f923c875dfd79df31981d2c93142ba6805da6"
EXPECTED_WORD_SHA256 = "9cc619a97cd6302ffe3c7471d74087bdcfbb6deeac7d861f3e5a9a9d02bdea91"


def table(lengths: tuple[int, ...]) -> list[list[int]]:
    p = [0]
    for n in lengths:
        p.append(p[-1] + n)
    h: list[list[int]] = [[] for _ in range(len(lengths) + 1)]
    h[-1] = [1] * (p[-1] + 1)
    for i in range(len(lengths) - 1, -1, -1):
        n = lengths[i]
        row = [0] * (p[i] + 1)
        prefix = 0
        for y in range(n - 1, p[i + 1]):
            prefix += comb(y - 1, n - 2) * h[i + 1][y]
            row[y - n + 1] = prefix
        h[i] = row
    return h


def pick_wide_rank(n: int, first: int, step: int) -> int:
    places, space = 1, M
    while space < n:
        places += 1
        space *= M
    wide, weight = 1, 1
    for j in range(places):
        wide += ((first - 1 + step * j) % M) * weight
        weight *= M
    limit = (space // n) * n
    if wide > limit:
        wide = limit if step == -1 else 1
    return (wide - 1) % n + 1


def enumerate_rank(lengths: tuple[int, ...], h: list[list[int]], rank: int) -> list[int]:
    remain = list(lengths)
    opened = closed = 0
    output: list[int] = []
    def subtree(rem: list[int], active: int, ended: int) -> int:
        factor, total = 1, 0
        for i in range(ended, active):
            n = rem[i]
            if n <= 0:
                return 0
            if total == 0:
                total = n
            else:
                factor *= comb(n + total - 1, total)
                total += n
        return factor * h[active][total]

    for _ in range(sum(lengths)):
        chosen = False
        for idx in range(closed, min(opened + 1, len(lengths))):
            n = remain[idx]
            if n <= 0 or (n == 1 and idx != closed):
                continue
            remain[idx] -= 1
            next_opened = max(opened, idx + 1)
            next_closed = closed + (remain[idx] == 0)
            count = subtree(remain, next_opened, next_closed)
            if rank > count:
                rank -= count
                remain[idx] += 1
            else:
                output.append(idx + 1)
                opened, closed = next_opened, next_closed
                chosen = True
                break
        if not chosen:
            raise AssertionError("independent Python global rank did not resolve")
    if rank != 1 or opened != len(lengths) or closed != len(lengths) or any(remain):
        raise AssertionError("independent Python global rank incomplete")
    return output


def digest(text: str) -> str:
    return sha256(text.encode("ascii")).hexdigest()


def main() -> int:
    if len(sys.argv) != 3:
        raise RuntimeError("usage: check_global.py ADA_STDOUT RECEIPT_JSON")
    source, target = Path(sys.argv[1]), Path(sys.argv[2])
    lines = source.read_text(encoding="utf-8").splitlines()
    def unique_line(prefix: str) -> str:
        hits = [x[len(prefix):] for x in lines if x.startswith(prefix)]
        if len(hits) != 1:
            raise RuntimeError("expected one Ada GMP line prefixed " + prefix)
        return hits[0]

    ada_rank = unique_line("V164_SYNTHETIC_GLOBAL_RANK_HEX=")
    ada_word = [int(x) for x in unique_line("V164_SYNTHETIC_GLOBAL_WEAVE_CSV=").split(",")]
    if "V164_SYNTHETIC_GLOBAL_RANK_FULL_4244_WEAVE_PASS_NO_F" not in lines:
        raise RuntimeError("Ada synthetic final validity marker absent")
    if len(ada_word) != 4244 or not ada_rank or ada_rank[0] == "0":
        raise RuntimeError("invalid Ada synthetic rank/weave width")

    h = table(LENGTHS)
    count = h[0][0]
    rank = pick_wide_rank(count, first=42, step=-1)
    py_word = enumerate_rank(LENGTHS, h, rank)
    rank_hex = format(rank, "x")
    if ada_rank != rank_hex or ada_word != py_word:
        raise RuntimeError("Ada GMP huge global rank or full weave does not equal independent Python")
    text = json.dumps(py_word, separators=(",", ":"))
    if digest(rank_hex) != EXPECTED_RANK_HEX_SHA256:
        raise RuntimeError("independent rank digest is not the pinned witness")
    if digest(text) != EXPECTED_WORD_SHA256:
        raise RuntimeError("independent full weave digest is not the pinned witness")

    receipt = {
        "schema": "ISSUE29_V164_INDEPENDENT_FULL_SYNTHETIC_GLOBAL_RANK_AND_WEAVE/1",
        "source_mode": "NATIVE_ADA_GMP_VS_PURE_PYTHON_INT_NO_CALENDAR_CODE",
        "lengths": "44x94 + 1x108",
        "months": len(LENGTHS),
        "slots": len(py_word),
        "global_rank_hex_sha256": digest(rank_hex),
        "global_rank_bit_length": rank.bit_length(),
        "weave_json_sha256": digest(text),
        "first_32_month_ids": py_word[:32],
        "synthetic_offset_2031_month_id": py_word[2031],
        "exact_rank_agreement": True,
        "all_4244_month_ids_identical": True,
        "calendar_F_calls": 0,
        "soak_years": 0,
    }
    target.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n")
    print("V164_INDEPENDENT_EXACT_GLOBAL_RANK_AND_ALL_4244_WEAVE_IDS_PASS_NO_F")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
