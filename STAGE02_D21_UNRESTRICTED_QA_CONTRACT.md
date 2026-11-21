# D21 unrestricted-N CHOOSE.SHORT — QA candidate only

Authorization: User approved 2026-11-21 new unrestricted-N production candidate in a separate QA branch, independent tests and Native differential. No main/merge, no canonical Logo+Ido change, no Stage2 completion.

## Exact interface
Reporter: `monster.stage02.choose.short :stream :N`.
Stream is exactly `[firstValue step]`, where firstValue is canonical exact BI in [1,M], step is integer +1 or -1. N is canonical exact BI in [1,M]. Frozen `M=2^127-1` from in-branch Appendix A. For malformed inputs return exact empty list `[]`; no global mutation. Arbitrary corrupted internal BI objects are outside the contract.

Let `x_k=1+EuclideanMod(firstValue-1+step*k,M)`, `q=floor(M/N)`, `r=M-qN`, `L=M-r`. Accept the first `k>=0` where `x_k<=L`, returning canonical rank `1+EuclideanMod(x_k-1,N)` as exact BI (not the k index).

## Proof of constant-step selection
Because `0<=r<N`, rejected values form the contiguous suffix `(L,M]`. If the first sample is accepted, k=0 and compute its rank by BI modular division. Otherwise, with step +1, first accepted x=1 occurs after wrapping, `k=M-firstValue+1`, rank=1; with step -1, first accepted x=L occurs after `k=firstValue-L`, rank=N. In both rejected cases `1<=k<=r<N`, including gaps larger than native Logo's bounded k. No rejection iteration; all arithmetic remains exact BI.

## Test and evidence gates
New QA branch `qa/logo-ido-d21-unrestricted-choose-short` based on pre-existing audit SHA `9db8ecd7494975ca6ea6de50e0889e52140c6c33`. Only additive candidate source, independent Python-int host oracle/generator, frozen contract, source-locked QA Native workflow. Python oracle is independent of Logo and its BI implementation, uses iterative +1/-1 for up to 32 steps and modular projection with predecessor for huge rejection intervals. It also checks the closed-form against exhaustive independent walks for small moduli 2..48.

Target host matrix: 134 valid cases, 13 invalid, total 147, assertions 549. 15 long-gap cases with first acceptance after k=32; max tested gap 85070591730234615865843651857942052863. Every valid native case checks canonical shape, independently generated rank, output range, and repeat determinism. Each invalid case checks exact [].

Native CI must pin exact Git HEAD and source blob hashes, use headless UCBLogo 6.2.5 at a0215433f07384e4c42fe247525867f11e6f32f7, run generated native fixture with bounded timeout, verify exact case/check/PASS lines and failure absence, and retain host/native logs as artifact. Queued or running is not PASS. Successful QA only does not imply canonical or Stage2 acceptance. No duplicate reruns; no user-machine execution required if GitHub CI succeeds.

NEXT after commit: inspect natural first-attempt exact-SHA run/job/log/artifact, diagnose real failures only, validate regression-source locks. Do not promote to canonical without separate authorization.
