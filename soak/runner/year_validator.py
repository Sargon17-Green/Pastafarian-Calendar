#!/usr/bin/env python3
"""Validate and compare complete-year Pastafarian transcripts; no converter execution.

This is a strict streaming gate, not a date oracle. It deliberately never
infers missing fields or silently repairs raw engine output.
"""
from __future__ import annotations
import dataclasses
import hashlib
import json
import pathlib
import re
from typing import Iterator, TextIO

SIGNED = re.compile(r"^(?:0|-?[1-9][0-9]*)$")
MANDATORY = frozenset({
    "calculation_day", "target_day", "year", "cutlet_index",
    "day_in_cutlet", "month_index", "day_in_month",
    "cutlet_name_raw", "month_name_raw", "source_raw_sha256",
})


@dataclasses.dataclass(frozen=True)
class YearCase:
    calculation_day: str
    year: str
    first_target_day: str
    last_target_day: str
    boundary_evidence_sha256: str

    def validate(self) -> None:
        for value in (self.calculation_day, self.year, self.first_target_day,
                      self.last_target_day):
            if not isinstance(value, str) or not SIGNED.fullmatch(value):
                raise ValueError(f"invalid signed decimal coordinate: {value!r}")
        if int(self.first_target_day) > int(self.last_target_day):
            raise ValueError("year has inverted bounds")
        if not re.fullmatch(r"[0-9a-f]{64}", self.boundary_evidence_sha256):
            raise ValueError("year boundaries have no pinned SHA-256 evidence")


@dataclasses.dataclass(frozen=True)
class CheckedDay:
    t: str
    normalized: tuple[str, int, int, int, int]
    raw_names: tuple[str, str]
    source_raw_sha256: str


class TranscriptError(ValueError):
    def __init__(self, reason: str, row: int):
        super().__init__(f"row {row}: {reason}")
        self.reason = reason
        self.row = row


def parse_line(raw_line: str, row_number: int, case: YearCase, expected_t: int) -> CheckedDay:
    try:
        row = json.loads(raw_line)
    except (ValueError, TypeError) as exc:
        raise TranscriptError(f"invalid JSON ({type(exc).__name__})", row_number) from exc
    if not isinstance(row, dict) or not MANDATORY.issubset(row):
        raise TranscriptError("missing mandatory normalized/raw fields", row_number)
    for key in ("calculation_day", "target_day", "year"):
        if not isinstance(row[key], str) or not SIGNED.fullmatch(row[key]):
            raise TranscriptError(f"invalid decimal string {key}", row_number)
    if row["calculation_day"] != case.calculation_day:
        raise TranscriptError("calculation day changed mid-year", row_number)
    if row["year"] != case.year:
        raise TranscriptError("year identity does not match boundary fixture", row_number)
    if int(row["target_day"]) != expected_t:
        raise TranscriptError(f"missing, duplicated or out-of-order day; expected {expected_t}", row_number)
    for key in ("cutlet_index", "day_in_cutlet", "month_index", "day_in_month"):
        if type(row[key]) is not int or row[key] < 0:
            raise TranscriptError(f"invalid numeric field {key}", row_number)
    if row["day_in_cutlet"] == 0 or row["day_in_month"] == 0:
        raise TranscriptError("one-based day number is zero", row_number)
    for key in ("cutlet_name_raw", "month_name_raw"):
        if not isinstance(row[key], str) or not row[key]:
            raise TranscriptError(f"raw native name missing: {key}", row_number)
    if not isinstance(row["source_raw_sha256"], str) or not re.fullmatch(r"[0-9a-f]{64}", row["source_raw_sha256"]):
        raise TranscriptError("source output evidence digest invalid", row_number)
    return CheckedDay(
        t=row["target_day"],
        normalized=(row["year"], row["cutlet_index"], row["day_in_cutlet"], row["month_index"], row["day_in_month"]),
        raw_names=(row["cutlet_name_raw"], row["month_name_raw"]),
        source_raw_sha256=row["source_raw_sha256"],
    )


def iter_checked(stream: TextIO, case: YearCase) -> Iterator[CheckedDay]:
    case.validate()
    count = 0
    first = int(case.first_target_day)
    last = int(case.last_target_day)
    for count, line in enumerate(stream, start=1):
        if count > last - first + 1:
            raise TranscriptError("more days than the pinned year interval", count)
        yield parse_line(line, count, case, first + count - 1)
    if count != last - first + 1:
        raise TranscriptError(f"incomplete year: {count} of {last - first + 1} days", count + 1)


def compare_years(path_a: pathlib.Path, path_b: pathlib.Path,
                  case: YearCase, engine_a: str, engine_b: str) -> dict:
    """Return a durable verdict; never claim PASS on truncated or malformed files."""
    if not engine_a or not engine_b or engine_a == engine_b:
        raise ValueError("comparison requires two distinct engine identities")
    case.validate()
    sha = hashlib.sha256()
    compared = 0
    try:
        with pathlib.Path(path_a).open("r", encoding="utf-8") as fa, pathlib.Path(path_b).open("r", encoding="utf-8") as fb:
            ita, itb = iter_checked(fa, case), iter_checked(fb, case)
            for da, db in zip(ita, itb):
                compared += 1
                if da.t != db.t or da.normalized != db.normalized:
                    return {
                        "verdict": "MISMATCH", "fully_matched_days": compared - 1,
                        "first_mismatch_target_day": da.t, "engine_a": engine_a,
                        "engine_b": engine_b, "native_a": dataclasses.asdict(da),
                        "native_b": dataclasses.asdict(db),
                        "halt_new_work": True,
                    }
                sha.update((da.t + ":" + json.dumps(da.normalized, ensure_ascii=False, separators=(",", ":")) + "\n").encode("utf-8"))
        # Both complete iterators must exhaust. zip(,) can defer a last
        # generator exhaustion exception until explicitly verified. Validate
        # separately for all-edge cases (especially exact-length streams).
        with pathlib.Path(path_a).open("r", encoding="utf-8") as fa:
            sum(1 for _ in iter_checked(fa, case))
        with pathlib.Path(path_b).open("r", encoding="utf-8") as fb:
            sum(1 for _ in iter_checked(fb, case))
    except (OSError, UnicodeError, TranscriptError, ValueError) as exc:
        return {
            "verdict": "INVALID_EVIDENCE", "fully_matched_days": 0,
            "last_rows_examined": compared, "error": str(exc),
            "engine_a": engine_a, "engine_b": engine_b, "halt_new_work": True,
        }
    return {
        "verdict": "PASS", "fully_matched_days": compared,
        "year": case.year, "calculation_day": case.calculation_day,
        "canonical_daystream_sha256": sha.hexdigest(),
        "engine_a": engine_a, "engine_b": engine_b,
        "halt_new_work": False,
    }


def robust_slow_threshold(durations: list[float], *, floor_seconds: float = 30.0) -> float:
    """Dynamic threshold computed only from completed comparable jobs.

    This threshold is for route *classification*, NEVER for process killing.
    """
    import statistics
    if len(durations) < 5:
        return max(300.0, floor_seconds)
    sample = durations[-40:]
    if any(not isinstance(x, (int, float)) or not (0 <= x < float("inf")) for x in sample):
        raise ValueError("invalid historical durations")
    median = statistics.median(sample)
    mad = statistics.median(abs(x - median) for x in sample)
    return max(floor_seconds, 3.0 * median + 6.0 * mad)
