# Dart+עברית — Stage 5 / DISCOVERY03 — separate-package consumer boundary

PROJECT_ID: PC-BRANCH-DART-HEBREW
BRANCH: Dart+עברית
MODE: Branch-only. No main changes, merge, release or publication.
STATUS: Candidate, NOT ACCEPTED before completed Native CI.
PRECONDITION: Stage4 natural push 44613330235 on c61bf90081f513f91a64ba886ddea0921c3c7bb8 completed/success 23/23. Stage4 job 135875345040: checks=62, canonical_anchors=3, package_uri=true, zero_transition=true, immutable_tuple=true, time=31101 ms, formatter 1/0 and analyzer clean. Stage1 job 135875344797: format 44/0, analyzer and tests clean. Stage3: 16, 14961ms; P16: 391, 36 synthetic, 3 anchors, 36873ms; D17: 31072, raw304920 valid11002 ranks268 projections3417 rejections32, 112ms; verify success.

## Evidence-based gap

Stage4 imported the public package URI from a bin/ script inside the same
pubspec root. It established public export and package URI resolution *within
that package*, not resolution from a distinct Dart project's dependency graph.
Stage5 closes precisely that packaging boundary without changing production
code or reimplementing the calendar algorithm.

## Scope and independent oracle

Create integration/dart_hebrew_consumer as a distinct, unpublished Dart package
named pastafari_calendar_external_consumer. Its only calendar dependency is
pastafari_calendar_dart_hebrew via a relative path to the repository root.
All test imports must use the public package URI, not lib/src or relative imports.
Run dart pub get and dart analyze in this child package's working directory,
and dart run bin/main.dart there.

Normative literal oracle: calculationDay=-15055671 and requestedDay offset
-1, 0, +1, maxTransitions=0. Retained-sum AC.1 values:
- -1: (5000,10,502,32,21)
-  0: (5000,10,503,20,56)
- +1: (5000,14,1,29,38)
The expected values are fixed normative data, not computed by production
helpers or copied programmatic fixtures. Verify Hebrew cutlet/month names
through the public SourceLanguageCatalog, five values and exact runtime
types, and both indexed-assignment and append immutability rejection.
Reject maxTransitions=-1 and 65 with RangeError.

## Contract and acceptance

One additional GitHub Actions job, dart-hebrew-stage5-external-consumer.
Install Dart 3.13.2; statically verify child pubspec name and path dependency;
run dart pub get from child; check Dart formatter 1 file/0 changed; analyze
child clean; execute child consumer without importing internal files.
Print and verify STAGE5_EXTERNAL_CONSUMER_PASS with:
checks>=65, canonical_anchors=3, separate_pubspec=true,
path_dependency=true, zero_transition=true, immutable_tuple=true.
Print numeric STAGE5_EXTERNAL_CONSUMER_TIME_MS <= 120000.

Accept Stage5 only when natural push is completed/success 24/24, exact source
SHA and child job Native marker and numeric bound confirmed from logs.
Stage1, Stage3, Stage4, P16, D17 and verify must remain successful on same SHA,
using previously established respective numeric gates. Queued/in_progress
are neither blockers nor PASS. Do not duplicate-dispatch a run.
If formatting fails, use the exact Dart 3.13.2 captured formatter output to
patch proven whitespace differences. No acceptance on static inspection.
