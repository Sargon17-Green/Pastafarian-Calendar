#!/usr/bin/env python3
"""Uninstrumented op40 signed-64 boundary gate; never grants Stage23 acceptance."""
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import time
import stage23_measure as m
import stage23_differential as d

E = Path("evidence/stage23_signed64")
FILES = ("src/bigint.false", "src/monster_bootstrap.false", "test/normative_reference.false",
         "tools/stage23_measure.py", "tools/stage23_differential.py",
         "tools/preintegration_op57_design_oracle.mjs", "tools/stage23_signed64_native.py",
         ".github/workflows/false-arabic-stage23-signed64.yml")
def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")

def run_case(index, row, program, checks):
    case = E / f"case_{index:02d}"
    case.mkdir(exist_ok=False)
    path = case / "program.false"
    path.write_bytes(program)
    write_json(case / "expected.json", row)
    cmd = ["/usr/bin/time", "-v", "-o", str(case / "time.txt"),
           "upstream/false_int", "-e", str(path)]
    started = time.monotonic()
    with subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          start_new_session=True, preexec_fn=m.limits) as proc:
        try:
            out, err = proc.communicate(timeout=600)
            code = proc.returncode
        except subprocess.TimeoutExpired:
            os.killpg(proc.pid, signal.SIGKILL)
            out, err = proc.communicate()
            code = 124
    elapsed = time.monotonic() - started
    (case / "stdout.txt").write_bytes(out)
    (case / "stderr.txt").write_bytes(err)
    (case / "exit_code.txt").write_text(str(code) + "\n")
    timing = (case / "time.txt").read_text() if (case / "time.txt").exists() else ""
    match = re.search(r"Maximum resident set size \(kbytes\):\s*(\d+)", timing)
    rss = int(match.group(1)) if match else None
    heap = m.parse_heap(out)
    passed = (code == 0 and not err and heap is not None and heap > 0
              and rss is not None and 0 < rss <= m.LIMIT // 1024 and elapsed <= 600)
    result = dict(index=index, pair=row["pair"], assertions_prepared=checks,
                  assertions_passed=checks if passed else None, exit_code=code,
                  elapsed_seconds=round(elapsed, 3), peak_rss_kib=rss, heap_cells=heap,
                  program_sha256=m.sha(program), stdout_sha256=m.sha(out),
                  stderr_sha256=m.sha(err), passed=passed)
    write_json(case / "receipt.json", result)
    print(json.dumps(result), flush=True)
    return result

def main():
    E.mkdir(parents=True, exist_ok=True)
    pin = os.environ["SOURCE_PIN"]
    assert subprocess.check_output(["git","rev-parse","HEAD"], text=True).strip() == pin
    assert os.environ["RUNTIME_PIN"] == m.RT
    assert (E / "runtime_observed.txt").read_text().strip() == m.RT
    hashes = {}
    for name in FILES:
        data = Path(name).read_bytes()
        assert data == subprocess.check_output(["git","show",pin+":"+name])
        dest = E / "source" / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(data)
        hashes[name] = m.sha(data)
    st, rows = d.oracle()
    rows = rows[1:]  # Do not repeat the already accepted epoch differential.
    lo, hi = -(1 << 63), (1 << 63) - 1
    assert [tuple(r["pair"]) for r in rows] == [
        (lo,hi),(hi,lo),(lo,lo),(hi,hi),(lo,lo+1),(lo+1,lo),(hi-1,hi),(hi,hi-1)]
    write_json(E / "oracle.json", dict(stones=st, records=rows))
    prefix = Path("src/bigint.false").read_bytes() + b"\n" + Path("src/monster_bootstrap.false").read_bytes() + b"\n"
    report = dict(project_id="PC-BRANCH-FALSE-ARABIC", source_pin=pin, runtime_pin=m.RT,
                  source_sha256=hashes, timeout_seconds=600, address_space_limit_bytes=m.LIMIT,
                  planned_pairs=[r["pair"] for r in rows], completed=[], boundary_native=False,
                  stage_acceptance=False, replay_native=False, malformed_native=False,
                  mutants_native=False, instrumented=False)
    write_json(E / "receipt.json", report)
    m.E = E
    m.framing_preflight()
    for i, row in enumerate(rows, 1):
        body, checks = m.fixture(row)
        assert checks > 0
        result = run_case(i, row, prefix + body.encode("utf-8"), checks)
        report["completed"].append(result)
        report["boundary_native"] = len(report["completed"]) == len(rows) and all(
            r["passed"] for r in report["completed"])
        write_json(E / "receipt.json", report)
        if not result["passed"]:
            raise SystemExit(1)
    print(json.dumps(report), flush=True)

if __name__ == "__main__":
    main()
