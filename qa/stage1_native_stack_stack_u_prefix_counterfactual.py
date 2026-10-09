#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Causal Native Funge-98 single-u mutant at two adjacent real checkpoints.

Two *real* pinned PyFunge Programs use the same signed-input cases and
source bytes differing in exactly ONE executed u opcode. Stop at the
coordinate before u, and the coordinate after u, reading the actual
interpreter TOSS. The programs share neither Funge-space nor IPs. No
Python calendar arithmetic, fabricated Native traces, or Pythonized
Befunge interpreter.

The existing stdout-level mutant can TIME OUT; this bounded causal
experiment proves a semantic numeric TOSS divergence at the very next
native instruction, avoiding false claims of a completed output mutant.
"""
from __future__ import print_function
import hashlib
import json
import os
import StringIO
import sys
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_diverse_geometry as corpus

GOOD="/stack/stack_stack_candidate.b98"
MUTANT="/stack/without_native_u.b98"
GOOD_SHA="3e64ba67eaaaf684fef221be33c368527a50a3c986e9f0b63e73ef81b21cdb59"
FOCUS=(954,1328)
AFTER=(954,1327)
CASES=("zero_equal","forward_short","positive_negative")

def require(ok,why):
    if not ok:raise AssertionError(why)

class Observation(Exception):pass

def snapshot(source,raw,coord):
    stdout=StringIO.StringIO()
    platform=BufferedPlatform([],{},stdin=StringIO.StringIO(raw),stdout=stdout)
    p=Program(Befunge98,platform=platform)
    p.load_code(source)
    p.create_ip()
    require(len(p.ips)==1,"one original Native program IP required")
    actual=p.execute_step
    ticks=[0]
    observations=[]
    def step_hook(self):
        ticks[0]+=1
        require(ticks[0]<40000,"Native boundary checkpoint exceeded 40000 steps")
        require(len(self.ips)==1,"Native arithmetic IP forked unexpectedly")
        ip=self.ips[0]
        point=tuple(ip.position)
        if point==coord:
            require(tuple(ip.delta)==(0,-1),
                    "Native stack-stack pre/post-u actual heading mismatch")
            toss=tuple(str(x) for x in list(ip.stack[0]))
            require(toss,"Native stack-stack boundary TOSS empty")
            observations.append({"xy":list(point),"ip":str(id(ip)),
                                 "tick":ticks[0],"toss":list(toss),
                                 "depth":len(toss)})
            raise Observation()
        return actual()
    p.execute_step=step_hook.__get__(p,p.__class__)
    try:
        p.execute()
    except Observation:pass
    finally:del p.execute_step
    require(len(observations)==1,"Native boundary was not observed exactly once")
    return observations[0]

def main():
    require(os.path.isfile(GOOD) and os.path.isfile(MUTANT),
            "positive and single-u Native candidate sources missing")
    good=open(GOOD,"rb").read();mutant=open(MUTANT,"rb").read()
    require(hashlib.sha256(good).hexdigest()==GOOD_SHA,
            "positive Native source not the 14-cell pin")
    require(len(good)==len(mutant),"causal Native source lengths differ")
    changes=[i for i,(a,b) in enumerate(zip(good,mutant)) if a!=b]
    lines=good.split("\n");rows=mutant.split("\n")
    require(len(changes)==1 and len(lines)==len(rows)==2016 and
            lines[1328][954]=="u" and rows[1328][954]==" " and
            changes[0]==sum(len(x)+1 for x in lines[:1328])+954,
            "causal control differs beyond one actually executed u")
    named={label:(fields,valid) for label,fields,valid in corpus.CASES}
    results=[]
    for name in CASES:
        fields,valid=named[name]
        require(valid,"causal comparison must use valid Native inputs")
        raw=" ".join(str(x) for x in fields)+"\n"
        before_real=snapshot(good,raw,FOCUS)
        before_mutant=snapshot(mutant,raw,FOCUS)
        after_real=snapshot(good,raw,AFTER)
        after_mutant=snapshot(mutant,raw,AFTER)
        require(before_real["toss"]==before_mutant["toss"],
                "before-u Native stacks differ despite identical prefix")
        require(after_mutant["toss"]==before_mutant["toss"],
                "the single-byte no-u control unexpectedly changed TOSS")
        require(after_real["toss"]!=after_mutant["toss"],
                "true Native executed u failed to affect arithmetic TOSS")
        require(after_real["tick"]==after_mutant["tick"] and
                before_real["tick"]==before_mutant["tick"] and
                after_real["tick"]==before_real["tick"]+1,
                "actual Native u did not make exactly one instruction step")
        print("NATIVE_STACK_STACK_U_IMMEDIATE_NUMERIC_CAUSALITY_PASS",
              name,"TOSS_before",before_real["toss"],
              "TOSS_after_u",after_real["toss"],
              "TOSS_after_no_u",after_mutant["toss"])
        sys.stdout.flush()
        results.append({"case":name,
                        "actual_before":before_real,
                        "single_u_actual_after":after_real,
                        "single_byte_mutant_after":after_mutant,
                        "real_native_arithmetic_toss_changed":True})
    require(len(results)==3,"Native causal prefix coverage truncated")
    with open("/stack/stack_stack_native_u_prefix_causality.json",
              "wb") as out:
        out.write(json.dumps({
            "schema":"befunge-stage1-u-native-adjacent-checkpoint-causality-v1",
            "status":"QA_ONLY_NOT_STAGE1_ACCEPTANCE",
            "real_native_interpreter":True,
            "mutant_removed_exactly_one_executed_u":True,
            "source_sha256":GOOD_SHA,
            "mutant_sha256":hashlib.sha256(mutant).hexdigest(),
            "positive_signed_valid_cases":len(results),
            "evidence":results},sort_keys=True,indent=2)+"\n")
    print("NATIVE_STACK_STACK_U_NUMERIC_CAUSAL_PREFIX_PASS",len(results),
          "valid signed Native cases; no completed-output-mutant claim")

if __name__=="__main__":
    main()
