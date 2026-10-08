#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Static source-map and byte-preservation guard for test-only 2D candidate.

The guard deliberately does not assert runtime safety: dynamic Funge-space
p/g ownership and actual execution still require native replay and IP trace.
"""
import hashlib

OLD = "qa/interleaved_work_counts_pre_lexical_baseline.b98"
NEW = "src/interleaved_work_counts.b98"
LEX = "qa/lexical_candidate.b98"
BASELINE_GIT_BLOB_SHA = "e06d8f75d6502b2771d6a76b00397c6b6dbee543"

def load(p):
    with open(p, "rb") as f:
        return f.read()

def git_blob_sha(payload):
    h = hashlib.sha1()
    h.update(("blob %d\0" % len(payload)).encode("ascii"))
    h.update(payload)
    return h.hexdigest()

def require(pred, message):
    if not pred:
        raise AssertionError(message)

old = load(OLD)
new = load(NEW)
# All QA production bytes must equal the separately native-qualified k+
# arithmetic source, rather than the now-frozen earlier lexical scanner.
lexical_baseline = load("qa/interleaved_work_counts_lexical_candidate.b98")
require(new == load("qa/interleaved_work_counts_kplus_2d_candidate.b98"),
        "QA production differs from its exact Native-qualified k+ source")
lex = load(LEX)
require(git_blob_sha(old) == BASELINE_GIT_BLOB_SHA,
        "pre-lexical baseline changed since native geometry baseline")

oldrows, newrows, lexrows = [p.split(b"\n") for p in (old, new, lex)]
require(len(oldrows) == len(newrows), "source height changed")
require(max(map(len, oldrows)) == max(map(len, newrows)),
        "Funge-space horizontal bounds changed")
require(newrows[0][:5] == b"v   >", "entry vector/right-heading bridge unexpected")
require(oldrows[0][:5] == b">&" + b"&"*3, "legacy input entry unexpected")
require(newrows[0][5:] == oldrows[0][5:],
        "any original day arithmetic at y=0 changed")
# Verify strictly localized intentional executable geometry insertion:
# original arithmetic opcode (1470,100): '+' -> 'v', while (1471,100)
# retains its original dynamic 'x'. The new row-101 circuit compensates
# for PyFunge's execute-k-then-execute-next semantics and rejoins at x.
baseline_rows = lexical_baseline.split(b"\n")
require(len(newrows) == len(baseline_rows),
        "native k+ geometry changed row count")
require(newrows[:100] == baseline_rows[:100],
        "production changed unrelated rows before k+ injection")
require(newrows[100][:1470] == baseline_rows[100][:1470]
        and baseline_rows[100][1470:1472] == b"+x"
        and newrows[100][1470:1472] == b"vx"
        and newrows[100][1472:] == baseline_rows[100][1472:],
        "unexpected source edit outside the exact arithmetic k+ entry")
k_lane = b">1-11k+0c-01-x"
require(newrows[101][:1470].rstrip() == baseline_rows[101][:1470].rstrip()
        and not baseline_rows[101][1470:].strip()
        and newrows[101][1470:].rstrip() == k_lane,
        "native arithmetic k+ detour not isolated to verified row-101 lane")
require(newrows[102:] == baseline_rows[102:],
        "production geometry outside the approved k+ circuit changed")
require(all(not row.strip() for row in oldrows[1:50]),
        "reserved top-of-map region no longer unoccupied")
for i in range(1, 50):
    if i in (41, 44):
        continue
    require(newrows[i] == lexrows[i],
            "scanner lane shifted or mutated at y=%d" % i)
require(newrows[41].rstrip().endswith(b"x"),
        "accept must return to legacy arithmetic through x")
require(newrows[44].rstrip().endswith(b"@"),
        "reject must halt without entering arithmetic")
require(b"&" not in b"\n".join(newrows[1:50]),
        "new lexical pathway must not reuse native integer &")
require(b"~" in newrows[5],
        "new lexical parser must operate at character level")
print("STAGE1_SCANNER_SOURCE_MAP_STATIC_PASS",
      "same_2d_extent=YES",
      "original_arithmetic_except_verified_kplus=YES",
      "reserved_parser_rows=1..49",
      "legacy_program_sha="+BASELINE_GIT_BLOB_SHA)
print("STATIC_PROOF_NOT_NATIVE_FUNCTIONAL_OR_STATE_OWNERSHIP_ACCEPTANCE")
