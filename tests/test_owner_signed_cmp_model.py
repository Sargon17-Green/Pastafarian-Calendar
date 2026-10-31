#!/usr/bin/env python3
"""Independent Python integer oracle for owner-scoped signed magnitudes.

This is a HOST reference contract, not execution of SM83 machine code.
The ROM exercise covers cases 191..243.
"""
from random import Random
from test_sram_owner_model import OwnedBanks, SIZE


def reference_integer(model, owner, sign, length):
    if sign not in (0, 1) or not 1 <= owner <= 253:
        raise ValueError("metadata")
    banks = [i for i in range(3, 16) if model.tags[i] == owner + 2]
    if not banks or length < 0 or length > len(banks) * SIZE:
        raise ValueError("capacity")
    if length == 0:
        if sign:
            raise ValueError("negative zero")
        return 0
    raw = b"".join(model.data[b] for b in banks)[:length]
    if raw[-1] == 0:
        raise ValueError("noncanonical leading zero")
    value = int.from_bytes(raw, "little")
    return -value if sign else value


def compare(model, a, b):
    try:
        va = reference_integer(model, *a)
        vb = reference_integer(model, *b)
    except ValueError:
        return 3
    return 1 if va > vb else 2 if va < vb else 0



def compare_read_only(model, a, b):
    """Check the independent host comparator preserves owners and all SRAM."""
    tag_snapshot = tuple(model.tags)
    bank_snapshot = tuple(bytes(bank) for bank in model.data)
    a_snapshot, b_snapshot = tuple(a), tuple(b)
    result = compare(model, a, b)
    assert tuple(model.tags) == tag_snapshot, "comparison changed lease tags"
    assert all(bytes(bank) == before for bank, before in zip(model.data, bank_snapshot)), (
        "comparison mutated SRAM payload")
    assert tuple(a) == a_snapshot and tuple(b) == b_snapshot, "metadata mutated"
    return result


def main():
    m = OwnedBanks()
    assert m.alloc(41, 3) == (0, (3, 4, 5))
    assert m.alloc(42, 1) == (0, (6,))
    assert m.release(41) == (0, 3)
    assert m.alloc(43, 1) == (0, (3,))
    assert m.alloc(44, 1) == (0, (4,))
    assert m.alloc(45, 2) == (0, (5, 7))
    assert m.alloc(46, 2) == (0, (8, 9))
    a = (45, 0, 0)
    b = (46, 0, 0)
    assert compare_read_only(m, a, b) == 0
    assert m.write_byte(45, 8192, 1) == 0
    assert m.write_byte(46, 8192, 2) == 0
    assert compare_read_only(m, (45, 0, 8193), (46, 0, 8193)) == 2
    assert compare_read_only(m, (45, 1, 8193), (46, 1, 8193)) == 1
    assert compare_read_only(m, (45, 1, 0), b) == 3
    assert compare_read_only(m, (45, 0, 8193), (46, 0, 16385)) == 3
    assert m.write_byte(46, 8192, 0) == 0
    assert compare_read_only(m, (45, 0, 8193), (46, 0, 8193)) == 3
    assert m.write_byte(46, 8192, 1) == 0
    assert m.write_byte(45, 8191, 0x33) == 0
    assert m.write_byte(46, 8191, 0x34) == 0
    assert compare_read_only(m, (45, 0, 8193), (46, 0, 8193)) == 2
    assert m.write_byte(46, 8191, 0x33) == 0
    assert compare_read_only(m, (45, 0, 8193), (46, 0, 8193)) == 0

    rng = Random(0x830531)
    checks = 0
    for _ in range(256):
        length_a = rng.choice((0, 1, 2, 17, 8192, 8193, 16384))
        length_b = rng.choice((0, 1, 2, 17, 8192, 8193, 16384))
        sign_a, sign_b = rng.randrange(2), rng.randrange(2)
        result = compare_read_only(m, (45, sign_a, length_a), (46, sign_b, length_b))
        assert result in (0, 1, 2, 3)
        if result != 3:
            na = reference_integer(m, 45, sign_a, length_a)
            nb = reference_integer(m, 46, sign_b, length_b)
            assert (result == 0) == (na == nb)
            assert (result == 1) == (na > nb)
            assert (result == 2) == (na < nb)
        checks += 1
    before = bytes(m.data[7]), bytes(m.data[9])
    assert m.release(45) == (0, 2)
    assert compare_read_only(m, (45, 0, 8193), (46, 0, 8193)) == 3
    assert bytes(m.data[9]) == before[1]
    assert m.data[7] == bytearray(SIZE)
    # Same read-only scenarios as Native ROM 203..206, after owner 45's release.
    assert m.write_byte(46, 0, 0x7F) == 0
    assert m.write_byte(42, 0, 1) == 0
    assert compare_read_only(m, (46, 0, 1), (42, 0, 1)) == 1
    assert compare_read_only(m, (46, 2, 1), (42, 0, 1)) == 3
    assert compare_read_only(m, (0, 0, 1), (42, 0, 1)) == 3
    assert compare_read_only(m, (46, 0, 16385), (42, 0, 1)) == 3
    # Cases 207-210: invalid SECOND operand; mirror Native ROM.
    assert compare_read_only(m, (46, 0, 1), (42, 2, 1)) == 3
    assert compare_read_only(m, (46, 0, 1), (45, 0, 1)) == 3  # released
    assert compare_read_only(m, (46, 0, 1), (42, 0, 8193)) == 3
    assert m.read_byte(42, 1) == (0, 0), "B high byte must be zero"
    assert compare_read_only(m, (46, 0, 1), (42, 0, 2)) == 3
    assert m.read_byte(42, 1) == (0, 0), "B high byte changed"
    # Cases 211-212: distinct nonzero magnitudes of opposite sign.
    assert compare_read_only(m, (46, 1, 1), (42, 0, 1)) == 2, "negative A must be less than positive B"
    assert compare_read_only(m, (46, 0, 1), (42, 1, 1)) == 1, "positive A must exceed negative B"
    # Cases 213-214: malformed SECOND operand with zero length, read-only.
    assert compare_read_only(m, (46, 0, 1), (42, 1, 0)) == 3, "B negative zero must fail closed"
    assert compare_read_only(m, (46, 0, 1), (0, 0, 0)) == 3, "B owner zero must fail even at length zero"
    # Cases 215-216: zero-length descriptors ignore nonzero residual SRAM.
    assert m.read_byte(42, 0) == (0, 1), "expected a nonzero stale byte for zero-length operand"
    assert compare_read_only(m, (46, 0, 1), (42, 0, 0)) == 1, "positive A must exceed zero B"
    assert compare_read_only(m, (42, 0, 0), (46, 1, 1)) == 1, "zero A must exceed negative B"
    # Case 217: both canonical zero descriptors ignore stale nonzero SRAM.
    assert m.read_byte(46, 0) == (0, 0x7F), "A stale zero-length payload missing"
    assert m.read_byte(42, 0) == (0, 1), "B stale zero-length payload missing"
    assert compare_read_only(m, (42, 0, 0), (46, 0, 0)) == 0, "two canonical zeros must compare equal"
    # Case 218: the same SRAM owner may be shared by independently signed descriptors.
    assert compare_read_only(m, (46, 0, 1), (46, 1, 1)) == 1, "same-owner positive must exceed negative"
    # Cases 219-220: reverse shared-owner signs, then equal negative aliases.
    assert compare_read_only(m, (46, 1, 1), (46, 0, 1)) == 2, (
        "same-owner negative A must be less than positive B"
    )
    assert compare_read_only(m, (46, 1, 1), (46, 1, 1)) == 0, (
        "two negative descriptors sharing owner and payload must be equal"
    )
    # Cases 221-222: same live owner, one zero-length descriptor.
    # The same stale nonzero SRAM[0] must be ignored by a canonical zero.
    assert m.read_byte(46, 0) == (0, 0x7F), "shared-owner zero must hide stale payload"
    assert compare_read_only(m, (46, 0, 0), (46, 0, 1)) == 2, (
        "same-owner canonical zero A must be below positive nonzero B"
    )
    assert compare_read_only(m, (46, 1, 1), (46, 0, 0)) == 2, (
        "same-owner negative nonzero A must be below canonical zero B"
    )
    # Cases 223-225: same-owner zero equality and negative-zero rejection.
    # The single physical SRAM[0]=0x7f stays stale for each zero descriptor.
    assert m.read_byte(46, 0) == (0, 0x7F), "shared owner lost stale payload"
    assert compare_read_only(m, (46, 0, 0), (46, 0, 0)) == 0, (
        "two canonical zero descriptors sharing one owner must be equal"
    )
    assert compare_read_only(m, (46, 1, 0), (46, 0, 1)) == 3, (
        "negative zero A must remain invalid under same-owner aliasing"
    )
    assert compare_read_only(m, (46, 0, 1), (46, 1, 0)) == 3, (
        "negative zero B must remain invalid under same-owner aliasing"
    )
    # Cases 226-227: aliasing must not bypass a 16384-byte owner capacity.
    # Validate the length of each descriptor independently, both directions.
    assert compare_read_only(m, (46, 0, 1), (46, 0, 16385)) == 3, (
        "over-capacity B must fail closed even when A shares its live owner"
    )
    assert compare_read_only(m, (46, 0, 16385), (46, 0, 1)) == 3, (
        "over-capacity A must fail closed even when B shares its live owner"
    )
    # Cases 228-229: same SRAM owner but a noncanonical high zero.
    assert m.read_byte(46, 0) == (0, 0x7F), "same-owner low byte changed"
    assert m.read_byte(46, 1) == (0, 0), "noncanonical high byte must be zero"
    assert compare_read_only(m, (46, 0, 1), (46, 0, 2)) == 3, (
        "invalid two-byte B must be rejected even under owner aliasing"
    )
    assert compare_read_only(m, (46, 0, 2), (46, 0, 1)) == 3, (
        "invalid two-byte A must be rejected even under owner aliasing"
    )
    # Cases 230-231: independent integer oracle for same-owner, bank-edge lengths.
    # The stored high byte is nonzero at both 8191 and 8192, so neither
    # descriptor is an invalid leading-zero representation.
    assert m.read_byte(46, 8191) == (0, 0x33), "8192-byte top byte must be 0x33"
    assert m.read_byte(46, 8192) == (0, 0x01), "8193-byte top byte must be 0x01"
    short = reference_integer(m, 46, 0, 8192)
    long = reference_integer(m, 46, 0, 8193)
    assert short > 0 and long > short, "bank-edge integer ordering disagrees"
    assert compare_read_only(m, (46, 0, 8192), (46, 0, 8193)) == 2, (
        "shared-owner shorter A must be less than longer B across bank edge"
    )
    assert compare_read_only(m, (46, 0, 8193), (46, 0, 8192)) == 1, (
        "shared-owner longer A must be greater than shorter B across bank edge"
    )
    # Cases 232-233: same owner, negative signs and unequal canonical lengths.
    # Negation reverses the strict ordering of the independently decoded integers.
    neg_short = reference_integer(m, 46, 1, 8192)
    neg_long = reference_integer(m, 46, 1, 8193)
    assert neg_long < neg_short < 0, "negative bank-edge ordering disagrees"
    assert neg_short == -short and neg_long == -long
    assert compare_read_only(m, (46, 1, 8192), (46, 1, 8193)) == 1, (
        "negative shorter A must exceed negative longer B across bank edge"
    )
    assert compare_read_only(m, (46, 1, 8193), (46, 1, 8192)) == 2, (
        "negative longer A must be less than negative shorter B across bank edge"
    )
    # Cases 234-235: equal negative descriptors sharing the same live owner.
    # Use independently decoded Python integers for each canonical bank-edge
    # length; identical metadata and payload must compare equal without writes.
    for length, expected_integer in ((8192, neg_short), (8193, neg_long)):
        decoded_a = reference_integer(m, 46, 1, length)
        decoded_b = reference_integer(m, 46, 1, length)
        assert decoded_a == decoded_b == expected_integer < 0, (
            f"shared-owner negative equality oracle failed at length={length}"
        )
        assert compare_read_only(m, (46, 1, length), (46, 1, length)) == 0, (
            f"shared-owner negative EQ failed at length={length}"
        )
    # Cases 236-237: mixed-sign same-owner aliases across the 8-KiB bank boundary.
    # The integer oracle decodes each descriptor independently, even with shared storage.
    positive_short = reference_integer(m, 46, 0, 8192)
    negative_long = reference_integer(m, 46, 1, 8193)
    assert positive_short == short > 0 and negative_long == neg_long < 0
    assert positive_short > negative_long, "positive shorter must exceed negative longer"
    assert compare_read_only(m, (46, 0, 8192), (46, 1, 8193)) == 1, (
        "shared-owner positive short A must exceed negative long B"
    )
    assert negative_long < positive_short, "negative longer must be below positive shorter"
    assert compare_read_only(m, (46, 1, 8193), (46, 0, 8192)) == 2, (
        "shared-owner negative long A must be below positive short B"
    )
    # Cases 238-239: opposite signs on equal 8192/8193-byte magnitudes.
    # Decode shared storage independently as signed Python integers; check
    # all owner tags, SRAM bank bytes and descriptors through compare_read_only.
    pos_8192 = reference_integer(m, 46, 0, 8192)
    neg_8192 = reference_integer(m, 46, 1, 8192)
    assert pos_8192 == -neg_8192 > 0, "8192-byte signed integer oracle"
    assert compare_read_only(m, (46, 0, 8192), (46, 1, 8192)) == 1, (
        "equal positive/negative 8192-byte aliases must return GT"
    )
    neg_8193 = reference_integer(m, 46, 1, 8193)
    pos_8193 = reference_integer(m, 46, 0, 8193)
    assert neg_8193 == -pos_8193 < 0, "8193-byte signed integer oracle"
    assert compare_read_only(m, (46, 1, 8193), (46, 0, 8193)) == 2, (
        "equal negative/positive 8193-byte aliases must return LT"
    )
    # Cases 240-241: the two-bank owner spans exactly 16384 bytes.
    # Write the highest legal byte and derive both signs independently
    # using Python's int.from_bytes (not the SM83 implementation).
    assert m.write_byte(46, 16383, 0x5A) == 0
    assert m.read_byte(46, 16383) == (0, 0x5A)
    pos_full = reference_integer(m, 46, 0, 16384)
    neg_full = reference_integer(m, 46, 1, 16384)
    assert pos_full > 0 and pos_full == -neg_full
    assert compare_read_only(m, (46, 0, 16384), (46, 1, 16384)) == 1, (
        "full-capacity positive A must exceed negative B"
    )
    assert compare_read_only(m, (46, 1, 16384), (46, 0, 16384)) == 2, (
        "full-capacity negative A must be less than positive B"
    )
    # Cases 242-243: equal signed aliases at the exact 16384-byte capacity.
    # Decode each operand independently from physical owner SRAM using Python
    # integers; the read-only wrapper snapshots every SRAM bank and all tags.
    assert reference_integer(m, 46, 0, 16384) == pos_full > 0
    assert compare_read_only(m, (46, 0, 16384), (46, 0, 16384)) == 0, (
        "full-capacity positive aliases must compare equal"
    )
    assert reference_integer(m, 46, 1, 16384) == neg_full < 0
    assert compare_read_only(m, (46, 1, 16384), (46, 1, 16384)) == 0, (
        "full-capacity negative aliases must compare equal"
    )
    assert m.read_byte(46, 16383) == (0, 0x5A), "highest owner byte changed"
    # Bank-edge read-only sentinels mirrored from ROM cases 203..210.
    assert m.read_byte(46, 8191) == (0, 0x33), "A bank-end sentinel changed"
    assert m.read_byte(42, 8191) == (0, 0x00), "B bank-end sentinel changed"
    assert m.read_byte(46, 8192) == (0, 0x01), "A next-bank sentinel changed"
    print("HOST_OWNER_SIGNED_CMP_READ_ONLY=PASS success=1 invalid_sign=1 invalid_owner=1 invalid_length=1 invalid_B=6 negative_zero_B=1 invalid_owner_zero_B=1 boundary_sentinels=3 mixed_nonzero_signs=2 zero_orderings=2 zero_equality_stale=1 same_owner_alias=26 same_owner_mixed_sign_boundary=4 same_owner_mixed_sign_equal_length=2 same_owner_boundary=4 same_owner_negative_boundary=2 same_owner_negative_equal_boundary=2 same_owner_noncanonical=2 same_owner_zero=5 same_owner_negative_zero=2 same_owner_overcapacity=2 same_owner_full_capacity=4 same_owner_full_capacity_equal=2 payload_and_tags=IMMUTABLE")
    print(f"HOST_OWNER_SIGNED_CMP_REFERENCE=PASS randomized_cases={checks} canonical=YES fragmented=YES zero_sign=YES owner_release=YES")
    print("NOT_A_NATIVE_ROM_VERIFICATION=YES")


if __name__ == "__main__":
    main()
