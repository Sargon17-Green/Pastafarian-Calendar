#!/usr/bin/env python3
"""v137 immutable, read-only historical Seer release binary hash census.

GitHub Actions metadata is sourced from two *different exact commits*. ZIP
bytes are optional and are NEVER executed; the six actual archive ZIP SHA-256
and each of 24 original binary SHA-256 are locked by v137 index. CLI without
--archive-dir does not imply that the binary bytes were examined by CI.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import re
import zipfile

from soak_scope_coverage_v127 import canonical,digest,parse_json
from soak_source_census_v129 import GitHubReadOnly

SCHEMA="PASTAFARI_SOAK_V137_CROSS_RUN_NATIVE_HASH_INDEX/1"
REPORT="PASTAFARI_SOAK_V137_CROSS_RUN_NATIVE_HASH_REPORT/1"
REPO="Sargon-17-Green/Pastafarian-Calendar-Seer"
FROZEN="866e9bbff59399310416ae25de1b664f9b6c3124"
LATER="4716594fc98fa882a9401455ae56f30895518e8c"
EARLIER="54e1d5d4eaa9f88887f1ed5c5b887ed318c31efa"
SUCCESS_RUNS={42423263952:LATER,42421325317:EARLIER}
FAILED_NEXT=42421321405
NEXT_RUN=42423259653
INNER_COMMITS={LATER:"29d18adba6844728c6be8331be181ea00b669eb5",
               EARLIER:"5f9a47dc961eddca5a77a9aff5b2358ec9aae1f9"}
ARCHIVE_LOCKS={
13594347792:(42423263952,4900691,"ed3c380c3790e22e86e269dc3afc5afb95f2ef8c6b66631834e113557fbc1770","linux-x64"),
13595475137:(42423263952,5729393,"3d506b322c761d1ad5bc45278a4d12ea1bc56a59d6dcc1780ccd49ae5571cd0b","win32-x64"),
13594263914:(42423263952,4852864,"fd9959a3ad0a756149df70cfb21b5cffa76d8517ebd3a8c962dced08647df2f6","linux-arm64"),
13593383581:(42421325317,4900689,"8102f73d1c278c1586f12f6ec9971fe13abe8367dc84ec9193baa27d823d3e77","linux-x64"),
13594370074:(42421325317,5729393,"999f9f616af52b285214698d665bb661e7e3c6245c3f3e60ec38e13d36b8e682","win32-x64"),
13593332766:(42421325317,4852864,"44cdc05e7c25c181fd7683e792392c5ebacbfc7c26dc6d49e831a535bef78a9f","linux-arm64")
}
TARGETS={
"baseline":"8191de4ccd416f159ac8400a7e12920b8464a0066b32651be69d76c54c47ab2b",
"candidate":"46dded4a81d884936fc0bd80a89a32fba6a821cf28c6b55fbfd1a6ff6f253ac8"
}
HEX64=re.compile(r"[0-9a-f]{64}\Z")

def require(cond,message):
    if not cond:raise ValueError(message)

def validate(m):
    require(type(m) is dict and m.get("schema")==SCHEMA and
            m.get("scope")=="ARCHIVED_PREBUILT_EXECUTABLE_BYTES_NOT_SEER_NEXT_EXPERIMENT" and
            m.get("repo")==REPO and
            m.get("original_next_frozen_commit")==FROZEN and
            m.get("original_next_ci_commit")==LATER and
            m.get("original_next_run")==NEXT_RUN and
            m.get("neighboring_failed_next_run")==FAILED_NEXT and
            m.get("neighboring_failed_next_run_expected_status")=="completed/failure",
            "v137 source identity or failed historical experiment lock changed")
    require(m.get("experiment_binary_hashes")==TARGETS
            and m.get("expected_archives")==6
            and m.get("expected_executable_entries")==24
            and m.get("expected_unique_executable_sha256")==16
            and m.get("expected_original_hash_matches")==0
            and m.get("platforms")==["linux-x64","win32-x64","linux-arm64"]
            and m.get("source_internal_commits")==[INNER_COMMITS[LATER],INNER_COMMITS[EARLIER]],
            "v137 expected original targets or archive counts changed")
    require(m.get("original_soak_years_certified")==0
            and m.get("independent_algorithms_certified")==0
            and m.get("soak_dispatch_authorized") is False
            and m.get("archive_contents_are_not_original_seer_next_binaries") is True
            and m.get("no_native_executables_executed") is True,
            "original native Soak stop gate violated")
    rows=m.get("artifacts")
    require(type(rows) is list and len(rows)==6,"v137 requires exactly six unique ZIP rows")
    seen=set()
    for a in rows:
        aid=a.get("artifact_id")
        require(type(aid) is int and aid in ARCHIVE_LOCKS and aid not in seen,
                "v137 duplicate/unknown historical archive ID")
        seen.add(aid)
        run,size,sha,platform=ARCHIVE_LOCKS[aid]
        require(a.get("run_id")==run
                and a.get("source_head")==SUCCESS_RUNS[run]
                and a.get("inner_source")==INNER_COMMITS[SUCCESS_RUNS[run]]
                and a.get("zip_bytes")==size
                and a.get("zip_sha256")==sha
                and a.get("platform")==platform
                and a.get("entry_count")==(14 if platform=="win32-x64" else 13),
                "v137 pinned historical archive bytes/commit metadata changed")
        bins=a.get("binaries")
        require(type(bins) is dict and len(bins)==4
                and all(type(key) is str and key.startswith("bin/")
                        and type(value) is str and HEX64.fullmatch(value)
                        for key,value in bins.items())
                and not set(bins.values()) & set(TARGETS.values()),
                "v137 prebuilt binary hash missing/unsafe or confusable with original trial")
        expected_names={"seer_engine_service","seer_year_batch","seer_year_locator","seer_year_structure"}
        expected_files={("bin/"+name+(".exe" if platform=="win32-x64" else ""))
                        for name in expected_names}
        require(set(bins)==expected_files,"v137 prebuilt executable set changed")
    require(seen==set(ARCHIVE_LOCKS),"v137 omitted one pinned archive")
    hashes={a["binaries"][name] for a in rows for name in a["binaries"]}
    require(len(hashes)==16,"v137 24 original hash entries no longer have 16 unique values")
    for p in ("linux-x64","linux-arm64"):
        paired=[a for a in rows if a["platform"]==p]
        require(len(paired)==2 and paired[0]["binaries"]==paired[1]["binaries"],
                "historical Linux binaries not byte-identical across artifact revisions")
    return rows

def check_live(m,gh):
    rows=validate(m)
    status=[]
    for run_id,sha in SUCCESS_RUNS.items():
        r=gh.get("/repos/"+REPO+"/actions/runs/"+str(run_id))
        require(r.get("id")==run_id and r.get("head_sha")==sha and
                r.get("status")=="completed" and r.get("conclusion")=="success",
                "historical prebuilt CI run is not completed/success at exact source")
        response=gh.get("/repos/"+REPO+"/actions/runs/"+str(run_id)+"/artifacts?per_page=100")
        require(type(response) is dict and
                type(response.get("total_count")) is int and
                response["total_count"]<=100 and
                type(response.get("artifacts")) is list,
                "incomplete historical artifact inventory")
        entries={a["id"]:a for a in response["artifacts"]}
        require(len(entries)==len(response["artifacts"]), "duplicate returned artifact ID")
        for row in rows:
            if row["run_id"]!=run_id:continue
            original=entries.get(row["artifact_id"])
            require(original is not None
                    and original.get("digest")=="sha256:"+row["zip_sha256"]
                    and original.get("size_in_bytes")==row["zip_bytes"]
                    and original.get("expired") is False
                    and original.get("name","").startswith("native-"+row["platform"]+"-"),
                    "historical artifact digest or availability changed")
            status.append({"run_id":run_id,"head_sha":sha,
                  "artifact_id":row["artifact_id"],
                  "artifact_zip_sha256":row["zip_sha256"],
                  "artifact_visible":True,
                  "binary_bytes_examined_by_metadata_scan":False})
    failed=gh.get("/repos/"+REPO+"/actions/runs/"+str(FAILED_NEXT))
    require(failed.get("id")==FAILED_NEXT and failed.get("head_sha")==EARLIER and
            failed.get("status")=="completed" and failed.get("conclusion")=="failure",
            "neighboring failed Seer Next run cannot be converted to PASS")
    art=gh.get("/repos/"+REPO+"/actions/runs/"+str(FAILED_NEXT)+"/artifacts?per_page=100")
    require(type(art) is dict and type(art.get("total_count")) is int and
            type(art.get("artifacts")) is list and art["total_count"]<=100,
            "adjacent failed experiment artifact list incomplete")
    return {"exact_completed_prebuilt_runs":len(SUCCESS_RUNS),
            "prebuilt_artifacts_verified":len(status),
            "prebuilt_archive_rows":status,
            "adjacent_seer_next_failed_run":FAILED_NEXT,
            "adjacent_seer_next_status":"completed/failure",
            "adjacent_failed_run_current_artifact_count":art["total_count"],
            "binary_bytes_reexamined_in_this_live_metadata_scan":False}

def scan_zip(m,row,raw):
    validate(m)
    require(type(raw) is bytes and
            len(raw)==row["zip_bytes"] and
            hashlib.sha256(raw).hexdigest()==row["zip_sha256"],
            "prebuilt ZIP SHA-256 or exact length mismatch")
    try:z=zipfile.ZipFile(io.BytesIO(raw))
    except (ValueError,zipfile.BadZipFile) as e:
        raise ValueError("invalid ZIP container") from e
    with z:
        members=z.infolist()
        names=[x.filename for x in members]
        require(len(members)==row["entry_count"] and len(set(names))==len(names)
                and all(x and not x.startswith("/") and
                        "\\" not in x and
                        ".." not in x.split("/") and
                        not x.endswith("/") for x in names),
                "unexpected/unsafe ZIP entries")
        require(all(x.file_size<=10000000 for x in members),
                "prebuilt archive member too large")
        require(z.testzip() is None,"prebuilt ZIP CRC failure")
        runtime=json.loads(z.read("runtime-manifest.json"))
        require(runtime.get("sourceCommit")==row["inner_source"]
                and runtime.get("target")==row["platform"]
                and runtime.get("backend")=="portable"
                and runtime.get("version")=="0.2.5"
                and runtime.get("package")=="pastafarian-calendar-seer-"+row["platform"],
                "embedded source/platform mismatch; cannot ascribe trial identity")
        require(set(runtime.get("binaries",[]))==
                set(path.removeprefix("bin/") for path in row["binaries"]),
                "embedded executable listing not the locked four")
        outcome=[]
        for name,expected in sorted(row["binaries"].items()):
            binary=z.read(name)
            actual=hashlib.sha256(binary).hexdigest()
            require(actual==expected and
                    runtime["files"].get(name.removeprefix("bin/"))==actual,
                    "executable SHA mismatch against frozen index or embedded manifest")
            require(binary.startswith(b"MZ") if row["platform"]=="win32-x64"
                    else binary.startswith(b"\x7fELF"),
                    "unexpected native executable format")
            outcome.append({"path":name,"bytes":len(binary),"sha256":actual,
                     "matches_trial_baseline":actual==TARGETS["baseline"],
                     "matches_trial_candidate":actual==TARGETS["candidate"]})
        require(not any(r["matches_trial_baseline"] or r["matches_trial_candidate"]
                        for r in outcome),
                "a historical release binary matches the trial; stop for separate review")
        return {"artifact_id":row["artifact_id"],"source_head":row["source_head"],
                "inner_source_commit":row["inner_source"],
                "platform":row["platform"],
                "zip_sha256_recomputed":row["zip_sha256"],
                "zip_crc_checked":True,"binaries":outcome,
                "trial_sha_match_count":0}

def report(m,gh,dirpath=None):
    rows=validate(m)
    live=check_live(m,gh)
    local=None
    if dirpath is not None:
        require(dirpath.is_dir(),"local archive directory not available")
        local=[]
        for row in rows:
            path=dirpath / (str(row["artifact_id"])+".zip")
            require(path.is_file(),"missing locally downloaded archive "+str(row["artifact_id"]))
            local.append(scan_zip(m,row,path.read_bytes()))
    hashes=set(b["sha256"] for r in local for b in r["binaries"]) if local else set()
    if local:require(len(hashes)==16,"wrong number of distinct SHA-256 native byte sequences")
    return {"schema":REPORT,"manifest_sha256":digest(m),
            "historical_github_metadata":live,
            "archive_bytes_checked_this_execution":local is not None,
            "local_byte_reports":local,
            "executables_sha256_recomputed_from_real_bytes":24 if local else 0,
            "distinct_executable_sha256_values":len(hashes) if local else None,
            "matching_original_seer_next_experimental_hashes":0 if local else None,
            "new_native_binary_execution_count":0,
            "new_original_Fct_dispatch_count":0,
            "independent_algorithms_certified":0,
            "original_full_years_certified":0,
            "soak_dispatch_authorized":False}

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--index",type=Path,required=True)
    p.add_argument("--output",type=Path,required=True)
    p.add_argument("--archive-dir",type=Path,default=None)
    a=p.parse_args()
    x=report(parse_json(a.index.read_bytes()),
             GitHubReadOnly(os.environ.get("GITHUB_TOKEN","")),a.archive_dir)
    with a.output.open("xb") as f:f.write(canonical(x)+b"\n")
    print(json.dumps({"schema":REPORT,
       "exact_sha_ci_prebuilt_runs":x["historical_github_metadata"]["exact_completed_prebuilt_runs"],
       "pinned_artifacts":x["historical_github_metadata"]["prebuilt_artifacts_verified"],
       "actual_executable_bytes_rehashed_this_execution":x["executables_sha256_recomputed_from_real_bytes"],
       "original_full_years_certified":0,"soak_dispatch_authorized":False},sort_keys=True))

if __name__=="__main__":main()
