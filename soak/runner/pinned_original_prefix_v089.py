#!/usr/bin/env python3
"""v089: generic, fail-closed readiness-only original ZIP prefix inventory.

The first two native ZIPs are legacy frozen source receipts. Further ZIPs
must have exactly one committed manifest per contiguous ordinal. Never treat
this inventory as a completed source year or an algorithmic-lineage proof.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import re

from original_generic_source_chunk_ledger_v073 import manifest_for
from original_chunk_artifact_gate_v072 import archive_files,validate_coordinates,sha
from source_ordinal_dispatch_v085 import pinned_prefix,SOURCE_COMMITS,BOUNDARY
from verify_next_original_chunk_v065 import json_unique

SCHEMA="PASTAFARI_PINNED_ORIGINAL_READINESS_PREFIX_V089/1"
FIRST=1015
MIN_LAST=1021
MAX_CI_LAST=1030
BASE=(
    (1015,14186295655,"f87b2e925b4a400cff2e2469be5b873b66c89ca35498e8fcda1090ab55d5d390"),
    (1016,14264392351,"91985794e9bb8e3c6995aa5634d684872c60aae544eaf780b668797d86557eb9"),
)
HEX=re.compile(r"[0-9a-f]{64}\Z")


def collect(root:Path)->dict:
    last=pinned_prefix(root)
    if not MIN_LAST<=last<=MAX_CI_LAST:
        raise ValueError("CI readiness pilot bounded to pinned ordinals 1021..1030")
    rows=[{"ordinal":o,"artifact_id":i,"sha256":s,"run_id":0,
           "path":f"evidence/source-{o}.zip"} for o,i,s in BASE]
    ids={r["artifact_id"] for r in rows}
    digests={r["sha256"] for r in rows}
    for ordinal in range(1017,last+1):
        pin,_=manifest_for(ordinal)
        c,year,first_day,last_day,got=validate_coordinates(pin)
        aid=pin.get("artifact_id")
        rid=pin.get("run_id")
        digest=pin.get("artifact_sha256")
        if (got!=ordinal or c!="-15055671" or year!="5000" or
                pin["original_source_commits"]!=SOURCE_COMMITS or
                pin.get("comparison",{}).get("first_mismatch","missing") is not None or
                pin.get("comparison",{}).get("original_year_soak_passes_certified")!=0 or
                type(aid) is not int or aid<=0 or aid in ids or
                type(rid) is not int or rid<=0 or
                type(digest) is not str or HEX.fullmatch(digest) is None or
                digest in digests):
            raise ValueError("previous original ZIP manifest not fully sealed")
        rows.append({"ordinal":ordinal,"artifact_id":aid,"sha256":digest,
                     "run_id":rid,"path":f"evidence/source-{ordinal}.zip"})
        ids.add(aid)
        digests.add(digest)
    if [r["ordinal"] for r in rows]!=list(range(FIRST,last+1)):
        raise ValueError("source ZIP provenance ordinal gap")
    return {"schema":SCHEMA,"last_ordinal":last,"artifacts":rows,
            "committed_full_original_years":0,"candidate_kotlin_years":0,
            "independence_certified":False,"windows_used":False}


def verify_new_request(archive:bytes,pin:dict)->dict:
    """Additional frozen v085 request source binding for ordinals >=1020."""
    c,year,first,last,ordinal=validate_coordinates(pin)
    if ordinal<1020:
        return {"ordinal":ordinal,"request_required":False}
    files=archive_files(archive,pin)
    raw=files["authorized-original-source-request-v085.json"]
    entry=pin.get("original_ordinal_request")
    request=json_unique(raw)
    allowed={"schema","ordinal","year","calculation_day","first_target_day",
             "last_target_day","boundary_evidence_sha256","original_source_commits"}
    if (not isinstance(entry,dict) or
            set(entry)!={"schema","source_commit","request_sha256"} or
            type(entry["source_commit"]) is not str or
            re.fullmatch("[a-f0-9]{40}",entry["source_commit"]) is None or
            type(entry["request_sha256"]) is not str or
            entry["request_sha256"]!=sha(raw) or
            request.get("schema")!=entry["schema"] or
            entry["schema"]!="PASTAFARI_ORIGINAL_SOURCE_ORDINAL_REQUEST_V085/1" or
            set(request)!=allowed or
            type(request["ordinal"]) is not int or request["ordinal"]!=ordinal or
            request["calculation_day"]!=c or request["year"]!=year or
            (request["first_target_day"],request["last_target_day"])!=(first,last) or
            request["boundary_evidence_sha256"]!=BOUNDARY or
            request["original_source_commits"]!=SOURCE_COMMITS or
            raw!=(json.dumps(request,sort_keys=True,separators=(",",":"),
                             ensure_ascii=False)+"\n").encode("utf-8")):
        raise ValueError("source request evidence does not match frozen original ZIP")
    return {"ordinal":ordinal,"request_sha256":sha(raw),
            "status":"V085_NATIVE_DISPATCH_REQUEST_PINNED_NOT_A_YEAR"}


def main():
    p=argparse.ArgumentParser()
    p.add_argument("--repo-root",required=True,type=Path)
    p.add_argument("--index-file",required=True,type=Path)
    args=p.parse_args()
    index=collect(args.repo_root.resolve(strict=True))
    args.index_file.write_text(json.dumps(index,sort_keys=True,indent=2)+"\n",
                              encoding="utf-8")
    print("V089_FROZEN_ORIGINAL_SOURCE_INDEX="+json.dumps({
        "last_ordinal":index["last_ordinal"],
        "frozen_source_archives":len(index["artifacts"]),
        "complete_years":0
    },sort_keys=True))


if __name__=="__main__":
    main()
