#!/usr/bin/env python3
"""Bounded native cost breakdown for the immutable Punjabi BASIC Oracle.

Diagnostic only. No acceptance of Stage 5 or production calendar, and no source
changes: diagnostic Basic functions exist only in a fresh temporary LO profile.
"""
import argparse
import csv
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile
import threading
import time
import traceback

import stage3_native_ci as office
import stage5_calendar_semantic_ci as s5

# Phase order is cumulative, so the first timed-out phase bounds the expensive
# chain without immediately repeating the 240-second all-in-one gate call.
PHASES = [
    ("stones", "S5DiagStones", 45),
    ("hidden", "S5DiagHidden", 60),
    ("visible", "S5DiagVisible", 90),
    ("initial_bowls", "S5DiagInitial", 30),
    ("drops", "S5DiagDrops", 120),
    ("post_stir", "S5DiagStir", 150),
    ("sauce", "S5DiagSauce", 180),
    ("one_gate_gap", "S5DiagGap", 180),
]
PROBE = r'''
' Temporary Stage5 cost diagnostics, NEVER committed as production Basic.
Public Function S5DiagStones() As String
 Dim stones As Variant
 stones = OracleBuildStones()
 S5DiagStones = CStr(Len(CStr(stones(46, 1))))
End Function
Public Function S5DiagHidden() As String
 Dim counts As Variant, stones As Variant, h As Variant
 counts = OracleWorkCounts("-15055671", "-15055674")
 stones = OracleBuildStones()
 h = OracleBuildHidden(counts, stones)
 S5DiagHidden = CStr(Len(CStr(h(7))))
End Function
Public Function S5DiagVisible() As String
 Dim counts As Variant, stones As Variant, h As Variant, v As Variant
 counts = OracleWorkCounts("-15055671", "-15055674")
 stones = OracleBuildStones()
 h = OracleBuildHidden(counts, stones)
 v = OracleBuildVisible(counts, stones, h)
 S5DiagVisible = CStr(Len(CStr(v(46))))
End Function
Public Function S5DiagInitial() As String
 Dim counts As Variant, b As Variant
 counts = OracleWorkCounts("-15055671", "-15055674")
 b = OracleInitialBowls(counts)
 S5DiagInitial = CStr(Len(CStr(b(6))))
End Function
Public Function S5DiagDrops() As String
 Dim counts As Variant, stones As Variant, h As Variant, v As Variant
 Dim b As Variant, r As Variant, bb As Variant
 counts = OracleWorkCounts("-15055671", "-15055674")
 stones = OracleBuildStones()
 h = OracleBuildHidden(counts, stones)
 v = OracleBuildVisible(counts, stones, h)
 b = OracleInitialBowls(counts)
 r = OracleApplyDropsToBowls(b, v, stones)
 bb = r(0)
 S5DiagDrops = CStr(Len(CStr(bb(6))))
End Function
Public Function S5DiagStir() As String
 Dim counts As Variant, stones As Variant, h As Variant, v As Variant
 Dim b As Variant, r As Variant, bb As Variant, z As Variant
 counts = OracleWorkCounts("-15055671", "-15055674")
 stones = OracleBuildStones()
 h = OracleBuildHidden(counts, stones)
 v = OracleBuildVisible(counts, stones, h)
 b = OracleInitialBowls(counts)
 r = OracleApplyDropsToBowls(b, v, stones)
 bb = r(0)
 z = OraclePostStir12(bb)
 S5DiagStir = CStr(Len(CStr(z(6))))
End Function
Public Function S5DiagSauce() As String
 Dim r As Variant, bb As Variant
 r = OracleSauce("-15055671", "-15055674")
 bb = r(0)
 S5DiagSauce = CStr(Len(CStr(bb(6))))
End Function
Public Function S5DiagGap() As String
 S5DiagGap = CStr(OracleOneGateGap("-3"))
End Function
'''

def inject_owned(profile_target):
    path = profile_target / "Standard" / "Tests.xba"
    source = path.read_text(encoding="utf-8")
    marker = "]]></script:module>"
    if source.count(marker) != 1 or "S5DiagStones" in source:
        raise AssertionError("DIAGNOSTIC_INJECTION_REFUSED")
    path.write_text(source.replace(marker, PROBE + marker), encoding="utf-8")


def run(basic, out):
    out.mkdir(parents=True, exist_ok=True)
    progress_path = out / "progress.log"
    rows = []
    errors = []
    outcome = "DIAGNOSTIC_INCOMPLETE"
    source_locked = False
    def log(msg):
        line = "%.3f\t%s\n" % (time.time(), msg)
        with progress_path.open("a", encoding="utf-8") as f:
            f.write(line)
            f.flush()
            os.fsync(f.fileno())
        print("[STAGE5-DIAG] " + msg, flush=True)
    log("DIAG_START")
    try:
        s5.preflight(basic)
        source_locked = True
        log("PREFLIGHT_LOCKS_PASS")
        with tempfile.TemporaryDirectory(prefix="pc-punjabi-gate-diagnostic-") as root:
            profile = Path(root) / "isolated-lo-profile"
            log("PROFILE_INIT_START")
            proc, context = s5.managed_office_session(office, profile, out / "lo-startup.log")
            s5.close_managed_office(office, proc, context)
            target = profile / "user" / "basic"
            if target.exists():
                shutil.rmtree(target)  # New, exclusively owned profile only.
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copytree(basic, target)
            inject_owned(target)
            log("TEMPORARY_PROBE_REGISTERED")
            proc, context = s5.managed_office_session(office, profile, out / "lo-startup.log")
            tainted = False
            try:
                factory = context.ServiceManager.createInstanceWithContext(
                    "com.sun.star.script.provider.MasterScriptProviderFactory", context
                )
                provider = factory.createScriptProvider("")
                for phase, function, timeout in PHASES:
                    log("PHASE_START %s timeout_s=%d" % (phase, timeout))
                    finished = threading.Event()
                    expired = threading.Event()
                    def watchdog():
                        if finished.is_set():
                            return
                        expired.set()
                        log("WATCHDOG_KILL_GROUP " + phase)
                        s5.kill_owned_office_group(proc)
                    timer = threading.Timer(timeout, watchdog)
                    timer.daemon = True
                    timer.start()
                    value, call_error = None, None
                    start = time.monotonic()
                    try:
                        script = provider.getScript(
                            "vnd.sun.star.script:Standard.Tests.%s?language=Basic&location=application" % function
                        )
                        value = script.invoke((), (), ())[0]
                    except Exception as exc:
                        call_error = exc
                    finally:
                        finished.set()
                        timer.cancel()
                    seconds = round(time.monotonic() - start, 3)
                    if expired.is_set():
                        tainted = True
                        rows.append([phase, function, timeout, seconds, "TIMEOUT", ""])
                        log("PHASE_TIMEOUT %s elapsed_s=%.3f" % (phase, seconds))
                        outcome = "DIAGNOSTIC_TIMEOUT_CAPTURED"
                        break
                    if call_error is not None:
                        rows.append([phase, function, timeout, seconds, "ERROR", type(call_error).__name__])
                        errors.append("%s: %r" % (phase, call_error))
                        log("PHASE_ERROR %s %s" % (phase, type(call_error).__name__))
                        outcome = "DIAGNOSTIC_NATIVE_ERROR_CAPTURED"
                        break
                    if not isinstance(value, str):
                        rows.append([phase, function, timeout, seconds, "NONSTRING", repr(value)])
                        errors.append("%s: non-string UNO return" % phase)
                        outcome = "DIAGNOSTIC_NATIVE_ERROR_CAPTURED"
                        break
                    rows.append([phase, function, timeout, seconds, "RETURNED", value])
                    log("PHASE_RETURNED %s elapsed_s=%.3f" % (phase, seconds))
                else:
                    outcome = "DIAGNOSTIC_ALL_PHASES_RETURNED"
            finally:
                s5.close_managed_office(office, proc, context, tainted=tainted)
    except Exception as exc:
        outcome = "DIAGNOSTIC_INFRASTRUCTURE_FAILED"
        errors.append("%s: %s" % (type(exc).__name__, exc))
        (out / "error.txt").write_text(traceback.format_exc(), encoding="utf-8")
        log("DIAG_EXCEPTION %s" % type(exc).__name__)
    finally:
        with (out / "timings.tsv").open("w", encoding="utf-8", newline="") as f:
            w = csv.writer(f, delimiter="\t", lineterminator="\n")
            w.writerow(("phase", "function", "timeout_s", "elapsed_s", "outcome", "returned_value"))
            w.writerows(rows)
        report = {
            "scope": "QA_NATIVE_DIAGNOSTIC_ONLY_NOT_STAGE5_ACCEPTANCE",
            "project": "PC-BRANCH-BASIC-PUNJABI",
            "source_stage3_lock": "74aa087b81094f34eab9a0e04e395cc693dd83b1",
            "candidate_commit": os.getenv("GITHUB_SHA", "LOCAL"),
            "full_production_calendar": "NOT_IMPLEMENTED",
            "complete_stage5_probes": 0,
            "outcome": outcome,
            "phases_attempted": len(rows),
            "phases_total": len(PHASES),
            "errors": errors,
            "phase_results": [dict(zip(("phase", "function", "timeout_s", "elapsed_s", "outcome", "returned_value"), r)) for r in rows],
        }
        (out / "diagnostic.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        (out / "source_metadata.json").write_text(json.dumps({
            "locks": s5.LOCKS,
            "source_sha_locked": source_locked,
            "source_stage3_lock": report["source_stage3_lock"],
            "candidate_commit": report["candidate_commit"],
            "profile": "temporary_isolated_owned_posix_process_group",
            "production_changed": False,
        }, indent=2) + "\n", encoding="utf-8")
        (out / "status.txt").write_text(outcome + "\n", encoding="utf-8")
        log("DIAG_END outcome=" + outcome)
    return 1 if outcome == "DIAGNOSTIC_INFRASTRUCTURE_FAILED" else 0


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--self-test", action="store_true")
    p.add_argument("--basic-dir", type=Path)
    p.add_argument("--output-dir", type=Path)
    a = p.parse_args()
    if a.self_test:
        assert len(PHASES) == 8 and len(set(x[0] for x in PHASES)) == 8
        assert all(x[2] > 0 for x in PHASES)
        assert PROBE.count("Public Function S5Diag") == len(PHASES)
        print("STAGE5_GATE_DIAG_SELFTEST_PASS phases=8")
        return 0
    if a.basic_dir is None or a.output_dir is None:
        p.error("--basic-dir and --output-dir are required")
    return run(a.basic_dir.resolve(), a.output_dir.resolve())

if __name__ == "__main__":
    sys.exit(main())
