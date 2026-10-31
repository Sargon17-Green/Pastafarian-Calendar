#!/usr/bin/env python3
"""Independent integrity audit for 12 valid-source Native lower-turn bypasses.

Checks actual raw 5-step stack, IP, p-cell and stdout snapshots against each
reported comparison, seven-field native oracle parity, exact 18-step shortcut,
and 16 deliberately falsified reports. Never computes calendar arithmetic.
The QA acceptance gate is explicitly OPEN whatever the outcome.
"""
import copy
import hashlib
import json
import sys
from pathlib import Path

PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
LABELS=(
 "foundation_cross","mixed_small","negative_positive",
 "foundation_neighbor_forward","foundation_neighbor_reverse",
 "negative_equal_high","negative_high_forward","negative_high_reverse",
 "cross_high_forward","foundation_to_origin","foundation_to_recent",
 "decimal_cross_reverse",
)
SKIPPED=(36,49,48,48,57,48,51,45,120,94,119,95,48,56,54,120,94,93)
FLAGS=("frames","context","p_modified","stdout")
def require(ok,reason):
    if not ok:raise AssertionError(reason)

def validate(d):
    require(d.get("schema")=="befunge-stage1-lower-feedback-twelve-wide-rejoin-v1"
            and d.get("production_git_blob")==PIN
            and d.get("status")=="OBSERVED_NATIVE_TWELVE_CASE_BYPASS_NOT_ACCEPTANCE"
            and d.get("source_corpus_artifact_id")==11666777943
            and d.get("native_case_count")==12
            and d.get("native_program_executions")==24
            and d.get("native_oracle_cases")==12
            and d.get("bypass_instruction_count")==18
            and d.get("scc_lower_cell")==[951,1336]
            and d.get("stage1_geometry_gate")=="OPEN"
            and d.get("last_completed_stage")==0,
            "Native source, evidence scope or Stage-1 status forged")
    rows=d.get("records")
    require(isinstance(rows,list) and len(rows)==12
            and tuple(x.get("case") for x in rows)==LABELS,
            "twelve source-pinned lower-case records missing/reordered")
    counts={k:0 for k in FLAGS}
    all_steps_saved=0
    for row in rows:
        expected=row.get("reference_output")
        inputfields=row.get("input_fields")
        require(isinstance(inputfields,list) and len(inputfields)==4
                and all(type(x) is int for x in inputfields)
                and isinstance(expected,list) and len(expected)==7
                and all(isinstance(x,str) for x in expected)
                and row.get("control_output")==expected
                and row.get("mutant_output")==expected
                and row.get("control_status")=="normal"
                and row.get("mutant_status")=="normal",
                "measured valid Native seven-field output reference differs")
        start=row.get("native_gate_tick")
        before=row.get("native_gate_direction_before")
        a=row.get("control_gate_direction_after")
        b=row.get("mutant_gate_direction_after")
        require(type(start) is int and start>1 and
                before==[0,1] and a==[-1,0] and b==[1,0],
                "live Native ] to [ first-turn vector not actually witnessed")
        require(type(row.get("control_steps")) is int
                and type(row.get("mutant_steps")) is int
                and start<row["mutant_steps"]<row["control_steps"]<=210001
                and row["control_steps"]-row["mutant_steps"]==18,
                "real Native eighteen-op feedback loop was not bypassed")
        all_steps_saved+=18
        require(row.get("native_source_instruction_restored") is True
                and row.get("first_common_motion_indices")==[18,0]
                and tuple(row.get("skipped_native_opcodes",()))==SKIPPED,
                "original observed eighteen-op route or source restoration changed")
        for key in ("post_gate_control_p_count","post_gate_mutant_p_count",
                    "post_gate_control_g_count","post_gate_mutant_g_count"):
            require(type(row.get(key)) is int and row[key]>=0,
                    "Native p/g counter missing or negative")
        require(row["post_gate_control_p_count"]==
                row["post_gate_mutant_p_count"] and
                row["post_gate_control_g_count"]==
                row["post_gate_mutant_g_count"],
                "native lower-route bypass unexpectedly added p/g dataflow")
        common=row.get("five_common_state_records")
        require(isinstance(common,list) and len(common)==5,
                "five full Native post-rejoin comparison records missing")
        eq={k:0 for k in FLAGS}
        for i,snap in enumerate(common):
            require(snap.get("step")==i and
                    snap.get("native_motion")==[952+i,1336,1,0] and
                    type(snap.get("native_opcode")) is int,
                    "Native shared 5-step rejoin motion forged")
            pairs={
                "frames":("control_frames","mutant_frames"),
                "context":("control_context","mutant_context"),
                "p_modified":("control_p_modified","mutant_p_modified"),
                "stdout":("control_stdout_prefix","mutant_stdout_prefix")
            }
            for field,(left,right) in pairs.items():
                matched=snap.get(left)==snap.get(right)
                require(snap.get("equal",{}).get(field) is matched,
                        "Native "+field+" equality claim misrepresents raw runtime state")
                eq[field]+=matched
            for suffix in ("control","mutant"):
                frames=snap.get(suffix+"_frames")
                ctx=snap.get(suffix+"_context")
                memory=snap.get(suffix+"_p_modified")
                require(isinstance(frames,list) and len(frames)>0
                        and all(isinstance(frame,list) and all(isinstance(v,str) for v in frame)
                                for frame in frames)
                        and isinstance(ctx,dict) and ctx.get("offset")==[0,0]
                        and type(ctx.get("stdin_cursor")) is int
                        and ctx["stdin_cursor"]>=0
                        and all(type(ctx.get(flag)) is bool
                                for flag in ("stringmode","invertmode","queuemode"))
                        and isinstance(memory,list) and
                        all(isinstance(c,list) and len(c)==3 and
                            type(c[0]) is int and type(c[1]) is int and
                            isinstance(c[2],str) for c in memory),
                        "measured Native stack/IP/p memory fields absent")
        require(row.get("five_common_state_equals")==eq,
                "Native five-step full-state equality counts are invented")
        for field in FLAGS:
            counts[field]+=eq[field]==5
    require(d.get("summary_all_five_equal_cases")==counts,
            "Native twelve-input equality summary forged")
    return {"native_cases":12,"native_programs":24,
            "saved_native_instruction_steps":all_steps_saved,
            "all_five_equal_cases":counts,
            "stage1_gate":"OPEN"}

def main(folder):
    source=Path("src/interleaved_work_counts.b98").read_bytes()
    sha=hashlib.sha1(b"blob "+str(len(source)).encode("ascii")+
                     b"\0"+source).hexdigest()
    require(sha==PIN,"Source Git blob not pinned")
    root=Path(folder)
    data=json.loads((root/"native_lower_wide_rejoin.json").read_text("utf-8"))
    report=validate(data)
    print("NATIVE_LOWER_WIDE_REJOIN_INDEPENDENT_AUDIT_PASS",
          json.dumps(report,sort_keys=True))
    rejected=[]
    def attack(label,change):
        bad=copy.deepcopy(data)
        change(bad)
        try:validate(bad)
        except AssertionError:
            rejected.append(label)
            print("NATIVE_LOWER_WIDE_FALSIFIED_REPORT_REJECT_PASS",label)
            return
        raise AssertionError("forged Native lower-turn evidence accepted: "+label)
    attack("source",lambda d:d.__setitem__("production_git_blob","0"*40))
    attack("case_missing",lambda d:d["records"].pop())
    attack("case_reordered",lambda d:d["records"][0].__setitem__("case","mixed_small"))
    attack("bad_native_reference",lambda d:d["records"][0]["control_output"].__setitem__(0,"BAD"))
    attack("wrong_mutant_oracle",lambda d:d["records"][0]["mutant_output"].__setitem__(0,"BAD"))
    attack("broken_direction",lambda d:d["records"][0].__setitem__("mutant_gate_direction_after",[0,1]))
    attack("bad_shortcut",lambda d:d["records"][0].__setitem__("mutant_steps",
        d["records"][0]["mutant_steps"]+1))
    attack("wrong_rejoin",lambda d:d["records"][0].__setitem__("first_common_motion_indices",[17,0]))
    attack("wrong_op",lambda d:d["records"][0]["skipped_native_opcodes"].__setitem__(0,ord("p")))
    attack("fake_stack",lambda d:d["records"][0]["five_common_state_records"][0].__setitem__("mutant_frames",None))
    attack("fake_context",lambda d:d["records"][0]["five_common_state_records"][0].__setitem__("mutant_context",None))
    attack("fake_memory",lambda d:d["records"][0]["five_common_state_records"][0].__setitem__("mutant_p_modified",None))
    attack("fake_stdout",lambda d:d["records"][0]["five_common_state_records"][0].__setitem__("mutant_stdout_prefix",None))
    attack("false_summary",lambda d:d["summary_all_five_equal_cases"].__setitem__("frames",999))
    attack("fake_completion",lambda d:d.__setitem__("stage1_geometry_gate","PASS"))
    attack("missing_native",lambda d:d.__setitem__("native_program_executions",23))
    require(len(rejected)==16,"Native lower-wide evidence adversarial suite incomplete")
    (root/"native_lower_wide_rejoin_audit.json").write_text(json.dumps(
      {"schema":"befunge-stage1-lower-feedback-twelve-wide-audit-v1",
       "summary":report,"forgeries_rejected":rejected,
       "stage1_complete":False},sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_LOWER_WIDE_SIXTEEN_FORGED_REPORTS_REJECTED_PASS")

if __name__=="__main__":
    require(len(sys.argv)==2,"usage: Native lower-wide evidence directory")
    main(sys.argv[1])
