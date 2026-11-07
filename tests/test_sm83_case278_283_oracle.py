#!/usr/bin/env python3
"""Source-specific Host/physical-SRAM oracle for Native278..283.

Status, marker, sentinel and lease expectations follow the Native source; each
expected state is checked independently from physical bytes/tags. This is a
Host-side oracle, NOT execution of the SM83 ROM or acceptance of all Stage 1.
"""
from __future__ import annotations

from pathlib import Path
import re

from test_sram_owner_model import OwnedBanks, SIZE


def check_native278_283_fixtures():
    src = (
        Path(__file__).resolve().parents[1]
        / "src/tests/owner_signed_cmp_test.asm"
    ).read_text(encoding="utf-8")
    group = src.split("OwnerCmpTestOwner253FullGroup:\n", 1)[1]
    assert group.count("call LeaseResetAll") >= 1
    markers = [
        int(value) for value in re.findall(
            r"^    ; (27[89]|28[0-3]):", group, flags=re.MULTILINE
        )
    ]
    assert markers == list(range(278, 284)), markers

    size = 13 * SIZE
    assert size == 106496 and size - 1 == 106495
    assert (size - 1).to_bytes(3, "little") == b"\xff\x9f\x01"
    assert size.to_bytes(3, "little") == b"\x00\xa0\x01"
    model = OwnedBanks()
    model.data[0][0] = 0x4D  # ROM source writes reserved SRAM bank 0.
    assert model.mapped == 0
    assert model.tags == [2] * 3 + [0] * 13
    cases = []
    sampled = 0

    def assert_checkpoint(case, *, expect_owned, value_at_last):
        nonlocal sampled
        marker = case.to_bytes(2, "little")
        assert marker == bytes((case - 256, 1)), (case, marker)
        assert model.data[0][0] == 0x4D, (case, "reserved bank corrupted")
        assert model.tags[:3] == [2, 2, 2]
        assert model.tags[3:] == ([255] * 13 if expect_owned else [0] * 13)
        if expect_owned:
            assert all(model.tags[bank] == 253 + 2 for bank in range(3, 16))
            assert model.data[15][-1] == value_at_last
            assert model.data[3][0] == 0
        else:
            assert all(not any(model.data[bank]) for bank in range(3, 16))
            assert model.data[15][-1] == 0
            assert model.data[3][0] == 0
        assert len(model.tags) == len(model.data) == 16
        assert all(len(bank) == SIZE for bank in model.data)
        cases.append(case)
        sampled += 1

    # 278: the valid maximum owner 253 tags all 13 physical scratch banks
    # with 255, retaining the persistent reserved-bank sentinel.
    before = tuple(bytes(bank) for bank in model.data)
    assert model.alloc(253, 13) == (0, tuple(range(3, 16)))
    assert model.selected == -1 and model.mapped == 15
    assert all(not any(model.data[bank]) for bank in range(3, 16))
    assert model.data[0] == before[0]
    assert_checkpoint(278, expect_owned=True, value_at_last=0)

    # 279: last valid logical byte 0x019FFF maps to physical bank 15:$BFFF.
    assert (size - 1) // SIZE + 3 == 15
    assert (size - 1) % SIZE == SIZE - 1
    assert model.write_byte(253, size - 1, 0x5A) == 0
    assert model.selected == model.mapped == 15
    assert model.data[15][-1] == 0x5A
    tag_snapshot = bytes(model.tags)
    all_sram_snapshot = tuple(bytes(bank) for bank in model.data)
    assert model.read_byte(253, size - 1) == (0, 0x5A)
    assert model.selected == model.mapped == 15
    assert bytes(model.tags) == tag_snapshot
    assert tuple(bytes(bank) for bank in model.data) == all_sram_snapshot
    assert_checkpoint(279, expect_owned=True, value_at_last=0x5A)

    # 280: first invalid logical offset must return (status=2, value=0),
    # revoke the cached physical handle, and preserve mapping and payload.
    tag_snapshot = bytes(model.tags)
    all_sram_snapshot = tuple(bytes(bank) for bank in model.data)
    mapping_before = model.mapped
    assert model.read_byte(253, size) == (2, 0)
    assert model.selected == -1 and model.mapped == mapping_before == 15
    assert bytes(model.tags) == tag_snapshot
    assert tuple(bytes(bank) for bank in model.data) == all_sram_snapshot
    assert_checkpoint(280, expect_owned=True, value_at_last=0x5A)

    # 281: invalid write also must fail without clobbering the 0x5A at
    # the highest valid address or modifying another physical SRAM byte.
    tag_snapshot = bytes(model.tags)
    all_sram_snapshot = tuple(bytes(bank) for bank in model.data)
    mapping_before = model.mapped
    invalid_written_value = 0xA7
    assert model.write_byte(253, size, invalid_written_value) == 2
    assert invalid_written_value == 0xA7
    assert model.selected == -1 and model.mapped == mapping_before == 15
    assert bytes(model.tags) == tag_snapshot
    assert tuple(bytes(bank) for bank in model.data) == all_sram_snapshot
    assert_checkpoint(281, expect_owned=True, value_at_last=0x5A)

    # 282: duplicate max-owner allocation fails with status=3, reporting
    # zero new leases, and cannot modify any of 16 physical SRAM banks.
    tag_snapshot = bytes(model.tags)
    all_sram_snapshot = tuple(bytes(bank) for bank in model.data)
    mapping_before = model.mapped
    assert model.alloc(253, 1) == (3, ())
    assert model.selected == -1 and model.mapped == mapping_before == 15
    assert bytes(model.tags) == tag_snapshot
    assert tuple(bytes(bank) for bank in model.data) == all_sram_snapshot
    assert_checkpoint(282, expect_owned=True, value_at_last=0x5A)

    # 283: release exactly 13 scratch banks, scrub both boundary banks
    # plus every intermediate bank, retain the reserved-bank 0x4D, and
    # reject a stale owner handle without remapping away from bank 0.
    assert model.release(253) == (0, 13)
    assert model.selected == -1 and model.mapped == 0
    assert_checkpoint(283, expect_owned=False, value_at_last=0)
    tag_snapshot = bytes(model.tags)
    all_sram_snapshot = tuple(bytes(bank) for bank in model.data)
    assert model.read_byte(253, size - 1) == (3, 0)
    assert model.selected == -1 and model.mapped == 0
    assert bytes(model.tags) == tag_snapshot
    assert tuple(bytes(bank) for bank in model.data) == all_sram_snapshot
    assert model.data[0][0] == 0x4D

    assert cases == list(range(278, 284)) and sampled == 6
    print(
        "HOST_NATIVE278_283_INDEPENDENT_FIXTURES=PASS cases=6 "
        "owner_max=253 tag_max=255 full_banks=13 "
        "last_valid=106495 first_invalid=106496 invalid_read=2 "
        "invalid_write=2 duplicate_allocation=3 released_banks=13 "
        "stale_owner_read=3 reserved_bank0=4D "
        "all_16_sram_snapshots=YES source_markers=278-283 "
        "not_native=YES",
        flush=True,
    )
