#!/usr/bin/env python3
"""Bounded QA09 timeout profiler; one Native case plus one Funge-mode control."""
import hashlib
import json
import subprocess
import tempfile
import time
from pathlib import Path

SOURCE = Path("src/interleaved_work_counts.b98")
FIXTURE = Path("qa/spaghetti09_nd17_two_worker_rendezvous_fixture.beq")
QA08 = Path("qa/spaghetti08_17d_concurrent_stack_residue.beq")
CANDIDATE = Path("qa/spaghetti09_17d_two_shard_eighty_opcode_candidate.beq")
MANIFEST = Path("qa/SPAGHETTI09_17D_EIGHTY_OPCODE_MANIFEST.json")
ENGINE = Path("third_party/funge-plus-plus/bin/funge")
SOURCE_SHA = "560d6aa5807a7f766213a33835cce85eab0fa40c"
FIXTURE_SHA = "e22a8b706fb84e3356db6c70aac29b9145642201"
QA08_SHA = "4ba6902de08cf9483374f43a33f1d4ae7a14e3f6"
CANDIDATE_SHA = "275cec0add8705565d27da4233860bf42d134a27"
MANIFEST_SHA = "95fa7eb37dfef24d0bf5a5dc157bd97324a6a08a"
ENGINE_SHA = "cd6d7f005b4fc33b486fcc2380b35406f6125ca4"

def need(ok, why):
    if not ok:
        raise AssertionError(why)

def gitblob(data):
    return hashlib.sha1(("blob %d\0" % len(data)).encode() + data).hexdigest()

def expected(seed):
    out = [31, 33]
    for axis in range(1, 17):
        triangular = axis * (axis + 1) // 2
        a = 48 + 10 * ((triangular + seed) % 2)
        d = 48 + 10 * ((triangular + seed + 1) % 2)
        out.extend([a, 36, d, 36, 62, axis])
    out.append(136 * seed)
    return out

def stat_from_path(path):
    try:
        raw = Path(path).read_text()
        tail = raw[raw.rfind(")") + 2:].split()
        if len(tail) < 22:
            return None
        return {
            "state": tail[0],
            "user_ticks": int(tail[11]),
            "system_ticks": int(tail[12]),
            "rss_pages": int(tail[21])
        }
    except (OSError, ValueError, IndexError):
        return None

def sample_process(pid):
    stat = stat_from_path("/proc/%d/stat" % pid)
    if stat is None:
        return {"alive": False}
    status = {}
    try:
        for line in Path("/proc/%d/status" % pid).read_text().splitlines():
            if line.startswith(("VmRSS:", "Threads:")):
                key, value = line.split(":", 1)
                status[key] = value.strip()
    except OSError:
        pass
    task_dir = Path("/proc/%d/task" % pid)
    thread_samples = []
    try:
        tids = sorted(task_dir.iterdir(), key=lambda p: int(p.name))
    except OSError:
        tids = []
    for task in tids[:16]:
        try:
            tstat = stat_from_path(task / "stat")
            wchan = (task / "wchan").read_text().strip()
            thread_samples.append({
                "tid": int(task.name),
                "state": tstat["state"] if tstat else None,
                "user_ticks": tstat["user_ticks"] if tstat else None,
                "system_ticks": tstat["system_ticks"] if tstat else None,
                "wchan": wchan
            })
        except (OSError, ValueError, IndexError):
            continue
    return {
        "alive": True, "process": stat, "status": status,
        "thread_count": len(tids), "threads": thread_samples
    }

def run_case(data, mode, seed, limit_seconds):
    with tempfile.TemporaryDirectory(prefix="qa09_timeout_diag_") as tmp:
        source = Path(tmp) / "candidate.beq"
        stdout_path = Path(tmp) / "stdout.bin"
        stderr_path = Path(tmp) / "stderr.bin"
        source.write_bytes(data)
        args = [
            str(ENGINE), "-fconcurrent", "-fthreads=" + mode,
            "-fno-filesystem", "-fno-execute", str(source)
        ]
        samples = []
        timed_out = False
        start = time.monotonic()
        sample_times = [1, 5, 10, 20, 40, 60]
        next_sample = 0
        with stdout_path.open("wb") as stdout, stderr_path.open("wb") as stderr:
            proc = subprocess.Popen(args, stdin=subprocess.PIPE,
                                    stdout=stdout, stderr=stderr)
            proc.stdin.write((str(seed) + "\n").encode("ascii"))
            proc.stdin.close()
            while proc.poll() is None:
                elapsed = time.monotonic() - start
                while next_sample < len(sample_times) and sample_times[next_sample] <= elapsed:
                    samples.append({
                        "elapsed_seconds": round(elapsed, 2),
                        "sample": sample_process(proc.pid)
                    })
                    next_sample += 1
                if elapsed >= limit_seconds:
                    samples.append({
                        "elapsed_seconds": round(elapsed, 2),
                        "sample": sample_process(proc.pid)
                    })
                    timed_out = True
                    proc.terminate()
                    try:
                        proc.wait(timeout=3)
                    except subprocess.TimeoutExpired:
                        proc.kill()
                        proc.wait()
                    break
                time.sleep(0.20)
            elapsed = time.monotonic() - start
            actual_rc = proc.returncode
        stdout_bytes = stdout_path.read_bytes()
        stderr_text = stderr_path.read_bytes().decode("utf-8", "replace")
        stdout_text = stdout_bytes.decode("utf-8", "replace")
        try:
            output = [int(token) for token in stdout_text.split()]
        except ValueError:
            output = []
        return {
            "mode": mode, "seed": seed, "limit_seconds": limit_seconds,
            "elapsed_seconds": round(elapsed, 3),
            "outcome": "bounded_timeout" if timed_out else "completed",
            "reported_exit_code": 124 if timed_out else actual_rc,
            "actual_exit_code": actual_rc,
            "output": output,
            "output_matches_oracle": (not timed_out and actual_rc == 0
                                      and output == expected(seed)),
            "stdout_text_prefix": stdout_text[:2000],
            "stderr_tail": stderr_text[-1000:],
            "samples": samples
        }

def main():
    source = SOURCE.read_bytes()
    fixture = FIXTURE.read_bytes()
    qa08 = QA08.read_bytes()
    candidate = CANDIDATE.read_bytes()
    manifest_bytes = MANIFEST.read_bytes()
    need(gitblob(source) == SOURCE_SHA, "production source pin")
    need(gitblob(fixture) == FIXTURE_SHA, "QA09 rendezvous fixture pin")
    need(gitblob(qa08) == QA08_SHA, "QA08 source pin")
    need(gitblob(candidate) == CANDIDATE_SHA, "80-opcode candidate pin")
    need(gitblob(manifest_bytes) == MANIFEST_SHA, "QA09 manifest pin")
    manifest = json.loads(manifest_bytes.decode("utf-8"))
    need(manifest["candidate_blob"] == CANDIDATE_SHA
         and manifest["fixture_parent_blob"] == FIXTURE_SHA
         and manifest["stage08_parent_blob"] == QA08_SHA
         and manifest["engine_commit"] == ENGINE_SHA
         and manifest["dimension_count"] == 17
         and manifest["generated_opcode_count"] == 80
         and len(manifest["stages"]) == 16
         and manifest["source_bytes"] == len(candidate),
         "QA09 manifest provenance")
    engine_commit = subprocess.check_output(
        ["git", "-C", "third_party/funge-plus-plus", "rev-parse", "HEAD"]
    ).decode("ascii").strip()
    need(engine_commit == ENGINE_SHA, "Funge++ engine commit")
    need(ENGINE.is_file(), "Native engine binary missing")

    control = run_case(candidate, "funge", 1, 12)
    native = run_case(candidate, "native", 1, 60)
    def classify(result):
        if result["outcome"] == "bounded_timeout":
            return "bounded_timeout"
        if result["output_matches_oracle"]:
            return "completed_expected"
        return "completed_mismatch"
    control["classification"] = classify(control)
    native["classification"] = classify(native)
    report = {
        "schema": "qa09-native-80-timeout-diagnostic-v1",
        "prior_run_id": 41525895742,
        "prior_run_sha": "b111f5f7980c427eccea16bc7f24318e976460f2",
        "diagnostic_head": subprocess.check_output(
            ["git", "rev-parse", "HEAD"]
        ).decode("ascii").strip(),
        "source_blob": SOURCE_SHA, "fixture_blob": FIXTURE_SHA,
        "qa08_blob": QA08_SHA, "candidate_blob": CANDIDATE_SHA,
        "manifest_blob": MANIFEST_SHA, "engine_commit": ENGINE_SHA,
        "control_funge_seed1": control,
        "native_seed1": native,
        "full_80_opcode_acceptance": False,
        "stage1_pass": False,
        "deadlock_proven": False
    }
    Path("qa09_timeout_diagnostic.json").write_text(
        json.dumps(report, sort_keys=True, indent=2) + "\n")
    with Path("qa09_timeout_diagnostic.log").open("w") as log:
        log.write("QA09_DIAG_CONTROL " + control["classification"] + "\n")
        log.write("QA09_DIAG_NATIVE " + native["classification"] + "\n")
        log.write("QA09_DIAG_NATIVE_ELAPSED " + str(native["elapsed_seconds"]) + "\n")
        log.write("QA09_DIAG_NATIVE_SAMPLES " + str(len(native["samples"])) + "\n")
        log.write("QA09_DIAG_NO_DEADLOCK_CLAIM\n")
        log.write("QA09_DIAGNOSTIC_COMPLETE\n")
    print("QA09_DIAG_CONTROL", control["classification"], control["elapsed_seconds"])
    print("QA09_DIAG_NATIVE", native["classification"], native["elapsed_seconds"])
    print("QA09_DIAG_NATIVE_SAMPLES", len(native["samples"]))
    print("QA09_DIAG_NO_DEADLOCK_CLAIM")
    print("QA09_DIAGNOSTIC_COMPLETE")

if __name__ == "__main__":
    main()
