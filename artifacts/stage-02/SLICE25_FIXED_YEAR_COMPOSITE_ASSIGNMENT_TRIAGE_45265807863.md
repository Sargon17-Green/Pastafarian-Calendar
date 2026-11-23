# SQL+தமிழ் Slice25: actual PG17.12 QA failure triage and bounded repair
Date: 2026-11-23
PROJECT_ID: PC-BRANCH-SQL-TAMIL
Scope: QA files only on SQL+தமிழ்; no production SQL 00..27 changes, no main/merge/release.
Parent source HEAD: 55f733a6a52df3d58eb4e0f0164f22b985e93fee
Verified complete original run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45265807863
Job: 138012271153 — completed/failure, original exact-SHA run 45265807863.
Artifact: 14862143453, sql-tamil-fixed-structure.zip, 5510 bytes.
Raw ZIP SHA-256: 08488d638d86af1a139891efd79d0a46a87d99a7b110b84722de8d30a7553d4f
Same digest in GitHub artifact metadata, original job upload log and independently calculated downloaded ZIP. ZIP 9/9 members, CRC test PASS.
Original versions.txt: branch SQL+தமிழ், HEAD 55f733a6a52df3d58eb4e0f0164f22b985e93fee, PostgreSQL 17.12.
Original locks.txt: 8/8 expected Git blob SHA match (workflow source lock step success), all 28 production SQL files loaded before QA step.
Original static.txt: S25_STATIC_SOURCE_LOCK=8/8 PASS; fixture 29/29, no Native PASS.
Original probe.log: S25_SOURCE_YEAR=4996; S25_ENTER=sauce; then psql line 26 ERROR malformed array literal from the composite sauce_result value (two arrays), inside the first DO/SELECT INTO STRICT v.
Observed START_UTC=2026-11-23T21:12:30Z, but exit.txt has NO PSQL_EXIT/END_UTC. Root cause: actions Bash shell was invoked with -e, and a psql exit code 3 preempted subsequent logging; 'set -uo pipefail' did not disable errexit.
Consequences: no S25_EXIT=sauce, no later cutlet phases, no five-field result, no untouched calendar_date differential. Not a demonstrated production algorithm defect.

Repair (source QA only):
1. SELECT (s).* INTO STRICT v FROM qa_sauce, to assign expanded composite attributes to the typed PL/pgSQL record; do not cast the whole record to one scalar field.
2. Apply the identical fix prospectively for SELECT (structure).* INTO STRICT v FROM qa_full.
3. Wrap psql with 'if ...; then code=0; else code=$?; fi', recording PSQL_EXIT and END_UTC even on failure while continuing to fail the job. Print tail from original probe.log.
4. Static workflow guard asserts both composite expansion statements remain present.
5. Preserve all five 60-second phase bounds, the independent accepted 9 archived gate gaps, source locks, unchanged production files, and the original 5-field oracle.

Validation gates:
- Source: exact branch/parent and newly-created blobs/readback before dispatch.
- Static checks: exact target replacements and exit-code capture; NOT PostgreSQL result.
- Native: wait for natural push CI on new SHA and inspect completed job, original artifact ZIP SHA/CRC, real phase markers and PSQL_EXIT.
- Separate five-field oracle (4996,வெண்கலம்,302,தவளை,50), calendar_date differential, Slice25 acceptance: NOT YET PASS.
- Historical successful 45133869661 gap gate and old QA runs are not to be manually replayed without new evidence.
