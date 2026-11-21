#!/usr/bin/env python3
"""Independent finite geometry/receipt QA for PC-BRANCH-LUA-HAITIAN.
Does not reproduce or call the normative stochastic Lua year-selection oracle.
"""
import copy
import hashlib
import json
import math
import re
import sys
from pathlib import Path

from lua_haitian_gate_window_radius96_scan_verify import check, load_seed

PROJECT = "PC-BRANCH-LUA-HAITIAN"
LOCKED_ZIP = "6e5aeec25cae0201e3181d652e63da0642196e39b414150a748c1fe80291cbca"
LOCKED_SOURCE = "ce4d541029c5d81c9f9c185ff734da0ed1d7c18a"
SEED_BLOB = "95e77bc49a4c9e944bbac72b744ae0b3628043e5"
OLD = {-15033432, -15032867, -15034166, -15033568, -15034351, -15033701}
FIELDS = ["ordinal", "window", "fraction", "day", "year", "openIndex",
          "closeIndex", "openDay", "closeDay", "length", "gaps",
          "minimumMonths", "maximumMonths", "selectedMonths", "stateUpper", "reason"]
NOT = "NOT_COMPUTED"

def require(condition, reason):
    if not condition:
        raise ValueError(reason)

def source_blob(path):
    raw = Path(path).read_bytes()
    return hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()

def gates_from_frozen(stdout_path, seed_path):
    require(source_blob(seed_path) == SEED_BLOB, "source seed blob mismatch")
    raw = Path(seed_path).read_bytes()
    check(Path(stdout_path).read_text(), 96, 64, load_seed(raw), SEED_BLOB, 64)
    gates = {}
    for line in Path(stdout_path).read_text().splitlines():
        m = re.fullmatch(r"GATE_INDEX\|index=(-?\d+)\|day=(-?\d+)", line)
        if m:
            index, day = map(int, m.groups())
            require(index not in gates, "duplicate index")
            gates[index] = day
    require(set(gates) == set(range(-96, 97)), "frozen gate set incomplete")
    return gates

def targets(gates):
    plan = []
    for start in (70, 71):
        end = start + 6
        length = sum(gates[k] - gates[k - 1] for k in range(start + 1, end + 1))
        require(252 <= length <= 1968, "new six-gap window is not short")
        for fraction in (1, 2):
            day = gates[start] + length * fraction // 3
            plan.append((len(plan) + 1, start, end, fraction, day))
    require(len(set(item[4] for item in plan)) == 4, "duplicate new target")
    require(not (set(item[4] for item in plan) & OLD), "already sampled target")
    require([p[4] for p in plan] ==
            [-15017677, -15017114, -15017465, -15016813],
            "frozen transcript does not support proposed targets")
    return plan

def load_plan(path):
    rows = []
    for line in Path(path).read_text().splitlines():
        tokens = line.split("\t")
        require(len(tokens) == 5, "bad plan row width")
        rows.append(tuple(int(x) for x in tokens))
    require(len(rows) == 4 and len(set(x[4] for x in rows)) == 4,
            "plan missing/duplicated targets")
    return rows

def state_upper(length, months):
    return sum(max(0, min(length, 123 * k) - 4 * k + 1)
               for k in range(1, months + 1))

def parse_result(stdout):
    lines = stdout.splitlines()
    expected_prefix = [
        "PROJECT_ID: " + PROJECT,
        "QA_SCOPE: NEW_RADIUS96_FOUR_TARGET_STATIC_ADMISSION",
        "COMPOSITION_NOT_INVOKED: YES",
        "FULL_DATE: NOT_RUN"
    ]
    require(len(lines) == 8 and lines[:4] == expected_prefix, "missing/extra output marker")
    require(lines[4].startswith("PROBE_RESULT|"), "missing result")
    chunks = lines[4].split("|")[1:]
    result = {}
    for chunk in chunks:
        key, sep, value = chunk.partition("=")
        require(bool(sep) and key not in result, "duplicate/malformed key")
        result[key] = value
    require(list(result) == FIELDS, "receipt schema mismatch")
    m = re.fullmatch(r"GAP_CALLS: (\d+)", lines[5])
    require(bool(m) and int(m.group(1)) <= 200, "gap call budget exceeded/missing")
    cpu = re.fullmatch(r"LUA_CPU_SECONDS: (\d+\.\d{6})", lines[6])
    require(bool(cpu) and float(cpu.group(1)) <= 110, "Lua CPU exceeded/missing")
    require(lines[7] == "QA_FINAL: COMPLETE", "missing complete receipt")
    return result

def verify_record(v, expected, gates):
    number, start, end, fraction, day = expected
    require(v["ordinal"] == str(number), "wrong ordinal")
    require(v["window"] == f"{start}..{end}", "swapped/wrong window")
    require(v["fraction"] == str(fraction), "wrong fraction")
    require(v["day"] == str(day) and day not in OLD, "wrong/old target day")
    yearfields = ["year", "openIndex", "closeIndex", "openDay", "closeDay",
                  "length", "gaps", "minimumMonths", "maximumMonths",
                  "selectedMonths", "stateUpper"]
    reason = v["reason"]
    if reason == "NO_YEAR_CANDIDATE":
        require(all(v[key] == NOT for key in yearfields), "no-candidate has fabricated fields")
        return reason
    require(v["year"] == "5000", "wrong selected year")
    a, b, x, y, length, gaps, minimum = [
        int(v[k]) for k in ("openIndex", "closeIndex", "openDay", "closeDay",
                            "length", "gaps", "minimumMonths")
    ]
    require(a < b and gaps == b - a and gaps >= 6, "invalid gate indices/gaps")
    require(252 <= length <= 5778 and length == y - x, "invalid interval length")
    require(x < day <= y, "target not inside selected year")
    # Unattested indices remain INCOMPLETE; never infer a new gate beyond the frozen scan.
    if a not in gates or b not in gates:
        raise RuntimeError("INCOMPLETE: selected gate boundary outside radius96 attestation")
    require(gates[a] == x and gates[b] == y, "invalid source gate boundary")
    require(minimum == max(3, (length + 122) // 123), "wrong minimum months")
    if length > 1968:
        require(reason == "MIN_MONTHS_OVER_CAP", "long year incorrectly admitted")
        require(all(v[k] == NOT for k in ("maximumMonths","selectedMonths","stateUpper")),
                "long year computed month selection")
        return reason
    maximum = min(47, length // 4)
    chosen, upper = int(v["selectedMonths"]), int(v["stateUpper"])
    require(v["maximumMonths"] == str(maximum), "incorrect maximum months")
    require(minimum <= chosen <= maximum, "month selection out of range")
    require(upper == state_upper(length, chosen), "incorrect static upper bound")
    correct = ("SELECTED_MONTH_COUNT_OVER_CAP" if chosen > 16 else
               "COMPOSITION_STATE_BOUND_OVER_CAP" if upper > 20000 else "ADMITTED")
    require(reason == correct, "fabricated admission/category")
    return reason

def verify_time(txt):
    m = re.fullmatch(
        r"WALL_SECONDS=(\d+(?:\.\d+)?)\nCPU_SECONDS=(\d+(?:\.\d+)?)\nMAX_RSS_KB=(\d+)\n?",
        txt)
    require(bool(m), "missing/invalid resource time receipt")
    wall, cpu, rss = float(m.group(1)), float(m.group(2)), int(m.group(3))
    require(wall <= 120 and cpu <= 110 and rss <= 131072,
            "wall/CPU/RSS resource cap violated")
    return dict(wall=wall, cpu=cpu, rss_kib=rss)

def verify_all(stdout_path, seed_path, plan_path, evidence_dir, sha):
    gates = gates_from_frozen(stdout_path, seed_path)
    plan = targets(gates)
    require(load_plan(plan_path) == plan, "planned targets do not match frozen geometry")
    require(re.fullmatch("[0-9a-f]{40}", sha) is not None, "invalid new SHA")
    root = Path(evidence_dir)
    require((root / "source_sha.txt").read_text().strip() == sha,
            "changed source SHA")
    require((root / "frozen_source_sha.txt").read_text().strip() == LOCKED_SOURCE,
            "wrong scan source SHA")
    outcomes = []
    for entry in plan:
        number = entry[0]
        p = root / ("probe-" + str(number))
        require((p / "source_sha.txt").read_text().strip() == sha,
                "per-probe source changed")
        require((p / "exit_code.txt").read_text().strip() == "0",
                "probe incomplete/nonzero exit")
        require((p / "stderr.txt").read_bytes() == b"", "probe stderr not empty")
        v = parse_result((p / "stdout.txt").read_text())
        reason = verify_record(v, entry, gates)
        metrics = verify_time((p / "time.txt").read_text())
        outcomes.append(dict(ordinal=number, day=entry[4], reason=reason, resources=metrics))
    marker = "STATIC_ADMISSION_PASS" if any(x["reason"] == "ADMITTED" for x in outcomes) else "STATIC_ADMISSION_NONE"
    result = dict(project_id=PROJECT, source_sha=sha, seed_blob=SEED_BLOB,
                  frozen_zip_sha256=LOCKED_ZIP, completed=4, expected=4,
                  status=marker, outcomes=outcomes,
                  selection_differential="NOT_VERIFIED",
                  composition="NOT_INVOKED", full_date="NOT_RUN")
    (root / "summary.json").write_text(json.dumps(result, indent=2) + "\n")
    print("FOUR_TARGET_INDEPENDENT_VERIFIER: PASS complete=4/4")
    print(marker + ": " + str(sum(x["reason"] == "ADMITTED" for x in outcomes)) + "/4")
    print("SELECTION_DIFFERENTIAL: NOT_VERIFIED")
    return result

def selftest():
    gates = {70: 0, 76: 1800}
    expected = (1, 70, 76, 1, 600)
    base = dict(zip(FIELDS, ["1","70..76","1","600","5000","70","76","0",
                            "1800","1800","6","15","47","15",
                            str(state_upper(1800,15)),"ADMITTED"]))
    assert verify_record(base, expected, gates) == "ADMITTED"
    cases = []
    for key, value in [
        ("day","601"), ("window","71..77"), ("reason","MIN_MONTHS_OVER_CAP"),
        ("openDay","1"), ("length","1801"), ("selectedMonths","17")
    ]:
        x = base.copy()
        x[key] = value
        cases.append(lambda x=x: verify_record(x, expected, gates))
    # Two more adversarial receipt checks, plus a distinct duplicate-plan check.
    valid = ("PROJECT_ID: " + PROJECT + "\n" +
             "QA_SCOPE: NEW_RADIUS96_FOUR_TARGET_STATIC_ADMISSION\n" +
             "COMPOSITION_NOT_INVOKED: YES\nFULL_DATE: NOT_RUN\n" +
             "PROBE_RESULT|" + "|".join(k + "=" + v for k,v in base.items()) +
             "\nGAP_CALLS: 200\nLUA_CPU_SECONDS: 0.001000\nQA_FINAL: COMPLETE")
    assert parse_result(valid) == base
    cases += [
        lambda: parse_result(valid.replace("GAP_CALLS: 200","GAP_CALLS: 201")),
        lambda: parse_result(valid.replace("QA_FINAL: COMPLETE","")),
        lambda: require(len({600,600}) == 2, "duplicate target")
    ]
    for case in cases:
        try:
            case()
        except (ValueError, RuntimeError):
            continue
        raise AssertionError("adversarial mutation was accepted")
    print("FOUR_TARGET_INDEPENDENT_SELFTEST: 10/10 PASS")

def main():
    if len(sys.argv) == 2 and sys.argv[1] == "--selftest":
        selftest()
    elif len(sys.argv) == 5 and sys.argv[1] == "--prepare":
        gates = gates_from_frozen(sys.argv[2], sys.argv[3])
        plan = targets(gates)
        Path(sys.argv[4]).write_text("".join("\t".join(map(str,p)) + "\n" for p in plan))
        print("FOUR_TARGET_PLAN_VERIFIED: 4/4")
    elif len(sys.argv) == 7 and sys.argv[1] == "--verify":
        verify_all(*sys.argv[2:7])
    else:
        raise ValueError("usage: --selftest | --prepare FROZEN_STDOUT SEED PLAN | --verify FROZEN_STDOUT SEED PLAN EVIDENCE SHA")

if __name__ == "__main__":
    try:
        main()
    except (ValueError, RuntimeError, AssertionError, OSError) as exc:
        print("FOUR_TARGET_INDEPENDENT_VERIFIER: INCOMPLETE " + str(exc), file=sys.stderr)
        sys.exit(3)
