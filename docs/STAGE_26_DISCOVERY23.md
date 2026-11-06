# Stage26/DISCOVERY23 — independent ±5778 / ±2 five-field real-date differential

Stage25 predecessor: exact SHA `d2df47c6939d9ff242c512283fa3683fc7b3b259`, [CI 41979143455](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41979143455) completed/success 27/27; direct GNAT13 log and exact 139/131/125 count markers, 25 ordered records.

## Scope and novelty
Let F=Foundation_Day. Test row-major pairs (F+c,F+t), each axis {-5778,-2,0,+2,+5778}. Union of prior Stage15,16,17 and 18 (asymmetric), Stage20–25 (Stage19 subset of 20) accounts for 9 regression pairs on {-5778,0,+5778}². Exactly 16 ordered combinations having ±2 on at least one axis are new. Python asserts explicit novel pair fixture against prior-matrix set subtraction; no defect is presumed.

## Inputs, oracle, limits
Public Ada Normative_Oracle.Calendar_Date supplies actual fields. Independent source-derived Python stage14_real_oracle.date supplies expected year/cutlet/cutlet_day/month/month_day. All five components must match numerically for all 25 unique ordered pairs. No expected values are taken from Native output or other branches. Domains year 4900..5100, cutlet 1..17, cutlet_day 1..5778, month 1..47, month_day 1..123. Exact center anchor (5000,10,503,30,52); repeat pivot (F-5778,F+2). No monotonicity assumption.

Python selftest: uniqueness 1 + explicit coverage 1 + norms 2 + 25×5 domains 125 + repeat 5 + center 5 = **139**. Ada Native: 25×5 domains + 5 repeat + center-year 1 = **131**. Strict differential comparator: one exact Native marker, exactly 25 correctly formed unique ordered pair records, no extra/missing/duplicate pair, 25×5 = **125 numerical scalar equalities**. Python timeout 180s each, executable timeout 600s, CI timeout 15 minutes, nonzero exit on mismatch.

## Acceptance — ACCEPTED (bounded)
Require same-SHA automatic push CI completed/success **28/28 jobs** including verify and native-stage26-limit-two; direct GNAT13 compile/bind/link log plus exact markers STAGE26_INDEPENDENT_LIMIT_TWO_SELFTEST_ASSERTIONS=139, STAGE26_NATIVE_LIMIT_TWO_ASSERTIONS=131, STAGE26_REAL_FIVEFIELD_SCALARS=125. Static QA and queued/in_progress runs are NOT Native PASS. No main/merge/release.

## 2026-11-06 — Stage26 first CI attempt and CI setup PATCH01

GitHub [push run 42125385167](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42125385167) was completed/cancelled on exact SHA `ebc8eaa50be8a9393a536fef57f50199501e46a0`, attempt 1: **27/28 jobs succeeded**, including `verify` and `native-stage26-limit-two` job `127588112089`. Direct GNAT 13 compile/bind/link log reported precisely `STAGE26_INDEPENDENT_LIMIT_TWO_SELFTEST_ASSERTIONS=139`, `STAGE26_NATIVE_LIMIT_TWO_ASSERTIONS=131` and `STAGE26_REAL_FIVEFIELD_SCALARS=125`, and 25 distinct ordered Native pairs; the new bounded Stage26 numerical differential passed in that job.

The one cancelled job was historical `native-stage21-edge-adjacent` (job `127588112069`), not the Stage26 job. Its `sudo apt-get update -qq; sudo apt-get install -y gnat gprbuild` setup started at 23:09:46 UTC and only printed GNATMAKE 13.3.0 at 23:24:35 UTC (about 14m49s), leaving fewer than 25 seconds of its 15-minute *job-level* timeout. Its Python selfcheck emitted 88 and GNAT compiled/bound/linked, but the Native executable was terminated at 23:24:58 UTC; its numerical comparison did **not** finish. There is no observed calendar mismatch. PATCH01 increases **only the Stage21 workflow job timeout from 15 to 30 minutes**; existing runner-level 180/600/180-second bounds, data, algorithms, assertion counts and 28-job gate stay unchanged. This is CI setup tolerance, not an Ada correctness fix.

**At the time PATCH01 was committed, Stage26 overall acceptance remained PENDING** until a new push-triggered run completes success with **28/28 jobs on the new exact SHA**, plus direct verification of required logs and markers. Do not treat the first cancelled run as a full-stage PASS; do not manually dispatch duplicate CI.

## 2026-11-06 — final acceptance on PATCH01 SHA
Exact `0a95e8f09a91eb43ca35ef1599cb4cb66449399e`, [automatic push CI 42173010037](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42173010037), completed/success **28/28 jobs**, including verify, Stage21 job 127744974912 and Stage26 job 127744974910. Direct GNATMAKE 13.3.0/gcc-13/gnatbind-13/gnatlink-13 evidence, 25 unique ordered pairs, Python selfcheck **139**, Ada Native **131**, five-field scalar differential **125**. Historical Stage21 direct markers **88/85/80** observed. Stage26 ACCEPTED for bounded 25-pair scope only; no main, merge or release.
