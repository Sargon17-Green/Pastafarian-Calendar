#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Real PyFunge-98 four-cell candidate same-process order/ownership audit.

The 49-route receipts independently prove finite domain oracle parity.
This regression adds alternating, repeated, and *overlapping* independent
Native Program instances for the four-cell candidate in one Python process.
All expected calendar outputs come from independent Native Befunge oracles.
No Python calendar implementation, promotion, or Stage 2 changes.

Scope excludes reusing one Program object without an explicit reset:
PyFunge's ended Program object is not a fresh execution environment.
"""
from __future__ import print_function
import hashlib
import sys
import StringIO

from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
from funge.exception import IPQuitted, IPStopped

import stage1_native_diverse_geometry as native
import stage1_native_lower_feedback_semantic_candidate as candidate

BASE="560d6aa5807a7f766213a33835cce85eab0fa40c"
FOUR="d965ce4bdfa282f2d3b82690808def5a2dde10a8"

def need(condition,message):
    if not condition:
        raise AssertionError(message)

with open(native.SOURCE,"rb") as stream:
    source=stream.read()
need(candidate.git_blob(source)==BASE,"Native source pin drifted")
code=candidate.candidate_bytes(source)
need(candidate.git_blob(code)==FOUR,"Native candidate pin drifted")

# Alternation deliberately crosses both directions of the real |, includes
# equal days, and revisits earlier inputs after intervening mutations.
cases=(
    ("lower_negative", (1,3,1,3)),
    ("upper_positive", (0,3,0,3)),
    ("cross_lower", (1,3,0,2)),
    ("cross_upper", (0,1,1,2)),
    ("zero_equal", (0,0,0,0)),
    ("lower_repeat", (1,1,1,1)),
    ("upper_zero", (0,0,0,3))
)
oracle={}
for label,fields in cases:
    oracle[label]=native.expected_for(*fields)
    need(len(oracle[label])==7,"Native independent oracle field count")

def raw(fields):
    return " ".join(map(str,fields))+"\n"

def new_program(fields):
    output=StringIO.StringIO()
    platform=BufferedPlatform([],{},stdin=StringIO.StringIO(raw(fields)),
                              stdout=output)
    program=Program(Befunge98,platform=platform)
    program.load_code(code)
    if not program.ips:
        program.create_ip()
    need(len(program.ips)==1,"Native candidate created multiple initial IPs")
    return program,output

guard_positions=((0,0),(0,49),(951,1335),(951,1337),(952,1336),
                 (700,0),(701,0),(1528,2014))

def sample(program):
    # Sampling Funge-space tests separation of completed, mutable state.
    point=program._qa_point
    return tuple(program.space.get(point(coords)) for coords in guard_positions)

def make_point(program):
    program._qa_point=program.ips[0].position.__class__
    return program

anchors=[]
sequence=(0,1,2,3,4,2,1,0,5,6,0,3,1,2)
for index in sequence:
    label,fields=cases[index]
    program,out=new_program(fields)
    make_point(program)
    need(all(program.space is not p.space for p,_ in anchors),
         "Native separate candidate Programs share Funge-space")
    program.execute()
    need(not program.ips,"Native candidate left active IPs")
    got=out.getvalue().split()
    need(got==oracle[label],"same-process candidate vs Native Befunge reference mismatch "+label)
    if len(anchors)<2:
        anchors.append((program,sample(program)))
    for held,saved in anchors:
        need(sample(held)==saved,
             "completed candidate Program state mutated by another Native execution")
    print("NATIVE_FOUR_CELL_REPEATED_ORDER",label,"PASS")
    sys.stdout.flush()
program=None
print("NATIVE_FOUR_CELL_CANDIDATE_ALTERNATING_ORDER_14_PASS")

def tick_one(program):
    if not program.ips:
        return
    need(len(program.ips)==1,"Native interleaved candidate unexpectedly forked IP")
    ip=program.ips[0]
    try:
        program.execute_step()
    except IPStopped:
        program.remove_ip(ip)
    except IPQuitted:
        for existing in list(program.ips):
            program.remove_ip(existing)

for ia,ib in ((0,1),(2,3),(4,5)):
    label_a,fields_a=cases[ia]
    label_b,fields_b=cases[ib]
    a,ao=new_program(fields_a)
    b,bo=new_program(fields_b)
    make_point(a);make_point(b)
    need(a.space is not b.space,"two simultaneous candidate Programs share Funge-space")
    # Before executing any opcode, prove one Program's stepping cannot
    # mutate the other Program's untouched Funge-space.
    untouched_b=sample(b)
    tick_one(a)
    need(sample(b)==untouched_b,
         "first Native candidate step changed the other live Program's source")
    ticks=1
    while a.ips or b.ips:
        need(ticks<100000,"Native interleaved candidate ran beyond 100000 ticks")
        tick_one(a)
        tick_one(b)
        ticks+=1
    need(ao.getvalue().split()==oracle[label_a],
         "interleaved candidate A diverged from Native reference "+label_a)
    need(bo.getvalue().split()==oracle[label_b],
         "interleaved candidate B diverged from Native reference "+label_b)
    for held,saved in anchors:
        need(sample(held)==saved,
             "candidate interleaving poisoned completed prior Program")
    print("NATIVE_FOUR_CELL_INTERLEAVED_ORDER_PASS",
          label_a,label_b,"ticks",ticks)
    sys.stdout.flush()

print("NATIVE_FOUR_CELL_SAME_PROCESS_14_SEQUENTIAL_3_INTERLEAVED_PAIRS_PASS")
print("QA_ONLY; SAME_PROGRAM_OBJECT_REUSE_WITHOUT_RESET_NOT_CLAIMED; STAGE1_OPEN")
