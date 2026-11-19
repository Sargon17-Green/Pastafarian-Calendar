#!/usr/bin/env python3
"""Read-only v115 native dispatch gate: 55 classified workflows, 24 stopped jobs."""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import re

SCHEMA="PASTAFARI_NATIVE_DISPATCH_INCIDENT_INTERLOCK_INVENTORY_V114/1"
OUT="PASTAFARI_QA_ALL_WORKFLOW_HALT_AUDIT_V115/1"
LOCK="PASTAFARI_CONFIRMED_NATIVE_FIRST_DIFFERENCE_AND_DISPATCH_HALT_V108/1"
BRANCH="qa/soak-readiness-20261114"
JOB=re.compile(r"^  ([a-zA-Z][\w-]*):\s*(?:#.*)?$",re.M)
IF=re.compile(r"^    if:\s*(.*?)\s*$",re.M)
HALT="${{ false }}"


def unique(pairs):
    result={}
    for k,v in pairs:
        if k in result:raise ValueError("duplicate safety JSON field")
        result[k]=v
    return result


def load_json(data:bytes)->dict:
    obj=json.loads(data.decode("utf8"),object_pairs_hook=unique)
    if type(obj) is not dict:raise ValueError("expected JSON object")
    return obj


def check_inventory(m:dict,lock:dict,files:dict[str,str])->dict:
    if (m.get("schema")!=SCHEMA or m.get("branch")!=BRANCH
        or m.get("repository")!="Sargon17-Green/Pastafarian-Calendar"
        or m.get("incident_issue")!=29 or m.get("governing_issue")!=27
        or m.get("decision")!="STOP_ALL_NEW_QA_NATIVE_SOAK_CONVERTER_DISPATCH"
        or m.get("lock_path")!="soak/control/confirmed_first_original_mismatch_dispatch_halt_v108.json"
        or m.get("main_must_remain_unchanged") is not True
        or m.get("full_original_years_passed")!=0
        or m.get("ten_thousand_soak_years_passed")!=0
        or m.get("first_difference")!={"calculation_day":"-15055671",
                                       "target_day":"-15055671",
                                       "field":"month_index","ada":30,"reference":20}):
        raise ValueError("invalid confirmed incident workflow inventory")
    if (lock.get("schema")!=LOCK or
        lock.get("decision")!="STOP_NEW_NATIVE_SOAK_DISPATCH"
        or lock.get("first_difference",{}).get("field")!="month_index"
        or lock.get("first_difference",{}).get("ada")!=30
        or lock.get("first_difference",{}).get("reference")!=20
        or lock.get("review_required_before_resuming_native_soak_dispatch") is not True
        or lock.get("main_changes_permitted") is not False
        or lock.get("successful_ten_thousand_soak_years")!=0):
        raise ValueError("confirmed v108 native HALT incident revoked")
    all_files=m.get("expected_workflow_paths")
    halted=m.get("native_dispatch_jobs_halted")
    remaining=m.get("classified_readonly_or_control_workflows")
    if not all(type(x) is list for x in (all_files,halted,remaining)):
        raise ValueError("incomplete workflow inventory")
    for items in (all_files,halted,remaining):
        if items!=sorted(set(items)) or any(
            type(path) is not str or
            not path.startswith(".github/workflows/") or
            not path.endswith((".yml",".yaml")) for path in items):
            raise ValueError("invalid or duplicate workflow paths")
    if (len(all_files)!=55 or len(halted)!=24 or len(remaining)!=31
        or set(halted)&set(remaining) or
        set(all_files)!=set(halted)|set(remaining)):
        raise ValueError("halt/readonly partition drift")
    if set(files)!=set(all_files):
        raise ValueError("unclassified or missing CI workflows "+
                         repr(sorted(set(files)^set(all_files))))
    inspected=0
    for name in all_files:
        source=files[name]
        if type(source) is not str or source.count("\n")<5:
            raise ValueError("malformed workflow "+name)
        blocks=list(re.finditer(r"^jobs:\s*$",source,re.M))
        if len(blocks)!=1:raise ValueError("cannot identify exactly one jobs map "+name)
        body=source[blocks[0].end():]
        jobs=list(JOB.finditer(body))
        if not jobs:raise ValueError("workflow has no jobs "+name)
        for i,j in enumerate(jobs):
            section=body[j.end():jobs[i+1].start() if i+1<len(jobs) else len(body)]
            conditions=IF.findall(section)
            inspected+=1
            if name in halted and conditions!=[HALT]:
                raise ValueError("unguarded native job "+name+"/"+j.group(1))
            if name in remaining and conditions==[HALT]:
                raise ValueError("readonly job unexpectedly stopped "+name)
    return {"schema":OUT,
            "status":"QA_NATIVE_SOAK_DISPATCH_FAIL_CLOSED_ALL_24_JOBS",
            "classified_workflows":len(all_files),
            "blocked_native_workflows":len(halted),
            "preserved_readonly_or_control_workflows":len(remaining),
            "jobs_inspected":inspected,
            "scientific_incident_status":"CONFIRMED_CROSS_SOURCE_DIFFERENCE",
            "protected_historic_commits_or_other_branches":False,
            "new_original_conversions_started_by_audit":0,
            "full_original_years_certified":0,
            "ten_thousand_years_certified":0}


def load_tree(root:Path):
    m=load_json((root/"soak/control/native_dispatch_halt_inventory_v114.json").read_bytes())
    lock=load_json((root/"soak/control/confirmed_first_original_mismatch_dispatch_halt_v108.json").read_bytes())
    files={p.relative_to(root).as_posix():p.read_text(encoding="utf8")
           for p in (root/".github/workflows").iterdir() if p.suffix in (".yaml",".yml")}
    return m,lock,files


def main():
    p=argparse.ArgumentParser()
    p.add_argument("--root",required=True,type=Path)
    p.add_argument("--verdict-out",required=True,type=Path)
    a=p.parse_args()
    result=check_inventory(*load_tree(a.root.resolve(strict=True)))
    with a.verdict_out.open("x",encoding="utf8") as f:
        json.dump(result,f,sort_keys=True,ensure_ascii=False,indent=2)
        f.write("\n")
    print("V115_ALL_24_NATIVE_JOBS_VERIFIED_DISABLED_NO_SOURCE_EXECUTION")


if __name__=="__main__":
    main()
