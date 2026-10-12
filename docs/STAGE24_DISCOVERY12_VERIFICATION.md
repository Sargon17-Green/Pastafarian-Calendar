# टप्पा 24 — DISCOVERY 12: fixed numeric bowl ID successor हा जुना दोष

## ऐतिहासिक defect; Stage25 चा patch अजून नाही

नियमाधारित `next bowl` हा `orderAt46Latch` या Stage23 मध्ये स्वतंत्र जतन केलेल्या 6-ID permutation मधील queried bowl ID च्या लगेच पुढच्या **cyclic position** वरील ID आहे. शेवटच्या position नंतर पहिला position घेतला जातो. जुन्या `oldNextBowlFixedName(id)` मध्ये त्याऐवजी **fixed bowl name** `id===6 ? 1 : id+1` वापरला जातो. दोन्ही प्रकारचे wrap वेगळे आहेत: `orderAt46Latch=[1,2,3,4,6,5]` मध्ये queried ID 6 चा canonical successor 5 पण legacy numeric successor 1; queried ID 5 हा क्रमाच्या सहाव्या position वर आहे, म्हणून canonical successor 1 पण numeric successor 6.

`src/discovery12LegacyFixedNextBowl.ts` हा मुद्दाम चुकीचा, स्वतंत्र historical मार्ग:
- `LegacyNextBowlFixedNameAdapter.oldNextBowlFixedName(queriedId)` खराखुरा executable fixed-numeric helper आहे. त्यात latch च्या position शोधण्याचे कोणतेही corrected logic नाही.
- `Discovery12FixedSuccessorHandler` हा Stage23 `patch11OrderLatch` production मार्ग पूर्ण 46+12 rounds चालवतो आणि corrected immutable DROP46 latch परत मिळाल्यावर **त्याचा उपयोग पुढच्या वाटीसाठी करत नाही**; original historical numeric helper call करून `legacyNextBowlId` देतो. Stage23 sidecar प्रमाणे 58 shared-memory writes, final bowls, latch/legacy STIR12 provenance जतन.
- outer `MonsterContext` वर success नंतरच trace/metrics/status; preflight, physical legacy helper call, failure at successor method after all 58 rounds, caller-state ownership/isolation.
- Stage23 latch, Stage22 old shared memory आणि सर्व Stage1–23 source/regressions अपरिवर्तित.

## Test-only स्वतंत्र नियमाधारित reference

`test/discovery12Reference.ts:canonicalNextBowl(order,id)` हा पूर्णपणे स्वतंत्र test-only reference: permutation array मध्ये `indexOf(id)` शोधून `order[(index+1)%6]` काढतो. **Production या oracle ला import करत नाही**.

`test/discovery12.ts`: 12 canonical day pairs ×6 queried IDs = 72 real full 58-write sequences; independent full `sauce`, `applyVisibleDropsToBowls` reference confirms all bowls, correct latch and wrong historical numeric successor. Exact three red witnesses for rank2 with IDs 4,5,6; legacy method monkeypatch instrumentation proves 2 physical original calls; all invalid IDs including 0,7, fractions, NaN, Infinity and sparse inputs rejected; fault injection at numerical successor confirms context/inputs unchanged, owner uniqueness and final route Stage54 barrier.

`test/discovery12Properties.ts`: all **720 lexicographic orders ×6 queried IDs = 4320 canonical successor comparisons**; old fixed numeric rule exactly **3456 wrong / 864 accidental matches**, including 720 numeric-ID6 wrap tests and 720 permutation-position6 wrap tests (576 divergent last-position wraps). Additionally **12 original day pairs +64 changed drop1/drop46 +8 enormous signed bigint +720 distinct canonical drop46 ranks =804 genuine 46+12 full-run executions, 46632 historical shared-memory writes**. Every full run cross-checks Stage23 latch, historical STIR12 and all six bowl final values against separate normative oracle; one numeric successor compared to canonical per full run.

`test/discovery12Red.ts`: twelve-th explicitly expected-red standalone script; rank2 order `[1,2,3,4,6,5]`, IDs 4,5,6 deliberately return wrong numeric next bowls; marker `DISCOVERY_12_EXPECTED_RED mismatches=3 matches=0 ids=4,5,6 order=1,2,3,4,6,5` and nonzero process exit. Earlier eleven historical expected-red scripts retained and independently checked by GitHub Actions.

**स्थिती:** native TypeScript CI आणि GitHub Actions होण्याआधी Stage24 verified नाही. पुढील Stage25 मध्येच actual permutation-position successor दुरुस्ती; Stage24 source मध्ये patch नाही.
