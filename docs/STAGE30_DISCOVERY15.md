# ደረጃ 30/55 — DISCOVERY 15: five-component output contract

## የታየው ችግር
The public calendar_date_spaghetti entrypoint currently returns a PATCH_12 diagnostic error even for valid calculation/target days; the full 46-visible-drop chain and final calendar assembly are not yet integrated. This is separate from the verified PATCH14 arithmetic.

The final CalendarResult must have exactly five fields, in order: year_number, cutlet_name, day_in_cutlet, month_name, day_in_month. A deterministic independent SHAPE oracle checks canonical cutlet/month membership against the 17/47 locked names, positive one-based day indices and five-field projection. It does NOT check the exact normative values of the resulting date. The latter requires subsequent calendar integration and an independent full-date oracle; do not claim numerical correctness here.

## የሙከራ ምስክሮች
GREEN: fixed signed-year five-part witness; four negative controls (empty cutlet, zero cutlet day, empty month, zero month day); five anchor offsets -2,-1,0,+1,+2 that continue to return the PATCH12 diagnostic.
EXPECTED_RED: valid public-date shape for foundation, foundation±1 and distinct calculation/target inputs (four separate assertion names). Compilers errors and panics are not acceptable substitutes for intentional RED assertions.

## Native gate
- Pinned V 0.5.2 7647ce1; V fmt -verify.
- Preserve all prior 43 GREEN files from Stage29.
- Check and run new discovery15_witness_test.v GREEN.
- V -check new discovery15_expected_red_test.v SUCCESS; V test expected RED with four named failure witnesses; no compiler error/panic.
- 45 total V test files (43 previous, one GREEN witness, one intentionally RED).
- Completed GitHub job/log evidence is required for Stage30 acceptance; no PASS claim based on queued/in_progress.
- No main edit, merge or publication.

## Stage31
PATCH15 must start integrating the missing date assembly, ultimately comparing exact five-field date values to the existing independent normative oracle. Shape checking alone is insufficient for correctness.
