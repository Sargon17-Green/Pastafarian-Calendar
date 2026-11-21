# Lua+Kreyòl-ayisyen — finite four-target Native negative acceptance and archive audit

Date: 2026-11-21
PROJECT_ID: PC-BRANCH-LUA-HAITIAN
Authorized branch: `Lua+Kreyòl-ayisyen`
Checked source SHA: `139c01b634c856bb79611cbf15493942870971d6`
Scope: evidence and bounded QA planning only; not Stage56, production composition, full-date, differential approval, merge, main or release.

## 1. Completed CI / focused Native provenance

- Canonical [run 44883988537](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44883988537): completed/success, exact source SHA above, 94/94 jobs successful (full jobs API `per_page=100`, not the 30-job connector default).
- Reusable-workflow [job 136785194889](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44883988537/job/136785194889): completed/success on the same SHA; all seven substantive steps succeeded, including source locks, frozen radius96 retrieval, four isolated Lua 5.3 processes, and independent Python receipt/resource verification.
- [Artifact 14698888975](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44883988537/artifacts/14698888975), `lua-haitian-four-target-static-admission-evidence`, 15,722 bytes, ZIP SHA-256 `adda0054dbaf4b897eb13adca0df131b75a04e4a7f93fa52ee27f9a748a824fd`.
- Frozen [radius96 artifact 14670954537](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44820267079/artifacts/14670954537): nested ZIP SHA-256 `6e5aeec25cae0201e3181d652e63da0642196e39b414150a748c1fe80291cbca`, source SHA `ce4d541029c5d81c9f9c185ff734da0ed1d7c18a`.
- Log markers: `FOUR_TARGET_INDEPENDENT_SELFTEST: 10/10 PASS`; `FOUR_TARGET_PLAN_VERIFIED: 4/4`; `FOUR_TARGET_INDEPENDENT_VERIFIER: PASS complete=4/4`; `STATIC_ADMISSION_NONE: 0/4`; `SELECTION_DIFFERENTIAL: NOT_VERIFIED`.
- Independent read-only archive inspection of downloaded bytes: outer ZIP 38/38 CRC; 37/37 content SHA-256 entries match `SHA256SUMS.txt`; frozen ZIP 8/8 CRC; exact manifest/source SHA; all four receipt fields, plan rows, time, source SHA, exit=0 and empty stderr; comparison against summary.json passed. Three separately mutated archives (changed reason, exit code, target day) were all rejected by the audit checks. Local audit code SHA-256: `84595486b57f50c161eb60477dba871bf06b90e6b313e01cc18940ea8efe758e` (locally generated independent verifier, not committed to this repository); local result file SHA-256: `03dcfb60701f029bcde2ec789192c9f5e0b72423acd3fb71b4dd9457bd1f333c`. Only CI/ZIP records are project-side permanent execution evidence; local source must be retained separately for later re-execution.

## 2. Four bounded Native findings

| Probe | day | selected year indices | year length | minimum months = ceil(length/123) | gap calls | Lua CPU seconds | wall seconds | peak RSS KiB | disposition |
| --- | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 1 | -15017677 | 66..76 | 3630 | 30 | 85 | 57.854498 | 57.96 | 3928 | MIN_MONTHS_OVER_CAP |
| 2 | -15017114 | 73..81 | 3839 | 32 | 85 | 54.956767 | 55.06 | 3912 | MIN_MONTHS_OVER_CAP |
| 3 | -15017465 | 72..84 | 5637 | 46 | 85 | 54.908455 | 55.01 | 3936 | MIN_MONTHS_OVER_CAP |
| 4 | -15016813 | 66..75 | 3562 | 29 | 86 | 55.765732 | 55.87 | 3796 | MIN_MONTHS_OVER_CAP |

All chosen year bounds matched the frozen G index/day pairs independently; all four target days fall within their selected years. Caps held per process: <=200 fresh gap calls; <=110 s Lua CPU; <=120 s wall; <=128 MiB RSS and virtual-memory limit. All four stderr files are empty; all four exit codes 0. The resulting four **negative admissibility observations** are accepted for those exact days only.

The selected year is NOT the six-gap window used to generate the input day. A short generating window does not imply a short selected year, and `STATIC_ADMISSION_NONE` is not a software failure and not a global impossibility proof.

## 3. Independent finite geometry check and bounded NEXT

Rebuilt `G[-96..96]` from frozen `stdout.txt`, then enumerated every pair `a < b` satisfying `b-a >= 6` and `252 <= G[b]-G[a] <= 1968`. There are **exactly five pairs** inside this observed radius: 36..42 (1951), 37..43 (1793), 38..44 (1694), 70..76 (1689), 71..77 (1956). There are no qualifying 7+ gap intervals in this **finite, locked** scan. Each of the four target days lies inside both geometric intervals 70..76 and 71..77, but the normative `year5000` selected a different, longer interval in every case.

NEXT: avoid repeating any of ten previously completed negative target days (six old radius64, four new radius96). Prepare a **static, no-Lua, bounded candidate-domain audit** before contemplating more expensive Native probes: enumerate geometric year candidates exclusively from the 193 frozen gate positions, check day-in-interval relationships and already tested target coverage, and produce an explicit `POTENTIAL_GEOMETRIC_ONLY` or `NO_NEW_JUSTIFIED_TARGET` decision. Inputs: frozen ZIP digest above, accepted four-target ZIP digest above, prior six negative days, month cap 16. Outputs: immutable candidate list with gate indices/days, lengths, theoretical minimum-month bounds, existing sample exclusion, reproducible SHA and mutation checks. Independent oracle: direct integer arithmetic over attested gate rows (no Lua selection code and no untrusted interpolation). Limits: at most 193 attested gate rows and their finite pairs; no extension outside [-96,96], no changes to resource policy or existing year/month rules. Any later Lua Native experiment needs separately justified untested calculation days, per-target resource caps and independent outcome verification; none is authorized merely by this document.

Status: four-target **finite negative Native accepted**, `STATIC_ADMISSION=0/4`; structural verifier PASS, stochastic selection differential NOT_VERIFIED, composition NOT_INVOKED, FULL_DATE NOT_RUN. No new CI run, stage, merge, main or release is claimed by this evidence-only commit.
