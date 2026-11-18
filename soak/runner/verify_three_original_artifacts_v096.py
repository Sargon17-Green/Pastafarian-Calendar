#!/usr/bin/env python3
"""v096: independently replay two original ZIPs into one THREE-ENGINE two-day proof.

Sources are raw v085 Kotlin/Python native output and v094 TypeScript/Python
native output, with exact frozen SHA-256/CRC and byte-identical Python repeat.
No new F(c,t) execution, full-year credit, name equivalence, or lineage proof.
"""
from __future__ import annotations
import argparse
import hashlib
import io
import json
from pathlib import Path
import re
import stat
import zipfile

ROOT = Path(__file__).resolve().parents[1]
KPIN = ROOT/"control/original_native_chunk1021_pin_v088.json"
TPIN = ROOT/"control/typescript_marathi_original_v094_pin_v095.json"
SCHEMA = "PASTAFARI_THREE_ORIGINAL_ENGINE_ARCHIVE_CROSS_WITNESS_V096/1"
C = "-15055671"
DAYS = ["-15055660","-15055659"]
DEC = re.compile(r"(?:0|-[1-9][0-9]*|[1-9][0-9]*)\Z")
K_SHA = "b7f250a98aea07acb4a78bf074e75c5f72d950f00a1d32d7bc81c6eb8c464b32"
T_SHA = "a798cac07e77e704c97af637009cf1fcbcaf1f1358767f3f7690bad4acb54a70"


def sha(x:bytes)->str:
    return hashlib.sha256(x).hexdigest()


def pairs(items):
    obj={}
    for k,v in items:
        if k in obj:raise ValueError("duplicate evidence JSON field")
        obj[k]=v
    return obj


def js(data:bytes):
    return json.loads(data.decode("utf8"),object_pairs_hook=pairs)


def number(x):
    if type(x) is not str or DEC.fullmatch(x) is None:
        raise ValueError("noncanonical source integer")
    return int(x)


def members(raw:bytes,pin:dict,limit:int)->dict:
    if len(raw)>limit or sha(raw)!=pin["artifact_sha256"]:
        raise ValueError("frozen source artifact SHA mismatch")
    expected=pin["artifacts_file_sha256"]
    with zipfile.ZipFile(io.BytesIO(raw)) as z:
        info=z.infolist()
        if len(info)!=len(expected) or len(set(i.filename for i in info))!=len(info) or set(i.filename for i in info)!=set(expected):
            raise ValueError("source artifact member set/duplicate mismatch")
        if z.testzip() is not None:raise ValueError("source artifact CRC failed")
        checked={}
        for i in info:
            if (i.is_dir() or stat.S_ISLNK(i.external_attr>>16) or
                not i.filename or i.filename.startswith("/") or
                any(s in (".","..") for s in i.filename.split("/")) or
                i.file_size>12_000_000):
                raise ValueError("unsafe source ZIP path or file")
            b=z.read(i)
            if sha(b)!=expected[i.filename]:
                raise ValueError("changed member SHA: "+i.filename)
            checked[i.filename]=b
        return checked


def ts_members(raw:bytes,pin:dict)->dict:
    if len(raw)!=pin["artifact"]["bytes"] or sha(raw)!=pin["artifact"]["sha256"]:
        raise ValueError("frozen TypeScript source ZIP SHA mismatch")
    expected=pin["member_sha256"]
    with zipfile.ZipFile(io.BytesIO(raw)) as z:
        entries=z.infolist()
        if len(entries)!=17 or len({x.filename for x in entries})!=17 or set(x.filename for x in entries)!=set(expected) or z.testzip() is not None:
            raise ValueError("TypeScript original ZIP member/CRC mismatch")
        found={}
        for i in entries:
            if (i.is_dir() or stat.S_ISLNK(i.external_attr>>16) or
                "/" in i.filename or "\\" in i.filename or
                i.file_size>2_000_000):
                raise ValueError("unsafe TypeScript witness member")
            b=z.read(i)
            if sha(b)!=expected[i.filename]:raise ValueError("TypeScript witness member drift")
            found[i.filename]=b
        return found


def replay(typescript_zip:bytes,python_kotlin_zip:bytes,kpin:dict,tpin:dict):
    if (sha(typescript_zip)!=T_SHA or sha(python_kotlin_zip)!=K_SHA or
        tpin["source_run"]["id"]!=44363057604 or
        tpin["artifact"]["id"]!=14454273351 or
        kpin["run_id"]!=43976583803 or
        kpin["artifact_id"]!=14281261657 or
        kpin["original_source_year"]["ordinal"]!=1021 or
        kpin["original_source_commits"]!={"REF-41":"0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4","PROD-KT-CY":"0c703446d8a3b7435698bd16402ac5fa30e461c9"} or
        tpin["source_commits"]!={"REF-41":"0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4","TS-MR":"cc3a613e3b80ba082e5cdb2c7a5d756c7e707df0"} or
        kpin["comparison"]["first_mismatch"] is not None or
        kpin["comparison"]["original_year_soak_passes_certified"]!=0 or
        tpin["whole_original_years_certified"]!=0 or
        tpin["algorithmic_independence_certified"] is not False):
        raise ValueError("mismatched frozen original source artifacts")
    k=members(python_kotlin_zip,kpin,15_000_000)
    t=ts_members(typescript_zip,tpin)
    kt_raw=k["PROD-KT-CY/os-stdout.tsv"].decode("ascii").splitlines()
    kt_norm=[js(x) for x in k["kotlin-index-only-normalized.jsonl"].splitlines()]
    pr_raw=k["REF-41/native-raw.jsonl"].splitlines(keepends=True)
    pr_norm=k["REF-41/native-normalized.jsonl"].splitlines(keepends=True)
    ts_raw=t["typescript-native-raw.jsonl"].splitlines()
    cat=js(t["typescript-source-catalog.json"])
    v88=js(k["original-two-day-verdict.json"])
    v94=js(t["v094-five-field-original-source-verdict.json"])
    if (len(kt_raw)!=2 or len(kt_norm)!=2 or len(pr_raw)!=2 or len(pr_norm)!=2 or len(ts_raw)!=2 or
        len(cat["cutlets"])!=17 or len(set(cat["cutlets"]))!=17 or
        len(cat["months"])!=47 or len(set(cat["months"]))!=47 or
        v88["matched_original_day_pairs"]!=2 or v88["original_complete_years_soak_passed"]!=0 or
        v88["kotlin_name_field_semantics"]!="NATIVE_INDEX_STRING_NOT_NAME" or
        v94["matched_native_pairs"]!=2 or v94["full_original_years_certified"]!=0 or
        v94["algorithmic_independence_certified"] is not False):
        raise ValueError("frozen full-data source evidence shape invalid")
    results=[]
    for i,day in enumerate(DAYS):
        if (pr_raw[i]!=t[f"python-{i}-raw.jsonl"] or
            pr_norm[i]!=t[f"python-{i}-normalized.jsonl"]):
            raise ValueError("two independent Python source runs are not byte-identical")
        ts=js(ts_raw[i])
        py=js(pr_norm[i])
        pyraw=js(pr_raw[i])
        kt=kt_raw[i].split("\t")
        kn=kt_norm[i]
        if ((ts["calculation_day"],ts["target_day"])!=(C,day) or
            (py["calculation_day"],py["target_day"])!=(C,day) or
            (kn["calculation_day"],kn["target_day"])!=(C,day) or
            kt[:2]!=[C,day] or len(kt)!=7 or
            pyraw["calculation_day"]!=C or pyraw["target_day"]!=day):
            raise ValueError("original three-engine input coordinates differ")
        v=ts["native_tuple"]
        if type(v) is not list or len(v)!=5 or not all(type(x) is str for x in v):
            raise ValueError("original TypeScript raw fields missing")
        try:
            ts_num=(number(v[0]),cat["cutlets"].index(v[1])+1,
                    number(v[2]),cat["months"].index(v[3])+1,number(v[4]))
        except ValueError as ex:
            raise ValueError("original Marathi native source name not in locked catalog") from ex
        py_num=(number(py["year"]),py["cutlet_index"],py["day_in_cutlet"],
                py["month_index"],py["day_in_month"])
        kt_num=tuple(number(x) for x in kt[2:])
        kn_num=(number(kn["year"]),kn["cutlet_index"],kn["day_in_cutlet"],
                kn["month_index"],kn["day_in_month"])
        if ts_num!=py_num or py_num!=kt_num or kn_num!=kt_num:
            raise ValueError("THREE_ORIGINAL_SOURCE_FIRST_MISMATCH day="+day)
        names=pyraw["native_names"]
        if (names["cutlet"]!=py["cutlet_name_raw"] or
            names["month"]!=py["month_name_raw"] or
            pyraw["native_date_ids"]["year_number"]!=py["year"] or
            py["source_raw_sha256"]!=sha(pr_raw[i])):
            raise ValueError("Python source raw/normalized mismatch")
        if (v94["rows"][i]["five_fields"]!=[str(ts_num[0]),*ts_num[1:]] or
            v94["rows"][i]["typescript_native_raw_sha256"]!=sha(ts_raw[i]+b"\n")):
            raise ValueError("original TypeScript saved verdict disagrees with raw")
        results.append({
            "target_day":day,
            "canonical_fields":list(ts_num),
            "typescript_raw_cutlet_name":v[1],
            "typescript_raw_month_name":v[3],
            "python_raw_cutlet_name":py["cutlet_name_raw"],
            "python_raw_month_name":py["month_name_raw"],
            "kotlin_has_native_names":False,
            "matching_original_engines":["REF-41","PROD-KT-CY","TS-MR"]
        })
    return {
        "schema":SCHEMA,
        "status":"TWO_DAYS_THREE_ORIGINAL_ENGINES_FIVE_FIELDS_EQUAL_NOT_YEAR",
        "calculation_day":C,"year":"5000","ordinal":1021,
        "source_commits":{
            "REF-41":"0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4",
            "PROD-KT-CY":"0c703446d8a3b7435698bd16402ac5fa30e461c9",
            "TS-MR":"cc3a613e3b80ba082e5cdb2c7a5d756c7e707df0"},
        "artifact_sources":{
            "python_kotlin":{"run_id":43976583803,"artifact_id":14281261657,
                "zip_sha256":K_SHA,"members_count":22},
            "typescript_python":{"run_id":44363057604,"artifact_id":14454273351,
                "zip_sha256":T_SHA,"members_count":17}},
        "matched_target_days":2,
        "matching_five_field_engine_observations":6,
        "matching_field_comparisons":20,
        "new_unique_days_certified":0,
        "first_mismatch":None,
        "whole_original_years_certified":0,
        "algorithmic_independence_certified":False,
        "canonical_oracle_certified":False,
        "windows_run_started":False,
        "rows":results
    }


def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--typescript-zip",required=True,type=Path)
    ap.add_argument("--python-kotlin-zip",required=True,type=Path)
    ap.add_argument("--output",required=True,type=Path)
    a=ap.parse_args()
    result=replay(a.typescript_zip.read_bytes(),
                  a.python_kotlin_zip.read_bytes(),
                  js(KPIN.read_bytes()),js(TPIN.read_bytes()))
    a.output.write_text(json.dumps(result,sort_keys=True,ensure_ascii=False,
                                   indent=2)+"\n",encoding="utf8")
    print("V096_THREE_ORIGINAL_ENGINES_TWO_DAYS_ARCHIVE_CROSS_MATCH_NOT_YEAR")


if __name__=="__main__":
    main()
