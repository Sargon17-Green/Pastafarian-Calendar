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
run("original",base)
run("ready_flags_preseeded",base.replace("#&#&",">&B&"))
run("zero_flags_preseeded",base.replace("#&#&","0&0&"))
run("empty_flag_B",base.replace("#&#&",">&&&"))
print("QA09_NATIVE_DIAGNOSTIC_FINISHED",flush=True)
