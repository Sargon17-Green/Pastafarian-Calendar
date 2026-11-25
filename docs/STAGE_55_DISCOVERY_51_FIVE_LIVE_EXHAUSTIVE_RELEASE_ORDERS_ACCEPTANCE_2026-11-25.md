# Stage55 acceptance — exhaustive release orders for five live owners

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Stage: 55 / DISCOVERY51
Status: ACCEPTED

## Tested source and completed CI

- Exact tested source SHA: `d05b92288d70ae4fd1659d3cd478c89b0a2f49cc`
- GitHub Actions run: `45673818180`
- Run conclusion: `success`
- Total jobs: 56 completed / 56 successful; zero failed, cancelled, queued or in-progress jobs at final read.
- Dedicated Native job: `139415894045`, completed / success.
- Compiler: GnuCOBOL `3.1.2.0` (confirmed in job log).
- Compile command used `-Wall -Wextra -Wstrict-typing -Wcall-params -Wlinkage -Wtruncate -Werror`; compile timeout 300 seconds, executable timeout 120 seconds, job timeout 20 minutes.
- Native log: `stage55-native.log`, embedded `PROJECT_ID=PC-BRANCH-COBOL-SIMPLIFIED-CHINESE` and `HEAD=d05b92288d70ae4fd1659d3cd478c89b0a2f49cc`.

## Artifact verification

- Artifact ID: `15050658237`
- Artifact name: `cobol-stage55-five-live-exhaustive-release-orders-evidence`
- Size: 1,205 bytes
- GitHub artifact digest: `sha256:eb9d60e06af612418f37f0ee17d5949f7001199f70f78f5b5e4560d7bc175458`
- Independently downloaded ZIP SHA-256: `eb9d60e06af612418f37f0ee17d5949f7001199f70f78f5b5e4560d7bc175458` — exact match.
- ZIP integrity test: PASS; CRC test: PASS.
- Embedded project ID and tested HEAD: exact match.
- The artifact contains the native log and all required result markers.

## Independent planning oracle

The Node BigInt oracle recursively enumerated all 120 permutations, independently checked the 120 unique (orientation,j) anchors, checked 600 exact arithmetic results and 546,600 base-10^9 chunk comparisons, and reported `gate=PASS_NOT_NATIVE` (planning only). Static COBOL preflight also passed: 18 paragraphs, 17 resolved PERFORM targets, eight required declarations, four orientation counter updates, maximum COBOL line length 70.

## Native results

The native executable reported:

- `STAGE55_PERMUTATIONS=120`
- `STAGE55_CASES=120`
- `STAGE55_PASS=120`
- first / last permutation: `12345` / `54321`
- initial owners / reverse-rebuilt owners: 600 / 600
- release steps: 1,200
- owner walks / chunk checks: 6,000 / 5,466,000
- distinct-owner checks: 2,400
- heap samples / zero-heap endpoints: 2,400 / 240
- orientation counts: 30 / 30 / 30 / 30
- unexpected failures: 0
- `STAGE55_HEAP_MEASURED=YES`
- `RESULT=PASS_STAGE55_FIVE_LIVE_EXHAUSTIVE_RELEASE_ORDERS_NATIVE`
- `STAGE55_NATIVE_GATE=PASS`

All five outputs were created and released in each enumerated permutation; all five were rebuilt in reverse order and released again. Every survivor was rechecked after each release, with exact heap counts and zero heap at both cleanup endpoints.

## Failure and repair audit

These were test-harness/configuration failures, not failures in the production arithmetic library:

1. Commit `9d193953547e3bb7b63b44f9107bf85373079ef4`, run `45671857759`: invalid root indentation for the appended workflow job; run created zero jobs. Corrected by restoring job indentation and the shell/Node newline escapes.
2. Commit `8bbe364c68c674f0aed13ff036d8c5d1d2dbaf07`, run `45672253852`, Stage55 job `139410369083`: the oracle's overescaped static-check expressions produced a false negative before compile. Artifact `15049942852`, SHA-256 `c9b53cbf71f3195ac8adddca8b0b8220dc21b349132bf4db77e3ef23ab7e408d`, ZIP CRC PASS. Replaced the fragile expressions with literal declaration matching and CRLF-safe line splitting.
3. Commit `b5bfb124709cda1e1e043208ae7286534bc70684`, run `45672819219`, Stage55 job `139412364242`: strict compile correctly rejected a possible numeric truncation from a four-digit source to a two-digit helper. Artifact `15050233584`, SHA-256 `e678a37c3b81b5d4408e7a27ba73a358459219c1d535890295b2e6df81634156`, ZIP CRC PASS. Widened the helper fields and copied only the rightmost one/two decimal digits.
4. Final source SHA `d05b92288d70ae4fd1659d3cd478c89b0a2f49cc`, run `45673818180`: 56/56 success, Native job success, exact artifact verified as above.

No expected-red was invented; no production source was changed.

## Scope boundary

Stage55 is the final bounded branch stage. No Stage56 is opened. The four QA51-B failure-injection paths remain NOT TESTED / NOT ACCEPTED: allocation denial/partial construction, valid-owner FREE-A failure, HEAP-LIVE service failure, and PATCHED-DISTANCE cleanup after subordinate failure. No failure injection, production change, main/protected-ref update, merge, release, or full-calendar integration was performed or claimed. `FULL_CALENDAR_INTEGRATION=NOT_YET_AVAILABLE`.

The acceptance applies to the tested source SHA above. This acceptance note and ledger update are a documentation-only child commit, made with `[skip ci]`; they do not alter the tested source or claim a Native run on the documentation commit.
