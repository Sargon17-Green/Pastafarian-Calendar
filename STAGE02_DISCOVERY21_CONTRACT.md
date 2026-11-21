# Stage 2 / Discovery 21 — bounded near-M CHOOSE.SHORT (Logo+Ido)

Status: QA_IMPLEMENTED_NOT_NATIVE_ACCEPTED. Forked from canonical documentation-only HEAD `7ed2e187a1ac075a98917b6030aa490a164f63cc`. This QA work does not advance LAST_COMPLETED_STAGE=1, alter canonical `Logo+Ido`, change main, or merge.

## Frozen normative contract and input/output

The branch-local test-only Appendix-A `test/normative_reference.logo` specifies `nr.choose.short`: for `x_k=1+EuclideanMod(first-1+step*k,M)`, reject `x_k > L` where `L=floor(M/N)*N`, and at first acceptance return `1+EuclideanMod(x_k-1,N)`. D21 implements only a provable bounded subdomain, not unrestricted CHOOSE.SHORT. Next frozen primitives include smallest.power and choose.wide.

Reporter: `monster.stage02.choose.short.near :stream :N`. Valid `stream` is two entries `[firstValue step]`, with canonical exact BI firstValue in [1,M] and small integer step in {-1,+1}, identical to accepted D20. `N` is canonical exact BI in [M-31,M]. Frozen M is much greater than 62, so in this range floor(M/N)=1 and L=N. The normative accepted rank therefore equals `x_k` exactly; output the first `x_k <= N` as canonical BI, no floating point. All malformed/out-of-domain inputs return exact [] and leave globals untouched. Arbitrarily corrupted BI internal objects are outside the contract.

**Bound proof:** if firstValue is already <=N, k=0. Otherwise for step=-1 the first accepted k is firstValue-N <= M-N <=31; for step=+1 the first accepted k is M-firstValue+1 <= M-N <=31 (wrap to 1). Thus at most 32 values indexed k=0..31 suffice. There is no general or unbounded rejection sampling.

## Independent oracle and measurable QA gates

Production reuses D20's accepted `monster.stage02.answer.at` to index the stream. The test-only oracle does not call `nr.choose.short`, `nr.answer.at`, production D21, or D20 `answer.at`: it iteratively adds/subtracts one exact BI with explicit wrap, checking the first accepted value and index. This tests a distinct algorithm.

QA matrix TARGETS (not observed results): N in {M,M-1,M-31}; four canonical firstValues per N; both directions = 24 valid cases, each four assertions (BI shape, independent value, [1,N] range, deterministic repeat) = 96 checks. Two additional 31-step boundary-index assertions. Twelve invalid cases with one assertion each. **36 cases / 110 checks** total. Source-lock original D20 production, exact BI and normative-reference Git blobs, plus D21 source/test blobs. Headless UCBLogo 6.2.5 pinned to `a0215433f07384e4c42fe247525867f11e6f32f7`, Ubuntu 24.04, program timeout 600s, job timeout 20 min. The first-attempt QA run must emit all three exact lines `STAGE_2_DISCOVERY_21_CASES_PASIS 36`, `STAGE_2_DISCOVERY_21_CHECKS_PASIS 110`, `STAGE_2_DISCOVERY_21_PASIS`. A gated workflow may then emit `NATIVE_STAGE_2_DISCOVERY_21_QA=PASS`.

QA implementation, static checks, CI successful completion, Native differential, canonical acceptance and Stage2 acceptance are separate gates. Do not claim Native PASS before inspecting completed run/job/log/SHA/artifact, and do not mark canonical acceptance before separate verified same-SHA regression gates.

NEXT: inspect the natural first-attempt QA run and fix only actual failures; preserve canonical HEAD. Later evaluate the rest of Appendix-A N domain without assuming the bounded result covers it.
