#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""42 real PyFunge-98 same-Program resets: every invalid path followed by valid.

21 malformed inputs from existing Native rejection corpus alternate with
21 valid inputs from three independent Native Befunge reference vectors.
Every execution reinitializes exactly the SAME Program, but must create
new semantics, input/output and private Funge-space. The immediately
preceding completed space must remain unchanged at ALL of its actual
p-write destinations plus fixed geometry anchors, before and after reset.

Finite Stage-1 QA only. No Python implementation of calendar arithmetic.
"""
from __future__ import print_function
import json, os, subprocess, sys, StringIO
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_current_fork_route_differential as fork
import stage1_native_invalid_memory_ownership as invalid

PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
SOURCE="src/interleaved_work_counts.b98"
OUT="/reset/native_invalid_valid_same_program_reset.json"
CMD=["timeout","--kill-after=2s","40s","pyfunge",
     "--disable-fprint","--no-concurrent","--no-filesystem","-v98","-d2"]
VALID=[
    "0 0 0 0",
    "1 15055672 1 15055670",
    "0 1 0 2",
]
GUARDS=[(0,0),(5,0),(10,49),(500,1500),(100,500),
        (1528,2014),(1475,101),(1476,101),(43,1702)]
def need(ok,msg):
    if not ok:raise AssertionError(msg)
def invoke(source,raw):
    p=subprocess.Popen(CMD+[source],stdin=subprocess.PIPE,
                       stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    out,err=p.communicate(raw)
    need(p.returncode==0,"reference native CLI failed "+source+repr(err[-400:]))
    return out.split()
def oracle_for(raw):
    a=raw.split()
    need(len(a)==4 and all(x.isdigit() for x in a),
         "valid domain reference shape")
    result=(invoke("reference/work_counts.b98",raw+"\n")+
            invoke("reference/save.b98",a[0]+" "+a[1]+"\n")+
            invoke("reference/save.b98",a[2]+" "+a[3]+"\n"))
    need(len(result)==7,"independent native Befunge oracle not seven fields")
    return result
def platform_for(raw):
    out=StringIO.StringIO()
    return BufferedPlatform([],{},stdin=StringIO.StringIO(raw+"\n"),
                            stdout=out),out
def freeze(space,cls,coords):
    return {c:int(space.get(cls(c))) for c in coords}
def main():
    need(os.path.isdir("/reset"),"Native same-object evidence mount missing")
    source=open(SOURCE,"rb").read()
    need(fork.blob(source)==PIN,"QA source blob not pinned")
    anchors={raw:oracle_for(raw) for raw in VALID}
    need(len(anchors)==3,"independent Befunge references incomplete")
    cases=([("numeric",i,raw) for i,raw in enumerate(invalid.NUMERIC)]+
           [("lexical",i,raw) for i,raw in enumerate(invalid.LEXICAL)])
    need(len(cases)==21,"Native error corpus shape changed")
    platform,out=platform_for("")
    program=Program(Befunge98,platform=platform)
    program_id=id(program)
    previous=None
    record=[]
    for i,(family,index,raw) in enumerate(cases):
        for kind,text,expected in (("invalid",raw,["-1"]*7),
                                   ("valid",VALID[i%3],anchors[VALID[i%3]])):
            iteration=len(record)
            need(id(program)==program_id and len(program.ips)==0,
                 "Native previous Program object not clean")
            old_space=program.space
            old_semantics=program.semantics
            previously_checked=0
            if previous is not None:
                space,vector_cls,snapshot=previous
                need(old_space is space,"stale old-space ownership changed")
                need(freeze(space,vector_cls,snapshot)==snapshot,
                     "old Native Funge-space changed before reset")
                previously_checked=len(snapshot)
            new_platform,new_stdout=platform_for(text)
            Program.__init__(program,Befunge98,platform=new_platform)
            need(id(program)==program_id and
                 program.space is not old_space and
                 program.semantics is not old_semantics and
                 program.semantics.platform is new_platform and
                 not program.ips,
                 "same Native Program reset kept old space/semantics/I-O")
            program.load_code(source)
            program.create_ip()
            need(len(program.ips)==1 and
                 tuple(program.ips[0].position)==(0,0) and
                 tuple(program.ips[0].delta)==(1,0) and
                 len(program.ips[0].stack[0])==0,
                 "newly initialized native IP not pristine")
            vector_cls=program.ips[0].position.__class__
            cls=type(program.space)
            native_put=cls.put
            captured=set()
            def observe_put(self,*args,**kwargs):
                need(self is program.space and len(args)>=2,
                     "tracked Native p wrote to another Program")
                address=args[0]
                result=native_put(self,*args,**kwargs)
                captured.add(tuple(map(int,address)))
                need(int(self.get(address))==int(args[1]),
                     "real Native p stored unexpected Funge value")
                return result
            try:
                cls.put=observe_put
                program.execute()
            finally:
                cls.put=native_put
            result=new_stdout.getvalue().split()
            need(not program.ips and result==expected,
                 "same-object reset lost independent Native result in "+str(iteration))
            checked_after=0
            if previous is not None:
                space,other_vector,snapshot=previous
                need(freeze(space,other_vector,snapshot)==snapshot,
                     "new Native run mutated previous completed Funge-space")
                checked_after=len(snapshot)
            watched=set(GUARDS)|captured
            snapshot=freeze(program.space,vector_cls,watched)
            previous=(program.space,vector_cls,snapshot)
            need(len(watched)>=len(GUARDS),"native space snapshot unexpectedly empty")
            record.append({
                "ordinal":iteration,"kind":kind,
                "invalid_family":family,"invalid_index":index,
                "raw":text,"output":result,"expected":expected,
                "program_identity":program_id,
                "new_space_after_reset":True,
                "new_semantics_after_reset":True,
                "fresh_io_after_reset":True,
                "terminated":True,
                "previous_space_checked_before":previously_checked,
                "previous_space_checked_after":checked_after,
                "write_targets_checked":len(captured),
                "snapshot_cells":len(watched),
                "previous_space_preserved":True})
            print("NATIVE_INVALID_VALID_SAME_OBJECT_PASS",iteration,kind,
                  family,index,"writes",len(captured),"oldcells",checked_after)
            sys.stdout.flush()
    need(len(record)==42,"42 complete Native same-object resets missing")
    data={"schema":"befunge-stage1-invalid-valid-same-object-reset-v1",
          "source_git_blob":PIN,"status":"QA_ONLY_STAGE1_OPEN",
          "same_program_native_executions":42,
          "invalid_inputs":21,"valid_recovery_runs":21,
          "native_independent_reference_invocations":9,
          "program_identity_consistent":True,
          "all_previous_space_write_targets_rechecked":True,
          "stage1_final_acceptance":False,
          "records":record}
    with open(OUT,"wb") as f:
        f.write(json.dumps(data,sort_keys=True,indent=2)+"\n")
    print("NATIVE_INVALID_VALID_42_SAME_OBJECT_RESET_PASS",
          "invalid",21,"valid",21,
          "independent_native_reference_calls",9)
    print("STAGE1_SEMANTIC_OWNERSHIP_FINAL_GATE=OPEN")
if __name__=="__main__":main()
