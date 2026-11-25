# Stage7 — authorized default A restoration

PROJECT_ID: PC-BRANCH-DART-HEBREW. Explicit user approval 2026-11-25: restore A on Dart+עברית only, including QA and Native; no Stage8/main/merge/release.

Parent: b974c3753b18dd3a1bfe1aacec1756836616ccb2. Active planner must be byte-exact 1824e96d82e6b0ceb12da01ba33fa75a83204d2a (7677 bytes, historical A plus approved R2 optional trailing-call-comma hunk). Immutable B experiment remains at parent, blob cd3e0ad955938db6f5a554fe030168ad3efd3436; historical A/B snapshots remain intact. No algorithmic change beyond restoring the authorized A implementation.

The existing [stage7-r2-only] workflow selector runs normal regressions and isolated differential while skipping historical B performance promotion runs. The isolated job now asserts active HEAD A, reads B from the pinned parent, materializes B only in a disposable worktree, and checks exact bytes before and after formatting. The independent oracle, three domains (26/461/1301), 1788 ranks per variant, six invalid bounds, three immutable results and input preservation remain unchanged. Pub get before formatting, package config, zero changed/exit zero and analyze remain required. Stage7 profile checks A's rank-one factor and absence of B guard in the same assertion; all existing correctness coverage, four digest locks and bounded five-pair A-vs-legacy profiling remain. This is not the targeted B-vs-A promotion benchmark.

Acceptance requires new exact-SHA completed CI, Stage1/P14 clean format/analyze, Stage7 13259 checks and four baseline digests, differential artifact and regression jobs. Historical B [4,4,4] performance FAIL (2/5, median -9.308410%) remains unchanged; KEEP_A_DEFAULT. No new Native or Stage7 acceptance at commit authoring time.
