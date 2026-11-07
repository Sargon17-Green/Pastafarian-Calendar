#!/usr/bin/env python3
"""Independent physical-SRAM Host oracle for Native cases 248..261.

The descriptors and expected ROM statuses are source-transcribed from
src/tests/owner_signed_cmp_test.asm. Python signed integers, immutable
lease-tag/SRAM snapshots and failure classifications are checked independently.
This is NOT an SM83 emulator execution or proof of new Native coverage.
"""
from __future__ import annotations

from test_sram_owner_model import OwnedBanks, SIZE


def check_native248_261_fixtures(compare_read_only):
    m = OwnedBanks()
    # Recreate the source's lease topology through cases 191..247, without
    # reusing comparison results or calculating expectations from ROM values.
    assert m.alloc(41, 3) == (0, (3, 4, 5))
    assert m.alloc(42, 1) == (0, (6,))
    assert m.release(41) == (0, 3)
    assert m.alloc(43, 1) == (0, (3,))
    assert m.alloc(44, 1) == (0, (4,))
    assert m.alloc(45, 2) == (0, (5, 7))
    assert m.alloc(46, 2) == (0, (8, 9))
    assert m.write_byte(46, SIZE, 1) == 0
    assert m.write_byte(46, SIZE - 1, 0x33) == 0
    assert m.release(45) == (0, 2)
    assert m.write_byte(46, 0, 0x7f) == 0
    assert m.write_byte(42, 0, 1) == 0

    # Source 240/244/246: set full-capacity high byte, penultimate high
    # byte, then zero the full-capacity high byte for noncanonicality.
    cap = 2 * SIZE
    assert m.write_byte(46, cap - 1, 0x5a) == 0
    assert m.write_byte(46, cap - 2, 0x3c) == 0
    assert m.write_byte(46, cap - 1, 0) == 0
    assert m.alloc(45, 2) == (0, (5, 7))
    assert m.write_byte(45, SIZE - 1, 0x33) == 0
    assert m.write_byte(45, SIZE, 1) == 0

    assert len(m.tags) == len(m.data) == 16
    assert all(len(bank) == SIZE for bank in m.data)
    assert (m.tags[3], m.tags[4], m.tags[5], m.tags[6],
            m.tags[7], m.tags[8], m.tags[9]) == (45, 46, 47, 44, 47, 48, 48)
    assert m.data[5][-1] == 0x33 and m.data[7][0] == 1
    assert m.data[6][0] == 1
    assert m.data[8][0] == 0x7f and m.data[8][-1] == 0x33
    assert m.data[9][0] == 1 and m.data[9][-2:] == bytes((0x3c, 0))
    assert tuple(i for i in range(3, 16) if m.tags[i] == 47) == (5, 7)
    assert tuple(i for i in range(3, 16) if m.tags[i] == 48) == (8, 9)

    # Each tuple is one actual compare in the Native source. 252..255 and
    # 259..261 use shared assembly loops, but each is separately asserted.
    # Fields: (case_id, A(owner, sign, length), B(...), ROM asserted result).
    cases = (
        (248, (45, 0, SIZE),     (45, 0, SIZE + 1), 2),
        (249, (45, 0, SIZE + 1), (45, 0, SIZE),     1),
        (250, (45, 1, SIZE),     (45, 1, SIZE + 1), 1),
        (251, (45, 1, SIZE + 1), (45, 1, SIZE),     2),
        (252, (45, 0, SIZE),     (45, 1, SIZE + 1), 3),
        (253, (45, 0, SIZE + 1), (45, 1, SIZE),     3),
        (254, (45, 1, SIZE),     (45, 0, SIZE + 1), 3),
        (255, (45, 1, SIZE + 1), (45, 0, SIZE),     3),
        (256, (45, 0, SIZE),     (45, 0, SIZE + 1), 3),
        (257, (45, 0, SIZE),     (45, 0, SIZE),     0),
        (258, (45, 0, SIZE),     (45, 0, SIZE),     3),
        (259, (45, 0, SIZE),     (46, 0, SIZE),     3),
        (260, (46, 0, SIZE),     (45, 0, SIZE),     3),
        (261, (46, 0, SIZE),     (45, 0, SIZE),     3),
    )
    assert len(cases) == 14
    assert tuple(case_id for case_id, *_ in cases) == tuple(range(248, 262))

    # Invalidity source: high-zero at fragmented logical offset 8192,
    # or physically revoked lease. Distinguish bad A, bad B and both bad.
    reasons = {
        252: (None, "noncanonical high zero"),
        253: ("noncanonical high zero", None),
        254: (None, "noncanonical high zero"),
        255: ("noncanonical high zero", None),
        256: (None, "noncanonical high zero"),
        258: ("revoked", "revoked"),
        259: ("revoked", None),
        260: (None, "revoked"),
        261: ("revoked", "revoked"),
    }
    assert len(reasons) == 9
    assert [case for case, _, _, expected in cases if expected == 3] == list(reasons)

    def encoded(desc):
        owner, sign, length = desc
        assert 0 <= owner <= 255 and sign in (0, 1)
        assert 0 <= length <= 0xffffff
        return bytes((owner, sign)) + length.to_bytes(3, "little")

    def independent_value(desc):
        owner, sign, length = desc
        if not 1 <= owner <= 253:
            raise ValueError("owner")
        if sign not in (0, 1):
            raise ValueError("sign")
        # The oracle finds banks only from actual physical tag values.
        # It never invokes the model's bank-selection or comparator logic.
        banks = tuple(i for i in range(3, 16) if m.tags[i] == owner + 2)
        if not banks:
            raise ValueError("revoked")
        if not 0 <= length <= len(banks) * SIZE:
            raise ValueError("capacity")
        if length == 0:
            if sign:
                raise ValueError("negative zero")
            return 0
        payload = b"".join(bytes(m.data[i]) for i in banks)[:length]
        if payload[-1] == 0:
            raise ValueError("noncanonical high zero")
        magnitude = int.from_bytes(payload, byteorder="little", signed=False)
        return -magnitude if sign else magnitude

    expected_bad_cases = 0
    across_16bit_marker = 0
    released_cases = 0
    for case_id, a, b, expected_rom in cases:
        # These are source mutation points, not effects of a comparison.
        if case_id == 252:
            assert m.write_byte(45, SIZE, 0) == 0
        if case_id == 258:
            assert m.release(45) == (0, 2)
        if case_id == 261:
            assert m.release(46) == (0, 2)

        marker = case_id.to_bytes(2, "little")
        assert int.from_bytes(marker, "little") == case_id
        if case_id == 255:
            assert marker == b"\xff\x00"
        if case_id == 256:
            assert marker == b"\x00\x01"
            across_16bit_marker += 1
        if 256 <= case_id <= 261:
            assert marker[1] == 1

        short_banks = tuple(i for i in range(3, 16) if m.tags[i] == 47)
        live_banks = tuple(i for i in range(3, 16) if m.tags[i] == 48)
        assert short_banks == ((5, 7) if case_id <= 257 else ())
        assert live_banks == ((8, 9) if case_id <= 260 else ())
        fragmented_high = (1 if case_id <= 251 else 0)
        assert m.data[5][-1] == (0x33 if case_id <= 257 else 0)
        assert m.data[7][0] == (fragmented_high if case_id <= 257 else 0)
        assert m.data[6][0] == 1, (case_id, "live peer bank overwritten")
        assert m.data[8][-1] == (0x33 if case_id <= 260 else 0)
        assert m.data[9][-2] == (0x3c if case_id <= 260 else 0)
        assert m.data[9][-1] == 0
        assert m.data[8][0] == (0x7f if case_id <= 260 else 0)

        # Raw fragmented magnitude independent of the Host comparator.
        if case_id <= 257:
            raw_fragmented = bytes(m.data[5]) + bytes(m.data[7])
            short_magnitude = int.from_bytes(raw_fragmented[:SIZE], "little")
            long_magnitude = int.from_bytes(raw_fragmented[:SIZE + 1], "little")
            assert short_magnitude > 0
            if case_id <= 251:
                assert long_magnitude > short_magnitude
                assert raw_fragmented[SIZE] == 1
            else:
                assert long_magnitude == short_magnitude
                assert raw_fragmented[SIZE] == 0
            assert short_magnitude.bit_length() > 8 * (SIZE - 1)
        else:
            assert not any(m.data[5]) and not any(m.data[7])
            released_cases += 1

        if case_id in (259, 260):
            peer_raw = bytes(m.data[8])
            assert int.from_bytes(peer_raw, "little") > 0
            assert peer_raw[-1] == 0x33

        descriptor_before = encoded(a) + encoded(b)
        assert len(descriptor_before) == 10
        tags_before = bytes(m.tags)
        sram_before = tuple(bytes(bank) for bank in m.data)
        sentinel = (
            (5, 0, 0), (5, SIZE - 1, 0x33 if case_id <= 257 else 0),
            (6, 0, 1), (7, 0, fragmented_high if case_id <= 257 else 0),
            (7, SIZE - 1, 0),
            (8, 0, 0x7f if case_id <= 260 else 0),
            (8, SIZE - 1, 0x33 if case_id <= 260 else 0),
            (9, 0, 1 if case_id <= 260 else 0),
            (9, SIZE - 2, 0x3c if case_id <= 260 else 0),
            (9, SIZE - 1, 0),
        )
        for bank, offset, value in sentinel:
            assert m.data[bank][offset] == value, (case_id, "before", bank, offset)

        values = []
        failures = []
        for desc in (a, b):
            try:
                values.append(independent_value(desc))
                failures.append(None)
            except ValueError as exc:
                values.append(None)
                failures.append(str(exc))
        if case_id in reasons:
            assert tuple(failures) == reasons[case_id], (
                case_id, "invalidity classification and position", failures
            )
            independent_result = 3
            expected_bad_cases += 1
        else:
            assert failures == [None, None], (case_id, failures)
            av, bv = values
            assert (av < 0) == bool(a[1])
            assert (bv < 0) == bool(b[1])
            independent_result = (av > bv) + 2 * (av < bv)
            if case_id == 257:
                assert av == bv == short_magnitude

        assert independent_result == expected_rom, (
            case_id, "source assertion vs Python signed-integer oracle",
            independent_result, expected_rom
        )
        assert compare_read_only(m, a, b) == independent_result, (
            case_id, "Host comparator differs from independent oracle"
        )
        assert encoded(a) + encoded(b) == descriptor_before
        assert bytes(m.tags) == tags_before
        assert tuple(bytes(bank) for bank in m.data) == sram_before
        for bank, offset, value in sentinel:
            assert m.data[bank][offset] == value, (
                case_id, "after", bank, offset
            )

    assert expected_bad_cases == 9
    assert released_cases == 4
    assert across_16bit_marker == 1
    print(
        "HOST_NATIVE248_261_INDEPENDENT_FIXTURES=PASS cases=14 comparisons=14 "
        "descriptor_bytes=10 lease_tags=16 SRAM=FULL_SNAPSHOT "
        "physical_sentinels=5,6,7,8,9 "
        "fragmented_owner45_banks=5,7 interposed_peer_bank=6 "
        "noncanonical_high_zero=5 invalidity_reasons=CHECKED "
        "revoked_cases=4 signed_integer_oracle=YES "
        "marker_00FF_to_0100=CHECKED shared_loops=252-255,259-261 "
        "not_native=YES",
        flush=True,
    )
