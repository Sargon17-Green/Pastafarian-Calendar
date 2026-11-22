# SM83 Stage1 — Native388 candidate: six-bowl snapshot update

PROJECT_ID: PC-BRANCH-SM83-ASSEMBLY-GEEZ
Branch: SM83-Assembly+ግዕዝ
Accepted base: Native387, exact 3f9ed288902eacde895bedd88f21117c0dc68ce6,
CI 45069435082 (19/19 completed/success, all checkout SHA matches).
Normative source: main README 56bc4173aae4975ded019ef5ab5a36249f1424df, sections J–K, Issue #30.

## Executable contract
- Inputs to CalendarBowlUpdateStep: six distinct canonical 16-byte old bowls (ID order),
  six-ID permutation from the accepted Native387 rank primitive, canonical drop,
  five canonical stones, iteration 1..46, active owner/ordinal and lease.
- Outputs: six canonical 16-byte new bowls indexed by fixed identity.
- First 3 direct pours SAVE(D² + stone[q] * old(order[q]) + (2q+1)*i).
- Each of 6 results uses the *single old snapshot*: predecessor/successor in
  permutation order, direct pours only for q<=3, stone sequence 1,2,3,4,5,1,
  SAVE(u² + 5*old(prev)*old(next) + i*q).
- All output bytes are staged in a separate 96-byte scratch. After complete
  validation and computation, a single publish loop copies scratch to output.
  The six old bowls and source stone/drop/order remain unchanged.
- Status 0 success, 2 invalid and 6 idle. Invalid order (range/duplicates),
  residue zero/high bit, iteration outside 1..46 and negative zero reject
  without output changes. No SRAM or lease modifications.
- One invocation computes a full single-iteration step: **not** the complete
  46-iteration integrated native sauce, 12 post-stirs, answer A0 or direction.

## Independent evidence requirements
- New independent Python arithmetic vs existing separately implemented Host
  reference on 72 nonfixture cases, plus two complete 96-byte ROM postcondition
  vectors (small and M-1 boundary), with in-place mutant rejected.
- Isolated Native388 checks both 96-byte vectors via real PyBoy, also invalid,
  negative-zero, idle, owner/lease/SRAM and old-snapshot immutability.
- CI must report exact SHA and all prior 19 jobs + new Native388 job completed/
  success, with checkout SHA readback from every log. RGBDS v1.0.4 link,
  ROM_HEADER, actual ROM0 free>=10, accepted default Native370 A5/370/40
  <=9000 frames and Native388 A5/388/40 <=30000 frames.
- This document and a source commit are **CANDIDATES**, not proof of a build.
  Do not claim Native388 until the precise CI + log + PyBoy gates pass.

## NEXT after Native388 gate
Integrate step across i=1..46 with the previous six-bowl output promoted only
after six results are computed; initialize bowls from normative work counts and
six seeds; preserve orderAt46. Then 12 post-stirs with retained S_r in both
ordering and u; reject the raw-sum mutant. Finally compute A0 and direction
for seals 10/11/12. Each requires separate exact-SHA Native acceptance.
No main change, merge, protected branch update, release or Stage2.
