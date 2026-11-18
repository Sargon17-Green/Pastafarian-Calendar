#!/usr/bin/env python3
"""v102: offline replay of real, pinned, four-target original source evidence.

No source process, conversion, oracle, cache, or new year credit. Fail closed on
ZIP bytes, ZIP members, raw/native row identity, source receipts, per-day
first-difference verdict and independent GNU time/RSS transcript readings.
"""
from __future__ import annotations
import argparse
from hashlib import sha256
import io
import json
from pathlib import Path
import re
import stat
from tempfile import TemporaryDirectory
import zipfile

from audit_original_sample_v101 import audit_one, SAMPLES
from audit_ts_original_v094 import _line

PIN = Path(__file__).resolve().parents[1]/"control/stratified_original_v101_pin_v102.json"
ZIP_SHA = "bb256c2a8e6d599f7f78aa2264129d4ab4ff0dc0c9b8680077149de55b752ff1"
SCHEMA = "PASTAFARI_STRATIFIED_ORIGINAL_SOURCE_PIN_V102/1"
OUT_SCHEMA = "PASTAFARI_STRATIFIED_ORIGINAL_OFFLINE_REPLAY_V102/1"
PY_SRC_SHA = "75d56765b45892940326f67bd85a2c7c9874c01e43b49ee3553c9f6192d94378"
HEX = re.compile("[0-9a-f]{64}\\Z")


def digest(data:bytes)->str:
    return sha256(data).hexdigest()


def no_duplicate_pairs(pairs):
    out={}
    for k,v in pairs:
        if k in out:raise ValueError("duplicate JSON evidence field")
        out[k]=v
    return out


def parsed(data:bytes)->dict:
    obj=json.loads(data.decode("utf-8"),object_pairs_hook=no_duplicate_pairs)
    if type(obj) is not dict:raise ValueError("evidence is not an object")
    return obj


def load_pin()->dict:
    return parsed(PIN.read_bytes())


def validate_pin(p:dict)->None:
    if (p.get("schema")!=SCHEMA or p.get("run")!={
            "id":44392067310,"conclusion":"success",
            "head_sha":"749d8d9c9b74889d00135f4b10c6781ad124d42c"} or
        p.get("artifact")!={
            "id":14469537094,
            "filename":"soak-v101-serial-four-point-original-source-performance-not-year.zip",
            "zip_sha256":ZIP_SHA,"zip_bytes":24119,"zip_members":53} or
        p.get("source_commits")!={
            "REF-41":"0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4",
            "TS-MR":"cc3a613e3b80ba082e5cdb2c7a5d756c7e707df0"} or
        p.get("source_source_sha256")!={
            "REF-41":PY_SRC_SHA,
            "TS-MR-entrypoint":"a611f6b99bf982db7e6f3bbb3ac7b59b2ef9596993fe2f041dbf299d105fa030",
            "TS-MR-catalog":"3b53acf4f70f5d49096e1783ab703073b571007f751643b2d42af0552f57bff6"} or
        p.get("year")!=5000 or p.get("calculation_day")!="-15055671" or
        p.get("ordered_target_days")!=list(SAMPLES) or
        p.get("original_day_pair_comparisons")!=4 or
        p.get("verified_five_field_comparisons")!=20 or
        p.get("first_mismatch") is not None or
        p.get("raw_receipt_sha256")!="8c3e8e1bc36c117c198096ef91689f9971800b7e8daa3075c7c83a8f4bdcfe3d" or
        p.get("new_unique_targets_from_this_run")!=3 or
        p.get("distinct_source_target_days_total")!=17 or
        p.get("three_engine_target_days_total")!=2 or
        p.get("full_original_years_certified")!=0 or
        p.get("ten_thousand_years_certified")!=0 or
        p.get("algorithmic_independence_certified") is not False or
        p.get("windows_runtime_certified") is not False or
        type(p.get("rows")) is not list or len(p["rows"])!=4):
        raise ValueError("frozen original source pin identity mismatch")
    for i,r in enumerate(p["rows"]):
        if (r.get("target_day")!=SAMPLES[i] or type(r.get("fields")) is not list or
            len(r["fields"])!=5 or type(r["fields"][0]) is not str or
            any(type(x) is not int for x in r["fields"][1:]) or
            set(r.get("native_raw_sha256",{}))!={"REF-41","TS-MR"} or
            any(type(d) is not str or HEX.fullmatch(d) is None for d in
                r["native_raw_sha256"].values())):
            raise ValueError("per-day immutable original source pin altered")


def validate_zip(raw:bytes,p:dict)->dict[str,bytes]:
    validate_pin(p)
    if len(raw)!=24119 or digest(raw)!=ZIP_SHA:
        raise ValueError("pinned source ZIP size/SHA-256 mismatch")
    with zipfile.ZipFile(io.BytesIO(raw)) as z:
        info=z.infolist()
        names=[x.filename for x in info]
        if len(names)!=53 or len(set(names))!=53 or z.testzip() is not None:
            raise ValueError("ZIP member count, duplication, or CRC invalid")
        out={}
        for item in info:
            if (item.is_dir() or stat.S_ISLNK(item.external_attr>>16) or
                not re.fullmatch(r"[A-Za-z0-9_.-]+",item.filename) or
                item.file_size<=0 or item.file_size>80000):
                raise ValueError("unsafe original source evidence ZIP member")
            out[item.filename]=z.read(item)
        return out


def number_from_time(source:str,label:str):
    m=re.search(r"^\s*"+re.escape(label)+r":\s*(.*?)\s*$",source,re.M)
    if m is None:raise ValueError("missing GNU time source metric: "+label)
    return m.group(1)


def replay(archive:bytes,pin:dict)->dict:
    items=validate_zip(archive,pin)
    report=parsed(items["v101-source-performance-verdict.json"])
    if digest(items["v101-source-performance-verdict.json"])!=pin["raw_receipt_sha256"]:
        raise ValueError("frozen four-case timing receipt digest mismatch")
    if (report.get("schema")!="PASTAFARI_ORIGINAL_SOURCE_PERFORMANCE_SAMPLE_V101/1" or
        report.get("status")!="FOUR_ORIGINAL_SOURCE_PAIRS_MATCH_NOT_FULL_YEAR" or
        report.get("target_days")!=list(SAMPLES) or
        report.get("original_source_pairs")!=4 or report.get("matched_fields")!=20 or
        report.get("first_mismatch") is not None or
        report.get("whole_original_years_certified")!=0 or
        report.get("ten_thousand_years_certified")!=0 or
        report.get("independence_certified") is not False or
        report.get("windows_certified") is not False or
        report.get("source_commits")!=pin["source_commits"] or
        type(report.get("rows")) is not list or len(report["rows"])!=4):
        raise ValueError("original performance receipt exceeds source evidence")
    findings=[]
    with TemporaryDirectory(prefix="soak-v102-replay-") as d:
        folder=Path(d)
        for name,data in items.items():
            (folder/name).write_bytes(data)
        for i,day in enumerate(SAMPLES):
            receipt=audit_one(folder,day)
            if parsed(items[f"v101-one-day-verdict-{i}.json"])!=receipt:
                raise ValueError("original first-difference verifier failed replay")
            if receipt["canonical_fields"]!=pin["rows"][i]["fields"]:
                raise ValueError("pinned original five fields differ")
            python_raw=items[f"original-python-{i}-raw.jsonl"]
            ts_raw=items[f"original-typescript-{i}-raw.jsonl"]
            if (digest(python_raw)!=pin["rows"][i]["native_raw_sha256"]["REF-41"] or
                digest(ts_raw)!=pin["rows"][i]["native_raw_sha256"]["TS-MR"]):
                raise ValueError("raw engine output does not match source pin")
            py_receipt=parsed(items[f"original-python-{i}-receipt.json"])
            if (py_receipt.get("status")!="NATIVE_TRANSPORT_OUTPUT_COMPLETE_NOT_COMPARED" or
                py_receipt.get("engine")!="REF-41" or
                py_receipt.get("source_commit")!=pin["source_commits"]["REF-41"] or
                py_receipt.get("source_sha256")!=PY_SRC_SHA or
                py_receipt.get("calculation_day")!="-15055671" or
                py_receipt.get("first_target_day")!=day or
                py_receipt.get("last_target_day")!=day or
                py_receipt.get("rows")!=1 or
                py_receipt.get("raw_stream_sha256")!=digest(python_raw) or
                py_receipt.get("normalized_stream_sha256")!=digest(
                    items[f"original-python-{i}-normalized.jsonl"]) or
                py_receipt.get("verified_comparisons_completed")!=0):
                raise ValueError("Python original process source receipt changed")
            prior=report["rows"][i]
            if (prior.get("target_day")!=day or
                prior.get("matched_original_source_fields")!=receipt["canonical_fields"] or
                prior.get("raw_sha256")!={"python":digest(python_raw),"typescript":digest(ts_raw)}):
                raise ValueError("native performance receipt differs from evidence")
            for engine in ("python","typescript"):
                metric=prior["timing_and_memory"][engine]
                timed=items[f"v101-{engine}-{i}-time.txt"].decode("utf-8")
                if (metric["peak_resident_kib"]!=int(number_from_time(
                        timed,"Maximum resident set size (kbytes)")) or
                    metric["user_cpu_seconds"]!=float(number_from_time(
                        timed,"User time (seconds)")) or
                    metric["system_cpu_seconds"]!=float(number_from_time(
                        timed,"System time (seconds)")) or
                    metric["wall_elapsed"]!=number_from_time(
                        timed,"Elapsed (wall clock) time (h:mm:ss or m:ss)")):
                    raise ValueError("reported CPU/RSS metric differs from original GNU time")
            findings.append({"target_day":day,
                             "canonical_fields":receipt["canonical_fields"],
                             "original_processes_verified":2})
    return {"schema":OUT_SCHEMA,"status":"FOUR_SOURCE_ORIGINAL_PAIRS_REPLAY_PASS_NOT_YEAR",
            "source_artifact_id":14469537094,"source_run_id":44392067310,
            "source_zip_sha256":ZIP_SHA,"zip_members_checked":53,
            "pairs_checked":4,"five_fields_checked":20,
            "first_mismatch":None,"rows":findings,
            "whole_source_years_certified":0,
            "ten_thousand_years_certified":0,
            "algorithmic_independence_certified":False,
            "windows_resource_admission_certified":False}


def main()->None:
    parser=argparse.ArgumentParser()
    parser.add_argument("--source-zip",type=Path,required=True)
    parser.add_argument("--verdict-out",type=Path,required=True)
    a=parser.parse_args()
    result=replay(a.source_zip.read_bytes(),load_pin())
    with a.verdict_out.open("x",encoding="utf8") as file:
        json.dump(result,file,sort_keys=True,ensure_ascii=False,indent=2)
        file.write("\n")
    print("V102_FOUR_ORIGINAL_SOURCE_PAIRS_REPLAY_VERIFIED_NOT_YEAR")


if __name__=="__main__":
    main()
