#!/usr/bin/env python3
"""Independent host oracle for six SM83 invocation lifecycle cases."""
from itertools import product
EMPTY = bytes(8192)
class Model:
    def __init__(self):
        self.owner = None
        self.tags = [0] * 13
        self.data = [EMPTY] * 13
    def snapshot(self):
        return self.owner, tuple(self.tags), tuple(self.data)
    def begin(self, owner, count):
        if self.owner is not None: return 5
        if not 1 <= owner <= 253 or not 1 <= count <= 13: return 2
        if owner + 2 in self.tags: return 3
        free = [i for i in range(13) if self.tags[i] == 0]
        if len(free) < count: return 1
        for i in free[:count]:
            self.tags[i], self.data[i] = owner + 2, EMPTY
        self.owner = owner
        return 0
    def abort(self):
        if self.owner is None: return 6
        for i in range(13):
            if self.tags[i] == self.owner + 2:
                self.tags[i], self.data[i] = 0, EMPTY
        self.owner = None
        return 0
def main():
    m = Model()
    assert m.begin(47, 1) == 0 and m.tags[0] == 49
    m.data[0] = bytes([0x6a])+bytes(8191)
    old = m.snapshot()
    assert m.begin(48, 1) == 5 and m.snapshot() == old
    assert m.abort() == 0 and m.owner is None and m.tags[0] == 0 and m.data[0] == EMPTY
    old = m.snapshot()
    assert m.abort() == 6 and m.snapshot() == old
    assert m.begin(254, 1) == 2 and m.snapshot() == old
    assert m.begin(52, 0) == 2 and m.snapshot() == old
    checks = 0
    for owner,count in product((0,1,47,253,254,255),(0,1,2,13,14)):
        m = Model(); before = m.snapshot()
        expected = 0 if 1 <= owner <= 253 and 1 <= count <= 13 else 2
        assert m.begin(owner, count) == expected
        if expected == 0:
            assert m.tags.count(owner+2) == count
            assert m.abort() == 0
        assert m.snapshot() == before
        checks += 1
    print("HOST_STAGE1_INVOCATION_LIFECYCLE=PASS native_contract=284..289 matrix=%d "
          "scrub=8192 busy=YES invalid=YES native_execution=NOT_CLAIMED" % checks)
if __name__ == "__main__":
    main()
