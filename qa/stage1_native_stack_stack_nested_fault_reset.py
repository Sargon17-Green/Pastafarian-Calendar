#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Two-live Native Befunge Programs: fault with TOSS/SOSS *still nested*.

The earlier concurrent state test interrupted after a production p write
AFTER stack-stack arithmetic completed. This independently interrupts the
same PyFunge Program immediately AFTER its real 'u' transfer, before the
matching '}' closes the nested stack. While it is frozen, another genuine
Native Program must finish unaffected. Reconstruct the faulted Program
IN PLACE and prove three subsequent native reference outputs, fresh
Funge-space, fresh IP stacks, no old-state contamination.

All computation under test is real Befunge-98, not Python calendar logic.
"""
from __future__ import print_function
import hashlib
import json
import os
import sys

import stage1_native_concurrent_pg_fault_isolation as suite

PRODUCTION="src/interleaved_work_counts.b98"
CANDIDATE="/stack/stack_stack_candidate.b98"
SHA256="3e64ba67eaaaf684fef221be33c368527a50a3c986e9f0b63e73ef81b21cdb59"
POINT=(954,1328)
SCRATCH=(1490,1600)
OUT="/stack/stack_stack_nested_u_fault_reset.json"

def require(ok,why):
    if not ok: raise AssertionError(why)

class NestedFault(Exception): pass

def frozen_toss(ip):
    return tuple(str(v) for v in ip.stack[0])

def main():
    source=open(PRODUCTION,"rb").read()
    sample=open(CANDIDATE,"rb").read()
    require(source==sample and hashlib.sha256(source).hexdigest()==SHA256,
            "Native nested-stack source is not exact current QA production")
    require(source.split("\n")[1328][954]=="u",
            "real Native stack-stack fault injection opcode changed")
    suite.CODE=source
    a=suite.Case("faulted_inside_nested_3u",suite.UP)
    b=suite.Case("unfaulted_concurrent_3u",suite.UP)
    require(a.program is not b.program and
            a.program.space is not b.program.space and
            a.program.ips[0].stack is not b.program.ips[0].stack,
            "two live Native programs share mutable stacks/Funge-space")
    rounds=0
    try:
        while a.program.ips:
            require(rounds<suite.MAX_TICKS,
                    "real Native Program never reached nested u fault")
            ip=a.program.ips[0]
            if tuple(ip.position)==POINT:
                require(tuple(ip.delta)==(0,-1),
                        "actual Native u instruction entered from wrong heading")
                before=frozen_toss(ip)
                require(before==("1","0","0"),
                        "actual Native valid-input 3u operands drifted")
                require(a.hits=={"p":0,"g":0},
                        "nested fault occurred after mutable scratch p/g")
                a.step()  # Executes actual 'u'; not Python arithmetic
                require(a.program.ips and a.program.ips[0] is ip,
                        "real Native stack transfer silently replaced/stopped IP")
                after=frozen_toss(ip)
                require(after==() and before!=after,
                        "actual Native u did not empty transferred TOSS")
                a.paused=True
                raise NestedFault()
            a.step()
            if b.program.ips:
                b.step()
            rounds+=1
    except NestedFault:
        pass
    require(a.paused and a.program.ips and b.program.ips and
            a.program.space.get(a.position)==32,
            "native nested u did not interrupt two genuinely live Programs")
    frozen_space=a.program.space
    frozen_ip=a.program.ips[0]
    frozen_stack=frozen_ip.stack
    original_id=id(a.program)
    original_toss=frozen_toss(frozen_ip)
    suite.finish_unfaulted(b,a)
    require(frozen_ip.stack is frozen_stack and
            frozen_toss(frozen_ip)==original_toss and
            frozen_space.get(a.position)==32,
            "other live Program changed frozen Native nested-stack state")
    report=[]
    for label,values,arm in [
        ("nested_fault_then_lower",suite.DOWN,"down"),
        ("nested_fault_then_upper",suite.UP,"up"),
        ("nested_fault_then_invalid_upper",suite.INVALID,"up")
    ]:
        a=suite.Case(label,values,program=a.program)
        require(id(a.program)==original_id and
                a.program.space is not frozen_space and
                a.program.space is not b.program.space and
                a.program.ips[0] is not frozen_ip and
                a.program.ips[0].stack is not frozen_stack,
                "explicit Native Program reset reused prior nested IP/TOSS state")
        require(a.program.space.get(a.position)==32,
                "reset Native scratch started dirty after nested fault")
        ticks=suite.execute_fresh(a,arm)
        require(frozen_toss(frozen_ip)==original_toss and
                frozen_space.get(a.position)==32 and
                b.program.space.get(b.position)==12 and
                b.output()==suite.expect(suite.UP),
                "Native stack fault/reset contaminated another live or frozen instance")
        report.append({"case":label,"native_ticks":ticks,"arm":arm,
                       "same_program_object":True,
                       "new_ip_and_stack":True,
                       "original_nested_stack_preserved":True})
        print("NATIVE_STACK_STACK_NESTED_U_FAULT_RESET_PASS",
              label,"native_ticks",ticks)
        sys.stdout.flush()
    require(len(report)==3,"incomplete nested source native reuse")
    data={"schema":"befunge-stage1-native-nested-u-fault-reset-v1",
          "status":"QA_ONLY_NOT_FINAL_STAGE1_ACCEPTANCE",
          "source_sha256":SHA256,
          "interrupt_after_executed_u_before_brace_close":True,
          "two_simultaneously_live_programs":2,
          "one_independently_completed_native_program":True,
          "faulted_program_explicit_same_object_resets":len(report),
          "real_interpreter_mutable_space_and_ip_stack_isolated":True,
          "fault_scheduling_rounds":rounds,
          "native_cases":report}
    with open(OUT,"wb") as file:
        file.write(json.dumps(data,sort_keys=True,indent=2)+"\n")
    print("NATIVE_STACK_STACK_NESTED_U_OWNERSHIP_AND_3_RESET_PASS",
          "two_live",2,"same_Program_resets",len(report))
    print("STAGE1_FINAL_SEMANTIC_STATE_OWNERSHIP=OPEN")

if __name__=="__main__":
    main()
