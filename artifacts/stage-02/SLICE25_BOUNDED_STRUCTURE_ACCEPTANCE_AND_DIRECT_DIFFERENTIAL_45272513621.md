# Slice25: bounded structure evidence and direct differential contract
PROJECT_ID: PC-BRANCH-SQL-TAMIL
Tested commit: 876700fd21eacd6a799a034a4d4c3f56e6a0089a
Branch: SQL+தமிழ்

## Completed evidence
- Run 45272513621 / job 138035714167 completed SUCCESS, PG17.12. Original artifact 14866556954, SHA256 105387169d44f1472a8ae3f10609b6ebebb111f968f7138b0d7f7902fa43c5fa matches metadata, upload log and locally downloaded ZIP; CRC 9/9. Probe SQL SHA256 6f8b7fdb69c8aecaf5a31655378beac6f9c22ce4f975cb92232130ebc70e7106 matches internal manifest. Static source locks 8/8, fixture 29/29; production 00..27 loaded. PSQL_EXIT=0, START_UTC 2026-11-23T21:50:56Z, END_UTC 21:51:24Z.
- Five phases completed: sauce 5516.113ms; count 3.338ms (k=8); partition 5516.177ms ({1,1,2,1,1,1,1,1}); names 4.277ms; structure 16869.684ms. Native five fields (4996,வெண்கலம்,302,தவளை,50) PASS. No gate replay or direct calendar_date.
- Run 45272513741 / job 138035716038 completed SUCCESS, PG17.12, 52 ordinary + 7 saved-sum + 3 heavy + 4 isolation. Original artifact 14867180087 SHA256 fcf88a05e2613c323f4dd83613066abf7918246312162e9be32fd0eb799f0567 matches metadata/upload/raw ZIP, CRC 3/3. Names lock run 45272513616 / job 138035715608 completed SUCCESS, no artifact configured.
- All three runs tested the exact parent SHA. Focused structure accepted, entire Slice25 NOT ACCEPTED.

## Next direct differential
One call to unchanged production calendar_date(-15055671,-15072356), in fresh PG17.12, no aliases, caches, fixture injection, or test-schema calls. Compare typed full result against existing archived independent normative oracle (case prev_3_prev_middle, artifact 14613763506, fixture blob 21f38cd280498070b08b6c3074780f1742c36957). All 28 production blobs and fixture locked. Fail on NULL, any mismatch, SQL failure or timeout; collect actual values, timing, exact SHA, original ZIP, exit and source hashes. No claimed expected-red. No full matrix replay.
The previous 12-minute limit obscured a selector measured at 694470.435ms alone (44928511225, archived phase audit). New evidence from the accepted bounded gates and 28-second structure isolates the remaining combined path. One 1500s statement limit, 1560s host watchdog and 30min job limit are deliberately larger, not a production performance acceptance. If timeout, diagnose rather than increase again without evidence. One case only, not Slice25-wide acceptance. Stage1/names historical evidence remains scoped to tested SHA.
