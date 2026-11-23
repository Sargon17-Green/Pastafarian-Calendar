#!/usr/bin/env python3
"""Fail-closed independent receipt parser and cross-engine adjudication, one date only."""
from __future__ import annotations
import hashlib
import json
import re
import sys
from collections import Counter
from pathlib import Path

DAY = -15055671
PHASE_FIELDS = [
    "year_number","open_gate_index","close_gate_index","open_gate_day","close_gate_day",
    "first_day","year_length","offset0",
    "work_action","work_target","work_distance","work_connection","work_direction",
    "hidden_drops","visible_drops","initial_bowls","bowls_after_drops","order46","bowls_after_stir",
    "seal30_first","seal30_step","seal31_first","seal31_step",
    "seal32_first","seal32_step","seal33_first","seal33_step",
    "cutlet_count","cutlet_partition","cutlet_names",
    "month_low","month_high","month_choice_count","month_count_rank","month_count",
    "month_length_family_count","month_length_rank","month_lengths",
    "month_weave","month_name_rank","month_names",
    "month_id","month_name_index","day_in_month","day_in_cutlet","cutlet_id",
]
ARRAY_KEYS = {"hidden_drops","visible_drops","initial_bowls","bowls_after_drops",
              "order46","bowls_after_stir","cutlet_partition","cutlet_names",
              "month_lengths","weave_tickets","month_weave","month_names"}

def parse_ada(path: Path):
    lines = path.read_text("utf-8").splitlines()
    observed = {}
    results = []
    for line in lines:
        if line.startswith("ISSUE29_OBS "):
            raw = line[len("ISSUE29_OBS "):]
            if "=" not in raw:
                raise AssertionError("malformed observation")
            key,value = raw.split("=",1)
            key = re.sub(r"\s+","",key)
            if key in observed:
                raise AssertionError("duplicate field " + key)
            if not re.fullmatch(r"[a-z0-9_]+",key):
                raise AssertionError("bad field")
            if key in ARRAY_KEYS:
                observed[key] = [int(item.strip()) for item in value.split(",")]
            else:
                observed[key] = int(value.strip())
        elif line.startswith("ISSUE29_FINAL "):
            results.append([int(x) for x in line.split()[1:]])
    if len(results) != 1:
        raise AssertionError("expected exactly one Ada original-date observation")
    final = results[0]
    if final != [5000,10,503,30,52]:
        raise AssertionError("Ada original terminal tuple changed: "+str(final))
    return {"schema":"ISSUE29_ONE_DAY_INTERNAL_V187/1","engine":"Ada_derived_original",
            "input":[DAY,DAY],"source_commit":"a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72",
            "original_date_invocations":1,"observations":observed,"final":final}

def check(engine):
    o=engine["observations"]
    missing=[k for k in PHASE_FIELDS if k not in o]
    if missing:
        raise AssertionError(engine["engine"]+" missing mandatory fields "+str(missing))
    n=o["month_count"]
    lengths=o["month_lengths"]; weave=o["month_weave"]; names=o["month_names"]
    assert len(lengths)==n and 3<=n<=47
    assert all(4<=x<=123 for x in lengths)
    assert sum(lengths)==o["year_length"]==len(weave)
    assert all(Counter(weave)[i]==lengths[i-1] for i in range(1,n+1))
    assert len(names)==n and len(set(names))==n and all(1<=x<=47 for x in names)
    assert o["close_gate_day"]-o["open_gate_day"]==o["year_length"]
    assert o["first_day"]==o["open_gate_day"]+1
    assert o["offset0"]==DAY-o["first_day"]
    assert 0<=o["offset0"]<o["year_length"]
    assert weave[o["offset0"]]==o["month_id"]
    assert names[o["month_id"]-1]==o["month_name_index"]==engine["final"][3]
    assert sum(1 for x in weave[:o["offset0"]+1] if x==o["month_id"])==o["day_in_month"]==engine["final"][4]
    assert o["day_in_cutlet"]==engine["final"][2]
    assert 1<=o["cutlet_id"]<=o["cutlet_count"]<=17
    assert len(o["cutlet_names"])==len(o["cutlet_partition"])==o["cutlet_count"]
    assert len(o["hidden_drops"])==7 and len(o["visible_drops"])==46
    assert len(o["initial_bowls"])==len(o["bowls_after_drops"])==len(o["bowls_after_stir"])==6
    assert sorted(o["order46"])==[1,2,3,4,5,6]
    assert o["month_high"]-o["month_low"]+1==o["month_choice_count"]
    assert o["month_low"]<=n<=o["month_high"]
    assert 1<=o["month_count_rank"]<=o["month_choice_count"]
    assert len(weave)<=5778
    return {"year_and_gate":True,"sauce_shape":True,"months_and_projection":True}

def main():
    if len(sys.argv)!=4:
        raise SystemExit("usage: adjudicate.py ADA_STDOUT PYTHON.json VERDICT.json")
    ada_stdout,py_json,verdict_path=map(Path,sys.argv[1:])
    ada=parse_ada(ada_stdout)
    py=json.loads(py_json.read_bytes())
    assert py["schema"]==ada["schema"] and py["engine"]=="Python_original"
    assert py["input"]==ada["input"]==[DAY,DAY]
    assert py["original_date_invocations"]==ada["original_date_invocations"]==1
    assert py["final"]==[5000,10,503,20,56]
    checks={e["engine"]:check(e) for e in [ada,py]}
    first=None
    all_differences=[]
    for key in PHASE_FIELDS:
        x=ada["observations"][key];y=py["observations"][key]
        if x != y:
            mismatch={"field":key}
            if isinstance(x,list) and isinstance(y,list):
                idx=next((i for i in range(min(len(x),len(y))) if x[i]!=y[i]),None)
                mismatch.update({"ada_length":len(x),"python_length":len(y),
                                 "first_different_zero_based_index":idx,
                                 "ada_at_first":x[idx] if idx is not None else None,
                                 "python_at_first":y[idx] if idx is not None else None})
            else:
                mismatch.update({"ada":x,"python":y})
            all_differences.append(mismatch)
            if first is None:
                first=mismatch
    assert first is not None,"historical original discrepancy unexpectedly absent"
    verdict={
        "schema":ada["schema"],"status":"NUMERIC_DISAGREEMENT_LOCATED_NOT_ROOT_CAUSE_CERTIFIED",
        "first_observed_internal_mismatch":first,
        "all_common_mismatches":all_differences,
        "historical_ada_five_fields":ada["final"],
        "historical_python_five_fields":py["final"],
        "per_engine_invariants":checks,
        "structural_caveat":"Python globally ranks legal weaves; historical Ada uses fixed rails and cyclic tickets. Distinct intermediate ranks need not be directly equivalent.",
        "original_full_years_accepted":0,"stage42_opened":False,
        "original_date_calls_per_engine":1,
        "input":[DAY,DAY],
        "source_sha256":{
            "ada_stdout":hashlib.sha256(ada_stdout.read_bytes()).hexdigest(),
            "python_json":hashlib.sha256(py_json.read_bytes()).hexdigest(),
        },
        "ada_record":ada,
        "python_record":py,
    }
    data=(json.dumps(verdict,ensure_ascii=False,sort_keys=True,separators=(",",":"))+"\n").encode()
    if len(data)>2*1024*1024:
        raise AssertionError("evidence exceeds 2 MiB")
    verdict_path.write_bytes(data)
    print("ISSUE29_V187_FIRST_OBSERVED_INTERNAL_MISMATCH",json.dumps(first,sort_keys=True))
    print("ISSUE29_V187_VERDICT_SHA256",hashlib.sha256(data).hexdigest())

if __name__=="__main__":
    main()
