# Dart+עברית — Stage 2 / PRODUCTION10 — §R numerical year component

PROJECT_ID: PC-BRANCH-DART-HEBREW
BRANCH: Dart+עברית only
PRECONDITION: PRODUCTION09_SELECTION_PASS on ecf9d86a9ecd9448004187e74ff68217feb5e5c3, run 41523484689, 13/13 jobs completed/success. Native checks=102, canonical=3, short=7, wide=3, rejections=3; Dart 3.13.2 format clean and analyze clean.
NORMATIVE_SOURCE: main README blob 74c424b44eadd4ece3f29072ddbf873236557604, §R lines 581–615; §O lines 504–534; §P lines 538–556; §§M,N lines 442–500.
STATE: First numerical component slice, NOT a complete five-component calendar date.

## Input/output and invariant
Inputs: BigInt calculation day c, BigInt requested day t, canonical complete year5000(c), bounded maxTransitions in 0..64. Output: the signed BigInt year number, ordinal gate pair, (openGate,closeGate] and selection witness (seal 11 forward or 12 backward, sauce (c,shared gate), 1-based §N choice, candidate count). The year initially has number 5000, regardless of c.

When t > closeGate, the next year's opening gate is the current closeGate, enumerating all eligible years of length 252..5778 with at least six §O intervals. For t <= openGate, the previous year's closing gate is the current openGate. In both directions, order by length ascending and apply bowl 1 with seal 11 or 12 using sauce (c, sharedGate); update year number by +1 or -1. The traversal never re-anchors to (t,t).

For an interval labeled by consecutive ordinals (i-1,i), the exact signed §O gap input is i if i>0, otherwise i-1; this includes the crossing (-1,0). Each interval has length 42..963, so 137 intervals suffice for any eligible adjacent year: 138 intervals would already exceed 5778. The six-interval candidate always fits the maximum. All positions and year numbers are BigInt.

## Fail-closed conditions
An invalid budget throws RangeError. If the request is outside the current year's (open,close] after maxTransitions, throw IncompleteMonsterYearTraversal, never emit a speculative date. This is a bounded computing policy, not a claim about the existence of dates beyond the cap.

## Independent oracle, tests, evidence
Native test builds adjacent candidates independently by recalculating exact §O signed gaps in a separate enumeration and comparison sorter. It reconstructs the §M bowl 1 answer from the (c,sharedGate) upstream work snapshot and independently implements §N's ring acceptance, without production year traversal, candidate enumeration, or chooseEqual. Compare candidate count, 1-based index, both ordinal and gate endpoints, lengths, labels and continuity. Test c=Foundation and ±1, both traversal directions (six oracle cases), shared-gate exclusivity/inclusivity, forward/backward requests and step-budget refusal. Minimum 85 assertions and explicit marker.

CI acceptance: all jobs completed/success at one SHA, format 0 changes, dart analyze 0 issues, and PRODUCTION10_YEAR_WALK_PASS with checks>=85, anchors=3, forward=3, backward=3, oracle=6. Any queued/in_progress run is neither failure nor PASS. No main/merge/release.

NEXT after Native PASS: implement §S/T meatball partition and canonical names as the next structural component, with its own independently counted composition oracle and a separate measurable gate. Then §§U–W month counts, lengths, weave and names, and finally §X five components compared against OracleEngine.calendar_date_normative. Do not mark the overall Stage 2 complete until all are verified.
