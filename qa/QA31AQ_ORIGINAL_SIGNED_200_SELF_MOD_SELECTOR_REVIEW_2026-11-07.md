# QA31AQ — original signed 200-case self-modifying source selector and input-pair divergence (2026-11-07)

PROJECT_ID: PC-BRANCH-BEFUNGE98-KYRGYZ
Original production Git blob: 560d6aa5807a7f766213a33835cce85eab0fa40c
Branch: qa-befunge98-stage1-order-isolation-20261008
Previous verified HEAD: f54568004f140baefc8b57ed41db37e7be2245dc
No production source changes; no new Native, no full-corpus GitHub CI, no main/merge/Stage2.

## Original signed evidence

QA31AI immutable 200-trace original:
`/Befunge_QA_Artifacts/QA31AI_BEFUNGE98_KYRGYZ_SIGNED_200_COUNTER_PREFIX_20261106.zip`
SHA256: `9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49`.
Eight QA31V shard SHA256 values pinned from original QA31X source and independently
recomputed. All 200 original signed gzip SHA256, HALT receipts, 3,628,390
contiguous STEP indices and next→IP links verified. No new original Native run.
Previous QA31AP source/trace ZIP SHA256:
`2da0fb801bb3f2ea663d787cb19b07b4808a20f5cf6f1ac4573994d9939337b3`.

## Definitively observed bounded mechanism

The frozen **original SOURCE BYTE** at (1500,1750) is ASCII 32 (space);
(1501,1750) is `>` and (1500,1751) is `v`. In 140/200
original signed physical traces, **p(1335,1354)** wrote to source
address (1500,1750) either ASCII 62 (`>`) or ASCII 118 (`v`).
An original signed IP step executed the rewritten cell exactly **20
STEPs** later, with matching execution opcode and next-IP.

There are 365 such source-modifying puts and corresponding executions:
140 `>` (turn east), 225 `v` (turn south), with no alternative
physical `p` writer to that target in this 200-case corpus.

Source-cell executed-opcode profiles of the 200 inputs:
- 60 cases never visit the dynamically written cell
- 5 cases execute `>` once
- 45 cases execute `v` then `>`
- 90 cases execute `v`, `v`, then `>`

Those 200 cases also execute 1,570 of the ten QA31AP fixed-vector
source `x` instructions (prior 1,710 `p` events include an
additional compound `p` per qualifying case). The QA31AQ audit
does NOT claim that every `x` instruction is exclusively caused by
the rewritten cell.

Independent reanalysis also confirmed 1,800 executed j(185,8)
source-control events in total: operand 0 in 700 events, 61 in 1,100
events. Original-source j(185,8) selects next-IP by its stack
operand. These are distinct physically observed mechanisms:
**ordinary computed jump and self-modifying source opcodes**.

## Source-grounded paired natural input comparisons

Eleven selected original raw-stdin pairs were re-read and compared
by signed STEP, source IP, vector, opcode, next-IP, stack and read record.
Examples:

- `pair_31_30` vs `pair_31_00`: first divergent IP transition
  at STEP 9,118, *same instruction* j(185,8). One operand 61
  advances to (247,8), the other operand 0 to (186,8).
- `pair_30_30` vs `pair_30_31`: first instruction/path difference
  at STEP 11,866, at (1500,1750): `>` versus `v`.
  The differing bytes had been written to that exact cell by
  p(1335,1354) at STEP 11,846.
- `pair_30_31` vs `pair_31_31`: first path difference at
  STEP 14,192 at that same mutable source cell, again `>` vs `v`.
- `pair_30_31` vs `pair_30_32`: source IP/opcode/next-IP path
  remains identical for the entire signed run, even though stack
  values differ from STEP 8,758.

The pairs demonstrate input-correlated route differences in these
**specific original inputs**. The source causal chain of the code
byte written by p(1335,1354) is the next research target; do not
assert that any arbitrary input will induce a particular route
without deriving it independently.

## Independently checkable delivery

Self-contained analysis ZIP saved in ChatGPT Library:
`/Befunge_QA_Artifacts/QA31AQ_BEFUNGE98_KYRGYZ_ORIGINAL_200_SELECTOR_MUTATION_20261107.zip`
Size 27,044 bytes, SHA256:
`1f5fd14d0a4cfb44f2be57bb3b8489690eee97632728d43645b3fc8cfc537aaf`
10 ZIP members, CRC 10/10 PASS and independently verified member
SHA256 9/9 from MANIFEST.json.

It contains two complete independent Python verification programs,
the original source-byte pin with frozen source Git blob,
200 original raw-stdin receipts and per-case physical source-write /
executed-byte / j gate / ten x-event ledger, 11 pairwise STEP split
audits, source and independent audit JSON, CSV, and full logs.
The 46 MB immutable input ZIP is referenced by exact SHA rather
than copied. The second verifier imports no forward logic; it replays
all 200 original gzip receipts and 3,628,390 original STEPs, independently
compares all 11 first path/stack/read divergence pairs, and rejects
20/20 synthetic corrupted report variants.

## Scope and acceptance

QA31AQ is ACCEPTED as finite original signed-200-code-change/
input-selector evidence only. It is NOT Stage1 functional/geometric/
global acceptance, NOT global control-flow or memory-writer ownership,
and NOT a new Native execution. No concrete new natural-input
candidate causing any `p` to write q=(1,49) or m=(3,49) has been
independently produced. All stronger reachability claims remain UNKNOWN.

NEXT QA31AR: bounded upstream original-source and signed-STEP
stack/backward operand provenance at p(1335,1354), especially where
ASCII 62 versus 118 is constructed from the input or from memory,
and how the j(185,8) gates interact with that construction. Seek
a concrete independently verified counter-address natural-input
candidate only if the derivation supports it; otherwise preserve
UNKNOWN and do not run Native. Any future Native case requires
an independently checked concrete original input and <=25,000 STEP.
No main/merge/Stage2.
