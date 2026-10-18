#!/usr/bin/env python3
"""Synthetic ownership identity mutation controls for cross-Program p/s guards."""
from stage1_native_peer_write_guard import guarded_step


class Vec(tuple):
    def __new__(cls, coords):
        return tuple.__new__(cls, coords)


class Space:
    def __init__(self, cells=None):
        self.cells = dict(cells or {})

    def get(self, pt):
        return self.cells.get(tuple(pt), 32)

    def put(self, pt, value):
        self.cells[tuple(pt)] = value


class IP:
    def __init__(self, stack):
        self.position = Vec((4, 2))
        self.delta = Vec((1, 0))
        self.offset = Vec((0, 0))
        self.stringmode = False
        self.stack = [list(stack)]


class Semantic:
    def __init__(self):
        self.platform = object()


class Program:
    def __init__(self, stack, opcode='p'):
        self.space = Space({(4, 2): ord(opcode)})
        self.ips = [IP(stack)]
        self._qa_point = Vec
        self.semantics = Semantic()


def mutate_space(peer):
    peer.space = Space(peer.space.cells)


def mutate_semantics(peer):
    peer.semantics = Semantic()


def mutate_platform(peer):
    peer.semantics.platform = object()


def mutate_ip_queue(peer):
    peer.ips = list(peer.ips)


MUTATIONS = (
    ('space_identity', mutate_space),
    ('semantics_identity', mutate_semantics),
    ('platform_identity', mutate_platform),
    ('ip_queue_identity', mutate_ip_queue),
    ('stack_stack_identity', lambda peer:
        setattr(peer.ips[0], 'stack', [list(frame) for frame in peer.ips[0].stack])),
    ('stack_frame_identity', lambda peer:
        peer.ips[0].stack.__setitem__(0, list(peer.ips[0].stack[0]))),
)


def write_actor(actor, opcode):
    if opcode == 'p':
        actor.space.put(Vec((123, 456)), 99)
    else:
        actor.space.put(Vec((5, 2)), 81)


def main():
    count = 0
    for opcode, stack in (('p', [99, 123, 456]), ('s', [81])):
        for label, mutation in MUTATIONS:
            actor = Program(stack, opcode)
            peer = Program([2, 4])
            peer_cell = peer.space.get(Vec((123, 456) if opcode == 'p' else (5, 2)))

            def hostile_step(program):
                write_actor(program, opcode)
                mutation(peer)

            try:
                guarded_step(actor, peer, hostile_step)
            except AssertionError as error:
                expected_reason = ("other Program's IP or stack-stack state"
                    if label.startswith('stack_') else
                    "other Program's owned runtime objects")
                if expected_reason not in str(error):
                    raise AssertionError('unexpected reason for ' + label + ': ' + str(error))
            else:
                raise AssertionError('accepted swapped peer runtime object: ' + label)
            if peer.space.get(Vec((123, 456) if opcode == 'p' else (5, 2))) != peer_cell:
                raise AssertionError('hostile fixture altered peer cell')
            count += 1
        actor = Program(stack, opcode)
        peer = Program([2, 4])
        if guarded_step(actor, peer, lambda runner: write_actor(runner, opcode)) != 1:
            raise AssertionError('valid p/s execution rejected')
        count += 1
    print('NATIVE_PEER_RUNTIME_IDENTITY_12_FALSIFICATIONS_2_POSITIVES_PASS', count)


if __name__ == '__main__':
    main()
