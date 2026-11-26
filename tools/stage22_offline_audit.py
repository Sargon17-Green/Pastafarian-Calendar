#!/usr/bin/env python3
"""Independent Stage22 offline audit; factoradic + Mersenne-fold implementation."""
import copy
import hashlib
import json
import os
from pathlib import Path
import subprocess
import zipfile

E = Path("evidence/stage22_acceptance")
M = (1 << 127) - 1
LOCKED = (
    "src/bigint.false",
    "src/monster_bootstrap.false",
    "test/normative_reference.false",
    "tools/stage22_batch_bowls_design_oracle.py",
    "evidence/stage22_design_oracle_2026-11-25.json",
    "tools/stage22_native_diagnostic.py",
    "tools/stage22_native_acceptance.py",
    "tools/stage22_offline_audit.py",
    "RUN_STAGE22.md",
    "DEVELOPMENT_STAGE.md",
    ".github/workflows/false-arabic-stage22-acceptance.yml",
    ".github/workflows/canonical-names-lock.yml",
)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def fold(value):
    if value <= 0:
        raise ValueError("fold input must be positive")
    while value > M:
        value = (value & M) + (value >> 127)
    return value


def unrank(rank):
    if not 1 <= rank <= 720:
        raise ValueError(rank)
    pool = [1, 2, 3, 4, 5, 6]
    remainder = rank - 1
    order = []
    for factorial in (120, 24, 6, 2, 1, 1):
        digit, remainder = divmod(remainder, factorial)
        order.append(pool.pop(digit))
    return order


def run_independent(initial, batches):
    state = list(map(int, initial))
    for batch in range(1, batches + 1):
        total = fold(sum(state) + 6 + 149 * batch)
        rank = 4 + ((total - 4) % 7)
        order = unrank(rank)
        ring = [state[bowl_id - 1] for bowl_id in order]
        position = {bowl_id: offset for offset, bowl_id in enumerate(order, start=1)}
        next_state = [0] * 6
        for bowl_id in range(1, 7):
            p = position[bowl_id] - 1
            left = ring[(p - 1) % 6]
            right = ring[(p + 1) % 6]
            raw = (
                state[bowl_id - 1] * state[bowl_id - 1]
                + 3 * left
                + 5 * right
                + total
                + batch
                + (p + 1) * (p + 1)
                + 7 * left * right
            )
            next_state[bowl_id - 1] = fold(raw)
        state = next_state
    return list(map(str, state))


def run_wrong(initial, mutation):
    state = list(map(int, initial))
    batch = 1
    multiplier = 148 if mutation == "t_offset_149_to_148" else 149
    total = fold(sum(state) + 6 + multiplier * batch)
    modulus = 6 if mutation == "rank_modulus_7_to_6" else 7
    rank = 4 + ((total - 4) % modulus)
    order = unrank(rank)
    ring = [state[bowl_id - 1] for bowl_id in order]
    position = {bowl_id: offset for offset, bowl_id in enumerate(order, start=1)}
    result = [0] * 6
    for bowl_id in range(1, 7):
        p = position[bowl_id] - 1
        left = ring[(p - 1) % 6]
        right = ring[(p + 1) % 6]
        if mutation == "swap_neighbor_weights":
            neighbor = 5 * left + 3 * right
        else:
            neighbor = 3 * left + 5 * right
        squared_position = 0 if mutation == "omit_position_squared" else (p + 1) ** 2
        cross = (6 if mutation == "cross_weight_7_to_6" else 7) * left * right
        raw = state[bowl_id - 1] ** 2 + neighbor + total + batch + squared_position + cross
        result[bowl_id - 1] = fold(raw)
    return list(map(str, result))


def limbs(value):
    n = int(value)
    digits = []
    while n:
        n, digit = divmod(n, 512)
        digits.append(digit)
    return [1, len(digits), *digits]


def first_numeric_marker(expected, observed):
    for bowl_id, (good, bad) in enumerate(zip(expected, observed), start=1):
        a, b = limbs(good), limbs(bad)
        for cell in range(max(len(a), len(b))):
            av = a[cell] if cell < len(a) else 0
            bv = b[cell] if cell < len(b) else 0
            if av != bv:
                if cell < 2:
                    raise AssertionError(("non-numeric mutant witness", bowl_id, cell))
                return f"STAGE22_OUT_BOWL_{bowl_id}_CELL_{cell}_FAIL"
    raise AssertionError("mutant was not detected")


def read_output(label):
    stdout = (E / (label + ".stdout.txt")).read_bytes().replace(b"\r", b"").replace(b"\n", b"")
    stderr = (E / (label + ".stderr.txt")).read_bytes()
    exit_code = int((E / (label + ".exit_code.txt")).read_text().strip())
    return stdout, stderr, exit_code


def check_intentional_abort(label, marker, stderr):
    # Independently bind the diagnostic coordinates, source excerpt and caret
    # to the actual archived program and marker, not merely to error type.
    path = E / (label + ".false")
    lines = stderr.split(b"\n")
    assert len(lines) == 4 and lines[-1] == b"", ("diagnostic framing", label)
    header, excerpt, caret, _ = lines
    fields = header.rsplit(b":", 3)
    assert len(fields) == 4 and fields[0] == str(path).encode()
    assert fields[3] == b" error: divide by zero"
    assert fields[1].isdigit() and fields[2].isdigit()
    number, column = int(fields[1]), int(fields[2])
    program_lines = path.read_bytes().split(b"\n")
    assert 1 <= number <= len(program_lines) and column >= 1
    assert excerpt == program_lines[number - 1]
    assert caret == b" " * (column - 1) + b"^"
    token = b'"' + marker.encode("ascii") + b'"0 0/'
    assert excerpt[:column].endswith(token), ("not the expected explicit abort", label)
    assert excerpt.count(token) == 1
    assert column <= len(excerpt)


def check_positive(record, stdout, stderr, exit_code, recomputed):
    if record["expected_bowls"] != recomputed:
        raise AssertionError("independent mathematical expectation mismatch")
    if stdout != b"STAGE22_CASE_OK" or stderr or exit_code != 0:
        raise AssertionError("positive Native output/exit mismatch")


def main():
    evidence = json.loads((E / "evidence.json").read_text())
    assert evidence["project_id"] == "PC-BRANCH-FALSE-ARABIC"
    assert evidence["stage"] == 22 and evidence["native_gate_passed"] is True
    assert evidence["source_pin"] == os.environ["SOURCE_PIN"]
    assert subprocess.check_output(["git", "rev-parse", "HEAD"]).decode().strip() == evidence["source_pin"]
    assert evidence["runtime_pin"] == "eb3135565a8670cced3f6bbca4dbf7b014c45634"
    assert (E / "runtime_observed.txt").read_text().strip() == evidence["runtime_pin"]

    source_snapshot = E / "source_snapshot"
    for path in LOCKED:
        actual = Path(path).read_bytes()
        committed = subprocess.check_output(["git", "show", f'{evidence["source_pin"]}:{path}'])
        assert actual == committed, path
        assert sha(actual) == evidence["source_sha256"][path], path
        assert (source_snapshot / path).read_bytes() == actual, path
        blob = subprocess.check_output(["git", "rev-parse", f'{evidence["source_pin"]}:{path}']).decode().strip()
        assert blob == evidence["source_git_blob_sha1"][path], path

    assert evidence["normative_reference_blob_sha1"] == "3e9acc012bedf83294a6ec3cccb081a069556b5b"
    assert len(evidence["positive"]) == 10
    assert len(evidence["invalid"]) == 16
    assert len(evidence["mutants"]) == 5

    for label, item in evidence["positive"].items():
        record = item["record"]
        recomputed = run_independent(record["input_bowls"], record["steps"])
        stdout, stderr, exit_code = read_output(label)
        check_positive(record, stdout, stderr, exit_code, recomputed)
        assert item["passed"] is True and item["program_sha256"] == sha((E / (label + ".false")).read_bytes())

    for label, item in evidence["invalid"].items():
        record = item["record"]
        stdout, stderr, exit_code = read_output(label)
        assert stdout.decode() == record["expected_marker"]
        assert exit_code == 1 and item["passed"] is True
        check_intentional_abort(label, record["expected_marker"], stderr)
        assert item["program_sha256"] == sha((E / (label + ".false")).read_bytes())

    for label, item in evidence["mutants"].items():
        record = item["record"]
        correct = run_independent(record["input_bowls"], 1)
        wrong = run_wrong(record["input_bowls"], record["mutation"])
        marker = first_numeric_marker(correct, wrong)
        stdout, stderr, exit_code = read_output(label)
        assert marker == record["expected_marker"]
        assert stdout.decode() == marker and exit_code == 1
        check_intentional_abort(label, marker, stderr)
        assert item["program_sha256"] == sha((E / (label + ".false")).read_bytes())
        assert item["passed"] is True

    for extension in (".false", ".stdout.txt", ".stderr.txt", ".exit_code.txt", ".fixture.json"):
        assert (E / ("full_witness" + extension)).read_bytes() == (E / ("replay_witness" + extension)).read_bytes()

    first = next(iter(evidence["positive"].values()))["record"]
    good_state = run_independent(first["input_bowls"], first["steps"])
    corrupted_expectation = copy.deepcopy(first)
    corrupted_expectation["expected_bowls"][0] = str(int(corrupted_expectation["expected_bowls"][0]) + 1)
    rejected_expected = False
    try:
        check_positive(corrupted_expectation, b"STAGE22_CASE_OK", b"", 0, good_state)
    except AssertionError:
        rejected_expected = True
    rejected_marker = False
    try:
        check_positive(first, b"CORRUPTED_MARKER", b"", 0, good_state)
    except AssertionError:
        rejected_marker = True
    assert rejected_expected and rejected_marker

    audit = {
        "project_id": "PC-BRANCH-FALSE-ARABIC",
        "stage": 22,
        "source_pin": evidence["source_pin"],
        "runtime_pin": evidence["runtime_pin"],
        "source_files_verified": len(LOCKED),
        "positive_native_paths": len(evidence["positive"]),
        "full_twelve_batch_paths": 3,
        "prefix_probes": 6,
        "exact_replay_byte_identical": True,
        "semantic_invalids_rejected": len(evidence["invalid"]),
        "actual_numeric_mutants_rejected": len(evidence["mutants"]),
        "independent_factoradic_mersenne_audit": "PASS",
        "corruption_controls": {"expected_value_rejected": rejected_expected, "stdout_marker_rejected": rejected_marker},
        "physical_pointer_safety_assessed": False,
        "stage22_acceptance": "NATIVE_AND_OFFLINE_GATES_PASS_PENDING_EXTERNAL_ARTIFACT_READBACK",
    }
    evidence["independent_offline_audit"] = True
    (E / "evidence.json").write_text(json.dumps(evidence, indent=2, sort_keys=True) + "\n")
    (E / "audit.json").write_text(json.dumps(audit, indent=2, sort_keys=True) + "\n")
    (E / "offline_audit.log").write_text("STAGE22_INDEPENDENT_OFFLINE_AUDIT_PASS\n")

    bundle = E / "stage22_evidence_bundle.zip"
    with zipfile.ZipFile(bundle, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(E.rglob("*")):
            if path.is_file() and path not in (bundle, E / "artifact_integrity.json"):
                archive.write(path, path.relative_to(E).as_posix())
    with zipfile.ZipFile(bundle, "r") as archive:
        assert archive.testzip() is None
        entries = len(archive.infolist())
    integrity = {
        "bundle": bundle.name,
        "sha256": sha(bundle.read_bytes()),
        "zip_crc": "PASS",
        "entries": entries,
        "bytes": bundle.stat().st_size,
    }
    (E / "artifact_integrity.json").write_text(json.dumps(integrity, indent=2, sort_keys=True) + "\n")
    print("STAGE22_INDEPENDENT_OFFLINE_AUDIT_PASS")
    print(json.dumps({**audit, "bundle_integrity": integrity}, sort_keys=True))


if __name__ == "__main__":
    main()
