# Dart+עברית — Stage 4 / DISCOVERY02 — external package consumer

PROJECT_ID: PC-BRANCH-DART-HEBREW
BRANCH: Dart+עברית. Branch-only; no main, merge, publication, or release.

## Preconditions

Stage3 / DISCOVERY01 public API was accepted on SHA
af2e3ac90cfafa3ff9f60197c6456466651c92a3:
- Natural push run 44374112687 completed/success, 22/22 jobs.
- Stage3: 16 checks, one canonical anchor, public_calendar_ready=true,
  canonical time 12162 ms.
- Stage1: Dart 3.13.2, 43 files formatted / 0 changed, analyzer clean.
- P16: 391 checks, 36 synthetic cases, 3 canonical anchors, 36707 ms.
- Discovery17: 31072 checks, 304920 raw words, 11002 valid words,
  268 rank probes, 3417 projections, 32 rejections, 182 ms.
- Exact branch HEAD and Stage3 source blobs were read back.

## Evidence-based objective

Stage3 exported MonsterFiveFieldCalendar and MonsterFiveFieldDate from
lib/pastafari_calendar.dart, but its smoke test imported the entrypoint by a
relative filesystem path. That proves the file-level export, not the package
URI that an ordinary Dart consumer uses. pubspec.yaml names the package
pastafari_calendar_dart_hebrew.

Add a standalone consumer test whose only import is
package:pastafari_calendar_dart_hebrew/pastafari_calendar.dart. Do not import
lib/src or alter production algorithms. Verify the public calculator, public
date type, public Hebrew name catalog, numeric tuple and transition bound.

## Inputs, independent oracle, and outputs

Foundation calculation day: -15055671.
For each requestedDay = foundation + delta, call calculate with
maxTransitions=0. All three normative AC.1 dates are in year 5000, so a
zero-transition limit must be sufficient.

| delta | year | cutlet index | cutlet day | month index | month day |
| ---: | ---: | ---: | ---: | ---: | ---: |
| -1 | 5000 | 10 | 502 | 32 | 21 |
| 0 | 5000 | 10 | 503 | 20 | 56 |
| 1 | 5000 | 14 | 1 | 29 | 38 |

For every row:
- Assert the five numeric public fields against the literal oracle.
- Assert Hebrew names against the exported SourceLanguageCatalog.
- Assert canonicalComponents has exactly five values, in order and with types
  BigInt, int, int, int, int.
- Assert the returned component list rejects mutation with UnsupportedError.

Also require maxTransitions=-1 and maxTransitions=65 to throw RangeError.
Measure the three public calculate calls together; require <=120000 ms.
The test must perform at least 60 assertions/checks and print:
STAGE4_PACKAGE_CONSUMER_PASS; checks>=60; canonical_anchors=3;
package_uri=true; zero_transition=true; immutable_tuple=true
plus numeric STAGE4_PACKAGE_CONSUMER_TIME_MS.

## CI acceptance

The natural push on Dart+עברית must complete with 23/23 success jobs:
the established 22 plus dart-hebrew-stage4-package-consumer.
Use Dart SDK 3.13.2; resolve packages; format the new test with zero changed;
dart analyze must report No issues found; run the standalone consumer test
through dart run bin/stage4_package_consumer_tests.dart and verify its marker
and numeric time bound. Reconfirm Stage1, P16, Discovery17 and Stage3 on the
same SHA. No duplicate manual dispatch.

No production algorithm changes are part of this discovery. No main, merge,
publication, or release.
