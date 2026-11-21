#!/usr/bin/env python3
"""Strict evidence verifier for ONE held-out Lua year-selection comparison.
It verifies independently generated Python output; it is not a new normative oracle.
No data from another branch. Standard library only.
"""
import copy
import hashlib
import json
import re
import sys
from pathlib import Path

PROJECT = "PC-BRANCH-LUA-HAITIAN"
DAY = -15017676
FROZEN_PY_SOURCE_BLOB = "a2d08aebd46fe2a135b3dbebf61b425204bcbe87"
FROZEN_REPORT_SHA256 = "89fae158fad5cb09fb320cef76ef801855002422624bacc135cbe34785410caf"
FROZEN_NORMATIVE_BLOB = "8fab731dff7011b1a4c3a241c5d1cdefef1c2f1d"
PARENT = "01561f6d1eaea06b0a70acf60a1a30340e743c79"
FIELDS = ["sourceSha", "day", "year", "candidateCount", "rank1",
          "openIndex", "closeIndex", "openDay", "closeDay",
          "length", "gaps", "minimumMonths", "reason"]

def require(test, detail):
    if not test:
        raise ValueError(detail)

def posint(s, field):
    require(re.fullmatch(r"[0-9]+", str(s)) is not None, "bad positive integer " + field)
    return int(s)

def exactint(s, field):
    require(re.fullmatch(r"-?[0-9]+", str(s)) is not None, "bad integer " + field)
    return int(s)

def decode_python(stdout):
    lines = stdout.splitlines()
    require(len(lines) == 3, "Python output truncated/extra")
    raw = lines[0]
    report = json.loads(raw)
    require(lines[1] == "STATIC_PYTHON_SELFTEST: 16/16 PASS", "Python selftests missing")
    require(lines[2] == "REPORT_SHA256: " + hashlib.sha256((raw+"\n").encode()).hexdigest(),
            "Python report digest mismatch")
    require(lines[2] == "REPORT_SHA256: " + FROZEN_REPORT_SHA256,
            "Python prediction no longer matches frozen digest")
    require(report["projectId"] == PROJECT and report["sourceLockCommit"] == PARENT
            and report["normativeSourceBlob"] == FROZEN_NORMATIVE_BLOB,
            "Python model provenance mismatch")
    require(report["independentGateComputations"] == 192 and report["shortPairs"] == 5
            and report["selfTestsPassed"] == 16
            and report["historicalFourTargetIndependentCrosscheck"] == "4/4 PASS",
            "Python bounded geometry/acceptance receipt mismatch")
    require(report["nativeFreshDay"] == "NOT_RUN"
            and report["composition"] == "NOT_INVOKED"
            and report["fullDate"] == "NOT_RUN", "Python scope changed")
    observations = report["rankSelectionObservations"]
    require(len(observations) == 5, "Python observation count changed")
    fresh = observations[-1]
    require(fresh["day"] == DAY
            and fresh["candidateCount"] == 69 and fresh["rank1"] == 56
            and fresh["selected"] == [71, 82] and fresh["length"] == 5294
            and fresh["minimumMonths"] == 44
            and fresh["shortCandidateRanks"] == [1, 2],
            "frozen Python held-out selection changed")
    return fresh

def decode_lua(stdout):
    lines = stdout.splitlines()
    prefix = ["PROJECT_ID: " + PROJECT,
              "QA_SCOPE: HELDOUT_YEAR5000_SELECTION_ONLY",
              "COMPOSITION_NOT_INVOKED: YES",
              "FULL_DATE: NOT_RUN"]
    require(len(lines) == 8 and lines[:4] == prefix, "Lua scope/line count mismatch")
    require(lines[4].startswith("HELDOUT_RESULT|"), "no Lua result")
    values = {}
    for field in lines[4].split("|")[1:]:
        key, sep, value = field.partition("=")
        require(sep == "=" and key not in values, "bad or duplicate Lua field")
        values[key] = value
    require(list(values) == FIELDS, "Lua result schema changed")
    gap = re.fullmatch(r"GAP_CALLS: ([0-9]+)", lines[5])
    cpu = re.fullmatch(r"LUA_CPU_SECONDS: ([0-9]+\.[0-9]{6})", lines[6])
    require(gap is not None and int(gap.group(1)) <= 200, "Lua gap cap exceeded")
    require(cpu is not None and float(cpu.group(1)) <= 110, "Lua CPU cap exceeded")
    require(lines[7] == "QA_FINAL: COMPLETE", "Lua completion marker missing")
    return values

def verify_pair(py, lua, sha):
    require(re.fullmatch("[0-9a-f]{40}", sha) is not None, "invalid source commit")
    require(lua["sourceSha"] == sha, "Lua source SHA differs from CI HEAD")
    require(exactint(lua["day"], "day") == DAY and lua["year"] == "5000",
            "wrong held-out day/year")
    n, rank = posint(lua["candidateCount"], "candidateCount"), posint(lua["rank1"], "rank1")
    a, b = exactint(lua["openIndex"], "openIndex"), exactint(lua["closeIndex"], "closeIndex")
    opening = exactint(lua["openDay"], "openDay")
    closing = exactint(lua["closeDay"], "closeDay")
    length = posint(lua["length"], "length")
    gaps = posint(lua["gaps"], "gaps")
    minimum = posint(lua["minimumMonths"], "minimumMonths")
    require(1 <= rank <= n <= 18528, "rank out of bounds")
    require(-96 <= a < b <= 96 and gaps == b-a and gaps >= 6,
            "selected gate index outside attested bounded domain")
    require(252 <= length <= 5778 and closing-opening == length
            and opening < DAY <= closing, "selected interval invalid")
    require(minimum == max(3, (length+122)//123), "minimum month bound incorrect")
    reason = ("MIN_MONTHS_OVER_CAP" if minimum > 16
              else "WITHIN_MONTH_CAP_NOT_COMPOSED")
    require(lua["reason"] == reason, "misclassified static feasibility")
    require(n == py["candidateCount"] and rank == py["rank1"]
            and [a,b] == py["selected"] and length == py["length"]
            and opening == py["selectedOpeningDay"]
            and closing == py["selectedClosingDay"]
            and minimum == py["minimumMonths"],
            "HELDOUT_NATIVE_PYTHON_SELECTION_MISMATCH")
    return {"project_id": PROJECT, "source_sha": sha, "day": DAY,
            "candidate_count": n, "rank1": rank, "selected": [a,b],
            "length": length, "minimum_months": minimum, "reason": reason,
            "scope": "YEAR5000_SELECTION_ONLY",
            "composition": "NOT_INVOKED", "full_date": "NOT_RUN",
            "differential": "PASS_SINGLE_HELDOUT_ONLY"}

def verify_timing(raw):
    m = re.fullmatch(
        r"WALL_SECONDS=([0-9]+(?:\.[0-9]+)?)\nCPU_SECONDS=([0-9]+(?:\.[0-9]+)?)\nMAX_RSS_KB=([0-9]+)\n?",
        raw)
    require(m is not None, "missing raw time receipt")
    wall, cpu, rss = float(m[1]), float(m[2]), int(m[3])
    require(wall <= 120 and cpu <= 110 and rss <= 131072,
            "OS resource budget exceeded")
    return {"wall_seconds": wall, "cpu_seconds": cpu, "max_rss_kib": rss}

def selftest():
    # Synthetic coordinates only; not a claim about canonical gate days.
    opening, length = DAY-1000, 5294
    py = {"candidateCount": 69, "rank1": 56, "selected": [71,82],
          "length": length, "selectedOpeningDay": opening,
          "selectedClosingDay": opening+length, "minimumMonths": 44}
    sha = "a"*40
    valid = dict(zip(FIELDS, [sha, str(DAY), "5000", "69", "56", "71", "82",
                               str(opening), str(opening+length), "5294",
                               "11", "44", "MIN_MONTHS_OVER_CAP"]))
    require(verify_pair(py, valid, sha)["differential"] == "PASS_SINGLE_HELDOUT_ONLY",
            "positive synthetic control failed")
    changes = [("sourceSha","b"*40), ("day",str(DAY+1)), ("year","4999"),
               ("candidateCount","68"), ("rank1","55"), ("openIndex","70"),
               ("closeIndex","83"), ("openDay",str(opening-1)),
               ("closeDay",str(opening+length+1)), ("length","5293"),
               ("gaps","12"), ("minimumMonths","43"), ("reason","ADMITTED")]
    passed = 1
    for key, value in changes:
        altered = copy.deepcopy(valid)
        altered[key] = value
        try:
            verify_pair(py, altered, sha)
        except ValueError:
            passed += 1
        else:
            raise AssertionError("accepted malformed synthetic field " + key)
    require(passed == 14, "mutation control count mismatch")
    print("HELDOUT_VERIFIER_SYNTHETIC_SELFTEST: 14/14 PASS")

def main():
    if sys.argv[1:] == ["--selftest"]:
        selftest()
        return
    require(len(sys.argv) == 8 and sys.argv[1] == "--verify",
            "usage --verify PY_STDOUT LUA_STDOUT LUA_TIME LUA_STDERR LUA_EXIT SHA")
    _, _, pyout, nativeout, timing, stderr, exitcode, sha = sys.argv
    require(Path(stderr).read_bytes() == b"", "native stderr not empty")
    require(Path(exitcode).read_text().strip() == "0", "native process did not exit zero")
    py = decode_python(Path(pyout).read_text())
    native = decode_lua(Path(nativeout).read_text())
    receipt = verify_pair(py, native, sha)
    receipt["resources"] = verify_timing(Path(timing).read_text())
    print(json.dumps(receipt,sort_keys=True,separators=(",",":")))
    print("HELDOUT_NATIVE_DIFFERENTIAL: PASS day=-15017676 rank=56/69 gates=71..82")
    print("HELDOUT_SCOPE: SELECTION_ONLY; COMPOSITION_NOT_INVOKED; FULL_DATE_NOT_RUN")

if __name__ == "__main__":
    try:
        main()
    except (KeyError, ValueError, AssertionError, OSError, IndexError, json.JSONDecodeError) as exc:
        print("HELDOUT_VERIFICATION: INCOMPLETE " + str(exc), file=sys.stderr)
        sys.exit(3)
