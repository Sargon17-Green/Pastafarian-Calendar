# Stage41 / Discovery26: coupled year-5000 calculation/target gate seams
PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG
Date: 2026-11-18
Predecessor: Stage40 exact-seal, run 44363584137, completed/success 14/14 on 9cc2392dc6f8c9f8a7aa9cd19fac6f93831e27c7.
Status: PREFLIGHT VERIFIED; STAGE41 ACTIVATED FOR EXACT-SHA NATIVE VERIFICATION; NATIVE RESULT PENDING.

Motivation: Stage40 varied calculation days across gate transitions with fixed foundation/distant targets. The distinct Stage41 hypothesis is whether simultaneous *calculation and target* gate transitions preserve independent normative agreement and mixed-axis finite differences. This is a bounded search for disagreement, not an assertion that one exists.

Inputs derive exclusively from oracle/NormativeScroll.ps1: foundation f, year-5000 open o, close c and positive modulus M. Require o<f<=c. Calculations C=[o-1,o,c,c+1], targets T=[o-1,o,c,c+1], legal seals S=[1,5,10], bowl ID 1. Use fresh production context for each (C,T,S) with Invoke-CalendarDateSpaghetti and Get-Discovery13AnswerStreamFromContext; compare against independent Invoke-NormSauce and Get-NormAnswerStream. No copied outputs or oracle logic from another branch.

**Exact acceptance contract**: 9 structural assertions; 48 labeled endpoints * 6 assertions (First/Step equality, First range, Step sign, legacy writes=58, Patch12 calls=1); 24 calculation-gate seam pairs * 2 oracle-based First-displacement/Step-flip assertions; 24 target-gate seam pairs * 2; 12 mixed C/T faces * 2 (modular First cross difference F11-F10-F01+F00, four-corner Step-sign parity); 32 adjacent seal pairs (1->5,5->10) * 2 = **481 assertions**. All expected values are computed from independent normative endpoint outputs. Zero failed assertions, 48 endpoints, 24+24 seams, 12 faces, 32 seal pairs required. Do not infer nonzero curvature, numerical randomness, statistical uniformity, or Gregorian mapping.

Native gate: Windows PowerShell 5.1, scoped 25-minute job, exact git SHA = GITHUB_SHA, canonical Stage40 seal still intact, retain transcript/metadata and DEVELOPMENT_STAGE.md as GitHub Actions artifact. This initial preflight changes only tests, contract documentation and CI; no src/oracle, stage metadata transition, main, merge or publication. Later Stage41 activation, if warranted by completed preflight evidence, requires a separate exact-SHA activation and seal recheck. Queued/in_progress is neither PASS nor a blocker.

## Completed research preflight — 2026-11-18

GitHub Actions run 44373929661 completed successfully with 15/15 jobs on exact commit 41c66f607ca4b994b3aa541813d169f58c0d2ead. The Windows PowerShell 5.1 Stage41 job 135047872168 used runtime 5.1.26100.33822 and recorded 481 assertions passed, 0 failed: 48 endpoints, 24 calculation seams, 24 target seams, 12 mixed faces, and 32 seal pairs.

The same run verified Stage40's 425/425 assertions and exact seal; Stage39, Stage38, Stage37, Stage36 and Stage35 seals; Stage28's 71/71 regression; canonical names verification; and Stage23 finalizer idempotency twice (exit code 0, stderr length 0, unchanged SHA-256 5BAF9C1A852011A0BB5815E59ECA749D22C92C169BA90388185D8475E3440792).

Retained Stage41 preflight artifact: ID 14461358631, SHA-256 `ab814732145f49eaa9e2f923990cf9a66625696a7c42f4ae11c758e0b79e9054`; ZIP CRC passed. It contains the exact-SHA metadata, original Windows PowerShell transcript, and DEVELOPMENT_STAGE.md. This is research-preflight evidence only; Stage41's Native activation SHA still requires completed CI and a separate evidence-only seal.
