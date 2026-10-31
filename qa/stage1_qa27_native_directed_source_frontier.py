#!/usr/bin/env python3
"""QA27: original 136-input native source-cell directed frontier, not a simulation.

Consumes the accepted original QA20 (48), QA24 (24), QA26 (64) raw physical
Native STEP files and original QA18 source roles. Never changes source, moves
an IP, assumes a missing edge is impossible, or certifies Stage 1.
"""
import argparse
import collections
import copy
import gzip
import hashlib
import json
from pathlib import Path

SOURCE="560d6aa5807a7f766213a33835cce85eab0fa40c"
QA18_SHA="263a73a40afa17a8a9b1c831a01239be671d9ea0a9c331fd3f725f83cf1cfea7"
RUNS={"QA20":(39761821210,48,1939997,12,"qa20_manifest.json"),
      "QA24":(39841651046,24,776706,6,"qa24_manifest.json"),
      "QA26":(39945902093,64,1796720,16,"qa26_manifest.json")}
OLDER_HITS={(10,44),(150,20),(175,38),(179,44),(235,11),(396,17)}

def need(condition,why):
    if not condition:raise AssertionError(why)

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def verified_source(path):
    raw=Path(path).read_bytes()
    identity=hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest()
    need(identity==SOURCE,"immutable original source Git blob changed")
    return raw.splitlines()

def targets(qa18,source):
    raw=Path(qa18).read_bytes()
    need(sha(raw)==QA18_SHA,"original QA18 roles SHA-256 mismatch")
    obj=json.loads(raw)
    need(obj.get("schema")=="qa18-source-glyph-contact-v1"
         and obj.get("source_git_blob")==SOURCE
         and obj.get("native_original_trace_count")==49
         and obj.get("dead_code_certified") is False,
         "QA18 original source observations invalid")
    rows=obj.get("never_touched_potential_control_glyphs")
    need(type(rows) is list and len(rows)==21,"expected precisely 21 QA18 cells")
    data={}
    for row in rows:
        x,y=int(row["x"]),int(row["y"])
        op=row["source_char"]
        need(type(op) is str and len(op)==1
             and 0<=y<len(source) and 0<=x<len(source[y])
             and source[y][x]==ord(op) and (x,y) not in data,
             "original static source byte missing or duplicated")
        data[(x,y)]=ord(op)
    need(OLDER_HITS<=set(data) and len(data)-len(OLDER_HITS)==15,
         "six historical hits or 15 unresolved cells changed")
    return data

def receipt_header(doc,group,shard,all_target_coords):
    expected_count=RUNS[group][3]
    need(doc.get("source_git_blob")==SOURCE
         and doc.get("shard")==shard
         and len(doc.get("records",[]))==expected_count
         and doc.get("stage1_complete",doc.get("stage1_final_acceptance")) is False,
         "Native source, shard, case count or Stage 1 status forged")
    if group=="QA20":
        need(doc.get("schema")=="qa20-native-natural-route-21-controls-v1"
             and doc.get("qa18_original_run")==39423789058
             and doc.get("source_modified") is False
             and doc.get("ip_relocated") is False
             and doc.get("all_natural_reachability_proved") is False
             and doc.get("native_case_count")==12,
             "QA20 native manifest provenance drifted")
    else:
        pfx="qa24" if group=="QA24" else "qa26"
        need(doc.get("schema")==("qa24-24-disjoint-native-input-physical-route-v1" if group=="QA24" else "qa26-native-64-disjoint-input-source-frontier-v1")
             and doc.get("ip_relocated") is False
             and doc.get("qa18_source_provenance_sha256",doc.get("qa18_original_roles_sha256"))==QA18_SHA
             and doc.get("qa20_prior_native_aggregate_sha256",doc.get("qa20_original_aggregate_sha256"))==
                 "75d2ee07eaf998fcb69bcb238d5fcb2163ab8305efe4abe4378af95f41385117",
             "QA24/QA26 source-glyph prior SHA or identity drifted")
        need(doc.get("production_source_modified",False) is False
             and doc.get("dead_code_certified") is False,
             "QA24/QA26 original-source and deadness claim altered")
    listed=doc.get("targets",doc.get("source_candidate_coordinates"))
    need(type(listed) is list and len(listed)==21 and
         {tuple(item[:2]) for item in listed}==all_target_coords,
         "Native 21-cell candidate array not preserved")

def check_trace(folder,row,group,shard,targets_map):
    label=row.get("label")
    need(type(label) is str and label
         and row.get("path")==label+".steps.gz"
         and row.get("natural_ip_no_intervention") is True
         and row.get("output")==row.get("expected")
         and len(row.get("output",[]))==7
         and type(row.get("valid")) is bool,
         "untrusted native output, input or trace path")
    if not row["valid"]:
        need(row["output"]==["-1"]*7,"malformed native input accepted")
    path=folder/(label+".steps.gz")
    need(path.is_file(),"original physical STEP file missing")
    compressed=path.read_bytes()
    need(sha(compressed)==row.get("compressed_trace_sha256")
         and len(compressed)==row.get("compressed_bytes"),
         "immutable Native gzip SHA-256 drifted")
    try:lines=gzip.decompress(compressed).splitlines()
    except Exception as exc:raise AssertionError("corrupt compressed Native trace") from exc
    need(len(lines)==row.get("steps") and len(lines)>50,
         "original Native raw STEP length altered")
    targets=list(targets_map.items())
    minimum={xy:10**12 for xy,op in targets}
    nearest={}
    visits=collections.Counter()
    exact=collections.Counter()
    near=collections.Counter()
    for tick,line in enumerate(lines,1):
        fields=line.split(b"\t")
        need(len(fields)==7,"invalid actual Native physical STEP field count")
        try:index,x,y,dx,dy,opcode,stringmode=map(int,fields)
        except ValueError as exc:raise AssertionError("non-numeric original physical STEP") from exc
        need(index==tick and 0<=opcode<=255 and stringmode in (0,1),
             "original Native physical step sequence, opcode, stringmode invalid")
        for xy,original_opcode in targets:
            d=abs(x-xy[0])+abs(y-xy[1])
            if d<minimum[xy]:
                minimum[xy]=d
                nearest[xy]=[tick,x,y,dx,dy,opcode,stringmode]
            if d<=3:near[xy]+=1
            if d==0:
                visits[xy]+=1
                if stringmode==0 and opcode==original_opcode:
                    exact[xy]+=1
    # Compare against the old Native writer's own separately saved nearest/hits.
    saved_nearest=row.get("nearest")
    saved_hits=row.get("target_step_hits")
    need(type(saved_nearest) is dict and type(saved_hits) is dict,
         "Native route receipt lacks original physical evidence summaries")
    for xy,op in targets:
        key="%d,%d"%xy
        need(saved_nearest[key][0]==minimum[xy]
             and saved_nearest[key][1]==nearest[xy]
             and len(saved_hits[key])==visits[xy],
             "Native saved nearest/hits disagrees with original compressed STEP route")
    return {"label":label,"steps":len(lines),
            "minimum":minimum,"nearest":nearest,"visits":visits,
            "exact":exact,"within_three":near}

def negative_controls(template,group,shard,coords):
    receipt_header(template,group,shard,coords)
    attacks=[
      ("changed-source",lambda z:z.__setitem__("source_git_blob","0"*40)),
      ("wrong-shard",lambda z:z.__setitem__("shard",(shard+1)%4)),
      ("missing-case",lambda z:z["records"].pop()),
      ("stage-closed",lambda z:z.__setitem__("stage1_complete",True)),
      ("changed-original-candidates",lambda z:z["targets"].pop() if "targets" in z else z["source_candidate_coordinates"].pop())]
    for name,mutate in attacks:
        bad=copy.deepcopy(template);mutate(bad)
        try:receipt_header(bad,group,shard,coords)
        except (AssertionError,KeyError,TypeError,ValueError,IndexError):pass
        else:raise AssertionError("forged Native header accepted: "+name)
    return len(attacks)

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--source",required=True)
    parser.add_argument("--qa18",required=True)
    parser.add_argument("--root",required=True,
                        help="root/QA20/shard0, root/QA24/shard0, root/QA26/shard0")
    parser.add_argument("--output",required=True)
    a=parser.parse_args()
    source=verified_source(a.source)
    cells=targets(a.qa18,source)
    missing={k for k in cells if k not in OLDER_HITS}
    minimum={k:10**12 for k in missing}
    witness={}
    nearby=collections.Counter()
    group_min={}
    totals={}
    hitcoords=set()
    all_labels=set()
    controls=0
    for group,(run,total,steps,per,manifest_name) in RUNS.items():
        group_steps=0; group_count=0
        per_min={xy:10**12 for xy in missing}
        for shard in range(4):
            folder=Path(a.root)/group/("shard%d"%shard)
            doc=json.loads((folder/manifest_name).read_bytes())
            receipt_header(doc,group,shard,set(cells))
            controls+=negative_controls(doc,group,shard,set(cells))
            for row in doc["records"]:
                record=check_trace(folder,row,group,shard,cells)
                key=group+":"+record["label"]
                need(key not in all_labels,"duplicate original Native label")
                all_labels.add(key)
                group_count+=1;group_steps+=record["steps"]
                hitcoords.update(k for k,v in record["exact"].items() if v)
                for xy in missing:
                    d=record["minimum"][xy]
                    per_min[xy]=min(per_min[xy],d)
                    nearby[xy]+=record["within_three"][xy]
                    if d<minimum[xy]:
                        minimum[xy]=d
                        witness[xy]={"group":group,"run":run,"shard":shard,
                                     "case":record["label"],"distance":d,
                                     "step":record["nearest"][xy][0],
                                     "observed_state":record["nearest"][xy][1:]}
        need(group_count==total and group_steps==steps,
             "historical group Native case/step totals changed")
        group_min[group]={f"{x},{y}":v for (x,y),v in sorted(per_min.items())}
        totals[group]={"native_runs":group_count,"actual_steps":group_steps,
                       "original_github_run":run}
    need(len(all_labels)==136 and sum(t["actual_steps"] for t in totals.values())==4513423,
         "original 136 real Native paths incomplete")
    need(controls==60,"12 original shards times five tampered headers required")
    need(hitcoords==OLDER_HITS,"unexpected old/new original source opcode hit set")
    result={
      "schema":"qa27-136-original-native-directed-source-frontier-v1",
      "source_git_blob":SOURCE,"qa18_roles_sha256":QA18_SHA,
      "original_21_source_candidates":21,"observed_original_opcode_coords":sorted(map(list,hitcoords)),
      "old_15_without_native_source_opcode_contact":sorted(map(list,missing)),
      "original_native_cases":136,"original_native_steps":4513423,
      "sha256_verified_trace_files":136,
      "original_groups":totals,
      "five_forged_header_controls_per_shard_rejected":controls,
      "minimum_l1_by_original_15":{f"{x},{y}":minimum[x,y] for x,y in sorted(missing)},
      "nearest_original_native_witnesses":{f"{x},{y}":witness[x,y] for x,y in sorted(missing)},
      "per_group_minimum_distances":group_min,
      "original_within_3_step_counts":{f"{x},{y}":nearby[x,y] for x,y in sorted(missing)},
      "all_15_closest_witnesses_from_QA20":all(w["group"]=="QA20" for w in witness.values()),
      "all_15_still_unobserved":True,
      "false_dead_code_inference":False,
      "source_byte_ownership_globally_proven":False,
      "directional_edge_absence_not_global_unreachability":True,
      "stage1_complete":False}
    need(result["all_15_closest_witnesses_from_QA20"]
         and all(3<=d<=9 for d in minimum.values()),
         "QA27 geometric frontier shifted; inspect independently before acceptance")
    Path(a.output).write_text(json.dumps(result,indent=2,sort_keys=True)+"\n")
    print("QA27_ORIGINAL_136_NATIVE_PHYSICAL_STEP_FRONTIERS_REPRODUCED",4513423)
    print("QA27_SIXTY_FORGED_MANIFEST_HEADERS_REJECTED")
    print("QA27_FIFTEEN_ORIGINAL_CELLS_UNREACHED_NO_DEAD_CODE_CONCLUSION")

if __name__=="__main__":main()
