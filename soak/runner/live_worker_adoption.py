#!/usr/bin/env python3
"""One-shot synthetic surviving-child adoption proof for a future native soak.

Only one bounded, sleeping child is spawned by this fixture. It is not an
actual converter, scheduler, installer, watchdog, or recurring task.

Protocol: durable PENDING manifest -> child immutable identity & resource gate
-> durable GO -> parent crash -> new parent verifies *same* child creation ID
and adopts its append-only evidence -> DONE -> verify/cleanup evidence.

Production use will require additional controls and individual converter adapters.
"""
from __future__ import annotations

import argparse
import ctypes
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import secrets
import shutil
import subprocess
import sys
import time
import uuid
import zipfile

FAMILY = 'PASTAFARI_SOAK_READINESS'
VERSION = 'v013'
CPU_RATE = 500  # Windows CPU_RATE_CONTROL_HARD_CAP, 5% of aggregate CPUs
MIN_FREE_RAM = 512 * 1024 * 1024
MIN_DISK_FREE = 10 * 1024 * 1024 * 1024
STEP_SECONDS = 0.3
STEP_COUNT = 10
KERNEL = None
JOB_HANDLE = None


def utc() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat()


def encoded(obj) -> bytes:
    return (json.dumps(obj, sort_keys=True, ensure_ascii=False, separators=(',', ':')) + '\n').encode('utf-8')


def sha(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


def hashfile(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for b in iter(lambda: f.read(131072), b''):
            h.update(b)
    return h.hexdigest()


def durable_file(path: Path, data: bytes) -> None:
    if path.exists():
        raise RuntimeError('immutable file already exists: ' + path.name)
    stage = path.with_name(path.name + '.part')
    with stage.open('xb') as f:
        f.write(data)
        f.flush()
        os.fsync(f.fileno())
    os.replace(stage, path)
    if os.name != 'nt':
        fd = os.open(path.parent, os.O_RDONLY)
        try: os.fsync(fd)
        finally: os.close(fd)


def load_json(path: Path) -> dict:
    with path.open('rb') as f:
        return json.load(f)


def free_ram() -> int:
    if os.name == 'nt':
        class MEMORY(ctypes.Structure):
            _fields_ = [('length', ctypes.c_ulong), ('load', ctypes.c_ulong),
                        ('total', ctypes.c_ulonglong), ('avail', ctypes.c_ulonglong),
                        ('total_page', ctypes.c_ulonglong), ('avail_page', ctypes.c_ulonglong),
                        ('total_virt', ctypes.c_ulonglong), ('avail_virt', ctypes.c_ulonglong),
                        ('extended', ctypes.c_ulonglong)]
        m = MEMORY(); m.length = ctypes.sizeof(m)
        if not ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(m)):
            raise OSError('GlobalMemoryStatusEx')
        return int(m.avail)
    # Linux-only offline unit-test fallback, no native Windows certification.
    if Path('/proc/meminfo').is_file():
        for line in Path('/proc/meminfo').read_text().splitlines():
            if line.startswith('MemAvailable:'):
                return int(line.split()[1]) * 1024
    return 0


def _win_kernel():
    global KERNEL
    if KERNEL is None:
        KERNEL = ctypes.WinDLL('kernel32', use_last_error=True)
        k = KERNEL
        k.OpenProcess.argtypes = [ctypes.c_uint32, ctypes.c_int, ctypes.c_uint32]
        k.OpenProcess.restype = ctypes.c_void_p
        k.GetCurrentProcess.restype = ctypes.c_void_p
        k.CloseHandle.argtypes = [ctypes.c_void_p]
        k.CloseHandle.restype = ctypes.c_int
        k.GetProcessTimes.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p]
        k.GetProcessTimes.restype = ctypes.c_int
        k.WaitForSingleObject.argtypes = [ctypes.c_void_p, ctypes.c_uint32]
        k.WaitForSingleObject.restype = ctypes.c_uint32
        k.CreateJobObjectW.argtypes = [ctypes.c_void_p, ctypes.c_wchar_p]
        k.CreateJobObjectW.restype = ctypes.c_void_p
        k.AssignProcessToJobObject.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
        k.AssignProcessToJobObject.restype = ctypes.c_int
        k.SetInformationJobObject.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p, ctypes.c_uint32]
        k.SetInformationJobObject.restype = ctypes.c_int
        k.QueryInformationJobObject.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p, ctypes.c_uint32, ctypes.c_void_p]
        k.QueryInformationJobObject.restype = ctypes.c_int
        k.IsProcessInJob.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p]
        k.IsProcessInJob.restype = ctypes.c_int
        k.SetPriorityClass.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
        k.SetPriorityClass.restype = ctypes.c_int
        k.GetPriorityClass.argtypes = [ctypes.c_void_p]
        k.GetPriorityClass.restype = ctypes.c_ulong
    return KERNEL


def process_identity(pid: int) -> tuple[str | None, bool]:
    if os.name == 'nt':
        k = _win_kernel()
        h = k.OpenProcess(0x1000 | 0x00100000, 0, int(pid))  # query + synchronize
        if not h:
            return None, False
        try:
            if k.WaitForSingleObject(h, 0) != 0x102:  # WAIT_TIMEOUT = active
                return None, False
            create, exit_t, kernel_t, user_t = (ctypes.c_uint64() for _ in range(4))
            ok = k.GetProcessTimes(h, ctypes.byref(create), ctypes.byref(exit_t),
                                   ctypes.byref(kernel_t), ctypes.byref(user_t))
            if not ok:
                raise OSError('GetProcessTimes: ' + str(ctypes.get_last_error()))
            return str(create.value), True
        finally:
            k.CloseHandle(h)
    stat = Path(f'/proc/{pid}/stat')
    if not stat.exists():
        return None, False
    fields = stat.read_text().rsplit(')', 1)[1].split()
    # /proc/pid/stat: field 3 is index 0 here, field 22 is index 19.
    if fields[0] == 'Z':
        return None, False
    return fields[19], True


def self_job_cpu_guard() -> dict:
    """A worker-owned Job handle survives its parent supervisor crashing."""
    global JOB_HANDLE
    if os.name != 'nt':
        return {'state': 'LINUX_TEST_ONLY_NO_HARD_CAP', 'native_cpu_cap_certified': False}
    k = _win_kernel()
    class CpuRate(ctypes.Structure):
        _fields_ = [('flags', ctypes.c_uint32), ('rate', ctypes.c_uint32)]
    h = k.CreateJobObjectW(None, None)
    if not h:
        raise OSError('CreateJobObjectW: '+str(ctypes.get_last_error()))
    try:
        request = CpuRate(5, CPU_RATE)
        if not k.SetInformationJobObject(h, 15, ctypes.byref(request), ctypes.sizeof(request)):
            raise OSError('SetInformationJobObject: '+str(ctypes.get_last_error()))
        if not k.AssignProcessToJobObject(h, k.GetCurrentProcess()):
            raise OSError('AssignProcessToJobObject self: '+str(ctypes.get_last_error()))
        yes = ctypes.c_int(0)
        if not k.IsProcessInJob(k.GetCurrentProcess(), h, ctypes.byref(yes)) or not yes.value:
            raise RuntimeError('worker cannot verify its own Job membership')
        if not k.SetPriorityClass(k.GetCurrentProcess(), 0x4000):
            raise OSError('SetPriorityClass: '+str(ctypes.get_last_error()))
        returned = CpuRate()
        if not k.QueryInformationJobObject(h, 15, ctypes.byref(returned), ctypes.sizeof(returned), None):
            raise OSError('QueryInformationJobObject: '+str(ctypes.get_last_error()))
        if returned.flags != 5 or returned.rate != CPU_RATE or k.GetPriorityClass(k.GetCurrentProcess()) != 0x4000:
            raise RuntimeError('CPU governance readback does not match')
        JOB_HANDLE = h  # kept by worker until exit (NOT KILL_ON_JOB_CLOSE)
        return {'state': 'WORKER_OWNS_CPU_JOB', 'hard_cap_rate': returned.rate,
                'hard_cap_flags': returned.flags, 'in_job': bool(yes.value),
                'priority_readback': 0x4000, 'native_cpu_cap_certified': True,
                'note': 'configuration/membership verified; actual throttling effectiveness separate gate'}
    except BaseException:
        k.CloseHandle(h)
        raise


def worker(work: Path, nonce: str, script_sha: str) -> int:
    # Do not perform work if no immutable launch manifest exists.
    try:
        plan = load_json(work / 'manifest.json')
        if hashfile(Path(__file__).resolve()) != script_sha:
            raise RuntimeError('actual executing worker source digest mismatch')
        if plan['nonce_sha256'] != sha(nonce.encode()) or plan['script_sha256'] != script_sha:
            raise RuntimeError('worker launch manifest mismatch')
        guard = self_job_cpu_guard()
        pid = os.getpid()
        creation, alive = process_identity(pid)
        if not alive or not creation:
            raise RuntimeError('worker identity unavailable')
        identity = {'pid': pid, 'creation_id': creation, 'nonce_sha256': plan['nonce_sha256'],
                    'script_sha256': script_sha, 'guard': guard, 'created_utc': utc()}
        durable_file(work / 'identity.json', encoded(identity))
        # Waiting child consumes no useful compute and must never start data
        # generation before the parent has durably recorded process identity.
        until = time.monotonic() + 15
        while not (work / 'GO.json').exists():
            if time.monotonic() > until:
                durable_file(work / 'blocked.json', encoded({'error': 'PARENT_DID_NOT_COMMIT_GO'}))
                return 12
            time.sleep(.05)
        go = load_json(work / 'GO.json')
        if go['pid'] != pid or go['creation_id'] != creation or go['nonce_sha256'] != plan['nonce_sha256']:
            raise RuntimeError('GO identity mismatch')
        spool = work / 'output.jsonl'
        with spool.open('xb', buffering=0) as f:
            for i in range(STEP_COUNT):
                f.write(encoded({'kind': 'MOCK_NO_CONVERTER', 'ordinal': i,
                                 'plan_sha256': sha((work/'manifest.json').read_bytes())}))
                os.fsync(f.fileno())
                time.sleep(STEP_SECONDS)
        durable_file(work / 'done.json', encoded({'output_sha256': hashfile(spool),
                'count': STEP_COUNT, 'pid': pid, 'creation_id': creation, 'nonce_sha256': plan['nonce_sha256'],
                'complete_utc': utc()}))
        return 0
    except BaseException as exc:
        # Fail closed; don't overwrite another committed outcome.
        try:
            durable_file(work / 'blocked.json', encoded({'kind': type(exc).__name__, 'message': str(exc)[:300]}))
        except BaseException:
            pass
        return 11


def manifest(work: Path, script_sha: str, nonce: str) -> dict:
    return {'protocol': 'PASTAFARI_SOAK_OWNED_CHILD/1', 'kind': 'SYNTHETIC_ONLY',
            'run_name': work.name, 'script_sha256': script_sha,
            'nonce_sha256': sha(nonce.encode()), 'sleep_step_count': STEP_COUNT,
            'cpu_rate_requested': CPU_RATE, 'immutable': True}


def supervisor_start(work: Path, script: Path) -> int:
    if (work / 'manifest.json').exists():
        raise RuntimeError('refuse duplicate child launch: an ownership manifest already exists')
    nonce = secrets.token_hex(16)
    script_sha = hashfile(script)
    pinned_script = work / 'worker_source.py'
    durable_file(pinned_script, script.read_bytes())
    if hashfile(pinned_script) != script_sha:
        raise RuntimeError('durable frozen worker source does not match original')
    durable_file(work / 'manifest.json', encoded(manifest(work, script_sha, nonce)))
    cmd = [sys.executable, '-I', str(pinned_script), 'worker', '--work', str(work), '--nonce', nonce,
           '--script-sha', script_sha]
    kwargs = {}
    if os.name == 'nt':
        kwargs['creationflags'] = subprocess.CREATE_NEW_PROCESS_GROUP | subprocess.DETACHED_PROCESS
    with (work / 'stderr.log').open('xb') as err:
        proc = subprocess.Popen(cmd, cwd=str(work), stdin=subprocess.DEVNULL,
                                stdout=subprocess.DEVNULL, stderr=err, close_fds=True, **kwargs)
    # The child writes identity before accepting work; it will not compute
    # until the durable GO record matches its PID + OS process creation ID.
    deadline = time.monotonic() + 6
    while not (work / 'identity.json').exists():
        if proc.poll() is not None:
            raise RuntimeError('child exited before identity; no restart permitted')
        if time.monotonic() > deadline:
            raise RuntimeError('identity handshake timeout; child may exist; no restart permitted')
        time.sleep(.025)
    identity = load_json(work / 'identity.json')
    got, alive = process_identity(identity['pid'])
    if (not alive or got != identity['creation_id'] or identity['pid'] != proc.pid
            or identity['nonce_sha256'] != sha(nonce.encode())
            or identity['script_sha256'] != script_sha):
        raise RuntimeError('identity cannot be validated; no restart permitted')
    if os.name == 'nt' and not identity['guard']['native_cpu_cap_certified']:
        raise RuntimeError('worker lacks CPU cap; no computation allowed')
    durable_file(work / 'GO.json', encoded({'pid': proc.pid, 'creation_id': got,
                                            'nonce_sha256': identity['nonce_sha256']}))
    # Simulate *supervisor* crash; never signal or terminate the worker.
    os._exit(86)


def verify_finished(work: Path, identity: dict) -> dict:
    done = load_json(work / 'done.json')
    spool = work / 'output.jsonl'
    if done['nonce_sha256'] != identity['nonce_sha256'] or done['pid'] != identity['pid'] or done['creation_id'] != identity['creation_id']:
        raise RuntimeError('DONE mismatches initial native process identity')
    if done['count'] != STEP_COUNT or hashfile(spool) != done['output_sha256']:
        raise RuntimeError('DONE hash/count mismatch')
    rows = spool.read_bytes().splitlines()
    if len(rows) != STEP_COUNT:
        raise RuntimeError('incomplete spool')
    for i, line in enumerate(rows):
        row = json.loads(line)
        if row != {'kind': 'MOCK_NO_CONVERTER', 'ordinal': i, 'plan_sha256': sha((work/'manifest.json').read_bytes())}:
            raise RuntimeError('invalid or out-of-order spool row')
    return {'verified_rows': len(rows), 'output_sha256': done['output_sha256']}


def supervisor_resume(work: Path, *, wait_seconds: float = 10) -> dict:
    # Fail closed on unknown/missing evidence. Never launch any new worker here.
    manifest_data = load_json(work / 'manifest.json')
    identity = load_json(work / 'identity.json')
    if manifest_data['nonce_sha256'] != identity['nonce_sha256']:
        raise RuntimeError('manifest/identity nonce mismatch')
    if hashfile(work / 'worker_source.py') != manifest_data['script_sha256']:
        raise RuntimeError('frozen worker source digest mismatch')
    if manifest_data['script_sha256'] != identity['script_sha256']:
        raise RuntimeError('identity mismatches immutable script digest')
    if not (work / 'GO.json').is_file():
        raise RuntimeError('worker is not authorized to run; BLOCKED_UNVERIFIED_IN_FLIGHT')
    go = load_json(work / 'GO.json')
    if go != {k: identity[k] for k in ('pid', 'creation_id', 'nonce_sha256')}:
        raise RuntimeError('GO/identity mismatch')
    observed, alive = process_identity(identity['pid'])
    live_adopted = alive and observed == identity['creation_id']
    if alive and not live_adopted:
        raise RuntimeError('PID collision: process creation ID does not match')
    if not live_adopted and not (work / 'done.json').exists():
        raise RuntimeError('no verified live child and no durable DONE; never restart')
    until = time.monotonic() + wait_seconds
    while live_adopted and not (work / 'done.json').exists():
        if time.monotonic() >= until:
            raise RuntimeError('child still active; no timeout cancellation or duplicate spawn')
        if (work / 'blocked.json').exists():
            raise RuntimeError('child reported BLOCKED; no duplicate spawn')
        current, still_alive = process_identity(identity['pid'])
        if not still_alive or current != identity['creation_id']:
            raise RuntimeError('child exited without DONE; do not assume completion')
        time.sleep(.05)
    if not (work / 'done.json').exists():
        raise RuntimeError('missing DONE')
    result = verify_finished(work, identity)
    return {'status': 'LIVE_CHILD_ADOPTION_PASS' if live_adopted else 'FINISHED_CHILD_REPLAY_PASS',
            'live_adopted': live_adopted, 'same_pid': identity['pid'],
            'same_creation_id': identity['creation_id'], 'new_processes_launched': 0,
            'output': result, 'cpu_guard': identity['guard'], 'verified_comparisons_completed': 0,
            'real_converters_launched': 0}


def run_fixture(root: Path, script: Path) -> tuple[int, dict]:
    rid = dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%SZ') + '_' + uuid.uuid4().hex[:8]
    scratch = root / 'scratch'
    scratch.mkdir(parents=True, exist_ok=True)
    work = scratch / ('owned_worker_' + rid)
    work.mkdir()
    results = {'version': VERSION, 'run_id': rid, 'kind': 'SYNTHETIC_ONLY',
               'children_started': 0, 'peak_active_children': 0,
               'killed_for_slowness': 0, 'soak_started': False,
               'original_converter_started': False, 'status': 'NOT_STARTED'}
    try:
        disk = shutil.disk_usage(root).free
        ram = free_ram()
        results['free_disk_bytes'] = disk
        results['free_ram_bytes'] = ram
        if disk < MIN_DISK_FREE or ram < MIN_FREE_RAM:
            results['status'] = 'RESOURCE_ADMISSION_BLOCKED'
            return 2, results
        cmd = [sys.executable, '-I', str(script), 'supervisor-start', '--work', str(work)]
        a = subprocess.run(cmd, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                           stderr=subprocess.PIPE, timeout=12)
        results['supervisor_crash_exit'] = a.returncode
        results['supervisor_error'] = a.stderr.decode('utf8','replace')[-500:]
        if a.returncode != 86:
            results['status'] = 'SUPERVISOR_CRASH_NOT_INJECTED'
            return 2, results
        results['children_started'] = 1
        results['peak_active_children'] = 1
        result = supervisor_resume(work)
        results.update(result)
        if os.name == 'nt' and not result['cpu_guard']['native_cpu_cap_certified']:
            results['status'] = 'CPU_CAP_NOT_PROVEN'
            return 2, results
        if not result['live_adopted']:
            results['status'] = 'CHILD_FINISHED_BEFORE_ADOPTION_UNVERIFIED'
            return 2, results
        # Keep original worker evidence in one evidence ZIP. Never erase it
        # until the ZIP has passed CRC, SHA and immutable source checks.
        handoff = root / 'handoffs'
        handoff.mkdir(parents=True, exist_ok=True)
        dest = handoff / f'PASTAFARI_SOAK_ADOPTION_{VERSION}_{rid}.zip'
        tmp = dest.with_suffix('.zip.part')
        files = sorted(p for p in work.iterdir() if p.is_file())
        with zipfile.ZipFile(tmp, 'x', zipfile.ZIP_DEFLATED) as z:
            for p in files:
                z.write(p, 'worker/' + p.name)
            z.writestr('result.json', encoded(results))
            z.writestr('sha256s.json', encoded({p.name: hashfile(p) for p in files}))
        with zipfile.ZipFile(tmp) as z:
            if z.testzip() is not None:
                raise RuntimeError('invalid evidence ZIP')
            for p in files:
                if sha(z.read('worker/' + p.name)) != hashfile(p):
                    raise RuntimeError('ZIP receipt differs from disk')
        os.replace(tmp, dest)
        results['evidence_sha256'] = hashfile(dest)
        results['status'] = 'LIVE_CHILD_ADOPTION_PASS'
        # The child is finished, so owned scratch can now be removed safely.
        shutil.rmtree(work)
        results['owned_scratch_cleaned'] = True
        return 0, results
    except BaseException as exc:
        # Never kill or remove a still-running child or its evidence.
        results['status'] = 'LIVE_ADOPTION_BLOCKED'
        results['error'] = type(exc).__name__ + ': ' + str(exc)[:280]
        results['retained_owned_work'] = str(work)
        return 2, results


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('mode', nargs='?', default='fixture', choices=('worker', 'supervisor-start', 'fixture'))
    ap.add_argument('--work', type=Path)
    ap.add_argument('--nonce')
    ap.add_argument('--script-sha')
    ap.add_argument('--root', type=Path)
    args = ap.parse_args(argv)
    script = Path(__file__).resolve()
    if args.mode == 'worker':
        return worker(args.work.resolve(), args.nonce, args.script_sha)
    if args.mode == 'supervisor-start':
        return supervisor_start(args.work.resolve(), script)
    if args.root is None:
        args.root = Path(os.environ.get('PASTAFARI_SOAK_ROOT') or Path.home()/'Pastafarian-Converter-Soak')
    args.root.mkdir(parents=True, exist_ok=True)
    code, result = run_fixture(args.root.resolve(), script)
    if code:
        # A guarded refusal must itself leave a verifiable receipt, even if
        # there was not enough RAM to start the first child.
        folder = args.root/'handoffs'
        folder.mkdir(parents=True, exist_ok=True)
        p = folder / ('PASTAFARI_SOAK_ADOPTION_'+VERSION+'_'+result['run_id']+'_BLOCKED.zip')
        with zipfile.ZipFile(p, 'x', compression=zipfile.ZIP_DEFLATED) as z:
            z.writestr('result.json', encoded(result))
        result['blocked_receipt_sha256'] = hashfile(p)
    print('PASTAFARI_SOAK_LIVE_ADOPTION_JSON=' + json.dumps(result, sort_keys=True, ensure_ascii=False), flush=True)
    return code


if __name__ == '__main__':
    raise SystemExit(main())
