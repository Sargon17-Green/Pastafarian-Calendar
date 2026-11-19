#!/usr/bin/env python3
"""v109: read-only three-artifact adjudication of original F(c,t) mismatch.

No date calculations, source compilation, subprocess execution, write to source,
or native converter dispatch. A successful evidence audit MUST report scientific
MISMATCH, not a successful soak comparison.
"""
from __future__ import annotations
import argparse
import hashlib
import io
import json
from pathlib import Path
import re
import zipfile

ROOT=Path(__file__).resolve().parents[1]
LOCK_PATH=ROOT/"control/confirmed_first_original_mismatch_dispatch_halt_v108.json"
SCHEMA="PASTAFARI_READ_ONLY_FIRST_ORIGINAL_MISMATCH_REPLAY_V109/1"
HEX=re.compile(r"[0-9a-f]{64}\Z")
DAY="-15055671"
FIELDS=("year","cutlet_index","day_in_cutlet","month_index","day_in_month")


def sha(data:bytes)->str:
    return hashlib.sha256(data).hexdigest()


def uniq_pairs(pairs):
    result={}
    for k,v in pairs:
        if k in result:
            raise ValueError("duplicate field in original source evidence")
        result[k]=v
    return result


def json_record(data:bytes)->dict:
    x=json.loads(data.decode("utf-8"),object_pairs_hook=uniq_pairs)
    if type(x) is not dict:
        raise ValueError("source evidence object expected")
    return x


def load_lock()->dict:
    return json_record(LOCK_PATH.read_bytes())


def verify_lock(lock:dict)->None:
    if (lock.get("schema")!="PASTAFARI_CONFIRMED_NATIVE_FIRST_DIFFERENCE_AND_DISPATCH_HALT_V108/1"
        or lock.get("status")!="CONFIRMED_CROSS_ORIGINAL_SOURCE_NUMERIC_MISMATCH"
        or lock.get("decision")!="STOP_NEW_NATIVE_SOAK_DISPATCH"
        or lock.get("parent_contract_issue")!=27
        or lock.get("incident_issue")!=29
        or lock.get("calculation_day")!=DAY or lock.get("target_day")!=DAY
        or lock.get("field_order")!=list(FIELDS)
        or lock.get("first_difference")!={"field":"month_index","field_index_one_based":4,
                                         "ada":30,"reference":20,
                                         "matched_numeric_fields_before_first_difference":3}
        or lock.get("native_ada",{}).get("five_fields")!=[5000,10,503,30,52]
        or lock.get("reference_python_ts",{}).get("original_reference_five_fields")!=[5000,10,503,20,56]
        or lock.get("independent_fourth_observation",{}).get("five_fields")!=[5000,10,503,20,56]
        or lock.get("successful_original_source_full_years")!=0
        or lock.get("successful_ten_thousand_soak_years")!=0
        or lock.get("overall_all_converter_pass") is not False
        or lock.get("main_changes_permitted") is not False
        or lock.get("review_required_before_resuming_native_soak_dispatch") is not True
        or lock.get("source_lineage_independence_certified") is not False
        or lock.get("oracle_canonical_proof_certified") is not False
        or "new_soak_native_converter_dispatch" not in lock.get("prohibited_actions",[])
        ):
        raise ValueError("missing or altered first-mismatch dispatch-halt lock")
    for name,key in (("run","artifact_sha256"),
                     ("native_ada","native_log_sha256"),
                     ("native_ada","verdict_sha256"),
                     ("reference_python_ts","archive_sha256"),
                     ("independent_fourth_observation","artifact_sha256"),
                     ("independent_fourth_observation","native_log_sha256"),
                     ("independent_fourth_observation","verdict_sha256")):
        s=lock.get(name,{}).get(key)
        if type(s) is not str or not HEX.fullmatch(s):
            raise ValueError("incident source digest missing or invalid")


def archive(data:bytes,expected_sha:str,expected_size:int,count:int)->dict[str,bytes]:
    if len(data)!=expected_size or sha(data)!=expected_sha:
        raise ValueError("immutably pinned artifact ZIP size/SHA differs")
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        info=z.infolist()
        if len(info)!=count or len({i.filename for i in info})!=count:
            raise ValueError("original source ZIP member count/uniqueness changed")
        if z.testzip() is not None:
            raise ValueError("source ZIP CRC failure")
        for i in info:
            if i.is_dir() or ".." in Path(i.filename).parts or i.file_size>1000000:
                raise ValueError("unsafe source ZIP member")
        return {i.filename:z.read(i) for i in info}


def original_native(line:bytes,marker:str)->list[int]:
    parts=line.decode("utf-8").strip().split()
    if len(parts)!=8 or parts[0]!=marker:
        raise ValueError("one complete original native F(c,t) row required")
    if any(re.fullmatch(r"(?:0|-[1-9][0-9]*|[1-9][0-9]*)",s) is None for s in parts[1:]):
        raise ValueError("noncanonical numeric original source output")
    nums=[int(v) for v in parts[1:]]
    if nums[:2]!=[int(DAY),int(DAY)]:
        raise ValueError("original source c,t identity changed")
    return nums[2:]


def native_log(art:dict[str,bytes],name:str,marker:str,expected_digest:str)->list[int]:
    data=art[name]
    if sha(data)!=expected_digest:
        raise ValueError("native process transcript digest changed")
    if data.count(b"\n")!=1 or not data.endswith(b"\n"):
        raise ValueError("native source transcript missing or duplicated")
    return original_native(data,marker)


def replay(lock:dict,a103:bytes,a106:bytes,a101:bytes)->dict:
    verify_lock(lock)
    # All three archives are original GitHub Actions evidence, not derived dates.
    one=archive(a103,lock["run"]["artifact_sha256"],lock["run"]["artifact_bytes"],
                lock["run"]["artifact_members"])
    two=archive(a106,lock["independent_fourth_observation"]["artifact_sha256"],
                lock["independent_fourth_observation"]["artifact_bytes"],
                lock["independent_fourth_observation"]["artifact_members"])
    three=archive(a101,lock["reference_python_ts"]["archive_sha256"],
                  lock["reference_python_ts"]["artifact_bytes"],53)
    if two["v106-python-source.zip"]!=a101:
        raise ValueError("Fortran native run compared different original Python archive")
    ada=native_log(one,"v103-original-ada-native.log","V103_ADA_ORIGINAL_FCT_NATIVE",
                   lock["native_ada"]["native_log_sha256"])
    fortran=native_log(two,"v106-native-output.log","V106_FORTRAN_ORIGINAL_FCT_NATIVE",
                       lock["independent_fourth_observation"]["native_log_sha256"])
    ada_verdict=one[lock["native_ada"]["verdict"]]
    fr_verdict=two["v106-source-verdict.json"]
    if (sha(ada_verdict)!=lock["native_ada"]["verdict_sha256"]
        or sha(fr_verdict)!=lock["independent_fourth_observation"]["verdict_sha256"]):
        raise ValueError("native first-difference judgment digest mismatch")
    av=json_record(ada_verdict)
    fv=json_record(fr_verdict)
    ref=json_record(three["original-python-0-normalized.jsonl"])
    pyraw=json_record(three["original-python-0-raw.jsonl"])
    tsraw=json_record(three["original-typescript-0-raw.jsonl"])
    catalog=json_record(three["original-typescript-0-catalog.json"])
    if ref.get("calculation_day")!=DAY or ref.get("target_day")!=DAY:
        raise ValueError("original Python signed coordinates changed")
    if (pyraw.get("calculation_day")!=DAY or pyraw.get("target_day")!=DAY
        or ref.get("source_raw_sha256")!=sha(three["original-python-0-raw.jsonl"])):
        raise ValueError("original Python raw provenance mismatch")
    py=[int(ref["year"]),ref["cutlet_index"],ref["day_in_cutlet"],
        ref["month_index"],ref["day_in_month"]]
    if not all(type(x) is int for x in py):
        raise ValueError("original Python source native identifiers invalid")
    if (tsraw.get("calculation_day")!=DAY or tsraw.get("target_day")!=DAY):
        raise ValueError("original TypeScript signed coordinates changed")
    vals=tsraw["native_tuple"]
    if type(vals) is not list or len(vals)!=5:
        raise ValueError("original TypeScript five native fields missing")
    cutlets=catalog["cutlets"]
    months=catalog["months"]
    ts=[int(vals[0]),cutlets.index(vals[1])+1,int(vals[2]),
        months.index(vals[3])+1,int(vals[4])]
    if (py!=lock["reference_python_ts"]["original_reference_five_fields"]
        or ts!=py or fortran!=py):
        raise ValueError("original Python, TypeScript, Fortran witnesses differ")
    if ada!=lock["native_ada"]["five_fields"]:
        raise ValueError("pinned Ada original source has changed")
    first=next((i for i in range(5) if ada[i]!=py[i]),None)
    if first!=3 or ada[3]!=30 or py[3]!=20 or ada[4]!=52 or py[4]!=56:
        raise ValueError("replayed FIRST original mismatch differs from frozen incident")
    if (av.get("status")!="ORIGINAL_ADA_CANONICAL_NUMERIC_MISMATCH"
        or av.get("ada_original_five_fields")!=ada
        or av.get("python_original_five_fields")!=py
        or av.get("first_mismatch")!={"field":"month_index",
                                     "field_index_one_based":4,
                                     "ada_original":30,"pinned_python_original":20}
        or av.get("original_ada_commit")!=lock["run"]["native_original_commit"]
        or fv.get("status")!="FOURTH_ORIGINAL_ENGINE_ONE_DAY_MATCH_NOT_YEAR"
        or fv.get("fortran_native_five_fields")!=fortran
        or fv.get("python_native_five_fields")!=py
        or fv.get("first_mismatch") is not None):
        raise ValueError("original source native verdict conflicts with immutable raw")
    return {
        "schema":SCHEMA,
        "scientific_status":"CONFIRMED_DIFFERENTIAL_FAIL",
        "audit_status":"IMMUTABLE_ORIGINAL_SOURCE_ARTIFACTS_VERIFIED",
        "stop_new_native_soak_dispatch":True,
        "first_difference":{"field":"month_index","index":4,"ada":30,"reference":20},
        "c":DAY,"t":DAY,
        "native_engines_observed":4,
        "ada_original":ada,"python_typescript_fortran_original":py,
        "source_artifacts_checked":[lock["run"]["artifact_id"],
                                    lock["reference_python_ts"]["artifact_id"],
                                    lock["independent_fourth_observation"]["artifact_id"]],
        "successful_whole_years":0,
        "successful_ten_thousand_soak_years":0,
        "canonical_oracle_independence_proven":False,
        "windows_runtime_certified":False,
    }


def main():
    p=argparse.ArgumentParser()
    p.add_argument("--ada-artifact",required=True,type=Path)
    p.add_argument("--fortran-artifact",required=True,type=Path)
    p.add_argument("--reference-artifact",required=True,type=Path)
    p.add_argument("--report-out",required=True,type=Path)
    args=p.parse_args()
    result=replay(load_lock(),args.ada_artifact.read_bytes(),
                  args.fortran_artifact.read_bytes(),args.reference_artifact.read_bytes())
    with args.report_out.open("x",encoding="utf-8") as f:
        json.dump(result,f,sort_keys=True,ensure_ascii=False,indent=2)
        f.write("\n")
    print("V109_READ_ONLY_ARTIFACT_AUDIT_PASS_SCIENTIFIC_MISMATCH_HALT_DISPATCH")


if __name__=="__main__":
    main()
