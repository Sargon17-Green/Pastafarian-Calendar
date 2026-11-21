# D21 Full-N arithmetic and bounded-walk audit — QA only

**Scope and authorization:** Companion to the accepted D21 near-M QA run, based on immutable QA commit `4e853ef6ed719988ba2caeb3478716c00d335904`. Separate QA branch `qa/logo-ido-d21-full-n-audit`. No production `choose.short` for unrestricted N has been implemented. No canonical `Logo+Ido` change, no Stage 2 acceptance or stage-number change.

## Exact contract

Appendix-A modulus **M = 2^127 - 1 = 170141183460469231731687303715884105727** is represented by the source's canonical base-10000 BI. Input: `1 <= N <= M`, canonical exact-BI `first in [1,M]`, and integer `step in {-1,+1}`. Define `q=floor(M/N)`, `r=M-qN`, `L=qN=M-r`; Euclidean identity must satisfy `M=qN+r` and `0<=r<N`. For each sample `x_k=1+EuclideanMod(first-1+step*k,M)`, accept exactly if `x_k<=L`, returning `[1+EuclideanMod(x_k-1,N), k]`. In this QA model only, inspect **k=0..31**, returning `[]` if no hit within that window; this is **not** proof that the unrestricted stream has no future hit.

## Independent oracle and adversarial domains

Fixtures use Python's arbitrary-precision integer arithmetic for independent `divmod` and a one-at-a-time, wrap-aware iterative stream oracle. The Python verifier parses and checks each fixed BI digit literal from the Logo test, and does not import Logo source, call its floor/mod or answer.at, or copy fixtures from other branches. Logo test model uses accepted D20 `answer.at`, `bi.divmod.floor`, `bi.floor.div`, and `bi.regmod`, and compares against independently checked expected quotient, remainder, acceptance index and rank.

N domain: one, two, three, seven, thirtyone, ninetyseven, base, half_floor, half_plus, third_floor, seventh_floor, near31, near1, modulus. This covers N=1, N=M, small nondivisors, quotient changes near M/2, large multi-digit N, and near-M boundaries. For each N, take unique valid starts from `1,L,L-1,L+1,M,L+31,L+32` and both step signs. Distinct within the valid domain are tested, including 31-step last-accepted and 32-step beyond-horizon candidates where feasible. Since M is the Mersenne prime 2^127-1, only 1 and M are positive divisors; both are explicitly included.

Fixture count: **130** cases, **115** expected within-horizon hits, **15** expected misses, **1010** Logo assertions: each hit checks 8 properties (q,r,reconstruction,remainder bounds, nonempty, rank, k, repeat determinism), each miss 6 (same arithmetic four, empty, repeat determinism). The Python host checker is another gate, not Native.

## Execution evidence required

Source lock Git blobs for `src/exact_integer.logo`, `src/stage02_answer_at.logo`, `src/stage02_choose_short_near.logo`, and `test/normative_reference.logo`, plus exact new fixture and Python verifier blob checks. Workflow pins headless UCBLogo 6.2.5 at `a0215433f07384e4c42fe247525867f11e6f32f7`, runner Ubuntu 24.04, per-program timeout 600 seconds, per-job 20 minutes. CI must independently show completed/success at the exact QA SHA, host verifier PASS and Native complete marker/counts in job log, and artifact for evidence. Queued/in_progress is not PASS; no duplicate dispatch.

**Acceptance separation:** independent host oracle != Logo static verification != Native execution != production full-N differential acceptance != canonical D21 promotion != full Stage 2 acceptance.

**NEXT after successful run:** inspect exact run/job/log/artifact and analyze any real counterexamples, then consider a separately authorized unrestricted-N production primitive; retain original D21 accepted QA SHA unchanged.
