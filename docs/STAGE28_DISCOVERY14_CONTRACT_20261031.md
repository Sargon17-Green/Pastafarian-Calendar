# Stage28 / Discovery14 — Wide answer-space sampling investigation

Branch: `PowerShell+Tagalog`. Predecessor HEAD: `096cbf17f15f439239616db54b457753cfd66bf7`. Stage27/Patch13 sealed by completed Windows PowerShell 5.1 + verify run 41117521423 (395 assertions). This document opens research only: NO production patch, NO Stage28 acceptance, NO main merge.

## Verified source facts and definitions

Let `M = 2^127 - 1` (`src/Discovery01.ps1`, `oracle/NormativeCore.ps1`), and investigate `M < N <= M^2`. The minimal `p` with `M^p >= N` is `p=2` throughout this range. `Get-NormAnswerAt(stream,k) = 1 + mod(First-1 + Step*k, M)`, with `Step` exactly +1 or -1. Source: `oracle/NormativeCore.ps1` lines 294-325; producer: `src/Discovery13.ps1`.

The existing normative wide oracle is **little-endian**: first stream answer contributes the least significant base-M digit. For `x0=AnswerAt(0)` and `x1=AnswerAt(1)`,
`R=(x0-1)+M*(x1-1)`, `W=1+R` in `[1,M^2]`.
With `S=M^2`, `L=floor(S/N)*N`:
- If `W<=L`, accept.
- If `W>L`, the CURRENT oracle advances **the entire composite W** by `Step` cyclically in `[1,S]`, rather than assembling a fresh pair of stream answers. The first accepted `A` gives `Rank=1+((A-1) mod N)`.
- Stage27 `Get-Patch13AcceptedRank` rejects `N>M` explicitly. It does not hang; claiming an observed infinite loop would be false. A hypothetical unguarded short-only limit `floor(M/N)*N=0` would never accept, but that is a mathematical observation, not an observed production fault.

## Bounded independent acceptance oracle

For `W>L` and `Step=-1`, closed-form `A=L`, `skipped=W-L`.
For `W>L` and `Step=+1`, closed-form `A=1`, `skipped=S-W+1`.
Otherwise `A=W`, `skipped=0`. This is independent of the normative oracle's iterative loop and is O(1). It is valid because rejected values form the contiguous suffix `(L,S]`. Test both steps, first answers `1,M-1,M`, and boundaries `N=M+1, M+2, M^2-1, M^2`. For N<=M retain Stage27 sealed behavior, unchanged.

## Distinct statistical-uniformity question — IMPORTANT

Modulo rejection yields uniform ranks **only if W is uniform over [1,S]**, which holds for independent uniform digits, not for the actual consecutive `x0,x1` of a deterministic ±1 stream. Do not assert end-to-end unbiased sampling merely from oracle agreement.

Proof of a counterexample under the explicit experiment `First ~ Uniform(1..M)`, `Step=+1`, `N=M+1`:
- For `1<=f<M`: `x0=f, x1=f+1`, hence `W=f*(M+1)` and `Rank=M+1`.
- For `f=M`: `x1=1`, `W=M`, `Rank=M`.
Thus `Pr(Rank=M+1)=(M-1)/M`, `Pr(Rank=M)=1/M`, all other ranks zero. These results concern a defined distribution over First; the real date-derived distribution has NOT been measured.
- Toy `M=7,N=8`: exhaustive independent uniform digit pairs give 48 accepted states, 6 of each rank 1..8, and one rejected state. Consecutive +1 words with First uniform give rank 8 six times and rank 7 once.

## Discovery acceptance / evidence plan

1. Confirm actual source order and full predecessor (already read at predecessor SHA); preserve 46+12 writes, Patch11 latch, Patch12 positional successor, Stage26 modulo scar, Stage27 short behavior, and five canonical date components.
2. Add a source-executed Stage28 Windows PowerShell 5.1 test with independent closed-form boundary checks against normative wide oracle; verify the existing short path throws for N>M; separate toy exhaustive statistical counterexample. Log counts and runtime SHA.
3. Do not label the absent wide implementation a numerical mismatch: it is an out-of-domain exception. Only assign a historical EXPECTED_RED outcome to a specifically defined and genuinely executed divergence. Current discovery is not sealed.
4. CI is valid only on exact committed SHA with completed logs, plus preserved regression status. A queued/in_progress run is neither PASS nor blockage. No rerun of successful Stage27 CI on predecessor SHA.
5. Next engineering question after evidence: whether to implement the prescribed deterministic wide oracle as a compatibility behavior (without statistical-uniformity claim) and/or supply a distinct demonstrably uniform entropy source. Do not silently rewrite the normative definition.

## Bounded test matrix

24 real-M combinations: four N boundaries, three First values, two directions; verify normative result against independent closed-form result and prove Stage27 guard throws. At least one wide rejection path. Toy M=7: 49 independent pairs, one rejected, eight ranks each with count six; seven consecutive-stream outcomes 6:1 for ranks 8:7. These are model checks until native completed/log is available.

Status: DISCOVERY14 evidence collection, not PATCH14, not Native PASS. Stage27 metadata remains sealed; new metadata requires an intentional compatibility update of all prior-stage regression gates in a separate change.
