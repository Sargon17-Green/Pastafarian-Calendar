#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage 1 QA06: reconstruct future executable instructions from live historical residue.
All calendar arithmetic stays in Befunge. Only actual PyFunge execution is accepted.
"""
from __future__ import print_function
import hashlib
import json
import os
import subprocess
import tempfile

PRODUCTION = "src/interleaved_work_counts.b98"
PARENT = "qa/spaghetti05_shared_stamp_polynomial_candidate.b98"
CHILD = "qa/spaghetti06_residue_compiler_candidate.b98"
PARENT_BLOB = "59917c4c73be687bfe80b03818e38ad9c3a97243"
CHILD_BLOB = "d89c0499f9e006eb62cd5876bd297085265435d6"
CMD = ["pyfunge","--disable-fprint","--no-concurrent","--no-filesystem","-v98","-d2"]
ASSEMBLER = "99ge4g+6a*3+4g+ba*1+4g+2%a*4a*8++92*a*7p99g:1-\\2-*3a*6++92*a*1-7p99g:1-\\2-*6a*+92*a*2-7p"
GATE_COORDS = ((14,4),(63,4),(111,4))
GENERATED_COORDS = ((180,7),(179,7),(178,7))
CASES = [
    ("zero_equal","0 0 0 0",True,0),
    ("foundation_cross","1 15055672 1 15055670",True,1),
    ("forward_short","0 1 0 2",True,0),
    ("mixed_small","1 987654321 0 123456789",True,1),
    ("invalid_sign","2 10 0 10",False,None),
    ("invalid_lexeme","-0 1 0 1",False,None)
]
MUTANTS = [
    ("upper_history_corrupted","foundation_cross",345,5,"3"),
    ("lower_history_corrupted","zero_equal",343,9,"3"),
    ("historical_gate1_read_removed","foundation_cross",299,7,"z"),
    ("historical_gate2_read_removed","zero_equal",291,7,"z"),
    ("historical_gate3_read_removed","mixed_small",283,7,"z"),
    ("first_emitter_disabled","zero_equal",265,7,"z"),
    ("second_emitter_disabled","foundation_cross",240,7,"z"),
    ("third_emitter_disabled","zero_equal",217,7,"z"),
]
OVERWRITE_CONTROLS = [
    ("first_trap_is_irrelevant","zero_equal",180,7,"@"),
    ("second_trap_is_irrelevant","foundation_cross",179,7,"@"),
    ("third_trap_is_irrelevant","forward_short",178,7,"@")
]
def need(ok,why):
    if not ok: raise AssertionError(why)

def gitblob(b):
    return hashlib.sha1("blob %d\0%s"%(len(b),b)).hexdigest()

def run(path,data,trace=None,limit=55):
    env=os.environ.copy()
    env.pop("BF98_TRACE_LOG",None)
    if trace:
        env["BF98_TRACE_LOG"]=trace
        env["PYTHONPATH"]="/work/qa"
    command=["timeout","--kill-after=2s",str(limit)+"s"]+CMD+[path]
    proc=subprocess.Popen(command,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,env=env)
    out,err=proc.communicate(data+"\n")
    return proc.returncode,out.split(),err[-600:]

def oracle(data):
    c,t,tc,tt=data.split()
    allfields=[]
    for path,arg in (("reference/work_counts.b98",data),
                     ("reference/save.b98",c+" "+t),
                     ("reference/save.b98",tc+" "+tt)):
        rc,v,err=run(path,arg)
        need(rc==0 and v,"Native independent reference failure "+repr((path,rc,err)))
        allfields.extend(v)
    need(len(allfields)==7,"Independent reference output not seven fields")
    return allfields

def parse_trace(path):
    need(os.path.exists(path),"Native trace missing: "+path)
    events=[]
    with open(path,"r") as fp:
        for line in fp:
            bits=line.rstrip("\n").split("\t")
            if bits[0] in ("STEP","WRITE_BEFORE","WRITE_AFTER","READ_BEFORE","READ_AFTER"):
                events.append((bits[0],tuple(map(int,bits[1:]))))
    return events

def witness(path,arm):
    events=parse_trace(path)
    steps=[v for kind,v in events if kind=="STEP"]
    need(len(steps)>100,"Missing executed Native IP trace")
    fork=next((i for i,v in enumerate(steps) if v[2:4]==(350,6)),None)
    need(fork is not None and steps[fork][6]==ord("|"),"No actual input-dependent fork")
    outgoing=(350,5) if arm==1 else (350,7)
    need(steps[fork+1][2:4]==outgoing,"Wrong Native input fork successor")
    later=next((i for i in range(fork+1,len(steps)) if steps[i][2:4]==(320,7)),None)
    need(later is not None,"No actual postbranch join")
    dyn=next((i for i in range(later+1,len(steps)) if steps[i][2:4]==(190,7)),None)
    need(dyn is not None and steps[dyn][6]==ord("x"),"No original dynamic x")
    ft, jt, dt=steps[fork][0],steps[later][0],steps[dyn][0]
    stamp=1 if arm==1 else 2

    def filtered(kind,coord,lo,hi):
        return [v for kind0,v in events
                if kind0==kind and v[1:3]==coord and lo<v[0]<hi]
    stamp_writes=filtered("WRITE_AFTER",(9,9),ft,jt)
    stamp_reads=filtered("READ_BEFORE",(9,9),jt,dt)
    stamp_after=filtered("READ_AFTER",(9,9),jt,dt)
    need(len(stamp_writes)==1 and len(stamp_reads)>=4 and len(stamp_reads)==len(stamp_after),
         "Missing historical shared-cell write or four later independent reads")
    need(stamp_writes[0][3]==stamp and all(v[3]==stamp for v in stamp_reads+stamp_after),
         "Historical residue changed between production and compilation")

    # Three gate bytes were themselves installed in formerly blank source cells
    # by earlier self-modifying code. QA06 reads their *runtime* values.
    gatevals=[]
    gate_read_ticks=[]
    old_gate_writes=[]
    for coord in GATE_COORDS:
        prior=filtered("WRITE_AFTER",coord,0,ft)
        reads=filtered("READ_BEFORE",coord,jt,dt)
        need(len(reads)==1,"Missing unique compiler read of earlier gate "+repr(coord))
        gatevals.append(reads[0][3])
        gate_read_ticks.append(reads[0][0])
        old_gate_writes.append(len(prior))
        # The original source at those coordinates is blank; the current
        # value must have been installed by a previous native p event.
        need(bool(prior) and prior[-1][3]==reads[0][3],
             "Compiler gate byte lacks earlier native write provenance "+repr(coord))

    expected = [48+10*((stamp+sum(gatevals))%2),
                36+(stamp-1)*(stamp-2),
                60+(stamp-1)*(stamp-2)]
    need(expected[0] in (48,58) and expected[1:]==[36,60],
         "Normal branch did not generate the expected executable dialect")
    compilation=[]
    for coord,expected_byte in zip(GENERATED_COORDS,expected):
        before=filtered("WRITE_BEFORE",coord,jt,dt)
        after=filtered("WRITE_AFTER",coord,jt,dt)
        need(len(before)==len(after)==1,
             "Missing unique native p emission to source trap "+repr(coord))
        need(before[0][3]==ord("v") and after[0][3]==expected_byte
             and before[0][4]==expected_byte,
             "Source trap not replaced by expected dynamic opcode "+repr(coord))
        compilation.append({"xy":list(coord),"tick":after[0][0],
                            "from":before[0][3],"to":after[0][3]})

    need(jt<min(gate_read_ticks)<max(gate_read_ticks)<dt,
         "Historical gate reads not strictly inside shared compilation")
    need(jt<min(c["tick"] for c in compilation)<dt,
         "Generated instructions were not emitted before executing the next phase")
    generated=[]
    start=dyn+1
    for pos,expect_coord,expect_byte in zip(range(start,start+3),GENERATED_COORDS,expected):
        need(pos<len(steps),"Missing compiled code execution")
        step=steps[pos]
        need(step[2:4]==expect_coord and step[6]==expect_byte,
             "Executed instruction differs from native emitted byte at "+repr(expect_coord))
        generated.append({"xy":list(step[2:4]),"opcode":step[6],"tick":step[0],"depth":step[7]})
    need(generated[0]["depth"]+1==generated[1]["depth"]
         and generated[1]["depth"]-1==generated[2]["depth"],
         "Compiled dialect did not preserve stack ownership")
    need(generated[0]["tick"]>max(c["tick"] for c in compilation),
         "Future instruction executed before generated code existed")
    need(start+3<len(steps) and steps[start+3][2:4]==(109,7),
         "Generated westward final return never reached existing scanner")
    return {"arm":"upper" if arm else "lower","stamp":stamp,
            "fork_tick":ft,"join_tick":jt,"dynamic_x_tick":dt,
            "gate_values":gatevals,"gate_read_ticks":gate_read_ticks,
            "historical_gate_write_counts":old_gate_writes,
            "emission":compilation,"executed_bytecode":generated,
            "trace_sha256":hashlib.sha256(open(path,"rb").read()).hexdigest(),
            "total_native_steps":len(steps)}

def mutate_bytes(data,x,y,repl):
    lines=data.splitlines(True)
    row=bytearray(lines[y])
    old=chr(row[x])
    need(old!=repl,"Inert source mutation "+repr((x,y,old,repl)))
    row[x]=ord(repl)
    lines[y]=bytes(row)
    return "".join(lines),old

def tempfile_run(data,case,label,trace=False,limit=9):
    fd,path=tempfile.mkstemp(prefix="spaghetti06_"+label+"_",suffix=".b98")
    with os.fdopen(fd,"wb") as fp:fp.write(data)
    tpath="/work/spaghetti06_native_mut_"+label+".tsv" if trace else None
    try:
        rc,out,err=run(path,case,trace=tpath,limit=limit)
        return rc,out,err,tpath
    finally:
        os.unlink(path)

parent=open(PARENT,"rb").read()
child=open(CHILD,"rb").read()
need(gitblob(parent)==PARENT_BLOB and gitblob(child)==CHILD_BLOB,
     "Git blob pin failure: original executable specimens not exact")
before=parent.splitlines()
after=child.splitlines()
need(len(before)==len(after)==2015,"Source row count unexpectedly changed")
changes=[]
for y in range(len(before)):
    for x in range(max(len(before[y]),len(after[y]))):
        p=before[y][x] if x<len(before[y]) else " "
        q=after[y][x] if x<len(after[y]) else " "
        if p!=q: changes.append((x,y,p,q))
need(len(changes)==91,"Source edit count not 91")
need(after[7][217:305]==ASSEMBLER[::-1] and after[7][178:181]=="vvv",
     "Runtime compiler and unresolved source tripwires not present")
need(after[7][190:204]=="x0-1*-2\\-1:g99" and after[6][350]=="|",
     "QA05 downstream computation or QA04 fork changed")
need(after[4][14]==after[4][63]==after[4][111]==" ",
     "Formerly blank historical gate source positions not preserved")

records=[]
controls={}
for label,data,valid,arm in CASES:
    trace="/work/spaghetti06_native_"+label+".tsv" if arm is not None else None
    prod=run(PRODUCTION,data)
    past=run(PARENT,data)
    built=run(CHILD,data,trace=trace)
    need(prod[0]==past[0]==built[0]==0 and prod[1]==past[1]==built[1],
         "Native production/QA05/QA06 parity failure "+repr((label,prod,past,built)))
    if valid:
        need(built[1]==oracle(data),"Independent native Befunge reference mismatch "+label)
    else:
        need(len(built[1])==7,"Invalid input output shape changed "+label)
    detail=witness(trace,arm) if trace else None
    records.append({"name":label,"input":data,"valid":valid,"output":built[1],"compiler":detail})
    controls[label]=built[1]
    if detail:
        print("SPAGHETTI06_NATIVE_RECONSTRUCTED_BYTECODE",label,
              "gate_values",detail["gate_values"],
              "branch_stamp",detail["stamp"],
              "emitted_opcodes",[d["to"] for d in detail["emission"]],
              "executed_opcodes",[d["opcode"] for d in detail["executed_bytecode"]])
    print("SPAGHETTI06_NATIVE_PARITY_PASS",label)

# A mutant that prevents compiler input / instruction emission must not
# be judged only by output: if it terminates normally, compare emitted opcodes.
mutations=[]
for label,case,x,y,repl in MUTANTS:
    fields=next(data for n,data,_,_ in CASES if n==case)
    alter,old=mutate_bytes(child,x,y,repl)
    rc,out,err,path=tempfile_run(alter,fields,label,trace=False,limit=9)
    changed=rc!=0 or out!=controls[case]
    need(changed,"Emitter/history sabotage did not affect final or termination "+label)
    mutations.append({"case":case,"label":label,"xy":[x,y],
                      "old":old,"new":repl,"return_code":rc,
                      "output_or_termination_changed":changed})
    print("SPAGHETTI06_HISTORY_OR_EMITTER_SABOTAGE",label,rc,changed)

# Mutating the *unexecuted original text* is purposely a GREEN metamorphic
# control, because p overwrites each source trap BEFORE it can execute.
masked=[]
for label,case,x,y,repl in OVERWRITE_CONTROLS:
    fields=next(data for n,data,_,_ in CASES if n==case)
    alter,old=mutate_bytes(child,x,y,repl)
    rc,out,err,trace=tempfile_run(alter,fields,label,trace=True,limit=55)
    need(rc==0 and out==controls[case],"Source masking failed "+label)
    arm=next(a for n,data,v,a in CASES if n==case)
    detail=witness(trace,arm)
    masked.append({"case":case,"name":label,"xy":[x,y],
                   "original_trap":old,"mutant_trap":repl,
                   "executed_bytecode":[v["opcode"] for v in detail["executed_bytecode"]]})
    print("SPAGHETTI06_MASKED_STATIC_TEXT_PASS",label)
need(sum(bool(r["compiler"]) for r in records)==4,"Missing four valid native bytecode traces")
need(sum(r["compiler"]["arm"]=="upper" for r in records if r["compiler"])==2
     and sum(r["compiler"]["arm"]=="lower" for r in records if r["compiler"])==2,
     "Missing two witnesses for each Native branch")

with open("/work/spaghetti06_native_receipt.json","w") as fp:
    json.dump({"schema":"befunge98-spaghetti06-residue-compiler-native-v1",
       "parent_sha":PARENT_BLOB,"candidate_sha":CHILD_BLOB,
       "qa_only":True,"production_modified":False,"stage1_complete":False,
       "changed_cells":len(changes),"cases":records,"mutants":mutations,
       "masked_source_controls":masked},
       fp,sort_keys=True,indent=2)
print("SPAGHETTI06_NATIVE_RESIDUE_COMPILER_PASS")
