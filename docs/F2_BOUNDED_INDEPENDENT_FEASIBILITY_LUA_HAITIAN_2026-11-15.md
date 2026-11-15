# F2 independent bounded feasibility — synthetic direct enumeration

PROJECT_ID: `PC-BRANCH-LUA-HAITIAN`  
Branch: `Lua+Kreyòl-ayisyen`  
Date: 2026-11-15  
Parent HEAD: `f2b2baec6d4af5e0692ab0f60c226fce21758c4a`  
Scope: **F2 synthetic-only**; no new Stage, production integration, merge, release, calendarDateSpaghetti, postStir12, or sixth field.

## Source locks and independent method

- Frozen normative source blob: `test/normative_oracle.lua` = `8fab731dff7011b1a4c3a241c5d1cdefef1c2f1d`.
- Frozen Kreyòl catalog blob: `src/source_language_catalog.lua` = `5b59ee6bb0ea2c2a551185929b5531ea28a50e49`.
- F1 contract blob: `docs/F0_NATIVE_ACCEPTANCE_F1_BOUNDED_INTERFACE_CONTRACT_LUA_HAITIAN_2026-11-07.md` = `74277716bf3822ee5728980f4bdebb331075bb19`.
- Checker: `test/lua_haitian_f2_independent_feasibility.cjs`; immutable hand-expectations: `test/lua_haitian_f2_fixtures.json`. Both self-contained, Node 20 standard library only.
- Algorithmic independence: enumerate every integer day in each synthetic half-open/closed year and assign its cutlet by a direct gate scan, never by partition-family unranking. Expand literal month run blocks into day IDs and verify total counts and first/last occurrence order, never by month-weaving counter, rank or unrank. Count month occurrences from day one for each queried day. Reference and production are **not imported**; only frozen catalog strings are data.

## Frozen 4/4 independent, hand-checkable witnesses

| ID | Year/gates | Target | Expected five fields | Hand check |
| --- | --- | ---: | --- | --- |
| A_OPEN_PLUS_ONE | 42, six 42-day gate gaps, (-300,-48] | -299 | `[42,"bwonz",1,"ajil",1]` | First permitted day; gate1; month1 |
| A_SECOND_CUTLET_END | 42, same | -216 | `[42,"rena",42,"ajil",80]` | Day 84; cutlet2 last; month1 = first 4 + 76 |
| A_RIGHT_CLOSED | 42, same | -48 | `[42,"kat pati sou nèf",42,"koud",84]` | Day 252 (included); cutlet6 last, month3 last |
| B_FOURTH_CUTLET_WEAVE | 43, seven 42-day gate gaps, (1000,1294] | 1127 | `[43,"Lagach",1,"Eridou",28]` | Day 127; cutlet4 first; month2 = opening 1 + 27 |

A: months lengths 84/84/84; weave runs `1x4,2x4,1x80,3x4,2x80,3x80`.  
B: months lengths 98/98/98; weave runs `1x1,2x1,3x1,1x97,2x97,3x97`.
First and final occurrences of each month are increasing by month ID, matching the *structural* order constraints. These fixtures are artificial, not outputs from the source calendar; matching them does **not** prove an actual reference-year tuple or real date conversion.

## Boundaries, resource rejection and independent preflight

- Input checks: safe integer year and gates, 6..17 cutlets, >=42 and <=963 days per gate gap, synthetic year between 252 and **512** days, month count 3..47, month lengths 4..123, distinct canonical indices, maximum 64 weave runs.
- Full coverage: 252 + 294 = **546** directly enumerated days, each assigned exactly one cutlet; every month occurrence is present exactly once at its day position.
- Five-field exact shape/types; exactly 4 frozen witness tuples; five negative/boundary checks (opening exclusive, after closing excluded, fractional day reject, illegal opening order reject, repeated cutlet-name index reject).
- Complexity: at most 512 days/structure, 17 cutlet comparisons/day, <=64 run blocks; two fixtures, four witnesses, five negative checks; CI has a strict 60-second process timeout and 3-minute job limit. Unbounded reference-year date construction is **not** run.
- The normative `buildYearStructure` includes bounded-composition family counting and a memoized weaving counter on month counts up to 47. For the F0 witnessed 4244/4358-day years, these structures can be far larger than the fixed synthetic suite. No finite native timing evidence currently proves those compositions practical. F2 intentionally rejects such reference cases **before executing** them; this is a scope guard, not an observed timeout or claim of mathematical impossibility.

## Verification states

Pre-commit independent JavaScript core: **4/4 frozen tuples**, **546/546 daily coverage**, **5/5 negative checks**, with no normative or production import.  
Native GitHub Actions Node run: **NOT_VERIFIED until completed job/log, exit 0, empty stderr and evidence artifact are checked on the post-commit SHA**.  
Native Lua calendar-date integration: **NOT_RUN / NOT_IMPLEMENTED**.  
F0 reference-only 2/2 remains accepted separately; F1 is design frozen; Stage55 remains accepted only for its original bounded scope.

Next after F2 gate: inspect completed F2 CI evidence; if green, assess bounded reference-year month composition feasibility with a separate controlled resource budget and determine which, if any, small actual reference-year date witnesses can safely be computed. Do not open Stage56 or attempt full date integration under this F2 task.
