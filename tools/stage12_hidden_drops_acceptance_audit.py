#!/usr/bin/env python3
"""Independent offline audit of the pinned Stage 12 Native artifact."""

import argparse
import hashlib
import json
import re
import subprocess
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = "PC-BRANCH-FALSE-ARABIC"
RUN = "44367931777"
WORKFLOW = "5e46f82567c31ab3bad71508b9549cb4bdf10823"
SOURCE = "c7b84a6cbdb5e5147f35ba58629aac17b87ff74d"
RUNTIME = "eb3135565a8670cced3f6bbca4dbf7b014c45634"
COMBINED = "693edf03ffdffae2fad2e39753f1a0daf83b783de1ed35b0ce13c2a490e8a96d"
FIXTURE = "7122e5c33700f00f951a2d51c47c1ca8fe754dbf7c7f28a40b40954a537ff166"
MODULUS = (1 << 127) - 1
PAIRS = ((15055671, 15055671), (15055670, 15055672),
         (15055673, 15055669))


def require(test, message):
    if not test:
        raise ValueError(message)


def digest(blob):
    return hashlib.sha256(blob).hexdigest()


def git(revision, path):
    return subprocess.check_output(["git", "show", f"{revision}:{path}"], cwd=ROOT)


def independent_cases():
    # Reconstruct the five stone columns as state, rather than importing the
    # design oracle or its row builder.
    state = [17, 29, 43, 71, 101]
    stone_rows = [tuple(state)]
    for row_number in range(2, 47):
        old_a, old_b, old_c, old_d, old_e = state
        state = [((old_a**2 + 3*old_b + row_number - 1) % MODULUS) + 1,
                 ((old_b**2 + 5*old_c + old_a - 1) % MODULUS) + 1,
                 ((old_c**2 + 7*old_d + old_b - 1) % MODULUS) + 1,
                 ((old_d**2 + 11*old_e + old_c - 1) % MODULUS) + 1,
                 ((old_e**2 + 13*old_a + old_d - 1) % MODULUS) + 1]
        stone_rows.append(tuple(state))
    require(len(stone_rows) == 46 and
            stone_rows[45][0] == 73799454308499791987382386781055001470,
            "stone recurrence witness")
    cases = []
    for index, (calculation, target) in enumerate(PAIRS):
        offset_a, offset_b = calculation - 15055671, target - 15055671
        count_a = 2*offset_a + 1 if offset_a >= 0 else -2*offset_a
        count_b = 2*offset_b + 1 if offset_b >= 0 else -2*offset_b
        direction = 1 + (target > calculation) + 2*(target < calculation)
        counts = (count_a, count_b, abs(target-calculation)+1,
                  count_a+count_b, direction)
        answers = []
        for row_number in range(1, 8):
            stone = stone_rows[row_number-1]
            coefficient = (2*row_number + 1, 3*row_number + 1,
                           4*row_number + 2, 4*row_number + 4)
            value = (counts[0] + sum(coefficient[j]*counts[j+1]
                                     for j in range(4)) + sum(stone)-1) % MODULUS + 1
            for step in range(1, 8):
                value = ((value*value + 3*value + stone[(step-1) % 5]
                          + step-1) % MODULUS) + 1
            answers.append(value)
        cases.append({"index": index, "calculation": str(calculation),
                      "target": str(target), "counts": [str(x) for x in counts],
                      "drops": [str(x) for x in answers]})
    return cases


def verify(archive, archive_sha, overrides=None):
    require(re.fullmatch(r"[0-9a-f]{64}", archive_sha) is not None, "SHA syntax")
    require(digest(archive.read_bytes()) == archive_sha, "artifact SHA")
    with zipfile.ZipFile(archive) as z:
        require(z.testzip() is None, "ZIP CRC")

        def raw(name):
            return (overrides[name] if overrides and name in overrides
                    else z.read(name))

        def read(name):
            return raw(name).decode("utf-8")

        receipt, oracle = json.loads(read("evidence.json")), json.loads(read("oracle.json"))
        fields = {"project_id": PROJECT, "github_run_id": RUN,
                  "github_sha": WORKFLOW, "source_pin": SOURCE,
                  "source_observed": SOURCE, "runtime_pin": RUNTIME,
                  "runtime_observed": RUNTIME, "combined_sha256": COMBINED,
                  "fixture_sha256": FIXTURE}
        for field, expected in fields.items():
            require(receipt.get(field) == expected, f"receipt {field}")
        require(receipt.get("hidden_drops_native_verified") is True
                and receipt.get("stage12_full_acceptance") is False,
                "Native receipt boundary")
        require(read("source_observed.txt").strip() == SOURCE and
                read("runtime_observed.txt").strip() == RUNTIME,
                "observed commits")
        workflow = ".github/workflows/false-arabic-stage12-native-hidden-drops.yml"
        script = "tools/stage12_hidden_drops_ci.py"
        require(git(WORKFLOW, workflow) == (ROOT/workflow).read_bytes() and
                git(WORKFLOW, script) == (ROOT/script).read_bytes(),
                "workflow/runner bytes")
        paths = ("src/bigint.false", "src/monster_bootstrap.false",
                 "test/stage12_hidden_drops_21.false")
        locked = [git(SOURCE, path) for path in paths]
        exact = b"\n".join(locked) + b"\n"
        require(digest(locked[-1]) == FIXTURE and digest(exact) == COMBINED and
                raw("stage12_hidden_drops_exact.false") == exact and
                locked[-1].count(b"29h;!!q:") == 3, "executed source and cases")
        require(oracle.get("project_id") == PROJECT and oracle.get("stage") == 12
                and oracle.get("native_evidence") is False
                and oracle.get("fixture_sha256") == FIXTURE
                and tuple(oracle.get(key) for key in
                          ("anchor_pairs", "result_assertions", "input_assertions",
                           "shape_assertions", "replay_assertions")) == (3,21,15,3,6)
                and oracle.get("cases") == independent_cases(),
                "independent numerical oracle")
        labels = [f"STAGE12_HIDDEN_CASE_{i:02d}_{j}_OK"
                  for i in range(3) for j in range(1,8)]
        output = read("native.stdout.txt")
        final = "STAGE12_HIDDEN_21_RESULTS_15_INPUTS_6_REPLAYS_VERIFIED"
        require(re.findall(r"STAGE12_HIDDEN_CASE_\d{2}_[1-7]_OK", output) == labels
                and output.count(final) == 1 and output.rstrip().endswith(final)
                and "STAGE12_HIDDEN_DROPS_FAILURE" not in output,
                "native labels")
        require(read("native.exit_code.txt").strip() == "0" and
                raw("native.stderr.txt") == b"" and
                read("mutant.exit_code.txt").strip() == "1" and
                "STAGE12_HIDDEN_DROPS_FAILURE" in read("mutant.stdout.txt") and
                final not in read("mutant.stdout.txt"), "Native and mutant exits")
        require(read("compiler_exit_code.txt").strip() == "0" and
                read("preflight.txt").strip() == "ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS",
                "compiler and Unicode preflight")
        require(receipt.get("case_labels") == labels and
                tuple(receipt.get(k) for k in
                      ("result_assertions", "input_assertions", "shape_assertions",
                       "replay_assertions", "native_exit_code", "mutant_exit_code"))
                == (21,15,3,6,0,1), "receipt counts")
    return {"project_id": PROJECT, "stage": 12, "status": "ACCEPTED",
            "audit": "OFFLINE_INDEPENDENT", "run_id": RUN, "workflow_sha": WORKFLOW,
            "source_sha": SOURCE, "runtime_sha": RUNTIME,
            "archive_sha256": archive_sha, "combined_sha256": COMBINED,
            "fixture_sha256": FIXTURE, "anchor_pairs": 3,
            "result_assertions": 21, "input_assertions": 15,
            "shape_assertions": 3, "replay_assertions": 6,
            "negative_controls": ["mutant"], "next_stage": 13}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    parser.add_argument("--sha256", required=True)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    report = verify(args.archive, args.sha256)
    with zipfile.ZipFile(args.archive) as z:
        damaged = json.loads(z.read("oracle.json"))
    damaged["cases"][0]["drops"][0] = "1"
    try:
        verify(args.archive, args.sha256,
               {"oracle.json": json.dumps(damaged).encode("utf-8")})
    except ValueError:
        report["audit_negative_control"] = "REJECTED_CORRUPTED_EXPECTED_DROP"
    else:
        raise SystemExit("AUDIT_NEGATIVE_CONTROL_FAILED")
    output = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.write_text(output)
    print(output, end="")


if __name__ == "__main__":
    main()
