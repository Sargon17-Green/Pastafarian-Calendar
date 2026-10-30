# Stage53 / PATCH26 — विणलेल्या महिन्याचा वास्तविक शेवट

Branch: \`TypeScript+मराठी\`. Parent: Stage52/DISCOVERY26 at \`a6f2aa413479fc17c6c325779c50ebb7206b303c\`.

## Correct derived predicate
For the complete legal weaving \`w[1..N]\` already selected by Stage52 and any valid target day \`d\`:
\`correctedLastMonthOccurrence(d) = NOT EXISTS j (d < j <= N AND w[j] = w[d])\`.
A month need not occupy consecutive days. This predicate is a *derived layer*, not a sixth canonical date component.

The intentionally flawed Stage52 \`oldNextDayMonthEndGuess\` remains unchanged, immutable, and retrievable via the historical result. Its disagreement is a synthetic diagnostic finding, not evidence of a preexisting production defect.

## Implementation
- Standalone \`Patch26SuffixOccurrenceChecker\`, independent owner, full Stage52 historical chain, no additional native predecessor query, and no mutation of historical traces or canonical outputs.
- Correction only when the old guess differs. The old result may claim "last" too early; it must not claim "not last" when the predicate says "last".
- Independently validate the 13-day dispersed witness (7 repaired, 6 equal; three actual month finals), the real Year5000 full chain, invalid input and forged historical metadata, deep-fault rollback, retry, and duplicate-owner rejection.
- 256 deterministic shuffled families × 47 target days = 12,032 oracle checks. Compare against a test-only \`slice(d).includes\` suffix oracle and require zero unexpected divergences.
- Preserve Stage52's three declared intentional red examples and two controls, older red guards, names lock, and final five-component date gate.

## Acceptance
\`npm run typecheck\`, \`npm test\`, verify and TypeScript Native CI jobs on the *new commit SHA*, \`STAGE_53_PATCH_26_GUARDS_PASS\`, \`STAGE_53_PATCH_26_PROPERTIES_PASS\`, historical \`STAGE_52_DISCOVERY_26_EXPECTED_RED_VERIFIED\`, and canonical names lock. Until all complete successfully Stage53 is *implementation only*, NOT PASS. No \`main\` merge, no final-date enablement, and no Stage54 opening without an independently documented contract.
