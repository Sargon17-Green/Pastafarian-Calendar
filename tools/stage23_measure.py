#!/usr/bin/env python3
"""Stage23 first full-path measurement, not a stage acceptance gate."""
import hashlib
import json
import os
from pathlib import Path
import resource
import re
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
# 46042890131: exact source ran to final success marker, exit 0, stderr empty,
# 590.761s, cumulative child RSS 1834064 KiB; strict measurement failed.
# ZIP 15220814079 sha256 59a39a31ace1c437623c2e501d41cecedcae5f409244c27de533847c96a1f95d.
# Archived stdout b'\\n\\nS23_HEAP_CELLS=S23_FULL_PATH_OK': original runtime
# uses putwchar for strings and printf for numbers on the same stream.
# Local C reproduction: printf returned -1 after putwchar. No heap value inferred.
# All seven source blobs, 21 CRC entries, ten receipt hashes, exact fixture and
# byte-identical design oracle independently verified; separate Python permutation
# enumeration matched epoch expected intermediate and final values.
# Only QA framing changes; no new Native PASS or stage acceptance.
def heap_bits(expr):
    # Emit exclusively through FALSE string literals (wide output), LSB first.
    return (expr+'r:"S23_HEAP_BITS_LSB="'
            'r;0=["0"]?'
            '[r;0>][r;2/s:r;s;2*-0=["0"]?'
            'r;s;2*-1=["1"]?s;r:]#'
            '";S23_FULL_PATH_OK"')
def parse_heap(out):
    m=re.fullmatch(rb"S23_HEAP_BITS_LSB=([01]{1,31});S23_FULL_PATH_OK",out)
    if not m:
        return None
    bits=m.group(1)
    if len(bits)>1 and bits[-1:]!=b"1":
        return None
    return int(bits[::-1],2)
def framing_preflight():
    for n in (0,1,2,511,512,65537,2147483647):
        path=E/f"framing_{n}.false"
        path.write_text(heap_bits(str(n))+"\n")
        p=subprocess.run(["upstream/false_int","-e",str(path)],
                         capture_output=True,timeout=15,preexec_fn=limits,check=False)
        (E/f"framing_{n}.stdout").write_bytes(p.stdout)
        (E/f"framing_{n}.stderr").write_bytes(p.stderr)
        (E/f"framing_{n}.exit").write_text(str(p.returncode)+"\n")
        assert p.returncode==0 and not p.stderr and parse_heap(p.stdout)==n, (n,p.stdout,p.stderr,p.returncode)
    for bad in (b"", b"S23_HEAP_CELLS=S23_FULL_PATH_OK",b"S23_HEAP_BITS_LSB=10;S23_FULL_PATH_OK",
                b"S23_HEAP_BITS_LSB=1;S23_FULL_PATH_OKextra",b"S23_HEAP_BITS_LSB=2;S23_FULL_PATH_OK"):
        assert parse_heap(bad) is None
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
    lines += [heap_bits("z;"),
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
    framing_preflight()
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
    heap_cells=parse_heap(out)
    passed=(code==0 and not err and heap_cells is not None and heap_cells>0)
    report={"project_id":"PC-BRANCH-FALSE-ARABIC","source_pin":pin,"runtime_pin":RT,
            "source_sha256":source_hashes,"pair":row["pair"],"expected":row,
            "assertions":checks,"heap_cells":heap_cells,"framing_preflight_cases":7,"program_sha256":sha(program),"stdout_sha256":sha(out),
            "stderr_sha256":sha(err),"exit_code":code,"elapsed_seconds":round(elapsed,3),
            "peak_child_rss_kib_cumulative":resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss,
            "address_space_limit_bytes":LIMIT,"timeout_seconds":600,
            "measurement_pass":passed,"stage_acceptance":False,
            "intermediate_differential":False,"boundary_and_replay_tested":False}
    (E/"receipt.json").write_text(json.dumps(report,indent=2)+"\n")
    print(json.dumps({k:report[k] for k in ("exit_code","elapsed_seconds","peak_child_rss_kib_cumulative","heap_cells","assertions","measurement_pass","stage_acceptance")}))
    if not passed:
        raise SystemExit(1)
if __name__=="__main__":
    main()
