"""Strict offline parser for the bounded Post55 D2 benign-child strace artifact.

This parser accepts only the observed Python -> clone3 -> /usr/bin/true trace
shape. It does not run strace, contact GitHub, authenticate provider pins, observe
the calendar producer, or attest the host OS. Success is conditional on external
provider readback pins supplied by the caller.

Run: python3 soak/post55_observer_trace.py --self-test
      python3 soak/post55_observer_trace.py --bundle artifact.zip --external-pins pins.json
"""
from __future__ import annotations

import argparse
import decimal
import hashlib
import io
import json
import re
import stat
import time
import unittest
import uuid
import warnings
import zipfile
from pathlib import Path

MIB = 1024 * 1024
TRACE_LIMIT = MIB
STDERR_LIMIT = MIB
RECEIPT_LIMIT = 256 * 1024
JSON_LIMIT = RECEIPT_LIMIT
OUTER_LIMIT = TRACE_LIMIT + STDERR_LIMIT + RECEIPT_LIMIT + MIB
MEMBERS = {"observer.stderr": STDERR_LIMIT, "raw.trace": TRACE_LIMIT,
           "receipt.json": RECEIPT_LIMIT}
PIN_KEYS = {
    "schema", "repository", "branch", "source_sha", "run_id", "run_attempt",
    "run_status", "run_conclusion", "job_id", "job_name", "job_status",
    "job_conclusion", "artifact_id", "artifact_name", "artifact_size_bytes",
    "artifact_digest", "artifact_run_id", "artifact_head_branch", "artifact_head_sha",
}
RECEIPT_KEYS = {
    "schema", "scope", "source_sha", "repository", "ref", "run_id", "run_attempt",
    "job_key", "runner_os", "runner_arch", "image_os", "image_version", "os_release",
    "kernel", "boot_id", "ptrace_scope", "strace_path", "strace_version",
    "strace_sha256", "observer_exit", "timeout_seconds", "raw_limit_bytes",
    "capture_status", "reason", "CI_PROCESS_OBSERVATION", "OS_ATTESTATION",
    "monotonic_start_ns", "monotonic_end_ns", "raw_trace_bytes", "raw_trace_sha256",
    "stderr_bytes", "stderr_sha256", "argv",
}
EXPECTED_CODE = "import subprocess; subprocess.run(['/usr/bin/true'], check=True)"
EXPECTED_ARGV = [
    "/usr/bin/strace", "-f", "-ttt", "-s", "4096", "-e",
    "trace=execve,execveat,clone,clone3,fork,vfork,exit,exit_group",
    "-o", "observer-evidence/raw.trace", "--", "/usr/bin/python3", "-I", "-S",
    "-c", EXPECTED_CODE,
]

class Rejected(ValueError):
    """The bundle or its external identity pins are malformed or inconsistent."""

class NotAssessed(ValueError):
    """The trace is incomplete, unsupported, ambiguous, or outside this parser's scope."""

def require(condition: bool, code: str, exc=Rejected) -> None:
    if not condition:
        raise exc(code)

def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def hex_digest(value, length: int = 64) -> bool:
    return isinstance(value, str) and re.fullmatch(r"[0-9a-f]{%d}" % length, value) is not None

def pairs(items):
    result = {}
    for key, value in items:
        require(key not in result, "DUPLICATE_JSON_KEY")
        result[key] = value
    return result

def parse_json(data: bytes, limit: int) -> dict:
    require(len(data) <= limit, "OVERSIZE")
    try:
        value = json.loads(data.decode("utf-8"), object_pairs_hook=pairs,
                           parse_constant=lambda _: (_ for _ in ()).throw(Rejected("BAD_JSON")))
    except (UnicodeError, json.JSONDecodeError, RecursionError) as exc:
        raise Rejected("BAD_JSON") from exc
    require(isinstance(value, dict), "BAD_SCHEMA")
    return value

def safe_name(name: str) -> bool:
    return (isinstance(name, str) and bool(name) and "\\" not in name
            and ":" not in name and "\x00" not in name and not name.startswith("/")
            and all(part not in ("", ".", "..") for part in name.split("/")))

def read_members(data: bytes, limits: dict[str, int]) -> dict[str, bytes]:
    require(len(data) <= OUTER_LIMIT, "OVERSIZE")
    try:
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            infos = archive.infolist()
            names = [info.filename for info in infos]
            require(len(set(names)) == len(names), "DUPLICATE_MEMBER")
            require(len(infos) == len(limits) and set(names) == set(limits), "MEMBER_SET")
            result = {}
            deadline = time.monotonic() + 10
            for info in infos:
                kind = stat.S_IFMT(info.external_attr >> 16)
                require(safe_name(info.filename) and info.orig_filename == info.filename
                        and kind in (0, stat.S_IFREG) and not info.is_dir(), "UNSAFE_MEMBER")
                require(not info.flag_bits & 1 and
                        info.compress_type in (zipfile.ZIP_STORED, zipfile.ZIP_DEFLATED),
                        "UNSUPPORTED_ZIP")
                limit = limits[info.filename]
                require(0 <= info.file_size <= limit and info.compress_size <= limit,
                        "OVERSIZE")
                chunks, count = [], 0
                with archive.open(info) as member:
                    while True:
                        require(time.monotonic() < deadline, "TIMEOUT")
                        block = member.read(65536)
                        if not block:
                            break
                        count += len(block)
                        require(count <= limit, "OVERSIZE")
                        chunks.append(block)
                require(count == info.file_size, "SIZE_MISMATCH")
                result[info.filename] = b"".join(chunks)
            return result
    except Rejected:
        raise
    except (zipfile.BadZipFile, RuntimeError, NotImplementedError, OSError) as exc:
        raise Rejected("BAD_ZIP") from exc

def _prefix(line: str):
    match = re.match(r"^(?P<pid>[1-9][0-9]*)\s+(?P<ts>[0-9]+\.[0-9]{1,9})\s+(?P<body>.*)$", line)
    require(match is not None, "TRACE_GRAMMAR_UNSUPPORTED", NotAssessed)
    return int(match.group("pid")), decimal.Decimal(match.group("ts")), match.group("body")

def parse_trace(data: bytes) -> dict:
    """Parse the one observed, complete parent/child trace grammar; no loose fallback."""
    try:
        text = data.decode("utf-8")
    except UnicodeError as exc:
        raise NotAssessed("TRACE_ENCODING_UNSUPPORTED") from exc
    require(b"\x00" not in data, "TRACE_NUL", NotAssessed)
    lines = text.splitlines()
    require(len(lines) == 10 and all(lines), "TRACE_INCOMPLETE_OR_EXTRA", NotAssessed)
    parsed = [_prefix(line) for line in lines]
    times = [entry[1] for entry in parsed]
    require(all(times[i] < times[i + 1] for i in range(len(times) - 1)),
            "TRACE_TIME_ORDER", NotAssessed)

    pids, _, bodies = zip(*parsed)
    # Parent starts the exact isolated Python child launcher.
    m1 = re.fullmatch(
        r'execve\("/usr/bin/python3", \["/usr/bin/python3", "-I", "-S", "-c", '
        r'"import subprocess; subprocess\.run\(\[\'/usr/bin/true\'\], check=True\)"\], '
        r'0x[0-9a-f]+ /\* ([1-9][0-9]*) vars \*/\) = 0', bodies[0])
    require(m1 is not None, "PARENT_EXECVE_UNSUPPORTED", NotAssessed)
    parent = pids[0]
    env_count = int(m1.group(1))

    # One clone3 only, with the exact vfork-like flags observed on the pinned runner.
    m2 = re.fullmatch(
        r'clone3\(\{flags=CLONE_VM\|CLONE_VFORK\|CLONE_CLEAR_SIGHAND, '
        r'exit_signal=SIGCHLD, stack=0x[0-9a-f]+, stack_size=0x([0-9a-f]+)\}, '
        r'([1-9][0-9]*) <unfinished \.\.\.>', bodies[1])
    require(m2 is not None and pids[1] == parent, "CLONE3_UNSUPPORTED", NotAssessed)
    stack_size, clone_args_size = int(m2.group(1), 16), int(m2.group(2))
    require(stack_size > 0 and clone_args_size > 0, "CLONE3_ARGUMENTS", NotAssessed)

    # The only child exec is /usr/bin/true; its environment is summarized, never dumped.
    m3 = re.fullmatch(
        r'execve\("/usr/bin/true", \["/usr/bin/true"\], '
        r'0x[0-9a-f]+ /\* ([1-9][0-9]*) vars \*/ <unfinished \.\.\.>', bodies[2])
    require(m3 is not None, "CHILD_EXECVE_UNSUPPORTED", NotAssessed)
    child = pids[2]
    require(child != parent and int(m3.group(1)) == env_count, "PROCESS_IDENTITY", NotAssessed)

    m4 = re.fullmatch(r'<\.\.\. clone3 resumed>\) = ([1-9][0-9]*)', bodies[3])
    require(m4 is not None and pids[3] == parent and int(m4.group(1)) == child,
            "CLONE3_RESUME_MISMATCH", NotAssessed)
    require(re.fullmatch(r'<\.\.\. execve resumed>\) = 0', bodies[4]) is not None
            and pids[4] == child, "CHILD_EXECVE_RESUME_MISMATCH", NotAssessed)
    require(re.fullmatch(r'exit_group\(0\)\s+= \?', bodies[5]) is not None
            and pids[5] == child, "CHILD_EXIT_UNSUPPORTED", NotAssessed)
    require(re.fullmatch(r'\+\+\+ exited with 0 \+\+\+', bodies[6]) is not None
            and pids[6] == child, "CHILD_LIFETIME_UNSUPPORTED", NotAssessed)
    m8 = re.fullmatch(
        r'--- SIGCHLD \{si_signo=SIGCHLD, si_code=CLD_EXITED, si_pid=([1-9][0-9]*), '
        r'si_uid=([0-9]+), si_status=0, si_utime=0, si_stime=0\} ---', bodies[7])
    require(m8 is not None and pids[7] == parent and int(m8.group(1)) == child,
            "SIGCHLD_MISMATCH", NotAssessed)
    require(re.fullmatch(r'exit_group\(0\)\s+= \?', bodies[8]) is not None
            and pids[8] == parent, "PARENT_EXIT_UNSUPPORTED", NotAssessed)
    require(re.fullmatch(r'\+\+\+ exited with 0 \+\+\+', bodies[9]) is not None
            and pids[9] == parent, "PARENT_LIFETIME_UNSUPPORTED", NotAssessed)

    return {
        "trace_events": len(lines), "parent_pid": parent, "child_pid": child,
        "environment_count_placeholder": env_count,
        "wall_trace_elapsed_ms": round(float(times[-1] - times[0]) * 1000, 3),
        "child_exec": "/usr/bin/true", "child_exit": 0, "parent_exit": 0,
        "observed_processes": 2,
    }

def validate(bundle: bytes, pins: dict) -> dict:
    """Offline validation conditional on externally fetched GitHub run/job/artifact pins."""
    require(isinstance(pins, dict) and set(pins) == PIN_KEYS
            and pins.get("schema") == "observer-provider-readback-v1", "BAD_PINS_SCHEMA")
    for key in ("run_id", "run_attempt", "job_id", "artifact_id", "artifact_size_bytes", "artifact_run_id"):
        require(type(pins.get(key)) is int and pins[key] > 0, "BAD_PROVIDER_INTEGER")
    for key in ("repository", "branch", "source_sha", "run_status", "run_conclusion", "job_name",
                "job_status", "job_conclusion", "artifact_name", "artifact_digest",
                "artifact_head_branch", "artifact_head_sha"):
        require(isinstance(pins.get(key), str) and pins[key], "BAD_PROVIDER_FIELD")
    require(pins["repository"] == "Sargon17-Green/Pastafarian-Calendar"
            and pins["branch"] == "Kotlin+Cymraeg"
            and hex_digest(pins["source_sha"], 40), "PROVIDER_IDENTITY")
    require(pins["run_status"] == pins["job_status"] == "completed"
            and pins["run_conclusion"] == pins["job_conclusion"] == "success",
            "PROVIDER_STATUS")
    require(pins["job_name"] == "post55-observer-capability", "PROVIDER_JOB")
    require(pins["artifact_name"] ==
            f"kotlin-cymraeg-d2-observer-{pins['run_id']}-{pins['run_attempt']}",
            "PROVIDER_ARTIFACT_NAME")
    require(pins["artifact_run_id"] == pins["run_id"]
            and pins["artifact_head_branch"] == pins["branch"]
            and pins["artifact_head_sha"] == pins["source_sha"], "PROVIDER_ARTIFACT_IDENTITY")
    require(re.fullmatch(r"sha256:[0-9a-f]{64}", pins["artifact_digest"]) is not None,
            "PROVIDER_DIGEST_FORMAT")
    require(len(bundle) == pins["artifact_size_bytes"]
            and digest(bundle) == pins["artifact_digest"][7:], "PROVIDER_DIGEST")

    members = read_members(bundle, MEMBERS)
    receipt = parse_json(members["receipt.json"], RECEIPT_LIMIT)
    require(set(receipt) == RECEIPT_KEYS and receipt.get("schema") == "post55-observer-capability-d2-v1",
            "BAD_RECEIPT_SCHEMA")
    require(receipt.get("scope") == "benign child only; no producer, no Java, no certification",
            "SCOPE_MISMATCH")
    require(receipt.get("repository") == pins["repository"]
            and receipt.get("ref") == "refs/heads/Kotlin+Cymraeg"
            and receipt.get("source_sha") == pins["source_sha"]
            and receipt.get("run_id") == str(pins["run_id"])
            and receipt.get("run_attempt") == str(pins["run_attempt"])
            and receipt.get("job_key") == "post55-observer-capability", "RECEIPT_IDENTITY")
    require(receipt.get("runner_os") == "Linux" and receipt.get("runner_arch") == "X64"
            and receipt.get("image_os") == "ubuntu26"
            and isinstance(receipt.get("image_version"), str) and receipt["image_version"]
            and isinstance(receipt.get("os_release"), str) and receipt["os_release"].startswith("Ubuntu ")
            and isinstance(receipt.get("kernel"), str) and receipt["kernel"]
            and isinstance(receipt.get("ptrace_scope"), str) and receipt["ptrace_scope"],
            "RUNNER_METADATA", NotAssessed)
    try:
        uuid.UUID(receipt["boot_id"])
    except (ValueError, TypeError, AttributeError) as exc:
        raise NotAssessed("BOOT_ID_UNAVAILABLE") from exc
    require(receipt.get("strace_path") == "/usr/bin/strace"
            and isinstance(receipt.get("strace_version"), str)
            and receipt["strace_version"].startswith("strace -- version ")
            and hex_digest(receipt.get("strace_sha256")), "STRACE_METADATA", NotAssessed)
    require(receipt.get("observer_exit") == 0 and receipt.get("timeout_seconds") == 15
            and receipt.get("raw_limit_bytes") == TRACE_LIMIT
            and receipt.get("capture_status") == "CAPTURED_REVIEW_REQUIRED"
            and receipt.get("reason") == "raw_grammar_not_yet_assessed"
            and receipt.get("CI_PROCESS_OBSERVATION") == "NOT_ASSESSED"
            and receipt.get("OS_ATTESTATION") is False, "CAPTURE_STATE")
    start, end = receipt.get("monotonic_start_ns"), receipt.get("monotonic_end_ns")
    require(type(start) is int and type(end) is int and 0 < end - start <= 15 * 1_000_000_000,
            "MONOTONIC_WINDOW", NotAssessed)

    trace, stderr = members["raw.trace"], members["observer.stderr"]
    require(receipt.get("raw_trace_bytes") == len(trace)
            and receipt.get("raw_trace_sha256") == digest(trace), "TRACE_DIGEST")
    require(receipt.get("stderr_bytes") == len(stderr)
            and receipt.get("stderr_sha256") == digest(stderr), "STDERR_DIGEST")
    require(len(stderr) == 0, "STDERR_NOT_EMPTY", NotAssessed)
    require(receipt.get("argv") == EXPECTED_ARGV, "OBSERVER_ARGV", NotAssessed)
    observed = parse_trace(trace)
    return {
        "PROCESS_TRACE": "PASS_BENIGN_CHILD_CHAIN_CONDITIONAL_ON_EXTERNAL_PROVIDER_PINS",
        "CI_PROCESS_OBSERVATION": "PASS_BENIGN_CHILD_TRACE_ONLY",
        "OS_ATTESTATION": False,
        "PROVIDER_PINS_AUTHENTICATED_BY_PARSER": False,
        "PRODUCER_OBSERVED": False,
        "JAVA_PRODUCER_OBSERVED": False,
        "FULL_CALENDAR_CERTIFICATION": False,
        "source_sha": pins["source_sha"], "run_id": pins["run_id"],
        "run_attempt": pins["run_attempt"], "job_id": pins["job_id"],
        "artifact_id": pins["artifact_id"],
        "artifact_sha256": pins["artifact_digest"][7:],
        "raw_trace_sha256": receipt["raw_trace_sha256"],
        "strace_sha256": receipt["strace_sha256"],
        **observed,
    }

def fixture_trace() -> bytes:
    """Independent synthetic trace fixture matching only the observed syscall grammar."""
    return ("""2481  1795635272.592562 execve(\"/usr/bin/python3\", [\"/usr/bin/python3\", \"-I\", \"-S\", \"-c\", \"import subprocess; subprocess.run(['/usr/bin/true'], check=True)\"], 0x7ffd7838b178 /* 112 vars */) = 0
2481  1795635272.631055 clone3({flags=CLONE_VM|CLONE_VFORK|CLONE_CLEAR_SIGHAND, exit_signal=SIGCHLD, stack=0x7f998417f000, stack_size=0x9000}, 88 <unfinished ...>
2482  1795635272.631489 execve(\"/usr/bin/true\", [\"/usr/bin/true\"], 0x7ffeb8ba7848 /* 112 vars */ <unfinished ...>
2481  1795635272.631770 <... clone3 resumed>) = 2482
2482  1795635272.631874 <... execve resumed>) = 0
2482  1795635272.633673 exit_group(0)   = ?
2482  1795635272.633781 +++ exited with 0 +++
2481  1795635272.633834 --- SIGCHLD {si_signo=SIGCHLD, si_code=CLD_EXITED, si_pid=2482, si_uid=1001, si_status=0, si_utime=0, si_stime=0} ---
2481  1795635272.637570 exit_group(0)   = ?
2481  1795635272.637890 +++ exited with 0 +++
""").encode("utf-8")

def fixture_bundle(trace: bytes | None = None, stderr: bytes = b"", receipt_patch=None, pin_patch=None):
    trace = fixture_trace() if trace is None else trace
    receipt = {
        "schema": "post55-observer-capability-d2-v1",
        "scope": "benign child only; no producer, no Java, no certification",
        "source_sha": "7e944531680950e31c4f402e5a55e7b73c930af4",
        "repository": "Sargon17-Green/Pastafarian-Calendar",
        "ref": "refs/heads/Kotlin+Cymraeg", "run_id": "45686518550", "run_attempt": "1",
        "job_key": "post55-observer-capability", "runner_os": "Linux", "runner_arch": "X64",
        "image_os": "ubuntu26", "image_version": "20261116.202.1",
        "os_release": "Ubuntu 26.04.1 LTS", "kernel": "7.0.0-1020-azure",
        "boot_id": "e53dd9d5-3fed-4488-931d-c27965933895", "ptrace_scope": "1",
        "strace_path": "/usr/bin/strace", "strace_version": "strace -- version 6.19",
        "strace_sha256": "66e7dbc556b949ba29efc6b02948580857b9a9c99adacf949cdc10c57d930fc5",
        "observer_exit": 0, "timeout_seconds": 15, "raw_limit_bytes": TRACE_LIMIT,
        "capture_status": "CAPTURED_REVIEW_REQUIRED", "reason": "raw_grammar_not_yet_assessed",
        "CI_PROCESS_OBSERVATION": "NOT_ASSESSED", "OS_ATTESTATION": False,
        "monotonic_start_ns": 24364836466, "monotonic_end_ns": 24429931760,
        "raw_trace_bytes": len(trace), "raw_trace_sha256": digest(trace),
        "stderr_bytes": len(stderr), "stderr_sha256": digest(stderr), "argv": EXPECTED_ARGV,
    }
    receipt.update(receipt_patch or {})
    out = io.BytesIO()
    with zipfile.ZipFile(out, "w", compression=zipfile.ZIP_DEFLATED) as z:
        z.writestr("observer.stderr", stderr)
        z.writestr("raw.trace", trace)
        z.writestr("receipt.json", json.dumps(receipt, sort_keys=True, separators=(",", ":")))
    bundle = out.getvalue()
    pins = {
        "schema": "observer-provider-readback-v1",
        "repository": "Sargon17-Green/Pastafarian-Calendar", "branch": "Kotlin+Cymraeg",
        "source_sha": "7e944531680950e31c4f402e5a55e7b73c930af4",
        "run_id": 45686518550, "run_attempt": 1, "run_status": "completed",
        "run_conclusion": "success", "job_id": 139460442255,
        "job_name": "post55-observer-capability", "job_status": "completed",
        "job_conclusion": "success", "artifact_id": 15056976560,
        "artifact_name": "kotlin-cymraeg-d2-observer-45686518550-1",
        "artifact_size_bytes": len(bundle), "artifact_digest": "sha256:" + digest(bundle),
        "artifact_run_id": 45686518550, "artifact_head_branch": "Kotlin+Cymraeg",
        "artifact_head_sha": "7e944531680950e31c4f402e5a55e7b73c930af4",
    }
    pins.update(pin_patch or {})
    return bundle, pins

class Controls(unittest.TestCase):
    def test_positive(self):
        bundle, pins = fixture_bundle()
        result = validate(bundle, pins)
        self.assertEqual(result["CI_PROCESS_OBSERVATION"], "PASS_BENIGN_CHILD_TRACE_ONLY")
        self.assertFalse(result["OS_ATTESTATION"])
        self.assertFalse(result["FULL_CALENDAR_CERTIFICATION"])
        self.assertEqual(result["trace_events"], 10)

    def test_P1_provider_run_status(self):
        bundle, pins = fixture_bundle(pin_patch={"run_status": "in_progress"})
        with self.assertRaisesRegex(Rejected, "^PROVIDER_STATUS$"):
            validate(bundle, pins)

    def test_P2_provider_job_status(self):
        bundle, pins = fixture_bundle(pin_patch={"job_conclusion": "failure"})
        with self.assertRaisesRegex(Rejected, "^PROVIDER_STATUS$"):
            validate(bundle, pins)

    def test_P3_provider_artifact_digest(self):
        bundle, pins = fixture_bundle(pin_patch={"artifact_digest": "sha256:" + "0" * 64})
        with self.assertRaisesRegex(Rejected, "^PROVIDER_DIGEST$"):
            validate(bundle, pins)

    def test_P4_source_identity(self):
        bundle, pins = fixture_bundle()
        pins["source_sha"] = "0" * 40
        pins["artifact_head_sha"] = "0" * 40
        with self.assertRaisesRegex(Rejected, "^RECEIPT_IDENTITY$"):
            validate(bundle, pins)

    def test_P5_wrong_artifact_run(self):
        bundle, pins = fixture_bundle(pin_patch={"artifact_run_id": 1})
        with self.assertRaisesRegex(Rejected, "^PROVIDER_ARTIFACT_IDENTITY$"):
            validate(bundle, pins)

    def test_P6_wrong_artifact_name(self):
        bundle, pins = fixture_bundle(pin_patch={"artifact_name": "other-artifact"})
        with self.assertRaisesRegex(Rejected, "^PROVIDER_ARTIFACT_NAME$"):
            validate(bundle, pins)

    def test_T1_extra_trace_event(self):
        trace = fixture_trace() + b"2481  1795635272.638000 getpid() = 2481\n"
        bundle, pins = fixture_bundle(trace=trace)
        with self.assertRaisesRegex(NotAssessed, "^TRACE_INCOMPLETE_OR_EXTRA$"):
            validate(bundle, pins)

    def test_T2_truncated_trace(self):
        trace = b"\n".join(fixture_trace().splitlines()[:-1]) + b"\n"
        bundle, pins = fixture_bundle(trace=trace)
        with self.assertRaisesRegex(NotAssessed, "^TRACE_INCOMPLETE_OR_EXTRA$"):
            validate(bundle, pins)

    def test_T3_unknown_syscall(self):
        trace = fixture_trace().replace(b"clone3({", b"clone({", 1)
        bundle, pins = fixture_bundle(trace=trace)
        with self.assertRaisesRegex(NotAssessed, "^CLONE3_UNSUPPORTED$"):
            validate(bundle, pins)

    def test_T4_child_pid_mismatch(self):
        trace = fixture_trace().replace(b"si_pid=2482", b"si_pid=2483")
        bundle, pins = fixture_bundle(trace=trace)
        with self.assertRaisesRegex(NotAssessed, "^SIGCHLD_MISMATCH$"):
            validate(bundle, pins)

    def test_T5_time_order(self):
        lines = fixture_trace().splitlines()
        lines[4] = lines[4].replace(b"1795635272.631874", b"1795635272.600000")
        bundle, pins = fixture_bundle(trace=b"\n".join(lines) + b"\n")
        with self.assertRaisesRegex(NotAssessed, "^TRACE_TIME_ORDER$"):
            validate(bundle, pins)

    def test_T6_stderr_nonempty(self):
        bundle, pins = fixture_bundle(stderr=b"strace warning\n")
        with self.assertRaisesRegex(NotAssessed, "^STDERR_NOT_EMPTY$"):
            validate(bundle, pins)

    def test_T7_wrong_argv(self):
        bundle, pins = fixture_bundle(receipt_patch={"argv": ["/usr/bin/strace", "-f"]})
        with self.assertRaisesRegex(NotAssessed, "^OBSERVER_ARGV$"):
            validate(bundle, pins)

    def test_T8_bad_monotonic_window(self):
        bundle, pins = fixture_bundle(receipt_patch={"monotonic_end_ns": 1})
        with self.assertRaisesRegex(NotAssessed, "^MONOTONIC_WINDOW$"):
            validate(bundle, pins)

    def test_T9_nonzero_child_exit(self):
        trace = fixture_trace().replace(b"exit_group(0)   = ?\n2482  1795635272.633781 +++ exited with 0 +++",
                                         b"exit_group(1)   = ?\n2482  1795635272.633781 +++ exited with 1 +++")
        bundle, pins = fixture_bundle(trace=trace)
        with self.assertRaisesRegex(NotAssessed, "^CHILD_EXIT_UNSUPPORTED$"):
            validate(bundle, pins)

    def test_T10_trace_digest_tamper(self):
        bundle, pins = fixture_bundle()
        with zipfile.ZipFile(io.BytesIO(bundle)) as z:
            members = {n: z.read(n) for n in z.namelist()}
        members["raw.trace"] += b"\n"
        out = io.BytesIO()
        with zipfile.ZipFile(out, "w", compression=zipfile.ZIP_DEFLATED) as z:
            for name, data in members.items():
                z.writestr(name, data)
        changed = out.getvalue()
        pins["artifact_size_bytes"] = len(changed)
        pins["artifact_digest"] = "sha256:" + digest(changed)
        with self.assertRaisesRegex(Rejected, "^TRACE_DIGEST$"):
            validate(changed, pins)

    def test_T11_duplicate_json_key(self):
        bad = b'{"schema":"x","schema":"y"}'
        with self.assertRaisesRegex(Rejected, "^DUPLICATE_JSON_KEY$"):
            parse_json(bad, RECEIPT_LIMIT)

    def test_T12_duplicate_zip_member(self):
        bundle, pins = fixture_bundle()
        with zipfile.ZipFile(io.BytesIO(bundle)) as z:
            members = [(n, z.read(n)) for n in z.namelist()]
        out = io.BytesIO()
        with warnings.catch_warnings():
            warnings.simplefilter("ignore", UserWarning)
            with zipfile.ZipFile(out, "w", compression=zipfile.ZIP_DEFLATED) as z:
                for name, data in members:
                    z.writestr(name, data)
                z.writestr("raw.trace", fixture_trace())
        changed = out.getvalue()
        pins["artifact_size_bytes"] = len(changed)
        pins["artifact_digest"] = "sha256:" + digest(changed)
        with self.assertRaisesRegex(Rejected, "^DUPLICATE_MEMBER$"):
            validate(changed, pins)

    def test_T13_unsupported_receipt_status(self):
        bundle, pins = fixture_bundle(receipt_patch={"capture_status": "NOT_ASSESSED"})
        with self.assertRaisesRegex(Rejected, "^CAPTURE_STATE$"):
            validate(bundle, pins)

    def test_T14_unknown_trace_encoding(self):
        bundle, pins = fixture_bundle(trace=b"\xff\xfe")
        with self.assertRaisesRegex(NotAssessed, "^TRACE_INCOMPLETE_OR_EXTRA$|^TRACE_ENCODING_UNSUPPORTED$"):
            validate(bundle, pins)


def read_bounded(path: str, limit: int) -> bytes:
    with Path(path).open("rb") as source:
        data = source.read(limit + 1)
    require(len(data) <= limit, "OVERSIZE")
    return data

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--bundle")
    parser.add_argument("--external-pins")
    args = parser.parse_args()
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(Controls)
        return 0 if unittest.TextTestRunner(verbosity=2).run(suite).wasSuccessful() else 1
    if not args.bundle or not args.external_pins:
        parser.error("provide --bundle and --external-pins, or --self-test")
    try:
        bundle = read_bounded(args.bundle, OUTER_LIMIT)
        pins = parse_json(read_bounded(args.external_pins, JSON_LIMIT), JSON_LIMIT)
        result = validate(bundle, pins)
        print(json.dumps(result, sort_keys=True))
        return 0
    except NotAssessed as exc:
        print(json.dumps({"PROCESS_TRACE": "NOT_ASSESSED", "reason": str(exc),
                          "CI_PROCESS_OBSERVATION": "NOT_ASSESSED", "OS_ATTESTATION": False,
                          "FULL_CALENDAR_CERTIFICATION": False}, sort_keys=True))
        return 2
    except (Rejected, OSError) as exc:
        print(json.dumps({"PROCESS_TRACE": "REJECTED", "reason": str(exc),
                          "CI_PROCESS_OBSERVATION": "NOT_ASSESSED", "OS_ATTESTATION": False,
                          "FULL_CALENDAR_CERTIFICATION": False}, sort_keys=True))
        return 1

if __name__ == "__main__":
    raise SystemExit(main())
