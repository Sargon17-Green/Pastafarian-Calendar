#!/usr/bin/env python3
"""Independent component oracle transcribed from the Hebrew Scroll, chapter 14.

This deliberately does not import or copy tests/normative_reference.py.
The Scroll distinguishes the saved value used to choose the bowl order from
the unsaved sum of the six bowls used in each bowl-update formula.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import subprocess
from pathlib import Path

PROJECT_ID = "PC-BRANCH-FORTRAN-ENGLISH"
SCROLL_SNAPSHOT = "Megilat_HaItim_Yehuda_FINAL_2026-09-18.md"
SCROLL_SNAPSHOT_SHA256 = "7b834f4a444e021bb65164282b851af960a6dbc0be3d458c2412181773b9db7b"
SCROLL_CHAPTER = "לוח ארבעה עשר: לבלול שתים עשרה פעמים אחר הטיפה האחרונה"
SCROLL_LINES = "831-885"
M = 2**127 - 1

VECTORS = (
    (1, 2, 3, 4, 5, 6),
    (17, 29, 43, 71, 101, 127),
    (1000003, 2000003, 3000017, 4000037, 5000011, 6000011),
    (1, 1, 1, 1, 1, 1),
    (999999937, 999999929, 999999893, 999999883, 999999797, 999999761),
)


def save_value(value: int) -> int:
    """The Scroll's SAVE operation: the unique representative in 1..M."""
    return 1 + ((value - 1) % M)


def bowl_order_from_number(order_number: int) -> tuple[int, ...]:
    """Select the one-based lexicographic permutation of the six bowl IDs."""
    if not 1 <= order_number <= math.factorial(6):
        raise ValueError("bowl order rank must be in 1..720")
    rank = order_number - 1
    remaining = [1, 2, 3, 4, 5, 6]
    order = []
    for slots_left in range(6, 0, -1):
        block_size = math.factorial(slots_left - 1)
        digit, rank = divmod(rank, block_size)
        order.append(remaining.pop(digit))
    if rank != 0 or remaining:
        raise AssertionError("permutation unranking left an unused state")
    return tuple(order)


def scroll_post_stir12(
    initial_bowls: tuple[int, ...] | list[int],
    *,
    use_saved_sum_in_update: bool = False,
) -> tuple[int, ...]:
    """Execute the Scroll's twelve simultaneous bowl updates.

    The saved sum chooses the permutation. The raw sum is added to each
    bowl's subtotal. Every bowl in a turn reads only the six values from the
    beginning of that turn; the six new values are installed together.
    """
    if len(initial_bowls) != 6 or any(not 1 <= int(x) <= M for x in initial_bowls):
        raise ValueError("exactly six bowl values in 1..M are required")

    bowls = [int(x) for x in initial_bowls]
    for turn_number in range(1, 13):
        raw_six_bowl_sum = sum(bowls)
        saved_order_value = save_value(raw_six_bowl_sum + 149 * turn_number)
        order_number = ((saved_order_value - 1) % 720) + 1
        order = bowl_order_from_number(order_number)
        next_bowls = [0] * 6

        for position, bowl_id in enumerate(order, start=1):
            previous_id = order[(position - 2) % 6]
            following_id = order[position % 6]
            update_sum = (
                saved_order_value if use_saved_sum_in_update else raw_six_bowl_sum
            )
            subtotal = (
                bowls[bowl_id - 1]
                + 3 * bowls[previous_id - 1]
                + 5 * bowls[following_id - 1]
                + update_sum
                + turn_number
                + position * position
            )
            next_bowls[bowl_id - 1] = save_value(
                subtotal * subtotal
                + 7 * bowls[previous_id - 1] * bowls[following_id - 1]
            )

        if any(not 1 <= value <= M for value in next_bowls):
            raise AssertionError("SAVE produced a bowl outside 1..M")
        bowls = next_bowls

    return tuple(bowls)


def self_test() -> None:
    checks = [
        save_value(1) == 1,
        save_value(M) == M,
        save_value(M + 1) == 1,
        save_value(0) == M,
        bowl_order_from_number(1) == (1, 2, 3, 4, 5, 6),
        bowl_order_from_number(720) == (6, 5, 4, 3, 2, 1),
    ]
    permutations = [bowl_order_from_number(rank) for rank in range(1, 721)]
    checks.append(len(set(permutations)) == 720)
    for vector in VECTORS:
        result = scroll_post_stir12(vector)
        checks.append(len(result) == 6 and all(1 <= value <= M for value in result))
    for vector in VECTORS:
        correct = scroll_post_stir12(vector)
        stale_mutant = scroll_post_stir12(vector, use_saved_sum_in_update=True)
        checks.append(correct != stale_mutant)

    passed = sum(bool(check) for check in checks)
    if passed != 17:
        raise SystemExit("Scroll reference self-test failed: {}/17".format(passed))
    print("STAGE01_SCROLL_STIR_SELFTEST=17/17")


def parse_fortran_output(stdout: str) -> tuple[int, ...]:
    values: dict[int, int] = {}
    prefix = "STAGE01_SCROLL_STIR_BOWL="
    for line in stdout.splitlines():
        if not line.startswith(prefix):
            if line.strip():
                raise AssertionError("unexpected Fortran output: " + line)
            continue
        payload = line[len(prefix):]
        bowl_text, value_text = payload.split(",", 1)
        bowl_id = int(bowl_text)
        if bowl_id in values:
            raise AssertionError("duplicate Fortran bowl ID {}".format(bowl_id))
        values[bowl_id] = int(value_text)
    if sorted(values) != [1, 2, 3, 4, 5, 6]:
        raise AssertionError("Fortran probe did not return exactly six bowls")
    return tuple(values[i] for i in range(1, 7))


def compare_fortran(fortran_exe: Path, output_path: Path) -> None:
    cases = []
    matched_bowls = 0
    for case_number, vector in enumerate(VECTORS, start=1):
        expected = scroll_post_stir12(vector)
        completed = subprocess.run(
            [str(fortran_exe), *(str(value) for value in vector)],
            check=True,
            capture_output=True,
            text=True,
            timeout=30,
        )
        actual = parse_fortran_output(completed.stdout)
        matched = sum(left == right for left, right in zip(expected, actual))
        matched_bowls += matched
        case = {
            "case": case_number,
            "initial_bowls": [str(value) for value in vector],
            "expected_bowls": [str(value) for value in expected],
            "fortran_bowls": [str(value) for value in actual],
            "matched_bowls": matched,
            "total_bowls": 6,
            "pass": matched == 6,
        }
        cases.append(case)
        print(
            "STAGE01_SCROLL_STIR_CASE={} MATCHED_BOWLS={}/6".format(
                case_number, matched
            )
        )
        if matched != 6:
            raise SystemExit("Fortran/Scroll mismatch in case {}".format(case_number))

    report = {
        "project_id": PROJECT_ID,
        "canonical_source_snapshot": SCROLL_SNAPSHOT,
        "canonical_source_snapshot_sha256": SCROLL_SNAPSHOT_SHA256,
        "chapter": SCROLL_CHAPTER,
        "chapter_lines": SCROLL_LINES,
        "stir_turns": 12,
        "case_count": len(cases),
        "matched_bowls": matched_bowls,
        "total_bowls": len(cases) * 6,
        "cases": cases,
        "component_only": True,
        "full_stage1_accepted": False,
    }
    output_path.parent.mkdir(parents=True, exist_ok=True)
    encoded = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    output_path.write_text(encoded, encoding="utf-8")
    report_sha = hashlib.sha256(encoded.encode("utf-8")).hexdigest()
    print(
        "STAGE01_SCROLL_STIR_DIFFERENTIAL={}/{} CASES; {}/{} EXACT BOWLS".format(
            len(cases), len(cases), matched_bowls, len(cases) * 6
        )
    )
    print("STAGE01_SCROLL_STIR_REPORT_SHA256=" + report_sha)
    print("STAGE01_SCROLL_STIR_COMPONENT_ONLY_NOT_FULL_STAGE1_ACCEPTANCE")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--fortran-exe", type=Path)
    parser.add_argument(
        "--output", type=Path, default=Path("build/stage01-scroll-stir.json")
    )
    args = parser.parse_args()

    if args.self_test:
        self_test()
    if args.fortran_exe is not None:
        compare_fortran(args.fortran_exe.resolve(), args.output)
    if not args.self_test and args.fortran_exe is None:
        parser.error("provide --self-test and/or --fortran-exe")


if __name__ == "__main__":
    main()
