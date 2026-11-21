#!/usr/bin/env python3
"""Independent offline Stage18 Native ZIP auditor.
Checks original Git source blobs, ZIP integrity, native execution and
factoradic expectations from raw encoded BigInt fixtures. Does not reuse
the Stage18 fixture generator or the JS design oracle.
Usage: python3 tools/stage18_drop_order_offline_audit.py ARTIFACT.zip [SHA256]
"""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import zipfile

EXPECTED_PROJECT = "PC-BRANCH-FALSE-ARABIC"
EXPECTED_SOURCE = "9ab8511b05158f7ddbd0c664b8d6cc9f7efc1339"
EXPECTED_RUNTIME = "eb3135565a8670cced3f6bbca4dbf7b014c45634"
EXPECTED_RUN_SHA = "300cc893f1f1901cae1ad2b71835930cf8145466"
SIZES = (0, 150, 300, 450, 600)
FACT = (1, 1, 2, 6, 24, 120, 720)

def sha(blob):
    return hashlib.sha256(blob).hexdigest()

def git_blob(ref, path):
    return subprocess.check_output(["git", "show", f"{ref}:{path}"])

def factoradic(rank):
    assert 1 <= rank <= 720
    remaining = [1, 2, 3, 4, 5, 6]
    value = rank - 1
    result = [6]
    for width in range(6, 0, -1):
        q, value = divmod(value, FACT[width - 1])
        assert q < len(remaining)
        result.append(remaining.pop(q))
    return result

def signed(text):
    return -int(text[:-1]) if text.endswith("_") else int(text)

def decode_raw(tokens):
    nums = [signed(x) for x in tokens]
    assert len(nums) >= 3
    sign, count = nums[:2]
    limbs = nums[2:]
    assert sign in (-1, 0, 1) and count == len(limbs) and count >= 1
    assert all(0 <= x <= 511 for x in limbs)
    assert count == 1 or limbs[-1] != 0
    assert (sign == 0) == (count == 1 and limbs[0] == 0)
    value = sign * sum(x * (512 ** i) for i, x in enumerate(limbs))
    return value, nums

def check_generated(code, start, expected_length):
    """Reconstruct source-independent expectations from generated FALSE input."""
    cases = list(re.finditer(
        r'z;d:((?:\d+_?a;!)+)\n(.*?)"STAGE18_DROP_(\d{4})_OK"10,',
        code, re.DOTALL))
    assert len(cases) == expected_length, ("CASE_COUNT", len(cases), expected_length)
    for index, match in enumerate(cases):
        tag = f"STAGE18_DROP_{start+index:04d}"
        assert int(match.group(3)) == start + index
        fields = re.findall(r'(\d+_?)a;!', match.group(1))
        value, raw = decode_raw(fields)
        rank = value % 720 or 720
        expected = factoradic(rank)
        body = match.group(2)
        detected = re.findall(
            r'o;(\d+)\+g;!(\d+_?)=~\["STAGE18_DROP_\d{4}_OUTPUT_(\d+)_FAIL"',
            body)
        assert len(detected) == 7, ("OUTPUT_COUNT", tag, len(detected))
        for pos, ((cell, got, label), wanted) in enumerate(zip(detected, expected)):
            assert int(cell) == pos and int(label) == pos
            assert signed(got) == wanted, ("OUTPUT_ORACLE", tag, pos, got, wanted)
        markers = [
            f'b;g;!d=~["{tag}_ARG_CELL_FAIL"',
            f'b;s;-0=~["{tag}_ARG_HANDLE_FAIL"',
            f'o;b;-0=["{tag}_OUTPUT_ARG_ALIAS_FAIL"',
            f'o;d;-0=["{tag}_OUTPUT_BIG_ALIAS_FAIL"',
            f'd;g;!{str(raw[0]) if raw[0]>=0 else str(-raw[0])+"_"}=~["{tag}_SIGN_FAIL"',
            f'd;1+g;!{raw[1]}=~["{tag}_LIMB_COUNT_FAIL"',
        ]
        for marker in markers:
            assert marker in body, ("MISSING_ASSERTION", tag, marker)
        for offset, limb in enumerate(raw[2:], 2):
            assert f'd;{offset}+g;!{limb}=~["{tag}_LIMB_{offset}_FAIL"' in body
    return len(cases)

def file_from_zip(z, name):
    paths = [p for p in z.namelist() if p == name or p.endswith("/" + name)]
    assert len(paths) == 1, ("ZIP_PATH", name, paths)
    return z.read(paths[0])

def check_zip(path, expected_sha):
    archive = Path(path).read_bytes()
    digest = sha(archive)
    if expected_sha is not None:
        assert digest == expected_sha, ("ZIP_SHA256", digest, expected_sha)
    with zipfile.ZipFile(path) as z:
        assert z.testzip() is None, "ZIP_CRC_FAILURE"
        manifest = json.loads(file_from_zip(z, "evidence.json"))
        assert manifest["project_id"] == EXPECTED_PROJECT and manifest["stage"] == 18
        assert manifest["source_pin"] == EXPECTED_SOURCE
        assert manifest["runtime_pin"] == EXPECTED_RUNTIME
        assert manifest["github_sha"] == EXPECTED_RUN_SHA
        assert manifest["native_gate_passed"] is True
        source = manifest["source_sha256"]
        assert len(source) == 6
        for name, expected in source.items():
            assert sha(git_blob(EXPECTED_SOURCE, name)) == expected, ("SOURCE_SHA", name)
        prefix = (git_blob(EXPECTED_SOURCE, "src/bigint.false") + b"\n" +
                  git_blob(EXPECTED_SOURCE, "src/monster_bootstrap.false") + b"\n")
        assert sha(prefix) == manifest["combined_source_sha256"]
        observed = 0
        for start in SIZES:
            name = "positive_" + str(start)
            program = file_from_zip(z, name + ".false")
            assert program.startswith(prefix), ("UNPINNED_SOURCE", start)
            body = program[len(prefix):].decode("utf-8")
            assert check_generated(body, start, 150) == 150
            row = next(x for x in manifest["positive"] if x["start"] == start)
            assert row["cases"] == 150 and row["passed"] is True
            assert row["generated_fixture_sha256"] == sha(program[len(prefix):])
            assert file_from_zip(z, name + ".exit_code.txt").strip() == b"0"
            assert not file_from_zip(z, name + ".stderr.txt")
            stdout = file_from_zip(z, name + ".stdout.txt").decode("utf-8")
            wanted = [f"STAGE18_DROP_{i:04d}_OK" for i in range(start, start + 150)]
            assert re.findall(r"STAGE18_DROP_\d{4}_OK", stdout) == wanted
            last = f"STAGE18_CHUNK_{start:04d}_OK"
            assert stdout.count(last) == 1 and stdout.rstrip().endswith(last)
            assert not re.findall(r"STAGE18_DROP_[A-Z0-9_]+_FAIL", stdout)
            observed += 150
        assert observed == 750
        for name, marker in [
            ("bad_order", "STAGE18_DROP_0000_OUTPUT_1_FAIL"),
            ("bad_sign", "STAGE18_DROP_0000_SIGN_FAIL"),
        ]:
            base = "mutant_" + name
            assert file_from_zip(z, base + ".exit_code.txt").strip() == b"1"
            stdout = file_from_zip(z, base + ".stdout.txt").decode("utf-8")
            assert marker in stdout and "STAGE18_CHUNK" not in stdout
            assert manifest["mutants"][name]["rejected"] is True
        # Independent corrupt-oracle control: the checker must reject a wrong output value.
        native_first = file_from_zip(z, "positive_0.false")
        body = native_first[len(prefix):].decode("utf-8")
        corrupted = body.replace('o;1+g;!1=~["STAGE18_DROP_0000_OUTPUT_1_FAIL"',
                                 'o;1+g;!7=~["STAGE18_DROP_0000_OUTPUT_1_FAIL"', 1)
        assert corrupted != body
        rejected = False
        try:
            check_generated(corrupted, 0, 150)
        except AssertionError:
            rejected = True
        assert rejected, "AUDITOR_MUTATION_NOT_REJECTED"
        return dict(project_id=EXPECTED_PROJECT, stage=18, artifact_sha256=digest,
                    zip_crc_verified=True, source_pin=EXPECTED_SOURCE,
                    original_interpreter_pin=EXPECTED_RUNTIME, github_sha=EXPECTED_RUN_SHA,
                    original_source_blobs_verified=len(source), native_cases=observed,
                    two_negative_controls_rejected=True, corrupted_oracle_rejected=True,
                    independent_factoradic_audit_passed=True,
                    physical_pointer_safety_assessed=False)

def main():
    if len(sys.argv) not in (2, 3):
        sys.exit("usage: audit.py artifact.zip [expected_sha256]")
    report = check_zip(sys.argv[1], sys.argv[2] if len(sys.argv) == 3 else None)
    out = Path("evidence/stage18_independent_native_audit_result.json")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, sort_keys=True, indent=2) + "\n")
    print(json.dumps(report, sort_keys=True, indent=2))

if __name__ == "__main__":
    main()
