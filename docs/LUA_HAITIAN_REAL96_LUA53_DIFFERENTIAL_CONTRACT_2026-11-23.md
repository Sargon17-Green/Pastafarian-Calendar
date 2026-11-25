# Lua Haitian real96 frozen rank differential — QA-only gate

PROJECT_ID: `PC-BRANCH-LUA-HAITIAN`
Branch: `Lua+Kreyòl-ayisyen`
Date: 2026-11-23
Frozen predecessor: `7bac3d896c332976cde5e97f6527b84084ce95b2`
Existing real-count source blob: `df7a6d31714d111a93aced5ccb74a55c09fd78b1`
Frozen independent Python fixture blob: `96cdc8a766220b05bea2f34b5977aedd821b1985`

## Purpose and boundary

This is **not** Stage56, production composition, normative weaving, fullDate, merge, main or release. The accepted Lua5.3 *count-only* run (45087322675, job 137408816059, artifact 14781275883) attested the real 47-month, 5294-day vector: the 8654-digit total hashes to `e3d498d39d6b4dfc401a85b8d9135ff1089a81ace85565ac5dcb123870c09f34`. Full canonical run 45087322675 is `completed/failure` because a **different**, old, expensive real-year interval discovery ran out of CPU. Never rerun that job without new evidence.

The independent Python oracle and three locked witnesses were already frozen before the Lua implementation, in commit `9f38a405095ff87bf8e340a95ee37a7ace3e8136`. Do not regenerate this JSON as a way of passing the test.

## Contract

**Input:** `test/lua_haitian_real96_prefix_differential_qa.lua` receives `real` and an output TSV path. The exact attested 47-multiplicity vector is source-locked by its CSV SHA-256 `9c623663a0d48455634df29749e1034a322a412a1898d7b24a77c2e29d708154`. Prefix length is 96; ranks are one-based `FIRST=1`, `MIDDLE=floor((N+1)/2)`, `LAST=N`.

**Output:** Exactly three TSV lines in that order, each with tag, comma-separated 96 zero-based labels, positive decimal residual rank, positive decimal suffix count. Lua also emits small exhaustive/guard and resource receipt markers; no production API.

**Mechanism:** Pure Lua5.3 base-10^7 limb arithmetic. Exact recurrence: `T(a,q) = T(a,q-1) + C(q+n[a]-2, n[a]-2) * T(a+1,q+n[a]-1)`; prefix remaining count equals a multinomial factor for already-open, non-exhausted labels times `T(opened,remaining-open-labels)`. The general rank chooser verifies the sum of all disjoint candidate branch cardinalities equals the remaining suffix cardinality; extreme ranks use direct smallest/largest nonzero candidate traversal, reducing unnecessary candidate evaluations. All limbs and intermediate products remain below double's exact-integer threshold.

**Independent comparison:** `test/lua_haitian_real96_differential_verify.py` compares exact ASCII prefix CSV bytes, 96-label bounds, all SHA-256 digests/lengths and residual edges against the pre-frozen Python fixture. It rejects noncanonical decimal strings and overlarge transcripts. Four mutated transcripts must be rejected. Six small domains are exhaustively enumerated with a distinct full-word permutation oracle: `(2,2), (3,2), (2,2,2), (2,3,2), (3,3), (2,2,2,2)`. The Lua module must reject rank 0, rank N+1, an overlength prefix, and four malformed vectors.

**Limits:** 47 labels, at most 6000 days, exactly 96 real prefix positions, at most 15,000 candidate branch evaluations per witness, total execution up to 600s wall/570s CPU/786432 KiB virtual memory in the focused workflow. Truncation, timeout, nonzero exit, nonempty stderr, fixture/source mismatch or failing comparison are **FAIL**, never expected-red/PASS.

**CI:** Reusable single `workflow_call` `.github/workflows/lua-haitian-real96-prefix-differential.yml` has SHA-locked source and fixture blobs, Lua5.3 syntax check, actual source HEAD, bounded execution, independent verifier, stdout/stderr/exit and resource checks, and raw ZIP artifact containing manifest, exact TSV, receipt and SHA256SUMS. The workflow is not evidence until an actual exact-SHA run/job/log/artifact is inspected. This QA gate does not bless a complete stage.

## Evidence and disposition

Commits with `[skip ci]` for isolation: initial code `dfe42635c73f5d98ceb00857e4ef2a0fd021a431`; optimized source `c6821e55cd467396aede74a8f9e6795c317c75af`, blob `3de016cedd67bfacd5c1bcb1678f2c694e575e2a`; verifier `2b8cd9b5f483dea1e6a43798901c6e00b8edad02`, blob `54efb6ee61f1fe0b2987b8255fad17134db98aba`; reusable workflow `d2eb2c751977cfdbc2dbcff0ae74a8002e908f81`.

Local LuaTeX (Lua 5.3 compatible) six exhaustive small domains / 41 exact ranks / 18 rank rejects / 4 malformed vectors PASS. FIRST and MIDDLE real prefixes and residual/suffix hashes matched frozen Python fixture in local evaluation; LAST and automated all-3 comparison pending at contract authoring, so **no real96 complete PASS claim**. No new GitHub Native/CI run claimed.

NEXT: Finish resource-bounded real96 local differential and verify all three; ensure canonical single workflow_call wiring; only then judge exact-SHA focused Native run by job logs and artifact SHA/CRC/manifest. Normative weaving/fullDate remain NOT_RUN.

## 2026-11-23 extreme-rank branch pruning (QA-only, source-lock revision)

The original extreme-LAST loop recomputed exact suffix cardinalities for every structurally legal next label. This is unnecessary: after any legal transition, append the remaining copies of already-open labels in increasing label order, then the still-unopened labels in order. This constructs at least one completion obeying increasing first and last occurrences, hence every structurally legal candidate has positive suffix cardinality. FIRST can choose the first legal label and LAST the last legal label; compute only the chosen branch's suffix count to update the one-based residual rank. A zero-cardinality assertion guards the constructive invariant. The non-extreme MIDDLE rank still checks the complete disjoint partition of all candidates.

Independent exhaustive model check (JavaScript, separate from Lua source): six tiny multiset domains `(2,2), (3,2), (2,2,2), (2,3,2), (3,3), (2,2,2,2)`; 141 unique reachable nonterminal prefixes, 176 structurally legal next transitions, 0 without a valid complete word. This is *static independent model evidence*, not a Lua5.3 run, CI pass, Native pass or complete three-witness differential. The focused workflow's source-blob lock was updated in the same commit; no canonical run was dispatched, and the unrelated CPU-aborted historical experiment was not repeated. Pending NEXT remains exact-SHA stock Lua5.3 focused job, full transcript, verifier and artifact integrity review.

## 2026-11-25 bounded Windows evidence and exact active-branch ratios

Windows v003 HANDOFF run 20261125T170142Z_fc88dfba SHA256 b257368059ec42b80490005ee0f0a8116936c7be50a92f2c7cbc654068b880ca: ZIP CRC 25/25, manifest 24/24, exact old HEAD 75634dc1e6df6983b1ed3b24bbfdd82b4c14ddba. Stock Lua5.3 small suite 41/41, 18 rank rejects, 4 vector rejects; FIRST exact frozen prefix/residual/suffix hash matched (8477 digits). WALL_CAP 600.11s, CPU 513.984375s, job commit 367544 KiB, exit 124. MIDDLE/LAST and full verifier not reached; Linux RLIMIT_AS not tested. Job accounting reported TotalProcesses=2 despite ActiveProcessLimit=1; unexplained, do not relax process-count acceptance.

QA-only optimization: define S_i as cumulative remaining multiplicities of active labels through i. Decrementing active label j changes its binomial factor by (r_j-1)/(S_j-1) and later factors by (S_i-r_i)/(S_i-1). The first active label closing at r_j=1 has S_j=1 and factor 1 disappears. The common suffix-row factor is T(opened,q-1). Each individual ratio is exact after multiplication because its old factor is present. Traverse active labels backwards to share transformed later factors. Opening a new label retains direct suffix computation; middle rank still sums every legal branch and compares against current cardinality. No change to DP recurrence, BigInt base, fixture, verifier, count source, caps or extreme-rank algorithm.

Local LuaTeX-compatible Lua selftest: 122 active-ratio vs direct cardinality checks and all 41 original exhaustive ranks, 18 rank rejects, 4 malformed vectors. Synthetic 47-label vector lengths 8..12 repeating, total 467, 96 prefixes: old and new all three TSV witnesses byte-identical; measured 1.60s vs 0.52s wall on same environment (one run each, not production timing). Actual 5294-day optimized run NOT_RUN. New source marker ACTIVE_RATIO_DIRECT=PASS checks=122; CI exact lock updated and Python isolated invocation. No Stage56, main, merge, production composition or fullDate. No canonical dispatch; [skip ci] avoids unrelated legacy rerun. NEXT exact new source Native bounded test, same frozen oracle and all four mutations.
