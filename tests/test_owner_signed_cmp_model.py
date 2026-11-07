#!/usr/bin/env python3
"""Independent Python integer oracle for owner-scoped signed magnitudes.

This is a HOST reference contract, not execution of SM83 machine code.
The ROM exercise covers cases 191..283; the independent max-owner allocation/byte\nHost oracle supplies expected statuses and SRAM/tag immutability for Native278..283.
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



def check_owner_id_high_boundary():
    """Host-only: exact 8-bit tag limit, invalid owner IDs, and revocation."""
    model = OwnedBanks()
    assert model.alloc(253, 1) == (0, (3,))
    assert model.alloc(1, 1) == (0, (4,))
    assert model.tags[3] == 255 and model.tags[4] == 3
    assert model.write_byte(253, 0, 0xA5) == 0
    assert model.write_byte(1, 0, 0x01) == 0
    assert reference_integer(model, 253, 0, 1) == int.from_bytes(bytes((0xA5,)), "little")
    assert reference_integer(model, 253, 1, 1) == -165
    assert reference_integer(model, 1, 0, 1) == 1

    # Invalid lease allocation cannot wrap owner+2 in the 8-bit tag.
    before_tags = tuple(model.tags)
    before_payload = tuple(bytes(bank) for bank in model.data)
    for invalid_id in (254, 255):
        assert model.alloc(invalid_id, 1) == (2, ())
    assert tuple(model.tags) == before_tags
    assert tuple(bytes(bank) for bank in model.data) == before_payload

    cases = (
        ((253, 0, 1), (1, 0, 1), 1),
        ((1, 0, 1), (253, 0, 1), 2),
        ((253, 1, 1), (1, 0, 1), 2),
        ((1, 0, 1), (253, 1, 1), 1),
        ((253, 0, 0), (1, 0, 0), 0),
        ((254, 0, 1), (253, 0, 1), 3),
        ((253, 0, 1), (254, 0, 1), 3),
        ((255, 0, 1), (253, 0, 1), 3),
        ((253, 0, 1), (255, 0, 1), 3),
        ((254, 0, 0), (253, 0, 0), 3),
        ((253, 0, 0), (255, 0, 0), 3),
        ((253, 1, 0), (1, 0, 1), 3),
        ((1, 0, 1), (253, 1, 0), 3),
        ((253, 0, 2), (1, 0, 1), 3),
        ((1, 0, 1), (253, 0, 2), 3),
        ((253, 0, 1), (253, 0, 1), 0),
    )
    for a, b, expected in cases:
        assert compare_read_only(model, a, b) == expected, (
            f"owner-ID boundary mismatch: {a}, {b}, expected={expected}"
        )

    assert model.release(253) == (0, 1)
    assert model.tags[3] == 0 and model.data[3] == bytearray(SIZE)
    for a, b in (
        ((253, 0, 1), (1, 0, 1)),
        ((1, 0, 1), (253, 0, 1)),
    ):
        assert compare_read_only(model, a, b) == 3
    print("HOST_OWNER_SIGNED_CMP_OWNER_ID_BOUNDARY=PASS cases=18 valid_max=253 rejected=254,255 tag255=YES revoked=YES payload_and_tags=IMMUTABLE")


def check_owner_id_fragmented_high_boundary():
    """Host-only: owner 253/tag 255 across discontiguous banks, then revocation."""
    model = OwnedBanks()
    assert model.alloc(253, 3) == (0, (3, 4, 5))
    assert model.alloc(1, 1) == (0, (6,))
    assert model.release(253) == (0, 3)
    assert model.alloc(2, 1) == (0, (3,))
    assert model.alloc(3, 1) == (0, (4,))
    assert model.alloc(253, 2) == (0, (5, 7))
    assert model.tags[5] == model.tags[7] == 255
    assert model.tags[6] == 3, "interposed bank belongs to owner 1"
    assert model.write_byte(253, 0, 0x11) == 0
    assert model.write_byte(253, SIZE - 1, 0x33) == 0
    assert model.write_byte(253, SIZE, 0x02) == 0
    assert model.write_byte(253, 2 * SIZE - 1, 0x77) == 0
    assert model.write_byte(1, 0, 0x01) == 0
    assert model.read_byte(253, SIZE - 1) == (0, 0x33)
    assert model.read_byte(253, SIZE) == (0, 0x02)
    assert model.read_byte(1, 0) == (0, 0x01)

    short = reference_integer(model, 253, 0, SIZE)
    long = reference_integer(model, 253, 0, SIZE + 1)
    full = reference_integer(model, 253, 0, 2 * SIZE)
    peer = reference_integer(model, 1, 0, 1)
    assert 0 < peer < short < long < full
    assert reference_integer(model, 253, 1, 2 * SIZE) == -full
    # Every tuple includes an independent, explicit expected result.
    baseline = (
        ((253, 0, SIZE), (253, 0, SIZE + 1), 2),
        ((253, 0, SIZE + 1), (253, 0, SIZE), 1),
        ((253, 1, SIZE), (253, 1, SIZE + 1), 1),
        ((253, 1, SIZE + 1), (253, 1, SIZE), 2),
        ((253, 0, SIZE), (253, 1, 2 * SIZE), 1),
        ((253, 1, 2 * SIZE), (253, 0, SIZE), 2),
        ((253, 1, SIZE), (253, 0, 2 * SIZE), 2),
        ((253, 0, 2 * SIZE), (253, 1, SIZE), 1),
        ((253, 0, 2 * SIZE), (253, 0, 2 * SIZE), 0),
        ((253, 1, 2 * SIZE), (253, 1, 2 * SIZE), 0),
        ((253, 0, SIZE), (1, 0, 1), 1),
        ((1, 0, 1), (253, 0, SIZE), 2),
        ((253, 1, SIZE), (1, 0, 1), 2),
        ((1, 0, 1), (253, 1, SIZE), 1),
        ((254, 0, 1), (253, 0, SIZE), 3),
        ((253, 0, SIZE), (254, 0, 1), 3),
        ((255, 0, 1), (253, 0, SIZE), 3),
        ((253, 0, SIZE), (255, 0, 1), 3),
        ((253, 0, 2 * SIZE + 1), (1, 0, 1), 3),
        ((1, 0, 1), (253, 0, 2 * SIZE + 1), 3),
        ((253, 1, 0), (1, 0, 1), 3),
        ((1, 0, 1), (253, 1, 0), 3),
        ((253, 0, 0), (1, 0, 0), 0),
        ((1, 0, 0), (253, 0, 0), 0),
    )
    assert len(baseline) == 24
    for a, b, expected in baseline:
        assert compare_read_only(model, a, b) == expected, (
            f"fragmented boundary mismatch: {a}, {b}, expected={expected}"
        )

    # A canonical SIZE-byte descriptor survives; SIZE+1 with high zero must fail.
    assert model.write_byte(253, SIZE, 0) == 0
    assert reference_integer(model, 253, 0, SIZE) == short
    high_zero = (
        ((253, 0, SIZE), (253, 0, SIZE + 1)),
        ((253, 0, SIZE + 1), (253, 0, SIZE)),
        ((253, 1, SIZE), (253, 1, SIZE + 1)),
        ((253, 1, SIZE + 1), (253, 1, SIZE)),
    )
    assert len(high_zero) == 4
    for a, b in high_zero:
        assert compare_read_only(model, a, b) == 3
    assert model.write_byte(253, SIZE, 0x02) == 0

    # A release revokes both fragmented banks; the interposed live peer persists.
    assert model.release(253) == (0, 2)
    assert model.tags[5] == model.tags[7] == 0
    assert not any(model.data[5]) and not any(model.data[7])
    assert model.tags[6] == 3
    assert reference_integer(model, 1, 0, 1) == peer
    revoked = (
        ((253, 0, SIZE), (1, 0, 1)),
        ((1, 0, 1), (253, 0, SIZE)),
        ((253, 1, SIZE + 1), (1, 0, 1)),
        ((1, 0, 1), (253, 1, SIZE + 1)),
    )
    assert len(revoked) == 4
    for a, b in revoked:
        assert compare_read_only(model, a, b) == 3

    # Distinct Stage 1 gap: both descriptors alias the *same revoked* max
    # owner (253 / tag 255), rather than comparing one revoked operand to
    # a live peer. Neither equality nor signed polarity may revive the lease.
    revoked_aliases = (
        ((253, 0, SIZE), (253, 0, SIZE)),
        ((253, 1, SIZE + 1), (253, 1, SIZE + 1)),
        ((253, 0, SIZE), (253, 1, SIZE + 1)),
        ((253, 1, SIZE + 1), (253, 0, SIZE)),
    )
    assert len(revoked_aliases) == 4
    for a, b in revoked_aliases:
        for descriptor in (a, b):
            try:
                reference_integer(model, *descriptor)
            except ValueError as exc:
                assert str(exc) == "capacity", "revoked alias must fail lease lookup"
            else:
                raise AssertionError(f"revoked max-owner descriptor accepted: {descriptor}")
        assert compare_read_only(model, a, b) == 3, (
            f"revoked max-owner alias compared as valid: {a}, {b}"
        )
    # Host-only revoked-zero boundary: zero length is not a valid value
    # when the owner lease is gone, even if both descriptors would equal zero.
    # No ROM0 increase and no implied Native coverage.
    assert reference_integer(model, 1, 0, 0) == 0
    assert reference_integer(model, 1, 0, 1) == int.from_bytes(bytes((1,)), "little")
    revoked_zero = (
        ((253, 0, 0), (253, 0, 0)),
        ((253, 0, 0), (1, 0, 0)),
        ((1, 0, 0), (253, 0, 0)),
        ((253, 0, 0), (1, 0, 1)),
        ((1, 0, 1), (253, 0, 0)),
        ((253, 1, 0), (1, 0, 0)),
        ((1, 0, 0), (253, 1, 0)),
        ((253, 1, 0), (253, 1, 0)),
    )
    assert len(revoked_zero) == 8
    for a, b in revoked_zero:
        for descriptor in (a, b):
            if descriptor[0] != 253:
                continue
            try:
                reference_integer(model, *descriptor)
            except ValueError as exc:
                assert str(exc) == "capacity", (
                    "revoked zero must fail lease lookup before sign/zero checks"
                )
            else:
                raise AssertionError(f"revoked zero descriptor accepted: {descriptor}")
        assert compare_read_only(model, a, b) == 3, (
            f"revoked zero descriptor compared as valid: {a}, {b}"
        )
    assert model.tags[5] == model.tags[7] == 0 and model.tags[6] == 3
    print("HOST_OWNER_SIGNED_CMP_FRAGMENTED_MAX_OWNER=PASS cases=44 revoked_zero=8 owner=253 tag=255 banks=5,7 peer_bank=6 canonical_and_revoked=YES payload_and_tags=IMMUTABLE")

def check_native_cases262_to277_oracle():
    """Independent integer oracle for ROM cases 262-277; not a Native PASS."""
    model = OwnedBanks()
    assert model.alloc(253, 1) == (0, (3,))
    assert model.tags[3] == 255
    assert model.alloc(1, 1) == (0, (4,))
    assert model.tags[4] == 3
    assert model.write_byte(253, 0, 2) == 0
    assert model.write_byte(1, 0, 1) == 0
    big = int.from_bytes(bytes((2,)), "little", signed=False)
    small = int.from_bytes(bytes((1,)), "little", signed=False)
    assert big == 2 and small == 1 and big > small
    assert reference_integer(model, 253, 0, 1) == big
    assert reference_integer(model, 1, 0, 1) == small
    assert compare_read_only(model, (253, 0, 1), (1, 0, 1)) == 1
    assert model.read_byte(253, 0) == (0, 2)
    assert model.read_byte(1, 0) == (0, 1)
    assert model.tags[3] == 255 and model.tags[4] == 3
    print("HOST_NATIVE262_INDEPENDENT_ORACLE=PASS owner=253 tag=255 peer=1 A=2 B=1 expected=GT1 payload_and_tags=IMMUTABLE")
    # Case 263: physical bank 3 was scrubbed upon revocation, while
    # physical bank 4 remains owned and contains the stale $01 sentinel.
    assert model.release(253) == (0, 1)
    assert model.tags[3] == 0 and model.tags[4] == 3
    assert model.data[3][0] == 0 and model.data[4][0] == 1
    assert reference_integer(model, 1, 0, 0) == 0
    try:
        reference_integer(model, 253, 0, 0)
    except ValueError as exc:
        assert str(exc) == "capacity", "revoked zero must fail lease validation"
    else:
        raise AssertionError("revoked owner 253 accepted as a valid zero")
    assert compare_read_only(model, (253, 0, 0), (1, 0, 0)) == 3
    assert model.tags[3] == 0 and model.tags[4] == 3
    assert model.data[3][0] == 0 and model.data[4][0] == 1
    print("HOST_NATIVE263_INDEPENDENT_ORACLE=PASS revoked_owner=253 old_tag=255 live_owner=1 zero_lengths=YES expected=INVALID3 bank3_scrubbed=YES bank4_preserved=YES payload_and_tags=IMMUTABLE")
    # Native 264: same physical state, reverse operand orientation.
    assert compare_read_only(model, (1, 0, 0), (253, 0, 0)) == 3
    assert model.tags[3] == 0 and model.tags[4] == 3
    assert model.data[3][0] == 0 and model.data[4][0] == 1
    print("HOST_NATIVE264_INDEPENDENT_ORACLE=PASS live_A=1 revoked_B=253 zero_lengths=YES expected=INVALID3 payload_and_tags=IMMUTABLE")
    # Case265: revoked negative zero remains invalid, irrespective of whether
    # capacity or noncanonicality is detected first by the implementation.
    assert compare_read_only(model, (1, 0, 0), (253, 1, 0)) == 3
    assert model.tags[3] == 0 and model.tags[4] == 3
    assert model.data[3][0] == 0 and model.data[4][0] == 1
    print("HOST_NATIVE265_INDEPENDENT_ORACLE=PASS live_A=1 revoked_B=253 negative_zero_B=YES expected=INVALID3 payload_and_tags=IMMUTABLE")
    # Native 266/267: invalid owner IDs cannot be accepted as numeric zero.
    # The reference parser rejects metadata (not just a missing lease).
    for invalid_owner, left, right in (
        (254, (1, 0, 0), (254, 0, 0)),
        (255, (255, 0, 0), (1, 0, 0)),
    ):
        try:
            reference_integer(model, invalid_owner, 0, 0)
        except ValueError as exc:
            assert str(exc) == "metadata", "invalid owner rejected at ID boundary"
        else:
            raise AssertionError(f"owner {invalid_owner} incorrectly accepted")
        assert compare_read_only(model, left, right) == 3
        assert model.tags[3] == 0 and model.tags[4] == 3
        assert model.data[3][0] == 0 and model.data[4][0] == 1
        print(
            f"HOST_NATIVE{266 if invalid_owner == 254 else 267}_INDEPENDENT_ORACLE=PASS "
            f"invalid_owner={invalid_owner} zero_lengths=YES expected=INVALID3 "
            "payload_and_tags=IMMUTABLE"
        )

    # Native 268/269 exercise nonzero descriptors for illegal owner IDs;
    # owner 1 provides a separate canonical one-byte integer peer.
    assert reference_integer(model, 1, 0, 1) == int.from_bytes(bytes((1,)), "little")
    for case_id, invalid_owner, left, right in (
        (268, 254, (1, 0, 1), (254, 0, 1)),
        (269, 255, (255, 0, 1), (1, 0, 1)),
    ):
        try:
            reference_integer(model, invalid_owner, 0, 1)
        except ValueError as exc:
            assert str(exc) == "metadata", "illegal ID must fail before byte reading"
        else:
            raise AssertionError(f"case {case_id}: illegal owner {invalid_owner} accepted")
        assert compare_read_only(model, left, right) == 3
        assert model.tags[3] == 0 and model.tags[4] == 3
        assert model.data[3][0] == 0 and model.data[4][0] == 1
        print(
            f"HOST_NATIVE{case_id}_INDEPENDENT_ORACLE=PASS "
            f"invalid_owner={invalid_owner} one_byte_lengths=YES "
            "live_peer=1 expected=INVALID3 payload_and_tags=IMMUTABLE"
        )
    # Native 270/271: the reserved owner ID 0 is not a live lease, even
    # when the physical free-bank tag is zero and operands look numeric.
    for case_id, left, right, invalid_length in (
        (270, (0, 0, 0), (1, 0, 0), 0),
        (271, (1, 0, 1), (0, 0, 1), 1),
    ):
        try:
            reference_integer(model, 0, 0, invalid_length)
        except ValueError as exc:
            assert str(exc) == "metadata", "reserved owner zero must reject before lease lookup"
        else:
            raise AssertionError(f"case {case_id}: reserved owner zero accepted")
        assert compare_read_only(model, left, right) == 3
        assert model.tags[3] == 0 and model.tags[4] == 3
        assert model.data[3][0] == 0 and model.data[4][0] == 1
        print(
            f"HOST_NATIVE{case_id}_INDEPENDENT_ORACLE=PASS "
            "invalid_owner=0 expected=INVALID3 payload_and_tags=IMMUTABLE"
        )

    # Case 272: live A against reserved B negative zero.
    # Case 273: reserved A/B alias, with A negative zero and B canonical zero.
    # Independently validate *each* reserved descriptor as invalid metadata.
    for case_id, left, right in (
        (272, (1, 0, 0), (0, 1, 0)),
        (273, (0, 1, 0), (0, 0, 0)),
    ):
        reserved = [descriptor for descriptor in (left, right) if descriptor[0] == 0]
        assert len(reserved) == (2 if case_id == 273 else 1)
        for descriptor in reserved:
            try:
                reference_integer(model, *descriptor)
            except ValueError as exc:
                assert str(exc) == "metadata", "reserved owner rejected before negative-zero semantics"
            else:
                raise AssertionError(f"case {case_id}: reserved owner accepted: {descriptor}")
        assert compare_read_only(model, left, right) == 3
        assert model.tags[3] == 0 and model.tags[4] == 3
        assert model.data[3][0] == 0 and model.data[4][0] == 1
        print(
            f"HOST_NATIVE{case_id}_INDEPENDENT_ORACLE=PASS "
            f"owner0_descriptors={len(reserved)} negative_zero=YES "
            "expected=INVALID3 payload_and_tags=IMMUTABLE"
        )

    # Native 274-277: both operands are invalid simultaneously.
    # Case 274 aliases owner 254 at zero length; cases 275/276 have
    # invalid 255/254 in both orientations; 277 aliases owner 255 at one byte.
    # Decode the live control independently, then reject EACH bad descriptor
    # via the Python integer reference (not an SM83 routine).
    assert reference_integer(model, 1, 0, 1) == int.from_bytes(
        bytes(model.data[4][:1]), "little", signed=False
    ) == 1
    for case_id, left, right in (
        (274, (254, 0, 0), (254, 0, 0)),
        (275, (255, 1, 1), (254, 0, 1)),
        (276, (254, 0, 1), (255, 1, 1)),
        (277, (255, 0, 1), (255, 1, 1)),
    ):
        for descriptor in (left, right):
            try:
                reference_integer(model, *descriptor)
            except ValueError as exc:
                assert str(exc) == "metadata", (
                    f"case {case_id}: invalid owner accepted by reference parser"
                )
            else:
                raise AssertionError(f"case {case_id}: invalid descriptor accepted: {descriptor}")
        assert compare_read_only(model, left, right) == 3
        assert model.tags[3] == 0 and model.tags[4] == 3
        assert model.data[3][0] == 0 and model.data[4][0] == 1
        print(
            f"HOST_NATIVE{case_id}_INDEPENDENT_ORACLE=PASS "
            f"owners={left[0]}/{right[0]} lengths={left[2]}/{right[2]} "
            "both_invalid=YES expected=INVALID3 payload_and_tags=IMMUTABLE"
        )


def check_dual_invalid_owner_cartesian():
    """Host-only exhaustive metadata matrix; no new Native case is claimed.

    The accepted ROM cases 273-277 sample simultaneous invalid owners.
    This independent oracle exercises all combinations of reserved/illegal
    IDs, two signs, and the 0/1 byte boundary, with a full read-only check.
    """
    model = OwnedBanks()
    assert model.alloc(1, 1) == (0, (3,))
    assert model.write_byte(1, 0, 0x5A) == 0
    assert reference_integer(model, 1, 0, 1) == int.from_bytes(b"\x5a", "little")
    invalid_owners = (0, 254, 255)
    checks = 0
    for owner_a in invalid_owners:
        for owner_b in invalid_owners:
            for sign_a in (0, 1):
                for sign_b in (0, 1):
                    for length_a in (0, 1):
                        for length_b in (0, 1):
                            descriptor_a = (owner_a, sign_a, length_a)
                            descriptor_b = (owner_b, sign_b, length_b)
                            for descriptor in (descriptor_a, descriptor_b):
                                try:
                                    reference_integer(model, *descriptor)
                                except ValueError as exc:
                                    assert str(exc) == "metadata", (
                                        f"invalid owner not rejected first: {descriptor}"
                                    )
                                else:
                                    raise AssertionError(
                                        f"illegal descriptor accepted: {descriptor}"
                                    )
                            assert compare_read_only(model, descriptor_a, descriptor_b) == 3, (
                                f"dual invalid operands accepted: {descriptor_a}, {descriptor_b}"
                            )
                            checks += 1
    assert checks == 144
    assert model.tags[3] == 3 and model.data[3][0] == 0x5A
    print(
        "HOST_STAGE1_DUAL_INVALID_OWNER_CARTESIAN=PASS cases=144 "
        "owners=0,254,255 signs=0,1 lengths=0,1 "
        "both_invalid=YES payload_and_tags=IMMUTABLE"
    )


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
    # Cases 244-245: canonical adjacent lengths at the exact owner capacity.
    # A shared owner still has two independently signed descriptors; decode
    # both magnitudes from physical SRAM with the Python-integer oracle.
    assert m.write_byte(46, 16382, 0x3C) == 0
    assert m.read_byte(46, 16382) == (0, 0x3C)
    pos_near = reference_integer(m, 46, 0, 16383)
    pos_full_edge = reference_integer(m, 46, 0, 16384)
    assert 0 < pos_near < pos_full_edge, "capacity-edge positive integer oracle"
    assert compare_read_only(m, (46, 0, 16383), (46, 0, 16384)) == 2, (
        "shared-owner canonical positive near-capacity must be less than full"
    )
    neg_near = reference_integer(m, 46, 1, 16383)
    neg_full_edge = reference_integer(m, 46, 1, 16384)
    assert neg_full_edge < neg_near < 0, "capacity-edge negative integer oracle"
    assert compare_read_only(m, (46, 1, 16383), (46, 1, 16384)) == 1, (
        "shared-owner canonical negative near-capacity must exceed full"
    )
    assert m.read_byte(46, 16382) == (0, 0x3C), "near-capacity byte changed"
    assert m.read_byte(46, 16383) == (0, 0x5A), "highest owner byte changed"
    # Cases 246-247: a 16383-byte canonical descriptor beside a full-capacity
    # 16384-byte descriptor whose most-significant SRAM byte is zero.
    # The Python int.from_bytes oracle accepts A and independently rejects B.
    assert m.write_byte(46, 16383, 0x00) == 0
    assert m.read_byte(46, 16382) == (0, 0x3C), "canonical short high byte missing"
    assert m.read_byte(46, 16383) == (0, 0x00), "full-capacity high zero missing"
    canonical_short = reference_integer(m, 46, 0, 16383)
    assert canonical_short > 0, "16383-byte descriptor must remain canonical"
    try:
        reference_integer(m, 46, 0, 16384)
    except ValueError as exc:
        assert str(exc) == "noncanonical leading zero", (
            "full-capacity oracle must reject exactly the zero high byte"
        )
    else:
        raise AssertionError("16384-byte high-zero descriptor was accepted")
    assert compare_read_only(m, (46, 0, 16383), (46, 0, 16384)) == 3, (
        "noncanonical full-capacity B must fail closed"
    )
    assert compare_read_only(m, (46, 0, 16384), (46, 0, 16383)) == 3, (
        "noncanonical full-capacity A must fail closed"
    )
    assert m.read_byte(46, 16382) == (0, 0x3C), "canonical short high byte changed"
    assert m.read_byte(46, 16383) == (0, 0x00), "noncanonical high zero changed"
    # Cases 248-249: reallocate owner 45 as the fragmented physical pair (5,7);
    # owner 42 keeps bank 6, so logical offsets 8191 and 8192 cross a bank gap.
    assert m.alloc(45, 2) == (0, (5, 7)), "owner 45 must be fragmented across banks 5 and 7"
    assert m.write_byte(45, 8191, 0x33) == 0
    assert m.write_byte(45, 8192, 0x01) == 0
    assert m.read_byte(45, 8191) == (0, 0x33)
    assert m.read_byte(45, 8192) == (0, 0x01)
    fragmented_short = reference_integer(m, 45, 0, 8192)
    fragmented_long = reference_integer(m, 45, 0, 8193)
    assert fragmented_short > 0 and fragmented_long > fragmented_short, (
        "fragmented-owner Python integer oracle across bank gap"
    )
    assert compare_read_only(m, (45, 0, 8192), (45, 0, 8193)) == 2, (
        "fragmented same-owner short A must be less than long B"
    )
    assert compare_read_only(m, (45, 0, 8193), (45, 0, 8192)) == 1, (
        "fragmented same-owner long A must exceed short B"
    )
    fragmented_negative_short = reference_integer(m, 45, 1, 8192)
    fragmented_negative_long = reference_integer(m, 45, 1, 8193)
    assert fragmented_negative_long < fragmented_negative_short < 0, (
        "fragmented-owner negative integer oracle across bank gap"
    )
    assert compare_read_only(m, (45, 1, 8192), (45, 1, 8193)) == 1, (
        "fragmented same-owner negative short A must exceed negative long B"
    )
    assert compare_read_only(m, (45, 1, 8193), (45, 1, 8192)) == 2, (
        "fragmented same-owner negative long A must be less than negative short B"
    )
    assert m.read_byte(45, 8191) == (0, 0x33)
    assert m.read_byte(45, 8192) == (0, 0x01)
    # Cases 252-253: the fragmented owner's next-bank high byte is zero.
    # The 8192-byte descriptor remains canonical; the 8193-byte descriptor
    # must be rejected as noncanonical in either operand position.
    assert m.write_byte(45, 8192, 0x00) == 0
    assert m.read_byte(45, 8191) == (0, 0x33)
    assert m.read_byte(45, 8192) == (0, 0x00)
    canonical_fragmented = reference_integer(m, 45, 0, 8192)
    assert canonical_fragmented > 0
    try:
        reference_integer(m, 45, 0, 8193)
    except ValueError as exc:
        assert str(exc) == "noncanonical leading zero"
    else:
        raise AssertionError("fragmented 8193-byte high-zero descriptor was accepted")
    assert compare_read_only(m, (45, 0, 8192), (45, 0, 8193)) == 3, (
        "fragmented noncanonical B must fail closed"
    )
    assert compare_read_only(m, (45, 0, 8193), (45, 0, 8192)) == 3, (
        "fragmented noncanonical A must fail closed"
    )
    # Native case IDs 256-257 reuse this independent Python-int oracle;
    # the 16-bit ID marker is verified separately by emulator gate tests.
    assert compare_read_only(m, (45, 0, 8192), (45, 0, 8193)) == 3, (
        "case 256 must reject noncanonical B without touching payload/tags"
    )
    assert reference_integer(m, 45, 0, 8192) > 0
    assert compare_read_only(m, (45, 0, 8192), (45, 0, 8192)) == 0, (
        "case 257 must accept canonical equality read-only"
    )
    # Stage 1 gap: opposite signs must not bypass canonical-length validation.
    # Native cases 252-253 exercise positive A/negative B in both length orders;
    # the full four-orientation matrix is a HOST oracle, not Native evidence.
    assert reference_integer(m, 45, 0, 8192) > 0
    assert reference_integer(m, 45, 1, 8192) < 0
    for sign in (0, 1):
        try:
            reference_integer(m, 45, sign, 8193)
        except ValueError as exc:
            assert str(exc) == "noncanonical leading zero"
        else:
            raise AssertionError(f"invalid fragmented high-zero accepted for sign={sign}")
    mixed_sign_invalid = (
        ((45, 0, 8192), (45, 1, 8193)),
        ((45, 0, 8193), (45, 1, 8192)),
        ((45, 1, 8192), (45, 0, 8193)),
        ((45, 1, 8193), (45, 0, 8192)),
    )
    for descriptor_a, descriptor_b in mixed_sign_invalid:
        assert compare_read_only(m, descriptor_a, descriptor_b) == 3, (
            f"opposite signs bypassed invalid high zero: {descriptor_a}, {descriptor_b}"
        )
    assert m.read_byte(45, 8191) == (0, 0x33)
    assert m.read_byte(45, 8192) == (0, 0x00)
    assert m.release(45) == (0, 2), "fragmented owner cleanup"
    # Native case 258: reusing a descriptor after fragmented-owner release
    # must fail closed even if its canonical magnitude was valid before release.
    # The host oracle decodes directly from the revoked lease table and checks
    # every SRAM bank, tag, and operand snapshot for immutability.
    assert compare_read_only(m, (45, 0, 8192), (45, 0, 8192)) == 3, (
        "released fragmented owner must invalidate both aliased operands"
    )
    # Native case 259: revoked fragmented A with independently valid, live B.
    # Python int.from_bytes verifies the live peer before the fail-closed
    # comparison. compare_read_only snapshots every SRAM bank and lease tag.
    assert reference_integer(m, 46, 0, 8192) > 0, "live peer must be canonical"
    assert compare_read_only(m, (45, 0, 8192), (46, 0, 8192)) == 3, (
        "released fragmented A must be invalid even against a live B"
    )
    # Native case 260: reverse the roles; only B is a revoked owner.
    # Independently decode live A using Python's int.from_bytes oracle.
    assert reference_integer(m, 46, 0, 8192) > 0, "live A must be canonical"
    assert compare_read_only(m, (46, 0, 8192), (45, 0, 8192)) == 3, (
        "revoked fragmented B must be invalid against a valid live A"
    )
    # Bank-edge read-only sentinels mirrored from ROM cases 203..210.
    assert m.read_byte(46, 8191) == (0, 0x33), "A bank-end sentinel changed"
    assert m.read_byte(42, 8191) == (0, 0x00), "B bank-end sentinel changed"
    assert m.read_byte(46, 8192) == (0, 0x01), "A next-bank sentinel changed"
    # Host-only case 261: owners independently released, without rewriting a
    # descriptor. Host also checks the reverse operand orientation.
    assert m.release(46) == (0, 2), "live peer lease must be released"
    assert compare_read_only(m, (46, 0, 8192), (45, 0, 8192)) == 3, (
        "two independently revoked owners must fail closed"
    )
    assert compare_read_only(m, (45, 0, 8192), (46, 0, 8192)) == 3, (
        "two revoked owners, reversed, must fail closed"
    )
    check_owner_id_high_boundary()
    check_dual_invalid_owner_cartesian()
    check_owner_id_fragmented_high_boundary()
    check_native_cases262_to277_oracle()
    from test_sm83_case191_202_oracle import check_native191_202_fixtures
    check_native191_202_fixtures(compare_read_only)
    from test_sm83_case203_210_oracle import check_native203_210_fixtures
    check_native203_210_fixtures(compare_read_only)
    from test_sm83_case211_220_oracle import check_native211_220_fixtures
    check_native211_220_fixtures(compare_read_only)
    from test_sm83_case221_231_oracle import check_native221_231_fixtures
    check_native221_231_fixtures(compare_read_only)
    from test_sm83_case232_239_oracle import check_native232_239_fixtures
    check_native232_239_fixtures(compare_read_only)
    from test_sm83_case240_247_oracle import check_native240_247_fixtures
    check_native240_247_fixtures(compare_read_only)
    print("HOST_OWNER_SIGNED_CMP_READ_ONLY=PASS success=1 invalid_sign=1 invalid_owner=1 invalid_length=1 invalid_B=6 negative_zero_B=1 invalid_owner_zero_B=1 boundary_sentinels=3 mixed_nonzero_signs=2 zero_orderings=2 zero_equality_stale=1 same_owner_alias=36 same_owner_fragmented_alias=6 same_owner_fragmented_noncanonical=2 same_owner_fragmented_mixed_sign_invalid=4 case_id_16bit_oracle=2 stale_fragmented_after_release=1 stale_fragmented_with_live_peer=1 stale_fragmented_as_B_with_live_A=1 both_revoked_distinct_owners=2 same_owner_capacity_edge=2 same_owner_mixed_sign_boundary=4 same_owner_mixed_sign_equal_length=2 same_owner_boundary=4 same_owner_negative_boundary=2 same_owner_negative_equal_boundary=2 same_owner_noncanonical=4 same_owner_full_capacity_noncanonical=2 same_owner_zero=5 same_owner_negative_zero=2 same_owner_overcapacity=2 same_owner_full_capacity=4 same_owner_full_capacity_equal=2 payload_and_tags=IMMUTABLE")
    print(f"HOST_OWNER_SIGNED_CMP_REFERENCE=PASS randomized_cases={checks} canonical=YES fragmented=YES zero_sign=YES owner_release=YES")
    print("NOT_A_NATIVE_ROM_VERIFICATION=YES")


if __name__ == "__main__":
    main()
