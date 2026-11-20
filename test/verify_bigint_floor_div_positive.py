#!/usr/bin/env python3
"""Independent Python-int oracle for positive BigFloorDivPositive inputs."""

from collections import Counter
from pathlib import Path

BASE = 10**9
COUNTS = {
    "SMALL_UNIT": 16,
    "LESS": 16,
    "RADIX": 16,
    "EXACT": 16,
    "MAX_REM": 16,
    "DENSE": 16,
}
SOURCE = Path(__file__).with_name("bigint_floor_div_positive_vectors.tsv")
PERTURBED_SOURCE = Path(__file__).with_name("bigint_floor_div_positive_divisor_plus_one.tsv")
DECREMENTED_SOURCE = Path(__file__).with_name("bigint_floor_div_positive_divisor_minus_one.tsv")


def limbs_value(digits):
    return sum(digit * (BASE ** index) for index, digit in enumerate(digits))


def make_limbs(count, seed):
    digits = []
    for index in range(count - 1):
        digits.append(
            ((seed + 1) * 104729 + (index + 3) * 7919 + (index * seed * 101))
            % BASE
        )
    digits.append((((seed + 1) * 2654435761) % (BASE - 1)) + 1)
    return digits


def cases():
    for dividend in range(8):
        yield "SMALL_UNIT", dividend, 2

    unit_values = [
        8,
        9,
        10,
        BASE - 1,
        BASE,
        BASE + 1,
        BASE**2 - 1,
        BASE**2,
    ]
    for dividend in unit_values:
        yield "SMALL_UNIT", dividend, 1

    for exponent in (1, 2, 3, 7):
        for offset in (1, 2, 3, 4):
            divisor = BASE**exponent + offset
            yield "LESS", divisor - 1, divisor

    for exponent in (1, 2, 3, 7):
        for delta in (-1, 0, 1, 2):
            dividend = BASE**exponent + delta
            divisor = BASE ** (exponent - 1) + 10 + delta
            yield "RADIX", dividend, divisor

    divisors = [
        2,
        3,
        7,
        10,
        BASE - 1,
        BASE,
        BASE + 1,
        BASE**2 - 1,
        BASE**2,
        BASE**2 + 1,
        BASE**3 + 17,
        BASE**3 + 99,
        BASE**7 - 1,
        BASE**7,
        BASE**7 + 1,
        10**45 + 987654321,
    ]
    quotients = [
        10,
        11,
        97,
        999999,
        1000000000,
        2,
        3,
        5,
        17,
        23,
        101,
        10**6 + 3,
        10**9 + 7,
        10**12 + 39,
        10**20 + 5,
        10**30 + 7,
    ]
    for divisor, quotient in zip(divisors, quotients):
        yield "EXACT", divisor * quotient, divisor

    for index, divisor in enumerate(divisors):
        quotient = 100 + index * 17
        yield "MAX_REM", divisor * quotient + (divisor - 1), divisor

    for index in range(16):
        divisor = limbs_value(make_limbs(2 + (index % 4), index + 11))
        quotient = limbs_value(make_limbs(4 + (index // 4) * 12, index + 101))
        remainder = (0, 1, divisor - 1, divisor // 2)[index % 4]
        dividend = divisor * quotient + remainder
        yield "DENSE", dividend, divisor


def main():
    case_list = list(cases())
    counts = Counter(category for category, _, _ in case_list)
    if len(case_list) != 96 or counts != Counter(COUNTS):
        raise AssertionError(f"wrong case count or distribution: {counts}")

    seen = set()
    rows = []
    perturbed_seen = set()
    perturbed_rows = []
    decremented_seen = set()
    decremented_rows = []
    max_a_digits = 0
    max_b_digits = 0
    max_q_digits = 0
    for category, dividend, divisor in case_list:
        if dividend < 0 or divisor <= 0:
            raise AssertionError("oracle inputs must be nonnegative / positive")
        pair = (dividend, divisor)
        if pair in seen:
            raise AssertionError("duplicate dividend/divisor pair")
        seen.add(pair)

        quotient, remainder = divmod(dividend, divisor)
        if dividend != quotient * divisor + remainder:
            raise AssertionError("division identity failed")
        if not (0 <= remainder < divisor):
            raise AssertionError("Euclidean remainder bounds failed")

        a_text = str(dividend)
        b_text = str(divisor)
        q_text = str(quotient)
        r_text = str(remainder)
        max_a_digits = max(max_a_digits, len(a_text))
        max_b_digits = max(max_b_digits, len(b_text))
        max_q_digits = max(max_q_digits, len(q_text))
        if max(len(a_text), len(b_text), len(q_text), len(r_text)) > 512:
            raise AssertionError("vector exceeds the 512-digit bound")

        rows.append("\t".join((category, a_text, b_text, q_text, r_text)))

        # Independent integer division: never derive Q' or R' from the baseline oracle.
        perturbed_divisor = divisor + 1
        perturbed_pair = (dividend, perturbed_divisor)
        if perturbed_pair in perturbed_seen:
            raise AssertionError("duplicate divisor+1 input pair")
        perturbed_seen.add(perturbed_pair)
        perturbed_q, perturbed_r = divmod(dividend, perturbed_divisor)
        if dividend != perturbed_q * perturbed_divisor + perturbed_r:
            raise AssertionError("divisor+1 identity failed")
        if not (0 <= perturbed_r < perturbed_divisor):
            raise AssertionError("divisor+1 remainder bounds failed")
        perturbed_fields = tuple(
            str(number) for number in
            (dividend, perturbed_divisor, perturbed_q, perturbed_r)
        )
        if max(map(len, perturbed_fields)) > 512:
            raise AssertionError("divisor+1 vector exceeds 512 decimal digits")
        perturbed_rows.append("\t".join((category, *perturbed_fields)))

        # Python-int oracle using divmod(A,B-1), not a baseline-Q adjustment.
        # The eight B=1 rows are excluded rather than dividing by zero.
        if divisor > 1:
            decremented_divisor = divisor - 1
            decremented_pair = (dividend, decremented_divisor)
            if decremented_pair in decremented_seen:
                raise AssertionError("duplicate divisor-1 input")
            decremented_seen.add(decremented_pair)
            decremented_q, decremented_r = divmod(dividend, decremented_divisor)
            if dividend != decremented_q * decremented_divisor + decremented_r:
                raise AssertionError("divisor-1 identity failed")
            if not (0 <= decremented_r < decremented_divisor):
                raise AssertionError("divisor-1 remainder bounds failed")
            decremented_fields = tuple(
                str(number) for number in
                (dividend, decremented_divisor, decremented_q, decremented_r)
            )
            if max(map(len, decremented_fields)) > 512:
                raise AssertionError("divisor-1 vector exceeds 512 digits")
            decremented_rows.append("\t".join((category, *decremented_fields)))

    if len(seen) != 96:
        raise AssertionError("not all input pairs are unique")
    if len(perturbed_seen) != 96 or len(perturbed_rows) != 96:
        raise AssertionError("not all divisor+1 input pairs are unique")
    if len(decremented_seen) != 88 or len(decremented_rows) != 88:
        raise AssertionError("expected 88 unique divisor-1 cases")
    SOURCE.write_text("\n".join(rows) + "\n", encoding="ascii")
    PERTURBED_SOURCE.write_text(
        "\n".join(perturbed_rows) + "\n", encoding="ascii"
    )
    DECREMENTED_SOURCE.write_text(
        "\n".join(decremented_rows) + "\n", encoding="ascii"
    )
    print(
        "Python-int BigFloorDivPositive oracle: 96/96 unique, "
        f"categories={dict(counts)}, max A={max_a_digits} digits, "
        f"max B={max_b_digits} digits, max Q={max_q_digits} digits, "
        "0 divergences; divisor+1 Python-int oracle: 96/96 unique generated; "
        "divisor-1 Python-int oracle: 88/88 unique generated"
    )


if __name__ == "__main__":
    main()
