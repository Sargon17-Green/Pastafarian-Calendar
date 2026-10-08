#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage-1 independently native Befunge structural acceptance replay.

The actual computational results are produced by the repository's own
Befunge-98 reference programs, never by another calendar implementation.
Python is only the test conductor: token comparisons, simple shapes,
lexicographic ordering and input-translation metamorphic assertions.

Important: this is a deliberately bounded corpus, NOT a proof of every
stage-1 input, not a replacement for the production geometry gate.
"""
from __future__ import print_function
import subprocess

COMMAND=("pyfunge","--disable-fprint","--no-concurrent","--no-filesystem",
         "-v98","-d2")
CALLS=[0]

def run(path, tokens, limit="55s"):
    CALLS[0]+=1
    argv=["timeout","--kill-after=5s",limit]+list(COMMAND)+[path]
    process=subprocess.Popen(argv,stdin=subprocess.PIPE,
                             stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    raw,err=process.communicate(tokens+"\n")
    if process.returncode:
        raise AssertionError("NATIVE_CALL_FAILED path=%s input=%r code=%d stderr=%r" %
                             (path,tokens,process.returncode,err[-550:]))
    return raw.split()

def same(label,actual,expected):
    expected=list(map(str,expected))
    if actual!=expected:
        raise AssertionError("%s got=%r expected=%r" % (label,actual,expected))

def count(lengths, expected):
    text=" ".join(map(str,[len(lengths)]+lengths))
    actual=run("reference/count_weavings.b98",text)
    same("weaving-count-"+text,actual,[expected])
    return actual[0]

def unrank(lengths,rank,limit="55s"):
    text=" ".join(map(str,[len(lengths)]+lengths+[rank]))
    return run("reference/unrank_weaving.b98",text,limit)

def check_weaving(seq,lengths,tag):
    vals=list(map(int,seq))
    if len(vals)!=sum(lengths):
        raise AssertionError("weaving length invalid: "+tag)
    for j,length in enumerate(lengths,1):
        if vals.count(j)!=length:
            raise AssertionError("weaving multiplicity invalid: "+tag)
    if any(vals[j]==vals[j+1] for j in range(len(vals)-1)):
        raise AssertionError("weaving contains adjacent equal months: "+tag)
    return vals

print("STAGE1_STRUCTURAL_NATIVE_START")

# Published Stage-1 Befunge reference fixture examples.
same("factorial17x6",run("reference/falling_factorial.b98","17 6"),["8910720"])
same("factorial47x3",run("reference/falling_factorial.b98","47 3"),["97290"])

count([3,3,2],26)
seen=set()
previous=None
for rank in range(1,27):
    seq=unrank([3,3,2],rank)
    vals=check_weaving(seq,[3,3,2],"3-3-2/rank=%d"%rank)
    t=tuple(vals)
    if t in seen:
        raise AssertionError("duplicate weaving rank=%d" % rank)
    if previous is not None and not (previous<t):
        raise AssertionError("weaving lexicographic rank order broken at %d" % rank)
    seen.add(t)
    previous=t
same("weaving invalid rank 0",unrank([3,3,2],0),["-1"])
same("weaving invalid rank 27",unrank([3,3,2],27),["-1"])
print("STAGE1_WEAVING_EXHAUSTIVE_3_3_2_NATIVE_PASS",len(seen))

count([3,3,3],71)
sample_ranks=(1,2,3,17,35,53,69,70,71)
selected=[]
for rank in sample_ranks:
    vals=check_weaving(unrank([3,3,3],rank),[3,3,3],"3-3-3/rank=%d"%rank)
    selected.append(tuple(vals))
if selected!=sorted(set(selected)):
    raise AssertionError("sampled weaving rank ordering violates native order")
same("weaving 3-3-3 rank overflow",unrank([3,3,3],72),["-1"])
print("STAGE1_WEAVING_3_3_3_NATIVE_SAMPLED_PASS",len(sample_ranks))

count([4,4,4],1301)
rank1=unrank([4,4,4],1,"150s")
ranklast=unrank([4,4,4],1301,"150s")
same("4-4-4 first",rank1,[1,1,1,1,2,2,2,2,3,3,3,3])
same("4-4-4 last",ranklast,[1,2,3,3,3,2,2,1,1,1,2,3])
print("STAGE1_WEAVING_4_4_4_NATIVE_BOUNDARIES_PASS")

# Year-5000 canonical fixture: six 42-day gate gaps, 252-day year.
# Translating every *absolute* gate and calculation day by the same
# positive integer leaves structure/rank untouched but translates
# the selected opening/closing gate coordinates by that integer.
def selection(shift,calculation_offset=100,rank=1):
    gates=[shift+42*i for i in range(7)]
    toks=[0,shift+calculation_offset,len(gates)]
    for gate in gates:
        toks += [0,gate]
    toks += [rank]
    return run("reference/year5000_from_gates_rank.b98",
               " ".join(map(str,toks)))

for shift in (0,1,21,84,1000,123456789):
    expected=[0,5000,0,6,shift,shift+252]
    same("year5000 shift=%d"%shift,selection(shift),expected)
    same("year5000 close boundary shift=%d"%shift,
         selection(shift,252),expected)
print("STAGE1_YEAR5000_TRANSLATION_AND_CLOSED_BOUNDARY_NATIVE_PASS",12)

for offset in (0,253,100000):
    same("year5000 uncovered "+str(offset),selection(0,offset),[-1])
for rank in (0,2,100):
    same("year5000 invalid rank "+str(rank),selection(0,100,rank),[-1])
print("STAGE1_YEAR5000_NEGATIVE_BOUNDARY_NATIVE_PASS",6)

print("STAGE1_STRUCTURAL_NATIVE_CORPUS_PASS",
      "native_calls",CALLS[0],
      "weaving_3_3_2_exhaustive",26,
      "weaving_3_3_3_sampled",len(sample_ranks),
      "year5000_translations",6)
print("SCOPE: native reference structural corpus; full production functional/"
      "geometric acceptance still remains separate")
