# Slice25 direct cutlet boundary acceptance
PROJECT_ID: PC-BRANCH-SQL-TAMIL; branch SQL+தமிழ்; 2026-11-25.
Tested SHA 8d9e07711d047b00ebc04ae8c0ef4ecd75ffcc7f; run 45551461538 completed/success, three completed jobs. PostgreSQL 17.12, production-only load; 29 source/fixture locks per job; direct unchanged calendar_date, typed 5/5 archived oracle each, PSQL_EXIT=0. Original ZIP bytes SHA256 matches upload log and artifact metadata; CRC 9/9 per ZIP; probe.sql and oracle.json SHA256 match internal manifest (6/6).
| case | job | artifact | raw SHA256 | ms | typed tuple |
|---|---|---|---|---|---|
| anchor_cutlet_boundary_minus | 138993367415 | 14993462927 | 14a39d9469bccd1c0da17cfd87bce0def578ca99ace361fd8717feaacb6b166e | 270290.805 | (5000,தேள்,502,மூடிய கதவு,21) |
| anchor_cutlet_boundary | 138993367652 | 14993857190 | 9ad31bfe3e9396beed2dbfbae18f9a49420eb271d6e848b4eff84352160551f7 | 166811.549 | (5000,தேள்,503,கிணறு,56) |
| anchor_cutlet_boundary_plus | 138993367739 | 14994680554 | 798b554d43192804305975fe5ce184dde8958cf5d35f1a12128310a751276ac1 | 159756.252 | (5000,சிரிப்பு,1,தவளை,38) |
Versions files match exact SHA/branch/PG. Original archived independent oracle source 1ddaef9a315f83402ececaf4dc31f96dbdd051bd, fixture blob 21f38cd280498070b08b6c3074780f1742c36957. Stage1 run 45551461445 and Names 45551461417 completed/success metadata only in this audit; not new full acceptance.
Cumulative direct archived-oracle acceptance 4/29 including prev_3_prev_middle (45505543502); 25 residual. This is not live normative differential. Full Slice25 NOT ACCEPTED.
## Next shard
Two fresh isolated PostgreSQL 17.12 jobs, next_1_month_first and next_1_month_second; locked calculation_day -15055671 and targets -15053457 / -15053421; expected (5001,கொத்து,2,எரிடு,1) / (5001,கொத்து,38,எரிடு,2), source artifact 14614701184. Same 29 locks, 720s statement / 750s watchdog / 15m job, one direct call per job, typed comparison and original evidence. No production change, no boundary rerun. Remaining original gates >=40 named Native, >=8 isolation, >=24 live normative comparisons, >=8 years; archived direct results not substituted. No main/merge/release.
