#!/usr/bin/env python3
"""Source-independent Host validation of the Native191..202 ROMX SRAM guard.

This validates every table row against physically reconstructed lease/SRAM
state, tests the 198 before/after release split, and injects one-byte corruptions
into each checked location to verify detection. NOT SM83 execution.
"""
from __future__ import annotations

from pathlib import Path
import re

from test_sram_owner_model import OwnedBanks, SIZE


def check_native191_202_sram_guard():
    path = Path(__file__).resolve().parents[1] / "src/tests/owner_signed_cmp_test.asm"
    asm = path.read_text(encoding="utf-8")
    region = asm.split("; 203-206:", 1)[0]
    assert region.count("call OwnerCmpTestExpectResultSnapshot") == 13, (
        "exactly 13 Native191..202 comparison checkpoints required"
    )
    hooked = asm.split("OwnerCmpTestExpectResultSnapshot:\n", 1)[1].split(
        "\nOwnerCmpTestReadOwnerStatus:", 1
    )[0]
    assert "call OwnerCmpTestCheckSnapshot" in hooked
    assert "call OwnerCmpTestEarlySentinelCheck" in hooked
    assert "ld [$2000], a" in hooked

    part = asm.split("OwnerCmpTestEarlySentinelExpected:\n", 1)[1].split(
        "\n; END OwnerCmpTestEarlySentinelExpected", 1
    )[0]
    table = []
    source_cases = []
    for line in part.splitlines():
        s = line.strip()
        if not s.startswith("db "):
            continue
        data, comment = s.split(";", 1)
        values = re.findall(r"\$([0-9a-fA-F]{2})", data)
        assert len(values) == 4, (line, values)
        table.append(tuple(int(value, 16) for value in values))
        source_cases.append(comment.strip())
    assert len(table) == 13
    assert source_cases == [
        "191", "192", "193", "194", "195", "196", "197",
        "198 before release", "198 after release",
        "199", "200", "201", "202",
    ], source_cases

    model = OwnedBanks()
    assert model.alloc(41, 3) == (0, (3, 4, 5))
    assert model.alloc(42, 1) == (0, (6,))
    assert model.release(41) == (0, 3)
    assert model.alloc(43, 1) == (0, (3,))
    assert model.alloc(44, 1) == (0, (4,))
    assert model.alloc(45, 2) == (0, (5, 7))
    assert model.alloc(46, 2) == (0, (8, 9))
    assert model.tags[5] == model.tags[7] == 47
    assert model.tags[6] == 44
    assert model.tags[8] == model.tags[9] == 48

    physical_positions = (
        (5, SIZE - 1), (7, 0), (8, SIZE - 1), (9, 0),
        (5, 0), (7, SIZE - 1), (8, 0), (6, 0),
    )
    checked_cases = []
    mutations = 0

    def check(case_id, after_release=False):
        nonlocal mutations
        # Index mirrors case IDs, except case198 has a separate post-release
        # checkpoint and 199..202 must shift by one row.
        idx = case_id - 191
        if case_id >= 199 or (case_id == 198 and after_release):
            idx += 1
        assert 0 <= idx < 13
        if case_id == 198:
            assert (model.tags[5] == 0) == after_release
        expected = table[idx] + (0, 0, 0, 0)
        tags_before = bytes(model.tags)
        all_banks_before = tuple(bytes(bank) for bank in model.data)
        observed = tuple(model.data[bank][off] for bank, off in physical_positions)
        assert observed == expected, (case_id, after_release, observed, expected)
        for (bank, off), value in zip(physical_positions, expected):
            model.data[bank][off] ^= 1
            altered = tuple(model.data[b][o] for b, o in physical_positions)
            assert altered != expected and altered[
                physical_positions.index((bank, off))
            ] != value, (case_id, bank, off, "injected error not detected")
            model.data[bank][off] ^= 1
            assert tuple(model.data[b][o] for b, o in physical_positions) == expected
            mutations += 1
        assert bytes(model.tags) == tags_before
        assert tuple(bytes(bank) for bank in model.data) == all_banks_before
        checked_cases.append((case_id, after_release))

    check(191)
    assert model.write_byte(45, SIZE, 1) == 0
    assert model.write_byte(46, SIZE, 2) == 0
    for case_id in (192, 193, 194):
        check(case_id)
    assert model.write_byte(46, SIZE, 0) == 0
    check(195)
    assert model.write_byte(46, SIZE, 2) == 0
    check(196)
    assert model.write_byte(46, SIZE, 1) == 0
    assert model.write_byte(45, SIZE - 1, 0x33) == 0
    assert model.write_byte(46, SIZE - 1, 0x34) == 0
    check(197)
    assert model.write_byte(46, SIZE - 1, 0x33) == 0
    check(198)
    assert model.release(45) == (0, 2)
    check(198, after_release=True)
    for case_id in range(199, 203):
        check(case_id)

    assert len(checked_cases) == 13 and len(set(x[0] for x in checked_cases)) == 12
    assert mutations == 13 * len(physical_positions) == 104
    print(
        "HOST_NATIVE191_202_SRAM_SENTINEL_INJECTION=PASS "
        "cases=12 comparisons=13 physical_sentinels=8 "
        "injected_mutations=104 table_rows=13 "
        "before_after_release198=YES ROMX_SOURCE_GUARD=CHECKED "
        "not_native=YES",
        flush=True,
    )
