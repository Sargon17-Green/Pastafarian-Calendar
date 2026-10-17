#!/usr/bin/env python3
import subprocess,tempfile
from pathlib import Path
p=Path("qa/spaghetti09_nd17_two_worker_rendezvous_fixture.beq")
base=p.read_text("ascii")
assert base.count("#&#&")==1
assert base.count("Lines 1,Origin 1:0,")==1
def run(name,src):
 with tempfile.TemporaryDirectory() as d:
  f=Path(d)/"candidate.beq";f.write_text(src)
  args=["third_party/funge-plus-plus/bin/funge","-fconcurrent","-fthreads=funge",str(f)]
  try:
   x=subprocess.run(args,input=b"1\n",capture_output=True,timeout=3)
   print("QA09_NATIVE_DIAGNOSTIC",name,"rc",x.returncode,"out",repr(x.stdout[:250]),"err",repr(x.stderr[-250:]),flush=True)
  except subprocess.TimeoutExpired as e:
   print("QA09_NATIVE_DIAGNOSTIC",name,"TIMEOUT","out",repr((e.stdout or b"")[:250]),flush=True)
   detail=(e.stderr or b"").decode("utf-8","replace").splitlines()
   for x in detail[-230:]:
    if "FUNGEPLUS" in x:print("QA09_TRACE",name,x,flush=True)
run("original",base)
run("ready_flags_preseeded",base.replace("#&#&",">&B&"))
run("zero_flags_preseeded",base.replace("#&#&","0&0&"))
run("empty_flag_B",base.replace("#&#&",">&&&"))
lines=base.splitlines(True)
ix=next(i for i in range(1,len(lines)-1,2) if lines[i].startswith("Lines 1,Origin 1:0,"))
row=lines[ix+1]
assert row[13]=="j" and row[129]=="t"
def swap(name,at,ch):
 copy=lines[:]
 arr=list(row);arr[at]=ch;copy[ix+1]="".join(arr)
 run(name,"".join(copy).replace("#&#&",">&B&"))
swap("second_fork_to_output",129,".")
swap("jump_to_output",13,".")
print("QA09_NATIVE_DIAGNOSTIC_FINISHED",flush=True)
