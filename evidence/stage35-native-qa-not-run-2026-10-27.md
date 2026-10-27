# Stage 35 PATCH 17 — Native QA recheck (NOT_RUN)

PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Date (Asia/Jerusalem): 2026-10-27
Repository: Sargon17-Green/Pastafarian-Calendar
Branch: Lua+Kreyòl-ayisyen
Verified source HEAD before evidence write: febdf75f3af310d5cfcdc91098fb7bcf6ddc7b38
Source checkpoint: https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/febdf75f3af310d5cfcdc91098fb7bcf6ddc7b38
Source test runner: https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/febdf75f3af310d5cfcdc91098fb7bcf6ddc7b38/test/stage35_tests.lua
Source stage policy: https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/febdf75f3af310d5cfcdc91098fb7bcf6ddc7b38/DEVELOPMENT_STAGE.md

## What was actually verified

- Canonical Sheet: 'ענפים'!A12:K12 and 'יומן המשך'!A13:I13 both identify this project and request local-only Native QA at the above checkpoint.
- The GitHub branch HEAD matched the canonical checkpoint before this documentation-only write.
- DEVELOPMENT_STAGE.md records Stage 35 PATCH 17 with historical CI 64/64 PASS and Stage 35 complete. This is **historical evidence only**, **not a new QA result**.
- test/stage35_tests.lua dispatches the prior stage suite plus Stage 35 scope, positive, property, BigInt, fault, reentrancy, and real-stream tests.
- The available execution container has no Lua command-line interpreter (checks for lua, lua5.4, and luajit yielded no executable). A liblua5.4 shared library exists but is not an executable harness with the complete checkout.
- Direct repository checkout failed because DNS resolution for github.com was unavailable from the execution container.
- Two registered Desktop Commander devices were offline when checked, hence no authorized remote native runner was reachable.

## Execution result

**NOT_RUN** — No Stage 35 Native suite was executed in this attempt; no new PASS, FAIL, test-count or code-defect claim is made.

The missing prerequisite is a runnable Lua interpreter together with the complete checkout at the source SHA, in an authorized environment. Do not repeat the failed environment/remote discovery without a new fact (e.g., a device becoming online, a runtime becoming available, or working repository access).

## Single NEXT after release of the blocker

On an authorized online Native machine with the complete repository checkout at `febdf75f3af310d5cfcdc91098fb7bcf6ddc7b38`, run from the repository root:

```sh
lua test/stage35_tests.lua .
```

Capture stdout, stderr, exit status, interpreter version and the tested SHA in a persistent evidence file. Examine n=1 and n=32 boundaries, BigInt, fault injection, reentrancy, and the frontier path. Only a reproduced Native failure permits a targeted fix. Stage 36 remains **DEFERRED pending explicit authorization**; do not touch main, merge, or trigger new CI for this check.

This file records the environment limitation and verified preconditions. It does not alter the Stage 35 program or authorize a new stage.
