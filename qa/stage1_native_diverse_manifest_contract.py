#!/usr/bin/env python3
"""Independent Stage-1 native diverse-corpus manifest integrity witness.

This verifies reported provenance and saved output files. It does NOT
implement Pastafarian arithmetic or replace a Native PyFunge execution.
"""
import copy
import hashlib
import json
import re
import tempfile
from pathlib import Path

# Independently duplicated from the frozen 17-case Native producer. Deliberately
# do not import producer case data: a coordinated producer drift must fail.
NATIVE_CASES = (
    ("zero_equal",                    (0, 0, 0, 0), True),
    ("foundation_cross",              (1, 15055672, 1, 15055670), True),
    ("forward_short",                 (0, 1, 0, 2), True),
    ("reverse_short",                 (0, 2, 0, 1), True),
    ("mixed_small",                   (1, 1, 0, 1), True),
    ("positive_negative",             (0, 123456789, 1, 987654321), True),
    ("negative_positive",             (1, 987654321, 0, 123456789), True),
    ("large_values",                  (0, 2**127, 1, 2**127 - 1), True),
    ("invalid_zero_sign",             (1, 0, 0, 0), False),
    ("invalid_big_sign",              (2, 10, 0, 10), False),
    ("epoch_forward_one",             (0, 0, 0, 1), True),
    ("epoch_reverse_one",             (0, 1, 0, 0), True),
    ("recent_anchor_equal",           (0, 2461319, 0, 2461319), True),
    ("recent_anchor_next",            (0, 2461319, 0, 2461320), True),
    ("foundation_neighbor_forward",   (1, 15055671, 1, 15055670), True),
    ("foundation_neighbor_reverse",   (1, 15055670, 1, 15055671), True),
    ("invalid_target_zero_sign",      (0, 0, 1, 0), False),
)
HEX_256 = re.compile(r"[0-9a-f]{64}\Z", re.ASCII)
DECIMAL = re.compile(r"-?(?:0|[1-9][0-9]*)\Z", re.ASCII)


def need(ok, message):
    if not ok:
        raise AssertionError(message)


def check_manifest_cases(items):
    """Fail-closed agreement on the exact Native input/domain oracle corpus."""
    need(type(items) is list and len(items) == len(NATIVE_CASES),
         "Native 17-case manifest size or type changed")
    for i, (row, (name, fields, valid)) in enumerate(zip(items, NATIVE_CASES)):
        need(type(row) is dict and row.get("case") == name,
             "Native 17-case manifest order/label changed at %d" % i)
        raw_fields = row.get("fields")
        need(type(raw_fields) is list and len(raw_fields) == 4 and
             all(type(x) is int for x in raw_fields) and
             tuple(raw_fields) == fields and
             type(row.get("valid")) is bool and row["valid"] is valid,
             "Native input or validity class drifted: " + name)
        need(row.get("trace_file") == name + ".tsv" and
             type(row.get("trace_sha256")) is str and
             HEX_256.fullmatch(row["trace_sha256"]) is not None,
             "Native trace filename/hash contract drifted: " + name)
        answer = row.get("output")
        need(type(answer) is list and len(answer) == 7 and
             all(type(x) is str and DECIMAL.fullmatch(x) for x in answer),
             "Native seven-field decimal output shape drifted: " + name)
        if not valid:
            need(answer == ["-1"] * 7,
                 "Native invalid family lost its seven sentinel outputs: " + name)
    return True


def check_saved_outputs(folder, items):
    """Verify byte-exact producer .out files, not self-consistent JSON alone."""
    root = Path(folder)
    for item in items:
        path = root / (item["case"] + ".out")
        need(path.is_file(), "Native saved output missing: " + item["case"])
        raw = path.read_bytes()
        expected = (" ".join(item["output"]) + "\n").encode("ascii")
        need(raw == expected,
             "Native saved .out differs from manifest: " + item["case"])
    return True



# Independent of the producer and the fresh-process replay implementation.
NATIVE_REPLAY_PROGRAM_PINS = {
    "src/interleaved_work_counts.b98":
        "560d6aa5807a7f766213a33835cce85eab0fa40c",
    "reference/work_counts.b98":
        "f941efc793c9eee4accf5d03873f8ed029b16725",
    "reference/save.b98":
        "7b5e79aa6e2bfb636717cb018a3db6a13fb2bb44",
}
NATIVE_REPLAY_REJECTIONS = [
    "forged_manifest", "forged_saved_stdout",
    "coordinated_manifest_and_saved_stdout",
    "coordinated_production_claim_and_saved_stdout",
]


def verify_native_replay_document(doc, items, folder):
    need(type(doc) is dict and
         doc.get("schema") == "befunge-stage1-diverse-independent-native-replay-v1" and
         doc.get("source_git_blobs") == NATIVE_REPLAY_PROGRAM_PINS and
         doc.get("scope") == "QA_ONLY_NOT_STAGE1_ACCEPTANCE" and
         doc.get("native_production_reexecutions") == 17 and
         doc.get("independent_native_reference_executions") == 42 and
         doc.get("fresh_native_processes") == 59 and
         doc.get("invalid_cases_checked_with_native_production_and_sentinels") == 3 and
         doc.get("hostile_output_reports_rejected") == NATIVE_REPLAY_REJECTIONS and
         doc.get("stage1_complete") is False and
         doc.get("functional_stage1_gate") == "OPEN" and
         doc.get("geometric_stage1_gate") == "OPEN",
         "independent Native replay report provenance/counters/Stage1 drifted")
    rows = doc.get("records")
    need(type(rows) is list and len(rows) == 17 and len(items) == 17,
         "independent Native replay report lost 17 ordered cases")
    for recorded, item in zip(rows, items):
        name, output = item["case"], item["output"]
        digest = hashlib.sha256((" ".join(output) + "\n").encode("ascii")).hexdigest()
        need(type(recorded) is dict and
             recorded.get("case") == name and
             recorded.get("fields") == item["fields"] and
             recorded.get("valid") is item["valid"] and
             type(recorded.get("reference_native_runs")) is int and
             recorded["reference_native_runs"] == (3 if item["valid"] else 0),
             "independent Native replay case/inputs drifted: " + name)
        need(recorded.get("native_reference_output") ==
             recorded.get("native_production_output") == output and
             recorded.get("saved_output_sha256") == digest and
             hashlib.sha256((Path(folder) / (name + ".out")).read_bytes()).hexdigest() == digest,
             "independent Native replay output/sha differs: " + name)
    return True


def check_native_replay_report(folder, items):
    filename = Path(folder) / "native_diverse_independent_replay.json"
    need(filename.is_file(), "fresh Native reference replay artifact is missing")
    data = json.loads(filename.read_text(encoding="utf-8"))
    need(verify_native_replay_document(data, items, folder),
         "native reference replay report rejected")
    attacks = (
        ("forged_reference_answer", lambda d:
         d["records"][0]["native_reference_output"].__setitem__(0, "-12345")),
        ("missing_replay_record", lambda d: d["records"].pop()),
        ("inflated_native_processes", lambda d:
         d.__setitem__("fresh_native_processes", 60)),
        ("premature_stage_completion", lambda d:
         d.__setitem__("stage1_complete", True)),
    )
    for name, mutate in attacks:
        forged = copy.deepcopy(data)
        mutate(forged)
        try:
            verify_native_replay_document(forged, items, folder)
        except AssertionError:
            pass
        else:
            raise AssertionError("Native replay forged report accepted: " + name)
    print("NATIVE_DIVERSE_INDEPENDENT_REPLAY_REPORT_AUDIT_AND_4_TAMPERS_PASS")
    return True


def selftest():
    """Synthetic corruption checks; never count as actual Native results."""
    items = [dict(case=name, fields=list(fields), valid=valid,
                  trace_file=name+".tsv", trace_sha256="a"*64,
                  output=(["0"]*7 if valid else ["-1"]*7))
             for name, fields, valid in NATIVE_CASES]
    need(check_manifest_cases(items), "synthetic case roster did not validate")
    attacks = (
        ("reordered_case", lambda x: x.reverse()),
        ("missing_case", lambda x: x.pop()),
        ("modified_input", lambda x: x[0]["fields"].__setitem__(2, 1)),
        ("bool_as_magnitude", lambda x: x[0]["fields"].__setitem__(1, True)),
        ("string_as_magnitude", lambda x: x[0]["fields"].__setitem__(1, "0")),
        ("changed_validity", lambda x: x[0].__setitem__("valid", False)),
        ("truthy_validity", lambda x: x[0].__setitem__("valid", 1)),
        ("trace_alias", lambda x: x[0].__setitem__("trace_file", "other.tsv")),
        ("unsafe_trace_path", lambda x: x[0].__setitem__("trace_file", "../bad.tsv")),
        ("malformed_digest", lambda x: x[0].__setitem__("trace_sha256", "x"*64)),
        ("truncated_output", lambda x: x[0]["output"].pop()),
        ("boolean_output", lambda x: x[0]["output"].__setitem__(0, True)),
        ("padded_number", lambda x: x[0]["output"].__setitem__(0, "00")),
        ("invalid_non_sentinel", lambda x: x[8]["output"].__setitem__(0, "0")),
    )
    for name, corrupt in attacks:
        mutant = copy.deepcopy(items)
        corrupt(mutant)
        try:
            check_manifest_cases(mutant)
        except AssertionError:
            pass
        else:
            raise AssertionError("Native manifest corruption accepted: " + name)
    with tempfile.TemporaryDirectory(prefix="bf98-diverse-manifest-selftest-") as tmp:
        folder = Path(tmp)
        for item in items:
            (folder / (item["case"] + ".out")).write_bytes(
                (" ".join(item["output"]) + "\n").encode("ascii"))
        check_saved_outputs(folder, items)
        first = folder / (items[0]["case"] + ".out")
        first.write_bytes(b"0 0 0 0 0 0 1\n")
        try:
            check_saved_outputs(folder, items)
        except AssertionError:
            pass
        else:
            raise AssertionError("Native saved output tamper accepted")
        first.unlink()
        try:
            check_saved_outputs(folder, items)
        except AssertionError:
            pass
        else:
            raise AssertionError("Missing Native saved output accepted")
    print("NATIVE_DIVERSE_MANIFEST_16_ADVERSARIAL_CONTROLS_REJECT_PASS")
    print("TEST_ONLY_SYNTHETIC_PROVENANCE_NOT_NATIVE_EXECUTION")
    return True


if __name__ == "__main__":
    selftest()
