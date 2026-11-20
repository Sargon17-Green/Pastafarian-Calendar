# SQL+தமிழ் — Slice25 fast-window candidate, evidence-first
PROJECT_ID: PC-BRANCH-SQL-TAMIL
Source before QA change: e702e3ad57c3aecd4e3b63779637195b112ee954
Baseline original run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44800413480 — completed/success; PostgreSQL 17.12, job 136510781166.
Original artifact ZIP 14662987818: downloaded bytes SHA256 9255fd368a9d8880537789a25962c1489d85f07f12a07acf9088fb94a0ca4d66 = GitHub digest = upload-log digest, CRC 8/8; 31 source-hash lines, generated SQL SHA256 2a2f476596358b841332eba98616a2b2f774b34ea94d21dac00868e76b898f0d.
Seed -15055671 = foundation_day; locked year5000, five numeric fields PASS, candidate count 43.
Native phases: window 479828.815 ms; candidates 1.560 ms; choice 7075.546 ms. The window dominates this single profile; these are not whole-selector timings.
Stage1 run 44800413675 and Names Lock run 44800413600 jobs completed/success on same SHA; original ZIP verification of Stage1 is a separate check.

## QA-only optimization
Current production sql/16 recomputes foundation-relative index walks for lower/upper bounds plus gate_day(lo). The new pg_temp function uses two independent forward/backward monotonic walks, each stopping exactly one sentinel gate beyond its own boundary. Duplicate foundation index is deduplicated. The selected lower index remains max(gate_day<=lower)-1; upper index remains min(gate_day>=upper)+1. Only the bounded consecutive gate array is returned.
Independent Python synthetic arithmetic oracle checks exact bisect semantics against simulated walk for 4,644 target days with gaps 42..963, exact gate days, off-by-one boundaries, signed days and +/-5778. All 4644 local cases PASS; this is NOT native evidence and uses no normative fixture.
Natural CI on the exact branch SHA must verify the fresh PG17 candidate with all five accepted source-locked year fields, 43 candidates, measured speed, source manifests, original psql logs, raw artifact SHA+CRC. The candidate can fail; no PASS is asserted in advance. No production SQL, main, merge or publication changed; Slice25 remains not accepted.
