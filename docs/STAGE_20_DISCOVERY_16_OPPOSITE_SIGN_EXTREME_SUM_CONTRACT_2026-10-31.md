# Stage20 / DISCOVERY16 — 异号大数加法边界研究

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage19 exact SHA f9eb0ef7eaa9ac27b2574863ae108f378590c904, completed/success 20/20 CI jobs in run 41244346530, strict Native 24/24, measured heap zero.

## Objective and independent expected-value oracle

Stage19 studied cancellation of a nearly identical high-order prefix. Stage20 instead tests absolute subtraction across opposite signs, where the result requires summing two potentially 319-digit magnitudes and applying the extra +1 distance rule.

For each n ∈ {8, 9, 18, 27, 127, 318}, set A = 10^n and B = A-1. Construct four original ordered (c,t) pairs:
1. (+A, -A) => expected 2A+1.
2. (-A, +A) => expected 2A+1.
3. (+B, -A) => expected 2A.
4. (-A, +B) => expected 2A.

All 24 expected decimal outputs were checked twice: the independent JavaScript BigInt oracle abs(t-c)+1, and the closed-form expressions above; agreement 24/24, no shared production COBOL calculation. These fixtures are generated for this branch and do not import other branch tests. Pair ordering and exact signed strings are part of the fixed contract.

## Bounded execution and acceptance

- 24 COBOL RUN-PAIR calls via MONSTER-DISTANCE/DISTANCE-PATCH, exactly 24 textual oracle comparisons; input immutability (sign, chunks, head, tail), output-owned FREE-A guards, invalid status detection.
- 320-character input fields: signed max = 320 characters at n=318; expected decimal max = 319 digits. Each literal is broken into <=80-character MOVE fragments; COBOL source line length <230 characters.
- Real BIG-INTEGER-SERVICE/HEAP-LIVE call after freeing every operand/result; require status=0, measured=YES, zero live heap.
- Ubuntu 24.04 GnuCOBOL 3.1.2.0 strict -Werror, compile timeout 300s, execution timeout 120s, job timeout 20m. Preserve evidence artifact even on failure.
- Stage20 adds one CI job to 20 previously accepted jobs. Acceptance requires exact-sha 21/21 completed-success, STAGE20_RUNS=24, STAGE20_PASS=24, STAGE20_UNEXPECTED_FAILURES=0, STAGE20_HEAP_MEASURED=YES, STAGE20_HEAP_LIVE_POST_RELEASE=0, RESULT=PASS_STAGE20_OPPOSITE_SIGN_EXTREME_SUM_DISCOVERY_NATIVE, STAGE20_NATIVE_GATE=PASS.
- A failed probe is evidence for investigation, never automatically an asserted historical defect or expected-red. Do not claim overall calendar readiness, main merge, release, or Native PASS before completed/log.
