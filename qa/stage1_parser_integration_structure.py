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
# QA production must equal the independent ten-case Native-qualified advanced
# circuit. Frozen prior sources remain separately checked for exact provenance.
lexical_baseline = load("qa/interleaved_work_counts_lexical_candidate.b98")
previous_bifurcation = load("qa/interleaved_work_counts_native_bifurcation_candidate.b98")
require(new == load("qa/interleaved_work_counts_advanced_turn_jump_candidate.b98"),
        "QA production differs from exact Native-qualified advanced turn/jump source")
lex = load(LEX)
require(git_blob_sha(old) == BASELINE_GIT_BLOB_SHA,
        "pre-lexical baseline changed since native geometry baseline")

oldrows, newrows, lexrows = [p.split(b"\n") for p in (old, new, lex)]
priorrows = previous_bifurcation.split(b"\n")
require(len(priorrows) == len(newrows), "prior source height changed")
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
require(priorrows[102:1334] == baseline_rows[102:1334],
        "production geometry changed before the approved conditional fork")
require(newrows[1337:] == baseline_rows[1337:],
        "production geometry changed after the approved conditional fork")
require(baseline_rows[1335][950:952] == b"+!" and
        newrows[1335][:950] == baseline_rows[1335][:950] and
        newrows[1335][950:952] == b"x|" and
        newrows[1335][952:] == baseline_rows[1335][952:],
        "native logical-not and addition were not replaced by the exact fork/rejoin")
upper = b">0+01-00c-1x"
lower = b">1+01-00e-01-x"
require(not baseline_rows[1334][951:951+len(upper)].strip() and
        priorrows[1334][:951] == baseline_rows[1334][:951] and
        priorrows[1334][951:951+len(upper)] == upper and
        priorrows[1334][951+len(upper):] == baseline_rows[1334][951+len(upper):],
        "upper native arithmetic fork escaped its allocated source-map lane")
require(not baseline_rows[1336][951:951+len(lower)].strip() and
        priorrows[1336][:951] == baseline_rows[1336][:951] and
        priorrows[1336][951:951+len(lower)] == lower and
        priorrows[1336][951+len(lower):] == baseline_rows[1336][951+len(lower):],
        "lower native arithmetic fork escaped its allocated source-map lane")
# Preserve the complete previous two-arm circuit as an independent
# byte-exact source-map proof; the promoted advanced production differs
# from THAT Native-qualified source at precisely eleven checked cells.
permitted = {
    (958,1322): (ord(" "),ord("x")),
    (958,1323): (ord(" "),ord("c")),
    (958,1324): (ord(" "),ord("1")),
    (958,1325): (ord(" "),ord("c")),
    (958,1331): (ord(" "),ord("j")),
    (958,1332): (ord(" "),ord("5")),
    (958,1333): (ord(" "),ord("0")),
    (951,1334): (ord(">"),ord("]")),
    (958,1334): (ord("0"),ord("^")),
    (959,1334): (ord("c"),ord(">")),
    (951,1336): (ord(">"),ord("["))
}
observed = {}
for y, (former, current) in enumerate(zip(priorrows,newrows)):
    require(len(former) == len(current),
            "native advanced circuit unexpectedly changed source row extent y=%d" % y)
    if former != current:
        for x,(left,right) in enumerate(zip(former,current)):
            if left != right:
                observed[(x,y)] = (left,right)
require(observed == permitted,
        "advanced turn/j/x source differs from exact 11-cell native-qualified circuit")
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
      "original_arithmetic_except_verified_kplus_bifurcation_and_advanced=YES",
      "reserved_parser_rows=1..49",
      "legacy_program_sha="+BASELINE_GIT_BLOB_SHA)
print("STATIC_PROOF_NOT_NATIVE_FUNCTIONAL_OR_STATE_OWNERSHIP_ACCEPTANCE")
