#!/usr/bin/env python3
"""Pinned Native gate for the eleven-row grind expansion needed by Stage 14."""

import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys

import stage11_visible_grind_55_oracle as oracle_module

E=Path("evidence")
SOURCE=os.environ["SOURCE_PIN"]
RUNTIME=os.environ["RUNTIME_PIN"]
COMBINED=os.environ["COMBINED_SHA256"]
FIXTURE=os.environ["FIXTURE_SHA256"]
FINAL=oracle_module.FINAL


def sha(blob):
    return hashlib.sha256(blob).hexdigest()


def locked(path):
    blob=subprocess.check_output(["git","show",f"{SOURCE}:{path}"])
    assert blob==Path(path).read_bytes(),("source drift",path)
    return blob


def run(label,path,seconds=20):
    try:
        p=subprocess.run(["upstream/false_int","-e",str(path)],
                         capture_output=True,timeout=seconds)
        code,out,err=p.returncode,p.stdout,p.stderr
    except subprocess.TimeoutExpired as exc:
        code,out,err=124,exc.stdout or b"",exc.stderr or b""
    (E/f"{label}.exit_code.txt").write_text(str(code)+"\n")
    (E/f"{label}.stdout.txt").write_bytes(out)
    (E/f"{label}.stderr.txt").write_bytes(err)
    return code,out.decode("utf-8"),err


def main():
    assert (E/"source_observed.txt").read_text().strip()==SOURCE
    assert (E/"runtime_observed.txt").read_text().strip()==RUNTIME
    assert (E/"compiler_exit_code.txt").read_text().strip()=="0"
    assert (E/"preflight.txt").read_text().strip()=="ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS"
    paths=("src/bigint.false","src/monster_bootstrap.false",
           "test/stage11_visible_grind_55.false")
    files=[locked(p) for p in paths]
    locked("tools/stage11_visible_grind_55_oracle.py")
    normative=locked("test/normative_reference.false")
    probe=locked("test/stage11_row11_reference_probe.false")
    assert sha(files[-1])==FIXTURE
    combined=b"\n".join(files)+b"\n"
    assert sha(combined)==COMBINED
    exact=E/"stage11_visible_grind_55_exact.false"
    exact.write_bytes(combined)
    reference=E/"stage11_row11_reference_exact.false"
    reference.write_bytes(files[0]+b"\n"+normative+probe)
    program,cases=oracle_module.build()
    assert program.encode()==files[-1]
    oracle={"project_id":os.environ["PROJECT_ID"],"scope":"STAGE11_PATCH_FOR_STAGE14",
            "native_evidence":False,"result_assertions":55,"input_assertions":110,
            "invalid_indices":[list(x) for x in oracle_module.NEGATIVE],
            "fixture_sha256":FIXTURE,"cases":cases}
    (E/"oracle.json").write_text(json.dumps(oracle,indent=2,sort_keys=True)+"\n")
    needle=b"v;3=e;!"
    assert files[-1].count(needle)>0
    prefix=b"\n".join(files[:2])+b"\n"
    mutant=E/"mutant.false"
    mutant.write_bytes(prefix+files[-1].replace(needle,b"v;4=e;!",1)+b"\n")
    negatives={}
    for name,grind,column,marker in oracle_module.NEGATIVE:
        path=E/f"{name}.false"
        path.write_bytes(prefix+oracle_module.invalid(grind,column).encode())
        negatives[name]=(path,marker)
    positive=run("native",exact)
    reference_result=run("reference",reference)
    mutant_result=run("mutant",mutant)
    invalid={name:run(name,path,10) for name,(path,_) in negatives.items()}
    labels=re.findall(r"STAGE11_PATCH_CASE_\d{2}_[1-5]_OK",positive[1])
    expected=[c["label"] for c in cases]
    good=(positive[0]==0 and positive[2]==b"" and labels==expected
          and positive[1].count(FINAL)==1 and positive[1].rstrip().endswith(FINAL)
          and reference_result[0]==0 and reference_result[2]==b""
          and reference_result[1].strip()=="REF_ROW11_COL4_47_COL5_1_OK"
          and mutant_result[0]==1 and "STAGE11_PATCH_FAILURE" in mutant_result[1]
          and FINAL not in mutant_result[1]
          and all(invalid[name][0]==1 and marker in invalid[name][1]
                  and FINAL not in invalid[name][1]
                  for name,(_,marker) in negatives.items()))
    receipt={"project_id":os.environ["PROJECT_ID"],
             "github_run_id":os.environ.get("GITHUB_RUN_ID"),
             "github_sha":os.environ.get("GITHUB_SHA"),
             "source_pin":SOURCE,"source_observed":SOURCE,
             "runtime_pin":RUNTIME,"runtime_observed":RUNTIME,
             "combined_sha256":COMBINED,"fixture_sha256":FIXTURE,
             "case_labels":labels,"result_assertions":55,"input_assertions":110,
             "native_exit_code":positive[0],"reference_exit_code":reference_result[0],
             "negative_exit_codes":[mutant_result[0]]+
                 [invalid[name][0] for name,*_ in oracle_module.NEGATIVE],
             "stage11_expansion_native_verified":good,
             "stage14_full_acceptance":False}
    (E/"evidence.json").write_text(json.dumps(receipt,indent=2,sort_keys=True)+"\n")
    print(json.dumps(receipt,sort_keys=True))
    if not good:
        sys.exit("STAGE11_EXPANSION_NOT_VERIFIED")


if __name__=="__main__":
    main()
