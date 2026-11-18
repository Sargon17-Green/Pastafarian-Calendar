# Stage41 / Discovery26: coupled year-5000 calculation/target gate seams
PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG
Date: 2026-11-18
Predecessor: Stage40 exact-seal, run 44363584137, completed/success 14/14 on 9cc2392dc6f8c9f8a7aa9cd19fac6f93831e27c7.
Status: RESEARCH PREFLIGHT ONLY; NOT ACTIVATED; NOT NATIVE VERIFIED.

Motivation: Stage40 varied calculation days across gate transitions with fixed foundation/distant targets. The distinct Stage41 hypothesis is whether simultaneous *calculation and target* gate transitions preserve independent normative agreement and mixed-axis finite differences. This is a bounded search for disagreement, not an assertion that one exists.

Inputs derive exclusively from oracle/NormativeScroll.ps1: foundation f, year-5000 open o, close c and positive modulus M. Require o<f<=c. Calculations C=[o-1,o,c,c+1], targets T=[o-1,o,c,c+1], legal seals S=[1,5,10], bowl ID 1. Use fresh production context for each (C,T,S) with Invoke-CalendarDateSpaghetti and Get-Discovery13AnswerStreamFromContext; compare against independent Invoke-NormSauce and Get-NormAnswerStream. No copied outputs or oracle logic from another branch.

**Exact acceptance contract**: 9 structural assertions; 48 labeled endpoints * 6 assertions (First/Step equality, First range, Step sign, legacy writes=58, Patch12 calls=1); 24 calculation-gate seam pairs * 2 oracle-based First-displacement/Step-flip assertions; 24 target-gate seam pairs * 2; 12 mixed C/T faces * 2 (modular First cross difference F11-F10-F01+F00, four-corner Step-sign parity); 32 adjacent seal pairs (1->5,5->10) * 2 = **481 assertions**. All expected values are computed from independent normative endpoint outputs. Zero failed assertions, 48 endpoints, 24+24 seams, 12 faces, 32 seal pairs required. Do not infer nonzero curvature, numerical randomness, statistical uniformity, or Gregorian mapping.

Native gate: Windows PowerShell 5.1, scoped 25-minute job, exact git SHA = GITHUB_SHA, canonical Stage40 seal still intact, retain transcript/metadata and DEVELOPMENT_STAGE.md as GitHub Actions artifact. This initial preflight changes only tests, contract documentation and CI; no src/oracle, stage metadata transition, main, merge or publication. Later Stage41 activation, if warranted by completed preflight evidence, requires a separate exact-SHA activation and seal recheck. Queued/in_progress is neither PASS nor a blocker.
