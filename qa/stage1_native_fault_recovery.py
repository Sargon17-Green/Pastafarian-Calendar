#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage-1 native PyFunge fault recovery on the EXACT same Program object.

A test-only exception is injected into live native opcode execution before
or after chosen actual g/p instructions. After an interrupted dirty run, the
SAME Program object is explicitly reinitialized, its old mutated Funge-space
is kept as independent evidence, and the recovered run is compared with
an independent native CLI execution of Befunge production code.

Python drives fault injection and checks byte-for-byte output; it contains NO
Pastafarian calendar arithmetic, nor a fallback calendar implementation.
"""
from __future__ import print_function
import StringIO
import subprocess

from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform

SOURCE = "src/interleaved_work_counts.b98"
with open(SOURCE,"rb") as fd:
    SOURCE_BYTES=fd.read()

COMMAND=["timeout","--kill-after=3s","50s",
         "pyfunge","--disable-fprint","--no-concurrent",
         "--no-filesystem","-v98","-d2",SOURCE]
VALID="1 15055672 1 15055670\n"
INVALID="2 10 0 10\n"
SCENARIOS=[
    ("p",1,"before"),
    ("p",1,"after"),
    ("p",3,"after"),
    ("p",20,"after"),
    ("p",90,"after"),
    ("g",1,"before"),
    ("g",1,"after"),
    ("g",20,"after"),
    ("g",80,"after"),
]
POINTS=((0,0),(5,0),(10,49),(500,1500),(1500,1750),
        (1528,2014),(3,49))

class DeliberateNativeFault(Exception):
    pass

def require(ok,why):
    if not ok:
        raise AssertionError(why)

def fresh_io(raw):
    stdout=StringIO.StringIO()
    platform=BufferedPlatform([],{},stdin=StringIO.StringIO(raw),stdout=stdout)
    return platform,stdout

def cli(raw):
    process=subprocess.Popen(COMMAND,stdin=subprocess.PIPE,
                             stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    stdout,stderr=process.communicate(raw)
    require(process.returncode==0,
            "independent native CLI failure exit=%d stderr=%r" %
            (process.returncode,stderr[-500:]))
    result=stdout.split()
    require(len(result)==7,"independent native CLI emitted %d fields" %
            len(result))
    return result

def snapshot(space,vector_type):
    return tuple(space.get(vector_type(p)) for p in POINTS)

VALID_NATIVE=cli(VALID)
INVALID_NATIVE=cli(INVALID)
require(INVALID_NATIVE==["-1"]*7,"native production invalid transport mismatch")

initial_platform,_=fresh_io("")
program=Program(Befunge98,platform=initial_platform)
identity=id(program)
print("NATIVE_FAULT_RECOVERY_REFERENCE_PREFLIGHT_PASS")
for index,(watch,depth,timing) in enumerate(SCENARIOS):
    # The dirty execution and its recovery run share the exact SAME object
    # identity, but no mutable Funge-space, interpreter semantics or streams.
    dirty_platform,dirty_output=fresh_io(VALID)
    Program.__init__(program,Befunge98,platform=dirty_platform)
    program.load_code(SOURCE_BYTES)
    program.create_ip()
    require(len(program.ips)==1,"dirty native execution has no initial IP")
    vector_type=program.ips[0].position.__class__
    require(id(program)==identity,"native object identity changed before injection")

    original_step=program.execute_step
    observed=[0]
    changed=[0]
    def injected_step(self):
        if not program.ips:
            return original_step()
        ip=program.ips[0]
        opcode=program.space.get(ip.position)
        selected=(opcode==ord(watch))
        if selected:
            observed[0]+=1
            if observed[0]==depth and timing=="before":
                raise DeliberateNativeFault("BEFORE %s at #%d" % (watch,depth))
        before=None
        if opcode==ord("p") and len(ip.stack[0])>=3:
            value,px,py=list(ip.stack[0])[-3:]
            pos=ip.position.__class__((px,py))
            before=(pos,program.space.get(pos))
        result=original_step()
        if before:
            point,prior=before
            if program.space.get(point)!=prior:
                changed[0]+=1
        if selected and observed[0]==depth and timing=="after":
            raise DeliberateNativeFault("AFTER %s at #%d" % (watch,depth))
        return result

    program.execute_step=injected_step.__get__(program,program.__class__)
    caught=None
    try:
        program.execute()
    except DeliberateNativeFault as err:
        caught=str(err)
    finally:
        # Restore the original method before Program.__init__ reset. This is
        # critical: preserving a test-only injection hook is NOT clean reuse.
        del program.execute_step

    require(caught is not None,
            "requested native execution fault not triggered: %r" %
            ((watch,depth,timing),))
    require(observed[0]==depth,
            "wrong native g/p instruction selected for fault")
    require(len(program.ips)>0,
            "injected fault did not interrupt a live instruction pointer")
    if depth>=20 and timing=="after":
        require(changed[0]>0,
                "faulted execution never actually changed mutable Funge-space")
    old_space=program.space
    old_semantics=program.semantics
    old_vectors=program.ips[0].position.__class__
    old_snapshot=snapshot(old_space,old_vectors)
    dirty_ips=len(program.ips)

    next_input=INVALID if index%2 else VALID
    next_expected=INVALID_NATIVE if index%2 else VALID_NATIVE
    platform,output=fresh_io(next_input)
    Program.__init__(program,Befunge98,platform=platform)
    require(id(program)==identity,"reset replaced exact native Program object")
    require(program.semantics is not old_semantics,
            "recovery kept stale native semantics instance")
    require(program.semantics.platform is platform,
            "recovery kept stale native input/output platform")
    require(program.space is not old_space,
            "recovery retained fault-dirtied Funge-space")
    require(not program.ips,"reset retained faulted instruction pointers")
    program.load_code(SOURCE_BYTES)
    program.create_ip()
    ip=program.ips[0]
    require(tuple(ip.position)==(0,0) and tuple(ip.delta)==(1,0),
            "fresh recovered native IP direction/position corrupted")
    require(len(ip.stack[0])==0,"recovered native IP stack contaminated")
    program.execute()
    require(not program.ips,"recovered native Program did not quit")
    got=output.getvalue().split()
    require(got==next_expected,
            "native recovery output differs from separate native CLI: "+
            repr((watch,depth,timing,got,next_expected)))
    require(snapshot(old_space,old_vectors)==old_snapshot,
            "recovered native invocation modified prior aborted Funge-space")
    print("NATIVE_SAME_PROGRAM_FAULT_ROLLBACK_PASS",
          index,watch,depth,timing,
          "dirty_p_cell_changes",changed[0],
          "dirty_live_ips",dirty_ips,
          "recovered_output_fields",len(got))
print("NATIVE_SAME_PROGRAM_EXPLICIT_FAULT_RESET_PASS",
      len(SCENARIOS),"injections/recoveries")
print("SCOPE: explicit reinitialization after test-injected g/p failure; "
      "not implicit in-place rollback and not full Stage 1 ownership proof")
