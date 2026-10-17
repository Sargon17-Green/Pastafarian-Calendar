#!/usr/bin/env python3
"""Isolated native 17D worker/handshake probes; forensic aid, not acceptance."""
from pathlib import Path
import subprocess,tempfile,re

source=Path("qa/spaghetti08_17d_concurrent_stack_residue.beq").read_text("ascii")
lines=source.splitlines()
blocks=[(i+1,lines[i],lines[i+1]) for i in range(1,len(lines),2)]
worker=[b for b in blocks if b[1].startswith("Lines 1,Origin -")]
assert len(worker)==1
wi,wh,ws=worker[0]
original=ws[::-1]
axis_rest="0"*16
dec=lambda n: "0"+"".join("a*"+d+"+" for d in str(n))
addr=lambda n: dec(n)+axis_rest

def execute(code,title):
  with tempfile.TemporaryDirectory() as work:
    file=Path(work)/"probe.beq";file.write_text(code,encoding="ascii")
    cmd=["third_party/funge-plus-plus/bin/funge","-fconcurrent","-fthreads=funge",str(file)]
    try:
      cp=subprocess.run(cmd,input=b"1\n",capture_output=True,timeout=4)
      print("NATIVE_QA08_FORENSIC",title,"rc",cp.returncode,
        "stdout",repr(cp.stdout[:150]),"stderr",repr(cp.stderr[-250:]),flush=True)
    except subprocess.TimeoutExpired as ex:
      print("NATIVE_QA08_FORENSIC",title,"TIMEOUT stdout",
        repr((ex.stdout or b"")[:150]),"stderr",repr((ex.stderr or b"")[-200:]),flush=True)

def fmt(cells):
  return "Version 1,Dimensions 17\n"+"".join(
    "Lines 1,Origin "+str(x)+":0,Coord "+":".join(["0"]*15)+":\n"+s+"\n"
    for x,s in cells)
# Standalone worker: can it construct stacks and write both cells?
standalone=original[:-1]+addr(10001)+"g."+addr(10000)+"g.@"
execute(fmt([(0,standalone)]),"standalone_worker_stack_31_62")
# Build a no-stack writer with exact same signed-coordinate worker lane width.
simple=dec(31)+addr(10001)+"p"+dec(62)+addr(10000)+"p@"
assert len(simple)<=len(ws)
# For a backward-running lane, source text must be left padded so right edge
# remains at x=-1, the first executed worker instruction.
textworker=simple[::-1].rjust(len(ws)," ")
probe=lines[:];probe[wi]=textworker
# Terminate main immediately after handshake by altering first compiler panel.
rows=[i for i,l in enumerate(probe) if l.startswith("Lines 1,Origin ") and "Coord" in l]
target=[i+1 for i in rows if probe[i].startswith("Lines 1,Origin 51:-1,")]
assert len(target)==1
probe[target[0]]=addr(10001)+"g."+addr(10000)+"g.@"
execute("\n".join(probe)+"\n","concurrent_simple_worker_gate")
# Original nested worker and same short parent.
probe[wi]=ws
execute("\n".join(probe)+"\n","concurrent_nested_worker_gate")
# A direct parent waiting for a fixed residue written by the worker,
# but with the first compiler field truncated, isolates poll/lane routing.
print("NATIVE_QA08_FORENSIC_PROBES_COMPLETE",flush=True)
