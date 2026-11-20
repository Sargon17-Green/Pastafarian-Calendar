"""Synthetic GitHub API source-census fixtures; no converter/date executions."""
from __future__ import annotations

import copy
import hashlib
import sys
from pathlib import Path
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "runner"))
from soak_source_census_v129 import (
    census, APIProblem, fail_if_invalid_inputs, git_blob_sha1,
    safe_path,
)

REPO="Sargon17-Green/Pastafarian-Calendar"
OTHER="Sargon-17-Green/Pastafarian-Calendar-Seer"
A=b"source one\n"
B=b"source two\n"
DEP=b"source dependency\n"


def source(data):
    return {"sha256": hashlib.sha256(data).hexdigest(),
            "blob": git_blob_sha1(data), "bytes": len(data)}


def fixture():
    roster={
        "schema": "PASTAFARI_SOAK_SOURCE_ROSTER_V127/1",
        "records": [
            {"record_id":"REF-41","engine_id":"REF-41",
             "algorithm_id":"UNASSESSED","source_kind":"reference"},
            {"record_id":"REF-24","engine_id":"REF-24",
             "algorithm_id":"UNASSESSED","source_kind":"reference"},
            {"record_id":"ALIAS","engine_id":"ALIAS",
             "algorithm_id":"UNASSESSED","source_kind":"production_candidate"},
            {"record_id":"MISSING","engine_id":"MISSING",
             "algorithm_id":"UNASSESSED","source_kind":"triage"},
            {"record_id":"SEER","engine_id":"SEER",
             "algorithm_id":"UNASSESSED","source_kind":"variant"},
        ]}
    rows = [
        {"record_id":"REF-41","repository":REPO,"branch":"Python+Türkçe",
         "source_path":"tests/reference.py"},
        {"record_id":"REF-24","repository":REPO,"branch":"JavaScript+Interlingue",
         "source_path":"tests/reference.js"},
        {"record_id":"ALIAS","repository":REPO,"branch":"Python+Türkçe",
         "source_path":"src/production.py"},
        {"record_id":"MISSING","repository":REPO,"branch":"Python+Türkçe",
         "source_path":None},
        {"record_id":"SEER","repository":OTHER,
         "branch":"research/native","source_path":"src/native.cpp"},
    ]
    for row in rows:
        row.update(source_status_as_of_2026_11_14="ARCHIVED",
                   source_url=None)
    provenance = {
        "schema":"PASTAFARI_SOAK_ARCHIVED_ROSTER_PROVENANCE_V127/1",
        "source_file":"synthetic.json",
        "source_internal_schema":"synthetic","source_created_utc_date":"2026-11-14",
        "source_scope":"synthetic","source_counts":{},
        "records":rows,"caveats":[]}
    locks={
        "schema":"PASTAFARI_SOAK_PILOT_SOURCE_LOCK/1",
        "main_changes_permitted":False,
        "engines":[
            {"id":"REF-41","repository":REPO,"branch":"Python+Türkçe",
             "commit":"1"*40,"sources":[{
                 "path":"tests/reference.py","sha256":source(A)["sha256"],
                 "git_blob_sha1":source(A)["blob"],"bytes":len(A)}]},
            {"id":"REF-24","repository":REPO,"branch":"JavaScript+Interlingue",
             "commit":"2"*40,"sources":[{
                 "path":"tests/reference.js","sha256":source(B)["sha256"],
                 "git_blob_sha1":source(B)["blob"],"bytes":len(B)},
                 {"path":"src/dependency.js","sha256":source(DEP)["sha256"],
                 "git_blob_sha1":source(DEP)["blob"],"bytes":len(DEP)}]}
        ]}
    return roster,provenance,locks


class FakeGitHub:
    def __init__(self):
        self.heads={REPO:{"Python+Türkçe":"1"*40,
                          "JavaScript+Interlingue":"2"*40}}
        self.by_path={
            (REPO,"1"*40,"tests/reference.py"):source(A),
            (REPO,"2"*40,"tests/reference.js"):source(B),
            (REPO,"2"*40,"src/dependency.js"):source(DEP),
            (REPO,"1"*40,"src/production.py"):source(b"another source"),
        }
        self.calls=[]

    def branch_heads(self,repo):
        self.calls.append(("branch_heads",repo))
        if repo not in self.heads:
            raise APIProblem("NOT_FOUND_OR_NOT_AUTHORIZED")
        return self.heads[repo]

    def source(self,repo,commit,path):
        self.calls.append(("source",repo,commit,path))
        if (repo,commit,path) not in self.by_path:
            raise APIProblem("NOT_FOUND_OR_NOT_AUTHORIZED")
        s=self.by_path[(repo,commit,path)]
        return {"source_sha256":s["sha256"],"git_blob_sha1":s["blob"],"bytes":s["bytes"]}


class SourceCensusTests(unittest.TestCase):
    def setUp(self):
        self.roster,self.prov,self.locks=fixture()
        self.gh=FakeGitHub()

    def run_census(self):
        return census(self.roster,self.prov,self.locks,self.gh)

    def test_frozen_all_deps_and_live_source_sha_checked(self):
        report=self.run_census()
        self.assertEqual(report["record_count"],5)
        by_id={r["record_id"]:r for r in report["records"]}
        for rid in ("REF-41","REF-24"):
            self.assertEqual(by_id[rid]["frozen_source_lock_status"],
                             "FROZEN_SOURCES_SHA_LOCK_PASS")
            self.assertEqual(by_id[rid]["source_observation"],
                             "SOURCE_BYTES_VERIFIED_AT_HEAD")
        self.assertEqual(len(by_id["REF-24"]["locked_sources"]),2)
        self.assertTrue(all(x["integrity_matches_archived_lock"]
                            for x in by_id["REF-24"]["locked_sources"]))
        self.assertFalse(report["soak_dispatch_authorized"])
        self.assertEqual(report["official_years_certified"],0)
        self.assertEqual(report["native_date_calls"],0)

    def test_archived_alias_not_counted_as_independent(self):
        report=self.run_census()
        item=next(r for r in report["records"] if r["record_id"]=="ALIAS")
        self.assertEqual(item["source_observation"],"SOURCE_BYTES_VERIFIED_AT_HEAD")
        self.assertFalse(item["independent_algorithm_certified_by_census"])
        self.assertFalse(item["eligible_for_soak"])

    def test_missing_path_is_explicit(self):
        report=self.run_census()
        item=next(r for r in report["records"] if r["record_id"]=="MISSING")
        self.assertEqual(item["source_observation"],"SOURCE_PATH_NOT_DECLARED")
        self.assertIsNone(item["observed_source"])

    def test_unavailable_cross_repo_never_reported_as_missing_branch(self):
        report=self.run_census()
        row=next(r for r in report["records"] if r["record_id"]=="SEER")
        self.assertEqual(row["source_observation"],"REPOSITORY_UNAVAILABLE_OR_NO_ACCESS")
        self.assertEqual(report["repository_access_failures"][OTHER],
                         "NOT_FOUND_OR_NOT_AUTHORIZED")

    def test_lock_mismatch_detected_without_claiming_native_failure(self):
        self.locks["engines"][0]["sources"][0]["sha256"]="f"*64
        row=self.run_census()["records"][0]
        self.assertEqual(row["frozen_source_lock_status"],"FROZEN_SOURCE_LOCK_MISMATCH")
        self.assertEqual(row["source_observation"],"SOURCE_BYTES_VERIFIED_AT_HEAD")
        self.assertFalse(row["native_full_date_execution_verified_by_census"])

    def test_missing_locked_dependency_fails_pin(self):
        del self.gh.by_path[(REPO,"2"*40,"src/dependency.js")]
        row=self.run_census()["records"][1]
        self.assertEqual(row["frozen_source_lock_status"],"FROZEN_SOURCE_UNAVAILABLE")
        self.assertFalse(row["locked_sources"][1]["integrity_matches_archived_lock"])

    def test_current_branch_move_does_not_break_pinned_historical_source(self):
        self.gh.heads[REPO]["Python+Türkçe"]="9"*40
        row=self.run_census()["records"][0]
        self.assertFalse(row["live_head_equals_locked_commit"])
        self.assertEqual(row["frozen_source_lock_status"],"FROZEN_SOURCES_SHA_LOCK_PASS")
        self.assertNotEqual(row["source_observation"],"SOURCE_BYTES_VERIFIED_AT_HEAD")

    def test_duplicate_id_is_rejected(self):
        self.prov["records"][2]["record_id"]="REF-41"
        with self.assertRaisesRegex(ValueError, "duplicate archived source"):
            self.run_census()

    def test_immutable_lock_wrong_archived_branch_is_rejected(self):
        self.locks["engines"][0]["branch"]="not-the-archived-branch"
        with self.assertRaisesRegex(ValueError, "lock disagrees"):
            self.run_census()

    def test_path_traversal_rejected(self):
        for path in ("/etc/passwd","../../secret","a//b","a\\b"):
            with self.subTest(path=path), self.assertRaises(ValueError):
                safe_path(path)

    def test_same_source_only_fetched_once(self):
        self.prov["records"][2]["source_path"]="tests/reference.py"
        self.run_census()
        rows=[v for v in self.gh.calls if v==(
            "source",REPO,"1"*40,"tests/reference.py")]
        self.assertEqual(len(rows),1)

    def test_archive_row_order_cannot_drop_records(self):
        self.prov["records"].pop()
        with self.assertRaisesRegex(ValueError, "roster/provenance count"):
            self.run_census()

    def test_metadata_never_confuses_completed_ci_with_execution(self):
        report=self.run_census()
        self.assertTrue(all(not row["native_build_success_verified_by_census"]
                            and not row["native_full_date_execution_verified_by_census"]
                            for row in report["records"]))
        self.assertFalse(report["independent_execution_attested"])


if __name__=="__main__":
    unittest.main()
