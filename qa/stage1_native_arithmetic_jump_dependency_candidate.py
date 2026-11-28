#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native Befunge QA of a non-decorative j/p/g arithmetic continuation.

This is a separate test-only candidate, NEVER an oracle. Python invokes the
pinned PyFunge-98 interpreter and compares seven numeric fields with three
independent repository-native Befunge reference programs. Observed IP steps,
real p/g and a sham-controlled single-byte j mutation are also checked.
"""
from __future__ import print_function
import os
import shutil
import subprocess
import sys
import tempfile
import stage1_native_diverse_geometry as suite

SOURCE="qa/interleaved_work_counts_arithmetic_dependency_j_candidate.b98"
FORK=(951,1335)
J=(958,1331)
RETURN=(950,1335)
AFTER=(949,1335)
SCRATCH=(1490,1600)
CASES=("zero_equal","foundation_cross","forward_short","reverse_short",
       "mixed_small","positive_negative","negative_positive","large_values",
       "invalid_zero_sign","invalid_big_sign")

def require(ok,why):
    if not ok:raise AssertionError(why)

def run_bounded(path,raw):
    p=subprocess.Popen(["timeout","--kill-after=2s","9s"]+
                       suite.COMMAND+[path],stdin=subprocess.PIPE,
                       stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    out,err=p.communicate(raw)
    return p.returncode,out.split(),err[-400:]

def tracked(path,points):
    seen=[]
    with open(path,"rb") as stream:
        for row in stream:
            if not row.startswith("STEP\t"):continue
            fields=row.rstrip("\n").split("\t")
            require(len(fields)==9,"native trace STEP event malformed")
            tick,ip,x,y,dx,dy,op,depth=map(int,fields[1:])
            if (x,y) in points:
                seen.append((tick,x,y,dx,dy,op,depth))
    return seen

def main():
    with open(SOURCE,"rb") as stream:original=stream.read()
    rows=original.split("\n")
    line=rows[1334]
    require(line[959]==">" and line[1027]=="x"
            and rows[1331][958]=="j","native source/circuit drift")
    pcol=line.index("p",959,1027)
    gcol=line.index("g",959,1027)
    require(pcol<gcol,"native versioned p/g instruction order unexpected")
    watched=set((FORK,(951,1334),(951,1336),J,
                 (pcol,1334),(gcol,1334),(1027,1334),
                 RETURN,AFTER))
    cases=dict((label,(fields,valid)) for label,fields,valid in suite.CASES)
    folder=tempfile.mkdtemp(prefix="native-j-stacks-dependency-")
    try:
        for label in CASES:
            values,valid=cases[label]
            raw=" ".join(map(str,values))+"\n"
            trace=(os.path.join(folder,label+".tsv")
                   if label in ("zero_equal","foundation_cross") else None)
            got=suite.native(SOURCE,raw,trace=trace)
            expected=suite.expected_for(*values) if valid else ["-1"]*7
            require(got==expected and len(got)==7,
                    "test-only j-dependent candidate Native oracle parity failed: "+
                    label+" "+repr(got)+" != "+repr(expected))
            if trace:
                hits=tracked(trace,watched)
                require(hits and (hits[0][1],hits[0][2])==FORK,
                        "the Native conditional fork was not executed")
                arm=("up" if (hits[1][1],hits[1][2])==(951,1334)
                     else "down" if (hits[1][1],hits[1][2])==(951,1336)
                     else None)
                want="up" if label=="zero_equal" else "down"
                require(arm==want,"Native arm selected wrong route "+repr(hits))
                coords=[(e[1],e[2]) for e in hits]
                if arm=="up":
                    want_points=[J,(pcol,1334),(gcol,1334),
                                 (1027,1334),RETURN,AFTER]
                    require(all(c in coords for c in want_points),
                            "native j/p/g/x upper circuit not executed: "+repr(hits))
                    require(coords.index(J)<coords.index((pcol,1334))<
                            coords.index((gcol,1334))<
                            coords.index((1027,1334))<
                            coords.index(RETURN)<coords.index(AFTER),
                            "Native arithmetic p/g and x return order invalid")
                    require(hits[coords.index((1027,1334))][5]==ord("x") and
                            hits[coords.index((pcol,1334))][5]==ord("p") and
                            hits[coords.index((gcol,1334))][5]==ord("g"),
                            "native opcode after in-place arithmetic detour wrong")
                else:
                    require(J not in coords and (pcol,1334) not in coords and
                            (gcol,1334) not in coords,
                            "unselected lower arm executes upper p/g or j")
                print("NATIVE_ARITHMETIC_J_PG_ROUTE_AND_PARITY_PASS",
                      label,"arm",arm,"targeted_native_steps",len(hits))
            else:
                print("NATIVE_ARITHMETIC_J_ORACLE_PARITY_PASS",label)
            sys.stdout.flush()

        # Test a complete exact-byte sham alongside one non-inert j mutant.
        sham=os.path.join(folder,"sham_exact.b98")
        shutil.copyfile(SOURCE,sham)
        copy=list(rows)
        copy[1331]=copy[1331][:958]+"0"+copy[1331][959:]
        mutant=os.path.join(folder,"j_changed_to_zero.b98")
        with open(mutant,"wb") as stream:stream.write("\n".join(copy))
        with open(sham,"rb") as stream:
            require(stream.read()==original,"native sham is not byte-identical")
        valid=cases["zero_equal"][0]
        raw=" ".join(map(str,valid))+"\n"
        expected=suite.native(SOURCE,raw)
        sham_rc,sham_out,_=run_bounded(sham,raw)
        require(sham_rc==0 and sham_out==expected,"native exact-copy sham failed")
        mut_rc,mut_out,err=run_bounded(mutant,raw)
        require(mut_rc!=0 or mut_out!=expected,
                "native j removal still arithmetic-output inert; "+repr(mut_out))
        print("NATIVE_J_VALUE_REMOVAL_CAUSALITY_PASS",
              "baseline_fields",len(expected),"mutant_exit",mut_rc,
              "mutant_outputs_changed",mut_out!=expected)
        sys.stdout.flush()
    finally:
        shutil.rmtree(folder)
    print("NATIVE_ARITHMETIC_DEPENDENCY_J_CANDIDATE_PASS",len(CASES))
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO; candidate is not QA production")

if __name__=="__main__":main()
