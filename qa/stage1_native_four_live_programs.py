#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Real Native BF98 four simultaneously live owned Funge-space Programs.

Four separate PyFunge-98 Program instances execute unchanged pinned production
source, same writable physical coordinates but PRIVATE memory. All 4 overlap.
Two unequal quantum/order profiles must preserve isolated outputs and
per-program exact instruction/get/put signatures. Every peer is snapshot-
checked after each quantum, with full prior-written peer cells sampled too.
Arithmetic references are independent Native BF98 programs, not Python.
Finite QA only: NEVER Stage 1 completion.
"""
from __future__ import print_function
import hashlib,json,os,sys
import stage1_native_live_pair_matrix as base
import stage1_native_invalid_memory_ownership as invalid

PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
ROOT="/quads"
PROFILES=(
  ("ABCD_11_7_13_5",(11,7,13,5),(0,1,2,3)),
  ("DCBA_2_17_3_19",(2,17,3,19),(3,2,1,0)),
)
GROUPS=(
  ("v0","v1","v2","v3"),
  ("v2","v3","i0","i10"),
  ("i1","v0","i16","v5"),
  ("v4","i4","v1","i14"),
  ("i20","v2","i6","v3"),
  ("i9","i18","v0","v4"),
  ("i0","i8","i11","i17"),
)
MAX_ROUNDS=250000
def need(ok,why):
    if not ok:raise AssertionError(why)
def execute(source,group,profile,expected):
    name,quanta,order=profile
    members=[base.make(source,label) for label in group]
    need(len({id(x["program"]) for x in members})==4 and
         len({id(x["program"].space) for x in members})==4 and
         len({id(x["program"].semantics) for x in members})==4 and
         len({id(x["stdin"]) for x in members})==4 and
         len({id(x["stdout"]) for x in members})==4,
         "Native four Programs share interpreter, memory or I/O")
    cls=type(members[0]["program"].space)
    need(all(type(x["program"].space) is cls for x in members),
         "four real Funge spaces have incompatible API types")
    get0,put0,putspace0=cls.get,cls.put,cls.putspace
    active=[None]
    counters={label:{"get":0,"put":0,"putspace":0,"direct_p":0}
              for label in group}
    written={label:set() for label in group}
    def guarded_get(self,*args,**kwargs):
        current=active[0]
        if current is not None:
            need(self is current["program"].space,
                 "Native quad read crossed Funge-space owner")
            counters[current["label"]]["get"]+=1
        return get0(self,*args,**kwargs)
    def guarded_put(self,*args,**kwargs):
        current=active[0]
        need(current is not None and
             self is current["program"].space and len(args)>=2,
             "Native quad memory write was not owned by active Program")
        result=put0(self,*args,**kwargs)
        need(int(get0(self,args[0]))==int(args[1]),
             "real Native quad put did not persist actual written byte")
        counters[current["label"]]["put"]+=1
        written[current["label"]].add(tuple(map(int,args[0])))
        return result
    def guarded_putspace(self,*args,**kwargs):
        current=active[0]
        need(current is not None and self is current["program"].space,
             "Native putspace escaped active quad")
        counters[current["label"]]["putspace"]+=1
        return putspace0(self,*args,**kwargs)
    def snapshot(peer,include_written):
        state=base.state(peer)
        if not include_written:return (state,None)
        point=peer["point"]
        cells=tuple((xy,int(get0(peer["program"].space,point(xy))))
                    for xy in sorted(written[peer["label"]]))
        return (state,cells)
    rounds=overlap=peer_checks=physical_checks=after_first=0
    first_done=None
    try:
        cls.get,cls.put,cls.putspace=guarded_get,guarded_put,guarded_putspace
        while any(x["program"].ips for x in members):
            rounds+=1
            need(rounds<=MAX_ROUNDS,"Native four-program quantum bound reached")
            live=sum(bool(x["program"].ips) for x in members)
            if live==4:overlap+=1
            if first_done is not None:after_first+=1
            for idx in order:
                cur=members[idx]
                if not cur["program"].ips:continue
                peers=[p for j,p in enumerate(members) if j!=idx]
                detailed=rounds<=8 or rounds%173==0
                before=[snapshot(x,detailed) for x in peers]
                for unused in range(quanta[idx]):
                    if not cur["program"].ips:break
                    p=cur["program"];ip=p.ips[0]
                    opcode=int(get0(p.space,ip.position))
                    if opcode==ord("p") and not ip.stringmode:
                        counters[cur["label"]]["direct_p"]+=1
                    active[0]=cur
                    try:base.tick(cur)
                    finally:active[0]=None
                    if not p.ips and first_done is None:
                        first_done=cur["label"]
                for x,prior in zip(peers,before):
                    need(snapshot(x,detailed)==prior,
                         "Native active quad quantum changed a peer's state")
                    peer_checks+=1
                    if detailed:physical_checks+=len(written[x["label"]])
    finally:
        active[0]=None
        cls.get,cls.put,cls.putspace=get0,put0,putspace0
    need(overlap>0 and peer_checks>0 and after_first>0
         and physical_checks>0 and first_done in group,
         "four live Native Programs did not overlap or preserve peer states")
    records=[]
    for x in members:
        label=x["label"];values=counters[label]
        output=x["stdout"].getvalue().split()
        need(not x["program"].ips and
             output==expected[label] and len(output)==7 and
             values["get"]>0 and values["put"]>0
             and values["put"]==values["direct_p"]
             and values["putspace"]==0
             and 0<len(written[label])<=values["put"],
             "Native quad per-Program reference, memory API or termination invalid")
        records.append({"label":label,"output":output,"ticks":x["steps"],
                        "native_get":values["get"],"native_put":values["put"],
                        "native_direct_p":values["direct_p"],
                        "native_putspace":values["putspace"],
                        "physical_written_coordinates":len(written[label])})
    return {"group":list(group),"profile":name,"programs":records,
            "all_four_alive_rounds":overlap,
            "three_passive_state_checks":peer_checks,
            "previous_written_peer_address_checks":physical_checks,
            "rounds_after_first_finished":after_first,
            "first_finished_label":first_done,
            "separate_programs_spaces_semantics_io":True,
            "every_get_put_owned_by_active":True,
            "all_three_peers_frozen_per_quantum":True,
            "all_four_terminated_reference_equal":True}
def main():
    need(os.path.isdir(ROOT),"Native quad evidence directory missing")
    src=open(base.SOURCE,"rb").read()
    got=hashlib.sha1("blob %d\0%s"%(len(src),src)).hexdigest()
    need(got==PIN==base.PIN,"native production BF98 source modified")
    bad=list(invalid.NUMERIC)+list(invalid.LEXICAL)
    need(len(bad)==21 and len(set(bad))==21,
         "original 21 invalid BF98 lexemes not available")
    base.INVALID=bad
    labels=sorted({label for group in GROUPS for label in group})
    oracles={}
    for label in labels:
        oracles[label]=base.reference(label)
        need(len(oracles[label])==7 and
             (label[0]!="i" or oracles[label]==["-1"]*7),
             "independent Native BF98 oracle missing or invalid input leaked")
    signatures={}
    results=[]
    for profile in PROFILES:
        for group in GROUPS:
            rec=execute(src,group,profile,oracles)
            for item in rec["programs"]:
                name=item["label"]
                sig=(item["ticks"],item["native_get"],item["native_put"],
                     tuple(item["output"]))
                if name in signatures:
                    need(signatures[name]==sig,
                         "Native quad output/step/API signature changes with peers/order")
                else:signatures[name]=sig
            results.append(rec)
            print("NATIVE_FOUR_LIVE_PROGRAMS_PASS",profile[0],
                  ",".join(group),"all_live_rounds",rec["all_four_alive_rounds"],
                  "peer_checks",rec["three_passive_state_checks"])
            sys.stdout.flush()
    need(len(results)==14 and len(signatures)==len(labels),
         "Native four-live independence matrix not exhausted")
    report={"schema":"befunge-stage1-native-four-live-ownership-v1",
            "source_git_blob":PIN,"status":"FINITE_NATIVE_QA_STAGE1_OPEN",
            "quadruples":[list(g) for g in GROUPS],
            "schedules":[{"name":x[0],"quanta":list(x[1]),"order":list(x[2])}
                         for x in PROFILES],
            "valid_reference_labels":sorted(x for x in labels if x[0]=="v"),
            "invalid_reference_labels":sorted(x for x in labels if x[0]=="i"),
            "invalid_full_corpus":bad,
            "native_four_program_trials":14,
            "native_program_executions":56,
            "all_four_programs_ever_simultaneously_live":True,
            "independent_befunge_reference_calls":
                3*len([x for x in labels if x[0]=="v"]),
            "last_completed_stage":0,"stage1_final_acceptance":False,
            "production_modified":False,"oracle":oracles,"records":results}
    with open(ROOT+"/native_four_live_programs.json","wb") as f:
        f.write(json.dumps(report,indent=2,sort_keys=True)+"\n")
    print("NATIVE_FOUR_LIVE_14_TRIALS_56_PROGRAMS_MEASURED_STAGE1_OPEN")
if __name__=="__main__":main()
