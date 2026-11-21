# Stage22 post-acceptance bounded static QA — Perl+國語 (2026-11-21)

PROJECT_ID: PC-BRANCH-PERL-GUOYU
Authorized branch: Perl+國語. Parent HEAD at review: bae9e3edbf7f06574e37853f01391e569da87195 (docs-only Stage22 acceptance).
Accepted **runtime source**: e28e6186c108b2ba2e2e7c4e5f32f778df33bd6a.
Producer: lib/Pastafari/Monster/WeavingPrimitive.pm, blob 4a7cd53e7132a6b3ab5fdaffd2d93a498e9296a6.
Projection: lib/Pastafari/Monster/MonthOccurrence.pm, blob bf77b36ccd2cb07d72527228ba951826abbbc8d1.
This review changes no executable producer, stage marker, scope, or acceptance.

## Previously accepted gates, separately verified
Canonical push run 44904659215 attempt1, completed/success, head_sha=e28e6186c108b2ba2e2e7c4e5f32f778df33bd6a; accepted review reports 23/23 mandatory completed/success and 146 skipped, with all 23 raw logs inspected. This review directly re-fetched run metadata, the dedicated Stage22 job log 136847546239, and GitHub artifact listing. Artifact 14708038426 current provider digest sha256:ddef2e09f29b460ad4e5ddf8de4f9bd74b79e2befbd1a83f37dfa388c3de66d8. Prior acceptance independently downloaded and CRC-verified that ZIP, including source lock and 1487045 TAP / 742900 ordinal comparisons. This post-acceptance review does not re-download or re-run those accepted jobs, and does not award any new Native, CI or differential PASS.

## Static invariants checked against the exact producer blob
1. For m=1..13 positive lengths and sum(length)<=52, reachable active labels form the interval (closed,opened]. The mixed-radix code is in [0, product(length[j]-1)-1] for each reachable interval. Beginning a length>1 month appends a zero high digit; advancing an active month adds its positional weight; closing the earliest active month strips its low digit. Length-1 months are opened and closed only while the active interval is empty, so zero-sized unreachable buckets cannot be indexed.
2. Offset ranges for distinct nonzero-size intervals are disjoint by additive prefix construction. The visited-bit offset equals the packed memo index, while each packed count occupies [32*index,32*index+31]. The terminal state uses the unique empty interval at (m,m).
3. The four base-10^12 limbs have 48 decimal digits of capacity. The independent Stage22 discovery bound for count cardinality is 41 digits. Each per-limb addition has at most one carry because both terms are already reduced modulo base; final d>=base is rejected.
4. _choices and _next_state enforce numeric lexical selection, monotone first/last appearances, cardinality and final length. Rank input Math::BigInt is copied before mutation; profile values are copied; unrank returns a fresh array. Boundary rejection remains at 14 months / 53 days. MonthOccurrence still has its separate 9-month / 36-day guard. These are code-path/static findings, not a new functional execution result.

## New independent exact arena geometry proof
For a month-length profile L[1..m], write y_i=L_i-1>=0 and sum(y)<=52-m. The allocated state count, including empty intervals, is

    C(L) = m+1 + sum_{1<=i<=j<=m} product_{k=i..j} y_k.

An independent DP (script qa/perl-guoyu/stage22_memo_capacity_static_qa.pl) maximizes this exactly. Let tail_i be the sum of products of nonempty intervals ending at i, and total_i the sum of all nonempty interval products up to i. Then tail_i=y_i*(1+tail_{i-1}) and total_i=total_{i-1}+tail_i. Enumerate integer budgets and prune a state only when another has both tail>= and total>=; every future transition with y>=0 is monotone, so this pruning is exact. The script uses no producer source or fixture, and checks the original interval formula on each maximizing witness.

Verified with local Perl 5.40.1: syntax exit 0, static script exit 0, all m=1..13 checked.
- All permitted m, lengths total <=52: maximum C=4,021,367, attained at m=12 and profile [3,4,4,5,5,5,5,5,5,4,4,3].
- Exactly m=13: maximum C=3,855,027, e.g. [3,4,4,4,4,4,5,5,4,4,4,4,3].
- Previously Native-benchmarked 13x4: C=3,587,219, so it was **not** the largest arena in the allowed domain.
- Maximum raw packed memory (32*C + ceil(C/8)): 129,186,415 bytes, i.e. approximately 123.20 MiB; no Perl object/runtime overhead is included.
- Maximum byte offset and state index are exactly representable by Perl's documented 64-bit integer environment. This is an allocation-size proof, NOT a worst-case runtime, RSS, time, or end-to-end memory verification.

## Findings and decision
No demonstrated production algorithm defect from this bounded static examination. **Coverage gap, not functional failure:** resource validation of 13x4 does not exercise the largest legal packed arena. The exact largest-memory witness has not been run through the accepted producer under resource limits. Two comments are stale: WeavingPrimitive.pm still calls accepted Stage22 a "production candidate", and MonthOccurrence.pm refers to the Stage21 12/48 bound for the producer. Documentation-only drift; unchanged to preserve the accepted source blob.

Stage22 remains accepted for the 13/52 weaving primitive only (LAST_COMPLETED_STAGE=22). The calendar/full-year generator remains UNVERIFIED. No Stage23, duplicate CI, main, merge or release.

NEXT (authorized Stage22 maintenance): perform one *new*, source-exact targeted resource and rank/unrank boundary check for the 12-month maximum-arena profile, with explicit Perl version, 120s/393216KiB per-process limits, exit/stderr/RSS evidence, and separate independent numeric/lexical checks. Do not call this Native PASS until the specific run, SHA and logs are examined; do not rerun accepted 13x4 or Catalan13 cases. A comment-only correction may follow after an evidence-preserving review, but does not change the accepted runtime source semantics.
