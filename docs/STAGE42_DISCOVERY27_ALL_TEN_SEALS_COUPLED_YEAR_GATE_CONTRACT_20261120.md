# Stage42 / Discovery27 — all-ten-seal coupled year-gate preflight

PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG
Branch: `PowerShell+Tagalog`
Verified predecessor SHA: `e315af49ee7efb1ba62ac4560f3ea1640b544a2b`
Verified predecessor CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44633607543 (completed/success 15/15; Stage41 481/481 and seal PASS; Stage40 425/425 and seal PASS; canonical verify success; Stage23 twice-idempotent).
State at creation: research contract plus executable preflight; **Stage42 Native NOT RUN, Stage42 NOT ACTIVATED**.

## Motivation and independent specification

Stage38 tested ten seals under its own bounded contexts, whereas Stage41 tested coupled calculation-day / target-day year seams under only {1,5,10}. Full ten-seal coverage on the coupled seam grid is a new finite domain and a coverage gap, not a demonstrated bug. Do not import a fixture from another language branch.

Let f = Get-NormFoundationDay; derive year 5000 once using Get-NormYear5000(f), with o=OpenGateDay and c=CloseGateDay. For calculation and target separately use [o−1,o,c,c+1]. Use all seals [1,2,3,4,5,6,7,8,9,10] with QueriedBowlId=1. This yields 4×4×10=160 unique (calculation,target,seal) observations. Expected First and Step must come from Invoke-NormSauce(C,T) followed by Get-NormAnswerStream(normSauce,1,seal), independently of the production output. Observed First and Step come from Invoke-CalendarDateSpaghetti(C,T) followed by Get-Discovery13AnswerStreamFromContext(context,1,seal).

At each endpoint check exact First, exact Step, First domain [1,M], Step∈{-1,+1}, legacyOrderMemoryWriteCount=58, patch12InvocationCount=1: 160×6=960 assertions. Check the modular First displacement and Step-flip against normative values on 80 calculation seams and 80 target seams: 320 assertions. Compare the modular mixed second difference of First and the four-corner Step-product sign on 40 mixed faces: 80 assertions. For the 144 adjacent seal pairs compare normative-vs-actual First displacement and Step flip: 288 assertions. Structural gates = 9. **Total 9+960+320+80+288=1657 planned assertions**.

The oracle is separately implemented in the established normative path. These checks are deterministic and bounded; they do NOT prove universal correctness, date conversion, distributional uniformity, or an expected-red incident.

## Native gate

Run tests/Stage42.Tests.ps1 via a new exact-SHA GitHub-hosted Windows PowerShell 5.1 job with timeout 25 minutes. Require completed job success, 160 endpoints, 80 calculation seams, 80 target seams, 40 mixed faces, 144 seal pairs, 1657/1657 PASS, 0 failures, and retained SHA-bound transcript/metadata artifacts. Verify the other jobs, including predecessor stage seals, canonical verify and Stage23 finalizer. A queued or in_progress run is not PASS, and no duplicate CI dispatch is allowed. If failed, inspect the actual job log and repair only a reproduced issue.

Preserve src/, oracle/, main, historical expected-red, all previous stage metadata, and the current Stage41 completion state. Stage42 activation and sealing require separate post-preflight steps; this commit claims neither.
