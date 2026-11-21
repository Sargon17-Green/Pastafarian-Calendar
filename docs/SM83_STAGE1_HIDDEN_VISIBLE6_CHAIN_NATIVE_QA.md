# Stage1 visible V6 / Native385 candidate
PROJECT_ID: PC-BRANCH-SM83-ASSEMBLY-GEEZ
Branch: SM83-Assembly+ግዕዝ
Historical V5 candidate (later found to use a non-normative predecessor): fa7b9a71bec4a48802f4131d642a5ad566ce7ede; historical CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44928353872
Authority: https://github.com/Sargon17-Green/Pastafarian-Calendar/issues/30

Input: signed32 c,t, owner/ordinal lease, canonical i5 five-stone state. Output: 16-byte
canonical V6. Simultaneous i6 stone update from frozen i5 snapshot, then visible
recurrence using V5, V3, H2 and work counts. Retain H1..H7 and V1..V5.
Independent Host oracle: 72 pairs including signed32 endpoints and snapshot-alias
mutant; fixtures are postconditions ONLY. Foundation V6 LE a12ecba0457ce72b055951075fb7c811.
Status invalid negative zero 2; idle 6; no early rejected output write.

Acceptance: candidate exact SHA checkout in all 17 jobs, all completed/success;
RGBDS v1.0.4 linked, ROM_HEADER PASS, ROM0 free>=10 measured, real PyBoy
A5/385/40 <=30000 frames; default 370 <=9000 frames and 371..384
regressions; lease, offset, source and SRAM checks.
No Native385 claim until logs verified, no Stage1 acceptance.
NEXT V7..V46, then six simultaneous bowls, 12 retained S_r in ordering and u,
A0 and direction. No main/merge/release/Stage2.

## V6 Host regression and fixture repair (2026-11-21)
Run https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44937725796
at 47cfbfc418321088e532d7160238845b15fbaaae: 16/17 jobs succeeded;
dmg-chain6-native job 136947930181 failed in the independent Host fixture
check `visibleExpected` before RGBDS/PyBoy. The benchmark's i6 wheat stone
had LE first byte `$2b`, corresponding to a stale `+5` iteration constant;
for simultaneous i6 from frozen i5, `p*p+3*q+6` yields `$2c`.
Independent modular recurrence with all 11 rounds gives V6 for c=t=0 as
LE `c687bddfe01bf33d8967966fdfec717d`. At that point only the two stale benchmark fixtures were corrected; production recurrence was unchanged. This historical conclusion is superseded by the normative predecessor audit below. Host now checks
five post-transition stones before the V6 output, to localize a regression.
This patch is NOT Native385 acceptance. Require a new completed exact-SHA
17/17 run, all job checkout SHA logs, link/ROM and real PyBoy gates.


## Normative predecessor audit (2026-11-22)

The pinned normative README at `56bc4173aae4975ded019ef5ab5a36249f1424df`, section E, places hidden drop 1 at position 0 and hidden drop 7 at position -6, then defines the third predecessor as `drop[i-7]`. Therefore V5 (`i=5`) must use H3 at position -2, and V6 (`i=6`) must use H2 at position -1. The earlier stage-specific V5/V6 chains and their independent Host oracles incorrectly used H5/H6. Their Native384/385 successes were internally consistent with those local fixtures but did not establish conformance to the pinned recurrence. The full sauce oracle already used the normative positional mapping; it previously exposed only V1 and V46, so it did not detect the intermediate mismatch. This repair changes the V5/V6 predecessor wiring and expected postconditions, exposes the full 46-value visible trace, and cross-checks V5/V6 Host results against that independent oracle. The completed 17/17 run 44947038746 on the old SHA is retained as historical evidence only; Native384 and Native385 must be revalidated on the repaired exact SHA. No Stage1 acceptance is implied by this audit.
