#!/usr/bin/env python3
"""Read-only pinned source build-graph audit; NEVER compile, link or execute F(c,t)."""
from __future__ import annotations
import argparse
from collections import defaultdict, Counter
import json
import os
from pathlib import Path
import re
import shlex
from soak_scope_coverage_v127 import canonical, digest, parse_json
from soak_source_census_v129 import GitHubReadOnly
from soak_first_hop_dependencies_v132 import checked_blob

AR="Sargon17-Green/Pastafarian-Calendar"
AC="1a1ea6a89f1f7a2cde9cba1f91aa1625a9284334"
SR="Sargon-17-Green/Pastafarian-Calendar-Seer"
SC="866e9bbff59399310416ae25de1b664f9b6c3124"
MODE=[
 ("SEER-NEXT-YEAR-CACHE","research/seer-next/scripts/build_candidate.sh","research/seer-next/src/seer_next_engine_service.cpp","research/seer-next/build/seer_next_engine_service"),
 ("SEER-NEXT-HYBRID","research/seer-next/scripts/build_hybrid.sh","research/seer-next/src/seer_next_hybrid_engine_service.cpp","research/seer-next/build/seer_next_hybrid_engine_service")]

def ensure(condition,message):
    if not condition: raise ValueError(message)

def validate(m,old):
    ensure(m.get("schema")=="PASTAFARI_SOAK_STATIC_BUILD_GRAPH_V133/1","wrong manifest")
    ensure(m.get("assembly")=={"repository":AR,"commit":AC,"build_script":"build.sh",
       "entrypoint":"src/production/stage54_integration.s","link_target":"build/stage54_final_integration"},"assembly identity changed")
    ensure(m.get("seer")=={"repository":SR,"commit":SC,
       "header":"prototype/src/seer_calendar_core.hpp","include_dir":"prototype/src",
       "modes":[{"record_id":r,"script":s,"root":p,"output":o} for r,s,p,o in MODE]},"Seer identity changed")
    ensure(all(m.get(k) is True for k in ("no_compiler_invocation","no_linker_invocation","no_original_date_calls")) and
       all(m.get(k) is False for k in ("readiness_upgrade_permitted","soak_dispatch_authorized")),"native dispatch forbidden")
    ensure(old.get("schema")=="PASTAFARI_SOAK_FIRST_HOP_DEPENDENCIES_V132/1" and
       old.get("eight_verified_root_files")==8 and old.get("native_date_calls")==0 and
       old.get("soak_dispatch_authorized") is False and old.get("original_full_years_certified")==0,"v132 report invalid")
    rows={x["record_id"]:x for x in old["observations"]}
    ensure(len(rows)==8,"duplicate v132 record")
    for rid,repo,commit,path in [("COPTIC-X64",AR,AC,"src/production/stage54_integration.s")]+[(r,SR,SC,p) for r,s,p,o in MODE]:
        x=rows[rid]
        ensure(x["repository"]==repo and x["commit"]==commit and x["root_path"]==path and
           x["eligible_for_soak"] is False and x["native_build_verified"] is False and
           x["root_content_status"]=="FROZEN_SOURCE_BYTES_RECHECKED","original source receipt missing")
    return rows

class Snapshot:
    def __init__(self,github,repo,commit):
        self.github,self.repo,self.commit=github,repo,commit
        t=github.get("/repos/"+repo+"/git/trees/"+commit+"?recursive=1")
        ensure(t.get("truncated") is False and isinstance(t.get("tree"),list),"truncated tree")
        self.tree={x["path"]:x for x in t["tree"] if x.get("type")=="blob"}
        self.cache={}
    def read(self,p):
        if p not in self.cache:
            ensure(p in self.tree,"missing source "+p)
            content,proof=checked_blob(self.github,self.repo,self.commit,p)
            ensure(proof["git_blob_sha1"]==self.tree[p]["sha"] and proof["bytes"]==self.tree[p]["size"],"tree/blob disagreement "+p)
            self.cache[p]=(content.decode("utf-8"),proof)
        return self.cache[p]

def globals_of(s):
    names=[]
    for line in s.splitlines():
        if line.strip().startswith((".global ",".globl ")):
            names.extend(t for t in re.split("[, ]+",line.split(None,1)[1].strip()) if re.fullmatch("[A-Za-z_.$][A-Za-z0-9_.$]*",t))
    return set(names)

def assembly(g,row):
    build,bhash=g.read("build.sh")
    entry,ehash=g.read("src/production/stage54_integration.s")
    ensure(ehash["source_sha256"]==row["root_sha256"],"Coptic v132/root mismatch")
    mapper={}
    links=[]
    for line in build.splitlines():
        line=line.strip()
        if line.startswith(("as --64 ","ld ")):
            parts=shlex.split(line)
            ensure("-o" in parts,"missing -o")
            output=parts[parts.index("-o")+1]
            if parts[0]=="as": mapper[output]=parts[-1]
            else: links.append((output,parts))
    t=[x for target,x in links if target=="build/stage54_final_integration"]
    ensure(len(t)==1,"ambiguous final link target")
    objs=[p for p in t[0] if p.endswith(".o")]
    ensure(len(objs)>=2 and len(objs)==len(set(objs)) and "build/stage54_integration.o" in objs and all(p in mapper for p in objs),"invalid object inputs")
    providers=defaultdict(list)
    sources=[]
    for obj in objs:
        txt,proof=g.read(mapper[obj])
        for symbol in globals_of(txt): providers[symbol].append(obj)
        sources.append({"object":obj,"source":mapper[obj],"sha256":proof["source_sha256"],"nm_verified":False})
    externs=sorted(set(re.findall(r"(?m)^\s*\.extern\s+([A-Za-z_.$][A-Za-z0-9_.$]*)",entry)))
    observations=[{"symbol":name,"declared_in_objects":sorted(providers.get(name,[])),
        "status":"NO_DECLARED_PROVIDER" if not providers.get(name) else "MULTIPLE_DECLARED_PROVIDERS" if len(providers[name])>1 else "ONE_DECLARED_PROVIDER_NOT_LINKER_VERIFIED",
        "nm_verified":False} for name in externs]
    return {"build_script_sha256":bhash["source_sha256"],"link_target":"build/stage54_final_integration",
       "object_sources":sources,"extern_symbols":observations,
       "extern_status_counts":dict(Counter(a["status"] for a in observations)),
       "link_wrap_flags":[x for x in t[0] if x.startswith("--wrap=")],
       "actual_binary_verified":False}

def seer(g,rows):
    header,h=g.read("prototype/src/seer_calendar_core.hpp")
    ensure(bool(header),"empty shared header")
    result=[]
    core=["prototype/src/seer_year_core.cpp","prototype/src/seer_calendar_core.cpp",
          "prototype/src/seer_weave_portable.cpp","prototype/src/seer_weave_avx2.cpp"]
    for rid,script,root,out in MODE:
        bash,b=g.read(script)
        text,p=g.read(root)
        ensure(p["source_sha256"]==rows[rid]["root_sha256"],"Seer v132/root mismatch")
        ensure('-I"$ROOT/prototype/src"' in bash and '"$ROOT/'+root+'"' in bash and
           '-o "$ROOT/'+out+'"' in bash and '"$CXX"' in bash and '"${COMMON[@]}"' in bash and
           '"${LINK[@]}"' in bash and "-lgmp" in bash,"no pinned compile expression or include flag")
        units=[]
        for name in core:
            ensure('"$ROOT/'+name+'"' in bash,"source TU absent "+name)
            _,proof=g.read(name)
            units.append({"path":name,"sha256":proof["source_sha256"]})
        result.append({"record_id":rid,"build_script":script,"build_sha256":b["source_sha256"],
           "source":root,"root_sha256":p["source_sha256"],"header_sha256":h["source_sha256"],
           "included_directory_in_script":"prototype/src","core_and_alternative_weave_units":units,
           "binary_output_literal":out,"build_command_executed":False})
    return {"services":result,"shared_core_source_sha256":result[0]["core_and_alternative_weave_units"],
      "shared_header":"prototype/src/seer_calendar_core.hpp","actual_compiler_flags_attested":False}

def run(manifest,v132,github):
    rows=validate(manifest,v132)
    return {"schema":"PASTAFARI_SOAK_STATIC_BUILD_GRAPH_REPORT_V133/1",
     "manifest_sha256":digest(manifest),"v132_report_sha256":digest(v132),
     "assembly":assembly(Snapshot(github,AR,AC),rows["COPTIC-X64"]),
     "seer":seer(Snapshot(github,SR,SC),rows),
     "native_builds_executed":0,"native_date_calls":0,
     "independent_algorithms_certified":0,"original_full_years_certified":0,
     "soak_dispatch_authorized":False,"scientific_soak_10000_pass":False}

def main():
    p=argparse.ArgumentParser()
    for name in ("manifest","v132-report","output"):p.add_argument("--"+name,required=True,type=Path)
    a=p.parse_args()
    r=run(parse_json(a.manifest.read_bytes()),parse_json(a.v132_report.read_bytes()),
          GitHubReadOnly(os.environ.get("GITHUB_TOKEN","")))
    with a.output.open("xb") as f:f.write(canonical(r)+b"\n")
    print(json.dumps({"object_count":len(r["assembly"]["object_sources"]),
      "extern_count":len(r["assembly"]["extern_symbols"]),
      "extern_status":r["assembly"]["extern_status_counts"],
      "seer_service_count":len(r["seer"]["services"]),
      "native_date_calls":0},sort_keys=True))
if __name__=="__main__":main()
