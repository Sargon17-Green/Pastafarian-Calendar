#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage-1 QA-only REAL arithmetic using Befunge-98 {, u and } stacks.

Precise 14-cell vertical detour on a SHA-frozen, independently qualified
two-valid-w candidate. The original upper arm computes 1,0,1,-1 and
continues through x/p/g/j. This detour replaces the original literal 0
with an actual stack-stack transfer of the preceding computed 1:

  0{ 3u : 1- 2}    moves the 1 from SOSS to TOSS, copies, subtracts,
                    and returns original 1 and computed 0 to SOSS.

The independent Python3 auditor checks real PyFunge STEP, READ and WRITE,
actual stack depth, route edges, source history and one-byte tampering.
Expected seven-field values ALWAYS come from three independent Native
Befunge programs and an unchanged SHA-pinned production baseline.
"""
from __future__ import print_function
import hashlib
import json
import os
import shutil
import subprocess
import sys
import stage1_native_diverse_geometry as native
import stage1_native_reflective_candidate_domain_matrix as wide

BASE="qa/interleaved_work_counts_w_valid_two_arithmetic_arms_candidate.b98"
BLOB="b6cf50de9ed45376db5fc4ebd003157210dff03b"
EXPERIMENT_BLOB="560d6aa5807a7f766213a33835cce85eab0fa40c"
EXPERIMENT_SHA256="3e64ba67eaaaf684fef221be33c368527a50a3c986e9f0b63e73ef81b21cdb59"
OUT="/stack"
CAND=OUT+"/stack_stack_candidate.b98"
MUTANT=OUT+"/without_native_u.b98"
UPPER=frozenset(("zero_equal","forward_short","reverse_short",
    "positive_negative","large_values","epoch_forward_one",
    "epoch_reverse_one","recent_anchor_equal","recent_anchor_next",
    "invalid_target_zero_sign"))
ENTRY=(954,1332)
BRACE=(954,1330)
TRANSFER=(954,1328)
CLOSE=(954,1322)
JUMP=(954,1318)
REJOIN=(955,1332)
STEPS=((1330,"{"),(1329,"3"),(1328,"u"),(1327,":"),
       (1326,"1"),(1325,"-"),(1323,"2"),(1322,"}"),
       (1321,"1"),(1320,"1"),(1319,"e"),(1318,"x"))

def require(ok,msg):
    if not ok:raise AssertionError(msg)

def gitblob(data):
    return hashlib.sha1("blob %d\0%s"%(len(data),data)).hexdigest()

def source():
    frozen=open(BASE,"rb").read()
    require(gitblob(frozen)==BLOB,"frozen two-valid-w native source drift")
    lines=frozen.split("\n")
    require(len(lines)==2016 and max(map(len,lines))==1531
            and lines[1332][953:957]=="101-" and
            lines[1331][954]=="0",
            "arithmetic dependency or source bounds unexpectedly changed")
    changes={(954,1332):("0","^"),(955,1332):("1",">")}
    for y,char in STEPS:changes[(954,y)]=(" ",char)
    require(len(changes)==14,"wrong isolated 14-cell stack-stack detour count")
    copy=list(lines)
    for (x,y),(old,new) in changes.items():
        require(copy[y][x]==old,
                "stack-stack corridor is not truly empty at "+str((x,y)))
        copy[y]=copy[y][:x]+new+copy[y][x+1:]
    data="\n".join(copy)
    require(len(data)==len(frozen) and
            [len(row) for row in copy]==[len(row) for row in lines]
            and sum(a!=b for a,b in zip(data,frozen))==14
            and gitblob(data)==EXPERIMENT_BLOB
            and hashlib.sha256(data).hexdigest()==EXPERIMENT_SHA256,
            "generated stack-stack source differs from frozen 14-byte contract")
    with open(CAND,"wb") as stream:stream.write(data)
    print("NATIVE_STACK_STACK_EXACT_14_CELL_SOURCE_PASS",EXPERIMENT_BLOB)
    return data

def observed(path,expect_upper):
    watched={ENTRY:[],BRACE:[],TRANSFER:[],CLOSE:[],JUMP:[],REJOIN:[]}
    all_corridor=[]
    previous=None
    with open(path,"rb") as stream:
        for line in stream:
            if not line.startswith("STEP\t"):continue
            parts=line.rstrip("\n").split("\t")
            require(len(parts)==9,"malformed real Native STEP")
            event=tuple(map(int,parts[1:]))
            tick,ip,x,y,dx,dy,opcode,depth=event
            if (x,y) in watched:watched[(x,y)].append(event)
            if x==954 and 1318<=y<=1330:
                all_corridor.append((tick,x,y,dx,dy,opcode,depth))
            if (x,y)==REJOIN and expect_upper:
                require(previous is not None and previous[2:4]==JUMP,
                        "Native dynamic vector did not actually rejoin original arithmetic")
            previous=event
    if not expect_upper:
        require(not all_corridor and not watched[ENTRY] and not watched[JUMP],
                "unselected Native stack-stack route was executed")
        return {"route":"bypass"}
    # Validate every executed instruction coordinate, allowing an unmodified
    # blank in the middle whether PyFunge records it or skips it.
    executed=[(entry[2],entry[5]) for entry in all_corridor
              if entry[5]!=ord(" ")]
    expected=[(y,ord(opcode)) for y,opcode in STEPS]
    require(executed==expected and
            all(entry[1]==954 and (entry[2]!=1324 or entry[5]==ord(" "))
                for entry in all_corridor),
            "Native stack-stack actual 2D opcodes or IP positions differ")
    require(all(len(watched[k])==1 for k in watched),
            "stack-stack entry/return visited a wrong number of times")
    require(watched[ENTRY][0][4:7]==(1,0,ord("^"))
            and watched[BRACE][0][4:7]==(0,-1,ord("{"))
            and watched[TRANSFER][0][4:7]==(0,-1,ord("u"))
            and watched[CLOSE][0][4:7]==(0,-1,ord("}"))
            and watched[JUMP][0][4:7]==(0,-1,ord("x"))
            and watched[REJOIN][0][4:7]==(1,14,ord(">"))
            and watched[REJOIN][0][7]==3,
            "real Native stack-stack direction/depth/rejoin differs")
    require(watched[ENTRY][0][0]+1==watched[BRACE][0][0]-1
            and watched[JUMP][0][0]+1==watched[REJOIN][0][0],
            "real Native stack arithmetic instructions are not on a continuous IP path")
    return {"route":"stack_stack","upper_opcode_count":len(executed),
            "native_u_tick":watched[TRANSFER][0][0],
            "after_dynamic_rejoin_stack_depth":watched[REJOIN][0][7]}

def call(source_path,raw,seconds):
    command=["timeout","--kill-after=2s",str(seconds)+"s"]+native.COMMAND+[source_path]
    p=subprocess.Popen(command,stdin=subprocess.PIPE,
                       stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    out,err=p.communicate(raw)
    return p.returncode,out.split(),err[-300:]

def native_pre_arithmetic_stack(source_file,raw):
    """Read-only LIVE PyFunge TOSS immediately before original - arithmetic.

    The same pinned interpreter, actual input and source bytes are used,
    with no Python implementation of Befunge semantics or calendar arithmetic.
    Stop once at the first exact production rejoin IP; do not execute a
    potentially nonterminating candidate merely to inspect its stack.
    """
    import StringIO
    from funge.program import Program
    from funge.languages.funge98 import Befunge98
    from funge.platform import BufferedPlatform
    class ObservationReady(Exception):pass
    stdout=StringIO.StringIO()
    platform=BufferedPlatform([],{},stdin=StringIO.StringIO(raw),stdout=stdout)
    program=Program(Befunge98,platform=platform)
    with open(source_file,"rb") as f: program.load_code(f.read())
    program.create_ip()
    original=program.execute_step
    observations=[]
    tick=[0]
    def watched_step(self):
        tick[0]+=1
        require(tick[0]<40000,
                "Native pre-arithmetic operand watcher failed to reach rejoin")
        if self.ips:
            ip=self.ips[0]
            xy=tuple(ip.position)
            if xy==(956,1332):
                require(tuple(ip.delta)==(1,0),
                        "Native pre-arithmetic IP heading is not east")
                values=tuple(map(str,list(ip.stack[0])))
                observations.append(values)
                raise ObservationReady()
        return original()
    program.execute_step=watched_step.__get__(program,program.__class__)
    try:
        program.execute()
    except ObservationReady:
        pass
    finally:
        del program.execute_step
    require(len(observations)==1 and observations[0],
            "Native interpreter did not expose exact pre-arithmetic stack")
    return observations[0]


def main():
    require(os.path.isdir(OUT),"Native /stack evidence destination unavailable")
    data=source()
    require(open("src/interleaved_work_counts.b98","rb").read()==data and
            open("qa/interleaved_work_counts_stack_stack_candidate.b98","rb").read()==data,
            "current QA src or frozen {u} Native production source changed")
    raw_probe="0 0 0 0\n"
    baseline_stack=native_pre_arithmetic_stack(BASE,raw_probe)
    candidate_stack=native_pre_arithmetic_stack(CAND,raw_probe)
    print("NATIVE_STACK_STACK_LIVE_PRE_ARITHMETIC_VALUES",
          "reference",repr(baseline_stack),"candidate",repr(candidate_stack))
    sys.stdout.flush()
    require(baseline_stack==candidate_stack,
            "ACTUAL_NATIVE_STACK_STACK_VALUES_DIFFER_AT_REJOIN")
    proof=[]
    for label,fields,valid in native.CASES:
        raw=" ".join(map(str,fields))+"\n"
        reference=native.expected_for(*fields) if valid else ["-1"]*7
        old=native.native(BASE,raw)
        trace=OUT+"/"+label+".tsv"
        got=native.native(CAND,raw,trace=trace)
        require(len(got)==len(old)==len(reference)==7 and
                got==old==reference,"Native stack-stack seven-field oracle mismatch "+label)
        route=observed(trace,label in UPPER)
        with open(trace,"rb") as inp:sha=hashlib.sha256(inp.read()).hexdigest()
        proof.append({"case":label,"valid":valid,"trace_file":label+".tsv",
                      "trace_sha256":sha,"observed":route})
        print("NATIVE_STACK_STACK_ARITHMETIC_ROUTE_ORACLE_PASS",
              label,route["route"])
        sys.stdout.flush()
    require(sum(x["observed"]["route"]=="stack_stack" for x in proof)==10,
            "ten Native upper arithmetic case routes were not covered")
    extensions=[]
    for label,fields,valid in wide.CASES:
        raw=" ".join(map(str,fields))+"\n"
        ref=native.expected_for(*fields) if valid else ["-1"]*7
        prior=native.native(BASE,raw)
        current=native.native(CAND,raw)
        require(len(ref)==len(prior)==len(current)==7 and
                ref==prior==current,
                "Native stack-stack wide signed-domain mismatch "+label)
        extensions.append({"case":label,"valid":valid,"oracle_equal":True})
        print("NATIVE_STACK_STACK_WIDE_SIGNED_ORACLE_PASS",label)
        sys.stdout.flush()
    rows=data.split("\n")
    require(rows[TRANSFER[1]][TRANSFER[0]]=="u",
            "native stack-stack causal transfer not in source")
    rows[TRANSFER[1]]=rows[TRANSFER[1]][:TRANSFER[0]]+" "+rows[TRANSFER[1]][TRANSFER[0]+1:]
    modified="\n".join(rows)
    require(len(modified)==len(data) and
            sum(a!=b for a,b in zip(modified,data))==1,
            "native stack-stack causal mutant must remove exactly one u")
    with open(MUTANT,"wb") as stream:stream.write(modified)
    raw="0 0 0 0\n"
    ref=native.expected_for(0,0,0,0)
    rc,altered,stderr=call(MUTANT,raw,8)
    require(rc!=0 or altered!=ref,
            "removing executed u did not change bounded Native program behavior")
    sham=OUT+"/exact_sham.b98"
    shutil.copyfile(CAND,sham)
    sham_rc,sham_out,sham_error=call(sham,raw,8)
    require(sham_rc==0 and sham_out==ref,
            "byte-identical Native sham differs from independently computed reference")
    print("NATIVE_STACK_STACK_NATIVE_SINGLE_U_CAUSAL_CONTROL_PASS",
          "mutant_exit",rc,"output_changed",altered!=ref,
          "same_source_control",sham_out==ref)
    report={"schema":"befunge-stage1-native-stack-stack-arithmetic-v1",
            "status":"QA_PRODUCTION_ONLY_NO_STAGE1_ACCEPTANCE",
            "base_blob":BLOB,"candidate_blob":EXPERIMENT_BLOB,
            "candidate_sha256":EXPERIMENT_SHA256,
            "changed_exact_executable_cells":14,
            "seventeen_native_cases":proof,
            "extra_native_signed_cases":extensions,
            "upper_stack_stack_executions":10,"lower_bypasses":7,
            "single_u_mutant":{"case":"zero_equal","exit":rc,
                               "output_changed":altered!=ref,
                               "sham_native_oracle_equal":True}}
    with open(OUT+"/native_stack_stack_arithmetic.json","wb") as stream:
        stream.write(json.dumps(report,indent=2,sort_keys=True)+"\n")
    print("NATIVE_STACK_STACK_MEANINGFUL_ARITHMETIC_CANDIDATE_PASS",
          len(proof),"Native traces",len(extensions),"wide reference cases")
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO STAGE1_OPEN=YES")

if __name__=="__main__":
    main()
