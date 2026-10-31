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
import StringIO
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
import stage1_native_diverse_geometry as suite

SOURCE = "qa/interleaved_work_counts_pre_two_valid_w_production.b98"
CASES = [
    # scenario, input case, (x, y), original instruction, substituted instruction
    ("upper_native_turn", "zero_equal", (951,1334), "]", "^"),
    ("lower_native_turn", "foundation_cross", (951,1336), "[", "v"),
    ("upper_dynamic_rejoin", "zero_equal", (958,1321), "x", "0"),
    ("upper_executed_jump", "zero_equal", (958,1331), "j", "0"),
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

STACK_CELLS = set(((958,1332),(958,1331),(958,1325),(958,1324),
                   (958,1323),(958,1322),(958,1321),(959,1334),(960,1334),
                   (961,1334),(962,1334)))
def native_operand_stack_probe(raw, expected):
    """Capture *actual* PyFunge operand stacks, without altering instructions."""
    stdout=StringIO.StringIO()
    platform=BufferedPlatform([],{},stdin=StringIO.StringIO(raw),stdout=stdout)
    program=Program(Befunge98,platform=platform)
    with open(SOURCE,"rb") as infile:
        program.load_code(infile.read())
    program.create_ip()
    original_step=program.execute_step
    observations=[]
    def watched_step(self):
        if program.ips:
            ip=program.ips[0]
            x,y=tuple(ip.position)
            if (x,y) in STACK_CELLS and len(observations)<32:
                items=list(ip.stack[0])
                observations.append((x,y,chr(program.space.get(ip.position)),
                                     len(items),tuple(map(str,items[-7:]))))
        return original_step()
    program.execute_step=watched_step.__get__(program,program.__class__)
    try:
        program.execute()
    finally:
        del program.execute_step
    require(stdout.getvalue().split()==expected and not program.ips,
            "Native stack observation unexpectedly changed production output")
    require(any(p[:2]==(958,1331) for p in observations),
            "Native stack probe failed to reach executable j")
    for item in observations:
        print("NATIVE_ADVANCED_JUMP_READONLY_OPERAND_STACK",repr(item))
    sys.stdout.flush()

def main():
    with open(SOURCE, "rb") as stream:
        original = stream.read()
    rows = original.split("\n")
    cases = dict((name,(fields,valid)) for name,fields,valid in suite.CASES)
    focus = cases["zero_equal"][0]
    raw_probe = " ".join(map(str,focus)) + "\n"
    native_operand_stack_probe(raw_probe,suite.native(SOURCE,raw_probe))
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
            print("NATIVE_ADVANCED_OPCODE_SINGLE_CELL_MUTATION_OBSERVED",
                  title,"exit",mutated_rc,
                  "native_output",repr(mutated_out),
                  "reference_output",repr(expect),
                  "changed",changed)
            sys.stdout.flush()
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
