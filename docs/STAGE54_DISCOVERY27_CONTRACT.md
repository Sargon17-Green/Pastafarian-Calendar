# Stage54 / DISCOVERY27 — विणलेल्या महिन्याच्या पसरलेल्या उपस्थितीतील छिद्रे

Branch: TypeScript+मराठी. Predecessor: Stage53/PATCH26 at 2caaa5c24db3359b49baad633a02d7156e551323, confirmed by completed/success Actions run 41126791569 (verify and TypeScript native jobs). No main merge.

## Research question and chosen contract
In the full legal weaving w[1..N], month m has a **support set** S(m)={d | w[d]=m}. This is not necessarily the full integer interval between its first and last occurrences. Define a deliberately **synthetic** legacy model
  spanGuess(w,m,d) = (firstIndex(m) <= d <= lastIndex(m)).
The correct independent predicate is the direct equality
  member(w,m,d) = (w[d]=m).
Compare these predicates without changing the canonical five-component date result or Stage53 corrected month-end. The spanGuess is introduced for diagnostic research; **it is not an allegation or proof of an existing production defect**.

Unlike Stage52 (month-last flag) or Stage51 (prefix occurrence count), Stage54 studies **membership of internal holes** in a noncontiguous month support. There is no sixth date component, no new date calculation, and no copied oracle from another branch.

## Initial independent executable witness (research only)
w=[1,2,1,2,1,2,1,3,2,3,3,3,3]. Month 1 has holes on days 2,4,6; month 2 has holes on 3,5,7,8; month 3 has a hole on day 9. Across 39 (month,day) questions: eight false positives, zero false negatives, and 31 agreements. This is **synthetic expected-red**, not an observed production bug. It has a separate nonzero-exit regression with guarded verifier.

Bounded diagnostic property research: 256 seeded shuffled families of 47 days and five month IDs, 60,160 membership questions, test-only direct equality oracle, zero false negatives, nonzero false positives, no oracle inconsistencies. Validate absent months, single-month words, day bounds, malformed month IDs, and 5,778-day maximum. The audit does not invoke the Native predecessor.

## Planned full Stage54 acceptance (NOT established by research-only tests)
- Integrate an independent Stage54 diagnostic handler on the **entire** Stage53 Native chain, with the exact legal weaving, immutable historical result, ownership/rollback/retry, and zero additional Native predecessor queries. Do not weaken Stage53 assertions.
- Obtain a real Year5000 membership-gap observation from that chain; record measured numbers, not predictions. Never claim real expected-red without a reproducible actual observation.
- Require npm run typecheck, npm test, Stage54 full-handler guards and bounded properties, genuine expected-red verifier, verify names lock, and TypeScript Native job on the same new HEAD SHA. Inspect completed CI logs before claiming Stage54 PASS.
- A later PATCH27 may be considered only after measured Stage54 evidence and its own contract. No automatic final-date enablement, main merge, or other branch edits.

The present commit registers **research diagnostics and an explicit acceptance plan**, not full Native implementation and NOT Stage54 PASS.
