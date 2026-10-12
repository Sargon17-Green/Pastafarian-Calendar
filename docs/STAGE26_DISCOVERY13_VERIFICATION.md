# Stage 26 — DISCOVERY 13: biased modulo rank selection (CI submission)

## नियमाधारित स्रोत व दोषाची अचूक व्याख्या

`test/normativeOracle.ts` मधील `askBowl`, `answerAt`, `chooseRankShort`, `chooseRankWide`, `chooseRank` हे स्वतंत्र नियमाधारित test-only references आहेत. `M=2^127-1`. विचारलेल्या वाटीचा `firstAnswer` नेहमी 1..M; `directionStep` +1/-1; `N` ही सकारात्मक पूर्णांक family cardinality.

- `1<=N<=M`: `L=floor(M/N)*N`, पहिले `answerAt(stream,k)<=L` स्वीकारून `1+((answer-1) mod N)` निवडायचे.
- `N>M`: `k` digit `M`-base उत्तर-समुच्चय तयार करून `floor(M^k/N)*N` मर्यादेपर्यंत rejection आणि नंतर rank.
- जुन्या `LegacyBiasedModuloRankAdapter.oldChooseModulo` मध्ये मात्र **फक्त** `1+((firstAnswer-1)%N)` आहे. Rejection नाही, wide digits नाही; Stage27 ची दुरुस्ती येथे जाणीवपूर्वक अनुपस्थित.

## स्वतंत्र production chain

`src/discovery13LegacyBiasedModulo.ts` हा आधीचा `patch12NextBowl` पूर्णपणे चालवतो: 46 drops, 12 post-stirs, 58 shared writes, स्वतंत्र DROP46 latch, corrected next bowl, actual old fixed-name helper. Production `patch01Save` ने खालील सूत्रे वेगळी मोजतो:

```text
first = SAVE((B[queried] + seal + 181)^2 + 179*B[correctNext] + seal)
directionNumber = SAVE((first + seal + 1 + 193)^2 + 193*first + 197*B[6])
directionStep = (directionNumber mod 2)==1 ? +1 : -1
oldRank = 1 + ((first - 1) mod N)
```

Corrected `chooseRank` किंवा test-only reference production import नाही.

## QA चाचण्या

- `test/discovery13.ts`: 12 canonical daypairs ×6 वास्तविक full routes (72 cases); independent oracle stream, 3 top `first=M` rejected witnesses at sizes 2/3/5; old modulo आणि Stage25 successor physical calls, malformed shapes/IDs/counts, fault-before/after complete prior work, rollback/retry, no context alias, Stage54 calendar barrier.
- `test/discovery13Properties.ts`: analytical modulo bias for all `N=1..256`, direct finite boundary and multi-digit wide ranks, rejection threshold adjacent witnesses, plus 12 real +64 variant +8 huge signed +720 rank-driven full Stage25 histories = **804 real traces, 46632 shared writes**. Corrected predecessor and exact answer-stream checked against the independent test-only normative oracle. Historical choice deliberately differs in witnessed cases.
- `test/discovery13Red.ts`: intentional thirteenth RED (3 mismatches, 0 matches at `first=M`, `N=2,3,5`). Twelve historical RED scripts untouched.
- GitHub Actions: `stage26-typescript-marathi` runs typecheck, Stage1–26 green suite, 13 independent archived intentionally-red checks; `verify` checks frozen names.

**Stage26 status: implementation submitted, CI not yet verified. LAST_COMPLETED_STAGE remains 25.** No Stage27 PATCH13 implementation.
