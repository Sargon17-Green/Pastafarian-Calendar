#!/usr/bin/env python3
"""Read-only, frozen-commit FIRST-HOP dependency probe for 8 source roots.

It never runs an original date converter or compiler. It distinguishes:
1) a referenced local file found and blob/bytes checked,
2) an include file found only elsewhere in tree (include-path unverified),
3) unresolved direct imports, external linker symbols, or unsupported DSL.
No assertion of transitive dependency closure, executable provenance,
algorithmic independence, year correctness, or dispatch readiness.
"""
from __future__ import annotations

import argparse
import ast
import base64
from collections import Counter
import hashlib
import json
import posixpath
from pathlib import Path
import re
from typing import Any
import os
from urllib.parse import quote

from soak_scope_coverage_v127 import canonical, digest, parse_json
from soak_source_census_v129 import (
    GitHubReadOnly, APIProblem, git_blob_sha1, safe_path, safe_repo, sha40
)

SCHEMA="PASTAFARI_SOAK_FIRST_HOP_DEPENDENCY_PROBES_V132/1"
REPORT="PASTAFARI_SOAK_FIRST_HOP_DEPENDENCIES_V132/1"
EXPECTED = {
    "REF-41":("PYTHON_TURKISH","PYTHON_RELATIVE_IMPORTS","ORIGINAL_TEST_REFERENCE"),
    "TURKISH-PY":("PYTHON_TURKISH","PYTHON_RELATIVE_IMPORTS","PRODUCTION_CANDIDATE"),
    "REF-24":("JAVASCRIPT_INTERLINGUE","JS_LITERAL_RELATIVE_REQUIRE","ORIGINAL_TEST_REFERENCE"),
    "INTERLINGUE-JS":("JAVASCRIPT_INTERLINGUE","JS_LITERAL_RELATIVE_REQUIRE","PRODUCTION_CANDIDATE"),
    "SEER-NEXT-HYBRID":("SEER_CPP","CPP_QUOTED_INCLUDE","RESEARCH_CANDIDATE"),
    "SEER-NEXT-YEAR-CACHE":("SEER_CPP","CPP_QUOTED_INCLUDE","RESEARCH_CANDIDATE"),
    "COPTIC-X64":("COPTIC_ASSEMBLY","ASSEMBLY_EXTERN_SYMBOLS","PRODUCTION_CANDIDATE"),
    "PALEO-CODESH":("CODESH_DSL","UNSUPPORTED_DSL_NEEDS_REVIEW","UNREVIEWED_SOURCE_CANDIDATE")
}
DUPLICATE_PAIRS = [
    ["COPTIC-X64","TRIAGE-10"],
    ["PALEO-CODESH","TRIAGE-02"],
    ["SEER-NEXT-COLD-PROBE","SEER-NEXT-HYBRID"]
]
HEX64=re.compile(r"[0-9a-f]{64}\Z")
JS_REQUIRE=re.compile(r"\brequire\s*\(\s*['\"](\.[^'\"]+)['\"]\s*\)")
CPP_INCLUDE=re.compile(r'^\s*#\s*include\s*"([^"]+)"',re.M)
ASM_EXTERN=re.compile(r"^\s*\.extern\s+([A-Za-z_.][A-Za-z0-9_.$]*)",re.M)
MAX_BYTES=2*1024*1024


def demand(value, reason):
    if not value:
        raise ValueError(reason)


def checked_blob(gh, repo: str, commit: str, path: str) -> tuple[bytes,dict]:
    """Read bytes from GitHub immutable commit and cryptographically verify."""
    safe_repo(repo)
    sha40(commit)
    safe_path(path)
    response=gh.get("/repos/"+repo+"/contents/"+quote(path,safe="/")+"?ref="+commit)
    if (type(response) is not dict or response.get("type")!="file" or
        response.get("encoding")!="base64"):
        raise APIProblem("SOURCE_CONTENT_NOT_BASE64_FILE")
    size=response.get("size")
    if type(size) is not int or not 0<=size<=MAX_BYTES:
        raise APIProblem("SOURCE_CONTENT_SIZE_OUT_OF_RANGE")
    blob=response.get("sha")
    if type(blob) is not str or not re.fullmatch("[0-9a-f]{40}",blob):
        raise APIProblem("SOURCE_GIT_BLOB_MISSING")
    try:
        payload=base64.b64decode(response["content"].replace("\n",""),validate=True)
    except (KeyError,AttributeError,ValueError,TypeError) as exc:
        raise APIProblem("SOURCE_BASE64_NOT_DECODABLE") from exc
    if len(payload)!=size or git_blob_sha1(payload)!=blob:
        raise APIProblem("SOURCE_BYTES_GIT_BLOB_MISMATCH")
    return payload,{"source_sha256":hashlib.sha256(payload).hexdigest(),
                    "git_blob_sha1":blob,"bytes":size}


def validate(manifest:dict, lineage:dict)->list[dict]:
    demand(type(manifest) is dict and set(manifest)=={
        "schema","v131_source_lineage_contract","source_mode","probes",
        "frozen_duplicate_pairs","prohibit_binary_build",
        "prohibit_native_date_execution","automatic_independence_decision",
        "soak_dispatch_authorized"
    } and manifest.get("schema")==SCHEMA,"v132 manifest shape invalid")
    demand(manifest["v131_source_lineage_contract"]==
           "PASTAFARI_SOAK_SOURCE_LINEAGE_SCREEN_V131/1"
           and manifest["source_mode"]=="IMMUTABLE_GITHUB_COMMIT_READONLY"
           and manifest["frozen_duplicate_pairs"]==DUPLICATE_PAIRS
           and manifest["prohibit_binary_build"] is True
           and manifest["prohibit_native_date_execution"] is True
           and manifest["automatic_independence_decision"] is False
           and manifest["soak_dispatch_authorized"] is False,
           "v132 tried to authorize scientific work or drop duplicate locks")
    demand(type(manifest["probes"]) is list and len(manifest["probes"])==len(EXPECTED),
           "eight first-hop probes required")
    seen=set()
    for probe in manifest["probes"]:
        demand(type(probe) is dict and set(probe)=={
            "record_id","family","parser","role"
        },"unexpected probe attributes")
        rid=probe["record_id"]
        demand(type(rid) is str and rid in EXPECTED and rid not in seen,
               "repeated/unknown probe root")
        seen.add(rid)
        demand((probe["family"],probe["parser"],probe["role"])==EXPECTED[rid],
               "probe parser or role laundering")
    demand(seen==set(EXPECTED),"probe list missing source roots")
    demand(type(lineage) is dict and
           lineage.get("schema")=="PASTAFARI_SOAK_SOURCE_LINEAGE_SCREEN_V131/1"
           and lineage.get("total_historical_records")==91
           and lineage.get("source_rows_bound_to_git_sha256")==91
           and lineage.get("independent_algorithm_count_certified")==0
           and lineage.get("native_original_full_date_engines_certified")==0
           and lineage.get("official_10000_year_soak_credit")==0
           and lineage.get("native_date_calls")==0
           and lineage.get("soak_dispatch_authorized") is False
           and lineage.get("scientific_soak_10000_pass") is False,
           "v131 signed source screening not safe for first-hop probing")
    duplicate_sets={tuple(x["record_ids"]) for x in
                    lineage.get("identical_file_content_groups",[])
                    if isinstance(x,dict)}
    for left,right in DUPLICATE_PAIRS:
        demand(tuple(sorted((left,right))) in duplicate_sets,
               "v131 identical-file collision lock vanished")
    by_id={}
    rows=lineage.get("records")
    demand(type(rows) is list and len(rows)==91,
           "v131 lineage record population changed")
    for row in rows:
        rid=row["record_id"]
        demand(rid not in by_id,"duplicate v131 record")
        by_id[rid]=row
    for rid in EXPECTED:
        row=by_id.get(rid)
        demand(type(row) is dict and row.get("eligible_for_soak") is False
               and row.get("algorithmic_independence_certified") is False
               and row.get("native_entrypoint_verified") is False
               and row.get("full_dependency_closure_verified") is False
               and row.get("original_stdout_execution_attested") is False
               and type(row.get("source_sha256")) is str
               and HEX64.fullmatch(row["source_sha256"])
               and type(row.get("git_blob_sha1")) is str
               and re.fullmatch("[a-f0-9]{40}",row["git_blob_sha1"])
               and type(row.get("source_bytes")) is int
               and row["source_bytes"]>0,
               rid+" invalid verified first-hop source root")
    return [by_id[p["record_id"]] for p in manifest["probes"]]


def python_references(payload:bytes, root:str)->list[str]:
    try:
        tree=ast.parse(payload.decode("utf-8"))
    except (UnicodeError,SyntaxError) as exc:
        raise APIProblem("PYTHON_SOURCE_SYNTAX_UNPARSEABLE") from exc
    relative=set()
    for node in ast.walk(tree):
        if isinstance(node,ast.ImportFrom) and node.level>0:
            base=posixpath.dirname(root)
            for _ in range(node.level-1):
                base=posixpath.dirname(base)
            module=node.module or ""
            if module:
                relative.add(posixpath.normpath(posixpath.join(
                    base,module.replace(".","/")+".py")))
            else:
                for imported in node.names:
                    if imported.name!="*":
                        relative.add(posixpath.normpath(posixpath.join(
                            base,imported.name+".py")))
    return sorted(relative)


def relative_candidates(payload:bytes,root:str,parser:str)->tuple[list[dict],list[str]]:
    """Direct file references only. Unsupported constructs are never certified."""
    if parser=="PYTHON_RELATIVE_IMPORTS":
        return ([{"reference":p,"candidate_paths":[p]}
                 for p in python_references(payload,root)],[])
    if parser=="JS_LITERAL_RELATIVE_REQUIRE":
        refs=set(JS_REQUIRE.findall(payload.decode("utf-8",errors="replace")))
        output=[]
        for ref in sorted(refs):
            base=posixpath.normpath(posixpath.join(posixpath.dirname(root),ref))
            paths=[base] if posixpath.splitext(base)[1] else [base+".js",base+"/index.js"]
            output.append({"reference":ref,"candidate_paths":paths})
        return output,[]
    if parser=="CPP_QUOTED_INCLUDE":
        refs=set(CPP_INCLUDE.findall(payload.decode("utf-8",errors="replace")))
        return ([{"reference":p,"candidate_paths":[posixpath.normpath(
                     posixpath.join(posixpath.dirname(root),p))]}
                 for p in sorted(refs)],[])
    if parser=="ASSEMBLY_EXTERN_SYMBOLS":
        symbols=sorted(set(ASM_EXTERN.findall(payload.decode("utf-8",errors="replace"))))
        return [],symbols
    if parser=="UNSUPPORTED_DSL_NEEDS_REVIEW":
        return [],[]
    raise ValueError("unknown first-hop parser")


def audit(manifest:dict,lineage:dict,gh:GitHubReadOnly)->dict:
    roots=validate(manifest,lineage)
    all_results=[]
    dependency_summary=Counter()
    seen_root={}
    for probe,root in zip(manifest["probes"],roots):
        repo=root["repository"]
        commit=root["historical_head_commit"]
        filename=root["observed_source_path"]
        safe_repo(repo)
        sha40(commit)
        safe_path(filename)
        base={"record_id":probe["record_id"],"family":probe["family"],
              "role":probe["role"],"parser":probe["parser"],
              "repository":repo,"commit":commit,"root_path":filename,
              "root_content_status":None,"root_sha256":root["source_sha256"],
              "root_git_blob_sha1":root["git_blob_sha1"],
              "direct_file_references":[],"unresolved_linker_symbols":[],
              "unparsed_language_dependencies":False,
              "transitive_dependencies_verified":False,
              "native_build_verified":False,"original_execution_attested":False,
              "independent_algorithm_certified":False,"eligible_for_soak":False}
        key=(repo,commit)
        if key not in seen_root:
            try:
                raw_tree=gh.get("/repos/"+repo+"/git/trees/"+commit+"?recursive=1")
                if (type(raw_tree) is not dict or
                    raw_tree.get("truncated") is not False or
                    type(raw_tree.get("tree")) is not list):
                    raise APIProblem("INVALID_OR_TRUNCATED_GIT_TREE")
                blobs={}
                for f in raw_tree["tree"]:
                    if type(f) is dict and f.get("type")=="blob":
                        if f["path"] in blobs:
                            raise APIProblem("DUPLICATED_BLOB_IN_GIT_TREE")
                        blobs[f["path"]]=f
                seen_root[key]=blobs
            except APIProblem as exc:
                raise ValueError("frozen Git tree unavailable: "+repo+":"+exc.code) from exc
        tree=seen_root[key]
        if filename not in tree:
            raise ValueError("source root absent from frozen Git tree: "+filename)
        original=tree[filename]
        if (original.get("sha")!=root["git_blob_sha1"] or
            original.get("size")!=root["source_bytes"]):
            raise ValueError("source tree no longer matches v131 immutable receipt")
        try:
            source_bytes,proof=checked_blob(gh,repo,commit,filename)
        except APIProblem as exc:
            raise ValueError("original root source unavailable: "+exc.code) from exc
        if proof!={"source_sha256":root["source_sha256"],
                  "git_blob_sha1":root["git_blob_sha1"],
                  "bytes":root["source_bytes"]}:
            raise ValueError("source root bytes not identical to original v131 evidence")
        base["root_content_status"]="FROZEN_SOURCE_BYTES_RECHECKED"
        references,symbols=relative_candidates(source_bytes,filename,probe["parser"])
        base["unresolved_linker_symbols"]=symbols
        base["unparsed_language_dependencies"]=probe["parser"]=="UNSUPPORTED_DSL_NEEDS_REVIEW"
        for dependency in references:
            candidates=dependency["candidate_paths"]
            for p in candidates:
                safe_path(p)
            existing=[p for p in candidates if p in tree]
            rec={"reference":dependency["reference"],
                 "candidate_paths":candidates,"status":None,
                 "resolved_path":None,"sha256":None,
                 "git_blob_sha1":None,"bytes":None}
            if len(existing)>1:
                rec["status"]="AMBIGUOUS_LITERAL_MODULE_PATH"
            elif len(existing)==1:
                name=existing[0]
                try:
                    _,proof=checked_blob(gh,repo,commit,name)
                except APIProblem as exc:
                    rec["status"]="DEPENDENCY_BYTES_UNAVAILABLE_"+exc.code
                else:
                    if (proof["git_blob_sha1"]!=tree[name].get("sha") or
                        proof["bytes"]!=tree[name].get("size")):
                        rec["status"]="DEPENDENCY_GIT_TREE_BLOB_MISMATCH"
                    else:
                        rec["status"]="DIRECT_RELATIVE_FILE_BYTES_RECHECKED"
                        rec.update({"resolved_path":name,
                                    "sha256":proof["source_sha256"],
                                    "git_blob_sha1":proof["git_blob_sha1"],
                                    "bytes":proof["bytes"]})
            else:
                # Header can exist in a different include directory, but
                # no flags/build graph have been audited to prove it is used.
                matches=[p for p in tree if
                         posixpath.basename(p)==posixpath.basename(candidates[0])]
                if probe["parser"]=="CPP_QUOTED_INCLUDE" and len(matches)==1:
                    rec["status"]="HEADER_ELSEWHERE_INCLUDE_PATH_UNVERIFIED"
                    rec["resolved_path"]=matches[0]
                else:
                    rec["status"]="DIRECT_DEPENDENCY_UNRESOLVED"
            dependency_summary[rec["status"]]+=1
            base["direct_file_references"].append(rec)
        if symbols:
            dependency_summary["ASSEMBLY_EXTERN_SYMBOL_UNRESOLVED"]+=len(symbols)
        if base["unparsed_language_dependencies"]:
            dependency_summary["DSL_DEPENDENCIES_NOT_PARSED"]+=1
        all_results.append(base)
    return {
        "schema":REPORT,
        "manifest_sha256":digest(manifest),
        "v131_lineage_sha256":digest(lineage),
        "eight_verified_root_files":sum(
            x["root_content_status"]=="FROZEN_SOURCE_BYTES_RECHECKED"
            for x in all_results),
        "probed_record_ids":[p["record_id"] for p in manifest["probes"]],
        "distinct_source_families":sorted(set(p["family"] for p in manifest["probes"])),
        "dependency_status_counts":dict(sorted(dependency_summary.items())),
        "observations":all_results,
        "full_dependency_closure_certified":False,
        "native_binary_identity_attested":False,
        "original_Fct_process_attested":False,
        "independent_algorithms_certified":0,
        "original_full_years_certified":0,
        "native_date_calls":0,
        "soak_dispatch_authorized":False,
        "scientific_soak_10000_pass":False,
        "limitation":"Literal direct file imports only. Runtime imports, linker objects, build flags and transitive closures unassessed."
    }


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    for k in ("manifest","v131-lineage","output"):
        ap.add_argument("--"+k,required=True,type=Path)
    args=ap.parse_args()
    manifest=parse_json(args.manifest.read_bytes())
    lineage=parse_json(args.v131_lineage.read_bytes())
    out=audit(manifest,lineage,GitHubReadOnly(os.environ.get("GITHUB_TOKEN","")))
    with args.output.open("xb") as stream:
        stream.write(canonical(out)+b"\n")
    print(json.dumps({x:out[x] for x in (
        "schema","eight_verified_root_files","probed_record_ids",
        "distinct_source_families","dependency_status_counts",
        "full_dependency_closure_certified","native_date_calls",
        "soak_dispatch_authorized","original_full_years_certified")},
        sort_keys=True,ensure_ascii=False))
    return 0


if __name__=="__main__":
    raise SystemExit(main())
