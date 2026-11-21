# QA31AP — original-source constant x-vector arithmetic and signed predecessor audit (2026-11-07)

PROJECT_ID: PC-BRANCH-BEFUNGE98-KYRGYZ
Branch: qa-befunge98-stage1-order-isolation-20261008
Verified starting HEAD: d6eac74ea47c5bc913c9c5a6b97a860e0b0203b5
Frozen production Git blob: 560d6aa5807a7f766213a33835cce85eab0fa40c
Original signed input QA31AI ZIP SHA256: 9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49
Prior candidate physical-event QA31AO ZIP SHA256: 68f48fc44260352a4ebe759b4ae63e259efd2e52f3171b022010af25910d45e8

## Concrete findings

Ten original-source `x` instructions dispatch into eleven original-source
`p` writer sites (one westward corridor includes two consecutive `p`
instructions, accounting for 140 extra `p` events).

There are exactly **1,570 observed executions of those ten x source
sites in 200 original signed Native traces** (3,628,390 STEPs). All 1,570
execute with the same site-specific vector and enter the original
QA31AO candidate `p` rays. No extra execution or alternate vector for
any of those ten `x` sites occurs in the frozen corpus.
The older QA31AO ledger had 1,710 `p` events at eleven sites; these
two different counts are CONSISTENT, not a missing trace.

For every one of these ten `x` sites, the exact frozen source contains a
contiguous stack-arithmetic suffix, **12–22 original source opcode bytes**.
All ten byte strings and their coordinate geometry were checked against
the exact source blob through GitHub, and the signed Native traces contain
the exact same unmodified source opcodes at those coordinates in all
1,570 dispatches.

The forward symbolic RPN stack proof is *structural*: starting with an
empty abstract stack, none of the source suffixes underflows, and each
constructs exactly two integer constants through only Funge-98 hex
digits `0..9,a..f`, `+`, `-`, and `*`. Therefore, if and only if
that precise unchanged-source straight-line suffix is traversed,
the two `x` vector operands are independent of *all earlier*
incoming stack values. No finite sampling assumption is needed for
this conditional result.

Original-source pinned x sites and source-computed vectors:

| x source IP | vector dx,dy | suffix bytes | signed executions |
|---|---|---:|---:|
| (37,0) | (348,575) | 18 | 140 |
| (62,195) | (513,1235) | 22 | 140 |
| (100,986) | (0,-506) | 12 | 140 |
| (290,318) | (0,1112) | 14 | 140 |
| (480,348) | (475,512) | 18 | 140 |
| (575,1295) | (760,-815) | 20 | 140 |
| (860,443) | (-665,512) | 20 | 140 |
| (1000,1050) | (-140,-950) | 22 | 225 |
| (1294,955) | (-434,190) | 20 | 140 |
| (1472,1620) | (-897,-665) | 22 | 225 |

Five x source sites each receive **100 distinct pre-suffix stack
states** in the 200 signed cases; the other five receive one distinct
pre-suffix stack state. Every vector is still fixed at that source
site. This supports and illustrates, but does not replace, the
original-source arbitrary-stack arithmetic proof.

## Reproducible evidence and independent checks

Artifact:
`/Befunge_QA_Artifacts/QA31AP_BEFUNGE98_KYRGYZ_SIGNED_X_VECTOR_AUDIT_20261107.zip`
ZIP SHA256: `2da0fb801bb3f2ea663d787cb19b07b4808a20f5cf6f1ac4573994d9939337b3`.
10 ZIP entries with ZIP CRC PASS, each non-manifest SHA256 in
MANIFEST.json verified. Source 46MB signed archive is NOT duplicated.

Evidence contains: all 1,570 per-event original signed receipt hashes,
raw input byte hex, signed STEP, IP and vector, the full preceding
source-byte suffix, pre-suffix original stack and 128-STEP bounded
control-op observations, 10 source byte pins, site CSV, forward source
audit, separate independent AST/receipt audit, full reproducible
Python stdlib-compatible scripts, and actual console logs.

Second independent verifier imports no forward code. It independently
reads the original signed source archive again, checks original nested
shard SHA256, each of 200 trace gzip SHA256/HALT receipts, all
3,628,390 ordered STEPs and next→IP links, 1,570 physical `x`
event tuples, source bytes and their locations, and computes the two
vector arithmetic expressions through a separate AST algorithm.
It rejects **20/20 deliberately corrupted synthetic reports**.
No additional original Native run or new GitHub full-corpus CI run
was performed.

## Explicit scope and non-claims

This is QA31AP PASS for a **finite, signed 200-case physical
reanalysis PLUS ten conditional original-source stack-independent
vector suffixes**. It is *not* evidence that arbitrary new natural
input cannot jump to the middle of one suffix, alter a source byte
via `p`, change an earlier control-flow selector, or reach a writer
through a noncanonical route. The 1,710 original `p` events in
QA31AO had zero writes to (1,49)/(3,49), but the physical
possibility on other inputs is UNKNOWN.

No concrete new natural-input counter-target witness was obtained.
Therefore no new Native action was justified. Production source
unchanged. Stage1 global, geometric, functional remain OPEN.
No merge, main, or Stage2.

## NEXT QA31AQ

Investigate bounded **upstream source selector reachability** before
the first opcode in each of the ten stack-constant x suffixes,
using all 200 original signed stdin+STEP/IP receipts and the exact
source Git blob. Identify earliest case-pair control-flow divergences
for source-input variations; source-pin real conditional branches,
memory writes and possible self-modification upstream of each suffix.
Try to derive a concrete independently validated new raw input that
breaks the standard source suffix/enters a candidate p from another
route. If no such input is grounded, preserve UNKNOWN and do not run
Native. A future Native candidate must be independent and capped at
<=25000 STEP/case. No main/merge/Stage2; Stage1 OPEN.
