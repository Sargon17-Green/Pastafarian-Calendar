#!/usr/bin/env python3
"""Mutation tests for real-p-target cross-Program ownership; no PyFunge needed."""
from stage1_native_peer_write_guard import guarded_step


class Vector(tuple):
    def __new__(cls, coords):
        return tuple.__new__(cls, coords)


class Space:
    def __init__(self, cells=None):
        self.cells = dict(cells or {})

    def get(self, point):
        return self.cells.get(tuple(point), 32)

    def put(self, point, value):
        self.cells[tuple(point)] = value


class IP:
    def __init__(self, stack, pos=(4, 2), offset=(0, 0), stringmode=False):
        self.position = Vector(pos)
        self.offset = Vector(offset)
        self.stack = [list(stack)]
        self.stringmode = stringmode


class Program:
    def __init__(self, stack, offset=(0, 0), opcode='p', stringmode=False):
        self.space = Space({(4, 2): ord(opcode)})
        self.ips = [IP(stack, offset=offset, stringmode=stringmode)]
        self._qa_point = Vector


def put_actor(actor):
    from stage1_native_pg_physical_address import physical_pg_operands
    point, _, value = physical_pg_operands(actor.ips[0], 'p')
    actor.space.put(point, value)


def reject(f, fragment):
    try:
        f()
    except AssertionError as e:
        if fragment not in str(e):
            raise AssertionError("Wrong reason: " + str(e))
    else:
        raise AssertionError("Forged cross-Program p write was accepted")


def main():
    # Target is far from the fixed eight-cell sentinels in the Native suite.
    a = Program([77, 5234, -222], offset=(6, -3))
    b = Program([], opcode=' ')
    if guarded_step(a, b, put_actor) != 1:
        raise AssertionError("native p not checked")
    if a.space.get(Vector((5240, -225))) != 77:
        raise AssertionError("physical put coordinate wrong")
    if b.space.get(Vector((5240, -225))) != 32:
        raise AssertionError("unrelated peer cell changed")

    # Real BF98 underflow supplies zero to missing put operands.
    a = Program([9], offset=(-17, 8))
    b = Program([])
    if guarded_step(a, b, put_actor) != 1 or a.space.get(Vector((-17, 17))) != 0:
        raise AssertionError("underflow/offset put contract failed")

    a = Program([77, 5234, -222], offset=(6, -3))
    b = Program([])
    def cross_write(actor):
        put_actor(actor)
        b.space.put(Vector((5240, -225)), 99)
    reject(lambda: guarded_step(a, b, cross_write), "other Program")

    a = Program([77, 5234, -222], offset=(6, -3))
    b = Program([])
    reject(lambda: guarded_step(a, b, lambda _: None), "expected physical")

    a = Program([77, 5234, -222], stringmode=True)
    b = Program([])
    if guarded_step(a, b, lambda _: None) != 0:
        raise AssertionError("quoted p incorrectly classified as memory write")

    a = Program([77, 5234, -222], opcode='g')
    b = Program([])
    if guarded_step(a, b, lambda _: None) != 0:
        raise AssertionError("non-p classified as put")

    a = Program([])
    b = Program([])
    b.space = a.space
    reject(lambda: guarded_step(a, b, put_actor), "same Funge-space")

    a = Program([])
    a.ips = []
    b = Program([])
    if guarded_step(a, b, lambda _: None) != 0:
        raise AssertionError("terminated actor unexpectedly executed put")

    print("NATIVE_PEER_PHYSICAL_WRITE_8_SYNTHETIC_CASES_PASS")


if __name__ == '__main__':
    main()
