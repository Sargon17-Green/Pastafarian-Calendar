# Exact month weaving: experimental endpoint recurrence

Native run **39552537262** proved the old full-state DAG grows too quickly:
year 5000, 4244 days, 45 months, 32768 distinct states at day 16,
then the runner received a shutdown signal. This is no oracle mismatch.
Stages 1–53 and static Stage 54 were PASS in that run.

## State reduction proof (for counting only)

For a legally formed suffix, let **c** be the last closed month and
**o** be the last opened month. Its remaining copies are
r_(c+1), …, r_K. Month IDs c+1,…,o were opened earlier and therefore
need no further first-occurrence constraint; months o+1,…,K must first
appear in increasing ID order. All remaining months must have last
occurrences in increasing ID order.

Build a word by inserting r_i identical copies of month i into each
word for the preceding remaining IDs. Let N be the length of that old
word, f and l the first and last positions of the old largest ID, and
p and q the first and last positions of the new largest ID.

- Last-occurrence order: q >= l + r_i, because exactly r_i-1 new
  letters occur before position q.
- First-occurrence order, only when i > o+1: p > f, because no new
  letter occurs before p.
- For r_i >= 2, the r_i-2 interior copies occupy any of q-p-1 positions,
  giving C(q-p-1, r_i-2) choices.
- For r_i = 1, the sole copy satisfies p=q.

Let DP_i(p,q) be the number of exact words whose largest ID first
appears at p and last appears at q. Then for r_i >= 2:

    DP_i(p,q) = C(q-p-1,r_i-2) *
        SUM DP_(i-1)(f,l)
        over l<=q-r_i, and f<p if first-order is required.

If first-order is not required, there is no bound on f. For r_i=1
only p=q is legal and the same sum has l<=p-1. The sum is evaluated
using a two-dimensional cumulative sum, not enumeration of each
remaining-multiplicity vector.

The base case of one remaining month is one word, with first position
1 and last position r_(c+1). The empty suffix also has one completion.
Consequently the recurrence counts every and only legal suffix word
once, preserving distinct lexicographic words and arbitrary exact
integer counts.

This recurrence uses O(K*T*T) arithmetic for T remaining days and
O(T*T) working entries, rather than storing an exponential set of
remaining-multiplicity states. It does **not yet** provide practical
rank/unrank performance: retrieving a completion count for each child
on each of 4244 positions is a separate optimization problem.

## Independent validation gates

- Python exhaustive small-state reference checked all reachable suffix
  states for every length vector with 1..3 months and each length 1..3:
  PASS. Python is a design check, **not** MATLAB native evidence.
- MATLAB experimental implementation:
  `src/+pastafari/countWholeWeavingSuffixByEndpoints.m`.
- MATLAB tests:
  `tests/run_stage55_endpoint_counter_tests.m`, checking exact totals,
  invalid input, and reachable suffixes against a separate exhaustive
  recursive test oracle. Native MATLAB R2026a Update 5 CI run
  [39603046056](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39603046056)
  **PASS** at commit `801bc516dc517724fb912405e7e610b304a234a6`.
  Verified exact totals in 7 cases, **all 41 reachable small suffix states**
  in three additional families, and strict invalid-input handling.
  Observed markers: `STAGE_55_ENDPOINT_TOTALS_PASS CASES=7`,
  `STAGE_55_ENDPOINT_SUFFIX_EXHAUSTIVE_PASS STATES=41`,
  `STAGE_55_ENDPOINT_VALIDATION_PASS`,
  `STAGE_55_ENDPOINT_EXPERIMENTAL_PASS`.
  These are genuine native PASS results for the experimental *counter*,
  not for big-input runtime or production rank/unrank.
- Existing `WholeMonthWeavingFamily` remains unchanged and continues
  to define the published semantics.

Do not mark Stage 55 or the heavy differential PASS until both the
actual production calendar and independent normative oracle have
completed and their complete tuples matched.

## Native rank/unrank experiment — 2026-10-21

At commit `62630272b1e1b12b68d3a4d40229c1e87865ff32`, GitHub Actions
[run 39609688589](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39609688589)
completed with native MATLAB R2026a **PASS**. Markers:

- `STAGE_55_ENDPOINT_UNRANK_BRUTE_PASS CASES=9 RANKS=120`
- `STAGE_55_ENDPOINT_UNRANK_OLD_DAG_DIFFERENTIAL_PASS`
- `STAGE_55_ENDPOINT_UNRANK_VALIDATION_PASS`
- `STAGE_55_ENDPOINT_COUNT_BENCH DAYS=60 MONTHS=6 SECONDS=0.214 DIGITS=37`
- `STAGE_55_ENDPOINT_COUNT_BENCH DAYS=160 MONTHS=8 SECONDS=2.344 DIGITS=129`
- `STAGE_55_ENDPOINT_UNRANK_EXPERIMENTAL_PASS`

These are real but bounded CPU measurements, not a performance
extrapolation to 4,244 days. The experimental lexicographic unrank
calls the exact endpoint counter for every candidate suffix. Correctness
on small cases is established; this unoptimized repeated-count strategy
is likely too expensive for the largest full-year input. A future
incremental/rank-oriented method must be demonstrated separately before
production integration.

The expanded native test **PASSED** at commit
`f957d17bafac3ff7c11a32679318d3d4d3628f64`:
[GitHub Actions run 39610273306](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39610273306).

- `STAGE_55_ENDPOINT_UNRANK_BRUTE_PASS CASES=12 RANKS=1555`;
  **every** rank checked against independently generated lexicographic
  brute rows, including every rank of the 1301-row [4,4,4] family,
  plus additional 4-/5-month input families.
- `STAGE_55_ENDPOINT_UNRANK_OLD_DAG_DIFFERENTIAL_PASS`;
  each rank checked against the previously implemented production
  exact-DAG family for those small inputs.
- `STAGE_55_ENDPOINT_UNRANK_VALIDATION_PASS` and
  `STAGE_55_ENDPOINT_UNRANK_EXPERIMENTAL_PASS`.
- Bounded benchmark on this later runner:
  `DAYS=60 MONTHS=6 SECONDS=0.410 DIGITS=37` and
  `DAYS=160 MONTHS=8 SECONDS=4.639 DIGITS=129`.
  Execution time differs from the prior runner (0.214 and 2.344s);
  neither result is a promise about 4244-day performance.

These checks establish native correctness on the tested exhaustive
small cases, **not** proof of completeness or adequate runtime for the
large year. The original production route has not been replaced.

GitHub native Stage 55 push triggering intentionally excludes only
the two experimental source files and their dedicated unit tests, to
avoid repeated expensive known-failing full-year runs when iterating on
an unintegrated experiment. The complete native Stage 55 workflow still
runs for production and full-stage test modifications and remains
manually dispatchable; the heavy test has not been skipped or
weakened.

## Native factorized fast path — verified

Commit `3275776b2c6025f1b8d46c62dd89593806e96477`, native MATLAB R2026a
[run 39613757474](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39613757474)
**PASS**:

- `STAGE_55_ENDPOINT_FACTORIZATION_EXHAUSTIVE_PASS CASES=7`: legal suffix
  completions compared with a separate recursive brute oracle.
- `STAGE_55_ENDPOINT_ALL_OPEN_BENCH MONTHS=45 DAYS=180 SECONDS=0.024 DIGITS=212`.
- `STAGE_55_ENDPOINT_ALL_OPEN_BENCH MONTHS=45 DAYS=360 SECONDS=0.062 DIGITS=503`.
- The earlier 41 reachable-state exhaustive comparisons and 1555
  lexicographic-rank checks remained PASS.

Both speed measurements concern **already-opened** 45-month suffixes, not
full-year year-structure selection, or the full heavy differential. No
production replacement or Stage55 completion is implied.

The next *experimental* benchmark now also runs the factorized all-open
frontier on **45 months x 94 remaining days = 4,230 remaining days** (similar
in size to the 4,244-day blocked year, but a different state frontier).
Record actual native timing and output digits; do not infer its result from
small-case benchmarks. All months were opened before the suffix in this
test, and nothing is omitted from the resulting exact count.


## Exact all-open child block recurrence (unranking optimization)

This section documents the experimental implementation
`src/+pastafari/allOpenedWholeWeaveChildCounts.m`, introduced by
commit `08f3138e7037f11d2c19542ff1c6e6383b6626d2`.
It is **not** an approved production replacement. A source-only parser
fix followed in commit `61359b7fbd8d610e10118464146750d8bb917483`.

For an all-open frontier with closed prefix `c`, let
`r=(r_1,...,r_m)` be the positive counts for unclosed months, and
`S_i=r_1+...+r_i`. Every legal suffix closes the remaining months in
ascending ID order. The exact suffix count is:

```text
F(r) = product(i=2..m) C(S_i-1, r_i-1).
```

For the lexicographic next choice, an already-open month `i>1`
cannot close before month 1, so `i>1` is legal precisely when
`r_i>1`. Month 1 is always legal. Partitioning the parent suffixes
by their first letter gives exact **child completion counts**:

```text
B_1 = F(r) * product(j=2..m) S_(j-1)/(S_j-1)

B_i = F(r) * (r_i-1)/(S_i-1) *
      product(j=i+1..m) S_(j-1)/(S_j-1), for i>1 and r_i>1

B_i = 0, for i>1 and r_i=1
sum(i=1..m) B_i = F(r).
```

These are integer identities because each `B_i` counts an exact
combinatorial block. The implementation performs only BigInt products
and checks exact division remainders, as well as the parent-partition
identity. Right-to-left cumulative rational products compute all
blocks without separate DP for each child.

The unranking experiment keeps the selected child count `B_i` as its
new parent count, avoiding repeat counts after the full set of months
has opened. Before that point it still uses the endpoint recurrence;
**this optimization alone does not solve the entire 4,244-day initial
frontier**. The associated native checks enumerate every legal child
of all small all-open frontiers, including closed prefixes, and compare
them to independent exact suffix counts. Another benchmark requests all
45 first-step child blocks for an all-open 4,230-day suffix, checking
their exact sum and reporting real duration.

The first native attempt, run `39622067568`, was blocked by a MATLAB
parser error at the parenthesized expression method call, not a proven
counterexample to the identity. The source was fixed to assign the
weighted numerator before invoking `floorDivMod`. The repaired
experimental code subsequently **PASSED** on MATLAB R2026a in
[run 39622404296](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39622404296)
at commit `ebe1d9a9f7e1b6dd16788e7c071cafa8a1aee6c8`.

Native evidence:
- `STAGE_55_ALL_OPEN_CHILD_BLOCKS_EXACT_PASS CASES=360 CHILDREN=972`;
  every legal next-letter block compared against independent exact
  suffix-count computations on all small frontiers.
- `STAGE_55_ALL_OPEN_CHILD_BLOCKS_BENCH MONTHS=45 DAYS=4230 SECONDS=2.150 DIGITS=6877`.
  The **entire next-choice block partition** of the 4,230-day all-open
  frontier was calculated in 2.150 seconds in this particular runner.
  The exact block sum was checked against the parent count.
- `STAGE_55_ALL_OPEN_CHILD_BLOCKS_PASS`,
  `STAGE_55_ENDPOINT_UNRANK_BRUTE_PASS CASES=12 RANKS=1555`,
  `STAGE_55_ENDPOINT_UNRANK_OLD_DAG_DIFFERENTIAL_PASS`,
  `STAGE_55_ENDPOINT_UNRANK_EXPERIMENTAL_PASS`.

The 4,230-day count itself took 1.529 seconds in that run, with
6,877 exact decimal digits. These results cover a **specific
already-opened frontier**. They do not demonstrate efficiency for
the original 4,244-day all-unopened state, and do not establish
production-oracle equivalence for the entire calendar.

The target gates are:

```text
STAGE_55_ALL_OPEN_CHILD_BLOCKS_EXACT_PASS
STAGE_55_ALL_OPEN_CHILD_BLOCKS_BENCH
STAGE_55_ALL_OPEN_CHILD_BLOCKS_PASS
STAGE_55_ENDPOINT_UNRANK_EXPERIMENTAL_PASS
```

No Stage 54 heavy differential or Stage 55 signoff follows merely
from these experimental markers.


## Odtwarzanie fragmentów i porównanie dróg licznikowych (2026-10-22)

Natywny MATLAB R2026a run
[39731783177](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39731783177)
zakończył się **PASS** na commit
`10c07638b8481c8034f750ed84472a0f1b895587`:

- `STAGE_55_ALL_OPEN_CHUNK_BRUTE_PASS FAMILIES=9 RANK_CHECKS=800 SEGMENTS=3098`.
  Fragmenty składane po wznowieniu dawały dokładnie te same leksykograficzne
  słowa co niezależny enumerator.
- `STAGE_55_ALL_OPEN_CHUNK_VALIDATION_PASS`.
- `STAGE_55_ALL_OPEN_CHUNK_BENCH MONTHS=45 DAYS=4230 STEPS=12 SECONDS=29.471 COUNT_DIGITS=6858 DONE=0`.
  To **tylko 12** z 4230 dni stanu z już otwartymi miesiącami.

Dalsza próba liczenia wszystkich wag przez osobne iloczyny współczynników
dwumianowych była **semantycznie poprawna** w natywnym run
[39761082346](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39761082346),
commit `15d236e2c9ab06983d24986d06715b2e1d09772f`:

- `STAGE_55_ALL_OPEN_FACTOR_DIFFERENTIAL_PASS FRONTIERS=1089 CHILDREN=3645`;
- `STAGE_55_ALL_OPEN_FACTOR_BENCH MONTHS=45 DAYS=4230 OLD_SECONDS=1.643 FACTOR_SECONDS=3.641 DIGITS=6877`;
- `STAGE_55_ALL_OPEN_FACTOR_EXPERIMENTAL_PASS`.

**Wniosek wydajnościowy:** metoda osobnych współczynników była w tym
konkretnym biegu wolniejsza i nie zastąpiła metody historycznie
zweryfikowanej. Nie należy mylić PASS semantycznego z polepszeniem czasu.

Nowa niezależna próba `allOpenedWholeWeaveChildCountsCommonDenominator`
w commit `35f42e7d6ff42a748d2b97f97b0f771c693355e1` korzysta z jednego
wspólnego mianownika \(D\) i dokładnego \(g=\gcd(F,D)\).
Każda liczba bloków ma postać \(B_i=F\,N_i/D\).
Ponieważ \(B_i\) jest liczbą całkowitą i
\(\gcd(F/g,D/g)=1\), również \(D/g\) dzieli \(N_i\).
Można obliczyć \(F/g\) **raz**, a dla każdego dziecka wykonać podział
\(\left(N_i/(D/g)\right)\) na liczbach znacznie krótszych niż \(F\).
Testy obejmują różnicę z dwiema niezależnymi zatwierdzonymi formułami,
1089 małych frontów oraz pełne 45 miesięcy / 4230 dni.

Run [39761828541](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39761828541)
zakończył się **PASS** na commit
`35f42e7d6ff42a748d2b97f97b0f771c693355e1`. Potwierdzono:
- `STAGE_55_ALL_OPEN_COMMON_DIFFERENTIAL_PASS FRONTIERS=1089 CHILDREN=3645`;
- `STAGE_55_ALL_OPEN_COMMON_VALIDATION_PASS`;
- `STAGE_55_ALL_OPEN_COMMON_BENCH MONTHS=45 DAYS=4230 OLD_SECONDS=2.368 FACTOR_SECONDS=6.410 COMMON_SECONDS=0.276 DIGITS=6877`;
- `STAGE_55_ALL_OPEN_COMMON_EXPERIMENTAL_PASS`.

W tym samym biegu dla pojedynczego zestawu 45 bloków nastąpiło
**około 8,6-krotne** przyspieszenie względem uprzednio zweryfikowanej
metody. Nie jest to jeszcze miara pełnego unrank 4230 dni.
Nowy eksperyment w commit `51ac233bec03c901803f1cd52790b48770d7a63f`
porównuje kompletną procedurę wznawianych 12 kroków z oboma
licznikami; jej wyniku nie wolno domniemywać z tej liczby.

Wszystkie trzy liczniki nadal dotyczą stanu, w którym miesiące już
otwarto. Ani ich zgodność, ani wyniki wydajnościowe nie stanowią
ukończonego całorocznego przebiegu od pustego prefiksu, porównania
z niezależnym `normative_oracle`, ani bramki
`STAGE_55_FINAL_AUDIT_PASS`.

## Oddzielny pomiar trudnego stanu początkowego

Commit `b79fb107e3ed35d9818313d7bdbbc2366790225c` dodaje
`run_stage55_preopen_scaling_bench` z niezależnym workflow
[39762862661](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39762862661).
W przeciwieństwie do frontów z otwartymi już wszystkimi miesiącami,
sprawdza on **całe dokładne liczby legalnych przeplotów przy zerowym
prefiksie**, z 8, 12 i 16 nieotwartymi miesiącami po 20 dni
(160, 240, 320 dni). Każdy przypadek musi obliczyć pełną wartość
`BigInt`, opublikować czas i liczbę cyfr, bez zawężania stanów.
Run był w kolejce przy opracowaniu dokumentu; żaden wynik
`STAGE_55_PREOPEN_SCALING_PASS` nie został tu ogłoszony.
Dane posłużą do wyboru rozwiązania właściwego problemu roku 4244 dni.
Nie zastępują ani porównania z `normative_oracle`, ani
`STAGE_55_FINAL_AUDIT_PASS`.
