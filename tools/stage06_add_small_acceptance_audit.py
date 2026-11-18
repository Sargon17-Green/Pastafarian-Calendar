#!/usr/bin/env python3
"""Offline byte and arithmetic audit of the pinned Stage 6 Native artifact."""

import argparse
import hashlib
import json
import re
import subprocess
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = "PC-BRANCH-FALSE-ARABIC"
RUN = "44321283079"
WORKFLOW = "1d567fe7613a4960dee96b02ad78c0e346e6961b"
SOURCE = "ef0b974aad41079ded998326bf6e92f3c83a57f1"
RUNTIME = "eb3135565a8670cced3f6bbca4dbf7b014c45634"
ARCHIVE = "1064264892eae57154ab6554ea75a89d22044bce305e38542342fe76c12adcf8"
COMBINED = "fd9c53df2335b0ab1ed7aac0f70998cd5ddfb8cb728957b09af362eac35162cc"
FIXTURE = "118ec416f4dad0b0e5371dc53f4057199fcd595807265d675ca676b177040f93"
M = 2**127 - 1
CASES = ((0, 0), (0, 1), (0, -1), (511, 1), (512, -1),
         (-512, 1), (-1, -511), (M, 1), (M, -2147483647),
         (-M, 2147483647), (2**256 - 1, 1), (-2**256, -1),
         (2**192 + 123456, -2147483647))


def check(ok, reason):
    if not ok:
        raise ValueError(reason)


def sha(blob):
    return hashlib.sha256(blob).hexdigest()


def git(path, rev):
    return subprocess.check_output(["git", "show", f"{rev}:{path}"], cwd=ROOT)


def verify(path, overrides=None):
    check(sha(path.read_bytes()) == ARCHIVE, "artifact sha256")
    with zipfile.ZipFile(path) as z:
        check(z.testzip() is None, "artifact CRC")

        def raw(name):
            return overrides[name] if overrides and name in overrides else z.read(name)

        def read(name):
            return raw(name).decode("utf-8")

        receipt = json.loads(read("evidence.json"))
        oracle = json.loads(read("oracle.json"))
        for key, expected in (("project_id", PROJECT), ("github_run_id", RUN),
                              ("github_sha", WORKFLOW), ("source_pin", SOURCE),
                              ("source_observed", SOURCE), ("runtime_pin", RUNTIME),
                              ("runtime_observed", RUNTIME), ("combined_sha256", COMBINED),
                              ("fixture_sha256", FIXTURE)):
            check(receipt.get(key) == expected, f"receipt {key}")
        check(receipt.get("add_small_native_verified") is True
              and receipt.get("stage6_full_acceptance") is False, "receipt boundary")
        check(read("source_observed.txt").strip() == SOURCE
              and read("runtime_observed.txt").strip() == RUNTIME, "observed commits")
        wf = ".github/workflows/false-arabic-stage06-native-add-small.yml"
        check(git(wf, WORKFLOW) == (ROOT / wf).read_bytes(), "workflow pinned bytes")
        paths = ("src/bigint.false", "src/monster_bootstrap.false", "test/stage06_add_small_13.false")
        files = [git(p, SOURCE) for p in paths]
        combined = b"\n".join(files) + b"\n"
        check(sha(files[-1]) == FIXTURE and sha(combined) == COMBINED, "pinned source SHA")
        check(raw("stage06_add_small_exact.false") == combined, "executed exact source")
        check(oracle.get("project_id") == PROJECT and oracle.get("stage") == 6
              and oracle.get("native_evidence") is False
              and (oracle.get("case_count"), oracle.get("result_assertions"),
                   oracle.get("input_assertions"), oracle.get("seeded_property_pairs"))
              == (13, 13, 26, 384) and oracle.get("fixture_sha256") == FIXTURE,
              "oracle metadata")
        check(len(oracle["cases"]) == 13, "oracle cases")
        labels = []
        for i, ((big, small), c) in enumerate(zip(CASES, oracle["cases"])):
            label = f"STAGE6_ADD_SMALL_CASE_{i:02d}_OK"
            check((c["index"], c["big"], c["small"], c["expected"], c["label"])
                  == (i, str(big), small, str(big + small), label), f"arithmetic case {i}")
            labels.append(label)
        out = read("native.stdout.txt")
        final = "STAGE6_ADD_SMALL_13_RESULTS_26_INPUTS_VERIFIED"
        check(re.findall(r"STAGE6_ADD_SMALL_CASE_\d{2}_OK", out) == labels,
              "ordered Native receipts")
        check(out.count(final) == 1 and out.rstrip().endswith(final)
              and "STAGE6_ADD_SMALL_FAILURE" not in out, "final receipt")
        check(read("native.exit_code.txt").strip() == "0" and raw("native.stderr.txt") == b"",
              "Native exit/stderr")
        check(read("compiler_exit_code.txt").strip() == "0"
              and read("preflight.txt").strip() == "ORIGINAL_UNICODE_PICK_PREFLIGHT_PASS",
              "compiler/Unicode preflight")
        mutant = read("mutant.stdout.txt")
        check(read("mutant.exit_code.txt").strip() == "1"
              and "STAGE6_ADD_SMALL_FAILURE" in mutant and final not in mutant,
              "mutant rejection")
        check(receipt.get("case_labels") == labels
              and (receipt.get("result_assertions"), receipt.get("input_assertions")) == (13, 26)
              and receipt.get("native_exit_code") == 0 and receipt.get("mutant_exit_code") == 1,
              "receipt counts")
    return {"project_id": PROJECT, "stage": 6, "status": "ACCEPTED",
            "audit": "OFFLINE_INDEPENDENT", "run_id": RUN, "workflow_sha": WORKFLOW,
            "source_sha": SOURCE, "runtime_sha": RUNTIME, "archive_sha256": ARCHIVE,
            "combined_sha256": COMBINED, "fixture_sha256": FIXTURE,
            "native_cases": 13, "result_assertions": 13, "input_assertions": 26,
            "seeded_python_pairs": 384, "negative_control": "mutant", "next_stage": 7}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("archive", type=Path)
    p.add_argument("--output", type=Path)
    args = p.parse_args()
    result = verify(args.archive)
    with zipfile.ZipFile(args.archive) as z:
        bad = json.loads(z.read("oracle.json"))
    bad["cases"][0]["expected"] = "1"
    try:
        verify(args.archive, {"oracle.json": json.dumps(bad).encode()})
    except ValueError:
        result["audit_negative_control"] = "REJECTED_CORRUPTED_EXPECTED_VALUE"
    else:
        raise SystemExit("audit accepted corrupted expected value")
    text = json.dumps(result, indent=2, sort_keys=True, ensure_ascii=False) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text, encoding="utf-8")
    print(text, end="")


if __name__ == "__main__":
    main()
