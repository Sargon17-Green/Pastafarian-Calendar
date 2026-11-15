#!/usr/bin/env python3
"""Experimental annual Python readout for a DIFFERENT calculation day, v034.

Pinned original Python F(c,t) is called on seven selected dates; every other
day is DERIVED from one original source YearStructure. This is not a full year
of unchanged native calls and never certifies algorithmic independence.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import sys
import time

C = -15055672
COMMIT = "0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4"
PINNED_SHA = "75d56765b45892940326f67bd85a2c7c9874c01e43b49ee3553c9f6192d94378"
BOUNDARY_SCHEMA = "PASTAFARI_ALTERNATE_CALCULATION_ORIGINAL_YEAR5000_V033/1"


def read_json_unique(path: Path):
    def unique(pairs):
        x={}
        for key,value in pairs:
            if key in x:
                raise ValueError("duplicate JSON evidence key")
            x[key]=value
        return x
    return json.loads(path.read_bytes(), object_pairs_hook=unique)


def mod_from_path(path: Path,name:str):
    spec=importlib.util.spec_from_file_location(name,path.resolve())
    if spec is None or spec.loader is None:
        raise ValueError("invalid Python module path")
    module=importlib.util.module_from_spec(spec)
    sys.modules[spec.name]=module
    spec.loader.exec_module(module)
    return module


def original_bounds(boundary: Path):
    witness=read_json_unique(boundary)
    if (witness.get("schema")!=BOUNDARY_SCHEMA
            or witness.get("status")!="THREE_CALCULATION_NATIVE_YEAR_BOUNDS_MATCH_NOT_CERTIFIED"
            or witness.get("exact_bound_fields_compared")!=27
            or witness.get("full_date_calls")!=0
            or witness.get("full_native_year_comparisons")!=0
            or witness.get("algorithm_independence_certified") is not False):
        raise ValueError("invalid or overcertified original alternative-c boundaries")
    records=witness["cases"]
    matches=[r for r in records if r.get("calculation_day")==str(C)]
    if len(matches)!=1:
        raise ValueError("missing unique c=-15055672 original boundary case")
    row=matches[0]
    expected={
        "year":"5000", "open_gate_index":"-1", "close_gate_index":"5",
        "open_gate_day":"-15056174","close_gate_day":"-15052605",
        "first_target_day":"-15056173","last_target_day":"-15052605",
        "length_days":3569
    }
    for key,value in expected.items():
        if row[key]!=value:
            raise ValueError("boundary witness c=-15055672 does not match observed source")
    return witness, row


def samples(first,last):
    length=last-first+1
    candidate=(first,first+1,first+length//3,C,first+2*length//3,last-1,last)
    if len(set(candidate))!=7 or any(not first<=x<=last for x in candidate):
        raise ValueError("not exactly seven distinct source sample targets")
    return candidate


def main():
    p=argparse.ArgumentParser()
    p.add_argument("--original-python",type=Path,required=True)
    p.add_argument("--v025-helper",type=Path,required=True)
    p.add_argument("--locked-boundaries",type=Path,required=True)
    p.add_argument("--output-dir",type=Path,required=True)
    args=p.parse_args()
    if args.output_dir.exists():
        raise FileExistsError("no overwrite of annual derivative")
    witness,record=original_bounds(args.locked_boundaries)
    if hashlib.sha256(args.original_python.read_bytes()).hexdigest()!=PINNED_SHA:
        raise ValueError("original Python source SHA-256 mismatch")
    sys.dont_write_bytecode=True
    original=mod_from_path(args.original_python,"_original_py_alt_c_v034")
    helper=mod_from_path(args.v025_helper,"_derived_annual_helper_v025_v034")
    start=time.monotonic()
    calculator=original.NormativeCalendar()
    y=calculator.year5000(C)
    original_native=(y.number,y.open_gate_index,y.close_gate_index,
                     y.open_gate_day,y.close_gate_day)
    pinned=tuple(int(record[key]) for key in (
        "year","open_gate_index","close_gate_index","open_gate_day","close_gate_day"
    ))
    if original_native!=pinned:
        raise ValueError("live original Python year differs from locked independent native bounds")
    native_structure=calculator.build_year_structure(C,y)
    rows=helper.expand_structure(y,native_structure)
    first,last=int(record["first_target_day"]),int(record["last_target_day"])
    if len(rows)!=last-first+1 or len(rows)!=3569:
        raise ValueError("wrong number of derived annual days")
    checks=[]
    for target in samples(first,last):
        native=helper.native_tuple(original.NormativeCalendar().calendar_date_ids(C,target))
        derived=rows[target-first]
        if native!=derived:
            raise AssertionError(
                f"ORIGINAL_PY_FCT_FIRST_MISMATCH_STOP c={C} t={target} native={native} derived={derived}"
            )
        checks.append(str(target))
        print(f"ALTERNATE_C_ORIGINAL_PY_SAMPLE_MATCH target={target} count={len(checks)}",flush=True)
    args.output_dir.mkdir(parents=True,exist_ok=False)
    name=args.output_dir/"python-derived-year5000-alternate-c.tsv"
    h=hashlib.sha256()
    with name.open("xb") as f:
        for offset,fields in enumerate(rows):
            line=("\t".join(str(x) for x in (C,first+offset,*fields))+"\n").encode("utf8")
            f.write(line)
            h.update(line)
        f.flush()
        os.fsync(f.fileno())
    receipt={
        "schema":"PASTAFARI_ALTERNATE_C_PYTHON_ANNUAL_DERIVATIVE_V034/1",
        "status":"ALTERNATE_C_PY_3569_DERIVED_ROWS_SAMPLED_ORIGINAL_NOT_FULL_YEAR",
        "calculation_day":str(C),"year":"5000",
        "first_target_day":str(first),"last_target_day":str(last),
        "derived_rows":len(rows),
        "derived_tsv_sha256":h.hexdigest(),
        "original_source_commit":COMMIT,
        "original_source_sha256":PINNED_SHA,
        "original_native_sample_targets":checks,
        "original_native_sample_matches":7,
        "all_3569_original_fct_calls_executed":False,
        "verified_original_full_years":0,
        "algorithmic_independence_certified":False,
        "soak_started":False,
        "seconds_including_direct_original_samples":round(time.monotonic()-start,4)
    }
    (args.output_dir/"receipt.json").write_text(
        json.dumps(receipt,sort_keys=True,indent=2)+"\n",encoding="utf8"
    )
    print("PY_ALTERNATE_C_3569_DERIVED_YEAR="+json.dumps(receipt,sort_keys=True),flush=True)


if __name__=="__main__":
    main()
