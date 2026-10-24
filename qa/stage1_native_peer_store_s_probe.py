#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native PyFunge ownership of s writes at IP+delta in overlapping Programs.

Run inside pinned Python 2.7 / PyFunge 0.5-rc2; QA only, Stage 1 open.
"""
from __future__ import print_function
import StringIO
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
from funge.exception import IPQuitted, IPStopped
from stage1_native_peer_write_guard import guarded_step


def need(ok, why):
    if not ok:
        raise AssertionError(why)


def new_program(code):
    out = StringIO.StringIO()
    platform = BufferedPlatform([], {}, stdin=StringIO.StringIO(''), stdout=out)
    p = Program(Befunge98, platform=platform)
    p.load_code(code)
    if not p.ips:
        p.create_ip()
    need(len(p.ips) == 1, 'Native s smoke requires one IP')
    p._qa_point = p.ips[0].position.__class__
    return p, out


def step_one(program):
    if not program.ips:
        return
    ip = program.ips[0]
    try:
        program.execute_step()
    except IPStopped:
        program.remove_ip(ip)
    except IPQuitted:
        for existing in list(program.ips):
            program.remove_ip(existing)


def main():
    # 8*8 => ASCII @ (64); s at x=4 stores it over '0' at x=5.
    # This is a real executable source write, not a Python mock.
    code = '>88*s0@'
    a, ao = new_program(code)
    b, bo = new_program(code)
    need(a.space is not b.space, 'Native Programs share a Funge-space')
    point = a._qa_point((5, 0))
    need(a.space.get(point) == b.space.get(point) == ord('0'),
         'Native s code did not load its original next cell')
    a.ips[0].offset = a._qa_point((999, -500))
    checked = 0
    ticks = 0
    while a.ips or b.ips:
        need(ticks < 40, 'Native s programs did not terminate')
        checked += guarded_step(a, b, step_one)
        checked += guarded_step(b, a, step_one)
        ticks += 1
    need(checked == 2, 'both real Native s writes were not checked')
    need(a.space.get(point) == b.space.get(point) == 64,
         'Native s missed its physical next source cell')
    need(ao.getvalue() == bo.getvalue() == '',
         'Native s smoke produced unexpected output')

    # BF98 pops zero on an empty TOSS; s must store physical zero.
    a, ao = new_program('>s0@')
    b, bo = new_program('>s0@')
    target = a._qa_point((2, 0))
    need(a.space.get(target) == b.space.get(target) == ord('0'),
         'Native underflow fixture was not loaded')
    checked = 0
    ticks = 0
    while a.ips:
        need(ticks < 15, 'Native s underflow run did not terminate')
        checked += guarded_step(a, b, step_one)
        ticks += 1
    need(checked == 1 and a.space.get(target) == 0,
         'Native s underflow must store zero')
    need(b.space.get(b._qa_point((2, 0))) == ord('0'),
         'Native underflow s corrupted the paused peer')
    need(not ao.getvalue(), 'Native underflow emitted unexpected output')
    print('NATIVE_PEER_STORE_S_OVERLAPPING_AND_UNDERFLOW_PASS')
    print('QA_ONLY_STAGE1_OPEN')


if __name__ == '__main__':
    main()
