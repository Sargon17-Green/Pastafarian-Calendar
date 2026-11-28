#!/usr/bin/env python3
"""Stage23 allocated malformed signed64 rejection only; no Stage23 acceptance."""
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import time
import stage23_measure as m

E = Path("evidence/stage23_malformed")
FILES = ("src/bigint.false", "src/monster_bootstrap.false",
         "tools/stage23_measure.py", "tools/stage23_malformed_native.py",
         ".github/workflows/false-arabic-stage23-malformed.yml",
         "RUN_STAGE23.md",
         "evidence/stage23_signed64_independent_review_2026-11-28.md")
# Fixed raw-cell negative witnesses from the bounded representation contract.
CASES = (
    ("sign_positive", [2,1,1], "SIGN"),
    ("sign_negative", [-2,1,1], "SIGN"),
    ("length_zero", [1,0], "LENGTH"),
    ("length_nine", [1,9,1,1,1,1,1,1,1,1,1], "LENGTH"),
    ("digit_negative", [1,1,-1], "DIGIT"),
    ("digit_512", [1,1,512], "DIGIT"),
    ("zero_nonzero_digit", [0,1,1], "ZERO"),
    ("zero_two_limbs", [0,2,0,0], "ZERO"),
    ("top_zero", [-1,2,1,0], "TOP"),
    ("positive_2pow63", [1,8,0,0,0,0,0,0,0,1], "RANGE"),
    ("negative_beyond_min", [-1,8,1,0,0,0,0,0,0,1], "RANGE"),
    ("negative_high_limb_two", [-1,8,0,0,0,0,0,0,0,2], "RANGE"),
)

def dump(path, data):
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")

def diagnostic(path, marker, err):
    lines = err.split(b"\n")
    if len(lines) != 4 or lines[-1] != b"":
        return False
    header, excerpt, caret, _ = lines
    suffix = b": error: divide by zero"
    if not header.endswith(suffix):
        return False
    fields = header[:-len(suffix)].rsplit(b":", 2)
    if len(fields) != 3 or fields[0] != str(path).encode() or not all(x.isdigit() for x in fields[1:]):
        return False
    number, column = map(int, fields[1:])
    source = path.read_bytes().split(b"\n")
    token = b'"' + marker.encode("ascii") + b'"0 0/'
    return (1 <= number <= len(source) and 1 <= column <= len(excerpt)
            and source[number-1] == excerpt and caret == b" "*(column-1)+b"^"
            and excerpt[:column].endswith(token) and excerpt.count(token) == 1)

def fixture(raw, position):
    # Both records have eleven allocated cells even for invalid length fields.
    # Both argument pointer cells are separately allocated and in range.
    good = m.limbs(-15055671)
    records = [good, good]
    records[position] = raw
    assert all(2 <= len(r) <= 11 for r in records)
    padded = [r + [0]*(11-len(r)) for r in records]
    cells = padded[0] + padded[1]
    lines = ["z;x:"]
    lines.extend(m.lit(v)+"a;!" for v in cells)
    lines.extend(["x;0+a;!","x;11+a;!","x;22+b:", "b;40h;!!%", '"S23_MALFORMED_UNEXPECTED_RETURN"'])
    return ("\n".join(lines)+"\n").encode(), padded

def run_case(label, program, marker, metadata):
    case = E / label
    case.mkdir(exist_ok=False)
    path = case / "program.false"
    path.write_bytes(program)
    dump(case/"expected.json", dict(metadata, expected_marker=marker, expected_exit=1))
    started = time.monotonic()
    cmd = ["/usr/bin/time","-v","-o",str(case/"time.txt"),"upstream/false_int","-e",str(path)]
    with subprocess.Popen(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE,
                          start_new_session=True,preexec_fn=m.limits) as proc:
        try:
            out, err = proc.communicate(timeout=600)
            code = proc.returncode
        except subprocess.TimeoutExpired:
            os.killpg(proc.pid,signal.SIGKILL)
            out, err = proc.communicate()
            code = 124
    elapsed = time.monotonic()-started
    (case/"stdout.txt").write_bytes(out)
    (case/"stderr.txt").write_bytes(err)
    (case/"exit_code.txt").write_text(str(code)+"\n")
    timing = (case/"time.txt").read_text() if (case/"time.txt").exists() else ""
    match = re.search(r"Maximum resident set size \(kbytes\):\s*(\d+)",timing)
    rss = int(match.group(1)) if match else None
    exact = diagnostic(path, marker, err)
    passed = (code == 1 and out == marker.encode() and exact
              and rss is not None and 0 < rss <= m.LIMIT//1024 and elapsed <= 600)
    result = dict(label=label, expected_marker=marker, exit_code=code,
                  exact_intentional_abort=exact, passed=passed,
                  elapsed_seconds=round(elapsed,3), peak_rss_kib=rss,
                  program_sha256=m.sha(program), stdout_sha256=m.sha(out),
                  stderr_sha256=m.sha(err))
    dump(case/"receipt.json",result)
    print(json.dumps(result),flush=True)
    return result

def main():
    E.mkdir(parents=True,exist_ok=True)
    pin = os.environ["SOURCE_PIN"]
    assert subprocess.check_output(["git","rev-parse","HEAD"],text=True).strip()==pin
    assert os.environ["RUNTIME_PIN"]==m.RT and (E/"runtime_observed.txt").read_text().strip()==m.RT
    hashes = {}
    for name in FILES:
        data = Path(name).read_bytes()
        assert data == subprocess.check_output(["git","show",pin+":"+name])
        dest = E/"source"/name
        dest.parent.mkdir(parents=True,exist_ok=True)
        dest.write_bytes(data)
        hashes[name]=m.sha(data)
    prefix = Path("src/bigint.false").read_bytes()+b"\n"+Path("src/monster_bootstrap.false").read_bytes()+b"\n"
    report = dict(project_id="PC-BRANCH-FALSE-ARABIC",source_pin=pin,runtime_pin=m.RT,
                  source_sha256=hashes, timeout_seconds=600,address_space_limit_bytes=m.LIMIT,
                  planned_cases=2*len(CASES),completed=[],malformed_native=False,
                  stage_acceptance=False,replay_native=False,mutants_native=False)
    dump(E/"receipt.json",report)
    pre = run_case("abort_preflight",b'"S23_ABORT_PREFLIGHT"0 0/\n',"S23_ABORT_PREFLIGHT",{"preflight":True})
    report["preflight"]=pre
    dump(E/"receipt.json",report)
    if not pre["passed"]:
        raise SystemExit(1)
    for pos in (0,1):
        for name,raw,reason in CASES:
            body,padded = fixture(raw,pos)
            marker = "E_OP57_"+reason
            result = run_case(f"arg{pos}_{name}",prefix+body,marker,
                              dict(position=pos,raw=raw,allocated_records=padded,argument_offsets=[0,11],argument_pointer=22))
            report["completed"].append(result)
            report["malformed_native"]=(len(report["completed"])==report["planned_cases"]
                                        and all(r["passed"] for r in report["completed"]))
            dump(E/"receipt.json",report)
            if not result["passed"]:
                raise SystemExit(1)
    print(json.dumps(report),flush=True)

if __name__=="__main__":
    main()
