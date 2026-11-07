#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native four-cell lower feedback fault/recovery across one Program object.

Test-only four-cell candidate; neither production nor canonical source is
changed. Every successful arithmetic output comes from independent Befunge
reference programs, not Python calendar arithmetic.
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
import stage1_native_lower_feedback_semantic_candidate as candidate
import stage1_native_diverse_geometry as suite

PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
FOUR_PIN="d965ce4bdfa282f2d3b82690808def5a2dde10a8"
NEW_LITERAL=(951,1337)
OUT="/candidate-ownership/native_four_cell_lower_fault_recovery.json"
SEQUENCE=(
 ("fault_lower_foundation","foundation_cross",True),
 ("recover_lower_mixed","mixed_small",False),
 ("fault_lower_negative","negative_positive",True),
 ("recover_upper_zero","zero_equal",False),
 ("fault_lower_neighbor","foundation_neighbor_forward",True),
 ("recover_lower_reverse","foundation_neighbor_reverse",False),
 ("recover_invalid","invalid_zero_sign",False),
)
WATCH=set([(948,1331),(951,1337),(951,1338),(952,1336),
           (951,1335),(951,1336),(951,1334),(954,1328),
           (1490,1600),(37,1700)])

class InjectedNativeFault(Exception):
    pass

def need(ok,why):
    if not ok:raise AssertionError(why)

def saved_cells(space,vector,targets):
    return [[xy[0],xy[1],int(space.get(vector(xy)))]
            for xy in sorted(targets)]

def digest(entries):
    return hashlib.sha256(json.dumps(entries,separators=(",",":"),
                                  sort_keys=True).encode("ascii")).hexdigest()

def fresh_platform(fields):
    raw=" ".join(map(str,fields))+"\n"
    output=StringIO.StringIO()
    platform=BufferedPlatform([],{},stdin=StringIO.StringIO(raw),stdout=output)
    return platform,output

def main():
    need(os.path.isdir("/candidate-ownership"),
         "Native candidate evidence mount missing")
    source=open("src/interleaved_work_counts.b98","rb").read()
    need(candidate.git_blob(source)==PIN,
         "original Befunge source pin changed")
    code=candidate.candidate_bytes(source)
    need(candidate.git_blob(code)==FOUR_PIN,
         "four-cell Native candidate identity changed")
    book=dict((name,(fields,valid)) for name,fields,valid in suite.CASES)
    need(len(SEQUENCE)==7 and len(set(name for name,_,_ in SEQUENCE))==7,
         "fault-recovery Native case sequence malformed")
    first,_=fresh_platform(book["foundation_cross"][0])
    program=Program(Befunge98,platform=first)
    identity=id(program)
    previous=[]
    evidence=[]
    reference_runs=0
    injected=0
    for index,(name,label,will_fault) in enumerate(SEQUENCE):
        need(label in book,"Native fault-recovery case name missing")
        if index:
            if SEQUENCE[index-1][2]:
                need(len(program.ips)==1,
                     "interrupted Native Program unexpectedly lost its live IP")
            else:
                need(not program.ips,
                     "previous normally completed Native Program retained IP")
        fields,valid=book[label]
        expected=(suite.expected_for(*fields) if valid else ["-1"]*7)
        if valid:reference_runs+=3
        need(len(expected)==7,
             "independent Befunge reference did not produce seven fields")
        platform,out=fresh_platform(fields)
        Program.__init__(program,Befunge98,platform=platform)
        need(id(program)==identity and program.semantics.platform is platform
             and not program.ips,
             "Native exact-object reset did not create new semantics/io")
        need(all(program.space is not row["space"] for row in previous),
             "Native reset retained previous owned Funge-space")
        program.load_code(code)
        program.create_ip()
        need(len(program.ips)==1 and
             tuple(program.ips[0].position)==(0,0) and
             tuple(program.ips[0].delta)==(1,0) and
             len(program.ips[0].stack[0])==0,
             "reset did not restart a pristine native execution")
        vector=program.ips[0].position.__class__
        need(all(int(program.space.get(vector((x,y))))==ord(after)
                 for x,y,before,after in candidate.PATCHES),
             "native reset did not load the exact four changed source cells")
        for row in previous:
            need(saved_cells(row["space"],row["vector"],row["targets"])
                 ==row["snapshot"],"previous interrupted Funge-space was mutated")
            row["later_checks"]+=1
        space=program.space
        cls=type(space)
        original_put=cls.put
        targets=set()
        def traced_put(self,*args,**kwargs):
            need(self is space and len(args)>=2,
                 "native candidate p wrote foreign Program Funge-space")
            result=original_put(self,*args,**kwargs)
            xy=tuple(map(int,args[0]))
            targets.add(xy)
            need(int(self.get(args[0]))==int(args[1]),
                 "native candidate physical p write failed")
            return result
        real_step=program.execute_step
        hits=[0]
        def step(self):
            if self.ips:
                ip=self.ips[0]
                xy=tuple(map(int,ip.position))
                at_new_literal=xy==NEW_LITERAL
                if at_new_literal:
                    need(int(self.space.get(ip.position))==ord("1")
                         and not ip.stringmode,
                         "new lower-loop literal was not a native opcode")
                    hits[0]+=1
                result=real_step()
                if at_new_literal and will_fault:
                    raise InjectedNativeFault("after real lower-loop literal")
                return result
            return real_step()
        caught=False
        try:
            cls.put=traced_put
            program.execute_step=step.__get__(program,program.__class__)
            program.execute()
        except InjectedNativeFault:
            caught=True
        finally:
            del program.execute_step
            cls.put=original_put
        need(caught==will_fault and len(targets)>0,
             "native fault was not injected as required, or no p writes occurred")
        if will_fault:
            need(hits[0]==1 and len(program.ips)==1,
                 "fault not immediately after native lower semantic literal")
            injected+=1
        else:
            need(len(program.ips)==0 and
                 out.getvalue().split()==expected,
                 "clean Native replay differs from independent Befunge oracle")
            if label=="zero_equal":
                need(hits[0]==0,"upper input illegally executed lower-loop literal")
            elif valid:
                need(hits[0]>=1,
                     "clean lower Native route never reached its new literal")
            else:
                need(hits[0]>=0,
                     "invalid Native recovery literal count malformed")
        full_targets=WATCH|targets
        snapshot=saved_cells(space,vector,full_targets)
        entry=dict(index=index,name=name,label=label,fields=list(fields),
                   valid=bool(valid),fault_expected=will_fault,
                   fault_observed=caught,lower_literal_executions=hits[0],
                   normal_termination=not caught and not program.ips,
                   expected_native_reference_output=expected,
                   actual_native_output=out.getvalue().split(),
                   source_cells=[[x,y,ord(after)] for x,y,old,after
                                 in candidate.PATCHES],
                   native_p_write_targets=len(targets),
                   owned_cell_count=len(full_targets),
                   owned_cell_values=snapshot,
                   owned_cells_digest=digest(snapshot),
                   program_identity=identity,fresh_space=True,
                   fresh_semantics=True,fresh_io=True,
                   later_checks=0)
        evidence.append(entry)
        previous.append(dict(space=space,vector=vector,
                             targets=full_targets,snapshot=snapshot,
                             later_checks=0))
        print("NATIVE_FOUR_CELL_FAULT_RECOVERY_EXECUTED",
              name,"fault",caught,"literal_hits",hits[0],
              "owned_cells",len(full_targets),"p_targets",len(targets))
        sys.stdout.flush()
    # Including faulted spaces, check all prior snapshots one last time.
    for row in previous:
        need(saved_cells(row["space"],row["vector"],row["targets"])
             ==row["snapshot"],
             "native post-reset candidate mutated an earlier faulted space")
    for entry,row in zip(evidence,previous):
        entry["later_checks"]=row["later_checks"]
    need(injected==3 and reference_runs==18 and len(evidence)==7,
         "expected three Native faults and 18 independent reference runs")
    report=dict(
        schema="befunge-stage1-four-cell-native-lower-fault-recovery-v1",
        status="TEST_ONLY_CANDIDATE_FAULT_RECOVERY_NOT_STAGE1_ACCEPTANCE",
        base_git_blob=PIN,candidate_git_blob=FOUR_PIN,
        changed_cells=[list(x) for x in candidate.PATCHES],
        native_same_program_invocations=7,
        real_native_post_literal_faults=3,
        native_successful_recoveries=4,
        independent_befunge_reference_program_runs=18,
        source_edited=False,canonical_edited=False,
        stage1_completed=False,
        program_identity=identity,records=evidence)
    with open(OUT,"wb") as stream:
        stream.write((json.dumps(report,sort_keys=True,indent=2)+"\n")
                     .encode("ascii"))
    print("NATIVE_FOUR_CELL_LOWER_LITERAL_THREE_FAULTS_FOUR_RECOVERIES_PASS")
    print("LAST_COMPLETED_STAGE=0; GEOMETRIC_SPAGHETTI_QA_PASS=NO")

if __name__=="__main__":
    main()
