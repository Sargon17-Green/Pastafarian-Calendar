# Stage 22 पूर्ण — Stage 23 PATCH 11 साठी HANDOFF

## अधिकृत तपासलेली अवस्था

- Repository `Sargon17-Green/Pastafarian-Calendar`. काम फक्त **`TypeScript+मराठी`** branch मध्ये करावे. `main` किंवा दुसऱ्या programming/natural-language branches मध्ये बदल किंवा push नको.
- 55-stage canonical contract: **LAST_COMPLETED_STAGE=22**, current **22 DISCOVERY 11**, पुढील एकमेव **23 PATCH 11**. पुढचे DISCOVERY12/Stage24 आगाऊ सुरू करू नका. एका user response मध्ये एकच stage.
- Tested Stage22 implementation commit `94f3ca8f5ab7ac440f03122889dc95ae32e87f2f`.
- [GitHub Actions 38233277622](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38233277622): `verify` आणि `stage22-typescript-marathi` **SUCCESS**. Native TypeScript `tsc`, complete Stage1–22 `npm test`, 11 independent deliberately-red archival scripts (nonzero expected exit verified separately), frozen `CANONICAL_NAMES_LOCK.sha256` PASS.
- Implementation pure TypeScript, natural-language comments/docs Marathi, frozen `SourceLanguageCatalog`; foreign language branches/fixtures/implementation never copy or import. Test-only `test/normativeOracle.ts` MUST NOT be imported into production.
- `calendarDateSpaghetti` final integration अद्याप नाही; Stage54 पूर्वी `MonsterStageError`.

## Stage22 जुन्या दोषाची executable साक्ष

`src/discovery11LegacyOrderMemory.ts`:
- `LegacySharedOrderMemoryAdapter` मध्ये **एकच बदलता six-cell `sharedOrder` buffer**. `write(source,order)` त्याच object वर सहा assignments करून overwrite करतो; प्रत्येक write चे forensic immutable record अलग `writeLedger` मध्ये. **Diagnostic ledger ला semantic `orderAt46Latch` समजू नका**: जुने `queryLegacyOrder()` केवळ live sharedOrder वाचते, ledger वापरत नाही.
- `Discovery11OverwrittenOrderHandler.run(ctx,visible,stoneRows,startBowls)`: 46 real visible-drop rounds `patch10Stir` वापरून canonical corrected bowl calculation; प्रत्येक round ने `DROP_i` order overwrite. मग 12 canonical post-stirs, प्रत्येकात वाचन old snapshot वरून आणि सहा pending results चा पूर्ण commit; `STIR_1`.. `STIR_12` orders त्याच sharedOrder वर overwrite.
- 58 actual shared-memory writes; old `queryLegacyOrder()` returns `STIR_12` order. The source does **not** latch `DROP_46` or reroute query; historical semantic error intentionally live.
- Drop rounds return correct `afterDropBowls`; 12 post-stirs exact `finalBowls`; immutable input/snapshots, journal and per-call `MonsterContext` tracking. Optional injected failure callback after any of 58 writes leaves external input/context untouched and allows deterministic retry.
- Legacy old Memory .write really executed 58 times per run; `test/discovery11Properties.ts` instrumentation confirmed one instance.
- Other Stage1–21 sources and first ten expected-red archival tests unchanged; `test/discovery11Red.ts` new eleventh expected-red.

## Verified QA evidence

```text
STAGE_22_DISCOVERY_11_GUARDS_PASS pairs=12 writesPerPair=58 rounds=46 postStirs=12 mismatches=32 matches=4 redPositions=1,2,6 witness=1 injectedFailures=5
STAGE_22_DISCOVERY_11_PROPERTIES_PASS realPairs=12 varied=64 giant=8 cases=84 writes=4872 drops=3864 postStirs=1008 ledgerCells=29232 queryDifferences=206 queryMatches=46 redWitnesses=48 spyWrites=58
DISCOVERY_11_EXPECTED_RED mismatches=3 matches=0 positions=1,2,6 writes=58
```

- 12 normative real day-pairs: 36 old-query comparisons at positions 1,2,6 have 32 wrong and 4 accidental correct.
- 64 deliberately varied drop1/drop46 sequences and 8 huge signed bigint sequences, total 84 complete 46+12 runs: 4872 shared buffer writes, 29232 ledger ID cells, 206 wrong query position values, 46 coincidences. **48** distinct scenarios where positions 1,2,6 all wrong.
- Independent test-only `normativePostStirLedger`, `applyVisibleDropsToBowls`, `postStir12`, `sauce` confirm 46-drop canonical bowl results, all 12 post-stir order writes and final bowl values, not merely the 58 counter.
- Five fault boundaries tested: after shared write 1, 46, 47, 52, 58. Corrected Stage21 bowl semantics retained throughout.
- CI first run `38233130886` test-only TypeScript errors; only getter-versus-method, narrowing and tuple type annotation repaired. Final source implementation unchanged; SUCCESS run `38233277622`.

## पुढचा Stage23 — PATCH 11, आणि फक्त तोच

Authoritative project contract नुसार **जुन्या overwritable 58-write memory ला स्पर्श नाही**. Fix म्हणजे `DROP_46` पूर्ण झाल्यावर *एकदाच*, त्याच computed permutation मधून स्वतंत्र immutable

```text
orderAt46Latch = clone(orderFromDrop46)
```

हा snapshot तयार करणे. Stage23 corrected semantic query `orderAt46Latch` मधूनच वाचेल. पुढील 12 post-stirs जुन्या general memory वर नेहमीप्रमाणे अजूनही 12 overwrites करतील; historical `queryLegacyOrder()` आणि all 58 write observations राहतील. **Old memory query ऐतिहासिकदृष्ट्या wrong राहणे आवश्यक**.

- नवीन corrected `src/patch11OrderLatch.ts` सारखा independent path. Stage22 code source, `LegacySharedOrderMemoryAdapter` आणि `test/discovery11Red.ts` **कधीही संपादू किंवा मिटवू नका**. Real Stage22 input stream, 46 corrected Stage21 bowl calculations, 12 normative post-stirs आणि independent order memory वर आधारित genuine latch; mere oracle-returned order static bypass नको.
- Latch creation exactly once at `DROP_46`; no overwrite/alias during STIR1..STIR12. Corrected semantic query returns latch, not `STIR_12`, with trace/metrics, independent ownership, no leaked shared array references and fault injection where useful.
- Tests: 12 actual day pairs, 64 varied, 8 giant or stronger; 58 writes unchanged, all 12 last-stir orders and bowls still normative, corrected queried positions 1,2,6 all exact, 11 archived deliberately-red regression preserved. Include 58-write late-stir overwrite witnesses, many full-cycle deterministic cases and actual three-red witness repair.
- Stage24 DISCOVERY12 numerical next-bowl successor bug **not yet**: preserve its legacy behavior for future stage, do not implement Stage25 patch12 or final calendar routing.
- Stage23 closure only after GitHub Actions both `verify` and Stage23 native TypeScript job success; record actual tested commit/run in `DEVELOPMENT_STAGE.md`, docs and new `HANDOFF_STAGE_23.md`. Always base Git tree on newest **live HEAD** to avoid accidental removal of prior-stage files; optimistic expected SHA on `update_ref`.
- No user local action needed. 
