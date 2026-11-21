#!/usr/bin/env python3
"""Independent finite-domain oracle for Logo+Ido Appendix-A wide selection.

QA-only mathematical model. It does not import or call the Logo normative
reference, the two-digit host oracle, or any production implementation.
The finite oracle walks both the base-M digit stream and the rejected wide
candidate interval one step at a time. The closed-form target is implemented
separately and is used only as the comparison target.
"""

M = (1 << 127) - 1
K2_COMPAT_MODULI = (3, 4, 5, 7, 11)
FINITE_MODULI = {
    3: (2, 3, 4, 6, 9),
    4: (2, 3, 4, 6),
    5: (2, 3, 4),
    6: (2, 3),
}


def advance(value: int, direction: int, modulus: int) -> int:
    """One explicit cyclic step; deliberately no modulo expression."""
    if direction == 1:
        return 1 if value == modulus else value + 1
    if direction == -1:
        return modulus if value == 1 else value - 1
    raise AssertionError((direction, modulus))


def enumerated_initial(first: int, direction: int, modulus: int, width: int) -> int:
    """Generate digits by stepping, then assemble with high-to-low Horner."""
    digits = []
    digit = first
    for _ in range(width):
        digits.append(digit)
        digit = advance(digit, direction, modulus)
    value = 0
    for digit in reversed(digits):
        value = value * modulus + digit - 1
    return value + 1


def enumerated_choice(first: int, direction: int, count: int, modulus: int, width: int):
    """Exhaustively walk the candidate circle until its first accepted point."""
    space = modulus ** width
    limit = (space // count) * count
    candidate = enumerated_initial(first, direction, modulus, width)
    walked = 0
    while candidate > limit:
        candidate = advance(candidate, direction, space)
        walked += 1
        if walked > space:
            raise AssertionError("No accepted candidate in one complete cycle")
    rank = 1 + ((candidate - 1) % count)
    return rank, walked, candidate


def minimum_width(count: int, modulus: int):
    """Find the least positive k with modulus**k >= count."""
    width = 1
    space = modulus
    while space < count:
        space *= modulus
        width += 1
    return width, space


def formula_initial(first: int, direction: int, modulus: int, width: int) -> int:
    """Closed-form digit construction, independent of the enumerative walker."""
    value = 1
    place = 1
    for index in range(width):
        digit = 1 + ((first - 1 + direction * index) % modulus)
        value += (digit - 1) * place
        place *= modulus
    return value


def formula_choice(first: int, direction: int, count: int, modulus: int):
    """Constant-gap mathematical target for any finite width k."""
    width, space = minimum_width(count, modulus)
    initial = formula_initial(first, direction, modulus, width)
    limit = space - (space % count)
    if initial <= limit:
        return 1 + ((initial - 1) % count), width, initial, limit
    return (1 if direction == 1 else count), width, initial, limit


def legacy_two_digit_target(first: int, direction: int, count: int, modulus: int) -> int:
    """Algebraic form of the already accepted k=2 reporter contract."""
    second = advance(first, direction, modulus)
    wide = first + modulus * (second - 1)
    space = modulus * modulus
    limit = space - (space % count)
    if wide <= limit:
        return 1 + ((wide - 1) % count)
    return 1 if direction == 1 else count


def guarded_formula(stream, count):
    """Python model of the k>=3 input boundary; not a Logo guard test."""
    if type(stream) is not list or len(stream) != 2:
        return []
    first, direction = stream
    if type(first) is not int or not (1 <= first <= M):
        return []
    if type(direction) is not int or direction not in (-1, 1):
        return []
    if type(count) is not int or count <= M * M:
        return []
    return formula_choice(first, direction, count, M)[0]


def finite_exhaustive() -> tuple[int, int, int, int, int, dict]:
    total = rejected = plus_rejected = minus_rejected = max_walk = 0
    per_width = {}

    bands = [(2, K2_COMPAT_MODULI)] + sorted(FINITE_MODULI.items())
    for width, moduli in bands:
        band_cases = 0
        for modulus in moduli:
            lower = modulus ** (width - 1) + 1
            upper = modulus ** width
            for count in range(lower, upper + 1):
                observed_width, observed_space = minimum_width(count, modulus)
                assert (observed_width, observed_space) == (width, upper)
                for first in range(1, modulus + 1):
                    for direction in (-1, 1):
                        got, walked, accepted = enumerated_choice(
                            first, direction, count, modulus, width
                        )
                        want, fast_width, initial, limit = formula_choice(
                            first, direction, count, modulus
                        )
                        assert fast_width == width
                        assert got == want, (
                            modulus, width, count, first, direction,
                            got, want, walked, initial, limit, accepted
                        )
                        assert 1 <= got <= count
                        if width == 2:
                            assert got == legacy_two_digit_target(
                                first, direction, count, modulus
                            ), (modulus, count, first, direction, got)
                        total += 1
                        band_cases += 1
                        if walked:
                            rejected += 1
                            if direction == 1:
                                plus_rejected += 1
                            else:
                                minus_rejected += 1
                        max_walk = max(max_walk, walked)
        per_width[width] = band_cases

    return total, rejected, plus_rejected, minus_rejected, max_walk, per_width


def large_modulus_vectors() -> tuple[int, int]:
    """Boundary and rejection vectors, including widths beyond D20's 31 cap."""
    # Full-M compatibility probes for the already accepted two-digit contract.
    k2_vectors = 0
    for first, direction, count in (
        (1, 1, M + 1),
        (M, -1, M * M),
    ):
        got, width, initial, limit = formula_choice(first, direction, count, M)
        assert width == 2 and 1 <= got <= count
        assert got == legacy_two_digit_target(first, direction, count, M)
        k2_vectors += 1

    k2_count = (M * M + 1) // 2
    for direction in (-1, 1):
        midpoint = (M // 2) + 1
        found = None
        for offset in range(0, 256):
            first = midpoint + offset
            initial = formula_initial(first, direction, M, 2)
            if initial > k2_count:
                found = first
                break
        assert found is not None
        got, width, initial, limit = formula_choice(found, direction, k2_count, M)
        assert width == 2 and limit == k2_count and initial > limit
        assert got == (1 if direction == 1 else k2_count)
        assert got == legacy_two_digit_target(found, direction, k2_count, M)
        k2_vectors += 1

    vectors = k2_vectors
    widths = (3, 4, 5, 32, 33, 64)

    for width in widths:
        space = M ** width

        # Exact upper boundary: no rejection is possible and rank equals W.
        first = M - width
        rank, actual_width, initial, limit = formula_choice(first, 1, space, M)
        assert actual_width == width and limit == space and initial <= limit
        assert rank == initial
        vectors += 1

        # Both rejection directions: N=ceil(S/2), hence floor(S/N)=1 and L=N.
        count = (space + 1) // 2
        for direction in (-1, 1):
            midpoint = (M // 2) + 1
            found = None
            for offset in range(0, 4 * width + 64):
                first = midpoint + offset
                if first > M:
                    break
                initial = formula_initial(first, direction, M, width)
                if initial > count:
                    found = first
                    break
            assert found is not None, (width, direction)
            rank, actual_width, initial, limit = formula_choice(found, direction, count, M)
            assert actual_width == width and limit == count and initial > limit
            assert rank == (1 if direction == 1 else count)
            vectors += 1

        # Minimal-width transition: M**(k-1)+1 must require exactly k digits.
        transition = (M ** (width - 1)) + 1
        actual_width, actual_space = minimum_width(transition, M)
        assert actual_width == width and actual_space == space
        rank, check_width, initial, limit = formula_choice(1, -1, transition, M)
        assert check_width == width and 1 <= rank <= transition
        vectors += 1

    # Explicitly pin the transition at the former 31-digit API boundary.
    for count, expected_width in ((M ** 31 + 1, 32), (M ** 32 + 1, 33)):
        width, _ = minimum_width(count, M)
        assert width == expected_width
        vectors += 1

    return vectors, k2_vectors


def invalid_guard_vectors() -> int:
    invalid = (
        (None, M * M + 1),
        ((), M * M + 1),
        ([1], M * M + 1),
        ([1, 1, 1], M * M + 1),
        ([0, 1], M * M + 1),
        ([M + 1, 1], M * M + 1),
        ([1, 0], M * M + 1),
        ([1, 2], M * M + 1),
        ([1, 1.5], M * M + 1),
        ([1, True], M * M + 1),
        ([1, 1], 0),
        ([1, 1], M * M),
        ([1, 1], M * M - 1),
        ([1, 1], 1.5),
    )
    for stream, count in invalid:
        assert guarded_formula(stream, count) == [], (stream, count)
    return len(invalid)


def verify() -> None:
    total, rejected, plus_rejected, minus_rejected, max_walk, per_width = finite_exhaustive()
    large_vectors, k2_large_vectors = large_modulus_vectors()
    invalid_vectors = invalid_guard_vectors()

    assert per_width[2] == 3340
    assert total == sum(per_width.values())
    assert rejected > 0 and plus_rejected > 0 and minus_rejected > 0
    assert large_vectors == 30
    assert k2_large_vectors == 4
    assert invalid_vectors == 14

    print(f"WIDE_GENERAL_ENUM_CASES {total}")
    for width in sorted(per_width):
        print(f"WIDE_GENERAL_K{width}_CASES {per_width[width]}")
    print(f"WIDE_GENERAL_K2_COMPAT_CASES {per_width[2]}")
    print(f"WIDE_GENERAL_REJECTION_CASES {rejected}")
    print(f"WIDE_GENERAL_POSITIVE_REJECTIONS {plus_rejected}")
    print(f"WIDE_GENERAL_NEGATIVE_REJECTIONS {minus_rejected}")
    print(f"WIDE_GENERAL_MAX_ENUMERATED_STEPS {max_walk}")
    print(f"WIDE_GENERAL_LARGE_M_VECTORS {large_vectors}")
    print(f"WIDE_GENERAL_K2_LARGE_M_COMPAT {k2_large_vectors}")
    print(f"WIDE_GENERAL_INVALID_GUARDS {invalid_vectors}")
    print("WIDE_GENERAL_HOST_ORACLE=PASS")
    print("WIDE_GENERAL_NATIVE=NOT_RUN")


if __name__ == "__main__":
    verify()
