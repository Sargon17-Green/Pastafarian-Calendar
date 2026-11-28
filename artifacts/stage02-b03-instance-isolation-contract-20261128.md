# B03 — host-instance isolation QA contract

**Project:** PC-BRANCH-WAT-SPANISH  
**Status:** PREPARED / NOT EXECUTED  
**Scope:** QA-only contract. No production source, public ABI, SAVE(M), Stage03, main, or merge changes.

## 1. Normative input domain

The Scroll specifies an ordered pair:

1. calculation/work day;
2. queried/target day.

The external day number is a positive integer. Relative to the base day:

- offset 0 maps to day number 1;
- later offset d>0 maps to 2d+1;
- earlier offset d<0 maps to -2d.

These identifiers are unique but not chronological. Do not sort them to infer date order, and do not pass signed offsets as if they were external day numbers. M=2^127-1 is the bowl-response modulus, not a maximum day number.

The Scroll defines five logical result fields: year number, cutlet name, day in cutlet, month name, and day in month. The year can be zero or negative and must not be narrowed to i64. The Scroll does not define JSON, decimal-string serialization, pointer ownership, error codes, or a public memory ABI.

## 2. Current implementation facts

At the audited branch HEAD:

- The bootstrap accepts opaque i32 handles; it does not parse or validate semantic day numbers.
- The calendar oracle accepts pointers to wide integers.
- The oracle writes a shared 20-byte global result record. Its fields are a pointer to the wide year, a pointer to the cutlet name, an i32 day-in-cutlet ordinal, a pointer to the month name, and an i32 day-in-month ordinal.
- The accessors take no arguments and read the shared record. A later calculation overwrites it.
- Catalog names are NUL-terminated UTF-8 strings; the catalog has 17 cutlet entries and 47 month entries.

Consequently, an accessor result or raw pointer cannot be retained across the next calculation. The year and both strings require deep copies into host-owned memory.

## 3. Candidate host contract for QA only

This is a test-harness proposal, not a ratified public ABI:

- Accept two positive canonical ASCII decimal strings, named work_day and asked_day, in that order.
- Candidate day-number lexical rule: ASCII digits only, first digit 1–9, no plus sign, no leading zero, whitespace, embedded NUL, decimal point, exponent, or Unicode digit.
- Parse with arbitrary-precision integer arithmetic. Do not route through JavaScript Number, float, or signed 64-bit types.
- Convert to the internal signed wide representation using base-2^30 little-endian limbs, sign=+1, minimal length, nonzero top limb, and capacity at least length. Zero and negative values are rejected as external day numbers.
- A technical input or memory limit, if imposed by the adapter, must produce an explicit resource-limit result. It must never truncate, wrap, substitute a civil date, or return a calendar date.
- After a successful call, copy the year exactly and copy both NUL-terminated UTF-8 strings before any subsequent call. Copy the two i32 ordinals as values.
- Return a host-owned immutable five-field result. No linear-memory pointer is exposed as a durable result.
- Candidate status classes are success, invalid input, resource limit, and internal failure. Numeric status codes remain unspecified until a separate ABI decision.

## 4. Isolation sequence

Use two distinct valid positive day-number pairs, A and B. Do not require their calendar outputs to differ; compare each with its own isolated baseline.

1. Create a fresh instance and run A alone. Deep-copy all five fields and snapshot the valid A input/object memory.
2. Create a separate fresh instance and run B alone. Deep-copy all five fields as B's isolated baseline.
3. In a test instance, run A1 and immediately deep-copy all five fields.
4. Run B1 and immediately deep-copy all five fields.
5. Run A2 and immediately deep-copy all five fields.
6. Compare A1 with A2 field-for-field and byte-for-byte for copied UTF-8 strings.
7. Compare interleaved B1 with isolated B.
8. Verify the host-owned A1 copy and A's input object are unchanged after B1.
9. Inject an invalid B input. It must return an explicit failure, must not mutate A's input or previously copied result, and must not expose a partially populated five-field result.
10. Verify that no pointer from one instance is accepted or dereferenced in another instance.

Because the current result record is a global singleton, the initial isolation gate must use separate instances and sequential calls. Concurrent calls on one instance are out of scope until per-instance state exists.

## 5. Acceptance criteria

- A1 equals A2 across all five logical fields.
- Interleaved B1 equals isolated B across all five logical fields.
- Year comparison is exact arbitrary precision, including zero and negative years.
- Cutlet and month strings are copied as strict UTF-8 content, not compared by raw pointer address.
- Day-in-cutlet is within 1..963 and day-in-month within 1..123.
- No stale accessor read, pointer escape, cross-instance pointer reuse, partial result, or state mutation after invalid B.
- Any imposed resource bound returns an explicit error and never a date.

## 6. Non-claims

This document does not prove that the current bootstrap is a complete adapter, that the global oracle is reentrant, or that the candidate decimal representation is normative. No B03 Native or differential PASS is claimed. Runtime execution starts only after a QA adapter implementing this contract exists.
