#!/usr/bin/env python3
# WINDOWS-EXEC-PACK/3.0 FAMILY_ID=PASTAFARI_SOAK_PILOT VERSION=v020
"""One-file Windows native pilot admission only: NO converters, NO child processes.

Suitable for the existing single-.py Drive/Gmail bridge. All observations and
the final handoff ZIP are read-only or restricted to the run-owned scratch.
This is deliberately NOT a date test or a claim of available CPU throughput.
"""
from __future__ import annotations

import ctypes
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import sys
import uuid
import zipfile

FAMILY="PASTAFARI_SOAK_PILOT"
VERSION="v020"
MIN_RAM=2*1024**3
MIN_DISK=10*1024**3
CPU_RATE=500
SOURCES=(
    ("Python-Turkce","0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4",
     "tests/normative_reference.py","75d56765b45892940326f67bd85a2c7c9874c01e43b49ee3553c9f6192d94378",
     "d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53"),
    ("JavaScript-Interlingue","03ac0c7f4db3c35487993dd31982faa37dd3948e",
     "tests/normative-reference.js","8276e428c3a392ab39429331cdfdd7b80a8b1041efb4c9d806a6c141630a9fa5",
     "77f57c2d3ae76ac38fb6f59760607fda2c292443"),
    ("JavaScript-Interlingue","03ac0c7f4db3c35487993dd31982faa37dd3948e",
     "src/source-language-catalog.js","211333bff832e597e5388a789c811ae8fffb55780484f28b60b097410c786699",
     "95761bd92f3fe23b7ee32257baa4000fa7c456e7"),
)

def now():
    return dt.datetime.now(dt.timezone.utc).isoformat()

def encoded(obj):
    return (json.dumps(obj, ensure_ascii=False, sort_keys=True, indent=2)+"\n").encode("utf-8")

def hash_bytes(data):
    return hashlib.sha256(data).hexdigest()

def file_digest(path):
    h=hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1048576), b""):
            h.update(block)
    return h.hexdigest()

def git_blob(path):
    size=path.stat().st_size
    h=hashlib.sha1(b"blob "+str(size).encode("ascii")+b"\0")
    with path.open("rb") as f:
        for block in iter(lambda:f.read(1048576),b""):
            h.update(block)
    return h.hexdigest()

def ram_windows():
    class M(ctypes.Structure):
        _fields_=[("length",ctypes.c_ulong),("load",ctypes.c_ulong),
                  ("total",ctypes.c_ulonglong),("avail",ctypes.c_ulonglong),
                  ("page_total",ctypes.c_ulonglong),("page_avail",ctypes.c_ulonglong),
                  ("virt_total",ctypes.c_ulonglong),("avail_virt",ctypes.c_ulonglong),
                  ("extended",ctypes.c_ulonglong)]
    x=M();x.length=ctypes.sizeof(x)
    if not ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(x)):
        raise OSError("GlobalMemoryStatusEx failed")
    return {"total_bytes":int(x.total),"available_bytes":int(x.avail),"memory_load_percent":int(x.load)}

def cpu_job_capability_probe():
    """Configure/query an *unassigned* ephemeral Job. No current/foreign process is moved."""
    k=ctypes.WinDLL("kernel32",use_last_error=True)
    k.CreateJobObjectW.argtypes=[ctypes.c_void_p,ctypes.c_wchar_p]
    k.CreateJobObjectW.restype=ctypes.c_void_p
    k.SetInformationJobObject.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p,ctypes.c_uint32]
    k.SetInformationJobObject.restype=ctypes.c_int
    k.QueryInformationJobObject.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p,ctypes.c_uint32,ctypes.c_void_p]
    k.QueryInformationJobObject.restype=ctypes.c_int
    k.CloseHandle.argtypes=[ctypes.c_void_p]
    k.CloseHandle.restype=ctypes.c_int
    class Rate(ctypes.Structure):
        _fields_=[("flags",ctypes.c_uint32),("rate",ctypes.c_uint32)]
    handle=k.CreateJobObjectW(None,None)
    if not handle:
        raise OSError("CreateJobObjectW "+str(ctypes.get_last_error()))
    try:
        setting=Rate(5,CPU_RATE)
        if not k.SetInformationJobObject(handle,15,ctypes.byref(setting),ctypes.sizeof(setting)):
            raise OSError("SetInformationJobObject "+str(ctypes.get_last_error()))
        readback=Rate()
        if not k.QueryInformationJobObject(handle,15,ctypes.byref(readback),ctypes.sizeof(readback),None):
            raise OSError("QueryInformationJobObject "+str(ctypes.get_last_error()))
        if readback.flags!=5 or readback.rate!=CPU_RATE:
            raise RuntimeError("Job Object CPU rate readback mismatch")
        return {"status":"CAPABILITY_ONLY_NO_PROCESS_ASSIGNED",
                "requested_aggregate_cpu_rate":500,
                "readback_aggregate_cpu_rate":readback.rate,
                "readback_flags":readback.flags,
                "actual_running_process_throttling_observed":False}
    finally:
        k.CloseHandle(handle)

def make_handoff(root: Path,run_id: str,result: dict,bootstrap: list[str]) -> Path:
    folder=root/"handoffs"
    folder.mkdir(parents=True,exist_ok=True)
    kind="PASS" if result["work_status"]=="PASS" else "BLOCKED"
    name=f"{FAMILY}_HANDOFF_{VERSION}_{run_id}_{kind}.zip"
    final=folder/name
    tmp=folder/(name+".part")
    if final.exists() or tmp.exists():
        raise FileExistsError("handoff output collision")
    doc=(
        "# בדיקת מוכנות לפיילוט Windows\n\n"
        "זו בדיקת סביבת עבודה וזיהוי מקורות בלבד. לא חושב שום תאריך.\n\n"
        "סטטוס: "+result["work_status"]+"\n"
        "מחשב: אין התקנות או תהליכי ממיר חדשים. main לא שונה.\n"
        "ניתן להעביר את קובץ ה-ZIP לשיחה לצורך המשך.\n"
    )
    cleanup={"housekeeping_status":"CLEAN","installed_software":[],
             "created_child_processes":0,"external_files_deleted":0,
             "run_created_scratch":[],"preexisting_source_snapshots_untouched":True}
    entries={
        "00_START_HERE_HE.md":doc.encode("utf-8"),
        "RESULT.json":encoded(result),
        "RESULT.txt":("work_status="+result["work_status"]+"\nreason="+result["reason_code"]+"\n").encode("ascii"),
        "LOGS/bootstrap.log":("\n".join(bootstrap)+"\n").encode("utf-8"),
        "CLEANUP_REPORT.json":encoded(cleanup),
        "MANIFEST.json":encoded({"schema":"WINDOWS-EXEC-PACK/3.0",
           "family_id":FAMILY,"package_version":VERSION,"run_id":run_id,
           "work_status":result["work_status"],"scope":"RESOURCE_PREFLIGHT_ONLY"})
    }
    entries["SHA256SUMS.txt"]=("".join(hash_bytes(data)+"  "+key+"\n" for key,data in sorted(entries.items()))).encode("ascii")
    with zipfile.ZipFile(tmp,"x",compression=zipfile.ZIP_DEFLATED) as z:
        for key,data in entries.items():
            z.writestr(key,data)
    with zipfile.ZipFile(tmp) as z:
        if z.testzip() is not None or sorted(z.namelist())!=sorted(entries):
            raise RuntimeError("candidate ZIP CRC/member check failed")
        for key,data in entries.items():
            if z.read(key)!=data:
                raise RuntimeError("candidate ZIP content mismatch "+key)
    os.replace(tmp,final)
    return final

def main():
    run_id=dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")+"_"+uuid.uuid4().hex[:8]
    start=now()
    root=Path(os.environ.get("PASTAFARI_SOAK_ROOT") or (Path.home()/"Pastafarian-Converter-Soak")).resolve()
    log=[now()+" START "+FAMILY+" "+VERSION]
    result={"family_id":FAMILY,"version":VERSION,"run_id":run_id,
            "work_status":"BLOCKED","reason_code":"UNKNOWN","started_at_utc":start,
            "native_converter_calls":0,"verified_full_year_comparisons":0,
            "soak_started":False,"github_main_mutations":0,
            "installed_software":0,"child_processes_started":0,
            "source_snapshots":[],"gates":{},"warnings":[]}
    def gate(name,ok,value):
        result["gates"][name]={"pass":bool(ok),"evidence":value}
        log.append(now()+" "+name+" "+("PASS" if ok else "BLOCKED"))
    try:
        root.mkdir(parents=True,exist_ok=True)
        if os.name!="nt":
            result["reason_code"]="BLOCKED_WINDOWS_REQUIRED"
        else:
            ram=ram_windows()
            disk=shutil.disk_usage(root)
            result["memory"]=ram
            result["disk_free_bytes"]=disk.free
            result["logical_processors"]=os.cpu_count()
            result["python_runtime"]=sys.version.split()[0]
            node=shutil.which("node") or shutil.which("node.exe")
            result["node_available"]=bool(node)
            gate("RAM_HEADROOM_AT_LEAST_2_GIB",ram["available_bytes"]>=MIN_RAM,ram["available_bytes"])
            gate("DISK_HEADROOM_AT_LEAST_10_GIB",disk.free>=MIN_DISK,disk.free)
            gate("NODE_DISCOVERABLE_WITHOUT_SPAWNING",bool(node),bool(node))
            source_ok=True
            for engine,commit,relative,expected_sha,expected_blob in SOURCES:
                source=root/"sources"/engine/commit/relative
                record={"engine":engine,"commit":commit,"path":relative,"exists":source.is_file()}
                if source.is_file():
                    record["sha256"]=file_digest(source)
                    record["git_blob_sha1"]=git_blob(source)
                record["pass"]=(record.get("sha256")==expected_sha and
                                record.get("git_blob_sha1")==expected_blob)
                source_ok=source_ok and record["pass"]
                result["source_snapshots"].append(record)
            gate("THREE_FROZEN_ORIGINAL_SOURCES_MATCH",source_ok,len(result["source_snapshots"]))
            try:
                job=cpu_job_capability_probe()
                result["job_object_probe"]=job
                gate("EPHEMERAL_CPU_CAP_CAPABILITY",True,job["readback_aggregate_cpu_rate"])
            except Exception as exc:
                result["job_object_probe_error"]=type(exc).__name__+": "+str(exc)
                gate("EPHEMERAL_CPU_CAP_CAPABILITY",False,type(exc).__name__)
            if all(v["pass"] for v in result["gates"].values()):
                result["work_status"]="PASS"
                result["reason_code"]="RESOURCE_PREFLIGHT_READY_NOT_ADMITTED"
            else:
                result["reason_code"]="BLOCKED_RESOURCE_OR_SOURCE"
    except BaseException as exc:
        result["work_status"]="BLOCKED"
        result["reason_code"]="BLOCKED_PREFLIGHT_EXCEPTION"
        result["error"]=type(exc).__name__+": "+str(exc)[:400]
        log.append(now()+" EXCEPTION "+result["error"])
    finally:
        result["ended_at_utc"]=now()
        try:
            handoff=make_handoff(root,run_id,result,log)
            result["handoff_sha256"]=file_digest(handoff)
            print("PASTAFARI_SOAK_WINDOWS_ADMISSION_JSON="+json.dumps(result,ensure_ascii=True,sort_keys=True),flush=True)
            print("PASTAFARI_SOAK_WINDOWS_ADMISSION_HANDOFF="+str(handoff),flush=True)
        except BaseException as exc:
            print("PASTAFARI_SOAK_WINDOWS_ADMISSION_DELIVERY_BLOCKED="+type(exc).__name__+": "+str(exc),flush=True)
            return 3
    return 0 if result["work_status"]=="PASS" else 2

if __name__=="__main__":
    raise SystemExit(main())
