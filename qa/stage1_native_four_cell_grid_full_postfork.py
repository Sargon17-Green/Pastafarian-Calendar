#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Full postfork Native BF98 route for all 49 signed-day combinations.

Reuses the 8-trajectory verified observer. Captures EVERY instruction after
the actual conditional | until genuine termination, plus physical p/g
histories. Writes a separate content-addressed JSON receipt for each pair.
Python dispatches actual BF98 code and three BF98 numerical references only.
No calendar algorithm in Python; no Stage-1 promotion.
"""
from __future__ import print_function
import hashlib,json,os,sys
import stage1_native_diverse_geometry as suite
import stage1_native_lower_feedback_semantic_candidate as candidate
import stage1_native_four_cell_full_postfork_trace as full

BASE="560d6aa5807a7f766213a33835cce85eab0fa40c"
FOUR="d965ce4bdfa282f2d3b82690808def5a2dde10a8"
OUT="/full-grid-route"
DOMAIN=tuple(range(-3,4))
LITERAL=(951,1337)

def need(ok,reason):
    if not ok:raise AssertionError(reason)

def main():
    need(os.path.isdir(OUT),"native full postfork signed grid mount missing")
    source=open(suite.SOURCE,"rb").read()
    need(candidate.git_blob(source)==BASE,"pinned production BF98 source drifted")
    code=candidate.candidate_bytes(source)
    need(candidate.git_blob(code)==FOUR,"test-only four-cell source changed")
    with open(os.path.join(OUT,"four_cell_candidate.b98"),"wb") as f:
        f.write(code)
    rows=[]
    for dc in DOMAIN:
        for dt in DOMAIN:
            index=len(rows)
            fields=(int(dc<0),abs(dc),int(dt<0),abs(dt))
            raw=" ".join(map(str,fields))+"\n"
            expected=suite.expected_for(*fields)
            observed=full.run_full(code,raw,False)
            need(observed["status"]=="normal" and
                 observed["remaining_ips"]==0 and
                 observed["output"]==expected and len(expected)==7 and
                 observed["gate"]["original"]==observed["gate"]["executed"],
                 "full observed Native path/result differs from reference %r"%
                 ((dc,dt),))
            trace=observed["complete_postfork_trace"]
            literal=sum(int((rec[1],rec[2])==LITERAL and
                            rec[5]==ord("1") and rec[6]==0) for rec in trace)
            need((literal>0)==(dc<0),
                 "Native lower-literal reach not selective by signed-day route")
            filename="pair_%02d.json"%index
            receipt=dict(index=index,signed_days=[dc,dt],fields=list(fields),
                         input_sha256=hashlib.sha256(raw.encode("ascii")).hexdigest(),
                         reference_output=expected,run=observed)
            contents=json.dumps(receipt,sort_keys=True,separators=(",",":"))+"\n"
            with open(os.path.join(OUT,filename),"wb") as f:
                f.write(contents)
            rows.append({
              "index":index,"signed_days":[dc,dt],"fields":list(fields),
              "trace_filename":filename,
              "trace_file_sha256":hashlib.sha256(contents).hexdigest(),
              "native_steps":observed["steps"],
              "fork_step":observed["gate"]["step"],
              "complete_postfork_steps":len(trace),
              "literal_executions":literal,
              "p_writes":observed["total_p_writes"],
              "g_reads":observed["total_g_reads"],
              "reference_output":expected})
            print("NATIVE_FOUR_CELL_FULL_POSTFORK_PAIR",index+1,"/49",
                  dc,dt,"steps",len(trace),"lower_literal",literal,
                  "p",observed["total_p_writes"],
                  "g",observed["total_g_reads"])
            sys.stdout.flush()
    reached=sum(z["literal_executions"]>0 for z in rows)
    need(len(rows)==49 and reached==21,
         "49 full Native trajectories did not cover the 21 lower and 28 upper routes")
    doc=dict(schema="befunge-stage1-four-cell-49-complete-native-postfork-v1",
      status="FINITE_49_COMPLETE_NATIVE_TRAJECTORIES_STAGE1_OPEN",
      base_git_blob=BASE,candidate_git_blob=FOUR,
      signed_domain=list(DOMAIN),
      original_native_candidate_executions=49,
      independent_native_reference_executions=147,
      native_processes_total=196,
      lower_literal_reached=21,upper_literal_not_reached=28,
      candidate_source_modified_in_repository=False,
      stage1_complete=False,stage2_started=False,records=rows)
    with open(os.path.join(OUT,"native_full_postfork_signed_grid_49.json"),"wb") as f:
        f.write(json.dumps(doc,sort_keys=True,indent=2)+"\n")
    print("NATIVE_FOUR_CELL_49_FULL_POSTFORK_COMPLETED_21_LOWER_28_UPPER_PASS")
    print("QA_ONLY; LAST_COMPLETED_STAGE=0; GEOMETRIC_SPAGHETTI_QA_PASS=NO")
if __name__=="__main__":main()
