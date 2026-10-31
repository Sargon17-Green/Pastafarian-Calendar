# Stage30 / Discovery15 — exact distribution of consecutive composite sampling

Branch: PowerShell+Tagalog. Predecessor sealed: Stage29 / Patch14 commit 1b1807bff7fb12ed4a5d1dd8a5f9ef0de0a7c34c.
Native seal CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41184025485 (completed/success, exact SHA, verify and Windows PowerShell 5.1). Stage29 has 568 passing assertions and two-run Stage23 finalizer idempotency.

## Scope and question
This is a research-only, independently checkable exact finite-distribution investigation. It does not alter the production implementation, normative oracle, or five canonical date outputs. It does NOT allege a newly reproduced implementation bug or claim statistical uniformity. Stage29 proved deterministic oracle compatibility only; the question here is how the output distributes under a precisely stated hypothetical First/Step law.

Let M = 2^127-1, N = M+1, First uniform in {1,...,M}, and Step independently be +1 or -1, with two stated experiments: fixed sign and balanced signs. The real date-derived law of First/Step is UNKNOWN; conclusions about it are expressly excluded.

The stream's second word is 1+((First-1+Step) mod M), the little-endian composite is W=First + M*(second-1), and the Patch14 acceptance threshold is L=floor(M^2/N)*N=M^2-1. Under this experiment no generated W equals M^2; the rejection path is not used for N=M+1.

## Exact analytic distribution
For Step=+1:
- First in 1..M-1 gives Rank=M+1; First=M gives Rank=M.
For Step=-1:
- First in 2..M gives Rank=2; First=1 gives Rank=3.
Thus each fixed-sign experiment has support only 2 of N=M+1 ranks. Total-variation distance from uniform N-rank sampling is 1-2/(M+1) for M>=5. This follows by summing half the absolute differences between output probabilities and 1/N.

For balanced signs, the four ranks 2,3,M,M+1 have counts M-1,1,1,M-1 among 2M equally likely (First,Step) states (M>=5); all remaining ranks have zero probability. Total variation is 1 - 2/(M+1) - 1/M (M>=5). The calculation is exact under the declared hypothetical input distribution, not a measurement of user dates or a claim of random-number quality.

## Independent, bounded execution contract
1. PowerShell 5.1 test enumerates a miniature M=7 model for N in {8,9,48,49}, both Step signs, seven First values each (56 states). Its oracle is a small iterative cyclic composite successor, structurally independent of Patch14's O(1) suffix jump and of NormativeScroll.
2. Verify every histogram sums to seven, valid ranks, and finite termination. At N=8, Step=+1 has rank8:6 and rank7:1; Step=-1 has rank2:6 and rank3:1. Balanced-sign histogram counts {2:6,3:1,7:1,8:6}, total variation =17/28 from uniform over ranks 1..8.
3. Include a rejection witness at M=7,N=9,Step=+1 (exactly one First requires moving the composite).
4. Execute actual Patch14 on real M for First in {1,2,M-1,M}, each Step sign, N=M+1 (8 analytic cases). Check rank, zero rejected composites, and preserved Stage29 metadata. No production modifications.
5. Wire this evidence-only test after already passing Stage29 regressions in the existing Windows native workflow. Record exact checkout SHA, assertion count, verdict and outputs. CI is accepted only after completed success on the final SHA, not a pending or earlier run. Do not repeat Stage29 tests outside the workflow.
6. No Stage30 expected-red designation without genuinely executed divergence, no modification to the canonical oracle, and no claim of real-world entropy. After CI evidence, update stage metadata and upstream regression gates through a separate scoped Stage30 evidence seal, then determine whether Stage31 should investigate date-derived empirical frequencies or entropy sourcing.

## Stage gates
Prior: Stage29 Runtime GREEN_CONFIRMED on exact seal SHA; Stage28 remains EVIDENCE_ONLY_CONFIRMED, Stage26 historical EXPECTED_RED=4 retained, all Stage01–29 regression gates unchanged.
This initial Stage30 research commit does not set LAST_COMPLETED_STAGE=30: it only adds the research contract, independent executable model, and Windows CI gate. Any PASS claim requires native test logs of this exact commit.

No main merge, no production patch, no protected ref move, no external publication.