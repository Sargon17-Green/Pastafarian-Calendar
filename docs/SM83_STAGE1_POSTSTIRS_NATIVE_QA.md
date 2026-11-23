# SM83 Stage1 — 12 retained post-stirs, Native391 candidate

PROJECT_ID: PC-BRANCH-SM83-ASSEMBLY-GEEZ
Branch: SM83-Assembly+ግዕዝ
Predecessor: Native390 exact bc47250fbe6e7f45a000b63a2da6b08bcbf936f4, CI45134370586 22/22 completed/success; 22 checkout SHA logs, dedicated Host72 with 46 rounds and 72/72 in-place-mutant rejection, RGBDS v1.0.4, ROM_HEADER PASS, isolated ROM0 16166 used/218 free; real PyBoy A5/390/40 20977 frames; default370 A5/370/40 8585 frames; artifact14800242884 includes ROM/map/sym. Accept ONLY 46-bowl trace and orderAt46, not full Stage1.

## Contract (source: Issue #30 / pinned main README 56bc4173aae4975ded019ef5ab5a36249f1424df E–K)

Inputs: six canonical 127-bit bowls indexed 1..6 after 46 visible rounds; active ordinal/lease and signed32 c,t already used by the predecessor. For r=1..12, all six previous bowls must remain an immutable snapshot until all six replacements are calculated.

S_r=SAVE(sum(old[1..6])+149*r), with SAVE(x)=1+((x-1) mod (2^127-1)).
order_r=lex_order(S_r), a permutation of IDs 1..6.
At permutation position q=1..6, b=order[q], p=old[order[q-1]] with wrap, n=old[order[q+1]] with wrap:
u=old[b]+3*p+5*n+S_r+r+q*q
new[b]=SAVE(u*u+7*p*n).

Retain all 12 S_r as 192 little-endian bytes, final six bowls as 96 bytes, and never overwrite orderAt46. **The raw six-bowl sum is not allowed in u.** Mutant raw-S and in-place serial six-bowl substitutions are explicitly rejected by independent Host reference arithmetic. Individual step r must reject r=0 or r>12; outputs untouched on failure. Full 12-step driver preserves original published bowls and sum array on invalid/idle failure, status=2 or 6; owner, lease, original offsets and nonowner SRAM unchanged. ROM0 work must remain >=10 free; allocate new working memory in WRAM0 and code in ROMX bank1.

## Acceptance gate — candidate only until measured on NEW exact SHA

Run **natural push** GitHub CI once; do not dispatch a duplicate run. All 23 jobs must be completed/success with exact checkout SHA in every job log. Dedicated job: independent 72 input pairs x12 rounds; Foundation independent 96 final-bowl bytes and 192 retained-sum bytes; raw-S and in-place mutants rejected, negative-zero/idle/illegal-round and lease/SRAM checks; RGBDS v1.0.4 compile/link; ROM_HEADER PASS; measured ROM0 free>=10; real PyBoy A5/391/40 within configured <=120000 frames (report actual observed frames), normal370 <=9000; regressions Native371..390 retained; downloadable ROM/map/sym artifact inspected. Source commit or Host-only PASS is NOT native acceptance.

After full Native391 milestone acceptance ONLY, next Stage1: compute A0 and direction from selected bowl and its successor in immutable orderAt46 for seals 10/11/12, with independent host oracle and separate native gate. No main/merge/release/Stage2.
