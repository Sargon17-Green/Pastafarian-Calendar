#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA-only real PyFunge-98 inventory of execution-time Funge-space.put.

Runs exact Git-blob-pinned QA production for 32 valid domain inputs,
normal and forced-opposite real | branch. Monitors all native .space.put
calls at the engine level, not only explicitly visited p instructions.
This detects potentially indirect writes through k. Source bytes are
unchanged and every arithmetic result is computed by Befunge itself.
"""
from __future__ import print_function
import json
import os
import StringIO
import sys
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_current_fork_route_differential as fork

SOURCE="src/interleaved_work_counts.b98"
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
FORBIDDEN="sio=()t"
OUT="/writes/native_fungespace_put_inventory.json"

def require(ok,msg):
    if not ok:raise AssertionError(msg)

class Limit(Exception):pass

def run(src,name,raw,opposite,oracle):
    stdout=StringIO.StringIO()
    program=Program(Befunge98,platform=BufferedPlatform(
        [],{},stdin=StringIO.StringIO(raw),stdout=stdout))
    program.load_code(src)
    program.create_ip()
    require(len(program.ips)==1,"native p inventory one IP precondition")
    space=program.space
    cls=type(space)
    original_put=cls.put
    original_step=program.execute_step
    puts=[]
    direct_p=[]
    gate=[]
    ticks=[0]
    def spy_put(self,*args,**kwargs):
        require(self is space and len(args)>=2,
                "Native Funge-space.put spy intercepted unexpected call")
        address,val=args[:2]
        require(len(program.ips)==1,
                "Funge-space.put called without the original Native IP")
        ip=program.ips[0]
        position=[int(ip.position[0]),int(ip.position[1])]
        opcode=int(self.get(ip.position))
        target=[int(address[0]),int(address[1])]
        result=original_put(self,*args,**kwargs)
        stored=int(self.get(address))
        require(stored==int(val),
                "actual Native put stored a value different from written")
        puts.append({"tick":ticks[0],"ip":position,"opcode":opcode,
                     "target":target,"value":stored})
        return result
    def step(self):
        ticks[0]+=1
        if ticks[0]>fork.BOUND:
            raise Limit()
        require(len(self.ips)==1,"unexpected concurrent Native IP")
        ip=self.ips[0]
        op=int(self.space.get(ip.position))
        xy=tuple(ip.position)
        if xy==fork.GATE:
            require(op==ord("|") and len(ip.stack[0])>0,
                    "pin-scoped fork missing during real Native execution")
            original=int(bool(ip.stack[0][-1]))
            if opposite:
                ip.stack[0][-1]=0 if original else 1
            gate.append([original,int(bool(ip.stack[0][-1]))])
        if op==ord("p") and not ip.stringmode:
            direct_p.append([int(ip.position[0]),int(ip.position[1]),ticks[0]])
        return original_step()
    try:
        cls.put=spy_put
        program.execute_step=step.__get__(program,program.__class__)
        status="normal"
        try:program.execute()
        except Limit:status="step-limit"
    finally:
        if "execute_step" in program.__dict__:
            del program.execute_step
        cls.put=original_put
    require(len(gate)==1 and len(puts)>0,
            "Native real fork/space-put observation incomplete")
    expected=oracle==stdout.getvalue().split()
    if not opposite:
        require(status=="normal" and not program.ips and expected,
                "Unmodified QA production diverged from independent Befunge oracle "+
                name)
    non_p=[e for e in puts if e["opcode"]!=ord("p")]
    created=[e for e in puts if e["value"] in [ord(c) for c in FORBIDDEN]]
    print("NATIVE_PUT_INVENTORY_CASE",name,"opposite",opposite,
          "puts",len(puts),"direct_p",len(direct_p),
          "indirect",len(non_p),"created_mutators",len(created),
          "status",status)
    sys.stdout.flush()
    return {"case":name,"opposite":bool(opposite),"gate":gate[0],
            "status":status,"remaining_ips":len(program.ips),
            "oracle_correct":expected,"ticks":ticks[0],
            "put_calls":len(puts),"direct_p_steps":len(direct_p),
            "non_p_attributed_puts":len(non_p),
            "created_other_mutator_cells":len(created),
            "native_put_events":puts}

def main():
    require(os.path.isdir("/writes"),"Native writer output folder absent")
    src=open(SOURCE,"rb").read()
    require(fork.blob(src)==PIN,"QA current source Git blob not pinned")
    absent={c:src.count(c) for c in FORBIDDEN}
    require(all(count==0 for count in absent.values()),
            "static source includes non-p Funge mutator opcode")
    families={row[0]:(row[1],row[2]) for row in fork.native.CASES}
    families.update({row[0]:(row[1],row[2]) for row in fork.wide.CASES})
    records=[]
    for name in fork.CASE_NAMES:
        fields,valid=families[name]
        require(valid,"only valid Native domain inputs are in writer scope")
        raw=" ".join(str(field) for field in fields)+"\n"
        oracle=fork.native.expected_for(*fields)
        records.append(run(src,name,raw,False,oracle))
        records.append(run(src,name,raw,True,oracle))
    require(len(records)==64,"64 real Native writer replays not completed")
    total=sum(r["put_calls"] for r in records)
    indirect=sum(r["non_p_attributed_puts"] for r in records)
    generated=sum(r["created_other_mutator_cells"] for r in records)
    require(total>64,"Native Funge-space write inventory implausibly empty")
    evidence={"schema":"befunge-stage1-native-fungespace-put-surface-v1",
              "status":"QA_ONLY_NOT_COMPLETE_SEMANTIC_OWNERSHIP",
              "production_git_blob":PIN,"valid_inputs":32,
              "real_native_program_runs":64,
              "source_forbidden_mutator_count":absent,
              "total_space_put_calls":total,
              "indirect_or_non_p_attributed_put_calls":indirect,
              "new_forbidden_mutator_bytes_written":generated,
              "other_space_mutation_APIs_audited":False,
              "stage1_final_acceptance":False,"records":records}
    with open(OUT,"wb") as f:
        f.write(json.dumps(evidence,sort_keys=True,indent=2)+"\n")
    print("NATIVE_REAL_FUNGESPACE_PUT_INVENTORY_64_CASE_PASS",
          "total_puts",total,"non_p_attributed",indirect,
          "generated_other_mutators",generated)
    print("STAGE1_SEMANTIC_OWNERSHIP_FINAL_GATE=OPEN")

if __name__=="__main__":
    main()
