#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Read-only operand telemetry for Native PyFunge Stage-1 QA, not an oracle.

Execute the unchanged QA production program on the ten established inputs,
compare each result with the independent Befunge-only oracle, and preserve
the interpreter's *actual* operand stack snapshots at selected executed cells.
This is discovery evidence; it does NOT satisfy the geometry acceptance gate.
"""
from __future__ import print_function
import collections
import hashlib
import json
import os
import subprocess
import sys
import stage1_native_diverse_geometry as suite

SOURCE = "src/interleaved_work_counts.b98"
OUT = "/operands"
EXPECTED_CELLS = ((132,5),(308,1430),(951,1335),
                  (1470,100),(1475,101),(1476,101),
                  (958,1325),(959,1334),(960,1334),
                  (986,1334),(1015,1334),(1027,1334))

def require(pred,why):
    if not pred:
        raise AssertionError(why)

def classification(value):
    if value == "EMPTY":
        return "EMPTY"
    n = int(value)
    return "NEG" if n < 0 else "POS" if n > 0 else "ZERO"

def launch(label, fields):
    raw = " ".join(map(str,fields)) + "\n"
    log = os.path.join(OUT,label+".operand.tsv")
    env = os.environ.copy()
    env.pop("BF98_TRACE_LOG",None)
    env["BF98_OPERAND_LOG"] = log
    env["PYTHONPATH"] = "/work/qa/native_operand_probe"
    cmd = ["timeout","--kill-after=2s","55s"] + suite.COMMAND + [SOURCE]
    process = subprocess.Popen(cmd,stdin=subprocess.PIPE,
                               stdout=subprocess.PIPE,stderr=subprocess.PIPE,
                               env=env)
    result,errors = process.communicate(raw)
    require(process.returncode == 0,
            "native operand probe process failure %s rc=%d stderr=%r" %
            (label,process.returncode,errors[-500:]))
    return log,result.split()

def main():
    require(os.path.isdir(OUT),"missing writable /operands evidence directory")
    reports=[]
    overall=collections.defaultdict(lambda:collections.defaultdict(set))
    raw_values=collections.defaultdict(lambda:collections.defaultdict(set))
    with open(SOURCE,"rb") as src:
        digest=hashlib.sha256(src.read()).hexdigest()
    for label,fields,valid in suite.CASES:
        path,got=launch(label,fields)
        expect=suite.expected_for(*fields) if valid else ["-1"]*7
        require(got==expect,"operand hook modified native output "+label)
        hits=collections.Counter()
        classes=collections.defaultdict(lambda:collections.defaultdict(set))
        samples=collections.defaultdict(list)
        with open(path,"rb") as lines:
            for row in lines:
                parts=row.rstrip("\n").split("\t")
                require(len(parts)==8 and parts[0]=="HIT",
                        "invalid native operand record")
                ip,x,y,opcode,depth=map(int,parts[1:6])
                point=(x,y)
                require(ip>0 and point in EXPECTED_CELLS and depth>=0,
                        "unrequested/incoherent native stack observation")
                require((parts[6]=="EMPTY") == (depth<2) and
                        (parts[7]=="EMPTY") == (depth<1),
                        "native operand stack depth/sentinel mismatch")
                hits[point]+=1
                classes[point]["second"].add(classification(parts[6]))
                classes[point]["top"].add(classification(parts[7]))
                overall[point]["top"].add(classification(parts[7]))
                overall[point]["second"].add(classification(parts[6]))
                raw_values[point]["second"].add(parts[6])
                raw_values[point]["top"].add(parts[7])
                if len(samples[point])<4:
                    samples[point].append({"opcode":opcode,"depth":depth,
                                           "second":parts[6],"top":parts[7]})
        require(hits[(1470,100)]>=1 and hits[(1475,101)]>=1,
                "native production did not traverse input's k-assisted path")
        record={"label":label,"fields":list(fields),"valid":valid,
                "native_output_fields":len(got),
                "native_hit_counts":{"%d,%d"%p:n for p,n in sorted(hits.items())},
                "native_sign_classes":{"%d,%d"%p:{k:sorted(v) for k,v in d.items()}
                        for p,d in sorted(classes.items())},
                "sample_native_stack_values":{"%d,%d"%p:v
                        for p,v in sorted(samples.items())}}
        reports.append(record)
        print("NATIVE_OPERAND_OBSERVATION_OUTPUT_PARITY_PASS",label,
              "observed_cells",len(hits),"stack_hits",sum(hits.values()))
        sys.stdout.flush()
    with open(os.path.join(OUT,"native_operand_discovery.json"),"wb") as dst:
        dst.write(json.dumps({"schema":"befunge-stage1-observed-operands-v1",
                              "proof_scope":"native telemetry only; not geometry acceptance",
                              "production_sha256":digest,
                              "cross_input_operand_sign_classes":{
                                  "%d,%d"%p:{k:sorted(v) for k,v in d.items()}
                                  for p,d in sorted(overall.items())},
                              "observed_raw_values_by_cell":{
                                  "%d,%d"%p:{k:sorted(v) for k,v in d.items()}
                                  for p,d in sorted(raw_values.items())},
                              "cases":reports},
                             sort_keys=True,indent=2)+"\n")
    for cell in ((958,1325),(959,1334),(960,1334),(986,1334),
                 (1015,1334),(1027,1334)):
        v=raw_values[cell]
        print("NATIVE_POST_J_ARITHMETIC_OPERAND_CLASSES",str(cell),
              "top",sorted(v["top"]),"second",sorted(v["second"]))
    print("NATIVE_OPERAND_DISCOVERY_CASES_PASS",len(reports))
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO (no branch inserted or accepted)")
if __name__=="__main__":
    main()
