#!/usr/bin/env python3
"""v070: ordinal-parametric ORIGINAL two-target F(c,t) supervisor, Linux CI only.

This is a carefully checked adapter over the already-successful pinned v061
supervisor, NOT an optimization of the original engine. It keeps Python
NormativeCalendar.calendar_date_ids and the Kotlin production bridge untouched.
For each single requested ordinal the two source engines run sequentially;
no year or independent canonical-oracle certification is issued.

The configured scope is year 5000 / c=-15055671, two target days per
chunk. Only previously UNEXECUTED ordinals >=1017 may be dispatched by
this coordinator. No work is performed without --ci-original-chunk.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import sys

import supervised_next_two_days_v061 as legacy
from native_execution_receipt_v038 import canonical,sha
from supervised_process_observation_v041 import _durable_exclusive,sha_file

SCHEMA="PASTAFARI_SUPERVISED_ORIGINAL_ORDINAL_CHUNK_V070/1"
DISPATCH_SCHEMA="PASTAFARI_SUPERVISED_ORDINAL_DISPATCH_RECEIPT_V070/1"
YEAR_FIRST=-15057702
YEAR_LAST=-15053459
YEAR_DAYS=YEAR_LAST-YEAR_FIRST+1
CHUNK_DAYS=2
EXISTING_SUPERVISED_MAX_ORDINAL=1016


def bounds_for_original_ordinal(ordinal:int)->tuple[str,str]:
    """Validated source-year arithmetic, not a derived date conversion."""
    if type(ordinal) is not int or not (
        EXISTING_SUPERVISED_MAX_ORDINAL < ordinal < YEAR_DAYS//CHUNK_DAYS
    ):
        raise ValueError("ordinal requires new two-day source chunk 1017..2121")
    first=YEAR_FIRST+ordinal*CHUNK_DAYS
    last=first+CHUNK_DAYS-1
    if first>last or last>YEAR_LAST:
        raise ValueError("source year 5000 original ordinal exceeds fixed boundary")
    return str(first),str(last)


def configure(ordinal:int)->tuple[str,str]:
    """One-shot isolated process configuration of original v061 supervisor.

    Not thread safe or an OS runner; caller must start a fresh process per
    ordinal. The ORIGINAL Python/Kotlin source code is never modified.
    """
    first,last=bounds_for_original_ordinal(ordinal)
    legacy.FIRST=first
    legacy.LAST=last
    legacy.YEAR_CHUNK_ORDINAL=ordinal
    legacy.SCHEMA=SCHEMA
    if (legacy.C!="-15055671" or legacy.YEAR!="5000"
        or legacy.N!=2 or legacy.BOUNDARY_SHA!=
        "ad64cc51522d7f19cb8a238e2a6a418e75203c6cbfe017c394f623edeb882e78"):
        raise ValueError("frozen original source year witness constants changed")
    return first,last


def run_chunk(ordinal:int,source_root:Path,kotlin_repo:Path,
              original_kotlin_jar:Path,evidence_root:Path)->dict:
    first,last=configure(ordinal)
    # legacy.run performs CI-only _admit, resource preflight for both sources,
    # immutable source SHA checks, independent OS process execution,
    # first-mismatch stop and exact native Python/Kotlin 5-field comparison.
    result=legacy.run(source_root,kotlin_repo,original_kotlin_jar,evidence_root)
    if (result["status"]!="SUPERVISED_ORIGINAL_TWO_DAYS_MATCH_NOT_FULL_YEAR"
        or result["schema"]!=SCHEMA or result["first_target_day"]!=first
        or result["last_target_day"]!=last or result["full_year_chunk_ordinal"]!=ordinal
        or result["matched_original_day_pairs"]!=2
        or result["first_mismatch"] is not None
        or result["original_complete_years_soak_passed"]!=0):
        raise ValueError("native original source two-day gate NOT accepted")
    root=evidence_root.resolve(strict=True)
    own=Path(__file__).resolve(strict=True)
    inherited=Path(legacy.__file__).resolve(strict=True)
    dispatch={
        "schema":DISPATCH_SCHEMA,"status":"TWO_REAL_ORIGINAL_SOURCE_DAYS_NOT_YEAR",
        "calculation_day":legacy.C,"year":legacy.YEAR,
        "year_first_target_day":str(YEAR_FIRST),
        "year_last_target_day":str(YEAR_LAST),
        "chunk_days":CHUNK_DAYS,"ordinal":ordinal,
        "first_target_day":first,"last_target_day":last,
        "runner_wrapper_sha256":sha_file(own),
        "inherited_supervisor_v061_sha256":sha_file(inherited),
        "native_verdict_sha256":sha((root/"original-two-day-verdict.json").read_bytes()),
        "ref41_native_process_sha256":sha((root/"REF-41/process-evidence.json").read_bytes()),
        "kotlin_native_process_sha256":sha((root/"PROD-KT-CY/process-evidence.json").read_bytes()),
        "original_native_date_pairs_compared":2,
        "full_original_years_soak_certified":0,
        "source_lineage_independence_certified":False,
        "external_host_process_attestation_certified":False,
        "canonical_oracle_certified":False,
        "windows_host_used":False,
    }
    _durable_exclusive(root/"original-ordinal-dispatch.json",canonical(dispatch))
    return {**result,"original_ordinal_dispatch_sha256":
            sha((root/"original-ordinal-dispatch.json").read_bytes())}


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--ci-original-chunk",action="store_true",required=True)
    parser.add_argument("--ordinal",type=int,required=True)
    parser.add_argument("--sources-root",type=Path,required=True)
    parser.add_argument("--original-kotlin-repo",type=Path,required=True)
    parser.add_argument("--original-kotlin-jar",type=Path,required=True)
    parser.add_argument("--evidence-root",type=Path,required=True)
    args=parser.parse_args()
    result=run_chunk(args.ordinal,args.sources_root,args.original_kotlin_repo,
                     args.original_kotlin_jar,args.evidence_root)
    print("V070_SUPERVISED_ORIGINAL_ORDINAL="+json.dumps(result,sort_keys=True))


if __name__=="__main__":
    main()
