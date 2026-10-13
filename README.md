# The Pastafarian Calendar, in Plain English

## A special branch

This branch is deliberately different from the other language branches in this project.

The most important rule here is that an ordinary reader should be able to understand the work. Clear writing is more important than clever tricks. There is no spaghetti-code rule, no 55-step schedule, and no requirement to follow the other branches' development rules.

Every instruction intended for a computer in this branch must be written in **Plain English Programming**. That means the Plain English language used by the CAL compiler, not merely text that looks like English. Explanations, this README, and the license are written for human readers, in ordinary English. No scripts in another programming language, build instructions written as shell commands, or workflow files belong in this branch.

The other branches have their own rules. This branch does not change them.

## What has been written so far

The file **the calendar** takes two calendar-day positions and computes the
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
- **the gate intervals** and **the gate interval checks**: calculate the
  interval selected by seal 1 in bowl 1 using the sauce made for
  (Foundation, Foundation+n), including negative n. Independent
  reference calculations give 345 days for n=1 and 503 for n=-1.
- **the gate walk** and **the gate walk checks**: start at gate zero,
  Foundation Day, and accumulate the exact chosen intervals in either
  direction; check the adjacent positions and the zero anchor.

The source now includes **40 groups of checks**, some of which compare several
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

**Not yet built:** unbounded-date and large-index support for the gate
walk, year selection, cutlets, months, and a complete Pastafarian date.
The full narrow and wide equal-choice mechanisms and bidirectional gate
walk are written, but remain untested in CAL.
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

This part is **not yet implemented** in this branch.

The calendar marks special days called **gates**. The sauce decides how far apart many of the gates are. The year is found using these gates and further rules. The rules give year 5000 a special fixed place near Foundation Day.

A year is cut into parts called **cutlets**. Each cutlet can contain several months, and the lengths and names of the months come from more careful choices. The result has five pieces: the year, the cutlet, the day within that cutlet, the month, and the day within that month.

The order of every step matters. Even one wrong number near the beginning can change the final date.

## How to read or use the first part

Plain English Programming is an actual programming language. Its CAL compiler is a separate tool. This branch does not include a compiler, a copy of its code, or any helper code in another language.

Get a CAL compiler that supports Plain English Programming. Open the extensionless source file called **the calendar** in the compiler's development environment. The source starts with a small set of examples, then explains the rules as short English sentences. All extensionless Plain English source files in this branch must be present when compiling. CAL also needs its usual Plain English library supplied by the compiler's development environment.

The examples use Foundation Day and its neighbors, and include whole-sauce Foundation reference vectors. The program is written to create a file called **calendar-checks.txt** when it is run. The file should say **The checks agree with the examples.** only if all 40 check groups pass. Otherwise it should name a failing check. Those checks are not proof that the full calendar works or even that the code compiles. Compare future outputs against the original calendar rules. **No successful CAL compilation or execution is claimed yet.**

## The original rules

The full calendar's rules remain in the README on the main branch of this repository. This English explanation is for learning; it does not replace those rules. When there is a difference, the original rules win.

This branch aims for two things at once: **the same exact answers as the original calendar** and **sentences a person can follow**.

The license is in the file named **LICENSE**. It grants the freedoms of the MIT license in plain language.
