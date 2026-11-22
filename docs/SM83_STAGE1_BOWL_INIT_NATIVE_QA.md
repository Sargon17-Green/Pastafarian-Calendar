# SM83 Stage1 — Native389 six-bowl initializer CANDIDATE

PROJECT_ID: PC-BRANCH-SM83-ASSEMBLY-GEEZ
Branch: SM83-Assembly+ግዕዝ
Accepted prerequisite: Native388 exact cc19281361343d16a49f5179d7a7e2fb54ee9df8, CI45076967603 20/20 completed/success and checkout SHA matching all logs. Dedicated job137376252270: Host72 vectors2 mutant72; RGBDS 1.0.4, ROM_HEADER PASS, ROM0 free218, real PyBoy A5/388/40 frames367. Default Native370 A5/370/40 frames8585. Normative source: pinned main README 56bc4173aae4975ded019ef5ab5a36249f1424df sections J-K and Issue#30.

## Bounded contract

Input: wPairCalcOffset and wPairTargetOffset, signed32 Foundation-relative offsets, active valid ordinal with lease.
Work counts A,B,C,D,E: use accepted WorkCountsFromOffsets32.
For each fixed identity j in 1..6, seeds = 17,19,23,29,31,37, compute B_j = SAVE((A+j*B+C+D+E+seed_j^2)^2+j), M=2^127-1.
Output: six canonical 16-byte LE residues by fixed bowl ID in wCalendarBowlsOld[96]. Scratch wCalendarBowlNewScratch[96] is shared with the accepted step; publication occurs only after all six computed.
Invalid status2, idle status6: no public output changes; preserve caller offsets, ordinal, lease and SRAM.
Independent Host oracle: 77 day-offset pairs including signed32 extremes, two full ROM vectors, wrong-seed mutant rejection, structural guard.
Native acceptance ONLY after exact new SHA 21/21 completed/success, all checkout logs matching; Host output; RGBDS v1.0.4 link, ROM_HEADER PASS, actual ROM0 free>=10; real PyBoy A5/389/40 <=30000 frames; standard Native370 <=9000 frames; regressions 371..388.
Source or static testing alone does NOT qualify as Native PASS.

## NEXT after this milestone

Integrate initial bowls with previously accepted 46 drops/stone transitions. For every i=1..46, derive order from that drop using Native387, execute Native388 using the frozen old bowls, promote Next to Old only after all six outputs complete. Retain orderAt46. Use 72-pair full-trace independent oracle and isolated Native test. Then add 12 post-stirs with retained S_r in BOTH order and u, rejecting historical raw-sum mutant, then A0/direction for seals10/11/12. No main/merge/Stage2/release.
