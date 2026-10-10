#!/usr/bin/env python3
"""Independent audit: 32 valid Native four-cell BF98 fork interventions.

Checks physical four-source-byte difference, 64 actual Native control and
operand-inverted executions, complete seven-field oracle vectors, actual
first fork branch direction, five common executed directed motions, raw
stack/frame/p-space/IP witnesses, effect groups and 16 hostile falsifications.
No numeric oracle is computed by Python; Stage1 stays OPEN.
"""
import copy,hashlib,json,sys
from pathlib import Path
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
CANDIDATE="d965ce4bdfa282f2d3b82690808def5a2dde10a8"
EDITS=[[948,1331,"6","7"],[951,1337,"^","1"],
       [951,1338," ","^"],[952,1336,"1"," "]]
def need(x,msg):
    if not x:raise AssertionError(msg)
def gitblob(s):
    return hashlib.sha1(b"blob "+str(len(s)).encode()+b"\0"+s).hexdigest()
def check(d):
    need(d.get("schema")=="befunge-stage1-four-cell-native-32-valid-fork-v2"
         and d.get("status")=="NATIVE_QA_ONLY_FORK_CAUSALITY_PROFILE_STAGE1_OPEN"
         and d.get("source_git_blob")==PIN
         and d.get("candidate_git_blob")==CANDIDATE
         and d.get("exact_four_source_edits")==EDITS
         and d.get("native_programs")==64
         and d.get("native_reference_cases")==32
         and d.get("zero_operand_cases")==12
         and d.get("nonzero_operand_cases")==20
         and d.get("all_native_controls_match_reference") is True
         and d.get("all_branch_first_vectors_opposite") is True
         and d.get("all_five_motion_rejoins_observed") is True
         and d.get("automatic_promotion") is False
         and d.get("stage1_complete") is False,
         "native four-cell fork source/evidence scope or Stage-1 flags forged")
    rows=d.get("records")
    need(isinstance(rows,list) and len(rows)==32 and
         len({x.get("label") for x in rows})==32,
         "thirty-two genuinely distinct valid Native case records not retained")
    zero=one=zc=oc=0
    for r in rows:
        fields=r.get("fields")
        ref=r.get("reference_7")
        ctl=r.get("control");mut=r.get("forced")
        need(isinstance(fields,list) and len(fields)==4
             and all(isinstance(x,str) and x.isdigit() for x in fields)
             and isinstance(ref,list) and len(ref)==7
             and all(isinstance(v,str) and v.lstrip("-").isdigit() for v in ref)
             and ref!=["-1"]*7 and
             isinstance(ctl,dict) and isinstance(mut,dict),
             "source-independent Native valid input/oracle vector invalid")
        need(ctl.get("status")=="normal" and ctl.get("remaining_ips")==0
             and ctl.get("output")==ref and
             mut.get("status") in ("normal","step-limit")
             and type(ctl.get("steps")) is int and
             type(mut.get("steps")) is int and
             0<ctl["steps"]<=750001 and 0<mut["steps"]<=750001
             and type(ctl.get("total_p_writes")) is int and
             type(mut.get("total_p_writes")) is int and
             type(ctl.get("total_g_reads")) is int and
             type(mut.get("total_g_reads")) is int,
             "real native control not normal or reference was modified")
        a=ctl.get("gate_events");b=mut.get("gate_events")
        need(isinstance(a,list) and len(a)==1
             and isinstance(b,list) and len(b)==1 and
             type(a[0].get("step")) is int and
             a[0]["step"]==b[0].get("step") and
             a[0].get("original")==a[0].get("executed") and
             a[0].get("original")==b[0].get("original")
             and b[0].get("executed")==1-a[0]["executed"]
             and type(a[0].get("depth")) is int and
             a[0]["depth"]>=1 and a[0]["depth"]==b[0].get("depth")
             and a[0]["executed"] in (0,1),
             "genuine native conditional | operand inversion not witnessed")
        group=a[0]["executed"]
        need(r.get("natural_nonzero")==group
             and r.get("forced_nonzero")==1-group,
             "real native route class mismatch")
        firsta=ctl.get("first_5_motion");firstb=mut.get("first_5_motion")
        need(isinstance(firsta,list) and isinstance(firstb,list)
             and len(firsta)==len(firstb)==5 and
             all(isinstance(row,list) and len(row)==5 for row in firsta+firstb)
             and firsta[0][:4]!=firstb[0][:4]
             and firsta[0][3]==-firstb[0][3] and
             firsta[0][3]!=0,
             "actual Native opposite first motion not measured")
        off=r.get("first_shared_motion_offsets")
        trace=r.get("five_shared_motion")
        need(isinstance(off,list) and len(off)==2 and
             all(type(v) is int and 0<=v<=507 for v in off)
             and isinstance(trace,list) and len(trace)==5
             and all(isinstance(v,list) and len(v)==4 and
                     all(type(n) is int for n in v) for v in trace),
             "five actually executed joint native directed instruction events missing")
        # Independently reconstruct the earliest five-instruction rejoin
        # from both complete directed (x,y,dx,dy) Native motion traces.
        # A self-reported "rejoin" is not sufficient evidence.
        full_routes=[]
        for key,first in (
                ("complete_motion_control",firsta),
                ("complete_motion_forced",firstb)):
            sequence=r.get(key)
            need(isinstance(sequence,list) and 5<=len(sequence)<=512
                 and all(isinstance(z,list) and len(z)==4
                         and all(type(t) is int for t in z)
                         for z in sequence)
                 and sequence[:5]==[z[:4] for z in first],
                 "complete directed Native fork route or prefix missing")
            full_routes.append(sequence)
        windows={}
        for i in range(len(full_routes[0])-4):
            event=tuple(tuple(z) for z in full_routes[0][i:i+5])
            windows.setdefault(event,i)
        independently_found=None
        for j in range(len(full_routes[1])-4):
            event=tuple(tuple(z) for z in full_routes[1][j:j+5])
            if event in windows:
                independently_found=[
                    windows[event],j,[list(z) for z in event]]
                break
        need(independently_found is not None
             and independently_found[:2]==off
             and independently_found[2]==trace,
             "claimed Native five-motion rejoin is not independently reproducible")
        pairs=(("frames","five_frames_control","five_frames_forced","five_equal_frames"),
               ("p_memory","five_p_mutations_control","five_p_mutations_forced","five_equal_p_mutations"),
               ("ip_context","five_context_control","five_context_forced","five_equal_context"))
        for tag,left,right,claim in pairs:
            aa=r.get(left);bb=r.get(right);flags=r.get(claim)
            need(isinstance(aa,list) and isinstance(bb,list) and
                 isinstance(flags,list) and len(aa)==len(bb)==len(flags)==5
                 and all(type(z) is bool for z in flags)
                 and flags==[x==y for x,y in zip(aa,bb)],
                 "actual Native "+tag+" equality contradictory to raw runtime values")
        expected_change=(mut["status"]!="normal" or mut.get("remaining_ips")!=0
                         or mut.get("output")!=ref)
        need(r.get("changed_final_output_or_termination") is expected_change
             and r.get("changed_actual_seven_output") is (mut.get("output")!=ref),
             "Native fork downstream output/termination causality misrepresented")
        if group==0:zero+=1;zc+=expected_change
        else:one+=1;oc+=expected_change
    need(zero==12 and one==20 and d.get("zero_operand_causal")==zc
         and d.get("nonzero_operand_causal")==oc,
         "real two-arm fork output causal summary does not match witnesses")
    return {"valid_native_inputs":32,"actual_native_executions":64,
            "lower_route_causal":zc,"lower_route_total":zero,
            "upper_route_causal":oc,"upper_route_total":one,
            "source_modified_in_repository":False,"stage1_complete":False}

def main(dirname):
    root=Path(dirname)
    source=Path("src/interleaved_work_counts.b98").read_bytes()
    new=(root/"four_cell_candidate.b98").read_bytes()
    need(gitblob(source)==PIN and gitblob(new)==CANDIDATE,
         "Native production/candidate source identity changed")
    old_rows=source.split(b"\n");new_rows=new.split(b"\n")
    need(len(old_rows)==len(new_rows),"Native source height changed")
    differences=[]
    for y,(old,newrow) in enumerate(zip(old_rows,new_rows)):
        need(len(old)==len(newrow),"Native Funge-space row width changed")
        for x,(a,b) in enumerate(zip(old,newrow)):
            if a!=b:differences.append([x,y,chr(a),chr(b)])
    need(differences==sorted(EDITS,key=lambda z:(z[1],z[0])),
         "candidate modified more or fewer than exact four Funge-space source cells")
    d=json.loads((root/"four_cell_fork_32_control_mutant.json").read_text(encoding="utf-8"))
    outcome=check(d)
    print("NATIVE_FOUR_CELL_32_VALID_FORK_INDEPENDENT_AUDIT_PASS",
          json.dumps(outcome,sort_keys=True))
    denied=[]
    def negative(label,mut):
        forged=copy.deepcopy(d);mut(forged)
        try:check(forged)
        except AssertionError:
            denied.append(label)
            print("NATIVE_FOUR_CELL_FORK_FORGERY_REJECT_PASS",label)
            return
        raise AssertionError("forged Native four-cell fork evidence accepted: "+label)
    negative("source",lambda z:z.__setitem__("candidate_git_blob","0"*40))
    negative("source_edits",lambda z:z.__setitem__("exact_four_source_edits",[]))
    negative("drop",lambda z:z["records"].pop())
    negative("duplicate",lambda z:z["records"][0].__setitem__("label",z["records"][1]["label"]))
    negative("bad_original",lambda z:z["records"][0]["control"]["output"].__setitem__(0,"BAD"))
    negative("fake_numeric_reference",lambda z:z["records"][0]["reference_7"].pop())
    negative("miscount",lambda z:z.__setitem__("zero_operand_cases",11))
    negative("wrong_gate",lambda z:z["records"][0]["forced"]["gate_events"][0].__setitem__("executed",
                   z["records"][0]["control"]["gate_events"][0]["executed"]))
    negative("wrong_direction",lambda z:z["records"][0]["forced"]["first_5_motion"][0].__setitem__(3,0))
    negative("missing_rejoin",lambda z:z["records"][0].__setitem__("first_shared_motion_offsets",None))
    negative("stack_flag",lambda z:z["records"][0]["five_equal_frames"].__setitem__(0,
                   not z["records"][0]["five_equal_frames"][0]))
    negative("memory_flag",lambda z:z["records"][0]["five_equal_p_mutations"].__setitem__(0,
                   not z["records"][0]["five_equal_p_mutations"][0]))
    negative("ip_flag",lambda z:z["records"][0]["five_equal_context"].__setitem__(0,
                   not z["records"][0]["five_equal_context"][0]))
    negative("effect",lambda z:z["records"][0].__setitem__("changed_final_output_or_termination",
                   not z["records"][0]["changed_final_output_or_termination"]))
    negative("total_effect",lambda z:z.__setitem__("nonzero_operand_causal",-1))
    negative("premature_stage",lambda z:z.__setitem__("stage1_complete",True))
    negative("fabricated_shared_event",
             lambda z:z["records"][0]["five_shared_motion"][0].__setitem__(0,999999))
    negative("fabricated_route_prefix",
             lambda z:z["records"][0]["complete_motion_control"][0].__setitem__(0,999999))
    negative("fabricated_offset",
             lambda z:z["records"][0]["first_shared_motion_offsets"].__setitem__(0,507))
    negative("missing_complete_route",
             lambda z:z["records"][0]["complete_motion_forced"].clear())
    need(len(denied)==20,"Native four-cell fork adversarial suite incomplete")
    (root/"four_cell_fork_32_audit.json").write_text(json.dumps(
      {"schema":"befunge-stage1-four-cell-fork32-audit-v2",
       "measured":outcome,"forged_reports_rejected":denied,
       "stage1_final":False},sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_FOUR_CELL_FORK_TWENTY_FALSIFIED_REPORTS_REJECTED_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"Native QA fork32 artifact path required")
    main(sys.argv[1])
