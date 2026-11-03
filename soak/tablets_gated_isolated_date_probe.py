#!/usr/bin/env python3
"""Combine a complete unseeded TABLETS gate transcript with two isolated 3x5 date sources.

This is only an integration diagnostic. The injected gate algorithms, date
mathematics and external caches require separate verification. No certification.
"""
from __future__ import annotations
import hashlib
import json
from time import monotonic
from audit_independent_tablets_brackets import audit_tablets
from tablets_date_module_provenance import DateModule, verify_date_module_identities
from tablets_five_field_contract import (
    FOUNDATION, TARGETS, MAX_QUESTIONS, MAX_SEGMENT, verify_bracket_receipt,
)
from tablets_isolated_date_runtime import compare_isolated_dates

STATUS = "PASS_GATED_ISOLATED_DATE_DIAGNOSTIC_NOT_CERTIFIED"

class ProbeError(ValueError):
    pass

def run_probe(independent: DateModule, pinned: DateModule, independent_gap, pinned_gap,
              *, max_questions: int = MAX_QUESTIONS, segment_limit: int = 4096,
              gate_seconds: int = 480, date_seconds: int = 90) -> dict:
    """Walk from FOUNDATION without a checkpoint seed, then compare Git-backed dates."""
    if not callable(independent_gap) or not callable(pinned_gap) or independent_gap is pinned_gap:
        raise ProbeError("E_PROBE_TWO_GAP_FUNCTIONS")
    if (type(max_questions) is not int or not 1 <= max_questions <= MAX_QUESTIONS
            or type(segment_limit) is not int or not 1 <= segment_limit <= MAX_SEGMENT
            or type(gate_seconds) is not int or not 1 <= gate_seconds <= 600
            or type(date_seconds) is not int or not 1 <= date_seconds <= 120):
        raise ProbeError("E_PROBE_BUDGET")
    before = verify_date_module_identities(independent, pinned)
    receipt = audit_tablets(
        independent_gap, pinned_gap, origin=FOUNDATION, targets=TARGETS,
        max_questions=max_questions, segment_limit=segment_limit,
        deadline=monotonic() + gate_seconds)
    verify_bracket_receipt(receipt)
    dates = compare_isolated_dates(
        independent, pinned, origin=FOUNDATION, targets=TARGETS,
        deadline=monotonic() + date_seconds)
    after = verify_date_module_identities(independent, pinned)
    if before != after:
        raise ProbeError("E_PROBE_SOURCE_CHANGED_DURING_RUN")
    if (dates["targets"] != receipt["targets"] or dates["cases"] != 3
            or dates["fields_per_case"] != 5 or dates["source_provenance"] != after):
        raise ProbeError("E_PROBE_DATE_RECEIPT_MISMATCH")
    canonical = {
        "trace": receipt["trace_sha256"],
        "terminal_segment": receipt["terminal_segment_sha256"],
        "questions": receipt["questions"], "targets": dates["targets"],
        "rows": dates["rows"],
        "independent_commit": after["independent"]["commit_sha"],
        "pinned_commit": after["pinned"]["commit_sha"],
        "independent_module_sha256": after["independent"]["module_sha256"],
        "pinned_module_sha256": after["pinned"]["module_sha256"],
    }
    digest = hashlib.sha256(
        (json.dumps(canonical, sort_keys=True, separators=(",", ":")) + "\n").encode()
    ).hexdigest()
    return {
        "status": STATUS, "project_id": "PC-BRANCH-KOTLIN-CYMRAEG",
        "targets": list(TARGETS), "cases": 3, "fields_per_case": 5,
        "gate_questions": receipt["questions"], "segment_count": receipt["segment_count"],
        "gate_trace_sha256": receipt["trace_sha256"],
        "terminal_segment_sha256": receipt["terminal_segment_sha256"],
        "cross_layer_receipt_sha256": digest,
        "source_provenance": after, "date_process_pids": dates["process_pids"],
        "date_stdout_sha256": dates["stdout_sha256"], "rows": dates["rows"],
        "checkpoint_seed_used": False, "production_gate_limit_unchanged": 8192,
        "gap_functions_executed_here": True,
        "independent_gap_mathematics_verified_here": False,
        "independent_date_mathematics_verified_here": False,
        "source_cache_independence_verified_here": False,
        "algorithmic_independence_certified": False,
        "full_date_certified": False, "certifiable": False,
    }
