#!/usr/bin/env python3
"""Independent arbitrary-precision integer oracle; generates Native Logo differential cases.

No imports or execution of production Logo. Fixed seed-free boundary matrix.
The smaller distances are checked by a genuine +/-1 iterative walker; large gaps
are checked using modular projection at candidate and predecessor plus interval proof.
"""
from __future__ import annotations
import argparse
from pathlib import Path

M = (1 << 127) - 1
BASE = 10000
EXPECTED_VALID = 134
EXPECTED_INVALID = 13
EXPECTED_LONG = 15

def bi(value: int) -> str:
    if value <= 0:
        raise ValueError("positive BI literal expected")
    digits = []
    while value:
        value, remainder = divmod(value, BASE)
        digits.append(str(remainder))
    return "(bi.make 1 [" + " ".join(digits) + "])"

def project(first: int, direction: int, index: int) -> int:
    return 1 + ((first - 1 + direction * index) % M)

def reference(n: int, first: int, direction: int) -> tuple[int, int]:
    assert 1 <= n <= M and 1 <= first <= M and direction in (-1, 1)
    q, r = divmod(M, n)
    limit = q * n
    x = first
    # Distinct test oracle: test one value at a time for small gaps.
    for index in range(33):
        if x <= limit:
            return 1 + ((x - 1) % n), index
        x = x + direction
        if x == M + 1:
            x = 1
        elif x == 0:
            x = M
    # For very long gaps, verify the exact boundary and predecessor by
    # modular projection, without iterating a potentially 10^38-sized gap.
    index = (M - first + 1) if direction == 1 else (first - limit)
    if index <= 32:
        raise AssertionError("inconsistent walk/boundary")
    current = project(first, direction, index)
    previous = project(first, direction, index - 1)
    assert 1 <= current <= limit and limit < previous <= M
    assert index <= r < n
    return 1 + ((current - 1) % n), index

def matrix():
    n_values = [1, 2, 3, 7, 31, 97, 10000,
                M // 7, M // 3, M // 2, M // 2 + 1,
                M - 31, M - 1, M]
    assert len(set(n_values)) == len(n_values)
    for n in n_values:
        q, r = divmod(M, n)
        limit = q * n
        first_values = [1, limit - 1, limit, limit + 1,
                        limit + 33, M - 1, M]
        for first in dict.fromkeys(first_values):
            if not 1 <= first <= M:
                continue
            for direction in (1, -1):
                yield n, first, direction

def small_exhaustive():
    # Independent model cross-check across small finite moduli.
    total = 0
    for modulus in range(2, 49):
        for n in range(1, modulus + 1):
            limit = (modulus // n) * n
            for first in range(1, modulus + 1):
                for direction in (-1, 1):
                    x = first
                    for index in range(modulus):
                        if x <= limit:
                            iterative = (1 + (x - 1) % n, index)
                            break
                        x += direction
                        if x == modulus + 1:
                            x = 1
                        elif x == 0:
                            x = modulus
                    if first <= limit:
                        closed = (1 + (first - 1) % n, 0)
                    elif direction == 1:
                        closed = (1, modulus - first + 1)
                    else:
                        closed = (n, first - limit)
                    assert iterative == closed, (modulus, n, first, direction)
                    total += 1
    return total

HEADER = r''' ; D21 unrestricted-N QA candidate. Differential oracle is Python integers.
load "src/exact_integer.logo
load "src/source_language_catalog.logo
load "src/monster_bootstrap.logo
load "src/stage02_boundary.logo
load "src/stage02_context.logo
load "src/stage02_choose_short.logo

make "D21U.CASES 0
make "D21U.CHECKS 0
make "D21U.FAILED "false

to d21u.require :condition :tag
  make "D21U.CHECKS (:D21U.CHECKS + 1)
  if not :condition [
    make "D21U.FAILED "true
    print sentence [D21U_TESTO_FALIIS:] :tag
  ]
end

to d21u.safe.equal :actual :expected
  if not (monster.stage02.bi.canonical :actual) [output "false]
  output bi.eq :actual :expected
end

to d21u.safe.range :actual :N
  if not (monster.stage02.bi.canonical :actual) [output "false]
  output (and (bi.ge :actual (bi.small 1)) (bi.le :actual :N))
end

to d21u.case :stream :N :expected :tag
  make "D21U.CASES (:D21U.CASES + 1)
  localmake "result monster.stage02.choose.short :stream :N
  d21u.require (monster.stage02.bi.canonical :result) (list :tag [canonical_shape])
  d21u.require (d21u.safe.equal :result :expected) (list :tag [python_integer_differential])
  d21u.require (d21u.safe.range :result :N) (list :tag [rank_range])
  d21u.require (equalp :result (monster.stage02.choose.short :stream :N)) (list :tag [repeat])
end

to d21u.invalid :stream :N :tag
  make "D21U.CASES (:D21U.CASES + 1)
  d21u.require (equalp (monster.stage02.choose.short :stream :N) []) :tag
end
'''
INVALID = r'''
d21u.invalid "not_a_list (bi.small 1) [stream_not_list]
d21u.invalid (list (bi.small 1)) (bi.small 1) [stream_length_one]
d21u.invalid (list (bi.small 1) 1 2) (bi.small 1) [stream_length_three]
d21u.invalid (list bi.zero 1) (bi.small 1) [first_zero]
d21u.invalid (list (bi.add nr.M (bi.small 1)) 1) (bi.small 1) [first_above_M]
d21u.invalid (list "not_bi 1) (bi.small 1) [first_non_BI]
d21u.invalid (list (bi.small 1) 0) (bi.small 1) [step_zero]
d21u.invalid (list (bi.small 1) 2) (bi.small 1) [step_two]
d21u.invalid (list (bi.small 1) 0.5) (bi.small 1) [step_fraction]
d21u.invalid (list (bi.small 1) 1) "invalid [N_non_BI]
d21u.invalid (list (bi.small 1) 1) bi.zero [N_zero]
d21u.invalid (list (bi.small 1) 1) (bi.add nr.M (bi.small 1)) [N_above_M]
d21u.invalid (list (bi.small 1) 1) (bi.small -1) [N_negative]
'''

def run(target: Path):
    small_count = small_exhaustive()
    cases = list(matrix())
    assert len(cases) == EXPECTED_VALID
    assert len(set(cases)) == len(cases)
    rendered = [HEADER]
    long_gaps = 0
    for case_no, (n, first, direction) in enumerate(cases, 1):
        rank, index = reference(n, first, direction)
        assert 1 <= rank <= n
        if index > 32:
            long_gaps += 1
        rendered.append(
            f"d21u.case (list {bi(first)} {direction}) {bi(n)} "
            f"{bi(rank)} [v{case_no:03d}]\n"
        )
    assert long_gaps == EXPECTED_LONG and long_gaps > 0
    rendered.append(INVALID)
    total = len(cases) + EXPECTED_INVALID
    checks = 4 * len(cases) + EXPECTED_INVALID
    rendered.append(
        f'\nif :D21U.FAILED [print [D21U_NATIVE_FALIIS] stop]\n'
        f'if :D21U.CASES <> {total} [print [D21U_NATIVE_CASE_COUNT_FALIIS] stop]\n'
        f'if :D21U.CHECKS <> {checks} [print [D21U_NATIVE_CHECK_COUNT_FALIIS] stop]\n'
        f'print sentence [D21U_NATIVE_CASES_PASIS] :D21U.CASES\n'
        f'print sentence [D21U_NATIVE_CHECKS_PASIS] :D21U.CHECKS\n'
        f'print [D21U_NATIVE_PASIS]\n')
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text("".join(rendered), encoding="utf-8")
    print(f"D21U_HOST_SMALL_EXHAUSTIVE {small_count}")
    print(f"D21U_HOST_VALID {len(cases)}")
    print(f"D21U_HOST_LONG_GAPS {long_gaps}")
    print(f"D21U_HOST_CASES {total}")
    print(f"D21U_HOST_CHECKS {checks}")
    print("D21U_HOST_ORACLE=PASS")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    run(args.output)
