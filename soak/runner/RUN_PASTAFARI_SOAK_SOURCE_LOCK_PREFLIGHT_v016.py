#!/usr/bin/env python3
# WINDOWS-EXEC-PACK/3.0 FAMILY_ID=PASTAFARI_SOAK_READINESS VERSION=v016
"""Read-only upstream, owned local source snapshot and syntax preflight.

Downloads three original GitHub blobs from two fully pinned branch commits.
No converter is executed. No heavy soak, no installation, no git push and
no global environment changes. Run-once via the existing Drive OTR bridge.
"""
from __future__ import annotations
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import urllib.request
import uuid
import zipfile

FAMILY='PASTAFARI_SOAK_READINESS'
VERSION='v016'
SOURCE_MAX=1_048_576
DISK_FLOOR=10*1024**3
RAM_FLOOR=512*1024**2
PINNED=[
 {'engine':'Python-Turkce','commit':'0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4',
  'source_path':'tests/normative_reference.py','git_blob':'d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53',
  'entrypoint':'NormativeCalendar().calendar_date_ids(c,t)','input_types':'Python int, Python int'},
 {'engine':'JavaScript-Interlingue','commit':'03ac0c7f4db3c35487993dd31982faa37dd3948e',
  'source_path':'tests/normative-reference.js','git_blob':'77f57c2d3ae76ac38fb6f59760607fda2c292443',
  'entrypoint':'calendarDate(BigInt(c), BigInt(t))','input_types':'BigInt, BigInt'},
 {'engine':'JavaScript-Interlingue','commit':'03ac0c7f4db3c35487993dd31982faa37dd3948e',
  'source_path':'src/source-language-catalog.js','git_blob':'95761bd92f3fe23b7ee32257baa4000fa7c456e7',
  'entrypoint':'textByCanonicalIndex(group,index)','input_types':'string, integer'}
]


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def git_blob(data: bytes) -> str:
    return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()


def available_ram_windows():
    import ctypes
    class Mem(ctypes.Structure):
        _fields_=[('size',ctypes.c_ulong),('load',ctypes.c_ulong),('total',ctypes.c_ulonglong),
                  ('avail',ctypes.c_ulonglong),('page_total',ctypes.c_ulonglong),
                  ('page_avail',ctypes.c_ulonglong),('virt_total',ctypes.c_ulonglong),
                  ('virt_avail',ctypes.c_ulonglong),('extended',ctypes.c_ulonglong)]
    x=Mem();x.size=ctypes.sizeof(x)
    if not ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(x)):
        raise OSError('GlobalMemoryStatusEx')
    return x.avail


def download_frozen(root: Path, item: dict) -> dict:
    path=root/'sources'/item['engine']/item['commit']/item['source_path']
    if path.exists():
        data=path.read_bytes()
        source='LOCAL_ALREADY_FROZEN'
    else:
        url=f"https://raw.githubusercontent.com/Sargon17-Green/Pastafarian-Calendar/{item['commit']}/{item['source_path']}"
        req=urllib.request.Request(url,headers={'User-Agent':'PastafarianSoakReadinessSourceLock-v016'})
        with urllib.request.urlopen(req,timeout=18) as response:
            data=response.read(SOURCE_MAX+1)
        source='GITHUB_IMMUTABLE_COMMIT'
        if len(data)>SOURCE_MAX:
            raise RuntimeError('source exceeds maximum allowed bytes')
    if git_blob(data)!=item['git_blob']:
        raise ValueError('GIT_BLOB_SHA1_MISMATCH '+item['engine']+' '+item['source_path'])
    if not path.exists():
        path.parent.mkdir(parents=True,exist_ok=True)
        temp=path.with_name(path.name+'.part')
        with temp.open('xb') as f:
            f.write(data);f.flush();os.fsync(f.fileno())
        os.replace(temp,path)
    if git_blob(path.read_bytes())!=item['git_blob']:
        raise RuntimeError('source changed after writing')
    return {'engine':item['engine'],'commit':item['commit'],'source_path':item['source_path'],
            'source_git_blob_sha1':item['git_blob'],'source_sha256':sha(data),
            'bytes':len(data),'provenance':source,'immutable_url':f"https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/{item['commit']}/{item['source_path']}",
            'local_relative_path':str(path.relative_to(root)).replace('\\','/')}


def syntax_check(root: Path, item: dict):
    path=root/'sources'/item['engine']/item['commit']/item['source_path']
    if item['engine']=='Python-Turkce':
        # python -I -m py_compile: never calls the converter entrypoint.
        cmd=[sys.executable,'-I','-m','py_compile',str(path)]
    else:
        node=shutil.which('node') or shutil.which('node.exe')
        if not node:
            return {'status':'BLOCKED_NODE_MISSING','file':item['source_path']}
        cmd=[node,'--check',str(path)]
    p=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=30,
                     cwd=str(path.parent),stdin=subprocess.DEVNULL,creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
    return {'status':'SYNTAX_PASS' if p.returncode==0 else 'SYNTAX_FAIL',
            'file':item['source_path'],'returncode':p.returncode,
            'stderr_tail':p.stderr.decode('utf8','replace')[-700:]}


def main():
    run=dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%SZ')+'_'+uuid.uuid4().hex[:8]
    root=Path(os.environ.get('PASTAFARI_SOAK_ROOT') or Path.home()/'Pastafarian-Converter-Soak').resolve()
    root.mkdir(parents=True,exist_ok=True)
    report={'version':VERSION,'run_id':run,'family':FAMILY,'status':'NOT_STARTED',
            'original_converter_executions':0,'soak_started':False,'installed_software':0,
            'github_main_mutations':0,'source_snapshots':[],'syntax_checks':[]}
    try:
        if os.name!='nt':
            report['status']='BLOCKED_WINDOWS_REQUIRED'
        elif shutil.disk_usage(root).free<DISK_FLOOR:
            report['status']='BLOCKED_DISK_HEADROOM'
        else:
            for item in PINNED:report['source_snapshots'].append(download_frozen(root,item))
            report['status']='SOURCE_SNAPSHOTS_SHA_LOCKED'
            ram=available_ram_windows()
            report['available_ram_bytes']=ram
            if ram<RAM_FLOOR:
                report['syntax_status']='SKIPPED_LOW_RAM'
            else:
                for item in PINNED:
                    report['syntax_checks'].append(syntax_check(root,item))
                report['syntax_status']='ALL_PASS' if all(x['status']=='SYNTAX_PASS' for x in report['syntax_checks']) else 'BLOCKED'
            if report['syntax_status']=='ALL_PASS':
                report['status']='TWO_ENGINE_SOURCES_AND_SYNTAX_PREFLIGHT_PASS'
            elif report['syntax_status']=='SKIPPED_LOW_RAM':
                report['status']='SOURCE_LOCKED_BUT_SYNTAX_WAITING_FOR_RAM'
            else:
                report['status']='SOURCE_LOCKED_SYNTAX_BLOCKED'
    except BaseException as e:
        report['status']='SOURCE_PREFLIGHT_BLOCKED'
        report['error']=type(e).__name__+': '+str(e)[:350]
    folder=root/'handoffs';folder.mkdir(parents=True,exist_ok=True)
    archive=folder/f'PASTAFARI_SOAK_SOURCES_v016_{run}_{report["status"]}.zip'
    part=archive.with_suffix('.zip.part')
    payload=(json.dumps(report,ensure_ascii=False,sort_keys=True,indent=2)+'\n').encode()
    with zipfile.ZipFile(part,'x',zipfile.ZIP_DEFLATED) as z:
        z.writestr('PREFLIGHT_REPORT.json',payload)
        z.writestr('SHA256SUMS.txt',sha(payload)+'  PREFLIGHT_REPORT.json\n')
        for item in report['source_snapshots']:
            path=root/item['local_relative_path']
            z.write(path,item['local_relative_path'])
    with zipfile.ZipFile(part) as z:
        if z.testzip():raise RuntimeError('archive CRC verification failed')
        for item in report['source_snapshots']:
            if git_blob(z.read(item['local_relative_path']))!=item['source_git_blob_sha1']:
                raise RuntimeError('archive source digest mismatch')
    os.replace(part,archive)
    report['evidence_zip_sha256']=sha(archive.read_bytes())
    print('PASTAFARI_SOAK_SOURCE_LOCK_JSON='+json.dumps(report,ensure_ascii=True,sort_keys=True),flush=True)
    return 0 if report['status'] in ('TWO_ENGINE_SOURCES_AND_SYNTAX_PREFLIGHT_PASS',
                                     'SOURCE_LOCKED_BUT_SYNTAX_WAITING_FOR_RAM') else 2

if __name__=='__main__':raise SystemExit(main())
