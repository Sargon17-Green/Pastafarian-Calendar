# Dart+עברית Stage7 — default-path audit and source-locked A forward-patch proposal

Project: `PC-BRANCH-DART-HEBREW`  
Date: 2026-11-21  
Scope: **QA-only static code-path audit and future patch proposal. No production code edited, no new Native/CI/performance/Stage acceptance.**

## Locked source facts

- Authorized branch: `Dart+עברית`; audited HEAD before this report: `a740114019ee18018a62ce82686464be84991212`.
- Previous accepted A: commit `1d98a83db7446ceb4548c39e0eaf9b4441b72b9a`, planner blob `3553a7f2e3899c958d56620c5449daa35b0731e2`.
- Current QA-branch B: planner blob `d736ca8afe3409a10474b8514284aceb154a46a9` at `a740114019ee18018a62ce82686464be84991212` (and Stage7 run source `71faa25858f691ca1a44eedd32acc008cc9e376b`).
- Public export `lib/pastafari_calendar.dart`: blob `3f7c35b6187e47667006ca0864a3ae956dd42080`; `export 'src/monster_five_field_calendar.dart';`.
- Constructor/call path `lib/src/monster_five_field_calendar.dart`: blob `f29c6cd893bbe31d5ddef294a25013ca384e504d`; default `this.weavePlanner = const MonsterMonthWeavePlanner()`; `calculate()` calls `weavePlanner.plan(...)`.
- `MonsterMonthWeavePlanner.plan()` calls `_unrankWithKnownTotal(...)`; `unrankFull()` also reaches that helper. The B-specific `ordinal <= childBases[0]` shortcut is inside that helper.
- Export and constructor blobs at the accepted A commit were separately read and match the above current blobs byte-for-byte by Git blob identity. The planner blob differs. Thus, **B is active by default when this branch's ordinary public Dart calendar is instantiated without an injected planner**. This does **not** establish deployment, a `main` merge, or public release.
- Public package metadata: `publish_to: none` at audited branch.
 
## Completed CI evidence; do not reinterpret the gate

[Run 44923491607](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44923491607), source `71faa25858f691ca1a44eedd32acc008cc9e376b`, completed/success, 27 jobs successful + one intentionally skipped. [Targeted job 136904389242](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44923491607/job/136904389242) completed/success; [artifact 14715470687](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44923491607/artifacts/14715470687), recorded ZIP SHA-256 `57a15b7369c7e2711fcd4854fae10d8e32edce9e17804b3508d1270179dc348e`. This audit independently checked live job status and log's `INCONCLUSIVE_DEFAULT_A` verdict; the earlier [independent result report](dart_hebrew_stage7_targeted_ab_run44923491607.md) records the separate downloaded-artifact audit.

- Domain `[4,4,3]`, rank 57: A/B exact ranked words match the independent oracle; B faster 5/5, median +8.927906%, minimum +3.020059%: **targeted gate PASS**.
- Domain `[4,4,4]`, rank 127: A/B exact ranked words match the independent oracle; B faster 2/5, median -9.308410%, minimum -11.553694%: **targeted gate FAIL**.
- The conjunction requires **both** cases 5/5, median ≥2%, minimum ≥1%. Hence **B performance promotion NOT ACCEPTED**; accepted choice policy is `KEEP_A_DEFAULT`, but current QA branch code has B as the actual default. CI job success and correctness are not performance acceptance.

## Exact minimal forward-patch proposal — NOT APPLIED

Target: only `lib/src/monster_month_weave_planner.dart`, after re-reading the live branch and ensuring the existing B blob is still `d736ca8afe3409a10474b8514284aceb154a46a9`; never reset HEAD or replace the branch with historical A commit. Preserve all other files and public signatures.

Replace the B-only block inside `_unrankWithKnownTotal` that tests `ordinal <= childBases[0]` with the historical A block guarded solely on `ordinal == BigInt.one`. Proposed replacement (exactly the A block):

```dart
        // For rank 1, the first active token is necessarily lexicographically
        // minimal. Avoid a full unopened-factor calculation in this case.
        final factor = ordinal == BigInt.one
            ? BigInt.one
            : _unopenedFactor(remaining, opened, activeLength - 1);
        for (var i = 0; i < active.length; i++) {
          if (childBases[i] == BigInt.zero) {
            continue;
          }
          final block = childBases[i] * factor;
          if (ordinal > block) {
            ordinal -= block;
          } else {
            chosen = closed + i;
            nextBase = childBases[i];
            break;
          }
        }
```

The QA static reconstruction performed on this locked B blob replaces **one contiguous block** (`825` source characters → `664` characters) and yields the *exact complete file contents* of accepted A, verified by whole-string equality against `3553a7f2e3899c958d56620c5449daa35b0731e2` source. This is static text/source correspondence, not a Dart test execution, speed claim, or applied production patch.

Rationale: B returns the first active child when its lower-bound count covers the rank, potentially skipping expensive suffix counting for ranks other than 1. That changes the timing path; while it produced identical words on the measured examples, the promotion gate failed. Restoring A’s narrowly established `ordinal==1` optimization while keeping current HEAD ancestry avoids defaulting to an unaccepted performance candidate.

## Authorization and proof gates for a later production edit

1. **Before any edit:** confirm `Dart+עברית` live HEAD and target B blob; if either changed, rebase the *single-block proposal* to the new tree and re-evaluate; do not force-push or reset. A production patch is **outside this QA-only authorization**.
2. **Edit scope:** one planner file; keep public `unrankFull` contract, `plan()` selection, exported API, immutable `List<int>` result, and constructor injection path intact. Do not touch `main`, stage policy, release, or Stage8.
3. **Static source oracle:** complete patched planner bytes must equal accepted A source; inspect changed files and parent SHA and verify no unintended production differences.
4. **Native checks if later authorized:** Dart format/analyze, Stage7 correctness suites and full-year assertions on the *new SHA*, plus rank 1, ranks 57 and 127, domain boundaries 1/total and rank 0/total+1 errors, and immutable-result checks.
5. **Independent differential oracle:** enumerate short domains independently (not via the target planner or imported fixtures); compare every ranked word with the candidate and accepted A. Include domain `[4,4,3]` rank57, `[4,4,4]` rank127, and canonical complete-year digest locks, with run/job/log/artifact/source SHA captured.
6. **Selection:** only after code QA and appropriate accepted gates, reflect `A` as the implementation default. Do not claim general performance improvements or advance Stage8 because of this source restoration alone. Do not repeat run 44923491607 on the same SHA.

## NEXT within current authorization

A source-locked QA design review of the forward patch and its proposed independent oracle is available; implementation into the actual planner must await explicit scope/authorization. No user-local execution results were involved, so no `/Pending_User_Execution` cleanup is triggered.
