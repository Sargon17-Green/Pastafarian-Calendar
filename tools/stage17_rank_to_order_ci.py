#!/usr/bin/env python3
"""Stage17 exact-source Native diagnostic gate; a completed audit is still required for acceptance."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import stage17_rank_to_order_fixture as fixtures

OUT = Path("evidence/stage17_native")
SOURCE = os.environ["SOURCE_PIN"]
RUNTIME = os.environ["RUNTIME_PIN"]
INPUTS = ("src/bigint.false", "src/monster_bootstrap.false",
          "test/stage17_rank_to_order_16.false")
OTHER = ("tools/stage17_rank_to_order_fixture.py",
         "tools/stage17_rank_to_order_design_oracle.py",
         "evidence/stage17_rank_to_order_design_oracle_2026-11-20.json")
def digest(x):
    return hashlib.sha256(x).hexdigest()
def locked(path):
    expected = subprocess.check_output(["git","show",f"{SOURCE}:{path}"])
    actual = Path(path).read_bytes()
    assert actual == expected, ("SOURCE_DRIFT",path)
    return actual
def run(label,program,seconds=90):
    p=OUT/(label+".false")
    p.write_bytes(program)
    try:
        proc=subprocess.run(["upstream/false_int","-e",str(p)],
                            capture_output=True,timeout=seconds)
        code,stdout,stderr=proc.returncode,proc.stdout,proc.stderr
    except subprocess.TimeoutExpired as ex:
        code,stdout,stderr=124,ex.stdout or b"",ex.stderr or b""
    (OUT/(label+".exit_code.txt")).write_text(str(code)+"\n")
    (OUT/(label+".stdout.txt")).write_bytes(stdout)
    (OUT/(label+".stderr.txt")).write_bytes(stderr)
    return code,stdout.decode("utf-8","replace"),stderr
def main():
    OUT.mkdir(parents=True,exist_ok=True)
    assert (OUT/"source_observed.txt").read_text().strip()==SOURCE
    assert (OUT/"runtime_observed.txt").read_text().strip()==RUNTIME
    assert (OUT/"compiler_exit_code.txt").read_text().strip()=="0"
    assert (OUT/"preflight.txt").read_text().strip()=="ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS"
    blobs={p:locked(p) for p in INPUTS+OTHER}
    generated,cases=fixtures.build()
    assert generated.encode("utf-8")==blobs[INPUTS[-1]], "FIXTURE_NOT_REPRODUCIBLE"
    assert len(cases)==16 and sum(int(c["replay"]) for c in cases)==2
    assert generated.count('=~["STAGE17_ORDER_')==144
    assert generated.count('0=["STAGE17_ORDER_')==16
    assert tuple(fixtures.INVALID)==(-1,0,721,722)
    prefix=b"\n".join(blobs[p] for p in INPUTS[:2])+b"\n"
    positive=run("native",prefix+blobs[INPUTS[-1]]+b"\n",120)
    negative={r:run("invalid_"+str(r).replace("-","minus"),prefix+fixtures.invalid(r).encode(),25)
              for r in fixtures.INVALID}
    mutated,_=fixtures.build(mutant=True)
    mutant=run("mutant",prefix+mutated.encode(),25)
    labels=re.findall(r"STAGE17_ORDER_\d{2}_OK",positive[1])
    expected=[c["label"] for c in cases]
    final=fixtures.FINAL
    ok=(positive[0]==0 and positive[2]==b"" and labels==expected
        and positive[1].count(final)==1 and positive[1].rstrip().endswith(final)
        and not re.findall(r"STAGE17_ORDER_[A-Z0-9_]+_FAIL",positive[1])
        and mutant[0]==1 and "STAGE17_ORDER_00_VALUE_1_FAIL" in mutant[1]
        and final not in mutant[1]
        and all(code==1 and text=="E_BALL_RANK" and final not in text
                for code,text,_ in negative.values()))
    result={"project_id":os.environ["PROJECT_ID"],"stage":17,
        "github_run_id":os.getenv("GITHUB_RUN_ID"),"github_sha":os.getenv("GITHUB_SHA"),
        "source_pin":SOURCE,"runtime_pin":RUNTIME,
        "source_sha256":{p:digest(v) for p,v in blobs.items()},
        "fixture_sha256":digest(blobs[INPUTS[-1]]),
        "expected_labels":expected,"actual_labels":labels,
        "native_exit_code":positive[0],
        "positive_embedded_assertions":160,
        "negative_exit_codes":{str(k):v[0] for k,v in negative.items()},
        "mutant_exit_code":mutant[0],
        "source_pinned_native_gate_passed":ok,
        "stage17_acceptance_audited":False,
        "physical_pointer_safety_assessed":False}
    (OUT/"evidence.json").write_text(json.dumps(result,sort_keys=True,indent=2)+"\n")
    print(json.dumps(result,sort_keys=True))
    if not ok:
        sys.exit("STAGE17_NATIVE_GATE_FAILED_OR_NOT_VERIFIED")
if __name__=="__main__":
    main()
