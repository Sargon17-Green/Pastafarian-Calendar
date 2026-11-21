# Stage7 Dart+עברית — independent QA design review of A forward patch

Project: `PC-BRANCH-DART-HEBREW`
Date: 2026-11-21
Scope: **Stage7 QA-only**. No production modification; no new Dart Native, CI, performance, differential-run, stage, main, merge or release acceptance.

## Live source-locks, verified in GitHub

- Branch: `Dart+עברית`, live HEAD before this QA write: `155ec5223fb4fdeffb7839a10746ff3661d37295`; parent `a740114019ee18018a62ce82686464be84991212`. Existing [forward-patch proposal](dart_hebrew_stage7_default_path_forward_patch_proposal_20261121.md) is a docs-only report at that SHA.
- Current branch planner: `lib/src/monster_month_weave_planner.dart`, blob `d736ca8afe3409a10474b8514284aceb154a46a9` (B). Accepted A source at commit `1d98a83db7446ceb4548c39e0eaf9b4441b72b9a`: same planner path, blob `3553a7f2e3899c958d56620c5449daa35b0731e2`.
- Public export `lib/pastafari_calendar.dart`, blob `3f7c35b6187e47667006ca0864a3ae956dd42080`, exposes `src/monster_five_field_calendar.dart`. Its constructor's `weavePlanner = const MonsterMonthWeavePlanner()` and `calculate()->weavePlanner.plan()` mean B is the actual default on this **QA branch**, independently of the selection policy `KEEP_A_DEFAULT`. This says nothing about main or a published app.

## Source-locked isolated patch review — verified, NOT applied

The complete A and B planner file bodies were fetched independently from their explicit refs and compared, not merely trusted from the earlier proposal.

- A source length: **7,685 characters**; B: **7,846**.
- Exact maximal common prefix: **4,662** characters; common suffix: **2,393** characters.
- The sole maximal differing middle segment is **791 chars in B** versus **630 chars in A**; this is the same isolated block previously described with additional shared context as 825→664 characters. Both ways differ by 161 chars.
- Replacing this B middle segment with the A segment reconstructed the **entire original A file exactly**, character-for-character; all other bytes/characters remain identical in this UTF-8 source. This is a static reconstruction, not a commit to production.
- B's extra shortcut checks `ordinal <= childBases[0]`. A instead computes `factor = ordinal == BigInt.one ? BigInt.one : _unopenedFactor(...)` and evaluates child blocks. No API signature, import, output container, or call-path change is required.
- **Patch oracle:** a later authorized one-file patch on the *then-current* HEAD must preserve the exact source-reconstruction invariant **if** the target file is still B blob `d736ca8...`. If not, stop and reassess; never reset HEAD to historical A. The Git blob SHA of the patched planner must match accepted A blob `3553a7...` only when the entire file has remained unchanged outside the known block.

## Independent short-domain oracle — executed separately (not Dart Native)

An independent exhaustive prefix DFS was implemented for QA review: from counts `[n0, n1, ...]` choose an already-open color or the next never-opened color; permit a last copy only for the earliest still-open color; emit a complete word only after all counts are consumed. The resulting words are in lexicographic order for colors `0,1,2`. This does not call the Dart planner, its dynamic programming, its fixtures, or another branch's implementation.

| Counts | Legal words enumerated | Unique? | Selected zero-based word |
| --- | ---: | --- | --- |
| [3,3,2] | 26 | yes | first: `00011122` |
| [4,4,3] | 461 | yes | rank 57 (1-based): `00100112122` |
| [4,4,4] | 1,301 | yes | rank 127 (1-based): `001001121222` |

The last two independent rank witnesses complement (but are **not** themselves a native comparison against) previous targeted CI run [44923491607](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44923491607), exact source `71faa25858f691ca1a44eedd32acc008cc9e376b`, completed/success. Its targeted job [136904389242](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44923491607/job/136904389242) has completed/success steps and log marker `STAGE7_TARGETED_QA_PASS` with verdict `INCONCLUSIVE_DEFAULT_A`. Artifact 14715470687 digest `sha256:57a15b7369c7e2711fcd4854fae10d8e32edce9e17804b3508d1270179dc348e`. Previous targeted speed gate passed [4,4,3] but **failed [4,4,4]**. Do not reclassify B as accepted or rerun that historical SHA.

## Proposed independent differential contract — design validated, not executed against Dart candidate

- **Input:** all 1-based ranks `1..total` for independently enumerated short vectors [3,3,2], [4,4,3], [4,4,4]; add edge vectors with one-length components only where permitted by the original domain. For every short vector also probe rank 0 and rank `total+1` (must throw), first and final rank, and immutability of returned `List<int>`.
- **Expected output:** exact ordered list of 1-based color IDs, equal to the independent DFS word with each zero-based ID incremented by one. Preserve public `MonsterMonthWeavePlanner.unrankFull` return type/signature and constructor-injection behavior, not just the new planner's internal private method.
- **Independent oracle:** enumeration as above, with counts exhaustion, first-opening order, last-closing order and uniqueness independently asserted. No production counter/planner code or previously generated Dart fixtures used as oracle.
- **Differential checks when a patch is authorized:** compare EVERY enumerated rank against the patched source and accepted A under a real Dart SDK; include [4,4,3]/rank57 and [4,4,4]/rank127 (with the exact words above), plus rank bounds. For complete-year tests use the original four independently locked output SHA-256 digests and source SHA, not guessed expectations.
- **Runtime/check gates:** on a new SHA, Dart format/analyze and the Stage7 correctness/large-year tests; record run, job, completed state, log, output/artifact, and SHA. No CI success may be relabeled as performance promotion. A fresh performance comparison is required only if promoting a new optimization, with an explicitly defined measurement gate.
- **Change isolation:** a future production patch is outside current QA-only scope. On authorization: verify live HEAD, verify current planner blob, create one-file minimal forward patch, compare complete file, run independent oracle and Native; preserve branch ancestry. Never touch main/merge/Stage8/release during this review.

## QA disposition

**Static restoration proof: PASS** for locked A/B files. **Independent small-domain enumeration: PASS** for three domains; it is an oracle-design check, **not** a Dart differential PASS. **CI status: historical targeted job verified completed/success but the B performance gate remains FAILED.** Production forward-patch, new Native tests, performance acceptance and Stage8: **NOT DONE**.

NEXT within authorization: turn this independently specified oracle into an executable isolated candidate test harness and test the synthetic A restoration under Dart without editing the production planner; only after explicit source-scope authorization may the forward patch be applied to the production file.
