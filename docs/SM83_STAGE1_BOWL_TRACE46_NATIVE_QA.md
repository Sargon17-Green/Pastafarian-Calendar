# SM83 Stage1 — Native390 integrated 46-round bowl-trace candidate

PROJECT_ID: PC-BRANCH-SM83-ASSEMBLY-GEEZ  
Branch: SM83-Assembly+ግዕዝ  
Accepted prerequisite: Native389 on 7fb1b6dd7a78bceaab5c4d0748282f253bd9e1b1, CI45087053434, 21/21 completed/success and 21/21 checkout SHA logs; dedicated job137407967610 Host77, two ROM vectors, wrong-seed mutant rejection77/77, RGBDS v1.0.4/ROM_HEADER, ROM0 free218, real PyBoy A5/389/40 in 212 frames; default370 A5/370/40 in 8585 frames; regressions371–388 success.

## Proposed Native390 gate — NOT yet accepted

Input: signed32 Foundation-relative offsets c,t and valid active owner/ordinal lease. Normative source pinned README 56bc4173aae4975ded019ef5ab5a36249f1424df sections E–K and Issue #30. Reuses independently accepted Native386 V1–V46, Native387 order, Native388 one-step immutable-snapshot bowl update and Native389 initial six bowls.

Output: wCalendarVisibleOutput=V46, wCalendarStoneOld=S46, wCalendarBowlsOld[96] final six bowls **after 46 visible iterations, before post-stirs**, wCalendarBowlOrderAt46[6] final lexicographic order. On status 2 or 6, original published visible and bowls must be preserved, as well as owner, lease, offsets, and SRAM. Intermediate orderAt46 never published on failure.

For each i=1..46: compute V_i and S_i; rank order from V_i; derive all six new bowls from the old, immutable six, then promote six together. First six visible steps deliberately use the already accepted chained entry points V1..V6; subsequent V7..V46 use the accepted seven-slot ring recurrence. The repeated first-six work is an isolation tradeoff to avoid changes to existing accepted entry points; time and memory feasibility must be measured, not assumed.

Host: compare 72 independent c/t pairs with full normative arithmetic, 46 step outputs and orderAt46; assert signed32 extremes and reject in-place update mutation. Native: independent Foundation pre-post-stir 96-byte bowl vector and orderAt46, V46, negative-zero/idle invariants, SRAM/owner/lease and real PyBoy. RGBDS v1.0.4 link; ROM_HEADER; ROM0 free>=10; default Native370 <=9000 frames; Native390 <=30000 measured frames; old Native371..389 regressions on exact SHA, all jobs completed/success, all exact checkout logs, and a downloadable ROM/map/sym artifact.

The source addition and CI job are only a **candidate** until the natural push run completes. Neither six initial bowls nor full sauce Stage1 acceptance implies post-stirs or seals; next is 12 retained S_r post-stirs using S_r in both permutation and u with historical raw-sum mutant rejection, then A0 and direction for seals 10/11/12. No main/merge/Stage2/release.
