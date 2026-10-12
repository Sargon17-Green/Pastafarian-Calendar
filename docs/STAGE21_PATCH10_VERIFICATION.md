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

**स्थिती:** GitHub Actions मधील तपासणी झाल्याशिवाय Stage21 पूर्ण म्हणून नोंदवू नये.
