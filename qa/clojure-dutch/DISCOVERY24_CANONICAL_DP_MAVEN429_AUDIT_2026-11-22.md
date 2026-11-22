# DISCOVERY24 canonical DP: pre-source Maven 429 audit (2026-11-22)

PROJECT_ID: PC-BRANCH-CLOJURE-DUTCH
Branch: Clojure+Nederlands
Inspected source: 009c052f8289cdc7b96f7276d8fbf77befc3b98f
Scope: TEST/QA ONLY; no production code or budget change.

## Completed exact-source evidence
- Automatic run https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44997360293, attempt 1, branch and head SHA verified.
- Canonical verify job 137131180108: completed SUCCESS.
- Isolated DP job 137131180406: completed FAILURE at step `Extract canonical profile and rank from independent normative oracle`.
- Raw error: Clojure dependency resolution failed for `org.clojure:clojure:pom:1.11.1`, Maven Central `repo1.maven.org` HTTP 429 Too Many Requests.
- The runner checked out 009c052f8289cdc7b96f7276d8fbf77befc3b98f and passed project/SHA identity. Failure occurred *before Clojure canonical input extraction*; no Python self-tests or canonical DP were run in this attempt.
- The following DP step was SKIPPED. The upload step ran but warned `No files were found`; run artifact listing is empty.
- Full Native stage02 job intentionally SKIPPED. No completed full Native PASS.
- This run does not test the 5288-digit parsing correction, does not establish DP_FEASIBILITY_UNPROVEN or DP_PROVEN, and does not establish a five-field date differential.

## Targeted workflow-only change
- Put the Python isolated QA preflight (`py_compile`, `--self-test`) before Java/Clojure classpath resolution; preserve stdout/stderr with exact project ID and `GITHUB_SHA` in `qa/clojure-dutch/discovery24_dp_python_selftest.log`.
- Preserve the preflight log in the existing canonical DP artifact upload even when Clojure dependency resolution fails. `pipefail` propagates a Python failure; nothing is green by default.
- Enable `actions/setup-java@v4` Maven dependency cache keyed to the existing `deps.edn`. Cache misses or remote HTTP 429 may still block Clojure; caching is not a success claim.
- Do not change the isolated Clojure extraction command, the DP Python input/result semantics, `LIMIT=5_000_000`, `search_budget=128N`, production code, API, or any existing Stage2 acceptance criteria.
- No automated retry loop and no endpoint cycling. Sonatype guidance says `repo.maven.apache.org` and `repo1.maven.org` are the same service and that repeated retries worsen aggregate HTTP 429 pressure: https://central.sonatype.org/faq/429-error/ and https://central.sonatype.org/faq/429-shared-egress/.

## Measurable acceptance contract
1. Verify exact commit and branch in newly triggered automatic run; no manual duplicate dispatch.
2. Python step must complete with `--self-test` checks and retained log stamped with exact project/SHA; this is Python QA only.
3. Canonical extraction must complete with independent normative-vs-production identity cross-check and emit canonical JSON; absent extraction remains PRE_SOURCE_DEPENDENCY_FAILURE.
4. A completed DP job with raw logs plus input/result JSON must be inspected. `DP_FEASIBILITY_UNPROVEN`/exit2 is bounded refusal only; `DP_PROVEN` still needs independent production-equivalent insertion-cost validation.
5. No p82/p520 numerical five-field acceptance, full Native PASS or Stage2 acceptance unless their separate real evidence exists. Legacy generic E2E remains 0/7.

NEXT: Inspect automatic exact-SHA run and retained Python preflight artifact first; if Maven 429 persists, classify infrastructure dependency and choose a non-repeat source-independent QA path. Preserve previous p81=4,995,675 vs proposed p82=5,002,652 accounting as LIMITED only, p1/p16 witnesses, unchanged budgets, Stage2 OPEN. No main/merge/publication/user-machine run.
