# Lua+Kreyòl-ayisyen: independent finite selection-identifiability countermodel (QA only)

- Date: 2026-11-21
- PROJECT_ID: `PC-BRANCH-LUA-HAITIAN`
- Branch: `Lua+Kreyòl-ayisyen`
- Audited branch HEAD before this change: `2da6b946b5280b46a67ff8a1d18963d7fab52359`
- Scope: QA-only standalone Python and this evidence note. No production Lua, workflow, Native execution, Stage56, calendar composition, main, merge, or release.

## Authenticated prior observations vs this test

Previously accepted [radius96 scan run 44820267079](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44820267079), artifact [14670954537](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44820267079/artifacts/14670954537), SHA256 `6e5aeec25cae0201e3181d652e63da0642196e39b414150a748c1fe80291cbca`, reports G[70]=-15018240 and G[76]=-15016551. Previously accepted [four-target run 44883988537](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44883988537), job [136785194889](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44883988537/job/136785194889), artifact [14698888975](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44883988537/artifacts/14698888975), SHA256 `adda0054dbaf4b897eb13adca0df131b75a04e4a7f93fa52ee27f9a748a824fd`, reports that `year5000(-15017677)` selected gates 66..76 of length 3630 and minimum 30 months. Current GitHub API readback independently confirms run `completed/success` on `139c01b634c856bb79611cbf15493942870971d6`, focused job `completed/success`, all 94 jobs completed successfully, and named artifact digest; focused job log explicitly contains `FOUR_TARGET_INDEPENDENT_VERIFIER: PASS complete=4/4`, `STATIC_ADMISSION_NONE: 0/4`, and `SELECTION_DIFFERENTIAL: NOT_VERIFIED`.

The new Python script consumes **attested numeric excerpts**, not the ZIP bytes. It does **not** independently reauthenticate either ZIP nor independently implement the normative selection algorithm. It is independently written integer logic and deliberately distinguishes these levels of evidence.

## Falsifiable finite identifiability test

1. From G[76] and the accepted selected length, deduce G[66] = -15016551 - 3630 = -15020181. Thus an actually observed *long* interval `(G[66],G[76]]` includes all of the *short* geometric interval `(G[70],G[76]]`.
2. The short interval 70..76 has six gaps and 1,689 days; its necessary month minimum is `ceil(1689/123)=14`, while the observed 66..76 interval has ten gaps and 3,630 days, so `ceil(3630/123)=30>16`.
3. Select previously untested `-15017676`, distinct from all ten accepted negative samples and one day after the actual negative witness `-15017677`. Both intervals contain the new day. A **hypothetical** 14-month partition of the short interval exists because `13*123+90=1689`; an independent direct sum for 14 months yields a potential state upper bound of `12476<=20000`. This proves only *structural possibility*, not the actual stochastic month choice.
4. Define two abstract selector completions that agree with all ten *observed* outcomes but assign different structurally possible selected-year intervals to the new day: A selects 70..76; B selects 66..76. Such completions have different answers to the minimum-month screen at that day. The finite geometric observations cannot distinguish A from B. **This is an identifiability counterexample relative to the observed constraints, not proof that the normative `year5000` can actually produce either completion.**
5. The script rejects deliberate mutations to the selected length, geometric boundary, duplicate prior sample and reused target; it checks exact open-exclusive/close-inclusive semantics, the day/gap constraints, integer month minima and arithmetic state bound. Local execution yielded `INDEPENDENT_SELECTION_IDENTIFIABILITY_SELFTEST: 14/14 PASS` and deterministic JSON `REPORT_SHA256: 7e2ea65e5d3e37772c40f6847dca93a3bb4520be9964eb721729a36870236dc9`.

Run from the repository root: `python3 test/lua_haitian_selected_year_identifiability.py`. No external modules or network are required. The script does not claim that the hypothetical selector is consistent with any uninspected hidden algorithmic constraints; this is exactly why it cannot be used as a selection-outcome differential oracle.

## Gate decision and concrete NEXT contract

- **Static structural logic: PASS 14/14 locally.** This is a fresh local Python QA run, not a CI job and not a new Lua Native result.
- **Counterexample: finite data are insufficient to identify the actual selected-year interval at an untested day.** The existing radius96 4,768-unsampled-day set is not itself a new Native dispatch criterion. The abstract A/B model cannot be promoted to actual selection outcomes.
- **Independent selected-year differential: NOT_VERIFIED.** Composition: `NOT_INVOKED`; full date: `NOT_RUN`; Stage56: not opened.
- **Next authorized bounded design:** investigate an *algorithmically independent* implementation of the **year-selection decision** for one bounded day (e.g. the withheld `-15017676`) with frozen numeric primitives specified and reviewed independently of Lua. Must define explicit inputs (day, gate indices, rank/selection source), output selected open/close index, deterministic seed/oracle rationale, error/abort conditions, CPU/memory/gap caps, and a held-out comparison on the same exact SHA. Reject proposals that merely restate geometric membership, call Lua `O.year5000` as their "independent" oracle, or import normative fixtures/selection code. Do not dispatch a new Native test unless the independently justified selection hypothesis is genuinely discriminative and all ten accepted negative probes remain excluded. If no independent selection mechanism can be defined under existing source and bounds, record `DIFFERENTIAL_NOT_VERIFIED` rather than invent a PASS.

Status: **open/READY; independent selection differential NOT_VERIFIED; no further user authorization needed for QA-only work in this branch; no promotion to Stage56 or release.**
