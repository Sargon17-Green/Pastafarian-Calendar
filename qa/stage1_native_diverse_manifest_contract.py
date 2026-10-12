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
