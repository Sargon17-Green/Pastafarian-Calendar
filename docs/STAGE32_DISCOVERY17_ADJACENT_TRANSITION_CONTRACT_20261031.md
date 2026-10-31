# Stage32 / Discovery17 — adjacent target First/Step transitions

Branch PowerShell+Tagalog. Predecessor Stage31 research-only seal SHA 3dca5b59fb7edfaf7e32b16fce1754aa99a5fb01, completed Native and verify: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41207069942 .

## Research question
Stage31 measured 134 individual First/Step observations. Stage32 evaluates two-target transitions: for the same CalculationDay F, seal and bowl 1, compare TargetDay d versus d+1. A single-target measurement cannot establish the modular First delta or Step sign flip of the pair.

Use independent normative year 5000 Y=Get-NormYear5000(F) from NormativeScroll, where F=Get-NormFoundationDay and M=2^127-1. Eight base ordinals: OpenGateDay-1; OpenGateDay (cross year-entry); CloseGateDay-1; CloseGateDay (cross year-exit); F-1; F; F+1; F+36525. The latter is an ordinal distance, NOT a calendar-year or Gregorian claim. For each base test both seals 1 and 2 at d and d+1. Total exactly 16 directed pairs, 32 endpoint computations, including four gate-crossing pairs across both seals.

For each endpoint run real Invoke-CalendarDateSpaghetti and Get-Discovery13AnswerStreamFromContext, independently calculate Invoke-NormSauce/Get-NormAnswerStream from the separate oracle. Require First, Step equality, 1<=First<=M, Step in {-1,+1}, exactly 58 legacy order-memory writes and exactly one Patch12 call. For each pair independently compare normalized nonnegative delta=(First(d+1)-First(d)) mod M and boolean flip=(Step(d+1)!=Step(d)) to oracle-derived values. Report changes and repeats, not guessed distributions.

## Planned measurable checks
Four metadata checks (Stage31 current/completed, evidence-only and Stage26 expected-red); four normative year checks (number 5000, foundation in its half-open year, year length 252..5778, at least six gate indices); 16*(2*6+2)=224 direct/oracle tests; seven aggregate assertions (8 bases, 16 pairs, 32 endpoints, two count conservations, 4 boundary crossings, nonempty bounded distinct deltas). Total 239 expected assertions. Zero failures, exact checkout SHA, Windows PowerShell 5.1, 15-minute CI job, retained transcript and metadata. Production and normative oracle unchanged; historical Stage26 RED preserved.

This is research-only and not a presumed bug. Preserve CURRENT_STAGE=31/LAST_COMPLETED_STAGE=31 while Stage32 is unverified. Require completed Native and verify evidence before Stage32 seal, no claims of statistical uniformity, independence, civil conversion or five-output global correctness; no main merge.
