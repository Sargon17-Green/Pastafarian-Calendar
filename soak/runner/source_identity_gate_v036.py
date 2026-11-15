#!/usr/bin/env python3
"""Strict v2 identity gate for a crash-durable DIFFERENTIAL soak ledger.

This is a structural/source-class gate, NOT an algorithmic independence oracle.
A self-declared engine id, lineage tag, source hash, or receipt cannot prove
whether two implementations were independently developed. v2 always returns
no official native-soak certification until an external audit is integrated.
Legacy v1 plans stay readable/recoverable but are explicitly uncertified.
No code in this module executes converters, reads network, or changes main.
"""
from __future__ import annotations

import hashlib
import json
import re
from typing import Any

PROVENANCE_CONTRACT = "PASTAFARI_SOAK_RECOVERY/2"
IDENTITY_SCHEMA = "PASTAFARI_SOURCE_IDENTITY/2"
LEGACY_CONTRACT = "PASTAFARI_SOAK_RECOVERY/1"
HEX64 = re.compile(r"^[a-f0-9]{64}$")
HEX40 = re.compile(r"^[a-f0-9]{40}$")
IDENT = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.:-]{0,127}$")
REPO = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
NATIVE_KINDS = frozenset({"original", "reference"})
NATIVE_METHODS = frozenset({"unchanged_original_Fct", "unchanged_reference_Fct"})
INADMISSIBLE_KINDS = frozenset({"derived", "adapter", "wrapper", "transcript", "synthetic"})


def _canonical(data: Any) -> bytes:
    return json.dumps(data, sort_keys=True, separators=(",", ":"),
                      ensure_ascii=False, allow_nan=False).encode("utf8")


def _hex64(value: Any, name: str) -> None:
    if not isinstance(value, str) or not HEX64.fullmatch(value):
        raise ValueError("invalid source identity digest: " + name)


def _identity_string(value: Any, name: str) -> None:
    if not isinstance(value, str) or not IDENT.fullmatch(value):
        raise ValueError("invalid source identity key: " + name)


def validate_provenance_v2(plan: dict) -> dict:
    """Validate immutable *assertions*, never attest real execution or lineage.

    v2 is noncertifying until there is a separate, independently checked audit.
    A v1 plan or a derived engine must not be promoted by wrapper metadata.
    """
    if not isinstance(plan, dict) or plan.get("contract") != PROVENANCE_CONTRACT:
        raise ValueError("source identity v2 requires exact version 2 plan")
    if set(plan).difference({
        "contract", "calculation_day", "chunk_days", "years", "engines",
        "identity_contract", "soak_purpose", "independence_audit_status",
    }):
        raise ValueError("unknown identity v2 plan fields")
    if plan.get("identity_contract") != IDENTITY_SCHEMA:
        raise ValueError("missing strict source identity contract version")
    if plan.get("soak_purpose") != "EXPERIMENTAL_NATIVE_DIFFERENTIAL_UNCERTIFIED":
        raise ValueError("v2 experimental source identity gate rejects official soak claim")
    if plan.get("independence_audit_status") != "NOT_CERTIFIED":
        raise ValueError("self-certified algorithmic independence forbidden")
    engines = plan.get("engines")
    if not isinstance(engines, list) or len(engines) < 2:
        raise ValueError("two original source descriptors required")
    seen_commits = set()
    seen_identity = set()
    seen_lineage = set()
    for engine in engines:
        if not isinstance(engine, dict):
            raise ValueError("malformed source identity descriptor")
        if set(engine) != {
            "id", "algorithm_id", "source_sha256", "binary_sha256",
            "name_map_sha256", "provenance"
        }:
            raise ValueError("strict v2 source identity fields are missing/extra")
        p = engine.get("provenance")
        if not isinstance(p, dict) or set(p) != {
            "schema", "source_class", "source_commit", "repository",
            "source_path", "source_family", "native_entrypoint",
            "execution_method", "derived_from", "original_source_sha256",
        }:
            raise ValueError("strict v2 source provenance fields are missing/extra")
        if p["schema"] != IDENTITY_SCHEMA:
            raise ValueError("wrong per-engine provenance schema")
        cls = p["source_class"]
        if cls in INADMISSIBLE_KINDS:
            raise ValueError("derived/wrapper source cannot enter native-original soak")
        if cls not in NATIVE_KINDS:
            raise ValueError("source_class unknown or untrusted")
        method = p["execution_method"]
        if (method not in NATIVE_METHODS or
                (cls == "original" and method != "unchanged_original_Fct") or
                (cls == "reference" and method != "unchanged_reference_Fct")):
            raise ValueError("source execution method is derived/unknown or class-mismatched")
        if p["derived_from"] is not None:
            raise ValueError("source with derived_from cannot claim unchanged original")
        if not isinstance(p["source_commit"], str) or not HEX40.fullmatch(p["source_commit"]):
            raise ValueError("unpinned source commit SHA")
        if not isinstance(p["repository"], str) or not REPO.fullmatch(p["repository"]):
            raise ValueError("invalid original source repository")
        if (not isinstance(p["source_path"], str)
                or not p["source_path"] or p["source_path"].startswith("/")
                or "\\" in p["source_path"] or "\x00" in p["source_path"]
                or any(part in ("", ".", "..") for part in p["source_path"].split("/"))):
            raise ValueError("invalid original source path")
        if (not isinstance(p["native_entrypoint"], str) or
                not 3 <= len(p["native_entrypoint"]) <= 256 or
                any(ch in p["native_entrypoint"] for ch in ("\n", "\r", "\x00"))):
            raise ValueError("native entrypoint not pinned")
        _identity_string(engine["id"], "engine.id")
        _identity_string(engine["algorithm_id"], "engine.algorithm_id")
        _identity_string(p["source_family"], "source_family")
        for field in ("source_sha256", "binary_sha256", "name_map_sha256"):
            _hex64(engine[field], field)
        _hex64(p["original_source_sha256"], "original_source_sha256")
        if p["original_source_sha256"] != engine["source_sha256"]:
            raise ValueError("original source SHA not equal pinned engine SHA")
        commit_identity = (p["repository"], p["source_commit"],
                           p["source_path"], p["native_entrypoint"])
        full_identity = (p["source_family"], engine["algorithm_id"])
        if commit_identity in seen_commits:
            raise ValueError("same original native entrypoint impersonates two engines")
        if full_identity in seen_identity or p["source_family"] in seen_lineage:
            raise ValueError("duplicate source lineage or underlying algorithm family")
        seen_commits.add(commit_identity)
        seen_identity.add(full_identity)
        seen_lineage.add(p["source_family"])

    # A source-class receipt is not an independent audit or cryptographically
    # signed proof of who generated a given stdout stream.
    return {
        "schema": IDENTITY_SCHEMA,
        "status": "STRUCTURAL_NATIVE_SOURCE_IDENTITY_PASS_NOT_INDEPENDENCE_CERTIFIED",
        "engine_count": len(engines),
        "plan_identity_sha256": hashlib.sha256(_canonical(plan)).hexdigest(),
        "original_source_class_assertions_checked": len(engines),
        "independence_certified": False,
        "unchanged_native_execution_proven": False,
        "official_soak_years_authorized": 0,
        "source_identity_provenance_is_self_declared": True,
    }


def evaluate_plan_identity(plan: dict) -> dict:
    """Structural verdict safe for display; legacy is never officially admitted."""
    if not isinstance(plan, dict):
        raise ValueError("plan must be object")
    version = plan.get("contract")
    if version == PROVENANCE_CONTRACT:
        return validate_provenance_v2(plan)
    if version == LEGACY_CONTRACT:
        return {
            "schema": IDENTITY_SCHEMA,
            "status": "LEGACY_PLAN_SOURCE_IDENTITY_NOT_VERIFIED",
            "engine_count": len(plan.get("engines", [])),
            "plan_identity_sha256": hashlib.sha256(_canonical(plan)).hexdigest(),
            "independence_certified": False,
            "unchanged_native_execution_proven": False,
            "official_soak_years_authorized": 0,
            "source_identity_provenance_is_self_declared": True,
        }
    raise ValueError("unknown soak recovery plan contract")
