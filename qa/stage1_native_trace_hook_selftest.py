#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native PyFunge-98 QA: trace g/p physical storage offsets and string mode.

This test runs real Befunge-98 code on the pinned PyFunge interpreter.
The calendar is not calculated in Python. No production code is changed.
"""
from __future__ import print_function
import os
import subprocess
import sys
import tempfile
import contextlib
import shutil
import StringIO
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform

def need(condition, why):
    if not condition:
        raise AssertionError(why)

def child(kind):
    output = StringIO.StringIO()
    program = Program(Befunge98, platform=BufferedPlatform(
        [], {}, stdin=StringIO.StringIO(""), stdout=output))
    code = '812p12g.@' if kind == 'offset' else '123"pg"n@'
    program.load_code(code)
    program.create_ip()
    need(len(program.ips) == 1, "missing real native instruction pointer")
    ip = program.ips[0]
    if kind == 'offset':
        ip.offset = ip.position.__class__((7, 9))
    program.execute()
    need(not program.ips, "native synthetic source failed to terminate")
    if kind == 'offset':
        need(output.getvalue().split() == ['8'],
             "real native storage-offset g/p arithmetic result incorrect")
        point = ip.position.__class__((8, 11))
        raw = ip.position.__class__((1, 2))
        need(int(program.space.get(point)) == 8 and
             int(program.space.get(raw)) == 32,
             "native p did not use the physical offset target")
    else:
        need(output.getvalue() == "",
             "quoted g/p synthetic program produced unexpected output")
    print("NATIVE_TRACE_HOOK_CHILD_PASS", kind)

def trace_events(path):
    with open(path, 'rb') as fh:
        rows = [x.strip().split('\t') for x in fh.read().splitlines()]
    need(any(x[0] == 'STEP' for x in rows), "missing hooked Native STEP events")
    return rows

@contextlib.contextmanager
def owned_temporary_directory():
    path = tempfile.mkdtemp(prefix='native-bf98-trace-')
    try:
        yield path
    finally:
        shutil.rmtree(path)

def parent():
    with owned_temporary_directory() as tmp:
        evidence = {}
        for kind in ('offset', 'quoted'):
            filename = os.path.join(tmp, kind + '.tsv')
            environ = os.environ.copy()
            environ['BF98_TRACE_LOG'] = filename
            environ['PYFUNGE_NO_PSYCO'] = '1'
            qa = os.path.dirname(os.path.abspath(__file__))
            environ['PYTHONPATH'] = qa + os.pathsep + environ.get('PYTHONPATH', '')
            subprocess.check_call(
                [sys.executable, os.path.abspath(__file__), '--child', kind],
                env=environ)
            evidence[kind] = trace_events(filename)
        by_tag = {}
        for row in evidence['offset']:
            by_tag.setdefault(row[0], []).append(row)
        for tag in ('WRITE_BEFORE', 'WRITE_AFTER', 'READ_BEFORE', 'READ_AFTER'):
            need(len(by_tag.get(tag, [])) == 1,
                 "unexpected Native offset trace event count: " + tag)
            need(by_tag[tag][0][2:4] == ['8', '11'],
                 "g/p trace used raw operands instead of physical storage offset")
        need(by_tag['WRITE_BEFORE'][0][4:] == ['32', '8'] and
             by_tag['WRITE_AFTER'][0][4:] == ['8'] and
             by_tag['READ_BEFORE'][0][4:] == ['8'] and
             by_tag['READ_AFTER'][0][4:] == ['8'],
             "physical Native write/read memory contents are incorrect")
        need(not any(row[0].startswith(('READ_', 'WRITE_'))
                     for row in evidence['quoted']),
             "quoted g/p emitted spurious physical memory events")
        need(any(row[7] == str(ord('g')) for row in evidence['quoted']
                 if row[0] == 'STEP') and
             any(row[7] == str(ord('p')) for row in evidence['quoted']
                 if row[0] == 'STEP'),
             "quoted Native g/p instruction cells were never executed")
    print("NATIVE_BF98_TRACE_HOOK_OFFSET_AND_STRINGMODE_PASS")
    print("STAGE1_FUNCTIONAL_AND_GEOMETRIC_FINAL_GATES_OPEN")

if __name__ == '__main__':
    need((len(sys.argv) == 1) or
         (len(sys.argv) == 3 and sys.argv[1] == '--child' and
          sys.argv[2] in ('offset', 'quoted')),
         "usage: native trace hook test [--child offset|quoted]")
    if len(sys.argv) == 1:
        parent()
    else:
        child(sys.argv[2])
