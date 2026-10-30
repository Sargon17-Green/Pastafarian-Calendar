# Stage 37 — PATCH 18: cumulative negative gate correction

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Branch: Lua+Kreyòl-ayisyen
Gate: Stage36 DISCOVERY18 completed/success run 41117421971, 65/65 jobs, SHA 976e46b75336f5b66f3d3968b9e3038e657d80a6; job lua_stage36_discovery 124281873262.
Status: implementation committed; Native Stage37 CI NOT YET VERIFIED.

## Derived canonical contract

This is the already specified successor to Stage36 in STAGE36_NEGATIVE_GATE_CHAIN_CONTRACT_2026-10-30.md. Preserve the six Stage36 diagnostic commits, append a seventh production correction:
F=-15055671; gapNeg(i)=41+chooseRank(sauce(F,F-i),922), 42..963.
Legacy(-n)=F-gapNeg(n); Correct(-n)=F-sum(gapNeg(i),i=1..n).
n is an integer in 1..32; caller owns independent SAVE answer streams.
The repair subtracts the prior n-1 validated gaps from legacy, and checks an independently recomputed sum from F. No oracle calls in production, no postStir12, no general calendar date output, no mutation to the positive chain or Stage36 legacy code.

## Acceptance

1. Native Lua5.3 syntax, provenance and immutability locks.
2. Stage36 historical 1 MATCH + 31 EXPECTED_RED remains passing as historical scar; PATCH18 produces 1 MATCH + 31 exact canonical corrections with 7 commits and independent semantic state.
3. 96 synthetic chains, prefix sensitivity, BigInt replay, 7 malformed inputs, ownership isolation. The Stage37 test prints distinct counts; do not mark pass from a queued run.
4. GitHub Actions Stage37 job must finish completed/success with matching SHA, stdout, empty stderr, exit 0, and retained evidence. Stage35/36 chain remains green. Only then mark Stage37 complete and proceed within existing 55-stage plan.
5. No main merge and no postStir12 in Stage37.

Source evidence:
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41117421971
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41117421971/job/124281873262
