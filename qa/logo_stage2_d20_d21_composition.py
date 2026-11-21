#!/usr/bin/env python3
"""QA-only D20/D21 composition fixtures; independent finite Python integer walk."""
from __future__ import annotations
import argparse
from pathlib import Path

M = (1 << 127) - 1
EXPECTED = (150, 18, 6, 4, 1094)

HEADER = r'''; Stage2 D20/D21 QA-only composition.
load "src/exact_integer.logo
load "src/source_language_catalog.logo
load "src/monster_bootstrap.logo
load "src/stage02_boundary.logo
load "src/stage02_context.logo
load "src/stage02_answer_at.logo
load "src/stage02_choose_short.logo
make "QCOMBO.CASES 0
make "QCOMBO.CHECKS 0
make "QCOMBO.FAIL "false

to qcombo.require :condition :tag
  make "QCOMBO.CHECKS (:QCOMBO.CHECKS + 1)
  if not :condition [
    make "QCOMBO.FAIL "true
    print sentence [QCOMBO_TESTO_FALIIS:] :tag
  ]
end

to qcombo.eq :actual :expected
  if not (monster.stage02.bi.canonical :actual) [output "false]
  output bi.eq :actual :expected
end

to qcombo.le :actual :limit
  if not (monster.stage02.bi.canonical :actual) [output "false]
  output bi.le :actual :limit
end

to qcombo.gt :actual :limit
  if not (monster.stage02.bi.canonical :actual) [output "false]
  output bi.gt :actual :limit
end

to qcombo.case :stream :N :k :valueExpected :rankExpected :limit :tag
  make "QCOMBO.CASES (:QCOMBO.CASES + 1)
  localmake "at monster.stage02.answer.at :stream :k
  localmake "rank monster.stage02.choose.short :stream :N
  qcombo.require (monster.stage02.bi.canonical :at) (list :tag [at_shape])
  qcombo.require (qcombo.eq :at :valueExpected) (list :tag [first_accepted_at])
  qcombo.require (monster.stage02.bi.canonical :rank) (list :tag [rank_shape])
  qcombo.require (qcombo.eq :rank :rankExpected) (list :tag [rank_from_walk])
  qcombo.require (qcombo.le :at :limit) (list :tag [at_accepted])
  qcombo.require (equalp :at (monster.stage02.answer.at :stream :k)) (list :tag [at_repeat])
  qcombo.require (equalp :rank (monster.stage02.choose.short :stream :N)) (list :tag [rank_repeat])
  if :k > 0 [
    localmake "prev monster.stage02.answer.at :stream (:k - 1)
    qcombo.require (qcombo.gt :prev :limit) (list :tag [previous_rejected])
  ]
end

to qcombo.invalid :stream :N :tag
  make "QCOMBO.CASES (:QCOMBO.CASES + 1)
  qcombo.require (equalp (monster.stage02.answer.at :stream 0) []) (list :tag [at_reject])
  qcombo.require (equalp (monster.stage02.choose.short :stream :N) []) (list :tag [choose_reject])
end
'''


def bi(value: int) -> str:
    assert value > 0
    digits = []
    while value:
        value, remainder = divmod(value, 10000)
        digits.append(str(remainder))
    return "(bi.make 1 [" + " ".join(digits) + "])"


def walk(first: int, step: int, limit: int):
    x = first
    for k in range(32):
        if x <= limit:
            return k, x
        x += step
        if x == M + 1:
            x = 1
        elif x == 0:
            x = M
    return None


def matrix():
    ns = [1, 2, 3, 7, 31, 97, 10000, M // 7, M // 2, M - 64, M - 1, M]
    assert len(set(ns)) == len(ns)
    for n in ns:
        limit = (M // n) * n
        choices = [1, 2, limit - 1, limit, limit + 1, limit + 2,
                   limit + 31, M - 30, M - 1, M]
        for first in dict.fromkeys(v for v in choices if 1 <= v <= M):
            for step in (-1, 1):
                yield n, limit, first, step


def run(destination: Path):
    content = [HEADER]
    valid = skipped = at31 = nonzero = 0
    for n, limit, first, step in matrix():
        accepted = walk(first, step, limit)
        if accepted is None:
            skipped += 1
            continue
        k, value = accepted
        assert 1 <= value <= limit and 0 <= k <= 31
        nonzero += int(k > 0)
        at31 += int(k == 31)
        rank = 1 + (value - 1) % n
        assert 1 <= rank <= n
        valid += 1
        content.append(
            f"qcombo.case (list {bi(first)} {step}) {bi(n)} {k} "
            f"{bi(value)} {bi(rank)} {bi(limit)} [c{valid:03d}]\n"
        )
    content.append("""
qcombo.invalid "notlist (bi.small 1) [not_list]
qcombo.invalid (list (bi.small 1)) (bi.small 1) [length_one]
qcombo.invalid (list bi.zero 1) (bi.small 1) [zero_first]
qcombo.invalid (list (bi.small 1) 0) (bi.small 1) [bad_step]
if :QCOMBO.FAIL [print [QCOMBO_FALIIS] stop]
if :QCOMBO.CASES <> 154 [print [QCOMBO_CASE_COUNT_FALIIS] stop]
if :QCOMBO.CHECKS <> 1094 [print [QCOMBO_CHECK_COUNT_FALIIS] stop]
print sentence [QCOMBO_NATIVE_CASES_PASIS] :QCOMBO.CASES
print sentence [QCOMBO_NATIVE_CHECKS_PASIS] :QCOMBO.CHECKS
print [QCOMBO_NATIVE_PASIS]
""")
    checks = 7 * valid + nonzero + 2 * 4
    assert (valid, skipped, at31, 4, checks) == EXPECTED
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text("".join(content), encoding="utf-8")
    print(f"QCOMBO_HOST_VALID {valid}")
    print(f"QCOMBO_HOST_SKIPPED {skipped}")
    print(f"QCOMBO_HOST_AT_K31 {at31}")
    print(f"QCOMBO_HOST_INVALID 4")
    print(f"QCOMBO_HOST_CHECKS {checks}")
    print("QCOMBO_HOST_ORACLE=PASS")


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--output", type=Path, required=True)
    run(p.parse_args().output)
