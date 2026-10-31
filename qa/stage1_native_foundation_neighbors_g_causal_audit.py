#!/usr/bin/env python3
"""Independent fail-closed audit of two Native BF98 Foundation-neighbor g tests."""
import copy,hashlib,json,sys
from pathlib import Path
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
CASES=(("foundation_neighbor_forward",-1),
       ("foundation_neighbor_reverse",0))
def need(v,why):
    if not v:raise AssertionError(why)
def verify(d):
    need(type(d) is dict and
         d.get("schema")=="befunge-stage1-foundation-neighbors-native-g-causal-v1"
         and d.get("scope")=="TWO_PREVIOUSLY_OBSERVATIONAL_NO_U_FOUNDATION_NEIGHBORS"
         and d.get("source_git_blob")==PIN
         and d.get("physical_cell")==[37,1700]
         and d.get("writer_site")==[1249,1050]
         and d.get("reader_site")==[575,1164]
         and d.get("native_executions")==4
         and d.get("independent_native_reference_cases")==2
         and d.get("native_counterfactual_pairs")==2
         and d.get("stage1_complete") is False
         and d.get("full_functional_qa_pass") is False
         and d.get("geometric_spaghetti_qa_pass") is False
         and d.get("production_modified") is False,
         "Foundation neighbor Native source or limited acceptance forged")
    r=d.get("records")
    need(type(r) is list and len(r)==2,"native two valid neighbors not covered")
    counted=0
    for x,(name,want) in zip(r,CASES):
        control=x.get("original");test=x.get("counterfactual")
        ref=x.get("reference_7")
        need(x.get("case")==name and
             type(x.get("fields")) is list
             and len(x["fields"])==4
             and all(type(v) is str and v.isdigit() for v in x["fields"])
             and x.get("writer_tick")==23083
             and x.get("reader_tick")==23246
             and x.get("written")==want
             and x.get("mutated_read")==want+1
             and type(ref) is list and len(ref)==7
             and all(type(y) is str and y.lstrip("-").isdigit() for y in ref)
             and type(control) is dict and type(test) is dict,
             "native Foundation legal reference or physical p/g pin changed")
        for run,v,is_mutant in ((control,want,False),(test,want+1,True)):
            need(run.get("actual_g_return")==v
                 and run.get("writer_executed") is True
                 and run.get("reader_executed") is True
                 and run.get("one_cell_intervention") is is_mutant
                 and type(run.get("steps")) is int
                 and 23246<=run["steps"]<=250001
                 and run.get("status") in ("normal","step_limit")
                 and type(run.get("remaining_ips")) is int
                 and type(run.get("output")) is list,
                 "real original Native p-write/g-read was not executed")
        need(control["status"]=="normal"
             and control["remaining_ips"]==0
             and control["output"]==ref
             and x.get("output_or_termination_changed") is
                 ((test["status"],test["remaining_ips"],test["output"])!=
                  (control["status"],control["remaining_ips"],control["output"])),
             "real Native signed-day output changed in sham or forged effect")
        changed=(test["status"]=="normal"
                 and test["remaining_ips"]==0
                 and len(test["output"])==7
                 and test["output"]!=ref)
        need(x.get("normal_seven_field_numeric_change") is changed,
             "numeric counterfactual effect not actually observed")
        counted+=int(changed)
    return counted
def main(path):
    source=Path("src/interleaved_work_counts.b98").read_bytes()
    need(hashlib.sha1(b"blob "+str(len(source)).encode()+b"\0"+source).hexdigest()==PIN,
         "original BF98 production source drift")
    root=Path(path)
    data=json.loads((root/"native_foundation_neighbor_g_causal.json").read_text("utf-8"))
    effects=verify(data)
    attacks=[
      ("source",lambda x:x.__setitem__("source_git_blob","0"*40)),
      ("fake_stage",lambda x:x.__setitem__("stage1_complete",True)),
      ("drop",lambda x:x["records"].pop()),
      ("case",lambda x:x["records"][0].__setitem__("case","FAKE")),
      ("g_target",lambda x:x.__setitem__("physical_cell",[38,1700])),
      ("write_tick",lambda x:x["records"][0].__setitem__("writer_tick",5)),
      ("read_tick",lambda x:x["records"][0].__setitem__("reader_tick",4)),
      ("baseline",lambda x:x["records"][0]["original"].__setitem__("output",["-1"]*7)),
      ("fake_read",lambda x:x["records"][0]["counterfactual"].__setitem__("actual_g_return",999)),
      ("fake_changed",lambda x:x["records"][0].__setitem__("normal_seven_field_numeric_change",
               not x["records"][0]["normal_seven_field_numeric_change"])),
      ("wrong_status",lambda x:x["records"][0]["original"].__setitem__("status","step_limit")),
      ("fake_scope",lambda x:x.__setitem__("geometric_spaghetti_qa_pass",True))]
    rejected=[]
    for label,attack in attacks:
        test=copy.deepcopy(data);attack(test)
        try:verify(test)
        except (AssertionError,KeyError,TypeError):rejected.append(label)
        else:raise AssertionError("forged Native Foundation neighbor accepted "+label)
    need(len(rejected)==12,"missing Native neighbor anti-tamper cases")
    report={"schema":"befunge-stage1-foundation-neighbor-g-causal-audit-v1",
            "native_programs":4,"independent_native_references":2,
            "valid_neighbors_with_changed_seven_field_numeric_output":effects,
            "falsified_reports_rejected":rejected,
            "stage1_complete":False,"geometric_spaghetti_qa_pass":False}
    (root/"native_foundation_neighbor_g_causal_audit.json").write_text(
        json.dumps(report,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print("NATIVE_BF98_TWO_FOUNDATION_G_NUMERIC_CAUSAL_AUDIT_PASS",
          "numerically_changed",effects,"of",2)
    print("NATIVE_BF98_TWO_FOUNDATION_TWELVE_FORGED_REPORTS_REJECT_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"Native Foundation neighbor evidence dir required")
    main(sys.argv[1])
