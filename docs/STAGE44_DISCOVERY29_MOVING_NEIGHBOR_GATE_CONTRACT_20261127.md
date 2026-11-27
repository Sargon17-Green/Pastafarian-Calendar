# Stage44 / Discovery29 — moving neighboring-year gate interaction
PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG
Branch: PowerShell+Tagalog
Authority: user explicitly approved opening and executing Stage44 on 2026-11-27, excluding main, merge and release.
Status: AUTHORIZED_PREFLIGHT / NOT_ACTIVATED / NOT_NATIVE_VERIFIED

Accepted predecessor: fafca7cf90f3a77eea27fcbaa0827b4fa2e4e686, run 46015468647, attempt 1, 17/17 jobs, Stage43 2215/2215, classifier 42/42. The Stage43 metadata blob 91f8dd0237903bc4db9131ba506bc398c92c3258 remains unchanged in this preflight.

## Question and scope
Stage43 held two calculation days fixed and swept adjacent targets near neighboring-year gates. Stage44 crosses calculation days at both seed year boundaries and recomputes the neighboring-year gates separately for each calculation day. It tests mixed target/calculation interaction in moving gate coordinates, not continuity, statistical uniformity or Gregorian mapping. The source only supports queried bowl 1; do not expand its domain.

Let F be Get-NormFoundationDay, Y=Get-NormYear5000(F), O=Y.OpenGateDay and C=Y.CloseGateDay. Calculation days are O-1,O,O+1,C-1,C,C+1, distinct. For every calculation day independently compute Year5000, its previous and next year. Target gate indices 0..3 represent previous open, previous close, current close, next close. For each gate take offsets -1,0,+1; seals 1..10. No numeric gate equality across calculation contexts is assumed. Use BigInteger throughout day/First/modular arithmetic.

For each of the 72 calculation/target coordinates obtain source Invoke-CalendarDateSpaghetti and independent same-branch oracle Invoke-NormSauce separately, once each. At each seal obtain source Get-Discovery13AnswerStreamFromContext and oracle Get-NormAnswerStream. Source stream function is read-only on the context. Assert First and Step equality, First in 1..M, Step +/-1, legacy write count 58 and Patch12 call count 1: 720 endpoints x 6 = 4320 assertions.

At each seed gate, take adjacent calculation pairs (-1,0) and (0,+1); for each gate index and each adjacent target offset pair (-1,0) and (0,+1) and seal, compare source versus oracle mixed differences. For a rectangle with corners 00,01,10,11, D=(F11-F10-F01+F00) mod M normalized nonnegative. For Step, compare parity of the number of negative steps across the four corners. These are oracle comparisons, not claims of vanishing differences. There are 2 x 2 x 4 x 2 x 10 = 320 rectangles, 640 assertions.

Structural guards: one for six distinct calculation days; 11 per calculation day (three year numbers, two gate seams, three positive year spans, four strictly increasing gates, twelve distinct targets, calculation within its recomputed Year5000). 67 guards. Total 5027 assertions, zero failures, 72 source and 72 independent oracle contexts. No expected-red or omitted samples.

## Acceptance
First run the dedicated hosted Windows PowerShell 5.1 preflight at exact checkout SHA with preserved Stage43 metadata. Retain metadata/transcript, fail for missing files, mismatched counters or any exception. The canonical workflow on the same SHA must independently pass all predecessors and finalizer. Check run attempt, exact SHA, jobs, actual log counters, artifacts and hashes. Preflight is not activation or acceptance. The current classifier accepts only Stage43 profiles; before metadata promotion, design a fail-closed Stage44 transition schema anchored to the exact accepted Stage43 map, update predecessor compatibility and prove negative cases without weakening frozen provenance. Separate pending, implementing-SHA Native, seal and exact-seal recheck. No production/oracle changes in preflight, no main/merge/release.
