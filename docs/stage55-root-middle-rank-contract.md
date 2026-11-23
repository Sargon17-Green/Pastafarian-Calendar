# Stage55 Year5000 — exact root-count and rank-policy gate

PROJECT_ID: PC-BRANCH-MATLAB-POLSKI
Authorized branch: MATLAB+Polski. Predecessor commit: f4871de21a599a4f57e6f2180f174a3cb66db54f.
This is an incremental bounded gate within Stage55; LAST_COMPLETED_STAGE=54 and no main/merge/release.

## Pinned input and policy

- Use only Git blob a1383b111a88203b0d652b8f0a0e9af1a8b75f25 at tests/fixtures/stage55_year5000_appendix_a_metadata.json.
- The vector is source-derived, NOT an independently reconstructed normative month-length oracle.
- Require 45 months, 4244 day occurrences, lengths 4..123, year=5000 and fixed first/last day boundaries.
- Legal words contain exactly L[j] copies of each label; first appearances strictly increase by label and last appearances strictly increase by label.
- Rank words by ascending lexicographic order of the full word, one-based. If T is the exact legal-word count, choose middle rank R=floor(T/2)+1. This deliberately resolves even-count ties toward the upper middle.

## Two exact count algorithms

1. Forward insertion with state = suffix length from the first copy of the current maximum label. New last copy must be last; new first copy must follow the former maximum's first copy. For r old characters after new first copy, interior choices equal C(r+m-2,m-2), weighted by the strict tail sum of old states with s>r.
2. Independently coded forward insertion with state = absolute position q of the previous maximum's first copy. For new first copy at p in [2,N+1], its eligible predecessor weight is sum(f[q],q<p), multiplied by C(N-p+m-1,m-2). The m=1 boundary is explicit.

Both integer algorithms must give the same entire exact decimal T, not matching floating-point approximations or a prefix. Exhaustive distinct-permutation oracles for 14 tiny families independently check both first/last constraints. Require T has 6765 digits and match SHA256 of the ASCII decimal count c0c08ac89c8faaaf589d1b3e076fe1e96405f2ad7172a15efa9d028fb43fb6f8. Require the ASCII decimal middle-rank SHA256 cd5ce4036fc8e99355a4bab5d48c3db473422083d035df5e0af25297be1be3b6.

## Output and acceptance

The Python script writes JSON with exact decimal count and rank as strings, source lock, fixture Git blob, count/rank hashes, negative scope flags, and 14 tiny controls; ASCII log, file digests, and artifact are retained by its exact-SHA CI workflow. Acceptance requires completed/success run and job, log markers, artifact and digest verification. queued/in_progress is not PASS. This is Python static/differential mathematics, NOT MATLAB R2026a Native or the normative calendar.

## After this gate

Independently unrank full length 4244 at this pinned rank and construct inverse-rank witness, confirm every prefix count/partition, check AFTER62 prefix, archive a full word JSON+SHA, invoke existing five-field Python oracle with --word-json, add native MATLAB two-pass production differential and negative boundaries, perform cross-engine soak, and only then consider Stage55 final. FIRST/LAST edge acceptance is not a substitute.
