#!/usr/bin/env python3
"""Separate wide Native stack-mediation provenance and hostile-report audit."""
import copy,hashlib,json,re,sys
from pathlib import Path
BASE="560d6aa5807a7f766213a33835cce85eab0fa40c"
PIN="d965ce4bdfa282f2d3b82690808def5a2dde10a8"
H=2**127
L=10**40+987654321
INPUTS=(
("zero_equal",(0,0,0,0)),
("foundation_cross",(1,15055672,1,15055670)),
("forward_short",(0,1,0,2)),
("reverse_short",(0,2,0,1)),
("mixed_small",(1,1,0,1)),
("positive_negative",(0,123456789,1,987654321)),
("negative_positive",(1,987654321,0,123456789)),
("large_values",(0,H,1,H-1)),
("epoch_forward_one",(0,0,0,1)),
("epoch_reverse_one",(0,1,0,0)),
("recent_anchor_equal",(0,2461319,0,2461319)),
("recent_anchor_next",(0,2461319,0,2461320)),
("foundation_neighbor_forward",(1,15055671,1,15055670)),
("foundation_neighbor_reverse",(1,15055670,1,15055671)),
("zero_two",(0,0,0,2)),
("two_zero",(0,2,0,0)),
("equal_high",(0,H,0,H)),
("high_forward_neighbor",(0,H,0,H+1)),
("high_reverse_neighbor",(0,H+1,0,H)),
("negative_equal_high",(1,H,1,H)),
("negative_high_forward",(1,H+1,1,H)),
("negative_high_reverse",(1,H,1,H+1)),
("cross_high_forward",(1,H,0,H)),
("cross_high_reverse",(0,H,1,H)),
("foundation_to_origin",(1,15055672,0,0)),
("origin_to_foundation",(0,0,1,15055672)),
("recent_to_foundation",(0,2461319,1,15055671)),
("foundation_to_recent",(1,15055671,0,2461319)),
("decimal_cross_forward",(0,L,1,10**41+123456789)),
("decimal_cross_reverse",(1,10**41+123456789,0,L)),
("recent_adjacent",(0,2461320,0,2461321)),
("recent_reverse",(0,2461321,0,2461320)),
)
NUM=re.compile(r"(?:0|-?[1-9][0-9]*)\Z")
def need(v,why):
    if not v:raise AssertionError(why)
def numerical(a):
    return type(a) is list and len(a)==7 and all(
        type(z) is str and NUM.fullmatch(z) for z in a)
def check(d):
    need(type(d) is dict and
      d.get("schema")=="befunge-stage1-four-cell-wide-literal-stack-v1" and
      d.get("status")=="FINITE_WIDE_NATIVE_MEDIATION_STAGE1_OPEN" and
      d.get("production_blob")==BASE and d.get("candidate_blob")==PIN and
      d.get("sampled_valid_cases")==32 and
      d.get("control_native_executions")==32 and
      d.get("intervention_native_executions")==32 and
      d.get("rescue_native_executions")==32 and
      d.get("native_reference_executions")==96 and
      d.get("total_native_executions")==192 and
      d.get("native_step_budget")==750000 and
      d.get("source_modified") is False and
      d.get("stage1_complete") is False and d.get("stage2_started") is False,
      "wide source, process counts or stage flags forged")
    rows=d.get("records")
    need(type(rows) is list and len(rows)==len(INPUTS)==32,
         "missing frozen 32 valid Native wide inputs")
    reach=effect=rescue_count=0
    for i,(r,(name,fields)) in enumerate(zip(rows,INPUTS)):
        raw=" ".join(map(str,fields))+"\n"
        a=r.get("control");b=r.get("zero_intervention");c=r.get("stack_rescue")
        want=r.get("reference_output")
        need(type(r) is dict and r.get("index")==i and
          r.get("case")==name and r.get("input_fields")==list(fields) and
          r.get("input_sha256")==hashlib.sha256(raw.encode("ascii")).hexdigest() and
          numerical(want) and type(a) is dict and
          type(b) is dict and type(c) is dict,
          "Native wide input/provenance/independent reference altered "+name)
        hits=a.get("native_lower_literal_visits")
        need(type(hits) is int and hits>=0,"invalid Native literal visits "+name)
        visit=int(hits>0)
        outcome=(b.get("status")!="normal" or b.get("remaining_ips")!=0 or
                 b.get("output")!=want)
        need(r.get("literal_reached") is bool(visit) and
          r.get("causal_effect") is bool(outcome) and
          r.get("next_step_toss_rescued") is bool(visit) and
          a.get("status")=="normal" and a.get("remaining_ips")==0 and
          a.get("output")==want and a.get("native_live_literal_edits")==0 and
          b.get("native_live_literal_edits")==visit and
          b.get("immediate_restorations")==visit and
          b.get("restored_source_byte")==(49 if visit else None) and
          c.get("status")=="normal" and c.get("remaining_ips")==0 and
          c.get("output")==want and c.get("lower_literal_visits")==hits and
          c.get("edited_literal_steps")==visit and
          c.get("repaired_toss_values")==visit and
          type(c.get("final_source_byte")) is int,
          "Native wide literal/counterfactual/next-opcode repair evidence false "+name)
        lit=c.get("actual_literal");toss=c.get("actual_stack_rescue")
        if visit:
            need(type(a.get("first_literal")) is dict and
              a["first_literal"].get("pushed")==1 and
              type(b.get("first_literal")) is dict and
              b["first_literal"].get("pushed")==0 and
              type(lit) is dict and type(toss) is dict and
              lit.get("pushed")==0 and
              lit.get("restored_physical_source_byte")==49 and
              toss.get("tick")==lit.get("tick")+1 and
              toss.get("top_before")=="0" and toss.get("top_after")=="1" and
              toss.get("other_stack_values_unchanged") is True and
              toss.get("intervened_source_byte_before_next")==49,
              "Native lower literal not rescued through one TOSS value "+name)
        else:
            need(a.get("first_literal") is None and
              b.get("first_literal") is None and lit is None and toss is None and
              b.get("status")=="normal" and b.get("remaining_ips")==0 and
              b.get("output")==want,
              "unreached literal silently altered different calculation "+name)
        reach+=visit;effect+=int(outcome);rescue_count+=visit
    need(d.get("visited_cases")==reach and
      d.get("unvisited_cases")==32-reach and
      d.get("causal_effect_cases")==effect and
      d.get("restored_by_one_toss_cases")==rescue_count,
      "Native wide stack mediation summary contradicts per-case evidence")
    need(0<reach<32,"both Native upper and lower routes not witnessed")
    return True
def fixture():
    rows=[]
    for i,(name,fields) in enumerate(INPUTS):
        hit=bool(fields[0])
        v=["0"]*7
        original=dict(status="normal",steps=30000,remaining_ips=0,
          output=list(v),native_lower_literal_visits=int(hit),
          native_live_literal_edits=0,immediate_restorations=0,
          restored_source_byte=None,final_source_byte=32,
          first_literal=(dict(pushed=1) if hit else None))
        changed=copy.deepcopy(original)
        changed.update(native_live_literal_edits=int(hit),
          immediate_restorations=int(hit),restored_source_byte=(49 if hit else None),
          first_literal=(dict(pushed=0) if hit else None))
        if hit: changed["output"]=["-1"]*7
        rescue=dict(status="normal",remaining_ips=0,output=list(v),
          lower_literal_visits=int(hit),edited_literal_steps=int(hit),
          repaired_toss_values=int(hit),final_source_byte=32,
          actual_literal=(dict(tick=200,pushed=0,
            restored_physical_source_byte=49) if hit else None),
          actual_stack_rescue=(dict(tick=201,top_before="0",top_after="1",
            other_stack_values_unchanged=True,
            intervened_source_byte_before_next=49) if hit else None))
        raw=" ".join(map(str,fields))+"\n"
        rows.append(dict(index=i,case=name,input_fields=list(fields),
          input_sha256=hashlib.sha256(raw.encode("ascii")).hexdigest(),
          reference_output=list(v),control=original,zero_intervention=changed,
          stack_rescue=rescue,literal_reached=hit,
          causal_effect=hit,next_step_toss_rescued=hit))
    n=sum(z["literal_reached"] for z in rows)
    return dict(schema="befunge-stage1-four-cell-wide-literal-stack-v1",
      status="FINITE_WIDE_NATIVE_MEDIATION_STAGE1_OPEN",
      production_blob=BASE,candidate_blob=PIN,sampled_valid_cases=32,
      control_native_executions=32,intervention_native_executions=32,
      rescue_native_executions=32,native_reference_executions=96,
      total_native_executions=192,native_step_budget=750000,
      visited_cases=n,unvisited_cases=32-n,causal_effect_cases=n,
      restored_by_one_toss_cases=n,source_modified=False,
      stage1_complete=False,stage2_started=False,records=rows)
def selftest():
    good=fixture()
    need(check(good),"clean synthetic Native wide evidence incorrectly rejected")
    attacks=(
       ("missing_case",lambda d:d["records"].pop()),
       ("wrong_large_magnitude",lambda d:d["records"][7]["input_fields"].__setitem__(1,12)),
       ("wrong_case_name",lambda d:d["records"][0].__setitem__("case","invalid")),
       ("fake_input_hash",lambda d:d["records"][4].__setitem__("input_sha256","0"*64)),
       ("changed_reference",lambda d:d["records"][0]["reference_output"].__setitem__(0,"9")),
       ("false_reach",lambda d:d["records"][0].__setitem__("literal_reached",True)),
       ("false_causality",lambda d:d["records"][0].__setitem__("causal_effect",True)),
       ("missed_immediate_restore",lambda d:d["records"][1]["zero_intervention"].__setitem__("restored_source_byte",48)),
       ("wrong_toss_rescue",lambda d:d["records"][1]["stack_rescue"]["actual_stack_rescue"].__setitem__("top_after","0")),
       ("invented_rescue",lambda d:d["records"][1]["stack_rescue"].__setitem__("repaired_toss_values",0)),
       ("missing_native_reference_run",lambda d:d.__setitem__("native_reference_executions",95)),
       ("false_stage_completion",lambda d:d.__setitem__("stage1_complete",True)),
    )
    for name,mutate in attacks:
        mutant=copy.deepcopy(good)
        mutate(mutant)
        try:check(mutant)
        except AssertionError:continue
        raise AssertionError("forged Native wide mediation accepted "+name)
    print("NATIVE_WIDE_LITERAL_MEDIATION_12_REPORT_FORGERIES_REJECT_PASS")
def main(directory):
    selftest()
    path=Path(directory)/"native_wide_literal_mediation_32.json"
    need(path.is_file(),"real Native wide mediation output absent")
    need(check(json.loads(path.read_text(encoding="utf8"))),
         "real Native wide mediation auditor rejected data")
    print("NATIVE_WIDE_FOUR_CELL_32_INPUT_192_EXECUTION_INDEPENDENT_AUDIT_PASS")
    print("STAGE1_OPEN; PRODUCTION_UNCHANGED")
if __name__=="__main__":
    if len(sys.argv)==1 or (len(sys.argv)==2 and sys.argv[1]=="--selftest"):selftest()
    else:
        need(len(sys.argv)==2,"usage: wide mediation AUDIT_DIR or --selftest")
        main(sys.argv[1])
