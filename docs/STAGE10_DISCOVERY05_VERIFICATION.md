# टप्पा 10/55 — DISCOVERY 05 पडताळणी

## ऐतिहासिक नियम

सात hidden थेंब क्रमाने `hidden1..hidden7` अपेक्षित असताना जुने storage त्यांना `hidden7..hidden1` या उलट क्रमाने ठेवते. त्यानंतर जुना reader `stored[k-1]` वाचतो. यामुळे मधला `hidden4` सोडून सहा थेंबांचे स्थान चुकते. Stage 10 मध्ये हा दोष **जाणीवपूर्वक** जतन केला आहे.

`src/discovery05LegacyHidden.ts` मध्ये `LegacyBackwardHiddenAdapter` चे `storeBackward`, `oldHiddenAt`, आणि स्वतंत्र संदर्भातील `Discovery05HiddenHandler`/ `discoverLegacyHiddenStorage` जोडले. Immutable परिणाम, प्रति-call metrics, स्पष्ट status आणि invalid input guards आहेत. `test/normativeOracle.ts` फक्त चाचण्यांत वापरलेले आहे; उत्पादन-कोडमध्ये नाही.

## नियमाधारित साक्षी

Foundation day वर `buildHiddenDrops(workCounts(F,F), STONES)` मधून सात वास्तविक hidden drops काढले. जुन्या reader च्या `hidden1..hidden7` क्रमात नेमके **6 mismatches, 1 match**; मध्यभागी चौथा थेंब योग्य. `test/discovery05Red.ts` मध्ये `DISCOVERY_05_EXPECTED_RED mismatches=6 matches=1` आणि मुद्दाम nonzero exit.

9 स्वतंत्र oracle दिवस-जोड्या: 54 mismatches, 9 matches. 1,030 properties cases मधील 7,210 slots: 6,168 mismatches, 1,042 matches. BigInt (8192 bits पर्यंत), duplicate/palindrome input, sparse/invalid arrays, immutable ownership, status, metrics आणि चार पूर्वीच्या PATCH ची regression तपासली.

## GitHub Actions

- Tested commit: `1fa1054a2ba4dbd3106baf9458657614c26419ca`
- Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/38160880004
- `verify` आणि `stage10-typescript-marathi`: PASS
- `STAGE_10_DISCOVERY_05_GUARDS_PASS firstMismatches=6 firstMatches=1 oracleCases=9 oracleMismatches=54 oracleMatches=9`
- `STAGE_10_DISCOVERY_05_PROPERTIES_PASS cases=1030 slots=7210 mismatches=6168 matches=1042`
- Stage 1–9 green; सर्व पाच historical expected-red स्वतंत्रपणे अपेक्षित failure सहित सत्यापित.

## पुढे: Stage 11 — PATCH 05

सुधारणा फक्त reader मध्ये: `hidden k` ला 1-based स्थान `8-k` (0-based array index `7-k`) वापरून वाचायचे. **उलट storage बदलायचे नाही; ऐतिहासिक `oldHiddenAt` हटवायचा नाही.** Stage 12 चा hidden-history दोष किंवा Stage 54 ची पूर्ण दिनांक-गणना अकाली सुरू करायची नाही.
