#!/usr/bin/env python3
"""Deterministic Stage 15 factorial Native fixture from an integer oracle."""

import math

FINAL = "STAGE15_FACTORIAL_SEVEN_PLUS_TWO_REPLAYS_OK"
CASES = tuple(range(7)) + (0, 6)


def build(mutant=False):
    output = ["{ المرحلة 15: سبع قيم وإعادتان للتأكد. }"]
    cases = []
    for order, n in enumerate(CASES):
        expected = math.prod(range(1, n+1)) + (1 if mutant and order == 0 else 0)
        label = f"STAGE15_FACTORIAL_{order:02d}_OK"
        output.append(f'z;b:{n}a;!b;32h;!!{expected}=~["STAGE15_FACTORIAL_{order:02d}_FAIL"0 0/]?')
        output.append(f'"{label}"10,')
        cases.append({"order": order, "input": n, "expected": math.factorial(n), "label": label})
    output += [f'"{FINAL}"10,', '[z;0>][%z;1-z:]#']
    return "\n".join(output)+"\n", cases


def invalid(kind):
    if kind == "below":
        return 'z;b:1_a;!b;32h;!!\n'
    if kind == "above":
        return 'z;b:7a;!b;32h;!!\n'
    if kind == "missing_argument":
        return '32h;!!\n'
    raise ValueError(kind)


if __name__ == "__main__":
    print(build()[0], end="")
