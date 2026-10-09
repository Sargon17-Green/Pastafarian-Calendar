#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Independent QA-only consistency audit of REAL Native fork-result evidence.

This does NOT reinterpret Befunge or claim to authenticate absent raw traces.
The separate Python-2 runner creates the evidence from real pinned PyFunge
executions and independent Befunge oracles. This Python-3 checker verifies
that all 32 records coherently tie together true motion direction, observed
and forced branch classes, final-output classification and the SHA-256
fingerprints of the five corresponding TOSS snapshots on each branch.

Six hostile REPORT mutations must fail the SAME checker, independently
of producer-side trivial in-memory comparisons. This is an evidence
contract, not a completed Stage-1 or full semantic state audit.
"""
import copy
import hashlib
import json
import os
import re
import sys

SOURCE="src/interleaved_work_counts.b98"
PIN="560d6aa5807a7f766213a33835cce85eab0fa40c"
SCHEMA="befunge-stage1-current-native-fork-route-differential-v4"
VALID_SHA=re.compile(r"^[0-9a-f]{64}$")
SPECIAL={"zero_equal":False,"foundation_cross":True,
         "forward_short":False,"mixed_small":True}

def require(ok,message):
    if not ok: raise AssertionError(message)

def source_git_blob(path):
    with open(path,"rb") as stream: data=stream.read()
    return hashlib.sha1(("blob %d\0"%len(data)).encode("ascii")+data).hexdigest()

def verify(proof):
    require(proof.get("schema")==SCHEMA and
            proof.get("source_git_blob")==PIN and
            proof.get("status")=="QA_ONLY_UPSTREAM_FORK_CAUSALITY_OPEN",
            "native evidence source/schema/status mismatch")
    require(proof.get("real_PyFunge_runs")==64 and
            proof.get("valid_input_cases")==32 and
            proof.get("native_route_changed_cases")==32 and
            proof.get("native_toss_rejoin_snapshots_measured")==320,
            "native trial/snapshot counts mismatch")
    cases=proof.get("records")
    require(isinstance(cases,list) and len(cases)==32,
            "expected 32 distinct actual Native records")
    labels=[x.get("case") for x in cases]
    require(all(isinstance(x,str) and x for x in labels) and
            len(set(labels))==32 and
            all(x in labels for x in SPECIAL),
            "duplicated/missing case labels in native evidence")
    tally={"zero":0,"nonzero":0,"causal":0,"inert":0,
           "rejoin_full_toss_equal":0}
    for record in cases:
        label=record["case"]
        original=record.get("gate_observed_nonzero")
        forced=record.get("gate_forced_nonzero")
        require(type(original) is int and original in (0,1) and
                type(forced) is int and forced==1-original,
                "actual/native opposite-fork class mismatch: "+label)
        v0=record.get("native_first_control_vector")
        v1=record.get("native_first_mutant_vector")
        require(isinstance(v0,list) and isinstance(v1,list) and
                len(v0)==len(v1)==5 and
                v0[:4]==[951,1336 if original==0 else 1334,0,1 if original==0 else -1] and
                v1[:4]==[951,1334 if original==0 else 1336,0,-1 if original==0 else 1] and
                v0[4]==v1[4],
                "Native IP vectors do not show true opposite conditional direction: "+label)
        require(record.get("different_native_route") is True,
                "Native opposite route witness missing: "+label)
        common=record.get("first_common_five_event_motion")
        require(isinstance(common,dict) and
                len(common.get("real_motion_sample",[]))==5 and
                all(isinstance(row,list) and len(row)==5
                    for row in common["real_motion_sample"]) and
                0<=common.get("original_offset",-1)<=507 and
                0<=common.get("mutant_offset",-1)<=507,
                "real five-motion convergence evidence missing: "+label)
        dig0=record.get("first_rejoin_toss_sha256_control")
        dig1=record.get("first_rejoin_toss_sha256_forced")
        reported=record.get("first_rejoin_native_toss_equal_each_step")
        depth0=record.get("first_rejoin_toss_depth_control")
        depth1=record.get("first_rejoin_toss_depth_forced")
        require(all(isinstance(arr,list) and len(arr)==5 for arr in
                    (dig0,dig1,reported,depth0,depth1)) and
                all(isinstance(x,str) and VALID_SHA.match(x)
                    for x in dig0+dig1) and
                all(type(flag) is bool for flag in reported) and
                all(type(depth) is int and depth>=0
                    for depth in depth0+depth1),
                "five-step Native TOSS hash/depth fields malformed: "+label)
        actual_equal=[left==right for left,right in zip(dig0,dig1)]
        require(actual_equal==reported and
                sum(reported)==record.get("first_rejoin_native_toss_equal_count") and
                all(reported)==record.get("first_rejoin_native_toss_identical_all_five") and
                depth0==depth1 and
                [row[4] for row in common["real_motion_sample"]]==depth0,
                "real five-step TOSS/hash/count/motion contradiction: "+label)
        # Independent five-checkpoint snapshot provenance: the producer
        # reports SHA-256 digests of *all native stack frames* and of the
        # sparse p-mutated Funge-space cells at each common IP motion.
        # The consistency check does not invent frame contents or replay
        # an unprovided Funge-space; it rejects any contradictory summary.
        for prefix in ("all_stack_frames","p_modified_cells"):
            control=record.get("first_rejoin_"+prefix+"_sha256_control")
            forced_hashes=record.get("first_rejoin_"+prefix+"_sha256_forced")
            equal_steps=record.get("first_rejoin_"+prefix+"_equal_each_step")
            equal_count=record.get("first_rejoin_"+prefix+"_equal_count")
            require(all(isinstance(z,list) and len(z)==5 for z in
                        (control,forced_hashes,equal_steps)) and
                    all(isinstance(value,str) and VALID_SHA.match(value)
                        for value in control+forced_hashes) and
                    all(type(flag) is bool for flag in equal_steps) and
                    [x==y for x,y in zip(control,forced_hashes)]==equal_steps and
                    sum(equal_steps)==equal_count,
                    "native full-frame/p-cell snapshot digest/class contradiction: "+
                    label+"/"+prefix)
        for prefix in ("frame_count","p_modified_cells_count"):
            cnt0=record.get("first_rejoin_"+prefix+"_control")
            cnt1=record.get("first_rejoin_"+prefix+"_forced")
            require(all(isinstance(a,list) and len(a)==5 and
                        all(type(n) is int and n>=0 for n in a)
                        for a in (cnt0,cnt1)),
                    "native stack frame/p-write count shape mismatch: "+
                    label+"/"+prefix)
        require(record.get("all_fungespace_mutators_audited") is False,
                "unsupported claim of full Funge-space state equivalence")
        causal=record.get("changed_final_semantics")
        require(type(causal) is bool and causal==(original==0) and
                all(reported)==(not causal) and
                sum(reported)==(0 if causal else 5) and
                record.get("full_semantic_state_equivalence_proven") is False,
                "observed output class/TOSS equivalence disagreement: "+label)
        if label in SPECIAL:
            require(causal==SPECIAL[label],
                    "frozen historical Native branch result changed: "+label)
        tally["zero" if original==0 else "nonzero"]+=1
        tally["causal" if causal else "inert"]+=1
        tally["rejoin_full_toss_equal"]+=int(all(reported))
    require(tally=={"zero":12,"nonzero":20,"causal":12,"inert":20,
                    "rejoin_full_toss_equal":20},
            "Native output/branch/TOSS corpus totals changed")
    require(proof.get("native_stack_frame_rejoin_snapshots_measured")==320 and
            proof.get("native_p_mutated_cell_rejoin_snapshots_measured")==320 and
            proof.get("non_p_fungespace_mutations_excluded_from_proof") is True and
            proof.get("native_frame_all_five_equal_cases")==sum(
                all(row["first_rejoin_all_stack_frames_equal_each_step"])
                for row in cases) and
            proof.get("native_p_changed_cells_all_five_equal_cases")==sum(
                all(row["first_rejoin_p_modified_cells_equal_each_step"])
                for row in cases),
            "reported frame/p-cell Native totals disagree with observed cases")
    require(proof.get("zero_operand_cases")==12 and
            proof.get("nonzero_operand_cases")==20 and
            proof.get("zero_operand_final_causal_cases")==12 and
            proof.get("nonzero_operand_final_inert_cases")==20 and
            proof.get("final_semantics_changed_cases")==12 and
            proof.get("final_semantics_inert_cases")==20 and
            proof.get("native_toss_equal_all_five_cases")==20 and
            proof.get("native_toss_equal_all_five_inert_cases")==20 and
            proof.get("native_toss_unequal_all_five_output_causal_cases")==12 and
            proof.get("full_fungespace_or_soss_equivalence_not_claimed") is True,
            "top-level Native aggregate proof inconsistent")
    return tally

def must_reject(label,data,change):
    forged=copy.deepcopy(data)
    change(forged)
    try:
        verify(forged)
    except AssertionError as err:
        print("NATIVE_FORK_EVIDENCE_CONSISTENCY_NEGATIVE_REJECT_PASS",
              label,str(err)[:120])
        return label
    raise AssertionError("forged native branch report incorrectly accepted: "+label)

def main(folder):
    require(os.path.isdir(folder),"Native fork evidence output folder missing")
    require(source_git_blob(SOURCE)==PIN,
            "QA production Funge source changed since real Native evidence")
    with open(os.path.join(folder,"current_fork_native_route_differential.json"),
              "r",encoding="utf-8") as stream:
        data=json.load(stream)
    counts=verify(data)
    print("NATIVE_FORK_32_INDEPENDENT_MANIFEST_TOSS_CHECK_PASS",counts)
    attempts=(
        ("forged_toss_digest",lambda p:p["records"][0]
            ["first_rejoin_toss_sha256_forced"].__setitem__(0,"f"*64)),
        ("forged_equal_flag",lambda p:p["records"][0]
            ["first_rejoin_native_toss_equal_each_step"].__setitem__(0,False)),
        ("forged_branch_class",lambda p:p["records"][0].__setitem__(
            "gate_observed_nonzero",0)),
        ("forged_output_causality",lambda p:p["records"][0].__setitem__(
            "changed_final_semantics",True)),
        ("duplicate_case",lambda p:p["records"][1].__setitem__(
            "case",p["records"][0]["case"])),
        ("forged_aggregate",lambda p:p.__setitem__(
            "native_toss_equal_all_five_cases",19)),
        ("forged_full_frame_digest",lambda p:p["records"][0]
            ["first_rejoin_all_stack_frames_sha256_control"].__setitem__(0,"f"*64)),
        ("forged_p_cell_digest",lambda p:p["records"][0]
            ["first_rejoin_p_modified_cells_sha256_forced"].__setitem__(0,"f"*64)),
        ("forged_full_frame_equal_flag",lambda p:p["records"][0]
            ["first_rejoin_all_stack_frames_equal_each_step"].__setitem__(0,False)))
    refused=[must_reject(name,data,change) for name,change in attempts]
    require(len(refused)==9,"negative manifest checks incomplete")
    report={"schema":"befunge-stage1-native-fork-manifest-adversarial-v2",
            "status":"QA_ONLY_NOT_FINAL_STAGE1_ACCEPTANCE",
            "source_blob":PIN,
            "external_raw_native_trace_replay_claimed":False,
            "positive_evidence_records_verified":32,
            "verified_measurement_classes":counts,
            "forged_manifest_variants_rejected":refused}
    with open(os.path.join(folder,"native_fork_manifest_adversarial_audit.json"),
              "w",encoding="utf-8") as stream:
        json.dump(report,stream,sort_keys=True,indent=2)
        stream.write("\n")
    print("NATIVE_FORK_32_MANIFEST_AND_SIX_ADVERSARIES_PASS",
          32,"positive,9 negative")
    print("GEOMETRIC_SPAGHETTI_QA_PASS=NO; no full-state equivalence asserted")

if __name__=="__main__":
    require(len(sys.argv)==2,
            "usage: stage1_native_current_fork_evidence_audit.py NATIVE_EVIDENCE_DIR")
    main(sys.argv[1])
