# Gate D: independent full-year inverse-lexicographic certificate

Project: PC-BRANCH-TYPESCRIPT-MARATHI / TypeScript+मराठी. Scope: test-only post-Stage55 Gate D, **not Stage56**. This does not change the five-component public API or production Native implementations.

## Independent mathematical method

For legal words with month lengths \(h_1,\dots,h_m\), first appearances and last appearances must each occur in increasing month-ID order. All ranks are exact, 1-based, lexicographic.

Define \(P_a(k)\) as the number of legal words on unopened IDs \(a,\dots,m\) with the **last occurrence of ID \(a\)** at position \(k\), counted from 1. For \(a=m\), \(P_m(h_m)=1\). Insert the \(h_a\) copies of new smallest ID \(a\) into a word on \(a+1,\dots,m\) whose first ID's final occurrence is at position \(k\). First \(a\) must be before first \(a+1\), and last \(a\) before last \(a+1\). If the last \(a\) lies after \(g\) existing symbols, \(0\le g<k\), its new position is \(h_a+g\), and the number of insertions is

- \(b(h,0)=1\);
- \(b(h,g)=\binom{h+g-2}{g}\) for \(g\ge1\).

Thus \(P_a(h_a+g)=b(h_a,g)\sum_{k>g}P_{a+1}(k)\). Prefix/suffix sums compute each \(P_a\) in linear space/time in the year length; no vector-of-remaining-counts recursion.

In a lex-prefix state, completed months form an initial segment, active months a consecutive segment, and unopened months the final segment. If active residual counts are \(r_i\), their legal final-order interleaving count is \(B=\prod_{j=closed}^{opened-1}\binom{\sum_{i=closed}^{j}r_i-1}{r_j-1}\). Writing \(S=\sum r_i\), the independent continuation count is \(B H(opened,S)\), where
\(H(a,S)=\sum_k P_a(k)\binom{S+k-1}{S}\);
when \(a=m\), \(H(m,S)=1\). The ranker traverses the **observed complete word**, adds counts only for smaller admissible next month IDs, and obtains its exact ordinal. It does not run a production rank/unrank function, read production suffix counters, or use a production ordinal as the expected answer. It evaluates the full word, not a few sampled prefixes.

The expected rank is separately calculated from the test-only normative Sauce, Bowl 4, Seal 32 answer stream and its independent exact-count range. Equal exact rank + full legal word implies the observed word is uniquely the lex-selected normative word, so every target position's month ID and prefix ordinal are thereby independently certified. The existing Gate D test still checks each of five public fields and measured Native witnesses; the independent certificate is cached per distinct \((c,\mathrm{year})\) rather than redoing a full-year rank for repeated target days.

## Checks and resource contract

- Test-only exhaustive equivalence against the existing small-state normative weavingFamily oracle on lengths (2,2,2), (4,4,4), (4,4,5): **5+1,301+3,101 = 4,407** full word ranks, and exact total counts.
- Six existing Gate D \((c,t)\) cases remain unchanged, including Year5000 day 239, exact year-close gate and adjacent year, 30 field checks.
- Three distinct full-year Sauce/length families independently rank-certified; 1-based rank must exactly match the independently selected answer-stream rank.
- Hard dimensions: at most 47 months, 5,778 days, 123 occurrences/month. Per independent family: <=6,000,000 scalar factor terms and <=300,000 branch/suffix queries. CI job has a 25-minute timeout; no exponential state enumeration.
- **Local algorithm-only preflight (not Native/CI acceptance):** exhaustive small families had zero mismatches. A synthetic 44-month/5,325-day legal word was ranked in about 31.4 seconds on the current worker, using 844 cached factors and 1,819,290 factor terms, with ~28,500-bit exact count and rank. This synthetic benchmark is not one of the six real Native cases.
- Gate D can be accepted **only** when GitHub Actions on the new exact HEAD completes all four jobs successfully, and the dedicated Gate D log contains both the existing six-pair marker and \`POST_STAGE55_GATE_D_INDEPENDENT_RANK_PASS pairs=6 components=30 smallExhaustive=4407 realFamilyCertificates=3 rankMismatches=0\`. Until then this document and committed tests are **not** evidence of final Gate D PASS.

No main change, merge, release or Stage56.
