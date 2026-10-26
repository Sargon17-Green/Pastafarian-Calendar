# Native SystemVerilog lexical unrank — first 64 physical month ordinals

Stage 1 only. This is a NEW bounded test-only algorithm, not production RTL,
not a complete all-4244-symbol SV proof, and not a Stage 1 acceptance claim.

## Inputs and provenance
- 572,279,002-byte H(s,N) archive from the exact native SystemVerilog
  101,594-state computation in the same isolated CI job.
- 2,809-byte root produced by that native computation.
- Initial 2,809-byte one-based rank derived from the pinned bowl-4 base-2^127-1
  digit stream using Python **only for rank construction**. Its independently
  established minimal-BE SHA256 is
  `2c447438a567fbc40a79c68fb8b3f27f308cb89a2f59aaba1d2275dd3acf1a06`.
- No Python generated 4,244-byte word, per-step branch ledger, or Python H table
  is read by the SystemVerilog unrank.

## Independent native arithmetic
At every position, compute N=sum started-month remaining copies and:
`parent=A(r)*H_s(N)`.
For each started month i with remaining copies:
`old_i=A(r-e_i)*H_s(N-1)`, with exhausted-month zeros explicitly handled.
The rightmost new-label block is
`fresh=parent-sum(old_i)`. It is independently cross-checked against
`A(r,L_(s+1)-1)*H_(s+1)(N+L_(s+1)-1)`, not merely accepted by subtraction.
One-based rank selects exactly one block; its rank and remaining-copy state
are updated. Every iteration checks parent equality and sum bounds.
An intentional +1 mutation to the first old H forces
`NATIVE_LEX_FRESH_PARTITION_MISMATCH`; unexpected acceptance fails CI.

## Independent 64-byte golden
Exact reference arithmetic over the Foundation lengths separately computed
the first 64 month ordinals. SHA256 of their 64 raw ordinal bytes:
`c799e928b30deb45924e8aa9f11be013b5a5f205190788e01dc99508793447dc`.
The native bench writes these bytes itself and the runner checks this hash.
The source allows `+max_positions=4244` for future full-year verification,
with terminal rank=1 and zero-remnant checks, but no full-year PASS is
claimed until native CI actually exercises it.

## Status
Source written, isolated CI verdict PENDING. Time bound for 64-symbol
experiment is 240 seconds following the pre-existing H construction.
Full-year count generation, production five-field ASIC RTL and 0/64
Kalaallisut approvals remain separate Stage 1 blockers.
PR #20 remains Draft/DO NOT MERGE. No main or Stage 2 changes.

## Exhausted-month corner cases

The native bench now computes six self-contained 3-started-month A(r)
regressions before reading the H archive: a leading completed month,
an illegal interior completed month, an illegal trailing completed month,
only the last month active, all months exhausted, and all three active.
Expected exact factors are respectively 2, 0, 0, 1, 1, and 4. This
is a native arithmetic unit fixture, NOT a proof of all full-year
exhaustion transitions. New CI verdict is pending.
