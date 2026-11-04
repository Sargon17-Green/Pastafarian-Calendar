# Stage3 — correction of DISCOVERY01 SAVE semantics (2026-11-04)

Project: PC-BRANCH-BASIC-PUNJABI (BASIC+ਪੰਜਾਬੀ)

## Proven baseline
- Parent source commit: `42c06edcb967add68f66a9a9373e47d074feb703`.
- Stage2 v17 native result accepted: **145 PASS + 3 expected RED**.
- Failing identifiers: `DISCOVERY_01_M`, `DISCOVERY_01_2M`, `DISCOVERY_01_3M`; `DISCOVERY_01_M_PLUS_1` was PASS.
- Do not repeat Stage2 or depend on the vanished v17 workspace or the physical identity of D:.

## Narrow production correction
- `BI_RegularMod(x, BI_M)` returns **0** for `x ∈ {M, 2M, 3M}`.
- Normative `BI_Save(x) = 1 + ((x - 1) mod M)` returns **M** for those inputs and **1** for `M+1`.
- `CalendarSpaghetti.oldRemainder` retains its public legacy symbol for compatibility but delegates to `BI_Save(x)`.
- `CalendarSpaghettiStage()` becomes 3. No change to `BigInt.xba`, the 17 cutlets, 47 months, or the pinned Catalog lock.
- `calendarDateSpaghetti` still deliberately raises `E_STAGE_02_DISCOVERY_ONLY` because the five-date-result engine is incomplete; this change does **not** claim full calendar functionality.

## Acceptance gate
- 148 individual distinct `PASS` results, 0 `FAIL`, `OVERALL=PASS` from actual LibreOffice/UNO execution.
- The original 145 individual PASS controls remain intact, adjusted only for the stage marker from 2 to 3.
- An ephemeral, isolated CI LibreOffice user profile is created from scratch; no historical disk/workspace access or cleanup retry.
- Static contract and code review do not substitute for completed native CI logs.
- Until native CI is completed and evidence inspected, Stage3 status is **CANDIDATE**, not ACCEPTED.

No main, merge or publish.
