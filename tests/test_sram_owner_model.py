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

    def alloc(self, owner, count):
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
        return 0, group

    def release(self, owner):
        if not 1 <= owner <= 253:
            return 2, 0
        tag = owner + 2
        group = [i for i in range(RESERVED, BANKS) if self.tags[i] == tag]
        if not group:
            return 3, 0
        for bank in group:
            self.data[bank][:] = bytes(SIZE)
            self.tags[bank] = 0
        return 0, len(group)


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
    print(f"HOST_SRAM_OWNER_MODEL=PASS randomized_transitions={checks} slots=13")
    print("NOT_A_NATIVE_ROM_VERIFICATION=YES")


if __name__ == "__main__":
    main()
