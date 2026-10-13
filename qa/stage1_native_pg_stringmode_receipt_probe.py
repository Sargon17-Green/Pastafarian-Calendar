#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native BF98 QA: quoted p/g are data, not physical memory operations.

Run inside the pinned Python-2/PyFunge environment. No production edits.
"""
from __future__ import print_function
import StringIO
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_current_fork_route_differential as fork


def need(ok, why):
    if not ok:
        raise AssertionError(why)


def run_native(code, expected_output, expected_receipts):
    output = StringIO.StringIO()
    platform = BufferedPlatform([], {}, stdin=StringIO.StringIO(''), stdout=output)
    program = Program(Befunge98, platform=platform)
    program.load_code(code)
    program.create_ip()
    original_step = program.execute_step
    observations = []
    steps = [0]

    def observer(self):
        steps[0] += 1
        need(steps[0] <= 100, 'small native BF98 test did not terminate')
        need(len(self.ips) == 1, 'native BF98 quote test has multiple IPs')
        ip = self.ips[0]
        byte = int(self.space.get(ip.position))
        stringmode = bool(ip.stringmode)
        kind = fork.actual_memory_opcode(byte, stringmode)
        if byte in (ord('p'), ord('g')):
            observations.append((chr(byte), stringmode, kind))
        return original_step()

    program.execute_step = observer.__get__(program, program.__class__)
    try:
        program.execute()
    finally:
        del program.execute_step
    need(not program.ips, 'native quoted p/g program did not halt')
    need(output.getvalue().split() == expected_output,
         'native BF98 quoted p/g produced unexpected output')
    need(observations == expected_receipts,
         'Native executed/mode-dependent p/g receipts disagree')
    return len(observations), steps[0]


def main():
    # Pure selector exhaustively checked, then observed against real PyFunge.
    for mode in (0, 1):
        for byte in range(256):
            expected = None if mode else ('p' if byte == 112 else
                                          'g' if byte == 103 else None)
            need(fork.actual_memory_opcode(byte, mode) == expected,
                 'selector misclassified BF98 byte/mode')
    quoted = [('p', True, None), ('g', True, None)]
    executed = [('p', False, 'p'), ('g', False, 'g')]
    q1 = run_native('>"pg"..@', ['103', '112'], quoted)
    real = run_native('>700p00g.@', ['7'], executed)
    q2 = run_native('>"pg"..@', ['103', '112'], quoted)
    need(q1 == q2, 'quoted BF98 isolation changed after actual p/g execution')
    print('NATIVE_QUOTED_PG_NOT_MEMORY_OPERATIONS_PASS')
    print('NATIVE_REAL_PG_STILL_OBSERVED_PASS')
    print('NATIVE_QUOTE_REAL_QUOTE_REENTRANCY_PASS')
    print('STAGE1_OPEN=YES; FULL_NATIVE_ACCEPTANCE=NO')


if __name__ == '__main__':
    main()
