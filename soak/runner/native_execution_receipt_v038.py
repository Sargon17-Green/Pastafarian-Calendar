#!/usr/bin/env python3
"""Fail-closed native stdout-to-normalized-chunk evidence contract v038.

The caller must supply exact captured bytes, a machine-readable receipt and
normalized JSONL chunk. The receipt is CHECKED against those bytes and the
immutable run plan, but is NOT a cryptographic attestation of which executable
actually ran. Its claims are self-reported; this is an integrity gate only.

The receipt is deterministic, without mutable timestamps, mutable paths,
operator names, random IDs, or self-declared certification flags.
"""
from __future__ import annotations

import hashlib
import json
import re
from typing import Any, Mapping

from source_identity_gate_v036 import PROVENANCE_CONTRACT, IDENTITY_SCHEMA

SCHEMA = "PASTAFARI_NATIVE_CHUNK_OBSERVATION/1"
STATUS = "RAW_AND_NORMALIZED_HASH_LINKED_NO_EXECUTION_ATTESTATION"
RECEIPT_FIELDS = frozenset((
    "schema", "status", "run_plan_sha256",
    "engine_id", "engine_descriptor_sha256", "source_class",
    "source_commit", "source_sha256", "binary_sha256", "native_entrypoint",
    "calculation_day", "year", "first_target_day", "last_target_day",
    "chunk_ordinal", "exit_code", "raw_stdout_sha256", "raw_stdout_bytes",
    "normalized_chunk_sha256", "normalized_chunk_bytes", "raw_rows",
    "trusted_execution_attested", "independent_algorithm_attested",
    "official_soak_authorized",
))
HEX64 = re.compile(r"^[a-f0-9]{64}$")


def canonical(data: Any) -> bytes:
    return json.dumps(data, sort_keys=True, separators=(",", ":"),
                      ensure_ascii=False, allow_nan=False).encode("utf8")


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _raw_lines(payload: bytes, n: int) -> list[bytes]:
    if not isinstance(payload, bytes):
        raise TypeError("raw native stdout must be original bytes")
    if not payload or not payload.endswith(b"\n") or b"\r" in payload:
        raise ValueError("raw native stdout missing final LF or has CR framing")
    if b"\x00" in payload:
        raise ValueError("raw native stdout contains NUL")
    lines = payload.splitlines(keepends=True)
    if len(lines) != n or any(not line or line == b"\n" for line in lines):
        raise ValueError("raw native stdout day count differs from pinned chunk")
    for line in lines:
        try:
            line.decode("utf-8", errors="strict")
        except UnicodeError as exc:
            raise ValueError("raw native stdout is not valid UTF-8") from exc
    return lines


def _normalized_lines(payload: bytes, n: int) -> list[dict]:
    if not isinstance(payload, bytes) or not payload.endswith(b"\n"):
        raise ValueError("normalized chunk is not complete newline-delimited bytes")
    lines = payload.splitlines(keepends=True)
    if len(lines) != n:
        raise ValueError("normalized chunk count differs from pinned chunk")
    parsed = []
    for line in lines:
        if line.count(b"\n") != 1:
            raise ValueError("invalid normalized line framing")
        def unique(pairs):
            d = {}
            for key, value in pairs:
                if key in d:
                    raise ValueError("duplicate normalized evidence field")
                d[key] = value
            return d
        try:
            item = json.loads(line, object_pairs_hook=unique,
                              parse_constant=lambda _: (_ for _ in ()).throw(ValueError("non-finite JSON")))
        except (UnicodeError, TypeError) as exc:
            raise ValueError("non UTF-8 normalized chunk") from exc
        if not isinstance(item, dict):
            raise ValueError("normalized day is not an object")
        parsed.append(item)
    return parsed


def _expected(plan: dict, plan_sha: str, engine_id: str, year: str,
              first: str, last: str, ordinal: int,
              normalized: bytes, raw: bytes) -> dict:
    if plan.get("contract") != PROVENANCE_CONTRACT or plan.get("identity_contract") != IDENTITY_SCHEMA:
        raise ValueError("native receipt gate accepts only structurally checked v2 plans")
    if not HEX64.fullmatch(plan_sha) or sha(canonical(plan)) != plan_sha:
        raise ValueError("receipt plan digest mismatch")
    if type(ordinal) is not int or ordinal < 0:
        raise ValueError("invalid chunk ordinal")
    engines = [e for e in plan["engines"] if e["id"] == engine_id]
    if len(engines) != 1:
        raise ValueError("receipt engine absent or duplicated in plan")
    e = engines[0]
    p = e["provenance"]
    if p["source_class"] not in ("original", "reference") or p["derived_from"] is not None:
        raise ValueError("derived source cannot emit native original receipt")
    if p["execution_method"] not in ("unchanged_original_Fct", "unchanged_reference_Fct"):
        raise ValueError("unsupported native F(c,t) method")
    n = int(last) - int(first) + 1
    if n <= 0 or n > plan["chunk_days"]:
        raise ValueError("receipt target range inconsistent with chunk-days")
    raw_lines = _raw_lines(raw, n)
    normalized_lines = _normalized_lines(normalized, n)
    # This binds every normalized row to precisely ONE original raw stdout
    # line, including its LF byte. The semantic decoder is a DIFFERENT gate.
    for i, (source, decoded) in enumerate(zip(raw_lines, normalized_lines)):
        if decoded.get("source_raw_sha256") != sha(source):
            raise ValueError(f"row {i+1} source_raw_sha256 not tied to raw stdout line")
        if (decoded.get("calculation_day") != plan["calculation_day"]
                or decoded.get("year") != year
                or decoded.get("target_day") != str(int(first) + i)):
            raise ValueError(f"row {i+1} native receipt coordinate mismatch")
    return {
        "schema": SCHEMA, "status": STATUS,
        "run_plan_sha256": plan_sha,
        "engine_id": engine_id,
        "engine_descriptor_sha256": sha(canonical(e)),
        "source_class": p["source_class"],
        "source_commit": p["source_commit"],
        "source_sha256": e["source_sha256"],
        "binary_sha256": e["binary_sha256"],
        "native_entrypoint": p["native_entrypoint"],
        "calculation_day": plan["calculation_day"],
        "year": year, "first_target_day": first, "last_target_day": last,
        "chunk_ordinal": ordinal, "exit_code": 0,
        "raw_stdout_sha256": sha(raw), "raw_stdout_bytes": len(raw),
        "normalized_chunk_sha256": sha(normalized),
        "normalized_chunk_bytes": len(normalized), "raw_rows": n,
        "trusted_execution_attested": False,
        "independent_algorithm_attested": False,
        "official_soak_authorized": False,
    }


def make_receipt(plan: dict, plan_sha: str, engine_id: str, year: str,
                 first: str, last: str, ordinal: int,
                 normalized: bytes, raw: bytes) -> dict:
    """Deterministic integrity receipt. Caller must not call this a proof."""
    return _expected(plan, plan_sha, engine_id, year, first, last,
                     ordinal, normalized, raw)


def verify_receipt(plan: dict, plan_sha: str, engine_id: str, year: str,
                   first: str, last: str, ordinal: int, normalized: bytes,
                   raw: bytes, receipt: Mapping[str, Any]) -> dict:
    if not isinstance(receipt, dict) or set(receipt) != RECEIPT_FIELDS:
        raise ValueError("native receipt has missing or extra fields")
    expected = _expected(plan, plan_sha, engine_id, year, first, last,
                         ordinal, normalized, raw)
    if receipt != expected or any(type(receipt[key]) is not type(expected[key]) for key in expected):
        raise ValueError("native receipt contradicts raw source, binary, plan or chunk coordinates")
    return expected
