# Dart+עברית — Stage 6 / DISCOVERY04 — bounded pipeline profiling

PROJECT_ID: PC-BRANCH-DART-HEBREW
BRANCH: Dart+עברית
MODE: Branch-only. No main, merge, release or publication.
STATUS: Candidate, NOT ACCEPTED without a completed Native CI log.
PARENT: 6fb2c5b4e6ab33f4093ee6da5ff3d65a09bd797b

## Accepted prerequisites

Stage5 natural push 44634103881 completed/success 24/24 on parent.
Stage5 job135948075106: 65 checks, 3 normative AC.1 anchors, separate
child pubspec/path dependency, immutable tuple, zero-transition calls,
39260ms <=120000, format 1/0, child analyzer clean (Dart 3.13.2).
Stage1 45/0, Stage3 16/15715ms, Stage4 62/30844ms, P16 391/31015ms,
Discovery17 31072/122ms, verify success.

## Evidence-based gap

The independent external-package consumer takes 39260ms for three complete
calendar calculations, but no subphase timings exist. This discovery profiles
a single normative calculation using the six existing production components.
Do not assume a bottleneck or claim any speedup. Do not alter production
algorithms, caching, serialization or public API.

## Inputs, oracle and output

calculationDay=requestedDay=-15055671, maxTransitions=0.
Measure separately and in order YEAR (resolve), CUTLETS (partition),
LENGTHS (plan), WEAVE (plan), NAMES (plan), PROJECTION (project).
Output six nonnegative millisecond timings and total milliseconds.
Check literal retained-sum AC.1 (5000,10,503,20,56), independent of the
production calculations, locked Hebrew names, dimensions and 6 measured
phases. Sum of phase durations must not exceed total elapsed duration.
The test profiles production component composition, not an independent
date-calculation implementation.

## Acceptance gates

One new GitHub Actions job dart-hebrew-stage6-component-profile with
Dart 3.13.2 and no new dependencies:
- format bin/stage6_profile_components.dart 1 file / 0 changed;
- dart analyze: No issues found;
- six STAGE6_PHASE_{YEAR,CUTLETS,LENGTHS,WEAVE,NAMES,PROJECTION}_MS;
- STAGE6_PROFILE_TIME_MS <= 120000;
- STAGE6_PROFILE_PASS checks>=18, canonical_anchors=1, phases=6,
  pipeline_consistent=true, retained_sum_ac1=true;
- Stage1 now formats 46/0 with existing analyzer/tests;
- Stage3, Stage4, Stage5, P16, D17 and verify remain passing;
- natural push run completed/success 25/25 on exact branch SHA.
No duplicate dispatch; any formatter failure requires exact Dart 3.13.2
capture and a verified branch-only patch. After acceptance, select an
optimization target only from the observed phase timings.
