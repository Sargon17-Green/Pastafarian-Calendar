#!/usr/bin/env python3
"""Independent Python integer oracle for isolated Logo wide Horner QA.
This is a targeted Native smoke probe, NOT the Stage2 acceptance matrix.
"""
import argparse
from pathlib import Path
from logo_stage2_wide_general_native_vectors import M, general_rank, logo_bi

def cases_for(width):
    if width == 4:
        space = M ** 4
        return [
            (M - 4, 1, space, "k4_no_rejection"),
            (M // 2 + 1, 1, (space + 1) // 2, "k4_upper_half_forward"),
            (M // 2 + 1, -1, (space + 1) // 2, "k4_upper_half_reverse"),
            (1, -1, M ** 3 + 1, "k4_general_division"),
        ]
    if width == 64:
        return [(M - 64, 1, M ** 64, "k64_no_rejection")]
    raise ValueError(width)

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--width", type=int, choices=(4, 64), required=True)
    p.add_argument("--output", type=Path, required=True)
    args = p.parse_args()
    cases = cases_for(args.width)
    pieces = [
        'load "src/exact_integer.logo\n',
        'load "src/stage02_context.logo\n',
        'load "src/stage02_answer_at.logo\n',
        'load "src/stage02_choose_wide.logo\n',
        'load "src/stage02_choose_wide_general.logo\n',
        'make "FAST.CASES 0\n',
        'to wide.fast.check :stream :N :expected :tag\n',
        '  print sentence [WIDE_FAST_CASE_START] :tag\n',
        '  localmake "actual monster.stage02.choose.wide.general :stream :N\n',
        '  if not (monster.stage02.bi.canonical :actual) [print [WIDE_FAST_BAD_SHAPE] stop]\n',
        '  if not (bi.eq :actual :expected) [print [WIDE_FAST_WRONG_RANK] stop]\n',
        '  make "FAST.CASES (:FAST.CASES + 1)\n',
        '  print sentence [WIDE_FAST_CASE_PASIS] :tag\n',
        'end\n',
    ]
    for first, direction, n, tag in cases:
        expected, k, sample, limit = general_rank(first, direction, n)
        assert k == args.width
        if tag.endswith("no_rejection"):
            assert n == M ** k and expected == sample
        if "upper_half" in tag:
            assert n > M ** k - n
        pieces += [
            '(wide.fast.check\n',
            f'  (list {logo_bi(first)} {direction})\n',
            f'  {logo_bi(n)}\n',
            f'  {logo_bi(expected)}\n',
            f'  [{tag}]\n',
            ')\n',
        ]
    pieces += [
        f'if :FAST.CASES <> {len(cases)} [print [WIDE_FAST_CASE_COUNT_FALIIS] stop]\n',
        f'print [WIDE_FAST_QA_COMPLETED_{args.width}]\n',
    ]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("".join(pieces), encoding="utf-8")
    print(f"QA_FAST_HOST_CASES={len(cases)} WIDTH={args.width}")
    print("QA_FAST_INDEPENDENT_PYTHON_ORACLE=READY")
    print("QA_FAST_FULL_STAGE2_ACCEPTANCE=NO")

if __name__ == "__main__":
    main()
