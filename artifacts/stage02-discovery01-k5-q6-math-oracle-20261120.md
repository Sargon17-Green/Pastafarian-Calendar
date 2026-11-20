# Stage02 DISCOVERY01 — k5 q6 arithmetic-only CI contract (2026-11-20)

PROJECT_ID: PC-BRANCH-WAT-SPANISH. Branch: `WAT+Español`.
Parent verified before creation: `65e42bf143fec4cd6de59a4c0c6a995a139ebe53`.
Native module `tests/normative_selector.wat` and Native runner unchanged.

## Scope and independent mathematics
Five consecutive ring responses with radix `B`, initial response `B-7` (+1) or `B-3` (-1), form
`S=B^5; x=1+sum((a_j-1)*B^j, j=0..4)`.
Independent closed forms: forward `D=3B^4+4B^3+5B^2+6B+7`, backward `D=7B^4+6B^3+5B^2+4B+3`; `x=S-D`.
For `B≡1 (mod 6)`, `x` is divisible by six. Set `N=x/6-δ` for `δ=0,1`. **Do not assume** `q=floor(S/N)=6` in the small model. Compute `q` and `L=qN` exactly. If `x<=L`, accept `x`; otherwise, +1 advances/wraps to 1, while -1 advances to `L`. Rank is `1+(accepted-1)%N`.

## Bounded gate and asserted outputs
- Small ring-walk model: `B=13,19,25`, both steps and both δ; exactly 12 stepwise cases; cumulative **1,237,658** rejection transitions; per-case hard cap 1,250,000 iterations. Some small `q>6` and some `N<=B^4`: deliberately **not** counted as normative k5/q6 witnesses.
- Medium algebra-only: `B=55,61,67,73`, both steps and both δ; 16 cases, all asserting `B^4<N<B^5` and `q=6`, independent polynomial/digit equality, exact limit, and rank. No large ring-walking.
- Production modulus: `B=2^127-1`, +1/-1 and δ=0/1, exactly four exact BigInt algebraic cases with `q=6`; astronomical ring-walking forbidden. δ=1 forward wraps after `D+1` mathematical rejections; δ=1 reverse accepts `L` after six.
- Fail on any mismatch, invalid domain, wrong totals, or excessive small-loop iterations. Output includes `native=NOT_EXECUTED_BY_THIS_ORACLE`.

Test command: `node tests/stage02_k5_q6_boundary_oracle.cjs`.
CI: add the command to the existing `wat-stage02-semantic` job; preserve its 95 Native and 67 independent memory checks unchanged. Local math preflight before commit: 12/12, 16/16, 4/4, 0 errors. This checked-in oracle is a new independently reconstructed implementation: its bytes are **not claimed identical** to the earlier uncommitted script with SHA256 `d0cd80af92309898dac6e38fbfab9d0969cb91f2fdf1db9c5abea3055947e17d`.

## Acceptance boundary
Local arithmetic checks do not establish CI acceptance; verify completed push run, checkout SHA, each job log, and q6 printed result. Even full CI success accepts only this q6 arithmetic increment, **not** any q6 Native probes, historical Stage02 ZIP equivalence, EXPECTED_RED, or global Stage02 completion.
Next after CI success: independently design four explicit WAT Native k5/q6 cases with exact memory-field expectations, keeping selectors untouched.
