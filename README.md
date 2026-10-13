# The Pastafarian Calendar, in Plain English

## A special branch

This branch is deliberately different from the other language branches in this project.

The most important rule here is that an ordinary reader should be able to understand the work. Clear writing is more important than clever tricks. There is no spaghetti-code rule, no 55-step schedule, and no requirement to follow the other branches' development rules.

Every instruction intended for a computer in this branch must be written in **Plain English Programming**. That means the Plain English language used by the CAL compiler, not merely text that looks like English. Explanations, this README, and the license are written for human readers, in ordinary English. No scripts in another programming language, build instructions written as shell commands, or workflow files belong in this branch.

The other branches have their own rules. This branch does not change them.

## What has been written so far

The extensionless file **the calendar** contains the first part of the
calculation. Given the positions of two days, it calculates the five starting
numbers: the count of each day, their inclusive distance, their sum, and their
direction. There are six small example checks.

Two more extensionless Plain English files have now been added:

- **wide numbers** contains nonnegative, arbitrary-precision whole-number
  arithmetic: comparison, addition, subtraction, multiplication, ordinary
  remainder, and the calendar's special SAVE operation.
- **the arithmetic checks** contains worked checks for long carries, long
  borrows, order, multiplication, ordinary remainders, and sauce-limit
  boundaries. The main program calls these checks.

The arithmetic stores a whole number as its decimal digits in a string. This
is essential because CAL's built-in numbers are signed 32-bit integers. The
individual columns never exceed small machine numbers. Multiplication and
long division are broken into separate routines, without nested loops.

**Important limitations:** The arithmetic routines take nonempty, normalized,
nonnegative decimal numbers. Subtraction requires the second number to be at
least as large as the first. The ordinary remainder routine requires a
positive divisor. SAVE currently handles only nonnegative arguments; handling
negative intermediate results without losing the original calendar's meaning
still needs to be built.

**Compilation and execution are not verified.** The source has been written
from documented CAL language constructs, but no CAL compiler is available in
the current environment. The checks are specifications embedded in the code,
not results from a successful test run. A reader must not treat the arithmetic
or the application as a tested release.

**This is not yet a complete date converter.** The full sauce, gates, year,
cutlets, months, and final Pastafarian date have not been implemented. They
must not be guessed or replaced by fixed answers.

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

The full sauce is **not yet implemented** in this branch. Its exact-number
arithmetic and nonnegative SAVE operation are now written, but not compiler-tested.

The full rule makes numbers grow very large. It uses one huge limit: start with 1, double it 127 times, and take away 1. Whenever a sauce number grows past this limit, it wraps around rather than growing forever. In this system, the last number before wrapping is kept instead of being turned into zero.

The rule puts five ingredient numbers in the first row and then makes 45 more rows, so there are 46 rows in all. It also makes seven hidden drops, followed by 46 visible drops. Each drop is calculated using earlier numbers, in a strict order.

There are six bowls. The drops are poured into the bowls. Their order changes according to the sauce rules. After each pour, all six bowls are mixed using their old contents at once. There are twelve more mixing rounds after the last pour.

The final bowls can answer carefully specified questions. Their answers only *look* unpredictable. The same pair of days always produces the same result.

The whole sauce needs exact whole-number arithmetic. The ordinary CAL number type is too small for the biggest values. A future part of this branch must teach Plain English to do long arithmetic with strings of digits, just as a person can do it on paper. It must not call a program written in another language.

### Step 4: Find the year and its smaller parts

This part is **not yet implemented** in this branch.

The calendar marks special days called **gates**. The sauce decides how far apart many of the gates are. The year is found using these gates and further rules. The rules give year 5000 a special fixed place near Foundation Day.

A year is cut into parts called **cutlets**. Each cutlet can contain several months, and the lengths and names of the months come from more careful choices. The result has five pieces: the year, the cutlet, the day within that cutlet, the month, and the day within that month.

The order of every step matters. Even one wrong number near the beginning can change the final date.

## How to read or use the first part

Plain English Programming is an actual programming language. Its CAL compiler is a separate tool. This branch does not include a compiler, a copy of its code, or any helper code in another language.

Get a CAL compiler that supports Plain English Programming. Open the extensionless source file called **the calendar** in the compiler's development environment. The source starts with a small set of examples, then explains the rules as short English sentences. The two additional extensionless Plain English files must be present when compiling. CAL also needs its usual Plain English library supplied by the compiler's development environment.

The examples use Foundation Day and its neighbors. The program is written to create a file called **calendar-checks.txt** when it is run. The file should say **The checks agree with the examples.** only if the six day-count checks and all of the added arithmetic checks pass. Otherwise it should name a failing check. Those checks are not proof that the full calendar works. Compare future outputs against the original calendar rules. **No successful CAL compilation or execution is claimed yet.**

## The original rules

The full calendar's rules remain in the README on the main branch of this repository. This English explanation is for learning; it does not replace those rules. When there is a difference, the original rules win.

This branch aims for two things at once: **the same exact answers as the original calendar** and **sentences a person can follow**.

The license is in the file named **LICENSE**. It grants the freedoms of the MIT license in plain language.
