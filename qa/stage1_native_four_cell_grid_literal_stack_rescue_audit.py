#!/usr/bin/env python3
"""Independent proof-of-evidence audit for Native 7x7 lower literal TOSS rescue.

Does not implement Pastafarian numerical arithmetic. The runner separately
executes PyFunge Native programs and independently computed BF98 references.
"""
import copy,hashlib,json,re,sys
from pathlib import Path

BASE="560d6aa5807a7f766213a33835cce85eab0fa40c"
CAND="d965ce4bdfa282f2d3b82690808def5a2dde10a8"
GRID=tuple(range(-3,4))
NUMBER=re.compile(r"(?:0|-?[1-9][0-9]*)\Z")
def need(v,err):
    if not v:raise AssertionError(err)

def check(doc):
    need(type(doc) is dict and
         doc.get("schema")=="befunge-stage1-native-four-cell-literal-stack-mediation-v1" and
         doc.get("status")=="FINITE_ACTUAL_NATIVE_STACK_MEDIATION_STAGE1_OPEN" and
         doc.get("base_source_blob")==BASE and
         doc.get("four_cell_candidate_blob")==CAND and
         doc.get("signed_days")==list(GRID) and
         doc.get("input_pairs")==49 and
         doc.get("actually_executed_lower_literals")==21 and
         doc.get("actual_next_opcode_toss_rescues")==21 and
         doc.get("lower_literal_unreached_controls")==28 and
         doc.get("native_control_executions")==49 and
         doc.get("native_zero_executions")==49 and
         doc.get("native_rescue_executions")==49 and
         doc.get("independent_native_befunge_references")==147 and
         doc.get("total_native_program_executions")==294 and
         doc.get("production_source_modified") is False and
         doc.get("stage1_complete") is False and
         doc.get("stage2_started") is False,
         "Native stack mediation source/count/Stage-1 scope is forged")
    cases=doc.get("records")
    need(type(cases) is list and len(cases)==49,
         "Native 49-pair stack mediation corpus incomplete")
    for row,(dc,dt) in zip(cases,((x,y) for x in GRID for y in GRID)):
        fields=(int(dc<0),abs(dc),int(dt<0),abs(dt))
        raw=" ".join(map(str,fields))+"\n"
        hit=dc<0
        expected=row.get("native_reference_output")
        require_vector=lambda v: type(v) is list and len(v)==7 and all(
            type(z) is str and NUMBER.fullmatch(z) for z in v)
        need(type(row) is dict and row.get("signed_days")==[dc,dt] and
             row.get("input_fields")==list(fields) and
             row.get("input_sha256")==hashlib.sha256(raw.encode("ascii")).hexdigest() and
             require_vector(expected) and
             require_vector(row.get("normal_output")) and
             require_vector(row.get("zero_mutant_output")) and
             require_vector(row.get("rescued_output")) and
             row["normal_output"]==row["rescued_output"]==expected and
             row["zero_mutant_output"]==(["-1"]*7 if hit else expected) and
             row.get("literal_was_executed") is hit and
             row.get("zero_mutant_normal_termination") is True and
             row.get("output_restored_by_only_one_toss_repair") is hit and
             type(row.get("original_steps")) is int and row["original_steps"]>0 and
             type(row.get("zero_mutant_steps")) is int and
             row["zero_mutant_steps"]>0,
             "Native BF98 signed pair, seven-field output, or causal witness altered")
        native=row.get("rescue_run")
        need(type(native) is dict and native.get("status")=="normal" and
             native.get("remaining_ips")==0 and native.get("output")==expected and
             type(native.get("steps")) is int and native["steps"]>0 and
             native.get("lower_literal_visits")==int(hit) and
             native.get("edited_literal_steps")==int(hit) and
             native.get("repaired_toss_values")==int(hit) and
             type(native.get("final_source_byte")) is int,
             "Native rescue process or executed literal was forged")
        lit=native.get("actual_literal")
        fix=native.get("actual_stack_rescue")
        if hit:
            need(type(lit) is dict and type(fix) is dict and
                 lit.get("pushed")==0 and
                 lit.get("restored_physical_source_byte")==49 and
                 type(lit.get("tick")) is int and lit["tick"]>0 and
                 fix.get("tick")==lit["tick"]+1 and
                 fix.get("top_before")=="0" and fix.get("top_after")=="1" and
                 fix.get("other_stack_values_unchanged") is True and
                 fix.get("intervened_source_byte_before_next")==49 and
                 type(fix.get("next_opcode_coordinate")) is list and
                 len(fix["next_opcode_coordinate"])==2,
                 "Native next-opcode physical stack repair not evidenced")
        else:
            need(lit is None and fix is None,
                 "unreached lower literal claimed nonexistent Native rescue")
    return True

def fixture():
    rows=[]
    for dc in GRID:
        for dt in GRID:
            fields=(int(dc<0),abs(dc),int(dt<0),abs(dt))
            raw=" ".join(map(str,fields))+"\n"
            hit=dc<0
            expected=["101","102","103","104","105","106","107"]
            lit=dict(tick=100,pushed=0,restored_physical_source_byte=49) if hit else None
            repair=dict(tick=101,next_opcode_coordinate=[951,1336],
                        top_before="0",top_after="1",
                        other_stack_values_unchanged=True,
                        intervened_source_byte_before_next=49) if hit else None
            native=dict(status="normal",steps=19000,remaining_ips=0,
                        output=list(expected),lower_literal_visits=int(hit),
                        edited_literal_steps=int(hit),repaired_toss_values=int(hit),
                        actual_literal=lit,actual_stack_rescue=repair,
                        final_source_byte=49)
            rows.append(dict(signed_days=[dc,dt],input_fields=list(fields),
                             input_sha256=hashlib.sha256(raw.encode("ascii")).hexdigest(),
                             native_reference_output=list(expected),
                             normal_output=list(expected),
                             zero_mutant_output=["-1"]*7 if hit else list(expected),
                             rescued_output=list(expected),
                             zero_mutant_steps=19000,original_steps=19124,
                             literal_was_executed=hit,
                             zero_mutant_normal_termination=True,rescue_run=native,
                             output_restored_by_only_one_toss_repair=hit))
    return dict(schema="befunge-stage1-native-four-cell-literal-stack-mediation-v1",
                status="FINITE_ACTUAL_NATIVE_STACK_MEDIATION_STAGE1_OPEN",
                base_source_blob=BASE,four_cell_candidate_blob=CAND,
                signed_days=list(GRID),input_pairs=49,
                actually_executed_lower_literals=21,
                actual_next_opcode_toss_rescues=21,
                lower_literal_unreached_controls=28,
                native_control_executions=49,native_zero_executions=49,
                native_rescue_executions=49,
                independent_native_befunge_references=147,
                total_native_program_executions=294,
                production_source_modified=False,
                stage1_complete=False,stage2_started=False,records=rows)

def selftest():
    clean=fixture()
    need(check(clean),"clean synthetic QA report rejected")
    attacks=(
      ("missing_pair",lambda r:r["records"].pop()),
      ("false_signed_day",lambda r:r["records"][0].__setitem__("signed_days",[3,3])),
      ("wrong_oracle",lambda r:r["records"][0]["native_reference_output"].__setitem__(0,"999")),
      ("false_zero_mutant",lambda r:r["records"][0]["zero_mutant_output"].__setitem__(0,"0")),
      ("fake_stack_rescue",lambda r:r["records"][0]["rescue_run"].__setitem__("repaired_toss_values",0)),
      ("wrong_rescue_tick",lambda r:r["records"][0]["rescue_run"]["actual_stack_rescue"].__setitem__("tick",100)),
      ("corrupted_source_restore",lambda r:r["records"][0]["rescue_run"]["actual_literal"].__setitem__("restored_physical_source_byte",48)),
      ("mutated_other_stack_values",lambda r:r["records"][0]["rescue_run"]["actual_stack_rescue"].__setitem__("other_stack_values_unchanged",False)),
      ("fabricated_reach",lambda r:r["records"][25].__setitem__("literal_was_executed",True)),
      ("incorrect_process_count",lambda r:r.__setitem__("total_native_program_executions",293)),
      ("source_drift",lambda r:r.__setitem__("four_cell_candidate_blob","0"*40)),
      ("premature_stage2",lambda r:r.__setitem__("stage2_started",True)),
    )
    for label,fn in attacks:
        m=copy.deepcopy(clean)
        fn(m)
        try:check(m)
        except AssertionError:pass
        else:raise AssertionError("Native mediation forged evidence accepted: "+label)
    print("NATIVE_FOUR_CELL_STACK_MEDIATION_12_SYNTHETIC_TAMPERS_REJECT_PASS")

def main(path):
    selftest()
    report_path=Path(path)/"native_lower_literal_stack_rescue_49.json"
    need(report_path.is_file(),"actual Native stack rescue report missing")
    report=json.loads(report_path.read_text("utf8"))
    need(check(report),"actual Native stack-mediation observations rejected")
    print("NATIVE_FOUR_CELL_21_STACK_RESCUES_28_UNREACHED_INDEPENDENT_AUDIT_PASS")
    print("STAGE1_OPEN; NO_PRODUCTION_PROMOTION")

if __name__=="__main__":
    if len(sys.argv)==1 or (len(sys.argv)==2 and sys.argv[1]=="--selftest"):
        selftest()
    else:
        need(len(sys.argv)==2,"usage: stack rescue auditor PATH or --selftest")
        main(sys.argv[1])
