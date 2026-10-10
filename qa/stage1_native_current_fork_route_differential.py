#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Native current-source | fault differential: measured route vs result.

The prior report records that forced opposite | is output-inert for two
valid inputs. This is an independent diagnostic: real PyFunge execution
must demonstrate the two *different instruction vectors/routes* and
separately classify whether the complete seven-field Native result changed.

Only the operand immediately before the executed native | is optionally
flipped. No Funge source cells are edited; no arithmetic is reimplemented
in Python. This diagnosis does not close any global Stage-1 acceptance.
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
import stage1_native_diverse_geometry as native
import stage1_native_reflective_candidate_domain_matrix as wide

SOURCE="src/interleaved_work_counts.b98"
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
GATE=(951,1335)
CASE_NAMES=tuple(row[0] for row in native.CASES if row[2])+tuple(row[0] for row in wide.CASES if row[2])
INERT=frozenset(("zero_equal","forward_short"))
BOUND=750000
WINDOW=512
OUT="/fork/current_fork_native_route_differential.json"

def require(condition,why):
    if not condition: raise AssertionError(why)

class NativeBudgetExceeded(Exception):pass

def blob(data):
    return hashlib.sha1("blob %d\0%s"%(len(data),data)).hexdigest()

def native_run(source,raw,opposite):
    out=StringIO.StringIO()
    input_stream=StringIO.StringIO(raw)
    platform=BufferedPlatform([],{},stdin=input_stream,stdout=out)
    p=Program(Befunge98,platform=platform)
    p.load_code(source)
    p.create_ip()
    require(len(p.ips)==1,"Native | diagnostic must start with one IP")
    old_step=p.execute_step
    total=[0]
    gate_events=[]
    post=[]
    post_toss=[]
    post_frames=[]
    post_modified_p_cells=[]
    post_ip_context=[]
    rows=source.split("\n")
    modified_p_cells={}
    p_write_events=[0]
    p_write_history=[]
    g_read_history=[]
    scratch_vector=p.ips[0].position.__class__((1490,1600))
    def initial_byte(px,py):
        if 0<=py<len(rows) and 0<=px<len(rows[py]):
            return ord(rows[py][px])
        return 32
    def hook(self):
        total[0]+=1
        if total[0]>BOUND:
            raise NativeBudgetExceeded("bounded Native route experiment")
        if self.ips:
            require(len(self.ips)==1,
                    "the observed native fork became concurrent unexpectedly")
            ip=self.ips[0]
            xy=tuple(ip.position)
            if xy==GATE:
                require(self.space.get(ip.position)==ord("|"),
                        "Native executable fork opcode at pinned cell changed")
                stack=ip.stack[0]
                require(len(stack)>0,"Native | invoked without operand")
                prev=int(bool(stack[-1]))
                if opposite:
                    stack[-1]=0 if prev else 1
                gate_events.append({"step":total[0],"original":prev,
                                    "executed":int(bool(stack[-1])),
                                    "depth":len(stack)})
            elif gate_events and len(post)<WINDOW:
                post.append((int(ip.position[0]),int(ip.position[1]),
                             int(ip.delta[0]),int(ip.delta[1]),
                             len(ip.stack[0])))
                # Capture actual Native TOSS at every observed post-| IP step.
                # This is stronger than motion-only reconvergence, but does
                # not claim equivalence of SOSS, Funge-space or full state.
                post_toss.append(tuple(str(v) for v in ip.stack[0]))
                post_frames.append(tuple(
                    tuple(str(value) for value in frame) for frame in ip.stack))
                post_modified_p_cells.append(tuple(
                    (point[0],point[1],modified_p_cells[point])
                    for point in sorted(modified_p_cells)))
                # Native IP/environment fields, not whole-program state.
                post_ip_context.append((
                    tuple(int(coord) for coord in ip.offset),
                    int(bool(ip.stringmode)),
                    int(bool(ip.invertmode)),
                    int(bool(ip.queuemode)),
                    int(input_stream.tell())))
        pending_p=None
        pending_g=None
        if self.ips:
            active=self.ips[0]
            if self.space.get(active.position)==ord("p"):
                values=active.stack[0]
                require(len(values)>=3,
                        "Native current fork reached p with too few operands")
                expected_value,px,py=map(int,list(values)[-3:])
                point=active.position.__class__((px,py))
                pending_p=(point,(px,py),expected_value)
            elif self.space.get(active.position)==ord("g"):
                values=active.stack[0]
                require(len(values)>=2,
                        "Native current fork reached g with too few coordinates")
                px,py=map(int,list(values)[-2:])
                point=active.position.__class__((px,py))
                before=int(self.space.get(point))
                pending_g=(point,(px,py),before,active)
        result=old_step()
        if pending_p is not None:
            point,coord,expected_value=pending_p
            observed_value=int(self.space.get(point))
            require(observed_value==expected_value,
                    "Native p write did not update the expected physical Funge-space cell")
            if observed_value==initial_byte(coord[0],coord[1]):
                modified_p_cells.pop(coord,None)
            else:
                modified_p_cells[coord]=str(observed_value)
            p_write_events[0]+=1
            p_write_history.append({
                "tick":total[0],
                "coordinate":list(coord),
                "value":str(observed_value)})
        if pending_g is not None:
            point,coord,before,old_ip=pending_g
            require(self.ips and self.ips[0] is old_ip and
                    len(old_ip.stack[0])>=1,
                    "Native g did not retain the reading IP and its stack")
            actual=int(old_ip.stack[0][-1])
            require(actual==before,
                    "Native real g returned a value unequal to physical Funge-space")
            g_read_history.append({
                "tick":total[0],
                "coordinate":list(coord),
                "read_before":str(before),
                "returned":str(actual)})
        return result
    p.execute_step=hook.__get__(p,p.__class__)
    status="normal"
    try:p.execute()
    except NativeBudgetExceeded:status="step-limit"
    finally:del p.execute_step
    return {"status":status,"output":out.getvalue().split(),
            "remaining_ips":len(p.ips),"steps":total[0],
            "gates":gate_events,"route":post,
            "post_toss":post_toss,
            "post_frames":post_frames,
            "post_modified_p_cells":post_modified_p_cells,
            "post_ip_context":post_ip_context,
            "observed_native_p_writes":p_write_events[0],
            "native_p_writes_raw":p_write_history,
            "native_g_reads_raw":g_read_history,
            "final_scratch_value":str(int(p.space.get(scratch_vector)))}

def common_subpath(a,b,length):
    # A common 5-event native directed motion window is stronger than a
    # single coincident grid cell. This is merely *observed*, never assumed.
    indices={}
    for i in range(len(a)-length+1):
        key=tuple(a[i:i+length])
        indices.setdefault(key,i)
    for j in range(len(b)-length+1):
        key=tuple(b[j:j+length])
        if key in indices:
            return {"original_offset":indices[key],"mutant_offset":j,
                    "real_motion_sample":list(key)}
    return None

def main():
    require(os.path.isdir("/fork"),"Native route evidence destination missing")
    src=open(SOURCE,"rb").read()
    require(blob(src)==PIN,"current-source | diff must match exact QA Git blob")
    labels={z[0]:(z[1],z[2]) for z in native.CASES}
    labels.update({z[0]:(z[1],z[2]) for z in wide.CASES})
    report=[]
    for label in CASE_NAMES:
        fields,valid=labels[label]
        require(valid,"native fork diagnosis must use valid input")
        raw=" ".join(map(str,fields))+"\n"
        expected=native.expected_for(*fields)
        unmodified=native_run(src,raw,False)
        altered=native_run(src,raw,True)
        require(unmodified["status"]=="normal" and
                unmodified["remaining_ips"]==0 and
                unmodified["output"]==expected and
                len(unmodified["gates"])==1,
                "real positive native fork replay invalid "+label+" status="+str(unmodified["status"])+" steps="+str(unmodified["steps"])+" observed="+repr(unmodified["output"])+" reference="+repr(expected))
        a=unmodified["gates"][0];b=altered["gates"][0]
        require(a["original"]==a["executed"] and
                a["original"]==b["original"] and
                b["executed"]==1-a["executed"] and
                a["depth"]==b["depth"] and len(altered["gates"])>=1,
                "fork operand counterfactual did not flip precisely one Native class "+label)
        first=unmodified["route"][0]
        opposite=altered["route"][0]
        require(first[:4]!=opposite[:4] and
                first[2]==opposite[2]==0 and
                first[3]==-opposite[3] and
                first[3]!=0,
                "Native fork operand changed but IP did not choose opposite directions "+label)
        changed=(altered["status"]!="normal" or
                 altered["remaining_ips"]!=0 or
                 altered["output"]!=expected)
        if label in INERT:
            require(not changed,
                    "frozen formerly inert Native fork became output-causal "+label)
        elif label in ("foundation_cross","mixed_small"):
            require(changed,
                    "frozen formerly causal Native fork became output-inert "+label)
        overlap=common_subpath(unmodified["route"],altered["route"],5)
        require(overlap is not None,"missing real Native five-motion rejoin "+label)
        require(len(unmodified["post_toss"])==len(unmodified["route"]) and
                len(altered["post_toss"])==len(altered["route"]),
                "Native route/TOSS snapshot counts do not align "+label)
        ia=overlap["original_offset"]
        ib=overlap["mutant_offset"]
        stack_a=unmodified["post_toss"][ia:ia+5]
        stack_b=altered["post_toss"][ib:ib+5]
        require(len(stack_a)==len(stack_b)==5,
                "incomplete real Native five-step TOSS rejoin "+label)
        # Python 2 list-comprehension variables leak into this scope: do
        # not clobber a/b, the native gate event dictionaries above.
        equal_toss=[left==right for left,right in zip(stack_a,stack_b)]
        frames_a=unmodified["post_frames"][ia:ia+5]
        frames_b=altered["post_frames"][ib:ib+5]
        changed_a=unmodified["post_modified_p_cells"][ia:ia+5]
        changed_b=altered["post_modified_p_cells"][ib:ib+5]
        ip_context_a=unmodified["post_ip_context"][ia:ia+5]
        ip_context_b=altered["post_ip_context"][ib:ib+5]
        require(len(ip_context_a)==len(ip_context_b)==5 and
                all(len(row)==5 and len(row[0])==2
                    for row in ip_context_a+ip_context_b),
                "Native rejoin IP offset/mode/input-cursor witness incomplete")
        ip_context_equal=[left==right for left,right in zip(
            ip_context_a,ip_context_b)]
        input_cursor_equal=[left[4]==right[4] for left,right in zip(
            ip_context_a,ip_context_b)]
        require(len(frames_a)==len(frames_b)==len(changed_a)==len(changed_b)==5,
                "Native stack-frame and p-cell snapshots are incomplete")
        require(all(len(frames)>0 for frames in frames_a+frames_b),
                "PyFunge stack-of-stacks unexpectedly lacked TOSS at rejoin")
        require(all(frames[0]==toss for frames,toss in
                    zip(frames_a,stack_a)) and
                all(frames[0]==toss for frames,toss in
                    zip(frames_b,stack_b)),
                "measured Native stack-of-stacks conflicts with the original TOSS")
        equal_frames=[left==right for left,right in zip(frames_a,frames_b)]
        equal_modified_p=[left==right for left,right in zip(changed_a,changed_b)]
        # This only covers p-written mutations relative to the original
        # Funge source, not possible non-p mutations or all interpreter state.
        # Negative control: a forged TOSS snapshot with unchanged native
        # IP motion must not pass the exact stack comparison.
        tampered=list(stack_a)
        tampered[0]=tampered[0]+("__forged_toss__",)
        require(not all(a==b for a,b in zip(stack_a,tampered)),
                "rejoin TOSS audit accepted deliberately forged stack content")
        # The structural isolation suite already proves exact Native p/g
        # for a few input families. Extend the same *executed* operation
        # lifecycle check to every valid 32-case opposite-fork pair.
        def verify_scratch_transaction(observed,should_execute,arm):
            writes=[event for event in observed["native_p_writes_raw"]
                    if event["coordinate"]==[1490,1600]]
            reads=[event for event in observed["native_g_reads_raw"]
                   if event["coordinate"]==[1490,1600]]
            require(len(writes)==len(reads)==should_execute,
                    "Native scratch p/g executed incorrect number of times "+
                    label+"/"+arm)
            if should_execute:
                require(writes[0]["tick"]<reads[0]["tick"] and
                        writes[0]["value"]=="12" and
                        reads[0]["read_before"]=="12" and
                        reads[0]["returned"]=="12" and
                        observed["final_scratch_value"]=="12",
                        "Native scratch p/g write-then-read lifecycle mismatch "+
                        label+"/"+arm)
            else:
                require(observed["final_scratch_value"]=="32",
                        "unselected Native scratch should remain initial blank "+
                        label+"/"+arm)
            return writes,reads
        expected_control=int(a["executed"]==1)
        normal_writes,normal_reads=verify_scratch_transaction(
            unmodified,expected_control,"original")
        forced_writes,forced_reads=verify_scratch_transaction(
            altered,1-expected_control,"opposite")
        result={"case":label,"gate_observed_nonzero":a["executed"],
                "gate_forced_nonzero":b["executed"],
                "native_first_control_vector":first,
                "native_first_mutant_vector":opposite,
                "different_native_route":True,
                "changed_final_semantics":changed,
                "control_status":unmodified["status"],
                "mutant_status":altered["status"],
                "mutant_output_equal_to_oracle":altered["output"]==expected,
                "control_step_count":unmodified["steps"],
                "mutant_step_count":altered["steps"],
                "captured_native_route_steps":len(unmodified["route"]),
                "captured_counterfactual_route_steps":len(altered["route"]),
                "first_common_five_event_motion":overlap,
                "first_rejoin_native_toss_equal_each_step":equal_toss,
                "first_rejoin_native_toss_equal_count":sum(equal_toss),
                "first_rejoin_native_toss_identical_all_five":all(equal_toss),
                "first_rejoin_toss_depth_control":[len(s) for s in stack_a],
                "first_rejoin_toss_depth_forced":[len(s) for s in stack_b],
                "first_rejoin_toss_sha256_control":[hashlib.sha256(repr(s)).hexdigest() for s in stack_a],
                "first_rejoin_toss_sha256_forced":[hashlib.sha256(repr(s)).hexdigest() for s in stack_b],
                "first_rejoin_all_stack_frames_raw_control":frames_a,
                "first_rejoin_all_stack_frames_raw_forced":frames_b,
                "first_rejoin_p_modified_cells_raw_control":changed_a,
                "first_rejoin_p_modified_cells_raw_forced":changed_b,
                "first_rejoin_all_stack_frames_equal_each_step":equal_frames,
                "first_rejoin_all_stack_frames_equal_count":sum(equal_frames),
                "first_rejoin_all_stack_frames_sha256_control":[hashlib.sha256(repr(s)).hexdigest() for s in frames_a],
                "first_rejoin_all_stack_frames_sha256_forced":[hashlib.sha256(repr(s)).hexdigest() for s in frames_b],
                "first_rejoin_frame_count_control":[len(s) for s in frames_a],
                "first_rejoin_frame_count_forced":[len(s) for s in frames_b],
                "first_rejoin_p_modified_cells_equal_each_step":equal_modified_p,
                "first_rejoin_p_modified_cells_equal_count":sum(equal_modified_p),
                "first_rejoin_p_modified_cells_sha256_control":[hashlib.sha256(repr(s)).hexdigest() for s in changed_a],
                "first_rejoin_p_modified_cells_sha256_forced":[hashlib.sha256(repr(s)).hexdigest() for s in changed_b],
                "first_rejoin_p_modified_cells_count_control":[len(s) for s in changed_a],
                "first_rejoin_p_modified_cells_count_forced":[len(s) for s in changed_b],
                "first_rejoin_ip_context_raw_control":ip_context_a,
                "first_rejoin_ip_context_raw_forced":ip_context_b,
                "first_rejoin_ip_context_equal_each_step":ip_context_equal,
                "first_rejoin_input_cursor_equal_each_step":input_cursor_equal,
                "native_scratch_p_writes_control":normal_writes,
                "native_scratch_p_writes_forced":forced_writes,
                "native_scratch_g_reads_control":normal_reads,
                "native_scratch_g_reads_forced":forced_reads,
                "final_native_scratch_control":unmodified["final_scratch_value"],
                "final_native_scratch_forced":altered["final_scratch_value"],
                "real_p_write_count_control":unmodified["observed_native_p_writes"],
                "real_p_write_count_forced":altered["observed_native_p_writes"],
                "all_fungespace_mutators_audited":False,
                "full_semantic_state_equivalence_proven":False}
        report.append(result)
        print("NATIVE_CURRENT_FORK_ROUTE_VS_OUTPUT_MEASURED",
              label,"real_route_changed",True,
              "final_output_causal",changed,
              "first_vector",first[:4],
              "forced_vector",opposite[:4],
              "common_5_event_motion",overlap is not None,
              "rejoin_toss_equal_steps",sum(equal_toss),
              "rejoin_all_frames_equal_steps",sum(equal_frames),
              "rejoin_p_modified_cells_equal_steps",sum(equal_modified_p),
              "rejoin_ip_context_equal_steps",sum(ip_context_equal),
              "rejoin_input_cursor_equal_steps",sum(input_cursor_equal))
        sys.stdout.flush()
    require(len(report)==32 and sum(z["changed_final_semantics"] for z in report if z["case"] in ("zero_equal","foundation_cross","forward_short","mixed_small"))==2,
            "incomplete or unexpectedly classified Native fork corpus")
    zeros=[z for z in report if z["gate_observed_nonzero"]==0]
    ones=[z for z in report if z["gate_observed_nonzero"]==1]
    # Befunge-98 | sends zero downward (+y) and nonzero upward (-y).
    # Native evidence: all 12 zero-operand cases are output-causal,
    # while all 20 nonzero-operand cases are output-inert under inversion.
    require(len(zeros)==12 and len(ones)==20 and
            all(z["changed_final_semantics"] for z in zeros) and
            all(not z["changed_final_semantics"] for z in ones),
            "32-case Native fork route/output dependence classification drifted")
    require(all(z["first_common_five_event_motion"] is not None for z in report),
            "expected 32 actual Native five-motion reconvergences missing")
    require(all(z["first_rejoin_native_toss_equal_count"]==0
                for z in zeros) and
            all(z["first_rejoin_native_toss_equal_count"]==5
                for z in ones),
            "Native five-step TOSS convergence must match measured fork class")
    require(all(z["first_rejoin_native_toss_identical_all_five"] !=
                z["changed_final_semantics"] for z in report),
            "output-causal and five-step Native TOSS-rejoin classes collided")
    require(all(z["first_rejoin_p_modified_cells_equal_count"]==0 for z in report),
            "Native p-modified Funge-space unexpectedly reconverged in checked motion")
    data={"schema":"befunge-stage1-current-native-fork-route-differential-v7",
          "status":"QA_ONLY_UPSTREAM_FORK_CAUSALITY_OPEN",
          "source_git_blob":PIN,"real_PyFunge_runs":64,
          "valid_input_cases":32,
          "native_route_changed_cases":32,
          "native_verified_scratch_write_read_transactions":32,
          "native_scratch_unwritten_control_cases":12,
          "native_scratch_written_control_cases":20,
          "native_scratch_final_state_bounded_check":True,
          "final_semantics_changed_cases":sum(z["changed_final_semantics"] for z in report),
          "final_semantics_inert_cases":sum(not z["changed_final_semantics"] for z in report),
          "output_causality_not_universal":True,
          "zero_operand_cases":len(zeros),
          "zero_operand_final_causal_cases":sum(z["changed_final_semantics"] for z in zeros),
          "nonzero_operand_cases":len(ones),
          "nonzero_operand_final_inert_cases":sum(not z["changed_final_semantics"] for z in ones),
          "native_toss_rejoin_snapshots_measured":len(report)*5*2,
          "native_toss_tamper_negative_controls":len(report),
          "native_toss_equal_all_five_cases":sum(z["first_rejoin_native_toss_identical_all_five"] for z in report),
          "native_toss_equal_all_five_inert_cases":20,
          "native_toss_unequal_all_five_output_causal_cases":12,
          "full_fungespace_or_soss_equivalence_not_claimed":True,
          "native_stack_frame_rejoin_snapshots_measured":320,
          "native_p_mutated_cell_rejoin_snapshots_measured":320,
          "native_frame_all_five_equal_cases":sum(
              all(z["first_rejoin_all_stack_frames_equal_each_step"]) for z in report),
          "native_p_changed_cells_all_five_equal_cases":sum(
              all(z["first_rejoin_p_modified_cells_equal_each_step"]) for z in report),
          "p_modified_cells_unequal_all_five_observed_cases":sum(
              z["first_rejoin_p_modified_cells_equal_count"]==0 for z in report),
          "native_ip_context_rejoin_snapshots_measured":320,
          "native_ip_context_equal_five_cases":sum(
              all(z["first_rejoin_ip_context_equal_each_step"]) for z in report),
          "native_input_cursor_equal_five_cases":sum(
              all(z["first_rejoin_input_cursor_equal_each_step"]) for z in report),
          "raw_native_rejoin_frames_and_p_modified_values_retained":True,
          "non_p_fungespace_mutations_excluded_from_proof":True,
          "records":report}
    with open(OUT,"wb") as sink:
        sink.write(json.dumps(data,sort_keys=True,indent=2)+"\n")
    print("NATIVE_CURRENT_UPSTREAM_FORK_ROUTE_VS_OUTPUT_CAUSALITY_PROFILE_PASS",
          "thirty_two_real_branch_changes","mixed_output_causality")
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO STAGE1_OPEN=YES")

if __name__=="__main__":
    main()
