"""Build a deterministic, manifest-checked distribution of the Bootstrap source and its Native replay."""
import argparse
import csv
import hashlib
import io
import json
import re
import subprocess
import zipfile
from pathlib import Path

DOCS=("BEFUNGE_KYRGYZ_README.md","SOURCE_LANGUAGE_CATALOG.md","source_language_catalog.tsv",
      "SEMANTIC_STATE_OWNERSHIP.md","BEFUNGE98_SPAGHETTI_ARCHITECTURE_CONTRACT.md","LICENSE")
SCRIPTS=("stage1_bootstrap_archive","stage1_bootstrap_replay","stage1_live_geometry","stage1_live_geometry_audit",
         "stage1_native_diverse_geometry","stage1_native_structural_corpus","stage1_native_structural_properties",
         "stage1_native_adversarial_rank_domains")
RANK_BASELINES=("unrank_bounded_composition","unrank_weaving","unrank_distinct_names")
ENGINE="PyFunge-0.5-rc2.tar.gz"
ENGINE_HASH="e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac"
RUNBOOK=b"""Bootstrap native replay (Linux, Python 2.7 and Python 3.8+, GNU timeout).
From the unpacked distribution, install the bundled original interpreter in an isolated Python 2.7 environment.
  python2 -m pip install --no-index --no-deps PyFunge-0.5-rc2.tar.gz
Keep the environment's pyfunge command on PATH. Create a writable results directory, then run:
  mkdir -p results
  timeout 300s python2 qa/stage1_bootstrap_replay.py results/reference.json
  timeout 360s python2 qa/stage1_live_geometry.py results
  timeout 100s python3 qa/stage1_live_geometry_audit.py results
For the additional structural and ranking corpora:
  timeout 500s python2 qa/stage1_native_structural_corpus.py
  timeout 500s python2 qa/stage1_native_structural_properties.py
  timeout 500s python2 qa/stage1_native_adversarial_rank_domains.py
The seven-field query is src/work_counts.b98. All reference programs belong to this branch.
"""


def need(value,why):
    if not value:
        raise ValueError(why)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def git_blob(data):
    return hashlib.sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest()


def deterministic_write(archive,path,data):
    item=zipfile.ZipInfo(path,(1980,1,1,0,0,0))
    item.create_system=3
    item.external_attr=0o100644<<16
    archive.writestr(item,data,compress_type=zipfile.ZIP_DEFLATED,compresslevel=9)


def git(*args):
    return subprocess.check_output(["git",*args])


def verify(path,expected_commit):
    with zipfile.ZipFile(path) as archive:
        names=archive.namelist()
        need(names==sorted(set(names)) and archive.testzip() is None,"archive integrity")
        manifest=json.loads(archive.read("MANIFEST.json"))
        need(manifest["commit"]==expected_commit and re.fullmatch("[0-9a-f]{40}",expected_commit),"source commit")
        need(set(names)==set(manifest["files"])|{"MANIFEST.json"},"manifest inventory")
        for p,r in manifest["files"].items():
            need(not p.startswith("/") and ".." not in p.split("/"),"unsafe member")
            data=archive.read(p)
            need(len(data)==r["bytes"] and digest(data)==r["sha256"],"damaged member "+p)
            if "git_blob" in r:
                need(git_blob(data)==r["git_blob"],"Git identity "+p)
        need(digest(archive.read(ENGINE))==ENGINE_HASH,"engine identity")
        for prefix,n in [("src/",12),("test/",7),("reference/",47)]:
            need(sum(p.startswith(prefix) and p.endswith(".b98") for p in names)==n,"incomplete "+prefix)
        rows=list(csv.DictReader(io.StringIO(archive.read("source_language_catalog.tsv").decode()),delimiter="\t"))
        for kind,n in [("cutlet",17),("month",47)]:
            entries=[r for r in rows if r["kind"]==kind]
            need([int(r["canonicalIndex"]) for r in entries]==list(range(1,n+1)) and
                 all(r["name"].strip() for r in entries),"frozen "+kind+" catalogue")
        need(len(rows)==64,"unexpected catalogue group")
        need(manifest["files"]["src/work_counts.b98"]["git_blob"]=="7418e1ec5fe88fe5c14b75710dea2d5607527f28",
             "active production source")
    return len(names)


def build(output,engine,commit):
    need(git("rev-parse","HEAD").decode().strip()==commit,"checkout commit")
    paths=["src","reference","test","fixtures",*DOCS,*["qa/"+s+".py" for s in SCRIPTS],
           *["qa/"+s+"_pre_strict_rank_baseline.b98" for s in RANK_BASELINES]]
    data={}
    manifest={}
    for entry in git("ls-tree","-rz",commit,"--",*paths).split(b"\0"):
        if not entry:
            continue
        meta,raw_path=entry.split(b"\t",1)
        mode,kind,sha=meta.decode().split()
        name=raw_path.decode()
        need(mode in ("100644","100755") and kind=="blob","non-regular path "+name)
        payload=Path(name).read_bytes()
        need(git_blob(payload)==sha,"checkout differs from pinned tree: "+name)
        data[name]=payload
        manifest[name]={"git_blob":sha}
    need(all(p in data for p in paths if p not in ("src","reference","test","fixtures")),"replay files incomplete")
    need(engine.is_file() and digest(engine.read_bytes())==ENGINE_HASH,"engine provenance")
    data[ENGINE]=engine.read_bytes()
    data["REPLAY.txt"]=RUNBOOK
    for name,payload in data.items():
        manifest.setdefault(name,{}).update(bytes=len(payload),sha256=digest(payload))
    data["MANIFEST.json"]=(json.dumps({"commit":commit,"files":manifest},indent=2,sort_keys=True)+"\n").encode()
    with zipfile.ZipFile(output,"w") as archive:
        for name in sorted(data):
            deterministic_write(archive,name,data[name])
    print("NATIVE_BOOTSTRAP_SOURCE_ARCHIVE",verify(output,commit),digest(output.read_bytes()))


if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive",type=Path)
    parser.add_argument("--commit",required=True)
    parser.add_argument("--engine",type=Path)
    args=parser.parse_args()
    if args.engine:
        build(args.archive,args.engine,args.commit)
    else:
        print("BOOTSTRAP_SOURCE_ARCHIVE_VERIFIED",verify(args.archive,args.commit))
