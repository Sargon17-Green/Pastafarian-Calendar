# Dart+עברית — Stage 3 / DISCOVERY01 — public calendar API

PROJECT_ID: PC-BRANCH-DART-HEBREW
BRANCH: Dart+עברית. Branch-only; no main, merge, publication, or release.
PRECONDITION: Stage2 P16 QA was accepted on 43938809355 (20/20). Stage2 Discovery17 was accepted on 44363911766 (21/21 completed/success), HEAD f88176f48902084fe2b8dae3a8e3aec5d5a535b3: D17 checks=31072, raw_words=304920, valid_words=11002, rank_probes=268, projection_cases=3417, rejections=32, synthetic_time_ms=122; P16 checks=391, synthetic_cases=36, canonical_anchors=3, canonical_time_ms=30569. Stage1 Dart 3.13.2 formatting 42/0, analyzer clean.
STATUS: New Stage3 candidate; no Native Stage3 PASS before fresh successful run.

## Evidence-based next step

The full five-field computation was already available internally at lib/src/monster_five_field_calendar.dart, but lib/pastafari_calendar.dart exported only monster_base.dart and source_language_catalog.dart. External Dart consumers could not import the canonical calculation class from the package entrypoint. Export the existing immutable MonsterFiveFieldCalendar and MonsterFiveFieldDate classes without changing their implementation, algorithms or names. Preserve all previous exports.

## Input, output and oracle

Public package entrypoint: import '../lib/pastafari_calendar.dart' in the standalone integration test. Call MonsterFiveFieldCalendar().calculate(c,t) with c=t=the independently fixed Foundation day, -15055671 (proleptic serial day). Normative AC.1 expected five numeric components are (5000,10,503,20,56), using retained-sum AC.1 and NOT superseded AC.2. Confirm both Hebrew canonical strings against SourceLanguageCatalog, immutable five-component list, and a measured bound <=120000 ms. No special helper import from lib/src and no separate full-year re-computation in this test.

Test marker: STAGE3_PUBLIC_API_PASS checks>=16 canonical_anchors=1 public_calendar_ready=true; numeric STAGE3_PUBLIC_API_CANONICAL_TIME_MS<=120000. Dart 3.13.2 formatter on entrypoint and test: zero changed; dart analyze: No issues found.

## Native acceptance

A natural push on Dart+עברית must complete with 22/22 success jobs (prior 21, plus dart-hebrew-stage3-public-api). Verify exact SHA, Stage1, Production16, Discovery17 and Stage3 logs. The established 21 jobs must stay successful, with retained P16/D17 counts and time gates. A queued/in_progress workflow is neither accepted nor blocked. No duplicate manual CI dispatch; inspect completed failures and patch only demonstrated faults. No main/merge/release.
