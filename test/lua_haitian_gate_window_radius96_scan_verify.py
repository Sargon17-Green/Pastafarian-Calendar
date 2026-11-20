#!/usr/bin/env python3
"""Independent geometry and source-lock verifier for Lua radius96 scan-only receipt."""
import hashlib
import re
import sys
from pathlib import Path

BLOB="95e77bc49a4c9e944bbac72b744ae0b3628043e5"
RUN="44800290037"
JOB="136510368350"
ARTIFACT="e96a51238c81a201a88798c9541909082632fda2422931623b0bf18ea0a6203e"
SCOPE="RADIUS96_GATE_WINDOW_SCAN_ONLY; YEAR5000=NOT_RUN; COMPOSITION=NOT_RUN; FULL_DATE=NOT_RUN"

def load_seed(raw):
    result={}
    for line in raw.decode("utf-8").splitlines():
        if not line or line.startswith("#"): continue
        m=re.fullmatch(r"(-?\d+)\s+(-?\d+)",line)
        if not m: raise ValueError("invalid seed row")
        i,d=map(int,m.groups())
        if i in result: raise ValueError("duplicate seed index")
        result[i]=d
    return result

def check(text,radius,core,seed,blob,expected_evals):
    gates,windows,markers={},{},{}
    for line in text.splitlines():
        m=re.fullmatch(r"GATE_INDEX\|index=(-?\d+)\|day=(-?\d+)",line)
        if m:
            i,d=map(int,m.groups())
            if i in gates: raise ValueError("duplicate gate")
            gates[i]=d
            continue
        m=re.fullmatch(r"GATE_WINDOW\|i=(-?\d+)\|j=(-?\d+)\|first=(-?\d+)\|last=(-?\d+)\|length=(\d+)",line)
        if m:
            row=tuple(map(int,m.groups()))
            if row[0] in windows: raise ValueError("duplicate window")
            windows[row[0]]=row
            continue
        if line.startswith(("GATE_TARGET","GATE_ADMITTED","SHORT_SELECTED","YEAR5000")):
            raise ValueError("target/date output in scan-only receipt")
        if line.startswith(("GATE_","MIN_SIX_","SHORT_SIX_","SCAN_ONLY","COMPOSITION_","SCOPE=")):
            k,sep,v=line.partition(": ")
            if not sep: k,sep,v=line.partition("=")
            if not sep or k in markers: raise ValueError("invalid or duplicate marker")
            markers[k]=v
    if set(seed)!=set(range(-core,core+1)): raise ValueError("seed range")
    if set(gates)!=set(range(-radius,radius+1)): raise ValueError("gate range")
    for i,d in seed.items():
        if gates[i]!=d: raise ValueError("seed changed")
    gaps=[gates[i]-gates[i-1] for i in range(-radius+1,radius+1)]
    if not all(42<=gap<=963 for gap in gaps): raise ValueError("gap bound")
    if set(windows)!=set(range(-radius,radius-5)): raise ValueError("window range")
    lengths=[]
    for i in range(-radius,radius-5):
        total=sum(gates[j]-gates[j-1] for j in range(i+1,i+7))
        if windows[i]!=(i,i+6,gates[i],gates[i+6],total):
            raise ValueError("window arithmetic")
        lengths.append(total)
    expected={
        "GATE_CORE_SEED":f"{-core}/{core}",
        "GATE_CORE_VERIFIED_RUN":RUN,
        "GATE_CORE_NATIVE_JOB":JOB,
        "GATE_CORE_ARTIFACT_SHA256":ARTIFACT,
        "GATE_CORE_SEED_BLOB":blob,
        "GATE_WINDOW_SCAN":f"{-radius}/{radius}",
        "GATE_WINDOWS_TOTAL":str(len(windows)),
        "MIN_SIX_GAP_WINDOW":str(min(lengths)),
        "SHORT_SIX_GAP_WINDOWS":str(sum(252<=x<=1968 for x in lengths)),
        "GATE_GAP_EVALUATIONS":str(expected_evals),
        "SCAN_ONLY":"YES",
        "COMPOSITION_NOT_INVOKED":"YES",
        "SCOPE":SCOPE
    }
    if expected!=markers:
        raise ValueError("summary mismatch: "+str({k:(markers.get(k),v) for k,v in expected.items() if markers.get(k)!=v}))
    return len(gates),len(gaps),len(windows),min(lengths)

def synthetic():
    g={i:(i+6)*100 for i in range(-6,7)}
    lines=[
        "GATE_CORE_SEED: -2/2",f"GATE_CORE_VERIFIED_RUN: {RUN}",
        f"GATE_CORE_NATIVE_JOB: {JOB}",
        f"GATE_CORE_ARTIFACT_SHA256: {ARTIFACT}",
        "GATE_CORE_SEED_BLOB: SELFTEST"
    ]
    lines += [f"GATE_INDEX|index={i}|day={g[i]}" for i in range(-6,7)]
    lines += [f"GATE_WINDOW|i={i}|j={i+6}|first={g[i]}|last={g[i+6]}|length=600" for i in range(-6,1)]
    lines += [
        "GATE_WINDOW_SCAN: -6/6","GATE_WINDOWS_TOTAL: 7",
        "MIN_SIX_GAP_WINDOW: 600","SHORT_SIX_GAP_WINDOWS: 7",
        "GATE_GAP_EVALUATIONS: 8","SCAN_ONLY: YES",
        "COMPOSITION_NOT_INVOKED: YES","SCOPE="+SCOPE
    ]
    return "\n".join(lines),{i:g[i] for i in range(-2,3)}

def selftest():
    good,seed=synthetic()
    assert check(good,6,2,seed,"SELFTEST",8)==(13,12,7,600)
    changes=[
        good.replace("GATE_INDEX|index=0|day=600","GATE_INDEX|index=0|day=599"),
        good+"\nGATE_INDEX|index=0|day=600",
        good.replace("GATE_INDEX|index=0|day=600",""),
        good.replace("|length=600","|length=601",1),
        good.replace("GATE_WINDOWS_TOTAL: 7","GATE_WINDOWS_TOTAL: 8"),
        good.replace("GATE_GAP_EVALUATIONS: 8","GATE_GAP_EVALUATIONS: 9"),
        good.replace("COMPOSITION_NOT_INVOKED: YES","COMPOSITION_NOT_INVOKED: NO"),
        good+"\nGATE_TARGET|probe=1|day=100",
    ]
    for value in changes:
        try: check(value,6,2,seed,"SELFTEST",8)
        except (ValueError,KeyError): continue
        raise AssertionError("bad evidence accepted")
    print("RADIUS96_INDEPENDENT_SELFTEST: 9/9 PASS")

def main():
    if len(sys.argv)==2 and sys.argv[1]=="--selftest": return selftest()
    if len(sys.argv)!=3: raise ValueError("usage: --selftest OR stdout.txt seed.tsv")
    raw=Path(sys.argv[2]).read_bytes()
    sha=hashlib.sha1(b"blob "+str(len(raw)).encode()+b"\0"+raw).hexdigest()
    if sha!=BLOB: raise ValueError("immutable seed blob hash")
    data=load_seed(raw)
    r=check(Path(sys.argv[1]).read_text(),96,64,data,sha,64)
    print("RADIUS96_INDEPENDENT_VERIFIER: PASS gates/gaps/windows/min="+"/".join(map(str,r)))

if __name__=="__main__":
    try: main()
    except (ValueError,AssertionError,KeyError) as exc:
        print("RADIUS96_INDEPENDENT_VERIFIER: FAIL "+str(exc),file=sys.stderr)
        sys.exit(1)
