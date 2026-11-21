# Stage1 V3 Native382 candidate — measured QA contract

PROJECT_ID: PC-BRANCH-SM83-ASSEMBLY-GEEZ
Branch: SM83-Assembly+ግዕዝ
Accepted predecessor: ae47cb9cde80106eea6b015395a8e40c2100ef5d (CI44905370003 13/13).
Authority: Issue #30; main README SHA 56bc4173aae4975ded019ef5ab5a36249f1424df.

Inputs: signed32 c,t, active owner/ordinal lease. Output: retained H1..H7,
V1, V2, final V3. At i=3 the predecessor triple is V2,H1,H5, and the
five i3 stones are one simultaneous update of i2's snapshot.
11 polynomial rounds, initial +3. V3 is the only final visible publication
on success. Status 0 success, 2 invalid, 6 idle. No fixture feeds the ROM.
Existing chain does not guarantee rollback of intermediates for an injected
failure after a successful earlier iteration.

Gate: exact commit SHA, 14/14 CI jobs completed/success including standard
370 A5/370/40 <=9000 and isolated 371..381; independent Host 72 signed32
pairs and Foundation postcondition; RGBDS v1.0.4 build+link; ROM_HEADER PASS;
ROM0 measured free>=10; PyBoy A5/382/40 <=30000; V1/V2 retained, i3
stones and (V2,H1,H5) verified; negative zero/idle, lease/offset and SRAM
sentinel preserved. Source-level assertion alone is not Native PASS.
No main, merge, release, Stage2.

NEXT after acceptance: V4..46, six simultaneous bowls, retained 12
post-stir sums, A0/direction. No Ge'ez names catalog yet.
