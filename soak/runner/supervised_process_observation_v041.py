#!/usr/bin/env python3
"""GitHub-CI-only real OS process observation fixture, v041.

Genuine subprocess supervision, but deliberately a SYNTHETIC, bounded Python
child. No Pastafarian F(c,t) computation; no Windows workload; no certification.
Prevents quietly equating v017 --raw-out data files to process stdout.
The fixture is stored in an immutable string here; the actual process's
interpreter file, command line, PID/creation ID, stdin/stdout/stderr, generated
raw/normalized files and resource limitations are observed by the parent.
"""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
try:
    import resource
except ImportError:  # Windows is deliberately blocked by _admit().
    resource = None
import shutil
import subprocess
import sys
import time

from native_execution_receipt_v038 import sha, _raw_lines, _normalized_lines

SCHEMA = "PASTAFARI_SUPERVISED_PROCESS_OBSERVATION_V041/1"
STATUS = "LINUX_SYNTHETIC_PROCESS_OBSERVED_NO_NATIVE_ATTESTATION"
AS_LIMIT_BYTES = 128 * 1024 * 1024
CPU_LIMIT_SECONDS = 3
WALL_LIMIT_SECONDS = 5
MAX_EVIDENCE_FILE = 64 * 1024
CASES = ("ok", "nonzero", "sleep")
CHILD = r'''#!/usr/bin/env python3
"""v041 test-only child; never imports the Pastafarian converter."""
import hashlib
import json
import os
from pathlib import Path
import sys
import time
mode, destination = sys.argv[1:]
work = Path(destination)
start = time.monotonic()
while not (work/"go.json").is_file():
    if time.monotonic()-start > 3:
        raise SystemExit(19)  # Never run test without supervisor GO.
    time.sleep(.01)
if mode == "sleep":
    print("SYNTHETIC_CHILD_INTENTIONALLY_SLEEPING", flush=True)
    time.sleep(30)
    raise SystemExit(0)
if mode == "nonzero":
    print("SYNTHETIC_CHILD_ERROR_PATH", file=sys.stderr, flush=True)
    raise SystemExit(17)
if mode != "ok":
    raise SystemExit(18)
raw_lines = []
norm_lines = []
for i, target in enumerate((-15056173, -15056172)):
    raw = (json.dumps({"kind":"SYNTHETIC_NOT_FCT",
                       "calculation_day":"-15055672",
                       "target_day":str(target),"day_number":i + 1},
                      sort_keys=True, separators=(",",":")) + "\n").encode()
    normalized = {"calculation_day":"-15055672",
                  "target_day":str(target),"year":"5000",
                  "cutlet_index":5,"day_in_cutlet":i + 1,
                  "month_index":7,"day_in_month":i + 1,
                  "cutlet_name_raw":"MOCK_CUTLET",
                  "month_name_raw":"MOCK_MONTH",
                  "source_raw_sha256":hashlib.sha256(raw).hexdigest()}
    raw_lines.append(raw)
    norm_lines.append((json.dumps(normalized,sort_keys=True,
                      separators=(",",":")) + "\n").encode())
for name, rows in (("raw-data.jsonl",raw_lines),
                   ("normalized-data.jsonl",norm_lines)):
    with (work/name).open("xb") as handle:
        handle.write(b"".join(rows))
        handle.flush()
        os.fsync(handle.fileno())
print("SYNTHETIC_PROGRESS_STDOUT_NOT_RAW_NATIVE_DATE_ROWS", flush=True)
print("SYNTHETIC_LOG_STDERR_CAPTURED", file=sys.stderr, flush=True)
'''

EXPECTED = ("raw-data.jsonl", "normalized-data.jsonl", "os-stdout.log",
            "os-stderr.log", "child-fixture.py", "process-evidence.json")


def canonical(data) -> bytes:
    return json.dumps(data,sort_keys=True,separators=(",",":"),
                      ensure_ascii=False,allow_nan=False).encode("utf8")


def sha_file(path: Path) -> str:
    h=hashlib.sha256()
    with path.open("rb") as stream:
        for part in iter(lambda:stream.read(65536),b""):
            h.update(part)
    return h.hexdigest()


def _durable_exclusive(path: Path, data: bytes):
    if path.exists():
        raise FileExistsError("never overwrite process evidence")
    staging = path.with_name(path.name + ".part")
    with staging.open("xb") as handle:
        handle.write(data)
        handle.flush()
        os.fsync(handle.fileno())
    os.replace(staging,path)
    directory=os.open(str(path.parent),os.O_RDONLY)
    try:os.fsync(directory)
    finally:os.close(directory)


def _pid_start_id(pid:int) -> str:
    # Linux /proc/PID/stat field 22; PID is not a sufficient process identity.
    info=Path("/proc")/str(pid)/"stat"
    fields=info.read_text(encoding="ascii").rsplit(")",1)[1].split()
    if fields[0] in ("Z","X"):
        raise ValueError("child already exited before initial identity sampling")
    return fields[19]


def _child_limit():
    os.nice(19)
    resource.setrlimit(resource.RLIMIT_AS,(AS_LIMIT_BYTES,AS_LIMIT_BYTES))
    resource.setrlimit(resource.RLIMIT_CPU,(CPU_LIMIT_SECONDS,CPU_LIMIT_SECONDS))
    os.umask(0o077)


def _admit(root:Path):
    if os.name != "posix" or not sys.platform.startswith("linux") or resource is None:
        raise RuntimeError("v041 supervisor test-only; Windows execution forbidden")
    if (os.environ.get("GITHUB_ACTIONS") != "true"
            or os.environ.get("RUNNER_OS") != "Linux"):
        raise RuntimeError("v041 only allowed in GitHub Actions Linux CI")
    if not root.is_dir():
        raise FileNotFoundError("owned test root must exist")
    if shutil.disk_usage(root).free < 100*1024*1024:
        raise RuntimeError("insufficient free disk for synthetic observation")
    if not Path("/proc/self/stat").is_file():
        raise RuntimeError("no Linux process identity source")


def _read_limited(path:Path) -> bytes:
    if not path.is_file() or path.is_symlink():
        raise ValueError("source evidence must be a regular owned file")
    if path.stat().st_size > MAX_EVIDENCE_FILE:
        raise ValueError("synthetic process evidence file exceeds size cap")
    return path.read_bytes()


def _status_invariant(raw:bytes, norm:bytes) -> int:
    rows=_raw_lines(raw,2)
    parsed=_normalized_lines(norm,2)
    for i,(source,item) in enumerate(zip(rows,parsed)):
        target=str(-15056173+i)
        if (item["source_raw_sha256"]!=sha(source)
                or item["calculation_day"]!="-15055672"
                or item["target_day"]!=target
                or item["year"]!="5000"):
            raise ValueError("synthetic output hash/coordinate mismatch")
        # Check fixture semantics strictly: cannot mislabel synthetic data as
        # a native calendar algorithm output.
        raw_item=json.loads(source)
        if raw_item != {
            "kind":"SYNTHETIC_NOT_FCT","calculation_day":"-15055672",
            "target_day":target,"day_number":i+1,
        }:
            raise ValueError("synthetic raw date mock unexpectedly changed")
    return len(rows)


def run_synthetic_ci_once(root:Path, *, mode:str="ok", wall_seconds:float=WALL_LIMIT_SECONDS) -> dict:
    """Launch ONE bounded fixture. No user computer and no real F(c,t)."""
    _admit(root)
    if mode not in CASES or not (0.2<=wall_seconds<=WALL_LIMIT_SECONDS):
        raise ValueError("unsupported or unsafe fixture mode/timeout")
    work=root/("process-observation-"+mode)
    work.mkdir(mode=0o700,parents=False,exist_ok=False)
    fixture=work/"child-fixture.py"
    _durable_exclusive(fixture,CHILD.encode("utf8"))
    interp=Path(sys.executable).resolve(strict=True)
    if not interp.is_file():
        raise ValueError("interpreter is not a regular file")
    initial_interpreter_sha=sha_file(interp)
    initial_fixture_sha=sha_file(fixture)
    if initial_fixture_sha!=sha(CHILD.encode("utf8")):
        raise RuntimeError("pinned executable child fixture mismatch")
    args=[str(interp), "-I", "-B", str(fixture), mode, str(work)]
    observed = {
        "schema":SCHEMA, "status":"NOT_COMPLETED",
        "mode":"SYNTHETIC_NOT_PASTAFARIAN",
        "fixture_case":mode,
        "os_name":os.name,"platform":sys.platform,
        "execution_argv":args,
        "command_sha256":sha(canonical(args)),
        "interpreter_executable_path":str(interp),
        "interpreter_executable_sha256":initial_interpreter_sha,
        "fixture_path":str(fixture),
        "fixture_sha256":initial_fixture_sha,
        "linux_resource_controls":{
            "nice_target":19,"address_space_limit_bytes":AS_LIMIT_BYTES,
            "cpu_time_seconds":CPU_LIMIT_SECONDS,
            "wall_timeout_seconds":wall_seconds,
        },
        "pid":None,"proc_start_id":None,"return_code":None,
        "stdout_sha256":None,"stderr_sha256":None,
        "raw_data_sha256":None,"normalized_data_sha256":None,
        "raw_data_rows":0,
        "process_exit_code_observed":False,
        "real_converter_calls":0,
        "independent_source_lineage_certified":False,
        "actual_native_execution_certified":False,
        "official_original_soak_years_certified":0,
        "windows_processes_started":0,
    }
    failed=None
    with (work/"os-stdout.log").open("xb") as standard_out, (work/"os-stderr.log").open("xb") as standard_err:
        proc=subprocess.Popen(args,cwd=str(work),stdin=subprocess.DEVNULL,
                              stdout=standard_out,stderr=standard_err,
                              close_fds=True,start_new_session=True,
                              preexec_fn=_child_limit)
        observed["pid"]=proc.pid
        try:
            observed["proc_start_id"]=_pid_start_id(proc.pid)
            _durable_exclusive(work/"go.json",canonical({
                "pid":proc.pid,
                "proc_start_id":observed["proc_start_id"],
                "command_sha256":observed["command_sha256"],
            }))
            proc.wait(timeout=wall_seconds)
        except subprocess.TimeoutExpired:
            # Allowed ONLY for synthetic bounded test child. Never apply a
            # wall-time kill to an actual slow soak converter.
            proc.kill()
            proc.wait(timeout=3)
            failed="SYNTHETIC_TEST_TIMEOUT_CHILD_TERMINATED"
        except BaseException as ex:
            if proc.poll() is None:
                proc.kill()
                proc.wait(timeout=3)
            failed="CHILD_IDENTITY_UNAVAILABLE:"+type(ex).__name__
        observed["return_code"]=proc.returncode
    observed["process_exit_code_observed"]=True
    if (initial_interpreter_sha!=sha_file(interp)
            or initial_fixture_sha!=sha_file(fixture)):
        failed="EXECUTABLE_OR_FIXTURE_BYTES_CHANGED_DURING_EXECUTION"
    for key,filename in (("stdout_sha256","os-stdout.log"),
                         ("stderr_sha256","os-stderr.log")):
        observed[key]=sha(_read_limited(work/filename))
    if failed is None and observed["return_code"]!=0:
        failed="NONZERO_CHILD_EXIT"
    if failed is None:
        try:
            raw=_read_limited(work/"raw-data.jsonl")
            normalized=_read_limited(work/"normalized-data.jsonl")
            observed["raw_data_rows"]=_status_invariant(raw,normalized)
            observed["raw_data_sha256"]=sha(raw)
            observed["normalized_data_sha256"]=sha(normalized)
            if (raw==_read_limited(work/"os-stdout.log")
                    or normalized==_read_limited(work/"os-stdout.log")):
                raise ValueError("OS stdout must not be conflated with native data files")
        except BaseException as ex:
            failed="INVALID_SYNTHETIC_DATA:"+type(ex).__name__
    observed["status"]=STATUS if failed is None else "SYNTHETIC_PROCESS_BLOCKED"
    observed["blocked_reason"]=failed
    _durable_exclusive(work/"process-evidence.json",canonical(observed))
    if failed is not None:
        raise RuntimeError("blocked synthetic process: "+failed)
    return observed


def verify_synthetic_evidence(work:Path) -> dict:
    """Re-read immutable bytes: a receipt alone cannot prove file integrity."""
    receipt=_read_limited(work/"process-evidence.json")
    obj=json.loads(receipt)
    if (obj.get("schema")!=SCHEMA or obj.get("status")!=STATUS
        or obj.get("mode")!="SYNTHETIC_NOT_PASTAFARIAN"
        or obj.get("fixture_case")!="ok"
        or obj.get("return_code")!=0
        or obj.get("process_exit_code_observed") is not True
        or obj.get("real_converter_calls")!=0
        or obj.get("official_original_soak_years_certified")!=0
        or obj.get("actual_native_execution_certified") is not False
        or obj.get("independent_source_lineage_certified") is not False
        or obj.get("blocked_reason") is not None):
        raise ValueError("invalid or overcertified process observation receipt")
    if receipt!=canonical(obj):
        raise ValueError("noncanonical immutable process observation record")
    if not isinstance(obj["pid"],int) or obj["pid"]<=0 or not obj["proc_start_id"]:
        raise ValueError("missing OS process identity")
    argv=obj["execution_argv"]
    if (argv!=[obj["interpreter_executable_path"],"-I","-B",
              obj["fixture_path"],"ok",str(work)]
            or obj["command_sha256"]!=sha(canonical(argv))):
        raise ValueError("observed command identity differs from recorded command")
    if obj["fixture_sha256"]!=sha(CHILD.encode("utf8")):
        raise ValueError("unexpected fixture source code")
    go=json.loads(_read_limited(work/"go.json"))
    if go!={"pid":obj["pid"],"proc_start_id":obj["proc_start_id"],
           "command_sha256":obj["command_sha256"]}:
        raise ValueError("supervisor GO does not match OS process identity")
    for name,field in (
        ("child-fixture.py","fixture_sha256"),
        ("os-stdout.log","stdout_sha256"),
        ("os-stderr.log","stderr_sha256"),
        ("raw-data.jsonl","raw_data_sha256"),
        ("normalized-data.jsonl","normalized_data_sha256"),
    ):
        if sha(_read_limited(work/name))!=obj[field]:
            raise ValueError("process evidence file altered: "+name)
    if sha_file(Path(obj["interpreter_executable_path"]))!=obj["interpreter_executable_sha256"]:
        raise ValueError("observed interpreter digest changed")
    if _status_invariant(_read_limited(work/"raw-data.jsonl"),
                         _read_limited(work/"normalized-data.jsonl"))!=2:
        raise ValueError("synthetic data row integrity failed")
    if obj["raw_data_rows"]!=2:
        raise ValueError("incomplete evidence")
    return {
        "schema":SCHEMA,
        "status":"SYNTHETIC_PROCESS_EVIDENCE_REVALIDATED_NOT_NATIVE_CERTIFIED",
        "captured_stdout_separate_from_raw_data":True,
        "captured_stderr_separate_from_normalized_data":True,
        "observed_process_id_bound_to_start_id":True,
        "original_native_full_years_certified":0,
        "linux_ci_only":True,
    }
