#!/usr/bin/env python3
"""Independent 49-case complete post-| Native lifecycle and geometry audit.

Replays every executed opcode against source bytes and intervening physical
p writes via a previously independently tested full-route validator.
Does NOT infer numerical calendar values or universal Stage-1 completion.
"""
import copy,hashlib,json,re,sys
from pathlib import Path
import stage1_native_four_cell_full_postfork_trace_audit as full
from stage1_native_strict_evidence_json import strict_evidence_loads

BASE="560d6aa5807a7f766213a33835cce85eab0fa40c"
CAND="d965ce4bdfa282f2d3b82690808def5a2dde10a8"
DOM=tuple(range(-3,4))
DIGEST=re.compile(r"[a-f0-9]{64}\Z")
DECIMAL=re.compile(r"(?:0|-?[1-9][0-9]*)\Z")
def need(ok,why):
    if not ok:raise AssertionError(why)
def roster():
    return [(x,y,(int(x<0),abs(x),int(y<0),abs(y)))
            for x in DOM for y in DOM]
def valid_output(a):
    return type(a) is list and len(a)==7 and all(
        type(z) is str and DECIMAL.fullmatch(z) for z in a)
def verify_index(doc):
    need(type(doc) is dict and
         doc.get("schema")=="befunge-stage1-four-cell-49-complete-native-postfork-v2" and
         doc.get("status")=="FINITE_49_COMPLETE_NATIVE_TRAJECTORIES_STAGE1_OPEN" and
         doc.get("base_git_blob")==BASE and doc.get("candidate_git_blob")==CAND and
         doc.get("signed_domain")==list(DOM) and
         doc.get("original_native_candidate_executions")==49 and
         doc.get("independent_native_reference_executions")==147 and
         doc.get("native_processes_total")==196 and
         doc.get("lower_literal_reached")==21 and
         doc.get("upper_literal_not_reached")==28 and
         doc.get("candidate_source_modified_in_repository") is False and
         doc.get("stage1_complete") is False and doc.get("stage2_started") is False,
         "Native signed-grid full-route scope/source provenance drift")
    entries=doc.get("records")
    need(type(entries) is list and len(entries)==49,
         "complete 49-case Native route manifest incomplete")
    for i,(row,(dc,dt,fields)) in enumerate(zip(entries,roster())):
        raw=" ".join(map(str,fields))+"\n"
        need(type(row) is dict and row.get("index")==i and
             row.get("signed_days")==[dc,dt] and
             row.get("fields")==list(fields) and
             row.get("trace_filename")=="pair_%02d.json"%i and
             type(row.get("trace_file_sha256")) is str and
             DIGEST.fullmatch(row["trace_file_sha256"]) and
             type(row.get("native_steps")) is int and row["native_steps"]>0 and
             type(row.get("fork_step")) is int and row["fork_step"]>0 and
             type(row.get("complete_postfork_steps")) is int and
             row["complete_postfork_steps"]>512 and
             type(row.get("complete_prefork_steps")) is int and
             row["complete_prefork_steps"]==row["fork_step"] and
             row["complete_prefork_steps"]+row["complete_postfork_steps"]==row["native_steps"] and
             type(row.get("literal_executions")) is int and
             (row["literal_executions"]>0)==(dc<0) and
             type(row.get("p_writes")) is int and row["p_writes"]>=0 and
             type(row.get("g_reads")) is int and row["g_reads"]>=0 and
             valid_output(row.get("reference_output")) and
             row.get("input_sha256")==hashlib.sha256(raw.encode("ascii")).hexdigest(),
             "Native complete-route roster, input, first-literal or case hash drift")
    need(sum(int(z["literal_executions"]>0) for z in entries)==21,
         "observed lower route case total no longer pinned")
    return True
def fixture():
    rows=[]
    for i,(dc,dt,fields) in enumerate(roster()):
        raw=" ".join(map(str,fields))+"\n"
        rows.append(dict(index=i,signed_days=[dc,dt],fields=list(fields),
          trace_filename="pair_%02d.json"%i,trace_file_sha256="a"*64,
          native_steps=19000,fork_step=11000,complete_prefork_steps=11000,complete_postfork_steps=8000,
          literal_executions=int(dc<0),p_writes=1,g_reads=1,
          reference_output=["0"]*7,
          input_sha256=hashlib.sha256(raw.encode("ascii")).hexdigest()))
    return dict(schema="befunge-stage1-four-cell-49-complete-native-postfork-v2",
       status="FINITE_49_COMPLETE_NATIVE_TRAJECTORIES_STAGE1_OPEN",
       base_git_blob=BASE,candidate_git_blob=CAND,signed_domain=list(DOM),
       original_native_candidate_executions=49,
       independent_native_reference_executions=147,
       native_processes_total=196,lower_literal_reached=21,
       upper_literal_not_reached=28,
       candidate_source_modified_in_repository=False,
       stage1_complete=False,stage2_started=False,records=rows)
def selftest():
    good=fixture()
    need(verify_index(good),"clean synthetic Native index rejected")
    attacks=(
      ("missing_pair",lambda d:d["records"].pop()),
      ("wrong_signed_day",lambda d:d["records"][0].__setitem__("signed_days",[2,2])),
      ("wrong_index",lambda d:d["records"][10].__setitem__("index",50)),
      ("malformed_native_hash",lambda d:d["records"][2].__setitem__("trace_file_sha256","0"*63)),
      ("boolean_native_steps",lambda d:d["records"][2].__setitem__("native_steps",True)),
      ("fractional_fork_step",lambda d:d["records"][2].__setitem__("fork_step",1.5)),
      ("missing_prefork_count",lambda d:d["records"][2].pop("complete_prefork_steps")),
      ("forged_prefork_count",lambda d:d["records"][2].__setitem__("complete_prefork_steps",11001)),
      ("changed_input",lambda d:d["records"][0]["fields"].__setitem__(3,99)),
      ("invented_lower_route",lambda d:d["records"][25].__setitem__("literal_executions",2)),
      ("erased_lower_route",lambda d:d["records"][0].__setitem__("literal_executions",0)),
      ("less_than_full_trace",lambda d:d["records"][0].__setitem__("complete_postfork_steps",64)),
      ("missing_native_reference",lambda d:d.__setitem__("independent_native_reference_executions",146)),
      ("altered_candidate",lambda d:d.__setitem__("candidate_git_blob","0"*40)),
      ("wrong_numerical_arity",lambda d:d["records"][0]["reference_output"].pop()),
      ("falsely_completed_stage1",lambda d:d.__setitem__("stage1_complete",True)),
    )
    for name,mutate in attacks:
        bad=copy.deepcopy(good)
        mutate(bad)
        try:verify_index(bad)
        except AssertionError:continue
        raise AssertionError("full Native manifest forgery accepted: "+name)
    print("NATIVE_49_FULL_POSTFORK_MANIFEST_16_FALSIFICATIONS_REJECT_PASS")
def main(root):
    selftest()
    path=Path(root)
    raw=(path/"four_cell_candidate.b98").read_bytes()
    need(full.gitblob(raw)==CAND,
         "four-cell complete-route physical program identity drifted")
    source=raw.split(b"\n")
    data=strict_evidence_loads((path/"native_full_postfork_signed_grid_49.json")
                    .read_text(encoding="utf-8"))
    need(verify_index(data),"Native 49-case manifest disagrees with frozen roster")
    measured=[]
    for row in data["records"]:
        payload=(path/row["trace_filename"]).read_bytes()
        need(hashlib.sha256(payload).hexdigest()==row["trace_file_sha256"],
             "Native 49-case route file changed: "+row["trace_filename"])
        case=strict_evidence_loads(payload.decode("ascii"))
        need(type(case) is dict and case.get("index")==row["index"] and
             case.get("signed_days")==row["signed_days"] and
             case.get("fields")==row["fields"] and
             case.get("input_sha256")==row["input_sha256"] and
             case.get("reference_output")==row["reference_output"],
             "Native complete route and signed input receipt disagree")
        run=case.get("run")
        need(type(run) is dict and
             run.get("status")=="normal" and run.get("remaining_ips")==0 and
             run.get("output")==row["reference_output"] and
             run.get("steps")==row["native_steps"] and
             run.get("gate",{}).get("step")==row["fork_step"] and
             run.get("total_p_writes")==row["p_writes"] and
             run.get("total_g_reads")==row["g_reads"] and
             len(run.get("complete_postfork_trace",[]))==row["complete_postfork_steps"] and
             len(run.get("complete_prefork_trace",[]))==row["complete_prefork_steps"],
             "Native full-route meta, oracle, physical p/g event totals drifted")
        rec=full.verify_run(run,source,require_prefork=True,require_gate_anchor=True)
        lit=sum(int((z[1],z[2])==(951,1337) and
                    z[5]==49 and z[6]==0) for z in run["complete_postfork_trace"])
        need(lit==row["literal_executions"],
             "Native actual executed lower literal differs from route index")
        measured.append(dict(
          signed_days=row["signed_days"],
          complete_postfork_events=rec["complete_postfork_events"],
          verified_prefork_executed_steps=rec["verified_prefork_executed_steps"],
          unique_directed_nodes=rec["unique_directed_nodes"],
          unique_directed_edges=rec["unique_edges"],
          physical_p_writes=rec["verified_p_writes"],
          physical_g_reads=rec["verified_g_reads"],
          executed_p_modified_cells=rec["executed_modified_code_byte_events"],
          complete_path_sha256=rec["complete_trace_sha256"]))
        print("NATIVE_49_FULL_POSTFORK_PHYSICAL_SOURCE_REPLAY_PASS",
              row["index"]+1,"/49",row["signed_days"],
              "executed",rec["complete_postfork_events"])
        sys.stdout.flush()
    # Challenge *actual saved trajectory* against three independent
    # byte/version/time invariants, not only the index fields.
    first=strict_evidence_loads((path/data["records"][0]["trace_filename"]).read_text("ascii"))
    run=first["run"]
    bad=[
      ("forged_step",lambda r:r["complete_postfork_trace"][100].__setitem__(0,0)),
      ("forged_opcode",lambda r:r["complete_postfork_trace"][100].__setitem__(5,999)),
      ("truncated_trajectory",lambda r:r["complete_postfork_trace"].pop()),
    ]
    for name,mutator in bad:
        altered=copy.deepcopy(run)
        mutator(altered)
        try:full.verify_run(altered,source,require_prefork=True,require_gate_anchor=True)
        except AssertionError:pass
        else:raise AssertionError("forged actual Native full route accepted "+name)
    summary=dict(
      schema="befunge-stage1-four-cell-49-native-full-postfork-audit-v1",
      status="FINITE_QA_ONLY_STAGE1_ACCEPTANCE_OPEN",
      base_git_blob=BASE,candidate_git_blob=CAND,
      complete_native_trajectories=49,
      independent_native_reference_executions=147,
      literal_reached_trajectories=21,
      literal_unreached_trajectories=28,
      complete_prefork_instructions=sum(x["verified_prefork_executed_steps"] for x in measured),
      complete_postfork_instructions=sum(x["complete_postfork_events"]
                                        for x in measured),
      total_replayed_native_p_writes=sum(x["physical_p_writes"] for x in measured),
      total_replayed_native_g_reads=sum(x["physical_g_reads"] for x in measured),
      adversarial_manifest_reports_rejected=16,
      adversarial_actual_trajectories_rejected=3,
      stage1_complete=False,stage2_started=False,
      records=measured)
    (path/"independent_full_postfork_signed_grid_audit.json").write_text(
        json.dumps(summary,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print("NATIVE_49_COMPLETE_POSTFORK_DYNAMIC_PG_SOURCE_REPLAY_PASS",
          "total_native_steps",summary["complete_postfork_instructions"])
    print("NATIVE_49_FULL_POSTFORK_THREE_ACTUAL_TRACE_FALSIFICATIONS_REJECT_PASS")
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO; LAST_COMPLETED_STAGE=0")
if __name__=="__main__":
    if len(sys.argv)==2 and sys.argv[1]=="--selftest":selftest()
    else:
        need(len(sys.argv)==2,"usage: postfork49 audit --selftest or artifact folder")
        main(sys.argv[1])
