#!/usr/bin/env python3
"""Independent domain oracle for the Stage 1 Object Pascal BigInt contract.

Calculates expected values using built-in Python integers; intentionally does
not import any implementation code or claim historical patch identity.
"""
import csv
import re
from collections import Counter
from pathlib import Path

INPUTS = Path(__file__).with_name("bigint_input_contract_vectors.tsv")
COUNTS = {"C": 22, "E": 26, "X": 14, "N": 8, "R": 18}
ASSERTIONS = 186
ASCII_DECIMAL = re.compile(r"-?[0-9]+\Z")

def parse(value: str) -> int:
    if not ASCII_DECIMAL.fullmatch(value):
        raise ValueError("decimal syntax invalid")
    return int(value)

def check(kind: str, a: str, b: str, expected: str) -> None:
    if kind == "C":
        assert b == "~" and str(parse(a)) == expected
    elif kind == "E":
        assert b == "~" and expected == "EConvertError"
        try:
            parse("" if a == "@EMPTY@" else a)
        except ValueError:
            return
        raise AssertionError("invalid decimal incorrectly considered valid")
    elif kind == "X":
        assert expected == "EDivByZero" and parse(b) <= 0
        parse(a)
    elif kind == "N":
        assert expected == "ERangeError" and parse(a) < 0 < parse(b)
    elif kind == "R":
        dividend, divisor = parse(a), parse(b)
        assert divisor > 0
        result = dividend % divisor
        assert 0 <= result < divisor and str(result) == expected
    else:
        raise AssertionError("unknown vector class")

def main() -> None:
    with INPUTS.open("r", encoding="utf-8", newline="") as file:
        rows = list(csv.reader(file, delimiter="\t"))
    kinds = Counter()
    for i, parts in enumerate(rows, 1):
        if len(parts) != 4:
            raise AssertionError(f"row {i}: expected four TSV fields")
        kind, a, b, expected = parts
        check(kind, a, b, expected)
        kinds[kind] += 1
    assert kinds == COUNTS, (kinds, COUNTS)
    assertions = 4 * kinds["C"] + kinds["E"] + 2 * kinds["X"] + kinds["N"] + 2 * kinds["R"]
    assert assertions == ASSERTIONS
    print(f"Oracle Python contrato: {len(rows)} casos; {assertions} assercoes previstas; 0 falhas.")

if __name__ == "__main__":
    main()
