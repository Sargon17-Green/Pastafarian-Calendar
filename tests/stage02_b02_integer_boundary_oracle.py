#!/usr/bin/env python3
"""B02 exact-integer representation oracle; not a calendar oracle or public ABI.

The 17 signed values exercise the internal base-2^30 representation. The
289 ordered pairs are operand/compare probes only; they are NOT 289 calendar
calculations. The normative Scroll's external day numbers are positive.
"""
import json
import re

PROJECT_ID = "PC-BRANCH-WAT-SPANISH"
BASE = 1 << 30
M = (1 << 127) - 1

MAGNITUDES = (
    ("one", 1),
    ("base_minus_one", BASE - 1),
    ("base", BASE),
    ("two_pow_53", 1 << 53),
    ("two_pow_63_minus_one", (1 << 63) - 1),
    ("two_pow_63", 1 << 63),
    ("M", M),
    ("two_pow_127", 1 << 127),
)

INVALID_DECIMAL_LITERALS = (
    "", "-0", "+1", "01", "-01", " 1", "1 ", "1\n",
    "١", "１", "1.0", "1e0", "\x00", "--1", "−1", "1_000",
)


def decompose(value: int) -> dict:
    if value == 0:
        sign, limbs = 0, []
    else:
        sign = 1 if value > 0 else -1
        magnitude = abs(value)
        limbs = []
        while magnitude:
            limbs.append(magnitude % BASE)
            magnitude //= BASE
    return {
        "sign": sign,
        "length": len(limbs),
        "capacity_candidate": max(1, len(limbs)),
        "limbs_le_base_2_30": limbs,
    }


def reconstruct(sign: int, limbs: list[int]) -> int:
    magnitude = 0
    for limb in reversed(limbs):
        if not 0 <= limb < BASE:
            raise ValueError("limb outside [0,2^30)")
        magnitude = magnitude * BASE + limb
    if sign == 0 and magnitude != 0:
        raise ValueError("zero sign with nonzero magnitude")
    if sign not in (-1, 0, 1):
        raise ValueError("invalid sign")
    return sign * magnitude


def validate_canonical_representation(value: int, rep: dict) -> None:
    sign = rep["sign"]
    limbs = rep["limbs_le_base_2_30"]
    length = rep["length"]
    capacity = rep["capacity_candidate"]
    if length != len(limbs) or capacity < max(1, length):
        raise AssertionError("length/capacity invariant mismatch")
    if value == 0:
        if sign != 0 or length != 0 or limbs:
            raise AssertionError("zero must be sign=0,length=0")
    elif sign != (1 if value > 0 else -1) or length == 0 or limbs[-1] == 0:
        raise AssertionError("nonzero sign or top-limb invariant mismatch")
    if any(not (0 <= limb < BASE) for limb in limbs):
        raise AssertionError("limb out of range")
    if reconstruct(sign, limbs) != value:
        raise AssertionError("exact reconstruction mismatch")


def parse_candidate_ascii_decimal(text: str) -> int:
    # Provisional lexical probe only; the Scroll does not define a wire ABI.
    if re.fullmatch(r"(?:0|-?[1-9][0-9]*)", text, flags=re.ASCII) is None:
        raise ValueError("non-canonical candidate decimal")
    return int(text, 10)


def parse_candidate_day_number(text: str) -> int:
    value = parse_candidate_ascii_decimal(text)
    if value < 1:
        raise ValueError("normative day number must be positive")
    return value


def day_number_from_signed_offset(offset: int) -> int:
    if offset == 0:
        return 1
    return 2 * offset + 1 if offset > 0 else -2 * offset


def build_values() -> list[dict]:
    raw = [("zero", 0)]
    for name, magnitude in MAGNITUDES:
        raw.extend(((name + "_positive", magnitude), (name + "_negative", -magnitude)))
    values = []
    for value_id, value in raw:
        rep = decompose(value)
        validate_canonical_representation(value, rep)
        decimal = str(value)
        if parse_candidate_ascii_decimal(decimal) != value:
            raise AssertionError("candidate decimal round trip mismatch")
        values.append({
            "id": value_id,
            "decimal_candidate": decimal,
            "is_positive_normative_day_number": value >= 1,
            **rep,
        })
    return values


def build_ordered_pairs(values: list[dict]) -> list[list[int]]:
    ints = [int(item["decimal_candidate"]) for item in values]
    return [
        [left_index, right_index,
         (ints[left_index] > ints[right_index]) - (ints[left_index] < ints[right_index])]
        for left_index in range(len(ints))
        for right_index in range(len(ints))
    ]


def main() -> None:
    values = build_values()
    pairs = build_ordered_pairs(values)
    pair_compare = {(row[0], row[1]): row[2] for row in pairs}
    for left_index in range(len(values)):
        for right_index in range(len(values)):
            if pair_compare[(left_index, right_index)] != -pair_compare[(right_index, left_index)]:
                raise AssertionError("ordered comparison antisymmetry mismatch")
            if left_index == right_index and pair_compare[(left_index, right_index)] != 0:
                raise AssertionError("self-comparison must be zero")

    rejected = []
    for literal in INVALID_DECIMAL_LITERALS:
        try:
            parse_candidate_ascii_decimal(literal)
        except ValueError:
            rejected.append(literal)
        else:
            raise AssertionError("invalid candidate literal accepted: " + repr(literal))

    positive_literals = [
        item["decimal_candidate"] for item in values
        if item["is_positive_normative_day_number"]
    ]
    accepted_day_ids = [parse_candidate_day_number(item) for item in positive_literals]
    rejected_day_ids = []
    for literal in ("0", "-1", "-170141183460469231731687303715884105727"):
        try:
            parse_candidate_day_number(literal)
        except ValueError:
            rejected_day_ids.append(literal)
        else:
            raise AssertionError("nonpositive day number accepted: " + repr(literal))

    offsets = list(range(-3, 4))
    mapping = [
        {"signed_offset": offset, "day_number": day_number_from_signed_offset(offset)}
        for offset in offsets
    ]
    if [x["day_number"] for x in mapping] != [6, 4, 2, 1, 3, 5, 7]:
        raise AssertionError("normative day-number mapping mismatch")
    if len({x["day_number"] for x in mapping}) != len(mapping):
        raise AssertionError("day-number mapping is not injective")

    positive_count = sum(1 for item in values if item["is_positive_normative_day_number"])
    positive_pair_count = sum(
        1 for left in values for right in values
        if left["is_positive_normative_day_number"] and right["is_positive_normative_day_number"]
    )
    if len(values) != 17 or len(pairs) != 289:
        raise AssertionError("B02 matrix cardinality mismatch")
    if positive_count != 8 or positive_pair_count != 64:
        raise AssertionError("positive day-number subset mismatch")
    if len(rejected) != len(INVALID_DECIMAL_LITERALS):
        raise AssertionError("candidate lexical rejection mismatch")
    if len(accepted_day_ids) != 8 or len(rejected_day_ids) != 3:
        raise AssertionError("candidate positive day-domain gate mismatch")

    payload = {
        "project_id": PROJECT_ID,
        "contract": "B02_internal_signed_integer_representation_only",
        "base": str(BASE),
        "M": str(M),
        "values": values,
        "pair_columns": ["left_value_index", "right_value_index", "expected_integer_compare"],
        "ordered_operand_pairs": pairs,
        "normative_day_number_domain": {
            "domain": "positive integers >= 1",
            "source_mapping_samples": mapping,
            "candidate_positive_literals_accepted": [str(x) for x in accepted_day_ids],
            "candidate_nonpositive_literals_rejected": rejected_day_ids,
            "note": "The 17-value signed matrix is internal representation coverage; zero and negative values are not external day numbers."
        },
        "candidate_decimal_lexical_probe": {
            "pattern": "^(0|-?[1-9][0-9]*)$",
            "status": "provisional_test_candidate_not_public_ABI",
            "invalid_literals_rejected": rejected,
        },
        "checks": {
            "signed_values": len(values),
            "ordered_operand_pairs": len(pairs),
            "exact_round_trips": len(values),
            "positive_normative_day_number_values": positive_count,
            "positive_day_number_pairs": positive_pair_count,
            "invalid_candidate_literals_rejected": len(rejected),
            "normative_day_number_mapping_samples": len(mapping),
            "nonpositive_day_numbers_rejected": len(rejected_day_ids),
            "calendar_calculations": 0,
            "native_executed": False,
            "differential_executed": False,
            "stage02_accepted": False,
        },
    }
    print(json.dumps(payload, sort_keys=True, separators=(",", ":")))


if __name__ == "__main__":
    main()
