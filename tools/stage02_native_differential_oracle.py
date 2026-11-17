#!/usr/bin/env python3
"""Independent Stage 2 boundary oracle and deterministic FALSE fixture builder.

This program checks fixture provenance and mathematical expectations. It does
not claim a native FALSE result; the pinned CI workflow executes the fixture.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

M = (1 << 127) - 1
ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "test" / "stage02_differential_13.false"

# Each expression is built by the Stage 1 BigInt operations in the fixture.
# The numeric values below are evaluated independently by Python.
ANCHORS = (
    ("ZERO", 0, "u"),
    ("ONE", 1, "t"),
    ("M_MINUS_ONE", M - 1, "p"),
    ("M", M, "s"),
    ("M_PLUS_ONE", M + 1, "w"),
    ("TWO_M", 2 * M, "x"),
    ("TWO_M_PLUS_ONE", 2 * M + 1, "v"),
    ("THREE_M", 3 * M, "y"),
    ("THREE_M_MINUS_ONE", 3 * M - 1, "q"),
    ("NEG_ONE", -1, "j"),
    ("NEG_M", -M, "l"),
    ("NEG_TWO_M", -2 * M, "m"),
    ("NEG_M_MINUS_ONE", -M - 1, "r"),
)

HEADER = """{ تفريق مستقل للمرحلة الثانية: 13 مدخلا، عمليتان لكل مدخل. }
{ الفشل ينهي المفسر بغير الصفر؛ علامة الحالة تأتي بعد المقارنتين. }
[~["DIFF13_FAILURE"10,0 0/]?]f:
[e:d:z;b:e;a;!d;a;!b;28o;!0=f;!]i:
z;b:0a;!b;21o;!c:
0 22o;!s: { M }
1 22o;!t: { 1 }
2 22o;!u: { 0 }
z;b:s;a;!s;a;!b;25o;!x: { 2M }
z;b:x;a;!s;a;!b;25o;!y: { 3M }
z;b:s;a;!t;a;!b;25o;!w: { M+1 }
z;b:s;a;!t;a;!b;26o;!p: { M-1 }
z;b:x;a;!t;a;!b;25o;!v: { 2M+1 }
z;b:y;a;!t;a;!b;26o;!q: { 3M-1 }
z;b:u;a;!t;a;!b;26o;!j: { -1 }
z;b:u;a;!s;a;!b;26o;!l: { -M }
z;b:u;a;!x;a;!b;26o;!m: { -2M }
z;b:l;a;!t;a;!b;26o;!r: { -M-1 }
"""


def oracle(x: int) -> tuple[int, int]:
    quotient, remainder = divmod(x, M)
    assert quotient * M + remainder == x and 0 <= remainder < M
    return remainder, M if x != 0 and remainder == 0 else remainder


def build_fixture() -> tuple[str, list[dict[str, object]]]:
    expected_handles = {0: "u", 1: "t", M - 1: "p", M: "s"}
    assert len(ANCHORS) == len({x for _, x, _ in ANCHORS}) == 13
    lines = [HEADER.rstrip()]
    manifest: list[dict[str, object]] = []
    for index, (name, x, input_handle) in enumerate(ANCHORS):
        regular, saved = oracle(x)
        assert regular in expected_handles and saved in expected_handles
        label = f"DIFF13_CASE_{index:02d}_OK"
        lines.extend(
            (
                f'{{ {name}: regularMod and SAVE. }}',
                f"z;b:{input_handle};a;!s;a;!b;30o;!n:n;{expected_handles[regular]};i;!",
                f"z;b:{input_handle};a;!b;36o;!n:n;{expected_handles[saved]};i;!",
                f'"{label}"10,',
            )
        )
        manifest.append(
            {
                "index": index,
                "label": label,
                "name": name,
                "input": str(x),
                "regular": str(regular),
                "save": str(saved),
                "input_handle": input_handle,
                "regular_handle": expected_handles[regular],
                "save_handle": expected_handles[saved],
            }
        )
    lines.extend(
        (
            '"DIFF13_26_CHECKS_VERIFIED"10,',
            "{ تحرير الكومة بعد اجتياز كل المقارنات. }",
            "[z;0>][%z;1-z:]#",
        )
    )
    program = "\n".join(lines) + "\n"
    assert program.count("30o;!") == program.count("36o;!") == 13
    assert program.count("_OK") == 13 and "P_{" not in program
    return program, manifest


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="generate the committed fixture")
    args = parser.parse_args()
    source, cases = build_fixture()
    if args.write:
        FIXTURE.write_text(source, encoding="utf-8")
    assert FIXTURE.read_text(encoding="utf-8") == source, "fixture differs from independent generator"
    print(
        json.dumps(
            {
                "project_id": "PC-BRANCH-FALSE-ARABIC",
                "stage": "2_NATIVE_ORACLE_DIFFERENTIAL",
                "native_evidence": False,
                "fixture_sha256": hashlib.sha256(source.encode("utf-8")).hexdigest(),
                "case_count": len(cases),
                "assertion_count": 2 * len(cases),
                "distinct_save_cases": sum(int(c["regular"] != c["save"]) for c in cases),
                "cases": cases,
            },
            ensure_ascii=False,
            sort_keys=True,
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
