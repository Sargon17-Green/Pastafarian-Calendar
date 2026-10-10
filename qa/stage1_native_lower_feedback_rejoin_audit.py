#!/usr/bin/env python3
"""Independent audit: six real Native lower feedback rejoin comparisons.

Each Native run changes one executed ] into [ for one step only and then
restores source. Original/calculation results only come from Befunge-98.
Checks actual 5-step rejoin state evidence and rejects adversarial forgeries.
A finite proof; no final Stage-1 acceptance.
"""
import copy
import hashlib
import json
import sys
from pathlib import Path

PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
CASES=("foundation_cross","mixed_small","negative_positive",
       "invalid_zero_sign","foundation_neighbor_forward",
       "foundation_neighbor_reverse")
def need(ok,msg):
    if not ok:raise AssertionError(msg)

def verify(d):
    need(d.get("schema")=="befunge-stage1-native-lower-feedback-rejoin-v1"
         and d.get("source_git_blob")==PIN
         and d.get("status")=="FINITE_NATIVE_LOWER_ROUTE_REJOIN_STAGE1_OPEN"
         and d.get("source_geometry_artifact_id")==11664135758
         and d.get("native_cases")==6 and d.get("native_programs")==12
         and d.get("saved_steps_each")==18
         and d.get("distinct_ip_semantic_snapshots")==60
         and d.get("stage1_geometry_pass") is False
         and d.get("stage1_functional_pass") is False,
         "Native source, input, measured snapshots or acceptance modified")
    rows=d.get("records")
    need(isinstance(rows,list) and len(rows)==6
         and tuple(z.get("case") for z in rows)==CASES,
         "native six-case lower-route corpus incomplete")
    totals={"frames":0,"context":0,"p_cells":0,"stdout":0}
    for row in rows:
        valid=row["case"]!="invalid_zero_sign"
        ref=row.get("native_expected")
        fields=row.get("input_fields")
        need(row.get("valid") is valid
             and isinstance(fields,list) and len(fields)==4
             and all(type(x) is int for x in fields)
             and isinstance(ref,list) and len(ref)==7
             and all(type(x) is str for x in ref)
             and (valid or ref==["-1"]*7),
             "Native lower-route case domain/oracle invalid")
        need(row.get("control_output")==ref
             and row.get("mutant_output")==ref
             and row.get("control_status")=="normal"
             and row.get("mutant_status")=="normal"
             and row.get("control_remaining_ips")==0
             and row.get("mutant_remaining_ips")==0,
             "native outcome disagrees with independent Befunge reference")
        need(type(row.get("control_steps")) is int
             and type(row.get("mutant_steps")) is int
             and 0<row["mutant_steps"]<row["control_steps"]<=210001
             and row["control_steps"]-row["mutant_steps"]==18
             and row.get("saved_steps")==18,
             "Native one-turn shortcut lost exact 18-step difference")
        a=row.get("control_gate")
        b=row.get("mutant_gate")
        need(isinstance(a,dict) and isinstance(b,dict)
             and a.get("executed_opcode")=="]"
             and b.get("executed_opcode")=="["
             and a.get("restored") is True and b.get("restored") is True
             and type(a.get("tick")) is int
             and a["tick"]==b.get("tick")
             and 1<a["tick"]<row["mutant_steps"]
             and a.get("direction_before")==b.get("direction_before")
             and a.get("direction_after")!=b.get("direction_after"),
             "Native single-instruction feedback change not witnessed")
        indices=row.get("first_shared_motion_indices")
        need(isinstance(indices,list) and len(indices)==2
             and all(type(x) is int and 0<=x<=251 for x in indices),
             "Native first five shared IP event indices malformed")
        observations=row.get("rejoin_5")
        need(isinstance(observations,list) and len(observations)==5,
             "Native five-step route rejoin evidence absent")
        count={"frames":0,"context":0,"p_cells":0,"stdout":0}
        for snap in observations:
            motion=snap.get("motion")
            need(isinstance(motion,list) and len(motion)==4
                 and all(type(x) is int for x in motion)
                 and type(snap.get("opcode")) is int
                 and 0<=snap["opcode"]<=255,
                 "native rejoin IP motion/opcode invalid")
            for key,left,right in (
                 ("frames","frames_control","frames_mutant"),
                 ("context","context_control","context_mutant"),
                 ("p_cells","p_modified_control","p_modified_mutant"),
                 ("stdout","stdout_control","stdout_mutant")):
                comparison=snap[left]==snap[right]
                flag=("frames_equal" if key=="frames"
                      else "context_equal" if key=="context"
                      else "p_mutated_cells_equal" if key=="p_cells"
                      else "stdout_prefix_equal")
                need(snap.get(flag) is comparison,
                     "Native rejoin "+key+" equality claim contradicted by raw state")
                count[key]+=comparison
            need(snap.get("input_cursor_equal") is
                 (snap["context_control"]["stdin_cursor"]==
                  snap["context_mutant"]["stdin_cursor"]),
                 "native stdin cursor equality claim contradicted")
            for suffix in ("control","mutant"):
                frames=snap["frames_"+suffix]
                ctx=snap["context_"+suffix]
                mem=snap["p_modified_"+suffix]
                need(isinstance(frames,list) and len(frames)>=1
                     and all(isinstance(frame,list) and
                             all(isinstance(v,str) for v in frame) for frame in frames)
                     and isinstance(ctx,dict)
                     and isinstance(ctx.get("offset"),list)
                     and len(ctx["offset"])==2
                     and type(ctx.get("stdin_cursor")) is int
                     and ctx["stdin_cursor"]>=0
                     and all(type(ctx.get(q)) is bool
                             for q in ("stringmode","invertmode","queuemode"))
                     and isinstance(mem,list)
                     and all(isinstance(cell,list) and len(cell)==3
                             and type(cell[0]) is int and type(cell[1]) is int
                             and isinstance(cell[2],str) for cell in mem),
                     "Native IP context, native stack frames or p-cell map fabricated")
        for field,flag in (("frames","all_five_frames_equal"),
                           ("context","all_five_context_equal"),
                           ("p_cells","all_five_p_cells_equal"),
                           ("stdout","all_five_stdout_equal")):
            need(row.get(flag) is (count[field]==5),
                 "native five-event composite rejoin assertion inaccurate")
            totals[field]+=count[field]==5
        for field in ("control_window_p_steps","mutant_window_p_steps",
                      "control_window_g_steps","mutant_window_g_steps"):
            need(type(row.get(field)) is int and row[field]>=0,
                 "negative/invalid native p/g instruction counts")
        need(type(row.get("capture_count_control")) is int
             and type(row.get("capture_count_mutant")) is int
             and 32<=row["capture_count_control"]<=256
             and 32<=row["capture_count_mutant"]<=256,
             "Native post-turn sampling below required minimum")
    for field,key in (("frames","all_frames_equal_cases"),
                      ("context","all_context_equal_cases"),
                      ("p_cells","all_p_cells_equal_cases"),
                      ("stdout","all_stdout_equal_cases")):
        need(d.get(key)==totals[field],
             "Native rejoin state evidence aggregate is forged")
    return {"cases":6,"native_programs":12,
            "same_frames":totals["frames"],
            "same_ip_context":totals["context"],
            "same_p_mutated_cells":totals["p_cells"],
            "same_stdout_prefix":totals["stdout"]}

def main(folder):
    src=Path("src/interleaved_work_counts.b98").read_bytes()
    git=hashlib.sha1(b"blob "+str(len(src)).encode("ascii")+b"\0"+src).hexdigest()
    need(git==PIN,"Native production source no longer matches Git blob")
    root=Path(folder)
    data=json.loads((root/"native_lower_feedback_rejoin.json").read_text("utf-8"))
    result=verify(data)
    print("NATIVE_LOWER_FEEDBACK_REJOIN_INDEPENDENT_AUDIT_PASS",
          json.dumps(result,sort_keys=True))
    attacks=[]
    def reject(name,operation):
        forged=copy.deepcopy(data)
        operation(forged)
        try:verify(forged)
        except AssertionError:
            attacks.append(name)
            print("NATIVE_LOWER_FEEDBACK_REJOIN_TAMPER_REJECT_PASS",name)
            return
        raise AssertionError("Native lower feedback forged report accepted "+name)
    reject("source_pin",lambda d:d.__setitem__("source_git_blob","0"*40))
    reject("missing_case",lambda d:d["records"].pop())
    reject("case_order",lambda d:d["records"][0].__setitem__("case","mixed_small"))
    reject("changed_native_reference",lambda d:d["records"][0]["control_output"].__setitem__(0,"BAD"))
    reject("false_18_steps",lambda d:d["records"][0].__setitem__("saved_steps",17))
    reject("forged_op",lambda d:d["records"][0]["mutant_gate"].__setitem__("executed_opcode","r"))
    reject("missing_restore",lambda d:d["records"][0]["mutant_gate"].__setitem__("restored",False))
    reject("no_direction_change",lambda d:d["records"][0]["mutant_gate"].__setitem__(
       "direction_after",d["records"][0]["control_gate"]["direction_after"]))
    reject("bad_index",lambda d:d["records"][0].__setitem__("first_shared_motion_indices",[254,0]))
    reject("altered_frames",lambda d:d["records"][0]["rejoin_5"][0]["frames_mutant"][0].append("FORGED"))
    reject("altered_context",lambda d:d["records"][0]["rejoin_5"][0]["context_mutant"].__setitem__("stdin_cursor",-1))
    reject("altered_mem",lambda d:d["records"][0]["rejoin_5"][0]["p_modified_mutant"].append([1,1,"99"]))
    reject("false_aggregate",lambda d:d.__setitem__("all_frames_equal_cases",999))
    reject("false_stage1",lambda d:d.__setitem__("stage1_geometry_pass",True))
    need(len(attacks)==14,"Native lower feedback adversarial checks incomplete")
    (root/"native_lower_feedback_rejoin_audit.json").write_text(
        json.dumps({"schema":"befunge-stage1-native-lower-rejoin-audit-v1",
                    "observed":result,"forgeries_rejected":attacks,
                    "final_geometric_acceptance":False},sort_keys=True,indent=2)+"\n",
        encoding="utf-8")
    print("NATIVE_LOWER_FEEDBACK_REJOIN_FOURTEEN_TAMPERS_REJECTED_PASS")

if __name__=="__main__":
    need(len(sys.argv)==2,"usage: live Native lower rejoin report directory")
    main(sys.argv[1])
