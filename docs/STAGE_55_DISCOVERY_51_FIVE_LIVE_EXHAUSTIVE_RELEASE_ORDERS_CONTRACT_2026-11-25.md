# Stage55 / DISCOVERY51 — exhaustive release orders for five live owners

PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Authorized branch: COBOL+简体中文
Prerequisite: Stage54 accepted on exact tested source d8027a79c16ca2153a3b62c82350ac719c587ab9, run 45551463457 (55/55), strict Native job 138993375177, artifact 14994755042 independently SHA256/CRC verified. Current parent is the documentation-only child 5b0360a70a3a83b1c374a66146f90084b9338fe2; it is not a separately Native-tested SHA.
Kind: final bounded test-only discovery. No historical defect or expected-red is asserted.

## Distinct coverage question

Stage42 exhausted all 4! = 24 release orders for four simultaneously owned outputs. Stage43 combined four-live release orders with occupied-output rejection and survivor preservation. Stages50–54 extended arithmetic and lifetime cases to five live outputs. Stage54 accepted mixed 8192/8193-digit five-live results and repeated serialization, but it freed one selected owner and performed its final cleanup in numeric slot order. It did not exhaust all 5! release orders of five simultaneously live owners.

Stage55 closes only that bounded lifecycle-order gap: every one of the 120 permutations of five output owners is exercised exactly once. It does not assert a defect and does not reopen the four QA51-B failure-injection paths.

## Inputs and independent expected values

Let M = 10^8192 - 1. For j = 1..30, define the five small operands
t = [j+1, 1, 0, -j, -(j+1)].
The base pair is C=M and T=t[k]. Four orientations are used: original, swapped operands, globally negated, and swapped plus globally negated. The absolute-distance operation is symmetric, so the five exact positive results are:

1. M-j (8192 decimal digits)
2. M (8192 decimal digits)
3. 10^8192 (8193 decimal digits)
4. 10^8192+j (8193 decimal digits)
5. 10^8192+j+1 (8193 decimal digits)

Every result has 911 base-10^9 chunks. Negative 8192-digit magnitudes are initialized as legal unsigned 8192-byte text and receive the already accepted normalized sign in the test descriptor; no 8193-byte signed INIT-TEXT input is introduced. No aliases, forged descriptors, raw address construction, fault injection, or unsafe release are permitted.

## Exhaustive permutation-to-case mapping

Enumerate permutations lexicographically from 12345 through 54321. Permutation id p=1..120 maps to orientation floor((p-1)/30) and j=((p-1) mod 30)+1. Thus all 120 release orders occur exactly once, with 30 unique arithmetic anchors in each orientation. The native enumerator validates each permutation contains slots 1..5 exactly once, keys are strictly increasing, the first key is 12345, the last is 54321, and the total is 120. The independent Node oracle uses recursive permutation enumeration, not the COBOL next-permutation procedure.

## Native lifecycle for each of 120 cases

1. Create five independently owned outputs in the permutation's order. Each creation initializes valid input owners, calls the real MONSTER-DISTANCE / DISTANCE-PATCH service, checks all live output and input descriptors/chains for exact expected digits and disjoint tails, then releases only the two known input owners.
2. After each output creation, walk and validate every currently live output, including all 911 nodes, PREV/NEXT links, null ARENA links, saved node addresses, sign/chunk/head/tail descriptors and exact decimal chunks. Measure HEAP-LIVE and require live-output-count * 911.
3. Release all five outputs in the same permutation order. After every FREE-A, require the released descriptor to be empty, revalidate every survivor, and measure the exact remaining heap. The fifth release must measure zero.
4. Rebuild all five outputs in reverse permutation order using fresh input owners. Revalidate every live output after each creation and measure the exact heap.
5. Release the rebuilt owners in the original permutation order, again validating every survivor after each release. The final measured heap must be zero.

No suspect pointer is freed after a failed check. Pointer walks are bounded to 911 nodes and test nonnull before dereference; later walks compare each pointer to its saved address before dereferencing. The process is isolated and bounded; crash, timeout, nonzero exit or any unexpected counter is failure, not a PASS.

## Independent planning oracle

test/stage55_planning_oracle.mjs independently:
- recursively enumerates 120 unique permutations;
- maps them to 120 unique (orientation,j) anchors, 30 per orientation;
- checks 600 exact arithmetic results with BigInt against the closed forms above;
- reconstructs and compares all 546,600 decimal chunks using independent division-by-10^9 and decimal slicing;
- calculates, but does not claim to execute, 6,000 native owner walks, 5,466,000 native chunk checks, 2,400 distinct-owner checks, 2,400 heap samples and 240 zero-heap endpoints.

Planning output is PASS_NOT_NATIVE only.

## Exact acceptance gate

The canonical workflow gains exactly one strict job; expected total is 56/56. Require exact pushed SHA, completed/success run and all 56 jobs, GnuCOBOL 3.1.2.0 strict -Werror, compile <=300 seconds, executable <=120 seconds, job <=20 minutes, exact native counters, zero unexpected failures, measured heap, uploaded evidence even on failure, and independently verified artifact ZIP SHA256, CRC and embedded PROJECT_ID/HEAD before acceptance.

Native counters:
- permutations/cases/pass: 120/120/120
- initial owners / reverse-rebuilt owners: 600 / 600
- release steps across both cycles: 1200
- owner walks / chunk checks: 6000 / 5466000
- distinct-owner checks: 2400
- heap samples / zero-heap endpoints: 2400 / 240
- orientation counts: 30 / 30 / 30 / 30
- unexpected failures: 0
- RESULT=PASS_STAGE55_FIVE_LIVE_EXHAUSTIVE_RELEASE_ORDERS_NATIVE
- STAGE55_NATIVE_GATE=PASS

Do not invent expected-red. A failed compile, crash, timeout, incorrect result or counter mismatch is diagnosed against its exact source and log before any repair. Do not rerun a completed accepted SHA.

## Explicit exclusions and boundary

The 2026-11-22 QA51-B decision A closed the coverage review with four disclosed untested paths; it did not authorize the test-build failure-injection interface (decision B). Allocation denial/partial construction, valid-owner FREE-A failure, HEAP-LIVE service failure, and PATCHED-DISTANCE cleanup after subordinate failure remain NOT TESTED / NOT ACCEPTED and are excluded from Stage55. No failure injection, production source modification, main/protected-ref update, merge, release, or full-calendar integration is authorized or claimed. FULL_CALENDAR_INTEGRATION remains NOT_YET_AVAILABLE. Stage55 is the final bounded branch stage; no Stage56 is opened.
