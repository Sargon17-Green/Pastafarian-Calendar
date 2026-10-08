#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Fail-closed native negative/out-of-domain rank corpus (Stage 1).

An input rank outside [1, native family count] must produce exactly -1.
All count and unrank results come from the Befunge-98 reference programs.
Python only marshals data and checks protocol/shape; no calendar oracle.
"""
from __future__ import print_function
import subprocess
import sys
import os
import tempfile

BF98=["pyfunge","--disable-fprint","--no-concurrent","--no-filesystem",
      "-v98","-d2"]
NATIVE=[0]
# Independent families intentionally cover singleton, unsaturated, and
# dense bounded-composition/weaving cases; no Python count oracle.
BOUNDED=[(5,2,1,4),(8,3,1,4),(9,3,2,5),(10,4,1,5)]
WEAVINGS=[(2,2),(3,3,2),(3,3,3)]
LARGE=1<<127

def run(module,fields):
    NATIVE[0]+=1
    line=" ".join(map(str,fields))+"\n"
    args=["timeout","--kill-after=2s","32s"]+BF98+[module if module.endswith(".b98") else "reference/"+module+".b98"]
    p=subprocess.Popen(args,stdin=subprocess.PIPE,
                       stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    out,err=p.communicate(line)
    if p.returncode:
        raise AssertionError("native interpreter %s input=%r exit=%s stderr=%r" %
                             (module,line,p.returncode,err[-600:]))
    try:
        return tuple(int(tok) for tok in out.split())
    except ValueError:
        raise AssertionError("native noninteger result %s input=%r output=%r" %
                             (module,line,out))

def one(module,fields):
    result=run(module,fields)
    if len(result)!=1:
        raise AssertionError("native count shape %s fields=%r result=%r" %
                             (module,fields,result))
    return result[0]

def verify(label,inputs,count_mod,unrank_mod):
    count=one(count_mod,inputs)
    if count<=0:
        raise AssertionError("%s has unexpected native count=%d" % (label,count))
    # Note: exercise ranks -1, 0, count+1, large negative and positive;
    # these must never alias the valid lexicographic 1-indexed domain.
    invalid=sorted(set([-LARGE,-1,0,count+1,count+2,LARGE+count+1]))
    for rank in invalid:
        got=run(unrank_mod,inputs+(rank,))
        if got!=(-1,):
            raise AssertionError("%s rank=%d count=%d incorrectly accepted: %r" %
                                 (label,rank,count,got))
    for rank in sorted(set(r for r in [1,2,3,count//3,count//2,count-2,count-1,count] if 1<=r<=count)):
        got=run(unrank_mod,inputs+(rank,))
        if got==(-1,) or len(got)<1:
            raise AssertionError("%s rejects legal rank %d of %d: %r" %
                                 (label,rank,count,got))
        baseline=("qa/unrank_bounded_composition_pre_strict_rank_baseline.b98"
                  if label.startswith("bounded:") else
                  "qa/unrank_weaving_pre_strict_rank_baseline.b98")
        expected=run(baseline,inputs+(rank,))
        if got!=expected:
            raise AssertionError("%s strict rank parser changed legal rank %d: %r != %r" %
                                 (label,rank,got,expected))
    print("NATIVE_ADVERSARIAL_RANK_DOMAIN_PASS",label,"count",count,
          "rejected",len(invalid))
    sys.stdout.flush()

def probe_native_integer_character_handoff():
    # Probe the interpreter's actual character position immediately after
    # four integer-input opcodes. This is diagnostic native Befunge, not math.
    fd,name=tempfile.mkstemp(suffix=".b98")
    try:
        os.write(fd,b"&$&$&$&$~.@\n")
        os.close(fd)
        observed=run(name,[5,2,1,4,1])
        print("NATIVE_INTEGER_CHARACTER_HANDOFF_ASCII",observed)
        sys.stdout.flush()
    finally:
        try: os.unlink(name)
        except OSError: pass

probe_native_integer_character_handoff()

for item in BOUNDED:
    verify("bounded:"+str(item),item,
           "count_bounded_compositions","unrank_bounded_composition")
for item in WEAVINGS:
    fields=(len(item),)+item
    verify("weaving:"+str(item),fields,"count_weavings","unrank_weaving")

print("NATIVE_STAGE1_ADVERSARIAL_RANK_DOMAIN_PASS native_invocations=%d" %
      NATIVE[0])
print("SCOPE: native rank-domain boundary corpus only, not Stage1 completion")
