#!/usr/bin/env python3
"""QA09 forensic: read true Native accumulator values without shifting 17D source."""
import json,subprocess,tempfile
from pathlib import Path
src=Path("qa/spaghetti09_17d_two_shard_eighty_opcode_candidate.beq").read_text("ascii")
manifest=json.loads(Path("qa/SPAGHETTI09_17D_EIGHTY_OPCODE_MANIFEST.json").read_text())
lines=src.splitlines(True)
assert lines[0]=="Version 1,Dimensions 17\n"
def run(spec,tag,seed=1):
    with tempfile.TemporaryDirectory(prefix="qa09acc_") as d:
        file=Path(d)/"probe.beq";file.write_text(spec,encoding="ascii")
        args=["third_party/funge-plus-plus/bin/funge","-fconcurrent","-fthreads=funge","-fno-filesystem","-fno-execute",str(file)]
        try:
            q=subprocess.run(args,input=("%d\n"%seed).encode("ascii"),capture_output=True,timeout=10)
            a=[int(x) for x in q.stdout.decode("utf-8","replace").split()]
            print("QA09_ACC_PROBE",tag,"seed",seed,"rc",q.returncode,"count",len(a),"values",a[:26],"last",a[-8:],flush=True)
        except subprocess.TimeoutExpired:
            print("QA09_ACC_PROBE",tag,"seed",seed,"TIMEOUT",flush=True)
for seed in (1,2):
    run(src,"original",seed)
    for axis in (1,2,3,4,8,12,15):
        entry=manifest["stages"][axis-1]
        prefix="Lines 1,Origin %d:"%entry["source_x"]
        ids=[i for i in range(1,len(lines)-1,2) if lines[i].startswith(prefix)]
        assert len(ids)==1,(axis,ids)
        j=ids[0]+1
        label=format(axis,"x")
        end=label+"."+label+"Z"
        old=lines[j]
        assert old.rstrip("\n").endswith(end),(axis,old[-90:])
        new=old[:-len(end)-1]+":."+label+"Z\n"
        assert len(new)==len(old)
        text=lines[:];text[j]=new
        run("".join(text),"acc_axis_%d"%axis,seed)
    ids=[i for i in range(1,len(lines)-1,2) if lines[i+1]=="*.@\n"]
    assert len(ids)==1
    ls=lines[:];ls[ids[0]+1]="..@\n"
    run("".join(ls),"stack_tail",seed)
print("QA09_NATIVE_ACCUMULATOR_PROBES_DONE",flush=True)
