#!/usr/bin/env python3
"""Stage20 independent post-run ZIP evidence auditor; does not import fixture or JS oracle.
Usage: python3 tools/stage20_initial_bowls_offline_audit.py artifact.zip ZIP_SHA256 RUN_SHA
"""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import zipfile

PROJECT = "PC-BRANCH-FALSE-ARABIC"
RUNTIME = "eb3135565a8670cced3f6bbca4dbf7b014c45634"
M = (1 << 127) - 1
WEIGHTS = (17, 19, 23, 29, 31, 37)
FINAL = "STAGE20_NATIVE_ALL_CASES_OK"
INVALID = ("header4", "header6", "direction0", "direction4")
MUTANTS = ("wrong_numeric", "wrong_sign")


def digest(data):
    return hashlib.sha256(data).hexdigest()


def signed(token):
    return -int(token[:-1]) if token.endswith("_") else int(token)


def parse_bigint(data):
    words = [signed(x) for x in re.findall(r"(\d+_?)a;!", data)]
    assert len(words) >= 3
    sign, n, *digits = words
    assert sign in (0, 1) and n >= 1 and n == len(digits)
    assert all(0 <= digit < 512 for digit in digits)
    assert n == 1 or digits[-1] != 0
    assert (sign == 0) == (n == 1 and digits[0] == 0)
    return sign * sum(digit * (512 ** index) for index, digit in enumerate(digits))


def fields_for(value):
    assert value > 0
    digits = []
    while value:
        digits.append(value % 512)
        value //= 512
    return [1, len(digits), *digits]


def oracle(c, t, d, s, q):
    assert min(c, t, d, s) >= 0 and q in (1, 2, 3)
    values = []
    for index, weight in enumerate(WEIGHTS, 1):
        raw = c + index * t + d + s + q + weight * weight + index
        values.append(raw % M or M)
    return values


def cases_in_program(body):
    rx = re.compile(
        r'z;u:((?:\d+_?a;!)+)\n'
        r'z;v:((?:\d+_?a;!)+)\n'
        r'z;w:((?:\d+_?a;!)+)\n'
        r'z;t:((?:\d+_?a;!)+)\n'
        r'z;y:5a;!u;a;!v;a;!w;a;!t;a;!(\d+)a;!\n'
        r'z;b:y;a;!b;s:b;37h;!!o:\n'
        r'(.*?)"STAGE20_CASE_(\d{3})_OK"10,', re.S,
    )
    found = list(rx.finditer(body))
    assert len(found) == 15, ("CASE_COUNT", len(found))
    for case_index, match in enumerate(found):
        assert int(match.group(7)) == case_index
        tag = f"STAGE20_CASE_{case_index:03d}"
        counts = [parse_bigint(match.group(i)) for i in range(1, 5)]
        q = int(match.group(5))
        values = oracle(*counts, q)
        code = match.group(6)
        assert f'o;g;!6=~["{tag}_OUT_HEADER_FAIL"' in code
        assert f'y;g;!5=~["{tag}_INPUT_HEADER_FAIL"' in code
        assert f'o;y;-0=["{tag}_OUT_ALIAS_FAIL"' in code
        assert f'b;g;!y;-0=~["{tag}_ARGUMENT_FAIL"' in code
        assert f'y;5+g;!{q}=~["{tag}_INPUT_DIRECTION_FAIL"' in code
        for index, output in enumerate(values, 1):
            assert code.count(f"o;{index}+g;!r:") == 1
            for cell, digit in enumerate(fields_for(output)):
                access = "r;g;!" if cell == 0 else f"r;{cell}+g;!"
                marker = f'{access}{digit}=~["{tag}_OUT_{index}_CELL_{cell}_FAIL"'
                assert marker in code, ("OUTPUT_ORACLE_MISMATCH", tag, index, cell)
        for index, (symbol, count) in enumerate(zip("uvwt", counts), 1):
            assert f'y;{index}+g;!{symbol};-0=~["{tag}_INPUT_HANDLE_{index}_FAIL"' in code
            rep = [0, 1, 0] if count == 0 else fields_for(count)
            for cell, field in enumerate(rep):
                access = f"{symbol};g;!" if cell == 0 else f"{symbol};{cell}+g;!"
                assert f'{access}{field}=~["{tag}_INPUT_{index}_CELL_{cell}_FAIL"' in code
        yield tag + "_OK"


def member(z, suffix):
    matches = [p for p in z.namelist() if p == suffix or p.endswith("/" + suffix)]
    assert len(matches) == 1, ("MISSING_OR_DUPLICATE_ZIP_ENTRY", suffix)
    return z.read(matches[0])


def normalize(data):
    return data.decode("utf-8").replace("\r", "").replace("\n", "")


def check(path, expected_zip_sha, expected_run_sha):
    zip_bytes = Path(path).read_bytes()
    assert digest(zip_bytes) == expected_zip_sha, "ZIP_SHA256"
    with zipfile.ZipFile(path) as z:
        assert z.testzip() is None, "ZIP_CRC"
        evidence = json.loads(member(z, "evidence.json"))
        assert evidence["project_id"] == PROJECT and evidence["stage"] == 20
        assert evidence["source_pin"] == expected_run_sha == evidence["github_sha"]
        assert evidence["runtime_pin"] == RUNTIME
        assert evidence["native_gate_passed"] is True
        source = evidence["source_sha256"]
        assert len(source) >= 11
        for source_path, observed_hash in source.items():
            original = subprocess.check_output(["git", "show", expected_run_sha + ":" + source_path])
            assert digest(original) == observed_hash, ("SOURCE_MISMATCH", source_path)
        base = (subprocess.check_output(["git", "show", expected_run_sha + ":src/bigint.false"]) + b"\n" +
                subprocess.check_output(["git", "show", expected_run_sha + ":src/monster_bootstrap.false"]) + b"\n")
        assert digest(base) == evidence["combined_source_sha256"]
        program = member(z, "positive.false")
        assert program.startswith(base)
        body = program[len(base):].decode("utf-8")
        labels = list(cases_in_program(body))
        assert len(labels) == 15 and body.endswith("[z;0>][%z;1-z:]#\n")
        assert evidence["positive"]["passed"] is True and evidence["positive"]["cases"] == 15
        assert evidence["positive"]["body_sha256"] == digest(body.encode())
        assert member(z, "positive.exit_code.txt").strip() == b"0"
        assert member(z, "positive.stderr.txt") == b""
        out = normalize(member(z, "positive.stdout.txt"))
        assert out == "".join(labels) + FINAL
        for name in INVALID:
            assert member(z, "invalid_" + name + ".false").startswith(base)
            assert member(z, "invalid_" + name + ".exit_code.txt").strip() == b"1"
            observed = normalize(member(z, "invalid_" + name + ".stdout.txt") +
                                 member(z, "invalid_" + name + ".stderr.txt"))
            error = "E_INITIAL_BOWLS_LENGTH" if name.startswith("header") else "E_INITIAL_BOWLS_DIRECTION"
            assert error in observed and "STAGE20_INVALID_ACCEPTED" not in observed
            assert evidence["invalid"][name]["rejected"] is True
        for name in MUTANTS:
            assert member(z, "mutant_" + name + ".false").startswith(base)
            assert member(z, "mutant_" + name + ".exit_code.txt").strip() == b"1"
            observed = normalize(member(z, "mutant_" + name + ".stdout.txt"))
            expected = "STAGE20_CASE_000_OUT_1_CELL_0_FAIL" if name == "wrong_sign" else "STAGE20_CASE_000_OUT_1_CELL_2_FAIL"
            assert expected in observed and FINAL not in observed
            assert evidence["mutants"][name]["rejected"] is True
        # Corrupt one expected numeric assertion: independent arithmetic must detect it.
        original = 'r;2+g;!291=~["STAGE20_CASE_000_OUT_1_CELL_2_FAIL"'
        modified = body.replace(original, 'r;2+g;!292=~["STAGE20_CASE_000_OUT_1_CELL_2_FAIL"', 1)
        assert modified != body
        corrupt_rejected = False
        try:
            list(cases_in_program(modified))
        except AssertionError:
            corrupt_rejected = True
        assert corrupt_rejected, "CORRUPTED_EXPECTATION_ACCEPTED"
        # Corrupt a stdout marker: exact stream comparison must detect it.
        assert out.replace(labels[0], "STAGE20_CASE_000_BAD", 1) != "".join(labels) + FINAL
        return {
            "project_id": PROJECT, "stage": 20, "zip_sha256": expected_zip_sha,
            "zip_crc": "PASS", "source_pin": expected_run_sha, "runtime_pin": RUNTIME,
            "source_blobs_verified": len(source), "native_cases": len(labels),
            "native_outputs_recomputed": 6 * len(labels),
            "invalid_controls_rejected": len(INVALID), "mutants_rejected": len(MUTANTS),
            "corrupt_expected_rejected": True, "corrupt_stdout_rejected": True,
            "offline_audit": "PASS", "stage20_acceptance": False,
            "physical_pointer_safety_assessed": False,
        }


def main():
    if len(sys.argv) != 4:
        sys.exit("usage: audit.py ARTIFACT.zip EXPECTED_ZIP_SHA256 EXPECTED_RUN_SHA")
    result = check(*sys.argv[1:])
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
