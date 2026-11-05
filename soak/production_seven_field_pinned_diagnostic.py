#!/usr/bin/env python3
"""Kotlin production seven-column vs pinned reference near FOUNDATION.

Three separate production JVMs, three isolated pinned Python processes.
The first two production fields are checked as inputs; the remaining five
are compared exactly. This is NOT an unseeded TABLETS or --certify gate.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from time import monotonic

FOUNDATION = -15055671
TARGETS = (FOUNDATION - 1, FOUNDATION, FOUNDATION + 1)
PINNED_SHA = "7cb12bf355461e5a179e0deadb7365689288bf29"
PINNED_MODULE_SHA256 = "a9e48e61124221cce39805a825c746a734a5f8f660406a898af38351e2cce6a1"
PASS = "PASS_BOUND_PRODUCTION_SEVEN_FIELDS_VS_PINNED_NOT_CERTIFIED"
DECIMAL = re.compile(r"(?:0|-?[1-9][0-9]*)", re.ASCII)


class SevenFieldError(ValueError):
    pass


def git_head(root: Path) -> str:
    return subprocess.check_output(
        ["git", "-C", str(root), "rev-parse", "HEAD"], text=True, timeout=12
    ).strip()


def source_guard(branch: Path, pinned_src: Path) -> tuple[str, str]:
    branch = branch.resolve(strict=True)
    pinned_src = pinned_src.resolve(strict=True)
    pinned_root = pinned_src.parent
    if (branch == pinned_root or branch.is_relative_to(pinned_root)
            or pinned_root.is_relative_to(branch)):
        raise SevenFieldError("E_SHARED_ROOT")
    sha = git_head(branch)
    if (sha != os.getenv("GITHUB_SHA")
            or os.getenv("GITHUB_REF_NAME") != "Kotlin+Cymraeg"):
        raise SevenFieldError("E_BRANCH_REVISION")
    if git_head(pinned_root) != PINNED_SHA:
        raise SevenFieldError("E_PINNED_REVISION")
    module = pinned_src / "pastafari_calendar" / "final_integration.py"
    if (not module.is_file()
            or hashlib.sha256(module.read_bytes()).hexdigest() != PINNED_MODULE_SHA256):
        raise SevenFieldError("E_PINNED_MODULE_HASH")
    return sha, hashlib.sha256(module.read_bytes()).hexdigest()


def parse_production(stdout: str, calculation: int, target: int) -> list[int]:
    lines = stdout.splitlines()
    if len(lines) != 1:
        raise SevenFieldError("E_PRODUCTION_ROW_COUNT")
    cells = lines[0].split("\t")
    if len(cells) != 7 or any(not DECIMAL.fullmatch(s) for s in cells):
        raise SevenFieldError("E_PRODUCTION_SEVEN_COLUMN_SHAPE")
    values = [int(s) for s in cells]
    if values[:2] != [calculation, target]:
        raise SevenFieldError("E_PRODUCTION_INPUT_ECHO")
    if not (values[2] >= 1 and 1 <= values[3] <= 17 and values[4] >= 1
            and 1 <= values[5] <= 47 and 1 <= values[6] <= 123):
        raise SevenFieldError("E_PRODUCTION_FIELD_BOUNDS")
    return values


def validate_reference(doc: dict, target: int) -> list[int]:
    if (type(doc) is not dict or doc.get("day") != target
            or doc.get("reference_commit") != PINNED_SHA
            or doc.get("module_sha256") != PINNED_MODULE_SHA256
            or doc.get("isolated") is not True
            or doc.get("cache_reset") is not True):
        raise SevenFieldError("E_REFERENCE_PROVENANCE")
    fields = doc.get("five_fields")
    if (type(fields) is not list or len(fields) != 5
            or any(type(x) is not int or x <= 0 for x in fields)
            or not 1 <= fields[1] <= 17 or not 1 <= fields[3] <= 47):
        raise SevenFieldError("E_REFERENCE_FIELDS")
    return fields


def reference_worker(root: Path, target: int):
    if not sys.flags.isolated or target not in TARGETS:
        raise SevenFieldError("E_NOT_ISOLATED")
    root = root.resolve(strict=True)
    if root.name != "src" or git_head(root.parent) != PINNED_SHA:
        raise SevenFieldError("E_WORKER_SOURCE")
    sys.path.insert(0, str(root))
    calendar = importlib.import_module("pastafari_calendar.calendar")
    integ = importlib.import_module("pastafari_calendar.final_integration")
    names = importlib.import_module("pastafari_calendar.source_language_catalog")
    scars = importlib.import_module("pastafari_calendar.acceleration_scars")
    for module in (calendar, integ, names, scars):
        if not Path(module.__file__).resolve(strict=True).is_relative_to(root):
            raise SevenFieldError("E_REFERENCE_IMPORT_ESCAPE")
    if (integ.FOUNDATION_DAY_INTEGRATED != FOUNDATION
            or hashlib.sha256(Path(integ.__file__).read_bytes()).hexdigest()
            != PINNED_MODULE_SHA256):
        raise SevenFieldError("E_REFERENCE_INTEGRATION_DRIFT")
    cutlets = {x.text: x.canonical_index for x in names.SOURCE_LANGUAGE_CATALOG.cutlets}
    months = {x.text: x.canonical_index for x in names.SOURCE_LANGUAGE_CATALOG.months}
    if (len(cutlets), len(months)) != (17, 47):
        raise SevenFieldError("E_REFERENCE_CATALOG")
    scars.reset_acceleration_scars_for_tests()
    with scars.acceleration_mode(True):
        result = calendar.calendar_date_spaghetti(FOUNDATION, target)
    if not isinstance(result, integ.SpaghettiDateResult):
        raise SevenFieldError("E_REFERENCE_RESULT")
    fields = [result.year_number, cutlets[result.cutlet_name],
              result.day_in_cutlet, months[result.month_name], result.day_in_month]
    print(json.dumps({"day": target, "five_fields": fields,
                      "reference_commit": PINNED_SHA,
                      "module_sha256": PINNED_MODULE_SHA256,
                      "isolated": True, "cache_reset": True}, sort_keys=True))


def spawn_python(script: Path, root: Path, target: int, timeout: int):
    # One throwaway HOME/CWD and one fresh process for each target.
    with tempfile.TemporaryDirectory(prefix="seven-field-reference-") as tmp:
        env = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": tmp,
               "PYTHONDONTWRITEBYTECODE": "1", "PYTHONNOUSERSITE": "1"}
        p = subprocess.run(
            [sys.executable, "-I", str(script.resolve(strict=True)), "--worker",
             "--pinned-root", str(root), "--day", str(target)],
            cwd=tmp, env=env, text=True, capture_output=True, timeout=timeout)
    if p.returncode or len(p.stdout.splitlines()) != 1:
        raise SevenFieldError("E_REFERENCE_EXEC_" + str(target) + " " + p.stderr[-300:])
    try:
        doc = json.loads(p.stdout)
    except json.JSONDecodeError as exc:
        raise SevenFieldError("E_REFERENCE_JSON") from exc
    return validate_reference(doc, target)


def spawn_kotlin(jar: Path, target: int, timeout: int):
    p = subprocess.run(
        ["java", "-XX:ActiveProcessorCount=1", "-Xmx1200m", "-Xss8m",
         "-cp", str(jar), "pastafari.Post55ProductionDateBridge"],
        input=f"{FOUNDATION}\t{target}\n", text=True,
        capture_output=True, timeout=timeout)
    if p.returncode:
        raise SevenFieldError("E_PRODUCTION_EXEC_" + str(target) + " " + p.stderr[-300:])
    return parse_production(p.stdout, FOUNDATION, target)


def compare(production: list[int], reference: list[int]) -> bool:
    return type(production) is list and type(reference) is list and production[2:] == reference


def run(args):
    if (args.worker_timeout < 1 or args.worker_timeout > 180
            or args.total_timeout < 1 or args.total_timeout > 700):
        raise SevenFieldError("E_TIMEOUT_BOUNDS")
    root = Path(__file__).resolve().parent.parent
    sha, module_sha = source_guard(root, args.pinned_root)
    jar = args.jar.resolve(strict=True)
    if not jar.is_file() or jar.stat().st_size == 0:
        raise SevenFieldError("E_PRODUCTION_JAR")
    start = monotonic()
    evidence = []
    for target in TARGETS:
        remaining = int(args.total_timeout - (monotonic() - start))
        if remaining <= 0:
            raise SevenFieldError("E_TOTAL_DEADLINE")
        production = spawn_kotlin(jar, target, min(remaining, args.worker_timeout))
        remaining = int(args.total_timeout - (monotonic() - start))
        if remaining <= 0:
            raise SevenFieldError("E_TOTAL_DEADLINE")
        reference = spawn_python(Path(__file__), args.pinned_root, target,
                                 min(remaining, args.worker_timeout))
        equal = compare(production, reference)
        evidence.append({"calculation_day": FOUNDATION, "target_day": target,
                         "production_seven": production, "reference_five": reference,
                         "matched": equal})
        if not equal:
            raise SevenFieldError("E_SEVEN_FIELD_DIFFERENTIAL_" +
                                  json.dumps(evidence, sort_keys=True))
    return {"status": PASS, "branch_commit": sha, "pinned_commit": PINNED_SHA,
            "pinned_module_sha256": module_sha,
            "jar_sha256": hashlib.sha256(jar.read_bytes()).hexdigest(),
            "cases": 3, "production_fields_per_case": 7, "compared_date_fields": 15,
            "comparisons": evidence, "cold_pinned_processes": 3,
            "reference_cache_reset_per_process": True,
            "pinned_reference_static_checkpoints_may_be_used": True,
            "production_gate_limit_unchanged": 8192,
            "full_date_certified": False, "certifiable": False,
            "elapsed_seconds": round(monotonic() - start, 3)}


def main(argv=None):
    p = argparse.ArgumentParser()
    p.add_argument("--worker", action="store_true")
    p.add_argument("--day", type=int)
    p.add_argument("--pinned-root", type=Path, required=True)
    p.add_argument("--jar", type=Path)
    p.add_argument("--evidence", type=Path)
    p.add_argument("--worker-timeout", type=int, default=150)
    p.add_argument("--total-timeout", type=int, default=600)
    a = p.parse_args(argv)
    if a.worker:
        reference_worker(a.pinned_root, a.day)
        return 0
    if a.jar is None or a.evidence is None:
        p.error("--jar and --evidence are required")
    try:
        report = run(a)
    except Exception as exc:
        report = {"status": "FAIL_BOUND_PRODUCTION_SEVEN_FIELDS",
                  "error_type": type(exc).__name__, "error": str(exc)[:2000],
                  "full_date_certified": False, "certifiable": False}
    a.evidence.parent.mkdir(parents=True, exist_ok=True)
    a.evidence.write_text(json.dumps(report, sort_keys=True, indent=2) + "\n",
                          encoding="utf-8")
    print(json.dumps(report, sort_keys=True))
    return 0 if report["status"] == PASS else 2


if __name__ == "__main__":
    raise SystemExit(main())
