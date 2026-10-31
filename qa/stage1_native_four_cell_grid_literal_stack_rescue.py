#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage-1 QA: causal mediation through the executed lower literal stack value.

For each signed input in [-3,3]^2: actual Native BF98 control, genuine one-
opcode 1->0 mutant, and 0-then-next-step-top-of-stack-to-1 rescue. The
interpreter still executes the mutated opcode; only the data it pushed is
corrected just before the NEXT Native opcode. All outputs compared against
three independent Native Befunge-98 references. Never modifies production.
"""
from __future__ import print_function
import hashlib
import json
import os
import sys
import StringIO
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_diverse_geometry as ref
import stage1_native_lower_feedback_semantic_candidate as four
import stage1_native_four_cell_grid_literal_intervention as first

BASE="560d6aa5807a7f766213a33835cce85eab0fa40c"
CAND="d965ce4bdfa282f2d3b82690808def5a2dde10a8"
OUT="/four-cell-rescue/native_lower_literal_stack_rescue_49.json"
TARGET=(951,1337)
DAYS=tuple(range(-3,4))
BOUND=350000

class NativeLimit(Exception):pass
def require(value, message):
    if not value:
        raise AssertionError(message)

def rescue_native(code,raw):
    stdin=StringIO.StringIO(raw)
    stdout=StringIO.StringIO()
    program=Program(Befunge98,platform=BufferedPlatform(
        [],{},stdin=stdin,stdout=stdout))
    program.load_code(code)
    program.create_ip()
    require(len(program.ips)==1,"Native rescue expected exactly one original IP")
    initial_ip=program.ips[0]
    point=initial_ip.position.__class__(TARGET)
    require(int(program.space.get(point))==ord("1"),
            "Native rescue candidate four-cell source pin wrong")
    real=program.execute_step
    tick=[0]
    changed=[0]
    visited=[0]
    rescued=[0]
    pending=[False]
    first_literal=[None]
    first_rescue=[None]
    def tick_native(self):
        tick[0]+=1
        if tick[0]>BOUND:
            raise NativeLimit("bounded native lower-literal rescue")
        if not self.ips:
            return real()
        require(len(self.ips)==1 and self.ips[0] is initial_ip,
                "Native rescue IP identity changed unexpectedly")
        ip=self.ips[0]
        if pending[0]:
            toss=ip.stack[0]
            require(len(toss)>0 and int(toss[-1])==0,
                    "next actual Native opcode did not receive intervened zero")
            before=tuple(str(v) for v in toss)
            observed_point=[int(v) for v in ip.position]
            memory_before=int(self.space.get(point))
            toss[-1]=1
            after=tuple(str(v) for v in toss)
            require(len(before)==len(after) and before[:-1]==after[:-1]
                    and before[-1]=="0" and after[-1]=="1"
                    and memory_before==int(self.space.get(point)),
                    "rescue changed data other than single TOSS value")
            first_rescue[0]=dict(tick=tick[0],
                                 next_opcode_coordinate=observed_point,
                                 top_before=before[-1],top_after=after[-1],
                                 other_stack_values_unchanged=True,
                                 intervened_source_byte_before_next=memory_before)
            rescued[0]+=1
            pending[0]=False
        coords=tuple(map(int,ip.position))
        if coords==TARGET and not ip.stringmode:
            require(int(self.space.get(point))==ord("1"),
                    "lower source literal not the actual Native opcode")
            visited[0]+=1
            if not changed[0]:
                toss=ip.stack[0]
                depth=len(toss)
                self.space.put(point,ord("0"))
                try:
                    result=real()
                finally:
                    self.space.put(point,ord("1"))
                    require(int(self.space.get(point))==ord("1"),
                            "intervened native opcode not immediately restored")
                require(self.ips and self.ips[0] is ip and
                        len(toss)==depth+1 and int(toss[-1])==0,
                        "Native literal zero was not actually pushed")
                first_literal[0]=dict(tick=tick[0],pushed=0,
                                       stack_depth_before=depth,
                                       restored_physical_source_byte=49)
                changed[0]=1
                pending[0]=True
                return result
        return real()
    program.execute_step=tick_native.__get__(program,program.__class__)
    status="normal"
    try:
        program.execute()
    except NativeLimit:
        status="step_limit"
    finally:
        del program.execute_step
    require(not pending[0],"the one-opcode Native correction never reached its consumer")
    return dict(status=status,steps=tick[0],
                remaining_ips=len(program.ips),
                output=stdout.getvalue().split(),
                lower_literal_visits=visited[0],
                edited_literal_steps=changed[0],
                repaired_toss_values=rescued[0],
                actual_literal=first_literal[0],
                actual_stack_rescue=first_rescue[0],
                final_source_byte=int(program.space.get(point)))

def main():
    require(os.path.isdir("/four-cell-rescue"),"Native artifact mount absent")
    raw_base=open(ref.SOURCE,"rb").read()
    require(four.git_blob(raw_base)==BASE,"production source changed")
    code=four.candidate_bytes(raw_base)
    require(four.git_blob(code)==CAND,"four-cell Native candidate source changed")
    rows=[]
    for day_c in DAYS:
        for day_t in DAYS:
            fields=(int(day_c<0),abs(day_c),int(day_t<0),abs(day_t))
            raw=" ".join(map(str,fields))+"\n"
            want=ref.expected_for(*fields)
            natural=first.run(code,raw,False)
            zero=first.run(code,raw,True)
            rescue=rescue_native(code,raw)
            hit=day_c<0
            require(natural["status"]=="normal" and
                    natural["remaining_ips"]==0 and
                    natural["output"]==want and len(want)==7,
                    "Native ordinary four-cell reference failed: %r"%(fields,))
            require(zero["status"]=="normal" and zero["remaining_ips"]==0 and
                    zero["output"]==(["-1"]*7 if hit else want) and
                    natural["native_lower_literal_visits"]==int(hit) and
                    zero["native_live_literal_edits"]==int(hit),
                    "Native 21/28 causal-zero baseline changed: %r"%(fields,))
            require(rescue["status"]=="normal" and
                    rescue["remaining_ips"]==0 and
                    rescue["output"]==want and
                    rescue["lower_literal_visits"]==int(hit) and
                    rescue["edited_literal_steps"]==int(hit) and
                    rescue["repaired_toss_values"]==int(hit) and
                    (rescue["actual_literal"] is not None)==hit and
                    (rescue["actual_stack_rescue"] is not None)==hit,
                    "Native next-instruction stack rescue did not recover: %r"%(fields,))
            rows.append(dict(
                signed_days=[day_c,day_t],input_fields=list(fields),
                input_sha256=hashlib.sha256(raw.encode("ascii")).hexdigest(),
                native_reference_output=want,
                normal_output=natural["output"],
                zero_mutant_output=zero["output"],
                rescued_output=rescue["output"],
                zero_mutant_steps=zero["steps"],
                original_steps=natural["steps"],
                literal_was_executed=hit,
                zero_mutant_normal_termination=True,
                rescue_run=rescue,
                output_restored_by_only_one_toss_repair=(hit and rescue["output"]==want)))
            print("NATIVE_FOUR_CELL_STACK_MEDIATION_PAIR_PASS",
                  day_c,day_t,"literal",int(hit),
                  "stack_rescues",rescue["repaired_toss_values"])
            sys.stdout.flush()
    require(len(rows)==49,"Native 7x7 source grid missing")
    report=dict(schema="befunge-stage1-native-four-cell-literal-stack-mediation-v1",
                status="FINITE_ACTUAL_NATIVE_STACK_MEDIATION_STAGE1_OPEN",
                base_source_blob=BASE,four_cell_candidate_blob=CAND,
                signed_days=list(DAYS),input_pairs=49,
                actually_executed_lower_literals=21,
                actual_next_opcode_toss_rescues=21,
                lower_literal_unreached_controls=28,
                native_control_executions=49,native_zero_executions=49,
                native_rescue_executions=49,
                independent_native_befunge_references=147,
                total_native_program_executions=294,
                production_source_modified=False,
                stage1_complete=False,stage2_started=False,
                records=rows)
    with open(OUT,"wb") as f:
        f.write((json.dumps(report,sort_keys=True,indent=2)+"\n").encode("ascii"))
    print("NATIVE_FOUR_CELL_21_LOWER_LITERAL_TOSS_RESCUES_28_UNREACHED_CONTROLS_PASS")
    print("FINITE_ONLY; LAST_COMPLETED_STAGE=0; GEOMETRIC_SPAGHETTI_QA_PASS=NO")

if __name__=="__main__":
    main()
