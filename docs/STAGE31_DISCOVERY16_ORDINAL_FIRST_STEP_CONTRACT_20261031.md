# Stage31 / Discovery16: bounded ordinal-day First/Step inquiry

Branch: PowerShell+Tagalog. Research-only: no production changes, no Stage31 PASS.

## Proven predecessor
Stage30 exact-seal SHA 8d78359ae4a40f69bcd2054a4dcbcd44f7d528b6 passed completed/success in https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41193007152. Windows PowerShell 5.1 ran Stage01-29=568 assertions plus Stage30=96, altogether 664, and Stage23 finalizer idempotency twice with unchanged SHA256 C98CD8E4CEC1CD7D9CE09DB6C43E4F55CED89F7D9C316A3ED2B45C12545E0A51. Verify success. The Stage26 historical expected-red remains.

## Question
Measure actual First and Step emitted by the branch's public computation on explicitly enumerated integer day-ordinal inputs, and compare to the separately implemented normative oracle. Report sign counts, distinct First values, repeated joint states. Neither the actual ordinal inputs nor the resulting streams are assumed probabilistically independent or uniform.

Let F be the reference foundation ordinal Get-NormFoundationDay=-15055671. First input axis: CalculationDay=F, TargetDay=F+delta with 22 offsets:
-36525,-36524,-1461,-1460,-731,-730,-366,-365,-1,0,1,2,3,364,365,366,730,731,1460,1461,36524,36525.
Second axis: CalculationDay=F+1, TargetDay=F+delta for delta=-1,0,1.
For every pair probe seal 1 and 2. This produces 25*2=50 deterministic observations, NOT independent random trials. Nominal 365/366, 730/731, 1460/1461 and 36524/36525 offsets are day distances, NOT a verified Gregorian or Pastafarian year-boundary mapping.

## Executable acceptance
For each observation create exactly one real Invoke-CalendarDateSpaghetti context; extract First/Step with Get-Discovery13AnswerStreamFromContext (one Stage25 predecessor). Independently compute Invoke-NormSauce and Get-NormAnswerStream on the same input. Require both First and Step equal, 1<=First<=M, Step in {-1,+1}, 58 order-memory writes and 1 Patch12 invocation. Emit all sample rows and summary counts; include total=50 and sum positive+negative=50. Do not hardcode outcome frequencies.

The separate Stage31 test-only workflow runs on Windows PowerShell 5.1, checks exact checkout SHA, has 20-minute timeout and retains logs/metadata. A completed Native success proves only the finite observed sample with oracle agreement. It is not statistical evidence of global uniformity, not a confirmed historical bug, not a Stage31 seal or permission to merge.

Stage metadata stays CURRENT_STAGE=30 and LAST_COMPLETED_STAGE=30 during inquiry to preserve all sealed regression gates. NEXT: read completed/log on the new inquiry SHA; if failed, fix proved cause; if passed, record findings with counts as Stage31 research evidence and assess broader date-pair coverage before sealing. No production, main, or protected-ref modifications.
