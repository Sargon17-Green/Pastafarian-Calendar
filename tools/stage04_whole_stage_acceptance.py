#!/usr/bin/env python3
"""Fail-closed whole-Stage04 evidence-consistency gate; not a live CI verifier."""
from __future__ import annotations
import argparse
import csv
import io
import json
import re
import subprocess
import sys
import unittest
from pathlib import Path

PROJECT = "PC-BRANCH-RUST-AZERBAIJANI"
F = -15055671
APPROVAL = ("audit/STAGE_04_RUST_AUTHORIZED_RECONSTRUCTION_SUBSTITUTION_2026-11-22.md",
            "e072d0f73e79dbecd354ed267782d257d539571b")
PRIOR_QA = ("audit/STAGE_04_RUST_APPROVED_SUBSTITUTION_EXACT_CI_ARTIFACT_QA_2026-11-22.md",
            "578621b5f36abbf027f88e9096e833fbb23a9486")
HISTORICAL = ("tools/stage04_rust_witness_provenance.py",
              "4969623f859827a603f88c5811d03ac9463bbd3c")

class GateError(ValueError):
    pass

def require(ok: bool, message: str) -> None:
    if not ok:
        raise GateError(message)

def offset_cases():
    return list(range(-3, 4)) + [s * (1 << bits) for bits in (127, 1025, 4096, 8192) for s in (-1, 1)]

def check_cases(cases):
    require(isinstance(cases, list) and len(cases) == 15, "fifteen differential cases required")
    for i, (delta, c) in enumerate(zip(offset_cases(), cases)):
        require(isinstance(c, dict), "case must be object")
        day = F + delta
        tag = 2 * abs(delta) + (1 if delta >= 0 else 0)
        old = tag - (1 if delta >= 0 else 0)
        required = {"index":i,"offset":str(delta),"day":str(day),
                    "legacy":str(old),"oracle":str(tag),"patched":str(tag),
                    "candidate":str(tag),"classification":"RED" if delta >= 0 else "CONTROL",
                    "pass":True}
        require(all(type(c.get(k)) is type(v) and c.get(k)==v for k,v in required.items()),
                "differential case mismatch " + str(i))
    return True

def check_evidence(root:Path, sha:str):
    require(bool(re.fullmatch(r"[0-9a-f]{40}",sha)), "exact 40-char SHA required")
    get=lambda p: (root/p).read_text(encoding="utf-8")
    j=lambda p: json.loads(get(p))
    require(get("sha.txt").splitlines() == [f"PROJECT_ID={PROJECT}",f"SHA={sha}"], "wrong SHA/project")
    require(get("exit.txt").strip()=="0", "Native exit nonzero")
    stage_result = get("result.txt")
    for marker in ("STAGE04_DISCOVERY02_ARCHIVAL_WITNESS_QA=PASS",
                   "STAGE04_DIRECT_RUNTIME_DIFFERENTIAL=PASS",
                   "STAGE04_AUTHORIZED_RECONSTRUCTION_STATIC_ADMISSION=PASS",
                   "STAGE04_CLOSURE=NOT_CLAIMED"):
        require(marker in stage_result.splitlines(), "missing stage marker "+marker)
    test_specs = (("stage04_tsv_protocol_tests.txt",6),
                  ("stage04_provenance_tests.txt",16),
                  ("stage04_callability_tests.txt",19),
                  ("stage04_substitution_unit_tests.txt",5))
    for name,count in test_specs:
        t = get(name)
        require(f"Ran {count} tests" in t and "\nOK\n" in "\n"+t+"\n"
                and "FAILED" not in t and "ERROR" not in t and "skipped=" not in t,
                "unit tests not complete: "+name)
    source=j("stage04_source_pin.json")
    require(source.get("source_pin_eligible") is True
            and source.get("historical_day_tag_route_proven") is False
            and source.get("observed_runtime_red") is False
            and source.get("stage04_closure")=="NOT_CLAIMED", "source provenance mismatch")
    call=j("stage04_old_rust_callability.json")
    require(call.get("callability_status")=="SOURCE_ONLY_NO_SUPPORTED_SIGNATURE"
            and call.get("callable_day_tag_route_verified") is False
            and call.get("observed_runtime_red") is False
            and call.get("stage04_closure")=="NOT_CLAIMED", "Rust callability claim mismatch")
    sub=j("stage04_reconstructed_substitution.json")
    require(sub.get("project_id")==PROJECT and sub.get("reconstruction_substitution_static_eligible") is True
            and sub.get("historical_pre_stage03_rust_red_proven") is False
            and sub.get("original_historical_gate_unchanged") is True
            and sub.get("native_ci_live_status_checked_by_this_script") is False
            and sub.get("independently_verified_observed_rows")==128
            and sub.get("before_foundation")==64 and sub.get("on_or_after_foundation")==64
            and sub.get("stage04_closure")=="NOT_CLAIMED", "reconstruction admission mismatch")
    diff=j("stage04_direct_runtime_report.json")
    require(diff.get("project_id")==PROJECT and diff.get("stage")=="04/DISCOVERY02"
            and diff.get("status")=="PASS" and diff.get("stage_closure")=="NOT_CLAIMED"
            and (diff.get("rust_rows"),diff.get("red"),diff.get("control"),diff.get("unexpected"),
                 diff.get("patch_ok"),diff.get("candidate_ok"))==(15,8,7,0,15,15),
            "differential summary mismatch")
    check_cases(diff.get("cases"))
    tsv=list(csv.reader(io.StringIO(get("stage04_rust_rows.tsv")),delimiter="\t"))
    require(len(tsv)==16 and tsv[0]==["index","day","oracle","candidate"], "Rust TSV shape mismatch")
    for i,(delta,row) in enumerate(zip(offset_cases(),tsv[1:])):
        tag=2*abs(delta)+(1 if delta>=0 else 0)
        require(row==[str(i),str(F+delta),str(tag),str(tag)],"Rust TSV mismatch "+str(i))
    d=get("stage04_differential_stdout.txt")
    require("STAGE04_CROSS_RUNTIME_RED=8 CONTROL=7 UNEXPECTED=0" in d
            and "STAGE04_CROSS_RUNTIME_PATCH_OK=15 CANDIDATE_OK=15" in d
            and "STAGE04_CROSS_RUNTIME_RESULT=PASS STAGE04_CLOSURE=NOT_CLAIMED" in d,
            "differential output mismatch")
    stdout=get("stdout.txt")
    for marker in ("STAGE04_DISCOVERY02_BASELINE_CASES=7",
                   "STAGE04_DISCOVERY02_ARCHIVED_RED=8 CONTROL=7 UNEXPECTED=0",
                   "STAGE02_DISCOVERY01_EXPECTED_RED=3 CONTROL=1 UNEXPECTED=0",
                   "STAGE03_PATCH01_BOUNDARY_OK=8"):
        require(marker in stdout,"Native regression marker missing")
    require("test result: FAILED" not in stdout, "Rust test failure")
    return {"stage04_completion_evidence_consistency":"PASS",
            "validated_original_rust_tsv_rows":15,"validated_reconstructed_native_observed_rows":128,
            "archived_python_red":8,"archived_python_control":7,
            "historical_pre_stage03_rust_red_proven":False,
            "live_completed_ci_checked_by_this_script":False,
            "closure_candidate":True,"stage04_closure":"ACCEPTED"}

def verify_repo(repo:Path,sha:str):
    def git(*args):
        p=subprocess.run(["git","-C",str(repo),*args],capture_output=True,text=True,timeout=15)
        require(p.returncode==0,"Git object unavailable: "+" ".join(args[:2]))
        return p.stdout.strip()
    require(git("rev-parse","HEAD")==sha,"checkout is not exact SHA")
    for path,blob in (APPROVAL,PRIOR_QA,HISTORICAL):
        require(git("rev-parse","HEAD:"+path)==blob,"pinned audit/source blob changed: "+path)
    s=(repo/"DEVELOPMENT_STAGE.md").read_text(encoding="utf-8").splitlines()
    require("CURRENT_STAGE=4" in s and "LAST_COMPLETED_STAGE=4" in s
            and "CURRENT_KIND=DISCOVERY02" in s, "stage counters changed prematurely")
    require("EXPECTED_REPOSITORY_STATE=DISCOVERY02_STAGE04_ACCEPTED_HOLD_NO_STAGE05" in s,
            "expected stage state changed")
    record=(repo/"audit/STAGE_04_RUST_FINAL_ACCEPTANCE_2026-11-22.md").read_text(encoding="utf-8")
    for pin in ("STAGE04_FINAL_DISPOSITION=ACCEPTED", "SOURCE_CI_SHA=fd0d125a2621c99fb9b356a845d40ebb91aa3e53",
                "STAGE04_CI_RUN=45069086364", "NAMES_LOCK_RUN=45069086363",
                "ARTIFACT_SHA256=117603bb1f57a8996cba087297cefbe70b0c811f6f646e90652ed24be0ffbbfe",
                "HISTORICAL_PRE_STAGE03_RUST_RED=NOT_PROVEN",
                "SUBSTITUTE=AUTHORIZED_2026_RECONSTRUCTED_NATIVE_RED_GREEN"):
        require(pin in record,"final acceptance record pin missing: "+pin)
    lib=(repo/"src/lib.rs").read_text(encoding="utf-8")
    require("BootstrapOnly" in lib, "Rust production bootstrap boundary absent")

class UnitTests(unittest.TestCase):
    def test_canonical_cases(self):
        a=[dict(index=i,offset=str(d),day=str(F+d),legacy=str(2*abs(d)),
                oracle=str(2*abs(d)+(d>=0)),patched=str(2*abs(d)+(d>=0)),
                candidate=str(2*abs(d)+(d>=0)),classification="RED" if d>=0 else "CONTROL",
                **{"pass":True}) for i,d in enumerate(offset_cases())]
        self.assertTrue(check_cases(a))
    def test_wrong_observed_fails(self):
        a=[dict(index=i,offset=str(d),day=str(F+d),legacy=str(2*abs(d)),
                oracle=str(2*abs(d)+(d>=0)),patched=str(2*abs(d)+(d>=0)),
                candidate=str(2*abs(d)+(d>=0)),classification="RED" if d>=0 else "CONTROL",
                **{"pass":True}) for i,d in enumerate(offset_cases())]
        a[3]["candidate"]="0"
        with self.assertRaises(GateError):check_cases(a)
    def test_truncated_cases_fail(self):
        with self.assertRaises(GateError):check_cases([])
    def test_only_full_sha(self):
        import tempfile
        with tempfile.TemporaryDirectory() as x:
            with self.assertRaisesRegex(GateError,"exact 40-char"):check_evidence(Path(x),"bad")
    def test_missing_evidence_fails_closed(self):
        import tempfile
        with tempfile.TemporaryDirectory() as x:
            with self.assertRaises(FileNotFoundError):check_evidence(Path(x),"0"*40)

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--self-test",action="store_true")
    p.add_argument("--repo",type=Path,default=Path("."))
    p.add_argument("--evidence",type=Path,default=Path("evidence"))
    p.add_argument("--branch-head")
    a=p.parse_args()
    if a.self_test:
        suite=unittest.defaultTestLoader.loadTestsFromTestCase(UnitTests)
        result=unittest.TextTestRunner(verbosity=2).run(suite)
        return 0 if result.wasSuccessful() else 1
    try:
        require(bool(a.branch_head), "missing --branch-head")
        verify_repo(a.repo,a.branch_head)
        result=check_evidence(a.evidence,a.branch_head)
        result["project_id"]=PROJECT
        result["verified_checkout_sha"]=a.branch_head
        print(json.dumps(result,sort_keys=True))
        return 0
    except (GateError,OSError,ValueError,subprocess.TimeoutExpired) as exc:
        print(json.dumps({"project_id":PROJECT,"closure_candidate":False,
                          "stage04_closure":"NOT_CLAIMED","reason":str(exc)},sort_keys=True))
        return 2

if __name__=="__main__":
    sys.exit(main())
