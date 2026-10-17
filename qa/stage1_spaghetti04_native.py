#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native PyFunge: real scanner-byte parity fork, two arithmetic arms, one join.
QA only. No calendar arithmetic reimplemented in Python.
"""
from __future__ import print_function
import hashlib,json,os,subprocess,tempfile

PRODUCTION="src/interleaved_work_counts.b98"
PARENT="qa/spaghetti03_arithmetic_braid_candidate.b98"
CANDIDATE="qa/spaghetti04_input_parity_bifurcation_candidate.b98"
PARENT_SHA="2baa1795a9a5802f58ecbd87ac8f138a1e811066"
CANDIDATE_SHA="2120c61485ae196dc387e617d3cff69a272bc413"
COMMAND=["pyfunge","--disable-fprint","--no-concurrent","--no-filesystem","-v98","-d2"]
CASES=[
    ("zero_equal","0 0 0 0",True,0),
    ("foundation_cross","1 15055672 1 15055670",True,1),
    ("forward_short","0 1 0 2",True,0),
    ("mixed_small","1 987654321 0 123456789",True,1),
    ("invalid_sign","2 10 0 10",False,None),
    ("invalid_lexeme","-0 1 0 1",False,None)
]
MUTATIONS=[
    ("south_live_vector","zero_equal",350,8,"1"),
    ("north_computed_vector","foundation_cross",334,5,"z"),
    ("north_input_to_vector","mixed_small",338,5,"1"),
    ("common_velocity","forward_short",198,7,"+")
]
def gitblob(data):
    return hashlib.sha1("blob %d\0%s"%(len(data),data)).hexdigest()
def need(v,msg):
    if not v:raise AssertionError(msg)
def run(path,inp,trace=None,limit=55):
    env=os.environ.copy()
    env.pop("BF98_TRACE_LOG",None)
    if trace:
        env["BF98_TRACE_LOG"]=trace
        env["PYTHONPATH"]="/work/qa"
    p=subprocess.Popen(["timeout","--kill-after=2s",str(limit)+"s"]+COMMAND+[path],
          stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,env=env)
    o,e=p.communicate(inp+"\n")
    return p.returncode,o.split(),e[-600:]
def native_expected(inp):
    a,b,c,d=inp.split()
    parts=[("reference/work_counts.b98",inp),
           ("reference/save.b98",a+" "+b),
           ("reference/save.b98",c+" "+d)]
    result=[]
    for path,fields in parts:
        rc,v,err=run(path,fields)
        need(rc==0 and v,"Native reference "+path+" "+repr(err))
        result.extend(v)
    need(len(result)==7,"Reference output must contain seven fields")
    return result
def analyze_native_trace(path,expected_arm):
    steps=[]
    need(os.path.isfile(path),"Missing actual Native STEP trace")
    with open(path,"r") as fp:
        for line in fp:
            bits=line.rstrip("\n").split("\t")
            if bits[0]=="STEP":
                need(len(bits)==9,"Malformed native STEP record")
                steps.append(tuple(map(int,bits[1:8])))
    gates=[i for i,v in enumerate(steps) if v[2:4]==(350,6)]
    need(len(gates)>=1,"Native conditional | must execute")
    idx=gates[0]
    step=steps[idx]
    need(step[6]==ord("|"),"Native fork executed wrong opcode")
    need(idx+1<len(steps),"Missing next Native IP instruction")
    next_xy=steps[idx+1][2:4]
    expect=(350,5) if expected_arm==1 else (350,7)
    need(next_xy==expect,"Native fork selected wrong actual direction "+repr((expect,next_xy)))
    limit=gates[1] if len(gates)>1 else len(steps)
    segment=steps[idx+1:limit]
    upper=(333,5) in [item[2:4] for item in segment]
    lower=(350,8) in [item[2:4] for item in segment]
    need(upper==(expected_arm==1) and lower==(expected_arm==0),
         "Native branch arm evidence mismatched expected sign byte")
    join=[i for i in range(idx+1,limit) if steps[i][2:4]==(320,7)]
    need(len(join)>=1,"Native path must rejoin at directed join")
    reentry=[i for i in range(join[0]+1,limit) if steps[i][2:4]==(109,5)]
    need(bool(reentry),"Native fork never returned to lexical scanner")
    return {"fork_tick":step[0],"fork_opcode":step[6],"outgoing":list(next_xy),
            "arm":"upper" if expected_arm else "lower",
            "join_tick":steps[join[0]][0],
            "reentry_tick":steps[reentry[0]][0],
            "executed_forks":len(gates),
            "native_step_records":len(steps),"trace_sha256":hashlib.sha256(open(path,"rb").read()).hexdigest()}
parent=open(PARENT,"rb").read()
candidate=open(CANDIDATE,"rb").read()
need(gitblob(parent)==PARENT_SHA and gitblob(candidate)==CANDIDATE_SHA,
     "Pinned source SHA conflict")
p=parent.splitlines()
c=candidate.splitlines()
need(len(p)==len(c)==2015,"Source rows changed")
changes=[]
for y in range(len(p)):
    for x in range(max(len(p[y]),len(c[y]))):
        old=p[y][x] if x<len(p[y]) else " "
        new=c[y][x] if x<len(c[y]) else " "
        if old!=new:changes.append((x,y,old,new))
need(len(changes)==28,"Expected 28 source-cell edits")
need(c[5][108:110]=="v>" and c[6][350]=="|" and c[7][109]=="^" and c[7][200]==":" and c[7][196]=="x"
     and c[5][350]=="<" and c[9][320]=="^","Route source map")
for (x,y) in ((14,4),(63,4),(111,4)):
    need(c[y][x]==" ","Historical runtime gate source unexpectedly modified")

rows=[]
byname={}
for name,fields,valid,sign in CASES:
    trace="/work/spaghetti04_native_"+name+".tsv" if sign is not None else None
    p_rc,p_out,p_err=run(PRODUCTION,fields)
    r_rc,r_out,r_err=run(PARENT,fields)
    c_rc,c_out,c_err=run(CANDIDATE,fields,trace=trace)
    need(p_rc==r_rc==c_rc==0 and p_out==r_out==c_out,
         "Native production/parent/candidate mismatch "+name+repr((p_rc,r_rc,c_rc,p_out,r_out,c_out,p_err,r_err,c_err)))
    if valid:
        expected=native_expected(fields)
        need(c_out==expected,"Independent Native numeric oracle mismatch "+name)
    elif len(c_out)!=7:
        raise AssertionError("Invalid scanner output shape "+name)
    route=analyze_native_trace(trace,sign) if trace else None
    if route: print("NATIVE_SPAGHETTI04_ACTUAL_BRANCH",name,route)
    rows.append({"name":name,"input":fields,"valid":valid,"reference_parity":True,
                 "route":route,"output":c_out})
    byname[name]=c_out
    print("NATIVE_SPAGHETTI04_REFERENCE_PASS",name)

mutations=[]
for label,case,x,y,replacement in MUTATIONS:
    raw=candidate.splitlines(True)
    v=bytearray(raw[y]);original=chr(v[x])
    need(original!=replacement,"Mutation has no effect "+label)
    v[x]=ord(replacement);raw[y]=bytes(v)
    fd,path=tempfile.mkstemp(prefix="spaghetti04_"+label+"_",suffix=".b98")
    file=os.fdopen(fd,"wb")
    file.write("".join(raw))
    file.close()
    try:
        inp=next(fields for n,fields,valid,sign in CASES if n==case)
        rc,result,err=run(path,inp,limit=12)
        changed=bool(rc!=0 or result!=byname[case])
        mutations.append({"label":label,"case":case,
              "coordinate":[x,y],"source_opcode":original,"replacement":replacement,
              "exit_code":rc,"changed_outcome":changed})
        need(changed,"The Native mutation was numerically/execution-inert: "+label)
        print("NATIVE_SPAGHETTI04_ARM_MUTATION_CAUSAL",label,rc)
    finally:os.unlink(path)

with open("/work/spaghetti04_native_receipt.json","w") as outfile:
    json.dump({"schema":"befunge-spaghetti04-real-native-input-fork-v1",
        "production_modified":False,"candidate_promoted":False,
        "stage1_complete":False,"new_source_cells":len(changes),
        "observations":rows,"negative_controls":mutations},
        outfile,sort_keys=True,indent=2)
need(sum(row["route"] is not None for row in rows)==4,"Missing Native split controls")
need(sum(row["route"]["arm"]=="upper" for row in rows if row["route"])==2
     and sum(row["route"]["arm"]=="lower" for row in rows if row["route"])==2,
     "Both actual Native input-dependent routes must be exercised twice")
print("NATIVE_SPAGHETTI04_TWO_ARMS_AND_CAUSALITY_PASS")
