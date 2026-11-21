#!/usr/bin/env python3
"""QA-only independent Python-integer differential vectors for two-digit Logo wide.

No production Logo code or normative Logo implementation is imported or evaluated.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import logo_stage2_wide_selection_host_oracle as finite_audit

M = (1 << 127) - 1
S = M * M
BASE = 10000
VALID = 96
INVALID = 16
REJECTED = 11


def bi(value: int) -> str:
    assert value > 0
    digits = []
    while value:
        value, remainder = divmod(value, BASE)
        digits.append(str(remainder))
    return "(bi.make 1 [" + " ".join(digits) + "])"


def rank_by_independent_integer_oracle(first: int, step: int, n: int):
    assert 1 <= first <= M and step in (-1, 1) and M < n <= S
    successor = first + step
    if successor == M + 1:
        successor = 1
    if successor == 0:
        successor = M
    sample = first + M * (successor - 1)
    q, rem = divmod(S, n)
    assert q >= 1 and 0 <= rem < n
    limit = S - rem
    assert limit == q * n and 1 <= sample <= S
    if sample <= limit:
        return ((sample - 1) % n) + 1, False
    # Check the immediately preceding rejected candidate in the selected
    # cyclic direction.  No enumeration of an astronomically long gap.
    assert rem > 0 and limit < sample <= S
    if step == 1:
        boundary = (sample + (S - sample)) % S + 1
        assert boundary == 1 and boundary <= limit
        return 1, True
    boundary = limit
    assert 1 <= boundary <= S
    assert ((boundary - 1) % n) + 1 == n
    return n, True


HEADER = r"""load "src/exact_integer.logo
load "src/source_language_catalog.logo
load "src/monster_bootstrap.logo
load "src/stage02_boundary.logo
load "src/stage02_context.logo
load "src/stage02_answer_at.logo
load "src/stage02_choose_wide.logo

make "WIDE.CASES 0
make "WIDE.CHECKS 0
make "WIDE.FAILED "false

to wide.require :condition :tag
  make "WIDE.CHECKS (:WIDE.CHECKS + 1)
  if not :condition [
    make "WIDE.FAILED "true
    print sentence [WIDE_TESTO_FALIIS:] :tag
  ]
end

to wide.safe.equal :actual :expected
  if not (monster.stage02.bi.canonical :actual) [output "false]
  output bi.eq :actual :expected
end

to wide.safe.range :actual :N
  if not (monster.stage02.bi.canonical :actual) [output "false]
  output (and (bi.ge :actual (bi.small 1)) (bi.le :actual :N))
end

to wide.good :stream :N :expected :tag
  make "WIDE.CASES (:WIDE.CASES + 1)
  localmake "actual monster.stage02.choose.wide :stream :N
  wide.require (monster.stage02.bi.canonical :actual) (list :tag [canonical_shape])
  wide.require (wide.safe.equal :actual :expected) (list :tag [python_differential])
  wide.require (wide.safe.range :actual :N) (list :tag [rank_range])
  wide.require (equalp :actual (monster.stage02.choose.wide :stream :N)) (list :tag [determinism])
end

to wide.invalid :stream :N :tag
  make "WIDE.CASES (:WIDE.CASES + 1)
  wide.require (equalp (monster.stage02.choose.wide :stream :N) []) :tag
end

"""

BAD = r"""wide.invalid "not_a_list (bi.add nr.M (bi.small 1)) [stream_word]
wide.invalid (list (bi.small 1)) (bi.add nr.M (bi.small 1)) [stream_one]
wide.invalid (list (bi.small 1) 1 2) (bi.add nr.M (bi.small 1)) [stream_three]
wide.invalid (list bi.zero 1) (bi.add nr.M (bi.small 1)) [first_zero]
wide.invalid (list (bi.add nr.M (bi.small 1)) 1) (bi.add nr.M (bi.small 1)) [first_over_M]
wide.invalid (list "not_bi 1) (bi.add nr.M (bi.small 1)) [first_non_BI]
wide.invalid (list (list 0 [1]) 1) (bi.add nr.M (bi.small 1)) [first_not_canonical]
wide.invalid (list (bi.small 1) 0) (bi.add nr.M (bi.small 1)) [step_zero]
wide.invalid (list (bi.small 1) 2) (bi.add nr.M (bi.small 1)) [step_two]
wide.invalid (list (bi.small 1) 0.5) (bi.add nr.M (bi.small 1)) [step_fraction]
wide.invalid (list (bi.small 1) "wrong) (bi.add nr.M (bi.small 1)) [step_word]
wide.invalid (list (bi.small 1) 1) "invalid [N_non_BI]
wide.invalid (list (bi.small 1) 1) bi.zero [N_zero]
wide.invalid (list (bi.small 1) 1) nr.M [N_not_wide]
wide.invalid (list (bi.small 1) 1) (bi.add (bi.square nr.M) (bi.small 1)) [N_over_space]
wide.invalid (list (bi.small 1) 1) (bi.small -1) [N_negative]
"""


def main(output: Path) -> None:
    finite_audit.verify()  # independent finite-circle walker: 3340 cases
    ns = [M + 1, M + 2, 2 * M, S // 3, S // 2 + 1, S - M, S - 1, S]
    starts = [1, 2, M // 2, M - 2, M - 1, M]
    assert len(set(ns)) == 8 and len(set(starts)) == 6
    lines = [HEADER]
    good = rejected = 0
    rejected_plus = rejected_minus = 0
    for n in ns:
        for first in starts:
            for step in (-1, 1):
                expected, was_rejected = rank_by_independent_integer_oracle(first, step, n)
                good += 1
                if was_rejected:
                    rejected += 1
                    if step == 1:
                        rejected_plus += 1
                    else:
                        rejected_minus += 1
                lines.append(
                    f"wide.good (list {bi(first)} {step}) {bi(n)} "
                    f"{bi(expected)} [v{good:03d}]\n"
                )
    assert good == VALID and rejected == REJECTED
    assert (rejected_plus, rejected_minus) == (5, 6)
    lines.append(BAD)
    cases = VALID + INVALID
    checks = 4 * VALID + INVALID
    lines.append(f"""
if :WIDE.FAILED [print [WIDE_NATIVE_FALIIS] stop]
if :WIDE.CASES <> {cases} [print [WIDE_NATIVE_CASE_COUNT_FALIIS] stop]
if :WIDE.CHECKS <> {checks} [print [WIDE_NATIVE_CHECK_COUNT_FALIIS] stop]
print sentence [WIDE_NATIVE_CASES_PASIS] :WIDE.CASES
print sentence [WIDE_NATIVE_CHECKS_PASIS] :WIDE.CHECKS
print [WIDE_NATIVE_PASIS]
""")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("".join(lines), encoding="utf-8")
    print(f"WIDE_HOST_VALID {good}")
    print(f"WIDE_HOST_REJECTED {rejected}")
    print(f"WIDE_HOST_REJECTED_PLUS {rejected_plus}")
    print(f"WIDE_HOST_REJECTED_MINUS {rejected_minus}")
    print(f"WIDE_HOST_CASES {cases}")
    print(f"WIDE_HOST_CHECKS {checks}")
    print("WIDE_HOST_ORACLE=PASS")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    main(args.output)
