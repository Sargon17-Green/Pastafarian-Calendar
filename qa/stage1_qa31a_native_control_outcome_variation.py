#!/usr/bin/env python3
"""QA31A: observed input-origin dynamic-control successors for 15 source cells.

This is a finite, read-only, original Native PyFunge STEP re-audit.
A distinct outcome under identical (physical coordinate, pre-vector, fetched
opcode, stringmode) in different input runs is an *observation* of control
state variation, NOT a causal effect attributed to input, NOT proof that
an unvisited target is reachable, and NOT an original-source-byte owner proof.
"""
import argparse
import collections
import gzip
import hashlib
import json
from pathlib import Path

import stage1_qa27_native_directed_source_frontier as foundation
import stage1_qa30a_native_control_frontier as qa30a

SOURCE=foundation.SOURCE
QA18=foundation.QA18_SHA
QA30A="7c3ba01dc00a4f67fc30cc52e594b1cd6a2adee597a21939dbe0176ac2be2d4e"
CONTROL=set(qa30a.CONTROL)
NEW_SOURCE_CANDIDATE_EXPECTED=15
MIN_NEIGHBOR_DISTANCE=9
MAX_NEAR_SITES_PER_TARGET=8

def need(ok, why):
    if not ok: raise AssertionError(why)

def sha(data):
    return hashlib.sha256(data).hexdigest()

def original_qa30a(path):
    raw=Path(path).read_bytes()
    need(sha(raw)==QA30A,"original independently accepted QA30A JSON SHA-256 drift")
    obj=json.loads(raw)
    need(obj.get("schema")=="qa30a-136-original-native-dynamic-control-frontier-v1"
         and obj.get("original_production_git_blob")==SOURCE
         and obj.get("original_qa18_sha256")==QA18
         and obj.get("original_programs_reaudited")==136
         and obj.get("original_native_steps_reaudited")==4513423
         and obj.get("negative_provenance_and_directed_edge_controls_rejected")==70
         and obj.get("absence_from_sample_not_proof_of_global_unreachability") is True
         and obj.get("stage1_complete") is False,
         "accepted QA30A Native origin/limits drift")
    return obj

def observed_edge(before, after, source_row, case_id):
    edge=qa30a.directed_edge(before,after)
    need(before[6]==0 and before[5] in CONTROL,
         "string-mode or non-control byte falsely admitted")
    op=before[5]
    x,y=before[1:3]
    source_match=(0<=y<len(source_row) and 0<=x<len(source_row[y]) and source_row[y][x]==op)
    key=(x,y,before[3],before[4],op)
    outcome=(after[1]-x,after[2]-y,after[3],after[4],after[6])
    return key,outcome,source_match,edge,case_id

def parse_native(route_folder, row, group, shard, source, original15, site_map, totals):
    label=row.get("label")
    need(type(label) is str and label and row.get("path")==label+".steps.gz"
         and row.get("natural_ip_no_intervention") is True
         and row.get("output")==row.get("expected")
         and type(row.get("output")) is list
         and len(row["output"])==7,
         "original Native input/output or natural-IP receipt changed")
    if not row["valid"]:
        need(row["output"]==["-1"]*7,"original malformed input not rejected")
    archive=route_folder/row["path"]
    compressed=archive.read_bytes()
    need(sha(compressed)==row.get("compressed_trace_sha256")
         and len(compressed)==row.get("compressed_bytes"),
         "original compressed Native STEP SHA-256/length mismatch")
    case=group+":"+label
    previous=None;first_edge=None;steps=0
    with gzip.open(archive,"rb") as stream:
        for line in stream:
            steps+=1
            current=qa30a.parse_step(line,steps)
            if (current[1],current[2]) in original15:
                raise AssertionError("Native IP reached one of fifteen historically unobserved source cells")
            if previous is not None and previous[6]==0 and previous[5] in CONTROL:
                key,outcome,source_match,edge,_=observed_edge(previous,current,source,case)
                char=chr(previous[5])
                totals["control:"+char]+=1
                if edge["is_non_nominal"]:totals["nonnominal:"+char]+=1
                if edge["pre_execution_vector_changed"]:totals["vector_changed:"+char]+=1
                if first_edge is None:first_edge=(previous,current)
                distances={xy:abs(previous[1]-xy[0])+abs(previous[2]-xy[1])
                           for xy in original15}
                near={xy:d for xy,d in distances.items() if d<=MIN_NEIGHBOR_DISTANCE}
                if near:
                    if key not in site_map:
                        site_map[key]={"occurrences":0,"source_byte_matches":0,
                                       "outcomes":{}, "near":{}}
                    site=site_map[key]
                    site["occurrences"]+=1
                    site["source_byte_matches"]+=int(source_match)
                    for xy,d in near.items():
                        site["near"][xy]=min(d,site["near"].get(xy,10**8))
                    if outcome not in site["outcomes"]:
                        site["outcomes"][outcome]={"cases":set(),"occurrences":0,
                                                   "examples":[]}
                    variant=site["outcomes"][outcome]
                    variant["occurrences"]+=1
                    if case not in variant["cases"] and len(variant["examples"])<3:
                        variant["examples"].append({
                            "input":case,"origin_run":foundation.RUNS[group][0],
                            "shard":shard,"tick":previous[0],
                            "before":list(previous),"after":list(current)})
                    variant["cases"].add(case)
            previous=current
    need(steps==row.get("steps") and steps>50,
         "original Native actual physical STEP count incomplete")
    return steps,first_edge

def across_input_variation(outcomes):
    if len(outcomes)<2:return False
    variants=list(outcomes.values())
    for i in range(len(variants)):
        for j in range(i+1,len(variants)):
            a,b=variants[i]["cases"],variants[j]["cases"]
            if any(x!=y for x in a for y in b):return True
    return False

def pack_site(key,site,target=None):
    x,y,dx,dy,op=key
    result={"position":[x,y],"pre_execution_vector":[dx,dy],
            "runtime_opcode":op,"runtime_opcode_char":chr(op),
            "pre_execution_stringmode":0,
            "original_byte_match_count":site["source_byte_matches"],
            "executed_control_steps":site["occurrences"],
            "distinct_outcomes":len(site["outcomes"]),
            "different_input_outcomes_observed":across_input_variation(site["outcomes"]),
            "outcomes":[]}
    if target is not None:result["target"]=list(target);result["distance_l1"]=site["near"][target]
    for outcome,v in sorted(site["outcomes"].items()):
        result["outcomes"].append({
            "observed_displacement":list(outcome[:2]),
            "post_execution_vector":list(outcome[2:4]),
            "next_stringmode":outcome[4],
            "occurrences":v["occurrences"],
            "distinct_input_runs":len(v["cases"]),
            "witnesses":v["examples"]})
    return result

def main():
    pa=argparse.ArgumentParser()
    pa.add_argument("--source",required=True)
    pa.add_argument("--qa18",required=True)
    pa.add_argument("--qa30a",required=True)
    pa.add_argument("--root",required=True)
    pa.add_argument("--output",required=True)
    a=pa.parse_args()
    source=foundation.verified_source(a.source)
    cells=foundation.targets(a.qa18,source)
    old=original_qa30a(a.qa30a)
    missing=sorted(set(cells)-foundation.OLDER_HITS)
    need(len(missing)==NEW_SOURCE_CANDIDATE_EXPECTED and
         set(old["nearest_observed_control_transitions_by_15_source_candidates"])==
         {"%d,%d"%xy for xy in missing},"frozen fifteen original source cells mismatch")
    counts=collections.Counter()
    sites={}
    group_reports={}
    previous_cases=set()
    first=None
    negative_controls=0
    for group,(run,ncases,nsteps,nshard,filename) in foundation.RUNS.items():
        group_steps=0;group_cases=0
        for shard in range(4):
            folder=Path(a.root)/group/("shard%d"%shard)
            manifest=json.loads((folder/filename).read_bytes())
            foundation.receipt_header(manifest,group,shard,set(cells))
            negative_controls+=foundation.negative_controls(manifest,group,shard,set(cells))
            for row in manifest["records"]:
                key=(group,row["label"])
                need(key not in previous_cases,"duplicated original Native route")
                previous_cases.add(key)
                steps,edge=parse_native(folder,row,group,shard,source,set(missing),sites,counts)
                group_steps+=steps;group_cases+=1
                if first is None and edge is not None:first=edge
        need(group_cases==ncases and group_steps==nsteps,
             "historical original Native run program or STEP totals changed")
        group_reports[group]={"run":run,"cases":group_cases,"steps":group_steps}
    need(len(previous_cases)==136 and
         sum(r["steps"] for r in group_reports.values())==4513423,
         "incomplete original 136 Native STEP histories")
    need(first is not None and sum(v for k,v in counts.items() if k.startswith("control:"))>0,
         "no original dynamic controls actually observed")
    negative_controls+=qa30a.adversarial_edge_controls(
        qa30a.directed_edge(first[0],first[1]),first[0],first[1])
    need(negative_controls==70,"60 manifest + 10 physical STEP edge controls not rejected")
    targets={}
    for xy in missing:
        near=[pack_site(key,site,xy) for key,site in sites.items() if xy in site["near"]]
        near.sort(key=lambda q:(q["distance_l1"],
                                -int(q["different_input_outcomes_observed"]),
                                -q["distinct_outcomes"],
                                q["position"],q["runtime_opcode"]))
        targets["%d,%d"%xy]={
            "source_byte":cells[xy],"observed_distinct_control_states_within_l1_9":len(near),
            "observed_differential_control_states":sum(x["different_input_outcomes_observed"] for x in near),
            "nearest_control_state_examples":near[:MAX_NEAR_SITES_PER_TARGET],
            "target_reached_by_original_native_ip":False}
    total_differential=sum(across_input_variation(z["outcomes"]) for z in sites.values())
    total_differential_targets=sum(v["observed_differential_control_states"]>0 for v in targets.values())
    result={
        "schema":"qa31a-input-origin-136-native-control-outcome-variation-v1",
        "immutable_production_source_blob":SOURCE,"original_qa18_sha256":QA18,
        "original_qa30a_sha256":QA30A,"original_native_programs":136,
        "original_native_steps":4513423,"original_github_groups":group_reports,
        "sha256_checked_original_raw_trace_count":136,
        "original_source_candidate_count":21,"original_unobserved_target_count":15,
        "original_unobserved_targets_still_not_reached":15,
        "signed_native_runtime_control_opcode_steps":dict(sorted(counts.items())),
        "unique_near_control_pre_states":len(sites),
        "pre_states_with_multiple_outcomes_in_different_input_runs":total_differential,
        "targets_with_near_differential_control_pre_states":total_differential_targets,
        "per_original_unobserved_target":targets,
        "forged_manifest_and_step_edges_rejected":negative_controls,
        "observed_different_outcomes_is_not_input_causality":True,
        "different_pre_states_may_have_different_unobserved_stacks":True,
        "original_source_byte_ownership_globally_proven":False,
        "original_15_target_reachability_proven":False,
        "full_geometric_qa_pass":False,"full_functional_qa_pass":False,
        "stage1_complete":False}
    Path(a.output).write_text(json.dumps(result,sort_keys=True,indent=2)+"\n")
    print("QA31A_ORIGINAL_136_NATIVE_CONTROL_OUTCOME_VARIATION_RECONSTRUCTED",4513423)
    print("QA31A_OBSERVED_DIFFERENTIAL_PRESTATES",total_differential)
    print("QA31A_70_ORIGINAL_FORGED_EVIDENCE_CONTROLS_REJECTED",negative_controls)
    print("QA31A_NO_INPUT_CAUSALITY_OR_SOURCE_DEAD_CODE_PROOF")
if __name__=="__main__":main()
