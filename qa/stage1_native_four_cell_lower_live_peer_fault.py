#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Actual Native lower feedback fault while a second Program survives LIVE.

Two input-dependent four-cell Befunge routes are stepped interleaved; the
failed Program is interrupted immediately after its genuinely executed new
lower feedback '1', while the peer remains an independently executing IP.
The peer then finishes and the SAME failed Program is explicitly reset.
Numerical references are independent Native BF98. Test-only QA, not Stage 1.
"""
from __future__ import print_function
import hashlib,json,os,sys,StringIO
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_lower_feedback_semantic_candidate as four
import stage1_native_live_pair_matrix as pair

SOURCE="src/interleaved_work_counts.b98"
BASE="560d6aa5807a7f766213a33835cce85eab0fa40c"
PIN="d965ce4bdfa282f2d3b82690808def5a2dde10a8"
OUT="/candidate-ownership/native_four_cell_lower_live_peer_fault.json"
NEW_LITERAL=(951,1337)
SCENARIOS=(("v1","v2","AB"),("v3","v2","BA"))
GUARDS=set(pair.GUARDS)|set((x,y) for x,y,b,a in four.PATCHES)
class FaultAfterNativeLowerLiteral(Exception):pass

def need(ok,msg):
    if not ok:raise AssertionError(msg)

def cells(item,targets,orig_get):
    return [[int(x),int(y),int(orig_get(
        item["program"].space,item["point"]((x,y))))]
        for x,y in sorted(targets)]

def signature(snapshot):
    return hashlib.sha256(json.dumps(snapshot,sort_keys=True,
                                    separators=(",",":")).encode("ascii")).hexdigest()

def scenario(code,failed_label,peer_label,order,reference):
    failed=pair.make(code,failed_label)
    peer=pair.make(code,peer_label)
    items={"f":failed,"p":peer}
    need(failed["program"] is not peer["program"] and
         failed["program"].space is not peer["program"].space and
         failed["program"].semantics is not peer["program"].semantics and
         failed["stdout"] is not peer["stdout"],
         "Native four-cell candidate unexpectedly shares Program state")
    cls=type(failed["program"].space)
    orig_put,orig_get=cls.put,cls.get
    need(cls is type(peer["program"].space),
         "Native peers have distinct Funge-space implementations")
    active=[None]
    writes={"f":set(),"p":set()}
    counts={"f":0,"p":0}
    injected=[False]
    fault_step=[None]
    frozen_space=[None]
    frozen_semantics=[None]
    frozen_stdout=[None]
    frozen_stdin_pos=[None]
    frozen_cells=[None]
    frozen_digest=[None]
    peer_step_before_fault=[None]
    peer_control_at_fault=[None]
    peer_cells_at_fault=[None]
    overlap=[0]
    def watch_put(self,*args,**kwargs):
        owner=active[0]
        need(owner in items and
             self is items[owner]["program"].space and len(args)>=2,
             "Native lower candidate put escaped current live Program")
        result=orig_put(self,*args,**kwargs)
        need(int(orig_get(self,args[0]))==int(args[1]),
             "native p store was not physically committed")
        writes[owner].add(tuple(map(int,args[0])))
        counts[owner]+=1
        return result
    try:
        cls.put=watch_put
        rounds=0
        while (failed["program"].ips and not injected[0]) or peer["program"].ips:
            rounds+=1
            need(rounds<=pair.BUDGET,
                 "two live Native candidate Programs exceeded bound")
            if failed["program"].ips and peer["program"].ips and not injected[0]:
                overlap[0]+=1
            for owner in (("f","p") if order=="AB" else ("p","f")):
                item=items[owner]
                if not item["program"].ips or (owner=="f" and injected[0]):
                    continue
                ip=item["program"].ips[0]
                xy=tuple(map(int,ip.position))
                op=int(orig_get(item["program"].space,ip.position))
                if owner=="f" and xy==NEW_LITERAL:
                    need(op==ord("1") and not ip.stringmode and peer["program"].ips,
                         "fault witness not at actual lower literal with live peer")
                    before=pair.state(peer)
                    pcell=cells(peer,writes["p"],orig_get)
                    peer_step_before_fault[0]=peer["steps"]
                else:
                    before=None;pcell=None
                active[0]=owner
                try:
                    pair.tick(item)
                finally:
                    active[0]=None
                if owner=="f" and xy==NEW_LITERAL:
                    need(pair.state(peer)==before and
                         cells(peer,writes["p"],orig_get)==pcell,
                         "single Native lower literal unexpectedly advanced peer")
                    need(failed["program"].ips,
                         "Native fault witness instruction stopped executing IP")
                    injected[0]=True
                    fault_step[0]=failed["steps"]
                    peer_control_at_fault[0]=before
                    peer_cells_at_fault[0]=pcell
                    frozen_space[0]=failed["program"].space
                    frozen_semantics[0]=failed["program"].semantics
                    frozen_stdout[0]=failed["stdout"].getvalue()
                    frozen_stdin_pos[0]=failed["stdin"].tell()
                    frozen_cells[0]=cells(failed,GUARDS|writes["f"],orig_get)
                    frozen_digest[0]=signature(frozen_cells[0])
                    # Exception deliberately injected after the actual Native
                    # opcode, not an artificial source byte substitution.
                    try:
                        raise FaultAfterNativeLowerLiteral()
                    except FaultAfterNativeLowerLiteral:
                        pass
            if injected[0] and rounds%313==0:
                need(cells(failed,GUARDS|writes["f"],orig_get)==frozen_cells[0],
                     "surviving peer changed abandoned Native Funge-space")
        need(injected[0] and not peer["program"].ips and
             failed["program"].ips and overlap[0]>0 and
             peer["steps"]>peer_step_before_fault[0] and
             counts["f"]>0 and counts["p"]>0,
             "real faulted lower Native candidate was not overlapped by live peer")
        need(peer["stdout"].getvalue().split()==reference[peer_label],
             "surviving peer output differs from independent Native Befunge")
        need(cells(failed,GUARDS|writes["f"],orig_get)==frozen_cells[0],
             "failed Native candidate memory changed as peer finished")
    finally:
        active[0]=None
        cls.put=orig_put
    oldspace=frozen_space[0]
    oldsemantic=frozen_semantics[0]
    old_stdout=frozen_stdout[0]
    old_position=frozen_stdin_pos[0]
    p=failed["program"]
    pid=id(p)
    new_out=StringIO.StringIO()
    platform=BufferedPlatform([],{},stdin=StringIO.StringIO(
        pair.raw_for(failed_label)),stdout=new_out)
    Program.__init__(p,Befunge98,platform=platform)
    need(id(p)==pid and p.space is not oldspace and
         p.semantics is not oldsemantic and
         p.semantics.platform is platform and not p.ips,
         "failed Native four-cell Program reset retained stale state")
    p.load_code(code)
    p.create_ip()
    p.execute()
    need(not p.ips and new_out.getvalue().split()==reference[failed_label],
         "restarted four-cell Program did not recover independent Native output")
    need(cells(dict(program=type("Witness",(object,),{"space":oldspace})(),
                    point=failed["point"]), GUARDS|writes["f"],orig_get)
         ==frozen_cells[0],
         "new execution mutated old interrupted native Funge-space")
    need(failed["stdout"].getvalue()==old_stdout and
         failed["stdin"].tell()==old_position,
         "restarted Program retroactively changed abandoned stdin/stdout")
    result=dict(
        failed_label=failed_label,peer_label=peer_label,schedule=order,
        fault_opcode_coordinate=list(NEW_LITERAL),fault_opcode=ord("1"),
        fault_step=fault_step[0],peer_step_at_fault=peer_step_before_fault[0],
        surviving_peer_steps=peer["steps"],overlap_rounds=overlap[0],
        surviving_peer_output=peer["stdout"].getvalue().split(),
        reset_program_output=new_out.getvalue().split(),
        reference_failed=reference[failed_label],
        reference_peer=reference[peer_label],
        unique_failed_p_targets=len(writes["f"]),
        unique_peer_p_targets=len(writes["p"]),
        faulted_memory_cells=len(frozen_cells[0]),
        faulted_memory_sha256=frozen_digest[0],
        survived_peer_without_space_mutation=True,
        no_peer_change_at_injected_step=True,
        recovered_same_program_object=True,
        old_io_unchanged=True,
        stage1_complete=False)
    print("NATIVE_FOUR_CELL_LOWER_FAULT_LIVE_PEER_SURVIVED_PASS",
          failed_label,peer_label,order,"overlap",overlap[0],
          "fault_step",fault_step[0],"survivor_steps",peer["steps"])
    return result

def main():
    need(os.path.isdir("/candidate-ownership"),
         "Native candidate live-peer evidence directory missing")
    original=open(SOURCE,"rb").read()
    need(four.git_blob(original)==BASE,
         "Befunge production source drifted")
    code=four.candidate_bytes(original)
    need(four.git_blob(code)==PIN,"four-cell source variant drifted")
    labels=sorted({label for f,p,s in SCENARIOS for label in (f,p)})
    expected={label:pair.reference(label) for label in labels}
    need(len(expected)==3 and all(len(x)==7 for x in expected.values()),
         "independent Native Befunge reference matrix incomplete")
    results=[scenario(code,f,p,order,expected) for f,p,order in SCENARIOS]
    need(len(results)==2,"two Native lower fault/peer scenarios incomplete")
    report=dict(schema="befunge-stage1-four-cell-live-lower-fault-v1",
                status="TEST_ONLY_LIVE_PEER_FAULT_ISOLATION_STAGE1_OPEN",
                base_git_blob=BASE,candidate_git_blob=PIN,
                trials=2,live_native_programs=6,
                native_reference_programs=9,
                faulted_lower_literals=2,
                native_clean_peer_completions=2,
                native_same_object_resets=2,
                candidate_promoted=False,
                stage1_completed=False,
                records=results)
    with open(OUT,"wb") as f:
        f.write((json.dumps(report,sort_keys=True,indent=2)+"\n")
                .encode("ascii"))
    print("NATIVE_FOUR_CELL_TWO_LIVE_LOWER_FAULT_AND_PEER_RECOVERY_PASS")
    print("STAGE1_OPEN; QA_ONLY; NO_PRODUCTION_PROMOTION")

if __name__=="__main__":
    main()
