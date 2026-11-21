# Lua Haitian — source-grounded year-selection to composition boundary audit
Date: 2026-11-21
PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Authorized branch: Lua+Kreyòl-ayisyen
Parent HEAD: 50c6d9ad4091a104eb34917c393e1d3f0a824b4b
Source lock: test/normative_oracle.lua Git blob 8fab731dff7011b1a4c3a241c5d1cdefef1c2f1d

## Static source findings
- Reference lines 416–442 select a year if there are >=6 gate gaps and 252<=length<=5778, without calculating months.
- Reference calendarDateIds lines 650–652 calls findTargetYear then buildYearStructure unconditionally; the latter calls bounded-composition unranking and month weaving at 562–569, without a prior resource preflight.
- Normative limit is 3..47 months of 4..123 days. The 16-month limit used in older specialized QA probes is an execution budget, NOT a calendar validity rule.
- Frozen heldout day -15017676 selects year interval (-15018117,-15012823], L=5294, gates 71..82, rank 56 of 69, on exact Native source SHA 4f9816f0ac3de0847f8c88237359848a41301484, run 44904821720, job 136848032736, artifact 14707099185. Only year-selection was Native tested.

## Independent falsifiable oracle and rejection policy
- Feasible normative month range: max(3,ceil(L/123)) .. min(47,floor(L/4)); for L=5294 it is 44..47.
- Ordered length vector count computed via inclusion-exclusion, independently of Lua's memoized dynamic programming, with constructive existence cross-check and exhaustive small-domain tests. All m=44..47 counts are positive. At m=44 exact count C(161,43). At m=43 there are zero solutions.
- Optional resource-bounded QA cap B=16: if minMonths>B, return RESOURCE_REJECT without calling composition, unranking or weaving. That is NOT a normative INVALID_YEAR result. If admitted, only the next resource gate is eligible; no guarantee of successful computation.
- QA-only Python script: test/lua_haitian_composition_boundary_oracle.py. Expected output 286/286 static checks, exact count report, no actual Lua, no composition, no full date. Source byte lock is enforced only when invoked with --check-source test/normative_oracle.lua; local run did not use this flag.
- Mutation checks include invalid years 251 and 5779, invalid budgets 0/48/-1, 43/44 boundary, spy counter on over-cap vs admissible path. No Stage56, main, merge, release or production semantics changed.

## CI context and limits
- Documentation-only HEAD 50c6d9ad had new run 44909908913 completed/failure; focused lua_haitian_real_year_interval_discovery job 136863317968 logged ABORT_CPU on 15th anchor (14 anchor lines), failure artifact 14709214383. Do not count as PASS or rerun unchanged. This is separate from prior heldout selection PASS.
- QA script was run independently on 2026-11-21: 286/286 checks PASS, sourceLock=NOT_CHECKED, no Lua Native or full-date claim. Static evidence and optional exact-source lock remain distinct.

NEXT: introduce a bounded QA adapter and instrument a pre-composition spy on the existing selected-year witness; verify the resource refusal occurs before the recursive composition and weaving methods. Do not modify canonical oracle, normative 47-month rule, or production selection merely to satisfy a 16-month QA budget.
