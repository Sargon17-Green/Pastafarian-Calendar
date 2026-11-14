#!/usr/bin/env python3
# WINDOWS-EXEC-PACK/3.0 FAMILY_ID=PASTAFARI_SOAK_READINESS VERSION=v011
"""No-child Windows file+SQLite recovery validation, using synthetic output only.
No converter/soak, no installations/services/scheduled tasks, no shell launches.
No genuine power outage or process crash is induced by this gentle test.
"""
from __future__ import annotations
import base64
import ctypes
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys
import traceback
import uuid
import zipfile
import zlib

FAMILY='PASTAFARI_SOAK_READINESS'
VERSION='v011'
SOURCES_ZLIB='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'
SOURCE_SHA={'year_validator.py': '84b5a7f6bc8e167db7ed3c436862665bfcc6aaea3716458bcff784bfb6f455a0', 'recovery_store.py': 'a0db249ac0ba6099ccb7581c56015f87b133a958ba90d8d4c309bcd5eb14f300'}
MIN_FREE=192*1024*1024


def free_memory():
    class Memory(ctypes.Structure):
        _fields_=[('length',ctypes.c_ulong),('load',ctypes.c_ulong),
                  ('total',ctypes.c_ulonglong),('available',ctypes.c_ulonglong),
                  ('tp',ctypes.c_ulonglong),('ap',ctypes.c_ulonglong),
                  ('tv',ctypes.c_ulonglong),('av',ctypes.c_ulonglong),('ex',ctypes.c_ulonglong)]
    status=Memory()
    status.length=ctypes.sizeof(status)
    if not ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(status)):
        raise OSError('GlobalMemoryStatusEx failed')
    return int(status.available)


def plan():
    return {'contract':'PASTAFARI_SOAK_RECOVERY/1',
        'calculation_day':'-15055671','chunk_days':2,
        'years':[{'year':'5000','first_target_day':'-15055671','last_target_day':'-15055668','boundary_evidence_sha256':'a'*64},
                 {'year':'5001','first_target_day':'-15055667','last_target_day':'-15055664','boundary_evidence_sha256':'b'*64}],
        'engines':[{'id':'synthetic-a','algorithm_id':'SYNTHETIC-A','source_sha256':'1'*64,'binary_sha256':'2'*64,'name_map_sha256':'3'*64},
                   {'id':'synthetic-b','algorithm_id':'SYNTHETIC-B','source_sha256':'4'*64,'binary_sha256':'5'*64,'name_map_sha256':'6'*64}]}


def output(year,ordinal,engine,mismatch_at=None):
    start=(-15055671 if year=='5000' else -15055667)+ordinal*2
    rows=[]
    for t in (start,start+1):
        v={'calculation_day':'-15055671','target_day':str(t),'year':year,
           'cutlet_index':10,'day_in_cutlet':503+t+15055671,
           'month_index':20+(1 if t==mismatch_at else 0),
           'day_in_month':56+t+15055671,
           'cutlet_name_raw':'Test A' if engine=='synthetic-a' else 'בדיקת ב',
           'month_name_raw':'Test M' if engine=='synthetic-a' else 'חודש בדיקה',
           'source_raw_sha256':hashlib.sha256((engine+str(t)).encode()).hexdigest()}
        rows.append(json.dumps(v,ensure_ascii=False,sort_keys=True)+'\n')
    return ''.join(rows).encode('utf8')


def audit(root,report):
    source_files=json.loads(zlib.decompress(base64.b64decode(SOURCES_ZLIB)).decode('utf8'))
    code=root/'code';code.mkdir()
    for name,value in source_files.items():
        data=value.encode('utf8')
        if hashlib.sha256(data).hexdigest()!=SOURCE_SHA[name]:raise RuntimeError('BUNDLED_MODULE_SHA_MISMATCH')
        (code/name).write_bytes(data)
    sys.path.insert(0,str(code))
    from recovery_store import CrashStore,Halted
    sroot=root/'ledger'
    p=plan()
    evidence=[]
    # Committed chunk survives a restart.
    with CrashStore(sroot,p) as s:
        selfstart=s.commit_chunk('synthetic-a','5000',0,output('5000',0,'synthetic-a'))
        if selfstart!='COMMITTED':raise RuntimeError('BASELINE_START_COMMIT')
        evidence.append({'phase':'baseline_commit','progress':s.progress()})
    with CrashStore(sroot,p) as s:
        chunk=s._chunk('synthetic-a','5000',1)
        part=s._chunk_path(chunk).with_suffix('.jsonl.part')
        s._durable_write(part,output('5000',1,'synthetic-a'))
        evidence.append({'phase':'simulated_stop_after_part_fsync','staged_exists':part.is_file()})
    with CrashStore(sroot,p) as s:
        recovered=s.verify_and_recover()
        if recovered['recovered_staged_files']!=1 or recovered['recovered_chunks']!=1:
            raise RuntimeError('PART_FILE_REPLAY_FAILED')
        evidence.append({'phase':'reopen_after_part','recovered':recovered})
    # Simulate a completed payload rename before SQLite record.
    with CrashStore(sroot,p) as s:
        chunk=s._chunk('synthetic-b','5000',0)
        data=output('5000',0,'synthetic-b')
        part=s._chunk_path(chunk).with_suffix('.jsonl.part')
        s._durable_write(part,data)
        os.replace(part,s._chunk_path(chunk))
        s._sync_dir(sroot/'chunks')
        evidence.append({'phase':'simulated_stop_after_payload_publish','bytes':len(data)})
    with CrashStore(sroot,p) as s:
        recovered=s.verify_and_recover()
        if recovered['recovered_chunks']!=1 or recovered['recovered_staged_files']!=0:
            raise RuntimeError('PUBLISHED_UNINDEXED_BLOB_NOT_RECOVERED')
        s.commit_chunk('synthetic-b','5000',1,output('5000',1,'synthetic-b'))
        if s.progress()['verified_comparisons_completed']!=1:raise RuntimeError('FULL_YEAR_NOT_ACCEPTED')
        evidence.append({'phase':'reopen_after_unindexed_publish','recovered':recovered,'progress':s.progress()})
    with CrashStore(sroot,p) as s:
        status=s.verify_and_recover()
        if status['progress']['verified_comparisons_completed']!=1:raise RuntimeError('REOPEN_LOST_YEAR')
        if s.commit_chunk('synthetic-b','5000',1,output('5000',1,'synthetic-b'))!='ALREADY_COMMITTED':
            raise RuntimeError('REPLAY_DOUBLE_COMMIT')
        evidence.append({'phase':'verified_no_duplicate_on_restart','progress':s.progress()})
    with CrashStore(sroot,p) as s:
        for ordinal in (0,1):
            s.commit_chunk('synthetic-a','5001',ordinal,output('5001',ordinal,'synthetic-a'))
        s.commit_chunk('synthetic-b','5001',0,output('5001',0,'synthetic-b',mismatch_at=-15055666))
        incident=s.incident()
        if not incident or incident['evidence']['target_day']!='-15055666':
            raise RuntimeError('FIRST_DIFFERENCE_NOT_FROZEN')
        evidence.append({'phase':'mismatch_frozen','incident':incident})
    with CrashStore(sroot,p) as s:
        if s.incident()!=incident:raise RuntimeError('INCIDENT_LOST_AFTER_REOPEN')
        try:s.pending_jobs()
        except Halted:pass
        else:raise RuntimeError('UNSAFE_DISPATCH_AFTER_RESTART')
        evidence.append({'phase':'restarted_still_halted','progress':s.progress()})
    import sqlite3
    conn=sqlite3.connect(str(sroot/'ledger.sqlite'))
    dest=sqlite3.connect(str(root/'ledger_snapshot.sqlite'))
    try:conn.backup(dest)
    finally:conn.close();dest.close()
    report['phases']=evidence
    report['ledger_snapshot_sha256']=hashlib.sha256((root/'ledger_snapshot.sqlite').read_bytes()).hexdigest()
    report['source_sha256']=SOURCE_SHA


def main():
    run_id=dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%SZ')+'_'+uuid.uuid4().hex[:8].upper()
    report={'family':FAMILY,'version':VERSION,'run_id':run_id,
            'status':'NOT_RUN','all_results_synthetic':True,'converters_executed':0,
            'real_soak_executed':False,'child_processes':0,'installs':0,'services':0}
    if os.name!='nt':
        print('PASTAFARI_SOAK_WINDOWS_PERSISTENCE='+json.dumps({'status':'WINDOWS_REQUIRED'}),flush=True)
        return 2
    root=Path(os.environ.get('PASTAFARI_SOAK_ROOT') or Path.home()/'Pastafarian-Converter-Soak').resolve()
    evidence=root/'handoffs'
    sandbox=root/'scratch'/('persistence_v011_'+run_id)
    allocated=False
    try:
        available=free_memory()
        report['free_ram_bytes']=available
        report['admission_threshold_bytes']=MIN_FREE
        if available<MIN_FREE:raise RuntimeError('BLOCKED_LOW_RAM')
        if shutil.disk_usage(root if root.exists() else Path.home()).free<10*1024**3:
            raise RuntimeError('BLOCKED_DISK_HEADROOM')
        sandbox.mkdir(parents=True,exist_ok=False)
        allocated=True
        audit(sandbox,report)
        report['status']='WINDOWS_FILE_SQLITE_RECOVERY_SIMULATED_PASS'
    except BaseException as exc:
        report['status']='WINDOWS_FILE_SQLITE_RECOVERY_BLOCKED'
        report['error']=type(exc).__name__+': '+str(exc)[:400]
        report['traceback_tail']=traceback.format_exc()[-1500:]
    finally:
        evidence.mkdir(parents=True,exist_ok=True)
        handoff=evidence/(FAMILY+'_HANDOFF_'+VERSION+'_'+run_id+'_'+report['status']+'.zip')
        candidate=handoff.with_suffix('.zip.part')
        report['cleanup_status']='PENDING'
        blob=json.dumps(report,ensure_ascii=False,sort_keys=True,indent=2).encode('utf8')
        with zipfile.ZipFile(candidate,'x',zipfile.ZIP_DEFLATED) as z:
            z.writestr('RESULT.json',blob)
            if allocated:
                for name in ('ledger_snapshot.sqlite',):
                    f=sandbox/name
                    if f.is_file():z.write(f,'evidence/'+name)
        with zipfile.ZipFile(candidate) as z:
            if z.testzip() is not None:raise RuntimeError('CANDIDATE_ZIP_BAD')
        if allocated:
            try:shutil.rmtree(sandbox)
            except OSError as exc:report['cleanup_error']=str(exc)[:160]
        report['cleanup_status']='CLEAN' if (not allocated or not sandbox.exists()) else 'PARTIAL'
        blob=json.dumps(report,ensure_ascii=False,sort_keys=True,indent=2).encode('utf8')
        receipt=json.dumps({'status':report['cleanup_status'],'no_child_processes':True,
                            'owned_scratch_remaining':bool(allocated and sandbox.exists())}).encode('utf8')
        final_tmp=handoff.with_suffix('.zip.finalizing')
        with zipfile.ZipFile(candidate) as src,zipfile.ZipFile(final_tmp,'x',zipfile.ZIP_DEFLATED) as z:
            z.writestr('RESULT.json',blob)
            z.writestr('CLEANUP_REPORT.json',receipt)
            z.writestr('SHA256SUMS.txt',hashlib.sha256(blob).hexdigest()+'  RESULT.json\n'+
                       hashlib.sha256(receipt).hexdigest()+'  CLEANUP_REPORT.json\n')
            for name in src.namelist():
                if name!='RESULT.json':z.writestr(name,src.read(name))
        with zipfile.ZipFile(final_tmp) as z:
            if z.testzip() is not None:raise RuntimeError('FINAL_ZIP_BAD')
        os.replace(final_tmp,handoff)
        candidate.unlink()
        report['handoff_sha256']=hashlib.sha256(handoff.read_bytes()).hexdigest()
        print('PASTAFARI_SOAK_WINDOWS_PERSISTENCE='+json.dumps(report,ensure_ascii=True,sort_keys=True),flush=True)
    return 0 if report['status']=='WINDOWS_FILE_SQLITE_RECOVERY_SIMULATED_PASS' else 2

if __name__=='__main__':raise SystemExit(main())
