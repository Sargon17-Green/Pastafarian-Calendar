#!/usr/bin/env python3
"""Independent physical-SRAM Python-integer fixtures for Native 232..239.

Host-side parity, NOT execution of SM83 machine code. Descriptors and expected
status codes are source-transcribed; mathematical ordering is independently
computed from physical lease tags and raw SRAM bytes using Python integers.
"""
from __future__ import annotations

from test_sram_owner_model import OwnedBanks, SIZE


def check_native232_239_fixtures(compare_read_only):
    m = OwnedBanks()

    # Recreate the exact leases and payload at entry to Native case 232.
    # Owner 45 was revoked, while owner 46 holds consecutive banks 8 and 9.
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
    assert m.tags[5] == m.tags[7] == 0
    assert m.tags[6] == 44
    assert m.tags[8] == m.tags[9] == 48
    assert not any(m.data[5]) and not any(m.data[7])
    assert m.data[8][0] == 0x7f
    assert m.data[8][SIZE - 1] == 0x33
    assert m.data[9][0] == 0x01

    # Read by inspecting the physical tag table, not the model's read_byte,
    # bank-selection helper, or signed-comparison implementation.
    physical = tuple(i for i in range(3, 16) if m.tags[i] == 46 + 2)
    assert physical == (8, 9)
    raw = b"".join(bytes(m.data[i]) for i in physical)
    short = int.from_bytes(raw[:SIZE], byteorder="little", signed=False)
    long = int.from_bytes(raw[:SIZE + 1], byteorder="little", signed=False)
    assert raw[SIZE - 1] == 0x33 and raw[SIZE] == 0x01
    assert short > 0 and long > short
    assert short.bit_length() > 8 * (SIZE - 1)
    assert long.bit_length() > 8 * SIZE

    # (Native ID, A(owner, sign, length), B(...), ROM assertion).
    cases = (
        (232, (46, 1, SIZE),     (46, 1, SIZE + 1), 1),
        (233, (46, 1, SIZE + 1), (46, 1, SIZE),     2),
        (234, (46, 1, SIZE),     (46, 1, SIZE),     0),
        (235, (46, 1, SIZE + 1), (46, 1, SIZE + 1), 0),
        (236, (46, 0, SIZE),     (46, 1, SIZE + 1), 1),
        (237, (46, 1, SIZE + 1), (46, 0, SIZE),     2),
        (238, (46, 0, SIZE),     (46, 1, SIZE),     1),
        (239, (46, 1, SIZE + 1), (46, 0, SIZE + 1), 2),
    )
    assert len(cases) == 8
    assert tuple(i for i, *_ in cases) == tuple(range(232, 240))

    def encode_descriptor(desc):
        owner, sign, length = desc
        assert 0 <= owner <= 255 and sign in (0, 1)
        assert 0 <= length <= 0xffffff
        return bytes((owner, sign)) + length.to_bytes(3, "little")

    def independent_integer(desc):
        owner, sign, length = desc
        if not 1 <= owner <= 253 or sign not in (0, 1):
            raise ValueError("metadata")
        banks = tuple(i for i in range(3, 16) if m.tags[i] == owner + 2)
        if not banks or not 0 <= length <= SIZE * len(banks):
            raise ValueError("capacity")
        if not length:
            if sign:
                raise ValueError("negative zero")
            return 0
        payload = b"".join(bytes(m.data[i]) for i in banks)[:length]
        if payload[-1] == 0:
            raise ValueError("noncanonical")
        unsigned = int.from_bytes(payload, "little", signed=False)
        return -unsigned if sign else unsigned

    sentinels = (
        (5, 0, 0), (5, SIZE - 1, 0),
        (7, 0, 0), (7, SIZE - 1, 0),
        (6, 0, 1), (8, 0, 0x7f), (8, SIZE - 1, 0x33),
        (9, 0, 0x01), (9, 1, 0),
    )

    for case_id, operand_a, operand_b, expected_rom in cases:
        descriptors = encode_descriptor(operand_a) + encode_descriptor(operand_b)
        assert len(descriptors) == 10
        tags_before = bytes(m.tags)
        all_sram_before = tuple(bytes(bank) for bank in m.data)
        for bank, offset, expected_byte in sentinels:
            assert m.data[bank][offset] == expected_byte, (
                case_id, "pre-SRAM-sentinel", bank, offset
            )

        # Separate mathematical oracle: reconstruct exact signed integers
        # without using compare(), compare_read_only() or Native statuses.
        a_value = independent_integer(operand_a)
        b_value = independent_integer(operand_b)
        assert abs(a_value) in (short, long)
        assert abs(b_value) in (short, long)
        assert (a_value < 0) == bool(operand_a[1])
        assert (b_value < 0) == bool(operand_b[1])
        expected_python = (a_value > b_value) + 2 * (a_value < b_value)
        assert expected_python == expected_rom, (
            case_id, "source expectation vs independent integer oracle",
            a_value, b_value, expected_python, expected_rom
        )
        assert compare_read_only(m, operand_a, operand_b) == expected_python, (
            case_id, "host comparator differs from independent oracle"
        )

        assert encode_descriptor(operand_a) + encode_descriptor(operand_b) == descriptors
        assert bytes(m.tags) == tags_before
        assert tuple(bytes(bank) for bank in m.data) == all_sram_before
        for bank, offset, expected_byte in sentinels:
            assert m.data[bank][offset] == expected_byte, (
                case_id, "post-SRAM-sentinel", bank, offset
            )

    print(
        "HOST_NATIVE232_239_INDEPENDENT_FIXTURES=PASS cases=8 comparisons=8 "
        "descriptor_bytes=10 lease_tags=16 SRAM=FULL_SNAPSHOT "
        "physical_sentinels=5,6,7,8,9 revoked_owner45_scrub=YES "
        "signed_integer_oracle=YES two_bank_boundary=8192,8193 "
        "shared_owner=46 not_native=YES",
        flush=True,
    )
