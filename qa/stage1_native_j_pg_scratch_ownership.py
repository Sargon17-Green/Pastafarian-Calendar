#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native QA of the new arithmetic j/p/g scratch cell's invocation ownership.

Runs the SAME PyFunge Program identity across successful upper/lower routes,
a fault injected after the actual upper-arm p write, and explicit recovery.
Every calendar output is compared with independent Native Befunge references.
No calendar arithmetic or pseudo-interpreter is implemented by Python.
"""
from __future__ import print_function
import StringIO
import sys

from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_diverse_geometry as suite

SOURCE="src/interleaved_work_counts.b98"
CELL=(1490,1600)
UP=(0,0,0,0)
DOWN=(1,15055672,1,15055670)
INVALID=(2,10,0,10)
with open(SOURCE,"rb") as file:
    CODE=file.read()
rows=CODE.split("\n")
p_col=rows[1334].index("p",959)
g_col=rows[1334].index("g",959)
P=(p_col,1334)
G=(g_col,1334)
require_input=(p_col<g_col and rows[1334][1027]=="x"
               and rows[1331][958]=="j")
if not require_input:raise AssertionError("approved j/p/g source geometry drift")

class NativeInjectedFault(Exception):
    pass

def require(ok,msg):
    if not ok:raise AssertionError(msg)

def ref(fields):
    result=suite.expected_for(*fields) if fields!=INVALID else ["-1"]*7
    require(len(result)==7,"independent Befunge oracle shape wrong")
    return result

def fresh_streams(fields):
    raw=" ".join(map(str,fields))+"\n"
    stdout=StringIO.StringIO()
    platform=BufferedPlatform([],{},stdin=StringIO.StringIO(raw),stdout=stdout)
    return platform,stdout

platform,out=fresh_streams(UP)
program=Program(Befunge98,platform=platform)
identity=id(program)
previous=None
previous_scratch=None

def replay(label,fields,inject_after_p=False):
    global previous,previous_scratch
    platform,output=fresh_streams(fields)
    Program.__init__(program,Befunge98,platform=platform)
    require(id(program)==identity,"Native Program object changed")
    if previous is not None:
        require(program.space is not previous,
                "Native reset retained previous mutable Funge-space")
    program.load_code(CODE)
    program.create_ip()
    require(len(program.ips)==1,"Native rerun has no initial instruction pointer")
    vec=program.ips[0].position.__class__
    cell=vec(CELL)
    blank=program.space.get(cell)
    require(blank==32,"new invocation inherited modified scratch Funge cell")
    original_step=program.execute_step
    hit={"p":0,"g":0}
    def instrumented_step(self):
        if program.ips:
            ip=program.ips[0]
            pt=tuple(ip.position)
        else:pt=None
        if pt==P:
            hit["p"]+=1
            require(program.space.get(cell)==32,
                    "Native arithmetic scratch cell dirty before p")
        if pt==G:
            hit["g"]+=1
            require(program.space.get(cell)==12,
                    "Native p did not write required scalar before g")
        outcome=original_step()
        if pt==P:
            require(program.space.get(cell)==12,
                    "Native p failed to own and write the exact scratch cell")
            if inject_after_p:
                raise NativeInjectedFault("Injected immediately after real Native p")
        if pt==G:
            require(program.ips and int(program.ips[0].stack[0][-1])==12,
                    "Native g did not return previously written scalar")
        return outcome

    program.execute_step=instrumented_step.__get__(program,program.__class__)
    caught=False
    try:
        program.execute()
    except NativeInjectedFault:
        caught=True
    finally:
        del program.execute_step

    expect_upper = fields in (UP,INVALID)
    if inject_after_p:
        require(caught and len(program.ips)==1 and
                hit["p"]==1 and hit["g"]==0,
                "fault did not interrupt between Native p and g")
        require(program.space.get(cell)==12,
                "dirty interrupted native Funge-space was not retained")
    else:
        require(not caught and not program.ips,
                "Native invocation failed to halt successfully")
        expected=ref(fields)
        require(output.getvalue().split()==expected,
                "Native Program output differs from independent Befunge reference")
        require(hit["p"]==int(expect_upper) and
                hit["g"]==int(expect_upper),
                "native input-dependent route used p/g in the wrong arm")
        require(program.space.get(cell)==(12 if expect_upper else 32),
                "Native per-invocation scratch write not branch-owned")
    if previous is not None:
        require(previous.get(previous_scratch[0])==previous_scratch[1],
                "new invocation retroactively modified prior Funge-space")
    previous=program.space
    previous_scratch=(cell,program.space.get(cell))
    print("NATIVE_J_PG_SCRATCH_OWNER_REPLAY_PASS",label,
          "same_program",id(program)==identity,
          "native_p",hit["p"],"native_g",hit["g"],
          "fault_injected",caught,"cell_after",program.space.get(cell))
    sys.stdout.flush()

replay("upper_success",UP)
replay("down_after_upper",DOWN)
replay("fault_after_native_p",UP,inject_after_p=True)
replay("upper_after_fault_reset",UP)
replay("invalid_after_upper",INVALID)
print("NATIVE_J_PG_SAME_PROGRAM_SCRATCH_RESET_PASS",5,"invocations")
print("SCOPE: Native explicit reset after p/g fault; not automatic rollback or full Stage 1 ownership")

