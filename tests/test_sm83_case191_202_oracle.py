#!/usr/bin/env python3
"""Independent Host/lease/SRAM fixture parity for Native SM83 cases 191..202.

This exercises Python integer semantics, not the SM83 ROM. Exactly 13 compare
checkpoints represent 12 Native case IDs (198 compares before/after release).
No Native PASS or complete 191..261 parity is implied by this fixture set.
"""
from __future__ import annotations

from test_sram_owner_model import OwnedBanks, SIZE


def check_native191_202_fixtures(compare_read_only):
    """Check source-derived descriptors and every byte of SRAM at each compare."""
    m = OwnedBanks()
    assert m.alloc(41, 3) == (0, (3, 4, 5))
    assert m.alloc(42, 1) == (0, (6,))
    assert m.release(41) == (0, 3)
    assert m.alloc(43, 1) == (0, (3,))
    assert m.alloc(44, 1) == (0, (4,))
    assert m.alloc(45, 2) == (0, (5, 7))
    assert m.alloc(46, 2) == (0, (8, 9))
    assert m.tags[5] == m.tags[7] == 47
    assert m.tags[8] == m.tags[9] == 48
    assert m.tags[6] == 44

    case_ids = []
    comparisons = 0

    def check(case, phase, a, b, expected, physical_sentinels=()):
        nonlocal comparisons
        # The actual 10-byte descriptor is owner+sign+little-endian 24-bit length.
        def serialize(desc):
            owner, sign, length = desc
            assert 0 <= owner <= 255 and 0 <= sign <= 255
            assert 0 <= length <= 0xFFFFFF
            return bytes((owner, sign)) + length.to_bytes(3, "little")

        descriptors = serialize(a) + serialize(b)
        assert len(descriptors) == 10
        tags_before = tuple(m.tags)
        sram_before = tuple(bytes(bank) for bank in m.data)
        for physical_bank, offset, byte in physical_sentinels:
            assert m.data[physical_bank][offset] == byte, (
                f"case {case} {phase}: pre-comparison bank {physical_bank}, offset {offset}")
        result = compare_read_only(m, a, b)
        assert result == expected, (
            f"case {case} {phase}: independent integer result {result}, source expects {expected}")
        assert descriptors == serialize(a) + serialize(b), f"case {case}: descriptor changed"
        assert tuple(m.tags) == tags_before, f"case {case}: lease tags changed"
        assert tuple(bytes(bank) for bank in m.data) == sram_before, (
            f"case {case}: SRAM payload changed")
        for physical_bank, offset, byte in physical_sentinels:
            assert m.data[physical_bank][offset] == byte, (
                f"case {case} {phase}: post-comparison bank {physical_bank}, offset {offset}")
        case_ids.append(case)
        comparisons += 1

    # Cases 191..194: separate live owners, bank boundary and negative zero.
    check(191, "zeros", (45, 0, 0), (46, 0, 0), 0,
          ((5, 0, 0), (7, 0, 0), (8, 0, 0), (9, 0, 0)))
    assert m.write_byte(45, SIZE, 1) == 0
    assert m.write_byte(46, SIZE, 2) == 0
    check(192, "fragmented-high-byte", (45, 0, SIZE + 1), (46, 0, SIZE + 1), 2,
          ((7, 0, 1), (9, 0, 2), (6, 0, 0)))
    check(193, "both-negative", (45, 1, SIZE + 1), (46, 1, SIZE + 1), 1,
          ((7, 0, 1), (9, 0, 2)))
    check(194, "negative-zero", (45, 1, 0), (46, 1, SIZE + 1), 3,
          ((7, 0, 1), (9, 0, 2)))

    # Cases 195..196: noncanonical magnitude and over-capacity length.
    assert m.write_byte(46, SIZE, 0) == 0
    check(195, "high-zero", (45, 0, SIZE + 1), (46, 0, SIZE + 1), 3,
          ((7, 0, 1), (9, 0, 0)))
    assert m.write_byte(46, SIZE, 2) == 0
    check(196, "over-capacity", (45, 0, SIZE + 1), (46, 0, 2 * SIZE + 1), 3,
          ((7, 0, 1), (9, 0, 2)))

    # Cases 197..198: equal top bytes, compare physical previous-bank boundary.
    assert m.write_byte(46, SIZE, 1) == 0
    assert m.write_byte(45, SIZE - 1, 0x33) == 0
    assert m.write_byte(46, SIZE - 1, 0x34) == 0
    check(197, "equal-high-byte-lower-difference",
          (45, 0, SIZE + 1), (46, 0, SIZE + 1), 2,
          ((5, SIZE - 1, 0x33), (8, SIZE - 1, 0x34), (7, 0, 1), (9, 0, 1)))
    assert m.write_byte(46, SIZE - 1, 0x33) == 0
    check(198, "before-release", (45, 0, SIZE + 1), (46, 0, SIZE + 1), 0,
          ((5, SIZE - 1, 0x33), (8, SIZE - 1, 0x33), (7, 0, 1), (9, 0, 1)))
    assert m.release(45) == (0, 2)
    assert m.tags[5] == m.tags[7] == 0
    assert m.data[5] == bytearray(SIZE) and m.data[7] == bytearray(SIZE)
    check(198, "after-release", (45, 0, SIZE + 1), (46, 0, SIZE + 1), 3,
          ((5, SIZE - 1, 0), (7, 0, 0), (8, SIZE - 1, 0x33), (9, 0, 1)))

    # Cases 199..202: canonical zero, reversed negative ordering, invalid sign/ID.
    check(199, "zero-versus-positive", (42, 0, 0), (46, 0, SIZE + 1), 2,
          ((6, 0, 0), (9, 0, 1)))
    check(200, "negative-versus-zero", (46, 1, SIZE + 1), (42, 0, 0), 2,
          ((9, 0, 1), (6, 0, 0)))
    check(201, "invalid-sign", (46, 2, SIZE + 1), (42, 0, 0), 3,
          ((9, 0, 1), (6, 0, 0)))
    check(202, "invalid-owner-zero", (0, 0, 0), (42, 0, 0), 3,
          ((9, 0, 1), (6, 0, 0)))
    assert comparisons == 13 and len(set(case_ids)) == 12
    assert case_ids == list(range(191, 199)) + [198] + list(range(199, 203))
    print(
        "HOST_NATIVE191_202_INDEPENDENT_FIXTURES=PASS cases=12 comparisons=13 "
        "descriptor_bytes=10 lease_tags=16 SRAM=FULL_SNAPSHOT "
        "fragmented_banks=5,7 revoked_scrub=YES not_native=YES",
        flush=True,
    )
