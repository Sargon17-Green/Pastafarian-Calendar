#!/usr/bin/env python3
"""v103: original Ada foundation-day source versus immutable v101 original Python.

This audit detects and freezes the earliest scalar mismatch. It never
computes a date itself or gives complete-year certification.
"""
from __future__ import annotations
import argparse
from hashlib import sha256
import io
import json
from pathlib import Path
import re
import zipfile

C="-15055671"
ZIP_SHA="bb256c2a8e6d599f7f78aa2264129d4ab4ff0dc0c9b8680077149de55b752ff1"
REF_COMMIT="0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4"
ADA_COMMIT="a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72"
SCHEMA="PASTAFARI_ADA_FOUNDATION_ORIGINAL_SOURCE_DISCRIMINATOR_V103/1"
MARKER="V103_ADA_ORIGINAL_FCT_NATIVE"
FIELDS=("year","cutlet_index","day_in_cutlet","month_index","day_in_month")
LINE=re.compile(r"^-?(?:0|[1-9][0-9]*)$")
PIN_FIELDS=("5000",10,503,20,56)

def pairs(rows):
    out={}
    for key,value in rows:
        if key in out:raise ValueError("duplicate original source JSON key")
        out[key]=value
    return out

def js(data:bytes)->dict:
    obj=json.loads(data.decode("utf8"),object_pairs_hook=pairs)
    if type(obj) is not dict:raise ValueError("original source evidence object expected")
    return obj

def integer(t:str)->int:
    if type(t) is not str or LINE.fullmatch(t) is None:
        raise ValueError("native Ada decimal scalar malformed")
    return int(t)

def parse_ada(log:str)->tuple[int,...]:
    lines=[line.strip() for line in log.splitlines() if line.strip().startswith(MARKER)]
    if len(lines)!=1:raise ValueError("exactly one native Ada Fct call receipt required")
    parts=lines[0].split()
    if len(parts)!=8 or parts[0]!=MARKER:
        raise ValueError("original Ada output cardinality differs")
    numbers=tuple(integer(x) for x in parts[1:])
    if numbers[:2]!=(int(C),int(C)):
        raise ValueError("original Ada c,t coordinate identity differs")
    if not (1<=numbers[3]<=17 and numbers[4]>0 and
            1<=numbers[5]<=47 and numbers[6]>0):
        raise ValueError("original Ada five-field domain malformed")
    return numbers[2:]

def pinned_python(archive:bytes)->tuple[int,...]:
    if sha256(archive).hexdigest()!=ZIP_SHA or len(archive)!=24119:
        raise ValueError("pinned original source ZIP immutable SHA/length differs")
    with zipfile.ZipFile(io.BytesIO(archive)) as z:
        names=z.namelist()
        if len(names)!=53 or len(set(names))!=53 or z.testzip() is not None:
            raise ValueError("original Python source archive CRC or inventory invalid")
        raw=z.read("original-python-0-raw.jsonl")
        norm=z.read("original-python-0-normalized.jsonl")
        receipt=js(z.read("original-python-0-receipt.json"))
        v101=js(z.read("v101-one-day-verdict-0.json"))
        summary=js(z.read("v101-source-performance-verdict.json"))
    py=js(norm)
    pyraw=js(raw)
    if (receipt.get("status")!="NATIVE_TRANSPORT_OUTPUT_COMPLETE_NOT_COMPARED" or
        receipt.get("engine")!="REF-41" or
        receipt.get("source_commit")!=REF_COMMIT or
        receipt.get("source_sha256")!="75d56765b45892940326f67bd85a2c7c9874c01e43b49ee3553c9f6192d94378" or
        receipt.get("calculation_day")!=C or
        receipt.get("first_target_day")!=C or
        receipt.get("last_target_day")!=C or
        receipt.get("rows")!=1 or
        receipt.get("raw_stream_sha256")!=sha256(raw).hexdigest() or
        receipt.get("normalized_stream_sha256")!=sha256(norm).hexdigest() or
        py.get("source_raw_sha256")!=sha256(raw).hexdigest() or
        py.get("calculation_day")!=C or py.get("target_day")!=C or
        pyraw.get("calculation_day")!=C or pyraw.get("target_day")!=C or
        v101.get("status")!="ONE_UNCHANGED_ORIGINAL_SOURCE_DAY_MATCH_NOT_YEAR" or
        v101.get("canonical_fields")!=list(PIN_FIELDS) or
        summary.get("status")!="FOUR_ORIGINAL_SOURCE_PAIRS_MATCH_NOT_FULL_YEAR" or
        summary.get("first_mismatch") is not None or
        summary.get("whole_original_years_certified")!=0):
        raise ValueError("frozen original Python/TypeScript source provenance drift")
    vector=(integer(py["year"]),py["cutlet_index"],py["day_in_cutlet"],
            py["month_index"],py["day_in_month"])
    if vector!=(5000,10,503,20,56):
        raise ValueError("unexpected original Python foundation vector")
    if pyraw["native_date_ids"]["month_name_index"]!=vector[3]:
        raise ValueError("original Python raw/native month index inconsistent")
    return vector

def compare(ada_log:str,archive:bytes)->dict:
    a=parse_ada(ada_log)
    p=pinned_python(archive)
    first=next((i for i in range(5) if a[i]!=p[i]),None)
    difference=None if first is None else {
        "field":FIELDS[first],"field_index_one_based":first+1,
        "ada_original":a[first],"pinned_python_original":p[first]}
    return {
        "schema":SCHEMA,
        "status":"ORIGINAL_ADA_CANONICAL_NUMERIC_MISMATCH" if first is not None
                  else "ADA_FOUNDATION_ONE_DAY_MATCH_NOT_WHOLE_YEAR",
        "calculation_day":C,"target_day":C,
        "original_ada_commit":ADA_COMMIT,
        "original_python_commit":REF_COMMIT,
        "typescript_witness_run":44392067310,
        "ada_original_five_fields":list(a),
        "python_original_five_fields":list(p),
        "first_mismatch":difference,
        "matched_fields_before_mismatch":5 if first is None else first,
        "original_admissions_checked":1,
        "full_years_certified":0,
        "ten_thousand_years_certified":0,
        "algorithms_independent_certified":False,
        "original_source_corrected_by_probe":False,
        "windows_runtime_certified":False,
    }

def main()->None:
    ap=argparse.ArgumentParser()
    ap.add_argument("--ada-source-log",type=Path,required=True)
    ap.add_argument("--original-sample-zip",type=Path,required=True)
    ap.add_argument("--verdict-out",type=Path,required=True)
    a=ap.parse_args()
    result=compare(a.ada_source_log.read_text(encoding="utf8"),
                   a.original_sample_zip.read_bytes())
    with a.verdict_out.open("x",encoding="utf8") as f:
        json.dump(result,f,sort_keys=True,ensure_ascii=False,indent=2)
        f.write("\n")
    if result["first_mismatch"] is not None:
        print("V103_ORIGINAL_ADA_FIRST_MISMATCH_RECORDED_NOT_SOAK_PASS")
    else:
        print("V103_ADA_FOUNDATION_ONE_DAY_MATCH_NOT_YEAR")

if __name__=="__main__":
    main()
