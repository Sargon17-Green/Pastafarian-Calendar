#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA15 finite PyFunge-98 hot-reset with a running private peer. QA only."""
from __future__ import print_function
import hashlib,json,os,sys,StringIO
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_live_pair_matrix as base
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
CASES=(("invalid_valid_cross","i0","v1","v0"),
       ("invalid_valid_large","i4","v2","v5"),
       ("valid_invalid_lexical","v0","v4","i5"),
       ("valid_invalid_numeric","v3","v2","i0"))
def need(ok,why):
    if not ok:raise AssertionError(why)
def run(src,case,refs):
    name,first,other,after=case
    a=base.make(src,first);b=base.make(src,other)
    ap=a["program"];bp=b["program"];aid=id(ap);bid=id(bp)
    need(ap is not bp and ap.space is not bp.space,"QA15 shared native state")
    cls=type(ap.space);need(type(bp.space) is cls,"different native Funge-space API")
    get0,put0,putspace0=cls.get,cls.put,cls.putspace
    live=[None];written={"a":set(),"b":set()}
    puts={"a":0,"b":0};gets={"a":0,"b":0};direct={"a":0,"b":0};putspace={"a":0,"b":0}
    def get(self,*args,**kw):
        cur=live[0]
        if cur is not None:
            need(self is cur[1]["program"].space,"QA15 cross-program get")
            gets[cur[0]]+=1
        return get0(self,*args,**kw)
    def put(self,*args,**kw):
        cur=live[0]
        need(cur is not None and self is cur[1]["program"].space and len(args)>=2,
             "QA15 cross-program put")
        answer=put0(self,*args,**kw)
        need(int(get0(self,args[0]))==int(args[1]),"QA15 p did not store byte")
        puts[cur[0]]+=1
        written[cur[0]].add(tuple(map(int,args[0])))
        return answer
    def wrapped_putspace(self,*args,**kw):
        cur=live[0]
        need(cur is not None and self is cur[1]["program"].space,
             "QA15 putspace escaped active Program")
        putspace[cur[0]]+=1
        return putspace0(self,*args,**kw)
    def activate():
        cls.get,cls.put,cls.putspace=get,put,wrapped_putspace
    def deactivate():
        live[0]=None
        cls.get,cls.put,cls.putspace=get0,put0,putspace0
    def snapshot(item,key):
        p=item["program"];typ=item["point"]
        return (base.state(item),
                tuple((xy,int(get0(p.space,typ(xy)))) for xy in sorted(written[key])))
    def step(item,key):
        p=item["program"]
        if not p.ips:return
        ip=p.ips[0]
        if not ip.stringmode and int(get0(p.space,ip.position))==ord("p"):
            direct[key]+=1
        live[0]=(key,item)
        try:base.tick(item)
        finally:live[0]=None
    def oracle(label):
        if label not in refs:refs[label]=base.reference(label)
        return refs[label]
    rounds=before_overlap=after_overlap=peer_checks=0
    try:
        activate()
        # Peer has actual earlier native execution, not just an allocated IP.
        for t in range(1500):
            need(bp.ips,"QA15 peer prematurely terminated in warm-up")
            step(b,"b")
        need(puts["b"]>0 and gets["b"]>0,"QA15 live peer did not execute real p/g")
        while ap.ips:
            rounds+=1;need(rounds<80000 and bp.ips,"QA15 no live peer at reset")
            before_overlap+=1
            previous=snapshot(b,"b")
            for i in range(100):
                if not ap.ips:break
                step(a,"a")
            need(snapshot(b,"b")==previous,"QA15 actor mutated paused live peer")
            peer_checks+=1
            step(b,"b")
        need(a["stdout"].getvalue().split()==oracle(first),
             "QA15 first Native response disagrees with independent BF98 oracle")
        oldspace=ap.space;oldtype=a["point"]
        oldvalues=tuple((xy,int(get0(oldspace,oldtype(xy))))
                        for xy in sorted(written["a"]))
        need(len(oldvalues)>0,"QA15 first execution never wrote memory")
        peer_snapshot=snapshot(b,"b");peer_space=bp.space
        peer_semantics=bp.semantics;peer_ip=bp.ips[0]
        deactivate()
        newin=StringIO.StringIO(base.raw_for(after))
        newout=StringIO.StringIO()
        platform=BufferedPlatform([],{},stdin=newin,stdout=newout)
        old_semantics=ap.semantics
        Program.__init__(ap,Befunge98,platform=platform)
        need(id(ap)==aid and ap.space is not oldspace and
             ap.semantics is not old_semantics and
             ap.semantics.platform is platform and not ap.ips,
             "QA15 exact-object hot-reset retained old semantics or memory")
        ap.load_code(src);ap.create_ip()
        need(len(ap.ips)==1 and tuple(ap.ips[0].position)==(0,0) and
             tuple(ap.ips[0].delta)==(1,0) and not ap.ips[0].stack[0],
             "QA15 restarted Native IP not pristine")
        a["stdin"]=newin;a["stdout"]=newout
        a["point"]=ap.ips[0].position.__class__;a["steps"]=0;a["label"]=after
        need(id(bp)==bid and bp.space is peer_space and
             bp.semantics is peer_semantics and bp.ips[0] is peer_ip and
             snapshot(b,"b")==peer_snapshot,
             "QA15 hot-reset contaminated another currently live Program")
        need(tuple((xy,int(get0(oldspace,oldtype(xy))))
                   for xy,_ in oldvalues)==oldvalues,
             "QA15 old discarded Native Funge-space mutated at reset")
        written["a"]=set();puts["a"]=gets["a"]=direct["a"]=putspace["a"]=0
        activate()
        while ap.ips or bp.ips:
            rounds+=1;need(rounds<80000,"QA15 scheduled Native pair exceeded bound")
            if ap.ips and bp.ips:after_overlap+=1
            if ap.ips:
                previous=snapshot(b,"b")
                for i in range(100):
                    if not ap.ips:break
                    step(a,"a")
                need(snapshot(b,"b")==previous,"QA15 reset actor wrote to peer")
                peer_checks+=1
            if bp.ips:
                previous=snapshot(a,"a")
                for i in range(1 if ap.ips else 100):
                    if not bp.ips:break
                    step(b,"b")
                need(snapshot(a,"a")==previous,"QA15 original peer wrote to reset actor")
                peer_checks+=1
        need(before_overlap>0 and after_overlap>0,"QA15 concurrency overlap missing")
        need(a["stdout"].getvalue().split()==oracle(after) and
             b["stdout"].getvalue().split()==oracle(other),
             "QA15 hot-reset/peer Native answer differs from BF98 oracle")
        need(tuple((xy,int(get0(oldspace,oldtype(xy))))
                   for xy,_ in oldvalues)==oldvalues,
             "QA15 old Funge-space modified after peer and new actor ran")
        for key in ("a","b"):
            need(puts[key]>0 and gets[key]>0 and puts[key]==direct[key] and
                 putspace[key]==0,"QA15 API opcode attribution failed "+key)
        return {"case":name,"before":first,"peer":other,"after":after,
                "before_output":oracle(first),"peer_output":oracle(other),
                "after_output":oracle(after),"warmup_peer_steps":1500,
                "before_reset_overlap":before_overlap,
                "after_reset_overlap":after_overlap,
                "peer_snapshot_checks":peer_checks,
                "old_actor_written_targets_checked":len(oldvalues),
                "actor_post_reset_put":puts["a"],"peer_put":puts["b"],
                "same_actor_object":True,"new_actor_space_and_semantics":True,
                "live_peer_unmodified_at_hot_reset":True,
                "old_actor_memory_preserved":True,
                "outputs_match_native_befunge_reference":True}
    finally:deactivate()
def main():
    need(os.path.isdir("/hotreset"),"QA15 artifact volume missing")
    src=open(base.SOURCE,"rb").read()
    pin=hashlib.sha1("blob %d\0%s"%(len(src),src)).hexdigest()
    need(pin==PIN==base.PIN,"QA15 production BF98 source pin changed")
    refs={};rows=[]
    for case in CASES:
        row=run(src,case,refs);rows.append(row)
        print("QA15_NATIVE_LIVE_PEER_RESET_PASS",row["case"],
              "before",row["before_reset_overlap"],"after",row["after_reset_overlap"])
        sys.stdout.flush()
    need(len(rows)==4 and sum(k.startswith("v") for k in refs)==6,
         "QA15 missed Native reference classes")
    data={"schema":"qa15-real-native-live-peer-hot-reset-v1",
          "source_git_blob":PIN,"qa_only":True,"stage1_final_accepted":False,
          "scenario_count":4,"native_program_executions":12,
          "native_reference_invocations":18,"records":rows}
    with open("/hotreset/native_live_peer_hot_reset.json","wb") as f:
        f.write(json.dumps(data,sort_keys=True,indent=2)+"\n")
    print("QA15_NATIVE_HOT_RESET_FINITE_4_SCENARIOS_PASS")
    print("STAGE1_OPEN")
if __name__=="__main__":main()
