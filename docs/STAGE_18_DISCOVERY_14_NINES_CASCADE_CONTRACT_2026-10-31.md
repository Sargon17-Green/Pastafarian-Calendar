# Stage18 / DISCOVERY14 — 九串跨块借位与进位（原创有界测试）

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage17 on b646f160380e0a55894a4e51c70f51edcf1fc4ef, completed-success run 41230883461, 18/18 jobs, 24/24 tests, measured heap zero.

## Scope, input and independent oracle
Only the existing MONSTER-DISTANCE/DISTANCE-PATCH route is exercised; no production implementation is copied or modified. Let n in {8,9,18,27,90,318}, M=10^n-1 (n significant nines), N=10^n.
For each n, exactly four ORIGINAL source fixtures (c,t):
1. (+M,+N) expected 2, because |N-M|+1=2.
2. (+N,+M) expected 2, reverse symmetry.
3. (-M,+1) expected N+1.
4. (+1,-M) expected N+1, reverse symmetry.

Total 24 cases. The expected decimal values were checked independently using JavaScript BigInt: abs(BigInt(t)-BigInt(c))+1, then cross-checked against the displayed closed forms. No other implementation provides oracle values. Tests do not presuppose any defect. This is distinct from Stage17's leading-zero normalization: each nine is significant and the all-nines to power-of-ten transition crosses 10^9-limb boundaries. Max signed operand=320 bytes; max expected result=319 digits; all source literal segments <=100 bytes.

## Strict acceptance
- test/stage18_discovery_tests.cob: 24 original RUN-PAIR calls; status=0; message PATCH03:DISTANCE-PATCH; decimal equality to independent oracle; unchanged caller-owned input; output release.
- Actual BIG-INTEGER-SERVICE/HEAP-LIVE measured after releases, not an initialized constant; zero live at completion.
- Linux GnuCOBOL 3.1.2.0 strict -Werror, compile timeout 300s, executable timeout 120s, archived logs including failure.
- Prior 18 native/verify jobs plus Stage18 job: 19/19 completed/success on exact new SHA.
- Required markers: STAGE18_RUNS=24, STAGE18_PASS=24, STAGE18_UNEXPECTED_FAILURES=0, STAGE18_HEAP_MEASURED=YES, STAGE18_HEAP_LIVE_POST_RELEASE=0, RESULT=PASS_STAGE18_NINES_CASCADE_DISCOVERY_NATIVE, STAGE18_NATIVE_GATE=PASS.
- No PASS until completed/log evidence. No expected-red classification absent reproduced failure; no main, merge or completed-calendar claim.
