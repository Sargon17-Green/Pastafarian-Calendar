#!/usr/bin/env python3
"""Independent physical-SRAM Python-integer fixtures for Native cases 221..231.

This is Host parity, NOT SM83 code execution. Input descriptors and ROM status
expectations are transcribed from the numbered Native assertions. Mathematical
values and invalidity reasons are obtained independently from the lease tags,
actual physical SRAM bytes, canonical length, and Python signed integers.
"""
from __future__ import annotations

from test_sram_owner_model import OwnedBanks, SIZE


def check_native221_231_fixtures(compare_read_only):
    m = OwnedBanks()
    # Rebuild Native lease topology, not its comparator or result logic.
    assert m.alloc(41, 3) == (0, (3, 4, 5))
    assert m.alloc(42, 1) == (0, (6,))
    assert m.release(41) == (0, 3)
    assert m.alloc(43, 1) == (0, (3,))
    assert m.alloc(44, 1) == (0, (4,))
    assert m.alloc(45, 2) == (0, (5, 7))
    assert m.alloc(46, 2) == (0, (8, 9))

    # Native 192/197/198 wrote the two-bank edge (final value at 8191=$33).
    # Native 203 wrote +127, and the surviving high byte at 8192 is $01.
    assert m.write_byte(46, SIZE, 1) == 0
    assert m.write_byte(46, SIZE - 1, 0x33) == 0
    assert m.release(45) == (0, 2)
    assert m.write_byte(46, 0, 0x7f) == 0
    assert m.write_byte(42, 0, 1) == 0

    assert len(m.tags) == len(m.data) == 16
    assert all(len(bank) == SIZE for bank in m.data)
    assert (m.tags[5], m.tags[6], m.tags[7], m.tags[8], m.tags[9]) == (
        0, 44, 0, 48, 48
    )
    assert not any(m.data[5]) and not any(m.data[7])
    assert bytes(m.data[8][0:2]) == bytes((0x7f, 0))
    assert m.data[8][SIZE - 1] == 0x33
    assert m.data[9][0] == 1

    # (case ID, source scenario, descriptor A, descriptor B, ROM expected).
    # Each descriptor encodes owner byte, sign byte, little-endian u24 length.
    cases = (
        (221, "shared-owner-positive-zero-below-127", (46, 0, 0), (46, 0, 1), 2),
        (222, "negative-127-below-shared-zero", (46, 1, 1), (46, 0, 0), 2),
        (223, "shared-owner-two-canonical-zeros", (46, 0, 0), (46, 0, 0), 0),
        (224, "negative-zero-A", (46, 1, 0), (46, 0, 1), 3),
        (225, "negative-zero-B", (46, 0, 1), (46, 1, 0), 3),
        (226, "overcapacity-B", (46, 0, 1), (46, 0, 2 * SIZE + 1), 3),
        (227, "overcapacity-A", (46, 0, 2 * SIZE + 1), (46, 0, 1), 3),
        (228, "noncanonical-high-zero-B", (46, 0, 1), (46, 0, 2), 3),
        (229, "noncanonical-high-zero-A", (46, 0, 2), (46, 0, 1), 3),
        (230, "two-bank-boundary-short-below-long",
         (46, 0, SIZE), (46, 0, SIZE + 1), 2),
        (231, "two-bank-boundary-long-above-short",
         (46, 0, SIZE + 1), (46, 0, SIZE), 1),
    )
    assert tuple(case for case, *_ in cases) == tuple(range(221, 232))
    assert len(cases) == 11

    # Expected human-readable failure classification is independent of
    # Native's single INVALID=3 status, and guards against a vacuous oracle.
    invalid_reasons = {
        224: "negative zero", 225: "negative zero",
        226: "capacity", 227: "capacity",
        228: "noncanonical", 229: "noncanonical",
    }
    simple_integer_pairs = {221: (0, 127), 222: (-127, 0), 223: (0, 0)}
    sentinels = (
        (5, 0, 0), (7, 0, 0), (6, 0, 1), (6, 1, 0),
        (8, 0, 0x7f), (8, 1, 0), (8, SIZE - 1, 0x33),
        (9, 0, 1),
    )

    def encode(desc):
        owner, sign, length = desc
        assert 0 <= owner <= 255 and 0 <= sign <= 255
        assert 0 <= length <= 0xffffff
        return bytes((owner, sign)) + length.to_bytes(3, "little")

    def physical_integer(desc):
        owner, sign, length = desc
        if sign not in (0, 1):
            raise ValueError("sign")
        if not 1 <= owner <= 253:
            raise ValueError("owner")
        # Discover bank topology by inspecting physical lease tags, not
        # by using the implementation's SRAM bank-selection function.
        physical = tuple(
            bank for bank in range(3, 16) if m.tags[bank] == owner + 2
        )
        if not physical:
            raise ValueError("revoked")
        if length < 0 or length > len(physical) * SIZE:
            raise ValueError("capacity")
        if length == 0:
            if sign:
                raise ValueError("negative zero")
            return 0
        raw = b"".join(bytes(m.data[bank]) for bank in physical)[:length]
        if raw[-1] == 0:
            raise ValueError("noncanonical")
        magnitude = int.from_bytes(raw, byteorder="little", signed=False)
        return -magnitude if sign else magnitude

    boundary_short = int.from_bytes(bytes(m.data[8]), "little")
    boundary_long = int.from_bytes(
        bytes(m.data[8]) + bytes((m.data[9][0],)), "little"
    )
    assert 0 < boundary_short < boundary_long
    assert boundary_short.bit_length() > 8 * (SIZE - 1)
    assert boundary_long.bit_length() > 8 * SIZE

    for case, scenario, a, b, rom_expected in cases:
        descriptor_before = encode(a) + encode(b)
        assert len(descriptor_before) == 10
        tags_before = bytes(m.tags)
        sram_before = tuple(bytes(bank) for bank in m.data)
        for bank, offset, byte in sentinels:
            assert m.data[bank][offset] == byte, (
                case, scenario, "pre SRAM sentinel", bank, offset
            )

        values = []
        failures = []
        for desc in (a, b):
            try:
                values.append(physical_integer(desc))
            except ValueError as exc:
                failures.append(str(exc))
                values.append(None)

        if case in invalid_reasons:
            assert failures == [invalid_reasons[case]], (
                case, scenario, "invalidity reason", failures
            )
            independent_code = 3
        else:
            assert not failures, (case, scenario, "unexpected invalid", failures)
            va, vb = values
            if case in simple_integer_pairs:
                assert (va, vb) == simple_integer_pairs[case], (
                    case, scenario, "signed integer values", va, vb
                )
            if case in (230, 231):
                assert {va, vb} == {boundary_short, boundary_long}
            independent_code = 1 if va > vb else 2 if va < vb else 0

        assert independent_code == rom_expected, (
            case, scenario, "Python-integer oracle differs from Native assertion",
            independent_code, rom_expected
        )
        assert compare_read_only(m, a, b) == independent_code, (
            case, scenario, "Host comparator differs from Python oracle"
        )
        assert encode(a) + encode(b) == descriptor_before
        assert bytes(m.tags) == tags_before
        assert tuple(bytes(bank) for bank in m.data) == sram_before
        for bank, offset, byte in sentinels:
            assert m.data[bank][offset] == byte, (
                case, scenario, "post SRAM sentinel", bank, offset
            )

    print(
        "HOST_NATIVE221_231_INDEPENDENT_FIXTURES=PASS cases=11 comparisons=11 "
        "descriptor_bytes=10 lease_tags=16 SRAM=FULL_SNAPSHOT "
        "physical_sentinels=5,6,7,8,9 revoked_owner45_scrub=YES "
        "signed_integer_oracle=YES invalidity_reasons=CHECKED "
        "two_bank_boundary=8192,8193 not_native=YES",
        flush=True,
    )
