# Fortran+English Stage1 — independent context artifact integrity QA

Date: 2026-11-21
Project: PC-BRANCH-FORTRAN-ENGLISH
Examined source commit: 55e08103aa15c04cd502217a496a6bc7ba696ec4
Completed CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44876485645 (attempt 1, completed/success; 10/10 jobs)
Context job: 136762196217 (completed/success)
Artifact: 14696862393, fortran-stage01-calculation-context-diff
ZIP SHA-256: a1fc647630e3699affac955ba83e204ab6822fed643841c7aa34de62a4bed0f8
JSON SHA-256: 5d9e069fdb927968dfc682cea611478e909b3f78da2a8bc61d930504f2adc77b

## Verified
- ZIP archive digest matches GitHub artifact metadata and job log; CRC check succeeded; exactly three expected members.
- JSON ties project, Fortran branch/SHA, CI run ID, pinned independent Python commit/blob to the run; full_stage1_accepted=false.
- Standalone comparison 14/14 cases and 70/70 exact fields; two boundary-sensitive and three Foundation-sensitive pairs.
- Three original Fortran same-process sequences (forward boundary, reverse boundary, fixed Foundation target), each 8/8 calls and 40/40 expected/actual fields, no reset.
- Local independent structural audit against downloaded artifact: 190/190 field observations PASS; 15/15 deliberately corrupted evidence variants rejected.
- Canonical existing gates: cache structure 215 assertions, 0 failures; full Stage1 executable 58/58 (entrypoint gate only).

## Added gate
test/stage01_context_artifact_audit.py independently checks numeric field types/ranges, input offsets, ordering, per-call provenance and accounting, context sensitivity, oracle-vs-Fortran traces, and evidence mutation rejection. Add this to the existing CI context job after output JSON is generated; a newly triggered CI is required to claim Native PASS on the new commit. The source implementation and Python pinned oracle remain unchanged.

This is evidence-integrity QA, not a second algorithmically independent normative calendar oracle, not full Stage1 acceptance, and not Stage2/main/merge/release.
