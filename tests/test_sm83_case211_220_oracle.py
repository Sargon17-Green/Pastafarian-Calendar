#!/usr/bin/env python3
"""Source-derived Host parity for the ten Native SM83 comparisons 211..220.

No SM83 instructions execute here. Expected codes from the ROM source are
checked independently against Python signed integers reconstructed from
physical leased SRAM; each comparison is read-only across all SRAM and tags.
"""
from __future__ import annotations

from test_sram_owner_model import OwnedBanks, SIZE


def check_native211_220_fixtures(compare_read_only):
    m = OwnedBanks()
    # Reconstruct the actual lease and payload state immediately after case 210.
    assert m.alloc(41, 3) == (0, (3, 4, 5))
    assert m.alloc(42, 1) == (0, (6,))
    assert m.release(41) == (0, 3)
    assert m.alloc(43, 1) == (0, (3,))
    assert m.alloc(44, 1) == (0, (4,))
    assert m.alloc(45, 2) == (0, (5, 7))
    assert m.alloc(46, 2) == (0, (8, 9))
    assert m.write_byte(46, SIZE, 1) == 0
    assert m.release(45) == (0, 2)
    assert m.write_byte(46, 0, 0x7f) == 0
    assert m.write_byte(42, 0, 1) == 0

    assert len(m.tags) == 16 and len(m.data) == 16
    assert all(len(bank) == SIZE for bank in m.data)
    assert (m.tags[5], m.tags[6], m.tags[7], m.tags[8], m.tags[9]) == (
        0, 44, 0, 48, 48)
    assert not any(m.data[5]) and not any(m.data[7])

    # ID, ROM scenario, descriptor A, descriptor B, ROM expected result.
    # Each descriptor is owner ID, sign (0/+ or 1/-), length in bytes.
    cases = (
        (211, "negative-A-positive-B", (46, 1, 1), (42, 0, 1), 2),
        (212, "positive-A-negative-B", (46, 0, 1), (42, 1, 1), 1),
        (213, "negative-zero-B", (46, 0, 1), (42, 1, 0), 3),
        (214, "reserved-owner-zero-B", (46, 0, 1), (0, 0, 0), 3),
        (215, "positive-A-above-stale-zero-B", (46, 0, 1), (42, 0, 0), 1),
        (216, "stale-zero-A-above-negative-B", (42, 0, 0), (46, 1, 1), 1),
        (217, "two-zeros-with-stale-bytes", (42, 0, 0), (46, 0, 0), 0),
        (218, "same-owner-positive-negative", (46, 0, 1), (46, 1, 1), 1),
        (219, "same-owner-negative-positive", (46, 1, 1), (46, 0, 1), 2),
        (220, "same-owner-negative-equality", (46, 1, 1), (46, 1, 1), 0),
    )
    assert tuple(entry[0] for entry in cases) == tuple(range(211, 221))
    # Independent signed-value expectations, not the result of the SM83 routine.
    expected_values = (
        (-127, 1), (127, -1), None, None, (127, 0),
        (0, -127), (0, 0), (127, -127), (-127, 127), (-127, -127),
    )
    sentinels = (
        (5, 0, 0), (7, 0, 0), (6, 0, 1), (6, 1, 0),
        (8, 0, 0x7f), (8, 1, 0), (9, 0, 1),
    )

    def encode(desc):
        owner, sign, length = desc
        assert 0 <= owner <= 255 and 0 <= sign <= 255
        assert 0 <= length <= 0xffffff
        return bytes((owner, sign)) + length.to_bytes(3, "little")

    def physical_python_integer(desc):
        """Independent fixture decoder: explicit physical-bank maps, not ROM."""
        owner, sign, length = desc
        if sign not in (0, 1):
            raise ValueError("sign")
        physical = {42: (6,), 46: (8, 9)}.get(owner)
        if physical is None or any(m.tags[b] != owner + 2 for b in physical):
            raise ValueError("owner")
        if length < 0 or length > len(physical) * SIZE:
            raise ValueError("capacity")
        if length == 0:
            if sign:
                raise ValueError("negative zero")
            return 0
        data = b"".join(bytes(m.data[b]) for b in physical)[:length]
        if data[-1] == 0:
            raise ValueError("noncanonical")
        magnitude = int.from_bytes(data, "little", signed=False)
        return -magnitude if sign else magnitude

    for (case, scenario, a, b, rom_expected), expected_pair in zip(
        cases, expected_values
    ):
        descriptor_snapshot = encode(a) + encode(b)
        assert len(descriptor_snapshot) == 10
        tags_snapshot = bytes(m.tags)
        sram_snapshot = tuple(bytes(bank) for bank in m.data)
        for bank, offset, byte in sentinels:
            assert m.data[bank][offset] == byte, (
                case, scenario, "pre sentinel", bank, offset)
        try:
            values = (physical_python_integer(a), physical_python_integer(b))
        except ValueError:
            values = None
        assert values == expected_pair, (case, scenario, "signed Python integers", values)
        oracle_code = (
            3 if values is None else
            1 if values[0] > values[1] else
            2 if values[0] < values[1] else 0
        )
        assert oracle_code == rom_expected, (
            case, scenario, "independent oracle versus ROM expected",
            oracle_code, rom_expected)
        assert compare_read_only(m, a, b) == oracle_code, (
            case, scenario, "Host comparator versus independent oracle")
        assert encode(a) + encode(b) == descriptor_snapshot, (case, "descriptor changed")
        assert bytes(m.tags) == tags_snapshot, (case, "lease tags changed")
        assert tuple(bytes(bank) for bank in m.data) == sram_snapshot, (
            case, "physical SRAM changed")
        for bank, offset, byte in sentinels:
            assert m.data[bank][offset] == byte, (
                case, scenario, "post sentinel", bank, offset)

    print(
        "HOST_NATIVE211_220_INDEPENDENT_FIXTURES=PASS cases=10 comparisons=10 "
        "descriptor_bytes=10 lease_tags=16 SRAM=FULL_SNAPSHOT "
        "physical_sentinels=5,6,7,8,9 revoked_owner45_scrub=YES "
        "signed_integer_oracle=YES not_native=YES",
        flush=True,
    )
