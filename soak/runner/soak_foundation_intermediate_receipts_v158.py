#!/usr/bin/env python3
"""v158: fail-closed, source-PINNED *synthetic-only* intermediate receipt contract.

No historical converter, subprocess, network client, compiler or timeouts.
This validates the data contract needed *before* an Issue #29 disposition;
it cannot attest a native original snapshot or authorize Soak dispatch.

An SHA-256 chain protects local consistency, not author/source authenticity.
Original provenance would need independent binary/PID/stdout/source receipts.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from native_execution_receipt_v038 import canonical
from soak_foundation_causal_observability_v157 import (
    inverse_ambiguity_demo, synthetic_snapshot, verify_snapshot,
    NEEDED, PARENTS, HISTORICAL_OBSERVED, ARCHIVES
)

SCHEMA = "PASTAFARI_SOAK_FOUNDATION_INTERMEDIATE_RECEIPTS_V158/1"
STATUS = "SYNTHETIC_RECEIPT_CONSISTENCY_ONLY_NOT_SOURCE_ATTESTATION"
SCOPE = "SYNTHETIC_TOY_NO_ORIGINAL_FCT"
ZERO = "0" * 64
SOURCE_IMPORTS = 0
STAGES = (
    "YEAR_BOUNDS", "MONTH_COUNT", "MONTH_LENGTHS", "WEAVE_SELECTOR",
    "MONTH_WEAVING", "MONTH_NAMES", "TARGET_LOOKUP", "FINAL_FIELDS"
)
REAL_NEEDED = (
    "year_open_day","year_close_day","month_count","month_lengths",
    "selector_family","global_rank_or_ada_tickets","month_weaving",
    "month_name_indices","target_offset0","month_id","day_in_month",
    "month_index"
)


def require(ok: bool, why: str) -> None:
    if not ok:
        raise ValueError(why)


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def pairs_no_duplicates(pairs):
    result = {}
    for name, value in pairs:
        require(name not in result, "duplicate JSON key")
        result[name] = value
    return result


def strict_json(blob: bytes) -> dict:
    require(type(blob) is bytes, "receipt must be bytes")
    try:
        data = json.loads(blob.decode("utf-8"),
                          object_pairs_hook=pairs_no_duplicates,
                          parse_constant=lambda x: (_ for _ in ()).throw(
                              ValueError("nonfinite number " + x)))
    except (UnicodeError, TypeError) as e:
        raise ValueError("receipt encoding invalid") from e
    require(type(data) is dict and canonical(data) == blob,
            "receipt JSON is not canonical or not an object")
    return data


def payloads(snapshot: dict) -> list[dict]:
    verify_snapshot(snapshot)
    return [
        {"year_open_day":snapshot["year_open_day"],
         "year_close_day":snapshot["year_close_day"]},
        {"month_count":snapshot["month_count"]},
        {"month_lengths":snapshot["month_lengths"]},
        {"selector_family":snapshot["engine_math_family"],
         "selector_evidence_type":"NO_ORIGINAL_RANK_SYNTHETIC_DIRECT_VECTOR",
         "global_rank_or_ada_tickets":None},
        {"month_weaving":snapshot["month_weaving"]},
        {"month_name_indices":snapshot["month_name_indices"]},
        {"target_offset0":snapshot["target_offset0"],
         "target_day":snapshot["target_day"],
         "month_id":snapshot["month_id"]},
        {"day_in_month":snapshot["day_in_month"],
         "month_index":snapshot["month_index"]},
    ]


def make_case(case: str, snapshot: dict) -> dict:
    require(case in ("A","B"), "only two hardcoded synthetic example cases")
    verify_snapshot(snapshot)
    steps = []
    previous = ZERO
    for i, (stage, payload) in enumerate(zip(STAGES, payloads(snapshot))):
        event = {
            "stage_index":i, "stage":stage, "payload":payload,
            "previous_event_sha256":previous,
        }
        event["event_sha256"] = sha(canonical(event))
        steps.append(event)
        previous = event["event_sha256"]
    body = {
        "schema":SCHEMA, "status":STATUS, "scope":SCOPE,
        "case_id":case, "historical_foundation":False,
        "historical_source_code_executed":False,
        "historical_original_Fct_calls":0,
        "original_full_years_certified":0,
        "halt_new_native_soak_dispatch":True,
        "main_changes_permitted":False,
        "native_process_provenance":None,
        "real_source_intermediate_receipt":None,
        "independent_source_identity_proven":False,
        "synthetic_snapshot":snapshot, "events":steps,
        "final_event_sha256":previous,
        "external_sha256_anchor_exists":False,
        "cryptographically_authenticated_source_record":False,
    }
    return {**body,"bundle_sha256":sha(canonical(body))}


def verify_case(obj: dict, *, expect_case: str | None = None) -> None:
    require(type(obj) is dict and
            set(obj)=={
                "schema","status","scope","case_id","historical_foundation",
                "historical_source_code_executed","historical_original_Fct_calls",
                "original_full_years_certified","halt_new_native_soak_dispatch",
                "main_changes_permitted","native_process_provenance",
                "real_source_intermediate_receipt",
                "independent_source_identity_proven","synthetic_snapshot",
                "events","final_event_sha256","external_sha256_anchor_exists",
                "cryptographically_authenticated_source_record","bundle_sha256"
            }, "receipt unexpected keys")
    require(obj["schema"] == SCHEMA and obj["status"] == STATUS and
            obj["scope"] == SCOPE and
            obj["case_id"] in ("A","B") and
            (expect_case is None or obj["case_id"] == expect_case),
            "not the exact authorized synthetic contract")
    require(obj["historical_foundation"] is False
            and obj["historical_source_code_executed"] is False
            and type(obj["historical_original_Fct_calls"]) is int
            and obj["historical_original_Fct_calls"] == 0
            and type(obj["original_full_years_certified"]) is int
            and obj["original_full_years_certified"] == 0
            and obj["halt_new_native_soak_dispatch"] is True
            and obj["main_changes_permitted"] is False
            and obj["native_process_provenance"] is None
            and obj["real_source_intermediate_receipt"] is None
            and obj["independent_source_identity_proven"] is False
            and obj["external_sha256_anchor_exists"] is False
            and obj["cryptographically_authenticated_source_record"] is False,
            "synthetic QA receipt tried to promote native provenance")
    s = obj["synthetic_snapshot"]
    verify_snapshot(s)
    require(type(obj["events"]) is list and len(obj["events"])==len(STAGES),
            "missing or extra sequence stages")
    previous = ZERO
    for i, (actual, name, expected_payload) in enumerate(
        zip(obj["events"], STAGES, payloads(s))
    ):
        require(type(actual) is dict and set(actual)=={
            "stage_index","stage","payload","previous_event_sha256",
            "event_sha256"
        }, "unexpected event data or missing chain field")
        require(type(actual["stage_index"]) is int
                and actual["stage_index"]==i
                and actual["stage"]==name
                and actual["payload"]==expected_payload
                and actual["previous_event_sha256"]==previous,
                "source-data stage altered, omitted, unordered or mismatched")
        event_no_hash={k:v for k,v in actual.items() if k!="event_sha256"}
        require(actual["event_sha256"]==sha(canonical(event_no_hash)),
                "event hash chain invalid")
        previous=actual["event_sha256"]
    require(obj["final_event_sha256"] == previous,
            "final event seal mismatched")
    body={k:v for k,v in obj.items() if k!="bundle_sha256"}
    require(obj["bundle_sha256"]==sha(canonical(body)),
            "bundle SHA-256 inconsistent")


def verify_both(bundle: dict) -> dict:
    require(type(bundle) is dict and set(bundle)=={
        "schema","status","cases","historical_source_inputs",
        "real_intermediate_fields_missing",
        "field_dependencies","native_original_dispatch_admitted",
        "original_soak_years_certified","main_changes_permitted"
    }, "unknown evidence bundle fields")
    require(bundle["schema"]==SCHEMA and bundle["status"]==STATUS,
            "invalid comparison bundle identity")
    cases=bundle["cases"]
    require(type(cases) is list and len(cases)==2,
            "two synthetic cases required")
    verify_case(cases[0], expect_case="A")
    verify_case(cases[1], expect_case="B")
    a,b=(z["synthetic_snapshot"] for z in cases)
    require(a["target_day"]==b["target_day"]
            and a["month_index"]==b["month_index"]==20
            and a["day_in_month"]==b["day_in_month"]==2
            and a["month_id"]!=b["month_id"]
            and a["month_weaving"]!=b["month_weaving"]
            and a["month_name_indices"]!=b["month_name_indices"],
            "same final output must be possible for different toy internals")
    require(bundle["historical_source_inputs"]==
            {x:list(y) for x,y in HISTORICAL_OBSERVED.items()},
            "historical final output evidence changed")
    require(bundle["real_intermediate_fields_missing"]==list(REAL_NEEDED),
            "missing original fields cannot be claimed as observed")
    require(bundle["field_dependencies"]==
            {name:list(PARENTS[name]) for name in NEEDED},
            "partial causal dependency graph drifted")
    require(bundle["native_original_dispatch_admitted"] is False
            and type(bundle["original_soak_years_certified"]) is int
            and bundle["original_soak_years_certified"]==0
            and bundle["main_changes_permitted"] is False,
            "original dispatch/acceptance promotion forbidden")
    return {
        "schema":SCHEMA, "status":"SYNTHETIC_TRACE_CHAIN_VALID_AND_ORIGINAL_PROVENANCE_GAP_UNRESOLVED",
        "two_complete_synthetic_receipts":True,
        "all_event_hashes_bound":True,
        "historical_foundation_intermediates_attested":False,
        "historical_native_date_calls":0,
        "original_soak_years_certified":0,
        "source_authenticity_proven":False,
        "native_soak_dispatch_admitted":False,
    }


def build() -> dict:
    examples=inverse_ambiguity_demo()
    cases=[make_case("A", examples["example_a"]),
           make_case("B", examples["example_b"])]
    package = {
        "schema":SCHEMA,"status":STATUS,"cases":cases,
        "historical_source_inputs":{k:list(v) for k,v in HISTORICAL_OBSERVED.items()},
        "real_intermediate_fields_missing":list(REAL_NEEDED),
        "field_dependencies":{k:list(PARENTS[k]) for k in NEEDED},
        "native_original_dispatch_admitted":False,
        "original_soak_years_certified":0,
        "main_changes_permitted":False,
    }
    verify_both(package)
    return package


def main() -> int:
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--write-example", type=Path)
    p.add_argument("--verify-example", type=Path)
    a=p.parse_args()
    require((a.write_example is None)!=(a.verify_example is None),
            "select exactly one of --write-example or --verify-example")
    if a.write_example:
        data=build()
        with a.write_example.open("xb") as f:f.write(canonical(data))
        report=verify_both(data)
    else:
        report=verify_both(strict_json(a.verify_example.read_bytes()))
    print(json.dumps(report, sort_keys=True))
    return 0


if __name__=="__main__":
    raise SystemExit(main())
