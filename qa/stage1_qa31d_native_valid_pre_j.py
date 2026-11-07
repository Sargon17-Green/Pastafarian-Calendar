#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""QA31D finite original-Native same-size valid input intervention at pre-j.
Diagnostic, NOT Stage 1 acceptance; source/IP/stack are never changed.
"""
from __future__ import print_function
import os, sys, json, gzip, hashlib, StringIO
import stage1_qa20_native_input_route_scan as qa20
from stage1_qa31c_native_read_probe import ReadProbe

PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
CASES={
    "valid00":(0,"782fb868a11a105550ef5af6f8f7cd39e4ba9de77d9565f7549e310549b0073a","0 0 0 0\n"),
    "valid01":(1,"9c5af6212cfd7c1ab58e9603f385767e64b10799c90be416a86c4f09d613bfdd","0 0 0 1\n")
}
def need(ok,why):
    if not ok: raise AssertionError(why)
def sha(x): return hashlib.sha256(x).hexdigest()
def signed(root,label):
    shard,digest,raw_input=CASES[label]
    folder=os.path.join(root,label)
    b=open(os.path.join(folder,"qa20_manifest.json"),"rb").read()
    need(sha(b)==digest,"original signed QA20 manifest drift "+label)
    m=json.loads(b)
    need(m["schema"]=="qa20-native-natural-route-21-controls-v1" and
         m["shard"]==shard and m["source_git_blob"]==PIN and
         m["source_modified"] is False and m["ip_relocated"] is False and
         m["stage1_final_acceptance"] is False,"original QA20 origin invalid")
    rows=[x for x in m["records"] if x["label"]==label]
    need(len(rows)==1,"original signed route absent")
    r=rows[0]
    need(r["raw_input"]==raw_input and r["valid"] is True and
         r["natural_ip_no_intervention"] is True and
         r["output"]==r["expected"] and len(r["output"])==7,
         "original Native input/output certificate changed")
    z=open(os.path.join(folder,r["path"]),"rb").read()
    need(len(z)==r["compressed_bytes"] and sha(z)==r["compressed_trace_sha256"],
         "original complete STEP digest changed")
    lines=gzip.GzipFile(fileobj=StringIO.StringIO(z),mode="rb").read().splitlines()
    need(len(lines)==r["steps"],"original STEP count changed")
    return r,lines

def replay(source,root,label,output):
    rec,expected=signed(root,label)
    baseline=CASES["valid00"][2]
    delivered=CASES[label][2]
    read=ReadProbe(baseline,delivered)
    stdout=StringIO.StringIO()
    platform=qa20.BufferedPlatform([],{},stdin=read,stdout=stdout)
    program=qa20.Program(qa20.Befunge98,platform=platform)
    program.load_code(source)
    program.create_ip()
    need(len(program.ips)==1,"original IP count drift")
    item={"program":program,"steps":0,"stdin":read,"stdout":stdout}
    observations=[]
    trace=[]
    while program.ips:
        need(len(program.ips)==1,"unexpected multi-IP")
        ip=program.ips[0]
        tick=item["steps"]+1
        need(tick<=len(expected),"exceeded original Native signed STEP count")
        step=[tick,int(ip.position[0]),int(ip.position[1]),
              int(ip.delta[0]),int(ip.delta[1]),
              int(program.space.get(ip.position)),int(bool(ip.stringmode))]
        line="\t".join(map(str,step))
        need(line==expected[tick-1],"Native STEP mismatch %s:%d"%(label,tick))
        trace.append(line+"\n")
        read.tick,read.ip=tick,ip
        targeted=(step[1:]==[114,38,1,0,106,0])
        if targeted:
            stack=ip.stack
            need(len(stack)>0 and not stack.queuemode and not stack.invertmode,
                 "unexpected stack-stack modes")
            pre=list(stack[-1])
            need(len(pre)<100000,"unbounded pre-j stack witness")
            operand=int(pre[-1] if pre else 0)
        qa20.tick_qa20(item)
        if targeted:
            need(program.ips and program.ips[0] is ip,"original j IP changed")
            post=list(ip.stack[-1])
            need(post==(pre[:-1] if pre else []),"j did not consume exactly one operand")
            successor=[tick+1,int(ip.position[0]),int(ip.position[1]),
                       int(ip.delta[0]),int(ip.delta[1]),
                       int(program.space.get(ip.position)),int(bool(ip.stringmode))]
            need(tick<len(expected) and
                 "\t".join(map(str,successor))==expected[tick] and
                 successor[1]==114+operand+1,
                 "signed physical j successor inconsistent with stack operand")
            observations.append({"tick":tick,"pre_step":step,"next_step":successor,
                                 "operand":operand,"pre_toss":pre,"post_toss":post,
                                 "stack_stack_depth":len(ip.stack)})
    need(item["steps"]==rec["steps"] and stdout.getvalue().split()==rec["output"],
         "original signed Native output/steps drift")
    need(read.events,"original Native stdin was never read")
    name="qa31d_"+label+".steps.gz"
    with gzip.open(os.path.join(output,name),"wb") as handle:
        handle.write("".join(trace))
    zipped=open(os.path.join(output,name),"rb").read()
    return {"label":label,"shard":CASES[label][0],
            "input_sha256":sha(delivered),
            "original_trace_sha256":rec["compressed_trace_sha256"],
            "steps":item["steps"],"output":rec["output"],
            "step_trace_file":name,"step_trace_sha256":sha(zipped),
            "j_observations":observations,"read_events":read.events}

def main(root,output):
    source=open(qa20.SOURCE,"rb").read()
    need(qa20.pin(source)==PIN==qa20.PIN,"original BF98 production blob changed")
    a=CASES["valid00"][2];b=CASES["valid01"][2]
    need(len(a)==len(b)==8 and a!=b and
         [i for i,c in enumerate(a) if c=="\n"]==
         [i for i,c in enumerate(b) if c=="\n"],
         "inputs are not equal-length/equal-newline")
    sham=replay(source,root,"valid00",output)
    changed=replay(source,root,"valid01",output)
    x=sham["read_events"];y=changed["read_events"]
    altered=[i for i,e in enumerate(y) if e["baseline_hex"]!=e["delivered_hex"]]
    need(altered and altered[0]<len(x),"no authentic changed stdin read")
    first=altered[0]
    keys=("tick","method","start","end","ip","toss_sha256")
    need(all(x[first][k]==y[first][k] for k in keys) and
         all(x[i]==y[i] for i in xrange(first)),
         "pre-intervention input state differed")
    need(x[first]["baseline_hex"]==x[first]["delivered_hex"] and
         y[first]["baseline_hex"]==x[first]["baseline_hex"],
         "input substitution was not isolated")
    aj=sham["j_observations"];bj=changed["j_observations"]
    both=bool(aj and bj)
    differ=bool(both and [z["operand"] for z in aj]!=
                [z["operand"] for z in bj])
    report={"schema":"qa31d-finite-valid-pair-original-native-pre-j-v1",
            "project_id":"PC-BRANCH-BEFUNGE98-KYRGYZ",
            "source_git_blob":PIN,"source_modified":False,"ip_relocated":False,
            "initial_buffer_sha256":sha(a),
            "first_changed_read_index":first,
            "same_pre_read_state":True,
            "both_routes_reach_target_j":both,
            "pre_j_operand_difference_observed":differ,
            "scope":"finite-equal-length-valid-pair-only",
            "stage1_complete":False,"global_input_ownership_proven":False,
            "records":[sham,changed]}
    with open(os.path.join(output,"qa31d_native.json"),"wb") as f:
        f.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("QA31D_SIGNED_NATIVE_STEPS",sham["steps"]+changed["steps"])
    print("QA31D_J_VISITS",len(aj),len(bj))
    print("QA31D_FINITE_PRE_J_DIFFERENCE",differ)
    print("QA31D_NOT_STAGE1_ACCEPTANCE")
if __name__=="__main__":
    need(len(sys.argv)==3,"usage: QA31D QA20_ROOT OUTPUT")
    main(sys.argv[1],sys.argv[2])
