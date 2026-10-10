#!/usr/bin/env python3
"""Cross-audit TWO independent real Native BF98 artifacts, including no-u routes.
No calendar math, no generated paths, no production mutation, no Stage1 promotion.
Both input artifacts MUST come from producer jobs of this same GitHub run.
"""
import copy,hashlib,json,sys
from pathlib import Path
BLOB="560d6aa5807a7f766213a33835cce85eab0fa40c"
ALL=("zero_equal","foundation_cross","forward_short","reverse_short",
"mixed_small","positive_negative","negative_positive","large_values",
"invalid_zero_sign","invalid_big_sign","epoch_forward_one",
"epoch_reverse_one","recent_anchor_equal","recent_anchor_next",
"foundation_neighbor_forward","foundation_neighbor_reverse",
"invalid_target_zero_sign")
ALTERNATES=("foundation_cross","mixed_small","negative_positive",
"foundation_neighbor_forward","foundation_neighbor_reverse")
CAUSAL=(("foundation_cross",23083,23246,-2),
        ("mixed_small",11323,11486,-1),
        ("negative_positive",24763,24926,-1))
CELL=(37,1700)
def need(v,reason):
    if not v:raise AssertionError(reason)
def blob(raw):
    return hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest()
def native_trace(path,sha):
    raw=path.read_bytes()
    need(hashlib.sha256(raw).hexdigest()==sha,"real Native trace hash differs")
    step={};wrote={};read={};u=w=x=0;last=0
    for line in raw.splitlines():
        a=line.split(b"\t");tag=a[0].decode("ascii")
        need(tag in ("STEP","WRITE_BEFORE","WRITE_AFTER","READ_BEFORE","READ_AFTER"),
             "unsupported Native tracer event")
        n=tuple(int(k) for k in a[1:])
        if tag=="STEP":
            need(len(n)==8 and n[0]==last+1 and n[1]==1,
                 "Native IP step/tick or ownership missing")
            last=n[0];step[last]=(n[2],n[3],n[6])
            pos=step[last]
            u+=(pos==(954,1328,117))
            w+=(pos==(951,1332,119))
            x+=(pos==(950,1335,120))
        else:
            need(n[0]==last and last in step,
                 "Native g/p memory event not attached to step")
            tick,px,py=n[:3]
            if (px,py)!=CELL:continue
            if tag=="WRITE_BEFORE":
                if step[tick]!=(1249,1050,112):continue
                need(len(n)==5,"Native p write old/new values missing")
                wrote.setdefault(tick,{})["before"]=n[3:]
            elif tag=="WRITE_AFTER":
                if tick not in wrote:continue
                need(len(n)==4 and wrote[tick]["before"][1]==n[3],
                     "actual Native p did not write declared cell value")
                wrote[tick]["after"]=n[3]
            elif tag=="READ_BEFORE":
                if step[tick]!=(575,1164,103):continue
                need(len(n)==4,"actual g physical cell read malformed")
                read.setdefault(tick,{})["before"]=n[3]
            elif tag=="READ_AFTER":
                if tick not in read:continue
                need(len(n)==4 and read[tick]["before"]==n[3],
                     "Native g read values inconsistent")
                read[tick]["after"]=n[3]
    need(last>1000 and all("after" in q for q in wrote.values())
         and all("after" in q for q in read.values()),
         "incomplete native execution or p/g memory pair")
    for t,r in read.items():
        prior=[(k,q["after"]) for k,q in wrote.items() if k<t]
        need(prior and max(prior)[1]==r["after"],
             "Native g did not read most recent p-write value")
    return dict(steps=last,u=u,w=w,x=x,p=len(wrote),g=len(read),
      first_p=min(wrote) if wrote else None,
      first_g=min(read) if read else None,
      first_p_value=wrote[min(wrote)]["after"] if wrote else None,
      first_g_value=read[min(read)]["after"] if read else None)
def validate(r):
    need(r.get("schema")=="befunge-stage1-no-u-two-native-artifacts-v1"
         and r.get("source_git_blob")==BLOB
         and r.get("scope")=="FIVE_NO_U_VALID_THREE_PG_NUMERICAL_COUNTERFACTUALS"
         and r.get("full_native_trace_inputs")==17
         and r.get("no_u_valid_cases")==list(ALTERNATES)
         and r.get("real_numerical_alternate_causal_cases")==3
         and r.get("observational_only_valid_cases")==2
         and r.get("stage1_complete") is False
         and r.get("automatic_promotion") is False
         and r.get("full_functional_qa_pass") is False
         and r.get("geometric_spaghetti_qa_pass") is False,
         "cross-artifact source, proof scope, or Stage1 state forged")
    rows=r.get("traces")
    need(type(rows) is list and len(rows)==17
         and tuple(x.get("case") for x in rows)==ALL,
         "Native 17-case source corpus order/count changed")
    for row in rows:
        if row["case"] in ALTERNATES:
            need(row.get("valid") is True and row.get("u")==0
                 and row.get("w")==row.get("x")==1
                 and row.get("p",0)>=1 and row.get("g",0)>=1,
                 "Native alternate route lacks required executed physical ops")
    proofs=r.get("causal")
    need(type(proofs) is list and len(proofs)==3
         and tuple(q.get("case") for q in proofs)==tuple(c[0] for c in CAUSAL),
         "missing real Native no-u numerical causal evidence")
    for p,(name,wt,rt,val) in zip(proofs,CAUSAL):
        need(p.get("p_tick")==wt and p.get("g_tick")==rt and
             p.get("native_g_before")==val and p.get("native_g_mutant")==val+1
             and p.get("mutant_terminated_normally") is True
             and p.get("control_terminated_normally") is True
             and type(p.get("native_original_output")) is list
             and len(p["native_original_output"])==7
             and type(p.get("native_mutated_output")) is list
             and len(p["native_mutated_output"])==7
             and p["native_original_output"]!=p["native_mutated_output"],
             "Native p/g causal numeric output and physical provenance forged")
    return True
def main():
    need(len(sys.argv)==3,"usage: audit.py NATIVE_DIVERSE_DIR NATIVE_SCC_DIR")
    need(blob(Path("src/interleaved_work_counts.b98").read_bytes())==BLOB,
         "original Native BF98 production source changed")
    traces,mutations=map(Path,sys.argv[1:])
    manifest=json.loads((traces/"diverse_manifest.json").read_text("utf-8"))
    need(manifest.get("schema")=="befunge-stage1-diverse-native-v1"
         and len(manifest.get("cases",[]))==17
         and tuple(x.get("case") for x in manifest["cases"])==ALL,
         "trace artifact not authoritative seventeen native cases")
    rows=[]
    for rec in manifest["cases"]:
        name=rec["case"]
        need(rec.get("trace_file")==name+".tsv"
             and type(rec.get("valid")) is bool
             and type(rec.get("output")) is list
             and len(rec["output"])==7,
             "native manifest origin/outputs unpinned")
        observed=native_trace(traces/(name+".tsv"),rec["trace_sha256"])
        observed.update(case=name,valid=rec["valid"],
                        native_output=rec["output"],
                        trace_sha256=rec["trace_sha256"])
        rows.append(observed)
    no_u=tuple(x["case"] for x in rows if x["valid"] and x["u"]==0)
    need(no_u==ALTERNATES,"unexpected executed u branch families")
    for x in rows:
        if x["case"] in ALTERNATES:
            need(x["w"]==x["x"]==1 and x["p"]>=1 and x["g"]>=1,
                 "alternate actual numeric path lacks w/x and p/g")
    src=json.loads((mutations/"native_scc_g_interventions.json").read_text("utf-8"))
    original_audit=json.loads(
        (mutations/"native_scc_g_interventions_audit.json").read_text("utf-8"))
    need(src.get("schema")=="befunge-stage1-native-scc-live-g-intervention-v1"
         and src.get("source_git_blob")==BLOB
         and src.get("real_native_intervention_pairs")==9
         and src.get("real_native_program_executions")==18
         and src.get("stage1_geometry_acceptance") is False
         and src.get("stage1_functional_acceptance") is False
         and original_audit.get("stage1_completion") is False
         and len(original_audit.get("negative_reports_rejected",[]))==14,
         "original second Native artifact/auditor source missing")
    evidence={p["case"]:p for p in src["records"]}
    need(len(evidence)==9,"original g-intervention input set omitted")
    baseline={q["case"]:q for q in rows}
    proofs=[]
    for name,wt,rt,v in CAUSAL:
        s=evidence[name];n=baseline[name]
        c=s["control"];m=s["intervention"]
        need(n["u"]==0 and n["first_p"]==s["native_writer_tick"]==wt
             and n["first_g"]==s["native_reader_tick"]==rt and
             n["first_p_value"]==n["first_g_value"]==s["cell_before"]==v
             and s["cell_mutated"]==v+1 and rt-wt==163,
             "Native p->g chronology/value not confirmed by independent raw trace")
        need(c["status"]=="normal" and c["remaining_ips"]==0
             and m["status"]=="normal" and m["remaining_ips"]==0
             and c["output"]==s["expected_reference"]==n["native_output"]
             and m["output"]!=c["output"] and len(m["output"])==7
             and c["actual_g_return"]==v and m["actual_g_return"]==v+1
             and c["one_cell_intervention"] is False
             and m["one_cell_intervention"] is True
             and s["downstream_output_or_termination_changed"] is True,
             "real Native BF98 alternate g numeric causal outcome absent")
        proofs.append(dict(case=name,p_tick=wt,g_tick=rt,
          native_g_before=v,native_g_mutant=v+1,
          native_original_output=c["output"],native_mutated_output=m["output"],
          control_steps=c["steps"],mutant_steps=m["steps"],
          control_terminated_normally=True,mutant_terminated_normally=True))
    result=dict(schema="befunge-stage1-no-u-two-native-artifacts-v1",
      source_git_blob=BLOB,
      scope="FIVE_NO_U_VALID_THREE_PG_NUMERICAL_COUNTERFACTUALS",
      full_native_trace_inputs=17,no_u_valid_cases=list(ALTERNATES),
      real_numerical_alternate_causal_cases=3,observational_only_valid_cases=2,
      causal=proofs,traces=rows,stage1_complete=False,
      automatic_promotion=False,full_functional_qa_pass=False,
      geometric_spaghetti_qa_pass=False)
    validate(result)
    challenges=[
      ("stage",lambda d:d.__setitem__("stage1_complete",True)),
      ("source",lambda d:d.__setitem__("source_git_blob","0"*40)),
      ("missing_trace",lambda d:d["traces"].pop()),
      ("reorder",lambda d:d["traces"].reverse()),
      ("fake_u",lambda d:d["traces"][1].__setitem__("u",1)),
      ("fake_w",lambda d:d["traces"][1].__setitem__("w",0)),
      ("fake_g",lambda d:d["traces"][1].__setitem__("g",0)),
      ("missing_proof",lambda d:d["causal"].pop()),
      ("p_tick",lambda d:d["causal"][0].__setitem__("p_tick",0)),
      ("g_value",lambda d:d["causal"][0].__setitem__("native_g_mutant",42)),
      ("unchanged_output",lambda d:d["causal"][0].__setitem__(
          "native_mutated_output",d["causal"][0]["native_original_output"])),
      ("fake_termination",lambda d:d["causal"][0].__setitem__(
          "mutant_terminated_normally",False))]
    rejected=[]
    for name,mutate in challenges:
        falsified=copy.deepcopy(result);mutate(falsified)
        try:validate(falsified)
        except (AssertionError,KeyError,TypeError):rejected.append(name)
        else:raise AssertionError("forged Native no-u report accepted "+name)
    need(len(rejected)==12,"Native no-u hostile report tests incomplete")
    result["hostile_reports_rejected"]=rejected
    (traces/"native_no_u_cross_artifact_audit.json").write_text(
        json.dumps(result,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print("NATIVE_NO_U_FIVE_REAL_ALTERNATE_W_X_PG_PATHS_PASS")
    print("NATIVE_NO_U_THREE_INDEPENDENT_NUMERICAL_PG_COUNTERFACTUALS_PASS")
    print("NATIVE_NO_U_TWO_FOUNDATION_NEIGHBORS_OBSERVATIONAL_ONLY")
    print("NATIVE_NO_U_TWELVE_HOSTILE_REPORTS_REJECT_PASS")
    print("LAST_COMPLETED_STAGE=0 GEOMETRIC_SPAGHETTI_QA_PASS=NO")
if __name__=="__main__":main()
