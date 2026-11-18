#!/usr/bin/env python3
"""v106: strict original Fortran single-day source-vs-frozen-Python audit."""
from __future__ import annotations
import argparse
from hashlib import sha256
import io
import json
from pathlib import Path
import re
import zipfile
from audit_ts_original_v094 import read_rows
C="-15055671"
ZIP_SHA="bb256c2a8e6d599f7f78aa2264129d4ab4ff0dc0c9b8680077149de55b752ff1"
REF_COMMIT="0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4"
FORTRAN_COMMIT="23349b9748859a1032b8a3afad0812b1d392be94"
SCHEMA="PASTAFARI_FORTRAN_FOURTH_ORIGINAL_ENGINE_ONE_DAY_V106/1"
MARKER="V106_FORTRAN_ORIGINAL_FCT_NATIVE"
DEC=re.compile(r"(?:0|-[1-9][0-9]*|[1-9][0-9]*)\Z")
FIELDS=("year","cutlet_index","day_in_cutlet","month_index","day_in_month")

def parse_native(log:str)->tuple[int,...]:
    lines=[l.strip() for l in log.splitlines() if l.strip().startswith(MARKER)]
    if len(lines)!=1:raise ValueError("exactly one original Fortran native row required")
    parts=lines[0].split()
    if len(parts)!=8 or parts[0]!=MARKER:
        raise ValueError("Fortran original raw five-field cardinality mismatch")
    if any(DEC.fullmatch(s) is None for s in parts[1:]):
        raise ValueError("noncanonical Fortran original signed decimal output")
    a=tuple(int(x) for x in parts[1:])
    if a[:2]!=(int(C),int(C)):
        raise ValueError("original source ordered coordinate identity differs")
    fields=a[2:]
    if not (1<=fields[1]<=17 and fields[2]>0 and
            1<=fields[3]<=47 and fields[4]>0):
        raise ValueError("original Fortran native output outside canonical domain")
    return fields

def compare(log:str,archive:bytes)->dict:
    if sha256(archive).hexdigest()!=ZIP_SHA or len(archive)!=24119:
        raise ValueError("original source provenance ZIP size/SHA mismatch")
    with zipfile.ZipFile(io.BytesIO(archive)) as z:
        names=z.namelist()
        if len(names)!=53 or len(set(names))!=53 or z.testzip() is not None:
            raise ValueError("original Python source ZIP member or CRC failure")
        norm=z.read("original-python-0-normalized.jsonl")
        raw=z.read("original-python-0-raw.jsonl")
        py_rec=json.loads(z.read("original-python-0-receipt.json"))
        src_verdict=json.loads(z.read("v101-one-day-verdict-0.json"))
    p=read_rows_bytes(norm)
    if (p.get("calculation_day")!=C or p.get("target_day")!=C or
        py_rec.get("source_commit")!=REF_COMMIT or
        py_rec.get("status")!="NATIVE_TRANSPORT_OUTPUT_COMPLETE_NOT_COMPARED" or
        py_rec.get("raw_stream_sha256")!=sha256(raw).hexdigest() or
        py_rec.get("normalized_stream_sha256")!=sha256(norm).hexdigest() or
        p.get("source_raw_sha256")!=sha256(raw).hexdigest() or
        src_verdict.get("status")!="ONE_UNCHANGED_ORIGINAL_SOURCE_DAY_MATCH_NOT_YEAR" or
        src_verdict.get("canonical_fields")!=["5000",10,503,20,56]):
        raise ValueError("original Python reference identity does not replay")
    python_fields=(int(p["year"]),p["cutlet_index"],p["day_in_cutlet"],
                   p["month_index"],p["day_in_month"])
    if python_fields!=(5000,10,503,20,56):
        raise ValueError("reference source native five-field vector drift")
    fortran_fields=parse_native(log)
    diff=next((i for i in range(5) if python_fields[i]!=fortran_fields[i]),None)
    return {
        "schema":SCHEMA,
        "status":"FOURTH_ORIGINAL_ENGINE_ONE_DAY_MATCH_NOT_YEAR" if diff is None
                 else "ORIGINAL_FORTRAN_FIRST_MISMATCH_RECORDED",
        "calculation_day":C,"target_day":C,
        "original_fortran_source_commit":FORTRAN_COMMIT,
        "original_python_source_commit":REF_COMMIT,
        "original_python_witness_run_id":44392067310,
        "fortran_native_five_fields":list(fortran_fields),
        "python_native_five_fields":list(python_fields),
        "first_mismatch":None if diff is None else {
            "field_index_one_based":diff+1,"field":FIELDS[diff],
            "fortran_original":fortran_fields[diff],
            "python_original":python_fields[diff]},
        "new_unique_days_certified":0,
        "full_original_years_certified":0,
        "ten_thousand_years_certified":0,
        "algorithmic_independence_certified":False,
        "windows_run_started":False,
    }

def read_rows_bytes(raw:bytes)->dict:
    if raw.count(b"\n")!=1 or not raw.endswith(b"\n"):
        raise ValueError("source normalized evidence not exactly one JSONL row")
    return json.loads(raw)

def main()->None:
    ap=argparse.ArgumentParser()
    ap.add_argument("--fortran-native-log",type=Path,required=True)
    ap.add_argument("--python-original-zip",type=Path,required=True)
    ap.add_argument("--verdict-out",type=Path,required=True)
    a=ap.parse_args()
    result=compare(a.fortran_native_log.read_text(encoding="utf8"),
                   a.python_original_zip.read_bytes())
    with a.verdict_out.open("x",encoding="utf8") as f:
        json.dump(result,f,sort_keys=True,ensure_ascii=False,indent=2)
        f.write("\n")
    print("V106_ONE_ORIGINAL_FORTRAN_DATE_RECORDED_NOT_YEAR status="+result["status"])

if __name__=="__main__":
    main()
