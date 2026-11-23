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


## Additional independent prefix-partition preflight — 2026-11-23 (not CI/Native acceptance)

For fixed lexicographic prefix P, let r[j] be the number of copies of
label j remaining and k the largest label whose first occurrence is already
in P (all labels 1..k were opened in order). A legal next label is an open
label with remaining copies, or label k+1, subject to the strict ascending
last-occurrence constraint (labels fully exhausted must form an initial
segment). Let N(P) count all legal completions of P. The partition invariant is

    N(P) = sum(N(P + [x]) for legal next symbol x).

An independent completion DP inserts labels in increasing order, forcing
each added label's last copy to be final in the suffix. Its state s is the
number of suffix characters beginning with that label's first copy.
When adding m>=2 copies and r old symbols will follow the new first copy,
the multiplicity is C(r+m-2,m-2). For labels at or before k+1, the first
copy can occur at any suffix position, because their global first-opening
condition was already satisfied in prefix P (for k+1 all earlier first
copies lie in P). Therefore weight is the sum of all preceding states.
For labels j>k+1, the first-opening condition remains within the suffix,
so weight is the strict previous tail sum over s>r. For m=1, the new
symbol is forced to the final position. The empty prefix uses the
ordinary ordered-first-occurrence rule. This DP is independently shaped
from the exact root-count script's state transition, and the code and
report are retained as separate LOCAL mathematical evidence.

Observed LOCAL evidence (no GitHub CI job for this gate has yet been accepted):
- Six tiny month-length families, 66 distinct feasible prefixes,
  brute-force enumeration vs completion DP and all next-symbol partitions: PASS.
- Year5000 source-derived 45-length fixture, total 4244 symbols: 4 full-length
  prefix partition probes at [], [1], [1,1], [1,2] verified by exact arithmetic.
- Full root decimal SHA256 c0c08ac89c8faaaf589d1b3e076fe1e96405f2ad7172a15efa9d028fb43fb6f8;
  one-based middle-rank decimal SHA256 cd5ce4036fc8e99355a4bab5d48c3db473422083d035df5e0af25297be1be3b6.
- Archive /QA_Artifacts/PC-BRANCH-MATLAB-POLSKI/Stage55_MATLAB_Polski_prefix_partition_local_20261123.zip;
  SHA256 aa0bb713ccff2ee3bfdd0ded2fbe6f6a5f9bfdbae77f6cf7f70de4011d939b79;
  original and library readback byte-identical.
- Attempt at 12-symbol full middle-rank prefix unranking exceeded bounded
  runtime; NO middle-word prefix is accepted from that attempt. The report
  does not claim unranked symbols or MATLAB Native results.

Remaining authorized work: confirm a completed exact-SHA CI run of the
root dual-counter workflow (run/job/log/JSON/ZIP SHA), optimize or rework
full canonical middle-rank unranking to meet bounded-runtime criteria,
verify its inverse lexicographic rank, partition and AFTER62 prefix, produce
word JSON+SHA and five-field Python/MATLAB differential, then cross-engine
soak and Stage55 final audit. Stage55 remains OPEN; LAST_COMPLETED_STAGE=54.
No main/merge/release.
