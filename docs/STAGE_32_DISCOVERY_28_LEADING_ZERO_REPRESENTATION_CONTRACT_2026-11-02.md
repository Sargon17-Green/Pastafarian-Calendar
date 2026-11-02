# Stage32 / DISCOVERY28 — 前导零文本等价与 9 位块归一化 (2026-11-02)

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Stage31 accepted prerequisite: SHA d204e33e3b009558990ee543ed739e7d88696a22, https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41524125855, 32/32 completed/success, Native 24/24 with measured post-free heap zero; job 125547363398, artifact https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41524125855/artifacts/13179964073.

## Hypothesis, inputs, outputs, independent oracle
The actual production path MONSTER-DISTANCE / DISTANCE-PATCH returns f(c,t)=|c-t|+1. The INIT-TEXT parser in src/big_integer.cob explicitly accepts leading zero digits before NORMALIZE-R. Stage32 holds each *numeric pair* fixed while changing *its text encoding*, checking normalization at 9-digit chunk boundaries. This is different from Stage31's affine changes to numeric values. No defect is presumed; expected-red is not declared without Native reproduction.

For n in {8,9,17,18,127,300}, set M=10^n, A=M-1, B=M-37. Signed pairs by n:
n=8 (-A,+B), n=9 (+A,+B), n=17 (-A,-B), n=18 (+A,-B), n=127 (+A,+B), n=300 (-A,+B).
Each numeric pair has four distinct signed *text* encodings: (1) canonical, (2) prepend 1 zero to c magnitude, (3) prepend 9 zeros to t magnitude, (4) prepend 18 zeros to both magnitudes. A leading sign remains before all zeros. Thus 24 distinct textual ordered pairs, only 6 underlying numeric pairs intentionally.

Independent closed-form decimal oracle: same signs => (M-1)-(M-37)+1=37; opposite signs => (M-1)+(M-37)+1=2M-37. Calculate by manual decimal-digit carry/borrow with no BigInt, and separately by JS BigInt abs(c-t)+1. Parse the *emitted COBOL source* to check every signed C/T literal and unsigned expected decimal against BigInt (24/24). Assert the three variant outputs equal the canonical result in each n-group (18/18 invariants). No code or oracle data copied from other language branches.

## Bounded gates
24 exact RUN-PAIR calls; input sign, chunk count and linked-list pointers may not mutate; output frees, input frees and measured HEAP-LIVE=0. Static verified 24/24 emitted literals, 18/18 invariants, 24 distinct textual pairs, max signed input 319<=320, expected max 301<=320, max COBOL source line 103<=115. Long literal chunks <=68 characters; no runtime random data.

Ubuntu 24.04 / GnuCOBOL 3.1.2, strict -Werror; compile <=300s, runtime <=120s, job <=20min; save evidence including failure. On exact push SHA require 33/33 completed/success including stage32-leading-zero-representation-discovery-native, and log:
STAGE32_RUNS=24
STAGE32_PASS=24
STAGE32_UNEXPECTED_FAILURES=0
STAGE32_HEAP_MEASURED=YES
STAGE32_HEAP_LIVE_POST_RELEASE=0
RESULT=PASS_STAGE32_LEADING_ZERO_REPRESENTATION_DISCOVERY_NATIVE
STAGE32_NATIVE_GATE=PASS
Static pass is not Native PASS. Do not modify production/main or merge/release; no full five-component calendar acceptance.
