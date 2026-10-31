# Stage16 / DISCOVERY12 — 带符号零与前导零正规化 (DRAFT; NOT STARTED)
PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Date: 2026-10-31
Starting source: ce2caffedb0b9c994dc48211388d6c73d51cf0f9
Prerequisite: Stage15 strict Native CI must be rerun on the corrected, actually measured HEAP-LIVE assertion. Existing run 41211355528 confirms 30 arithmetic calls, but its heap marker was sourced from a constant-zero WS-HEAP variable; it is NOT valid proof of leak freedom. Stage16 remains NOT_STARTED pending that gate.

## Independent scope and rationale
No expected historical defect is alleged. Production MONSTER-DISTANCE/DISTANCE-PATCH computes d(c,t)=|t-c|+1. Unlike Stage15's alternating base-10^9 arithmetic chunks, Stage16 probes the textual BigInt input boundary: unary +, unary -, arbitrary leading zeros, and canonicalization of signed zero. The branch's own src/big_integer.cob PARSE-TEXT-INTO-R accepts optional leading +/- and strips high zero chunks before assigning sign; this is source-grounded, not a guessed requirement.

Six distinct magnitude anchors: A in {0, 1, 999999999, 1000000000, 10^54+1, 10^198-1}.
For each A, use four original inputs / independent mathematical outputs:
1. ("+000000000000"+A, "+"+A) => 1.
2. ("-000000000000"+A, "-"+A) => 1.
3. ("-000000000000"+A, "+"+A) => 2*A+1.
4. ("+000000000000"+A, "-000000000000000000") => A+1.
All 24 cases have been checked by JavaScript arbitrary-precision BigInt with an independent closed-form identity. Use hard-coded decimal oracle literals in the COBOL test source, not the producer's implementation nor fixtures from other branches. The zero anchor separately checks the literal "-0" normalization path. Maximum digit lengths are < 320 for all input and expected strings.

## Planned gates (only after Stage15 corrected heap proof)
- A new independent test/stage16_discovery_tests.cob with 24 calls, 24 exact decimal outputs; each action status 0 and PATCH03:DISTANCE-PATCH, no input mutation and output ownership release.
- Query BIG-INTEGER-SERVICE/HEAP-LIVE after all frees (not an initialized placeholder): expect 0 and explicit STAGE16_HEAP_MEASURED=YES.
- Strict GnuCOBOL 3 -Werror native compilation within 300s and execution within 120s; preservation of logs on failure.
- All 17/17 verify + Stage1–16 jobs completed/success on the exact branch SHA; STAGE16_RUNS=24, STAGE16_PASS=24, STAGE16_UNEXPECTED_FAILURES=0, STAGE16_HEAP_LIVE_POST_RELEASE=0, RESULT=PASS_STAGE16_SIGNED_ZERO_NORMALIZATION_DISCOVERY_NATIVE, STAGE16_NATIVE_GATE=PASS.
- On failure, reproduce actual input and examine logs before asserting defect or expected-red. No production change, merge, main mutation or generalized claim of five-field calendar completion.

## Preliminary oracle cross-check
Oracle generation (not Native tests): 24/24 independent mathematical identities agree with JavaScript BigInt |t-c|+1; no COBOL Stage16 execution was performed.
