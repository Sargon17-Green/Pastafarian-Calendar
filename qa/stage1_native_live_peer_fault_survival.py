#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage-1 QA: fault one live PyFunge Program during a real p; preserve peer.

Six dual-Program trials with a test-only exception AFTER actual Funge-space.put.
The healthy peer must complete uninterrupted; the interrupted object is
explicitly reinitialized and its output verified by independent native
Befunge references. All read/write API hooks are restored even on failure.
No Python calendar arithmetic, no source mutation, no Stage-2 acceptance.
"""
from __future__ import print_function
import hashlib,json,os,sys,StringIO
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_live_pair_matrix as pair

OUT="/faultpair/native_faulting_peer_survival.json"
SCENARIOS=(
    ("v1","v2","a",1,"AB"),
    ("v0","i3","b",1,"BA"),
    ("i2","v5","a",1,"AB"),
    ("v2","v3","b",20,"BA"),
    ("v5","v0","a",5,"BA"),
    ("i3","v1","a",1,"AB"),
)
class InjectedPutFault(Exception):pass
def snap(space,vector,points,getter):
    return {tuple(pt):int(getter(space,vector(pt))) for pt in points}
def require(ok,msg):
    if not ok:raise AssertionError(msg)

def trial(source,scenario,expected):
    left,right,failed_side,depth,schedule=scenario
    items={"a":pair.make(source,left),"b":pair.make(source,right)}
    failed=items[failed_side]
    peer_key="b" if failed_side=="a" else "a"
    peer=items[peer_key]
    cls=type(failed["program"].space)
    require(failed["program"] is not peer["program"] and
            failed["program"].space is not peer["program"].space and
            cls is type(peer["program"].space),
            "two live programs share interpreter space")
    original_get,original_put,original_putspace=cls.get,cls.put,cls.putspace
    active=[None]
    metrics={k:{"get":0,"put":0,"direct_p":0,"putspace":0}
             for k in ("a","b")}
    writes={"a":set(),"b":set()}
    counter=[0];fired=[False];fault_round=[0];rounds=[0];overlaps=[0]
    peer_at_fault=[None];peer_cells_at_fault=[None]
    aborted_memory=[None];old_output=[None];old_input=[None]
    aborted_semantics=[None];aborted_vector=[None]
    aborted_cells=[None];aborted_snapshot=[None]
    pre_peer=[None];pre_peer_cells=[None]
    def read(self,*args,**kwargs):
        if active[0]:
            key=active[0]
            require(self is items[key]["program"].space,
                    "active Program read peer Funge-space")
            metrics[key]["get"]+=1
        return original_get(self,*args,**kwargs)
    def put(self,*args,**kwargs):
        key=active[0]
        require(key in items and self is items[key]["program"].space and
                len(args)>=2,"Native put escaped active program")
        ip=items[key]["program"].ips[0]
        require(int(original_get(self,ip.position))==ord("p") and
                not ip.stringmode,
                "unaccounted Native non-p memory write")
        res=original_put(self,*args,**kwargs)
        require(int(original_get(self,args[0]))==int(args[1]),
                "Native p wrote unexpected value")
        metrics[key]["put"]+=1
        writes[key].add(tuple(map(int,args[0])))
        if key==failed_side:
            counter[0]+=1
            if counter[0]==depth:
                require(peer["program"].ips,
                        "peer completed before deliberate injection")
                fired[0]=True;fault_round[0]=rounds[0]
                raise InjectedPutFault("after actual native p")
        return res
    def putspace(self,*args,**kwargs):
        key=active[0]
        require(key in items and self is items[key]["program"].space,
                "Native putspace escaped active Program")
        metrics[key]["putspace"]+=1
        return original_putspace(self,*args,**kwargs)
    stopped=False
    try:
        cls.get,cls.put,cls.putspace=read,put,putspace
        while (failed["program"].ips and not stopped or
               peer["program"].ips):
            rounds[0]+=1
            require(rounds[0]<=pair.BUDGET,
                    "native peer/fault scenario step budget exceeded")
            if failed["program"].ips and peer["program"].ips and not stopped:
                overlaps[0]+=1
            order=("a","b") if schedule=="AB" else ("b","a")
            for key in order:
                item=items[key]
                if not item["program"].ips or (key==failed_side and stopped):
                    continue
                ip=item["program"].ips[0]
                op=int(original_get(item["program"].space,ip.position))
                if op==ord("p") and not ip.stringmode:
                    metrics[key]["direct_p"]+=1
                imminent=(key==failed_side and op==ord("p") and
                          not ip.stringmode and counter[0]+1==depth)
                if imminent:
                    pre_peer[0]=pair.state(peer)
                    pre_peer_cells[0]=snap(peer["program"].space,
                                          peer["point"],writes[peer_key],
                                          original_get)
                active[0]=key
                try:
                    pair.tick(item)
                except InjectedPutFault:
                    require(key==failed_side and fired[0],
                            "test exception escaped wrong live Program")
                    stopped=True
                    # Native step has ended exceptionally: reset the QA-only
                    # active-IP sentinel before sampling passive peer state.
                    active[0]=None
                    require(pre_peer[0]==pair.state(peer),
                            "injected p mutated passive peer IP/stack/I-O")
                    require(pre_peer_cells[0]==snap(
                        peer["program"].space,peer["point"],
                        pre_peer_cells[0],original_get),
                        "injected p mutated any prior peer write destination")
                    peer_at_fault[0]=pair.state(peer)
                    peer_cells_at_fault[0]=snap(
                        peer["program"].space,peer["point"],
                        writes[peer_key],original_get)
                    aborted_memory[0]=failed["program"].space
                    aborted_vector[0]=failed["point"]
                    aborted_semantics[0]=failed["program"].semantics
                    old_output[0]=failed["stdout"].getvalue()
                    old_input[0]=failed["stdin"].tell()
                    aborted_cells[0]=set(pair.GUARDS)|writes[failed_side]
                    aborted_snapshot[0]=snap(
                        aborted_memory[0],aborted_vector[0],
                        aborted_cells[0],original_get)
                finally:
                    active[0]=None
            if stopped and rounds[0]%313==0:
                require(snap(aborted_memory[0],aborted_vector[0],
                             aborted_cells[0],original_get)==
                        aborted_snapshot[0],
                        "surviving peer changed faulted Program memory")
        require(stopped and fired[0] and overlaps[0]>0 and
                not peer["program"].ips and failed["program"].ips,
                "peer recovery boundary not reached")
        require(peer["stdout"].getvalue().split()==expected[peer["label"]],
                "surviving native peer differs from independent Befunge")
        require(peer_at_fault[0]!=pair.state(peer),
                "surviving peer never advanced after injection")
        require(snap(aborted_memory[0],aborted_vector[0],aborted_cells[0],
                     original_get)==aborted_snapshot[0],
                "completed peer modified discarded native memory")
    finally:
        active[0]=None
        cls.get,cls.put,cls.putspace=(
            original_get,original_put,original_putspace)
    # Same object identity, but fresh native semantics, space and I/O.
    old_program=failed["program"]
    identity=id(old_program)
    stdout=StringIO.StringIO()
    fresh_platform=BufferedPlatform(
        [],{},stdin=StringIO.StringIO(pair.raw_for(failed["label"])),
        stdout=stdout)
    Program.__init__(old_program,Befunge98,platform=fresh_platform)
    require(id(old_program)==identity and
            old_program.space is not aborted_memory[0] and
            old_program.semantics is not aborted_semantics[0] and
            old_program.semantics.platform is fresh_platform and
            not old_program.ips,
            "interrupted same Program did not reset cleanly")
    old_program.load_code(source)
    old_program.create_ip()
    old_program.execute()
    require(not old_program.ips and
            stdout.getvalue().split()==expected[failed["label"]],
            "restarted Native Program disagrees with independent reference")
    require(snap(aborted_memory[0],aborted_vector[0],aborted_cells[0],
                 original_get)==aborted_snapshot[0],
            "fresh native execution modified abandoned Funge-space")
    require(failed["stdout"].getvalue()==old_output[0] and
            failed["stdin"].tell()==old_input[0],
            "fresh native execution modified abandoned I/O")
    require(all(x["putspace"]==0 and x["get"]>0 for x in metrics.values())
            and all(x["put"]==x["direct_p"] for x in metrics.values())
            and len(aborted_cells[0])>=len(pair.GUARDS),
            "actual native memory API ownership incomplete")
    result={"left":left,"right":right,"fault_side":failed_side,
            "fault_after_put":depth,"schedule":schedule,
            "failure_caught":True,"overlap_rounds":overlaps[0],
            "fault_round":fault_round[0],"peer_terminated":True,
            "peer_output":peer["stdout"].getvalue().split(),
            "recovery_output":stdout.getvalue().split(),
            "peer_unchanged_at_injection":True,
            "aborted_space_preserved":True,
            "same_faulty_object_recovered":True,
            "abandoned_io_preserved":True,
            "peer_steps":peer["steps"],
            "peer_get":metrics[peer_key]["get"],
            "peer_put":metrics[peer_key]["put"],
            "peer_direct_p":metrics[peer_key]["direct_p"],
            "fault_get":metrics[failed_side]["get"],
            "fault_put":metrics[failed_side]["put"],
            "fault_direct_p":metrics[failed_side]["direct_p"],
            "putspace_calls":0,
            "prior_peer_write_cells_checked":len(peer_cells_at_fault[0]),
            "aborted_memory_cells_checked":len(aborted_cells[0])}
    print("NATIVE_LIVE_PEER_SURVIVES_INJECTED_P_FAULT_PASS",
          left,right,failed_side,depth,schedule,
          "survivor_steps",peer["steps"],
          "aborted_cells",len(aborted_cells[0]))
    sys.stdout.flush()
    return result

def main():
    require(os.path.isdir("/faultpair"),"native peer fault output missing")
    source=open(pair.SOURCE,"rb").read()
    pin=hashlib.sha1("blob %d\0%s" % (len(source),source)).hexdigest()
    require(pin==pair.PIN,"Native source SHA changed")
    labels=sorted(set([row[0] for row in SCENARIOS]+
                      [row[1] for row in SCENARIOS]))
    expected={name:pair.reference(name) for name in labels}
    require(all(len(v)==7 for v in expected.values()),
            "Native independent reference incomplete")
    records=[trial(source,c,expected) for c in SCENARIOS]
    require(len(records)==6,"six Native fault+peer cases not executed")
    report={"schema":"befunge-stage1-faulted-live-peer-v1",
            "production_source_git_blob":pair.PIN,
            "status":"QA_ONLY_STAGE1_OPEN",
            "native_pair_trials":6,"native_program_runs":18,
            "injected_actual_put_failures":6,
            "reference_labels":labels,
            "expected_by_label":expected,
            "undocumented_memory_apis_covered":False,
            "stage1_final_acceptance":False,
            "records":records}
    with open(OUT,"wb") as f:
        f.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_SIX_LIVE_PEER_FAILURE_RECOVERY_PASS",len(records))
    print("STAGE1_SEMANTIC_OWNERSHIP_FINAL_GATE=OPEN")
if __name__=="__main__":main()
