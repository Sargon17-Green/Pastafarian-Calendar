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



def storage_offset_native_regression():
    """Run real native p/g with nonzero storage offsets and underflow.

    Each Program is independent. Physical p/g receipt coordinates must
    include the active BF98 storage offset, not only popped x/y operands.
    """
    cases = (
        ('>700p00g.@', (100, 200), ['7'], ('p', 'g'), (100, 200), 7),
        ('>p@', (100, 200), [], ('p',), (100, 200), 0),
        ('>9p@', (-17, 8), [], ('p',), (-17, 17), 0),
        ('>700p00g.@', (-17, 8), ['7'], ('p', 'g'), (-17, 8), 7),
    )
    for code, offset, expected_output, expected_kinds, target, expected_value in cases:
        output = StringIO.StringIO()
        program = Program(Befunge98, platform=BufferedPlatform(
            [], {}, stdin=StringIO.StringIO(''), stdout=output))
        program.load_code(code)
        program.create_ip()
        need(len(program.ips) == 1, 'storage-offset probe needs one IP')
        ip = program.ips[0]
        ip.offset = ip.position.__class__(offset)
        position_type = ip.position.__class__
        target_vector = position_type(target)
        original_step = program.execute_step
        seen = []

        def observer(self):
            need(len(self.ips) == 1, 'native p/g offset probe IP count drifted')
            current = self.ips[0]
            opcode = int(self.space.get(current.position))
            kind = fork.actual_memory_opcode(opcode, bool(current.stringmode))
            if kind:
                point, coord, value = fork.physical_pg_operands(current, kind)
                need(tuple(coord) == target and tuple(point) == target,
                     'native p/g operand mapper ignored storage offset')
                before = int(self.space.get(point))
            result = original_step()
            if kind:
                if kind == 'p':
                    need(value == expected_value and
                         int(self.space.get(point)) == value,
                         'Native p wrote wrong physical storage-offset cell')
                else:
                    need(current.stack[0] and int(current.stack[0][-1]) == before,
                         'Native g read wrong physical storage-offset cell')
                seen.append(kind)
            return result

        program.execute_step = observer.__get__(program, program.__class__)
        try:
            program.execute()
        finally:
            del program.execute_step
        need(not program.ips and output.getvalue().split() == expected_output,
             'Native p/g offset run did not complete with expected output')
        need(tuple(seen) == expected_kinds,
             'Native p/g offset opcode/receipt execution order drifted')
        need(int(program.space.get(target_vector)) == expected_value,
             'Native physical p write did not persist at storage-offset cell')
        need(int(program.space.get(position_type((0, 0)))) == ord('>'),
             'Native relative p erroneously overwrote program entry cell')
        print('NATIVE_PG_STORAGE_OFFSET_REAL_INTERPRETER_PASS', offset, code)
    print('NATIVE_PG_OFFSET_UNDERFLOW_FOUR_REAL_PROGRAMS_PASS')


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
    storage_offset_native_regression()
    print('STAGE1_OPEN=YES; FULL_NATIVE_ACCEPTANCE=NO')


if __name__ == '__main__':
    main()
