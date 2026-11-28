#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA: actual Native BF98 p fault with three LIVE peers and immediate SAME-object recovery.

Inject immediately after real Funge-space.put in one of four live Programs.
Reinitialize the exact faulted Program while the other 3 remain alive,
without advancing or touching them, then finish all four under two distinct
round-robin quantum orders. Hold the abandoned dirty Funge-space and its
I/O objects; assert these and each peer's actual previously written cells
never change after recovery. References are computed in independent Native
Befunge programs; no Python Pastafarian arithmetic; Stage1 stays OPEN.
"""
from __future__ import print_function
import hashlib,json,os,sys,StringIO
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_live_pair_matrix as base
import stage1_native_invalid_memory_ownership as invalid

PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
OUT="/quad-fault"
SCENARIOS=(
    (("v0","v1","v2","i0"),0,1),
    (("i4","v3","i6","v5"),0,1),
    (("v2","v3","v4","v5"),2,20),
    (("i0","v5","i1","v3"),1,5),
)
PROFILES=(("ABCD_2_3_5_7",(2,3,5,7),(0,1,2,3)),
          ("DCBA_11_13_17_19",(11,13,17,19),(3,2,1,0)))
MAX_ROUNDS=250000
class InjectedAfterNativeP(Exception):pass
def need(v,msg):
    if not v:raise AssertionError(msg)
def snapshot(item,orig_get,coords):
    p=item["program"]
    point=item["point"]
    return tuple((xy,int(orig_get(p.space,point(xy))))
                 for xy in sorted(coords))
def trial(code,case,profile,oracle):
    labels,failing,depth=case
    profname,quanta,order=profile
    members=[base.make(code,label) for label in labels]
    need(len({id(x["program"]) for x in members})==4
         and len({id(x["program"].space) for x in members})==4
         and len({id(x["program"].semantics) for x in members})==4
         and len({id(x["stdin"]) for x in members})==4
         and len({id(x["stdout"]) for x in members})==4,
         "four live Native BF98 programs not independent")
    cls=type(members[0]["program"].space)
    orig_get,orig_put,orig_putspace=cls.get,cls.put,cls.putspace
    active=[None];fired=[False];recovered=[False]
    first_fault_round=[None];live_at_fault=[None]
    old_space=[None];old_io=[None];old_memory=[None];old_vec=[None]
    abandoned_set=[None];initial_fault_ticks=[None];first_recovered_round=[None]
    counters=[{"get":0,"put":0,"direct_p":0,"putspace":0} for _ in labels]
    dirty_stats=[None];wrote=[set() for _ in labels]
    peer_check=physical_check=abandoned_check=overlap_rounds=rounds=0
    def get(self,*args,**kwargs):
        idx=active[0]
        if idx is not None:
            need(self is members[idx]["program"].space,
                 "Native Funge-space read escaped active Program")
            counters[idx]["get"]+=1
        return orig_get(self,*args,**kwargs)
    def put(self,*args,**kwargs):
        idx=active[0]
        need(idx is not None and self is members[idx]["program"].space
             and len(args)>=2,
             "Native put escaped active Program")
        ip=members[idx]["program"].ips[0]
        need(int(orig_get(self,ip.position))==ord("p") and not ip.stringmode,
             "Native put not caused by executed BF98 p")
        result=orig_put(self,*args,**kwargs)
        need(int(orig_get(self,args[0]))==int(args[1]),
             "real Native BF98 put not persisted")
        counters[idx]["put"]+=1
        wrote[idx].add(tuple(map(int,args[0])))
        if idx==failing and not fired[0] and counters[idx]["put"]==depth:
            fired[0]=True
            raise InjectedAfterNativeP("after actual native p write")
        return result
    def putspace(self,*args,**kwargs):
        idx=active[0]
        need(idx is not None and self is members[idx]["program"].space,
             "Native putspace escaped active Program")
        counters[idx]["putspace"]+=1
        return orig_putspace(self,*args,**kwargs)
    try:
        cls.get,cls.put,cls.putspace=get,put,putspace
        while any(x["program"].ips for x in members):
            rounds+=1
            need(rounds<=MAX_ROUNDS,"four-peer fault recovery quantum bound exceeded")
            if sum(bool(x["program"].ips) for x in members)==4:overlap_rounds+=1
            for index in order:
                cur=members[index]
                if not cur["program"].ips:continue
                peers=[x for i,x in enumerate(members) if i!=index]
                detailed=(rounds<=8 or rounds%193==0)
                prior=[(base.state(x),snapshot(x,orig_get,wrote[labels.index(x["label"])])
                        if detailed else None) for x in peers]
                for tick in range(quanta[index]):
                    if not cur["program"].ips:break
                    ip=cur["program"].ips[0]
                    op=int(orig_get(cur["program"].space,ip.position))
                    if op==ord("p") and not ip.stringmode:
                        counters[index]["direct_p"]+=1
                    active[0]=index
                    try:
                        base.tick(cur)
                    except InjectedAfterNativeP:
                        active[0]=None
                        need(index==failing and fired[0] and not recovered[0]
                             and all(x["program"].ips for x in peers),
                             "Native injected p fault not isolated in 3 live peers")
                        first_fault_round[0]=rounds;live_at_fault[0]=3
                        oldprog=cur["program"];sameid=id(oldprog)
                        old_space[0]=oldprog.space
                        old_vec[0]=cur["point"]
                        old_io[0]=(cur["stdin"],cur["stdout"])
                        abandoned_set[0]=set(base.GUARDS)|wrote[index]
                        old_memory[0]=snapshot(cur,orig_get,abandoned_set[0])
                        dirty_stats[0]=dict(counters[index])
                        initial_fault_ticks[0]=cur["steps"]
                        before_peers=[(base.state(x),snapshot(x,orig_get,
                                      wrote[labels.index(x["label"])]))
                                      for x in peers]
                        # Source loading may use putspace; temporarily remove
                        # active-execution guards while ALL peers are frozen.
                        cls.get,cls.put,cls.putspace=orig_get,orig_put,orig_putspace
                        stdout=StringIO.StringIO()
                        inp=StringIO.StringIO(base.raw_for(cur["label"]))
                        platform=BufferedPlatform([],{},stdin=inp,stdout=stdout)
                        Program.__init__(oldprog,Befunge98,platform=platform)
                        need(id(oldprog)==sameid and
                             oldprog.space is not old_space[0] and
                             oldprog.semantics is not members[(index+1)%4]["program"].semantics,
                             "same Native Program object not freshly reinitialized")
                        oldprog.load_code(code);oldprog.create_ip()
                        cur["stdin"]=inp;cur["stdout"]=stdout
                        cur["point"]=oldprog.ips[0].position.__class__
                        cur["steps"]=0
                        counters[index]={"get":0,"put":0,"direct_p":0,"putspace":0}
                        wrote[index]=set()
                        cls.get,cls.put,cls.putspace=get,put,putspace
                        for x,(st,cells) in zip(peers,before_peers):
                            need(base.state(x)==st and
                                 snapshot(x,orig_get,[xy for xy,val in cells])==cells,
                                 "three healthy peers changed during Native fault recovery")
                        need(snapshot({"program":oldprog,"point":old_vec[0]},orig_get,[])==()
                             and tuple((xy,int(orig_get(old_space[0],old_vec[0](xy))))
                                       for xy,_ in old_memory[0])==old_memory[0],
                             "abandoned Native Funge-space modified by peer reset")
                        recovered[0]=True;first_recovered_round[0]=rounds
                        break
                    finally:
                        active[0]=None
                for peer,(state,cells) in zip(peers,prior):
                    need(base.state(peer)==state,
                         "Native active quantum altered passive peer state")
                    peer_check+=1
                    if cells is not None:
                        need(snapshot(peer,orig_get,[xy for xy,val in cells])==cells,
                             "Native active quantum altered peer historical p writes")
                        physical_check+=len(cells)
                if recovered[0] and rounds%197==0:
                    need(tuple((xy,int(orig_get(old_space[0],old_vec[0](xy))))
                               for xy,_ in old_memory[0])==old_memory[0],
                         "recovered peer mutated abandoned dirty Native memory")
                    abandoned_check+=1
        need(recovered[0] and first_fault_round[0]>0
             and live_at_fault[0]==3 and overlap_rounds>0
             and physical_check>0 and peer_check>0
             and abandoned_check>0 and first_recovered_round[0]==first_fault_round[0],
             "not an actual four-live immediate-injection/recovery scenario")
        results=[]
        for i,x in enumerate(members):
            label=x["label"]
            output=x["stdout"].getvalue().split()
            c=counters[i]
            need(not x["program"].ips and output==oracle[label]
                 and len(output)==7 and c["get"]>0 and c["put"]>0
                 and c["put"]==c["direct_p"] and c["putspace"]==0,
                 "recovered/peer native execution differs from independent BF98 oracle")
            results.append({"label":label,"output":output,"steps":x["steps"],
                            "native_get":c["get"],"native_put":c["put"],
                            "native_direct_p":c["direct_p"],"native_putspace":c["putspace"]})
        need(old_io[0][0] is not members[failing]["stdin"] and
             old_io[0][1] is not members[failing]["stdout"] and
             tuple((xy,int(orig_get(old_space[0],old_vec[0](xy))))
                   for xy,_ in old_memory[0])==old_memory[0],
             "Native old faulted memory or streams not isolated")
        return {"labels":list(labels),"profile":profname,
                "fault_index":failing,"fault_after_real_p":depth,
                "fault_round":first_fault_round[0],
                "alive_healthy_peers_at_fault":live_at_fault[0],
                "faulted_same_object_reinitialized_while_three_alive":True,
                "fresh_funge_space_not_abandoned_memory":True,
                "passive_peer_state_unchanged_during_reset":True,
                "original_dirty_memory_unchanged_after_completion":True,
                "all_four_live_rounds":overlap_rounds,
                "passive_state_quantum_checks":peer_check,
                "passive_written_cell_checks":physical_check,
                "abandoned_memory_periodic_checks":abandoned_check,
                "faulted_dirty_steps":initial_fault_ticks[0],
                "faulted_dirty_puts":dirty_stats[0]["put"],
                "faulted_dirty_gets":dirty_stats[0]["get"],
                "faulted_dirty_written_cells":len(abandoned_set[0]),
                "all_four_outputs_reference_equal":True,
                "all_four_terminated":True,"programs":results}
    finally:
        active[0]=None
        cls.get,cls.put,cls.putspace=orig_get,orig_put,orig_putspace
def main():
    need(os.path.isdir(OUT),"four-live Native injected fault evidence mount missing")
    src=open(base.SOURCE,"rb").read()
    need(hashlib.sha1("blob %d\0%s"%(len(src),src)).hexdigest()==PIN==base.PIN,
         "pinned production BF98 source code changed")
    base.INVALID=list(invalid.NUMERIC)+list(invalid.LEXICAL)
    oracle={label:base.reference(label)
            for label in sorted({p for c in SCENARIOS for p in c[0]})}
    need(all(len(v)==7 for v in oracle.values()),"independent BF98 oracle incomplete")
    records=[]
    for profile in PROFILES:
        for scenario in SCENARIOS:
            r=trial(src,scenario,profile,oracle)
            records.append(r)
            print("NATIVE_QUAD_FAULT_RECOVERED_WITH_THREE_LIVE_PEERS_PASS",
                  profile[0],",".join(scenario[0]),"injected_depth",scenario[2],
                  "peer_checks",r["passive_state_quantum_checks"])
            sys.stdout.flush()
    need(len(records)==8,"four-live Native failure/recovery matrix incomplete")
    doc={"schema":"befunge-stage1-native-four-live-immediate-fault-recovery-v1",
         "source_git_blob":PIN,"scope":"FOUR_LIVE_ONE_REAL_P_FAULT_THREE_PEERS_FINISH",
         "four_live_sessions":8,"native_programs_recovered_or_survived":32,
         "actual_real_p_faults":8,
         "all_three_peers_alive_at_every_fault":True,
         "all_faulted_same_program_reinitialized_while_three_alive":True,
         "independent_befunge_reference_labels":len(oracle),
         "last_completed_stage":0,"stage1_final_acceptance":False,
         "production_modified":False,"oracle":oracle,"records":records}
    with open(OUT+"/native_quad_fault_recovery.json","wb") as fh:
        fh.write(json.dumps(doc,indent=2,sort_keys=True)+"\n")
    print("NATIVE_FOUR_LIVE_EIGHT_REAL_P_FAULTS_AND_IMMEDIATE_RECOVERIES_MEASURED_STAGE1_OPEN")
if __name__=="__main__":main()
