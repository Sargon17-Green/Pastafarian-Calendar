#!/usr/bin/env python3
"""Independent host model of DMG MBC5 scratch bank leases.
This checks API properties only, not the SM83 instruction stream.
"""
from random import Random

BANKS = 16
RESERVED = 3
SIZE = 8192

class Model:
    def __init__(self) -> None:
        self.sram = [bytearray(SIZE) for _ in range(BANKS)]
        self.state = [2] * RESERVED + [0] * (BANKS - RESERVED)

    def reset(self) -> None:
        for i in range(RESERVED, BANKS):
            self.sram[i][:] = bytes(SIZE)
            self.state[i] = 0

    def alloc(self) -> tuple[int, int]:
        for i in range(RESERVED, BANKS):
            if self.state[i] == 0:
                self.state[i] = 1
                self.sram[i][:] = bytes(SIZE)
                return 0, i
        return 1, 0xFF

    def free(self, bank: int) -> int:
        if not RESERVED <= bank < BANKS:
            return 2
        if self.state[bank] != 1:
            return 3
        self.sram[bank][:] = bytes(SIZE)
        self.state[bank] = 0
        return 0

def main() -> None:
    m = Model()
    m.sram[0][0] = 0x23
    m.sram[2][-1] = 0x77
    assert [m.alloc() for _ in range(13)] == [(0,i) for i in range(3,16)]
    assert m.alloc() == (1,0xFF)
    for i in range(3,16):
        m.sram[i][0] = i
        m.sram[i][-1] = 255 - i
    assert m.free(2) == 2
    assert m.free(16) == 2
    assert m.free(3) == 0
    assert m.free(3) == 3
    assert m.alloc() == (0,3)
    assert not any(m.sram[3])
    assert m.sram[4][0] == 4

    rng = Random(0x83A11)
    checks = 0
    for _ in range(600):
        allocated = [i for i in range(3,16) if m.state[i] == 1]
        if allocated and rng.getrandbits(1):
            selected = rng.choice(allocated)
            assert m.free(selected) == 0
            assert not any(m.sram[selected])
        else:
            status, selected = m.alloc()
            if status == 0:
                assert selected in range(3,16)
                assert not any(m.sram[selected])
                m.sram[selected][rng.randrange(SIZE)] = rng.randrange(1,256)
            else:
                assert selected == 0xFF and all(x == 1 for x in m.state[3:])
        checks += 1
    m.reset()
    assert all(x == 0 for x in m.state[3:])
    assert all(not any(m.sram[i]) for i in range(3,16))
    assert m.sram[0][0] == 0x23 and m.sram[2][-1] == 0x77
    print(f"HOST_SRAM_LEASE_MODEL=PASS randomized_transitions={checks} banks=13")
    print("NOT_A_NATIVE_ROM_VERIFICATION=YES")

if __name__ == "__main__":
    main()
