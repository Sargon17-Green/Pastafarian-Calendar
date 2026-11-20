# Native Chapel median evidence design — research only, pre–Stage 6

Project PC-BRANCH-CHAPEL-UKRAINIAN. Research branch Chapel+Українська-мова; source baseline 4de36645da9ed5853c9a8627b5d41d3b602f7feb. Natural CI 44800564992 completed/failure with independent Native retained-prefix research PASS: 88 families, 42221 direct permutations, 331 words, 662 rank/unrank, 2698 prefix checks, 85 invalid-first checks, 2596 saved DP layers, wall 0.68 s / RSS 9900 KiB. Chapel Native Stages 1–5, DISCOVERY03, polynomial and canonical names passed. Separate legacy GateOracle exited 124 after 180 seconds: INCONCLUSIVE, not a native prefix failure.

## Inputs and two isolated phases

Exactly 45 months, 4244 total symbols; immutable length tuple in test/weaving_native_median_evidence_gate.py. Exact root has 22470 bits and unsigned big-endian SHA256 925c8a377ab6e61ed5d71f5ca7b7b5b184923308a0b7a27113bbd0085af0c5da. Target rank is floor(root/2), zero based.

1. Unrank: a separate Native Chapel 2.10.0 process computes the median complete word, residual zero, twelve exact prefix-count checkpoints. Write exactly one canonical comma-separated ASCII line plus newline to the witness file. Incomplete unrank must NOT authorize a rank run.
2. Reverse rank: a second isolated Native Chapel 2.10.0 process reads that exact witness and independently returns rank floor(root/2), with twelve checkpoints. It must not echo the input rank as a shortcut.

A previously independent GMP/FIFO full-year reference run established complete witness SHA256 over comma-delimited ASCII with NO newline: 06c6599cdb55601d2a0f2562150a558ac7bc5eae7805251d2007ee9a84c0b488. This fixed witness comparison is not Native evidence on its own.

Each Native process separately requires OS-enforced wall time <=180 seconds and peak RSS <=524288 KiB (512 MiB). CI must preserve the exact Git commit, binary SHA256, verified Chapel version and package digest, executable command, exit code 0, Ubuntu OS version, raw stdout/stderr, measured external wall/RSS, JSON result, and witness as artifacts. Timeout, OOM, partial computation, nonzero code, identity mismatch, missing output, or absent independent evidence MUST NOT be accepted as PASS. A resource exhaustion can be marked INCONCLUSIVE. Do not rerun accepted checks on the same SHA.

## JSON evidence schema and independent validator

Command:
python3 test/weaving_native_median_evidence_gate.py --verify --unrank-log PATH --rank-log PATH --word-file PATH --source-sha EXACT_GIT_SHA

Each phase emits exactly one JSON object with keys: schema=1, source_sha, direction (unrank/rank), chapel_version=2.10.0, status=COMPLETE, elapsed_seconds, peak_rss_kib, root_bits, root_sha256, median_rank (decimal string), residual (unrank "0", rank null), result_rank (unrank null, rank median decimal string), witness_sha256, checkpoints, stage6_acceptance=NOT_CLAIMED.

Each checkpoint is exactly {depth, prefix_sha256, count}. Ordered depths:
6, 16, 32, 64, 96, 128, 256, 512, 1024, 2048, 4096, 4244.
count is the precise decimal number of legal completions of that prefix; prefix_sha256 is the hash of canonical ASCII comma-separated prefix.

Independent verifier: positional (first/last occurrence) FIFO and multiplicities, complete witness identity, exact root bits and digest, and exact Python dense-prefix reference for all twelve checkpoints in each direction, 24 comparisons total. This Python implementation is separate from Chapel and its finite self-test directly enumerates unique permutations. In addition, external OS provenance is mandatory: a JSON record alone cannot prove native execution or resource measurements.

## Scope, limitations, and NEXT

This commit provides the actual executable JSON verifier with self-test (one positive and ten deliberately invalid evidence mutations) and an exact contract. The static self-test does NOT run Chapel and MUST print NATIVE_4244=NOT_TESTED. The current dense retained-state Chapel finite prototype has not demonstrated feasibility at 4244 symbols; the Native benchmark executable and OS-supervised runner do not yet exist. Next: design and implement sparse, memory-bounded, reverse-adjoint candidate-block enumeration in Native Chapel; verify a small independent positional oracle; then run the two isolated Native median directions under the above caps, preserve artifacts, and only then use --verify. The old GateOracle 180-second result remains separate and INCONCLUSIVE.

No Stage 6 acceptance, no production/src changes, and no main, merge, release, or publication.
