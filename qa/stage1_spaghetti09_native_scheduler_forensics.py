#!/usr/bin/env python3
"""QA09 scheduler forensic: unmodified upstream versus ephemeral lifecycle patch.
No production, QA07/08/09 source, or engine checkout commit is modified in the Git repo.
"""
from __future__ import annotations
import hashlib,json,subprocess,sys
from pathlib import Path

ENGINE=Path("third_party/funge-plus-plus/bin/funge")
SRC=Path("third_party/funge-plus-plus/src/FungeUniverse.cpp")
PATCH_MARKER="cv.notify_all(); // qa09 native scheduler drain notification"
QA09=Path("qa/spaghetti09_17d_two_shard_eighty_opcode_candidate.beq")
QA09_SHA="275cec0add8705565d27da4233860bf42d134a27"
QA09A=Path("qa/spaghetti09_nd17_two_worker_rendezvous_fixture.beq")
QA09A_SHA="e22a8b706fb84e3356db6c70aac29b9145642201"
OUT=Path("spaghetti09_native_scheduler_receipt.json")
# Output includes 2 residues + 16*6 numbers + checksum
def target_numbers(seed):
    a=[31,33]
    for axis in range(1,17):
        t=axis*(axis+1)//2
        a += [48+10*((t+seed)%2),36,48+10*((t+seed+1)%2),36,62,axis]
    return a+[136*seed]

def sha(data):
    return hashlib.sha1(("blob %d\0"%len(data)).encode()+data).hexdigest()

def run(label,path,seed,mode,seconds):
    args=[str(ENGINE),"-fconcurrent","-fthreads="+mode,
          "-fno-execute","-fno-filesystem",str(path)]
    try:
        r=subprocess.run(args,input=(str(seed)+"\n").encode(),
            capture_output=True,timeout=seconds)
        stdout=r.stdout
        stderr=r.stderr
        exit_code=r.returncode
        timed_out=False
    except subprocess.TimeoutExpired as ex:
        stdout=ex.stdout or b""
        stderr=ex.stderr or b""
        exit_code=124
        timed_out=True
    raw=stdout.decode("utf-8","replace")
    try:
        nums=[int(x) for x in raw.split()]
    except ValueError:
        nums=[]
    outcome={"label":label,"mode":mode,"seed":seed,"limit_s":seconds,
        "exit":exit_code,"timeout":timed_out,"stdout_bytes":len(stdout),
        "nums":len(nums),"prefix":nums[:8],"suffix":nums[-8:],
        "stderr_tail":stderr.decode("utf-8","replace")[-200:]}
    print("QA09_NATIVE_SCHEDULER_PROBE",json.dumps(outcome,ensure_ascii=False),flush=True)
    return outcome,nums

def main():
    # Expected source immutable; no recovery from source drift.
    assert sha(QA09.read_bytes())==QA09_SHA
    assert sha(QA09A.read_bytes())==QA09A_SHA
    assert ENGINE.is_file()
    assert PATCH_MARKER not in SRC.read_text()
    p=Path("qa/spaghetti09_native_thread_single_runner.beq")
    p.write_text("Version 1,Dimensions 17\n"+
         "Lines 1,Origin 0:0,Coord "+":".join(["0"]*15)+":\n0.@\n"+
         "Lines 1,Origin 99:0,Coord "+":".join(["0"]*14+["1"])+":\nz\n",
         encoding="ascii")
    probes=[]
    for name,path,seconds in (("one_ip",p,4),("two_worker",QA09A,5),("eighty_opcode",QA09,23)):
        for mode in ("funge","native"):
            receipt,nums=run("upstream_"+name,path,1,mode,seconds)
            receipt["parity"]=(nums==[0] if name=="one_ip" else
                nums==[31,33] if name=="two_worker" else nums==target_numbers(1))
            probes.append(receipt)
    # All unmodified Native timed-out executions still disclose output bytes.
    # That distinguishes a deadlock after completion from a logic hang.
    with_postfix=False
    if "--postfix" in sys.argv:
        with_postfix=True
        text=SRC.read_text()
        before="""\
				threads.pop();
				delete thread;
			}
			mutex.unlock();
		}else{"""
        after="""\
				threads.pop();
				delete thread;
			}
			cv.notify_all(); // qa09 native scheduler drain notification
			mutex.unlock();
		}else{"""
        assert text.count(before)==1,"Upstream native scheduler structure drift"
        SRC.write_text(text.replace(before,after))
        subprocess.run(["make","-C","third_party/funge-plus-plus","funge"],
            check=True,stdout=subprocess.DEVNULL)
        print("QA09_SCHEDULER_PATCHED_LOCAL_ONLY",flush=True)
        for name,path,seconds in (("one_ip",p,5),("two_worker",QA09A,7),("eighty_opcode",QA09,30)):
            for mode in ("funge","native"):
                receipt,nums=run("patched_"+name,path,1,mode,seconds)
                receipt["parity"]=(nums==[0] if name=="one_ip" else
                    nums==[31,33] if name=="two_worker" else nums==target_numbers(1))
                probes.append(receipt)
    results={"schema":"qa09-native-fungeplusplus-scheduler-forensics-v1",
        "unmodified_engine":"cwesson/funge-plus-plus@cd6d7f005b4fc33b486fcc2380b35406f6125ca4",
        "postfix_requested":with_postfix,"patch_is_outside_git_repo":True,
        "qa09_source_blob":QA09_SHA,"qa09a_source_blob":QA09A_SHA,
        "results":probes}
    OUT.write_text(json.dumps(results,indent=2,sort_keys=True)+"\n")
    # Native upstream may fail, but forensic job must never imply that it passed.
    # Require the healthy cooperative baseline and, if patched, healthy patched native.
    for name in ("one_ip","two_worker","eighty_opcode"):
        a=next(p for p in probes if p["label"]=="upstream_"+name and p["mode"]=="funge")
        assert a["exit"]==0 and a["parity"],"Even healthy cooperative baseline failed "+name
        if with_postfix:
            b=next(p for p in probes if p["label"]=="patched_"+name and p["mode"]=="native")
            assert b["exit"]==0 and b["parity"],"Scheduler lifecycle fix insufficient "+name
    print("QA09_NATIVE_SCHEDULER_FORENSIC_BASELINES_PASS",flush=True)

if __name__=="__main__":
    main()
