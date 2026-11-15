#!/usr/bin/env python3
"""Compare 4999 and 5001 FULL DERIVED annual streams with original native samples.

The original Python and Kotlin F(c,t) entrypoints are executed only on 6
selected targets per year. The two full derived streams are compared for
all 9,693 rows; they must never count as original native full-year soak PASS.
All comparisons stop at the first difference, retaining exact coordinates.
"""
from __future__ import annotations

import argparse
import hashlib
import itertools
import json
from pathlib import Path
import re

DECIMAL=re.compile(r"^(?:0|-?[1-9][0-9]*)$")
C="-15055671"
YEARS={
    4999:(-15061828,-15057703),
    5001:(-15053458,-15047892),
}


def strict_json(data:bytes):
    def no_dupes(pairs):
        z={}
        for k,v in pairs:
            if k in z:
                raise ValueError("duplicate evidence JSON key "+k)
            z[k]=v
        return z
    return json.loads(data,object_pairs_hook=no_dupes)


def read_line(line: bytes):
    if not line.endswith(b"\n") or line.count(b"\n")!=1:
        raise ValueError("incomplete TSV line or unexpected newline")
    try:
        values=line[:-1].decode("utf-8").split("\t")
    except UnicodeDecodeError as e:
        raise ValueError("non UTF-8 source") from e
    if len(values)!=7 or any(not DECIMAL.fullmatch(x) for x in values):
        raise ValueError("not exactly seven canonical decimal columns")
    if any(int(x)<=0 for x in values[2:]):
        raise ValueError("non-positive year or canonical date ordinal")
    return values


def compare(py_folder:Path, kotlin_years:Path, kotlin_sample:Path):
    receipt=strict_json((py_folder/"receipt.json").read_bytes())
    if (receipt.get("schema")!="PASTAFARI_TWO_ADJACENT_PY_DERIVED_ANNUAL_V031/1"
        or receipt.get("status")!="TWO_ADJACENT_PY_ANNUAL_TRANSCRIPTS_SAMPLED_NATIVE_MATCH_NOT_FULL_YEAR"
        or receipt.get("calculation_day")!=C
        or receipt.get("original_full_year_native_comparisons")!=0
        or receipt.get("original_source_not_modified") is not True
        or receipt.get("all_days_recomputed_via_original_fct") is not False
        or receipt.get("independent_canonical_oracle_certified") is not False
        or receipt.get("soak_started") is not False):
        raise ValueError("missing/falsely promoted original Python derivative receipt")
    entries=receipt.get("years")
    if not isinstance(entries,list) or len(entries)!=2:
        raise ValueError("expected 4999 and 5001 Python receipt records")
    expected_original=[]
    for i,year in enumerate(YEARS):
        first,last=YEARS[year]
        e=entries[i]
        if (e.get("year")!=str(year) or e.get("first_target_day")!=str(first)
            or e.get("last_target_day")!=str(last)
            or e.get("derived_rows")!=last-first+1
            or e.get("direct_original_fct_sample_matches")!=6):
            raise ValueError("invalid bounded original annual structure or samples")
        targets=e.get("direct_original_fct_targets")
        if (not isinstance(targets,list) or len(targets)!=6
            or len(set(targets))!=6
            or any(not DECIMAL.fullmatch(x) or not first<=int(x)<=last for x in targets)):
            raise ValueError("invalid sample target list")
        expected_original.extend(targets)
        raw=(py_folder/f"python-derived-{year}.tsv").read_bytes()
        if hashlib.sha256(raw).hexdigest()!=e["derived_sha256"]:
            raise ValueError("Python adjacent source stream SHA mismatch")

    if not kotlin_years.read_bytes().endswith(b"\n") or not kotlin_sample.read_bytes().endswith(b"\n"):
        raise ValueError("Kotlin incomplete output framing")
    result={
      "schema":"PASTAFARI_ADJACENT_DERIVED_TWO_YEAR_COMPARISON_V031/1",
      "status":"INCOMPLETE_DERIVED_ADJACENT_YEAR",
      "calculation_day":C,
      "year_numbers":["4999","5001"],
      "expected_derived_rows_per_year":[4126,5567],
      "derived_rows_compared":0,
      "fully_compared_derived_years":0,
      "date_fields_matched":0,
      "first_mismatch":None,
      "python_original_sample_matches":12,
      "kotlin_original_sample_matches":0,
      "python_derived_source_sha256":{
          str(y): entries[i]["derived_sha256"] for i,y in enumerate(YEARS)
      },
      "kotlin_derived_source_sha256":hashlib.sha256(kotlin_years.read_bytes()).hexdigest(),
      "kotlin_original_sample_sha256":hashlib.sha256(kotlin_sample.read_bytes()).hexdigest(),
      "original_source_commits":{
          "python":"0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4",
          "kotlin":"0c703446d8a3b7435698bd16402ac5fa30e461c9",
      },
      "original_native_all_year_days_executed":False,
      "two_unmodified_original_annual_streams_compared":False,
      "algorithmic_independence_certified":False,
      "canonical_oracle_certified":False,
      "verified_original_soak_full_year_comparisons":0,
      "soak_started":False,
      "main_modified":False,
    }
    observed_selected={}
    with kotlin_years.open("rb") as kt:
        for yi,year in enumerate(YEARS):
            first,last=YEARS[year]
            with (py_folder/f"python-derived-{year}.tsv").open("rb") as py:
                for i in range(last-first+1):
                    python_line=py.readline()
                    kotlin_line=kt.readline()
                    if not python_line or not kotlin_line:
                        result["status"]="FIRST_MISMATCH_MISSING_DERIVED_ROW_STOP"
                        result["first_mismatch"]={"year":year,"target_day":str(first+i)}
                        return result
                    a,b=read_line(python_line),read_line(kotlin_line)
                    target=str(first+i)
                    if (a[0]!=C or b[0]!=C or a[1]!=target or b[1]!=target
                        or a[2]!=str(year) or b[2]!=str(year)):
                        result["status"]="FIRST_MISMATCH_DERIVED_YEAR_COORDINATES_STOP"
                        result["first_mismatch"]={"year":year,"target_day":target,"python":a,"kotlin":b}
                        return result
                    if a!=b:
                        result["status"]="FIRST_MISMATCH_DERIVED_DATE_FIELDS_STOP"
                        col=next(j for j in range(7) if a[j]!=b[j])
                        result["first_mismatch"]={
                            "year":year,"target_day":target,
                            "difference_column0":col,
                            "python":a,"kotlin":b,
                        }
                        return result
                    observed_selected[target]=b
                    result["derived_rows_compared"]+=1
                    result["date_fields_matched"]+=5
                    if result["derived_rows_compared"]%1000==0:
                        print("ADJACENT_DERIVED_ROWS_MATCH="+str(result["derived_rows_compared"]),flush=True)
                if py.readline():
                    result["status"]="FIRST_MISMATCH_EXTRA_PY_DERIVED_ROWS_STOP"
                    result["first_mismatch"]={"year":year,"reason":"extra_python_row"}
                    return result
            result["fully_compared_derived_years"]+=1
        if kt.readline():
            result["status"]="FIRST_MISMATCH_EXTRA_KOTLIN_DERIVED_ROWS_STOP"
            result["first_mismatch"]={"reason":"extra_kotlin_row"}
            return result

    with kotlin_sample.open("rb") as f:
        sample_lines=list(f)
    if len(sample_lines)!=12:
        raise ValueError("original native Kotlin sample count not 12")
    for expected_target,line in zip(expected_original,sample_lines):
        native=read_line(line)
        if native[0]!=C or native[1]!=expected_target:
            raise ValueError("original native Kotlin sample order or coordinates changed")
        expected=observed_selected[expected_target]
        if native!=expected:
            result["status"]="FIRST_MISMATCH_ORIGINAL_KOTLIN_FCT_SAMPLE_STOP"
            result["first_mismatch"]={
                "target_day":expected_target,"original_kotlin":native,
                "kotlin_derived":expected,
            }
            return result
        result["kotlin_original_sample_matches"]+=1
    if (result["fully_compared_derived_years"]==2
        and result["derived_rows_compared"]==9693
        and result["kotlin_original_sample_matches"]==12):
        result["status"]="TWO_ADJACENT_DERIVED_YEARS_9693_ROWS_MATCH_NATIVE_SAMPLED_NOT_CERTIFIED"
    return result


def main():
    p=argparse.ArgumentParser()
    p.add_argument("--python-annual-dir",type=Path,required=True)
    p.add_argument("--kotlin-derived-years",type=Path,required=True)
    p.add_argument("--kotlin-original-samples",type=Path,required=True)
    p.add_argument("--verdict",type=Path,required=True)
    a=p.parse_args()
    d=compare(a.python_annual_dir,a.kotlin_derived_years,a.kotlin_original_samples)
    with a.verdict.open("x",encoding="utf8",newline="\n") as f:
        json.dump(d,f,sort_keys=True,indent=2)
        f.write("\n")
    print("ADJACENT_TWO_YEAR_DERIVED_VERDICT="+json.dumps(d,sort_keys=True),flush=True)
    if d["status"]!="TWO_ADJACENT_DERIVED_YEARS_9693_ROWS_MATCH_NATIVE_SAMPLED_NOT_CERTIFIED":
        raise SystemExit(1)


if __name__=="__main__":
    main()
