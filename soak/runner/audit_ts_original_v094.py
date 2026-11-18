#!/usr/bin/env python3
"""v094 read-only independent audit of original TypeScript Marathi vs Python Turkish.

This DOES NOT compute a date or use the TypeScript test oracle. It compares
complete five-part native fields against immutable Python native raw+normalized
records; name-to-index conversion uses the source Marathi catalog only.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import re

SCHEMA = "PASTAFARI_TS_MARATHI_NATIVE_TWO_DAY_V094/1"
C = "-15055671"
DAYS = ("-15055660", "-15055659")
DEC = re.compile(r"(?:0|-[1-9][0-9]*|[1-9][0-9]*)\Z")
FIELDS = {"calculation_day","target_day","year","cutlet_index","day_in_cutlet",
          "month_index","day_in_month","cutlet_name_raw","month_name_raw",
          "source_raw_sha256"}
RAW_KEYS = {"calculation_day","target_day","native_tuple"}
PY_RAW_KEYS = {"calculation_day","target_day","native_date_ids","native_names"}


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _pairs(items):
    obj={}
    for key,val in items:
        if key in obj: raise ValueError("duplicate JSON key")
        obj[key]=val
    return obj


def _line(data:bytes)->dict:
    if not data.endswith(b"\n") or data.count(b"\n")!=1:
        raise ValueError("one canonical JSONL line required")
    item=json.loads(data.decode("utf8"),object_pairs_hook=_pairs)
    if type(item) is not dict: raise ValueError("JSONL object expected")
    return item


def _canonical(x):
    if type(x) is not str or DEC.fullmatch(x) is None:
        raise ValueError("noncanonical decimal")
    return int(x)


def read_rows(path:Path,expected:int)->list[tuple[dict,bytes]]:
    if path.is_symlink() or not path.is_file() or path.stat().st_size>50000:
        raise ValueError("missing, unsafe or oversized native evidence")
    raw=path.read_bytes()
    if raw.count(b"\n")!=expected or not raw.endswith(b"\n"):
        raise ValueError("native evidence row count or newline changed")
    return [( _line(line+b"\n"),line+b"\n") for line in raw.split(b"\n")[:-1]]


def audit_pair(ts:dict, ts_bytes:bytes, py_raw:dict,py_raw_bytes:bytes,
               py_norm:dict,py_norm_bytes:bytes,catalog:dict,t:str)->dict:
    if (set(ts)!=RAW_KEYS or set(py_raw)!=PY_RAW_KEYS or
        set(py_norm)!=FIELDS or any(obj["calculation_day"]!=C or
        obj["target_day"]!=t for obj in (ts,py_raw,py_norm))):
        raise ValueError("raw/normalized original input identity not preserved")
    a=ts["native_tuple"]
    if type(a) is not list or len(a)!=5 or type(a[1]) is not str or type(a[3]) is not str:
        raise ValueError("Marathi native tuple malformed")
    y,dc,dm=[_canonical(a[i]) for i in (0,2,4)]
    if dc<=0 or dm<=0: raise ValueError("invalid native day index")
    try:
        ci=catalog["cutlets"].index(a[1])+1
        mi=catalog["months"].index(a[3])+1
    except ValueError as e:
        raise ValueError("native Marathi name missing from original catalog") from e
    p=py_raw["native_date_ids"]
    names=py_raw["native_names"]
    if (type(p) is not dict or type(names) is not dict or
        set(p)!={"year_number","cutlet_name_index","day_in_cutlet",
                "month_name_index","day_in_month"} or
        set(names)!={"cutlet","month"}):
        raise ValueError("original Python native raw shape invalid")
    py_nums=( _canonical(p["year_number"]),p["cutlet_name_index"],
              p["day_in_cutlet"],p["month_name_index"],p["day_in_month"])
    if any(type(x) is not int for x in py_nums[1:]):
        raise ValueError("Python original identifiers not integer")
    if (names["cutlet"]!=py_norm["cutlet_name_raw"] or
        names["month"]!=py_norm["month_name_raw"] or
        py_norm["source_raw_sha256"]!=sha(py_raw_bytes) or
        py_nums!=( _canonical(py_norm["year"]),py_norm["cutlet_index"],
                   py_norm["day_in_cutlet"],py_norm["month_index"],
                   py_norm["day_in_month"])):
        raise ValueError("original Python raw-to-normalized provenance mismatch")
    observed=(y,ci,dc,mi,dm)
    if observed!=py_nums:
        raise ValueError("V094_FIRST_ORIGINAL_NATIVE_MISMATCH at t="+t+
                         " typescript="+str(observed)+" python="+str(py_nums))
    return {"target_day":t,"five_fields":[str(y),ci,dc,mi,dm],
            "typescript_cutlet_name_raw":a[1],
            "typescript_month_name_raw":a[3],
            "typescript_native_raw_sha256":sha(ts_bytes),
            "python_native_raw_sha256":sha(py_raw_bytes),
            "python_normalized_sha256":sha(py_norm_bytes)}


def load_catalog(path:Path)->dict:
    rec=_line(path.read_bytes())
    if set(rec)!={"cutlets","months"}: raise ValueError("Marathi catalog fields invalid")
    if (any(type(rec[k]) is not list or len(rec[k])!=n or
            any(type(x) is not str or not x for x in rec[k]) or
            len(set(rec[k]))!=n for k,n in (("cutlets",17),("months",47)))):
        raise ValueError("Marathi original name catalog invalid")
    return rec


def evaluate(directory:Path)->dict:
    catalog=load_catalog(directory/"typescript-source-catalog.json")
    ts=read_rows(directory/"typescript-native-raw.jsonl",2)
    rows=[]
    for index,t in enumerate(DAYS):
        pr=read_rows(directory/f"python-{index}-raw.jsonl",1)[0]
        pn=read_rows(directory/f"python-{index}-normalized.jsonl",1)[0]
        rows.append(audit_pair(ts[index][0],ts[index][1],
                               pr[0],pr[1],pn[0],pn[1],catalog,t))
    return {
        "schema":SCHEMA,
        "status":"TWO_ORIGINAL_NATIVE_DATES_MATCH_NOT_FULL_YEAR",
        "calculation_day":C,
        "original_source_ordinal":1021,
        "original_native_target_days":list(DAYS),
        "matched_native_pairs":2,
        "matched_five_fields":10,
        "first_mismatch":None,
        "rows":rows,
        "typescript_source_catalog_sha256":sha((directory/"typescript-source-catalog.json").read_bytes()),
        "typescript_native_stream_sha256":sha((directory/"typescript-native-raw.jsonl").read_bytes()),
        "full_original_years_certified":0,
        "algorithmic_independence_certified":False,
        "canonical_oracle_certified":False,
        "windows_run_started":False,
    }


def main():
    p=argparse.ArgumentParser()
    p.add_argument("--evidence-dir",type=Path,required=True)
    p.add_argument("--verdict-out",type=Path,required=True)
    a=p.parse_args()
    result=evaluate(a.evidence_dir.resolve(strict=True))
    a.verdict_out.write_text(json.dumps(result,sort_keys=True,ensure_ascii=False,indent=2)+"\n",
                             encoding="utf8")
    print("V094_ORIGINAL_TYPESCRIPT_PYTHON_TWO_DAYS_MATCH_NOT_YEAR="+json.dumps({
        "matched_pairs":2,"fields":10,"years":0
    },sort_keys=True))


if __name__=="__main__":
    main()
