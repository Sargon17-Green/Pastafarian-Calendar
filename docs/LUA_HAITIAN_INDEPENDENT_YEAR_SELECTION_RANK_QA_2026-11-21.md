# Lua+Kreyòl-ayisyen — bounded independent Python year-selection/rank QA

Date: 2026-11-21  
PROJECT_ID: `PC-BRANCH-LUA-HAITIAN`  
Authorized branch: `Lua+Kreyòl-ayisyen`  
Verified parent HEAD before this QA change: `01561f6d1eaea06b0a70acf60a1a30340e743c79`  
Reference specification in the **same branch**: `test/normative_oracle.lua`, frozen Git blob `8fab731dff7011b1a4c3a241c5d1cdefef1c2f1d`.  
New source: `test/lua_haitian_independent_rank_decision.py`, Git blob `a2d08aebd46fe2a135b3dbebf61b425204bcbe87`, local SHA-256 `c2fef8413dbed60d8fe9eeb71d046205985b60ef5cded483efa8636c352686ef`.

## Purpose and actual independent computation

The prior [selection-identifiability QA](https://github.com/Sargon17-Green/Pastafarian-Calendar/blob/01561f6d1eaea06b0a70acf60a1a30340e743c79/docs/LUA_HAITIAN_SELECTED_YEAR_IDENTIFIABILITY_2026-11-21.md) established that finite geometric membership alone cannot identify which year interval is selected. This follow-up **executes an independently authored Python integer model** of the documented deterministic seed/rank mechanism for the finite year-selection decision. The model does not invoke or import Lua, load another branch's code/fixtures, call the production facade, calculate month composition, or request a new Native job. Its mathematical specification is still drawn from the same audited normative source; independent *implementation* is not equivalent to an independently justified normative *specification*.

**Inputs:** integer calculation day, foundation day -15055671, 127-bit modular domain M=2^127-1, the published numeric weights/constants, the seal for year 5000, exact gate indices [-96,96], and the explicit candidate selection rule. **Algorithm:** independent Python built-in integers; generate 46 fixed five-element stone vectors; compute hidden/visible drops and bowl streams, including 12 post-stirs; derive rank from a one-based residue and bounded rejection; independently compute 192 gate gaps; enumerate year intervals containing the requested day and meeting 6+ gaps and length 252..5778; order candidates by (length, opening day) and select the zero-based candidate using the independently computed rank. The output records selected gate indices/days, candidate count, rank, length, minimum months, short-window candidate ranks, stream seed SHA-256 and direction.

**Bounds:** exactly 193 gate indices, at most 18,528 gate pairs, 20,000 rejection iterations per selection (abort, never a fake result), a checked 15-second wall limit; on POSIX, RLIMIT_CPU 20 seconds and RLIMIT_AS 192 MiB. All computations fail closed on source/anchor/fixture mismatch. No network, nonstandard dependency, or mutable input files.

## Executed static Python QA, provenance and interpretation

Command: `python3 test/lua_haitian_independent_rank_decision.py`. Local result: `STATIC_PYTHON_SELFTEST: 16/16 PASS`. Deterministic canonical JSON report SHA-256: `89fae158fad5cb09fb320cef76ef801855002422624bacc135cbe34785410caf`. Output tests include modular boundaries and rejection-domain checks; exactly 193 gates; 192 gaps within 42..963; seven independent gate-anchor comparisons; exactly five 6-gap short geometric gate pairs; exclusion of ten previously accepted negative days; and exact **4/4** independent selection comparisons with existing, previously completed Native receipts.

Prior historical evidence (NOT rerun): four-target Native [run 44883988537](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44883988537), focused [job 136785194889](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44883988537/job/136785194889), [artifact 14698888975](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44883988537/artifacts/14698888975), on source `139c01b634c856bb79611cbf15493942870971d6`. Independent selected-year results exactly reproduce those prior four data points:

| calculationDay | accepted Native selected indices | selected length | Python match |
| ---: | --- | ---: | --- |
| -15017677 | 66..76 | 3630 | MATCH |
| -15017114 | 73..81 | 3839 | MATCH |
| -15017465 | 72..84 | 5637 | MATCH |
| -15016813 | 66..75 | 3562 | MATCH |

**Falsifiable held-out prediction, not Native evidence:** For the previously untested day **-15017676**, the independent Python computation enumerates **69** finite candidate intervals, selects **rank 56**, gates **71..82** with **5294 days** and a **minimum of 44 months** (over the 16-month cap). The geometrically short intervals occupy ranks **1 and 2** in this candidate list. This prediction is distinct from the abstract A/B geometric countermodel and is an algorithmic selection discriminator. It is not a statement about a completed Native result; a genuine held-out Native comparison on a separately authorized exact SHA remains **NOT_RUN**, and the selected-year held-out differential remains **NOT_VERIFIED**. The 4/4 matches are only retrospectively validated historical samples; they do not establish universal equivalence.

## Acceptance boundaries and NEXT

- Code change: two QA-only files (this contract and independent Python); Lua production, canonical workflow, gate policies and stage status unchanged.
- Python static verification: **16/16 PASS**, historic Native comparison **4/4 MATCH**.
- Historical four-target Native: finite 0/4 admitted on its **original** source SHA; accepted separately, not rerun or upgraded.
- Current-HEAD CI: [run 44895772879](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44895772879) was `queued/conclusion=null` when checked on parent SHA `01561f6d...`; never present that as PASS.
- Held-out selected-year Native: **NOT_RUN**. Held-out differential: **NOT_VERIFIED**. Composition: **NOT_INVOKED**. Full date: **NOT_RUN**. No Stage56, main, merge or release.
- **NEXT:** verify completion/log/source SHA of the pending/current CI run; then, if a genuinely new Native comparison is wanted, design one narrow, source-locked **single-day** held-out `year5000(-15017676)` comparison against this frozen Python prediction, isolated with explicit CPU/wall/memory/gap caps, raw stdout/stderr/exit and retrievable artifacts, without repeating any of the ten previously accepted negative samples. A Python prediction alone cannot justify calling a new Native result PASS; a single-day mismatch must be investigated, never silently treated as expected-red. No month composition or promotion of release gates.

Project status: `פתוחה / READY`; nonproduction algorithmic QA advance; independent selected-year held-out differential `NOT_VERIFIED`.
