#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage1 Native actual p -> g intervention inside observed 2326-cell SCC.

The numerical calendar is exclusively computed by real pinned Befunge-98
production and independent native Befunge reference programs, NOT Python.
A control and a one-cell intervention per case execute the exact same source.
At the proven executed g cell, the test changes just the previously p-written
memory value from v to v+1, observes the real g stack result, and reports
whether seven-field output/termination changes. Causal output is MEASURED,
not presumed. Bounded finite QA, never final geometric acceptance.
"""
from __future__ import print_function
import hashlib
import json
import os
import StringIO
import sys
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_diverse_geometry as suite

PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
SRC="src/interleaved_work_counts.b98"
OUT="/scc-intervention/native_scc_g_interventions.json"
CELL=(37,1700)
WRITER=(1249,1050)
READER=(575,1164)
LIMIT=250000
# Values, writer/reader ticks independently observed in the 17-case
# SHA-pinned Native STEP/READ/WRITE artifact 11664135758.
WITNESSES=(
    ("foundation_cross",23083,23246,-2),
    ("forward_short",11399,11562,1),
    ("reverse_short",11399,11562,2),
    ("mixed_small",11323,11486,-1),
    ("positive_negative",24839,25002,9),
    ("negative_positive",24763,24926,-1),
    ("large_values",75239,75402,8),
    ("recent_anchor_next",21479,21642,9),
    ("invalid_big_sign",13067,13230,0),
)

def require(ok,msg):
    if not ok:raise AssertionError(msg)
class StepLimit(Exception):pass

def blob(source):
    return hashlib.sha1("blob %d\0%s"%(len(source),source)).hexdigest()

def program_case(source,raw,write_tick,read_tick,want,intervene):
    stdout=StringIO.StringIO()
    program=Program(Befunge98,platform=BufferedPlatform(
        [],{},stdin=StringIO.StringIO(raw),stdout=stdout))
    program.load_code(source)
    program.create_ip()
    require(len(program.ips)==1,"Native source must start one IP")
    point=program.ips[0].position.__class__(CELL)
    base_step=program.execute_step
    counter=[0]
    witness={"write":0,"read":0}
    read_value=[None]
    read_stack=[None]
    def step(self):
        counter[0]+=1
        tick=counter[0]
        if tick>LIMIT:raise StepLimit("bounded counterfactual ended")
        if self.ips:
            ip=self.ips[0]
            pos=tuple(ip.position)
            if tick==write_tick:
                require(pos==WRITER and self.space.get(ip.position)==ord("p"),
                        "p writer opcode or Native tick diverged")
                require(witness["write"]==0,"duplicate writer witness")
                result=base_step()
                require(int(self.space.get(point))==want,
                        "p failed to commit exact Native observed arithmetic value")
                witness["write"]=1
                return result
            if tick==read_tick:
                require(pos==READER and self.space.get(ip.position)==ord("g"),
                        "Native g target opcode or tick diverged")
                require(witness["write"]==1 and witness["read"]==0,
                        "Native g did not follow original p write")
                require(len(ip.stack[0])>=2 and
                        tuple(map(int,list(ip.stack[0])[-2:]))==CELL,
                        "native g operands did not address pinned memory cell")
                require(int(self.space.get(point))==want,
                        "g did not encounter prior p-written value")
                read_value[0]=want+1 if intervene else want
                if intervene:self.space.put(point,want+1)
                result=base_step()
                require(self.ips and self.ips[0] is ip and len(ip.stack[0])>=1
                        and int(ip.stack[0][-1])==read_value[0],
                        "g did not push the actual physical Funge-space value")
                read_stack[0]=int(ip.stack[0][-1])
                witness["read"]=1
                return result
        return base_step()
    program.execute_step=step.__get__(program,program.__class__)
    status="normal"
    try: program.execute()
    except StepLimit: status="step_limit"
    finally: del program.execute_step
    require(witness=={"write":1,"read":1} and
            read_stack[0]==read_value[0],
            "first active SCC p/g write-read chain not witnessed")
    return {"status":status,"steps":counter[0],
            "output":stdout.getvalue().split(),
            "remaining_ips":len(program.ips),
            "actual_g_return":read_stack[0],
            "writer_executed":True,"reader_executed":True,
            "one_cell_intervention":bool(intervene)}

def signature(entry):
    return entry["status"],entry["remaining_ips"],entry["output"]

def main():
    require(os.path.isdir("/scc-intervention"),
            "Native SCC intervention evidence volume is not mounted")
    source=open(SRC,"rb").read()
    require(blob(source)==PIN,"Native production source git blob changed")
    cases=dict((name,(fields,valid)) for name,fields,valid in suite.CASES)
    records=[]
    for label,wt,rt,value in WITNESSES:
        require(label in cases and rt-wt==163,
                "SHA-pinned Native SCC writer/read timing changed")
        fields,valid=cases[label]
        raw=" ".join(map(str,fields))+"\n"
        expected=(suite.expected_for(*fields)
                  if valid else ["-1"]*7)
        require(len(expected)==7,"Native independent expected output malformed")
        original=program_case(source,raw,wt,rt,value,False)
        changed=program_case(source,raw,wt,rt,value,True)
        require(original["status"]=="normal" and original["remaining_ips"]==0
                and original["output"]==expected
                and original["actual_g_return"]==value,
                "unmodified Native SCC run diverged from Befunge reference: "+label)
        require(changed["actual_g_return"]==value+1,
                "controlled one-cell Native g mutation did not reach actual stack")
        require(changed["steps"]>=rt and original["steps"]>=rt,
                "intervention reported steps without executing g")
        output_or_termination_changed=signature(changed)!=signature(original)
        row={"case":label,"valid":bool(valid),
             "input_fields":list(fields),"native_writer_tick":wt,
             "native_reader_tick":rt,"cell_before":value,
             "cell_mutated":value+1,"expected_reference":expected,
             "control":original,"intervention":changed,
             "downstream_output_or_termination_changed":
                 bool(output_or_termination_changed)}
        records.append(row)
        print("NATIVE_SCC_REAL_G_INTERVENTION_PASS",label,
              "p_tick",wt,"g_tick",rt,
              "g",value,"to",value+1,
              "final_output_or_termination_changed",output_or_termination_changed)
        sys.stdout.flush()
    require(len(records)==9 and sum(x["valid"] for x in records)==8,
            "bounded 8 valid + 1 invalid Native SCC coverage missing")
    total_changed=sum(r["downstream_output_or_termination_changed"]
                      for r in records)
    report={"schema":"befunge-stage1-native-scc-live-g-intervention-v1",
            "source_git_blob":PIN,
            "status":"FINITE_NATIVE_CAUSALITY_OBSERVATION_STAGE1_OPEN",
            "source_trace_artifact_id":11664135758,
            "physical_cell":list(CELL),"writer":list(WRITER),
            "reader":list(READER),
            "real_native_intervention_pairs":9,
            "real_native_program_executions":18,
            "valid_cases":8,"invalid_cases":1,
            "native_oracle_invocations":24,
            "causal_g_stack_changes":9,
            "downstream_final_effects":total_changed,
            "stage1_functional_acceptance":False,
            "stage1_geometry_acceptance":False,"records":records}
    with open(OUT,"wb") as stream:
        stream.write(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("NATIVE_SCC_ONE_CELL_REAL_G_NINE_INPUTS_PASS",
          "g_stack_causal",9,
          "final_effects_measured",total_changed)
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO STAGE1_OPEN")

if __name__=="__main__":main()
