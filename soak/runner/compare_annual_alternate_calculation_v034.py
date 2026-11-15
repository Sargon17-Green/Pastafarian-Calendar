#!/usr/bin/env python3
"""Compare two DERIVED Year-5000 streams for a new calculation day, fail first.

Original unmodified Python F(c,t) and Kotlin F(c,t) are separately observed for
exactly seven selected targets each. The 3569-row derived comparison is NOT a
full year of original F calls, and must never certify one.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import re

C="-15055672"
FIRST=-15056173
LAST=-15052605
ROWS=3569
NUM=re.compile(r"^(?:0|-?[1-9][0-9]*)$")


def unique_json(data:bytes):
    def no_dupes(pairs):
        out={}
        for key,val in pairs:
            if key in out:
                raise ValueError("duplicate evidence JSON key")
            out[key]=val
        return out
    return json.loads(data.decode("utf8"),object_pairs_hook=no_dupes)


def read_fields(raw:bytes):
    if not raw.endswith(b"\n") or raw.count(b"\n")!=1:
        raise ValueError("invalid TSV record framing")
    parts=raw[:-1].decode("utf8").split("\t")
    if len(parts)!=7 or any(not NUM.fullmatch(p) for p in parts):
        raise ValueError("not exactly seven canonical numeric TSV fields")
    if any(int(v)<=0 for v in parts[2:]):
        raise ValueError("invalid year or canonical date component")
    return parts


def evidence(py_dir:Path, kt_stream:Path, kt_original:Path):
    receipt=unique_json((py_dir/"receipt.json").read_bytes())
    if (receipt.get("schema")!="PASTAFARI_ALTERNATE_C_PYTHON_ANNUAL_DERIVATIVE_V034/1"
            or receipt.get("status")!="ALTERNATE_C_PY_3569_DERIVED_ROWS_SAMPLED_ORIGINAL_NOT_FULL_YEAR"
            or receipt.get("calculation_day")!=C
            or receipt.get("first_target_day")!=str(FIRST)
            or receipt.get("last_target_day")!=str(LAST)
            or receipt.get("derived_rows")!=ROWS
            or receipt.get("original_native_sample_matches")!=7
            or receipt.get("all_3569_original_fct_calls_executed") is not False
            or receipt.get("verified_original_full_years")!=0
            or receipt.get("algorithmic_independence_certified") is not False
            or receipt.get("soak_started") is not False):
        raise ValueError("Python annual evidence absent or overcertified")
    targets=receipt.get("original_native_sample_targets")
    if (not isinstance(targets,list) or len(targets)!=7
            or len(set(targets))!=7 or any(not NUM.fullmatch(t) for t in targets)):
        raise ValueError("untrusted native original target list")
    py_path=py_dir/"python-derived-year5000-alternate-c.tsv"
    py_bytes=py_path.read_bytes()
    if hashlib.sha256(py_bytes).hexdigest()!=receipt["derived_tsv_sha256"]:
        raise ValueError("tampered Python annual transcript SHA")
    result={
        "schema":"PASTAFARI_ALTERNATE_C_CROSS_DERIVED_YEAR_V034/1",
        "status":"INCOMPLETE_ALTERNATE_C_DERIVED_COMPARISON",
        "calculation_day":C,
        "year":"5000",
        "first_target_day":str(FIRST),
        "last_target_day":str(LAST),
        "derived_rows_expected":ROWS,
        "derived_rows_matched":0,
        "derived_fields_matched":0,
        "original_python_native_sample_matches":7,
        "original_kotlin_native_sample_matches":0,
        "first_mismatch":None,
        "original_python_commit":receipt["original_source_commit"],
        "original_kotlin_commit":"0c703446d8a3b7435698bd16402ac5fa30e461c9",
        "python_derived_sha256":hashlib.sha256(py_bytes).hexdigest(),
        "kotlin_derived_sha256":hashlib.sha256(kt_stream.read_bytes()).hexdigest(),
        "kotlin_original_sample_sha256":hashlib.sha256(kt_original.read_bytes()).hexdigest(),
        "full_original_Fct_years_passed":0,
        "original_native_3569_calls_per_engine_executed":False,
        "source_lineage_independence_certified":False,
        "canonical_oracle_certified":False,
        "soak_started":False,
    }
    observed={}
    with py_path.open("rb") as p,kt_stream.open("rb") as k:
        for i in range(ROWS):
            a,b=p.readline(),k.readline()
            if not a or not b:
                result["status"]="FIRST_MISMATCH_MISSING_ROW_STOP"
                result["first_mismatch"]={"row_index1":i+1,"reason":"missing_derived_row"}
                return result
            pfields,kfields=read_fields(a),read_fields(b)
            day=str(FIRST+i)
            if any(row[0]!=C or row[1]!=day or row[2]!="5000"
                   for row in (pfields,kfields)):
                result["status"]="FIRST_MISMATCH_WRONG_CALCULATION_OR_YEAR_STOP"
                result["first_mismatch"]={"target_day":day,"python":pfields,"kotlin":kfields}
                return result
            if pfields!=kfields:
                result["status"]="FIRST_MISMATCH_DERIVED_FIELDS_STOP"
                result["first_mismatch"]={
                    "target_day":day,
                    "first_difference_column0":next(j for j in range(7)
                                                     if pfields[j]!=kfields[j]),
                    "python":pfields,"kotlin":kfields,
                }
                return result
            if day in targets:
                observed[day]=kfields
            result["derived_rows_matched"]+=1
            result["derived_fields_matched"]+=7
            if (i+1)%512==0:
                print("ALTERNATE_C_DERIVED_YEAR_MATCHED="+str(i+1),flush=True)
        if p.readline() or k.readline():
            result["status"]="FIRST_MISMATCH_EXTRA_ROW_STOP"
            result["first_mismatch"]={"reason":"extra_derived_row"}
            return result
    native_raw=kt_original.read_bytes()
    if not native_raw.endswith(b"\n") or len(native_raw.splitlines())!=7:
        raise ValueError("original native Kotlin Fct sample output incomplete")
    for target,line in zip(targets,native_raw.splitlines(keepends=True)):
        fields=read_fields(line)
        if fields[0]!=C or fields[1]!=target:
            raise ValueError("original Kotlin native sample ordering or coordinate wrong")
        if fields!=observed[target]:
            result["status"]="FIRST_MISMATCH_UNMODIFIED_KOTLIN_FCT_SAMPLE_STOP"
            result["first_mismatch"]={
                "target_day":target,
                "original_kotlin":fields,"derived_kotlin":observed[target]
            }
            return result
        result["original_kotlin_native_sample_matches"]+=1
    result["status"]="ALTERNATE_C_3569_DERIVED_ROWS_MATCH_SAMPLED_NATIVE_NOT_CERTIFIED"
    return result


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--python-year-dir",type=Path,required=True)
    parser.add_argument("--kotlin-derived",type=Path,required=True)
    parser.add_argument("--kotlin-original-samples",type=Path,required=True)
    parser.add_argument("--verdict",type=Path,required=True)
    a=parser.parse_args()
    verdict=evidence(a.python_year_dir,a.kotlin_derived,a.kotlin_original_samples)
    with a.verdict.open("x",encoding="utf8",newline="\n") as f:
        json.dump(verdict,f,sort_keys=True,indent=2)
        f.write("\n")
    print("ALTERNATE_C_3569_DERIVED_V034_VERDICT="+json.dumps(verdict,sort_keys=True),flush=True)
    if verdict["status"]!="ALTERNATE_C_3569_DERIVED_ROWS_MATCH_SAMPLED_NATIVE_NOT_CERTIFIED":
        raise SystemExit(1)


if __name__=="__main__":
    main()
