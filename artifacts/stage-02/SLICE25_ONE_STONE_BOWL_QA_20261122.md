# SQL+தமிழ் Slice25 — independently grounded one-stone-bowl QA candidate

PROJECT_ID: PC-BRANCH-SQL-TAMIL
Parent SHA: f343acee17b2fd87257827ff4991f200b7ac2649
2026-11-22

## Completed original parent evidence
- Run 45065425082 job 137340370989 PG17.12 completed/success: 230/230 stone fields and 32/32 bowl arrays; original artifact #14770519125 SHA256 18885eb7505371e2deb69616c25a61e59a10f8a65a03165a64bff80e1561460b, original ZIP CRC PASS, exact SHA and source locks, SOURCE_LOAD_EXIT=0 ORACLE_EXIT=0.
- Run 45065425124 job 137340371525 completed/success: Stage1 52 normal +7 saved-sum +4 isolation +3 heavy; original #14770339403 ZIP SHA256 61fd13e34aba57609cf3db3c5e63e8e24c2411e811774dae0bcc9229c699644a and CRC PASS.
- Run 45065425061 job 137340371057 Names Lock completed/success, no ZIP.
- Source generator JSON says Native NOT_EXECUTED at generation; subsequent original PostgreSQL oracle.log/exits.txt demonstrate actual Native PASS.

## Candidate acceptance contract
- QA-only schema function. MATERIALIZED CTE calculates one composite stone_state per bowl call. Production SQL unchanged.
- Native differential 46 positions x four drop permutations x two boundary bowl arrays = 368 full numeric arrays; twelve malformed inputs expected NULL; 32 independently generated complete arrays plus 230 stone fields; alternating four 46-position EXPLAIN ANALYZE timings without assuming speedup.
- Exact source locks inherited from independent same-branch Python oracle (no other branch copied). No production merge, main, release, or full 56-job matrix. Until exact-SHA completed job+log+original ZIP SHA/CRC, candidate Native NOT ACCEPTED; full Slice25 remains NOT ACCEPTED.
