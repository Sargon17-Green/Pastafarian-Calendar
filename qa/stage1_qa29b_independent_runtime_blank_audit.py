#!/usr/bin/env python3
"""QA29B independent receipt auditor for original PyFunge runtime blank snapshots.

Checks original QA20 Native manifest, QA28 signed full-state triads, original
source bytes, replay invariants and scoped live FungeSpace get/put evidence.
Cannot independently inspect a different runtime or prove no other mutation API.
"""
import argparse
import copy
import hashlib
import json
from pathlib import Path

SOURCE_BLOB="560d6aa5807a7f766213a33835cce85eab0fa40c"
QA20_MANIFEST_SHA="782fb868a11a105550ef5af6f8f7cd39e4ba9de77d9565f7549e310549b0073a"
QA28_RECEIPT_SHA="c5a5beaab308df31222652484e5fb18af554bf75e7b492225b107197fb29aa6e"
TARGETS={(113,32):(112,29),(199,35):(198,38)}

def need(ok,msg):
    if not ok:raise AssertionError(msg)

def sha(b):
    return hashlib.sha256(b).hexdigest()

def pinned_json(path,digest):
    b=Path(path).read_bytes()
    need(sha(b)==digest,"signed original Native source data SHA-256 changed")
    return json.loads(b)

def signed_source(path):
    b=Path(path).read_bytes()
    blob=hashlib.sha1(b"blob "+str(len(b)).encode("ascii")+b"\0"+b).hexdigest()
    need(blob==SOURCE_BLOB,"original source blob changed")
    return b.splitlines()

def validate(row,original,qa28,source):
    need(row.get("schema")=="qa29b-original-native-two-runtime-blank-corridors-v1"
         and row.get("original_source_git_blob")==SOURCE_BLOB
         and row.get("original_qa20_shard0_manifest_sha256")==QA20_MANIFEST_SHA
         and row.get("original_qa28_receipt_sha256")==QA28_RECEIPT_SHA
         and row.get("qa20_original_run")==39761821210
         and row.get("qa28_original_run")==39985923985
         and row.get("new_native_program_executions")==1
         and row.get("native_input_label")=="valid00"
         and row.get("full_original_native_step_replay") is True
         and row.get("original_native_full_steps")==original["steps"]
         and row.get("original_native_trace_compressed_sha256")==original["compressed_trace_sha256"]
         and row.get("original_native_output")==original["output"]
         and row.get("full_program_native_ip_relocated") is False
         and row.get("production_source_modified") is False
         and row.get("proof_scoped_to_recorded_fungespace_get_and_put") is True
         and row.get("alternative_interpreter_mutation_apis_globally_ruled_out") is False
         and row.get("all_input_global_blank_or_dead_code_proven") is False
         and row.get("stage1_complete") is False,
         "falsified original Native provenance or unsupported global claim")
    writes=row.get("all_corridor_put_events")
    shots=row.get("two_signed_native_blank_corridor_runtime_snapshots")
    need(type(writes) is list and type(shots) is list and len(shots)==2,
         "missing real Native skip snapshots or puts")
    need(type(row.get("actual_program_fungespace_put_calls")) is int
         and row["actual_program_fungespace_put_calls"]>=len(writes),
         "instrumented put count missing")
    witness={tuple(r["target"]):r for r in qa28["records"] if tuple(r["target"]) in TARGETS}
    need(set(witness)==set(TARGETS),
         "one of the two original signed QA28 blank-skip witnesses missing")
    observed=set()
    for snapshot in shots:
        target=tuple(snapshot["target"])
        need(target in TARGETS and target not in observed,
             "duplicate or unexpected Native blank corridor")
        observed.add(target)
        w=witness[target]
        anchor=w["nearest_native_step"];nxt=w["successor_native_step"]
        x,y=TARGETS[target]
        coords=[[k,y] for k in range(x+1,x+8)]
        need(snapshot.get("original_anchor_tick")==anchor[0]
             and snapshot.get("anchor")==anchor
             and snapshot.get("successor")==nxt
             and snapshot.get("corridor_cells")==coords
             and snapshot.get("live_memory_before_instruction")==[32]*7
             and snapshot.get("live_memory_after_instruction")==[32]*7
             and snapshot.get("put_calls_to_corridors_during_tick")==0
             and snapshot.get("state_read_from_actual_native_fungespace") is True,
             "original signed skip physical memory data altered")
        need(anchor[1:3]==[x,y] and anchor[5]==ord("-")
             and nxt[1:3]==[x+8,y]
             and all(source[y][k]==32 for k in range(x+1,x+8)),
             "seven original source space bytes missing")
        count=sum(wr.get("tick",0)<anchor[0]
                  for wr in writes)
        need(snapshot["put_calls_to_corridors_before_tick"]==count,
             "chronological Native corridor write count falsified")
        need(not any(wr.get("tick")==anchor[0] for wr in writes),
             "Native minus instruction wrote into the corridor")
    need(observed==set(TARGETS),"not all original Native corridors verified")
    for wr in writes:
        coord=wr.get("coord")
        need(type(coord) is list and tuple(coord) in
             {(i,y) for x,y in TARGETS.values() for i in range(x+1,x+8)}
             and type(wr.get("tick")) is int and 1<=wr["tick"]<=original["steps"]
             and type(wr.get("before")) is int and type(wr.get("after")) is int,
             "forged Native physical write event")

def controls(data,original,qa28,source):
    attack=[
      ("unpin-source",lambda t:t.__setitem__("original_source_git_blob","0"*40)),
      ("fake-completion",lambda t:t.__setitem__("stage1_complete",True)),
      ("fake-output",lambda t:t.__setitem__("original_native_output",["1"]*7)),
      ("fake-steps",lambda t:t.__setitem__("original_native_full_steps",1)),
      ("missing-snapshot",lambda t:t["two_signed_native_blank_corridor_runtime_snapshots"].pop()),
      ("incorrect-anchor",lambda t:t["two_signed_native_blank_corridor_runtime_snapshots"][0].__setitem__("original_anchor_tick",1)),
      ("corrupt-live-before",lambda t:t["two_signed_native_blank_corridor_runtime_snapshots"][0]["live_memory_before_instruction"].__setitem__(0,33)),
      ("corrupt-live-after",lambda t:t["two_signed_native_blank_corridor_runtime_snapshots"][1]["live_memory_after_instruction"].__setitem__(0,33)),
      ("changed-corridor-coordinate",lambda t:t["two_signed_native_blank_corridor_runtime_snapshots"][0]["corridor_cells"][0].__setitem__(0,999)),
      ("fake-other-mutation-apis",lambda t:t.__setitem__("alternative_interpreter_mutation_apis_globally_ruled_out",True)),
      ("forge-source-modification",lambda t:t.__setitem__("production_source_modified",True)),
      ("pretend-global-dead-code",lambda t:t.__setitem__("all_input_global_blank_or_dead_code_proven",True))]
    for label,fn in attack:
        x=copy.deepcopy(data);fn(x)
        try:validate(x,original,qa28,source)
        except (AssertionError,IndexError,KeyError,TypeError):pass
        else:raise AssertionError("QA29B mutated Native physical provenance accepted "+label)
    return len(attack)

def main():
    pa=argparse.ArgumentParser()
    pa.add_argument("--source",required=True)
    pa.add_argument("--qa20",required=True)
    pa.add_argument("--qa28",required=True)
    pa.add_argument("--native",required=True)
    pa.add_argument("--output",required=True)
    args=pa.parse_args()
    source=signed_source(args.source)
    qa20=pinned_json(args.qa20,QA20_MANIFEST_SHA)
    qa28=pinned_json(args.qa28,QA28_RECEIPT_SHA)
    original=next(x for x in qa20["records"] if x["label"]=="valid00")
    need(original["raw_input"]=="0 0 0 0\n" and original["output"]==original["expected"]
         and qa20["source_git_blob"]==SOURCE_BLOB
         and qa20["shard"]==0 and qa20["stage1_final_acceptance"] is False,
         "original QA20 Native input or source evidence invalid")
    data=json.loads(Path(args.native).read_bytes())
    validate(data,original,qa28,source)
    count=controls(data,original,qa28,source)
    need(count==12,"missing QA29B adversarial provenance controls")
    out={"schema":"qa29b-finite-live-memory-scoped-audit-v1",
         "original_source_blob":SOURCE_BLOB,
         "original_native_full_steps":original["steps"],
         "qa29b_live_blank_corridors":len(data["two_signed_native_blank_corridor_runtime_snapshots"]),
         "original_candidate_put_events":len(data["all_corridor_put_events"]),
         "put_calls_during_both_exact_native_minus_steps":0,
         "adversarial_receipt_controls_rejected":count,
         "global_unreachability_or_memory_api_completeness_proven":False,
         "stage1_complete":False}
    Path(args.output).write_text(json.dumps(out,indent=2,sort_keys=True)+"\n")
    print("QA29B_INDEPENDENT_TWO_NATIVE_RUNTIME_BLANK_CORRIDORS_AUDITED")
    print("QA29B_TWELVE_FORGED_NATIVE_MEMORY_RECEIPTS_REJECTED")
    print("QA29B_SOURCE_DEADNESS_AND_GLOBAL_MEMORY_STILL_UNPROVEN")

if __name__=="__main__":
    main()
