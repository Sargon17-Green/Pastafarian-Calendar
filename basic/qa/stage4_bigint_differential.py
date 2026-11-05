#!/usr/bin/env python3
"""Stage4 independent Python BigInt oracle vs live StarBasic in an isolated UNO profile."""
import argparse
import hashlib
import json
from pathlib import Path
import random
import shutil
import sys
import tempfile
import traceback

M = 170141183460469231731687303715884105727
SEED = 0x20261106
LOCKS = {
    "Standard/BigInt.xba": "b89dd817bb4f18fef6297d43ecfd04969e6cdca0",
    "Standard/CalendarSpaghetti.xba": "bc753e64dba2f691ec8916ffd8cc7e062bf681a2",
    "Standard/Tests.xba": "7a1efac6b851a97874589dc5e72ef8274b5c0fc5",
}
PROBE = """
' Stage4 CI-only probe, injected into a TEMPORARY COPY of Tests.xba.
Public Function Stage4Evaluate(ByVal x As String) As String
    Stage4Evaluate = BI_Normalize(x) & "|" & BI_RegularMod(x, BI_M) & "|" & BI_Save(x) & "|" & oldRemainder(x) & "|" & CalendarSpaghettiDiscovery01Remainder(x)
End Function
"""


def blob_sha(raw):
    return hashlib.sha1(b"blob " + str(len(raw)).encode("ascii") + b"\0" + raw).hexdigest()


def verify_sources(basic):
    for name, expected in LOCKS.items():
        got = blob_sha((basic / name).read_bytes())
        if got != expected:
            raise AssertionError("Stage3 source lock mismatch: %s %s != %s" % (name, got, expected))


def vectors():
    cases = {}
    groups = []

    def add(x):
        cases.setdefault(str(x), None)

    for k in range(-3, 4):
        for offset in (-2, -1, 0, 1, 2):
            add(k * M + offset)
    for s in ("0000", "-0000", "+0000", "+000001", "-000001", "0000002", "-0000002", "+0000002"):
        add(s)
    for n in (6, 9, 18, 19, 37, 38, 39, 40, 60, 80, 128, 256):
        for x in (10 ** n, -(10 ** n), 10 ** n + 1, -(10 ** n + 1)):
            add(x)
    rng = random.Random(SEED)
    digit_sizes = (1, 2, 8, 18, 38, 39, 40, 41, 80, 128, 256)
    for i in range(24):
        length = digit_sizes[i % len(digit_sizes)]
        x = rng.randrange(1, 10)
        for _ in range(length - 1):
            x = x * 10 + rng.randrange(10)
        if i % 2:
            x = -x
        for candidate in (x, -x, x + M, x - M, x + 2 * M):
            add(candidate)
        groups.append((str(x), str(x + M), str(x - M)))
    return tuple(cases), tuple(groups)


def oracle(s):
    x = int(s)
    r = x % M
    save = 1 + ((x - 1) % M)
    return (str(x), str(r), str(save), str(save), str(save))


def self_test():
    cases, groups = vectors()
    assert len(cases) >= 150 and len(set(cases)) == len(cases)
    assert len(groups) == 24
    assert oracle(str(M))[1:] == ("0", str(M), str(M), str(M))
    assert oracle(str(-M))[1:] == ("0", str(M), str(M), str(M))
    assert oracle(str(M + 1))[2] == "1"
    assert oracle("-1")[2] == str(M - 1)
    for a, b, c in groups:
        assert oracle(a)[1:] == oracle(b)[1:] == oracle(c)[1:]
    return cases, groups


def inject_temporary_probe(target):
    tests = target / "Standard" / "Tests.xba"
    raw = tests.read_text(encoding="utf-8")
    marker = "]]></script:module>"
    if raw.count(marker) != 1 or "Stage4Evaluate" in raw:
        raise AssertionError("Unexpected Tests.xba structure")
    tests.write_text(raw.replace(marker, PROBE + marker), encoding="utf-8")


def run(basic, output):
    import stage3_native_ci as office
    output.mkdir(parents=True, exist_ok=True)
    status = output / "status.txt"
    status.write_text("STARTED\n", encoding="utf-8")
    lines = ["id\tinput\tnormalized\tregular_mod\tsave\told_remainder\tdiscovery\texpected_normalized\texpected_mod\texpected_save\tresult"]
    try:
        verify_sources(basic)
        cases, groups = self_test()
        actual = {}
        errors = []
        with tempfile.TemporaryDirectory(prefix="pc-basic-punjabi-stage4-") as temp:
            profile = Path(temp) / "isolated-lo-profile"
            proc, context = office.office_session(profile, output / "lo-startup.log")
            try:
                pass  # Initialize a virgin LibreOffice profile before Basic registration.
            finally:
                office.stop_office(proc, context)
            target = profile / "user" / "basic"
            if target.exists():
                shutil.rmtree(target)  # Owned ephemeral profile only.
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copytree(basic, target)
            inject_temporary_probe(target)
            proc, context = office.office_session(profile, output / "lo-startup.log")
            try:
                factory = context.ServiceManager.createInstanceWithContext(
                    "com.sun.star.script.provider.MasterScriptProviderFactory", context)
                script = factory.createScriptProvider("").getScript(
                    "vnd.sun.star.script:Standard.Tests.Stage4Evaluate?language=Basic&location=application")
                for index, s in enumerate(cases, 1):
                    returned = script.invoke((s,), (), ())[0]
                    if not isinstance(returned, str):
                        raise AssertionError("Non-string UNO result for case %d: %r" % (index, returned))
                    fields = tuple(returned.split("|"))
                    if len(fields) != 5:
                        raise AssertionError("Incorrect field count for case %d: %r" % (index, returned))
                    want = oracle(s)
                    actual[s] = fields
                    good = fields == want
                    lines.append("\t".join(("S4_%04d" % index, s, *fields, want[0], want[1], want[2],
                                            "PASS" if good else "FAIL")))
                    if not good:
                        errors.append("S4_%04d: actual=%r expected=%r input=%s" % (index, fields, want, s))
                    if index % 20 == 0:
                        print("Stage4 live UNO %d/%d, mismatches=%d" % (index, len(cases), len(errors)), flush=True)
            finally:
                office.stop_office(proc, context)
        metamorphic = 0
        for center, plus, minus in groups:
            for shifted in (plus, minus):
                metamorphic += 1
                if actual[center][1:] != actual[shifted][1:]:
                    errors.append("METAMORPHIC_%d: %s / %s" % (metamorphic, center, shifted))
        (output / "cases.tsv").write_text("\n".join(lines) + "\n", encoding="utf-8")
        report = {
            "stage": 4, "native": "PASS" if not errors else "FAIL",
            "source_stage3_blob_locks": LOCKS, "seed": SEED, "modulus": str(M),
            "oracle": "Python int: x%M and 1+((x-1)%M)",
            "individual_cases": len(cases), "unique_cases": len(set(cases)),
            "native_invocations": len(actual), "metamorphic_pairs": metamorphic,
            "failures": len(errors), "errors": errors[:40],
            "stage3_regression": "Required independent stage3-native-green CI job: 148 unique PASS",
        }
        (output / "assertions.json").write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        status.write_text("PASS\n" if not errors else "FAILED\n", encoding="utf-8")
        print(json.dumps({k: v for k, v in report.items() if k != "source_stage3_blob_locks"}, sort_keys=True), flush=True)
        return 0 if not errors else 1
    except Exception:
        (output / "cases.tsv").write_text("\n".join(lines) + "\n", encoding="utf-8")
        status.write_text("FAILED\n", encoding="utf-8")
        (output / "error.txt").write_text(traceback.format_exc(), encoding="utf-8")
        traceback.print_exc()
        return 1


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--self-test", action="store_true")
    p.add_argument("--basic-dir", type=Path)
    p.add_argument("--output-dir", type=Path)
    a = p.parse_args()
    cases, groups = self_test()
    if a.self_test:
        print("STAGE4_PYTHON_SELFTEST_PASS cases=%d metamorphic_pairs=%d" % (len(cases), 2 * len(groups)))
        return 0
    if not a.basic_dir or not a.output_dir:
        p.error("--basic-dir and --output-dir are mandatory for native run")
    return run(a.basic_dir.resolve(), a.output_dir.resolve())


if __name__ == "__main__":
    sys.exit(main())
