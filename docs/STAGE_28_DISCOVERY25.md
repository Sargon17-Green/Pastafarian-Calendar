# Stage28/DISCOVERY25 — ±5780 remote frontier crossed with ±3 days

## Verified predecessor and choice
Stage27 on exact SHA `3b2c75582a193ae6e9a7629cdc13b5bdb56a921a` finished [automatic run 42250337981](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42250337981): completed/success, 29/29 jobs, including verify/Stage04/Stage16 and dedicated Stage27 GNAT13 job 128003427880; 25 unique pairs and direct Python 139, Ada 131 and numerical 125. Bounded Stage27 ACCEPTED only.

This discovery extends the previously tested ±5779 far boundary by one day (±5780) and adds an untouched ±3 local offset. It tests the source's real five-field conversion rather than presuming an error. No production calendar algorithm, fixture or foreign-branch code is changed.

## Inputs, independent oracle, precise coverage
Let F=Foundation_Day. Calculation and target days independently range over F+{-5780,-3,0,+3,+5780}. Enumerate all 25 unique **ordered** pairs row-major. Subtract the explicitly enumerated Stage15,16,17,18,20,21,22,23,24,25,26,27 matrices (Stage19 subset of Stage20). Exactly **24 new** ordered pairs remain; the only regression is (F,F). Assert the complete novelty set rather than only its size. Do not assume commutativity or monotonicity.

Ada `Normative_Oracle.Calendar_Date` emits `STAGE28_NATIVE_PAIR` with input calculation/target days and five numerical fields. An independent source-derived Python reference `tests/stage14_real_oracle.py` computes expected five-tuples, without consuming Ada outputs as expectations. Strict comparator rejects duplicate/missing/extra/malformed pairs, wrong marker multiplicity and every numeric mismatch. Domain invariants for each result: year 4900..5100, cutlet 1..17, cutlet-day 1..5778, month 1..47, month-day 1..123. Repeat pivot (F-5780,F+3) and check center year plus known full center anchor (5000,10,503,30,52).

## Bounded execution and acceptance gate
Python independent selftests: 1 cardinality + 1 complete novelty-set + 2 axis norms + 125 domain + 5 repeat + 5 center = **139**.
Ada Native assertions: 125 domains + 5 repeat + 1 center-year = **131**.
Independent five-field numerical equalities: 25×5 = **125**.
Require exactly 25 unique ordered Native pair rows. Runner timeouts: 180s Python selftest, 600s Ada execution, 180s comparator; nonzero exit is mandatory on failure. GNAT13 compile/bind/link in dedicated `native-stage28-remote-three` job with 30-minute outer timeout to tolerate observed apt mirror delays.

**Stage28 PENDING** until automatic push CI on the precise new SHA is **completed/success 30/30**, including verify and all historical jobs, particularly Stage04/Stage16/Stage27/Stage28. The Stage28 job must contain directly observed:
`STAGE28_INDEPENDENT_REMOTE_THREE_SELFTEST_ASSERTIONS=139`,
`STAGE28_NATIVE_REMOTE_THREE_ASSERTIONS=131`,
`STAGE28_REAL_FIVEFIELD_SCALARS=125`,
and 25 unique pair rows. Source-only checks and queued/in-progress jobs are not Native PASS. On actual failure inspect the failing log and apply a focused patch. No main/merge/release.
