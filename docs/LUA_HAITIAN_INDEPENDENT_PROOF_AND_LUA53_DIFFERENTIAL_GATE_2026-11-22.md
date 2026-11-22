# Independent mathematical review and bounded Lua 5.3 differential gate (QA-only)

PROJECT_ID: PC-BRANCH-LUA-HAITIAN  
Branch: `Lua+Kreyòl-ayisyen`  
Reviewed source SHA: `43bc645a7f2f4bd30cc08a36f391f5c6444cc19a`  
Review date: 2026-11-22  
Scope: proof and executable-test contract only. This document does not implement, invoke, or accept the normative Lua weaving algorithm, chooseRankWide, calendarDate, fullDate, or Stage56.

## A. Fixed evidence; do not conflate gates

- Focused exact-Python job: [137342278080](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45066038674/job/137342278080), **completed/success** at the reviewed exact SHA. Job log records 43/43 counts, 290/290 prefixes, 122/122 lex-unranks, 12/12 Catalan, 10/10 guards, synthetic complete 47/5294 unrank for first/middle/last rank, and 47/5294 real-vector exact-count fingerprint.
- Evidence artifact [14771401518](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/45066038674/artifacts/14771401518): ZIP SHA-256 `aa7eda569bcce340e936ee7f9f491d824082ffd32f7addf484b5cb08abcaf2f1` agrees with upload log; all 5 ZIP members passed CRC; `manifest.txt` identifies the reviewed SHA and QA-only scope; `exit_code.txt=0`, `stderr.txt` empty; `stdout.txt` contains the required markers.
- Entire canonical run 45066038674 is **not accepted** merely because this job passed. In the inspected job listing, the separate `lua_haitian_real_year_interval_discovery` job 137342276209 had **completed/failure** with `ABORT_CPU` after 11 printed anchors of 15. Do not repeat that experiment without a new hypothesis/input and keep it separate from the exact-polynomial QA.
- Accepted prior sparse-prefix differential evidence: run 44996963044, job 137130036980, artifact 14744243018. That is not a real-vector Native exact-weaving differential.

## B. Independent source-level proof review

Let `n[0..m-1]` be integer multiplicities, each at least 2. A valid length-`L=sum(n)` multiset word requires increasing first-occurrence positions and increasing last-occurrence positions for labels 0,...,m-1. After a valid prefix, exhausted labels are `[0,b)`, active labels are `[b,a)` with remaining positive counts `r_i`, and unopened labels are `[a,m)`; this interval property follows from the two ordering constraints.

**Active-label interleaving lemma.** For `P_i=sum_{j=b}^i r_j`, the count of sequences of active labels whose final occurrences are increasing is

`A(b,a,r)=product_{i=b}^{a-1} C(P_i-1,r_i-1)`.

Induct on the last active label: to keep its final occurrence last, choose positions for its other `r_i-1` copies in the `P_i-1` preceding slots; the earlier active-label word has exactly the inductive number of arrangements. This proof does not use the Python implementation.

**Virtual-label recurrence.** Collapse active labels to a virtual label with `q=sum r_i` copies, retaining the exact multiplicative interleaving factor `A`. Define `T(a,q)` as the valid completions of this virtual label and unopened labels `a..m-1`, with increasing first and last appearances. Then

`T(m,q)=1`, `T(a,0)=T(a+1,n_a-1)`, and for `q>=1`:

`T(a,q)=T(a,q-1)+C(q+n_a-2,n_a-2)T(a+1,q+n_a-1)`.

The first term consumes the virtual label; the second opens the next label (forced by first-occurrence order), arranges its `n_a-2` interior copies before the last virtual-label occurrence, and then exposes its required final occurrence as part of a new virtual block. The two first-symbol alternatives are disjoint and exhaustive. Therefore the exact suffix count after a valid prefix is `A*T(a,q)`. At the empty prefix the total is `T(0,0)`.

**Lexicographic unrank check.** For active candidate `i` with `r_i>1`, the ratio of new to old active interleaving factors is

`((r_i-1)/(P_i-1)) * product_{j=i+1}^{a-1} ((P_j-r_j)/(P_j-1))`.

For `i=b,r_b=1`, the first factor is absent and b advances; any other final occurrence is forbidden. Opening the next label increases `A` by `C(q+n_a-2,n_a-2)`. Iterating legal next labels in ascending order and subtracting exact block sizes yields a one-based lexicographic unrank. Every selected block must be positive, and block totals must equal the current suffix count; a final complete word must leave rank 1 and zero counts. These identities are algebraic, not empirical claims of Lua Native equivalence.

**Finite independently enumerated witnesses.** For multiplicities (2,2), accepted words in rank order are `0011,0101`; for (3,2): `00011,00101,01001`; for (2,2,2): `001122,001212,010122,010212,012012`. They follow by explicit multiset-word enumeration and checking positions of first/last occurrences, not the virtual-label DP. These witnesses cover nontrivial separation of open/close constraints. Existing CI has broader independent small-domain enumeration.

**Complexity boundary.** DP *cell count* is `sum_{a=0}^m (1+sum_{i<a} n_i)`, capped at 180,000 in Python QA; the actual real vector used 128,668 cells. Big-integer bit-complexity and resident memory are not O(mL), and none of the proof implies Native Lua timing, address-space, or full-date feasibility.

## C. Next implementation gate: isolated resource-bounded Lua 5.3 differential

This is a design contract, **not an executed Native PASS**. Implement only under a QA/test namespace or reusable scoped workflow, leaving production and normative sources byte-identical.

1. **Inputs and source lock:** `PROJECT_ID`, branch, exact tested commit and per-file Git blobs. Small vectors with `m<=4, L<=12, each n_i>=2`; a frozen *attested* 47-element length vector with `sum(n)=5294`. For CSV serialization of the real length vector (no spaces, decimal, comma separated), SHA-256 is `9c623663a0d48455634df29749e1034a322a412a1898d7b24a77c2e29d708154`. Verify its provenance against completed Native job 136980280634 in run 44948262844, not merely against the Python script.
2. **Independent small oracle:** generate every distinct multiset word with recursion and no use of `T`, `A` or source Python fixtures; filter using ordered first/last positions, sort lexicographically, and independently compare Lua exact count, every valid prefix count, and rank 1/middle/last (including rejected zero/out-of-range ranks). Known tiny explicit witnesses in section B are hard anchors. Evaluate input, output, rejected cases and guard count separately.
3. **Lua big integers:** use a verified arbitrary-precision Lua 5.3 representation; never represent full counts or ranks in IEEE-754 `number` or a 64-bit integer. Validate decimal-string roundtrips, exact `divmod`/comparison on values crossing 2^53 and 2^63 before real-vector comparison; record which library/source blob was used.
4. **Large frozen oracle:** the 47-month / 5294-day exact count has 8,654 decimal digits, and SHA-256 over its unpadded ASCII decimal representation is `e3d498d39d6b4dfc401a85b8d9135ff1089a81ace85565ac5dcb123870c09f34`. Compare independently computed Lua count against this frozen fingerprint (not by invoking Python from Lua). For ranks 1, floor((N+1)/2), N, compare conditional lexicographic *96-label prefixes* and residual rank; retain full output only if bounded memory/time admits it. The real prefixes produced by Python must be independently locked as immutable fixtures with provenance before comparing; do not silently regenerate expected data inside the Lua implementation.
5. **Bounded resources / semantics:** separately record wall time, CPU time, peak RSS, number of DP cells and output size. Proposed initial QA envelope: wall <=120s, CPU <=110s, virtual-memory <=262144 KiB, no stdout truncation, maximum month count 47 and length 6000. Cap failures are `RESOURCE_UNSUPPORTED`, never `INVALID_CALENDAR_DATE`. Gate failure is not an expected-red success unless explicitly contracted, never silently convert an error into PASS.
6. **Evidence & acceptance:** one exact-SHA push-triggered or isolated reusable CI path, no duplicate dispatch. Capture stdout, stderr, exit code, `manifest.txt` with `PROJECT_ID`/SHA, source-locks, SHA-256 files, immutable expected witnesses, mutation-rejection results and the uploaded ZIP digest/CRC. PASS requires a completed focused job, zero exit, empty unexpected stderr, every exact assertion, resource-cap compliance and independently inspected artifact. Report independently (a) source-level review, (b) Python proof QA, (c) Lua Native small differential, (d) Lua Native real-vector count/prefix differential, and (e) normative full-date gate. None implies any other.

## D. Review disposition

**Source-level recurrence and lex block algebra: REVIEWED (static mathematical argument).** Python exact QA: **focused CI PASS at 43bc645a...**, artifact audited. No Lua Native exact-weaving differential, rank-wide selection, normative weaving, composition or fullDate was executed by this review. No Stage56, no main, merge, release, or policy change. NEXT: implement a small independent Lua 5.3 oracle adapter plus isolated big-integer feasibility probe according to section C, without re-running the already accepted Python exact QA on the unchanged SHA.
