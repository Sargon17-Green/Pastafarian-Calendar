#!/usr/bin/env python3
"""Independent fail-closed check of Native SCC physical p->g intervention."""
import copy,hashlib,json,sys
from pathlib import Path
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
ROWS=(("forward_short",1,11399,11562),
      ("mixed_small",-1,11323,11486),
      ("foundation_cross",-2,23083,23246))
def need(x,m):
    if not x:raise AssertionError(m)
def check(d):
    need(d.get("schema")=="befunge-stage1-scc-real-pg-causal-v1"
         and d.get("source_git_blob")==PIN and d.get("qa_only") is True
         and d.get("last_completed_stage")==0 and
         d.get("stage1_complete") is False
         and d.get("native_executions")==6 and
         d.get("read_cell")==[37,1700]
         and d.get("p_site")==[1249,1050]
         and d.get("g_site")==[575,1164],
         "SCC Native source identity or Stage1 scope forged")
    r=d.get("records")
    need(type(r) is list and len(r)==3,"Native SCC three cases missing")
    changed=0
    for row,(name,val,p_tick,g_tick) in zip(r,ROWS):
        a=row.get("control");b=row.get("mutant");ref=row.get("reference_7")
        need(row.get("case")==name and type(a) is dict and type(b) is dict
             and type(ref) is list and len(ref)==7
             and a.get("status")=="normal" and a.get("remaining_ips")==0
             and a.get("output")==ref and b.get("status") in ("normal","step-limit")
             and type(b.get("steps")) is int and b["steps"]>=g_tick,
             "Native BF98 independent reference or execution drift")
        for run,return_val,injected in ((a,val,False),(b,val+1,True)):
            t=run.get("read")
            need(type(t) is dict and t.get("p_tick")==p_tick
                 and t.get("g_tick")==g_tick and t.get("written")==val
                 and t.get("returned")==return_val
                 and t.get("injected") is injected and
                 t.get("physical_cell")==[37,1700],
                 "real physical Native p/g causal read forgery")
        is_changed=b["status"]!="normal" or b["remaining_ips"]!=0 or b["output"]!=ref
        need(row.get("final_effect") is is_changed,
             "Native intervention output-effect claim forged")
        changed+=is_changed
    need(d.get("causal_effect_pairs")==changed,"causal effects count forged")
    return changed
def main(folder):
    source=Path("src/interleaved_work_counts.b98").read_bytes()
    need(hashlib.sha1(b"blob "+str(len(source)).encode()+b"\0"+source).hexdigest()==PIN,
         "Native production source changed")
    root=Path(folder)
    d=json.loads((root/"native_scc_real_pg_causal.json").read_text("utf-8"))
    observed=check(d)
    trials=[
        ("stage",lambda x:x.__setitem__("stage1_complete",True)),
        ("identity",lambda x:x.__setitem__("source_git_blob","0"*40)),
        ("missing",lambda x:x["records"].pop()),
        ("case",lambda x:x["records"][0].__setitem__("case","FAKE")),
        ("oracle",lambda x:x["records"][0]["control"].__setitem__("output",["-1"]*7)),
        ("writer",lambda x:x["records"][0]["control"]["read"].__setitem__("p_tick",0)),
        ("reader",lambda x:x["records"][0]["control"]["read"].__setitem__("g_tick",0)),
        ("returned",lambda x:x["records"][0]["mutant"]["read"].__setitem__("returned",-99)),
        ("injected",lambda x:x["records"][0]["mutant"]["read"].__setitem__("injected",False)),
        ("effect",lambda x:x["records"][0].__setitem__("final_effect",
                  not x["records"][0]["final_effect"]))]
    rejected=[]
    for name,mutate in trials:
        forged=copy.deepcopy(d);mutate(forged)
        try:check(forged)
        except (AssertionError,KeyError,TypeError):rejected.append(name)
        else:raise AssertionError("SCC forged causal report accepted "+name)
    need(len(rejected)==10,"Native SCC hostile evidence incomplete")
    out={"schema":"befunge-stage1-scc-real-pg-causal-independent-audit-v1",
         "native_programs":6,"causal_effect_pairs":observed,
         "forged_evidence_rejected":rejected,
         "stage1_complete":False,"geometric_spaghetti_qa_pass":False}
    (root/"native_scc_real_pg_causal_audit.json").write_text(
        json.dumps(out,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print("NATIVE_SCC_PHYSICAL_READ_CAUSAL_AUDIT_PASS",observed,"of",3)
    print("NATIVE_SCC_TEN_FALSIFIED_REPORTS_REJECT_PASS")
if __name__=="__main__":
    need(len(sys.argv)==2,"SCC causal evidence directory required")
    main(sys.argv[1])
