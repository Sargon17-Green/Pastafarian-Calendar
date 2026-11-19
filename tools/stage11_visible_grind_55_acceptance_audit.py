#!/usr/bin/env python3
"""Independent audit of the 55-cell grind extension and reference witness."""

import argparse
import hashlib
import json
import math
import re
import subprocess
import zipfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
PROJECT="PC-BRANCH-FALSE-ARABIC"
RUN="44480074938"
WORKFLOW="2f0573f40456004b9903429145cb6c7791686507"
SOURCE="7f52bc68f33dd732e6d2605ad40cb0bd75bf74d3"
RUNTIME="eb3135565a8670cced3f6bbca4dbf7b014c45634"
COMBINED="c74344f0bd206604c37c0be7477d8a504c3fafeeb5882a95024f9c974b5618bb"
FIXTURE="4eb957182723103913e405a627464631a687847225d3d5b9dc64ba93db13fb6a"
FINAL="STAGE11_PATCH_55_RESULTS_110_INPUTS_VERIFIED"
NEGATIVE=(("grind_0","E_VISIBLE_GRIND"),("grind_12","E_VISIBLE_GRIND"),
          ("column_0","E_VISIBLE_COLUMN"),("column_6","E_VISIBLE_COLUMN"))


def check(value,reason):
    if not value:
        raise ValueError(reason)


def sha(blob):
    return hashlib.sha256(blob).hexdigest()


def git(revision,path):
    return subprocess.check_output(["git","show",f"{revision}:{path}"],cwd=ROOT)


def independent_cases():
    primes=[]
    for candidate in range(3,48):
        if all(candidate%divisor for divisor in range(2,math.isqrt(candidate)+1)):
            primes.append(candidate)
    check(len(primes)==14 and primes[-1]==47,"prime witness")
    cases=[]
    for grind in range(1,12):
        for column in range(1,6):
            expected=(grind-1)%5+1 if column==5 else primes[grind+column-2]
            cases.append({"grind":grind,"column":column,"expected":expected,
                          "label":f"STAGE11_PATCH_CASE_{grind:02d}_{column}_OK"})
    check(len(cases)==55 and [x["expected"] for x in cases[-5:]]==[37,41,43,47,1],
          "eleventh row")
    return cases


def verify(path,expected_sha,overrides=None):
    check(re.fullmatch(r"[0-9a-f]{64}",expected_sha) is not None,"SHA syntax")
    check(sha(path.read_bytes())==expected_sha,"archive SHA")
    with zipfile.ZipFile(path) as z:
        check(z.testzip() is None,"archive CRC")

        def raw(name):
            return overrides[name] if overrides and name in overrides else z.read(name)

        def read(name):
            return raw(name).decode("utf-8")

        receipt=json.loads(read("evidence.json"))
        oracle=json.loads(read("oracle.json"))
        fields={"project_id":PROJECT,"github_run_id":RUN,"github_sha":WORKFLOW,
                "source_pin":SOURCE,"source_observed":SOURCE,
                "runtime_pin":RUNTIME,"runtime_observed":RUNTIME,
                "combined_sha256":COMBINED,"fixture_sha256":FIXTURE}
        for field,value in fields.items():
            check(receipt.get(field)==value,f"receipt {field}")
        check(receipt.get("stage11_expansion_native_verified") is True and
              receipt.get("stage14_full_acceptance") is False,"receipt boundary")
        check(read("source_observed.txt").strip()==SOURCE and
              read("runtime_observed.txt").strip()==RUNTIME,"observed commits")
        workflow=".github/workflows/false-arabic-stage11-native-grind-55.yml"
        runner="tools/stage11_visible_grind_55_ci.py"
        check(git(WORKFLOW,workflow)==(ROOT/workflow).read_bytes() and
              git(WORKFLOW,runner)==(ROOT/runner).read_bytes(),"workflow/runner bytes")
        source_paths=("src/bigint.false","src/monster_bootstrap.false",
                      "test/stage11_visible_grind_55.false")
        pinned=[git(SOURCE,p) for p in source_paths]
        combined=b"\n".join(pinned)+b"\n"
        check(sha(pinned[-1])==FIXTURE and sha(combined)==COMBINED and
              raw("stage11_visible_grind_55_exact.false")==combined,"source bytes")
        reference=pinned[0]+b"\n"+git(SOURCE,"test/normative_reference.false")+git(SOURCE,"test/stage11_row11_reference_probe.false")
        check(raw("stage11_row11_reference_exact.false")==reference and
              read("reference.exit_code.txt").strip()=="0" and
              read("reference.stdout.txt").strip()=="REF_ROW11_COL4_47_COL5_1_OK" and
              raw("reference.stderr.txt")==b"","original reference witness")
        cases=independent_cases()
        check(oracle.get("project_id")==PROJECT and oracle.get("scope")=="STAGE11_PATCH_FOR_STAGE14"
              and oracle.get("native_evidence") is False and
              oracle.get("fixture_sha256")==FIXTURE and
              (oracle.get("result_assertions"),oracle.get("input_assertions"))==(55,110)
              and oracle.get("cases")==cases,"independent oracle")
        expected_negative=[["grind_0",0,1,"E_VISIBLE_GRIND"],
                           ["grind_12",12,1,"E_VISIBLE_GRIND"],
                           ["column_0",1,0,"E_VISIBLE_COLUMN"],
                           ["column_6",1,6,"E_VISIBLE_COLUMN"]]
        check(oracle.get("invalid_indices")==expected_negative,"invalid metadata")
        output=read("native.stdout.txt")
        labels=[case["label"] for case in cases]
        check(re.findall(r"STAGE11_PATCH_CASE_\d{2}_[1-5]_OK",output)==labels
              and output.count(FINAL)==1 and output.rstrip().endswith(FINAL)
              and "STAGE11_PATCH_FAILURE" not in output,"Native labels")
        check(read("native.exit_code.txt").strip()=="0" and
              raw("native.stderr.txt")==b"","Native exit")
        check(read("mutant.exit_code.txt").strip()=="1" and
              "STAGE11_PATCH_FAILURE" in read("mutant.stdout.txt") and
              FINAL not in read("mutant.stdout.txt"),"mutant rejection")
        for name,marker in NEGATIVE:
            out=read(f"{name}.stdout.txt")
            check(read(f"{name}.exit_code.txt").strip()=="1" and
                  marker in out and FINAL not in out,f"{name} rejection")
        check(read("compiler_exit_code.txt").strip()=="0" and
              read("preflight.txt").strip()=="ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS",
              "compiler/preflight")
        check(receipt.get("case_labels")==labels and
              (receipt.get("result_assertions"),receipt.get("input_assertions"),
               receipt.get("native_exit_code"),receipt.get("reference_exit_code"))
              ==(55,110,0,0) and receipt.get("negative_exit_codes")==[1]*5,
              "receipt counts")
    return {"project_id":PROJECT,"scope":"STAGE11_PATCH_FOR_STAGE14",
            "status":"ACCEPTED","run_id":RUN,"workflow_sha":WORKFLOW,
            "source_sha":SOURCE,"runtime_sha":RUNTIME,"archive_sha256":expected_sha,
            "combined_sha256":COMBINED,"fixture_sha256":FIXTURE,
            "result_assertions":55,"input_assertions":110,
            "negative_controls":["mutant"]+[name for name,_ in NEGATIVE],
            "stage14_full_acceptance":False}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive",type=Path)
    parser.add_argument("--sha256",required=True)
    parser.add_argument("--output",type=Path)
    args=parser.parse_args()
    report=verify(args.archive,args.sha256)
    with zipfile.ZipFile(args.archive) as z:
        damaged=json.loads(z.read("oracle.json"))
    damaged["cases"][-2]["expected"]=99
    try:
        verify(args.archive,args.sha256,
               {"oracle.json":json.dumps(damaged).encode("utf-8")})
    except ValueError:
        report["audit_negative_control"]="REJECTED_CORRUPTED_ROW11_VALUE"
    else:
        raise SystemExit("AUDIT_NEGATIVE_CONTROL_FAILED")
    output=json.dumps(report,indent=2,sort_keys=True)+"\n"
    if args.output:
        args.output.write_text(output)
    print(output,end="")


if __name__=="__main__":
    main()
