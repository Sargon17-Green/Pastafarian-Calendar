#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""PyFunge Native single-opcode counterfactuals for promoted [] / j / x route.

This QA-only harness changes ONE executed Befunge source byte per mutant;
Python contains NO calendar arithmetic. The exact source copy is a negative
control, while every changed output or bounded failure comes from the same
pinned Native Befunge-98 interpreter. Outputs are compared with independent
Befunge reference programs, not with a Python oracle.

These checks prove observed route dependence, not final spaghetti acceptance.
"""
from __future__ import print_function
import os
import shutil
import subprocess
import sys
import tempfile
import stage1_native_diverse_geometry as suite

SOURCE = "src/interleaved_work_counts.b98"
CASES = [
    # scenario, input case, (x, y), original instruction, substituted instruction
    ("upper_native_turn", "zero_equal", (951,1334), "]", "^"),
    ("lower_native_turn", "foundation_cross", (951,1336), "[", "v"),
    ("upper_executed_jump", "zero_equal", (958,1331), "j", "0"),
    ("upper_dynamic_rejoin", "zero_equal", (958,1322), "x", "0"),
]
NATIVE = suite.COMMAND
LIMIT = "8s"

def require(ok, message):
    if not ok:
        raise AssertionError(message)

def call_native(path, raw):
    cmd = ["timeout","--kill-after=2s",LIMIT] + NATIVE + [path]
    process = subprocess.Popen(cmd, stdin=subprocess.PIPE,
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = process.communicate(raw)
    return process.returncode, out.split(), err[-500:]

def main():
    with open(SOURCE, "rb") as stream:
        original = stream.read()
    rows = original.split("\n")
    cases = dict((name,(fields,valid)) for name,fields,valid in suite.CASES)
    folder = tempfile.mkdtemp(prefix="befunge-advanced-native-mutants-")
    try:
        sham = os.path.join(folder,"exact_copy_control.b98")
        shutil.copyfile(SOURCE,sham)
        with open(sham,"rb") as stream:
            require(stream.read()==original,"exact source-copy control changed bytes")

        for title,label,(x,y),old,new in CASES:
            require(old!=new and rows[y][x]==old,
                    "advanced executable cell no longer matches the approved source: "+title)
            fields,valid = cases[label]
            require(valid,"counterfactual must use a valid native reference case")
            raw = " ".join(map(str,fields))+"\n"
            expect = suite.expected_for(*fields)
            canonical = suite.native(SOURCE,raw)
            require(canonical==expect and len(expect)==7,
                    "independent native Befunge reference output mismatch "+title)
            sham_rc, sham_out, sham_err = call_native(sham,raw)
            require(sham_rc==0 and sham_out==expect,
                    "exact byte-source control is not behaviorally identical "+title+
                    " stderr="+repr(sham_err))
            copy=list(rows)
            copy[y]=rows[y][:x]+new+rows[y][x+1:]
            data="\n".join(copy)
            require(len(data)==len(original) and
                    sum(a!=b for a,b in zip(data,original))==1,
                    "native test mutant altered more than one byte "+title)
            path=os.path.join(folder,title+".b98")
            with open(path,"wb") as dst: dst.write(data)
            mutated_rc, mutated_out, mutant_err = call_native(path,raw)
            changed = mutated_rc!=0 or mutated_out!=expect
            require(changed,
                    "native executed advanced direction/jump cell is observationally inert "+
                    title)
            print("NATIVE_ADVANCED_OPCODE_SINGLE_CELL_COUNTERFACTUAL_PASS",
                  title,"case",label,"coordinate",str((x,y)),
                  "original",old,"mutant",new,
                  "sham_identical",True,"mutant_exit",mutated_rc,
                  "mutant_output_changed",mutated_out!=expect)
            sys.stdout.flush()
    finally:
        shutil.rmtree(folder)
    print("NATIVE_ADVANCED_DIRECTION_JUMP_CONTROLLED_COUNTERFACTUAL_PASS",
          len(CASES),"of",len(CASES))
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO; source-byte causal probes only")

if __name__=="__main__":
    main()
