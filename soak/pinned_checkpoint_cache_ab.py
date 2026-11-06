#!/usr/bin/env python3
"""Bounded pinned-reference static-checkpoint A/B experiment, diagnostic only.

Six fresh Python -I workers: FOUNDATION +/- 1 and zero, static table on/off.
This is not a TABLETS oracle, not algorithmic independence, not --certify.
The pinned Git worktree is read-only; disabling checkpoints is process-local.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from time import monotonic

PINNED_SHA = "7cb12bf355461e5a179e0deadb7365689288bf29"
FOUNDATION = -15055671
TARGETS = (FOUNDATION - 1, FOUNDATION, FOUNDATION + 1)
BLOBS = {
    "src/pastafari_calendar/final_integration.py": "c927c324f039a94bc36b2ea8827acd58511b6f8c",
    "src/pastafari_calendar/calendar.py": "3ab6fdb56f107cb08b27bb60f3eca27b5164435a",
    "src/pastafari_calendar/acceleration_scars.py": "1f25dff702bde739ab027556457377e01962ee49",
}
MODES = ("table", "empty")
PASS = "PASS_PINNED_FOUNDATION_CACHE_AB_DIAGNOSTIC_NOT_CERTIFIED"


class AuditError(ValueError):
    pass


def git(root: Path, *args: str) -> str:
    return subprocess.check_output(
        ["git", "-C", str(root), *args], text=True, timeout=15
    ).strip()


def provenance(branch: Path, source: Path) -> dict:
    branch = branch.resolve(strict=True)
    source = source.resolve(strict=True)
    root = source.parent
    if (source.name != "src" or branch == root
            or branch.is_relative_to(root) or root.is_relative_to(branch)):
        raise AuditError("E_DISTINCT_ROOTS")
    current = git(branch, "rev-parse", "HEAD")
    if (current != os.environ.get("GITHUB_SHA")
            or os.environ.get("GITHUB_REF_NAME") != "Kotlin+Cymraeg"):
        raise AuditError("E_BRANCH_HEAD_OR_NAME")
    if git(root, "rev-parse", "HEAD") != PINNED_SHA:
        raise AuditError("E_PINNED_HEAD")
    for relative, expected in BLOBS.items():
        file = root / relative
        if file.is_symlink() or not file.is_file():
            raise AuditError("E_PINNED_FILE_" + relative)
        if git(root, "rev-parse", "HEAD:" + relative) != expected:
            raise AuditError("E_PINNED_GIT_BLOB_" + relative)
        if git(root, "hash-object", "--no-filters", str(file)) != expected:
            raise AuditError("E_PINNED_WORKTREE_" + relative)
    return {"branch_commit": current, "pinned_commit": PINNED_SHA,
            "pinned_git_blobs": BLOBS.copy(), "distinct_git_roots": True}


def checked_fields(fields) -> list[int]:
    if (type(fields) is not list or len(fields) != 5
            or any(type(v) is not int or v < 1 for v in fields)
            or not 1 <= fields[1] <= 17
            or not 1 <= fields[3] <= 47
            or not 1 <= fields[4] <= 123):
        raise AuditError("E_FIVE_TYPED_FIELDS")
    return fields


def validate_worker(doc, day: int, mode: str) -> dict:
    if (type(doc) is not dict or doc.get("day") != day
            or doc.get("mode") != mode
            or doc.get("pinned_commit") != PINNED_SHA
            or doc.get("isolated") is not True
            or doc.get("cache_reset") is not True
            or doc.get("static_count_before") != 75
            or doc.get("static_count_active") != (75 if mode == "table" else 0)
            or type(doc.get("reanchors")) is not list
            or any(type(x) is not list or len(x) != 2
                   or any(type(z) is not int for z in x)
                   for x in doc["reanchors"])):
        raise AuditError("E_WORKER_PROVENANCE_OR_SHAPE")
    checked_fields(doc.get("five_fields"))
    if mode == "empty" and doc["reanchors"]:
        raise AuditError("E_REANCHOR_WITH_EMPTY_TABLE")
    return doc


def compare_pair(a: dict, b: dict) -> dict:
    if (a["day"] != b["day"] or a["mode"] != "table"
            or b["mode"] != "empty"):
        raise AuditError("E_PAIR_IDENTITY")
    left = checked_fields(a["five_fields"])
    right = checked_fields(b["five_fields"])
    matched = [x == y for x, y in zip(left, right)]
    if not all(matched):
        raise AuditError("E_CHECKPOINT_AB_DATE_MISMATCH_" + str(a["day"]))
    return {"day": a["day"], "table_five": left, "empty_five": right,
            "typed_field_comparisons": len(matched),
            "matched": True, "table_reanchors": a["reanchors"],
            "empty_reanchors": b["reanchors"]}


def worker(source: Path, day: int, mode: str) -> None:
    if (not sys.flags.isolated or day not in TARGETS or mode not in MODES
            or source.name != "src" or git(source.parent, "rev-parse", "HEAD") != PINNED_SHA):
        raise AuditError("E_WORKER_ISOLATION_SOURCE_OR_INPUT")
    for relative, sha in BLOBS.items():
        if git(source.parent, "rev-parse", "HEAD:" + relative) != sha:
            raise AuditError("E_WORKER_GIT_BLOB")
    sys.path.insert(0, str(source))
    calendar = importlib.import_module("pastafari_calendar.calendar")
    integration = importlib.import_module("pastafari_calendar.final_integration")
    names = importlib.import_module("pastafari_calendar.source_language_catalog")
    scars = importlib.import_module("pastafari_calendar.acceleration_scars")
    for module in (calendar, integration, names, scars):
        if not Path(module.__file__).resolve(strict=True).is_relative_to(source):
            raise AuditError("E_WORKER_IMPORT_ESCAPE")
    if (integration.FOUNDATION_DAY_INTEGRATED != FOUNDATION
            or hashlib.sha1(b"blob " + str(Path(integration.__file__).stat().st_size).encode()
                               + b"\0" + Path(integration.__file__).read_bytes()).hexdigest()
            != BLOBS["src/pastafari_calendar/final_integration.py"]):
        raise AuditError("E_WORKER_MODULE_DRIFT")
    old_table = integration.GATE_CHECKPOINTS_INTEGRATED
    if (type(old_table) is not tuple or len(old_table) != 75
            or (0, FOUNDATION) not in old_table):
        raise AuditError("E_PINNED_CHECKPOINT_STRUCTURE")
    cat = names.SOURCE_LANGUAGE_CATALOG
    cutlets = {v.text: v.canonical_index for v in cat.cutlets}
    months = {v.text: v.canonical_index for v in cat.months}
    if len(cutlets) != 17 or len(months) != 47:
        raise AuditError("E_REFERENCE_CATALOG")
    reanchors = []
    old_method = integration.IntegratedGateCache._reanchor_for_cover

    def traced(self, low_day, high_day):
        before = (self.min_known, self.max_known)
        outcome = old_method(self, low_day, high_day)
        if (before == (0, 0) and self.min_known == self.max_known
                and self.min_known != 0):
            reanchors.append([self.min_known, self.gates[self.min_known]])
        return outcome

    integration.IntegratedGateCache._reanchor_for_cover = traced
    if mode == "empty":
        integration.GATE_CHECKPOINTS_INTEGRATED = ()
    active = len(integration.GATE_CHECKPOINTS_INTEGRATED)
    scars.reset_acceleration_scars_for_tests()
    try:
        with scars.acceleration_mode(True):
            result = calendar.calendar_date_spaghetti(FOUNDATION, day)
    finally:
        integration.IntegratedGateCache._reanchor_for_cover = old_method
        integration.GATE_CHECKPOINTS_INTEGRATED = old_table
    if not isinstance(result, integration.SpaghettiDateResult):
        raise AuditError("E_REFERENCE_RESULT")
    fields = checked_fields([result.year_number, cutlets[result.cutlet_name],
                             result.day_in_cutlet, months[result.month_name],
                             result.day_in_month])
    print(json.dumps({"day": day, "mode": mode, "five_fields": fields,
                      "pinned_commit": PINNED_SHA, "isolated": True,
                      "cache_reset": True, "static_count_before": len(old_table),
                      "static_count_active": active, "reanchors": reanchors},
                     sort_keys=True))


def spawn(script: Path, source: Path, day: int, mode: str, seconds: int) -> dict:
    if (day not in TARGETS or mode not in MODES
            or type(seconds) is not int or not 1 <= seconds <= 90):
        raise AuditError("E_SPAWN_BOUNDS")
    with tempfile.TemporaryDirectory(prefix="pinned-cache-ab-") as tmp:
        env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"),
               "HOME": tmp, "PYTHONDONTWRITEBYTECODE": "1",
               "PYTHONNOUSERSITE": "1"}
        p = subprocess.run(
            [sys.executable, "-I", str(script.resolve(strict=True)), "--worker",
             "--pinned-src", str(source.resolve(strict=True)),
             "--day", str(day), "--mode", mode],
            cwd=tmp, env=env, capture_output=True, text=True, timeout=seconds)
    if p.returncode or len(p.stdout.splitlines()) != 1:
        raise AuditError("E_WORKER_EXEC_" + str(day) + "_" + mode
                         + "_" + p.stderr[-500:])
    try:
        doc = json.loads(p.stdout)
    except json.JSONDecodeError as exc:
        raise AuditError("E_WORKER_JSON") from exc
    return validate_worker(doc, day, mode)


def execute(args) -> dict:
    if (not 1 <= args.worker_timeout <= 90
            or not 1 <= args.total_timeout <= 420):
        raise AuditError("E_DEADLINE_BOUNDS")
    branch = Path(__file__).resolve().parent.parent
    src = args.pinned_src.resolve(strict=True)
    origin = provenance(branch, src)
    start = monotonic()
    rows = []
    for day in TARGETS:
        items = {}
        for mode in MODES:
            remaining = int(args.total_timeout - (monotonic() - start))
            if remaining < 1:
                raise AuditError("E_TOTAL_DEADLINE")
            items[mode] = spawn(Path(__file__), src, day, mode,
                                min(args.worker_timeout, remaining))
        rows.append(compare_pair(items["table"], items["empty"]))
    return {**origin, "status": PASS, "cases": 3,
            "cold_isolated_workers": 6, "typed_field_comparisons": 15,
            "pairs": rows, "static_table_disabling": "process_local_only",
            "independent_tablets_date_oracle": False,
            "full_date_certified": False, "certifiable": False,
            "production_gate_limit_unchanged": 8192,
            "elapsed_seconds": round(monotonic() - start, 3)}


def main(argv=None):
    p = argparse.ArgumentParser()
    p.add_argument("--worker", action="store_true")
    p.add_argument("--pinned-src", type=Path, required=True)
    p.add_argument("--day", type=int)
    p.add_argument("--mode", choices=MODES)
    p.add_argument("--worker-timeout", type=int, default=90)
    p.add_argument("--total-timeout", type=int, default=420)
    p.add_argument("--evidence", type=Path)
    args = p.parse_args(argv)
    if args.worker:
        worker(args.pinned_src.resolve(strict=True), args.day, args.mode)
        return 0
    if args.evidence is None:
        p.error("--evidence is required")
    try:
        report = execute(args)
    except Exception as exc:
        report = {"status": "FAIL_PINNED_CHECKPOINT_CACHE_AB",
                  "error_type": type(exc).__name__, "error": str(exc)[:1500],
                  "full_date_certified": False, "certifiable": False}
    args.evidence.parent.mkdir(parents=True, exist_ok=True)
    args.evidence.write_text(json.dumps(report, sort_keys=True, indent=2) + "\n",
                             encoding="utf-8")
    print(json.dumps(report, sort_keys=True))
    return 0 if report["status"] == PASS else 2


if __name__ == "__main__":
    raise SystemExit(main())
