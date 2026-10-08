#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native-only Stage-1 sauce-to-choice composition regression.

Tests a specific equivalence between independently executable *Befunge-98*
reference modules. Python here only marshals tokens and compares results.
It does NOT implement or import Pastafarian arithmetic or an external oracle.
This is a bounded Stage-1 functional property test, not full acceptance.
"""
from __future__ import print_function
import subprocess

CMD=["pyfunge","--disable-fprint","--no-concurrent",
     "--no-filesystem","-v98","-d2"]
RUNS=[0]
M=(1<<127)-1

PAIRS=[
    (1,15055671,1,15055671),
    (1,15055672,1,15055670),
    (0,0,0,0),
    (0,123456789,1,987654321),
    (1,10**20,0,10**20),
    (0,M,1,M+1),
    (1,M+1,0,M+2),
]

# Canonical Stage-1 (bowl,seal) selections.
QUERIES=[
    (1,1,922),
    (2,20,17),
    (3,30,47),
    (4,32,1000),
    (5,33,47),
]

def execute(module, tokens, limit="80s"):
    RUNS[0]+=1
    arguments=["timeout","--kill-after=3s",limit]+CMD+["reference/"+module+".b98"]
    raw=" ".join(map(str,tokens))+"\n"
    proc=subprocess.Popen(arguments,stdin=subprocess.PIPE,
                          stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    out,err=proc.communicate(raw)
    if proc.returncode:
        raise AssertionError("native failed %s input=%r rc=%d stderr=%r" %
                             (module,raw,proc.returncode,err[-600:]))
    try:
        return tuple(int(v) for v in out.split())
    except ValueError:
        raise AssertionError("noninteger native output %s %r" % (module,out))

def single(module,tokens):
    result=execute(module,tokens)
    if len(result)!=1:
        raise AssertionError("%s expected one result input=%r got=%r" %
                             (module,tokens,result))
    return result[0]

def same(label,left,right):
    if left!=right:
        raise AssertionError("native Befunge disagreement %s: %r != %r" %
                             (label,left,right))

for index,days in enumerate(PAIRS):
    sauce=execute("sauce",days)
    if len(sauce)!=12:
        raise AssertionError("native sauce must emit six bowls and six order indices")
    order=sauce[6:]
    if sorted(order)!=[1,2,3,4,5,6]:
        raise AssertionError("invalid native bowl permutation %r" % (order,))
    native_days_gap=single("gate_gap_from_days",days)
    native_sauce_gap=single("gate_gap_from_sauce",sauce)
    same("gate-gap independent native composition %d" % index,
         native_days_gap,native_sauce_gap)
    if not 42<=native_days_gap<=963:
        raise AssertionError("gate gap outside normative range %d" % native_days_gap)
    for bowl,seal,n in QUERIES:
        from_days=single("rank_from_days",days+(bowl,seal,n))
        from_sauce=single("rank_from_sauce",sauce+(bowl,seal,n))
        same("native sauce-to-choice %d bowl %d seal %d N=%d" %
             (index,bowl,seal,n),from_days,from_sauce)
        if not 1<=from_days<=n:
            raise AssertionError("choice rank out of range %r %r" %
                                 ((index,bowl,seal,n),from_days))
    # Mandatory wide-choice probe with N one beyond the 127-bit SAVE modulus.
    if index in (0,3):
        wide=(3,31,M+1)
        from_days=single("rank_from_days",days+wide)
        from_sauce=single("rank_from_sauce",sauce+wide)
        same("native wide-choice %d" % index,from_days,from_sauce)
        if not 1<=from_days<=M+1:
            raise AssertionError("wide rank escaped requested family")
    print("NATIVE_SAUCE_CHOICE_COMPOSITION_CASE_PASS",index,"queries",
          len(QUERIES)+(index in (0,3)))

print("NATIVE_SAUCE_CHOICE_COMPOSITION_PASS",len(PAIRS),
      "day_pairs",RUNS[0],"native_program_invocations")
print("FULL_FUNCTIONAL_QA_PASS=NO (finite composition sample only)")
