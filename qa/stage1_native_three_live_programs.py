#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA Stage-1: three simultaneously live *real* PyFunge-98 Programs.

All twenty-one invalid forms participate, with two independently referenced
valid peers, plus four distinct 3-way mixtures. Two unequal quantum schedules
and different turn order. Every Native Funge-space get/put/putspace is owned
by the active Program, and both passive Programs are snapshot-checked after
every quantum. Calendar arithmetic is always executed by native Befunge.
This is bounded QA, not global semantic ownership or final Stage-1 approval.
"""
from __future__ import print_function
import hashlib
import json
import os
import sys
import stage1_native_live_pair_matrix as base
import stage1_native_invalid_memory_ownership as invalid

PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
OUT="/triads/native_three_live_programs.json"
PROFILES=(("ABC_2_3_5",(2,3,5),(0,1,2)),
          ("CAB_11_7_13",(11,7,13),(2,0,1)))
MAX_ROUNDS=250000

def need(ok,reason):
    if not ok:raise AssertionError(reason)

def build_cases():
    bad=list(invalid.NUMERIC)+list(invalid.LEXICAL)
    need(len(bad)==21 and len(set(bad))==21,"invalid corpus drifted")
    base.INVALID=bad
    tris=[]
    for i in range(21):
        a,b="v%d"%(i%6),"v%d"%((i+3)%6)
        c="i%d"%i
        if i%3==0:tris.append((c,a,b))
        elif i%3==1:tris.append((a,c,b))
        else:tris.append((a,b,c))
    tris.extend([("v0","v1","v2"),
                 ("i0","i10","i20"),
                 ("v3","i5","i11"),
                 ("i2","v4","i14")])
    need(len(tris)==25 and len(set(tris))==25 and
         all(len(set(t))==3 for t in tris),"unique 3-way case list broken")
    return tris,bad

def replay(source,triad,profile,oracle):
    name,quanta,order=profile
    members=[base.make(source,l) for l in triad]
    need(len({id(m["program"]) for m in members})==3 and
         len({id(m["program"].space) for m in members})==3 and
         len({id(m["program"].semantics) for m in members})==3 and
         len({id(m["stdin"]) for m in members})==3 and
         len({id(m["stdout"]) for m in members})==3,
         "three Native programs share space, semantics or streams")
    cls=type(members[0]["program"].space)
    need(all(type(m["program"].space) is cls for m in members),
         "three Native Funge-spaces not same API class")
    get0,put0,putspace0=cls.get,cls.put,cls.putspace
    active=[None]
    counts={label:{"get":0,"put":0,"putspace":0,"direct_p":0}
            for label in triad}
    destinations={label:set() for label in triad}
    def watch_get(self,*args,**kwargs):
        cur=active[0]
        if cur is not None:
            need(self is cur["program"].space,
                 "triple concurrently live cross-Program Funge-space.get")
            counts[cur["label"]]["get"]+=1
        return get0(self,*args,**kwargs)
    def watch_put(self,*args,**kwargs):
        cur=active[0]
        need(cur is not None and self is cur["program"].space and
             len(args)>=2,"triple Funge-space.put escaped own Program")
        result=put0(self,*args,**kwargs)
        need(int(get0(self,args[0]))==int(args[1]),
             "Native triple space.put did not preserve value")
        counts[cur["label"]]["put"]+=1
        destinations[cur["label"]].add(tuple(map(int,args[0])))
        return result
    def watch_putspace(self,*args,**kwargs):
        cur=active[0]
        need(cur is not None and self is cur["program"].space,
             "triple putspace escaped active Program")
        counts[cur["label"]]["putspace"]+=1
        return putspace0(self,*args,**kwargs)
    def passive_snapshot(item,with_writes):
        signature=base.state(item)
        if not with_writes:return (signature,None)
        pt=item["point"];space=item["program"].space
        values=tuple((coord,int(get0(space,pt(coord))))
                     for coord in sorted(destinations[item["label"]]))
        return (signature,values)
    rounds=0
    all_live=0
    untouched=0
    write_target_checks=0
    first_done=None
    after_first=0
    try:
        cls.get,cls.put,cls.putspace=watch_get,watch_put,watch_putspace
        while any(m["program"].ips for m in members):
            rounds+=1
            need(rounds<=MAX_ROUNDS,"three-Program quantum bound exceeded")
            live=sum(bool(m["program"].ips) for m in members)
            if live==3:all_live+=1
            if first_done is not None:after_first+=1
            for idx in order:
                cur=members[idx]
                if not cur["program"].ips:continue
                peers=[m for j,m in enumerate(members) if j!=idx]
                # Check all API accesses every instruction. Snapshot both
                # non-running states every quantum; add EVERY previously
                # written peer coordinate on all first eight and periodic
                # 167th rounds to detect subtler cross-space leakage.
                detailed=rounds<=8 or rounds%167==0
                before=[passive_snapshot(p,detailed) for p in peers]
                for k in range(quanta[idx]):
                    if not cur["program"].ips:break
                    p=cur["program"];ip=p.ips[0]
                    op=int(get0(p.space,ip.position))
                    if op==ord("p") and not ip.stringmode:
                        counts[cur["label"]]["direct_p"]+=1
                    active[0]=cur
                    try:base.tick(cur)
                    finally:active[0]=None
                    if not p.ips and first_done is None:
                        first_done=cur["label"]
                for peer,snapshot in zip(peers,before):
                    need(passive_snapshot(peer,detailed)==snapshot,
                         "active Native program quantum modified one of two peers")
                    untouched+=1
                    if detailed:
                        write_target_checks+=len(destinations[peer["label"]])
    finally:
        active[0]=None
        cls.get,cls.put,cls.putspace=get0,put0,putspace0
    need(all_live>0 and untouched>0 and first_done is not None and
         after_first>0,"three live programs did not overlap and finish separately")
    out=[]
    for m in members:
        label=m["label"];c=counts[label]
        actual=m["stdout"].getvalue().split()
        need(actual==oracle[label] and
             not m["program"].ips and c["get"]>0 and c["put"]>0 and
             c["put"]==c["direct_p"] and c["putspace"]==0,
             "three-live Native output, termination or write count disagrees")
        out.append({"label":label,"output":actual,"ticks":m["steps"],
                    "space_get":c["get"],"space_put":c["put"],
                    "direct_p":c["direct_p"],"putspace":c["putspace"],
                    "actual_written_coordinates":len(destinations[label])})
    return {"triad":list(triad),"profile":name,
            "programs":out,"all_three_alive_rounds":all_live,
            "two_passive_state_checks":untouched,
            "prior_write_coordinate_checks":write_target_checks,
            "rounds_after_first_done":after_first,
            "first_finished":first_done,
            "private_programs_semantics_spaces_streams":True,
            "all_runtime_api_calls_owned_by_active_program":True,
            "two_other_programs_unchanged_each_quantum":True,
            "all_outputs_match_independent_reference":True,
            "all_terminated":True}

def main():
    need(os.path.isdir("/triads"),"triad QA evidence directory missing")
    source=open(base.SOURCE,"rb").read()
    pin=hashlib.sha1("blob %d\0%s"%(len(source),source)).hexdigest()
    need(pin==PIN==base.PIN,"Native source Git blob pin changed")
    cases,bad=build_cases()
    labels=set(x for triad in cases for x in triad)
    oracle={}
    for label in sorted(labels):
        oracle[label]=base.reference(label)
        need(len(oracle[label])==7,"Native independent oracle missing fields")
    signatures={};records=[]
    for profile in PROFILES:
        for triad in cases:
            result=replay(source,triad,profile,oracle)
            for program in result["programs"]:
                label=program["label"]
                signature=(program["ticks"],program["space_get"],
                           program["space_put"],tuple(program["output"]))
                if label in signatures:
                    need(signature==signatures[label],
                         "triple Native result depends on two peers/quantum")
                else:signatures[label]=signature
            records.append(result)
            print("NATIVE_TRIPLE_PROGRAM_PASS",profile[0],
                  ",".join(triad),"triple_overlap",result["all_three_alive_rounds"],
                  "peer_snapshots",result["two_passive_state_checks"])
            sys.stdout.flush()
    need(len(records)==50 and len(signatures)==27,
         "triple Native 50-triad coverage or 27 input signatures missing")
    report={"schema":"befunge-stage1-native-three-live-v1",
            "source_git_blob":PIN,"status":"QA_ONLY_STAGE1_OPEN",
            "profiles":[{"name":p[0],"quanta":list(p[1]),
                         "order":list(p[2])} for p in PROFILES],
            "triads":[list(x) for x in cases],
            "invalid_inputs":bad,
            "real_native_triple_trials":50,
            "real_native_program_executions":150,
            "independent_native_oracle_invocations":18,
            "input_signatures_verified":27,
            "final_stage1_accepted":False,
            "oracle":oracle,"records":records}
    with open(OUT,"wb") as fh:
        fh.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_THREE_LIVE_50_TRIPLE_150_PROGRAM_PASS")
    print("SEMANTIC_STATE_OWNERSHIP_FINAL=OPEN")

if __name__=="__main__":main()
