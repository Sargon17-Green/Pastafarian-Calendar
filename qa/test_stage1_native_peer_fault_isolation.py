#!/usr/bin/env python3
"""Injected-fault ownership check for Native p/s boundaries (synthetic).

A Native step may fail midway. An unmodified peer must leave the original
exception visible. Corrupting peer memory, IPs, stacks or runtime objects
must be rejected even when the actor's opcode raises. No PyFunge required.
"""
from stage1_native_peer_write_guard import guarded_step
from test_stage1_native_peer_runtime_identity import Program, Vec, Space, Semantic


def write(actor, opcode):
    if opcode == 'p':
        actor.space.put(Vec((123, 456)), 99)
    else:
        actor.space.put(Vec((5, 2)), 81)


def check(opcode, name, corrupt=None, before_write=False):
    actor = Program([99, 123, 456] if opcode == 'p' else [81], opcode)
    peer = Program([8, 3, 5])
    target = Vec((123, 456) if opcode == 'p' else (5, 2))
    old_peer_byte = peer.space.get(target)

    def faulting_step(current):
        if not before_write:
            write(current, opcode)
        if corrupt is not None:
            corrupt(peer, target)
        raise RuntimeError('injected native opcode fault')

    try:
        guarded_step(actor, peer, faulting_step)
    except AssertionError as exc:
        if corrupt is None:
            raise AssertionError('clean fault was misclassified: ' + str(exc))
        if "other Program" not in str(exc):
            raise AssertionError('wrong ownership rejection: ' + name + ': ' + str(exc))
        print('EXPECTED_PEER_FAULT_CORRUPTION_REJECT', opcode, name)
    except RuntimeError as exc:
        if corrupt is not None:
            raise AssertionError('peer ' + name + ' corruption masked by original fault')
        if str(exc) != 'injected native opcode fault':
            raise AssertionError('fault changed its meaning')
        print('ORIGINAL_NATIVE_FAULT_PRESERVED', opcode, name)
    else:
        raise AssertionError('injected fault swallowed for ' + name)
    if name != 'peer_cell' and peer.space.get(target) != old_peer_byte:
        raise AssertionError('fixture changed peer target unexpectedly: ' + name)


def main():
    corruptions = (
        ('peer_cell', lambda p, t: p.space.put(t, 17)),
        ('peer_stack', lambda p, t: p.ips[0].stack[0].append(1729)),
        ('peer_stack_stack_replaced', lambda p, t:
            setattr(p.ips[0], 'stack', [list(frame) for frame in p.ips[0].stack])),
        ('peer_stack_frame_replaced', lambda p, t:
            p.ips[0].stack.__setitem__(0, list(p.ips[0].stack[0]))),
        ('peer_position', lambda p, t: setattr(p.ips[0], 'position', Vec((555, -23)))),
        ('peer_offset', lambda p, t: setattr(p.ips[0], 'offset', Vec((9, 90)))),
        ('peer_space', lambda p, t: setattr(p, 'space', Space(p.space.cells))),
        ('peer_queue', lambda p, t: setattr(p, 'ips', list(p.ips))),
        ('peer_semantics', lambda p, t: setattr(p, 'semantics', Semantic())),
        ('peer_platform', lambda p, t: setattr(p.semantics, 'platform', object())),
    )
    for opcode in ('p', 's'):
        check(opcode, 'before_write_clean_fault', before_write=True)
        check(opcode, 'after_write_clean_fault')
        for name, mutation in corruptions:
            check(opcode, name, mutation)
    print('NATIVE_P_S_FAULT_PATH_20_PEER_CORRUPTIONS_4_CLEAN_ERRORS_PASS')


if __name__ == '__main__':
    main()
