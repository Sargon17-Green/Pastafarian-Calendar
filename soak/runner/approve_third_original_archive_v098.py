#!/usr/bin/env python3
"""v098: one-shot, QA-only preservation admission for immutable TypeScript evidence.

Creates an approval manifest; does not execute F(c,t), publish a release, or
perform remote writes. An external Actions step may upload the already-verified
original ZIP only after source replay and exact Git ancestry checks pass.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

from replay_third_original_v095 import pinned, validate_manifest

SCHEMA="PASTAFARI_ORIGINAL_TYPESCRIPT_ARCHIVE_REQUEST_V098/1"
OUTPUT_SCHEMA="PASTAFARI_ORIGINAL_TYPESCRIPT_DRAFT_ARCHIVE_MANIFEST_V098/1"
REQUEST_RE=re.compile(
    r"soak/control/original_archive_requests/typescript-marathi-1021-v098(?:-retry[0-9]{2})?\.json\Z"
)
BRANCH="qa/soak-readiness-20261114"
TAG="soak-native-typescript-marathi-ordinal1021-v098"
FILENAME="typescript-marathi-1021-native.zip"
COMMIT_RE=re.compile(r"[0-9a-f]{40}\Z")


def pair_unique(pairs):
    out={}
    for k,v in pairs:
        if k in out:raise ValueError("duplicate archive approval JSON field")
        out[k]=v
    return out


def canon(obj):
    return (json.dumps(obj,sort_keys=True,separators=(",",":"),
                       ensure_ascii=False)+"\n").encode("utf-8")


def exact_asset():
    pin=pinned()
    validate_manifest(pin)
    return {
        "filename":FILENAME,
        "artifact_id":pin["artifact"]["id"],
        "run_id":pin["source_run"]["id"],
        "sha256":pin["artifact"]["sha256"],
        "bytes":pin["artifact"]["bytes"],
        "source_commits":pin["source_commits"],
        "source_tree_git_sha1":pin["typescript_source_tree_git_sha1"],
        "members":len(pin["member_sha256"]),
        "matched_original_target_days":pin["original_native_pairs_compared"],
    }


def approve(obj,before):
    expected={"schema","release_tag","source_branch","approved_parent_sha",
              "asset","whole_original_years_certified",
              "independence_certified","canonical_oracle_certified"}
    if (set(obj)!=expected or obj["schema"]!=SCHEMA or
        obj["release_tag"]!=TAG or obj["source_branch"]!=BRANCH or
        obj["approved_parent_sha"]!=before or not COMMIT_RE.fullmatch(before or "") or
        obj["asset"]!=exact_asset() or
        type(obj["whole_original_years_certified"]) is not int or
        obj["whole_original_years_certified"]!=0 or
        obj["independence_certified"] is not False or
        obj["canonical_oracle_certified"] is not False):
        raise ValueError("archive approval not identical to pinned original evidence")
    return True


def git_check(root,before,after):
    if (not COMMIT_RE.fullmatch(before or "") or
        not COMMIT_RE.fullmatch(after or "") or
        before=="0"*40 or after=="0"*40 or before==after):
        raise ValueError("single nonzero push ancestry required")
    def git(*args):
        return subprocess.run(["git","-C",str(root),*args],
                              check=True,capture_output=True,text=True).stdout.strip()
    if git("rev-parse","HEAD")!=after:
        raise ValueError("build checkout is not triggering source approval commit")
    git("merge-base","--is-ancestor",before,after)
    changed=git("diff","--name-status","--no-renames",before,after)
    return approved_new_request_path(changed)


def approved_new_request_path(changed: str) -> str:
    if not changed.startswith("A\t") or changed.count("\n"):
        raise ValueError("only one newly added archive approval file allowed")
    path=changed[2:]
    if REQUEST_RE.fullmatch(path) is None:
        raise ValueError("unexpected original archive request filename")
    return path


def produce(root,before,after):
    request_path=git_check(root,before,after)
    request=root/request_path
    if request.is_symlink() or not request.is_file() or request.stat().st_size>16384:
        raise ValueError("original archive approval request absent or unsafe")
    raw=request.read_bytes()
    data=json.loads(raw.decode("utf-8"),object_pairs_hook=pair_unique)
    if type(data) is not dict or raw!=canon(data):
        raise ValueError("approval request is not canonical JSON")
    approve(data,before)
    return {
        "schema":OUTPUT_SCHEMA,"source_branch":BRANCH,
        "source_commit_sha":after,"release_tag":TAG,
        "source_request_sha256":hashlib.sha256(raw).hexdigest(),
        "asset":exact_asset(),"original_calculation_day":"-15055671",
        "original_target_days":["-15055660","-15055659"],
        "whole_original_years_certified":0,
        "independence_certified":False,
        "canonical_oracle_certified":False,
        "windows_run_started":False,
    }


def main():
    p=argparse.ArgumentParser()
    p.add_argument("--repo-root",required=True,type=Path)
    p.add_argument("--before",required=True)
    p.add_argument("--after",required=True)
    p.add_argument("--manifest-out",required=True,type=Path)
    a=p.parse_args()
    result=produce(a.repo_root.resolve(strict=True),a.before,a.after)
    a.manifest_out.write_bytes(canon(result))
    print("V098_SOURCE_THIRD_ORIGINAL_ARCHIVE_AUTHORIZED_NOT_YEAR")


if __name__=="__main__":
    main()
