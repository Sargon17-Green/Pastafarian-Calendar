#!/usr/bin/env python3
"""Generate exact-BI Native fixtures for general Logo+Ido wide selection.

Expected ranks are derived from Python integers only. No Logo source,
normative Logo reference, or existing WIDE2 fixture is imported or executed.
"""

from __future__ import annotations

import argparse
from pathlib import Path

M = (1 << 127) - 1
BASE = 10000
WIDTHS = (3, 4, 5, 32, 33, 64)


def logo_bi(value: int) -> str:
    if value == 0:
        return "bi.zero"
    sign = 1 if value > 0 else -1
    magnitude = abs(value)
    digits = []
    while magnitude:
        magnitude, remainder = divmod(magnitude, BASE)
        digits.append(str(remainder))
    rows = [" ".join(digits[i:i + 18]) for i in range(0, len(digits), 18)]
    if len(rows) == 1:
        return f"(bi.make {sign} [{rows[0]}])"
    return f"(bi.make {sign} [\n      " + "\n      ".join(rows) + "\n    ])"


def advance(value: int, direction: int, modulus: int) -> int:
    if direction == 1:
        return 1 if value == modulus else value + 1
    if direction == -1:
        return modulus if value == 1 else value - 1
    raise AssertionError(direction)


def min_width(count: int) -> tuple[int, int]:
    width = 1
    space = M
    while space < count:
        space *= M
        width += 1
    return width, space


def initial_wide(first: int, direction: int, width: int) -> int:
    value = 1
    weight = 1
    digit = first
    for _ in range(width):
        value += (digit - 1) * weight
        weight *= M
        digit = advance(digit, direction, M)
    return value


def general_rank(first: int, direction: int, count: int) -> tuple[int, int, int, int]:
    width, space = min_width(count)
    sample = initial_wide(first, direction, width)
    limit = space - (space % count)
    if sample <= limit:
        return 1 + ((sample - 1) % count), width, sample, limit
    return (1 if direction == 1 else count), width, sample, limit


def legacy_two_digit_rank(first: int, direction: int, count: int) -> int:
    second = advance(first, direction, M)
    sample = first + M * (second - 1)
    space = M * M
    limit = space - (space % count)
    if sample <= limit:
        return 1 + ((sample - 1) % count)
    return 1 if direction == 1 else count


def find_rejecting_start(width: int, direction: int, count: int) -> int:
    midpoint = M // 2 + 1
    for offset in range(0, 4 * width + 64):
        first = midpoint + offset
        if first > M:
            break
        if initial_wide(first, direction, width) > count:
            return first
    raise AssertionError((width, direction, count))


def valid_cases():
    cases = []
    for tag, first, direction, count in (
        ("k2_lower_boundary", 1, 1, M + 1),
        ("k2_upper_boundary", M, -1, M * M),
    ):
        expected = legacy_two_digit_rank(first, direction, count)
        cases.append(("two", first, direction, count, expected, tag))

    k2_reject_count = (M * M + 1) // 2
    for direction in (-1, 1):
        first = find_rejecting_start(2, direction, k2_reject_count)
        expected = legacy_two_digit_rank(first, direction, k2_reject_count)
        assert expected == (1 if direction == 1 else k2_reject_count)
        cases.append(("two", first, direction, k2_reject_count, expected, f"k2_reject_{direction}"))

    for width in WIDTHS:
        space = M ** width
        first = M - width
        expected, actual_width, sample, limit = general_rank(first, 1, space)
        assert actual_width == width and sample <= limit and expected == sample
        cases.append(("general", first, 1, space, expected, f"k{width}_no_rejection"))

        reject_count = (space + 1) // 2
        for direction in (-1, 1):
            first = find_rejecting_start(width, direction, reject_count)
            expected, actual_width, sample, limit = general_rank(first, direction, reject_count)
            assert actual_width == width and sample > limit == reject_count
            assert expected == (1 if direction == 1 else reject_count)
            cases.append(("general", first, direction, reject_count, expected, f"k{width}_reject_{direction}"))

        transition = M ** (width - 1) + 1
        expected, actual_width, sample, limit = general_rank(1, -1, transition)
        assert actual_width == width
        cases.append(("general", 1, -1, transition, expected, f"k{width}_transition_plus_one"))

    for width, count in ((32, M ** 31 + M), (33, M ** 32 + M)):
        actual_width, _ = min_width(count)
        assert actual_width == width
        expected, check_width, _, _ = general_rank(M - 1, 1, count)
        assert check_width == width
        cases.append(("general", M - 1, 1, count, expected, f"k{width}_transition_plus_M"))

    assert len(cases) == 30
    assert sum(1 for c in cases if c[0] == "two") == 4
    assert sum(1 for c in cases if c[0] == "general") == 26
    return cases


HEADER = """load \"src/exact_integer.logo
load \"src/stage02_context.logo
load \"src/stage02_answer_at.logo
load \"src/stage02_choose_wide.logo
load \"src/stage02_choose_wide_general.logo

make \"WIDE.CASES 0
make \"WIDE.CHECKS 0
make \"WIDE.FAILED \"false
print [WIDE_GENERAL_NATIVE_BOOT]

to wide.require :condition :tag
  make \"WIDE.CHECKS (:WIDE.CHECKS + 1)
  if not :condition [
    make \"WIDE.FAILED \"true
    print sentence [WIDE_GENERAL_TESTO_FALIIS:] :tag
  ]
end

to wide.safe.equal :actual :expected
  if not (monster.stage02.bi.canonical :actual) [output \"false]
  output bi.eq :actual :expected
end

to wide.safe.range :actual :N
  if not (monster.stage02.bi.canonical :actual) [output \"false]
  output and (bi.ge :actual (bi.small 1)) (bi.le :actual :N)
end

to wide.good.two :stream :N :expected :tag
  make \"WIDE.CASES (:WIDE.CASES + 1)
  print sentence [WIDE_GENERAL_NATIVE_CASE_START] :tag
  localmake \"actual monster.stage02.choose.wide :stream :N
  wide.require (monster.stage02.bi.canonical :actual) (list :tag [canonical_shape])
  wide.require (wide.safe.equal :actual :expected) (list :tag [legacy_k2_exact])
  wide.require (wide.safe.range :actual :N) (list :tag [rank_range])
  wide.require (equalp :actual (monster.stage02.choose.wide :stream :N)) (list :tag [determinism])
end

to wide.good.general :stream :N :expected :tag
  make \"WIDE.CASES (:WIDE.CASES + 1)
  print sentence [WIDE_GENERAL_NATIVE_CASE_START] :tag
  localmake \"actual monster.stage02.choose.wide.general :stream :N
  wide.require (monster.stage02.bi.canonical :actual) (list :tag [canonical_shape])
  wide.require (wide.safe.equal :actual :expected) (list :tag [python_integer_differential])
  wide.require (wide.safe.range :actual :N) (list :tag [rank_range])
  wide.require (equalp :actual (monster.stage02.choose.wide.general :stream :N)) (list :tag [determinism])
end

to wide.invalid :stream :N :tag
  make \"WIDE.CASES (:WIDE.CASES + 1)
  print sentence [WIDE_GENERAL_NATIVE_CASE_START] :tag
  wide.require (equalp (monster.stage02.choose.wide.general :stream :N) []) :tag
end

"""


BAD = """wide.invalid \"not_a_list (bi.add :WIDE.M (bi.small 1)) [stream_nonlist]
wide.invalid (list (bi.small 1)) (bi.add (bi.square :WIDE.M) (bi.small 1)) [stream_length_one]
wide.invalid (list (bi.small 1) 1 2) (bi.add (bi.square :WIDE.M) (bi.small 1)) [stream_length_three]
wide.invalid (list bi.zero 1) (bi.add (bi.square :WIDE.M) (bi.small 1)) [first_zero]
wide.invalid (list (bi.add :WIDE.M (bi.small 1)) 1) (bi.add (bi.square :WIDE.M) (bi.small 1)) [first_over_M]
wide.invalid (list \"not_bi 1) (bi.add (bi.square :WIDE.M) (bi.small 1)) [first_non_BI]
wide.invalid (list (bi.small 1) 0) (bi.add (bi.square :WIDE.M) (bi.small 1)) [step_zero]
wide.invalid (list (bi.small 1) 2) (bi.add (bi.square :WIDE.M) (bi.small 1)) [step_two]
wide.invalid (list (bi.small 1) 0.5) (bi.add (bi.square :WIDE.M) (bi.small 1)) [step_fraction]
wide.invalid (list (bi.small 1) \"wrong) (bi.add (bi.square :WIDE.M) (bi.small 1)) [step_word]
wide.invalid (list (bi.small 1) 1) \"invalid [N_non_BI]
wide.invalid (list (bi.small 1) 1) bi.zero [N_zero]
wide.invalid (list (bi.small 1) 1) (bi.square :WIDE.M) [N_not_k3]
wide.invalid (list (bi.small 1) 1) (bi.small -1) [N_negative]
wide.invalid (list (list 2 [1]) 1) (bi.add (bi.square :WIDE.M) (bi.small 1)) [first_invalid_sign]
wide.invalid (list (list 1 []) 1) (bi.add (bi.square :WIDE.M) (bi.small 1)) [first_empty_digits]
wide.invalid (list (bi.small 1) 1) (list 1 [10000]) [N_digit_out_of_base]
wide.invalid (list (list 1 [1 0]) 1) (bi.add (bi.square :WIDE.M) (bi.small 1)) [first_trailing_zero]
"""


def main(output: Path, max_width: int | None = None, only_width: int | None = None) -> None:
    all_cases = valid_cases()
    if only_width is not None:
        if max_width is not None or only_width not in WIDTHS:
            raise ValueError("Specify one supported exact width or a maximum width, not both")
        cases = [c for c in all_cases if c[0] == "general" and min_width(c[3])[0] == only_width]
        assert len(cases) == (5 if only_width in (32, 33) else 4)
    else:
        cases = [c for c in all_cases if max_width is None or c[0] == "two" or min_width(c[3])[0] <= max_width]
    lines = [HEADER, f'make "WIDE.M {logo_bi(M)}\n']
    rejected = plus = minus = 0
    for index, (kind, first, direction, count, expected, tag) in enumerate(cases, 1):
        width, _ = min_width(count)
        sample = initial_wide(first, direction, width)
        limit = (M ** width) - ((M ** width) % count)
        if sample > limit:
            rejected += 1
            if direction == 1:
                plus += 1
            else:
                minus += 1
        procedure = "wide.good.two" if kind == "two" else "wide.good.general"
        lines.append(
            f"({procedure}\n"
            f"  (list\n    {logo_bi(first)}\n    {direction}\n  )\n"
            f"  {logo_bi(count)}\n"
            f"  {logo_bi(expected)}\n"
            f"  [v{index:03d}_{tag}]\n"
            f")\n"
        )
    lines.append(BAD)
    total_cases = len(cases) + 18
    total_checks = (4 * len(cases)) + 18
    lines.append(f"""
if :WIDE.FAILED [print [WIDE_GENERAL_NATIVE_FALIIS] stop]
if :WIDE.CASES <> {total_cases} [print [WIDE_GENERAL_NATIVE_CASE_COUNT_FALIIS] stop]
if :WIDE.CHECKS <> {total_checks} [print [WIDE_GENERAL_NATIVE_CHECK_COUNT_FALIIS] stop]
print sentence [WIDE_GENERAL_NATIVE_CASES_PASIS] :WIDE.CASES
print sentence [WIDE_GENERAL_NATIVE_CHECKS_PASIS] :WIDE.CHECKS
print [WIDE_GENERAL_NATIVE_PASIS]
""")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("".join(lines), encoding="utf-8")
    print(f"WIDE_GENERAL_HOST_VALID {len(cases)}")
    print("WIDE_GENERAL_HOST_INVALID 18")
    print(f"WIDE_GENERAL_HOST_REJECTED {rejected}")
    print(f"WIDE_GENERAL_HOST_REJECTED_PLUS {plus}")
    print(f"WIDE_GENERAL_HOST_REJECTED_MINUS {minus}")
    print(f"WIDE_GENERAL_HOST_CASES {total_cases}")
    print(f"WIDE_GENERAL_HOST_CHECKS {total_checks}")
    print("WIDE_GENERAL_HOST_ORACLE=PASS")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--max-width", type=int, default=None)
    parser.add_argument("--only-width", type=int, choices=WIDTHS, default=None)
    args = parser.parse_args()
    main(args.output, args.max_width, args.only_width)
