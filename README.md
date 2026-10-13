# The Pastafarian Calendar, in Plain English

## A special branch

This branch is deliberately different from the other language branches in this project.

The most important rule here is that an ordinary reader should be able to understand the work. Clear writing is more important than clever tricks. There is no spaghetti-code rule, no 55-step schedule, and no requirement to follow the other branches' development rules.

Every instruction intended for a computer in this branch must be written in **Plain English Programming**. That means the Plain English language used by the CAL compiler, not merely text that looks like English. Explanations, this README, and the license are written for human readers, in ordinary English. No scripts in another programming language, build instructions written as shell commands, or workflow files belong in this branch.

The other branches have their own rules. This branch does not change them.

## What has been written so far

The file **source/the calendar** takes two calendar-day positions and computes the
five starting counters. It runs a sequence of checks, stops at the first
failure, and writes the result to **calendar-checks.txt**.

All files containing program instructions have no filename extension and are
written in Plain English Programming:

- **wide numbers**: exact decimal-string arithmetic for nonnegative integers,
  including comparison, addition, subtraction, multiplication, remainder,
  and the sauce's SAVE operation. It also handles signed *differences*
  between two already-saved values.
- **the arithmetic checks**: checks long arithmetic and modulus boundaries.
- **the five stones**: grows all 46 rows of five stones, calculating each
  new row entirely from the old row.
- **the stone checks**: checks all five stones at rows 1, 2, 3, 7, and 46.
- **the hidden drops**: computes the seven hidden drops, each using its
  four coefficients, the five stones of the matching visible row, and
  seven grinding steps.
- **the hidden drop checks**: compares all seven Foundation-Day hidden drops
  with the exact numbers published in the original rules.
- **the visible drops**: computes up to 46 visible drops, preserving their
  preceding seven-drop history and performing all eleven grinding steps
  before advancing the history.
- **the visible drop checks**: checks the first and last Foundation-Day
  visible drops against the published exact results.
- **the bowl order** and **the bowl order checks**: select and test all
  six-bowl arrangements by lexicographic rank, including the original
  final-drop ordering [4,5,2,3,6,1].
- **the six bowls** and **the six bowl checks**: calculate and check the
  six independent starting bowl values using their fixed identities.
- **the bowl mixing** and **the bowl mixing checks**: calculate the three
  direct pours and all six new bowls from a single old-bowl snapshot for
  each of 46 drops; perform all twelve final mixes with the saved S value;
  preserve the final visible order for later queries. The checks compare
  the first mixed drop, the complete state after drop 46, and all six
  final bowls with independent canonical Foundation-Day values.
- **the sealed answers** and **the sealed answer checks**: use the bowls
  after the twelve final mixes and the remembered drop-46 circle to
  calculate A0, stream direction D, answer stepping, and exact narrow
  equal choice for 1 <= N <= M. Includes Foundation-Day seal vectors
  and exact rejection-boundary tests.
- **the wide choices** and **the wide choice checks**: build consecutive
  saved answers as base-M digits when the option count N exceeds M;
  select the smallest sufficient k, compute the exact rejection limit,
  and move on the finite M^k circle without approximations. Five
  reference cases check two- and three-digit values and both rejection
  directions; one more case checks the narrow/wide boundary.
- **the option safety checks**: ensure that public, narrow and wide
  equal-choice routines reject an empty or zero option count without
  reaching division by zero, and still accept a later valid choice.
- **the native day bounds** and **the native day bound checks**:
  check both input days before attempting full conversion. Until
  absolute day coordinates and all five initial counters have an
  arbitrary-precision implementation, each requested day must lie
  between -415055671 and 384944329, inclusive. This conservative
  temporary range keeps native 32-bit day counts, their sum and the
  inclusive distance within their representable limits. Checks also
  verify the exact even/odd counters, sum and inclusive distance at
  the two opposite extreme endpoints, without expensive gate scans.
  The low-level day-counter routine itself remains unrestricted and
  should only be used with inputs meeting this precondition.
- **the gate intervals** and **the gate interval checks**: calculate the
  interval selected by seal 1 in bowl 1 using the sauce made for
  (Foundation, Foundation+n), including negative n. Independent
  reference calculations give 345 days for n=1 and 503 for n=-1.
- **the gate walk**, **the gate walk checks** and **the gate
  budget checks**: start at gate zero, Foundation Day, and accumulate
  exact intervals in either direction. Signed gap ownership is handled
  across gate zero; index zero is not a gap identifier. A shared
  allowance of at most 1024 gate-gap computations per complete date
  search stops impractically distant scans without inventing an
  incomplete year or cutlet. This is a resource limit, not a date rule.
- **the year candidates** and **the year candidate checks**: check
  the eligibility and canonical ordering of pairs of year-boundary gates.
- **the year 5000**, **the year 5000 checks**, and **the year
  ranking checks**: enumerate eligible gate pairs around the
  calculation day, sort them by duration and earliest opening gate,
  and use bowl 1, seal 10 on the sauce for (c,c). Normal tests
  exercise an invented eleven-candidate ledger and reject invalid
  ranks, truncated lists and incorrectly included opening gates.
  A slow test compares Foundation against the canonical year bounds.
- **the year walk** and **the year walk checks**: calculate following and
  preceding years from their fixed shared gate, using seals 11 and 12
  with the original calculation day. The boundary oracle is a slow
  integration check, not a default test.
- **the year structure counts** and **the year structure checks**:
  prepare one sauce for (c, first day of year) and select the cutlet
  count with bowl 2/seal 20 and the month count with bowl 3/seal 30.
  Fast tests cover the exact count ranges and extreme year lengths.
- **the combination arithmetic** and **the combination checks**:
  divide decimal integers by small positive integers without losing
  remainder information, and calculate exact binomial coefficients.
- **the cutlet partitions** and **the cutlet partition checks**:
  count and unrank all positive gate-span compositions in
  lexicographic order. If the calculation day coincides with an
  internal gate, that gate is required as a cutlet boundary.
  Combinatorial counts replace infeasible brute-force enumeration.
- **the cutlet positions** and **the cutlet position checks**:
  locate the requested day within the selected cutlet, using actual
  variable-length gate intervals rather than assuming equal spans.
- **the cutlet names** and **the cutlet name checks**:
  choose K distinct names from the canonical 17 indices with
  bowl 5 and seal 22. The selected name index is not necessarily the
  ordinal position of its cutlet in the year.
- **the month lengths** and **the month length checks**:
  count exact ordered month lengths between 4 and 123 days, and
  unrank the lexicographic result chosen by bowl 3 and seal 31.
  Large counts are evaluated with bounded-composition
  inclusion/exclusion and exact arithmetic, without enumerating
  all month sequences. A separate optional check covers 47-month
  cases with very large combinatorial counts.
- **the month names** and **the month name checks**:
  select distinct month-name indices from 1..47 in lexicographic
  order, using the shared year sauce and bowl 5 / seal 33.
  Name indices differ from the ordinal position of a month in the
  year and can require wide equal-choice arithmetic.
- **the month weaving** and **the month weaving checks**:
  count exact suffixes by a memoized recurrence, enforcing both
  first-occurrence and last-occurrence order, then unrank a complete
  weaving with bowl 4 and seal 32. The requested day's month ordinal
  and its one-based occurrence in that month are recorded.
- **the weaving short suffixes**, **the weaving started suffixes**,
  and **the weaving shortcut checks**: bypass recursion and the memo
  for one or two unfinished months, and for arbitrary suffixes when
  all months except possibly the last have appeared. The direct
  formula is a product of exact binomial coefficients that enforces
  the final-occurrence order. An independently calculated case with
  eight four-day months requires 1635 cached states with these
  shortcuts, compared with 14756 using the original general DP.
  Tests also cover a 73-digit count for 47 previously started months.
- **the weaving streaming checks**: compare a full stored weaving
  against streaming selection at the same exact rank. Ordinary
  conversion now stores only the requested day's month and occurrence,
  rather than allocating a node for every woven day. Full-word
  materialization remains available during QA.
- **the list cleanup**: explicit CAL list destructors to release
  the project's owned linked records and memo buffers.
- **the weaving reentrancy checks**: exercise changes between two
  and three months, repeated rank selections and invalid rank handling.
- **the structure audit** and **the structure audit checks**: independently
  verify the total gate spans of selected cutlets, the total number
  of calendar days in selected months, their permitted length
  bounds, and the number, range and **uniqueness** of their chosen
  names. They also check that resetting a date cannot expose fields
  from a prior result.
- **the English name catalogue** and **the English catalogue checks**:
  fix the English source-language labels for all 17 cutlet indices
  and all 47 month indices. All 64 labels are checked explicitly,
  including proper-name spellings and out-of-range inputs. Numeric
  canonical indices, not translated labels, remain the sole input
  to ranking and unranking.
- **the English date text** and **the English date checks**:
  format a successful five-part date as a readable English string
  without modifying its canonical numeric components. Invalid or
  stale date results produce no display text.
- **the date file output** and **the date file checks**:
  provide an explicit callable procedure, `Write a calendar date for
  a calendar day and another calendar day`. It writes the English
  five-part date, or an explanatory failure reason, to
  `pastafarian-date.txt`. It does not run in the default quick QA.
- **the signed wide days** and **the signed wide day checks**:
  introduce signed decimal day coordinates with a canonical zero,
  exact addition, subtraction, comparison, and readable decimal text
  without using native 32-bit arithmetic on magnitudes. Four quick
  regression groups cover 48-digit integer arithmetic. **This is
  currently an independent building block**; the gate, year,
  cutlet and month algorithms still use native day coordinates.
  Do not claim unlimited-date support until those algorithms have
  been migrated and tested.
- **the wide day counters** and **the wide day counter checks**:
  compute the five Foundation-relative counters from arbitrary-width
  signed day inputs. Two check groups cover the Foundation day and
  both directions across a pair of coordinates at plus/minus
  10^48 days. The wide counters are now also connected to the
  complete sauce through a separate adapter; gate-position traversal
  and year/cutlet/month selection remain native-width.
- **the native wide day bridge** and **the native wide bridge checks**:
  safely convert native day coordinates into signed wide day values
  (except the unnegatable 32-bit minimum), then compare all five
  wide and original native counters on six existing fixtures. This
  is a differential migration aid, not yet a full wide-calendar path.
- **the wide sauce bridge** and **the wide sauce bridge checks**:
  map exact wide day counters into the same five sauce fields used by
  the complete 46-drop, six-bowl calculation. Quick tests compare all
  five source fields against the native path for six known day pairs
  and a pair beyond 32-bit limits. An optional slow test checks the
  complete Foundation sauce against all six canonical final bowls.
- **the wide gate intervals** and **the wide gate interval checks**:
  use exact signed gate indices to form (Foundation, Foundation+index),
  then run the same canonical seal 1 after the complete sauce. The
  zero index is rejected as a nonexistent gap. Quick tests verify
  four gate-counter input vectors including indices at +/-10^48;
  two optional slow tests check the positive and negative first gaps.
  The native gate adapter also explicitly rejects zero and indices
  outside +/-400000000 to avoid counter overflow.
- **the wide gate positions** and **the wide gate position checks**:
  add an independent, signed-wide gate-coordinate walker with atomic
  position updates and mathematically correct gap ownership in both
  directions across Foundation. It refuses traversal requests needing
  more than 1024 full sauces, and leaves a blocked position unchanged.
  The default tests exercise cross-zero gap choices and resource failure
  without running the expensive sauce; one optional slow test checks the
  positive first-gate coordinate. The native year and cutlet walkers
  have not yet been converted to this wide-coordinate machinery.
- **the canonical date vectors**: ten optional end-to-end reference
  checks for the authoritative AC.1 table on the main branch, including
  past and future year transitions. The obsolete mutant table is
  specifically excluded. These expensive checks are not run by default.
- **the complete date**: joins the independently selected year,
  cutlet lengths, cutlet names, month lengths, month names and the
  full weaving into five fields. The five fields are explicitly cleared
  at the start of each conversion and are only published after the
  selected structures pass their integrity checks. The canonical
  Foundation-day (5000, 10, 503, 20, 56) comparison is an optional
  slow oracle, not a demonstrated result of running the program.

The source now includes **92 groups of checks**, some of which compare several
values. CAL's built-in number is only 32 bits; the sauce therefore uses
decimal strings so it never depends on machine-sized large integers. Each
individual decimal arithmetic column still uses ordinary small numbers.
No single routine contains nested loops.

**Compilation and execution have not been verified.** These are real source
routines and expected outcomes, not evidence of a successful CAL run. The
arithmetic values and Foundation-Day drop outputs have been checked
independently against the equations and the published original examples, but
a compiler may still uncover errors in the Plain English syntax or library
integration.

**Current restrictions:** decimal arithmetic inputs must be nonempty,
normalized, nonnegative strings. Plain subtraction requires the destination
to be at least as large as the number being subtracted. A positive divisor
is required for ordinary remainder. Direct SAVE requires nonnegative input;
a separate operation supports signed differences between numbers in 1..M.
The current first-stage day-count conversion and signed gate indexing still
use CAL's 32-bit number type and need wide-number replacements for extreme
dates and gate indices.

**The source pipeline now reaches all five date fields, but this is not
a tested or production-ready calendar.** The CAL compiler has not run it.
The day axis and gate indices still use 32-bit numbers. Sparse
memoization of the month-weaving recurrence is exact but can have a
prohibitively large state space for a real year with many months.
A hard cap of 4096 cached suffix states and a maximum of 256
nested weaving-count calls prevent uncontrolled memo growth and deep
recursion. Either limit produces an explicit failed calculation
instead of publishing an unverified or approximate calendar date.
The linked-list cache is still not a practical high-performance
solution for the full range of real calendar years.
Further work is required for CAL syntax validation, complete differential
execution, large-instance performance, broad date support and resource
ownership, even though all five stages now have source implementations.
Year 5000, following/preceding year selection and the initial cutlet/month
count choices are present as source but have not been compiled in CAL.
The narrow and wide equal-choice mechanisms and gate/year-selection
machinery are written, but remain untested in CAL.
No shortcuts, approximate answers, or hard-coded final dates are allowed.

## The idea, explained simply

A normal calendar gives a name to a day. This calendar asks two questions:

1. On which day are we doing the calculation?
2. Which day do we want to know about?

The answer can change when the first day changes, even if the second day stays the same. The order of these two days matters.

Imagine one very long line with one mark for every day. Each day has a place on that line. This program starts with those places, not with a day or month name.

### Step 1: Give each day a number

One very old day is called **Foundation Day**. Its place on the project's continuous day line is **-15,055,671**. The number **1** belongs to that day.

Days before Foundation Day receive the even numbers: 2, 4, 6, and so on, as we move backward.

Days after Foundation Day receive the odd numbers: 3, 5, 7, and so on, as we move forward.

For example:

| Position relative to Foundation Day | Day number |
| --- | ---: |
| Three days earlier | 6 |
| Two days earlier | 4 |
| One day earlier | 2 |
| Foundation Day | 1 |
| One day later | 3 |
| Two days later | 5 |

### Step 2: Get five starting numbers

Take the day number of the calculation day. Then take the day number of the day we are asking about.

Count how many days lie between them **including both ends**. If they are the same day, this count is 1.

Add the first two day numbers.

Finally, write down a direction: **1** when the asked-about day is earlier, **2** when the days are the same, or **3** when the asked-about day is later.

These five numbers are the ingredients for everything that follows.

### Step 3: Make the sauce

The entire sauce calculation has now been written as Plain English source:
five stones, seven hidden drops, 46 visible drops, six starting bowls,
720 bowl orders, three pours for each visible drop, a simultaneous
six-bowl mixing round for each drop, and twelve final rounds. The order
selected at visible drop 46 is preserved for seal questions. Narrow sealed
answers and equal-choice selection have also been implemented in source.
**None of this has yet been successfully compiled or run by CAL.**

The full rule makes numbers grow very large. It uses one huge limit: start with 1, double it 127 times, and take away 1. Whenever a sauce number grows past this limit, it wraps around rather than growing forever. In this system, the last number before wrapping is kept instead of being turned into zero.

The rule puts five ingredient numbers in the first row and then makes 45 more rows, so there are 46 rows in all. It also makes seven hidden drops, followed by 46 visible drops. Each drop is calculated using earlier numbers, in a strict order.

There are six bowls. The drops are poured into the bowls. Their order changes according to the sauce rules. After each pour, all six bowls are mixed using their old contents at once. There are twelve more mixing rounds after the last pour.

The final bowls can answer carefully specified questions. Their answers only *look* unpredictable. The same pair of days always produces the same result.

The whole sauce needs exact whole-number arithmetic. The ordinary CAL number type is too small for the biggest values. The arithmetic routines already do long arithmetic with strings of digits, as a person can do on paper. They must still be verified in CAL. They do not call a program written in another language.

### Step 4: Find the year and its smaller parts

The full sequence of calendar rules **has source code now**, but it is not
yet a verified working CAL program.

The calendar marks special days called **gates**. Their distances come from
complete sauce calculations. Gate pairs determine eligible years; seal 10
chooses year 5000, and seals 11 and 12 choose following and preceding years.

Within a year, seals 20 and 21 choose the number and lengths of its
**cutlets**. Seal 22 assigns their distinct names. The requested cutlet
ordinal (its position in the year) is not necessarily its name index.

Seals 30 and 31 choose the number and lengths of the **months**, seal 32
weaves their occurrences day by day, and seal 33 assigns distinct month
names. A woven month's ordinal and its canonical name index also differ.
The resulting date has five pieces: year number, cutlet name, day within
that cutlet, month name, and occurrence within that month.

The entire computation is deterministic. The exact monthly weaving
shortcut code has independently checked examples, but large instances can
still fail the explicit resource limits. The CAL compiler has **not**
compiled or executed any of these files, and the native day axis still
needs an arbitrary-precision replacement. Never treat a written routine
or reference value as a successful integration test.

## Project layout

- **`source/`** — all Plain English program and check files; choose
  this folder, **not the repository root**, as CAL's source directory.
- **`README.md`** — this readable guide (not compiled).
- **`LICENSE`** — the legal text (not compiled).

## How to read or use the first part

Plain English Programming is an actual programming language. Its CAL compiler is a separate tool. This branch does not include a compiler, a copy of its code, or any helper code in another language.

Get a CAL compiler that supports Plain English Programming, and select
**`source/`** inside this branch as the source directory. It contains the
extensionless program and check files, including **`source/the calendar`**,
and no extra documents. CAL can compile a single source folder without a
special `noodle` subfolder. In compatible CAL versions, the compiler
automatically reads extensionless files in the selected source folder.
The **`README.md`** and **`LICENSE`** documents stay at the repository
root, outside the compile input. Use the matching CAL standard library
supplied by the compiler. No successful compiler execution has been
reported.

The examples use Foundation Day and its neighbors, and include whole-sauce Foundation reference vectors. The program is written to create a file called **calendar-checks.txt** when it is run. The file should say **The checks agree with the examples.** only if all 92 check groups pass. Otherwise it should name a failing check. Those checks are not proof that the full calendar works or even that the code compiles. Compare future outputs against the original calendar rules. **No successful CAL compilation or execution is claimed yet.**

## The original rules

The full calendar's rules remain in the README on the main branch of this repository. This English explanation is for learning; it does not replace those rules. When there is a difference, the original rules win.

This branch aims for two things at once: **the same exact answers as the original calendar** and **sentences a person can follow**.

The license is in the file named **LICENSE**. It grants the freedoms of the MIT license in plain language.
