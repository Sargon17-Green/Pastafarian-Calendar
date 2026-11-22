#!/usr/bin/env python3
"""QA-only Stage41 source-to-binary provenance collector (compile-only; never runs Ada).

The only native build performed by --build-only is GPRBuild of the Stage41 observer.
This module deliberately has no command that executes the observer or calls Calendar_Date.
Direct-child capture is exercised only with short Python fixture children in --selftest.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import selectors
import shutil
import signal
import subprocess
import sys
import tempfile
import time
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

PROJECT_ID = "PC-BRANCH-ADA-TELUGU"
EXPECTED_BRANCH = "qa/issue29-ada-gmp-build-stream-v176"
BASE_SHA = "1160096aa847c54cbef27c232771ce1549d7ba8f"
BASE_TREE = "dc2bdbfd671d359782a00ced9966228f7ac1f1c9"
MAX_BUILD_OUTPUT_BYTES = 64 * 1024 * 1024

PRODUCTION_BLOBS = {
    ".github/workflows/canonical-names-lock.yml": "226d85d9a225d8c72968b72b5fb117d46f75f96f",
    "pastafari_calendar_stage41.gpr": "0f168e882fefd1174a75fbf4c1329e8c310e07fe",
    "pastafari_calendar_legacy_gmp.gpr": "1e3f05e34f8a70ab2e1b32251befd0cddd4d9c36",
    "run_stage41_remote_seventeen.sh": "8c43e8329df0d914fd9d68abf3b91167540a4a00",
    "run_stage03_patch01.sh": "14d7087e9020a69ce20906f9a06f0056089cfd13",
    "run_stage05_patch02.sh": "c9f56815e0a7e258dd7dd53616a88bb50ed5df86",
    "tests/stage41_remote_seventeen.py": "15b949479f4da7d41f0b55add5a2f37d6adb5724",
    "tests/stage14_real_oracle.py": "0922f5cbb32697106d4537463e56f7edb74e3355",
    "tests/stage41_remote_seventeen_observer.adb": "47d097ba9f081420379f85823b3a1e92316a8962",
    "src/normative_oracle.adb": "0be8f8ab4ddef26d34963d5567707a511ebda50b",
    "src/normative_oracle.ads": "c4588566076798dd394feeab580ebc3d38c09744",
    "src/exact_math.adb": "4b014d2e6a467ec606493c6c977e8cc184fea40a",
    "src/exact_math.ads": "3ab9c5325858e5ef2d7fa59ab6d30d0c1ff523aa",
    "src/month_weaving.adb": "9b02c62dfbc7d8b3b532aba8cd9f1ad0f8b28fef",
    "src/month_weaving.ads": "183c0e4d9538ae1defe1b63eb3871ffe7feee991",
    "src/canonical_full_weave_gmp_v164.adb": "845bd8905943a54e63d6aba0334404a5051fe666",
    "src/canonical_full_weave_gmp_v164.ads": "0b68edf7eddbc33869358bcfcc21e32465fc591e",
    "src/canonical_wide_rank_gmp_v164.adb": "52b8814c2ab1924cdebafe893a65d97cd3ccfa61",
    "src/canonical_wide_rank_gmp_v164.ads": "14b94e81534e98cfdb07be3824076bd7082385ea",
}

ALLOWED_QA_DIFFS = {
    ".github/workflows/issue29-stage41-build-provenance-v12.yml",
    "qa/issue29_stage41_provenance_runner_v12.py",
    "QA_REVIEW_v12_HE.md",
    "README_v12_HE.md",
    "RUN_QA_v12.sh",
}


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2) + "\n", encoding="utf-8")


@dataclass
class StreamInfo:
    path: str
    size_bytes: int
    sha256: str


@dataclass
class CaptureResult:
    pid: int
    argv: list[str]
    cwd: str
    direct_child: bool
    shell: bool
    return_code: int
    timed_out: bool
    output_limit_exceeded: bool
    bytes_observed_total: int
    bytes_stored_total: int
    elapsed_seconds: float
    executable_path: str
    executable_sha256_before: str
    executable_sha256_after: str
    stdout: StreamInfo
    stderr: StreamInfo


def _signal_group(pid: int, sig: int) -> None:
    try:
        os.killpg(pid, sig)
    except ProcessLookupError:
        pass


def capture_direct_child(
    argv: list[str],
    stdout_path: Path,
    stderr_path: Path,
    *,
    cwd: Path,
    env: dict[str, str] | None = None,
    timeout_seconds: float = 60.0,
    max_total_bytes: int = 4 * 1024 * 1024,
    grace_seconds: float = 0.75,
) -> CaptureResult:
    """Capture stdout/stderr independently with a streaming byte cap.

    POSIX-only by design: the CI target is Ubuntu and process-group termination is
    required so timeout/overflow also stops compiler/linker descendants.
    Only the first max_total_bytes are retained; the child is terminated as soon
    as the observed combined stream exceeds that cap. The streams are never merged.
    """
    if os.name != "posix":
        raise RuntimeError("v12 direct-child capture requires POSIX process groups (Ubuntu CI target)")
    if not argv or not Path(argv[0]).is_absolute():
        raise ValueError("argv[0] must be an absolute executable path")
    executable = Path(argv[0]).resolve()
    if not executable.is_file():
        raise ValueError(f"direct-child executable does not exist: {executable}")
    executable_sha_before = sha256_file(executable)
    if timeout_seconds <= 0 or max_total_bytes <= 0 or grace_seconds <= 0:
        raise ValueError("timeout, max_total_bytes and grace_seconds must be positive")

    stdout_path.parent.mkdir(parents=True, exist_ok=True)
    stderr_path.parent.mkdir(parents=True, exist_ok=True)
    start = time.monotonic()
    proc = subprocess.Popen(
        argv,
        cwd=str(cwd),
        env=env,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=False,
        shell=False,
        close_fds=True,
        start_new_session=True,
    )
    assert proc.stdout is not None and proc.stderr is not None
    selector = selectors.DefaultSelector()
    streams = {
        "stdout": {"pipe": proc.stdout, "path": stdout_path, "hash": hashlib.sha256(), "stored": 0, "observed": 0},
        "stderr": {"pipe": proc.stderr, "path": stderr_path, "hash": hashlib.sha256(), "stored": 0, "observed": 0},
    }
    files = {name: item["path"].open("wb") for name, item in streams.items()}
    for name, item in streams.items():
        os.set_blocking(item["pipe"].fileno(), False)
        selector.register(item["pipe"], selectors.EVENT_READ, name)

    deadline = start + timeout_seconds
    timed_out = False
    limit_exceeded = False
    term_sent_at: float | None = None
    kill_sent = False
    post_exit_last_activity: float | None = None
    observed_total = 0
    stored_total = 0

    try:
        while selector.get_map() or proc.poll() is None:
            now = time.monotonic()
            if proc.poll() is None and not timed_out and not limit_exceeded and now >= deadline:
                timed_out = True
                _signal_group(proc.pid, signal.SIGTERM)
                term_sent_at = now
            if term_sent_at is not None and not kill_sent and now - term_sent_at >= grace_seconds:
                _signal_group(proc.pid, signal.SIGKILL)
                kill_sent = True
            if proc.poll() is not None and selector.get_map():
                if post_exit_last_activity is None:
                    post_exit_last_activity = now
                elif now - post_exit_last_activity >= grace_seconds and not kill_sent:
                    # A grandchild may have inherited a pipe after the direct child exited.
                    _signal_group(proc.pid, signal.SIGTERM)
                    term_sent_at = now
                    kill_sent = False
                    post_exit_last_activity = now
            wait_for = 0.05
            if proc.poll() is None and not timed_out and not limit_exceeded:
                wait_for = max(0.0, min(wait_for, deadline - now))
            events = selector.select(wait_for) if selector.get_map() else []
            got_data = False
            for key, _ in events:
                name = key.data
                pipe = key.fileobj
                try:
                    chunk = os.read(pipe.fileno(), 65536)
                except BlockingIOError:
                    continue
                if not chunk:
                    selector.unregister(pipe)
                    pipe.close()
                    continue
                got_data = True
                observed_total += len(chunk)
                streams[name]["observed"] += len(chunk)
                remaining = max_total_bytes - stored_total
                if remaining > 0:
                    keep = chunk[:remaining]
                    files[name].write(keep)
                    streams[name]["hash"].update(keep)
                    streams[name]["stored"] += len(keep)
                    stored_total += len(keep)
                if len(chunk) > max(remaining, 0) and not limit_exceeded:
                    limit_exceeded = True
                    _signal_group(proc.pid, signal.SIGTERM)
                    term_sent_at = time.monotonic()
            if got_data and proc.poll() is not None:
                post_exit_last_activity = time.monotonic()
            elif proc.poll() is not None and selector.get_map() and post_exit_last_activity is not None:
                # Preserve a short drain window; kill only after the pipes go idle.
                pass
        return_code = proc.wait()
    finally:
        for name, f in files.items():
            f.flush()
            os.fsync(f.fileno())
            f.close()
        selector.close()
        for item in streams.values():
            try:
                item["pipe"].close()
            except Exception:
                pass

    elapsed = time.monotonic() - start
    executable_sha_after = sha256_file(executable)
    return CaptureResult(
        pid=proc.pid,
        argv=list(argv),
        cwd=str(cwd.resolve()),
        direct_child=True,
        shell=False,
        return_code=return_code,
        timed_out=timed_out,
        output_limit_exceeded=limit_exceeded,
        bytes_observed_total=observed_total,
        bytes_stored_total=stored_total,
        elapsed_seconds=round(elapsed, 6),
        executable_path=str(executable),
        executable_sha256_before=executable_sha_before,
        executable_sha256_after=executable_sha_after,
        stdout=StreamInfo(str(stdout_path.resolve()), streams["stdout"]["stored"], streams["stdout"]["hash"].hexdigest()),
        stderr=StreamInfo(str(stderr_path.resolve()), streams["stderr"]["stored"], streams["stderr"]["hash"].hexdigest()),
    )


def run_capture_selftests() -> list[dict[str, Any]]:
    tests: list[dict[str, Any]] = []

    def check(name: str, ok: bool, detail: str) -> None:
        tests.append({"name": name, "passed": bool(ok), "detail": detail})
        if not ok:
            raise AssertionError(f"{name}: {detail}")

    with tempfile.TemporaryDirectory(prefix="ada-v12-capture-") as temp:
        root = Path(temp)
        py = str(Path(sys.executable).resolve())

        r = capture_direct_child(
            [py, "-c", "import os; os.write(1,b'OUT'); os.write(2,b'ERR')"],
            root / "dual.stdout", root / "dual.stderr", cwd=root,
            timeout_seconds=3, max_total_bytes=1024,
        )
        out, err = Path(r.stdout.path).read_bytes(), Path(r.stderr.path).read_bytes()
        check("distinct_streams", out == b"OUT" and err == b"ERR" and r.return_code == 0,
              f"stdout={out!r}; stderr={err!r}; rc={r.return_code}")
        check("direct_child_identity", r.pid > 0 and r.direct_child and not r.shell and r.argv[0] == py
              and r.executable_sha256_before == r.executable_sha256_after,
              f"pid={r.pid}; direct_child={r.direct_child}; shell={r.shell}; executable_sha_stable={r.executable_sha256_before == r.executable_sha256_after}")

        r = capture_direct_child(
            [py, "-c", "import os; os.write(1,b'ONLY')"],
            root / "empty.stdout", root / "empty.stderr", cwd=root,
            timeout_seconds=3, max_total_bytes=1024,
        )
        check("empty_stderr_preserved", Path(r.stderr.path).read_bytes() == b"" and Path(r.stdout.path).read_bytes() == b"ONLY",
              f"stdout_bytes={r.stdout.size_bytes}; stderr_bytes={r.stderr.size_bytes}")

        r = capture_direct_child(
            [py, "-c", "raise SystemExit(7)"],
            root / "nonzero.stdout", root / "nonzero.stderr", cwd=root,
            timeout_seconds=3, max_total_bytes=1024,
        )
        check("nonzero_exit_preserved", r.return_code == 7 and not r.timed_out,
              f"rc={r.return_code}; timed_out={r.timed_out}")

        r = capture_direct_child(
            [py, "-c", "import time; time.sleep(30)"],
            root / "timeout.stdout", root / "timeout.stderr", cwd=root,
            timeout_seconds=0.15, max_total_bytes=1024, grace_seconds=0.1,
        )
        check("timeout_kills_process_group", r.timed_out and r.return_code is not None and r.elapsed_seconds < 3,
              f"rc={r.return_code}; timed_out={r.timed_out}; elapsed={r.elapsed_seconds}")

        r = capture_direct_child(
            [py, "-c", "import os; b=b'x'*8192\nwhile True: os.write(1,b)"],
            root / "limit.stdout", root / "limit.stderr", cwd=root,
            timeout_seconds=3, max_total_bytes=16384, grace_seconds=0.1,
        )
        stored = r.stdout.size_bytes + r.stderr.size_bytes
        check("streaming_limit_enforced", r.output_limit_exceeded and stored <= 16384 and r.bytes_observed_total > 16384,
              f"observed={r.bytes_observed_total}; stored={stored}; exceeded={r.output_limit_exceeded}; rc={r.return_code}")

        r = capture_direct_child(
            [py, "-c", "import os; a=b'a'*100000; b=b'b'*100000; os.write(1,a); os.write(2,b)"],
            root / "large.stdout", root / "large.stderr", cwd=root,
            timeout_seconds=3, max_total_bytes=300000,
        )
        out, err = Path(r.stdout.path).read_bytes(), Path(r.stderr.path).read_bytes()
        check("concurrent_pipe_drain_no_deadlock", r.return_code == 0 and len(out) == 100000 and len(err) == 100000,
              f"stdout={len(out)}; stderr={len(err)}; rc={r.return_code}")

        fake_repo = root / "workflow-fixture"
        workflow_path = fake_repo / ".github/workflows/canonical-names-lock.yml"
        workflow_path.parent.mkdir(parents=True)
        fixture = ["jobs:", "  verify:", "    runs-on: ubuntu-latest", "    steps:", "      - run: echo verify"]
        for i in range(42):
            fixture.extend([f"  native-{i:02d}:", "    if: ${{ false }}", "    runs-on: ubuntu-latest"])
        workflow_path.write_text("\n".join(fixture) + "\n", encoding="utf-8")
        gate = verify_halted_workflow(fake_repo)
        check("exact_42_job_halt_gate", gate["other_jobs_hard_disabled"] == 42 and gate["verify_enabled"], str(gate))
        bad = fixture.copy()
        bad[6] = "    runs-on: ubuntu-latest"  # remove the first native job's if:false line
        workflow_path.write_text("\n".join(bad) + "\n", encoding="utf-8")
        rejected = False
        try:
            verify_halted_workflow(fake_repo)
        except RuntimeError:
            rejected = True
        check("halt_gate_rejects_enabled_native_job", rejected, f"rejected={rejected}")

    return tests


def run_tool(argv: list[str], out: Path, err: Path, *, cwd: Path, env: dict[str, str], timeout: float = 20.0, max_bytes: int = 8 * 1024 * 1024) -> CaptureResult:
    exe = shutil.which(argv[0], path=env.get("PATH"))
    if not exe:
        raise RuntimeError(f"required tool missing: {argv[0]}")
    full = [str(Path(exe).resolve()), *argv[1:]]
    return capture_direct_child(full, out, err, cwd=cwd, env=env, timeout_seconds=timeout, max_total_bytes=max_bytes)


def check_process_ok(name: str, result: CaptureResult) -> None:
    if result.return_code != 0 or result.timed_out or result.output_limit_exceeded:
        raise RuntimeError(f"{name} failed: rc={result.return_code}, timeout={result.timed_out}, limit={result.output_limit_exceeded}")


def git_text(root: Path, *args: str) -> str:
    return subprocess.check_output(["git", *args], cwd=root, text=True, encoding="utf-8").strip()


def tracked_ada_sources(root: Path) -> dict[str, str]:
    names = git_text(root, "ls-files", "src", "tests").splitlines()
    result: dict[str, str] = {}
    for name in names:
        if name.endswith((".adb", ".ads")):
            result[name] = git_text(root, "rev-parse", f"HEAD:{name}")
    return result


def verify_halted_workflow(root: Path) -> dict[str, Any]:
    path = root / ".github/workflows/canonical-names-lock.yml"
    lines = path.read_text(encoding="utf-8").splitlines()
    try:
        start = lines.index("jobs:") + 1
    except ValueError as exc:
        raise RuntimeError("canonical-names-lock.yml has no jobs section") from exc
    headers = []
    for i in range(start, len(lines)):
        m = re.match(r"^  ([A-Za-z0-9_-]+):\s*$", lines[i])
        if m:
            headers.append((i, m.group(1)))
    jobs: dict[str, str] = {}
    for pos, (line_no, name) in enumerate(headers):
        end = headers[pos + 1][0] if pos + 1 < len(headers) else len(lines)
        jobs[name] = "\n".join(lines[line_no + 1:end])
    if len(jobs) != 43 or "verify" not in jobs:
        raise RuntimeError(f"expected 43 jobs including verify; found {len(jobs)}")
    enabled = [name for name, body in jobs.items() if name != "verify" and "if: ${{ false }}" not in body]
    if enabled:
        raise RuntimeError(f"non-verify jobs are not hard-disabled: {enabled}")
    if "if: ${{ false }}" in jobs["verify"]:
        raise RuntimeError("canonical verify job was disabled")
    return {"total_jobs": len(jobs), "verify_enabled": True, "other_jobs": len(jobs) - 1, "other_jobs_hard_disabled": len(jobs) - 1}


def verify_source_identity(root: Path, expected_head: str) -> dict[str, Any]:
    branch = git_text(root, "branch", "--show-current")
    head = git_text(root, "rev-parse", "HEAD")
    tree = git_text(root, "rev-parse", "HEAD^{tree}")
    parent = git_text(root, "rev-parse", "HEAD^1")
    merge_base = git_text(root, "merge-base", BASE_SHA, head)
    status = git_text(root, "status", "--porcelain", "--untracked-files=all")
    base_tree = git_text(root, "rev-parse", f"{BASE_SHA}^{{tree}}")
    if branch != EXPECTED_BRANCH:
        raise RuntimeError(f"wrong branch: {branch}")
    if head != expected_head:
        raise RuntimeError(f"HEAD mismatch: {head} != {expected_head}")
    if merge_base != BASE_SHA:
        raise RuntimeError(f"QA branch is not based on the locked production commit: {merge_base} != {BASE_SHA}")
    if base_tree != BASE_TREE:
        raise RuntimeError(f"base tree mismatch: {base_tree} != {BASE_TREE}")
    if status:
        raise RuntimeError(f"working tree is not clean: {status}")
    changed = set(git_text(root, "diff", "--name-only", f"{BASE_SHA}..{head}").splitlines())
    if changed != ALLOWED_QA_DIFFS:
        raise RuntimeError(f"QA branch changed unexpected paths: {sorted(changed ^ ALLOWED_QA_DIFFS)}")
    observed = {}
    for path, expected in PRODUCTION_BLOBS.items():
        actual = git_text(root, "rev-parse", f"HEAD:{path}")
        if actual != expected:
            raise RuntimeError(f"production blob mismatch {path}: {actual} != {expected}")
        observed[path] = actual
    return {
        "project_id": PROJECT_ID,
        "branch": branch,
        "head_sha": head,
        "tree_sha": tree,
        "parent_sha": parent,
        "merge_base_sha": merge_base,
        "base_sha": BASE_SHA,
        "base_tree_sha": base_tree,
        "working_tree_clean": True,
        "changed_paths": sorted(changed),
        "production_blob_locks": observed,
        "tracked_ada_source_blobs": tracked_ada_sources(root),
    }


def resolve_gmp_project(root: Path, output: Path, env: dict[str, str]) -> tuple[Path, dict[str, Any]]:
    dpkg = run_tool(["dpkg-query", "-L", "libgnatcoll-gmp-dev"], output / "dpkg-gmp-files.stdout", output / "dpkg-gmp-files.stderr", cwd=root, env=env)
    check_process_ok("dpkg-query -L libgnatcoll-gmp-dev", dpkg)
    candidates = []
    for line in Path(dpkg.stdout.path).read_text(encoding="utf-8").splitlines():
        p = Path(line.strip())
        if p.name == "gnatcoll_gmp.gpr" and p.is_file():
            candidates.append(p.resolve())
    candidates = sorted(set(candidates))
    if len(candidates) != 1:
        raise RuntimeError(f"expected exactly one packaged gnatcoll_gmp.gpr; found {candidates}")
    project = candidates[0]
    if (root / "gnatcoll_gmp.gpr").exists():
        raise RuntimeError("repository-local gnatcoll_gmp.gpr would shadow the packaged project")
    # Make the package directory the first project search path. Record the exact value
    # used by the actual GPRBuild child process.
    old = env.get("GPR_PROJECT_PATH", "")
    env["GPR_PROJECT_PATH"] = str(project.parent) + (os.pathsep + old if old else "")
    project_bytes = project.read_bytes()
    return project, {
        "path": str(project),
        "real_path": str(project.resolve()),
        "sha256": sha256_bytes(project_bytes),
        "size_bytes": len(project_bytes),
        "gpr_project_path_environment": env["GPR_PROJECT_PATH"],
        "project_text": project_bytes.decode("utf-8", errors="replace"),
    }


def build_only(root: Path, expected_head: str, output: Path) -> dict[str, Any]:
    output.mkdir(parents=True, exist_ok=True)
    report: dict[str, Any] = {
        "project_id": PROJECT_ID,
        "scope": "compile-only; Stage41 observer is built but never executed; no Calendar_Date calls",
        "passed": False,
        "errors": [],
    }
    try:
        report["source_identity"] = verify_source_identity(root, expected_head)
        report["legacy_dispatch_halt"] = verify_halted_workflow(root)

        env = dict(os.environ)
        tool_versions = {}
        for name, argv in {
            "gprbuild": ["gprbuild", "--version"],
            "gnatmake": ["gnatmake", "--version"],
            "gnatls": ["gnatls", "--version"],
        }.items():
            res = run_tool(argv, output / f"{name}.stdout", output / f"{name}.stderr", cwd=root, env=env, timeout=20)
            check_process_ok(f"{name} --version", res)
            tool_versions[name] = {
                "stdout": asdict(res.stdout), "stderr": asdict(res.stderr),
                "stdout_text": Path(res.stdout.path).read_text(encoding="utf-8", errors="replace"),
                "return_code": res.return_code,
            }

        pkg = run_tool(
            ["dpkg-query", "-W", "-f=${binary:Package}\\t${Version}\\n", "libgnatcoll-gmp-dev", "libgmp10"],
            output / "gmp-packages.stdout", output / "gmp-packages.stderr", cwd=root, env=env, timeout=20,
        )
        check_process_ok("dpkg-query package versions", pkg)
        package_versions = Path(pkg.stdout.path).read_text(encoding="utf-8", errors="replace").splitlines()
        if not any("libgnatcoll-gmp-dev" in x for x in package_versions) or not any("libgmp10" in x for x in package_versions):
            raise RuntimeError(f"missing GNATCOLL GMP/GMP package version evidence: {package_versions}")

        gmp_project, gmp_info = resolve_gmp_project(root, output, env)
        gmp_text = gmp_info.pop("project_text")
        lib_name_match = re.search(r'for\s+Library_Name\s+use\s+"([^"]+)"', gmp_text, flags=re.IGNORECASE)
        library_name = lib_name_match.group(1) if lib_name_match else None
        gmp_info["library_name_from_project"] = library_name

        project_file = root / "pastafari_calendar_stage41.gpr"
        project_text = project_file.read_text(encoding="utf-8")
        exec_match = re.search(r'for\s+Exec_Dir\s+use\s+"([^"]+)"', project_text, flags=re.IGNORECASE)
        main_match = re.search(r'for\s+Main\s+use\s*\(\s*"([^"]+\.adb)"', project_text, flags=re.IGNORECASE)
        if not exec_match or not main_match:
            raise RuntimeError("cannot resolve Exec_Dir/Main from the pinned Stage41 GPR project")
        binary_path = (root / exec_match.group(1) / Path(main_match.group(1)).stem).resolve()
        link_map = (output / "stage41-link.map").resolve()
        build_cmd = [
            "gprbuild", "-v", "-p", "-j2", "-P", str(project_file),
            "-largs", "-Wl,-t", f"-Wl,-Map={link_map}",
        ]
        build = run_tool(build_cmd, output / "gprbuild.stdout", output / "gprbuild.stderr", cwd=root, env=env, timeout=240, max_bytes=MAX_BUILD_OUTPUT_BYTES)
        report["build"] = {
            "argv": build.argv,
            "cwd": build.cwd,
            "pid": build.pid,
            "return_code": build.return_code,
            "timed_out": build.timed_out,
            "output_limit_exceeded": build.output_limit_exceeded,
            "elapsed_seconds": build.elapsed_seconds,
            "stdout": asdict(build.stdout),
            "stderr": asdict(build.stderr),
        }
        check_process_ok("GPRBuild Stage41 compile/link", build)
        if not binary_path.is_file() or not os.access(binary_path, os.X_OK):
            raise RuntimeError(f"Stage41 observer binary missing or not executable: {binary_path}")
        binary_bytes = binary_path.read_bytes()
        if not binary_bytes.startswith(b"\x7fELF"):
            raise RuntimeError("Stage41 observer output is not an ELF executable")

        stdout_text = Path(build.stdout.path).read_text(encoding="utf-8", errors="replace")
        stderr_text = Path(build.stderr.path).read_text(encoding="utf-8", errors="replace")
        combined = stdout_text + "\n" + stderr_text
        if not link_map.is_file():
            raise RuntimeError("linker map was not produced")
        map_text = link_map.read_text(encoding="utf-8", errors="replace")
        link_lines = [line for line in combined.splitlines() if re.search(r"gnatlink|gcc(?:-[0-9]+)?| -l| -Wl,", line, re.IGNORECASE)]
        if not link_lines:
            raise RuntimeError("verbose GPRBuild output contains no observable linker command line")
        (output / "link-command.txt").write_text("\n".join(link_lines) + "\n", encoding="utf-8")
        trace_text = "\n".join(line for line in combined.splitlines() if "gmp" in line.lower()) + "\n"
        trace_text += "\n".join(line for line in map_text.splitlines() if "gmp" in line.lower()) + "\n"
        (output / "gmp-link-trace.txt").write_text(trace_text, encoding="utf-8")

        path_tokens = set(re.findall(r"/(?:[^\s'\"()]+/)*[^\s'\"()]*gmp[^\s'\"()]*", combined + "\n" + map_text, flags=re.IGNORECASE))
        linked_files = []
        for token in sorted(path_tokens):
            p = Path(token.rstrip(",;:]")).resolve()
            if p.is_file() and "gmp" in p.name.lower():
                linked_files.append({"path": str(p), "size_bytes": p.stat().st_size, "sha256": sha256_file(p)})
        if library_name:
            exact_library_files = [x for x in linked_files if library_name.lower() in Path(x["path"]).name.lower()]
            if not exact_library_files:
                raise RuntimeError(
                    f"GPR project Library_Name={library_name!r} was not found among actual linker inputs; "
                    "refusing link proof"
                )
            linked_files = exact_library_files
        elif not linked_files:
            raise RuntimeError("no actual GMP-named file path found in linker trace/map; refusing link proof")
        if not linked_files:
            raise RuntimeError("no actual GNATCOLL/GMP link input was resolved; refusing link proof")

        compile_units = []
        seen_units = set()
        for line in stdout_text.splitlines():
            m = re.match(r"\s*\[Ada\]\s+([^\s]+\.adb)\s*$", line)
            if m:
                unit = m.group(1)
                if unit not in seen_units:
                    compile_units.append(unit)
                    seen_units.add(unit)
        if not compile_units:
            raise RuntimeError("GPRBuild output did not enumerate any Ada compile units")

        report["tool_versions"] = tool_versions
        report["package_versions"] = package_versions
        report["gmp_project"] = gmp_info
        report["linked_gmp_inputs"] = linked_files
        report["link_command"] = {
            "path": str((output / "link-command.txt").resolve()),
            "sha256": sha256_file(output / "link-command.txt"),
            "line_count": len(link_lines),
        }
        report["link_trace"] = {
            "path": str((output / "gmp-link-trace.txt").resolve()),
            "sha256": sha256_file(output / "gmp-link-trace.txt"),
            "map_path": str(link_map),
            "map_sha256": sha256_file(link_map),
        }
        report["binary"] = {
            "path": str(binary_path),
            "size_bytes": len(binary_bytes),
            "sha256": sha256_bytes(binary_bytes),
            "elf_magic": binary_bytes[:4].hex(),
        }
        report["compile_units"] = compile_units
        report["actual_stage41_observer_executed"] = False
        report["calendar_date_calls"] = 0
        report["source_to_binary_build_proof"] = True
        report["passed"] = True
    except Exception as exc:
        report["errors"].append(f"{type(exc).__name__}: {exc}")
        report["actual_stage41_observer_executed"] = False
        report["calendar_date_calls"] = 0
        report["source_to_binary_build_proof"] = False

    report_path = output / "build_provenance_v12.json"
    write_json(report_path, report)
    manifest = {}
    for p in sorted(output.iterdir()):
        if p.is_file() and p.name != "evidence_manifest_v12.json":
            manifest[p.name] = {"size_bytes": p.stat().st_size, "sha256": sha256_file(p)}
    write_json(output / "evidence_manifest_v12.json", manifest)
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--selftest", action="store_true", help="test only the direct-child capture helper with Python fixture children")
    group.add_argument("--build-only", action="store_true", help="compile/link Stage41 observer; never execute it")
    parser.add_argument("--expected-head", help="exact GitHub Actions commit SHA; required for --build-only")
    parser.add_argument("--output", type=Path, default=Path("evidence-v12"))
    args = parser.parse_args()

    if args.selftest:
        tests = run_capture_selftests()
        report = {"project_id": PROJECT_ID, "scope": "Python fixture children only; no GNAT/GPRBuild/Ada", "passed": len(tests), "total": len(tests), "tests": tests}
        write_json(args.output / "capture_selftests_v12.json", report)
        print(f"PC_BRANCH_ADA_TELUGU_V12_CAPTURE_TESTS={len(tests)}/{len(tests)}")
        return 0

    if not args.expected_head:
        parser.error("--expected-head is required with --build-only")
    root = Path.cwd().resolve()
    report = build_only(root, args.expected_head, args.output.resolve())
    print(f"PC_BRANCH_ADA_TELUGU_V12_BUILD_ONLY={'PASS' if report['passed'] else 'FAIL'}")
    print(f"PC_BRANCH_ADA_TELUGU_V12_OBSERVER_EXECUTED={report.get('actual_stage41_observer_executed', False)}")
    for error in report.get("errors", []):
        print(f"ERROR: {error}", file=sys.stderr)
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())