"""Frozen build script provenance tests; synthetic source bytes, no compilers."""
import base64
import copy
import hashlib
import json
from pathlib import Path
import sys
import unittest
from urllib.parse import unquote
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"runner"))
from soak_source_census_v129 import git_blob_sha1
from soak_static_build_graph_v133 import run,validate,assembly,Snapshot,AR,AC,SR,SC,MODE

def proof(body):
    return {"source_sha256":hashlib.sha256(body).hexdigest(),
            "git_blob_sha1":git_blob_sha1(body),
            "bytes":len(body)}

def fixture():
    repo=Path(__file__).resolve().parents[1]
    manifest=json.loads((repo/"control"/"static_build_graph_v133.json").read_text())
    assembly_src=b'.extern arena_alloc\n.extern catalog_get_month\n.extern missing_link_symbol\n.global calendarDateSpaghetti\n'
    build=b'''#!/bin/bash
as --64 -o build/arena.o src/runtime/arena.s
as --64 -o build/stage54_integration.o src/production/stage54_integration.s
as --64 -o build/catalog.o src/catalog/source_language_catalog.s
ld --wrap=stage56SauceRawBowlSumCorrective -o build/stage54_final_integration build/arena.o build/stage54_integration.o build/catalog.o
'''
    records=[
      (AR,AC,"build.sh",build),
      (AR,AC,"src/production/stage54_integration.s",assembly_src),
      (AR,AC,"src/runtime/arena.s",b'.global arena_alloc\narena_alloc:\n ret\n'),
      (AR,AC,"src/catalog/source_language_catalog.s",b'.global catalog_get_month\ncatalog_get_month:\n ret\n')
    ]
    header=b"#pragma once\n"
    records.append((SR,SC,"prototype/src/seer_calendar_core.hpp",header))
    for path in ["seer_year_core.cpp","seer_calendar_core.cpp",
                 "seer_weave_portable.cpp","seer_weave_avx2.cpp"]:
        records.append((SR,SC,"prototype/src/"+path,
                        ("// synthetic "+path+"\n").encode()))
    for rid,script,root,out in MODE:
        snippet='''#!/bin/bash
COMMON=(-O3 -DNDEBUG -std=c++20 -fopenmp -pthread -I"$ROOT/prototype/src")
WEAVE="$ROOT/prototype/src/seer_weave_portable.cpp"
WEAVE="$ROOT/prototype/src/seer_weave_avx2.cpp"
"$CXX" "${COMMON[@]}" "$ROOT/prototype/src/seer_year_core.cpp" "$ROOT/prototype/src/seer_calendar_core.cpp" "$WEAVE" "$ROOT/'''+root+'''" "${LINK[@]}" -lgmp -o "$ROOT/'''+out+'''"
'''
        records.append((SR,SC,script,snippet.encode()))
        records.append((SR,SC,root,("// "+rid+"\n").encode()))
    data={(r,c,p):body for r,c,p,body in records}
    receipts=[]
    for rid,repo_,commit,path in [
       ("COPTIC-X64",AR,AC,"src/production/stage54_integration.s")]+[
       (rid,SR,SC,root) for rid,_,root,_ in MODE]:
        h=proof(data[repo_,commit,path])
        receipts.append({"record_id":rid,"repository":repo_,"commit":commit,
          "root_path":path,"root_sha256":h["source_sha256"],
          "root_git_blob_sha1":h["git_blob_sha1"],
          "root_content_status":"FROZEN_SOURCE_BYTES_RECHECKED",
          "eligible_for_soak":False,"native_build_verified":False})
    for i in range(5):
        receipts.append({"record_id":"FILLER"+str(i)})
    v132={"schema":"PASTAFARI_SOAK_FIRST_HOP_DEPENDENCIES_V132/1",
          "eight_verified_root_files":8,"observations":receipts,
          "native_date_calls":0,"original_full_years_certified":0,
          "soak_dispatch_authorized":False}
    return manifest,v132,data

class FakeGit:
    def __init__(self,files):
        self.files=files
        self.missing=None
        self.wrong_sha=None
        self.truncated=False
    def get(self,url):
        if "/git/trees/" in url:
            prefix,rest=url.split("/git/trees/")
            repo=prefix.removeprefix("/repos/")
            commit=rest.split("?")[0]
            return {"truncated":self.truncated,"tree":[
                {"path":p,"type":"blob",
                 "sha":self.wrong_sha or git_blob_sha1(body),"size":len(body)}
                for (r,c,p),body in self.files.items() if r==repo and c==commit and p!=self.missing]}
        if "/contents/" in url:
            prefix,rest=url.split("/contents/")
            repo=prefix.removeprefix("/repos/")
            path,commit=rest.split("?ref=")
            path=unquote(path)
            body=self.files[repo,commit,path]
            return {"type":"file","encoding":"base64",
                    "size":len(body),"sha":git_blob_sha1(body),
                    "content":base64.b64encode(body).decode()}
        raise AssertionError("unrecognized synthetic URL "+url)

class BuildGraphTests(unittest.TestCase):
    def setUp(self):
        self.m,self.v,self.data=fixture()
        self.gh=FakeGit(self.data)
    def output(self):
        return run(self.m,self.v,self.gh)
    def put(self,repo,commit,path,body):
        self.data[repo,commit,path]=body

    def test_static_graph_and_zero_native_invocations(self):
        report=self.output()
        self.assertEqual(len(report["assembly"]["object_sources"]),3)
        self.assertEqual(len(report["assembly"]["extern_symbols"]),3)
        self.assertEqual(report["native_builds_executed"],0)
        self.assertEqual(report["original_full_years_certified"],0)
        self.assertFalse(report["soak_dispatch_authorized"])
        self.assertEqual(len(report["seer"]["services"]),2)

    def test_two_symbols_resolve_declaration_one_remains_open(self):
        a=self.output()["assembly"]
        self.assertEqual(a["extern_status_counts"],
                         {"ONE_DECLARED_PROVIDER_NOT_LINKER_VERIFIED":2,
                          "NO_DECLARED_PROVIDER":1})
        self.assertTrue(all(not x["nm_verified"] for x in a["extern_symbols"]))

    def test_same_seer_core_sources_but_no_independence(self):
        v=self.output()["seer"]
        self.assertEqual(len(v["shared_core_source_sha256"]),4)
        self.assertTrue(all(not s["build_command_executed"] for s in v["services"]))

    def test_seer_include_flag_absent_rejected(self):
        script=MODE[0][1]
        raw=self.data[SR,SC,script].decode()
        self.put(SR,SC,script,raw.replace('-I"$ROOT/prototype/src"','-I"$ROOT/surrogate"').encode())
        with self.assertRaisesRegex(ValueError,"no pinned compile"):
            self.output()

    def test_seer_header_missing_fails(self):
        self.gh.missing="prototype/src/seer_calendar_core.hpp"
        with self.assertRaisesRegex(ValueError,"missing source"):
            self.output()

    def test_wrong_Git_tree_blob_fails(self):
        self.gh.wrong_sha="a"*40
        with self.assertRaisesRegex(ValueError,"tree/blob disagreement"):
            self.output()

    def test_missing_assembler_object_source_fails(self):
        self.gh.missing="src/runtime/arena.s"
        with self.assertRaisesRegex(ValueError,"missing source"):
            self.output()

    def test_real_shell_multiline_link_inputs_preserved(self):
        src=self.data[AR,AC,"build.sh"]
        self.put(AR,AC,"build.sh",src.replace(
            b"build/arena.o build/stage54_integration.o",
            b"build/arena.o \\\n  build/stage54_integration.o"))
        result=self.output()
        self.assertEqual(len(result["assembly"]["object_sources"]),3)

    def test_link_target_missing_fails(self):
        raw=self.data[AR,AC,"build.sh"]
        self.put(AR,AC,"build.sh",raw.replace(b"build/stage54_final_integration",b"build/not-final"))
        with self.assertRaisesRegex(ValueError,"ambiguous final link"):
            self.output()

    def test_link_object_without_as_map_fails(self):
        raw=self.data[AR,AC,"build.sh"]
        self.put(AR,AC,"build.sh",raw.replace(
            b"build/stage54_integration.o build/catalog.o",
            b"build/stage54_integration.o build/ghost.o build/catalog.o"))
        with self.assertRaisesRegex(ValueError,"invalid object"):
            self.output()

    def test_unexpected_pinned_commit_fails(self):
        self.m["assembly"]["commit"]="0"*40
        with self.assertRaisesRegex(ValueError,"identity changed"):
            self.output()

    def test_no_dispatch_flag_can_not_be_changed(self):
        self.m["soak_dispatch_authorized"]=True
        with self.assertRaisesRegex(ValueError,"native dispatch forbidden"):
            self.output()

    def test_v132_original_source_hash_must_match(self):
        self.v["observations"][0]["root_sha256"]="0"*64
        with self.assertRaisesRegex(ValueError,"Coptic v132/root mismatch"):
            self.output()

    def test_seer_root_alias_cannot_be_substituted(self):
        self.v["observations"][1]["root_path"]="research/other/wrapper.cpp"
        with self.assertRaisesRegex(ValueError,"source receipt missing"):
            self.output()

    def test_tree_truncation_rejected(self):
        self.gh.truncated=True
        with self.assertRaisesRegex(ValueError,"truncated tree"):
            self.output()

if __name__=="__main__":
    unittest.main()
