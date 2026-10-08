#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native Befunge-98 exact SAME PyFunge Program object reset/replay.

This exercises an explicitly defined reset between executions: replace the
completed Program's mutable Funge-space, fresh I/O platform, and create a new
IP. Reuse the SAME Program object identity across every call. Merely calling
Program.load_code on previously mutated Funge-space is NOT a reset.

No Python computation of calendar reference values. Every expected output is
obtained from an independent native CLI PyFunge-98 process running exactly
the same Befunge code. Dedicated native reference/fixture suites test math.
"""
from __future__ import print_function
import StringIO
import subprocess

from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform

SOURCES = [
    "src/interleaved_work_counts.b98",
    "qa/interleaved_work_counts_pre_lexical_baseline.b98",
]
CODES = {}
for path in SOURCES:
    with open(path,"rb") as stream:
        CODES[path] = stream.read()

CMD = ["timeout","--kill-after=2s","50s",
       "pyfunge","--disable-fprint","--no-concurrent",
       "--no-filesystem","-v98","-d2"]

def run_cli(path,input_text):
    proc=subprocess.Popen(CMD+[path],stdin=subprocess.PIPE,
                          stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    out,err=proc.communicate(input_text)
    if proc.returncode:
        raise AssertionError("native baseline process error %s rc=%d stderr=%r" %
                             (path,proc.returncode,err[-500:]))
    result=out.split()
    if len(result)!=7:
        raise AssertionError("native CLI non-seven-value output %r" % result)
    return result

def fresh_platform(raw):
    stdout=StringIO.StringIO()
    platform=BufferedPlatform([],{},stdin=StringIO.StringIO(raw),stdout=stdout)
    return platform,stdout

def sample(space,vector_cls):
    positions=((0,0),(5,0),(10,49),(500,1500),(100,500),(1528,2014))
    return tuple(space.get(vector_cls(p)) for p in positions)

def replay(program,source_path,raw,iteration,previous):
    if program.ips:
        raise AssertionError("prior native IP was not fully terminated")

    old_space=program.space
    if previous:
        old_snapshot,old_vector_type=previous
        if sample(old_space,old_vector_type)!=old_snapshot:
            raise AssertionError("prior completed Funge-space changed before reset")
    platform,stdout=fresh_platform(raw)

    # Explicit reset/reload; object identity must remain unchanged.
    program.platform=platform
    program.space=program.semantics.create_space()
    if program.space is old_space:
        raise AssertionError("new run reused previous mutable Funge-space")
    program.load_code(CODES[source_path])
    program.create_ip()
    if len(program.ips)!=1:
        raise AssertionError("reset failed to create one fresh instruction pointer")
    ip=program.ips[0]
    vector_cls=ip.position.__class__
    if tuple(ip.position)!=(0,0) or tuple(ip.delta)!=(1,0):
        raise AssertionError("fresh IP initial position/direction corrupted")
    if len(ip.stack[0])!=0:
        raise AssertionError("new IP stack not empty at execution start")
    if program.space.get(vector_cls((0,0)))!=ord(CODES[source_path][0:1]):
        raise AssertionError("source entry is not freshly loaded")

    if len(stdout.getvalue())!=0:
        raise AssertionError("unexpected output before execute")
    result=program.execute()
    if program.ips:
        raise AssertionError("native Program.execute left unclean IP list")
    got=stdout.getvalue().split()
    expected=run_cli(source_path,raw)
    if got!=expected:
        raise AssertionError("same Program reset/replay %d %r got=%r expected=%r" %
                             (iteration,raw,got,expected))
    # Previous Funge-space object must remain untouched by the new run.
    if previous:
        old_snapshot,old_vector_type=previous
        if sample(old_space,old_vector_type)!=old_snapshot:
            raise AssertionError("new Program run contaminated old Funge-space")
    return sample(program.space,vector_cls),vector_cls

qa=SOURCES[0]
original=SOURCES[1]
CASES=[
    (qa,"1 15055672 1 15055670\n"),
    (qa,"2 10 0 10\n"),
    (qa,"0 -1 0 1\n"),
    (qa,"0 0 0 0\n"),
    (qa,"1 15055671 1 15055671\n"),
    (original,"0 1 0 1\n"),
    (qa,"0 -1 0 1\n"),
    (original,"0 -1 0 1\n"),
    (qa,"0 123456789 1 987654321\n"),
    (qa,"1 987654321 0 123456789\n"),
    (qa,"0 170141183460469231731687303715884105727 1 1\n"),
    (qa,"1 0 0 0\n"),
    (qa,"0 1 0 2\n"),
    (qa,"0 2 0 1\n"),
    (original,"1 15055672 1 15055670\n"),
    (qa,"0 1 0 1\n"),
]
if run_cli(original,"0 -1 0 1\n")!=run_cli(original,"0 1 0 1\n"):
    raise AssertionError("old source no longer exhibits the lexical bug")
if run_cli(qa,"0 -1 0 1\n")==run_cli(qa,"0 1 0 1\n"):
    raise AssertionError("QA source still accepts the forbidden sign")

platform,output=fresh_platform("")
program=Program(Befunge98,platform=platform)
identity=id(program)
previous=None
print("NATIVE_SAME_PROGRAM_RESET_PREFLIGHT_PASS")
for iteration,(source_path,raw) in enumerate(CASES):
    previous=replay(program,source_path,raw,iteration,previous)
    if id(program)!=identity:
        raise AssertionError("test accidentally replaced Program object")
    print("NATIVE_SAME_PROGRAM_OBJECT_REPLAY_PASS",iteration,
          source_path,repr(raw.strip()))
print("NATIVE_SAME_PROGRAM_OBJECT_RESET_PASS",len(CASES),
      "runs in exact same object with clean spaces/IPs/streams")
print("SCOPE: explicit reset contract. In-place no-reset execution is NOT safe.")
