# ഘട്ടം 1 oracle നടപ്പാക്കൽ മാപ്പ്

ഈ മാപ്പ് Appendix A-യിലെ നിർബന്ധിത ഭാഗങ്ങളെ SPL test-only oracle-ലേക്ക് മാറ്റേണ്ട ജോലി രേഖപ്പെടുത്തുന്നു. പൂർത്തിയായതായി അടയാളപ്പെടുത്തിയിട്ടില്ലാത്ത ഭാഗം Stage 1-ന്റെ blocker തന്നെയാണ്.

## ഇതിനകം source/probe ആയി പ്രത്യക്ഷപ്പെട്ട അടിസ്ഥാനങ്ങൾ

- `SourceLanguageCatalog`: 17 + 47 canonical പേരുകൾ, index-സ്ഥിരത, മലയാള presentation source.
- നിഷ്പക്ഷ production bootstrap skeleton: future patch ഒന്നുമില്ല.
- runtime exact-integer capability contract.
- `M = 2^127 - 1` നിർമ്മിക്കാൻ കഴിയേണ്ട വലിയ integer probe.
- `FOUNDATION_DAY=-15055671` source-ലുതന്നെ decimal construction വഴി നിർമ്മിക്കുന്ന primitive oracle.
- Euclidean `regularMod`-ന്റെ negative-remainder correction.
- `SAVE(x)=1+regularMod(x-1,M)`-ന്റെ source path.
- Foundation day-ന്റെ `dayCount` മൂന്ന് branches.
- `workCounts`: action, target, chronological distance `abs(t-c)+1`, connection, direction.
- short selection-ന്റെ `acceptanceLimit=floor(M/N)*N`, same-ring rejection step, final unbiased rank എന്നിവയ്ക്കുള്ള SPL probe.
- primitive expectations-ന്റെ സ്വതന്ത്ര പട്ടിക; മറ്റൊരു implementation output ഉപയോഗിച്ചിട്ടില്ല.

## പൂർണ്ണ test-only oracle-ൽ ഇനിയും എഴുതേണ്ട ഭാഗങ്ങൾ

- `ceilDiv`, `wrap1` എന്നിവയുടെ പൊതുവായ exact helpers.
- 46-row stone table.
- 7 hidden drops.
- 46 visible drops, 11 grinds ഓരോ drop-ലും.
- 6 bowls, per-drop permutation, pours, simultaneous stir.
- 12 post-stirs, 1A വായനയായ `SAVE(sum(oldBowls)+149*stirNumber)` ഒരേയൊരു saved value ആയി.
- `askBowl`, latched drop-46 order, answer ring.
- short/wide selection source probes നിലവിലുണ്ട്; full-oracle integration ഇനിയും വേണം.
- gate generation ഇരുവശത്തേക്കും.
- year 5000 candidate family, `252..5778`, tie order.
- sequential next/previous year walk.
- cutlet count, filtered partition family, distinct name unrank.
- month count, bounded composition count/unrank.
- whole-weaving count/unrank.
- distinct month name unrank.
- final five-field tuple.
- end-to-end fixtures/expected outputs, oracle തന്നെ SPL-ൽ കണക്കാക്കി വീണ്ടും ഉറപ്പിച്ചവ.

പൂർണ്ണമായ oracle source ഇല്ലാതെ Stage 1 പൂർത്തിയായതായി പ്രഖ്യാപിക്കരുത്. ഈ മാപ്പ് implementation substitute അല്ല; ശേഷിക്കുന്ന ജോലിയുടെ കൃത്യ പട്ടിക മാത്രമാണ്.

## ഇപ്പോഴത്തെ അധിക oracle slice

ഈ പുരോഗതി ചുറ്റിൽ Appendix A-യുടെ അടുത്ത ഭാഗങ്ങൾ executable SPL probe-ുകളായി വേർതിരിച്ചു:

- `test/stack_memory_probe.spl`: character stack-ുകളുടെ LIFO runtime gate;
- `test/stone_step_probe.spl`: അഞ്ചു കല്ലുകളുടെ simultaneous-old-snapshot recurrence;
- `test/hidden_drop_trace_probe.spl`: ഒരു hidden row-യുടെ coefficient തിരഞ്ഞെടുപ്പ്, seed, ഏഴ് grind-ുകൾ;
- `test/visible_seed_probe.spl`: visible-drop seed formula, predecessor inputs നേരിട്ട്;
- `test/visible_grind_step_probe.spl`: visible grind recurrence-ന്റെ generic ഒറ്റ ചുവട്.

ഇവ പൂർണ്ണ oracle-ന്റെ substitute അല്ല. ഇനി source-ൽ ബന്ധിപ്പിക്കേണ്ട പ്രധാന ഭാഗങ്ങൾ: 46 stone rows-ന്റെ storage/recomputation policy, ഏഴ് hidden values-ന്റെ timeline mapping, 46 visible drops-ന്റെ rolling predecessor state, six-bowl ordering/pours/stirs, post-stir 12, answer stream, gates, years, cutlets, months, weaving, final five-field resolver.

Stage 1-ൽ ഇതുവരെ patch-specific legacy code ഒന്നും ചേർത്തിട്ടില്ല.

## ഈ പുരോഗതി ചുറ്റിലെ പുതിയ exact slices

- `test/visible_eleven_grinds_probe.spl`: ഒരേ predecessor snapshot നിലനിർത്തി പതിനൊന്ന് visible grind recurrence-ുകൾ തുടർച്ചയായി നടത്താനുള്ള loop gate.
- `test/answer_at_probe.spl`: `first`, സ്ഥിര `directionStep`, offset എന്നിവയിൽ നിന്നുള്ള exact answer-ring സ്ഥാനം.
- `test/factoradic_rank6_probe.spl`: 1..720 one-based rank-നെ `[120,24,6,2,1]` blocks വഴി ആറു zero-based factoradic തിരഞ്ഞെടുപ്പ് സൂചികകളാക്കി തുറക്കുന്നു.
- `test/year_candidate_predicate_probe.spl`: Appendix A-യിലെ `gaps >= 6` കൂടാതെ `252..5778` year-pair validity predicate source-ൽ ഉറപ്പിക്കുന്നു.

ഇവ full calendar oracle അല്ല. പ്രത്യേകിച്ച് factoradic സൂചികകളെ remaining bowl IDs-ൽ നിന്ന് യഥാർത്ഥ permutation ആയി materialize ചെയ്യൽ, 46 visible drops-ന്റെ rolling timeline, bowls/post-stirs, sauce query, gates, years, cutlets, months, weaving, final five-field resolver എന്നിവ ഇനിയും ബന്ധിപ്പിക്കണം.

## ഈ തുടർച്ചയിൽ ചേർത്ത bowl/sauce exact slices

- `test/initial_bowl_formula_probe.spl`: `initialBowls`-ന്റെ ഒരു സ്ഥിര bowl ID-യ്ക്കുള്ള exact formula.
- `test/pour_triplet_probe.spl`: drop order-ിലെ position 1..3-ക്ക് wheat/barley/salt പകർച്ചകൾ; സ്ഥിര bowl 1..3 എന്ന തെറ്റായ വായന ഇല്ല.
- `test/bowl_shadow_stir_probe.spl`: ഒരേ പഴയ snapshot-ിൽ നിന്ന് pending bowl scalar കണക്കാക്കുന്ന formula.
- `test/post_stir_saved_sum_probe.spl`: 1A പ്രകാരമുള്ള ഏക `SAVE(sum(oldBowls)+149*stir)` value.
- `test/post_stir_bowl_probe.spl`: post-stir-ിലെ ഒരു order position-ന്റെ pending bowl formula.
- `test/latched_order_successor_probe.spl`: തുള്ളി 46-ൽ പൂട്ടിയ order-ിൽ circular next-bowl lookup.
- `test/ask_bowl_probe.spl`: `first` answer-ഉം ഒരിക്കൽ മാത്രം നിശ്ചയിക്കുന്ന direction step-ഉം.

ഇവകൊണ്ട് bowls/sauce മേഖലയുടെ scalar semantics source-ൽ കൂടുതൽ അടഞ്ഞുവെങ്കിലും full 46-drop orchestration, ആറു bowls-ന്റെ simultaneous rounds, 12 post-stirs-ന്റെ മുഴുവൻ chain, factoradic digits-ൽ നിന്ന് actual permutation materialization എന്നിവ ഇനിയും വേണം. Gate/year/cutlet/month/weaving/final tuple ഭാഗങ്ങളും ഇനിയും blocker ആണ്.

## ഈ തുടർച്ചയിലെ permutation/helper/orchestration പുരോഗതി

ഈ revision-ൽ Stage 1 clean oracle-ന്റെ താഴെപ്പറയുന്ന ഭാഗങ്ങൾ കൂടി SPL source ആയി ചേർത്തു:

- `test/select_kth_remaining_probe.spl`: factoradic digit-നെ active remaining bowl ID-യിൽ resolve ചെയ്യുന്ന primitive;
- `test/wrap1_probe.spl`: 1-based circular wrapping, negative position ഉൾപ്പെടെ;
- `test/ceil_div_probe.spl`: non-negative exact ceiling division;
- `test/six_bowl_round_control_probe.spl`: ആറു order positions-ന്റെ shared-old-snapshot scalar loop-ിനുള്ള control fixture;
- `test/month_count_bounds_probe.spl`: `ceilDiv(L,123)` മുതൽ `min(47,floorDiv(L,4))` വരെ month-count bounds;
- `test/falling_factorial_probe.spl`: distinct-name ordered family count-ന്റെ exact arithmetic.

ഇതോടെ factoradic decomposition-നും actual remaining-item selection-നും ഇടയിലെ primitive gap ചുരുങ്ങി. എന്നിരുന്നാലും ആറു factoradic digits തുടർച്ചയായി പ്രയോഗിച്ച് active-set mutate ചെയ്യുന്ന full permutation function ഇനിയും source-ൽ ബന്ധിപ്പിച്ചിട്ടില്ല. 46-drop rolling timeline, generic six-bowl round, 12 post-stir chain, gates, year traversal, cutlet partition DP, bounded month composition DP, whole-weaving DP, name unranking, final resolver എന്നിവയും blocker ആയി തുടരുന്നു.

## ഈ തുടർച്ചയിലെ timeline/year-boundary control slices

ഈ revision-ൽ full oracle-ലേക്ക് നേരിട്ട് ആവശ്യമായ അഞ്ചു control primitives കൂടി SPL source ആയി ചേർത്തു:

- `test/timeline_source_mux_probe.spl`: `slot=i-back` positive ആണെങ്കിൽ visible predecessor, zero/negative ആണെങ്കിൽ `hiddenIndex=1-slot` എന്ന mapping;
- `test/post_stir_twelve_schedule_probe.spl`: stir 1..12 എണ്ണം കൃത്യമായി കടന്നുപോകുന്ന 1A saved-sum schedule control;
- `test/year_interval_membership_probe.spl`: വർഷം `[open,close]` അല്ല, നിർബന്ധിതമായി `(open,close]` ആണെന്ന membership gate;
- `test/cutlet_required_boundary_probe.spl`: calculation gate internal exact gate ആണെങ്കിൽ മാത്രം required prefix boundary offset;
- `test/target_year_walk_direction_probe.spl`: `target>close` next, `target<=open` previous, മറ്റെല്ലാം current എന്ന sequential-walk control.

ഇവ scalar/control semantics അടയ്ക്കുന്നു; full rolling 46-drop value store, actual six-ID permutation materialization, six bowls-ന്റെ generic simultaneous commit, 12 post-stir bowl-state chain, gate generation/cache, year candidate enumeration/selection, composition/unranking DP, weaving DP, final five-field resolver എന്നിവ ഇനിയും blocker ആണ്.

## ഈ തുടർച്ചയിലെ full-permutation/combinatorics/weaving പുരോഗതി

ഈ revision-ൽ clean Stage 1 oracle-ന്റെ അഞ്ചു ഭാഗങ്ങൾ കൂടി SPL source ആയി ചേർത്തു:

- `test/permutation_materialize6_probe.spl`: ആറു factoradic digits active-set removal സഹിതം actual six-ID permutation ആക്കുന്നു;
- `test/bounded_composition_window_probe.spl`: bounded-composition suffix-ിൽ അടുത്ത lexicographic value-ന്റെ exact inclusive feasibility window;
- `test/weave_move_legality_probe.spl`: `legalWeaveMove`-ന്റെ remaining/open/close ordering predicate;
- `test/weave_state_transition_probe.spl`: legal move-ന്റെ `applyWeaveMove` state update;
- `test/month_occurrence_prefix6_probe.spl`: final `dayInMonth`-ന്റെ inclusive occurrence count ചെറിയ weaving prefix-ിൽ.

ഇതോടെ permutation materialization-ന്റെ മുൻ primitive gap source-ൽ അടഞ്ഞു. എന്നിരുന്നാലും `rank1 -> factoradic digits -> permutation` ഒരൊറ്റ integrated routine ആയി ബന്ധിപ്പിക്കൽ, rolling 7+46 drop values, 46 bowl rounds, 12 post-stir state chain, lazy gates, year candidate enumeration/selection, full composition count/unrank memo, full weaving Count/Unrank memo, distinct-name unrank, final five-field resolver എന്നിവ ഇനിയും blocker ആണ്.

## ഈ തുടർച്ചയിലെ gate/year/name integration primitives

ഈ revision-ൽ clean Stage 1 oracle-ന്റെ അഞ്ചു അടുത്ത ബന്ധങ്ങൾ കൂടി SPL source ആയി ചേർത്തു:

- `test/permutation_rank_first_block_probe.spl`: one-based permutation rank-ന്റെ ആദ്യ 120-size lexicographic block-ും residual rank-ും ഒരൊറ്റ source path-ൽ;
- `test/gate_question_day_probe.spl`: signed gate step-ന്റെ positive/negative question-day semantics;
- `test/gate_accumulate_three_probe.spl`: known gate-ിൽ നിന്ന് മൂന്ന് exact gaps ഒരേ signed ദിശയിൽ accumulate ചെയ്യൽ;
- `test/year5000_candidate_filter_probe.spl`: `gaps>=6`, `252..5778`, `(open,close]` calculation-day containment എന്നിവ ഒരൊറ്റ clean candidate predicate-ൽ;
- `test/distinct_name_first_choice_probe.spl`: falling-factorial block ഉപയോഗിച്ച് distinct-name lexicographic unrank-ന്റെ ആദ്യ candidate ordinal/residual rank.

ഇവ full oracle-ന്റെ സഹായക integration slices ആണ്. 720-rank-നെ ആറ് factoradic decisions വഴി permutation-ൽ പൂർണ്ണമായി ബന്ധിപ്പിക്കുന്ന ഒറ്റ routine, gate gap-ുകൾ sauce/answer selection-ൽ നിന്ന് യഥാർത്ഥമായി സൃഷ്ടിക്കുന്ന lazy cache, year candidate enumeration/sort/selection, repeated distinct-name positions, full cutlet/month composition DP, full weaving DP, final five-field resolver എന്നിവ ഇനിയും blocker ആണ്.

## പുതിയ clean-reference slices

### Gate/year ordering

- `test/gate_gap_choice_probe.spl` — selector rank `1..922` മുതൽ gap `42..963` വരെ.
- `test/year5000_pair_order_probe.spl` — candidate pair sort: length ascending, tie-ൽ open day ascending.

ഇനി വേണ്ടത്: sauce/ask/chooseRank മുതൽ gap creation വരെ full call path, lazy indexed gate store, Year 5000 candidate enumeration, list sort, selected rank materialization, next/previous year candidate lists, sequential walk.

### Structure candidate ranges

- `test/cutlet_count_candidate_count_probe.spl` — cutlet count candidate family size.
- `test/month_count_rank_resolve_probe.spl` — month count lower/upper bounds + selected rank.

ഇനി വേണ്ടത്: chosen cutlet count-ിൽ filtered positive-composition DP; chosen month count-ിൽ bounded-composition general memo/count/unrank.

### Distinct names

- `test/distinct_name_two_choice_probe.spl` — ആദ്യ രണ്ടു positions removal-aware original canonicalIndex mapping സഹിതം.

ഇനി വേണ്ടത്: arbitrary `k` positions മുഴുവൻ loop ചെയ്ത് remaining canonicalIndex list mutate ചെയ്യുന്ന general unrank routine; presentation layer-ൽ മാത്രം SourceLanguageCatalog string resolve ചെയ്യൽ.

### Exact family base cases

- `test/bounded_composition_two_slot_probe.spl` — slots=2 bounded family exact count/unrank base slice.
- `test/weave_two_month_count_probe.spl` — m=2 weaving-family exact cardinality sanity slice.

ഇനി വേണ്ടത്: arbitrary slots-ിന്റെ memoized bounded-composition suffix counter/unrank, arbitrary month-count weaving state memo CountWeavings + lexicographic unrank.

## പുതിയ clean-reference integration slices — rank-to-order, മൂന്ന്-slot DP, final resolver helpers

ഈ continuation-ൽ clean Stage 1 oracle-ന്റെ അടുത്ത എട്ട് source slices ചേർത്തു:

- `test/bowl_order_rank6_integrated_probe.spl`: one-based rank `1..720` -> factoradic digits -> removal-aware six-ID permutation, ഒരൊറ്റ source path;
- `test/cutlet_count_rank_resolve_probe.spl`: `6..min(17,gateGaps)` family count + one-based rank resolve;
- `test/bounded_composition_three_slot_count_probe.spl`: slots=3 bounded family exact count;
- `test/bounded_composition_three_slot_unrank_probe.spl`: slots=3 lexicographic unrank;
- `test/cutlet_partition_three_slot_filter_probe.spl`: മൂന്ന് positive cutlet parts-ൽ required prefix boundary filter + exact count/unrank;
- `test/cutlet_day_resolve_three_probe.spl`: materialized cutlet intervals-ൽ canonicalIndex + inclusive day position resolve;
- `test/weave_offset_select6_probe.spl`: year offset-ിൽ നിന്ന് weaving monthId resolve;
- `test/distinct_name_third_mapping_probe.spl`: രണ്ടു removals കഴിഞ്ഞ third remaining ordinal original canonicalIndex ordinal-ിലേക്ക് map ചെയ്യൽ.

ഇതോടെ rank-to-permutation integration blocker ചെറിയ ആറു-ID domain-ിൽ source-ൽ അടഞ്ഞു. bounded composition slots=2 base-ൽ നിന്ന് slots=3 വരെ exact count/unrank ഉയർന്നു; cutlet partition-ന്റെ required-boundary semantics ചെറിയ മൂന്ന്-part family-ൽ count/unrank സഹിതം source-ൽ പ്രവർത്തനരൂപം നേടി. final resolver-ന്റെ cutlet half-ും weaving-offset selection half-ും ഇപ്പോൾ വേർതിരിച്ച exact helpers ആയി ഉണ്ട്.

ഇനി പ്രധാന blockers:

- 7 hidden + 46 visible values ഒരൊറ്റ rolling timeline-ൽ സംയോജിപ്പിക്കൽ;
- ഓരോ 46 drop-ലും integrated rank-to-order, pours, six old-snapshot reads, six pending writes, simultaneous commit;
- 12 post-stirs-ന്റെ full bowl-state chain;
- sauce result -> askBowl -> short/wide chooseRank integrated calls;
- sauce-derived gate gap generation, lazy indexed gate cache, exact gate lookup;
- Year 5000 candidate enumeration/list ordering/selection, next/previous candidate lists, sequential walk;
- arbitrary-K filtered cutlet partition DP `(rem,slots,cumulative,hitBoundary)` count+unrank;
- arbitrary-slot bounded month-length memo/count/unrank;
- arbitrary-m weaving state memo `CountWeavings` + lexicographic unrank;
- arbitrary-k distinct-name unrank മുഴുവൻ positions;
- selected canonicalIndex-ുകളിൽ നിന്ന് frozen മലയാള source strings presentation layer-ൽ resolve ചെയ്യൽ;
- exactly five-field end-to-end calendar result;
- local SPL runtime-ൽ complete GREEN execution.

## പുതിയ clean-reference integration slices — gate lookup, materialization, small weaving unrank, five-field resolver

ഈ continuation-ൽ clean Appendix A oracle-ന്റെ അടുത്ത ആറു source slices ചേർത്തു:

- `test/gate_lookup_four_probe.spl`: ordered gate day-കളിൽ at-or-before / at-or-after / exact ordinal lookup;
- `test/cutlet_materialize_three_probe.spl`: gate boundaries-ൽ നിന്ന് മൂന്ന് `(firstDay,lastDay)` cutlet intervals materialize ചെയ്യൽ;
- `test/weave_three_two_unrank_probe.spl`: lengths `3,2` legal weaving family-യുടെ complete lexicographic unrank sanity slice;
- `test/structure_first_day_probe.spl`: എല്ലാ year-structure ചോദ്യങ്ങൾക്കും `openGateDay+1` target നിർബന്ധമാക്കുന്ന clean reference gate;
- `test/year_number_step_probe.spl`: year number unit-step continuity, zero കടന്നും;
- `test/final_resolver_six_day_probe.spl`: materialized ചെറിയ structure-ൽ canonicalIndex-only semantics ഉപയോഗിച്ച് exactly five fields ഒരൊറ്റ source path-ൽ resolve ചെയ്യൽ.

ഇതോടെ final-resolution ഭാഗം ആദ്യമായി five-field integrated SPL path ആയി source-ൽ കാണപ്പെടുന്നു. ഇത് presentation string resolution അല്ല; canonical indices ആണ് output semantic IDs. gate lookup-നും cutlet materialization-നും ചെറിയ ordered integration slices ലഭിച്ചു; two-month small-family weaving-ിന് count sanity മാത്രമല്ല lexicographic unrank sanityയും ഇപ്പോൾ ഉണ്ട്.

ഇനി പ്രധാന blockers:

- 7 hidden + 46 visible values ഒരൊറ്റ rolling timeline-ൽ exact recurrence സഹിതം ബന്ധിപ്പിക്കൽ;
- ഓരോ 46 drop-ലും order rank, full permutation, pours, six old-snapshot reads, six pending writes, simultaneous commit;
- drop-46 order latch integrated source path;
- 12 post-stirs-ന്റെ മുഴുവൻ six-bowl state chain;
- sauce result -> askBowl -> short/wide selection integrated path;
- sauce-derived gate gaps, arbitrary lazy indexed gate store/cache, monotone lookup;
- Year 5000 candidate enumeration/order/selection, next/previous candidate families, sequential walk;
- arbitrary-K filtered cutlet partition DP memo/count/unrank;
- arbitrary-slot bounded month-length DP memo/count/unrank;
- arbitrary-m weaving `CountWeavings` memo + lexicographic unrank;
- arbitrary-k distinct-name unrank;
- frozen `SourceLanguageCatalog` canonicalIndex-ുകളിൽ നിന്ന് മലയാള source strings presentation layer-ൽ resolve ചെയ്യൽ;
- generated full year structure-ിൽ നിന്ന് end-to-end five-field result;
- local SPL runtime-ൽ complete GREEN execution.

## പുതിയ clean-reference slices — four-slot exact families, post-stir rank, lazy gate/year record controls

ഈ continuation-ൽ ആറു പുതിയ SPL source slices ചേർത്തു:

- `test/post_stir_order_rank_probe.spl`: Appendix A 1A saved value -> `regularMod(saved-1,720)+1` order rank;
- `test/bounded_composition_four_slot_count_probe.spl`: slots=4 exact family cardinality;
- `test/bounded_composition_four_slot_unrank_probe.spl`: slots=4 exact lexicographic member selection;
- `test/weave_two_two_one_unrank_probe.spl`: m=3, lengths `2,2,1` ചെറിയ legal-weave family complete unrank;
- `test/year_transition_record_probe.spl`: selected outer gate ലഭിച്ച ശേഷം next/previous Year record materialization;
- `test/gate_cover_need_probe.spl`: known lazy gate coverage interval-ന്റെ expansion direction predicate.

ഇതോടെ bounded-composition source coverage slots=2 -> 3 -> 4 ആയി വളർന്നു. post-stir 1A scalar probe-ും order-rank derivation-ും ഒരൊറ്റ source path-ൽ ബന്ധപ്പെട്ടു. year walking-ന്റെ മുൻ direction predicate-ിന് പിന്നാലെ actual record boundary ownership source slice ലഭിച്ചു; lazy gate coverage-ന്റെ exact endpoint semantics വേർതിരിച്ചും ഉണ്ട്.

പ്രധാന blockers ഇപ്പോഴും:

- seven hidden + 46 visible exact rolling timeline;
- ഓരോ visible drop-നും 11 grinds, rank-to-order, pours, six pending bowl values, simultaneous commit എന്ന integrated 46-round chain;
- drop-46 order latch clean integrated path;
- 12 post-stirs-ന്റെ actual six-bowl transactional chain, ഓരോ stir-നും saved sum -> order -> six pending values -> commit;
- sauce -> askBowl -> chooseRank integrated dispatcher;
- sauce-derived ± gate gaps, arbitrary indexed lazy gate store/cache, monotone gate lookup;
- Year 5000 full candidate enumeration/order/selection, next/previous candidate generation, sequential target walk;
- arbitrary-K required-boundary cutlet partition memo/count/unrank;
- arbitrary-slot month-length bounded composition memo/count/unrank;
- arbitrary-m weaving state memo `CountWeavings` + lexicographic unrank;
- arbitrary-k distinct-name removal-aware unrank;
- frozen canonicalIndex -> മലയാള source string presentation resolve;
- generated year structure -> exactly five final fields end-to-end;
- local SPL-only runtime GREEN.
- `test/bowl_shadow_stir_probe.spl`: pre-square `s`-ൽ current/prev/next/pour/drop/stone എല്ലാം ചേർത്ത് ശേഷം square ചെയ്യുന്ന രീതിയിലേക്ക് തിരുത്തി.
- `test/post_stir_bowl_probe.spl`: pre-square `s`-ൽ current/prev/next/saved/stir/position^2 എല്ലാം ചേർത്ത് ശേഷം square ചെയ്യുന്ന രീതിയിലേക്ക് തിരുത്തി.
- `test/STAGE_01_EXPECTATIONS.md`: ബന്ധപ്പെട്ട regression fixture-ുകൾ `16846`, `17130` ആയി പുതുക്കി.

## പുതിയ clean-reference integration slices — progress 16

- `test/bowl_round_uniform_snapshot_probe.spl`: six-position visible-drop bowl recurrence, shared old snapshot control.
- `test/post_stir_uniform_round_probe.spl`: 1A saved sum -> six post-stir order-position outputs.
- `test/drop46_latch_twelve_post_probe.spl`: twelve post-stir diagnostic reads കഴിഞ്ഞും drop-46 order rank latch unchanged.
- `test/cutlet_partition_four_slot_filter_probe.spl`: four positive parts, internal required-boundary filter, exact count/unrank.
- `test/distinct_name_fourth_mapping_probe.spl`: three removals കഴിഞ്ഞ fourth remaining ordinal original ordinal-ിലേക്ക്.
- `test/gate_gap_stream_short_probe.spl`: AnswerStream short rejection path -> selected rank -> `41+rank` gate gap.

ഇതോടെ small exact source coverage-ൽ bowl recurrence scalar one-position-ൽ നിന്ന് six positions വരെ, filtered cutlet family 3 slots-ൽ നിന്ന് 4 slots വരെ, distinct-name removal-aware mapping third-ൽ നിന്ന് fourth position വരെ വളർന്നു. drop-46 latch preservation source-level gate ആദ്യമായി twelve post-stir reads മുഴുവനായി consume ചെയ്യുന്നു. gate-gap conversion ഇപ്പോൾ synthetic stream selection-നൊപ്പം integrated ആണ്.

ഇനിയും പ്രധാന blockers:

- seven hidden + 46 visible exact rolling timeline, ഓരോ visible drop-നും 11 grinds;
- rank-to-order + order-position pours + six arbitrary old-snapshot bowl reads/writes + simultaneous commit എന്ന full 46-round chain;
- actual order-ID mapping സഹിതം 12 committed post-stir bowl states;
- sauce -> askBowl -> short/wide dispatcher integrated path;
- sauce-derived signed gate gaps, arbitrary indexed lazy gate store/cache, monotone lookup;
- Year 5000 full candidate enumeration/order/selection, next/previous candidate families, sequential walk;
- arbitrary-K cutlet partition memo/count/unrank;
- arbitrary-slot month-length bounded-composition memo/count/unrank;
- arbitrary-m weaving state memo/count/unrank;
- arbitrary-k distinct-name unrank;
- frozen canonicalIndex -> മലയാള source string presentation resolve;
- generated full year structure -> exactly five fields end-to-end;
- local SPL-only runtime GREEN.

## പുതിയ clean-reference integration slices — progress 17

ഈ continuation-ൽ Stage 1 test-only Appendix A reference-ിന്റെ അഞ്ചു അടുത്ത slices ചേർത്തു:

- `test/rolling_predecessor_four_drop_probe.spl`: hidden timeline-ിൽ നിന്ന് visible commits-ലേക്ക് ആദ്യ നാല് drop-ുകളുടെ `prev1/prev3/prev7` rolling source mapping;
- `test/bowl_identity_round_arbitrary_snapshot_probe.spl`: identity order-ിൽ ആറു വ്യത്യസ്ത old bowl values ഒരേ snapshot ആയി വായിക്കുന്ന full six-position no-wrap round;
- `test/post_stir_identity_order_no_wrap_probe.spl`: 1A saved sum rank 1 fixture-ൽ six distinct old bowls -> six post-stir pending values, ഒരേ saved value ഉപയോഗിച്ച്;
- `test/distinct_name_fifth_mapping_probe.spl`: നാല് removals കഴിഞ്ഞ fifth remaining ordinal original canonical ordinal-ിലേക്ക് mapping;
- `test/year_three_candidate_validity_probe.spl`: മൂന്ന് year-pair candidates-ന്റെ clean `gaps>=6`, `252..5778` predicate batch.

ഇതോടെ rolling predecessor source mapping single mux-ിൽ നിന്ന് multiple committed visible positions വരെ നീങ്ങി; bowl snapshot coverage uniform old values-ിൽ നിന്ന് six arbitrary old values വരെ ഉയർന്നു; post-stir six-position round uniform old state-ിൽ നിന്ന് distinct old state-ിലേക്ക് ഒരു rank-1 order fixture-ൽ വികസിച്ചു; distinct-name removal mapping അഞ്ചാം position വരെ എത്തി; year validity predicate batch candidate scanning-ന്റെ ഒരു ചെറിയ അടിസ്ഥാനമായി ലഭിച്ചു.

ഇനിയും പ്രധാന blockers:

- ഏഴ് hidden values യഥാർത്ഥമായി നിർമ്മിച്ച് 46 visible drops-ന്റെ ഓരോ seed + 11 grinds ഒരൊറ്റ rolling value store-ൽ commit ചെയ്യൽ;
- ഓരോ 46 drop-ലും arbitrary rank-to-order, position-specific pours, six arbitrary old-snapshot bowl reads, six pending writes, simultaneous commit;
- drop 46-ന്റെ actual order latch പിടിച്ച് sauce result-ിൽ സൂക്ഷിക്കൽ;
- stir 1..12 മുഴുവൻ saved-sum -> order-rank -> full permutation -> six pending -> commit state chain;
- sauce result -> askBowl -> short/wide dispatcher full integration;
- sauce-derived signed gate gaps, arbitrary indexed lazy gate storage/cache, monotone lookup;
- Year 5000 full candidate enumeration/order/selection, next/previous candidate lists, sequential walk;
- arbitrary-K cutlet partition memo/count/unrank;
- arbitrary-slot month-length bounded composition memo/count/unrank;
- arbitrary-m weaving memo/count/unrank;
- arbitrary-k distinct-name unrank മുഴുവൻ positions;
- frozen canonicalIndex -> മലയാള source string presentation resolve;
- generated full structure -> exactly five final fields end-to-end;
- local SPL-only runtime GREEN.

## പുതിയ clean-reference integration slices — progress 18

ഈ continuation-ൽ ആറു പുതിയ SPL source slices ചേർത്തു:

- `test/rolling_two_visible_full_grinds_probe.spl`: ആദ്യ രണ്ടു visible drop-ുകൾക്ക് hidden predecessor mapping, seed SAVE, 11-row grind recurrence, first commit -> second `prev1` ownership;
- `test/bowl_nonidentity_order_round_probe.spl`: non-identity order `3,1,6,2,5,4`-ൽ six arbitrary old-snapshot reads + six pending outputs;
- `test/post_stir_nonidentity_order_probe.spl`: raw sum + 149*stir -> saved 255 -> rank 255 known permutation -> six pending post-stir values;
- `test/sauce_query_short_selection_probe.spl`: queried/successor/bowl6/seal scalar sauce view -> askBowl -> fixed direction -> first-answer short selection -> gate gap;
- `test/distinct_name_sixth_mapping_probe.spl`: five removals കഴിഞ്ഞ sixth remaining ordinal original ordinal-ിലേക്ക്;
- `test/weave_two_two_two_unrank_probe.spl`: lengths `2,2,2` small legal family count/unrank materialization.

കൂടാതെ `test/post_stir_identity_order_no_wrap_probe.spl`-ന്റെ position-6 source literal `20`-ൽ നിന്ന് Appendix A-യിലെ `6^2=36`-ലേക്ക് clean Stage 1 correction ചെയ്തു; corresponding expected value മാറ്റേണ്ടതില്ല, കാരണം expectation ഇതിനകം ശരിയായ `36` അടിസ്ഥാനമാക്കിയിരുന്നു.

ഇതോടെ ചില blockers ചുരുങ്ങി:

- rolling visible recurrence source ഇനി single predecessor mux അല്ല; two committed visible drops full 11-grind chains ആയി ബന്ധപ്പെട്ടു;
- bowl routing identity-only fixture-ിൽ നിന്ന് non-identity cyclic order fixture-ിലേക്ക് നീങ്ങി;
- post-stir distinct state identity order-ിൽ നിന്ന് known non-identity permutation-ിലേക്ക് നീങ്ങി;
- askBowl scalar output gate-gap short-selection integration-ുമായി ബന്ധപ്പെട്ടു;
- distinct-name removal mapping sixth position വരെ എത്തി;
- m=3 weaving small-force family lengths `2,2,2` വരെ materialize ചെയ്തു.

ഇനിയും പ്രധാന blockers:

- seven hidden values-ന്റെ actual generation-ുമായി all 46 visible recurrences ഒരൊറ്റ rolling store-ൽ commit ചെയ്യൽ;
- ഓരോ 46 drop-ലും drop-derived full permutation, position pours, six old-snapshot reads, six pending writes, simultaneous commit;
- actual drop-46 order latch sauce result-ിൽ പിടിക്കൽ;
- stir 1..12 മുഴുവൻ saved-sum -> order -> six pending -> commit chain;
- sauce-derived signed gate gaps, arbitrary lazy indexed gate storage/cache, exact monotone lookup;
- Year 5000 full candidate enumeration/order/selection, next/previous candidate generation, sequential target walk;
- arbitrary-K filtered cutlet partition memo/count/unrank;
- arbitrary-slot bounded month-length memo/count/unrank;
- arbitrary-m weaving state memo/count/unrank;
- arbitrary-k distinct-name unrank മുഴുവൻ positions;
- frozen canonicalIndex -> മലയാള source string presentation resolve;
- generated full year structure -> exactly five final fields end-to-end;
- local SPL-only runtime GREEN.

## പുതിയ clean-reference integration slices — progress 19

- `test/rolling_three_visible_full_grinds_probe.spl`: three-drop committed rolling recurrence ownership, ഓരോ drop-നും 11 grind iterations;
- `test/post_stir_two_committed_rounds_probe.spl`: two successive six-bowl transactional rounds, pending -> commit -> next old snapshot;
- `test/gate_signed_store_five_probe.spl`: `gate[-2..2]` signed indexed materialization from four already-selected gaps;
- `test/next_year_three_candidate_rank_probe.spl`: next-year same-open three-candidate validity scan + rank resolve;
- `test/distinct_name_seventh_mapping_probe.spl`: six removals കഴിഞ്ഞ seventh remaining ordinal original canonical ordinal-ിലേക്ക്.

ഈ revision blockers-ിൽ ചെറിയ കുറവ് വരുത്തുന്നു: rolling recurrence source ഇനി three committed visible positions വരെ എത്തി; post-stir ownership actual inter-round commit boundary source-ൽ ഉണ്ട്; signed gate storage ആദ്യ ചെറിയ materialized form നേടി; next-year candidate predicate isolated batch-ിൽ നിന്ന് ranked scan-ിലേക്ക് നീങ്ങി; distinct-name mapping seventh position വരെ എത്തി.

ഇനിയും പ്രധാന blockers:

- actual seven hidden generation + all 46 visible seeds/11-grind recurrences one rolling exact store;
- ഓരോ 46 drop-ലും drop-derived full permutation, pours, six old-snapshot bowl reads, pending writes, simultaneous commit;
- actual drop-46 order latch SauceResult-ലേക്ക്;
- stir 1..12-ന്റെ normative saved-sum -> order -> six pending -> commit chain;
- sauce-derived signed gate gaps, arbitrary indexed lazy gate store/cache, exact monotone lookup;
- Year 5000 full candidate enumeration/order/selection; next/previous arbitrary candidate lists; sequential target walk;
- arbitrary-K cutlet partition memo/count/unrank;
- arbitrary-slot month-length bounded composition memo/count/unrank;
- arbitrary-m whole-weaving memo/count/unrank;
- arbitrary-k distinct-name unrank;
- frozen canonicalIndex -> മലയാള source string presentation resolve;
- generated full year structure -> exactly five final fields;
- local SPL-only runtime GREEN.

## പുതിയ clean-reference integration slices — progress 20

- `test/visible_drop4_predecessor_seed_probe.spl`: `i=4`-ൽ `prev1=visible3`, `prev3=visible1`, `prev7=hidden4` എന്ന boundary-crossing seed ownership.
- `test/previous_year_three_candidate_rank_probe.spl`: fixed-close previous-year three-candidate clean validity scan + one-based rank resolve.
- `test/bounded_composition_five_slot_count_probe.spl`: exact bounded-composition family count അഞ്ചു slots വരെ.
- `test/cutlet_partition_five_slot_filter_count_probe.spl`: required internal prefix boundary ഉള്ള positive cutlet-partition exact count അഞ്ചു slots വരെ.
- `test/distinct_name_eighth_mapping_probe.spl`: seven removals കഴിഞ്ഞ eighth remaining ordinal original canonical ordinal-ിലേക്ക്.
- `test/weave_three_two_two_count_probe.spl`: lengths `3,2,2` exact small whole-weaving count witness.

ഇതോടെ fixed-size clean combinatorial coverage വീണ്ടും ഒരു slot/position കൂടി വളർന്നു; previous-year ranked candidate path next-year path-നൊപ്പം symmetric source coverage നേടി; visible recurrence predecessor ownership `i=4` hidden/visible boundary crossing വരെ explicit ആയി.

ഇനിയും പ്രധാന blockers:

- actual seven hidden generation + all 46 visible seeds/11-grind recurrences one rolling exact store;
- ഓരോ 46 drop-ലും drop-derived full permutation, pours, six old-snapshot bowl reads, pending writes, simultaneous commit;
- actual drop-46 order latch SauceResult-ലേക്ക്;
- stir 1..12-ന്റെ normative saved-sum -> order -> six pending -> commit chain;
- sauce-derived signed gate gaps, arbitrary indexed lazy gate store/cache, exact monotone lookup;
- Year 5000 full candidate enumeration/order/selection; next/previous arbitrary candidate lists; sequential target walk;
- arbitrary-K cutlet partition memo/count/unrank;
- arbitrary-slot month-length bounded-composition memo/count/unrank;
- arbitrary-m whole-weaving memo/count/unrank;
- arbitrary-k distinct-name unrank;
- frozen canonicalIndex -> മലയാള source string presentation resolve;
- generated full year structure -> exactly five final fields;
- local SPL-only runtime GREEN.

## പുതിയ clean-reference integration slices — progress 21

ഈ continuation-ൽ Stage 1 clean Appendix A reference-ന്റെ അഞ്ചു അടുത്ത ഭാഗങ്ങൾ കൂടി SPL source ആയി ചേർത്തു:

- `test/hidden_seven_seed_rows_no_wrap_probe.spl`: ഏഴ് hidden coefficient rows ഒരേ counts input-ൽ seed mapping ആയി;
- `test/drop_rank1_identity_bowl_commit_probe.spl`: drop value 1 -> rank 1 identity order -> position pours -> shared-old-snapshot six pending bowl values എന്ന integrated clean round;
- `test/target_year_forward_two_step_probe.spl`: closing-gate-inclusive semantics പാലിച്ച് രണ്ട് sequential next-year unit transitions വരെ target walk;
- `test/gate_two_short_streams_accumulate_probe.spl`: accepted short ranks -> 42..963 gaps -> രണ്ട് positive gates cumulative materialization;
- `test/weave_three_two_two_unrank_probe.spl`: lengths `3,2,2` exact count witness-നെ ഒൻപത് lexicographic rows മുഴുവനായുള്ള small-family unrank witness ആയി വികസിപ്പിക്കുന്നു.

കൂടാതെ `choose_rank_wide_probe.spl`-ന്റെ Stage 1 expectations-ൽ `N=M^2+1` boundary fixture ചേർത്തു; expected rank `M-1` ആണ്.

ഇതിലൂടെ hidden coefficient-row coverage single-row trace-ൽ നിന്ന് seven-row mapping വരെ ഉയർന്നു; bowl path rank/order/pours/pending commit semantics ഒരൊറ്റ rank-1 clean source path-ൽ ആദ്യമായി കൂടിച്ചേർന്നു; target-year walking ഒരു direction predicate-ിൽ നിന്ന് രണ്ട് actual unit transitions വരെ നീങ്ങി; gate gap conversion രണ്ട് cumulative gates വരെ എത്തി; `3,2,2` weaving-ിന് count മാത്രം അല്ല complete small unrank familyയും ലഭിച്ചു.

ഇനിയും blockers:

- ഏഴ് hidden drops-ന്റെ full seed + ഏഴ് grinds actual generation;
- 46 visible drops-ന്റെ full seed + 11 grinds rolling store;
- ഓരോ 46 drop-ലും arbitrary rank-to-order, pours, six pending values, simultaneous commit;
- drop-46 order latch-ോടെ full sauce result;
- 12 normative post-stirs full committed state chain;
- sauce-derived arbitrary signed lazy gate generation/cache;
- Year 5000 full candidate enumeration/order/selection, next/previous candidate families, unbounded sequential walk;
- arbitrary-K cutlet partition DP, arbitrary-slot month-length DP, arbitrary-m weaving DP, arbitrary-k distinct-name unrank;
- frozen canonicalIndex -> മലയാള source presentation resolution;
- generated exactly-five-field end-to-end oracle;
- local SPL-only runtime GREEN.

## പുതിയ clean-reference integration slices — progress 22

- `test/rolling_46_source_ownership_counts_probe.spl`: all 46 visible positions-ൽ prev1/prev3/prev7 hidden-versus-committed-visible source ownership counts.
- `test/visible_46x11_row_schedule_probe.spl`: corrected full 46×11 nested traversal; stone row സ്ഥിരമായി `i`, grind coefficient row `g=1..11`; step count, രണ്ട് axis sums, final `(46,11)` witness.
- `test/bowl_46_transactional_commit_control_probe.spl`: six pending-before-commit ownership exactly 46 rounds വരെ.
- `test/post_stir_12_transactional_commit_control_probe.spl`: six pending-before-commit ownership exactly 12 post-stirs വരെ.
- `test/target_year_backward_two_step_probe.spl`: `(open,close]` semantics-ോടെ രണ്ട് sequential previousYear transitions.
- `test/year5000_three_candidate_sort_probe.spl`: valid three-candidate `length ascending, open ascending` ranking and requested-rank materialization.

ഇതോടെ full required cardinality-കളുടെ control coverage വളർന്നു: rolling source boundaries 46 positions, grind row schedule 506 steps, bowl commit epochs 46, post-stir commit epochs 12. എന്നാൽ actual normative value integration ഇനിയും വേണം.

ഇനിയും പ്രധാന blockers:

- ഏഴ് hidden drops-ന്റെ full seed + ഏഴ് grinds actual generation;
- all 46 visible drops-ന്റെ seed + 11 normative grinds one rolling exact store-ൽ;
- ഓരോ visible drop-ലും actual drop-derived rank-to-order, three position pours, stone value, six normative pending values, simultaneous commit;
- drop-46 order latch-ോടെ complete SauceResult;
- stir 1..12 actual 1A saved sum -> order -> six normative pending -> commit chain;
- sauce-derived arbitrary signed lazy gate generation/cache and exact lookup;
- Year 5000 full candidate enumeration/filter/sort/seal-10 selection; next/previous arbitrary candidate families; unbounded sequential target-year walk;
- arbitrary-K cutlet partition memo/count/unrank;
- arbitrary-slot month-length bounded composition memo/count/unrank;
- arbitrary-m weaving memo/count/unrank;
- arbitrary-k distinct-name unrank;
- frozen canonicalIndex -> മലയാള source string presentation resolution;
- generated exactly-five-field end-to-end oracle;
- local SPL-only runtime GREEN.

## പുതിയ clean-reference integration slices — progress 23

- `test/stones_row2_fixed_snapshot_probe.spl`: Appendix A stone row 1 -> row 2 actual five-value simultaneous snapshot witness.
- `test/initial_six_bowls_fixture_probe.spl`: initial bowl formula six IDs-ലേക്ക് ഒരുമിച്ച് വ്യാപിപ്പിച്ച no-wrap family witness.
- `test/bowl_pour_nonidentity_mapping_probe.spl`: order positions `3,1,6` വഴി three pours actual fixed-ID aliasing ഒഴിവാക്കി map ചെയ്യുന്ന witness.
- `test/order46_successor_lookup_probe.spl`: arbitrary six-ID latched order-ൽ queried bowl circular successor lookup.
- `test/gate_signed_pair_accumulate_probe.spl`: rank -> gap -> positive/negative Foundation first gates.
- `test/visible_grind_table_eleven_mapping_probe.spl`: 11 normative visible grind rows മുഴുവൻ `a,b,c,d,stoneKind` mapping.

ഇതോടെ stone initialization/transition, bowl initialization/pours, latched-order query adjacency, signed first-gate arithmetic, visible grind table എന്നിവ source-level clean reference-ൽ കൂടുതൽ നേരിട്ട് materialize ചെയ്തു.

ഇനിയും പ്രധാന blockers:

- ഏഴ് hidden drops-ന്റെ full seed + ഏഴ് grinds actual generation one reusable path;
- all 46 visible drops-ന്റെ seed + 11 normative grinds one rolling exact store-ൽ;
- ഓരോ visible drop-ലും actual drop-derived six-ID order, three pours, stone-by-position, six pending values, simultaneous commit;
- drop-46 order latch-ോടെ complete SauceResult;
- stir 1..12 actual 1A saved sum -> order -> six normative pending -> commit chain;
- sauce-derived arbitrary signed lazy gate generation/cache and exact lookup;
- Year 5000 full candidate enumeration/filter/sort/seal-10 selection; next/previous arbitrary candidate families; unbounded sequential target-year walk;
- arbitrary-K cutlet partition memo/count/unrank;
- arbitrary-slot month-length bounded composition memo/count/unrank;
- arbitrary-m weaving memo/count/unrank;
- arbitrary-k distinct-name unrank;
- frozen canonicalIndex -> മലയാള source string presentation resolution;
- generated exactly-five-field end-to-end oracle;
- local SPL-only runtime GREEN.

## progress 24 — large-M arithmetic integration

ഈ continuation test-only clean reference-ൽ താഴെ പറയുന്ന exact slices ചേർക്കുന്നു:

- `hidden_seven_grind_modulus_lock_probe.spl`: ഏഴ് hidden grind updates-നും M-sized exact SAVE lock;
- `drop_M_order_rank_probe.spl`: M-sized drop-ിൽ നിന്ന് one-based 720 bowl rank;
- `bowl_round_modulus_reduction_probe.spl`: M-sized drop/old bowls/stones ഉപയോഗിച്ച് full six-position visible bowl round;
- `post_stir_M_snapshot_rank149_probe.spl`: six-M old snapshot -> 1A saved sum 149 -> rank 149 -> six post-stir pending position values;
- `wide_M2_plus1_boundary_probe.spl`: mandatory `N=M^2+1` wide selector boundary source witness;
- `ask_bowl_M_wrap_formula_probe.spl`: latched circular-successor companion fixture-നെ full askBowl first/direction arithmetic-ുമായി ബന്ധിപ്പിക്കുന്നു.

ഇവ individual clean-reference slices ആണ്; production bootstrap നിഷ്പക്ഷമാണ്. full rolling sauce state, arbitrary-order 46 committed bowl rounds, 12 committed normative post-stirs, sauce-derived lazy gate generation, complete years, general DP/weaving/name-unrank, മലയാള presentation resolution, generated final five-field result എന്നിവ blockers ആയി തുടരുന്നു.

## progress 25 — sauce chain integration bridges

ഈ continuation-ൽ Stage 1 clean reference-ന്റെ താഴെപ്പറയുന്ന source bridges ചേർന്നു:

1. `stones_row2_to_row3_snapshot_probe.spl` — consecutive stone row ownership: committed row 2 -> row 3 five pending values, same old snapshot.
2. `visible_eleven_M_integrated_table_probe.spl` — explicit 11-row grind dispatch -> generic recurrence -> SAVE commit, M-sized exact fixture.
3. `two_drop_two_bowl_commits_probe.spl` — two visible drops -> pours -> six bowl pending values -> commit -> next six-bowl round reads committed snapshot.
4. `sauce_46_12_latch_phase_probe.spl` — 46 drop commit epochs -> single drop-46 latch -> 12 post-stir commit epochs; post phase cannot rewrite latch.
5. `ask_after_poststir_uses_latch_probe.spl` — query successor source is drop-46 latch, not the later diagnostic post-stir order.

ഇവ production bootstrap architecture-നെ future monster fields ഉപയോഗിച്ച് വളർത്തുന്നില്ല. test-only clean oracle-ന്റെ semantic ownership/integration coverage മാത്രം വർധിപ്പിക്കുന്നു.

ഇനിയും അടയ്ക്കാത്ത പ്രധാന source gaps: all 46 stone rows generated in one table; seven hidden drops generated together; full 46 visible rolling recurrence with actual stone rows; all 46 drop-derived permutations and bowl commits; all 12 value-producing post-stirs; completed SauceResult; sauce-derived lazy gate store; full Year 5000 enumeration and sequential adjacent-year construction; arbitrary-size composition/weaving/name unrank; frozen മലയാളം catalog string resolution; final five-field end-to-end oracle; native SPL runtime execution.

## പുതിയ clean-reference integration slices — progress 26

- `test/hidden_seven_full_synthetic_generation_probe.spl`: ഏഴ് hidden drops × ഏഴ് grinds ഒരേ source control path-ൽ; synthetic exact fixture final 132.
- `test/stones_full_46_transactional_path_probe.spl`: normative five-stone recurrence row 1->46, five pending values from one old snapshot then commit.
- `test/post_stir_twelve_saved_rank_schedule_probe.spl`: 1A `savedBowlSum` + one-based 720 rank മുഴുവൻ stir 1..12 schedule.
- `test/year_max_5778_to_5781_boundary_probe.spl`: clean maximum boundary 5778 accept; 5779..5781 reject.
- `test/final_five_field_closing_boundary_probe.spl`: closing-day inclusive materialized structure -> exactly five fields `5000,7,3,17,2`.
- `test/distinct_name_general_sorted_mapping_probe.spl`: dynamic removal-count stack-backed remaining ordinal -> canonical ordinal helper.
- `test/year5000_seal10_short_rank_probe.spl`: mandatory Year 5000 seal 10 -> AnswerStream -> short candidate rank bridge.

ഇതോടെ stone recurrence-ന്റെ full 46-row traversal source-level ആയി ലഭിച്ചു; hidden generation fixed per-k fragments-ൽ നിന്ന് seven-by-seven integrated control-ലേക്ക് നീങ്ങി; post-stir saved/rank phase full 12 rows നേടി; clean year ceiling 5779/5780/5781 explicit rejection ആയി source test-ൽ materialize ചെയ്തു; distinct-name mapping fixed eighth position-ൽ നിന്ന് dynamic removal-count helper-ലേക്ക് നീങ്ങി; final resolver closing boundaryയും discontiguous month occurrence count-വും ഒരേ exactly-five-field fixture-ൽ ചേർന്നു.

ഇനിയും പ്രധാന blockers:

- legal workCounts + actual generated 46-row stones ഉപയോഗിച്ച് seven hidden values end-to-end generation;
- all 46 visible values one rolling exact timeline-ൽ actual generated predecessors/stones ഉപയോഗിച്ച്;
- all 46 drop-derived arbitrary orders + pours + six-bowl transactional commits;
- 12 actual post-stir value rounds with committed state;
- complete SauceResult + orderAtDrop46 latch;
- sauce-derived arbitrary signed lazy gates;
- full Year 5000 candidate enumeration/filter/sort/seal-10 selection and arbitrary adjacent-year walking;
- arbitrary-K cutlet partition count/unrank, arbitrary-slot month composition count/unrank;
- arbitrary-m whole-weaving count/unrank;
- full arbitrary-k partial-permutation name unrank;
- frozen canonicalIndex -> മലയാളം presentation string resolution;
- generated year structure -> exactly five final fields;
- local SPL-only runtime GREEN.

### progress 26 clean-reference correction

`test/distinct_name_eighth_mapping_probe.spl` candidate-scan ആയി പുനഃരചിച്ചു. പഴയ shortcut removal input order-നോട് sensitive ആയിരുന്നു; canonical removed set-ന്റെ order semantic ആയിരിക്കരുത്. fixed fixture outputs `15`/`13` തന്നെയാണ്.

## progress 27 — legal workCounts and full-46 rolling bridge

- `test/work_counts_full_probe.spl`: raw action/target day -> action dayCount, target dayCount, chronological distance, connection, direction; Foundation parity mapping ഉൾപ്പെടെ.
- `test/legal_foundation_hidden_seed_rows_probe.spl`: legal same-Foundation workCounts `1,1,1,2,2`-ൽ seven hidden coefficient rows exact no-wrap witness.
- `test/legal_foundation_six_initial_bowls_probe.spl`: അതേ legal workCounts-ൽ six initial bowl formula family exact no-wrap witness.
- `test/visible_46_full_rolling_invariant_probe.spl`: 46 visible outer commits + 11 normative grind coefficient rows per drop + seven-slot predecessor ring in one source path; synthetic M invariant stones/base isolate rolling/value ownership.

ഇതോടെ legal workCounts ഇനി primitive operation code-ന്റെ ഉള്ളിൽ മാത്രം ഒളിഞ്ഞിട്ടില്ല; dedicated full source path ഉണ്ട്. full-46 visible recurrence ഇനി cardinality/schedule control മാത്രം അല്ല; recurrence value ഓരോ 11 grind-ലും SAVE ചെയ്ത് rolling commit ചെയ്യുന്നു. എന്നാൽ actual generated stone row/kind lookup, legal seed base, drop-derived bowl order/pours/six-bowl round എന്നിവ ഈ full-46 source-ൽ ഇനിയും ബന്ധിപ്പിച്ചിട്ടില്ല.

## progress 28 — corrected visible stone-row axis

- `test/visible_46x11_row_schedule_probe.spl`: progress-22 wrapped-row interpretation തിരുത്തുന്നു; `stoneRow=i`, `grindRow=g`; full 46×11 traversal outputs `506,11891,3036,46,11`.
- `test/visible_row1_two_grinds_legal_probe.spl`: legal same-Foundation counts + actual stone row 1 + predecessor fixture -> seed + first two normative grind commits; exact chain `443 -> 197618 -> 39053862074`.
- `test/visible_same_stone_row_kind_cycle_probe.spl`: one retained stone row across all 11 grind kind selections; row-1 selected sum `539`, first/last `17`.

### correction ownership

progress-22 documentation-ൽ ഉണ്ടായിരുന്ന `wrap1(i+g,46)` stone-row rule superseded ആണ്. Appendix A clean visible recurrence-ൽ stone row outer drop index `i` ആണ്. `g`-യുടെ role coefficient row + stone kind selection മാത്രം.

### remaining bridge

- full stone table row 1..46 later phases-ക്ക് queryable state ആയി materialize ചെയ്യുക;
- legal workCounts + actual generated rows -> seven hidden drops;
- generated hidden timeline + actual row `i` -> all 46 visible values;
- visible value -> order -> position pours -> six-bowl transactional commit, 46 തവണ;
- തുടർന്ന് 12 actual post-stirs, sauce result, gates, years, general structure DP/name/presentation/five-field path.

## progress 29 — forward-consumable stone table bridge

- `test/stones_full_46_forward_replay_probe.spl`: actual 46-row simultaneous stone recurrence + per-kind archive stacks + reverse-to-forward replay; row 1 replay witness `17,29,43,71,101`.
- `test/hidden1_actual_row1_first_grind_probe.spl`: legal same-Foundation workCounts + actual row 1 + hidden approach 1 seed + first hidden grind, both through SAVE; `297 -> 89118`.
- `test/drop_M_factoradic_digits_probe.spl`: M-sized drop -> one-based order rank 127 -> factoradic digits `1,0,1,0,0,0`.

### ഇപ്പോഴത്തെ sauce integration gap

stone generation ഇനി value retention ഇല്ലാത്ത traversal മാത്രമല്ല: five replay stacks row 1..46 forward consumption-നായി source-level ownership നൽകുന്നു. അടുത്ത bridge ഈ replay state-നെ seven hidden + all 46 visible value generation-ൽ consume ചെയ്യുന്നതാണ്. visible drop order path-ൽ rank computation-നും factoradic digit decomposition-നും source witnesses ഇപ്പോൾ ഉണ്ട്; active-ID removal/permutation materialization ഇതിനകം വേറൊരു clean probe-ൽ ഉണ്ട്, പക്ഷേ full 46-drop sauce source-ൽ ഇനിയും ചേർന്നിട്ടില്ല.

## progress 30 — forward stone consumption മുതൽ post-stir order materialization വരെ

ഈ continuation-ൽ clean oracle integration നാലു പുതിയ source slices-ും ഒരു existing stone replay extension-ും ചേർക്കുന്നു.

- `test/stones_full_46_forward_replay_probe.spl`: full 46-row archive/reverse path ഇപ്പോൾ replay row 1-ന് പിന്നാലെ row 2-വും consume ചെയ്യുന്നു; expected row 2 `378,1073,2375,6195,10493`.
- `test/visible_row2_from_snapshot_first_grind_legal_probe.spl`: legal same-Foundation workCounts + row-1-to-row-2 simultaneous stone transition + visible i=2 seed + first grind; expected `37213,1384919409`.
- `test/factoradic_127_materialize_probe.spl`: rank-127 digits `1,0,1,0,0,0` -> order `2,1,4,3,5,6`.
- `test/bowl_rank127_M_snapshot_round_probe.spl`: rank-127 order + M-sized drop/old snapshot + actual row-1 stones -> three pours + six bowl candidates + first post-stir saved sum/rank; expected `1158,401,5045,2503,10206,295,19608,19757,317`.
- `test/factoradic_317_materialize_probe.spl`: rank 317 -> order `3,5,1,6,2,4`, അതായത് previous source-ന്റെ first post-stir rank-നെ അടുത്ത order state-ലേക്ക് ബന്ധിപ്പിക്കുന്നു.

ഇവ test-only clean Appendix A integration slices ആണ്. production bootstrap oracle-നെ വിളിക്കുന്നില്ല. all-46 actual generated visible/drop-order/bowl sequence ഇനിയും ഒരൊറ്റ authoritative test path ആയി materialize ചെയ്തിട്ടില്ല.

## progress 31 — retained stones -> actual seven hidden -> timeline ring

- `test/hidden_seven_actual_stone_replay_probe.spl`
  - full 46-row stone transactional generation + forward replay നിലനിർത്തുന്നു;
  - replay rows 1..7 actual hidden generation-ലേക്ക് consume ചെയ്യുന്നു;
  - same-Foundation legal workCounts contribution + actual five-stone row + SAVE;
  - hidden ഓരോന്നിലും 7 normative grinds;
  - 7 hidden commits backward archive-ലേക്ക്;
  - archive `hidden7..hidden1` pop ചെയ്ത് ring slots `2,3,4,5,6,7,1` seed ചെയ്യുന്നു.
- `test/timeline_seven_slot_ring_index_probe.spl`
  - timeline position modulo-7 ownership mapping i=1..46 മുഴുവൻ;
  - current slot prev7 slot തന്നെയാണെന്ന് 46-step control;
  - i=1, i=46 distinguishing mappings.
- `test/timeline_ring_seed_eight_commit_probe.spl`
  - hidden positions 0..-6 -> seven ring slots;
  - visible1..8 overwrite-after-read control;
  - i=8-ൽ prev7 hidden storage-ൽ നിന്ന് committed visible storage-ലേക്ക് മാറുന്നത് തെളിയിക്കുന്നു.

ഇനിയും blocker: actual hidden ring-നെ retained stone row 1..46 visible recurrence-ലേക്ക് same source path-ൽ feed ചെയ്ത് 46 final drops നിർമ്മിക്കണം; തുടർന്ന് ഓരോ drop-നും factoradic order/pours/six-bowl commit, latch46, 12 post-stirs, SauceResult, gates, years, general combinatorial DP, name unrank, final five-field result.

## progress 32 — hidden-to-visible arithmetic bridge

- `test/hidden_actual_to_visible_two_full_probe.spl`
  - actual 46-row stone path-ൽ നിന്നുള്ള rows 1..7 ഉപയോഗിച്ച് seven hidden drops നിർമ്മിക്കുന്നു;
  - hidden archive seven-slot timeline seed-ലേക്ക് മാറ്റുന്നു;
  - visible 1: hidden1/hidden3/hidden7 snapshot + actual row 1 + 11 visible grinds;
  - row 2 stones row-1 old snapshot-ൽ നിന്ന് transactional ആയി നിർമ്മിക്കുന്നു;
  - visible 2: committed visible1/hidden2/hidden6 snapshot + actual row 2 + 11 visible grinds;
  - രണ്ടും SAVE domain check ചെയ്യുന്നു;
  - actual visible2 `1+regularMod(drop-1,720)` rank domain-ലേക്ക് ബന്ധിപ്പിക്കുന്നു.
- `test/stone_dual_consumer_replay_control_probe.spl`
  - one backward ordered archive -> two independent forward replay owners;
  - hidden consumer 7 rows; visible consumer 46 rows;
  - next all-46 integration-ൽ real stone values duplicate-replay ചെയ്യാനുള്ള ownership contract isolate ചെയ്യുന്നു.

ഇനിയും പ്രധാന blocker: dual replay control-നെ actual five-value stone rows-ലേക്ക് കൊണ്ടുവന്ന് same source path-ൽ all 46 visible drops generate ചെയ്യുക; അതിനു പിന്നാലെ ഓരോ actual drop-നും full permutation materialization, pours, six-bowl transactional commit, drop-46 latch, 12 post-stirs, gates/years/general DP/name-unrank/final five-field path ചേർക്കുക.

progress 32 same source-ൽ actual visible2 rank -> factoradic blocks `120,24,6,2,1` -> six digits path കൂടി ഉണ്ട്. digit-domain aggregate control expected true ആണ്. full six-ID active-set removal ഈ dynamic digits-ൽ നിന്ന് same path-ൽ നടത്തുന്നത് അടുത്ത bowl-order integration step ആണ്.

## progress 33 — all-46 actual visible sauce bridge

- `test/stones_full_46_dual_five_value_replay_probe.spl`
  - actual 46-row five-stone simultaneous recurrence;
  - one backward archive family;
  - two independent forward five-value replay owners;
  - hidden consumer rows 1..7, visible consumer rows 1..46.
- `test/sauce_foundation_actual_hidden_visible46_probe.spl`
  - legal same-Foundation workCounts specialized fixture;
  - actual 46-row stones;
  - actual seven hidden values with seven grinds each;
  - hidden values -> rolling last1..last7 history;
  - actual visible rows 1..46, 11 normative grinds each;
  - commit-after-computation rolling ownership;
  - committed drop46 -> one-based bowl rank domain;
  - drop46 rank -> six factoradic digit domain.

### remaining integration gap

all-46 actual visible generation ഇനി blocker അല്ല. അടുത്ത blocker actual drop-derived factoradic digits full active six-ID removal-ലേക്ക് same path-ൽ ബന്ധിപ്പിച്ച് order materialize ചെയ്യുന്നതും, ഓരോ drop-നും position-indexed pours + six-bowl old-snapshot transaction നടത്തുന്നതുമാണ്. തുടർന്ന് drop-46 order latch, 12 committed post-stirs, complete SauceResult/askBowl, signed lazy gates, full years, arbitrary composition/weaving/name DP, മലയാളം presentation resolve, generated five-field result, compliant SPL runtime GREEN എന്നിവ ശേഷിക്കുന്നു.

### progress 33 clean-reference correction

- `hidden_seven_actual_stone_replay_probe.spl`: hidden index/count initialization reversal completion-ൽ once-only; `Act V` loop entry reset-free.
- `hidden_actual_to_visible_two_full_probe.spl`: അതേ once-only initialization correction.
- `sauce_foundation_actual_hidden_visible46_probe.spl`: correction ആദ്യം മുതൽ same pattern-ൽ ഉൾപ്പെടുത്തിയിട്ടുണ്ട്.

## progress 34 — generated drop46 full order materialization and dynamic pour dispatch

- `test/sauce_foundation_actual_hidden_visible46_probe.spl`
  - existing legal same-Foundation full stone/hidden/visible path തുടരുന്നു;
  - actual committed drop46 -> one-based rank -> factoradic digits;
  - six active IDs removal-aware ആയി തിരഞ്ഞെടുക്കുന്നു;
  - selected IDs backward archive-ൽ push ചെയ്യുന്നു;
  - archive reverse ചെയ്ത് position-1-first forward order replay stack ഉണ്ടാക്കുന്നു;
  - hard-coded order value ഇല്ല; structural outputs `6,21,720,6`.
- `test/dynamic_order_three_pours_dispatch_probe.spl`
  - arbitrary order IDs 1..3-ൽ നിന്ന് corresponding old bowl values dynamic dispatch ചെയ്യുന്നു;
  - WHEAT/BARLEY/SALT position pours `SAVE` സഹിതം കണക്കാക്കുന്നു;
  - fixed bowl ID-കളിലേക്കല്ല, order positions-ലേക്കാണ് pours ബന്ധിപ്പിക്കുന്നത്.

അടുത്ത integration blocker: full sauce source-ൽ initial six bowls retain ചെയ്ത് visible i=1..46 ഓരോ drop-നും dynamic order materialize ചെയ്യുക; order positions-ൽ pours, prev/next circular neighbors, six pending values old snapshot-ൽ നിന്ന് കണക്കാക്കി transactional commit ചെയ്യുക; i=46 order latch ചെയ്യുക.

### progress 34 clean-reference correction — ID 5 zero branch

താഴെയുള്ള existing test-only materializers-ൽ ID 5 active + current digit 0 path select ചെയ്യാതെ decrement ചെയ്തിരുന്ന control-flow പിഴവ് തിരുത്തി:

- `test/bowl_order_rank6_integrated_probe.spl`
- `test/factoradic_127_materialize_probe.spl`
- `test/factoradic_317_materialize_probe.spl`
- `test/permutation_materialize6_probe.spl`

zero branch പുതിയ ID-5 selection scene-ലേക്ക് പോകുന്നു; positive branch മാത്രം decrement ചെയ്യുന്നു. rank 481 fixture ID 5 first selection നിർബന്ധമാക്കുന്നു.

## progress 35 — retained bowl-phase replay and first actual drop cursor

- `test/sauce_foundation_actual_hidden_visible46_probe.spl`
  - visible generation സമയത്ത് actual five-value `stones[i]` row bowl-phase backward archives-ലേക്ക് പകർത്തുന്നു;
  - committed `visible[i]` drop സ്വതന്ത്ര backward archive-ലേക്ക് പകർത്തുന്നു;
  - 46 completion-ൽ അഞ്ച് stone archives + drop archive 46-step reverse വഴി forward replay ആക്കുന്നു;
  - first bowl-phase consume actual row 1 (`17,29,43,71,101`) + actual visible drop 1 ലഭ്യമാക്കുന്നു;
  - actual drop 1-ൽ നിന്ന് one-based order rank + factoradic digits കണക്കാക്കി domain-check ചെയ്യുന്നു;
  - actual drop46 full order replay നിലനിർത്തുന്നു.

- `test/dynamic_order_circular_neighbors_probe.spl`
  - dynamic six-ID order-ന്റെ positions 1..6 circular predecessor/current/successor triples lock ചെയ്യുന്നു;
  - position-wrap semantics full bowl formula-യിൽ ചേർക്കുന്നതിനുമുമ്പുള്ള isolated topology slice ആണ്.

ശേഷിക്കുന്ന പ്രധാന sauce blocker: actual drop 1 factoradic digits full six-ID active-set removal-ലേക്ക് materialize ചെയ്ത് initial bowls-ോടൊപ്പം first real round commit ചെയ്യുക; തുടർന്ന് ഇതേ dispatcher 46 rounds മുഴുവൻ ആവർത്തിച്ച് drop46 order latch നിലനിർത്തുക, പിന്നെ 12 post-stirs.

## progress 36 — bowl bootstrap integration map

- `test/legal_initial_bowls_order316_pours_probe.spl`
  - legal same-Foundation workCounts -> six initial bowls -> order-prefix-based direct pours.
  - initial bowl values hard-code ചെയ്യാതെ Appendix A formula-യിൽ source-ൽ തന്നെ നിർമ്മിക്കുന്നു.
- `test/full_bowl_round_position_stone_probe.spl`
  - six distinct old bowls -> non-identity circular order -> three direct pours -> six position stones -> six pending values.
  - എല്ലാ pending reads-ും same old snapshot-ൽ നിന്നാണ്.

ഇനിയും തുറന്നിരിക്കുന്ന പ്രധാന sauce path: actual generated drop1 rank/factoradic digits -> full order materialization -> legal initial bowls -> actual row1/drop1 first transactional commit; തുടർന്ന് rows/drops `2..46`-ൽ same machinery loop ചെയ്യുകയും drop46 order latch ചെയ്യുകയും വേണം.

## progress 37 — actual drop1 order + legal bowl snapshot + actual pours

- `test/sauce_foundation_actual_hidden_visible46_probe.spl`
  - generated visible drop 1 factoradic digits -> full six-ID active-set removal;
  - selected order backward archive -> forward replay -> six scalar positions;
  - permutation structural invariants `count=6,sum=21,product=720`;
  - same-Foundation legal initial bowls rebuilt in the integrated path;
  - `M=2^127-1` rebuilt before bowl SAVE operations;
  - actual order positions 1..3 dynamically select old bowl IDs;
  - actual row-1 WHEAT/BARLEY/SALT stones and actual generated drop1 feed three direct pours;
  - each pour is reduced by normative SAVE and checked in `1..M`.

Remaining immediate integration gap: retain the three computed pours, perform circular prev/current/next old-bowl lookup for all six positions, compute all six pending bowl values from one immutable old snapshot, then commit simultaneously. After that, loop the same machinery through drops 2..46 and latch the generated order at drop 46.

## progress 38 integration slice

- `test/sauce_foundation_actual_hidden_visible46_probe.spl`
  - actual drop1 three direct pours retained scalar state;
  - actual materialized six order IDs separate commit-target archive;
  - position scalars converted to legal old-bowl values;
  - circular six-position pending recurrence from one immutable snapshot;
  - six pending values archived before any bowl mutation;
  - six ID/value commits only after pending phase completion;
  - commit count `6` + six SAVE-domain flags expected.

ഇതോടെ first actual generated-drop bowl round same sauce path-ൽ പൂർത്തിയായി. remaining blocker: same mechanism drops `2..46`-ൽ iterate ചെയ്യുക, `i=46` order latch preserve ചെയ്യുക, തുടർന്ന് 12 post-stirs and downstream oracle complete ചെയ്യുക.

## progress 39 — all actual drops rank/factoradic coverage after first bowl commit

- `test/sauce_foundation_actual_hidden_visible46_probe.spl`
  - progress 38 first actual drop1 transactional bowl commit state നിലനിർത്തുന്നു;
  - retained actual drop replay-ൽ നിന്ന് `drop2..drop46` sequential pop;
  - ഓരോ drop-നും `1+regularMod(drop-1,720)`;
  - factoradic blocks `120,24,6,2,1`;
  - per-current-drop rank/factoradic domain controls;
  - all-drop processed count `46`, next index `47`;
  - final actual drop46 rank/factoradic flags `1,1`;
  - committed bowl values untouched during this scan.

Immediate remaining bowl integration gap: same per-drop dynamic digits six-ID active-set removal-ലേക്ക് materialize ചെയ്ത് actual retained stone row + current committed six-bowl snapshot ഉപയോഗിച്ച് three pours + six shared-old-snapshot pending values + transactional commit നടത്തുക. machinery drops `2..46` മുഴുവൻ loop ചെയ്യുകയും final drop46 materialized order dedicated latch-ൽ സൂക്ഷിക്കുകയും വേണം.

## progress 40 — latch/replay ownership before all-46 bowl loop

- `test/sauce_foundation_actual_hidden_visible46_probe.spl`
  - actual drop46 materializer selected IDs working archive-ിനൊപ്പം dedicated latch archive-ലേക്ക് duplicate ചെയ്യുന്നു;
  - post-drop1 first bowl commit + all-46 rank scan latch archive mutate ചെയ്യുന്നില്ല;
  - scan completion-ൽ dedicated drop46 latch forward replay ആക്കി `count=6,sum=21,product=720` പരിശോധിക്കുന്നു;
  - scan ചെയ്യപ്പെടുന്ന actual drops `2..46` വേറൊരു backward archive-ൽ preserve ചെയ്യുന്നു;
  - completion-ൽ exactly 45 actual drops future forward replay ആയി reverse ചെയ്യുന്നു.

- `test/drop46_full_order_latch_probe.spl`
  - six scalar latched order positions;
  - 12 diagnostic post-stir rank reads;
  - final exact six-position latch + read count output.

Remaining immediate bridge: preserved actual drops `2..46` forward replay -> generic rank/factoradic -> full six-ID active-set materializer -> position pours -> six immutable-old-snapshot pending values -> transactional bowl commit loop. drop46 dedicated latch ഇതിനകം വേർതിരിച്ച ownership state ആയി നിലനിൽക്കുന്നു.

## progress 41 — all-45 actual-drop generic order materialization

- `test/sauce_foundation_actual_hidden_visible46_probe.spl`
  - progress 40-ലെ actual drops `2..46` Romeo forward replay വീണ്ടും consume ചെയ്യുന്നു;
  - ഓരോ drop-നും `1 + regularMod(drop-1,720)` exact ആയി കണക്കാക്കുന്നു;
  - blocks `120,24,6,2,1` ഉപയോഗിച്ച് factoradic digits നിർണ്ണയിക്കുന്നു;
  - six-ID active-set removal committed bowl-state scalar characters-ിൽ നിന്ന് വേർതിരിച്ച ownership characters ഉപയോഗിച്ച് നടത്തുന്നു;
  - ഓരോ resulting order-നും `count=6,sum=21,product=720` നിർബന്ധമായി validate ചെയ്യുന്നു;
  - temporary selected-order archive ഓരോ round-നും clear ചെയ്യുന്നു;
  - actual drop values വീണ്ടും preserve ചെയ്ത് completion-ൽ exactly 45-value forward replay rebuild ചെയ്യുന്നു;
  - dedicated drop46 latch Juliet memory-ൽ untouched ആയി തുടരുന്നു.

Immediate remaining bridge: rebuilt actual drops `2..46` + retained stone rows `2..46` -> dynamic full order -> position pours -> circular neighbors -> six immutable-old-snapshot pending bowl values -> transactional commit loop. ഈ loop-നുശേഷം drop46 latch ഉപയോഗിച്ച് 12 post-stirs/askBowl phase തുടരാം.

## progress 42 integration map — separated bowl-phase replay ownership

Clean oracle handoff state ഇപ്പോൾ താഴെപ്പറയുന്ന owners-ായി വേർതിരിച്ചിരിക്കുന്നു:

- `Hamlet/Juliet/Romeo/Othello/Macbeth` memories: actual stones rows `2..46` forward replays മാത്രം;
- `Caliban` memory: actual drops `2..46` forward replay മാത്രം;
- `Brutus` memory: 45 full orders x 6 IDs = 270-ID forward replay;
- `Antony` memory: dedicated actual drop46 six-ID forward latch;
- committed bowl scalars: progress 38 first actual bowl round-ന്റെ state untouched.

`test/sauce_foundation_actual_hidden_visible46_probe.spl` all-45 full-order pass-ൽ ഓരോ six-ID order local reverse ചെയ്ത് `Cleopatra` backward archive-ൽ preserve ചെയ്യുന്നു; completion-ൽ `Brutus` forward replay ആക്കുന്നു. structural suffix `270`.

`test/bowl_phase_separated_replay_probe.spl` small witness ആയി stone/drop/order/latch owners തമ്മിൽ intermix ഇല്ലെന്ന് ഉറപ്പാക്കുന്നു.

Immediate blocker: separated rows `2..46`, drops `2..46`, 270 order IDs, committed bowl state എന്നിവ same loop-ൽ consume ചെയ്ത് ഓരോ round-നും three position pours, six circular-neighbor position snapshots, six pending bowl values from one immutable committed old snapshot, then transactional six-bowl commit. i=46 dedicated `Antony` latch mutate ചെയ്യരുത്.

## Stage 1 clean continuation — progress 43: drops 2..46 transactional bowl recurrence

progress 42-ൽ semantic owners വേർതിരിച്ച state same integrated clean-oracle source ഇപ്പോൾ full remaining bowl rounds-ലേക്ക് consume ചെയ്യുന്നു. ഓരോ drop `2..46`-നും five stones + actual drop + six order IDs load ചെയ്ത ശേഷം six committed bowls-ന്റെ position-ordered old snapshot ആദ്യം പൂർണ്ണമായി copy ചെയ്യുന്നു. മൂന്ന് position pours അതിൽ നിന്ന് കണക്കാക്കുന്നു; തുടർന്ന് circular prev/current/next topology ഉപയോഗിച്ച് ആറു pending values മുഴുവൻ immutable old snapshot-ൽ നിന്ന് Titania memory-ലേക്ക് നിർമ്മിക്കുന്നു.

pending count `6` verify ചെയ്തതിന് ശേഷം മാത്രമാണ് Helena commit-target IDs-ഉം Titania pending values-ഉം pair ആയി pop ചെയ്ത് six committed bowl states mutate ചെയ്യുന്നത്. അതിനാൽ same-round write-after-read contamination ഇല്ല. loop exact `45` commits നടത്തി index `47`-ൽ അവസാനിക്കുന്നു. `Antony` dedicated drop46 latch executable path-ൽ untouched ആണ്.

ഇതോടെ immediate progress 42 blocker അടഞ്ഞു: actual generated drops `1..46` എല്ലാം normative per-drop six-bowl transactional recurrence-ൽ integrated ആണ്. അടുത്ത Stage 1 blocker dedicated drop46 latch ഉപയോഗിച്ച് Appendix A-യിലെ `12` committed post-stirs, ഓരോ stir-ലും ഒരിക്കൽ മാത്രം കണക്കാക്കുന്ന `savedBowlSum = SAVE(sum(oldBowls)+149*stir)`, തുടർന്ന് SauceResult/askBowl integration എന്നിവയാണ്. Gate/year/general DP/name-unrank/presentation/final five-field result, compliant SPL runtime GREEN എന്നിവയും പിന്നെയും ബാക്കി.

## Stage 1 clean continuation — progress 44: 12 post-stir transactional rounds

`test/sauce_foundation_actual_hidden_visible46_probe.spl` progress 43 final committed bowls-ൽ നിന്ന് post-stir phase same source-ൽ തുടരുന്നു.

- `Titania`: current stir number `1..12`;
- `Viola`: completed stir count;
- `Caliban`: one-per-stir immutable `savedBowlSum`;
- `Shylock`: existing exact `M`, overwrite ചെയ്യാതെ SAVE modulus;
- `Ariel/Falstaff/Rosalind/Horatio/Polonius/Cordelia`: current stir six order IDs;
- `Helena` memory: current stir six commit-target IDs, position order-ൽ;
- `Othello/Macbeth/Tybalt/Romeo/Hamlet/Juliet`: current stir immutable old-position snapshot;
- `Brutus` memory: current stir six pending values, position order-ൽ;
- committed bowls: `Miranda/Lady Macbeth/Beatrice/Benedick/Desdemona/Portia`;
- `Antony` memory: actual drop46 latch മാത്രം; post-stir executable segment touch ചെയ്യുന്നില്ല.

ഓരോ stir-ലും saved value ഒരിക്കൽ മാത്രം -> factoradic order -> permutation invariants -> six old-position copies -> six pending values -> pending-complete -> six transactional commits എന്ന ownership boundary ആണ്. commit കഴിഞ്ഞാൽ മാത്രമാണ് stir counter മുന്നോട്ട് പോകുന്നത്. exact 12 commits കഴിഞ്ഞ structural suffix `12,13,1,1,1,1,1,1`.

Immediate blocker ഇപ്പോൾ SauceResult/askBowl integration ആണ്: final six bowls + immutable `Antony` drop46 order latch ഒരേ sauce-result semantic state ആയി expose ചെയ്ത് queried bowl-ന്റെ successor drop46 order-ൽ resolve ചെയ്യുകയും seal-dependent `first`/`directionNumber` exact SAVE formulas bind ചെയ്യുകയും വേണം. അതിനു ശേഷമാണ് selection/gates/years/general DP/name-unrank/presentation/final tuple.

## progress 45 — SauceResult മുതൽ exact selection വരെ integrated bridge

`test/sauce_foundation_actual_hidden_visible46_probe.spl` ഇപ്പോൾ progress 44 post-stir state-ിൽ നിന്ന് തുടർന്നു:

`final bowls + drop46 latch -> non-destructive order materialization/restore -> circular successor -> askBowl first/direction -> short chooseRank rejection ring -> wide chooseRank boundary/rejection ring`.

state ownership:

- final bowl IDs `1..6`: `Miranda`, `Lady Macbeth`, `Beatrice`, `Benedick`, `Desdemona`, `Portia`; progress 45-ൽ read-only;
- `Shylock`: exact M, read-only;
- `Antony` memory: six-ID forward drop46 order latch; materialization സമയത്ത് six pops കഴിഞ്ഞ് temporary reverse archive വഴി same order-ൽ restore;
- order position scalars: `Othello`, `Macbeth`, `Hamlet`, `Juliet`, `Romeo`, `Tybalt`;
- `Caliban`: askBowl first;
- `Brutus`: fixed directionStep;
- selection scratch final bowls/latch overwrite ചെയ്യുന്നില്ല.

short path actual integrated family `N=922`; wide clean boundary `N=M+1`, expected places `2`.

ഇനി integrated general-calendar blocker: same-Foundation sauce instance-നെ arbitrary `targetDay` calls-ലേക്ക് ഉയർത്തി positive/negative gate gaps actual sauce/ask/chooseRank chain-ൽ നിർമ്മിക്കുക; തുടർന്ന് lazy signed gates, years, structure, final resolver.
