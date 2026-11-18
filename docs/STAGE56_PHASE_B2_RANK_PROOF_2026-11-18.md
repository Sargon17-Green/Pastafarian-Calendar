# Stage56 Phase B2 — bounded lexicographic rank proof, not provider acceptance

PROJECT_ID: PC-BRANCH-PHP-MALAY
Branch: PHP+Bahasa-Melayu
Predecessor: 2c24afaa27aca93c817ab26a1a023b0ef548efaf

## Verified predecessor (B1)

Canonical run 43959531429 completed/success, 28/28 jobs on predecessor SHA, including PHP 8.3.36/64-bit B1 job 133622896329. Native output: vectors=120, prefixes=18302, words=3940, rejected=6; 3/3 lint, exit=0, empty stderr, 512MiB/900s. B1 artifact 14274605536, PROJECT_ID/SHA exact, ZIP CRC PASS, sha256:d28802a9bada4b977ee5e505f3199e9657f62186627384cf2144b1af76e07170.

## Proof-only rank semantics

For each residual prefix, legal next IDs are 1..opened+1 with nonzero count, excluding an ID's final occurrence while any earlier ID remains active. This is independent of production's suffix insertion recurrence, but uses that exact BigInt countSuffix as a black-box block cardinality. In ascending ID order, the rank of a word is 1 plus all lexicographically preceding valid completion block sizes. Unrank subtracts entire blocks until the 1-based index falls into a block. Each prefix maps to a disjoint partition of valid completions; induction on remaining length proves rank/unrank mutual inversion, assuming B1 suffix-count correctness.

The test-only PHP file repeats neither B1's insertion recurrence nor the independent DFS generator. It loads the latter as an independent order oracle. It checks 120 vectors and 3,940 complete words exhaustively in both directions, 360 rank exceptions for 0, -1 and N+1, five invalid words/counts, and two genuine BigInt rank roundtrips for eight symbols repeated six times. Source inputs are never mutated.

## Explicit nonacceptance and performance

This is a correctness baseline only, not an efficient production algorithm. Every candidate invokes countSuffix from scratch. Worst-case arithmetic-operation upper bound is O(m^2 L^2), with m<=47 and L<=5778; this is not justified to satisfy the 512MiB/900s actual-year acceptance gate. No year-structure provider or PATCH22/PATCH23 integration is added, and Stage56 remains in progress.

The new exact-SHA B2 Native job requires PHP 8.3/64-bit, 4 lint, exact counters, exit=0, empty stderr, 512MiB/900s, and SHA-bound artifact. Its result is not assumed until completed logs and artifact readback.

## NEXT

Resolve new B2 CI and verify exact artifact. Then derive an incremental/reusable suffix frontier avoiding full recomputation for each candidate, prove its exact block cardinalities independently and profile with genuine year records 4999, 5000 and 5001 under the 512MiB/900s gate. Only after that integrate the production weaving ranker and validate provider behavior. Do not modify main or merge.
