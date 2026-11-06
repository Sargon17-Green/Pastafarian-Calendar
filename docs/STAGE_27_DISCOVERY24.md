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
