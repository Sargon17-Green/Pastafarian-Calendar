# Stage39 complete — Stage40 DISCOVERY20 continuation

Repository `Sargon17-Green/Pastafarian-Calendar`; edit **only** `TypeScript+मराठी`. Total 55 alternating stages, **LAST_COMPLETED_STAGE=39**, next exactly **Stage40 DISCOVERY20**, NOT Stage41 PATCH20.

Before work, read central project policy from ChatGPT Library `/Pastafarian_Calendar_Project/PROJECT_WORKFLOW.md` and inspect/update the *same* canonical `/Pastafarian_Calendar_Project/BRANCH_REGISTRY.xlsx` (only branch row and append journal). Inspect live GitHub HEAD, `DEVELOPMENT_STAGE.md`, `docs/STAGE39_PATCH19_VERIFICATION.md`, `src/patch19GuardedYearCache.ts`, `src/discovery19LegacyYearCache.ts`, `src/patch18YearWalk.ts`, `test/normativeOracle.ts` and original normative Library file `06-implementation-prompt.md` Stage40 / oldStructureSauce contract.

Implementation Stage39 commit [8f6648a](https://github.com/Sargon17-Green/Pastafarian-Calendar/commit/8f6648a17001ad8fc2c6208132df135f6f9474fa), [GitHub Actions 38588328651](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38588328651): both jobs SUCCESS, 19 historic red scripts, frozen name/hash lock. The eventual signing commit CI must ALSO pass before Stage39 is confirmed closed.

Stage39 physically invokes full Stage38 original WRONG `LegacyYearNumberOnlyCache.oldGet`/`oldPut` Map keyed only by BigInt `year.number`; retains stale original `historicalServed`. Corrected guarded cache still uses same wrong key, with a sidecar `{calculationDayFingerprint,openGate,closeGate,value}`, and admits HIT only if ALL 3 guards match current genuine Year5000(c) and original old slot coheres. Misses physically invoke original oldPut on number-only slot. Stage37 real signed gate/Seal10–12 full producer runs on every request; tests show 512 direct giant signed cases, 6 true Year5000 queries, zero corrected wrong results; historical wrong hits remain in archives. Avoid introducing compound-key cache, altering old getter or erasing any of 19 red witnesses.

Verified summary:
```text
STAGE_39_PATCH_19_GUARDS_PASS directMisses=5 directHits=1 individualGuards=3 externalTamperMiss=1 preloadedNoGuardMiss=1 actualYear5000Queries=4 correctedMisses=3 correctedHits=1 staleHistoricalStage38StillServed=1 oldGetSpy=8 oldPutSpy=4 stage37WalkSpy=4 truePredecessors=134 sharedWrites=7772 lateFaultCases=2 rankWrong=0
STAGE_39_PATCH_19_PROPERTIES_PASS directKeys=512 fingerprintUnique=512 cDayOnlyMiss=512 openingOnlyMiss=512 closingOnlyMiss=512 tripleMiss=512 emptyMiss=512 trueDirectHits=1024 historicalWouldBeWrong=512 originalMapGets=3584 originalMapPuts=2560 bigIntBits=32768 realQueries=6 realHITs=2 realMISSes=4 originalWrongHITs=3 correctedWrong=0 stage37Walks=6 old365Calls=12 realPredecessors=198 realWrites=11484 correctedKeyCount=1
```

Stage40 DISCOVERY20: original historical `oldStructureSauce` ghost, followed by local PATCH20 correction in Stage41. Study normative structure sauce formula carefully before implementing; preserve ORIGINAL wrong helper and deliberately non-matching output in Stage40 and add a twentieth standalone expected-RED witness; do **not** implement PATCH20 or Stage42 in Stage40. Keep true full Stage39 predecessor (and old Stage38 cache scar), no test oracle imported into production, pure TypeScript, Marathi prose/comments, SourceLanguageCatalog frozen, Stage54 calendar barrier. Include actual Sauce questions, deep rollback/ownership/giant signed tests, full native CI and signing-commit rerun.

Do not edit main/other branches, do not commit private HANDOFF archives, work from current HEAD with optimistic expected SHA and no force. No user action is required unless a genuine external execution block emerges.
