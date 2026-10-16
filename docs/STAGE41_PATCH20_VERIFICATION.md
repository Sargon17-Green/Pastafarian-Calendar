# Stage41 PATCH20 — authoritative first-day structure Sauce

## Why Stage40's original wrong Sauce must still physically execute

The canonical Library `06-implementation-prompt.md` section 13 requires:

```text
ghost = oldStructureSauce(cDay, originalTargetDay)
mustUse = year.openDay + 1
if originalTargetDay != mustUse:
    return sauceWithScars(cDay, mustUse)
return ghost
```

The Stage40 bad source is `LegacyStructureSauceAdapter.oldStructureSauce(cDay, originalTargetDay, source)`. Its original target is physically queried after full Stage39 corrected Year5000 and the original Stage38 wrong cache. It makes 46 native drop computations, twelve post-stirs and 58 actual shared memory writes while retaining a correct DROP46 latch. It must remain unchanged and must never be replaced by a test-only normative oracle.

`src/patch20StructureSauce.ts` adds `Patch20StructureSauceHandler` and `patch20StructureSauce`. The handler **first physically invokes the entire** `discoverLegacyStructureSauce` predecessor through the original Stage40 handler, recording the old wrong Sauce as an immutable `historical.oldSauce`. It verifies the authentic `correctedServed.year` from Stage39 and obtains `trueYearFirstDay=year.openGateDay+1n`.

When the original target differs from the true first day, it requires a completely separate first-day-native `Patch18Question` whose target exactly equals that first day, then physically calls `patch11OrderLatch(cDay,trueYearFirstDay,visible,stones,startBowls)`: the whole historical 46-drop/12-stir chain and corrected DROP46 latching perform another **58 actual shared writes**. Only this newer result's six `finalBowls` and latched `orderAt46Latch` are authoritative for the structure. The old source remains in `historical.oldSauce`, never used as the authoritative answer. If original target **already equals** first day, the old physical Sauce result is correct and is reused without a duplicate helper/58 writes. Both branches commit to the outer caller-owned context only after all fallible predecessor and new native Sauce calls succeed.

The first-day question source must be independently prepared by caller and validated by the actual native Patch11 production chain. The implementation does not yet independently generate the source; this is staged API work and is not the complete Stage54 calendarDateSpaghetti implementation. No Stage42 cutlet partition/filter code has been implemented. No test-only normative oracle imports in production.

## Verification evidence and intentional historical scar

`test/patch20.ts` verifies two genuinely independent Year5000 action dates (true original source questions, Stage37 real signed gates, Stage38 original wrong cache, Stage39 triple guard), checks that original helper and corrected Patch11 helper **actually** executed twice, compares all six authoritative bowls and DROP46 order against independently computed `sauce(c,trueYearFirstDay)`, and checks archived old Sauce still equals `sauce(c,originalTargetDay)` and is demonstrably wrong. It verifies correct count of 58-memory-write chains and immutable original snapshots; a third case sets the target to the true first day, proving zero second Sauce invocations and reuse of the actual old result. Negative tests include unready context, contradictory historical target, wrong first-day question, injected deep failure in either original ghost or the corrected first-day helper, semantic state rollback, same-context retry, independent instance state, and Stage54 barrier.

`test/patch20Properties.ts` verifies 128 direct genuine native first-day sauces with test-only independent canonical answers, including 64 8192-bit signed action days, 720 distinct explicit DROP46 permutations checked against independent bowl replay and post-stir calculation, eight enormous signed injected source/bowl values (explicitly noncanonical test inputs), and two complete true Year5000 Stage39+40+41 routes. It compares all 58-write ledgers, immutability and no added extra work on exact first-day coincidence.

All **twenty** historical deliberately failing discovery witnesses are still run through their expected-red verifiers by the existing `npm test`. Completion requires both independent GitHub Actions jobs (native tsc + full Stage1–41 suite, and frozen source language catalog/hash) to pass. The authorizing Stage40 previous signing CI run is 38894027444 and the last signed branch HEAD is cedefb455ca47ff17e4e6766e960b468b2d8dc06. No Stage42 or main branch edits.
