#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""QA-only causal Native one-instruction '1' to '0' intervention over 7x7 days.

Actual PyFunge Program.execute_step is invoked at the first REAL execution
of (951,1337). This test-only changed Funge-space cell is restored in finally,
before the next step. All other executed instructions are unchanged. A fresh
Native Befunge reference calculates each expected seven-value answer.
"""
from __future__ import print_function
import hashlib,json,os,sys,StringIO
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_diverse_geometry as refs
import stage1_native_lower_feedback_semantic_candidate as builder

SOURCE="src/interleaved_work_counts.b98"
BASE="560d6aa5807a7f766213a33835cce85eab0fa40c"
CAND="d965ce4bdfa282f2d3b82690808def5a2dde10a8"
TARGET=(951,1337)
DOMAIN=tuple(range(-3,4))
OUTPUT="/four-cell-literal/native_first_literal_intervention_49.json"
BOUND=350000

class StepLimit(Exception):pass
def need(ok,why):
    if not ok:raise AssertionError(why)

def run(code,raw,mutate):
    stdin=StringIO.StringIO(raw)
    stdout=StringIO.StringIO()
    prog=Program(Befunge98,platform=BufferedPlatform(
        [],{},stdin=stdin,stdout=stdout))
    prog.load_code(code)
    prog.create_ip()
    need(len(prog.ips)==1,"native causal run did not create one IP")
    vector=prog.ips[0].position.__class__
    point=vector(TARGET)
    need(int(prog.space.get(point))==ord("1"),
         "Native causal variant lower source cell not the pinned literal")
    orig=prog.execute_step
    ticks=[0]
    visited=[0]
    edited=[0]
    first=[None]
    def observed_step(self):
        ticks[0]+=1
        if ticks[0]>BOUND:
            raise StepLimit("Native 49-grid one-literal bounded execution")
        if not self.ips:
            return orig()
        need(len(self.ips)==1,"Native causal experiment unexpectedly forked IP")
        ip=self.ips[0]
        xy=tuple(map(int,ip.position))
        if xy==TARGET and not ip.stringmode:
            need(int(self.space.get(ip.position))==ord("1"),
                 "Native candidate lower literal overwritten before execution")
            visited[0]+=1
            before=len(ip.stack[0])
            edit_this=mutate and edited[0]==0
            if edit_this:
                self.space.put(ip.position,ord("0"))
            try:
                result=orig()
            finally:
                if edit_this:
                    self.space.put(ip.position,ord("1"))
            need(self.ips and ip in self.ips and
                 len(ip.stack[0])==before+1 and
                 int(ip.stack[0][-1])==(0 if edit_this else 1),
                 "Native literal intervention was not actually executed/pushed")
            if first[0] is None:
                first[0]={"tick":ticks[0],"stack_depth_before":before,
                          "pushed":0 if edit_this else 1,
                          "stringmode":False}
            if edit_this:edited[0]+=1
            return result
        return orig()
    prog.execute_step=observed_step.__get__(prog,prog.__class__)
    status="normal"
    try:
        prog.execute()
    except StepLimit:
        status="step_limit"
    finally:
        del prog.execute_step
    return {"status":status,"steps":ticks[0],
            "remaining_ips":len(prog.ips),
            "output":stdout.getvalue().split(),
            "native_lower_literal_visits":visited[0],
            "native_live_literal_edits":edited[0],
            "first_literal":first[0],
            "restored_source_byte":int(prog.space.get(point))}

def main():
    need(os.path.isdir("/four-cell-literal"),
         "Native candidate intervention evidence directory missing")
    base=open(SOURCE,"rb").read()
    need(builder.git_blob(base)==BASE,"production Befunge source changed")
    code=builder.candidate_bytes(base)
    need(builder.git_blob(code)==CAND,"four-cell test-only source changed")
    records=[]
    for x in DOMAIN:
        for y in DOMAIN:
            left=(int(x<0),abs(x))
            right=(int(y<0),abs(y))
            fields=left+right
            raw=" ".join(map(str,fields))+"\n"
            want=refs.expected_for(*fields)
            control=run(code,raw,False)
            mutant=run(code,raw,True)
            need(len(want)==7 and control["status"]=="normal" and
                 control["remaining_ips"]==0 and control["output"]==want,
                 "Native four-cell control differs from real Befunge oracle: %r"%(fields,))
            need(control["native_lower_literal_visits"]==
                 mutant["native_lower_literal_visits"] or
                 mutant["native_live_literal_edits"]==1,
                 "Native lower literal visit discrepancy without intervention")
            need(control["native_live_literal_edits"]==0 and
                 mutant["native_live_literal_edits"]==
                 (1 if control["native_lower_literal_visits"]>0 else 0),
                 "Native intervention did not occur once at actually executed literal")
            need(control["restored_source_byte"]==mutant["restored_source_byte"]==ord("1"),
                 "intervened Native BF98 instruction was not restored")
            if control["native_lower_literal_visits"]==0:
                need(mutant["status"]=="normal" and
                     mutant["remaining_ips"]==0 and mutant["output"]==want,
                     "unreached Native lower literal changed an unrelated arithmetic route")
            causal=(mutant["status"]!="normal" or
                    mutant["remaining_ips"]!=0 or mutant["output"]!=want)
            records.append({"signed_days":[x,y],"fields":list(fields),
                "input_sha256":hashlib.sha256(raw.encode("ascii")).hexdigest(),
                "native_befunge_reference_output":want,
                "control":control,"intervention":mutant,
                "causal_output_or_termination_effect":bool(causal)})
            print("NATIVE_FIRST_LOWER_LITERAL_INTERVENTION",x,y,
                  "executed",control["native_lower_literal_visits"],
                  "causal",bool(causal))
            sys.stdout.flush()
    hits=sum(z["control"]["native_lower_literal_visits"]>0 for z in records)
    effect=sum(z["causal_output_or_termination_effect"] for z in records)
    nohit=49-hits
    need(hits>0 and nohit>0 and effect>0 and effect<=hits,
         "Native 49-grid real first-literal intervention did not show selective causal reach")
    document={"schema":"befunge-stage1-four-cell-first-literal-intervention-49-v1",
       "status":"FINITE_NATIVE_ACTUAL_INSTRUCTION_INTERVENTION_STAGE1_OPEN",
       "base_git_blob":BASE,"candidate_git_blob":CAND,
       "literal_coordinate":list(TARGET),"baseline_opcode":ord("1"),
       "temporary_opcode":ord("0"),"instruction_restored_after_native_step":True,
       "grid_domain":list(DOMAIN),"input_cases":49,
       "native_candidate_control_programs":49,
       "native_candidate_intervention_programs":49,
       "independent_befunge_reference_programs":147,
       "actual_literal_reached_input_cases":hits,
       "literal_not_reached_input_cases":nohit,
       "causal_effect_input_cases":effect,
       "test_only":True,"stage1_complete":False,
       "stage2_started":False,"records":records}
    with open(OUTPUT,"wb") as f:
        f.write((json.dumps(document,sort_keys=True,indent=2)+"\n").encode("ascii"))
    print("NATIVE_FOUR_CELL_FIRST_LOWER_LITERAL_49_GRID_CAUSALITY_PASS",
          "reached",hits,"unreached",nohit,"causal",effect)
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO; LAST_COMPLETED_STAGE=0")

if __name__=="__main__":main()
