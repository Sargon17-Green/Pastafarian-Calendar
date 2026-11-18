#!/usr/bin/env python3
"""v095: immutable offline replay of a third ORIGINAL source's two-day witness.

No F(c,t) execution, no new year or independent-algorithm credit.
Fails closed on the artifact ZIP, every member digest, source Git identity,
each original Python process receipt, and rederived 5-field comparator verdict.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
from pathlib import Path
import re
import stat
import subprocess
import sys
import tempfile
import zipfile

from audit_ts_original_v094 import DAYS, C, evaluate

PIN_PATH = Path(__file__).resolve().parents[1] / "control/typescript_marathi_original_v094_pin_v095.json"
SCHEMA = "PASTAFARI_TS_MARATHI_PINNED_NATIVE_WITNESS_V095/1"
REPLAY_SCHEMA = "PASTAFARI_THIRD_ORIGINAL_SOURCE_REPLAY_V095/1"
TS_COMMIT = "cc3a613e3b80ba082e5cdb2c7a5d756c7e707df0"
PY_COMMIT = "0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4"
PY_SHA = "75d56765b45892940326f67bd85a2c7c9874c01e43b49ee3553c9f6192d94378"
HEX64 = re.compile(r"[0-9a-f]{64}\Z")


def sha(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


def no_duplicate_pairs(items):
    result = {}
    for k, v in items:
        if k in result: raise ValueError("duplicate JSON member")
        result[k] = v
    return result


def decode(raw: bytes) -> dict:
    obj=json.loads(raw.decode("utf8"),object_pairs_hook=no_duplicate_pairs)
    if type(obj) is not dict: raise ValueError("evidence JSON object required")
    return obj


def pinned() -> dict:
    return decode(PIN_PATH.read_bytes())


def validate_manifest(p:dict)->None:
    expected={
        "schema","source_run","artifact","source_commits",
        "typescript_source_tree_git_sha1","typescript_original_source_file_count",
        "typescript_entrypoint_sha256","typescript_catalog_source_sha256",
        "original_calculation_day","target_days",
        "original_native_pairs_compared","original_five_fields_compared",
        "first_mismatch","whole_original_years_certified",
        "algorithmic_independence_certified","canonical_oracle_certified",
        "windows_started","member_sha256",
    }
    if (type(p) is not dict or set(p)!=expected or p["schema"]!=SCHEMA or
        p["original_calculation_day"]!=C or p["target_days"]!=list(DAYS) or
        p["source_commits"]!={"REF-41":PY_COMMIT,"TS-MR":TS_COMMIT} or
        p["source_run"]!={"id":44363057604,"status":"completed",
                         "conclusion":"success",
                         "head_sha":"cbbc36a05ed7d678abd8f6af5e35d63cac3fa1e8"} or
        p["artifact"]!={"id":14454273351,
            "filename":"soak-v094-original-typescript-marathi-two-day-not-year.zip",
            "bytes":10817,
            "sha256":"a798cac07e77e704c97af637009cf1fcbcaf1f1358767f3f7690bad4acb54a70"} or
        p["typescript_source_tree_git_sha1"]!="e733eb4e82f15efc27f294e09aff2e588b4ea06f" or
        p["typescript_entrypoint_sha256"]!="a611f6b99bf982db7e6f3bbb3ac7b59b2ef9596993fe2f041dbf299d105fa030" or
        p["typescript_catalog_source_sha256"]!="3b53acf4f70f5d49096e1783ab703073b571007f751643b2d42af0552f57bff6" or
        p["typescript_original_source_file_count"]!=69 or
        p["original_native_pairs_compared"]!=2 or
        p["original_five_fields_compared"]!=10 or
        p["first_mismatch"] is not None or
        p["whole_original_years_certified"]!=0 or
        p["algorithmic_independence_certified"] is not False or
        p["canonical_oracle_certified"] is not False or
        p["windows_started"] is not False or
        type(p["member_sha256"]) is not dict or
        len(p["member_sha256"])!=17 or
        any(type(key) is not str or "/" in key or "\\" in key or
            not key or key.startswith(".") or
            type(val) is not str or HEX64.fullmatch(val) is None
            for key,val in p["member_sha256"].items())):
        raise ValueError("immutable v095 original source pin violated")


def zip_members(zip_raw:bytes,expected:dict)->dict[str,bytes]:
    if not zip_raw or len(zip_raw)>20_000_000:
        raise ValueError("source evidence ZIP absent or too large")
    with zipfile.ZipFile(io.BytesIO(zip_raw)) as z:
        infos=z.infolist()
        if len({i.filename for i in infos})!=len(infos):
            raise ValueError("duplicate source ZIP members")
        if len(infos)!=len(expected) or {i.filename for i in infos}!=set(expected):
            raise ValueError("ZIP member set does not equal immutable source inventory")
        if z.testzip() is not None:raise ValueError("ZIP CRC failure")
        result={}
        for info in infos:
            if (not info.is_dir() and not stat.S_ISLNK(info.external_attr>>16)
                and 0<info.file_size<=2_000_000 and
                info.compress_size<=20_000_000 and
                info.filename not in (".","..")):
                b=z.read(info)
            else:
                raise ValueError("unsafe ZIP member kind, length, or symlink")
            if sha(b)!=expected[info.filename]:
                raise ValueError("source ZIP member changed: "+info.filename)
            result[info.filename]=b
        return result


def git(repo:Path,*args)->str:
    return subprocess.run(["git","-C",str(repo),*args],capture_output=True,
                          text=True,check=True).stdout.strip()


def check_sources(p:dict,files:dict[str,bytes],ts_repo:Path,py_repo:Path)->int:
    ts_repo=ts_repo.resolve(strict=True)
    py_repo=py_repo.resolve(strict=True)
    if (git(ts_repo,"rev-parse","HEAD")!=TS_COMMIT or
        git(py_repo,"rev-parse","HEAD")!=PY_COMMIT or
        git(ts_repo,"status","--porcelain") or
        git(py_repo,"status","--porcelain") or
        git(ts_repo,"rev-parse","HEAD:src")!=p["typescript_source_tree_git_sha1"]):
        raise ValueError("original Git source commit/tree/worktree identity mismatch")
    source = (py_repo/"tests/normative_reference.py").read_bytes()
    if sha(source)!=PY_SHA:raise ValueError("original Python source bytes modified")
    closure=decode(files["typescript-source-closure.json"])
    if (closure.get("schema")!="PASTAFARI_TS_SOURCE_CLOSURE_V094/1" or
        closure.get("source_commit")!=TS_COMMIT or
        closure.get("source_tree_git_sha1")!=p["typescript_source_tree_git_sha1"] or
        closure.get("native_entrypoint")!="calendarDateSpaghetti(c:bigint,t:bigint)" or
        closure.get("full_year_soak_certified")!=0 or
        closure.get("algorithms_independent") is not False):
        raise ValueError("TypeScript native source closure receipt invalid")
    rows=closure.get("source_files")
    paths=git(ts_repo,"ls-files","src").splitlines()
    if (type(rows) is not list or len(rows)!=69 or
        [r.get("path") for r in rows]!=sorted(paths)):
        raise ValueError("TypeScript 69-file closure differs from checkout")
    seen=set()
    for row in rows:
        path=row["path"]
        if (path in seen or not path.startswith("src/") or
            ".." in Path(path).parts or "\\" in path or
            type(row.get("sha256")) is not str or
            HEX64.fullmatch(row["sha256"]) is None):
            raise ValueError("unsafe original TypeScript source closure")
        source_file=ts_repo/path
        if (source_file.is_symlink() or not source_file.is_file() or
                sha(source_file.read_bytes())!=row["sha256"]):
            raise ValueError("original TypeScript source bytes drift: "+path)
        seen.add(path)
    paths_to_check={
        "src/postStage55FinalDate.ts":p["typescript_entrypoint_sha256"],
        "src/sourceLanguageCatalog.ts":p["typescript_catalog_source_sha256"],
    }
    for k,v in paths_to_check.items():
        if next((row["sha256"] for row in rows if row["path"]==k),None)!=v:
            raise ValueError("original TypeScript entrypoint/catalog digest drift")
    return len(rows)


def verify_receipts(files:dict[str,bytes])->None:
    for index,target in enumerate(DAYS):
        rec=decode(files[f"python-{index}-receipt.json"])
        if (rec.get("status")!="NATIVE_TRANSPORT_OUTPUT_COMPLETE_NOT_COMPARED" or
            rec.get("engine")!="REF-41" or
            rec.get("source_commit")!=PY_COMMIT or
            rec.get("source_sha256")!=PY_SHA or
            rec.get("calculation_day")!=C or
            rec.get("first_target_day")!=target or
            rec.get("last_target_day")!=target or
            rec.get("rows")!=1 or rec.get("verified_comparisons_completed")!=0 or
            rec.get("raw_stream_sha256")!=sha(files[f"python-{index}-raw.jsonl"]) or
            rec.get("normalized_stream_sha256")!=sha(files[f"python-{index}-normalized.jsonl"])):
            raise ValueError("source Python OS process receipt differs from raw evidence")


def verify_archive(archive:bytes,p:dict,ts_repo:Path,py_repo:Path)->dict:
    validate_manifest(p)
    if len(archive)!=p["artifact"]["bytes"] or sha(archive)!=p["artifact"]["sha256"]:
        raise ValueError("original native witness archive ZIP SHA/size mismatch")
    files=zip_members(archive,p["member_sha256"])
    count=check_sources(p,files,ts_repo,py_repo)
    verify_receipts(files)
    with tempfile.TemporaryDirectory(prefix="soak-v095-replay-") as td:
        root=Path(td)
        for name,data in files.items():
            (root/name).write_bytes(data)
        replay=evaluate(root)
    received=decode(files["v094-five-field-original-source-verdict.json"])
    if received!=replay:
        raise ValueError("frozen original TypeScript/Python numeric comparison cannot replay")
    if (replay["status"]!="TWO_ORIGINAL_NATIVE_DATES_MATCH_NOT_FULL_YEAR" or
        replay["matched_native_pairs"]!=2 or
        replay["matched_five_fields"]!=10 or
        replay["first_mismatch"] is not None or
        replay["full_original_years_certified"]!=0 or
        replay["algorithmic_independence_certified"] is not False):
        raise ValueError("v094 replay claim exceeds original source evidence")
    return {
        "schema":REPLAY_SCHEMA,
        "status":"PINNED_THIRD_ORIGINAL_SOURCE_TWO_DAYS_REPLAY_PASS_NOT_YEAR",
        "original_source_archive_sha256":sha(archive),
        "original_source_artifact_id":p["artifact"]["id"],
        "original_run_id":p["source_run"]["id"],
        "source_closure_files_checked":count,
        "source_artifact_members_checked":len(files),
        "original_native_target_days":list(DAYS),
        "verified_original_five_field_pairs":2,
        "new_unique_target_days":0,
        "full_original_years_certified":0,
        "algorithmic_independence_certified":False,
        "canonical_oracle_certified":False,
        "windows_run_started":False,
    }


def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--zip",type=Path,required=True)
    ap.add_argument("--typescript-source-repo",type=Path,required=True)
    ap.add_argument("--python-source-repo",type=Path,required=True)
    ap.add_argument("--output",type=Path,required=True)
    a=ap.parse_args()
    out=verify_archive(a.zip.read_bytes(),pinned(),
                       a.typescript_source_repo,a.python_source_repo)
    a.output.write_text(json.dumps(out,sort_keys=True,indent=2)+"\n",
                        encoding="utf8")
    print("V095_THIRD_ORIGINAL_SOURCE_PINNED_TWO_DAYS_REPLAY_PASS_NOT_YEAR")


if __name__=="__main__":
    main()
