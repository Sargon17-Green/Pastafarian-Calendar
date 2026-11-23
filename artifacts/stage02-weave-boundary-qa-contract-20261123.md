# WAT+Español Stage02 — targeted weave boundary QA contract (2026-11-23)

PROJECT_ID: PC-BRANCH-WAT-SPANISH. Authorized branch: WAT+Español.

Base before this change: 552125b620ca69dae8782b4ea389cbbedbb09019.
Locked normative calendar WAT Git blob: 70267bb5730678f81d6138a2224d6b8d9a193eb8.
Locked isolated selector WAT Git blob: e23f013ab96b498b0ac365dbb1b25273c845e790.
No normative WAT changes permitted in this QA increment.

## Input, independent oracle, output

Input: nontrivial month-length vectors with entries >=2; all valid weave ranks;
zero-based target day offsets. An independent recursive DFS constructs valid
month-ID words directly, respecting ascending first and last appearances,
and sorts by lexicographic month ID. It does not use completion_table,
the production WAT source, or the previous combinatorial unrank algorithm
to derive the expected words.

Small fully enumerated families: [2,2,2,2], [2,3,2,2], [3,2,3],
[3,3,3], [4,3,2]. Their independently enumerated word counts from local
enumerator-only preflight were respectively 14, 37, 19, 71, 50 (191 total).
For each word/rank, compare full decoded word against DFS and the month/day
pair at the year endpoints, midpoint, and neighbors of every month first/last
occurrence. Reject ranks -1,0,N+1 and offsets -1,L; inject changed month
ID, day zero, and day > month length. Each mutation must return a failure.

Separate structural-only larger families: [5,7,9,11,13,15,17,19]
and [3,4,5,6,7,8,9]. Probe ranks 1,2,3,floor(N/2),N-2,N-1,N,
check full-word multiplicities, ordered first/last appearances, and
month/day consistency at five offsets. These tests do NOT independently
validate large-rank outputs.

## Evidence and gates

Local preflight: Python compilation PASS, source-independent DFS
enumeration returned the five counts above. No local full differential or
new Native/CI PASS is claimed before CI logs and exact-SHA artifact review.
New branch-only push workflow stores identity, code hashes, an enumeration
JSON, selftest log, full boundary JSON on success (partial evidence on error).
A completed successful job at the exact commit SHA plus logs and artifact
are required before accepting this *focused QA* gate.

Historical run 45087126165 / job 137408195912 and artifact 14779309057
remain historical 3-case Native trace evidence only. WasmKit was skipped.
Original Stage02 ZIP+manifest provenance is unverified; Stage02 NOT ACCEPTED.

NEXT: inspect the exact-SHA focused workflow completed outcome and evidence;
if a boundary mismatch occurs, isolate the minimal rank/offset and determine
whether the prior QA oracle or a contract assumption is wrong. Independently
recover authentic original Stage02 ZIP and manifest. Do not merge/main/release.
