# Stage 22 — DISCOVERY 11: drop46 permutation स्मृतीवर 12 post-stir overwrites

## ऐतिहासिक दोष — शोध, दुरुस्ती नाही

सामान्य six-cell permutation स्मृती (`LegacySharedOrderMemoryAdapter`) एका साच्यातच ठेवली आहे. Stage21 corrected 46 actual visible-drop stir rounds प्रत्येक वेळी एक पूर्ण six-ID order लिहितात. त्यानंतरच्या **12 post-stirs** मधील तंतोतंत normative post-stir formula सहा-कक्षांची तीच shared order स्मृती प्रत्येक वेळी पुन्हा लिहिते. **46+12=58** write operations. शेवटचा source `STIR_12`; जुन्या `queryLegacyOrder()` ला `DROP_46` order ऐवजी `STIR_12` मधील overwritable memory दिसते.

Stage23 चा `orderAt46Latch` **या stage मध्ये कुठेही नाही**. `writeLedger` मधील अपरिवर्तनीय प्रति-write copies फक्त diagnostics साठी आहेत; production query फक्त shared mutable six-cell memory वरून प्रत काढते, ledger किंवा drop46 history वरून नाही. Historical wrong behavior असा प्रत्यक्ष executable मार्ग नोंदवला आहे; जुने Stage 1–21 sources, दहा deliberate expected-red tests, Stage 21 corrected shadow stir अबाधित आहेत.

## गणिती सत्यापन

`src/discovery11LegacyOrderMemory.ts` मधील Stage21 `patch10Stir` 46 वेळा **खरोखर** चालतो; each round uses corrected patch09/patch10 pours and snapshots. मग 12 वेळा post-stir गणना:

```text
S_r = SAVE(sum(B_old[1..6]) + 149*r)
order_r = unrank6(regularMod(S_r-1, 720)+1)
for position=1..6:
  b = order_r[position], previous, next = cyclic order neighbors
  mixed = B_old[b] + 3*B_old[previous] + 5*B_old[next] + S_r + r + position²
  pending[b] = SAVE(mixed² + 7*B_old[previous]*B_old[next])
commit all six pending bowls once per stir
sharedOrderMemory.write("STIR_r", order_r) // overwrites previous order
```

प्रत्येक stir सर्व reads old snapshot वरून करतो. Stage21 corrected bowls नंतर चुकीची in-place legacy mutation पुन्हा जोडली जात नाही. Test-only `normativePostStirLedger`, `applyVisibleDropsToBowls`, `postStir12`, `sauce` यांनी 46-drop bowls, सर्व 12 post-stir orders आणि final bowls स्वतंत्र तपासले जातात. Query थेट canonical drop46 order शी तुलना करणे ही **फक्त test** जबाबदारी आहे.

## कसोटीचे पुरावे

- `test/discovery11.ts`: 12 actual date pairs, each 58 writes, exact ledger sources DROP_1..DROP_46 आणि STIR_1..STIR_12, drop46 versus poststir query positions **1, 2, 6** वर three-cell mismatch witness, context/array ownership, immutable forensic entries, true adapter physical memory identity, malformed inputs, five fault-injection boundaries (writes 1, 46, 47, 52, 58), context/no caller partial mutation आणि successful retry.
- `test/discovery11Properties.ts`: 12 actual date pairs + 64 deterministic variants of drop1/drop46 + 8 signed giant cases = **84 complete sequences**, 46 real patched drops +12 post-stirs each = **4872 actual shared order writes**, 3864 drop rounds, 1008 post-stirs, 29232 forensic order positions, independent post-stir ledger/order comparisons. Original `LegacySharedOrderMemoryAdapter.write` actual call instrumentation 58 calls to a single memory instance.
- `test/discovery11Red.ts`: 11th deliberately-red script; three genuine mismatches at positions **1,2,6**, `DISCOVERY_11_EXPECTED_RED mismatches=3 matches=0 positions=1,2,6 writes=58`, genuine nonzero process exit.
- All Stages1–21 regressions and earlier **10** deliberately-red scripts, TypeScript native compile, frozen canonical names SHA lock.

**स्थिती:** GitHub Actions validation बाकी; success प्रमाण नसताना LAST_COMPLETED_STAGE=21 कायम. Stage23 latch patch या branch वर अजून नाही.
