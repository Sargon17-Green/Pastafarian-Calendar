#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Finite Native state-ownership QA for FOUR-CELL lower-loop candidate.

Original production is pinned/read-only; candidate is generated in memory
with four exact physical Befunge source edits. Test existing source
independent Befunge-only numerical references, six live Program pairings
in both schedules, then six invalid->valid SAME-PROGRAM explicit resets
with private fresh semantics, Funge space, and IO. Compare every prior
completed space's actual p-write cells and fixed geometry anchors before
and after each reset. This is finite Native QA, NOT Stage1 sign-off.
"""
from __future__ import print_function
import json
import os
import StringIO
import sys
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_lower_feedback_semantic_candidate as candidate
import stage1_native_live_pair_matrix as pair
from stage1_native_invalid_valid_same_object_reset import freeze

SOURCE="src/interleaved_work_counts.b98"
PRODUCTION_PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
CANDIDATE_PIN="d965ce4bdfa282f2d3b82690808def5a2dde10a8"
OUT="/candidate-ownership/native_four_cell_candidate_ownership.json"
PAIRS=(("v0","v1"),("v2","v3"),("v4","i4"),
       ("i1","v5"),("i0","i3"),("i2","i5"))
RESET_SEQUENCE=(("i0","v0"),("i3","v2"),("i4","v4"),
                ("i1","v1"),("i2","v3"),("i5","v5"))
ALL_LABELS=tuple("v%d"%i for i in range(6))+tuple("i%d"%i for i in range(6))
GUARDS=set(pair.GUARDS)|set((x,y) for x,y,b,a in candidate.PATCHES)

def need(ok,msg):
    if not ok:raise AssertionError(msg)

def platform_for(label):
    ins=StringIO.StringIO(pair.raw_for(label))
    outs=StringIO.StringIO()
    plat=BufferedPlatform([],{},stdin=ins,stdout=outs)
    return plat,ins,outs

def main():
    need(os.path.isdir("/candidate-ownership"),"Native ownership evidence mount missing")
    original=open(SOURCE,"rb").read()
    need(candidate.git_blob(original)==PRODUCTION_PIN and
         pair.PIN==PRODUCTION_PIN,"production native source changed")
    edited=candidate.candidate_bytes(original)
    need(candidate.git_blob(edited)==CANDIDATE_PIN,
         "candidate source not pinned to actual four-cell Befunge program")
    need(len(ALL_LABELS)==12 and len(PAIRS)==6 and len(RESET_SEQUENCE)==6,
         "Native candidate ownership matrix changed")
    expectations={}
    for i in range(6):
        key="v%d"%i
        expectations[key]=pair.reference(key)
        need(len(expectations[key])==7 and expectations[key]!=["-1"]*7,
             "independent Native reference invalid "+key)
        expectations["i%d"%i]=["-1"]*7
    results=[]
    by_label={}
    for schedule in ("AB","BA"):
        for left,right in PAIRS:
            row=pair.pair(edited,left,right,schedule,expectations)
            for label,side in ((left,"left"),(right,"right")):
                current=(row[side+"_steps"],
                         row[side+"_memory_gets"],row[side+"_memory_puts"])
                if label in by_label:
                    need(by_label[label]==current,
                         "candidate execution changed with Native peer/schedule "+label)
                else:by_label[label]=current
            results.append(row)
            print("NATIVE_FOUR_CELL_CANDIDATE_LIVE_PAIR_PASS",
                  schedule,left,right,
                  "steps",row["left_steps"],row["right_steps"],
                  "memory_writes",row["left_memory_puts"],row["right_memory_puts"])
            sys.stdout.flush()
    need(len(results)==12 and len(by_label)==12,
         "candidate Native live-pair inputs or memory footprints missing")
    firstplatform,ins,outs=platform_for("i0")
    p=Program(Befunge98,platform=firstplatform)
    identifier=id(p)
    previous=None
    reset_results=[]
    for batch,(illegal,valid) in enumerate(RESET_SEQUENCE):
        for label in (illegal,valid):
            need(id(p)==identifier and not p.ips,
                 "same Native candidate Program identity/termination changed")
            oldspace=p.space
            oldsemantics=p.semantics
            verified_before=0
            if previous is not None:
                old,vc,record=previous
                need(old is oldspace and freeze(old,vc,record)==record,
                     "prior Native candidate space mutated before next reset")
                verified_before=len(record)
            platform,stream,newout=platform_for(label)
            Program.__init__(p,Befunge98,platform=platform)
            need(id(p)==identifier and p.space is not oldspace and
                 p.semantics is not oldsemantics and
                 p.semantics.platform is platform and not p.ips,
                 "Native candidate same-object reset reused shared state or I/O")
            p.load_code(edited)
            p.create_ip()
            need(len(p.ips)==1 and
                 tuple(p.ips[0].position)==(0,0) and
                 tuple(p.ips[0].delta)==(1,0) and
                 len(p.ips[0].stack[0])==0,
                 "Native reset didn't create a pristine executing IP")
            point=p.ips[0].position.__class__
            observed_four=[[x,y,int(p.space.get(point((x,y))))]
                           for x,y,old,new in candidate.PATCHES]
            need(all(v==ord(new) for (x,y,v),(_,_,old,new)
                     in zip(observed_four,candidate.PATCHES)),
                 "candidate Native four-cell source not present before each reset")
            cls=type(p.space)
            original_put=cls.put
            actual_writes=set()
            def watch_put(self,*args,**kwargs):
                need(self is p.space and len(args)>=2,
                     "native candidate p wrote outside executing Program")
                result=original_put(self,*args,**kwargs)
                actual_writes.add(tuple(map(int,args[0])))
                need(int(self.get(args[0]))==int(args[1]),
                     "candidate native p did not persist physical Funge cell")
                return result
            try:
                cls.put=watch_put
                p.execute()
            finally:
                cls.put=original_put
            output=newout.getvalue().split()
            need(not p.ips and output==expectations[label],
                 "candidate same-object reset output differs from Native reference "+
                 label+" got="+repr(output))
            checked_after=0
            if previous is not None:
                old,vc,record=previous
                need(freeze(old,vc,record)==record,
                     "candidate new Program execution mutated old owned space")
                checked_after=len(record)
            watched=GUARDS|actual_writes
            snapshot=freeze(p.space,point,watched)
            previous=(p.space,point,snapshot)
            need(len(actual_writes)>0 and len(watched)>=len(GUARDS),
                 "candidate execution did not exercise native p-write ownership")
            reset_results.append({
                "ordinal":len(reset_results),"batch":batch,
                "label":label,"expected_output":expectations[label],
                "native_output":output,"program_identity":identifier,
                "fresh_semantics":True,"fresh_space":True,"fresh_io":True,
                "source_four_cells":observed_four,
                "p_write_target_count":len(actual_writes),
                "snapshot_cell_count":len(watched),
                "previous_snapshot_checked_before":verified_before,
                "previous_snapshot_checked_after":checked_after,
                "previous_memory_preserved":True,
                "terminated":True})
            print("NATIVE_FOUR_CELL_CANDIDATE_EXACT_OBJECT_RESET_PASS",
                  label,"p_targets",len(actual_writes),
                  "previous_cells",verified_before)
            sys.stdout.flush()
    need(len(reset_results)==12 and
         sum(x["label"].startswith("i") for x in reset_results)==6,
         "twelve real invalid->valid Native same-object resets incomplete")
    report={
        "schema":"befunge-stage1-four-cell-candidate-native-ownership-v1",
        "status":"FINITE_NATIVE_QA_OWNERSHIP_STAGE1_OPEN",
        "production_git_blob":PRODUCTION_PIN,
        "candidate_git_blob":CANDIDATE_PIN,
        "four_physical_source_changes":[list(x) for x in candidate.PATCHES],
        "native_independent_reference_calls":18,
        "native_live_pair_cases":len(results),
        "native_live_program_executions":len(results)*2,
        "native_same_object_explicit_reset_runs":len(reset_results),
        "native_invalid_reset_runs":6,
        "native_valid_recovery_runs":6,
        "both_pair_schedules":["AB","BA"],
        "native_program_reused_identity":identifier,
        "expected_by_label":expectations,
        "stage1_complete":False,
        "production_edited":False,
        "canonical_branch_edited":False,
        "pairs":results,
        "resets":reset_results}
    with open(OUT,"wb") as dest:
        dest.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_FOUR_CELL_CANDIDATE_12_PAIRS_AND_12_RESETS_PASS",
          "24 live Native programs,12 explicit reset executions")
    print("STAGE1_FINAL_SEMANTIC_OWNERSHIP=OPEN")
if __name__=="__main__":main()
