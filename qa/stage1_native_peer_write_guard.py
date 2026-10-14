#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA-only Native Funge-space ownership guard at every actually executed p.

Independent Program objects can have distinct `space` wrappers but accidentally
share or poison underlying cells. Sparse fixed sentinels alone cannot detect a
cross-write elsewhere. This helper checks the exact *physical* put target
against the other live Program before/after every put. It is Python 2/3 safe.
"""
from stage1_native_pg_physical_address import physical_pg_operands


def guarded_step(actor, peer, step):
    """Execute one Native step, prove actual p writes only actor-owned memory.

    `step(actor)` must execute one actual PyFunge step and perform the caller's
    usual IPStopped/IPQuitted handling. Return 1 for checked executed p, else 0.
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
    if bool(ip.stringmode) or int(actor.space.get(ip.position)) != ord('p'):
        step(actor)
        return 0
    target, coordinates, expected = physical_pg_operands(ip, 'p')
    peer_target = peer._qa_point(coordinates)
    untouched_peer_byte = peer.space.get(peer_target)
    step(actor)
    if int(actor.space.get(target)) != expected:
        raise AssertionError("Native p did not write its expected physical Funge-space cell")
    if peer.space.get(peer_target) != untouched_peer_byte:
        raise AssertionError("Native p mutated the other Program's corresponding Funge-space cell")
    return 1
