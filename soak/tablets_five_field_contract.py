#!/usr/bin/env python3
"""Fail-closed TABLETS five-field research acceptance boundary.

This module never constructs an independent full-date oracle. Callers must
supply one; a verified gate bracket alone is insufficient to assert dates.
Receipts remain DIAGNOSTIC_NOT_CERTIFIED even when all values agree.
No production navigator limits, caching or --certify behavior are changed.
"""
from __future__ import annotations

from collections.abc import Callable, Mapping
from dataclasses import dataclass
from time import monotonic

FOUNDATION = -15055671
TABLETS = -278522
TARGETS = (TABLETS - 1, TABLETS, TABLETS + 1)
FIELDS = ("year_number", "cutlet_index", "day_in_cutlet", "month_index", "day_in_month")
PINNED_SHA = "7cb12bf355461e5a179e0deadb7365689288bf29"
MAX_QUESTIONS = 32768
MAX_SEGMENT = 8192
MAX_GAP = 963
STATUS = "MATCH_TABLETS_FIVE_FIELDS_PROVENANCE_PENDING_NOT_CERTIFIED"


class ContractError(ValueError):
    pass


@dataclass(frozen=True)
class DateImplementation:
    name: str
    commit_sha: str
    module_sha256: str
    algorithm: str


def _sha(value: object, length: int = 64) -> bool:
    return (type(value) is str and len(value) == length
            and all(c in "0123456789abcdef" for c in value))


def _date_provenance(record: DateImplementation, *, label: str) -> None:
    if (not isinstance(record, DateImplementation)
            or type(record.name) is not str or not record.name.strip()
            or not _sha(record.commit_sha, 40) or not _sha(record.module_sha256)
            or type(record.algorithm) is not str or not record.algorithm.strip()):
        raise ContractError(f"E_{label}_PROVENANCE")


def verify_bracket_receipt(receipt: Mapping, *, targets: tuple[int, ...] = TARGETS,
                           origin: int = FOUNDATION) -> None:
    """Structural gate receipt preflight; cannot cryptographically recheck its trace.

    For real usage the receipt must be separately replayed with unseeded
    independent gaps, source pin verification, and preserved logs/artifact.
    """
    if (type(origin) is not int or type(targets) is not tuple
            or len(targets) != 3 or any(type(t) is not int for t in targets)
            or not (origin < targets[0] < targets[1] < targets[2])):
        raise ContractError("E_TABLETS_TARGETS")
    if not isinstance(receipt, Mapping):
        raise ContractError("E_TABLETS_BRACKET_RECEIPT")
    if (receipt.get("status") != "PASS_TABLETS_INDEPENDENT_UNSEEDED_BRACKETS_NOT_CERTIFIED"
            or receipt.get("origin") != origin
            or receipt.get("targets") != list(targets)
            or receipt.get("checkpoint_seed_used") is not False
            or receipt.get("tablets_bracket_verified") is not True
            or receipt.get("certifiable") is not False
            or receipt.get("full_date_verified") is not False
            or receipt.get("tablets_date_components_verified") is not False
            or receipt.get("production_gate_limit_unchanged") != MAX_SEGMENT):
        raise ContractError("E_TABLETS_UNSEEDED_PROOF_REQUIRED")
    count, segment_limit = receipt.get("questions"), receipt.get("segment_limit")
    if (type(count) is not int or type(segment_limit) is not int
            or not (targets[-1] - origin + MAX_GAP - 1) // MAX_GAP <= count <= MAX_QUESTIONS
            or not 1 <= segment_limit <= MAX_SEGMENT):
        raise ContractError("E_TABLETS_PROOF_BUDGET")
    brackets, segments = receipt.get("brackets"), receipt.get("segments")
    if (not isinstance(brackets, list) or len(brackets) != 3
            or not isinstance(segments, list) or not segments):
        raise ContractError("E_TABLETS_BRACKET_SHAPE")
    for target, bracket in zip(targets, brackets):
        if not isinstance(bracket, Mapping):
            raise ContractError("E_TABLETS_BRACKET_SHAPE")
        low, high, index = (bracket.get(x) for x in
                            ("bracket_low", "bracket_high", "gate_index"))
        if (bracket.get("target_day") != target
                or any(type(x) is not int for x in (low, high, index))
                or not origin <= low <= target <= high
                or not 1 <= index <= count
                or bracket.get("from_foundation") != index
                or high - low > MAX_GAP):
            raise ContractError("E_TABLETS_BRACKET_CONTENT")
    previous_index = 0
    for part in segments:
        if (not isinstance(part, Mapping)
                or type(part.get("end_index")) is not int
                or type(part.get("end_day")) is not int
                or not _sha(part.get("segment_sha256"))
                or not previous_index < part["end_index"] <= count
                or part["end_index"] - previous_index > segment_limit):
            raise ContractError("E_TABLETS_SEGMENT_CHAIN")
        previous_index = part["end_index"]
    if (previous_index != count
            or segments[-1]["end_day"] != brackets[-1]["bracket_high"]
            or receipt.get("segment_count") != len(segments)
            or receipt.get("terminal_segment_sha256") != segments[-1]["segment_sha256"]
            or not _sha(receipt.get("trace_sha256"))):
        raise ContractError("E_TABLETS_SEGMENT_TERMINAL")


def _fields(value: object, target: int, label: str) -> tuple[int, ...]:
    if (type(value) not in (tuple, list) or len(value) != len(FIELDS)
            or any(type(x) is not int for x in value)):
        raise ContractError(f"E_{label}_DATE_FIELDS_AT_{target}")
    year, cutlet, day_in_cutlet, month, day_in_month = value
    if (year < 1 or not 1 <= cutlet <= 17 or day_in_cutlet < 1
            or not 1 <= month <= 47 or day_in_month < 1):
        raise ContractError(f"E_{label}_DATE_RANGE_AT_{target}")
    return tuple(value)


def compare_tablets_five_fields(
    receipt: Mapping,
    independent_date: Callable[[int, int], tuple[int, ...]] | None,
    pinned_date: Callable[[int, int], tuple[int, ...]] | None,
    independent_source: DateImplementation,
    pinned_source: DateImplementation,
    *,
    targets: tuple[int, ...] = TARGETS,
    origin: int = FOUNDATION,
    deadline: float | None = None,
) -> dict:
    """Compare 3x5 fields, after strict preflight; never auto-certify provenance."""
    verify_bracket_receipt(receipt, targets=targets, origin=origin)
    _date_provenance(independent_source, label="INDEPENDENT")
    _date_provenance(pinned_source, label="PINNED")
    if (pinned_source.commit_sha != PINNED_SHA
            or independent_source.commit_sha == pinned_source.commit_sha
            or independent_source.module_sha256 == pinned_source.module_sha256):
        raise ContractError("E_TABLETS_DATE_SOURCE_SEPARATION")
    if (not callable(independent_date) or not callable(pinned_date)
            or independent_date is pinned_date):
        raise ContractError("E_TABLETS_INDEPENDENT_DATE_ORACLE_REQUIRED")
    if deadline is not None and (type(deadline) not in (int, float)
                                 or deadline <= monotonic()):
        raise ContractError("E_TABLETS_DATE_DEADLINE")
    compared = []
    for target in targets:
        if deadline is not None and monotonic() >= deadline:
            raise ContractError("E_TABLETS_DATE_DEADLINE")
        a = _fields(independent_date(origin, target), target, "INDEPENDENT")
        if deadline is not None and monotonic() >= deadline:
            raise ContractError("E_TABLETS_DATE_DEADLINE")
        b = _fields(pinned_date(origin, target), target, "PINNED")
        if a != b:
            mismatch = [name for name, left, right in zip(FIELDS, a, b)
                        if left != right]
            raise ContractError(f"E_TABLETS_DATE_MISMATCH_AT_{target}:{','.join(mismatch)}")
        compared.append({"target_day": target, "five_fields": dict(zip(FIELDS, a))})
    return {
        "status": STATUS, "targets": list(targets), "cases": len(compared),
        "fields_per_case": len(FIELDS), "rows": compared,
        "source_commit_sha": pinned_source.commit_sha,
        "independent_commit_sha": independent_source.commit_sha,
        "gate_questions": receipt["questions"],
        "checkpoint_seed_used": False,
        "production_gate_limit_unchanged": MAX_SEGMENT,
        "full_date_certified": False, "certifiable": False,
        "algorithmic_independence_certified": False,
        "receipt_replay_verified_here": False,
        "source_cache_independence_verified_here": False,
        "note": "Validates supplied outputs only; actual source/algorithm provenance,"
                " pin and replay must be reviewed separately.",
    }



def compare_tablets_five_fields_replayed(
    receipt: Mapping,
    independent_date: Callable[[int, int], tuple[int, ...]],
    pinned_date: Callable[[int, int], tuple[int, ...]],
    independent_source: DateImplementation,
    pinned_source: DateImplementation,
    *,
    independent_gap: Callable[[int], int],
    pinned_gap: Callable[[int], int],
    targets: tuple[int, ...] = TARGETS,
    origin: int = FOUNDATION,
    max_questions: int = MAX_QUESTIONS,
    segment_limit: int = 4096,
    deadline: float,
) -> dict:
    """Fail closed unless the entire unseeded gate transcript is regenerated.

    The recomputation begins at origin, uses global positive indices, compares
    every gap, and rebuilds segment and trace digests. Caller-supplied receipt
    hashes are never treated as proof. Full-date algorithmic independence and
    pinned module provenance are still separate external review gates.
    """
    verify_bracket_receipt(receipt, targets=targets, origin=origin)
    if (not callable(independent_gap) or not callable(pinned_gap)
            or independent_gap is pinned_gap):
        raise ContractError("E_TABLETS_REPLAY_TWO_GAP_ORACLES")
    now = monotonic()
    if (type(deadline) not in (int, float) or not now < deadline <= now + 600):
        raise ContractError("E_TABLETS_REPLAY_DEADLINE")
    if (type(max_questions) is not int or not 1 <= max_questions <= MAX_QUESTIONS
            or type(segment_limit) is not int or not 1 <= segment_limit <= MAX_SEGMENT):
        raise ContractError("E_TABLETS_REPLAY_BUDGET")
    # Reject a changed replay configuration; it changes the hash-chain layout.
    if (receipt.get("max_questions") != max_questions
            or receipt.get("segment_limit") != segment_limit):
        raise ContractError("E_TABLETS_REPLAY_CONFIGURATION")
    from audit_independent_tablets_brackets import audit_tablets, TabletsAuditError
    try:
        actual = audit_tablets(
            independent_gap, pinned_gap, origin=origin, targets=targets,
            max_questions=max_questions, segment_limit=segment_limit,
            deadline=deadline,
        )
    except TabletsAuditError as exc:
        raise ContractError(f"E_TABLETS_REPLAY_FAILED:{exc}") from exc
    for key in (
        "status", "origin", "targets", "brackets", "questions",
        "max_questions", "segment_limit", "segments", "segment_count",
        "trace_sha256", "terminal_segment_sha256", "checkpoint_seed_used",
        "production_gate_limit_unchanged", "full_date_verified",
        "certifiable", "tablets_bracket_verified",
        "tablets_date_components_verified",
    ):
        if receipt.get(key) != actual[key]:
            raise ContractError(f"E_TABLETS_REPLAY_RECEIPT_MISMATCH:{key}")
    result = compare_tablets_five_fields(
        receipt, independent_date, pinned_date,
        independent_source, pinned_source,
        targets=targets, origin=origin, deadline=deadline,
    )
    result["receipt_replay_verified_here"] = True
    result["replayed_gate_questions"] = actual["questions"]
    result["replay_trace_sha256"] = actual["trace_sha256"]
    # This replay does NOT prove independent full-date mathematics or that
    # pinned source objects were loaded without an independent cache.
    result["algorithmic_independence_certified"] = False
    result["source_cache_independence_verified_here"] = False
    result["full_date_certified"] = False
    return result
