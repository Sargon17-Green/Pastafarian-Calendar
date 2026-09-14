# Kasaysayan ng Paglago ng Spaghetti Monster

## Stage 1 — Bootstrap

Neutral na PowerShell base, test-only normative oracle, frozen source-language catalog, at per-invocation semantic state.

## Stage 2 — Discovery 01

Raw `oldRemainder` defect.

## Stage 3 — Patch 01

`savePatch` correction sa ibabaw ng raw remainder scar.

## Stage 4 — Discovery 02

Raw `oldDayTag` defect.

## Stage 5 — Patch 02

`dayTagWithFoundationScar` correction, kasama ang historical redundant Foundation guard.

## Stage 6 — Discovery 03

Raw `oldDistance(c,t)=abs(dayTagWithFoundationScar(c)-dayTagWithFoundationScar(t))` defect.

## Stage 7 — Patch 03

Tinatawag muna ang raw `oldDistance`, inihahambing sa chronological difference, pinapalitan lamang kapag magkaiba, at laging dinaragdagan ng final inclusive `+1`.

## Stage 8 — Discovery 04: sunod-sunod na pagdumi ng stone state

### Historical defect

Ang limang stone value ay binago sa iisang mutable state object sa ganitong pagkakasunod:

```text
S.w = SAVE(S.w*S.w + 3*S.b + i)
S.b = SAVE(S.b*S.b + 5*S.s + S.w)
S.s = SAVE(S.s*S.s + 7*S.m + S.b)
S.m = SAVE(S.m*S.m + 11*S.r + S.s)
S.r = SAVE(S.r*S.r + 13*S.w + S.m)
```

Ang unang formula lamang ang siguradong nakakakita sa buong lumang row. Ang mga susunod na formula ay nakakabasa ng mga bagong intermediate value na naisulat na sa parehong invocation.

### Normative contrast

Ang normative row ay kumukuha muna ng lumang row at kinakalkula nang hiwalay ang lahat ng limang bagong value mula sa snapshot na iyon.

Sa row 2, ang legacy `w` ay nagkataong kapareho ng normative `w`, ngunit ang legacy `b`, `s`, `m`, at `r` ay iba.

Ang pagkakaiba ay patuloy sa mga susunod na row.

### Discovery surface

Ang rows 2, 3, at 46 ng tunay na legacy builder ay inihahambing sa test-only normative stone table. Lahat ng tatlong probe ay inaasahang `EXPECTED_RED`.

### State ownership

Ang legacy stone table at `legacyStoneRowsBuilt=46` ay nakaimbak lamang sa invocation context na gumawa sa mga ito. Ang ibang invocation ay nananatiling malinis.

### Hindi pa kasama

Wala pang `stonePatch`, walang preserved legacy clone, walang legacy-garbage capture, at walang snapshot-based overwrite ng limang field. Ang mga iyon ay para sa Patch 04 sa susunod na stage.

## Stage 9 — Patch 04: snapshot sa ibabaw ng legacy stone mutation

Hindi binago ang `mutateStonesWrong`.

Ang `stonePatch` ay kumukuha muna ng old snapshot. Pagkatapos, pinapatakbo nito ang raw legacy mutator sa hiwalay na clone at kinukuha ang maling `legacy garbage`. Sa huli, lahat ng limang field ng garbage object ay dini-deterministically overwrite gamit lamang ang old snapshot.

Sa row 2, ang legacy garbage `w` ay nagkataong tama at ang `b/s/m/r` ay mali; pagkatapos ng overwrite, lahat ng limang field ay normative.

Ang patched builder ay gumagamit ng `stonePatch` sa rows 2–46. Ang 45 trace entries ay nagpapatunay na hindi nilaktawan ang historical call.

Ang production context ay nagtatago ng:
- `patch04RowsPatched`;
- `patch04LastOldStones`;
- `patch04LastLegacyGarbage`;
- `patch04LastCommittedStones`.

Ang mga scar state na ito ay invocation-local lamang.

Wala pang Stage 10 o anumang susunod na historical defect/patch.
