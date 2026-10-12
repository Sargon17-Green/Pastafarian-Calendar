# टप्पा 24 पूर्ण — Stage 25 PATCH 12 साठी HANDOFF

## अधिकृत पूर्णत्व आणि सीमा

- Repository `Sargon17-Green/Pastafarian-Calendar`; **फक्त `TypeScript+मराठी` branch**. `main` आणि इतर branches मध्ये बदल किंवा push नाही.
- Canonical **55 stages**. **LAST_COMPLETED_STAGE=24**, current **24 DISCOVERY 12**. पुढे **25 PATCH 12** एकमेव stage; Stage26 DISCOVERY13 किंवा पुढील काम एका उत्तरात सुरू नको.
- Tested Stage24 implementation commit `e5c03c15c7fb6b99126b2290dfa8e90ede457b4d`.
- [GitHub Actions 38239449544](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38239449544): `verify` आणि `stage24-typescript-marathi` दोन्ही SUCCESS, native TypeScript `npm run typecheck`, all Stage1–24 green tests, **all 12 archived historical intentionally-red scripts** verified expected nonzero, frozen `CANONICAL_NAMES_LOCK.sha256` PASS.
- Pure TypeScript source, Marathi comments/docs, frozen `SourceLanguageCatalog`, no cross-language source/fixtures or test-only normative production import. `calendarDateSpaghetti` remains intentionally unsupported until Stage54.

## DISCOVERY 12: जुना fixed numeric successor

`src/discovery12LegacyFixedNextBowl.ts` मधील `LegacyNextBowlFixedNameAdapter.oldNextBowlFixedName(queriedId)` असा मूळ दोष चालवतो:

```text
return (queriedId == 6) ? 1 : queriedId + 1
```

हे six-name **numeric ID** arithmetic आहे, **DROP46 saved permutation position** नाही. `Discovery12FixedSuccessorHandler` संपूर्ण Stage23 `patch11OrderLatch(c,t,visible,STONES,start)` production route independent child context मध्ये चालवतो: 46 patched drop rounds +12 canonical post-stirs =58 real shared order-memory writes; frozen correct `orderAt46Latch` एकदा captured; original old query `STIR_12` memory कायम. अशा योग्य saved order असूनही `legacyNextBowlId` हा actual old numeric helper call चा result आहे; **Stage25 patchचा एकही टप्पा Stage24 source मध्ये नाही**.

नियमाधारित independent test-only oracle `test/discovery12Reference.ts:canonicalNextBowl(order,queriedId)` हे

```text
position = indexOf(orderAt46Latch, queriedId)
nextBowl = orderAt46Latch[(position + 1) % 6]
```

करते. हे function **Stage24 source मध्ये import नाही**.

Concrete RED witness:

```text
DROP46 order number 2 => [1,2,3,4,6,5]
queriedId=4: legacy 5, canonical 6
queriedId=5: legacy 6, canonical 1  // permutation last-position wrap
queriedId=6: legacy 1, canonical 5  // numeric name-6 wrap ≠ positional successor
```

`test/discovery12Red.ts` standalone intentionally throws `DISCOVERY_12_EXPECTED_RED mismatches=3 matches=0 ids=4,5,6 order=1,2,3,4,6,5`. Previous 11 historical expected-red tests unchanged. Diagnostic old helper `oldNextBowlFixedName` **must remain wrong** in Stage25, usable for side-by-side scar.

## पूर्ण प्रमाण

```text
STAGE_24_DISCOVERY_12_GUARDS_PASS dayPairs=12 cells=72 mismatches=60 matches=12 rank2Wrong=3 actualLegacyCalls=2 injectedFailures=1
STAGE_24_DISCOVERY_12_PROPERTIES_PASS orders=720 cells=4320 wrong=3456 matches=864 numericWrap=720 positionWrap=720 positionWrapWrong=576 realPairs=12 varied=64 giant=8 ranks=720 unique=720 histories=804 sharedWrites=46632 queryWrong=629 queryMatches=175 realWrong=11 realMatches=1
DISCOVERY_12_EXPECTED_RED mismatches=3 matches=0 ids=4,5,6 order=1,2,3,4,6,5
```

- All 720 lexicographic six-ID orders ×6 queried IDs => 4320 independent successor differences: **3456 legacy wrong, 864 accidental same**.
- 720 numeric ID6→1 wrap checks, 720 permutation-position6→position1 wrap checks; the latter 576 cases legacy numeric returns wrong successor.
- 12 real day-pairs ×all six queries =72 full Stage23 histories, 60 wrong/12 accidentally same; 804 additional full traces combining 12 real +64 deterministic varied visible drops +8 enormous signed bigint +720 distinct actual DROP46 ranks, totaling **46632 genuine shared-memory writes**. 804 one-queried-ID samples: 629 wrong/175 same; canonical six bowl state after 46 drops and after 12 post-stirs remains exact.
- Legacy method physically invoked (2-invocation monkeypatch), invalid ID 0/7/nonint/nonfinite & malformed input guards, injected error at old numeric helper after full Stage23 calculation yields no partial caller input/outer context mutations, isolation/reentrancy verified.
- The bad historical selection concerns successor only; frozen Stage23 latch + Stage21 bowl calculations remain correct.

## पुढचा एकमेव Stage 25 — PATCH 12

प्रारंभ live GitHub HEAD व `DEVELOPMENT_STAGE.md`, `HANDOFF_STAGE_24.md`, authoritative 55-stage contract व `test/normativeOracle.ts` तपासूनच करा. स्वतंत्र **corrected production** helper `src/patch12NextBowl.ts` तयार करा:

1. Full `patch11OrderLatch(c,t,visible,stones,bowls)` path with old 58 writes and frozen `orderAt46Latch` reused unchanged.
2. Find `queriedId` at its **index in immutable orderAt46Latch**. Return next cyclic permutation position (position6→position1). Numeric name arithmetic must *not* compute corrected answer.
3. Preserve **actual invocation of old `LegacyNextBowlFixedNameAdapter.oldNextBowlFixedName`** separately for historical scar and mismatch accounting, but do not reuse its result to compute correct answer. Original `src/discovery12LegacyFixedNextBowl.ts` and `test/discovery12Red.ts` unchanged. Previous eleven historical expected-red tests unchanged.
4. QA: 720 ranks×6 queried IDs 4320 corrected comparisons zero wrong, while 3456 old wrong still visible; 12 canonical daypairs×6, 64 variants, eight giant signed values; full 58-write histories retained. Numerical ID6 wrap, permutation position6 wrap, rank2 red three witnesses corrected; validated inputs, mutable state ownership, function real-call instrumentation, thrown exception rollback, independent contexts. `calendarDateSpaghetti` still unsupported before Stage54.
5. Extend `src/monsterBase.ts`, `src/index.ts`, `package.json`, CI workflow and docs. All Stage1–25 green regression scripts, **12** archived intentionally-red checks and locked canonical names should pass in GitHub Actions. Do not mark `LAST_COMPLETED_STAGE=25` until both CI jobs successful. Create `HANDOFF_STAGE_25.md` after verified closure.
6. Next Stage26 DISCOVERY13 biased modulo selection is out of scope for Stage25; never preempt it. Exactly one stage per user response.

Important Git practice: build new tree from **latest live branch commit tree**; prior Stage21 accidentally omitted prior-stage files by basing on stale tree. Use SHA optimistic concurrency, no force push. No human/local action needed.
