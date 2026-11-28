# Stage56 real-source-shape GMP rank/unrank qualification (QA only)

**Status:** isolated qualification experiment; not Stage56 acceptance, not a production change, and not a new project stage.

## Scope and branch isolation

This QA work is based on the exact PHP+Bahasa-Melayu source commit  fcaf1674d2c4125b6794fd37312f68d11aa2a8dd  (2026-11-28). It is placed on the isolated branch  PHP+Bahasa-Melayu-source-shape-qa  so that the existing branch's long Stage56 provider and external-reference jobs are not rerun. The existing Stage56 and audit jobs in  canonical-names-lock.yml  are conditioned on the exact branch  PHP+Bahasa-Melayu ; they therefore do not execute on this QA branch. A dedicated QA job is added to that existing workflow on this branch and is conditioned on the QA branch ref.

The QA branch is not merged to  PHP+Bahasa-Melayu ,  main , or any protected branch. Production PHP files, runtime dependencies, provider wiring, release policy, and Stage56 acceptance state are unchanged.

## Source evidence for the three length vectors

The source vectors were reconstructed from the original external QA artifact, not inferred from the earlier synthetic fixtures:

- Workflow run: 46142645805
- External-reference job: 140971780911
- Artifact: 15263468829 ( php-malay-stage56-external-qa.zip )
- ZIP SHA-256: 27f6de6de2ff525e32d5d5f7bc55ce41ebeae9d488212f5c07a6a74ee800b500
- The archive's  stage56-evidence-files.sha256  contains 80 entries; all 80 checks passed.

For each year, the profile's first complete DP run ( id=1 ,  start=0 ,  stop=month_count-1 ) contains every row width  q_i . Its terminal  end.cells  equals its  planned_cells . The length vector is reconstructed by:

\[
L_0=q_0,\qquad L_i=q_i-q_{i-1}+1\quad(i>0).
\]

| Year | Month IDs | Total symbols | DP cells (sum(q_0..q_{n-2})) | Maximum q_i | product(L_i+1) decimal digits | Vector SHA-256 |
|---:|---:|---:|---:|---:|---:|---|
| 4999 | 34 | 4,126 | 67,743 | 4,093 | 71 | a092a613e33081084cf685467877dc49c00f6a403826e6a9fa81159e25a7a95e |
| 5000 | 45 | 4,244 | 97,394 | 4,200 | 89 | 6d64022344c04935e6423aa6f96b285098d35b9b5ecb4b8c57a4c7149773a134 |
| 5001 | 46 | 5,567 | 124,263 | 5,522 | 96 | 7a6dfeded28c46b96de176bbe836802c7f80b03aaa2a614401991add6afcc7c6 |

The artifact's overall external-reference workflow did not pass. This qualification uses only the integrity-checked, completed initial DP row profiles to establish the real source shapes; it does not reinterpret that workflow as a successful real-year run or acceptance.

The fixture source  tools/stage56_gmp_qa/row_microgate.py , the year provider,  BigInt.php , and  MonthWeavingInterleaving56.php  are blob-locked by the gate. The three vector digests above are checked again at runtime.

## Independent feasible oracle

The prior direct memoized state space has size  product_i(L_i+1) , which is 71–96 decimal digits for these vectors. Expanding that oracle is not feasible and is not attempted.

The independent Python oracle instead uses an ordered-ending suffix recurrence. Let  F_i(q)  be the suffix count at the boundary where month IDs through  i  have been opened and  q  old active positions remain. With  m=L_{i+1} :

\[
F_{n-1}(q)=1,
\]

\[
F_i(q)=\sum_{r=0}^{q-1}
\binom{m+r-2}{r}\,F_{i+1}(m+r).
\]

For a valid non-empty prefix, let  low..high  be the active opened-ID interval,  R_i  the remaining multiplicities, and  A=sum(R_i)  over that interval. The independent completion oracle recomputes

\[
B=\prod_{i=low+1}^{high}
\binom{\left(\sum_{j=low}^{i}R_j\right)-1}{R_i-1},
\]

then returns  B * F_high(A+1)  when a later ID remains unopened, or  B  when  high  is the final ID. If the active interval is empty, the next unopened ID is forced and its suffix row is used directly. Invalid prefixes return zero.

This oracle uses Python arbitrary-precision integers and  math.comb ; it does not call the PHP candidate's branch-update helpers, GMP functions, or rank/unrank implementation. It recomputes the prefix base product from the remaining multiplicities rather than using the candidate's incremental ratios.

Before the real vectors, the oracle is checked by exhaustive multiset-permutation enumeration over 43 small length vectors (one to three IDs with counts 1–3, plus four four-ID cases): 342 legal words and 1,557 distinct prefixes. Every word's ordinal, every distinct prefix's completion count, and every full-word unrank are compared.

## GMP candidate and bounded samples

 source_shape_gmp_worker.php  is a standalone QA candidate. It uses GMP integers, incremental exact branch ratios, and a suffix-row cache with checkpoints every eight IDs. It retains at most eight unique live/stored DP rows; it does not retain a full suffix table. The worker is not wired into the production  MonthWeavingInterleaving56  class.

For each real vector, the gate compares candidate and oracle on:

1. Four deterministic root ranks:  2 ,  ceil(total_count/2) ,  total_count-1 , and  total_count , each unranked to a 32-symbol prefix and checked for residual rank and exact completion count. The first and last samples also run the candidate rank-prefix operation and must round-trip to the root rank.
2. Prefixes crossing row/checkpoint boundaries (including indices around 8, 16, 24, 32, and 40), checked for exact completion count. Their one-based rank-block start is independently fixed at 1 by their lexicographically minimal structure, which the worker validates explicitly.
3. Long prefixes leaving two occurrences per ID and one occurrence per ID, plus the full grouped word, each checked for exact completion count. The full grouped word has rank 1 by lexicographic minimality.
4. Negative prefixes (wrong first ID, skipped ID, and a later ID closed before a lower ID) and out-of-range ranks.

## Measurable resource gates

Each real-vector PHP worker is isolated under these limits:

- PHP  memory_limit : 512 MiB
- OS address-space limit: 512 MiB
- measured process RSS: at most 512 MiB
- watchdog and CPU limit: 180 seconds per vector
- maximum live/stored DP rows: 8
- cumulative rebuilt DP cells: at most 7 times that vector's planned DP cells

The overall GitHub job has a 20-minute timeout; the Python gate has a 12-minute watchdog. Missing GMP is  NOT_RUN  (exit 77); there is no non-GMP fallback. A failure or timeout is not converted to PASS.

## Interpretation

A successful run means only that the GMP rank/unrank candidate agrees with the independent oracle on the bounded real-source-shape prefix/rank samples, passes the small exhaustive cases, and stays within the stated resource gates.

It does not mean:

- a full real-year provider execution passed;
- a paired full-year performance comparison was run;
- the candidate demonstrated the required 20% end-to-end speedup;
- production integration or dependency approval was granted;
- Stage56 or the project as a whole was accepted.

No full-year provider run, paired full-year comparison, production source edit, dependency wiring, PATCH22/PATCH23, merge, main update, or publication is performed by this gate.
