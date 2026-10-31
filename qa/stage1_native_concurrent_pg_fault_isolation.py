#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native SAME-SOURCE overlapping p/g scratch ownership under fault injection.

All arithmetic remains Befunge-only. Two live, independent PyFunge Program
instances execute the EXACT QA production source and write the SAME Funge
coordinates; one gets an injected interruption immediately after its native
p. The other must finish unaffected. The interrupted Program is reused ONLY
after an EXPLICIT constructor reset, and historical spaces stay immutable.

This is one bounded ownership experiment, NOT global Stage-1 acceptance.
"""
from __future__ import print_function
import StringIO
import sys
from funge.program import Program
from funge.languages.funge98 import Befunge98
from funge.platform import BufferedPlatform
from funge.exception import IPStopped, IPQuitted
import stage1_native_diverse_geometry as suite

SOURCE="src/interleaved_work_counts.b98"
UP=(0,0,0,0)
DOWN=(1,15055672,1,15055670)
INVALID=(2,10,0,10)
CELL=(1490,1600)
with open(SOURCE,"rb") as stream:
    CODE=stream.read()
ROWS=CODE.split("\n")
PCOL=ROWS[1334].index("p",959)
GCOL=ROWS[1334].index("g",959)
P=(PCOL,1334)
G=(GCOL,1334)
MAX_TICKS=150000

def require(ok,msg):
    if not ok:raise AssertionError(msg)

require(959<PCOL<GCOL<1027 and ROWS[1331][958]=="j",
        "production's native j/p/g route changed unexpectedly")

def expect(fields):
    if fields==INVALID:
        return ["-1"]*7
    return suite.expected_for(*fields)

class Case(object):
    def __init__(self,name,fields,program=None):
        self.name=name
        self.fields=fields
        text=" ".join(map(str,fields))+"\n"
        self.stdout=StringIO.StringIO()
        platform=BufferedPlatform([],{},stdin=StringIO.StringIO(text),
                                  stdout=self.stdout)
        self.program=program if program is not None else Program(Befunge98,platform=platform)
        if program is not None:
            Program.__init__(self.program,Befunge98,platform=platform)
        self.program.load_code(CODE)
        self.program.create_ip()
        require(len(self.program.ips)==1,"initial program must have one IP")
        self.vec=self.program.ips[0].position.__class__
        self.position=self.vec(CELL)
        require(self.program.space.get(self.position)==32,
                "new invocation inherited dirty Funge scratch")
        self.hits={"p":0,"g":0}
        self.paused=False
        self.stopped=False
    def step(self,inject=False):
        require(not self.paused and not self.stopped,"paused Program was scheduled")
        if not self.program.ips:
            return
        require(len(self.program.ips)==1,"unexpected native concurrent IPs")
        ip=self.program.ips[0]
        coord=tuple(ip.position)
        if coord==P:
            self.hits["p"]+=1
            require(self.program.space.get(self.position)==32,
                    "native scratch cell not blank before p")
        if coord==G:
            self.hits["g"]+=1
            require(self.program.space.get(self.position)==12,
                    "native scratch differs from the preceding real p")
        try:
            self.program.execute_step()
        except IPStopped:
            self.program.remove_ip(ip)
        except IPQuitted:
            for to_remove in list(self.program.ips):
                self.program.remove_ip(to_remove)
        if coord==P:
            require(self.program.space.get(self.position)==12,
                    "actual native p failed to commit to private Funge-space")
            if inject:
                self.paused=True
        if coord==G:
            require(self.program.ips and
                    int(self.program.ips[0].stack[0][-1])==12,
                    "actual native g failed to read the prior private p value")
        if not self.program.ips:
            self.stopped=True
    def output(self):
        return self.stdout.getvalue().split()
    def assert_complete(self,arm):
        require(self.stopped and not self.program.ips and not self.paused,
                self.name+": Native Program did not halt normally")
        require(self.output()==expect(self.fields),
                self.name+": independent Native Befunge oracle mismatch")
        required=1 if arm=="up" else 0
        require(self.hits=={"p":required,"g":required},
                self.name+": native j/p/g execution counts mismatch")
        require(self.program.space.get(self.position)==(12 if required else 32),
                self.name+": native scratch cell ownership mismatch")

def run_until_fault(a,b):
    require(a.program.space is not b.program.space,
            "two simultaneous native Programs share Funge-space")
    i=0
    while not a.paused:
        require(i<MAX_TICKS,"interleaving failed to reach actual native p write")
        if a.program.ips and not a.paused:
            a.step(inject=True)
        if b.program.ips:
            b.step()
        i+=1
    require(a.hits=={"p":1,"g":0} and a.program.ips,
            "fault was not injected exactly between native p and native g")
    require(a.program.space.get(a.position)==12,
            "interrupted native Funge-space did not retain dirty scratch")
    require(b.program.space is not a.program.space,
            "other live Program's Funge-space was replaced by injected fault")
    print("NATIVE_TWO_LIVE_PROGRAMS_FAULT_AT_P_PASS",
          "scheduling_rounds",i,
          "same_numeric_cell",CELL,
          "faulted_space_dirty",True)
    sys.stdout.flush()
    return i

def finish_unfaulted(b,other):
    count=0
    preserved=other.program.space.get(other.position)
    while b.program.ips:
        require(count<MAX_TICKS,"unfaulted independent Native Program timed out")
        b.step()
        if count%127==0:
            require(other.program.space.get(other.position)==preserved,
                    "other invocation changed frozen faulted Funge-space")
        count+=1
    require(other.program.space.get(other.position)==preserved,
            "completed other invocation contaminated faulted scratch")
    b.assert_complete("up")
    print("NATIVE_UNFAULTED_PROGRAM_INDEPENDENT_COMPLETION_PASS",
          "native_p",b.hits["p"],"native_g",b.hits["g"],
          "other_faulted_space_unchanged",True)
    sys.stdout.flush()

def execute_fresh(case,arm):
    ticks=0
    while case.program.ips:
        require(ticks<MAX_TICKS,"explicit-reset native replay timed out")
        case.step()
        ticks+=1
    case.assert_complete(arm)
    return ticks

def main():
    a=Case("faulted_upper",UP)
    b=Case("concurrent_upper",UP)
    original_id=id(a.program)
    run_until_fault(a,b)
    frozen=a.program.space
    frozen_point=a.position
    finished=b.program.space
    finish_unfaulted(b,a)
    require(frozen.get(frozen_point)==12 and
            finished.get(b.position)==12 and frozen is not finished,
            "two native scratch ownership states aliased")
    for label,values,arm in [
        ("after_fault_lower_no_pg",DOWN,"down"),
        ("after_fault_upper_pg",UP,"up"),
        ("after_fault_invalid_upper_pg",INVALID,"up")
    ]:
        a=Case(label,values,program=a.program)
        require(id(a.program)==original_id,
                "explicit reset unexpectedly changed Python Program identity")
        require(a.program.space is not frozen and a.program.space is not finished,
                "explicit reset reused another invocation's mutable Funge-space")
        rounds=execute_fresh(a,arm)
        require(frozen.get(frozen_point)==12,
                "reset/replay retroactively modified faulted Funge-space")
        require(finished.get(b.position)==12 and b.output()==expect(UP),
                "reset/replay corrupted separately completed Native Program")
        print("NATIVE_FAULT_RESET_CROSS_INSTANCE_ISOLATION_PASS",label,
              "rounds",rounds,"p",a.hits["p"],"g",a.hits["g"])
        sys.stdout.flush()
    print("NATIVE_SAME_SOURCE_OVERLAPPING_PG_FAULT_ISOLATION_PASS",
          "two_live_programs_plus_three_explicit_resets")
    print("STAGE1_SEMANTIC_STATE_OWNERSHIP_FINAL_ACCEPTANCE=OPEN")

if __name__=="__main__":
    main()
