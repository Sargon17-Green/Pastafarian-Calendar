# ਪੜਾਅ 2 / DISCOVERY 01

Normative: `BI_Save(x) = 1 + ((x - 1) mod M)` with `M=2^127-1`.
Intentional legacy bug: `oldRemainder(x) = BI_RegularMod(x, BI_M)`.

| x | Normative | Legacy | Contract |
|---|---|---|---|
| M | M | 0 | expected FAIL |
| 2M | M | 0 | expected FAIL |
| 3M | M | 0 | expected FAIL |
| M+1 | 1 | 1 | PASS |

`CalendarSpaghettiDiscovery01Remainder` uses invocation-local context and the production legacy helper.
`calendarDateSpaghetti` touches the legacy helper but does not yet produce five canonical components; it raises `E_STAGE_02_DISCOVERY_ONLY`.
Oracle and `BI_Save` remain unchanged. No `savePatch` until Stage 3 / PATCH 01.
Stage 2 Native requires 144 baseline individual PASS + one control PASS + exactly three expected FAIL; `OVERALL=FAIL`, `FAILURES=3`.
Do not claim Native PASS before CI run/artifact verification.
