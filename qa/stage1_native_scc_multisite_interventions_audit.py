#!/usr/bin/env python3
"""Fail-closed QA audit: 18 real Native p->g interventions at two extra SCC sites.

Original calendar output only from native Befunge-98 oracle and production,
never Python arithmetic. All asserted measurements are from Native programs.
"""
import copy
import hashlib
import json
import sys
from pathlib import Path

PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
CASES=(
    ("foundation_cross",True,23207,23287,0,23389,23669,-2),
    ("forward_short",True,11523,11603,2,11705,11985,3),
    ("reverse_short",True,11523,11603,1,11705,11985,3),
    ("mixed_small",True,11447,11527,1,11629,11909,0),
    ("positive_negative",True,24963,25043,-1,25145,25425,8),
    ("negative_positive",True,24887,24967,9,25069,25349,8),
    ("large_values",True,75363,75443,-7,75545,75825,1),
    ("recent_anchor_next",True,21603,21683,0,21785,22065,9),
    ("invalid_big_sign",False,13191,13271,0,13373,13653,0),
)
SITES=(
    ("cell41",[41,1701],[405,860],[749,290],80,2),
    ("cell43",[43,1702],[962,480],[958,1050],280,5),
)

def need(x,why):
    if not x:raise AssertionError(why)

def signature(row):
    return (row["status"],row["remaining_ips"],row["output"])

def verify(report):
    need(report.get("schema")=="befunge-stage1-native-scc-two-site-intervention-v1"
         and report.get("source_git_blob")==PIN
         and report.get("source_geometry_artifact_id")==11664135758
         and report.get("status")=="OBSERVED_NATIVE_DEPENDENCE_FINITE_CORPUS_STAGE1_OPEN"
         and report.get("new_distinct_cells")==2
         and report.get("native_live_program_executions")==36
         and report.get("native_control_mutant_pairs")==18
         and report.get("unique_input_cases")==9
         and report.get("valid_case_site_pairs")==16
         and report.get("invalid_case_site_pairs")==2
         and report.get("independent_native_oracle_invocations")==24
         and report.get("functional_acceptance") is False
         and report.get("geometric_acceptance") is False,
         "Native source/corpus/acceptance manifest forged")
    rows=report.get("records")
    need(isinstance(rows,list) and len(rows)==18,
         "expected exactly eighteen measured Native physical p/g pairs")
    summaries={}
    ref_by_label={}
    for i,row in enumerate(rows):
        site=SITES[i//9]
        label,valid,wt1,rt1,v1,wt2,rt2,v2=CASES[i%9]
        name,cell,writer,reader,spacing,idx=site
        wt,rt,val=(wt1,rt1,v1) if idx==2 else (wt2,rt2,v2)
        need(row.get("site")==name and row.get("case")==label
             and row.get("valid") is valid
             and row.get("physical_cell")==cell
             and row.get("physical_writer")==writer
             and row.get("physical_reader")==reader
             and row.get("native_writer_tick")==wt
             and row.get("native_reader_tick")==rt
             and rt-wt==spacing
             and row.get("cell_before")==val
             and row.get("cell_after")==val+1,
             "physical Native p/g cell, chronological read, or source-coordinate drift")
        fields=row.get("input_fields")
        refs=row.get("independent_native_oracle")
        need(isinstance(fields,list) and len(fields)==4
             and all(type(x) is int for x in fields)
             and isinstance(refs,list) and len(refs)==7
             and all(type(v) is str for v in refs)
             and (valid or refs==["-1"]*7),
             "valid/invalid Native oracle input or seven-field output malformed")
        if label in ref_by_label:
            need(ref_by_label[label]==(fields,refs),
                 "same Native calendar input changed between SCC sites")
        else:ref_by_label[label]=(fields,refs)
        sham=row.get("control")
        altered=row.get("intervention")
        need(isinstance(sham,dict) and isinstance(altered,dict),
             "Native Program result missing")
        for part,want,flag in ((sham,val,False),(altered,val+1,True)):
            need(type(part.get("steps")) is int and rt<=part["steps"]<=250001
                 and part.get("status") in ("normal","step_limit")
                 and type(part.get("remaining_ips")) is int
                 and part["remaining_ips"]>=0
                 and part.get("one_cell_intervention") is flag
                 and part.get("actual_g_return")==want
                 and part.get("writer_executed") is True
                 and part.get("reader_executed") is True
                 and isinstance(part.get("output"),list)
                 and all(type(x) is str for x in part["output"]),
                 "Native actual read/stack/termination evidence fabricated")
        need(sham["status"]=="normal"
             and sham["remaining_ips"]==0
             and sham["output"]==refs,
             "unmutated real Befunge outcome disagrees with independent oracle")
        effect=signature(sham)!=signature(altered)
        outcome=sham["output"]!=altered["output"]
        need(row.get("final_output_or_termination_changed") is effect
             and row.get("actual_output_changed") is outcome,
             "Native SCC final-output causal effect misreported")
        if name not in summaries:
            summaries[name]={"cases":0,"g_returns_changed":0,
                             "output_or_termination_changed":0,
                             "actual_output_changed":0}
        sums=summaries[name]
        sums["cases"]+=1
        sums["g_returns_changed"]+=sham["actual_g_return"]!=altered["actual_g_return"]
        sums["output_or_termination_changed"]+=effect
        sums["actual_output_changed"]+=outcome
    need(len(ref_by_label)==9
         and report.get("site_stats")==summaries
         and all(s["cases"]==9 and s["g_returns_changed"]==9
                 for s in summaries.values()),
         "Native two SCC-site causal statistics inconsistent with raw outcomes")
    return summaries

def main(folder):
    source=Path("src/interleaved_work_counts.b98").read_bytes()
    blob=hashlib.sha1(b"blob "+str(len(source)).encode("ascii")+
                      b"\0"+source).hexdigest()
    need(blob==PIN,"pinned Native Befunge source bytes changed")
    root=Path(folder)
    source_record=root/"native_scc_multisite_interventions.json"
    report=json.loads(source_record.read_text(encoding="utf-8"))
    sums=verify(report)
    print("NATIVE_SCC_TWO_SITE_INDEPENDENT_AUDIT_PASS",
          json.dumps(sums,sort_keys=True))
    attacks=[]
    def reject(label,change):
        falsified=copy.deepcopy(report)
        change(falsified)
        try:verify(falsified)
        except AssertionError:
            attacks.append(label)
            print("NATIVE_TWO_SITE_TAMPER_REJECT_PASS",label)
            return
        raise AssertionError("forged Native SCC report passed: "+label)
    reject("wrong_source",lambda d:d.__setitem__("source_git_blob","0"*40))
    reject("lost_record",lambda d:d["records"].pop())
    reject("swapped_case",lambda d:d["records"][0].__setitem__("case","forward_short"))
    reject("wrong_site",lambda d:d["records"][0].__setitem__("site","cell43"))
    reject("wrong_cell",lambda d:d["records"][0].__setitem__("physical_cell",[40,1701]))
    reject("wrong_writer",lambda d:d["records"][0].__setitem__("physical_writer",[406,860]))
    reject("wrong_reader",lambda d:d["records"][0].__setitem__("physical_reader",[749,291]))
    reject("wrong_write_tick",lambda d:d["records"][0].__setitem__("native_writer_tick",23208))
    reject("wrong_read_tick",lambda d:d["records"][0].__setitem__("native_reader_tick",23288))
    reject("unchanged_g",lambda d:d["records"][0]["intervention"].__setitem__("actual_g_return",0))
    reject("falsified_sham",lambda d:d["records"][0]["control"]["output"].__setitem__(0,"fake"))
    reject("falsified_oracle",lambda d:d["records"][0]["independent_native_oracle"].__setitem__(0,"fake"))
    reject("false_effect",lambda d:d["records"][0].__setitem__(
        "final_output_or_termination_changed",
        not d["records"][0]["final_output_or_termination_changed"]))
    reject("false_output_effect",lambda d:d["records"][0].__setitem__(
        "actual_output_changed",not d["records"][0]["actual_output_changed"]))
    reject("wrong_site_totals",lambda d:d["site_stats"]["cell43"].__setitem__("actual_output_changed",-1))
    reject("wrong_native_program_count",lambda d:d.__setitem__("native_live_program_executions",35))
    reject("premature_geometric_gate",lambda d:d.__setitem__("geometric_acceptance",True))
    reject("premature_functional_gate",lambda d:d.__setitem__("functional_acceptance",True))
    need(len(attacks)==18,"Native SCC two-site hostile reports incomplete")
    out={"schema":"befunge-stage1-native-scc-two-site-intervention-audit-v1",
         "audited":sums,"hostile_reports_rejected":attacks,
         "full_geometric_acceptance":False,"last_completed_stage":0}
    (root/"native_scc_multisite_interventions_audit.json").write_text(
         json.dumps(out,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_SCC_TWO_SITE_EIGHTEEN_TAMPER_REPORTS_REJECTED_PASS")

if __name__=="__main__":
    need(len(sys.argv)==2,"usage: Native SCC two-site intervention artifact dir")
    main(sys.argv[1])
