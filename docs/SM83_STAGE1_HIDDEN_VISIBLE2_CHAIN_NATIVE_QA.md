# Stage1 visible2 Native381 candidate (not yet accepted)
PROJECT_ID: PC-BRANCH-SM83-ASSEMBLY-GEEZ
Branch: SM83-Assembly+ግዕዝ
Predecessor: d774079e062ddc5b6755c9ae246ce496aa2927aa accepted Native380 in CI44896124822 (12/12).
Normative contract: Issue #30, main README pinned 56bc4173aae4975ded019ef5ab5a36249f1424df.

Signed32 offsets c,t with validated active owner lease. Existing chain produces
H1..H7 and visible1. Native381 retains 16-byte V1 and selects predecessor
(V1,H2,H6) corresponding to (i-1,i-3,i-7) for i=2. Five i2 stones
are recomputed from canonical seeds with accepted simultaneous ROMX transition,
then the same 11-round visible polynomial executes with initial +i=2.
Only V2 publishes on successful second iteration. Cross-iteration rollback
after an artificial intermediate failure is not separately claimed.
Status 0 success, 2 invalid, 6 idle. No bowl, post-stir, or Ge'ez catalog.

Independent Host oracle with 72 signed32 pairs, Foundation V1/V2/H2/H6
and five i2 stones checked as postconditions, not runtime inputs.
Native381 tests hidden retention, V1, V2, 48-byte predecessor input,
i2 stones, invalid negative zero, idle/abort, 8-byte offset integrity,
lease and physical SRAM sentinel.
Acceptance requires exact-SHA 13/13 jobs completed/success (verify, default
370, isolated 371..381), matching checkout in each log, Host72, real
RGBDS v1.0.4 and ROM_HEADER, measured ROM0 free>=10, PyBoy A5/381/40
<=30000 frames. No main/merge/release/Stage2. Visible3..46,
six bowls, 12 post-stirs and answer remain unfinished.
