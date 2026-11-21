# One-call sauce → bowl/stone hotspot: QA-only contract

Project PC-BRANCH-SQL-TAMIL, branch SQL+தமிழ். Follows [completed timeout 44947014984](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44947014984) (tested SHA 1313785d7d1e0f779e32f77dcb53e72afd809473).
The historic 180-second year case is NOT rerun. This is new profiling coverage for one representative signed-negative-offset-1 sauce path.

Inputs: calculation=-15055671, target=-15055672. PostgreSQL 17.12. SQL 75-second statement budget and 5-minute job cap.
Output: original and QA-cloned sauce_result compared using IS DISTINCT FROM, plus independent original-vs-clone stone_value(46,1) equivalence. No claim of a mathematically independent sauce oracle: an external oracle is required before production optimization acceptance.
Source locks: original Git blobs for 04,08,10. Refuse changed definitions, changed counts, irreversibility. Original SQL 00-27 loaded byte-for-byte before only new qa_hot_* definitions; production untouched.
Coverage: ENTER/EXIT and milliseconds for stone_state, stone_value, bowl_round, post_stir_chain, and sauce. Durations are nested, never summed across parent and child.
Evidence: exact SHA/branch, source and generated file digest, static log, full PostgreSQL logs, probe exit code, job and ZIP. Exit capturing uses set +e so expected SQL failures cannot skip exits.txt. Artifact uploaded even on failure.
Accept diagnostic only if completed exact-SHA run and artifact verified, exit=0, two equivalence PASS notices and bowl_round trace. No Slice25/five-field/differential acceptance, no merge/main/release.
NEXT: inspect per-round timings and source for a narrowly scoped production optimization candidate, then require independent oracle and distinct complete Native/differential gates.
