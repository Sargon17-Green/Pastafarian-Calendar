# टप्पा 21 — PATCH 10: vaultOld / pending वापरून सहा bowl stir

## अनिवार्य सुधारणा

Stage 20 मधील `LegacyInPlaceBowlStirAdapter.stirInPlace` हा ऐतिहासिक in-place दूषणाचा helper **बदललेला नाही**. `test/discovery10Red.ts` आणि त्याआधीचे नऊ archival deliberately-red पुरावे कायम आहेत.

नव्या `src/patch10SnapshotStir.ts` मध्ये `Patch10ShadowBowlAdapter` दोन पूर्णपणे स्वतंत्र अवस्थांचा वापर करतो:

```text
vaultOld = clone(initialBowls)
pending  = clone(initialBowls)
for position = 1..6:
  bowlId = order[position]
  prevId = order[wrap6(position-1)]
  nextId = order[wrap6(position+1)]
  current  = vaultOld[bowlId]
  previous = vaultOld[prevId]
  next     = vaultOld[nextId]
  mix = current + 2*previous + 3*next
    + pour[position] + drop + stone[kind[position]]
  pending[bowlId] = SAVE(mix*mix + 5*previous*next + i*position)
// सहाही गणिते यशस्वी झाल्यावरच:
for bowlId=1..6: ownedDestination[bowlId] = pending[bowlId]
```

उपरोक्त pseudocode 1-based bowl IDs दर्शवतो; TypeScript arrays मध्ये प्रत्येक bowl `id-1` index आहे. `vaultOld` फक्त **reads**, `pending` फक्त **pre-commit writes**; मूळ caller array बदलत नाही. `Patch10SnapshotStirHandler` corrected Stage19 pours व Stage17 order घेतो; खऱ्या जुन्या helper ला **स्वतंत्र private bowl clone** वर एकदा प्रत्यक्ष call करून wrong history संग्रहित करतो. त्या historical output वर corrected calculation आधारित नाही.

`Patch10ShadowBowlAdapter.stage` मध्ये fault-injection callback हा optional deterministic seam आहे: प्रत्येक pending-write नंतर थ्रो झाल्यास final commit होत नाही, मूळ input व context स्थिती बदलत नाही. `commit` हे स्वतंत्र explicit six-bowl assignment आहे, पूर्ण `stage` नंतरच. Per-call immutable `originalBowls`, `vaultOld`, `pending`, `correctedBowls`, `historicalBowls`, `correctedSteps`, `historicalSteps` व context trace/metrics.

## चाचणी निकष

- `test/patch10.ts`: आठ सीमावर्ती values ×6=48 corrected positions, **0** corrected mismatches; जुन्या code चे **40 wrong /8 coincident** परिणाम जतन. Per-step current/previous/next reads original bowl state शी मुळापासून जुळतात. जुन्या helper ची खरी call; six-stage pending नंतर six-write explicit commit; सर्व सहा position वर स्वतंत्र injected failure व पुनर्प्रयत्न; invalid inputs, frozen ownership, lifecycle आणि Stage54 final route guard.
- `test/patch10Properties.ts`: सर्व 720 order permutations ×6=4320; पूर्वीचे 3600 wrong व 720 matches; 12 actual date pairs ×46=552 visible drops; त्याच 12 जोड्यांची **पूर्ण 46-step evolving** गणना independent `applyVisibleDropsToBowls` reference शी तंतोतंत जुळावी आणि Stage20 ऐतिहासिक final 72 bowl differences नष्ट न करता historical shadow मध्येच राखावीत. 1024 seeded signed cases व 8 extremely huge bigint cases; एकूण 2304 single-drop calls ×6 = 13824 independent corrected cells, expected **0 mismatches**.
- TypeScript `tsc --noEmit`, Stages1–21 full green tests, ten independent archived intentional expected-red workflows, frozen canonical names lock सर्व PASS.
- Stage22 DISCOVERY11 सुरू नाही; Stage54 पूर्वी `calendarDateSpaghetti` अजून unsupported.

**स्थिती: GitHub Actions संपूर्ण PASS**. Verified implementation commit `5010a3c4af0d875e4195e1c8176557943531743f`. [Run 38228198853](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38228198853): `verify` आणि `stage21-typescript-marathi` दोन्ही `success`. TypeScript compiler, Stage 1–21 regressions, सर्व दहा deliberately-red archival proofs, canonical names lock प्रमाणित.

```text
STAGE_21_PATCH_10_GUARDS_PASS witnesses=8 cells=48 mismatches=0 historicWrong=40 historicMatches=8 vaultReads=6 pendingWrites=6 committedWrites=6 injectedFailures=6 legacyCalls=1
STAGE_21_PATCH_10_PROPERTIES_PASS orders=720 orderWrong=3600 orderMatches=720 cases=2304 cells=13824 mismatches=0 oldWrong=11520 oldMatches=2304 vaultReads=13824 pendingWrites=13824 committedWrites=13824 realPairs=12 realDrops=552 evolvingPairs=12 evolvingDrops=552 evolvingMismatches=0 historicalFinalMismatches=72 seeded=1024 giant=8
```

- 720 पूर्ण permutations, 13,824 corrected bowl positions, zero corrected differences; 11,520 old wrong / 2,304 coincident comparisons स्वतंत्र shadow मध्येच राहिले.
- 12 actual date pairs, 552 normative visible drops; पूर्ण 12 evolving ×46 sequences मधील **प्रत्येक intermediate corrected bowl state** आणि final six bowls independent full normative `applyVisibleDropsToBowls` बरोबर. Stage20 जुन्या evolving final bowl states मध्ये सर्व 72 फरक कायम.
- सहाही pending-write failure-injection positions वर context/input integrity टिकते, पुनर्प्रयत्न deterministically successful. पूर्ण Stage 20 old method वास्तवात एकदा per call invoke केला जातो; जुन्या source/helper/test scripts पैकी कोणताही बदल नाही.
- पहिला run `38227820573` मध्ये जुन्या tree base मुळे Stage20 ची काही files checkout मध्ये उपलब्ध नव्हती; `f601004...` मध्ये complete Stage20 tree वर Stage21 files पुनर्लावून सुधारले. दुसऱ्या run `38228022417` मध्ये Node22 strip-types ला constructor parameter property unsupported होती; ordinary constructor field `5010a3c...` मध्ये करून अंतिम run 38228198853 यशस्वी. हे source semantics मध्ये नव्हे तर tree integration आणि Node loader compatibility मध्ये झाले.
- पुढील टप्पा Stage22 `DISCOVERY 11` — general permutation-order memory overwritten after drop 46 by 12 post-stirs. त्यावरील Stage23 स्वतंत्र latch patch इथे लागू नाही.
