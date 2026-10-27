#!/usr/bin/env python3
"""Independent QA30B verification of full raw STEP parity and FungeSpace provenance.

No Python calendar oracle, no instruction-pointer relocation, and no
global byte-ownership/dead-code conclusion from a finite two-input sample.
"""
import argparse
import copy
import gzip
import hashlib
import json
from pathlib import Path

SOURCE="560d6aa5807a7f766213a33835cce85eab0fa40c"
QA30A="7c3ba01dc00a4f67fc30cc52e594b1cd6a2adee597a21939dbe0176ac2be2d4e"
META={
 "invalid00":(3,"3f2e81afb325a4f1e8bfee3910be6d92d2bef23145ba39a33fc355ea23a5454b"),
 "invalid18":(1,"9c5af6212cfd7c1ab58e9603f385767e64b10799c90be416a86c4f09d613bfdd")
}
def need(ok,msg):
    if not ok:raise AssertionError(msg)
def sha(b):
    return hashlib.sha256(b).hexdigest()
def pinned(path,checksum):
    raw=Path(path).read_bytes()
    need(sha(raw)==checksum,"pinned original native evidence mismatch")
    return json.loads(raw)
def signed_source(path):
    raw=Path(path).read_bytes()
    blob=hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest()
    need(blob==SOURCE,"original production blob changed")
    return raw.splitlines()
def original(label,root):
    shard,checksum=META[label]
    folder=Path(root)/label
    doc=pinned(folder/"qa20_manifest.json",checksum)
    need(doc.get("shard")==shard and doc.get("source_git_blob")==SOURCE
         and doc.get("ip_relocated") is False
         and doc.get("source_modified") is False
         and doc.get("stage1_final_acceptance") is False,
         "original QA20 source/geometry identity changed")
    original=[r for r in doc["records"] if r.get("label")==label]
    need(len(original)==1,"original QA20 input case missing")
    row=original[0]
    need(row["valid"] is False and row["output"]==row["expected"]==["-1"]*7,
         "original rejected input output not signed")
    zipped=(folder/row["path"]).read_bytes()
    need(sha(zipped)==row["compressed_trace_sha256"]
         and len(zipped)==row["compressed_bytes"],
         "original native compressed step evidence changed")
    rows=gzip.decompress(zipped).splitlines()
    need(len(rows)==row["steps"],"original physical STEP archive incomplete")
    data=[]
    for tick,line in enumerate(rows,1):
        cols=line.split(b"\t")
        need(len(cols)==7,"signed native STEP tuple malformed")
        values=tuple(map(int,cols))
        need(values[0]==tick and values[6] in (0,1) and 0<=values[5]<=255,
             "signed native STEP tick/opcode/stringmode altered")
        data.append(values)
    return row,data

def candidates(qa30a):
    n=qa30a.get("nearest_observed_control_transitions_by_15_source_candidates")
    need(type(n) is dict and len(n)==15,"original fifteen source candidates missing")
    return sorted(tuple(map(int,k.split(","))) for k in n)

def expected_events(qa30a,label,trace):
    expected={}
    for name,items in qa30a["nearest_observed_control_transitions_by_15_source_candidates"].items():
        for e in items:
            if e["input_group"]!="QA20" or e["input_label"]!=label:continue
            tick=e["tick"]
            need(0<tick<len(trace),"original QA30A control witness tick invalid")
            before=trace[tick-1];after=trace[tick]
            need(e["position"]==list(before[1:3])
                 and e["vector_before"]==list(before[3:5])
                 and e["runtime_opcode"]==before[5]
                 and e["stringmode_before"]==before[6]
                 and e["next_position"]==list(after[1:3])
                 and e["vector_after"]==list(after[3:5])
                 and e["next_runtime_opcode"]==after[5],
                 "QA30A original physical control edge not signed")
            expected.setdefault(tick,[]).append(name)
    need(expected,"at least one original control witness required")
    return expected

def verify_record(record,label,original,trace,qa30a,source):
    need(record.get("label")==label
         and record.get("original_shard")==META[label][0]
         and record.get("original_input")==original["raw_input"]
         and record.get("original_signed_steps")==len(trace)
         and record.get("qa20_original_gzip_sha256")==original["compressed_trace_sha256"]
         and record.get("native_final_output")==original["output"]
         and record.get("full_original_native_step_parity") is True
         and record.get("no_forced_ip_relocation") is True
         and record.get("production_source_mutated") is False,
         "QA30B original Native input/output/step claims altered")
    p=record.get("real_native_put_calls")
    writes=record.get("writes_to_original_15_cells")
    snapshots=record.get("live_state_snapshots")
    need(type(p) is int and p>=0 and type(writes) is list and len(writes)<=p
         and type(snapshots) is list,
         "QA30B actual Native state and physical put events missing")
    # The signed unmodified Native STEP trace independently fixes how many
    # actual p instructions executed. A forged count must not pass just
    # because it exceeds the number of reported candidate-cell writes.
    traced_p_ticks={step[0] for step in trace if step[5]==ord("p") and step[6]==0}
    need(p==len(traced_p_ticks),
         "QA30B Native put count differs from signed executed p opcodes")
    all_puts=record.get('all_real_native_put_events')
    need(type(all_puts) is list and len(all_puts)==p,
         'QA30B incomplete physical Native put event ledger')
    for event in all_puts:
        need(type(event) is dict and type(event.get('coordinate')) is list
             and len(event['coordinate'])==2
             and all(type(x) is int for x in event['coordinate'])
             and type(event.get('tick')) is int
             and type(event.get('before')) is int
             and type(event.get('after')) is int,
             'QA30B physical Native put event malformed')
    need([event['tick'] for event in all_puts]==sorted(traced_p_ticks),
         'QA30B physical Native put events do not match signed p chronology')
    targets=candidates(qa30a)
    originals={(x,y):source[y][x] for x,y in targets}
    derived_candidate_puts=[event for event in all_puts
                            if tuple(event['coordinate']) in originals]
    need(writes==derived_candidate_puts,
         'QA30B candidate put ledger differs from all actual physical Native puts')
    current=dict(originals)
    for i,w in enumerate(writes):
        xy=tuple(w["coordinate"])
        need(xy in originals and type(w["tick"]) is int
             and 1<=w["tick"]<=len(trace) and type(w["before"]) is int
             and type(w["after"]) is int,
             "QA30B physical candidate mutation metadata malformed")
        if i:need(writes[i-1]["tick"]<=w["tick"],"candidate puts unordered")
        need(w["tick"] in traced_p_ticks,
             "reported candidate FungeSpace put did not execute at a signed Native p STEP")
        need(w["before"]==current[xy],
             "candidate physical put previous byte contradicts original source history")
        current[xy]=w["after"]
    expected=expected_events(qa30a,label,trace)
    need(len(snapshots)==len(expected) and
         {s.get("tick") for s in snapshots}==set(expected),
         "QA30B must show exact original witness tick set")
    for s in snapshots:
        tick=s["tick"]
        need(s.get("target_coords")==sorted(expected[tick])
             and s.get("actual_before_step")==list(trace[tick-1])
             and s.get("actual_next_step")==list(trace[tick])
             and type(s.get("fetched_source_candidate_live_values")) is list
             and len(s["fetched_source_candidate_live_values"])==15,
             "QA30B signed control before/after or source-state completeness altered")
        prior=[w for w in writes if w["tick"]<tick]
        need(s.get("physical_candidate_writes_prior_to_tick")==len(prior),
             "original Native candidate write count inconsistent")
        observed={}
        for item in s["fetched_source_candidate_live_values"]:
            xy=tuple(item["coordinate"])
            need(xy in originals and xy not in observed
                 and item["static_original_value"]==originals[xy],
                 "source candidate duplicated or original byte corrupted")
            history=[w for w in prior if tuple(w["coordinate"])==xy]
            want=history[-1]["after"] if history else originals[xy]
            need(item["runtime_value"]==want
                 and item["actual_prior_put_ticks"]==[w["tick"] for w in history],
                 "QA30B physical live FungeSpace cell not explained by witnessed puts")
            observed[xy]=True
        need(len(observed)==15,"signed complete 15-cell source snapshot not provided")
    # Frozen original Native paths had zero physical puts to these 15 cells.
    # A forged put *after* the final sampled memory snapshot is not evidence.
    need(writes == [], "QA30B frozen original inputs require zero candidate source writes")
    return len(snapshots)

def test_forgery(report,label,original,trace,qa30a,source):
    need(trace[-1][5]!=ord("p") and
         max(s["tick"] for s in report["live_state_snapshots"])<len(trace),
         "forged tail-put challenge requires a real non-p terminal STEP after all control witnesses")
    tail_source=report["live_state_snapshots"][0]["fetched_source_candidate_live_values"][0]
    attacks=[
      ("label",lambda a:a.__setitem__("label","forged")),
      ("input",lambda a:a.__setitem__("original_input","0 0 0 0\n")),
      ("step-total",lambda a:a.__setitem__("original_signed_steps",1)),
      ("oracle",lambda a:a.__setitem__("native_final_output",["42"]*7)),
      ("forced-ip",lambda a:a.__setitem__("no_forced_ip_relocation",False)),
      ("modified-program",lambda a:a.__setitem__("production_source_mutated",True)),
      ("wrong-native-sha",lambda a:a.__setitem__("qa20_original_gzip_sha256","0"*64)),
      ("delete-snapshot",lambda a:a["live_state_snapshots"].pop()),
      ("wrong-tick",lambda a:a["live_state_snapshots"][0].__setitem__("tick",0)),
      ("fake-direction",lambda a:a["live_state_snapshots"][0]["actual_before_step"].__setitem__(3,999)),
      ("fake-next",lambda a:a["live_state_snapshots"][0]["actual_next_step"].__setitem__(1,999)),
      ("fake-target",lambda a:a["live_state_snapshots"][0]["target_coords"].append("999,999")),
      ("fake-live-byte",lambda a:a["live_state_snapshots"][0]["fetched_source_candidate_live_values"][0].__setitem__("runtime_value",-999)),
      ("delete-source-cell",lambda a:a["live_state_snapshots"][0]["fetched_source_candidate_live_values"].pop()),
      ("fake-prior-ticks",lambda a:a["live_state_snapshots"][0]["fetched_source_candidate_live_values"][0]["actual_prior_put_ticks"].append(-1)),
      ("inflate-native-put-count",lambda a:a.__setitem__("real_native_put_calls",report["real_native_put_calls"]+1)),
      ("omit-real-put-event",lambda a:a["all_real_native_put_events"].pop()),
      ("forge-real-put-tick",lambda a:a["all_real_native_put_events"][0].__setitem__("tick",0)),
      ("forge-real-put-candidate-coordinate",lambda a:a["all_real_native_put_events"][0].__setitem__("coordinate",list(tail_source["coordinate"]))),
      ("fake-post-witness-non-p-put",lambda a:a["writes_to_original_15_cells"].append({
          "tick":len(trace),"coordinate":list(tail_source["coordinate"]),
          "before":tail_source["static_original_value"],
          "after":tail_source["static_original_value"]+1}))
    ]
    # A real signed p instruction at tick 9926 occurs AFTER the last
    # control witness of original invalid00. Reject fake receipts that
    # attach a candidate-cell write to this genuine but unrelated opcode.
    if label == "invalid00":
        last_control=max(s["tick"] for s in report["live_state_snapshots"])
        late=sorted(t[0] for t in trace if t[5]==ord("p") and t[6]==0
                    and t[0]>last_control)
        need(late and late[0]==9926, "frozen signed post-witness p tick changed")
        attacks.append(("fake-real-p-after-final-control-witness", lambda a:
            a["writes_to_original_15_cells"].append({
                "tick":late[0], "coordinate":list(tail_source["coordinate"]),
                "before":tail_source["static_original_value"],
                "after":tail_source["static_original_value"]+1})))
    for name,edit in attacks:
        mutated=copy.deepcopy(report)
        edit(mutated)
        try:verify_record(mutated,label,original,trace,qa30a,source)
        except (AssertionError,IndexError,KeyError,TypeError,ValueError):pass
        else:raise AssertionError("forged Native physical control receipt accepted "+name)
    return len(attacks)

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--source",required=True)
    ap.add_argument("--qa30a",required=True)
    ap.add_argument("--root",required=True)
    ap.add_argument("--native",required=True)
    ap.add_argument("--output",required=True)
    a=ap.parse_args()
    source=signed_source(a.source)
    qa30a=pinned(a.qa30a,QA30A)
    need(qa30a.get("original_programs_reaudited")==136
         and qa30a.get("original_native_steps_reaudited")==4513423
         and qa30a.get("negative_provenance_and_directed_edge_controls_rejected")==70
         and qa30a.get("stage1_complete") is False,
         "original QA30A signed historical data changed")
    doc=json.loads(Path(a.native).read_bytes())
    need(doc.get("schema")=="qa30b-two-original-input-live-source-owner-frontier-v1"
         and doc.get("production_git_blob")==SOURCE
         and doc.get("qa30a_original_json_sha256")==QA30A
         and doc.get("qa20_original_run")==39761821210
         and doc.get("qa30a_original_run")==40125781530
         and doc.get("original_programs_replayed")==2
         and doc.get("original_native_steps_replayed")==18859
         and doc.get("candidate_count")==15
         and doc.get("all_native_execution_input_origin") is True
         and doc.get("native_program_bytes_modified") is False
         and doc.get("no_forced_ip_relocation") is True
         and doc.get("global_mutation_apis_excluded") is False
         and doc.get("global_source_deadness_proved") is False
         and doc.get("stage1_complete") is False,
         "QA30B unsupported finite/global acceptance condition")
    rows=doc.get("records")
    need(type(rows) is list and len(rows)==2 and
         [x.get("label") for x in rows]==["invalid00","invalid18"],
         "two pinned original input-driven PyFunge programs missing")
    result=[];controls=0
    for rec in rows:
        label=rec["label"]
        signed_case,trace=original(label,a.root)
        samples=verify_record(rec,label,signed_case,trace,qa30a,source)
        controls+=test_forgery(rec,label,signed_case,trace,qa30a,source)
        result.append({"input_label":label,"steps":len(trace),
                       "real_put_calls":rec["real_native_put_calls"],
                       "candidate_puts":len(rec["writes_to_original_15_cells"]),
                       "audited_actual_native_control_witnesses":samples})
    need(controls==41 and sum(x["steps"] for x in result)==18859,
         "QA30B must reject exactly 41 adversarial Native records")
    report={"schema":"qa30b-independent-live-original-control-source-audit-v1",
            "actual_native_programs":2,"original_steps_replayed":18859,
            "live_witness_snapshots":sum(x["audited_actual_native_control_witnesses"] for x in result),
            "candidate_puts":sum(x["candidate_puts"] for x in result),
            "negative_controls_rejected":controls,
            "all_input_global_byte_ownership_proven":False,
            "all_input_target_unreachability_proven":False,
            "stage1_complete":False,"original_programs":result}
    Path(a.output).write_text(json.dumps(report,sort_keys=True,indent=2)+"\n")
    print("QA30B_INDEPENDENT_TWO_INPUT_LIVE_NATIVE_SOURCE_PARITY_PASS",18859)
    print("QA30B_FORTY_ONE_ADVERSARIAL_SOURCE_RECEIPTS_REJECTED",controls)
    print("QA30B_GLOBAL_REACHABILITY_AND_STAGE1_REMAIN_OPEN")

if __name__=="__main__":
    main()
