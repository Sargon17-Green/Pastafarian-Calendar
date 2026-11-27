#!/usr/bin/env python3
"""Stage23 first full-path measurement, not a stage acceptance gate."""
import hashlib
import json
import os
from pathlib import Path
import resource
import subprocess
import time

E = Path("evidence/stage23_measure")
RT = "eb3135565a8670cced3f6bbca4dbf7b014c45634"
LIMIT = 2 * 1024**3
FILES = ("src/bigint.false","src/monster_bootstrap.false","test/normative_reference.false",
         "tools/preintegration_op57_design_oracle.mjs","tools/stage23_measure.py",
         ".github/workflows/false-arabic-stage23-measure.yml","RUN_STAGE23.md")
def sha(b):
    return hashlib.sha256(b).hexdigest()
def limbs(n):
    if n == 0:
        return [0,1,0]
    sign = -1 if n < 0 else 1
    v = abs(n)
    digits = []
    while v:
        v,digit = divmod(v,512)
        digits.append(digit)
    return [sign,len(digits),*digits]
def lit(n):
    return str(abs(n)) + ("_" if n < 0 else "")
def fixture(row):
    cells = []
    def alloc(values):
        p = len(cells)
        cells.extend(values)
        return p
    c,t = map(int,row["pair"])
    handles = [alloc(limbs(c)),alloc(limbs(t))]
    arg = alloc(handles)
    lines = ["z;x:"]
    for i,v in enumerate(cells):
        lines.append(("x;"+lit(v)+"+" if i>=arg else lit(v))+"a;!")
    lines += [f"x;{arg}+b:", "z;y:", "k;w:", "b;40h;!!o:"]
    # All registers except z must have been restored; b/x/y/w are preserved.
    checks = 0
    def eq(expr,want,tag):
        nonlocal checks
        expected = lit(want) if isinstance(want,int) else want
        lines.append(expr+"r:r;"+expected+'-0=~["'+tag+'"0 0/]?')
        checks += 1
    def neq(expr,want,tag):
        nonlocal checks
        lines.append(expr+"r:r;"+want+'-0=["'+tag+'"0 0/]?')
        checks += 1
    eq("k;","w;","S23_FRAME")
    eq("b;",f"x;{arg}+","S23_ARG_REGISTER")
    eq("o;g;!",2,"S23_OUTER_LENGTH")
    # Each returned record is new after the pre-call heap boundary.
    lines.append('o;y;<["S23_OUTER_FRESH"0 0/]?')
    lines.append("o;1+g;!v:o;2+g;!u:")
    eq("v;g;!",6,"S23_BOWLS_LENGTH")
    eq("u;g;!",6,"S23_ORDER_LENGTH")
    neq("v;","u;","S23_TABLE_ALIAS")
    for j,value in enumerate(map(int,row["finalBowls"]),1):
        lines.append(f"v;{j}+g;!t:")
        lines.append(f't;y;<["S23_BOWL_{j}_FRESH"0 0/]?')
        for p in range(1,j):
            neq(f"v;{p}+g;!","t;",f"S23_BOWL_{j}_ALIAS_{p}")
        for i,want in enumerate(limbs(value)):
            eq(f"t;{i}+g;!",want,f"S23_BOWL_{j}_CELL_{i}")
    for j,want in enumerate(row["returnOrder"],1):
        eq(f"u;{j}+g;!",want,f"S23_ORDER_{j}")
    for i,value in enumerate(cells):
        expected = f"x;{value}+" if i>=arg else value
        eq(f"x;{i}+g;!",expected,f"S23_INPUT_{i}")
    lines += ['"S23_HEAP_CELLS="z;.10,','"S23_FULL_PATH_OK"10,',
              "[z;0>][%z;1-z:]#"]
    return "\n".join(lines)+"\n",checks
def limits():
    resource.setrlimit(resource.RLIMIT_AS,(LIMIT,LIMIT))
    resource.setrlimit(resource.RLIMIT_CORE,(0,0))
def main():
    E.mkdir(parents=True,exist_ok=True)
    pin = os.environ["SOURCE_PIN"]
    assert subprocess.check_output(["git","rev-parse","HEAD"],text=True).strip()==pin
    assert os.environ["RUNTIME_PIN"]==RT
    assert (E/"runtime_observed.txt").read_text().strip()==RT
    source_hashes={}
    for f in FILES:
        data=Path(f).read_bytes()
        assert data==subprocess.check_output(["git","show",pin+":"+f])
        dest=E/"source"/f
        dest.parent.mkdir(parents=True,exist_ok=True)
        dest.write_bytes(data)
        source_hashes[f]=sha(data)
    raw=subprocess.check_output(["node","tools/preintegration_op57_design_oracle.mjs"],timeout=30)
    (E/"oracle.json").write_bytes(raw)
    oracle=json.loads(raw)
    row=oracle["records"][0]
    assert row["pair"]==["-15055671","-15055671"] and row["counts"]==["1","1","1","2","2"]
    body,checks=fixture(row)
    program=Path("src/bigint.false").read_bytes()+b"\n"+Path("src/monster_bootstrap.false").read_bytes()+b"\n"+body.encode()
    path=E/"epoch_equal.false"
    path.write_bytes(program)
    started=time.monotonic()
    try:
        p=subprocess.run(["upstream/false_int","-e",str(path)],capture_output=True,
                         timeout=600,preexec_fn=limits,check=False)
        code,out,err=p.returncode,p.stdout,p.stderr
    except subprocess.TimeoutExpired as ex:
        code,out,err=124,ex.stdout or b"",ex.stderr or b""
    elapsed=time.monotonic()-started
    (E/"stdout.txt").write_bytes(out)
    (E/"stderr.txt").write_bytes(err)
    (E/"exit_code.txt").write_text(str(code)+"\n")
    lines=out.decode("utf-8",errors="replace").splitlines()
    passed=(code==0 and not err and len(lines)==2 and lines[0].startswith("S23_HEAP_CELLS=")
            and lines[0].split("=")[1].strip().isdigit() and lines[1]=="S23_FULL_PATH_OK")
    report={"project_id":"PC-BRANCH-FALSE-ARABIC","source_pin":pin,"runtime_pin":RT,
            "source_sha256":source_hashes,"pair":row["pair"],"expected":row,
            "assertions":checks,"program_sha256":sha(program),"stdout_sha256":sha(out),
            "stderr_sha256":sha(err),"exit_code":code,"elapsed_seconds":round(elapsed,3),
            "peak_child_rss_kib_cumulative":resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss,
            "address_space_limit_bytes":LIMIT,"timeout_seconds":600,
            "measurement_pass":passed,"stage_acceptance":False,
            "intermediate_differential":False,"boundary_and_replay_tested":False}
    (E/"receipt.json").write_text(json.dumps(report,indent=2)+"\n")
    print(json.dumps({k:report[k] for k in ("exit_code","elapsed_seconds","peak_child_rss_kib_cumulative","assertions","measurement_pass","stage_acceptance")}))
    if not passed:
        raise SystemExit(1)
if __name__=="__main__":
    main()
