#!/usr/bin/env python3
"""QA-only immutable-source phase tracer for slow Logo Stage2 wide cases.

This diagnostic is NOT an acceptance oracle. It imports the current QA-only
Python-vector builder to select the exact previously timed-out case, and
instruments a temporary copy of the current Logo candidate with print-only
phase probes. The locked original source is never modified.
"""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path

from logo_stage2_wide_general_native_vectors import valid_cases, logo_bi

CASES = {
    32: "k32_reject_1",       # prior Native run timed out on its third vector
    33: "k33_reject_-1",      # prior Native run timed out on its second vector
    64: "k64_no_rejection",   # prior Native run timed out on its first vector
}

# Each probe is a pure Logo print statement inserted next to one exact,
# source-locked statement; no source expression or branch is replaced.
PROBES = (
    (
        'to monster.stage02.choose.wide.general.prepare :firstv :step :N :m :space :width\n',
        '  print sentence [WIDE_PERF_PREPARE_WIDTH] :width\n',
    ),
    (
        'to monster.stage02.choose.wide.general.build :step :N :m :space :width :digit :index :wide :weight\n',
        '  print sentence [WIDE_PERF_BUILD_INDEX] :index\n',
    ),
    (
        '  if :index >= :width [\n',
        '    print [WIDE_PERF_DIVISION_BEGIN]\n',
    ),
    (
        '    localmake "remainder bi.regmod :space :N\n',
        '    print [WIDE_PERF_DIVISION_END]\n',
    ),
    (
        '  localmake "digitOffset bi.sub :digit (bi.small 1)\n',
        '  print sentence [WIDE_PERF_TERM_BEGIN] :index\n',
    ),
    (
        '  localmake "term bi.mul :digitOffset :weight\n',
        '  print sentence [WIDE_PERF_TERM_END] :index\n',
    ),
    (
        '  localmake "nextWide bi.add :wide :term\n',
        '  print sentence [WIDE_PERF_WEIGHT_BEGIN] :index\n',
    ),
    (
        '  localmake "nextWeight bi.mul :weight :m\n',
        '  print sentence [WIDE_PERF_WEIGHT_END] :index\n',
    ),
)


def make_probe(source: Path, traced: Path, fixture: Path, width: int) -> None:
    if width not in CASES:
        raise ValueError(f"Unsupported diagnostic width: {width}")
    original = source.read_text(encoding="utf-8")
    modified = original
    injected = []
    for anchor, statement in PROBES:
        if modified.count(anchor) != 1:
            raise AssertionError(f"Expected one occurrence of {anchor!r}")
        modified = modified.replace(anchor, anchor + statement, 1)
        injected.append(statement)

    recovered = modified
    for statement in injected:
        if recovered.count(statement) != 1:
            raise AssertionError("Probe not uniquely reversible")
        recovered = recovered.replace(statement, "", 1)
    if recovered != original:
        raise AssertionError("Instrumented source changed non-probe logic")

    matches = [c for c in valid_cases() if c[5] == CASES[width]]
    if len(matches) != 1:
        raise AssertionError(f"Missing target case {CASES[width]}")
    kind, first, step, n, expected, tag = matches[0]
    if kind != "general":
        raise AssertionError("Selected a non-general-width case")

    traced.parent.mkdir(parents=True, exist_ok=True)
    fixture.parent.mkdir(parents=True, exist_ok=True)
    traced.write_text(modified, encoding="utf-8")
    # The completed probe checks exactly one independent Python-integer
    # fixture, but deliberately does NOT claim the full Native QA shard passed.
    fixture.write_text(
        'load "src/exact_integer.logo\n'
        'load "src/stage02_context.logo\n'
        'load "src/stage02_answer_at.logo\n'
        'load "src/stage02_choose_wide.logo\n'
        f'load "{traced.resolve().as_posix()}\n'
        'to wide.perf.probe\n'
        f'  print [WIDE_PERF_CASE_START_{tag}]\n'
        '  localmake "actual (monster.stage02.choose.wide.general\n'
        f'    (list {logo_bi(first)} {step})\n'
        f'    {logo_bi(n)}\n'
        '  )\n'
        '  print [WIDE_PERF_NATIVE_CALL_RETURNED]\n'
        '  if not (monster.stage02.bi.canonical :actual) [print [WIDE_PERF_BAD_SHAPE] stop]\n'
        f'  if not (bi.eq :actual {logo_bi(expected)}) [print [WIDE_PERF_WRONG_RANK] stop]\n'
        '  print [WIDE_PERF_DIAGNOSTIC_CASE_MATCHES_PYTHON]\n'
        'end\n'
        'wide.perf.probe\n',
        encoding="utf-8",
    )
    print(f"WIDE_PERF_WIDTH={width}")
    print(f"WIDE_PERF_CASE={tag}")
    print("WIDE_PERF_IS_FULL_SHARD_PASS=NO")
    for name, path in (("LOCKED_SOURCE", source), ("TRACED_SOURCE", traced), ("GENERATED_FIXTURE", fixture)):
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        print(f"WIDE_PERF_{name}_SHA256={digest}")
    print("WIDE_PERF_INSTRUMENTATION_RECOVERY=PASS")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--width", type=int, choices=CASES, required=True)
    parser.add_argument("--source", type=Path, default=Path("src/stage02_choose_wide_general.logo"))
    parser.add_argument("--traced-source", type=Path, required=True)
    parser.add_argument("--fixture", type=Path, required=True)
    args = parser.parse_args()
    make_probe(args.source, args.traced_source, args.fixture, args.width)


if __name__ == "__main__":
    main()
