#!/usr/bin/env python3
"""QA28: independently verify real predecessor/successor edges at 15 QA27 witnesses.

Only signed original QA20 PyFunge raw STEP files and accepted QA27 aggregate
are read. No synthetic IP step, source edit, new run, or dead-code inference.
Consecutive STEP positions are observed actual interpreter transitions; they
need not equal old_position + pre-execution delta (e.g. control-flow effects).
"""
import argparse
import copy
import gzip
import hashlib
import json
from collections import Counter
from pathlib import Path

SOURCE_BLOB="560d6aa5807a7f766213a33835cce85eab0fa40c"
QA18_SHA="263a73a40afa17a8a9b1c831a01239be671d9ea0a9c331fd3f725f83cf1cfea7"
QA27_SHA="20caa24769f882e38c69eb8bb9a31567fdbd7bb52f3f885b95436c1ece2798f3"
MANIFEST_SHA={
    0:"782fb868a11a105550ef5af6f8f7cd39e4ba9de77d9565f7549e310549b0073a",
    1:"9c5af6212cfd7c1ab58e9603f385767e64b10799c90be416a86c4f09d613bfdd",
}
Q20_NATIVE=39761821210
Q27_NATIVE=39966335703

def need(condition,message):
    if not condition: raise AssertionError(message)

def sha(data):
    return hashlib.sha256(data).hexdigest()

def load_pinned(path,digest):
    b=Path(path).read_bytes()
    need(sha(b)==digest,"pinned original Native JSON SHA-256 mismatch "+str(path))
    return json.loads(b)

def immutable_source(path):
    b=Path(path).read_bytes()
    blob=hashlib.sha1(b"blob "+str(len(b)).encode("ascii")+b"\0"+b).hexdigest()
    need(blob==SOURCE_BLOB,"signed original production source changed")
    return b.splitlines()

def candidate_roles(roles,source):
    need(roles.get("schema")=="qa18-source-glyph-contact-v1"
         and roles.get("source_git_blob")==SOURCE_BLOB
         and roles.get("dead_code_certified") is False
         and len(roles.get("never_touched_potential_control_glyphs",[]))==21,
         "QA18 candidate source-role provenance drifted")
    out={}
    for e in roles["never_touched_potential_control_glyphs"]:
        xy=(int(e["x"]),int(e["y"]))
        opcode=ord(e["source_char"])
        need(xy not in out and source[xy[1]][xy[0]]==opcode,
             "original 2D source byte/candidate coordinate disagreement")
        out[xy]=opcode
    return out

def original_manifest(folder,shard,roles):
    obj=load_pinned(folder/"qa20_manifest.json",MANIFEST_SHA[shard])
    need(obj.get("schema")=="qa20-native-natural-route-21-controls-v1"
         and obj.get("shard")==shard and obj.get("source_git_blob")==SOURCE_BLOB
         and obj.get("qa18_original_run")==39423789058
         and obj.get("native_case_count")==12
         and obj.get("stage1_final_acceptance") is False
         and obj.get("source_modified") is False
         and obj.get("ip_relocated") is False,
         "QA20 accepted source Native receipt altered")
    expected=set(roles)
    need(len(obj.get("targets",[]))==21
         and {tuple(e[:2]) for e in obj["targets"]}==expected,
         "original twenty-one QA18 candidates missing")
    rows={r["label"]:r for r in obj["records"]}
    need(len(rows)==12,"QA20 12 original source cases missing per shard")
    return rows

def load_actual_trace(folder,entry):
    label=entry["label"]
    need(entry.get("path")==label+".steps.gz"
         and entry.get("natural_ip_no_intervention") is True
         and len(entry.get("output",[]))==7
         and entry["output"]==entry["expected"],
         "original Native route label/input/output contract modified")
    encoded=(folder/(label+".steps.gz")).read_bytes()
    need(len(encoded)==entry["compressed_bytes"]
         and sha(encoded)==entry["compressed_trace_sha256"],
         "original QA20 compressed Native STEP bytes/hash changed "+label)
    try: raw=gzip.decompress(encoded)
    except Exception as exc:raise AssertionError("Native gzip corrupted "+label) from exc
    lines=raw.splitlines()
    need(len(lines)==entry["steps"],"original Native STEP count changed "+label)
    parsed=[]
    for i,line in enumerate(lines,1):
        fields=line.split(b"\t")
        need(len(fields)==7,"original PyFunge native STEP field width invalid")
        try:values=tuple(map(int,fields))
        except ValueError as exc:raise AssertionError("original Native STEP not numeric") from exc
        need(values[0]==i and values[-1] in (0,1) and 0<=values[-2]<=255,
             "Native raw STEP chronology or fetched opcode invalid")
        parsed.append(values)
    return parsed

def l1(step,coord):
    return abs(step[1]-coord[0])+abs(step[2]-coord[1])

def verify_anchor(triad,witness,coord,immutable):
    need(type(triad) is list and len(triad)==3,
         "three consecutive real Native STEP records required")
    for observed,signed in zip(triad,immutable):
        need(tuple(observed)==tuple(signed),
             "directed witness STEP tuple differs from original signed raw Native route")
    before,anchor,after=triad
    need(before[0]+1==anchor[0] and anchor[0]+1==after[0],
         "anchor predecessor/successor have missing or fabricated ticks")
    need(anchor[0]==witness["step"]
         and tuple(anchor[1:])==tuple(witness["observed_state"])
         and l1(anchor,coord)==witness["distance"],
         "QA27 closest actual Native witness drifted")
    need(anchor[6]==0,"closest input-origin source witness unexpectedly stringmode")
    return True

def controls(baseline,witness,coord):
    verify_anchor(baseline,witness,coord,baseline)
    negative=[
        ("shift-anchor-x",lambda d:d[1].__setitem__(1,d[1][1]+1)),
        ("forge-anchor-delta",lambda d:d[1].__setitem__(3,d[1][3]+1)),
        ("forge-anchor-opcode",lambda d:d[1].__setitem__(5,(d[1][5]+1)%256)),
        ("flip-anchor-stringmode",lambda d:d[1].__setitem__(6,1-d[1][6])),
        ("shift-predecessor-tick",lambda d:d[0].__setitem__(0,d[0][0]+1)),
        ("change-next-position",lambda d:d[2].__setitem__(1,d[2][1]+1)),
        ("drop-predecessor",lambda d:d.pop(0)),
        ("forge-next-opcode",lambda d:d[2].__setitem__(5,(d[2][5]+1)%256)),
    ]
    for name,alter in negative:
        mutated=[list(e) for e in baseline]
        alter(mutated)
        try:verify_anchor(mutated,witness,coord,baseline)
        except (AssertionError,IndexError,TypeError,ValueError):pass
        else:raise AssertionError("forged directed Native edge was accepted: "+name)
    return len(negative)

def direction_state(anchor,target):
    vx,vy=anchor[3],anchor[4]
    to=(target[0]-anchor[1],target[1]-anchor[2])
    dot=vx*to[0]+vy*to[1]
    # Pre-instruction direction is NOT necessarily the direction taken after
    # executing an x, j, k, #, or other control-changing instruction.
    return {"dot_with_target":dot,"class":
        ("towards_projection" if dot>0 else "away_projection" if dot<0 else "orthogonal_projection")}

def directed_receipt(triad,witness,coord,opcode):
    before,anchor,after=triad
    need(l1(anchor,coord)>0,"target was actually reached; no longer an unobserved frontier")
    dx,dy=anchor[3],anchor[4]
    observed_move=[after[1]-anchor[1],after[2]-anchor[2]]
    nominal=[anchor[1]+dx,anchor[2]+dy]
    return {
      "target":list(coord),"static_target_opcode":opcode,
      "minimum_original_l1":witness["distance"],
      "original_run":witness["run"],"original_group":witness["group"],
      "original_shard":witness["shard"],"original_case":witness["case"],
      "original_witness_tick":witness["step"],
      "predecessor_native_step":list(before),
      "nearest_native_step":list(anchor),
      "successor_native_step":list(after),
      "actual_directed_entry_displacement":[anchor[1]-before[1],anchor[2]-before[2]],
      "actual_directed_exit_displacement":observed_move,
      "pre_execution_delta":[dx,dy],
      "nominal_position_plus_pre_delta":nominal,
      "actual_successor_equals_nominal":nominal==list(after[1:3]),
      "observed_predecessor_opcode_x":before[5]==ord("x") and before[6]==0,
      "observed_anchor_opcode":anchor[5],
      "observed_anchor_is_original_target":(anchor[1],anchor[2])==coord,
      "anchor_to_target_projection":direction_state(anchor,coord),
      "actual_successor_l1_from_target":l1(after,coord),
      "actual_exit_changes_source_row":after[2]!=anchor[2],
      "real_native_observations_only":True,
      "source_cell_byte_ownership_globally_proven":False,
      "global_target_unreachability_proven":False}

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--qa27",required=True)
    p.add_argument("--qa18",required=True)
    p.add_argument("--source",required=True)
    p.add_argument("--shard0",required=True)
    p.add_argument("--shard1",required=True)
    p.add_argument("--output",required=True)
    a=p.parse_args()
    source=immutable_source(a.source)
    roles=candidate_roles(load_pinned(a.qa18,QA18_SHA),source)
    qa27=load_pinned(a.qa27,QA27_SHA)
    need(qa27.get("schema")=="qa27-136-original-native-directed-source-frontier-v1"
         and qa27.get("source_git_blob")==SOURCE_BLOB
         and qa27.get("original_native_cases")==136
         and qa27.get("original_native_steps")==4513423
         and qa27.get("all_15_still_unobserved") is True
         and qa27.get("stage1_complete") is False
         and qa27.get("five_forged_header_controls_per_shard_rejected")==60,
         "accepted original QA27 data/metadata changed")
    missing={tuple(c) for c in qa27["old_15_without_native_source_opcode_contact"]}
    known={tuple(c) for c in qa27["observed_original_opcode_coords"]}
    need(len(missing)==15 and len(known)==6
         and set(roles)==missing|known,"not exactly the original 21 source cells")
    folders={0:Path(a.shard0),1:Path(a.shard1)}
    manifests={s:original_manifest(folder,s,roles)
               for s,folder in folders.items()}
    cached={}
    rows=[];controls_rejected=0
    for coord in sorted(missing):
        label="%d,%d"%coord
        w=qa27["nearest_original_native_witnesses"][label]
        need(w["group"]=="QA20" and w["run"]==Q20_NATIVE
             and w["shard"] in folders and w["case"] in ("valid00","invalid18"),
             "QA27 nearest original witness did not come from pinned original two shards")
        shard=w["shard"];case=w["case"]
        item=manifests[shard][case]
        key=(shard,case)
        if key not in cached:cached[key]=load_actual_trace(folders[shard],item)
        trace=cached[key]
        tick=w["step"]
        need(2<=tick<len(trace),"nearest original source witness lacks directed neighbors")
        triad=[list(t) for t in trace[tick-2:tick+1]]
        need(item["nearest"][label][0]==w["distance"]
             and item["nearest"][label][1]==[tick]+w["observed_state"],
             "QA20 original saved witness does not match QA27 independent aggregate")
        immutable=[list(t) for t in trace[tick-2:tick+1]]
        verify_anchor(triad,w,coord,immutable)
        controls_rejected+=controls(triad,w,coord)
        rows.append(directed_receipt(triad,w,coord,roles[coord]))
    need(len(rows)==15 and controls_rejected==120
         and sum(r["observed_predecessor_opcode_x"] for r in rows)==2
         and sum(not r["actual_successor_equals_nominal"] for r in rows)==2
         and sum(r["actual_exit_changes_source_row"] for r in rows)==0,
         "directed original source frontier differs; stop and inspect the raw evidence")
    result={"schema":"qa28-15-original-source-candidate-directed-native-triads-v1",
       "original_source_git_blob":SOURCE_BLOB,"qa18_sha256":QA18_SHA,
       "qa27_independent_original_aggregate_sha256":QA27_SHA,
       "original_qa20_run":Q20_NATIVE,"original_qa27_run":Q27_NATIVE,
       "frozen_full_original_native_replay_basis":136,
       "frozen_full_original_native_step_basis":4513423,
       "original_native_trace_files_rechecked":len(cached),
       "source_candidate_count":21,"originally_unobserved_target_count":15,
       "exact_directed_witness_triads":15,
       "predecessor_x_transfer_at_witness":2,
       "actual_exit_differs_from_pre_execution_delta":2,
       "observed_next_step_changes_row":0,
       "eight_negative_controls_per_target_rejected":controls_rejected,
       "original_source_byte_ownership_globally_proven":False,
       "no_missing_edge_is_universal_unreachability_claim":True,
       "stage1_complete":False,"records":rows}
    Path(a.output).write_text(json.dumps(result,indent=2,sort_keys=True)+"\n")
    print("QA28_FIFTEEN_SIGNED_DIRECTED_NATIVE_SOURCE_FRONTIERS_REPRODUCED")
    print("QA28_ONE_HUNDRED_TWENTY_FORGED_DIRECTED_EDGES_REJECTED")
    print("QA28_NO_DEAD_CODE_OR_GLOBAL_STAGE1_ACCEPTANCE")
if __name__=="__main__":main()
