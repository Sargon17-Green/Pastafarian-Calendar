#!/usr/bin/env python3
"""Native-structure-derived Python annual transcripts for 4999 and 5001.

The pinned original NormativeCalendar builds every YearStructure exactly once;
the annual row expansion is a separate derivative (v025), not 4126/5567
unchanged native F(c,t) invocations. Sampled direct original calls are counted
separately and never promoted into full-year native verification.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import time

C = -15055671
EXPECTED = {
    4999: {"open_gate_index":-12, "close_gate_index":-4,
           "open_gate_day":-15061829, "close_gate_day":-15057703},
    5000: {"open_gate_index":-4, "close_gate_index":4,
           "open_gate_day":-15057703, "close_gate_day":-15053459},
    5001: {"open_gate_index":4, "close_gate_index":14,
           "open_gate_day":-15053459, "close_gate_day":-15047892},
}
ORIGINAL_PY_SHA = "75d56765b45892940326f67bd85a2c7c9874c01e43b49ee3553c9f6192d94378"


def strict_json(data: bytes):
    def no_dupes(pairs):
        ans = {}
        for k,v in pairs:
            if k in ans:
                raise ValueError("duplicate field " + k)
            ans[k] = v
        return ans
    return json.loads(data, object_pairs_hook=no_dupes)


def validate_boundary_witness(path: Path):
    d = strict_json(path.read_bytes())
    if (d.get("schema") != "PASTAFARI_NATIVE_ADJACENT_YEAR_BOUNDARY_V030/1"
        or d.get("status") != "THREE_ORIGINAL_NATIVE_YEAR_BOUNDARIES_AGREE_NOT_CANONICAL_CERTIFIED"
        or d.get("original_full_year_date_comparisons") != 0
        or d.get("original_native_full_date_calls") != 0
        or d.get("canonical_oracle_certified") is not False):
        raise ValueError("no verified original adjacent boundary witness")
    for name in ("python_boundaries","kotlin_boundaries"):
        rows = d[name]
        if len(rows) != 3:
            raise ValueError("incomplete year boundary list")
        for i, year in enumerate((4999,5000,5001)):
            row=rows[i]
            expected=EXPECTED[year]
            if row["calculation_day"]!=str(C) or row["year"]!=str(year):
                raise ValueError("wrong year or calculation day")
            for field,val in expected.items():
                if row[field]!=str(val):
                    raise ValueError("changed original boundary candidate " + field)
            if row["first_target_day"]!=str(expected["open_gate_day"]+1):
                raise ValueError("inconsistent first day")
            if row["last_target_day"]!=str(expected["close_gate_day"]):
                raise ValueError("inconsistent last day")
    return d


def load_v025_helper(path: Path):
    spec = importlib.util.spec_from_file_location("pinned_annual_reuse_helper_v025",path)
    mod = importlib.util.module_from_spec(spec)
    import sys
    sys.modules[spec.name]=mod
    spec.loader.exec_module(mod)
    return mod


def native_boundary(y,number):
    expected=EXPECTED[number]
    if (y.number!=number or
        (y.open_gate_index,y.close_gate_index,
         y.open_gate_day,y.close_gate_day) != tuple(expected.values())):
        raise ValueError("pinned Python original year changed from v030 witness")


def target_samples(year):
    first=year.open_gate_day+1
    last=year.close_gate_day
    length=last-first+1
    # Six independently recomputed exact original F(c,t) witnesses per year.
    days=[first,first+1,first+length//3,
          first+2*length//3,last-1,last]
    if len(set(days)) != 6:
        raise ValueError("sample days are not distinct")
    return days


def main():
    p=argparse.ArgumentParser()
    p.add_argument("--original-python",type=Path,required=True)
    p.add_argument("--v025-helper",type=Path,required=True)
    p.add_argument("--native-boundary-witness",type=Path,required=True)
    p.add_argument("--output-dir",type=Path,required=True)
    a=p.parse_args()
    if a.output_dir.exists():
        raise FileExistsError("no overwrite of evidence folder")
    if hashlib.sha256(a.original_python.read_bytes()).hexdigest()!=ORIGINAL_PY_SHA:
        raise ValueError("original Python SHA mismatch")
    witness=validate_boundary_witness(a.native_boundary_witness)
    v025=load_v025_helper(a.v025_helper)
    original=v025.original_module(a.original_python.resolve())
    started=time.monotonic()
    cal=original.NormativeCalendar()
    center=cal.year5000(C)
    previous=cal.previous_year(C,center)
    following=cal.next_year(C,center)
    native_boundary(center,5000)
    native_boundary(previous,4999)
    native_boundary(following,5001)
    years=(previous,following)
    data={}
    # Validate all derived rows and 12 unchanged direct native calls BEFORE
    # creating the successful evidence directory.
    for year in years:
        t0=time.monotonic()
        structure=cal.build_year_structure(C,year)
        fields=v025.expand_structure(year,structure)
        length=year.close_gate_day-year.open_gate_day
        if len(fields)!=length:
            raise ValueError("native annual structure length mismatch")
        if not 252<=length<=5778:
            raise ValueError("unexpected year length")
        checks=[]
        for t in target_samples(year):
            expected=v025.native_tuple(original.NormativeCalendar().calendar_date_ids(C,t))
            observed=fields[t-year.open_gate_day-1]
            if observed!=expected:
                raise AssertionError(
                    f"ORIGINAL_PY_FCT_FIRST_MISMATCH_STOP year={year.number} target={t}"
                    f" native={expected} derived={observed}"
                )
            checks.append(t)
            print(f"PY_ADJACENT_ORIGINAL_SAMPLE_MATCH year={year.number} target={t}"
                  f" count={len(checks)}",flush=True)
        data[year.number]=(year,fields,checks,round(time.monotonic()-t0,4))
    a.output_dir.mkdir(parents=True,exist_ok=False)
    receipt={
        "schema":"PASTAFARI_TWO_ADJACENT_PY_DERIVED_ANNUAL_V031/1",
        "status":"TWO_ADJACENT_PY_ANNUAL_TRANSCRIPTS_SAMPLED_NATIVE_MATCH_NOT_FULL_YEAR",
        "original_python_commit":"0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4",
        "original_python_sha256":ORIGINAL_PY_SHA,
        "calculation_day":str(C),
        "boundary_witness_sha256":hashlib.sha256(a.native_boundary_witness.read_bytes()).hexdigest(),
        "years":[],
        "original_full_year_native_comparisons":0,
        "original_source_not_modified":True,
        "all_days_recomputed_via_original_fct":False,
        "independent_canonical_oracle_certified":False,
        "soak_started":False
    }
    for n in (4999,5001):
        y,rows,samples,duration=data[n]
        file=a.output_dir/f"python-derived-{n}.tsv"
        h=hashlib.sha256()
        with file.open("xb") as f:
            for i,values in enumerate(rows):
                t=y.open_gate_day+1+i
                line=("\t".join(map(str,(C,t,*values)))+"\n").encode("utf8")
                f.write(line)
                h.update(line)
            f.flush()
            os.fsync(f.fileno())
        sub={
            "year":str(n),"first_target_day":str(y.open_gate_day+1),
            "last_target_day":str(y.close_gate_day),
            "derived_rows":len(rows),"derived_sha256":h.hexdigest(),
            "direct_original_fct_targets":[str(x) for x in samples],
            "direct_original_fct_sample_matches":len(samples),
            "derived_plus_six_native_seconds":duration,
        }
        receipt["years"].append(sub)
        print("PY_DERIVED_ADJACENT_YEAR="+json.dumps(sub,sort_keys=True),flush=True)
    receipt["elapsed_total_seconds"]=round(time.monotonic()-started,4)
    (a.output_dir/"receipt.json").write_text(
        json.dumps(receipt,sort_keys=True,indent=2)+"\n",encoding="utf8"
    )
    print("PY_DERIVED_TWO_ADJACENT_YEARS_VERDICT="+json.dumps(receipt,sort_keys=True),flush=True)


if __name__=="__main__":
    main()
