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
        self.delta = Vector((1, 0))
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



def test_s_store_ownership():
    def store_actor(actor):
        ip = actor.ips[0]
        dest = Vector((ip.position[0] + ip.delta[0],
                       ip.position[1] + ip.delta[1]))
        actor.space.put(dest, ip.stack[0][-1] if ip.stack[0] else 0)

    # s writes at physical IP + delta, independent of the storage offset.
    a = Program([81], offset=(999, -999), opcode='s')
    b = Program([])
    if guarded_step(a, b, store_actor) != 1:
        raise AssertionError('executed native s was not monitored')
    if a.space.get(Vector((5, 2))) != 81 or b.space.get(Vector((5, 2))) != 32:
        raise AssertionError('s physical next-cell address incorrect')

    # Cross-program corruption beyond all fixed Native sentinel positions.
    a = Program([81], opcode='s')
    b = Program([])
    def forged_s(actor):
        store_actor(actor)
        b.space.put(Vector((5, 2)), 66)
    reject(lambda: guarded_step(a, b, forged_s), 'other Program')

    # Reject an apparently executed s that wrote a different actor cell.
    a = Program([81], opcode='s')
    b = Program([])
    def wrong_cell(actor):
        actor.space.put(Vector((6, 2)), 81)
    reject(lambda: guarded_step(a, b, wrong_cell), 'expected physical')

    # Underflow in Funge-98 makes an empty-stack s store zero.
    a = Program([], opcode='s')
    b = Program([])
    if guarded_step(a, b, store_actor) != 1 or a.space.get(Vector((5, 2))) != 0:
        raise AssertionError('s stack-underflow store contract failed')

    # The literal character s within stringmode is NOT an executed store.
    a = Program([81], opcode='s', stringmode=True)
    b = Program([])
    if guarded_step(a, b, lambda _: None) != 0:
        raise AssertionError('quoted s incorrectly treated as memory write')
    print('NATIVE_PEER_PHYSICAL_STORE_S_5_SYNTHETIC_CASES_PASS')


def test_peer_ip_state_ownership():
    """Hostile cross-Program IP and stack-stack mutations, no cell crossover.

    These defeat the old eight-cell sentinels and the peer physical p/s
    target check: the observed peer source byte never changes.
    """
    def actor_step(actor, opcode):
        if opcode == 'p':
            put_actor(actor)
        else:
            ip = actor.ips[0]
            position = Vector((ip.position[0] + ip.delta[0],
                               ip.position[1] + ip.delta[1]))
            actor.space.put(position, ip.stack[0][-1] if ip.stack[0] else 0)

    attacks = (
        ('peer_toss_append', 'p', lambda peer:
            peer.ips[0].stack[0].append(2718)),
        ('peer_soss_added', 's', lambda peer:
            peer.ips[0].stack.append([42])),
        ('peer_position', 'p', lambda peer:
            setattr(peer.ips[0], 'position', Vector((999, -7)))),
        ('peer_delta', 's', lambda peer:
            setattr(peer.ips[0], 'delta', Vector((0, -1)))),
        ('peer_offset', 'p', lambda peer:
            setattr(peer.ips[0], 'offset', Vector((7, 8)))),
        ('peer_stringmode', 's', lambda peer:
            setattr(peer.ips[0], 'stringmode', True)),
        ('peer_ip_deleted', 'p', lambda peer:
            peer.ips.pop()),
    )
    for label, opcode, mutate in attacks:
        stack = [77, 5234, -222] if opcode == 'p' else [81]
        actor = Program(stack, opcode=opcode)
        peer = Program([1, 2, 3])
        original_cell = peer.space.get(Vector((5234, -222) if opcode == 'p'
                                               else (5, 2)))
        def hostile_step(runner):
            actor_step(runner, opcode)
            mutate(peer)
        reject(lambda: guarded_step(actor, peer, hostile_step),
               "other Program's IP or stack-stack state")
        if peer.space.get(Vector((5234, -222) if opcode == 'p'
                                  else (5, 2))) != original_cell:
            raise AssertionError('hostile fixture changed peer cell: '+label)
        print('EXPECTED_PEER_IP_STATE_REJECTION', label)

    for opcode in ('p', 's'):
        stack = [77, 5234, -222] if opcode == 'p' else [81]
        actor = Program(stack, opcode=opcode)
        peer = Program([1, 2, 3])
        before = (tuple(peer.ips[0].position), tuple(peer.ips[0].stack[0]))
        if guarded_step(actor, peer, lambda p: actor_step(p, opcode)) != 1:
            raise AssertionError('valid native p/s step rejected: '+opcode)
        after = (tuple(peer.ips[0].position), tuple(peer.ips[0].stack[0]))
        if before != after:
            raise AssertionError('positive fixture modified peer IP state')
    print('NATIVE_PEER_IP_STACKSTACK_SEVEN_FORGERIES_TWO_POSITIVES_PASS')


if __name__ == '__main__':
    main()
    test_s_store_ownership()
    test_peer_ip_state_ownership()
