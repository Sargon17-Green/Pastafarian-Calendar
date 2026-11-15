#!/usr/bin/env python3
"""Import pinned REF-41 / REF-24 pilot transport evidence into v2 crash ledger.

READS results produced by existing v017 original-F(c,t) transport wrappers.
v018 independently validates source blobs, native names, numeric fields,
raw/normalized correspondence, dates and existing transport receipt.
v038 then binds those bytes to immutable plan/chunk SQLite evidence.

This importer DOES NOT execute a converter, and cannot attest that the
producer process or interpreter was the one claimed. "binary_sha256" in the
experimental plan is checked against the *transport adapter artifact*,
not independently against an operating-system process image.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from native_execution_receipt_v038 import make_receipt, canonical, sha
from native_raw_pair_gate_v018 import (
    LOCK, name_maps, verify_locked_sources, verify_stream
)
from recovery_store import CrashStore
from source_identity_gate_v036 import PROVENANCE_CONTRACT

PILOT_PROFILES = {
    "REF-41": {
        "source_path": "tests/normative_reference.py",
        "transport": "pilot_python_transport_v017.py",
        "source_class": "reference",
        "execution_method": "unchanged_reference_Fct",
    },
    "REF-24": {
        "source_path": "tests/normative-reference.js",
        "transport": "pilot_javascript_transport_v017.cjs",
        "source_class": "reference",
        "execution_method": "unchanged_reference_Fct",
    },
}


def catalog_digest(maps: list[dict]) -> str:
    if len(maps) != 2:
        raise ValueError("source native name maps must have two groups")
    ordered = []
    for expected, group in zip((17, 47), maps):
        if len(group) != expected or sorted(group.values()) != list(range(1, expected + 1)):
            raise ValueError("source name map incomplete or not canonical")
        ordered.append([name for name, index in sorted(group.items(), key=lambda x: x[1])])
    return sha(canonical({"cutlets":ordered[0], "months":ordered[1]}))


def _load_original_source_identity(engine_id: str, source_root: Path, adapter: Path):
    if engine_id not in PILOT_PROFILES:
        raise ValueError("only known REF-41 or REF-24 pilot sources can be imported")
    profile = PILOT_PROFILES[engine_id]
    source_info, contents = verify_locked_sources(source_root, engine_id)
    if (source_info["id"] != engine_id
            or source_info["sources"][0]["path"] != profile["source_path"]):
        raise ValueError("original pilot source lock does not describe expected primary source")
    verified_name_sha = catalog_digest(name_maps(engine_id, contents))
    if adapter.name != profile["transport"] or not adapter.is_file():
        raise ValueError("native pilot transport implementation has unexpected path")
    return source_info, verified_name_sha, sha(adapter.read_bytes())


def import_pilot_chunk(store: CrashStore, *, engine_id: str, year: str,
                       ordinal: int, source_root: Path, adapter: Path,
                       raw_file: Path, normalized_file: Path,
                       transport_receipt: Path) -> dict:
    """Import one exact precomputed chunk. No OS child is launched here."""
    if store.plan["contract"] != PROVENANCE_CONTRACT:
        raise ValueError("native pilot import requires v2 ledger and source identity")
    if engine_id not in PILOT_PROFILES or engine_id not in store.engines:
        raise ValueError("pilot engine unrecognized or not in run plan")
    store._assert_immutable_plan()
    chunk = store._chunk(engine_id,year,ordinal)
    native, names_sha, adapter_sha = _load_original_source_identity(
        engine_id,source_root,adapter)
    entry = next((e for e in store.plan["engines"] if e["id"] == engine_id), None)
    profile = PILOT_PROFILES[engine_id]
    p = entry["provenance"]
    expected = {
        "source_class":profile["source_class"],
        "execution_method":profile["execution_method"],
        "source_path":profile["source_path"],
        "source_commit":native["commit"],
        "repository":native["repository"],
        "native_entrypoint":native["entrypoint"],
    }
    for field,value in expected.items():
        if p.get(field) != value:
            raise ValueError("original pilot provenance differs from pinned source: "+field)
    if (entry["source_sha256"] != native["sources"][0]["sha256"]
            or p["original_source_sha256"] != entry["source_sha256"]
            or entry["name_map_sha256"] != names_sha
            or entry["binary_sha256"] != adapter_sha):
        raise ValueError("pilot source/name-map/transport artifact SHA mismatch")
    receipt = json.loads(transport_receipt.read_text(encoding="utf8"))
    case=store._case(year)
    if (receipt.get("calculation_day") != store.plan["calculation_day"]
            or receipt.get("first_target_day") != chunk.first_day
            or receipt.get("last_target_day") != chunk.last_day
            or receipt.get("boundary_evidence_sha256") != case.boundary_evidence_sha256):
        raise ValueError("pilot transport output is not scoped to the pinned ledger chunk")
    verified = verify_stream(engine_id,source_root,raw_file,normalized_file,
                             transport_receipt)
    if (verified["status"]!="NATIVE_RAW_TRANSPORT_EVIDENCE_PASS_BOUNDED"
            or verified["rows_verified"]!=int(chunk.last_day)-int(chunk.first_day)+1
            or verified["year_certified"] is not False):
        raise ValueError("native source and normalization validation not passed")
    raw=raw_file.read_bytes()
    normalized=normalized_file.read_bytes()
    bound=make_receipt(store.plan,store.plan_sha,engine_id,year,
                       chunk.first_day,chunk.last_day,ordinal,normalized,raw)
    outcome=store.commit_chunk(engine_id,year,ordinal,normalized,
                               raw_stdout=raw,native_receipt=bound)
    return {
        "schema":"PASTAFARI_PILOT_IMPORT_TO_LEDGER/1",
        "status":"ORIGINAL_PILOT_NATIVE_RAW_SEMANTICS_VALIDATED_NO_EXECUTION_ATTESTATION",
        "engine_id":engine_id,"year":year,
        "first_target_day":chunk.first_day, "last_target_day":chunk.last_day,
        "source_commit":native["commit"], "source_sha256":entry["source_sha256"],
        "transport_adapter_sha256":adapter_sha,
        "native_rows_validated":verified["rows_verified"],
        "native_receipt_sha256":sha(canonical(bound)),
        "ledger_result":outcome,
        "trusted_process_execution_attested":False,
        "independent_algorithm_attested":False,
        "official_original_soak_years_certified":0,
    }
