#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA-only Native Funge-space ownership guard at each executed p or s write.

Independent Program objects can have distinct `space` wrappers but accidentally
share or poison underlying cells. Sparse fixed sentinels alone cannot detect a
cross-write elsewhere. This helper checks the exact *physical* p/s write target
against the other live Program before/after every put. It is Python 2/3 safe.
"""
from stage1_native_pg_physical_address import physical_pg_operands


def peer_ip_snapshot(peer):
    """Read-only full IP/stack-stack witness across one executed p/s step.

    This is intentionally captured only at an actual source write to avoid
    copying every live stack at every Native instruction.
    """
    return tuple((id(ip), tuple(ip.position), tuple(ip.delta),
                  tuple(ip.offset), bool(ip.stringmode),
                  bool(getattr(ip, 'invertmode', False)),
                  bool(getattr(ip, 'queuemode', False)),
                  tuple(tuple(int(value) for value in frame)
                        for frame in ip.stack)) for ip in peer.ips)


def guarded_step(actor, peer, step):
    """Execute one Native step, prove actual p/s writes only actor-owned memory.

    `step(actor)` must execute one actual PyFunge step and perform the caller's
    usual IPStopped/IPQuitted handling. Return 1 for an executed checked p or s, else 0.
    This witness is deliberately a single-cell noninterference check; it does
    not claim complete program-state isolation or detect an uninstrumented
    write to an unrelated cell.
    """
    if actor.space is peer.space:
        raise AssertionError("Native candidate Programs share the same Funge-space object")
    if not actor.ips:
        step(actor)
        return 0
    if len(actor.ips) != 1:
        raise AssertionError("Native peer ownership witness expects one active IP")
    ip = actor.ips[0]
    opcode = int(actor.space.get(ip.position))
    if bool(ip.stringmode) or opcode not in (ord('p'), ord('s')):
        step(actor)
        return 0
    if opcode == ord('p'):
        target, coordinates, expected = physical_pg_operands(ip, 'p')
    else:
        # Funge-98 s stores into (IP position + IP delta), not relative
        # to the storage offset used by p/g. An empty TOSS pops zero.
        coordinates = (int(ip.position[0]) + int(ip.delta[0]),
                       int(ip.position[1]) + int(ip.delta[1]))
        target = ip.position.__class__(coordinates)
        stack = ip.stack[0]
        expected = int(stack[-1]) if stack else 0
    peer_target = peer._qa_point(coordinates)
    untouched_peer_byte = peer.space.get(peer_target)
    untouched_peer_ip = peer_ip_snapshot(peer)
    step(actor)
    if int(actor.space.get(target)) != expected:
        raise AssertionError("Native p/s did not write its expected physical Funge-space cell")
    if peer.space.get(peer_target) != untouched_peer_byte:
        raise AssertionError("Native p/s mutated the other Program's corresponding Funge-space cell")
    if peer_ip_snapshot(peer) != untouched_peer_ip:
        raise AssertionError("Native p/s mutated the other Program's IP or stack-stack state")
    return 1
