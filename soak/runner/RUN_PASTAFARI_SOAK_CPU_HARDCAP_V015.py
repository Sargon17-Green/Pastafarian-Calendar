#!/usr/bin/env python3
# WINDOWS-EXEC-PACK/3.0 FAMILY_ID=PASTAFARI_SOAK_READINESS VERSION=v015
"""One-shot Windows self-job CPU cap measurement, ~2s bounded work.

No child processes, no converters, no benchmark of project algorithms,
no installation, no global machine configuration, no recurring process.
"""
from __future__ import annotations
import ctypes
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import time
import uuid
import zipfile

FAMILY = 'PASTAFARI_SOAK_READINESS'
RATE = 500  # Windows CPU rate units: 500/100 = 5% of total system CPU.
DURATION = 2.0
MIN_RAM = 256*1024*1024


def available_memory():
    class Mem(ctypes.Structure):
        _fields_ = [('length',ctypes.c_ulong),('load',ctypes.c_ulong),
                   ('total',ctypes.c_ulonglong),('avail',ctypes.c_ulonglong),
                   ('page_total',ctypes.c_ulonglong),('page_available',ctypes.c_ulonglong),
                   ('virt_total',ctypes.c_ulonglong),('virt_available',ctypes.c_ulonglong),
                   ('extended',ctypes.c_ulonglong)]
    m=Mem();m.length=ctypes.sizeof(m)
    if not ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(m)):
        raise OSError('GlobalMemoryStatusEx failed')
    return int(m.avail)


def measure():
    if os.name != 'nt':
        return {'status':'WINDOWS_REQUIRED','no_processes_started':True}
    ram=available_memory()
    out={'available_ram_bytes':ram,'cpu_rate_requested':RATE,'sample_seconds_requested':DURATION,
         'logical_cpu_count':os.cpu_count(),'children_started':0,'converters_started':0,
         'soak_started':False,'global_changes':0}
    if ram<MIN_RAM:
        out['status']='RESOURCE_BLOCKED'
        return out
    k=ctypes.WinDLL('kernel32',use_last_error=True)
    k.CreateJobObjectW.argtypes=[ctypes.c_void_p,ctypes.c_wchar_p]
    k.CreateJobObjectW.restype=ctypes.c_void_p
    k.GetCurrentProcess.restype=ctypes.c_void_p
    k.SetInformationJobObject.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p,ctypes.c_uint32]
    k.SetInformationJobObject.restype=ctypes.c_int
    k.QueryInformationJobObject.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p,ctypes.c_uint32,ctypes.c_void_p]
    k.QueryInformationJobObject.restype=ctypes.c_int
    k.AssignProcessToJobObject.argtypes=[ctypes.c_void_p,ctypes.c_void_p]
    k.AssignProcessToJobObject.restype=ctypes.c_int
    k.IsProcessInJob.argtypes=[ctypes.c_void_p,ctypes.c_void_p,ctypes.c_void_p]
    k.IsProcessInJob.restype=ctypes.c_int
    k.SetPriorityClass.argtypes=[ctypes.c_void_p,ctypes.c_uint32]
    k.SetPriorityClass.restype=ctypes.c_int
    k.GetPriorityClass.argtypes=[ctypes.c_void_p]
    k.GetPriorityClass.restype=ctypes.c_uint32
    k.CloseHandle.argtypes=[ctypes.c_void_p]
    k.CloseHandle.restype=ctypes.c_int
    class Rate(ctypes.Structure):
        _fields_=[('flags',ctypes.c_uint32),('rate',ctypes.c_uint32)]
    h=k.CreateJobObjectW(None,None)
    if not h:
        return {**out,'status':'JOB_CREATE_BLOCKED','error_code':ctypes.get_last_error()}
    try:
        setrate=Rate(5,RATE)
        if not k.SetInformationJobObject(h,15,ctypes.byref(setrate),ctypes.sizeof(setrate)):
            return {**out,'status':'JOB_RATE_BLOCKED','error_code':ctypes.get_last_error()}
        if not k.AssignProcessToJobObject(h,k.GetCurrentProcess()):
            return {**out,'status':'JOB_SELF_ASSIGN_BLOCKED','error_code':ctypes.get_last_error()}
        member=ctypes.c_int(0)
        if not k.IsProcessInJob(k.GetCurrentProcess(),h,ctypes.byref(member)) or not member.value:
            return {**out,'status':'JOB_MEMBERSHIP_UNVERIFIED','error_code':ctypes.get_last_error()}
        actual=Rate()
        if not k.QueryInformationJobObject(h,15,ctypes.byref(actual),ctypes.sizeof(actual),None):
            return {**out,'status':'JOB_READBACK_BLOCKED','error_code':ctypes.get_last_error()}
        if actual.flags!=5 or actual.rate!=RATE:
            return {**out,'status':'JOB_READBACK_MISMATCH', 'actual_rate':actual.rate,'actual_flags':actual.flags}
        if not k.SetPriorityClass(k.GetCurrentProcess(),0x4000):
            return {**out,'status':'PRIORITY_BLOCKED','error_code':ctypes.get_last_error()}
        out['priority_below_normal_verified']=k.GetPriorityClass(k.GetCurrentProcess())==0x4000
        # Very short workload only. Job is already capped, so at most 5% of
        # aggregate host CPU is requested. No unrelated process is touched.
        start_wall=time.perf_counter();start_cpu=time.process_time();counter=0
        while time.perf_counter()-start_wall<DURATION:
            counter=(counter*1664525+1013904223)&0xffffffff
        elapsed=time.perf_counter()-start_wall
        used=time.process_time()-start_cpu
        share=used/(elapsed*max(1,os.cpu_count() or 1))
        out.update({'elapsed_seconds':round(elapsed,4),'cpu_process_seconds':round(used,4),
                    'observed_fraction_of_aggregate_cpu':round(share,5),
                    'cpu_rate_fraction_requested':RATE/10000,
                    'job_self_membership_verified':True,
                    'rate_readback':actual.rate,'flags_readback':actual.flags,
                    'work_counter':counter})
        # An over-generous 1.8x margin avoids small-sample false failure.
        # This is observed throttling evidence, NOT universal OS enforcement.
        out['status']=('SHORT_CPU_THROTTLE_OBSERVED_PASS' if share<=0.09 and
                       out['priority_below_normal_verified'] else
                       'SHORT_CPU_THROTTLE_NOT_PROVEN')
        return out
    finally:
        # Handle is local to the current process; no persistent system policy.
        k.CloseHandle(h)


def main():
    rid=dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%SZ')+'_'+uuid.uuid4().hex[:8]
    try:result=measure()
    except BaseException as e:result={'status':'PROBE_ERROR','error':type(e).__name__+': '+str(e)[:200]}
    result.update({'version':'v015','run_id':rid,'family':FAMILY})
    if os.name=='nt':
        folder=Path(os.environ.get('PASTAFARI_SOAK_ROOT') or Path.home()/'Pastafarian-Converter-Soak')/'handoffs'
        folder.mkdir(parents=True,exist_ok=True)
        dest=folder/f'PASTAFARI_SOAK_CPU_HARDCAP_v015_{rid}_{result["status"]}.zip'
        stage=dest.with_suffix('.zip.part')
        payload=(json.dumps(result,ensure_ascii=False,sort_keys=True)+'\n').encode()
        with zipfile.ZipFile(stage,'x',zipfile.ZIP_DEFLATED) as z:
            z.writestr('RESULT.json',payload)
            z.writestr('SHA256SUMS.txt',hashlib.sha256(payload).hexdigest()+'  RESULT.json\n')
        with zipfile.ZipFile(stage) as z:
            if z.testzip():raise RuntimeError('failed to verify evidence ZIP')
        os.replace(stage,dest)
        result['evidence_zip_sha256']=hashlib.sha256(dest.read_bytes()).hexdigest()
    print('PASTAFARI_SOAK_CPU_HARDCAP_RESULT='+json.dumps(result,sort_keys=True,ensure_ascii=False),flush=True)
    return 0 if result['status'] in ('SHORT_CPU_THROTTLE_OBSERVED_PASS','WINDOWS_REQUIRED') else 2

if __name__=='__main__':raise SystemExit(main())
