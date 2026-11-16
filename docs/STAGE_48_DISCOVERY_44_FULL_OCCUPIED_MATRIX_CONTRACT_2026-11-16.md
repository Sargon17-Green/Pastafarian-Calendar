# Stage48 / DISCOVERY44 — complete four-destination occupied-probe matrix
PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage47 accepted on exact source b2451b83eddd421d67af88393258ce4420ad676b; 48/48 completed/success.
Evidence: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43946572363 ; artifact https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43946572363/artifacts/14265503896
Artifact SHA256: e1cc9c80be6c8276e464d57a6ee51e0bdbbb477b27aa6184cc766ce014e1ff75
Kind: test-only bounded DISCOVERY; no presumptive defect, no production edit.

## Question and strict native contract
Stage47 probes only one occupied destination immediately before each of 192
rolling frees. Stage48 probes ALL FOUR occupied destinations, one by one, while
four outputs are concurrently live, before EACH rolling free.
For every attempt the DISTANCE-PATCH route must return status 175,
not allocate a fifth output, not change any output's byte string, chunk chain,
sign, or head/tail pointer, and not alter either caller-owned BigInt input.
The candidate destination is selected independently of the scheduled hole;
the harness must save the loop's release index across any helper that mutates it.
After the four negative probes, release the selected slot and verify three
survivors, then recreate the slot and verify four distinct output owners.
Retain the two original fixed probes per 24-case run.
This extends Stage47's 192 rolling probes to 768 (4 * 192), with
total occupied rejects and preserved-state checks 816 (768 + 2 * 24).
No expected-red assertion unless a native failure is first reproduced.

## Fixtures and independent oracle
24 deterministic ordered C/T cases: n=3,9,320,8192 digits and j=1..6.
X=10^(n-1)+(5j+2), Y=10^(n-1)-(2j+5); odd j uses (C,T)=(X,Y),
even j uses (Y,X). For 4 outputs, C'=C+(slot-1) for odd j and
C'=C-(slot-1) otherwise; expected |T-C'|+1 = 7j+8+slot-1.
All 24 release permutations covered exactly once, each with a forward and
reverse four-step sweep. 96 independent BigInt arithmetic checks, 24 unique
pairs, 6 at width 8192. Independent test-only oracle in
test/stage48_planning_oracle.mjs generates permutations via Heap's algorithm
and models output ownership with Map and reference-identity assertions;
it never calls the COBOL implementation and is not a Native acceptance oracle.
Planning target counts: 768 rejected occupied-slot probes, 192 slot
release/recreate transitions, exactly 192 probes against EACH of slots 1..4.

## Native implementation / acceptance (not yet performed)
Implement an isolated test/stage48_discovery_tests.cob based ONLY on this
branch's accepted source interfaces and this contract. Keep production untouched.
Wire one strict GnuCOBOL 3.1.2 -Werror job into canonical-names-lock.yml,
with bounded compile <=300s, execution <=120s, job <=20min, source/oracle
marker checks and evidence upload. Require natural exact-SHA CI 49/49
completed/success including existing 48 regression jobs and new Stage48 job.
Required Stage48 markers include:
  ORACLE_PASS=96/96; PERMUTATIONS_STATIC=24/24;
  OCCUPIED_MATRIX_MODEL=768/768; ROLLING_MODEL=192/192;
  OCCUPIED_REJECTS=816; REJECTED_PRESERVED=816;
  ROLL_PROBES=768; ROLL_FREES/REUSES/THREE/QUADS=192 each;
  runs=24; pass=24; unexpected_failures=0;
  HEAP_MEASURED=YES; HEAP_LIVE_POST_RELEASE=0;
  RESULT=PASS_STAGE48_FULL_OCCUPIED_MATRIX_DISCOVERY_NATIVE;
  STAGE48_NATIVE_GATE=PASS.
Additional surviving lifetime/ownership and 24-permutation counters from
Stage47 remain mandatory; changing the expected meaning of those counters
is not authorized by this plan. Capture run ID, job, artifact, digest and log.
Current state: CONTRACT+PLANNING_ORACLE only; NO Stage48 Native test,
NO Stage48 source integration, NO Stage48 CI run and NO Stage48 acceptance.
No main, merge, release, or full calendar integration claim.
