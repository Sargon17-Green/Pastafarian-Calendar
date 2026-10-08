#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native PyFunge single-Python-process ownership/reentrancy regression.

NO calendar arithmetic is implemented in Python here. CLI PyFunge provides
the expected semantic results, while the identical native Befunge-98 source
is evaluated via independent Program objects inside ONE interpreter process.
A separate native oracle-differential suite validates mathematical truth.

Scope: fresh Program objects in one Python interpreter; interleaved step-by-
step execution of two Program objects. Reusing the exact same Program/Funge-
space without resetting it is explicitly NOT validated here.
"""
from __future__ import print_function
import os
import subprocess
import sys
import StringIO

from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform

CMD = ["timeout","--kill-after=2s","50s","pyfunge",
       "--disable-fprint","--no-concurrent","--no-filesystem",
       "-v98","-d2"]
PATHS = [
    "src/interleaved_work_counts.b98",
    "qa/interleaved_work_counts_lexical_candidate.b98"
]
source = {}
for path in PATHS:
    with open(path,"rb") as fh:
        source[path] = fh.read()

def native_cli(path, stdin):
    runner = subprocess.Popen(CMD+[path],stdin=subprocess.PIPE,
                              stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    out,err = runner.communicate(stdin)
    if runner.returncode:
        raise AssertionError("CLI Native PyFunge failed %s input=%r rc=%d stderr=%r"
                             % (path, stdin, runner.returncode, err[-700:]))
    return out.split()

def make_instance(path, input_text):
    """Documented PyFunge v0.5-rc2 library APIs; no source or numeric fallback."""
    instream = StringIO.StringIO(input_text)
    outstream = StringIO.StringIO()
    platform = BufferedPlatform([],{},stdin=instream,stdout=outstream)
    program = Program(Befunge98,platform=platform)
    program.load_code(source[path])
    if not program.ips:
        program.create_ip()
    if len(program.ips) != 1:
        raise AssertionError("unexpected initial IP count")
    return program, outstream

def run_instance(path, input_text):
    program, outstream = make_instance(path,input_text)
    result = program.execute()
    if program.ips:
        raise AssertionError("native Program.execute returned with active IPs")
    return program, outstream.getvalue().split()

def compare(path, input_text):
    expected=native_cli(path,input_text)
    program,observed=run_instance(path,input_text)
    if observed!=expected:
        raise AssertionError("same-process result differs from native CLI %s %r %r %r"
                             % (path,input_text,observed,expected))
    return program

# Check API usage with a tiny native Befunge program before loading the huge source.
tiny=StringIO.StringIO()
probe=Program(Befunge98,platform=BufferedPlatform(
    [],{},stdin=StringIO.StringIO(""),stdout=tiny))
probe.load_code("12+.@")
if not probe.ips:
    probe.create_ip()
probe.execute()
if tiny.getvalue().split()!=["3"]:
    raise AssertionError("PyFunge Program API smoke did not produce 3")
print("NATIVE_PROGRAM_LIBRARY_API_PREFLIGHT_PASS")

inputs=[
    "0 0 0 0\n",
    "1 15055672 1 15055670\n",
    "0 123456789 1 987654321\n",
    "1 987654321 0 123456789\n",
    "0 10 0 20\n",
    "1 0 0 0\n",
    "2 10 0 10\n"
]
created=[]
snapshots=[]
guard_positions=((0,0),(5,0),(10,49),(500,1500),(100,500),(1528,2014))
for j in [0,1,0,4,2,3,1,5,6,0,2,4]:
    for path in PATHS:
        program=compare(path,inputs[j])
        created.append(program)
        snapshots.append((program,tuple(program.space.get(p)
                                        for p in guard_positions)))
for program,expected in snapshots:
    actual=tuple(program.space.get(p) for p in guard_positions)
    if actual!=expected:
        raise AssertionError("previous native Program was mutated by a later run")
if len(set(id(p.space) for p in created)) != len(created):
    raise AssertionError("independent Program instances unexpectedly share Funge-space")
print("NATIVE_SAME_PYTHON_PROCESS_FRESH_PROGRAM_PASS",len(created),"runs",
      "preserved_finished_program_snapshots",len(snapshots))

def interleaved(a_case,b_case):
    a_path=PATHS[1]
    b_path=PATHS[0]
    ea=native_cli(a_path,a_case)
    eb=native_cli(b_path,b_case)
    a,ao=make_instance(a_path,a_case)
    b,bo=make_instance(b_path,b_case)
    if a.space is b.space:
        raise AssertionError("two live Program instances share Funge-space")
    ticks=0
    while a.ips or b.ips:
        if ticks>=150000:
            raise AssertionError("native interleaved Program.execute_step timeout")
        if a.ips:
            a.execute_step()
        if b.ips:
            b.execute_step()
        ticks+=1
    got_a=ao.getvalue().split()
    got_b=bo.getvalue().split()
    if got_a!=ea or got_b!=eb:
        raise AssertionError("native interleaved process mismatch (%r,%r), (%r,%r)"
                             % (got_a,ea,got_b,eb))
    print("NATIVE_INTERLEAVED_PROGRAM_INSTANCES_PASS",
          "ticks",ticks,"inputs",repr(a_case),repr(b_case))

interleaved(inputs[1],inputs[0])
interleaved(inputs[2],inputs[6])
print("NATIVE_SAME_INTERPRETER_INSTANCE_ISOLATION_PASS",
      "24 sequential Program executions; two overlapping Program pairs")
print("LIMITATION: same Program object reused without an explicit reset remains UNTESTED")
