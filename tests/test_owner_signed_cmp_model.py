#!/usr/bin/env python3
"""Independent Python integer oracle for owner-scoped signed magnitudes.

This is a HOST reference contract, not execution of SM83 machine code.
The ROM exercise covers cases 191..212.
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
    # Bank-edge read-only sentinels mirrored from ROM cases 203..210.
    assert m.read_byte(46, 8191) == (0, 0x33), "A bank-end sentinel changed"
    assert m.read_byte(42, 8191) == (0, 0x00), "B bank-end sentinel changed"
    assert m.read_byte(46, 8192) == (0, 0x01), "A next-bank sentinel changed"
    print("HOST_OWNER_SIGNED_CMP_READ_ONLY=PASS success=1 invalid_sign=1 invalid_owner=1 invalid_length=1 invalid_B=4 boundary_sentinels=3 mixed_nonzero_signs=2 payload_and_tags=IMMUTABLE")
    print(f"HOST_OWNER_SIGNED_CMP_REFERENCE=PASS randomized_cases={checks} canonical=YES fragmented=YES zero_sign=YES owner_release=YES")
    print("NOT_A_NATIVE_ROM_VERIFICATION=YES")


if __name__ == "__main__":
    main()
