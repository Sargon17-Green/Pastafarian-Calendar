#!/usr/bin/env python3
"""Independent bank-group ownership model; not SM83 execution."""
from random import Random

RESERVED = 3
BANKS = 16
SIZE = 8192


class OwnedBanks:
    def __init__(self):
        self.tags = [2] * RESERVED + [0] * (BANKS - RESERVED)
        self.data = [bytearray(SIZE) for _ in range(BANKS)]
        self.mapped = 0  # MBC5 RAM bank, not an ownership capability
        self.selected = -1  # cached physical handle or revoked sentinel

    def alloc(self, owner, count):
        self.selected = -1  # allocation invalidates an earlier selection
        if not (1 <= owner <= 253 and 1 <= count <= 13):
            return 2, ()
        tag = owner + 2
        if tag in self.tags:
            return 3, ()
        free = [i for i in range(RESERVED, BANKS) if self.tags[i] == 0]
        if len(free) < count:
            return 1, ()
        group = tuple(free[:count])
        for bank in group:
            self.tags[bank] = tag
            self.data[bank][:] = bytes(SIZE)
        self.mapped = group[-1]  # the native zeroizer leaves this bank mapped
        return 0, group

    def select(self, owner, logical_index):
        """Resolve a current owner's physical bank by sorted logical index."""
        self.selected = -1  # invalid selection revokes the cached handle
        if not (1 <= owner <= 253 and 0 <= logical_index <= 12):
            return 2, -1
        matches = [i for i in range(RESERVED, BANKS)
                   if self.tags[i] == owner + 2]
        if logical_index >= len(matches):
            return 3, -1
        self.mapped = matches[logical_index]
        self.selected = self.mapped
        return 0, self.mapped

    def read_byte(self, owner, offset):
        if not 0 <= offset < 13 * SIZE:
            self.selected = -1
            return 2, 0
        status, physical = self.select(owner, offset // SIZE)
        if status:
            return status, 0
        return 0, self.data[physical][offset % SIZE]

    def write_byte(self, owner, offset, value):
        if not 0 <= offset < 13 * SIZE:
            self.selected = -1
            return 2
        status, physical = self.select(owner, offset // SIZE)
        if status:
            return status
        self.data[physical][offset % SIZE] = value
        return 0

    def release(self, owner):
        self.selected = -1
        if not 1 <= owner <= 253:
            return 2, 0
        tag = owner + 2
        group = [i for i in range(RESERVED, BANKS) if self.tags[i] == tag]
        if not group:
            return 3, 0
        for bank in group:
            self.data[bank][:] = bytes(SIZE)
            self.tags[bank] = 0
        self.mapped = 0  # successful release selects reserved bank 0
        return 0, len(group)



def check_stage1_high_owner_and_byte_boundaries():
    """Host-only contract oracle for Native 165..190; not SM83 execution."""
    allocation_cases = 0
    # An independent arithmetic oracle fixes the 8-bit owner/tag edge:
    # owner 253 -> tag 255 is valid; 254/255 must never wrap.
    for owner in (0, 1, 253, 254, 255):
        for count in (0, 1, 13, 14):
            sample = OwnedBanks()
            sample.data[0][0] = 0x61
            for bank in range(3, 16):
                sample.data[bank][8191] = 0xC0 + bank
            old_tags = sample.tags[:]
            old_data = tuple(bytes(bank) for bank in sample.data)
            valid = 1 <= owner <= 253 and 1 <= count <= 13
            status, group = sample.alloc(owner, count)
            assert status == (0 if valid else 2), (owner, count, status)
            if valid:
                expected = tuple(range(3, 3 + count))
                assert group == expected
                assert sample.mapped == expected[-1]
                assert sample.tags[3:3 + count] == [owner + 2] * count
                assert all(not any(sample.data[bank]) for bank in expected)
                assert sample.tags[3 + count:] == [0] * (13 - count)
            else:
                assert group == ()
                assert sample.tags == old_tags
                assert tuple(bytes(bank) for bank in sample.data) == old_data
                assert sample.mapped == 0
            assert sample.selected == -1 and sample.data[0][0] == 0x61
            allocation_cases += 1

    full = OwnedBanks()
    assert full.alloc(253, 13) == (0, tuple(range(3, 16)))
    before = (full.tags[:], tuple(bytes(bank) for bank in full.data))
    assert full.alloc(253, 1) == (3, ())  # duplicate; no partial mutation
    assert (full.tags, tuple(bytes(bank) for bank in full.data)) == before
    allocation_cases += 1
    assert full.alloc(1, 1) == (1, ())  # exhausted; no partial mutation
    assert (full.tags, tuple(bytes(bank) for bank in full.data)) == before
    allocation_cases += 1
    for owner in (254, 255):
        assert full.release(owner) == (2, 0)
        assert (full.tags, tuple(bytes(bank) for bank in full.data)) == before
        assert full.mapped == 15 and full.selected == -1
        allocation_cases += 1

    byte_cases = 0
    # 13 * 8192 = 106496; 106495 is the final valid 24-bit address.
    for offset in (0, 8191, 8192, 106495, 106496,
                   0x1ffff, 0x20000, 0xffffff):
        valid = 0 <= offset < 13 * SIZE
        pre_data = tuple(bytes(bank) for bank in full.data) if not valid else None
        pre_map = full.mapped
        value = (offset ^ 0x5a) & 0xff
        status = full.write_byte(253, offset, value)
        assert status == (0 if valid else 2), (offset, status)
        if valid:
            physical = 3 + offset // SIZE
            assert full.selected == physical and full.mapped == physical
            assert full.data[physical][offset % SIZE] == value
            assert full.read_byte(253, offset) == (0, value)
        else:
            assert full.selected == -1 and full.mapped == pre_map
            assert tuple(bytes(bank) for bank in full.data) == pre_data
            assert full.read_byte(253, offset) == (2, 0)
            assert full.mapped == pre_map
        byte_cases += 1

    for invalid_owner in (0, 254, 255):
        data_before = tuple(bytes(bank) for bank in full.data)
        mapped_before = full.mapped
        assert full.write_byte(invalid_owner, 0, 0xee) == 2
        assert full.read_byte(invalid_owner, 0) == (2, 0)
        assert full.selected == -1 and full.mapped == mapped_before
        assert tuple(bytes(bank) for bank in full.data) == data_before
        byte_cases += 1

    small = OwnedBanks()
    assert small.alloc(1, 1) == (0, (3,))
    mapped_before = small.mapped
    assert small.write_byte(1, SIZE, 0xa5) == 3
    assert small.mapped == mapped_before and small.selected == -1
    byte_cases += 1
    assert small.read_byte(1, SIZE) == (3, 0)
    assert small.mapped == mapped_before and small.selected == -1
    byte_cases += 1

    assert full.release(253) == (0, 13)
    assert full.mapped == 0 and full.selected == -1
    assert full.tags == [2] * 3 + [0] * 13
    assert all(not any(full.data[bank]) for bank in range(3, 16))
    assert full.read_byte(253, 106495) == (3, 0)
    byte_cases += 1
    assert allocation_cases == 24 and byte_cases == 14
    print(f"HOST_STAGE1_OWNER_ALLOC_HIGH_BOUNDARY=PASS cases={allocation_cases} "
          "owners=0,1,253,254,255 counts=0,1,13,14", flush=True)
    print(f"HOST_STAGE1_OWNER_BYTE_HIGH_BOUNDARY=PASS cases={byte_cases} "
          "last_valid=106495 first_invalid=106496 high_byte_2=REJECTED", flush=True)

def main():
    model = OwnedBanks()
    model.data[0][0] = 0x66
    assert model.alloc(0, 2) == (2, ())
    assert model.alloc(9, 2) == (0, (3, 4))
    assert model.alloc(10, 3) == (0, (5, 6, 7))
    model.data[5][-1] = 0x5A
    assert model.alloc(9, 1) == (3, ())
    assert model.alloc(11, 9) == (1, ())
    assert model.tags[8:] == [0] * 8
    assert model.release(9) == (0, 2)
    assert model.release(9) == (3, 0)
    assert model.data[5][-1] == 0x5A
    assert model.alloc(11, 2) == (0, (3, 4))
    assert model.release(10) == (0, 3)
    assert model.release(11) == (0, 2)
    assert model.tags == [2] * 3 + [0] * 13
    assert model.data[0][0] == 0x66

    # Logical indexing is owner-scoped even after physical fragmentation.
    assert model.select(0, 0) == (2, -1)
    assert model.select(21, 13) == (2, -1)
    assert model.select(21, 0) == (3, -1)
    assert model.alloc(21, 3) == (0, (3, 4, 5))
    assert model.alloc(22, 1) == (0, (6,))
    assert model.release(21) == (0, 3)
    assert model.alloc(23, 1) == (0, (3,))
    assert model.alloc(24, 1) == (0, (4,))
    assert model.alloc(25, 2) == (0, (5, 7))
    assert model.select(25, 0) == (0, 5)
    assert (model.mapped, model.selected) == (5, 5)
    assert model.select(25, 1) == (0, 7)
    assert (model.mapped, model.selected) == (7, 7)
    assert model.select(25, 2) == (3, -1)
    assert (model.mapped, model.selected) == (7, -1)
    assert model.select(23, 1) == (3, -1)
    assert model.select(23, 0) == (0, 3)
    assert model.release(25) == (0, 2)
    assert (model.mapped, model.selected) == (0, -1)
    assert model.select(25, 0) == (3, -1)
    assert (model.mapped, model.selected) == (0, -1)
    assert model.release(22) == (0, 1)
    assert model.release(23) == (0, 1)
    assert model.release(24) == (0, 1)
    assert model.tags == [2] * 3 + [0] * 13

    # Failed release is atomic for another owner's live mapped bank.
    model.data[0][0] = 0x4D
    assert model.alloc(26, 1) == (0, (3,))
    assert model.select(26, 0) == (0, 3)
    model.data[3][0] = 0x9C
    assert model.release(27) == (3, 0)
    assert (model.mapped, model.selected) == (3, -1)
    assert model.tags[3] == 28 and model.data[3][0] == 0x9C
    assert model.release(26) == (0, 1)
    assert (model.mapped, model.selected) == (0, -1)
    assert model.data[0][0] == 0x4D and model.data[3][0] == 0
    assert model.tags == [2] * 3 + [0] * 13

    # 24-bit logical byte addressing over physically fragmented banks.
    assert model.alloc(31, 3) == (0, (3, 4, 5))
    assert model.alloc(32, 1) == (0, (6,))
    assert model.release(31) == (0, 3)
    assert model.alloc(33, 1) == (0, (3,))
    assert model.alloc(34, 1) == (0, (4,))
    assert model.alloc(35, 2) == (0, (5, 7))
    assert model.write_byte(35, 8191, 0x5A) == 0
    assert model.write_byte(35, 8192, 0xA7) == 0
    assert model.read_byte(35, 8191) == (0, 0x5A)
    assert model.read_byte(35, 8192) == (0, 0xA7)
    assert model.write_byte(34, 8192, 0x66) == 3
    assert model.read_byte(35, 8192) == (0, 0xA7)
    assert model.read_byte(35, 13 * SIZE) == (2, 0)
    assert model.read_byte(35, 0x20000) == (2, 0)
    assert model.release(35) == (0, 2)
    assert model.data[5][-1] == 0 and model.data[7][0] == 0
    assert model.read_byte(35, 8192) == (3, 0)
    assert model.release(32) == (0, 1)
    assert model.release(33) == (0, 1)
    assert model.release(34) == (0, 1)
    assert model.tags == [2] * 3 + [0] * 13

    rng = Random(0x83A110C)
    checks = 0
    for _ in range(1000):
        owner = rng.randrange(1, 254)
        if rng.getrandbits(1):
            status, group = model.alloc(owner, rng.randrange(1, 14))
            if status == 0:
                assert all(not any(model.data[i]) for i in group)
                for i in group:
                    model.data[i][rng.randrange(SIZE)] = 0xA5
        else:
            status, count = model.release(owner)
            assert status in (0, 3)
            if status == 0:
                assert count > 0
        assert model.tags[:3] == [2] * 3
        assert all(x == 0 or 3 <= x <= 255 for x in model.tags[3:])
        checks += 1
    check_stage1_high_owner_and_byte_boundaries()
    print(f"HOST_SRAM_OWNER_MODEL=PASS randomized_transitions={checks} slots=13 logical_index=PASS release_unmap=PASS stale_handle=REVOKED absent_release=ATOMIC offset24=PASS fragmented_boundary=PASS")
    print("NOT_A_NATIVE_ROM_VERIFICATION=YES")


if __name__ == "__main__":
    main()
