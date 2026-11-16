# Stage40 / Discovery25 — calculation-year gate crossings under six seal values

PROJECT_ID: PC-BRANCH-POWERSHELL-TAGALOG
Branch: PowerShell+Tagalog
Predecessor exact-seal CI: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43769971528
Predecessor SHA: a03baf6f4f556d5982243345376511e8d89554ea
Status: CONTRACT + EXECUTABLE PREFLIGHT ONLY; Stage40 NOT ACTIVATED; Native outcome NOT YET ESTABLISHED.

## Independent research question

Stage39 covered ten seals on a 2x2 foundation/distant calculation-target grid. It did not test calculation days straddling normative year-5000 open/close gates. Stage40 probes whether the corrected date-derived First and Step stream continues to agree with the independent normative oracle across these calculation-day discontinuities. This is a bounded observational question, not an alleged historical bug or expected-red claim.

The year gates (O,C) and foundation F come independently from Get-NormYear5000 / Get-NormFoundationDay. Let D=F+36525 and M=Discovery01M. Build four calculation days [O-1,O,C,C+1], with two target days [F,D] and six legal seals [1,2,3,5,8,10]. Every (calculation day,target day,seal) endpoint instantiates a FRESH production context and independently calls Invoke-NormSauce and Get-NormAnswerStream with queried bowl ID 1. Do not derive expected answers from production, neighboring test results, Stage39 outputs, or another branch.

## Exact 425-assertion preflight budget

* Structural/predecessor invariants: 9. Require precise Stage39 evidence-sealed metadata with predecessor seals; preserve Stage26 expected-red; normative year=5000; O<F<=C; M>0; exactly four calculation days, two targets, six seals, four distinct calculation days.
* Endpoint comparisons: 4x2x6=48 independently materialized endpoints; for each, normative First and Step, First in [1,M], Step in {-1,+1}, 58 legacy writes, exactly one Patch12 invocation. 48x6=288 assertions.
* Year-gate seam comparisons: two directed calculation-day edges (O-1 -> O; C -> C+1), two fixed targets, six seals: 2x2x6=24 edges. Compare modular First displacement and Step-flip boolean against separately derived normative values: 24x2=48 assertions.
* Seal adjacency comparisons: eight calculation-target contexts and five neighboring selected seal pairs (1-2,2-3,3-5,5-8,8-10); modular First displacement and Step-flip boolean each: 8x5x2=80 assertions.
* Total: 9+288+48+80=425 assertions, zero tolerated failures. Expose counts for 48 endpoints, 24 boundary edges, 40 seal pairs and 425 assertions.

For signed BigInteger values normalize modular displacement as mod_M(x)=((x % M)+M)%M to avoid negative remainder. Boolean step flip is (Step_before != Step_after); compare derived values from production to those computed independently on the normative endpoints. Do not require nonzero displacement, flips or collisions unless observed; no inferred expected-red or probability/uniformity claim.

## Gates and evidence

Preflight requires the accepted Stage39 seal, with CURRENT_STAGE=LAST_COMPLETED_STAGE=39 and STAGE39_RUNTIME_VERIFICATION=EVIDENCE_ONLY_CONFIRMED, without changing stage metadata. Run on hosted Windows PowerShell 5.1 with exact GITHUB_SHA checkout and bounded 25-minute job; upload metadata, transcript, and stage state. Preflight Native success means only 425/425 bounded research checks on that SHA. Stage40 activation and later evidence-only seal each require their own subsequent exact-SHA Windows Native acceptance and predecessor rechecks. Production source, normative oracle, historical red, all previously accepted seals, and main must remain unchanged.

If any actual check fails, record the observed input and actual/expected values, diagnose the completed job log, and repair only the proven defect. A queued or in_progress run is neither PASS nor a material blocker.
