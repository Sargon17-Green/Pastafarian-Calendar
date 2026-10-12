# टप्पा 19 — PATCH 09: bowl aliases through the unchanged legacy helper

## अचूक ऐतिहासिक दुरुस्ती

Stage 18 मधील `LegacyFixedBowlPoursAdapter.legacyFixedPours` या historical helper च्या कोडला व `test/discovery09Red.ts` ला स्पर्श नाही. नव्या `src/patch09BowlAlias.ts` मध्ये `LegacyBowlAliasAdapter.installOrderAliases(order)` सह:

```text
bowlAlias[0] = 0  // निष्प्रभावी sentinel
for position 1..6:
    bowlAlias[position] = order[position]
    virtualView[position] = originalBowls[bowlAlias[position]]
```

Implementation TypeScript zero-based bowl storage मध्ये `legacyPositionBowlView[position-1] = originalBowls[bowlAlias[position]-1]` वापरतो. पूर्ण सहा bowl positions चे alias mapping ठेवलेले आहे, जरी या stage मध्ये फक्त पहिल्या तीन legacy pours वाचले जातात.

`Patch09BowlAliasHandler` मूळ `LegacyFixedBowlPoursAdapter.legacyFixedPours` ला दोन स्वतंत्र वास्तविक calls करतो: एक raw bowl input वर (historical scar), एक immutable remapped virtual view वर (corrected). त्यामुळे जुनाच production arithmetic वापरला जातो; normative reference उत्पादनात आयात होत नाही. Frozen aliases, original input snapshots, six-position view, branchTrace, metrics, explicit lifecycle आणि context re-use rejection समाविष्ट.

## पडताळणी योजना

- `test/patch09.ts`: 8 ऐतिहासिक witnesses ×3 = 24 cells, historical 16 wrong व 8 accidental matches; corrected 0 mismatches. Six aliases, both real historical method calls, input preflight, error handling, frozen outputs व independent ownership.
- `test/patch09Properties.ts`: 720 permutations ×3=2160 comparisons, 1800 previous wrong व 360 previous accidental matches; त्यानंतर 12 normative day pairs ×46=552 real visible drops, 1656 comparisons, historic 1383 wrong व 273 accidental matches; 2048 deterministic signed-value runs व 8 signed giant values. सर्व corrected values normative test-only `normativeThreePours` शी अचूक जुळावेत; एकूण 3328 calls ×3 = 9984 cells.
- Stage 1–18 regressions, 9 deliberately-red historical regressions, TypeScript native typecheck आणि canonical names lock बदललेले नाहीत.
- Stage 20 in-place contamination, Stage 21 vaultOld/pending writes, Stage 54 final date integration यांपैकी काहीही आत्ता जोडलेले नाही.

स्थिती: GitHub Actions run प्रमाणित झाल्यावरच Stage 19 पूर्ण मानावा.
