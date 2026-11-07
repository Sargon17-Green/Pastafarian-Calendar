# Stage27/DISCOVERY24 — cross-axis ±5779 and ±2 independent real-date differential

## Proven predecessor
Stage26 on exact PATCH01 SHA `0a95e8f09a91eb43ca35ef1599cb4cb66449399e`, automatic push [CI 42173010037](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42173010037) completed/success **28/28** jobs including verify, Stage21 and Stage26 job **127744974910**. Direct GNAT13 compile/bind/link, 25 unique ordered pairs, Python 139, Ada Native 131 and real five-field numerical 125. Stage26 ACCEPTED bounded only.

## Stage27 novelty and input contract
Let F=Foundation_Day; all 25 row-major ordered pairs (F+c,F+t), with both c and t ranging over {-5779,-2,0,+2,+5779}. Previous Stage15/16/17/18/20/21/22/23/24/25/26 coverage (Stage19 subset of 20) overlaps this grid in 17 pairs. Eight novel ordered offset pairs are exactly (-5779,-2), (-5779,+2), (-2,-5779), (-2,+5779), (+2,-5779), (+2,+5779), (+5779,-2), (+5779,+2). The independent Python source asserts this exact coverage difference. The other 17 pairs are regression. No defect is presumed; no expected-red before actual reproduction.

## Oracle, outputs, strict checks
Native Ada uses public `Normative_Oracle.Calendar_Date` and prints STAGE27_NATIVE_PAIR with calculation day, target day, year, cutlet, cutlet_day, month and month_day. Independent source-derived Python oracle `tests/stage14_real_oracle.py` computes the expected five fields; it does not read expectations from Ada or other branches. Exact numerical equality for each of five fields on all 25 ordered pairs. Strict parser rejects duplicated, malformed, missing or extra pairs and invalid Native assertion marker.
Domains: year 4900..5100; cutlet 1..17; cutlet_day 1..5778; month 1..47; month_day 1..123. Center anchor (5000,10,503,30,52); repeat pivot (F-5779,F+2). No monotonicity assumption.
Python: uniqueness 1 + novelty 1 + axis norms 2 + 25×5 domains 125 + repeat 5 + center 5 = **139**.
Ada Native: 25×5 domains 125 + repeat 5 + center year 1 = **131**.
Independent numerical differential: 25×5 = **125 scalars**.
Bounded Python 180s, Ada process 600s, comparator 180s; nonzero failures. CI job timeout 30 minutes due observed apt-get startup variation.

## Acceptance — PENDING
Require exact committed SHA automatic push CI **completed/success 29/29 jobs**, including verify and `native-stage27-remote-two`; direct GNAT13 compile/bind/link and exactly 25 unique ordered pair records with:
`STAGE27_INDEPENDENT_REMOTE_TWO_SELFTEST_ASSERTIONS=139`
`STAGE27_NATIVE_REMOTE_TWO_ASSERTIONS=131`
`STAGE27_REAL_FIVEFIELD_SCALARS=125`
Source/static preflight, queued and in_progress CI are not Native PASS. No main/merge/release.

## PATCH01 — Stage04 CI setup timeout only (2026-11-06)
Automatic push run [42176995669](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42176995669) at exact SHA `569577c7857c5cbd0c0cc25cfa8bb40384cbf0a3` completed with **28/29 successful** jobs. Verify job `127757631474` succeeded. Stage27 native job [127757631974](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42176995669/job/127757631974) succeeded: GNAT 13 compile/bind/link, 25 distinct ordered pairs, Python independent selftest 139, Ada invariants 131 and exact numerical five-field scalars 125. These are direct observed results of the Stage27-specific job, **not** full Stage27 acceptance.

Unrelated historical `native-stage04-discovery02` job [127757631563](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42176995669/job/127757631563) was cancelled after approximately ten minutes during `apt-get install -y gnat gprbuild`. Its liveness probe was skipped; no Ada mismatch was observed. Workflow's Stage04-specific `timeout-minutes: 10` exhausted while the package mirror was slow. PATCH01 changes **only** Stage04 job timeout 10 → 30 minutes; no calculations, oracles, fixtures, runners or other job timeouts are altered. It is not a retry or redispatch of the previous run: the next push CI must validate the patch at its own exact SHA.

**Stage27 acceptance remains PENDING** until the new same-SHA automatic run is completed/success with 29/29 jobs, including Stage04, verify and Stage27 direct numeric evidence. No main/merge/release.

## PATCH02 — Stage16 job timeout after completed PATCH01 CI (2026-11-06)
Automatic push [42187965275](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42187965275) on exact SHA `f3acea61339bf766ffd247e93839a4dd464c48a6` finished **completed/cancelled, 28/29 jobs successful** (not 29/29). The Stage04 job [127792733401](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42187965275/job/127792733401) succeeded after PATCH01; verify job 127792733595 succeeded. Dedicated Stage27 GNAT13 job [127792733657](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42187965275/job/127792733657) succeeded with independent Python **139**, Native **131**, independent five-field scalar comparison **125**, and exactly 25 distinct ordered pairs directly observed. These are **not** full Stage27 acceptance.

The unrelated historical Stage16 job [127792733988](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42187965275/job/127792733988) was cancelled under the workflow's `timeout-minutes: 15` at approximately 08:45 UTC. Its GNAT apt setup finished at approximately 08:43:55 UTC, consuming nearly the entire job time; Python independent selftest **135** and GNAT13 compile/bind/link were observed, but Native assertions **131** and real five-field comparisons **125** were **not** observed before the cancellation. The last log says "The operation was canceled"; no Ada mismatch was observed. Previously accepted Stage16 numerical results are not retroactively invalidated.

PATCH02 changes **only** the Stage16 workflow job `timeout-minutes` from **15 to 30**. No Ada source, Python oracle, fixtures, runners, other workflow jobs, or acceptance criteria change. Do not redispatch the previous run. Require a new push CI run at the precise PATCH02 SHA, **completed/success 29/29**, including verify, Stage04, Stage16, Stage27 and direct Stage27 numerical markers 139/131/125 for 25 unique ordered pairs. Otherwise inspect the single failing job and apply a justified focused correction. Stage27 acceptance remains **PENDING**; no main/merge/release.

## Final PATCH02 acceptance — verified completed run (2026-11-07)
The exact PATCH02 SHA `3b2c75582a193ae6e9a7629cdc13b5bdb56a921a` on branch `Ada+తెలుగు` has automatic push [run 42250337981](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42250337981) with status **completed**, conclusion **success**, attempt 1, and **29/29** successful jobs. Verify job 128003427535, Stage04 job 128003427338 (18 Ada assertions), and Stage16 job 128003427997 (Python 135, Ada 131, numerical 125) all succeeded. Direct Stage27 GNAT13 compile/bind/link in job [128003427880](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42250337981/job/128003427880) succeeded: Python independent selftests **139**, Ada Native assertions **131**, independent five-field numerical comparisons **125**, and exactly **25** unique ordered `STAGE27_NATIVE_PAIR` rows. **Stage27 ACCEPTED for its bounded matrix only**. Previous PENDING text is historical.
