#!/usr/bin/env python3
"""Independent Host-side integer/lease/SRAM parity for Native 240..247.

The numbered operands and ROM assertions are source-transcribed from
src/tests/owner_signed_cmp_test.asm. The mathematical oracle is computed from
lease-tag-selected physical bytes and Python integers, not SM83 execution,
the Host comparator, or the source's expected result.
"""
from __future__ import annotations

from test_sram_owner_model import OwnedBanks, SIZE


def check_native240_247_fixtures(compare_read_only):
    m = OwnedBanks()

    # Reconstruct the leases and surviving physical bytes on entry to 240.
    assert m.alloc(41, 3) == (0, (3, 4, 5))
    assert m.alloc(42, 1) == (0, (6,))
    assert m.release(41) == (0, 3)
    assert m.alloc(43, 1) == (0, (3,))
    assert m.alloc(44, 1) == (0, (4,))
    assert m.alloc(45, 2) == (0, (5, 7))
    assert m.alloc(46, 2) == (0, (8, 9))
    assert m.write_byte(46, SIZE, 0x01) == 0
    assert m.write_byte(46, SIZE - 1, 0x33) == 0
    assert m.release(45) == (0, 2)
    assert m.write_byte(46, 0, 0x7f) == 0
    assert m.write_byte(42, 0, 0x01) == 0

    assert len(m.tags) == len(m.data) == 16
    assert all(len(bank) == SIZE for bank in m.data)
    assert m.tags[:3] == [2] * 3
    assert m.tags[5] == m.tags[7] == 0
    assert m.tags[6] == 44
    assert m.tags[8] == m.tags[9] == 48
    assert all(not any(m.data[bank]) for bank in (5, 7))
    assert m.data[8][0] == 0x7f
    assert m.data[8][-1] == 0x33
    assert m.data[9][0] == 0x01

    # Native source keeps a single shared owner 46. Logical bytes 16382
    # and 16383 are physically bank 9 indices 8190 and 8191.
    cap = 2 * SIZE
    short_length = cap - 1
    cases = (
        (240, (46, 0, cap),          (46, 1, cap),          1),
        (241, (46, 1, cap),          (46, 0, cap),          2),
        (242, (46, 0, cap),          (46, 0, cap),          0),
        (243, (46, 1, cap),          (46, 1, cap),          0),
        (244, (46, 0, short_length), (46, 0, cap),          2),
        (245, (46, 1, short_length), (46, 1, cap),          1),
        (246, (46, 0, short_length), (46, 0, cap),          3),
        (247, (46, 0, cap),          (46, 0, short_length), 3),
    )
    assert cap == 16384 and short_length == 16383
    assert len(cases) == 8
    assert tuple(case_id for case_id, *_ in cases) == tuple(range(240, 248))

    def descriptor_bytes(desc):
        owner, sign, length = desc
        assert 0 <= owner <= 255 and 0 <= sign <= 255
        assert 0 <= length <= 0xffffff
        return bytes((owner, sign)) + length.to_bytes(3, "little")

    def signed_from_physical_lease(desc):
        owner, sign, length = desc
        if not 1 <= owner <= 253:
            raise ValueError("owner")
        if sign not in (0, 1):
            raise ValueError("sign")
        # Select physical banks independently from their lease tags, sorted
        # by bank number. Do not call read_byte, select, or compare().
        physical_banks = tuple(
            bank for bank in range(3, 16) if m.tags[bank] == owner + 2
        )
        if not physical_banks:
            raise ValueError("revoked")
        if not 0 <= length <= len(physical_banks) * SIZE:
            raise ValueError("capacity")
        if length == 0:
            if sign:
                raise ValueError("negative zero")
            return 0
        magnitude_bytes = b"".join(
            bytes(m.data[bank]) for bank in physical_banks
        )[:length]
        if magnitude_bytes[-1] == 0:
            raise ValueError("noncanonical high zero")
        absolute_value = int.from_bytes(
            magnitude_bytes, byteorder="little", signed=False
        )
        return -absolute_value if sign else absolute_value

    for case_id, a, b, expected_native in cases:
        # Source-defined setup changes happen BEFORE comparator snapshots.
        if case_id == 240:
            assert m.write_byte(46, cap - 1, 0x5a) == 0
        if case_id == 244:
            assert m.write_byte(46, cap - 2, 0x3c) == 0
        if case_id == 246:
            assert m.write_byte(46, cap - 1, 0x00) == 0

        banks = tuple(i for i in range(3, 16) if m.tags[i] == 48)
        assert banks == (8, 9), (case_id, "physical bank order", banks)
        assert m.data[8][-1] == 0x33 and m.data[9][0] == 0x01
        assert m.data[8][0] == 0x7f and m.data[6][0] == 0x01
        assert m.data[9][-2] == (0 if case_id < 244 else 0x3c)
        assert m.data[9][-1] == (0 if case_id >= 246 else 0x5a)
        assert all(not any(m.data[i]) for i in (5, 7))
        raw = bytes(m.data[8]) + bytes(m.data[9])
        assert len(raw) == cap
        short_integer = int.from_bytes(raw[:short_length], "little")
        full_integer = int.from_bytes(raw, "little")
        if case_id <= 243:
            assert short_integer > 0 and full_integer > short_integer
            assert raw[-1] == 0x5a
        elif case_id <= 245:
            assert short_integer > 0 and full_integer > short_integer
            assert raw[-2:] == bytes((0x3c, 0x5a))
        else:
            assert short_integer > 0 and full_integer == short_integer
            assert raw[-2:] == bytes((0x3c, 0x00))

        pre_desc = descriptor_bytes(a) + descriptor_bytes(b)
        assert len(pre_desc) == 10
        pre_tags = bytes(m.tags)
        pre_all_sram = tuple(bytes(data) for data in m.data)
        sentinels = (
            (5, 0, 0), (5, SIZE - 1, 0),
            (6, 0, 1),
            (7, 0, 0), (7, SIZE - 1, 0),
            (8, 0, 0x7f), (8, SIZE - 1, 0x33),
            (9, 0, 0x01),
            (9, SIZE - 2, raw[-2]), (9, SIZE - 1, raw[-1]),
        )
        for bank, index, value in sentinels:
            assert m.data[bank][index] == value, (
                case_id, "before", bank, index
            )

        decoded = []
        errors = []
        for desc in (a, b):
            try:
                decoded.append(signed_from_physical_lease(desc))
                errors.append(None)
            except ValueError as exc:
                decoded.append(None)
                errors.append(str(exc))

        if case_id in (246, 247):
            assert errors == (
                [None, "noncanonical high zero"] if case_id == 246
                else ["noncanonical high zero", None]
            ), (case_id, "invalid operand position/reason", errors)
            assert decoded[0 if case_id == 246 else 1] == short_integer
            python_result = 3
        else:
            assert errors == [None, None], (case_id, errors)
            value_a, value_b = decoded
            assert abs(value_a) in (short_integer, full_integer)
            assert abs(value_b) in (short_integer, full_integer)
            assert (value_a < 0) == bool(a[1])
            assert (value_b < 0) == bool(b[1])
            python_result = (value_a > value_b) + 2 * (value_a < value_b)

        assert python_result == expected_native, (
            case_id, "independent Python integers vs source assertion",
            decoded, python_result, expected_native
        )
        assert compare_read_only(m, a, b) == python_result, (
            case_id, "Host comparison vs independent physical-integer oracle"
        )
        assert descriptor_bytes(a) + descriptor_bytes(b) == pre_desc
        assert bytes(m.tags) == pre_tags, (case_id, "lease tag changed")
        assert tuple(bytes(data) for data in m.data) == pre_all_sram, (
            case_id, "comparison changed physical SRAM"
        )
        for bank, index, value in sentinels:
            assert m.data[bank][index] == value, (
                case_id, "after", bank, index
            )

    print(
        "HOST_NATIVE240_247_INDEPENDENT_FIXTURES=PASS cases=8 comparisons=8 "
        "descriptor_bytes=10 lease_tags=16 SRAM=FULL_SNAPSHOT "
        "physical_sentinels=5,6,7,8,9 revoked_owner45_scrub=YES "
        "signed_integer_oracle=YES last_valid_offset=16383 "
        "capacity_lengths=16383,16384 noncanonical_high_zero=2 "
        "invalidity_reasons=CHECKED not_native=YES",
        flush=True,
    )
