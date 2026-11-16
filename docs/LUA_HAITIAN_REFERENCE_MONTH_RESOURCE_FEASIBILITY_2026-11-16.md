# Lua/Kreyòl ayisyen — Reference month capacity preflight (2026-11-16)

PROJECT_ID: `PC-BRANCH-LUA-HAITIAN`  
Branch: `Lua+Kreyòl-ayisyen`  
Previous verified HEAD: `bab5ebcbfdc97c3e7d1bb1f617b6b80ad905e5aa`  
Scope: **bounded independent resource QA only** — NOT Stage56, F3 implementation, Lua native date integration, product PASS, merge or release.

## Prior gate (same source SHA)
[Canonical run 43938445803](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43938445803) is `completed/success` with **86/86 successful jobs**; F2's existing Node job is synthetic-only. F0 2/2 Native witnesses and F1 frozen design remain separate and narrower than complete date integration.

## Code inspected
`test/normative_oracle.lua` frozen blob `8fab731dff7011b1a4c3a241c5d1cdefef1c2f1d`. `makeBoundedCompositionFamily` memoizes `(remaining, slots)`, iterating month lengths 4..123. `makeWeavingCounter` memoizes `(remaining-vector, last-opened, last-closed)`; its keys encode every remaining length, and neither memo has a hard state cap or time guard. `buildYearStructure` calls both. **Do not directly invoke it on F0 year-length witnesses as a feasibility test.**

## Independent conservative screening

Preflight file: `test/lua_haitian_month_resource_gate.cjs`, Node.js, no Lua or normative import.

- F0 anchors are the **already accepted** two `year5000` interval witnesses: `calculationDay=-15055671`, length `4244`; and `calculationDay=-15043671`, length `4358`.
- Candidate month counts satisfy `ceil(L/123) <= m <= min(47,floor(L/4))` (plus normative minimum 3).
- An upper bound on dense composition memo states is `(L+1)*(m+1)`; this bounds potential **cached state coordinates**, not measured allocations. Each state has at most 120 possible month-length transitions.
- The rectangular count of remaining-length vectors for a fixed length assignment is `product(length_i+1)`. Extremal length assignments with the same sum give conservative minimum/maximum rectangular-space sizes. **Rectangular-space counts do not imply that all vectors are reachable or cached**; using them is a risk-screening policy, not a measured lower bound on runtime.
- Static admission limits (engineering policy, NOT normative constants): `m<=8`, dense composition potential `<=50,000`, rectangular vector potential `<=1,000,000`. Future runtime instrumentation must additionally stop at **20,000 cached states, 128 MiB heap and 60 seconds per case**, before invoking large compositions. These runtime caps are **specified, not yet implemented in the Lua oracle**.

| F0 calculationDay | year length | candidate months | composition state upper bounds | candidate profiles rejected |
| ---: | ---: | ---: | ---: | ---: |
| -15055671 | 4244 | 35..47 (13) | 152,820..203,760 | 13/13 |
| -15043671 | 4358 | 36..47 (12) | 161,283..209,232 | 12/12 |

Total: **25/25 rejected by this conservative screening policy**. This does **not** prove these years cannot be computed. It means no full-reference-month path has earned admission under an enforceable budget; do not launch an unbounded reference call or claim an actual timeout.

## Checks and evidence boundaries
Local Node v22 static test: **8/8 assertions PASS**, both F0 witnesses rejected **before any oracle callback** (2/2). The script tests the exact month ranges, rejection counts, skip guard, BigInt combinatorics, and invalid interval rejection. Source file SHA256: `b94c20942faeae755f1b22cef151286c3ca0c8d6fda957a1115e461006686b03`. No Lua native date execution, no actual month-length sampling, no measured Lua memo use, and no real reference-month witness.

## NEXT
Instrument a **separate, bounded, read-only** reference composition probe with explicit early state, heap, and wall-clock aborts (including memo state counts) before attempting any genuine small witness. Prefer an independently located short feasible year only after its interval selection is itself budgeted and evidenced. Preserve the existing F0/F1/F2 and Stage55 gates, keep `calendarDateSpaghetti` unimplemented, and do not open Stage56, change `main`, merge, or release.
