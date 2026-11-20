# Lua+Kreyòl-ayisyen — accepted radius96 finite geometry and scoped new year5000 admission contract

Date: 2026-11-21  
PROJECT_ID: PC-BRANCH-LUA-HAITIAN  
Authorized branch: `Lua+Kreyòl-ayisyen`  
Evidence source commit (unchanged): `ce4d541029c5d81c9f9c185ff734da0ed1d7c18a`  
Scope: permanent QA evidence and design only. No new Native admission run is claimed by this document; no Stage56, production date/composition, main, merge, or release.

## 1. Native evidence accepted for the finite scan ONLY

- Canonical workflow run [44820267079](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44820267079): `completed/success`, exact source SHA, 93/93 jobs `completed/success`, run attempt 1.
- Focused Lua 5.3 job [136579040589](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44820267079/job/136579040589): `completed/success`.
- [Artifact 14670954537](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44820267079/artifacts/14670954537): `lua-haitian-gate-window-radius96-scan-only-evidence`; 6,295 bytes; SHA-256 `6e5aeec25cae0201e3181d652e63da0642196e39b414150a748c1fe80291cbca`.
- Inspected actual downloaded ZIP: 8 entries; all CRC-32 values verified by independent ZIP extraction. `source_sha.txt` equals the locked commit; `manifest.txt` matches project, run/job/artifact ancestry and `RADIUS96_GATE_WINDOW_SCAN_ONLY`; `exit_code.txt=0`; `stderr.txt` empty; `verifier_selftest.txt=9/9 PASS`; `verifier_result.txt=PASS gates/gaps/windows/min=193/192/187/1689`. SHA-256 list and every member CRC were inspected.
- Independent reconstruction from `stdout.txt`: 193 gate rows for [-96,96], 192 consecutive positive gaps (observed min/max 51/961, allowed 42..963), 187 six-gap windows, minimum length 1689, 64 new normative gap evaluations. The 129-row [-64,64] immutable seed's Git blob remains `95e77bc49a4c9e944bbac72b744ae0b3628043e5`.
- `SCAN_ONLY: YES`, `COMPOSITION_NOT_INVOKED: YES`, `YEAR5000=NOT_RUN`, `FULL_DATE=NOT_RUN`. This is NOT a full-date test, algorithmic differential admission, global negative, or Stage56 approval.

## 2. Exact five geometrically short six-gap windows

The necessary precondition is `252 <= G[i+6]-G[i] <= 16*123 = 1968`. This is NOT sufficient to establish that a selected year5000 interval is admissible.

| i..i+6 | G[i] | G[i+6] | days | Provenance |
| --- | ---: | ---: | ---: | --- |
| 36..42 | -15035001 | -15033050 | 1951 | In accepted radius64 core |
| 37..43 | -15034763 | -15032970 | 1793 | In accepted radius64 core |
| 38..44 | -15033996 | -15032302 | 1694 | In accepted radius64 core |
| 70..76 | -15018240 | -15016551 | 1689 | Newly discovered outside radius64 |
| 71..77 | -15018117 | -15016161 | 1956 | Newly discovered outside radius64 |

The accepted radius64 run 44800290037 / job 136510368350 already attempted six unique one-third/two-thirds target days in the three old windows: -15033432, -15032867, -15034166, -15033568, -15034351, -15033701. All six selected years were too long (minimum required months 34..41); `GATE_TARGET_ADMISSION_NONE: 0/6`. Do not rerun those samples without new grounds.

## 3. Contract for a SEPARATE prospective, bounded new-target static admission experiment (NOT yet implemented)

Purpose: sample ONLY the two newly observed short six-gap windows without duplicating old target samples. Produce four deterministic, distinct calculation days by integer floor thirds: `G[i]+floor((G[i+6]-G[i])*p/3)`, `p=1,2`.

| Probe | Window | fraction | calculationDay |
| --- | --- | --- | ---: |
| 1 | 70..76 | 1/3 | -15017677 |
| 2 | 70..76 | 2/3 | -15017114 |
| 3 | 71..77 | 1/3 | -15017465 |
| 4 | 71..77 | 2/3 | -15016813 |

**Inputs:** frozen `stdout.txt` of artifact 14670954537 and the pinned 129-row seed, both integrity-checked before admitting any candidate. The four target days must be recomputed independently from actual logged gate positions and checked against the prior six known targets; no hidden interpolation or extension outside the observed geometry. Frozen normative source blobs: `test/normative_oracle.lua=8fab731dff7011b1a4c3a241c5d1cdefef1c2f1d`, `src/bigint.lua=fcff58bcaaf8bb3f205e7a9c624a51069c0e5a5d`, `src/source_language_catalog.lua=5b59ee6bb0ea2c2a551185929b5531ea28a50e49`.

**Native operation, per target:** invoke only `O.year5000(calculationDay)` with an isolated reset gate cache and no month composition; capture selected open/close gate indices/days, year number, selected length and gap count, and whether the requested day lies in `(open,close]`. A selected interval may be longer or elsewhere than its seeding short window: never substitute the seed window for `O.year5000` selection. Validate `year=5000`, integral fields, `gaps>=6`, normative `252<=length<=5778`, and exact gate boundaries. For `length>1968`, emit `MIN_MONTHS_OVER_CAP` with `ceil(length/123)` and do not evaluate month-count sauce. For `length<=1968`, use the frozen pre-composition month-count selection `O.sauce(day,openGateDay+1)`, `O.askBowl(...,3,O.SEAL_MONTH_COUNT)`, `O.chooseRank`, with `minMonths=max(3,ceil(length/123))`, `maxMonths=min(47,floor(length/4))`, and the existing finite static state-bound formula. Record `ADMITTED` only if selected `monthCount<=16` AND upper state bound `<=20000`. Do not invoke `O.makeBoundedCompositionFamily`, `O.buildYearStructure`, month weaving, date facade, `O.calendarDate`, or full conversion. Treat errors or budget overruns as `ABORT`, never as a negative witness.

**Resource caps and execution:** maximum 4 distinct target days, one separate Lua process per target to prevent cross-target cache or CPU-budget ambiguity; at most 200 actual fresh gate-gap calls, 110 s Lua CPU, 120 s wall (+2 s kill grace), 128 MiB heap and 128 MiB process virtual memory PER process. Never increase a cap silently or use a previously accepted run as a substitute for new Native evidence. If one process aborts, preserve its partial stdout/stderr/exit and classify only that probe as unverified; do not report a completed 4/4 gate.

**Output per probe:** exact project ID, branch, run/job/source SHA, target ordinal, window i/j, target calculationDay, selected year/open/close/length/gaps/minimumMonths, selectedMonthCount and compositionStateUpper (or `NOT_COMPUTED`), categorical reason, gap calls, wall/CPU resource result, `COMPOSITION_NOT_INVOKED: YES`, `FULL_DATE=NOT_RUN`; an explicit `NO_YEAR_CANDIDATE` is allowed only when returned by the normative oracle. Summary reports each of four target statuses separately; `STATIC_ADMISSION_PASS` needs at least one complete selection and all admission checks, while `STATIC_ADMISSION_NONE` requires four completed negative selections. Other outcomes are `INCOMPLETE`, never PASS/NONE.

**Independent oracle / QA:** independent Python process reads the pinned radius96 transcript and new Native receipts; rebuilds G indices/gaps/windows and the four target days without importing Lua or copying the normative selection algorithm; validates all interval arithmetic, source locks, receipt order, uniqueness, previous-sample exclusion, selected boundaries against the attested G range (or marks out-of-range as unverified pending further bounded gate evidence), month arithmetic, state upper bound, and every marker. This structural checker is NOT an independent oracle for the normative stochastic year selection. Supply synthetic mutation selftests for wrong target, swapped target/window, duplicate sample, altered source SHA, fabricated admitted reason, missing output, invalid interval, and concealed budget exhaustion. A selection-outcome differential remains `NOT_VERIFIED` until a genuinely independent oracle exists.

**Acceptance evidence:** first produce implementation and selftests as a separate QA-only commit on this branch, with exact parent/readback. Native acceptance only after a completed GitHub run on exact HEAD, distinct focused jobs with verified source SHA/job/exit/stderr/stdout/caps, independent structural checker results, and retrievable ZIP(s) containing manifests, source hashes, stdout, stderr, exit codes and SHA-256 digests/CRC. No invented expected-red, no duplicate manual dispatch. This document alone is DESIGN COMPLETE / NEW TARGET NATIVE NOT_RUN.

## 4. Decision and boundaries

Two newly short windows at 70..76 and 71..77 justify the tightly scoped four-target admission design. Existing six negative selected years stay accepted as finite negatives, not global impossibility. A later admissible static witness would permit design of a separate composition differential gate only, not production date correctness or authorization for Stage56/main/merge/release. All four negative samples would justify recording exactly that finite negative outcome only. No user execution package is required for this design-only checkpoint. No deletion or cleanup of pending user execution packages is initiated.
