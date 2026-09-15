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

## Stage 10 — Discovery 05: backward hidden-drop storage

### Historical physical layout

Ang hidden-drop layer ay hindi nag-imbak ng hidden values sa near-ness order. Sa halip:

```text
legacyHidden[1] = hidden7
legacyHidden[2] = hidden6
legacyHidden[3] = hidden5
legacyHidden[4] = hidden4
legacyHidden[5] = hidden3
legacyHidden[6] = hidden2
legacyHidden[7] = hidden1
```

Ang coefficient table ay nakaimbak ding reversed bilang historical layout scar, ngunit ang `Get-Discovery05CoeffForHidden` ay ginagamit ang tamang coefficient para sa mismong hidden computation. Ang bagong Discovery 05 defect ay nasa access layer, hindi sa coefficient selection.

### Historical access defect

Ang unang near-ness accessor ay ipinagpalagay na ang physical storage ay forward:

```text
legacyHiddenDirectByAssumedNearness(storage, k)
    -> storage[k]
```

Kaya ang `hidden1` request ay nagbabalik ng `hidden7`, at ang `hidden2` request ay nagbabalik ng `hidden6`.

Ang `hidden4` ay fixed midpoint at nagkataong tama.

### Production route

Pagkatapos ng Patch 04 stone table, ang tunay na production route ay gumagawa ng backward hidden storage at aktuwal na gumagawa ng maling `k=1` direct read.

Ang storage, hidden count, last requested k, at last returned value ay invocation-owned semantic state.

### EXPECTED_RED contract

Sa `k=1,2,4,6,7`, eksaktong apat ang divergent (`1,2,6,7`) at eksaktong isa ang MATCH (`4`).

Wala pang `hiddenByNearness` Patch 05 translator at walang Stage 11 correction.

## Stage 11 — Patch 05: 8-k translator sa backward hidden storage

### Ano ang hindi binago

Nananatiling backward ang physical hidden storage:

```text
slot 1 = hidden7
slot 2 = hidden6
slot 3 = hidden5
slot 4 = hidden4
slot 5 = hidden3
slot 6 = hidden2
slot 7 = hidden1
```

Nananatili ring pisikal ang historical wrong direct accessor:

```text
legacyHiddenDirectByAssumedNearness(storage,k)
    -> storage[k]
```

### Correction layer

Ang hiwalay na `hiddenByNearness` translator ay gumagamit ng:

```text
storage[8-k]
```

Ito ang eksaktong inverse ng physical write position ng hidden `k`.

### Preserved scar execution

Ang `Invoke-Patch05HiddenNearnessRepair` ay hindi nilalaktawan ang lumang defect. Una nitong tinatawag ang wrong direct accessor at iniimbak ang raw value. Pagkatapos lamang nito binabasa ang corrected `8-k` slot.

Ang context ay invocation-local na nagtatago ng:
- requested `k`;
- translated physical slot;
- legacy direct value;
- corrected value;
- applied status;
- invocation count.

### GREEN contract

Lahat ng pitong `k=1..7` corrected reads ay dapat tumugma sa test-only normative hidden values.

Ang raw `k=1` direct accessor ay dapat manatiling `hidden7` at manatiling mali laban sa normative `hidden1`.

Wala pang Stage 12 `legacyPrior`, `priorPatch`, visible-history adapter, o anumang mas huling correction.

## Stage 12 — Discovery 06: hindi alam ng visible history ang hidden history

### Historical helper

Ang unang prior/history helper ay visible store lamang ang alam:

```text
legacyPrior(dropStore, i, back)
    -> dropStore[i-back]
```

Kapag positive ang `i-back`, normal na visible slot ang nababasa nito.

Kapag `i-back <= 0`, walang nakalaang hidden-history translation.

### Normative hidden timeline

Ang nonpositive history slots ay dapat tumukoy sa hidden drops:

```text
slot 0  -> hidden1
slot -1 -> hidden2
slot -2 -> hidden3
...
slot -6 -> hidden7
```

Hindi alam ng raw helper ang mapping na ito.

### Production route

Hindi pa sinisimulan ang visible-drop computation. Sa halip, ang tunay na production chain ay nagpapatakbo ng valid probe na `i=2, back=1`, kaya `slot=1`.

Ang probe store slot 1 ay naglalaman ng kasalukuyang corrected Patch 05 hidden value. Ang probe ay patunay lamang na nasa real chain ang raw helper at hindi ito ginagamit bilang bagong calendar semantic input.

### EXPECTED_RED contract

Ang tunay na adapter ay sinusukat sa tatlong missing-history cases:

```text
i=1, back=1 -> slot 0  -> hidden1
i=1, back=3 -> slot -2 -> hidden3
i=1, back=7 -> slot -6 -> hidden7
```

Dahil visible store lamang ang raw helper, lahat ng tatlo ay walang value at lahat ay `EXPECTED_RED`.

### Invocation-owned scar state

Ang context ay nagtatago ng:
- `legacyPriorI`;
- `legacyPriorBack`;
- `legacyPriorSlot`;
- `legacyPriorValue`;
- `legacyPriorProbeValue`;
- Discovery 06 status at invocation count.

### Hindi pa kasama

Wala pang `priorPatch`, walang `hiddenK=1-slot`, at walang `hiddenByNearness` fallback sa Discovery 06. Hindi pa sinisimulan ang visible-drop grind logic o anumang Stage 13+ correction.

## Stage 13 — Patch 06: nonpositive history slots papunta sa hidden history

### Preserved raw scar

Hindi binago ang `legacyPrior`:

```text
legacyPrior(dropStore, i, back)
    -> dropStore[i-back]
```

Ang helper na ito ay visible-only pa rin at walang kaalaman sa hidden history.

### Correction layer

Ang hiwalay na `priorPatch` ay gumagamit ng computed slot:

```text
slot = i - back

if slot >= 1:
    return legacyPrior(dropStore, i, back)

hiddenK = 1 - slot
return hiddenByNearness(legacyHidden, hiddenK)
```

Sa positive branch, talagang tinatawag ang raw legacy helper at hindi kinakailangan ang hidden storage.

Sa nonpositive branch, hindi tinatawag ang raw helper. Sa halip, ang exact `hiddenK=1-slot` mapping ay ipinapasa sa Stage 11 near-ness translator.

### Stage 12 regression becomes GREEN

Ang dating red mapping ay:

```text
slot 0  -> hidden1
slot -2 -> hidden3
slot -6 -> hidden7
```

Lahat ng tatlo ay GREEN na sa patched adapter.

### Invocation-owned branch state

Ang context ay nagtatago ng:
- `patch06Slot`;
- `patch06UsedHidden`;
- `patch06HiddenK`;
- `patch06Value`;
- `patch06Applied`;
- Patch 06 status at invocation count.

Ang Stage 12 coordinates na `legacyPriorI`, `legacyPriorBack`, `legacyPriorSlot`, at `legacyPriorValue` ay nananatili rin.

### Production route

Ang tunay na production probe ay nananatiling `i=2, back=1, slot=1`.

Dahil positive slot ito, talagang dumadaan ang production route sa raw `legacyPrior` sa loob ng Patch 06.

### Hindi pa kasama

Wala pang Stage 14 `legacyGrindRow`, `LEGACY_VISIBLE_GRIND_TABLE`, sentinel row, o visible-drop builder.

## Stage 14 — Discovery 07: one-based grind ordinal laban sa zero-based table

### Historical physical table

Ang visible-grind table ay may labing-isang totoong row lamang at zero-based ang physical indexing:

```text
index 0  = [3,5,7,11,WHEAT]
index 1  = [5,7,11,13,BARLEY]
index 2  = [7,11,13,17,SALT]
index 3  = [11,13,17,19,BITTER]
index 4  = [13,17,19,23,RED]
index 5  = [17,19,23,29,WHEAT]
index 6  = [19,23,29,31,BARLEY]
index 7  = [23,29,31,37,SALT]
index 8  = [29,31,37,41,BITTER]
index 9  = [31,37,41,43,RED]
index 10 = [37,41,43,47,WHEAT]
```

### Historical defect

Ang semantic grind ordinal ay `1..11`, ngunit ang raw helper ay direktang ginagamit iyon bilang zero-based array index:

```text
legacyGrindRow(grind)
    -> table[grind]
```

Kaya ang ordinals `1..10` ay laging nakakakuha ng susunod na row, at ang ordinal `11` ay undefined.

### Production route

Ang Stage 13 Patch 06 production probe ay nananatiling buo at GREEN.

Pagkatapos nito, ang tunay na route ay gumagawa ng neutral Discovery 07 probe sa `grind=1`:

```text
LegacyGrindTableAdapter
-> Discovery07GrindIndexHandler
-> legacyGrindRow(1)
-> physical index 1
-> semantic row 2
```

Hindi ginagamit ang row bilang bagong calendar semantic input.

### EXPECTED_RED contract

Ang lahat ng semantic grind ordinals `1..11` ay divergent laban sa normative row na may parehong ordinal.

Exact count:

```text
EXPECTED_RED = 11
MATCH = 0
```

### Invocation-owned scar state

Ang context ay nagtatago ng:
- requested grind ordinal;
- direct physical index;
- returned legacy row;
- undefined flag;
- production probe row;
- Discovery 07 status at invocation count.

### Hindi pa kasama

Wala pang sentinel row, walang `GRIND_TABLE_WITH_SENTINEL`, walang `grindRowWithSentinel`, at walang visible-drop builder. Ang mga iyon ay para sa Patch 07 sa Stage 15.

## Stage 15 — Patch 07: sentinel wrapper sa zero-based grind table

### Preserved raw scar

Hindi binago ang Stage 14 `LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED` o `legacyGrindRow`.

Patuloy na mali ang raw helper:

```text
legacyGrindRow(1)  -> raw row 2
...
legacyGrindRow(10) -> raw row 11
legacyGrindRow(11) -> undefined
```

### Correction layer

Ang Patch 07 ay nagdaragdag ng hiwalay na sentinel row:

```text
[0,0,0,0,NONE]
```

at bumubuo ng:

```text
GRIND_TABLE_WITH_SENTINEL[0]  = sentinel
GRIND_TABLE_WITH_SENTINEL[1]  = raw row 1
...
GRIND_TABLE_WITH_SENTINEL[11] = raw row 11
```

Kaya:

```text
grindRowWithSentinel(g)
    -> GRIND_TABLE_WITH_SENTINEL[g]
```

ay GREEN para sa lahat ng `g=1..11`.

### Preserved scar execution

Ang `Invoke-Patch07GrindRowRepair` ay hindi nilalaktawan ang Stage 14 defect. Una nitong tinatawag ang `LegacyGrindTableAdapter`, kaya aktuwal na tumatakbo ang raw `legacyGrindRow`. Pagkatapos lamang nito kinukuha ang corrected sentinel-indexed row.

Ang context ay nagtatago ng:
- requested grind;
- sentinel index;
- raw legacy row;
- corrected row;
- applied flag;
- Patch 07 status at invocation count.

### Production route

Ang production probe ay nananatiling `grind=1`.

Ang raw scar ay `row 2`; ang authoritative Patch 07 result ay `row 1`.

### Hindi pa kasama

Wala pang visible-drop builder, `visibleDropThroughCurrentLayers`, permutation-unrank scar, o anumang Stage 16+ layer.

## Stage 16 — Discovery 08: one-based ordinal na direktang ipinasa sa zero-based permutation helper

Ang `oldPermutationUnrank0(rank0)` ay nananatiling zero-based at tama sa `0..719`. Ang historical caller ay nagko-compute ng `oneBasedOrdinal = regularMod(drop-1,720)+1` ngunit ipinapasa iyon nang direkta bilang `rank0`.

Samakatuwid, ordinal `1` ay nagbabalik ng permutation 2, ordinal `719` ay nagbabalik ng permutation 720, at ordinal `720` ay undefined. Lahat ng 720 ordinals ay `EXPECTED_RED`.

Ang production route ay gumagamit lamang ng neutral `dropValue=1` probe at hindi pa nagsisimula ng bowl-pour logic. Wala pang Patch 08 bridge na nagbabawas ng isa.

