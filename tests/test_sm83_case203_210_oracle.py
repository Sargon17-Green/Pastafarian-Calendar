#!/usr/bin/env python3
"""Source-derived independent Python-integer/lease/SRAM checks for Native 203-210.

These are eight distinct comparison checkpoints, not execution of SM83 code.
At entry 203, owner 45 has been released (banks 5 and 7 scrubbed);
owners 42 and 46 remain live. The fixture reconstructs only this state,
not the unrelated earlier scratch registers or MBC5 mapping.
"""
from __future__ import annotations

from test_sram_owner_model import OwnedBanks, SIZE


def check_native203_210_fixtures(compare_read_only):
    m = OwnedBanks()
    assert m.alloc(41, 3) == (0, (3, 4, 5))
    assert m.alloc(42, 1) == (0, (6,))
    assert m.release(41) == (0, 3)
    assert m.alloc(43, 1) == (0, (3,))
    assert m.alloc(44, 1) == (0, (4,))
    assert m.alloc(45, 2) == (0, (5, 7))
    assert m.alloc(46, 2) == (0, (8, 9))
    assert m.write_byte(46, SIZE, 1) == 0  # case 198's surviving top byte
    assert m.release(45) == (0, 2)
    assert m.tags[5] == m.tags[7] == 0
    assert m.tags[6] == 44
    assert m.tags[8] == m.tags[9] == 48
    assert not any(m.data[5]) and not any(m.data[7])

    # Native case 203 writes the live canonical one-byte A and B.
    assert m.write_byte(46, 0, 0x7f) == 0
    assert m.write_byte(42, 0, 1) == 0
    # Owner 42's second byte remains zero; case 210 relies on this.
    assert m.data[6][1] == 0

    # (case ID, scenario, A descriptor, B descriptor, Native expected code).
    # Each descriptor is (owner, sign, logical byte length).
    # The expectation is checked by a Python integer oracle, not adopted as truth.
    fixtures = (
        (203, "127-above-1", (46, 0, 1), (42, 0, 1), 1),
        (204, "invalid-sign-A", (46, 2, 1), (42, 0, 1), 3),
        (205, "invalid-owner-A", (0, 0, 1), (42, 0, 1), 3),
        (206, "A-over-two-bank-capacity", (46, 0, 2 * SIZE + 1), (42, 0, 1), 3),
        (207, "invalid-sign-B", (46, 0, 1), (42, 2, 1), 3),
        (208, "revoked-owner-B", (46, 0, 1), (45, 0, 1), 3),
        (209, "B-over-one-bank-capacity", (46, 0, 1), (42, 0, SIZE + 1), 3),
        (210, "B-noncanonical-high-zero", (46, 0, 1), (42, 0, 2), 3),
    )
    assert tuple(item[0] for item in fixtures) == tuple(range(203, 211))
    sentinels = ((5, 0, 0), (7, 0, 0), (6, 0, 1),
                 (6, 1, 0), (8, 0, 0x7f), (9, 0, 1))
    assert len(m.tags) == 16 and all(len(bank) == SIZE for bank in m.data)

    def descriptor_bytes(desc):
        owner, sign, length = desc
        assert 0 <= owner <= 255 and 0 <= sign <= 255
        assert 0 <= length <= 0xffffff
        return bytes((owner, sign)) + length.to_bytes(3, "little")

    for case, scenario, a, b, expected in fixtures:
        encoded_before = descriptor_bytes(a) + descriptor_bytes(b)
        assert len(encoded_before) == 10
        tags_before = bytes(m.tags)
        sram_before = tuple(bytes(bank) for bank in m.data)
        for bank, offset, value in sentinels:
            assert m.data[bank][offset] == value, (
                case, scenario, "pre SRAM sentinel", bank, offset)
        # Independent read-only reference uses Python arbitrary-precision ints.
        actual = compare_read_only(m, a, b)
        assert actual == expected, (
            case, scenario, "Python integer / source expectation mismatch",
            actual, expected)
        assert encoded_before == descriptor_bytes(a) + descriptor_bytes(b), (
            case, "descriptor changed")
        assert bytes(m.tags) == tags_before, (case, "lease tags mutated")
        assert tuple(bytes(bank) for bank in m.data) == sram_before, (
            case, "SRAM modified")
        for bank, offset, value in sentinels:
            assert m.data[bank][offset] == value, (
                case, scenario, "post SRAM sentinel", bank, offset)

    print(
        "HOST_NATIVE203_210_INDEPENDENT_FIXTURES=PASS cases=8 comparisons=8 "
        "descriptor_bytes=10 lease_tags=16 SRAM=FULL_SNAPSHOT "
        "revoked_owner=45 bank_sentinels=5,6,7,8,9 not_native=YES",
        flush=True,
    )
