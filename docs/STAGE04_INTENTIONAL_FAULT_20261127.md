# Stage04 — explicit intentional fault injection (not historical discovery)

PROJECT_ID: PC-BRANCH-OBJECT-PASCAL-PORTUGUESE
Branch: Object-Pascal+Português
Clean parent: ea2bee76d9402a4a48ab3234172c9a0790074974
Original source blob: 88da645965a0898a5217718582dc829e04afff2c

User directive 2026-11-27: "אם אין תקלה שאפשר למצוא, צור אחת. בצע עריכה שתגרום לתקלה (במפורש ובגלוי לכתוב שזו המטרה), ואז יהיה מה למצוא ולתקן."

Purpose: intentionally seed a real executable boundary defect in the live branch, not claim it was pre-existing. Change only the comparison in CountForDay from strict less-than to less-than-or-equal. The Foundation Day F=-15055671 now goes through the before-Foundation formula, giving 0 instead of normative 1. F-1 gives 2; F+1 gives 3. Other mathematical inputs are unchanged by this comparison change. Deliberately incorrect interim branch: no release or merge.

Independent oracle unchanged: docs/stage04_foundation_day_tag_oracle.py, blob 80f981204d8334aec0b15a36e52174b4890fee45. The 1072-row TSV digest is 74dc3e3d4ea07eeebed2647c798c7a3e1cbf91877e73a65351370a58c7e7ecab. Probe invokes CountForDay directly plus both public WorkCounts wrappers, comparing five tag values per row. Native exit 1 is expected for exactly one row, F, with all five outputs 0; 1071 other rows must match. Runner fails on compilation failure, timeout, unexpected mismatch, or absence of the seeded RED. General Stage02 regressions may now fail intentionally; do not suppress them. A successful discovery harness is not green production or whole-stage acceptance.

Stage04 remains NOT ACCEPTED until exact-SHA Native evidence (run, job, logs, artifact, hashes) is reviewed. Stage05 not started. After confirmation, retain the faulty expression as explicitly labeled seeded legacy and restore normative production behavior in a separate patch, then require full regression GREEN. No claim of pre-existing historical defect. Frozen common plan unchanged. No main, merge, release or other branch changes.
