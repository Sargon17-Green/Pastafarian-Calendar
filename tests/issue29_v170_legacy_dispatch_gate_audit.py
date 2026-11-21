#!/usr/bin/env python3
"""Issue29 v170: byte-exact staged stop for the Ada legacy 42-job native matrix.

Read-only workflow inspection. NEVER executes any F(c,t).
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import unittest

BASE="e17ab44aa3fd1d08eb14644164735a7c5c87721d"
HISTORIC_BLOB="6c0843169f78e71fbfe95fd0d3c47aa3dc40b7f1"
PATH=".github/workflows/canonical-names-lock.yml"
OLD="    if: github.event_name == 'push' && github.ref == 'refs/heads/Ada+తెలుగు'"
NEW="    if: ${{ false }}"
MARKER=(
    "jobs:\n"
    "  # ISSUE29_NATIVE_DISPATCH_HALT: all 42 historic native jobs below are hard-skipped.\n"
    "  # This QA-stage proposal never alters the canonical names lock verifier.\n"
    "  # Re-enabling a specific job requires a separately reviewed policy change.\n"
    "  verify:"
)
EXPECTED_JOBS=42


def sha1_git_blob(data):
    return hashlib.sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest()


def baseline() -> str:
    raw=subprocess.check_output(["git","show",BASE+":"+PATH],stderr=subprocess.DEVNULL)
    if sha1_git_blob(raw)!=HISTORIC_BLOB:
        raise ValueError("baseline original legacy CI Git blob mismatch")
    return raw.decode("utf-8")


def staged_expected(original:str)->str:
    if original.count(OLD)!=EXPECTED_JOBS:
        raise ValueError("unexpected number of historic Ada auto-date jobs")
    if original.count("jobs:\n  verify:")!=1:
        raise ValueError("cannot uniquely target canonical verifier job")
    return original.replace(OLD,NEW).replace("jobs:\n  verify:",MARKER,1)


def validate(actual:str,original:str)->dict:
    expected=staged_expected(original)
    if actual!=expected:
        raise ValueError("staged legacy gate deviated from exact 42-condition lockdown")
    if actual.count(NEW)!=EXPECTED_JOBS:
        raise ValueError("native matrix is not fully and exactly gated")
    if OLD in actual:
        raise ValueError("historic automatic Ada native dispatch remains active")
    if actual.count("  verify:\n")!=1:
        raise ValueError("canonical name hash verifier was lost")
    if "CANONICAL_NAMES_LOCK.sha256" not in actual:
        raise ValueError("canonical name hash assertion missing")
    jobs=re.findall(r"^  ((?:native-)?stage\d+(?:[-_]\w+)*):\s*$",actual,re.M)
    if len(jobs)!=EXPECTED_JOBS:
        raise ValueError("unexpected number of historical test jobs")
    for name in jobs:
        pattern=r"^  "+re.escape(name)+r":\n"+re.escape(NEW)+r"$"
        if len(re.findall(pattern,actual,re.M))!=1:
            raise ValueError("native test job is not guarded: "+name)
    return {
       "schema":"ISSUE29_V170_LOCKDOWN_ALL_42_ADA_LEGACY_DISPATCH_JOBS/1",
       "status":"EXACT_42_HISTORICAL_NATIVE_JOBS_HARD_SKIPPED",
       "baseline_commit":BASE,"baseline_blob_sha1":HISTORIC_BLOB,
       "native_jobs_hard_skipped":EXPECTED_JOBS,
       "canonical_name_hash_verify_preserved":True,
       "native_jobs_before_source_review_can_execute":False,
       "historical_original_F_calls":0,
       "main_changed":False,
       "soak_dispatch_allowed":False,
       "this_is_QA_staging_not_original_branch_merge":True,
       "staged_sha256":hashlib.sha256(actual.encode("utf-8")).hexdigest(),
    }


class Mutations(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.original=baseline()
        cls.actual=Path(PATH).read_text(encoding="utf-8")

    def test_01_exact_halt(self):
        self.assertEqual(validate(self.actual,self.original)["native_jobs_hard_skipped"],42)

    def test_02_original_has_all_42_autorun_jobs(self):
        self.assertEqual(self.original.count(OLD),42)

    def test_03_active_legacy_not_accepted(self):
        with self.assertRaises(ValueError):validate(self.original,self.original)

    def test_04_one_job_reenabled_rejected(self):
        with self.assertRaises(ValueError):
            validate(self.actual.replace(NEW,OLD,1),self.original)

    def test_05_one_guard_removed_rejected(self):
        with self.assertRaises(ValueError):
            validate(self.actual.replace(NEW,"",1),self.original)

    def test_06_any_native_job_extra_rejected(self):
        with self.assertRaises(ValueError):
            validate(self.actual+"\n  native-stage42-unsafe:\n    runs-on: ubuntu-latest\n",self.original)

    def test_07_name_lock_hash_script_tamper_rejected(self):
        with self.assertRaises(ValueError):
            validate(self.actual.replace("CANONICAL_NAMES_LOCK.sha256","other.sha256"),self.original)

    def test_08_push_trigger_tamper_rejected(self):
        with self.assertRaises(ValueError):
            validate(self.actual.replace("  pull_request:","  pull_request:\n  workflow_dispatch:"),self.original)

    def test_09_42_conditions_are_job_if_exact_false(self):
        self.assertEqual(self.actual.count("    if: ${{ false }}"),42)

    def test_10_no_default_native_autorun_condition(self):
        self.assertNotIn("if: github.event_name == 'push' && github.ref == 'refs/heads/Ada+తెలుగు'",self.actual)

    def test_11_job_still_verifies_canonical_names(self):
        self.assertIn("while read -r expected path",self.actual)
        self.assertIn("  verify:\n    runs-on: ubuntu-latest",self.actual)

    def test_12_original_source_blob_provenance(self):
        self.assertEqual(sha1_git_blob(self.original.encode("utf-8")),HISTORIC_BLOB)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--check",action="store_true")
    parser.add_argument("--tests",action="store_true")
    a=parser.parse_args()
    if a.tests:
        suite=unittest.defaultTestLoader.loadTestsFromTestCase(Mutations)
        result=unittest.TextTestRunner(verbosity=2).run(suite)
        if not result.wasSuccessful():
            raise SystemExit(1)
        return
    record=validate(Path(PATH).read_text(encoding="utf-8"),baseline())
    print(json.dumps(record,sort_keys=True,ensure_ascii=False))

if __name__=="__main__":
    main()
