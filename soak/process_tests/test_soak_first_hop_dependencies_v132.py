"""Synthetic GitHub snapshot/original-source direct dependency tests. No F(c,t)."""
from __future__ import annotations

import base64
import copy
import hashlib
import sys
from pathlib import Path
from urllib.parse import unquote
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
from soak_source_census_v129 import git_blob_sha1
from soak_first_hop_dependencies_v132 import (
    audit, validate, checked_blob, EXPECTED, DUPLICATE_PAIRS,
    SCHEMA, APIProblem
)


def proof(raw):
    return {"source_sha256":hashlib.sha256(raw).hexdigest(),
            "git_blob_sha1":git_blob_sha1(raw),"source_bytes":len(raw)}


def fixture():
    repos={
        "PYTHON_TURKISH":("source-repo/python","1"*40),
        "JAVASCRIPT_INTERLINGUE":("source-repo/javascript","2"*40),
        "SEER_CPP":("source-repo/seer","3"*40),
        "COPTIC_ASSEMBLY":("source-repo/assembly","4"*40),
        "CODESH_DSL":("source-repo/dsl","5"*40),
    }
    roots={
        "REF-41":("tests/normative_reference.py",b"from math import factorial\n"),
        "TURKISH-PY":("src/pastafari_calendar/calendar.py",
                      b"from .helper import work\nfrom . import config\n"),
        "REF-24":("tests/normative-reference.js",
                  b"const foo=require('../src/source-language-catalog');\n"),
        "INTERLINGUE-JS":("src/index.js",
                          b"const foo = require('./source-language-catalog');\n"),
        "SEER-NEXT-HYBRID":("research/seer-next/src/seer_next_hybrid_engine_service.cpp",
                            b'#include "seer_calendar_core.hpp"\nint main() { return 0; }\n'),
        "SEER-NEXT-YEAR-CACHE":("research/seer-next/src/seer_next_engine_service.cpp",
                                b'#include "seer_calendar_core.hpp"\nint main() { return 1; }\n'),
        "COPTIC-X64":("src/production/stage54_integration.s",
                      b".intel_syntax noprefix\n.extern arena_alloc\n.extern arena_reset\n"),
        "PALEO-CODESH":("מקור/תאריך־שלם־טהור.אמן",
                        "ויהי מחשב שלם נגלה היה.\n".encode("utf-8")),
    }
    aliases={
        "TRIAGE-10":"COPTIC-X64",
        "TRIAGE-02":"PALEO-CODESH",
        "SEER-NEXT-COLD-PROBE":"SEER-NEXT-HYBRID"
    }
    extras={
        "PYTHON_TURKISH":{
            "src/pastafari_calendar/helper.py":b"def work(): pass\n",
            "src/pastafari_calendar/config.py":b"VALUE=1\n",
        },
        "JAVASCRIPT_INTERLINGUE":{
            "src/source-language-catalog.js":b"module.exports={};\n",
        },
        "SEER_CPP":{
            "prototype/src/seer_calendar_core.hpp":b"#pragma once\n",
        },
    }
    files={}
    rows=[]
    manifest={
        "schema":SCHEMA,
        "v131_source_lineage_contract":"PASTAFARI_SOAK_SOURCE_LINEAGE_SCREEN_V131/1",
        "source_mode":"IMMUTABLE_GITHUB_COMMIT_READONLY",
        "probes":[{"record_id":rid,"family":family,"parser":parser,"role":role}
                  for rid,(family,parser,role) in EXPECTED.items()],
        "frozen_duplicate_pairs":DUPLICATE_PAIRS,
        "prohibit_binary_build":True,
        "prohibit_native_date_execution":True,
        "automatic_independence_decision":False,
        "soak_dispatch_authorized":False
    }
    for rid, (family,_,_) in EXPECTED.items():
        repo,commit=repos[family]
        path,raw=roots[rid]
        files[(repo,commit,path)]=raw
        rows.append({"record_id":rid,"repository":repo,
                     "branch":family,"historical_head_commit":commit,
                     "observed_source_path":path,
                     **proof(raw),
                     "eligible_for_soak":False,
                     "algorithmic_independence_certified":False,
                     "native_entrypoint_verified":False,
                     "full_dependency_closure_verified":False,
                     "original_stdout_execution_attested":False})
    for alias, parent in aliases.items():
        parent_row=next(r for r in rows if r["record_id"]==parent)
        rows.append({**copy.deepcopy(parent_row),"record_id":alias})
    for family,sources in extras.items():
        repo,commit=repos[family]
        for path,raw in sources.items():
            files[(repo,commit,path)]=raw
    for i in range(91-len(rows)):
        fake="FILLER-"+str(i)
        rows.append({
            "record_id":fake,"repository":"synthetic-archive/extra",
            "branch":"other"+str(i),
            "historical_head_commit":"6"*40,
            "observed_source_path":"src/other"+str(i)+".py",
            **proof(b"non-executed"+str(i).encode()),
            "eligible_for_soak":False,
            "algorithmic_independence_certified":False,
            "native_entrypoint_verified":False,
            "full_dependency_closure_verified":False,
            "original_stdout_execution_attested":False
        })
    lineage={
        "schema":"PASTAFARI_SOAK_SOURCE_LINEAGE_SCREEN_V131/1",
        "total_historical_records":91,
        "source_rows_bound_to_git_sha256":91,
        "independent_algorithm_count_certified":0,
        "native_original_full_date_engines_certified":0,
        "official_10000_year_soak_credit":0,
        "native_date_calls":0,
        "soak_dispatch_authorized":False,
        "scientific_soak_10000_pass":False,
        "identical_file_content_groups":[
            {"record_ids":sorted(pair)} for pair in DUPLICATE_PAIRS],
        "records":rows
    }
    return manifest,lineage,files


class FakeGitHub:
    def __init__(self,files):
        self.files=files
        self.truncated=False
        self.drop=None
        self.tamper_bytes=None
        self.wrong_tree_sha=None
        self.calls=[]

    def get(self,endpoint):
        self.calls.append(endpoint)
        if "/git/trees/" in endpoint:
            repo,tail=endpoint.split("/git/trees/",1)
            repo=repo.removeprefix("/repos/")
            commit=tail.split("?",1)[0]
            tree=[]
            for (r,c,p),raw in self.files.items():
                if r==repo and c==commit and p!=self.drop:
                    tree.append({"path":p,"type":"blob",
                                 "sha":self.wrong_tree_sha or git_blob_sha1(raw),
                                 "size":len(raw)})
            return {"truncated":self.truncated,"tree":tree}
        if "/contents/" in endpoint:
            repo,tail=endpoint.split("/contents/",1)
            repo=repo.removeprefix("/repos/")
            path,commit=tail.rsplit("?ref=",1)
            path=unquote(path)
            data=self.files[(repo,commit,path)]
            if self.tamper_bytes==(repo,commit,path):
                data+=b"tamper"
            return {"type":"file","encoding":"base64",
                    "content":base64.b64encode(data).decode("ascii"),
                    "size":len(data),"sha":git_blob_sha1(data)}
        raise AssertionError("unrecognized fake GitHub URL "+endpoint)


class FirstHopDependencyTests(unittest.TestCase):
    def setUp(self):
        self.manifest,self.lineage,self.files=fixture()
        self.gh=FakeGitHub(self.files)
    def result(self):
        return audit(self.manifest,self.lineage,self.gh)
    def by_id(self,rid):
        return next(x for x in self.result()["observations"] if x["record_id"]==rid)

    def test_all_eight_roots_frozen_and_no_execution_certification(self):
        result=self.result()
        self.assertEqual(result["eight_verified_root_files"],8)
        self.assertEqual(len(result["distinct_source_families"]),5)
        self.assertFalse(result["full_dependency_closure_certified"])
        self.assertFalse(result["soak_dispatch_authorized"])
        self.assertEqual(result["original_full_years_certified"],0)
        self.assertTrue(all(not p["eligible_for_soak"] for p in result["observations"]))

    def test_python_relative_imports_resolve_direct_files(self):
        r=self.by_id("TURKISH-PY")
        self.assertEqual(len(r["direct_file_references"]),2)
        self.assertTrue(all(x["status"]=="DIRECT_RELATIVE_FILE_BYTES_RECHECKED"
                            for x in r["direct_file_references"]))

    def test_python_standard_library_not_misclassified_as_local(self):
        self.assertEqual(self.by_id("REF-41")["direct_file_references"],[])

    def test_js_reference_and_production_reuse_catalog_file(self):
        a=self.by_id("REF-24")["direct_file_references"][0]
        b=self.by_id("INTERLINGUE-JS")["direct_file_references"][0]
        self.assertEqual(a["resolved_path"],"src/source-language-catalog.js")
        self.assertEqual(a["sha256"],b["sha256"])
        self.assertEqual(a["status"],"DIRECT_RELATIVE_FILE_BYTES_RECHECKED")

    def test_seer_header_found_elsewhere_is_not_build_approval(self):
        a=self.by_id("SEER-NEXT-HYBRID")["direct_file_references"][0]
        self.assertEqual(a["status"],
                         "HEADER_ELSEWHERE_HASH_VERIFIED_INCLUDE_PATH_UNVERIFIED")
        self.assertEqual(a["resolved_path"],"prototype/src/seer_calendar_core.hpp")
        self.assertEqual(len(a["sha256"]),64)

    def test_assembly_external_symbols_are_pending_linking(self):
        r=self.by_id("COPTIC-X64")
        self.assertEqual(r["unresolved_linker_symbols"],["arena_alloc","arena_reset"])
        self.assertFalse(r["native_build_verified"])

    def test_custom_dsl_dependencies_explicitly_not_parsed(self):
        self.assertTrue(self.by_id("PALEO-CODESH")["unparsed_language_dependencies"])
        self.assertFalse(self.result()["full_dependency_closure_certified"])

    def test_duplicate_alias_source_identity_forgery_rejected(self):
        alias=next(x for x in self.lineage["records"]
                   if x["record_id"]=="TRIAGE-10")
        alias["source_sha256"]="f"*64
        with self.assertRaisesRegex(ValueError,"frozen duplicate pair"):
            self.result()

    def test_duplicate_pair_lock_drop_rejected(self):
        self.lineage["identical_file_content_groups"].pop()
        with self.assertRaisesRegex(ValueError,"identical-file collision"):
            self.result()

    def test_root_bytes_changed_from_frozen_sha_rejected(self):
        first=self.manifest["probes"][0]["record_id"]
        row=next(r for r in self.lineage["records"] if r["record_id"]==first)
        self.gh.tamper_bytes=(row["repository"],row["historical_head_commit"],
                              row["observed_source_path"])
        with self.assertRaisesRegex(ValueError,"source root bytes"):
            self.result()

    def test_git_tree_missing_root_rejected(self):
        self.gh.drop="tests/normative_reference.py"
        with self.assertRaisesRegex(ValueError,"source root absent"):
            self.result()

    def test_truncated_git_tree_rejected(self):
        self.gh.truncated=True
        with self.assertRaisesRegex(ValueError,"frozen Git tree unavailable"):
            self.result()

    def test_different_parser_cannot_be_smuggled_in(self):
        self.manifest["probes"][0]["parser"]="UNSUPPORTED_DSL_NEEDS_REVIEW"
        with self.assertRaisesRegex(ValueError,"parser or role laundering"):
            self.result()

    def test_unverified_direct_dependency_not_passed(self):
        self.gh.drop="src/pastafari_calendar/helper.py"
        r=self.by_id("TURKISH-PY")
        self.assertTrue(any(x["status"]=="DIRECT_DEPENDENCY_UNRESOLVED"
                            for x in r["direct_file_references"]))
        self.assertFalse(r["transitive_dependencies_verified"])

    def test_extra_header_missing_does_not_become_linked(self):
        self.gh.drop="prototype/src/seer_calendar_core.hpp"
        a=self.by_id("SEER-NEXT-HYBRID")["direct_file_references"][0]
        self.assertEqual(a["status"],"DIRECT_DEPENDENCY_UNRESOLVED")

    def test_source_identity_self_promotion_rejected(self):
        row=next(r for r in self.lineage["records"] if r["record_id"]=="REF-24")
        row["native_entrypoint_verified"]=True
        with self.assertRaisesRegex(ValueError,"invalid verified first-hop"):
            self.result()

    def test_build_authorization_toggle_rejected(self):
        self.manifest["prohibit_binary_build"]=False
        with self.assertRaisesRegex(ValueError,"authorize scientific work"):
            self.result()


if __name__=="__main__":
    unittest.main()
