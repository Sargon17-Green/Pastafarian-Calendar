#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Stage-1 Native Befunge wide-magnitude oracle + memory provenance, QA only.

Four independently run native Befunge programs per case: reference
work_counts, reference save twice, and the QA production, plus three
different source-input layouts. Python generates input integers and
records *actual* interpreter memory events, not calendar arithmetic.
"""
from __future__ import print_function
import hashlib
import json
import os
import subprocess
import sys
import StringIO
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_current_fork_route_differential as fork

PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
SOURCE="src/interleaved_work_counts.b98"
OUT="/wide/native_wide_magnitude.json"
COMMAND=["timeout","--kill-after=2s","60s","pyfunge",
         "--disable-fprint","--no-concurrent","--no-filesystem","-v98","-d2"]
CASES=[
 ("pow255_neighbor", (0,2**255-1,0,2**255)),
 ("pow256_forward",(0,2**256-1,0,2**256)),
 ("pow256_reverse",(0,2**256,0,2**256-1)),
 ("pow256_negative_forward",(1,2**256,1,2**256+1)),
 ("pow256_negative_reverse",(1,2**256+1,1,2**256)),
 ("pow257_cross_forward",(1,2**257,0,2**257)),
 ("pow257_cross_reverse",(0,2**257,1,2**257)),
 ("pow512_boundary",(0,2**512-1,0,2**512)),
 ("pow512_negative_reverse",(1,2**512,1,2**512-1)),
 ("decimal155_cross",(0,10**155+17,1,10**155+19)),
 ("decimal240_cross_forward",(1,10**240+23,0,10**240+29)),
 ("decimal240_cross_reverse",(0,10**240+29,1,10**240+23)),
 ("pow1024_boundary",(0,2**1024-1,0,2**1024)),
]
def need(ok,reason):
    if not ok:raise AssertionError(reason)
def invoke(path,raw):
    p=subprocess.Popen(COMMAND+[path],stdin=subprocess.PIPE,
                       stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    stdout,stderr=p.communicate(raw)
    need(p.returncode==0,"Native process failed: "+path+" "+str(p.returncode)+
         " "+repr(stderr[-350:]))
    tokens=stdout.split()
    need(tokens,"Native process returned no output "+path)
    return tokens
def layouts(fields):
    s=list(map(str,fields))
    return [" ".join(s)+"\n",
            "\t"+s[0]+" "+s[1]+"\r\n"+s[2]+"\t"+s[3]+"\n",
            s[0]+"\t"+s[1]+" "+s[2]+"\t"+s[3]+" \n"]
def sample(code,raw,expected):
    out=StringIO.StringIO()
    p=Program(Befunge98,platform=BufferedPlatform(
        [],{},stdin=StringIO.StringIO(raw),stdout=out))
    p.load_code(code)
    p.create_ip()
    space=p.space
    cls=type(space)
    orig_put=cls.put
    orig_putspace=cls.putspace
    old_step=p.execute_step
    ticks=[0]
    writes=[]
    reads=0
    read_after_write=0
    ks=0
    putspace=0
    last={}
    gate=0
    def wrapped_put(self,*args,**kwargs):
        need(self is space and len(args)>=2 and len(p.ips)==1,
             "real native put did not own running Funge-space")
        ip=p.ips[0]
        need(not ip.stringmode and
             int(space.get(ip.position))==ord("p"),
             "unexpected indirect memory writer in extended domain")
        target=tuple(map(int,args[0]))
        result=orig_put(self,*args,**kwargs)
        actual=int(self.get(args[0]))
        need(actual==int(args[1]),"native p stored wrong value")
        writes.append((ticks[0],target,actual))
        last[target]=actual
        return result
    def wrapped_putspace(self,*args,**kwargs):
        need(self is space,"unknown native space putspace")
        raise AssertionError("new Native putspace on extended domain")
    def step(self):
        ticks[0]+=1
        if ticks[0]>fork.BOUND:
            raise AssertionError("wide Native step bound exceeded")
        need(len(self.ips)==1,"unanticipated native IP fork")
        ip=self.ips[0]
        op=int(self.space.get(ip.position))
        pending=None
        if not ip.stringmode and op==ord("k"):
            target=tuple(int(ip.position[i])+int(ip.delta[i]) for i in (0,1))
            t=int(self.space.get(ip.position.__class__(target)))
            need(t==ord("+") and tuple(map(int,ip.position))==(1475,101),
                 "unexpected k dispatch opcode on extended domain")
            trace[0]+=1
        if not ip.stringmode and op==ord("g"):
            values=list(ip.stack[0])[-2:]
            while len(values)<2:values.insert(0,0)
            x,y=map(int,values)
            point=(x+int(ip.offset[0]),y+int(ip.offset[1]))
            actual=int(self.space.get(ip.position.__class__(point)))
            pending=(point,actual,ip,point in last)
            if point in last:
                need(actual==last[point],
                     "Native g contradicted earlier physical p memory")
        answer=old_step()
        if pending is not None:
            point,actual,reader,is_from_p=pending
            need(self.ips and self.ips[0] is reader and reader.stack[0] and
                 int(reader.stack[0][-1])==actual,
                 "Native g returned wrong physical memory value")
            cnt[0]+=1
            if is_from_p:cnt[1]+=1
        return answer
    cnt=[0,0]
    trace=[0]
    try:
        cls.put=wrapped_put
        cls.putspace=wrapped_putspace
        p.execute_step=step.__get__(p,p.__class__)
        p.execute()
    finally:
        if "execute_step" in p.__dict__:del p.execute_step
        cls.put=orig_put
        cls.putspace=orig_putspace
    need(not p.ips and out.getvalue().split()==expected,
         "Native instrumented wide result differs from independent reference")
    need(writes and cnt[0]>0 and cnt[1]>0,
         "Native wide p/g physical history missing")
    return {"native_steps":ticks[0],"engine_puts":len(writes),
            "direct_g_reads":cnt[0],"reads_from_prior_put":cnt[1],
            "actual_k_executions":trace[0],
            "runtime_putspace_calls":0}
def main():
    need(os.path.isdir("/wide"),"Native wide artifact mount not found")
    code=open(SOURCE,"rb").read()
    need(fork.blob(code)==PIN,"QA Native production source drifted")
    seen=set()
    records=[]
    for label,fields in CASES:
        need(label not in seen,"duplicate wide label")
        seen.add(label)
        base=layouts(fields)
        signature=hashlib.sha256(base[0]).hexdigest()
        want=(invoke("reference/work_counts.b98",base[0])+
              invoke("reference/save.b98",
                     str(fields[0])+" "+str(fields[1])+"\n")+
              invoke("reference/save.b98",
                     str(fields[2])+" "+str(fields[3])+"\n"))
        need(len(want)==7 and all(z.lstrip("-").isdigit() for z in want),
             "Native Befunge wide reference not seven integers")
        for raw in base:
            got=invoke(SOURCE,raw)
            need(got==want,"Native wide parser/oracle discrepancy "+label)
        measured=sample(code,base[0],want)
        record={"label":label,"fields":[str(z) for z in fields],
                "plain_input_sha256":signature,
                "input_digit_lengths":[len(str(z)) for z in fields],
                "valid_reference_7":want,
                "canonical_spaced_output":want,
                "whitespace_forms_checked":3,
                "oracle_invocations":3,
                "source_invocations":3,
                "instrumented_native_execution":True,
                "native_memory":measured}
        records.append(record)
        print("NATIVE_WIDE_MAGNITUDE_PASS",label,
              "max_decimal_digits",max(record["input_digit_lengths"]),
              "p",measured["engine_puts"],"g",measured["direct_g_reads"],
              "k",measured["actual_k_executions"])
        sys.stdout.flush()
    need(len(records)==13,"expected thirteen real extended-domain trials")
    result={"schema":"befunge-stage1-native-wide-magnitude-v1",
            "source_git_blob":PIN,"real_cases":13,
            "native_cli_invocations":78,
            "native_instrumented_invocations":13,
            "native_reference_invocations":39,
            "native_production_cli_invocations":39,
            "numeric_bit_boundaries":[255,256,257,512,1024],
            "all_programs_really_executed":True,
            "other_runtime_mutation_apis_not_proven":True,
            "stage1_final_accepted":False,"records":records}
    with open(OUT,"wb") as f:
        f.write(json.dumps(result,sort_keys=True,indent=2)+"\n")
    print("NATIVE_WIDE_MAGNITUDES_13_CASES_91_EXECUTIONS_PASS",
          "native_cli",78,"instrumented",13)
    print("FULL_FUNCTIONAL_QA_PASS=NO STAGE1_OPEN=YES")
if __name__=="__main__":main()
