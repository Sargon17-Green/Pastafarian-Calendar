# Stage29 / Patch14 — deterministic wide-rank compatibility (PowerShell+Tagalog)

## Proven entry gate (2026-10-31)
- Predecessor branch `PowerShell+Tagalog` at `202a238c68b5a701bb01989a49d9d8cdfe0dc3ae`; compared to live branch ref: identical (ahead=0, behind=0).
- Stage27 sealed on `096cbf17f15f439239616db54b457753cfd66bf7`; complete Windows PowerShell 5.1 verification: Stage01/23/24/25/26/27 395 assertions.
- Stage28 investigation run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41136580111, head_sha `202a238c68b5a701bb01989a49d9d8cdfe0dc3ae`, both Native Windows PowerShell 5.1 and verify jobs completed/success.
- The Stage28 native log proves `STAGE28_WIDE_CASES=24`, `STAGE28_LEGACY_GUARD_CASES=24`, `STAGE28_REJECTION_CASES=1`, `STAGE28_ASSERTIONS_PASSED=70`, `STAGE28_ASSERTIONS_FAILED=0`, `STAGE28_DISCOVERY_RESULT=EVIDENCE_ONLY`. Stage23 finalizer idempotency ran twice with exit 0 and identical SHA256. This establishes discovery evidence, NOT production patch or statistical uniformity.
- The existing `Get-Patch13AcceptedRank` throws when N>M, rather than returning a wrong rank. Never invent an observed historical numerical mismatch or infinite loop.

## Decision
Implement exact *deterministic compatibility* with the normative wide oracle for `M < N <= M^2`, where `M=2^127-1`. This is the minimal bounded expansion after Discovery14, not a redesign of entropy. Treat independently and explicitly the separate mathematical question of distributional uniformity. Do NOT claim that the date-derived consecutive stream produces unbiased ranks.

## Inputs and outputs
Pure `Get-Patch14WideAcceptedRank` inputs:
- `First`: BigInteger in [1,M], `Step`: integer in {-1,+1}, `N`: BigInteger in [M+1,M^2].
- Output record: `Rank` in [1,N], `Accepted` in [1,L], `RejectedCompositeWords` nonnegative BigInteger, `Limit=L`, `Composite=W`, `Space=S=M^2`.
- Illegal inputs throw; no overflow or floating point allowed.
- For `N<=M` retain Stage27's short implementation without changes. For `N>M^2` explicitly reject rather than silently extend untested p>2 handling.
- A real-context adapter must execute `Invoke-CalendarDateSpaghetti` exactly once, preserve existing 46-drop + 12-stir pipeline, derive `Get-Discovery13AnswerStreamFromContext` from its corrected predecessor once, and use the pure Patch14 function. The old modulo/historical Stage26 API remains unchanged, and is not incorrectly called with `N>M`. Preserve five canonical date components.

## Independent O(1) implementation contract
Let `x0=First` and `x1=1+((First-1+Step+M) mod M)`.
Compute the little-endian composite `W=1+(x0-1)+M*(x1-1)`, `S=M^2`, `L=floor(S/N)*N`.
- If `W<=L`, `Accepted=W` and `RejectedCompositeWords=0`.
- If `W>L` and `Step=-1`, `Accepted=L` and `RejectedCompositeWords=W-L`.
- If `W>L` and `Step=+1`, `Accepted=1` and `RejectedCompositeWords=S-W+1`.
- Return `Rank=1+((Accepted-1) mod N)`.

Derivation: rejected composites form a contiguous suffix `L+1,...,S`. Advancing the *entire* composite cyclically by ±1 reaches the stated boundary. This is an independent closed form of the normative oracle's iterative rejection, NOT code copied from that oracle. For N=S, L=S and zero rejected composites.

## Tests and acceptance gates
1. PowerShell 5.1 direct differential for 4 boundaries `N=M+1,M+2,M^2-1,M^2`, 3 first answers `1,M-1,M`, 2 directions: 24/24 equal to normative `Get-NormChooseRankWide`; verify result/range and rejection-count arithmetic separately. Must exercise at least one rejected suffix.
2. Boundary/invalid input: `N<=M`, `N>M^2`, First=0 or M+1, Step=0. All explicitly rejected by wide entry point.
3. Real predecessor at three date offsets (0,3,11) compared independently to normative sauce + answer stream + wide chooser; verify 58 writes and a single Patch12 invocation.
4. Stage27 short path unchanged; Stage26 historical expected-red=4 stays observable, Stage23 finalizer idempotency unchanged, 395 earlier Stage01/23/24/25/26/27 assertions pass, Stage28 70 evidence assertions remain valid.
5. Live CI must run Windows PowerShell 5.1 and canonical names lock on the *exact committed SHA*, with completed job status and assertion counters. No 'PASS' inferred from queued/in_progress.
6. To seal Stage28/enable Stage29: update old stage-specific metadata constraints in previous test suites and workflow **deliberately**, preserving prior stage seals; do not merely bump stage metadata and allow fallback branch. Until CI passes, `STAGE29_RUNTIME_VERIFICATION=AWAITING`, `LAST_COMPLETED_STAGE=28`; Stage28 retains `EVIDENCE_ONLY_CONFIRMED` separate from a patch's GREEN.
7. Stage29 native success only certifies *compatibility on this bounded domain*. A future research stage must separately assess real input-stream distribution and, if required by the canonical spec, independent entropy. No silent normative spec change.

## Change scope
Permitted: new Patch14 source and Stage29 tests, MonsterSkeleton dot-source wiring, necessary stage test metadata predicates, existing active Windows CI gate, DEVELOPMENT_STAGE.md and documentation. No main merge, no canonical five-component changes, no changes to the historical modulo scar, no production code copied from the normative oracle, no publication.

## At handoff
This document is an executable stage contract created after completed Stage28 evidence; it is NOT evidence of a Stage29 implementation, CI run, or Stage29 PASS. The NEXT engineering work is to implement and run the bounded patch and regression gates as specified, in a narrowly scoped branch commit, then inspect completed logs.
