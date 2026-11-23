# DISCOVERY24 — Source-formula drift/mutation QA (2026-11-23)

PROJECT_ID: PC-BRANCH-CLOJURE-DUTCH
Authorized branch: Clojure+Nederlands
Scope: TEST/QA ONLY. No production/API/budget/main/merge/publication change.

## Evidence-first baseline

- Prework branch HEAD dc895330ccd5162504b06a0a86a8c167961991b4.
- Production src/pastafari/maandrang.clj live Git blob 62f304dc013a9a9f70475bb0d34f186838b27318 unchanged at the latest verified branch SHA.
- Frozen MODEL prefix digest: 2d44e8c3ba6770c498098be3a463df3941d1079ee8c0bfbdd9c2010b87be8e1a. p82 active charge 1+(33-31)*3488 = 6977; 4995675+6977 = 5002652 > 5000000. Not a Native observation.

## Implemented

New QA script: qa/clojure-dutch/discovery24_source_formula_drift_qa.py.
It checks the exact whole-source Git blob (fail closed on any change), isolates one balanced Clojure definition each for prefix-gedeelde-raming, prefix-legale-kandidaten, and prefix-volgende-keuze, and checks the billing/legality/rank/strict-budget clauses. It computes per-definition SHA-256 only after passing the whole-source guard. A self-contained model tests shared active-group charges, new-month charges, illegal last-close choices, budget equality and cost-minus-one refusal, and the p82 witness.

- Initial branch-only test commit cd41935aae2cae9ff5246f5e98a10efd2b210b5f [skip ci].
- Actual test defect found: the clause (when (> nieuw-kosten begroting) occurs six times in the entire production file. A global first-occurrence mutant could modify the wrong function. This was corrected to mutate only the extracted named function, in branch-only commit 8611ab2d973468ab723883a5cc3857a297f2bf7b [skip ci].
- Final QA script Git blob 3ba36cffe24c0e6d8a0c28d0581ab7ada24d2158; 9597 bytes. Local git hash-object equals GitHub's returned blob.

## Observed checks

| Check | Result and scope |
|---|---|
| Local Python syntax compile | exit 0 |
| Independent model checks | 15 assertions PASS (MODEL) |
| Source mutants (five mutation types, two guards each) | 10/10 rejected against a locally transcribed exact THREE-FUNCTION SOURCE EXCERPT, not the full production source |
| Blob guard on excerpt | Expected rejection PASS: FAIL-CLOSED production Git blob changed |
| Live GitHub source inspection | Three definitions present, lengths 197 / 284 / 1496 characters; 3 / 3 / 9 required clauses present, exactly two strict greater-than budget checks in prefix-volgende-keuze |
| Branch write / script Git blob readback | VERIFIED |
| New Python QA run with complete live source file | NOT_RUN: full live Clojure source inspected with GitHub connector but not available as local checkout |
| New CI / Native / five-field differential | NOT_RUN |
| Stage2 DISCOVERY24 | OPEN |

Important: The 10/10 local mutation tests demonstrate guard behavior on exact isolated excerpts only, and are NOT a full-source runtime test or Clojure Native evidence.

## NEXT — QA only

Run this committed script against the WHOLE live production file in an authorized local checkout, requiring Git blob 62f304dc013a9a9f70475bb0d34f186838b27318, ten mutation rejections, and 15 independent model assertions. Preserve frozen prefix digest and p82 billing witness. Do not create a duplicate CI or new Native, or modify production/API/128N/5000000N/main/merge/publication. Five-field and Stage2 remain OPEN. No user-machine result arrived, so no Pending_User_Execution cleanup.
