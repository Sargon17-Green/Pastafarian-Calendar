#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native counterfactual: remove one genuinely executed runtime-written gate.

No calendar semantics in Python. Native PyFunge is invoked for production
and three independently computed Befunge reference outputs. The mutation
is injected into the *running Funge-space*, never persisted to source.
"""
from __future__ import print_function
import json
import os
import subprocess

SOURCES=[
 ("foundation_cross","1 15055672 1 15055670\n",True),
 ("invalid_sign","2 10 0 10\n",False),
]
NATIVE=("pyfunge","--disable-fprint","--no-concurrent",
        "--no-filesystem","-v98","-d2")
SRC="src/interleaved_work_counts.b98"
OUT="/counterfactual"

def assert_true(ok,why):
    if not ok:
        raise AssertionError(why)

def run(path,data,modified=False):
    env=os.environ.copy()
    env.pop("BF98_TRACE_LOG",None)
    env.pop("BF98_GATE_COUNTERFACTUAL",None)
    env.pop("PYTHONPATH",None)
    if modified:
        env["BF98_GATE_COUNTERFACTUAL"]="1"
        env["PYTHONPATH"]="/work/qa/native_gate_counterfactual"
    cmd=["timeout","--kill-after=2s","12s" if modified else "50s"]+list(NATIVE)+[path]
    p=subprocess.Popen(cmd,stdin=subprocess.PIPE,stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE,env=env)
    out,err=p.communicate(data)
    return (p.returncode,out.split(),err)

def oracle(raw):
    fields=raw.split()
    a=run("reference/work_counts.b98",raw)
    b=run("reference/save.b98","%s %s\n"%(fields[0],fields[1]))
    c=run("reference/save.b98","%s %s\n"%(fields[2],fields[3]))
    for name,part in (("work_counts",a),("save_calculation",b),
                      ("save_target",c)):
        assert_true(part[0]==0,"independent Befunge oracle %s failed"%name)
    result=a[1]+b[1]+c[1]
    assert_true(len(result)==7,"Befunge oracle did not emit seven values")
    return result

def main():
    assert_true(os.path.isdir(OUT),"missing counterfactual output directory")
    results=[]
    for label,data,isvalid in SOURCES:
        rc,raw,err=run(SRC,data)
        assert_true(rc==0 and len(raw)==7,
                    "unmodified native production did not finish for "+label)
        expected=oracle(data) if isvalid else ["-1"]*7
        assert_true(raw==expected,
                    "unmodified production diverged from native oracle "+label)
        mrc,mout,merr=run(SRC,data,modified=True)
        assert_true("CF_HOOK_LOADED" in merr and "CF_HOOK_BOUND" in merr,
                    "counterfactual sitecustomize import or Program.execute "
                    "monkeypatch not active: "+label+
                    " stderr="+repr(merr[-600:]))
        assert_true("CF_GATE_TRIGGER position=(1500,1750)" in merr,
                    "counterfactual hook did not witness executed changed gate: "+
                    label+" stderr="+repr(merr[-350:]))
        assert_true("CF_GATE_POST_WINDOW" in merr,
                    "counterfactual did not log modified instruction path: "+label)
        # A different result, or no finite result within the hard execution
        # budget, proves the executed opcode participates in reaching the
        # native program's output. Merely taking a different graphical
        # route with the same output would NOT satisfy this stronger check.
        changed = mrc!=0 or mout!=raw
        assert_true(changed,
                    "neutralizing mutated executable gate did NOT affect "
                    "termination or output for "+label)
        outcome={"case":label,"input":data.strip(),"unmodified_native_output":raw,
                 "mutated_output":mout,"mutated_exit_code":mrc,
                 "observed_output_or_termination_dependency":True,
                 "counterfactual_trigger":
                    next(line for line in merr.splitlines()
                         if line.startswith("CF_GATE_TRIGGER")),
                 "counterfactual_early_path":
                    next(line for line in merr.splitlines()
                         if line.startswith("CF_GATE_POST_WINDOW"))}
        results.append(outcome)
        print("NATIVE_COUNTERFACTUAL_EXECUTED_GATE_DEPENDENCE_PASS",
              label,"native_exit",mrc,"output_changed",mout!=raw)
    with open(os.path.join(OUT,"executed_gate_counterfactual.json"),"wb") as f:
        f.write(json.dumps({"schema":"befunge-stage1-native-gate-counterfactual-v1",
                            "scope":"observed genuine gate dependence, "
                                    "not full geometric spaghetti acceptance",
                            "cases":results},sort_keys=True,indent=2)+"\n")
    print("NATIVE_COUNTERFACTUAL_EXECUTABLE_ROUTE_IMPACTS_OUTPUT_PASS",len(results))
    print("STAGE1_GEOMETRIC_SPAGHETTI_ACCEPTANCE_STILL_OPEN")

if __name__=="__main__":main()
