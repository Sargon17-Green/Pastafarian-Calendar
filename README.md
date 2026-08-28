# Shakespeare Programming Language / മലയാളം — ഘട്ടം 1 ആരംഭം

ഈ ഡയറക്ടറി മുമ്പുണ്ടായിരുന്ന repository-യിലേക്കുള്ള delta അല്ല. ഉപയോക്താവിന്റെ നിർദ്ദേശപ്രകാരം ഈ implementation line ഒരു പുതിയ repository ആയി ശൂന്യത്തിൽ നിന്ന് ആരംഭിക്കുന്നു.

ഈ ശ്രമത്തിന്റെ ഏക പ്രോഗ്രാമിങ് ഭാഷ Shakespeare Programming Language ആണ്. മനുഷ്യർ വായിക്കേണ്ട നടപ്പാക്കൽ ഗദ്യത്തിന്റെ ഏക ഉറവിടഭാഷ മലയാളമാണ്. മറ്റൊരു implementation-ന്റെ code, tests, fixtures, expected outputs, generated tables, caches, logs, hashes, checksums, oracle, അല്ലെങ്കിൽ differential ഫലങ്ങൾ ഇവിടെ ഉപയോഗിച്ചിട്ടില്ല.

നിലവിലുള്ള repository ഒന്നും മുൻകൂർ കരുതുന്നില്ല. ഈ package തന്നെയാണ് പുതിയ repository-യുടെ ആരംഭ working tree. Git history സൃഷ്ടിച്ചിട്ടില്ല; commit, tag, branch, push, pull, fetch, PR, issue, release, GitHub Actions എന്നിവ ഒന്നും നിർവഹിച്ചിട്ടില്ല.

ഈ package-ൽ ഇതിനകം തയ്യാറാക്കിയിരിക്കുന്നത്:

- 17 കട്ട്ലറ്റ് പേരുകളും 47 മാസം പേരുകളും സ്ഥിരമായ `canonicalIndex` സഹിതം ഉൾക്കൊള്ളുന്ന versioned source-language catalog;
- അർത്ഥമുള്ള പേരുകൾ മലയാളത്തിലേക്ക് അർത്ഥാനുവാദം ചെയ്യുകയും സ്ഥലനാമങ്ങൾ, വ്യക്തിനാമങ്ങൾ, അർത്ഥമില്ലാത്ത ശബ്ദസംയോജനങ്ങൾ നിർണ്ണിതമായി ലിപ്യന്തരം ചെയ്യുകയും ചെയ്യുന്ന നിയമം;
- ഭാവിയിലെ patch 01–26 ഒന്നും ഉൾക്കൊള്ളാത്ത നിഷ്പക്ഷ SPL bootstrap skeleton;
- exact-integer runtime contractയും `2^127-1` probe-ഉം;
- `regularMod`, `SAVE`, `dayCount`, `workCounts` എന്നിവ SPL-ൽ നടപ്പാക്കുന്ന test-only primitive oracle അരങ്ങ്;
- primitive expected outputs-ന്റെ സ്വതന്ത്ര Stage 1 പട്ടിക;
- ശേഷിക്കുന്ന Appendix A ഭാഗങ്ങളുടെ implementation map.

ഘട്ടം 1 ഇനിയും പൂർത്തിയായിട്ടില്ല. കാരണം repository അഭാവമല്ല. Appendix A-യുടെ പൂർണ്ണ test-only oracle ഇനിയും source-ൽ പൂർത്തിയായിട്ടില്ല; കൂടാതെ ഈ execution environment-ൽ പ്രാദേശികമായി പ്രവർത്തിപ്പിക്കാവുന്ന SPL runner/compiler ലഭ്യമല്ല. അതിനാൽ എഴുതിയ SPL source syntax/runtime-ൽ പ്രവർത്തിപ്പിച്ച് GREEN തെളിവ് നേടാനായിട്ടില്ല.

ഇനി ചെയ്യാതെ ബാക്കിയുള്ള നിർബന്ധിത ജോലികൾ:

- stones മുതൽ final five-field tuple വരെ Appendix A-യുടെ ശേഷിക്കുന്ന മുഴുവൻ oracle SPL-ൽ എഴുതുക;
- runtime exact arbitrary-precision arithmetic probe കടക്കുന്നതായി തെളിയിക്കുക;
- SPL-only fixtures, helper differential checks, end-to-end expected values എന്നിവ പൂർത്തിയാക്കുക;
- SPL runtime-ൽ എല്ലാ Stage 1 tests-ഉം പ്രവർത്തിപ്പിച്ച് GREEN തെളിവ് നേടുക;
- അതിനു ശേഷമേ `LAST_COMPLETED_STAGE=1` ആക്കാവൂ.

മറ്റൊരു implementation-ന്റെ output ഉപയോഗിച്ച് expected values സൃഷ്ടിക്കരുത്. Stage 1 GREEN ആകുന്നതിന് മുമ്പ് Stage 2-ലെ legacy bug അല്ലെങ്കിൽ patch code ഒന്നും ചേർക്കരുത്.

## ഏറ്റവും പുതിയ ഘട്ടം 1 പുരോഗതി

പൂർണ്ണ oracle-ിലേക്കുള്ള അടുത്ത ഭാഗങ്ങളായി stack runtime gate, simultaneous stone recurrence, hidden-drop trace, visible seed, visible grind-step probe എന്നിവ SPL-ൽ ചേർത്തിട്ടുണ്ട്. ഇവ test-only reference നിർമ്മാണത്തിന്റെ ഭാഗങ്ങളാണ്; production bootstrap-ിലേക്ക് future legacy/patch code ചേർത്തിട്ടില്ല. bowls, post-stirs, answer streams, gates, years, cutlets, months, weaving, final tuple എന്നിവ ഇനിയും പൂർത്തിയാക്കേണ്ടതിനാൽ Stage 1 പൂർത്തിയായതായി ഈ tree അവകാശപ്പെടുന്നില്ല.

## ഇപ്പോഴത്തെ Stage 1 പുരോഗതി

Test-only oracle source ഇപ്പോൾ primitive arithmetic, work counts, short/wide selection, stone step, hidden-drop trace, visible seed/ഒറ്റ grind എന്നിവയ്ക്ക് പുറമേ പതിനൊന്ന്-grind loop, answer-ring offset, six-item factoradic rank decomposition, year-pair validity predicate എന്നിവയും ഉൾക്കൊള്ളുന്നു. ഇത് ഇനിയും Appendix A-യുടെ end-to-end oracle അല്ല; Stage 2 ആരംഭിച്ചിട്ടില്ല.

## ഇപ്പോഴത്തെ Stage 1 പുരോഗതി

Test-only oracle source ഇപ്പോൾ primitive counts/selection/stones/drops ഭാഗങ്ങൾക്കൊപ്പം bowl/sauce scalar ഭാഗങ്ങളിലേക്കും എത്തിയിട്ടുണ്ട്: initial bowl formula, മൂന്ന് order-position pours, old-snapshot bowl update, 1A saved post-stir sum, post-stir bowl update, drop-46 latched successor, askBowl first/direction. ഇത് full calendar oracle അല്ല. Stage 1 പൂർത്തിയാകുന്നതിന് മുമ്പ് ഇവയെ actual permutation, 46-drop timeline, six-bowl simultaneous rounds, 12 post-stirs, gates, years, cutlets, months, weaving, five-field resolver എന്നിവയുമായി ബന്ധിപ്പിക്കണം; തുടർന്ന് SPL-only runtime test suite യഥാർത്ഥമായി GREEN ആകണം.

## ഏറ്റവും പുതിയ Stage 1 clean continuation

ഈ revision factoradic decomposition-ന്റെ പിന്നാലെയുള്ള remaining-item selection primitive, പൊതുവായ `wrap1`, `ceilDiv`, six-position bowl-round control fixture, month-count bounds, distinct-name family count-ന്റെ falling factorial എന്നിവ SPL test-only source ആയി ചേർക്കുന്നു. production bootstrap-ിൽ future legacy scar അല്ലെങ്കിൽ patch code ഒന്നും ചേർത്തിട്ടില്ല.

local static scan പ്രകാരം tree-ൽ 40 files ഉണ്ട്; അവയിൽ 30 SPL files ആണ്. അറിയാവുന്ന future-patch identifiers-ഉം `5781`-ഉം SPL source-ൽ ഇല്ല. ഇത് runtime GREEN തെളിവല്ല. full permutation integration മുതൽ final five-field resolver വരെ ശേഷിക്കുന്ന reference source-ും local SPL execution-ഉം പൂർത്തിയാകാതെ Stage 1 complete ആയി കണക്കാക്കരുത്.

## ഏറ്റവും പുതിയ Stage 1 തുടർച്ച — timeline, interval, boundary controls

ഈ revision Appendix A-യിലെ control semantics-ന്റെ അഞ്ചു ഭാഗങ്ങൾ കൂടി SPL test-only source ആയി ചേർക്കുന്നു: hidden/visible predecessor source mux, 1 മുതൽ 12 വരെ post-stir schedule, നിർബന്ധിത `(open,close]` year membership, internal exact calculation-gate cutlet boundary offset, sequential target-year walk direction. ഇവ future patch code അല്ല; clean oracle bootstrap-ന്റെ ചെറു ഘടകങ്ങൾ മാത്രം ആണ്.

Stage 1 ഇനിയും പൂർത്തിയായിട്ടില്ല. rolling drop values, full six-ID permutation materialization, full bowl/post-stir state chain, gates, year selection, cutlet/month combinatorics, weaving, final five-field result, കൂടാതെ SPL runtime GREEN തെളിവ് ഇനിയും വേണം.

## ഏറ്റവും പുതിയ Stage 1 തുടർച്ച — permutation materialization, composition window, weaving controls

ഈ revision ആറു factoradic digits-നെ active-set removal സഹിതം actual six-ID permutation ആക്കുന്ന SPL probe ചേർക്കുന്നു. കൂടാതെ bounded-composition candidate window, month-weaving legal move, weaving state transition, inclusive month-occurrence prefix count എന്നിവ clean Appendix A test-only source ആയി ചേർത്തിട്ടുണ്ട്. future legacy/patch code ഒന്നും production bootstrap-ിലേക്ക് ചേർത്തിട്ടില്ല.

ഇതോടെ factoradic digit-ുകളിൽ നിന്ന് actual permutation-ലേക്കുള്ള local source gap അടഞ്ഞുവെങ്കിലും end-to-end oracle ഇനിയും പൂർത്തിയായിട്ടില്ല. 46-drop rolling timeline, മുഴുവൻ bowl/post-stir state chain, gates, year selection/walk, full composition/weaving DP count+unrank, distinct-name unrank, final five-field result, SPL runtime GREEN തെളിവ് എന്നിവ ഇനിയും വേണം.

## ഏറ്റവും പുതിയ Stage 1 തുടർച്ച — gate/year/name integration primitives

ഈ revision permutation rank-ന്റെ ആദ്യ 120-size block/residual rank, signed gate question day, ചെറിയ three-gap signed gate chain, clean Year 5000 candidate predicate, distinct-name unrank-ന്റെ ആദ്യ falling-factorial block എന്നിവ SPL test-only source ആയി ചേർക്കുന്നു. ഇവ Appendix A-യുടെ clean semantics മാത്രം ആണ്; future legacy ceiling, cache scar, negative-gate patch, name-repeat detour എന്നിവ Stage 1-ൽ ചേർത്തിട്ടില്ല.

ഇതിനു ശേഷവും Stage 1 പൂർത്തിയായിട്ടില്ല. full rank-to-permutation integration, sauce-ൽ നിന്നുള്ള actual gate-gap generation, lazy gate cache/indexing, candidate enumeration/sorting/selection, full distinct-name repeated positions, cutlet/month DP count+unrank, weaving count+unrank, final five-field resolver, SPL runtime GREEN തെളിവ് എന്നിവ ഇനിയും വേണം.

## ഏറ്റവും പുതിയ Stage 1 clean continuation — gate ordering, repeated-name, small exact family counts

ഈ revision-ൽ full Appendix A oracle-ിലേക്കുള്ള ഏഴ് അടുത്ത slices കൂടി SPL source ആയി ചേർത്തു:

- `test/gate_gap_choice_probe.spl`: 1..922 selector rank-നെ 42..963 gate gap ആക്കുന്ന exact conversion;
- `test/year5000_pair_order_probe.spl`: Year 5000 candidate sort-ിന്റെ length-first, opening-day-tie-break order;
- `test/cutlet_count_candidate_count_probe.spl`: `6..min(17,gateGaps)` candidate family cardinality;
- `test/month_count_rank_resolve_probe.spl`: exact month-count bounds-ിൽ നിന്ന് one-based rank resolve;
- `test/distinct_name_two_choice_probe.spl`: distinct-name unrank-ന്റെ ആദ്യ രണ്ടു canonicalIndex തിരഞ്ഞെടുപ്പുകൾ, removal-aware mapping സഹിതം;
- `test/bounded_composition_two_slot_probe.spl`: രണ്ട്-slot bounded composition family-യുടെ exact count + lexicographic unrank;
- `test/weave_two_month_count_probe.spl`: രണ്ട് month threads-ന്റെ legal weaving family-യ്ക്ക് exact ചെറിയ count sanity gate.

ഇവ clean reference slices മാത്രമാണ്. rolling 7+46 values, 46 bowl-state commits, 12 full post-stirs, sauce-derived lazy gates, full year enumeration/selection/walk, general composition memo/unrank, general weaving memo/unrank, മുഴുവൻ distinct-name positions, final five-field resolver എന്നിവ ഇനിയും പൂർത്തിയാക്കണം. Stage 2 ആരംഭിച്ചിട്ടില്ല.

## ഏറ്റവും പുതിയ Stage 1 തുടർച്ച — rank-to-order integration, മൂന്ന്-slot families, cutlet/month final-resolution helpers

ഈ revision clean Appendix A reference-ന്റെ അടുത്ത integration ഭാഗങ്ങൾ SPL test-only source ആയി ചേർക്കുന്നു. `bowl_order_rank6_integrated_probe.spl` one-based rank `1..720` നേരിട്ട് factoradic digits-ആക്കി active six-ID set-ിൽ removal-aware ആയി materialize ചെയ്യുന്നു; അതിനാൽ rank decomposition-നും actual bowl order-നും ഇടയിലെ source gap ഇപ്പോൾ ഒരൊറ്റ SPL path-ൽ അടഞ്ഞു.

കൂടാതെ മൂന്ന്-slot bounded composition family-യ്ക്ക് exact countയും lexicographic unrank-ഉം, മൂന്ന് cutlet positive-composition family-യ്ക്ക് internal required-boundary filter സഹിതം exact count/unrank, cutlet interval-ിൽ നിന്ന് canonicalIndex + `dayInCutlet` resolve, weaving position-ിൽ നിന്ന് monthId resolve, ആദ്യ രണ്ടു name removals കഴിഞ്ഞ third ordinal mapping എന്നിവ ചേർത്തിട്ടുണ്ട്.

ഇവ future patch code അല്ല. production bootstrap ഇനിയും നിഷ്പക്ഷമാണ്. Stage 1 ഇനിയും പൂർത്തിയായിട്ടില്ല: rolling 7+46 drop timeline, 46 full bowl rounds, 12 full post-stir state chain, sauce-derived lazy gates, complete year enumeration/selection/walk, arbitrary-slot cutlet/month DP, arbitrary-month weaving memo/unrank, arbitrary-k distinct-name unrank, source-language string presentation resolve, exact five-field end-to-end result, SPL runtime GREEN തെളിവ് എന്നിവ ഇനിയും വേണം.

local static scan പ്രകാരം tree-ൽ 70 files ഉണ്ട്; അവയിൽ 60 SPL files ആണ്. അറിയാവുന്ന future-patch identifiers-ഉം `5781`-ഉം SPL source-ൽ ഇല്ല. ഇത് runtime execution-ന്റെ പകരം അല്ല.

## ഏറ്റവും പുതിയ Stage 1 തുടർച്ച — ordered gate lookup മുതൽ five-field resolver വരെ

ഈ revision clean Appendix A test-only source-ൽ ആറു അടുത്ത integration slices ചേർക്കുന്നു: നാല് gate-ുകളുള്ള ordered lookup, മൂന്ന് cutlet interval materialization, lengths `3,2` weaving family-യുടെ complete lexicographic unrank sanity slice, structure sauce target ആയി `openGateDay+1`, year number unit-step continuity, കൂടാതെ ചെറിയ materialized structure-ിൽ canonicalIndex-only semantics ഉപയോഗിച്ച് exactly five output fields resolve ചെയ്യുന്ന integrated probe.

ഇത് പ്രധാന പുരോഗതിയാണ്, കാരണം final resolver-ന്റെ അഞ്ചു fields ഇപ്പോൾ ഒരൊറ്റ SPL source path-ൽ കാണുന്നു. എന്നാൽ inputs ഇതിനകം materialized structure ആണ്; sauce, lazy gates, year candidate generation, arbitrary DP/unrank, full SourceLanguageCatalog presentation resolution എന്നിവ ഈ probe സൃഷ്ടിക്കുന്നില്ല. അതിനാൽ Stage 1 ഇനിയും പൂർത്തിയായിട്ടില്ല, Stage 2 ആരംഭിച്ചിട്ടില്ല.

## ഏറ്റവും പുതിയ Stage 1 clean continuation — four-slot families, post-stir order rank, lazy-cover/year-record controls

ഈ revision clean Appendix A oracle-ന്റെ ആറു അടുത്ത source slices SPL test-only tree-ലേക്ക് ചേർക്കുന്നു:

- `test/post_stir_order_rank_probe.spl`: 1A saved bowl sum-ിൽ നിന്ന് `1..720` post-stir bowl-order rank;
- `test/bounded_composition_four_slot_count_probe.spl`: നാല്-slot bounded composition family exact count;
- `test/bounded_composition_four_slot_unrank_probe.spl`: നാല്-slot family-യുടെ exact lexicographic unrank;
- `test/weave_two_two_one_unrank_probe.spl`: lengths `2,2,1` weaving family-യുടെ complete ചെറിയ lexicographic unrank;
- `test/year_transition_record_probe.spl`: next/previous year record-ൽ shared gate boundary + unit year-number step;
- `test/gate_cover_need_probe.spl`: lazy gate store ഏത് ദിശയിൽ മാത്രം വിപുലീകരിക്കണം എന്ന exact boundary control.

ഇവ future legacy/patch code അല്ല. clean reference family semantics slots=3-ൽ നിന്ന് slots=4 വരെ നീണ്ടു; post-stir saved value ഇപ്പോൾ order-rank derivation-ുമായി source-ൽ ബന്ധപ്പെട്ടു; year transition record-ന്റെ boundary ownership ചെറിയ integration path ആയി ഉണ്ട്. Stage 1 ഇനിയും complete അല്ല: rolling 7+46 drops, 46 full bowl commits, 12 full six-bowl post-stirs, sauce-derived gate gaps/store, full year candidate enumeration/selection/walk, arbitrary-K/general DP, arbitrary-m weaving memo/unrank, arbitrary-k distinct names, മലയാള presentation resolution, end-to-end generated five-field result, local SPL runtime GREEN എന്നിവ ഇനിയും വേണം.
## ഏറ്റവും പുതിയ Stage 1 തിരുത്തൽ — കിണ്ണ recurrence-കളിലെ square സ്ഥാനത്തിന്റെ ശരിയാക്കൽ

Appendix A വീണ്ടും വരി-വരി പരിശോധിക്കുമ്പോൾ രണ്ട് clean oracle probe-ുകളിൽ ഒരേ രൂപത്തിലുള്ള പിഴവ് കണ്ടെത്തി: `bowl_shadow_stir_probe.spl`-ൽ square മുഴുവൻ pre-square sum-ിന് പകരം `oldCurrent`-ന് മാത്രം പ്രയോഗിച്ചിരുന്നു; `post_stir_bowl_probe.spl`-ലും അതേ തെറ്റ് ഉണ്ടായിരുന്നു. Stage 1 ഇനിയും പൂർത്തിയായിട്ടില്ലാത്തതിനാൽ ഇത് historical patch അല്ല; അപൂർണ്ണ clean oracle-ന്റെ നേരിട്ടുള്ള തിരുത്തലാണ്. ഇപ്പോൾ ആദ്യ probe `s = oldCurrent + 2*oldPrev + 3*oldNext + pour + drop + stoneValue` കണക്കാക്കി `SAVE(s^2 + 5*oldPrev*oldNext + i*position)` ഉപയോഗിക്കുന്നു. രണ്ടാം probe `s = oldCurrent + 3*oldPrev + 5*oldNext + savedBowlSum + stirNumber + position^2` കണക്കാക്കി `SAVE(s^2 + 7*oldPrev*oldNext)` ഉപയോഗിക്കുന്നു. ബന്ധപ്പെട്ട ചെറിയ expected outputs യഥാക്രമം `16846`, `17130` ആയി തിരുത്തി. future patch code ഒന്നും ചേർത്തിട്ടില്ല; Stage 2 ആരംഭിച്ചിട്ടില്ല.

## ഏറ്റവും പുതിയ Stage 1 clean continuation — six-position bowl/post-stir integration, latch, four-slot boundary family

ഈ revision progress-15-ലെ corrected recurrence semantics-ിൽ നിന്ന് മാത്രം തുടരുന്നു. പുതിയ test-only SPL slices:

- `test/bowl_round_uniform_snapshot_probe.spl`: ഒരേ old snapshot ഉപയോഗിച്ച് ഒരു visible-drop round-ന്റെ ആറു positions-ും corrected pre-square formula പ്രകാരം output ചെയ്യുന്നു;
- `test/post_stir_uniform_round_probe.spl`: 1A saved sum-ിൽ നിന്ന് ഒരു മുഴുവൻ six-position post-stir scalar round വരെ ബന്ധിപ്പിക്കുന്നു;
- `test/drop46_latch_twelve_post_probe.spl`: drop-46 order latch പന്ത്രണ്ട് post-stir order reads കൊണ്ട് overwrite ആകുന്നില്ലെന്ന് source-level control gate;
- `test/cutlet_partition_four_slot_filter_probe.spl`: four-part positive-composition family-ൽ internal required-boundary prefix filter + exact count/unrank;
- `test/distinct_name_fourth_mapping_probe.spl`: മൂന്ന് removals കഴിഞ്ഞ fourth remaining ordinal original canonicalIndex ordinal-ിലേക്ക് map ചെയ്യൽ;
- `test/gate_gap_stream_short_probe.spl`: synthetic AnswerStream short selection മുതൽ exact `42..963` gate-gap conversion വരെ ഒരൊറ്റ source path.

ഇവ future historical scars അല്ല. production bootstrap നിഷ്പക്ഷമായി തുടരുന്നു. full oracle ഇനിയും complete അല്ല; പ്രത്യേകിച്ച് arbitrary order-ിലുള്ള 46 bowl rounds, rolling 7+46 drop values, actual twelve committed post-stir states, sauce-derived lazy gates, full years, arbitrary-K/m combinatorial DP/unrank, full name unrank, frozen മലയാള presentation resolve, generated five-field end-to-end result, local SPL runtime GREEN എന്നിവ ഇനിയും വേണം.

## ഏറ്റവും പുതിയ Stage 1 തുടർച്ച — progress 17

ഈ revision clean test-only oracle-ിൽ rolling predecessor boundary നാല് visible positions വരെ നീക്കുന്നു; identity order-ിൽ six distinct old bowl values ഒരേ snapshot ആയി ഉപയോഗിക്കുന്ന full no-wrap round ചേർക്കുന്നു; 1A saved sum rank 1 ആകുന്ന fixture-ൽ six distinct post-stir pending values source-ൽ ബന്ധിപ്പിക്കുന്നു; distinct-name removal mapping അഞ്ചാം position വരെ നീക്കുന്നു; മൂന്ന് year-pair candidates-ന്റെ clean validity batch ചേർക്കുന്നു.

production bootstrap-ിൽ future legacy scar ഒന്നും ചേർത്തിട്ടില്ല. `5781`, old remainder/day-tag/distance paths, negative-gate legacy question, bad year cache key, repeated-name generator, ghost weaving, contiguous-month guess എന്നിവ Stage 1 source-ൽ ഇല്ല.

Stage 1 ഇപ്പോഴും പൂർത്തിയായിട്ടില്ല. 46-drop exact rolling recurrence, arbitrary-order 46 bowl commits, committed 12 post-stirs, sauce-derived gates, full years, general DP/unrank, full name unrank, presentation resolve, generated five-field end-to-end result, local SPL runtime GREEN എന്നിവ ഇനിയും വേണം.

## ഏറ്റവും പുതിയ Stage 1 clean continuation — progress 18

ഈ revision progress-17-ൽ നിന്ന് മാത്രം തുടരുന്നു. clean test-only Appendix A source-ിൽ ആറു അടുത്ത integration slices ചേർത്തു:

- `test/rolling_two_visible_full_grinds_probe.spl`: hidden predecessor values-ിൽ നിന്ന് visible drop 1 seed, പതിനൊന്ന് grinds, commit, തുടർന്ന് അതേ committed value visible drop 2-ന്റെ `prev1` ആക്കി seed + പതിനൊന്ന് grinds വരെ ഒരൊറ്റ rolling source path;
- `test/bowl_nonidentity_order_round_probe.spl`: fixed non-identity order `3,1,6,2,5,4`-ൽ six distinct old bowl values ഒരേ snapshot ആയി വായിക്കുന്ന full six-position round;
- `test/post_stir_nonidentity_order_probe.spl`: 1A saved value `255` -> rank 255 order `3,1,5,4,2,6` -> six distinct pending post-stir values;
- `test/sauce_query_short_selection_probe.spl`: askBowl scalar output -> direction -> accepted short rank -> gate-gap conversion എന്ന integrated path;
- `test/distinct_name_sixth_mapping_probe.spl`: അഞ്ചു removals കഴിഞ്ഞ sixth remaining ordinal original canonical ordinal-ിലേക്ക്;
- `test/weave_two_two_two_unrank_probe.spl`: lengths `2,2,2` legal weaving family-യിലെ അഞ്ചു rows-ന്റെ complete small lexicographic unrank.

ഈ continuation-ൽ ഒരു Stage 1 clean-source mismatch കൂടി കണ്ടെത്തി: `post_stir_identity_order_no_wrap_probe.spl`-ന്റെ position 6 expression `position^2=36` ആകേണ്ടിടത്ത് source literal `20` ആയിരുന്നു, എന്നാൽ documented expected value ഇതിനകം `36` അനുസരിച്ചായിരുന്നു. source മാത്രം നേരിട്ട് ശരിയാക്കി; historical scar/patch ഒന്നും സൃഷ്ടിച്ചിട്ടില്ല. പുതിയ non-identity post-stir probe-ിലും position 6 `36` തന്നെയാണ്.

ഇതിനു ശേഷവും Stage 1 പൂർത്തിയായിട്ടില്ല. full seven-hidden generation, all 46 visible recurrences, actual 46 bowl commits, stir 1..12 മുഴുവൻ committed state chain, sauce-derived lazy gates, complete year enumeration/selection/walk, arbitrary-size memoized composition/weaving families, arbitrary-k name unrank, frozen മലയാള presentation resolution, generated end-to-end five-field calendar output, SPL-only runtime GREEN എന്നിവ ഇനിയും വേണം. Stage 2 ആരംഭിച്ചിട്ടില്ല.

## ഏറ്റവും പുതിയ Stage 1 clean continuation — progress 19

ഈ revision progress-18-ൽ നിന്ന് മാത്രം തുടരുന്നു. പുതിയ test-only SPL slices അഞ്ച്:

- `test/rolling_three_visible_full_grinds_probe.spl`: three committed visible drops വരെ predecessor ownership + seed + 11 zero-row grind loop;
- `test/post_stir_two_committed_rounds_probe.spl`: six pending values -> logical commit -> അടുത്ത six-bowl old snapshot എന്ന രണ്ടു-round transactional chain;
- `test/gate_signed_store_five_probe.spl`: Foundation-നെ ചുറ്റിയുള്ള `gate[-2..2]` ചെറിയ signed store materialization;
- `test/next_year_three_candidate_rank_probe.spl`: same-open next-year candidate scan, `gaps>=6`, `252..5778`, one-based rank resolve;
- `test/distinct_name_seventh_mapping_probe.spl`: six removals കഴിഞ്ഞ seventh-position canonical ordinal mapping.

ഇവ future historical scars അല്ല. production bootstrap നിഷ്പക്ഷമായി തുടരുന്നു. പ്രധാന blockers ഇപ്പോഴും full seven-hidden generation + 46 visible recurrences, 46 drop-derived bowl rounds, twelve normative committed post-stirs, sauce-derived arbitrary lazy gates, Year 5000/next/previous full candidate machinery, arbitrary-K/m DP/unrank, full distinct-name unrank, frozen മലയാള presentation resolution, generated end-to-end five-field result, local SPL runtime GREEN എന്നിവയാണ്.

## Stage 1 progress 20

clean test-only reference coverage ഇപ്പോൾ നാലാമത്തെ visible drop predecessor boundary, previous-year ranked candidate scan, five-slot bounded composition/count, five-slot internal-boundary cutlet partition count, eighth distinct-name mapping, lengths `3,2,2` weaving exact count എന്നിവ വരെ എത്തിയിട്ടുണ്ട്. Stage 2 ആരംഭിച്ചിട്ടില്ല; future legacy/patch code ഒന്നും ചേർത്തിട്ടില്ല. full Appendix A oracleയും local SPL-only GREEN execution-ഉം ഇനിയും പൂർത്തിയായിട്ടില്ല.

## Stage 1 clean continuation — progress 21

ഈ revision clean test-only oracle-ൽ അഞ്ച് integration slices കൂടി ചേർക്കുന്നു. ഏഴ് hidden coefficient rows ഒരേ source path-ൽ പരിശോധിക്കുന്നു; drop value 1-ന്റെ rank-1 identity bowl round-ൽ order/pours/shared-old-snapshot pending values ഒരുമിക്കുന്നു; target-year walk രണ്ട് unit next transitions വരെ നീളുന്നു; രണ്ട് accepted short stream values positive gate gaps ആക്കി cumulative gates materialize ചെയ്യുന്നു; lengths `3,2,2` weaving family count-ൽ നിന്ന് ഒൻപത് rows മുഴുവൻ lexicographic unrank witness ആയി വികസിക്കുന്നു. wide selector expectations-ൽ `N=M^2+1` boundaryയും ചേർത്തു.

ഇവ future historical defects അല്ല. production bootstrap നിഷ്പക്ഷമായി തുടരുന്നു; Stage 2 ആരംഭിച്ചിട്ടില്ല. full 7-hidden generation, 46-drop recurrence, 46 bowl commits, 12 normative post-stirs, sauce-derived lazy gates, full years/general combinatorial DP, source-language presentation, end-to-end five-field result, SPL runtime GREEN എന്നിവ ഇനിയും വേണം.

## Stage 1 continuation — progress 22

ഈ snapshot full-range control invariants-ിലേക്ക് നീങ്ങുന്നു. `rolling_46_source_ownership_counts_probe.spl` എല്ലാ 46 visible index-ുകളിലും prev1/prev3/prev7 hidden-to-visible ownership boundaries എണ്ണുന്നു; `visible_46x11_row_schedule_probe.spl` 46×11 grind row schedule മുഴുവൻ nested SPL control path-ൽ പരിശോധിക്കുന്നു. `bowl_46_transactional_commit_control_probe.spl` exactly 46 six-bowl pending-before-commit epochs isolate ചെയ്യുന്നു; `post_stir_12_transactional_commit_control_probe.spl` exactly 12 post-stir transactional commit epochs isolate ചെയ്യുന്നു. ഇവ normative arithmetic-ന്റെ പകരമല്ല; shared-old-snapshot ownership invariant full required cardinality വരെ നീട്ടുന്ന control witnesses ആണ്.

Year walking-ൽ `target_year_backward_two_step_probe.spl` forward two-step witness-ന്റെ symmetric previousYear path നൽകുന്നു. Year 5000 ordering-ൽ `year5000_three_candidate_sort_probe.spl` pairwise comparator-ിൽ നിന്ന് മൂന്ന് valid candidates-ന്റെ exact `length,open` ranking-ിലേക്ക് നീങ്ങുന്നു.

Stage 1 ഇപ്പോഴും incomplete ആണ്: actual seven hidden generation, all 46 visible value recurrence, arbitrary drop-derived bowl order/pours/formula, normative 12 post-stir state chain, sauce-derived gates, full candidate enumeration/selection, general DP/unrank, മലയാള presentation resolve, end-to-end five-field oracle, local SPL runtime GREEN എന്നിവ ശേഷിക്കുന്നു.

## Stage 1 continuation — progress 23

clean Appendix A reference-ിന്റെ sauce അടിത്തറയിൽ ആറു source slices കൂടി ചേർത്തു: ആദ്യ stone transition-ന്റെ actual simultaneous row, ആറു initial bowl formula family, non-identity order-ിൽ position-mapped pours, drop-46 latched order circular successor lookup, Foundation-ന്റെ ഇരുവശ signed gate step, കൂടാതെ 11 visible-grind rows-ന്റെ മുഴുവൻ `a,b,c,d,stoneKind` mapping. ഇവ future legacy patch logic അല്ല; Stage 1 test-only clean oracle-ന്റെ നേരിട്ടുള്ള ഭാഗങ്ങളാണ്.

ഇതോടെ stone/bowl/grind table semantics കൂടുതൽ concrete ആയി, പക്ഷേ full 46-drop state machine, 12 normative post-stir chain, generic gate/year/combinatorial DP, presentation resolve, end-to-end five-field oracle എന്നിവ ഇനിയും പൂർത്തിയായിട്ടില്ല.

## Stage 1 clean continuation — progress 24

ഈ revision Appendix A clean oracle-ന്റെ വലിയ exact-integer integration ശക്തിപ്പെടുത്തുന്നു. പുതിയ six test-only SPL slices `M=2^127-1` source-ൽ തന്നെ നിർമ്മിച്ച് hidden seven-grind recurrence-ന്റെ modulus lock, drop-derived 720 rank, ഒരു full visible bowl round, 1A post-stir saved sum + six-position arithmetic, നിർബന്ധിത `N=M^2+1` wide boundary, latched-wrap companion askBowl arithmetic എന്നിവ പരിശോധിക്കുന്നു.

ഈ fixtures small no-wrap arithmetic മാത്രം ആശ്രയിക്കുന്നില്ല: square/product intermediate values M-നെ വളരെ കവിയുന്നു, തുടർന്ന് SAVE അല്ലെങ്കിൽ wide modulo വഴി exact result-ിലേക്ക് മടങ്ങുന്നു. ഇതുകൊണ്ട് arbitrary-precision requirement source-level ആയി കൂടുതൽ നേരിട്ട് stress ചെയ്യുന്നു. എങ്കിലും full stone generation -> seven hidden values -> all 46 visible drops -> 46 bowl commits -> 12 committed post-stirs എന്ന ഒരൊറ്റ end-to-end sauce path ഇനിയും പൂർത്തിയായിട്ടില്ല. Stage 2 ആരംഭിച്ചിട്ടില്ല; future defect/patch code ഒന്നും ചേർത്തിട്ടില്ല.

## ഏറ്റവും പുതിയ Stage 1 clean continuation — progress 25

ഈ continuation clean Appendix A oracle-ന്റെ വേർതിരിച്ചിരുന്ന sauce primitives തമ്മിലുള്ള integration gap കുറയ്ക്കുന്നു; historical defect അല്ലെങ്കിൽ future patch behavior ഒന്നും ചേർത്തിട്ടില്ല.

- `test/stones_row2_to_row3_snapshot_probe.spl` row 2 commit കഴിഞ്ഞ് row 3-ന്റെ അഞ്ചു values ഒരേ old snapshot മാത്രം വായിച്ച് നിർമ്മിക്കുന്ന second consecutive stone transition witness ആണ്.
- `test/visible_eleven_M_integrated_table_probe.spl` 11-row coefficient dispatch-നെ generic visible recurrence-ുമായി ഒരേ execution path-ൽ ബന്ധിപ്പിക്കുന്നു; M-sized modulus-lock fixture ഓരോ row-ലും exact SAVE commit തെളിയിക്കാൻ രൂപപ്പെടുത്തിയതാണ്.
- `test/two_drop_two_bowl_commits_probe.spl` രണ്ട് consecutive visible-drop bowl rounds actual pour + six-position formulas സഹിതം നടത്തുകയും round 2 round 1-ന്റെ committed six-bowl snapshot മാത്രം വായിക്കണമെന്ന് ഉറപ്പാക്കുകയും ചെയ്യുന്നു.
- `test/sauce_46_12_latch_phase_probe.spl` 46 drop commits-ിൽ നിന്ന് 12 post-stir commits-ിലേക്കുള്ള phase boundary-യും drop-46 latch ഒരിക്കൽ മാത്രം എഴുതപ്പെടുന്നതും full-cardinality control ആയി ബന്ധിപ്പിക്കുന്നു.
- `test/ask_after_poststir_uses_latch_probe.spl` post-stir diagnostic order drop-46 latch-ിൽ നിന്ന് വ്യത്യസ്തമാക്കിയ fixture ഉപയോഗിച്ച് ask successor authoritative latch-ൽ നിന്നുതന്നെയാണെന്ന് distinguishing control നൽകുന്നു.

ഇതോടെ stone snapshot continuity, visible grind-table recurrence integration, multi-round bowl commit ownership, sauce phase cardinality, query/latch separation എന്നിവ source-level ആയി കൂടുതൽ ബന്ധപ്പെട്ടു. എന്നിരുന്നാലും complete 46-row stone table, generated seven hidden values, generated all-46 visible values, all-46 actual bowl rounds, 12 actual post-stir values, sauce-derived gates, complete years/general DP/weaving/name-unrank/presentation/final resolver, കൂടാതെ SPL runtime GREEN ഇനിയും വേണം.

## Stage 1 continuation — progress 26

ഈ continuation clean Appendix A test-only reference-ൽ fixed small probes-ിൽ നിന്ന് കൂടുതൽ full-cardinality/source-path coverage-ിലേക്ക് നീങ്ങുന്നു. ഏഴ് hidden drops-ന്റെ full seven-grind synthetic integration, row 1 മുതൽ row 46 വരെ transactional stone recurrence, 12 post-stir 1A saved-sum/rank schedule, clean 5778..5781 year ceiling boundary, dynamic sorted-removal canonical ordinal mapper, seal-10 Year 5000 short-selection bridge, closing-boundary five-field resolver fixture എന്നിവ ചേർന്നു.

ഇവയിൽ ചിലത് deliberately isolation/control fixtures ആണ്. അവ legal end-to-end workCounts അല്ലെങ്കിൽ complete generated sauce path എന്ന് അവകാശപ്പെടുന്നില്ല. production bootstrap ഇപ്പോഴും neutral ആണ്; test-only reference-ന്റെ source coverage മാത്രം വികസിപ്പിക്കുന്നു.

ഈ progress audit-ൽ `distinct_name_eighth_mapping_probe.spl`-ന്റെ പഴയ order-sensitive threshold shortcut കണ്ടെത്തി candidate-scan ആയി തിരുത്തി. expected canonicalIndex fixtures മാറിയിട്ടില്ല. ഇത് Stage 1 clean-reference correction മാത്രമാണ്.

## Stage 1 continuation — legal workCounts + full-46 rolling visible control

ഈ progress-ൽ clean Appendix A oracle-ന്റെ രണ്ട് വേർതിരിച്ചിരുന്ന ഭാഗങ്ങൾ കൂടുതൽ അടുത്ത് ബന്ധിപ്പിച്ചു. `work_counts_full_probe.spl` raw action/target day-ുകളിൽ നിന്ന് dayCount parity, chronological distance, connection, direction എന്നിവ മുഴുവൻ ഒരേ SPL source-ൽ നിർമ്മിക്കുന്നു. അതിൽ നിന്നുള്ള legal same-Foundation fixture `1,1,1,2,2` ഉപയോഗിച്ച് hidden coefficient rows-നും six initial bowls-നും പുതിയ exact witnesses ചേർത്തു.

കൂടാതെ `visible_46_full_rolling_invariant_probe.spl` 46 visible-drop outer commits, ഓരോ drop-ലെയും 11 normative grind coefficient rows, seven-slot predecessor rolling state എന്നിവ ഒരൊറ്റ source path-ൽ നടത്തുന്നു. ഇതിലെ stones/base synthetic invariant fixture ആണ്; അതിനാൽ actual generated 46-row stone lookup-ന്റെ പകരക്കാരനല്ല. Appendix A പ്രകാരം ഓരോ visible drop `i`-ലും എല്ലാ 11 grind-ുകളും അതേ `stones[i]` row തന്നെയാണ് ഉപയോഗിക്കുന്നത്; grind coefficient row മാത്രം `g=1..11` ആയി മാറുന്നു. അടുത്ത integration blocker actual retained stone row `i` values-നെ ഈ full-46 path-ലേക്ക് നൽകുകയും seed base-നെ legal workCounts/stone contribution-ൽ നിന്ന് നിർമ്മിക്കുകയും ചെയ്യുന്നതാണ്.

Stage 1 ഇനിയും incomplete ആണ്; production neutral bootstrap തന്നെയാണ്, test-only oracle production path-ൽ ചേർന്നിട്ടില്ല, Stage 2 ആരംഭിച്ചിട്ടില്ല.

## Stage 1 clean continuation — progress 28

ഈ revision ആദ്യം clean oracle-ിലെ ഒരു indexing പിഴവ് തിരുത്തുന്നു. progress 22-ൽ `visible_46x11_row_schedule_probe.spl` visible grind stone row `wrap1(i+g,46)` ആണെന്ന് തെറ്റായി രേഖപ്പെടുത്തിയിരുന്നു. Appendix A പ്രകാരം visible drop `i`-ന്റെ എല്ലാ 11 grind-ുകളും അതേ `stones[i]` row തന്നെയാണ് ഉപയോഗിക്കുന്നത്; `g` coefficient row-യും stone kind-ഉം മാത്രമാണ് മാറ്റുന്നത്. probe source, expectations, implementation map, handoff എന്നിവ ഈ revision-ൽ തിരുത്തി.

അതിനുശേഷം രണ്ട് test-only SPL integration slices ചേർത്തു. `visible_row1_two_grinds_legal_probe.spl` legal same-Foundation workCounts, actual stone row 1, മൂന്ന് predecessor fixtures എന്നിവയിൽ നിന്ന് seed `443`, grind-1 `197618`, grind-2 `39053862074` വരെ clean recurrence നേരിട്ട് ബന്ധിപ്പിക്കുന്നു. `visible_same_stone_row_kind_cycle_probe.spl` ഒരേ stone row-ൽ 11 grind kind cycle മുഴുവൻ isolate ചെയ്യുന്നു; row-1 values-ന്റെ selected sum `539` ആണ്.

production bootstrap-ിൽ future historical scar ഒന്നും ചേർത്തിട്ടില്ല. Stage 1 ഇനിയും incomplete ആണ്: actual 46-row stone values later lookup ചെയ്യാവുന്ന state-ൽ സൂക്ഷിക്കൽ, legal workCounts + generated stones -> seven hidden values, actual full-46 visible recurrence, all 46 bowl rounds, 12 post-stirs, gates, years, general DP/unrank, മലയാള presentation, generated five-field result, native SPL runtime GREEN എന്നിവ ശേഷിക്കുന്നു.

## Stage 1 clean continuation — progress 29

ഈ revision full stone table traversal-നെ പിന്നീട് sauce phase-ൽ consume ചെയ്യാവുന്ന state ownership-ലേക്ക് നീക്കുന്നു. `stones_full_46_forward_replay_probe.spl` actual row 1..46 transactional recurrence നിർമ്മിച്ച് അഞ്ച് stone families സ്വതന്ത്ര archive stack-ുകളിൽ സൂക്ഷിക്കുന്നു; generation കഴിഞ്ഞ് stack reversal വഴി row 1 ആദ്യം കിട്ടുന്ന forward replay രൂപപ്പെടുത്തുന്നു. expected control `45 transitions, 46 archived, 46 reversed`, replay first row `17,29,43,71,101` ആണ്.

അതോടൊപ്പം `hidden1_actual_row1_first_grind_probe.spl` legal workCounts + actual stone row 1-നെ hidden approach 1 seed-ലും ആദ്യ grind-ലും SAVE സഹിതം ബന്ധിപ്പിക്കുന്നു: `297 -> 89118`. `drop_M_factoradic_digits_probe.spl` M-sized visible drop-നെ 720 order rank 127-ലേക്ക്, തുടർന്ന് factoradic digits `1,0,1,0,0,0`-ലേക്ക് ബന്ധിപ്പിക്കുന്നു.

ഇതോടെ actual 46-row stone values forward-consumable ആയി retain ചെയ്യാനുള്ള source pattern ലഭിച്ചു. ഇനിയും blocker: ഈ replay stack-ുകൾ legal seven-hidden generation-ലും 46-visible outer loop-ലും ഒരേ sauce source-ൽ consume ചെയ്യുക; ഓരോ visible drop-നും rank digits active-ID removal വഴി complete six-bowl order ആക്കി pours + six pending + commit ചെയ്യുക; 12 post-stirs, gates, years, general DP/name/presentation/five-field path, runtime GREEN എന്നിവ പൂർത്തിയാക്കുക.

## Stage 1 clean continuation — progress 30

ഈ continuation progress-29-ൽ നിന്ന് മാത്രം തുടരുന്നു; Stage 2 ആരംഭിച്ചിട്ടില്ല, future legacy defect/patch behavior ഒന്നും production-ൽ ചേർത്തിട്ടില്ല.

ഈ revision retained stone replay-നെ ഒരു row മാത്രം തെളിയിക്കുന്ന witness-ിൽ നിന്ന് sequential two-row consumption വരെ നീട്ടി: full 46-row generation/reversal കഴിഞ്ഞ് row 1 `17,29,43,71,101` മാത്രമല്ല, അടുത്ത replay row 2 `378,1073,2375,6195,10493` ആണെന്നും source-level ആയി പരിശോധിക്കുന്നു. row 1 snapshot-ൽ നിന്ന് row 2 transactional ആയി നിർമ്മിച്ച് same-Foundation legal workCounts-ോടുകൂടി visible drop `i=2` seed `37213`, first grind `1384919409` വരെ പുതിയ integration path ചേർന്നു.

Drop/order/bowl ഭാഗത്തും രണ്ട് bridge ചേർന്നു. rank 127-ന്റെ factoradic digits `1,0,1,0,0,0` active-ID removal വഴി order `2,1,4,3,5,6` ആയി materialize ചെയ്യുന്നു. അതേ order, `drop=M`, six old bowls `M`, actual row-1 stones എന്നിവയിൽ മൂന്ന് pours + six bowl formulas ചേർന്ന് bowl-ID order-ൽ `1158,401,5045,2503,10206,295` നൽകുന്നു. അവയുടെ sum `19608`; stir 1-ന്റെ 1A saved sum `19757`; bowl-order rank `317`. rank 317-നും full materialized order `3,5,1,6,2,4` ആയി പുതിയ bridge ഉണ്ട്.

ഇതോടെ full sauce path ഇനിയും പൂർത്തിയായിട്ടില്ല. പ്രധാന blocker actual seven hidden values + retained forward stones + all 46 visible values ഒരേ source-ൽ ബന്ധിപ്പിക്കൽ, തുടർന്ന് drop-derived order/pours/all-46 bowl commits, 12 committed post-stirs, sauce-derived gates, complete year machinery, general composition/weaving/name-unrank, മലയാള presentation resolution, generated final five-field result, SPL runtime GREEN എന്നിവയാണ്.

## Stage 1 continuation — actual seven-hidden path and seven-slot timeline ring

ഈ continuation retained 46-row stone table-ന്റെ forward replay-ൽ നിന്ന് rows 1..7 നേരിട്ട് consume ചെയ്ത് same-Foundation legal workCounts fixture-നൊപ്പം ഏഴ് hidden values പൂർണ്ണമായി കണക്കാക്കുന്നു. ഓരോ hidden value-നും ഏഴ് normative grinds commit ചെയ്ത ശേഷം backward archive-ൽ സൂക്ഷിക്കുന്നു; archive പിന്നീട് Appendix A timeline positions-നുസരിച്ച് seven-slot rolling ring-ലേക്ക് seed ചെയ്യുന്നു.

ഇതോടൊപ്പം ring index mapping മുഴുവൻ i=1..46-ൽ പരിശോധിക്കുന്ന control-ും hidden→visible handoff കാണിക്കുന്ന eight-commit synthetic ownership witness-ും ചേർന്നു. ഇവ production semantics മാറ്റുന്നില്ല; test-only clean oracle slices ആണ്. Stage 1 ഇനിയും പൂർത്തിയായിട്ടില്ല.

## Stage 1 continuation — actual hidden-to-visible bridge and dual stone replay ownership

clean test-only oracle-ൽ actual 46-row stones ഉപയോഗിച്ച് ഉണ്ടാക്കിയ ഏഴ് hidden values ഇപ്പോൾ visible generation-ലേക്ക് നേരിട്ട് കടക്കുന്നു. `hidden_actual_to_visible_two_full_probe.spl` hidden ring-ൽ നിന്ന് visible 1 predecessor snapshot എടുത്ത് actual row 1-ൽ 11 grinds മുഴുവനായി നടത്തുന്നു; committed visible 1 ഉപയോഗിച്ച് row 2 transactional stone update ചെയ്യുകയും visible 2-ന്റെ predecessor snapshot-ലേക്ക് committed visible1 ചേർത്ത് row 2-ൽ വീണ്ടും 11 grinds നടത്തുകയും ചെയ്യുന്നു. രണ്ടാം committed drop bowl-order one-based rank domain-ലേക്കും ബന്ധിപ്പിക്കുന്നു.

`stone_dual_consumer_replay_control_probe.spl` ഒരേ ordered 46-row stone family hidden generation-നും visible generation-നും സ്വതന്ത്ര forward consumers ആയി ലഭിക്കേണ്ട ownership pattern വ്യക്തമാക്കുന്നു. future patch behavior ഒന്നും production-ൽ ചേർത്തിട്ടില്ല; production bootstrap ഇപ്പോഴും neutral ആണ്.

അതേ integrated source actual visible 2-ന്റെ one-based rank-നെ six factoradic digits-ആക്കി തുറന്ന് ഓരോ digit-ന്റെയും നിയമാനുസൃത domain source-ൽ പരിശോധിക്കുന്നു. ഇതോടെ actual generated drop -> rank -> factoradic-digit bridge clean oracle-ൽ ഒരൊറ്റ execution path-ൽ എത്തിയിരിക്കുന്നു; full active-ID removal order materialization അടുത്ത integration blocker ആണ്.

## Stage 1 continuation — progress 33

clean test-only oracle ഇപ്പോൾ actual five-value stone ownership-നെ രണ്ടു consumers-ലേക്ക് duplicate ചെയ്യുന്നു; hidden consumer rows `1..7` consume ചെയ്താലും visible consumer independent ആയി rows `1..46` consume ചെയ്യുന്നു. അതിന് മുകളിൽ പുതിയ integrated source same-Foundation legal workCounts-ൽ full 46-row stone generation, seven actual hidden drops, hidden history seed, എല്ലാ 46 actual visible drops, ഓരോ visible drop-ലും 11 normative grinds, rolling commit എന്നിവ ഒരൊറ്റ SPL path-ൽ ബന്ധിപ്പിക്കുന്നു.

അവസാന committed visible value drop 46 ആയി `1+regularMod(drop46-1,720)` bowl-order rank domain-ലേക്കും, തുടർന്ന് factoradic digit domain-ലേക്കും same source-ൽ എത്തുന്നു. full active-ID removal/materialized order, 46 bowl rounds, 12 post-stirs, gates/years/general DP/final five-field path ഇനിയും പൂർത്തിയായിട്ടില്ല. production bootstrap test oracle-നെ വിളിക്കുന്നില്ല; Stage 2 ആരംഭിച്ചിട്ടില്ല.

progress 33 audit-ൽ progress 31/32 hidden loop-ിലെ ഒരു clean-reference control-flow reset കൂടി കണ്ടെത്തി. hidden index/count initialization ഇപ്പോൾ reversal completion-ൽ ഒരിക്കൽ മാത്രം നടക്കുന്നു; ഓരോ hidden commit-നും ശേഷം loop entry അവ വീണ്ടും reset ചെയ്യുന്നില്ല. ഇത് historical patch അല്ല; Stage 1 പൂർത്തിയാകുന്നതിന് മുമ്പുള്ള test-only oracle correction ആണ്.

## Stage 1 continuation — progress 34

clean test-only oracle-ൽ full sauce path drop46 factoradic digit decomposition-ൽ നിന്ന് ഇനി six active bowl IDs removal-aware ആയി materialize ചെയ്യുന്നു. dynamic rank/drop/order hard-code ചെയ്തിട്ടില്ല: generated drop46 -> rank -> six digits -> six selections എന്ന same path ആണ്. ഓരോ selected ID-യും backward archive stack-ൽ push ചെയ്യുന്നു; ആറു selections കഴിഞ്ഞ് archive reverse ചെയ്ത് position 1 ആദ്യം ലഭിക്കുന്ന forward-order replay stack ഉണ്ടാക്കുന്നു. structural invariants selection count `6`, selected-ID sum `21`, product `720`, reverse count `6` ആണ്.

`dynamic_order_three_pours_dispatch_probe.spl` materialized order-ന്റെ ആദ്യ മൂന്ന് IDs arbitrary input ആയി സ്വീകരിച്ച് old six-bowl snapshot-ൽ നിന്ന് ID അനുസരിച്ച് value തിരഞ്ഞെടുക്കുകയും position pours 1..3 `SAVE` സഹിതം കണക്കാക്കുകയും ചെയ്യുന്നു. fixture order `3,1,6`, old bowls `2,3,5,7,11,13`, drop/i `1/1`, stones `17,29,43` ഉപയോഗിച്ച് pours `89,64,567` ലഭിക്കണം.

ഇതോടെ blocker dynamic drop46 digits -> full six-ID order വരെ മാറി. ഇനിയും all 46 visible drops-ന്റെ ഓരോ dynamic order-വും materialize ചെയ്ത് initial bowls മുതൽ six-pending shared-old-snapshot update, transactional commit, drop46 order latch, 12 post-stirs, gates/years/general DP/name-unrank/final five-field path പൂർത്തിയാക്കണം. production bootstrap neutral ആണ്; Stage 2 ആരംഭിച്ചിട്ടില്ല.

### progress 34 clean-reference correction — active ID 5

source audit-ൽ മുമ്പത്തെ four permutation materializer probes-ൽ active ID 5-ന്റെ zero-digit branch തെറ്റായി decrement path-ലേക്ക് പോകുന്നതായി കണ്ടെത്തി. zero digit ഇപ്പോൾ ID 5 തന്നെ തിരഞ്ഞെടുക്കുന്നു; positive digit മാത്രം decrement ചെയ്ത് ID 6 scan-ലേക്ക് നീങ്ങുന്നു. rank `481 -> 5,1,2,3,4,6` fixture ഈ branch നേരിട്ട് cover ചെയ്യുന്നു. same correction പുതിയ full sauce drop46 materializer-ലും ബാധകമാണ്. ഇത് historical patch അല്ല; Stage 1 clean oracle പൂർത്തിയാകുന്നതിന് മുമ്പുള്ള correction ആണ്.

## Stage 1 continuation — progress 35

clean oracle-ന്റെ വലിയ same-Foundation sauce integration ഇപ്പോൾ visible generation കഴിഞ്ഞ് bowl phase-നാവശ്യമായ state നഷ്ടപ്പെടുത്തുന്നില്ല. ഓരോ visible iteration-ലും actual five-value stone row, committed drop value എന്നിവ backward archive ചെയ്യുന്നു; 46 drops കഴിഞ്ഞാൽ ആ ആറു archives forward replay-കളാക്കി മാറ്റുന്നു. അതിന്റെ ആദ്യ consume actual `stones[1]=17,29,43,71,101`യും actual `visible[1]`-ഉം bowl-phase cursor-ലേക്ക് കൊണ്ടുവരുന്നു. തുടർന്ന് actual drop 1-ൽ നിന്ന് one-based `1..720` rankയും six factoradic digits-ും same source path-ൽ കണക്കാക്കി domain-check ചെയ്യുന്നു.

`dynamic_order_circular_neighbors_probe.spl` arbitrary six-ID order-ന്റെ circular `prev/current/next` topology positions 1..6 മുഴുവൻ isolate ചെയ്യുന്നു. ഇതോടെ അടുത്ത integration target actual drop 1 digits -> full order materialization -> three pours -> six shared-old-snapshot pending bowl values എന്നതാണ്.

## Stage 1 തുടർച്ച — initial bowl state മുതൽ full six-position bowl formula വരെ

ഈ progress-ൽ bowl phase-ന്റെ രണ്ട് വേർതിരിച്ച integration gaps അടച്ചു. same-Foundation legal workCounts-ൽ നിന്നുള്ള six initial bowls ഇപ്പോൾ order positions `3,1,6` ഉപയോഗിച്ച direct pours-ലേക്ക് same SPL source-ൽ കടക്കുന്നു. കൂടാതെ non-identity six-position order fixture-ൽ position stone cycle `WHEAT,BARLEY,SALT,BITTER,RED,WHEAT`, circular neighbors, first-three direct pours, drop contribution, `i*position`, shared-old-snapshot pending computation എന്നിവ ഒരുമിച്ച് പരിശോധിക്കുന്ന full bowl-round source ചേർന്നു.

ഇത് actual generated drop1-ന്റെ order materialization അല്ല; അതിനാൽ integrated all-46 sauce path-ന്റെ അടുത്ത ഘട്ടം ഇനിയും വേറെയുണ്ട്. ഇപ്പോഴത്തെ ലക്ഷ്യം actual drop1 factoradic digits-നെ full six-ID order-ലേക്ക് materialize ചെയ്ത് legal initial bowls + actual row1/drop1-ൽ ഇതേ round semantics പ്രയോഗിക്കുകയാണ്.

## Stage 1 clean-reference progress 37

valid progress 36-ൽ നിന്ന് clean continuation. `sauce_foundation_actual_hidden_visible46_probe.spl` actual generated visible drop 1-ന്റെ factoradic digits ഇനി six active bowl IDs-ൽ removal-aware ആയി materialize ചെയ്യുന്നു; count/sum/product invariants `6,21,720`, reverse count `6` ആണ്. അതേ source same-Foundation legal initial bowls `87617,136163,289447,724205,944789,1907167` പുനർനിർമ്മിക്കുന്നു, `M=2^127-1` വീണ്ടും exact ആയി നിർമ്മിക്കുന്നു, actual materialized order positions 1..3-ന് old-bowl snapshot dynamic ID lookup നടത്തി row-1 stones + actual drop1 ഉപയോഗിച്ച് three direct pours `SAVE` സഹിതം കണക്കാക്കുന്നു. pour numeric values hard-code ചെയ്തിട്ടില്ല; ഓരോ result-ും `1..M` range control വഴി പരിശോധിക്കുന്നു.

ഇതോടെ actual drop1 full order + legal old-bowl snapshot + actual first-three position-based pours same integrated sauce source-ൽ ഒരുമിച്ചു. first real six-bowl pending vector/transactional commit ഇനിയും അടുത്ത blocker ആണ്; production bootstrap neutral തന്നെയാണ്, Stage 2 ആരംഭിച്ചിട്ടില്ല.

## Stage 1 continuation — actual drop1 first transactional bowl commit

clean test-only oracle-ന്റെ integrated same-Foundation path ഇനി actual generated visible drop 1-ന്റെ first real six-bowl round വരെ എത്തുന്നു. actual drop1-ൽ നിന്ന് materialize ചെയ്ത full order, legal initial bowls, actual row1 stones, exact direct pours എന്നിവ ഉപയോഗിച്ച് circular position snapshot നിർമ്മിക്കുന്നു. commit-target bowl IDs memory archive-ൽ വേർതിരിച്ച് സൂക്ഷിക്കുന്നതിനാൽ position scalars old-bowl values ആയി മാറ്റിയാലും identity നഷ്ടപ്പെടുന്നില്ല.

ആറ് pending bowls മുഴുവൻ immutable old snapshot-ൽ നിന്ന് കണക്കാക്കി memory-ൽ സൂക്ഷിച്ചശേഷം മാത്രമാണ് bowl ID state mutate ചെയ്യുന്നത്. അതിനാൽ Stage 1 clean oracle-ൽ first actual bowl round transactional ownership source-ൽ explicit ആയി lock ചെയ്തിരിക്കുന്നു. അടുത്ത ലക്ഷ്യം ഇതേ machinery drops `2..46`-ലേക്ക് iterate ചെയ്ത് generated drop46 order latch ചെയ്യുന്നതാണ്.

## Stage 1 clean continuation — progress 39

ഈ revision progress 38-ലെ first actual generated-drop bowl commit കഴിഞ്ഞ state-ൽ നിന്ന് തുടരുന്നു. `test/sauce_foundation_actual_hidden_visible46_probe.spl` bowl state മാറ്റാതെ retained actual visible-drop replay-ന്റെ ശേഷിക്കുന്ന `drop2..drop46` consume ചെയ്യുന്നു. ഓരോ actual drop-നും one-based 720 rank, zero-based residual, blocks `120,24,6,2,1` ഉപയോഗിച്ച factoradic digits source-ൽ exact ആയി കണക്കാക്കുന്നു.

Drop 1 ഇതിനുമുമ്പ് same source-ൽ rank/factoradic/full-order ആയി process ചെയ്തതിനാൽ all-drop coverage counter `1`-ൽ ആരംഭിക്കുന്നു; 45 retained drops consume ചെയ്ത ശേഷം count `46`, next index `47`, final drop46 rank-domain flag `1`, factoradic-domain flag `1` ലഭിക്കേണ്ടതാണ്.

ഇത് all-46 bowl rounds പൂർത്തിയായെന്ന അവകാശവാദമല്ല. progress 39 all actual drops-ന്റെ rank/factoradic decomposition path മാത്രമാണ് full-cardinality ആക്കുന്നത്. അടുത്ത integration step ഈ dynamic digits ഓരോ round-ലും six-ID materialization, position pours, shared-old-snapshot pending values, transactional commit എന്നിവയിലേക്ക് ബന്ധിപ്പിക്കുകയാണ്; i=46-ൽ order latch വേർതിരിച്ച് നിലനിർത്തണം.

## Stage 1 continuation — progress 40: dedicated drop46 full-order latch and preserved actual-drop replay

Clean test-only sauce integration ഇപ്പോൾ actual drop46 six-ID order working materialization-ിൽ നിന്ന് വേറിട്ട dedicated latch archive-ൽ copy ചെയ്യുന്നു. first drop bowl commit + retained drops 2..46 rank/factoradic scan കഴിഞ്ഞിട്ടും latch touch ചെയ്യപ്പെടുന്നില്ല; scan completion-ൽ അത് forward order-ലേക്ക് reverse ചെയ്ത് `count=6, sum=21, product=720` structural invariants തെളിയിക്കുന്നു.

അതോടൊപ്പം rank scan actual generated drops `2..46` വീണ്ടും backward archive-ൽ preserve ചെയ്യുന്നു; completion-ൽ 45 values future forward replay ആയി മാറ്റുന്നു. ഇതാണ് അടുത്ത all-46 order/pour/bowl loop-ന് input ownership. പുതിയ `drop46_full_order_latch_probe.spl` rank-only latch-നേക്കാൾ ശക്തമായി six exact order positions പന്ത്രണ്ട് diagnostic reads കഴിഞ്ഞിട്ടും മാറാത്തത് fixture-ൽ ഉറപ്പാക്കുന്നു.

Stage 1 ഇപ്പോഴും incomplete ആണ്: actual drops `2..46` full order materialization + pours + six-bowl transactional commits, 12 normative post-stirs, SauceResult/askBowl, signed gates, years, general DP/weaving/name-unrank, മലയാള presentation resolve, generated five-field end-to-end result, compliant SPL runtime GREEN എന്നിവ ബാക്കി.

## Stage 1 continuation — progress 41: all actual drops full-order materialization coverage

progress 40-ലെ preserved actual drops `2..46` forward replay ഇപ്പോൾ same integrated clean-oracle source വീണ്ടും consume ചെയ്യുന്നു. ഓരോ drop-നും one-based 720-rank, factoradic digits, six-ID active-set removal എന്നിവ source-ൽ നേരിട്ട് നടത്തുന്നു. ഓരോ resulting order-നും `count=6`, `sum=21`, `product=720` satisfy ചെയ്താൽ മാത്രം loop മുന്നോട്ട് പോകുന്നു.

ഈ pass committed six-bowl state clobber ചെയ്യാതിരിക്കാനായി active flags വേറിട്ട scalar characters-ൽ ആണ്; progress 38-ലെ actual drop1 transactional bowl state untouched ആണ്. ഓരോ processed actual drop വേറൊരു backward archive-ൽ preserve ചെയ്ത് completion-ൽ വീണ്ടും exactly 45-value forward replay ആക്കുന്നു. dedicated drop46 full-order latch ഇതിനിടയിൽ mutate ചെയ്യുന്നില്ല.

integrated structural output sequence-ന്റെ പുതിയ suffix `0,45` ആണ്: all-45 full-order loop remaining count zero, rebuilt drop replay count 45.

Stage 1 ഇപ്പോഴും incomplete ആണ്: drops `2..46` position pours + shared-old-snapshot six pending values + transactional commits, 12 normative post-stirs, complete SauceResult/askBowl, signed gates, years, general composition/weaving/name unrank, മലയാള presentation resolve, generated five-field end-to-end result, compliant SPL runtime GREEN എന്നിവ ബാക്കി.

## Stage 1 clean continuation — progress 42: bowl-phase ownership separation and 270-ID order replay

progress 41-ന്റെ all-45 full-order materialization pass audit ചെയ്യുമ്പോൾ future bowl phase-നായി reuse ചെയ്തിരുന്ന memory owners clean semantic ownership ലംഘിക്കുന്നതായി കണ്ടെത്തി. barley stone replay നിലനിൽക്കുന്ന `Juliet` memory-ൽ drop46 latch കൂടി വയ്ക്കുന്നതും salt stone replay നിലനിൽക്കുന്ന `Romeo` memory-ൽ drops `2..46` replay കൂടി വയ്ക്കുന്നതും stack intermix സൃഷ്ടിക്കാമായിരുന്നു. ഇത് historical defect അല്ല; Stage 1 clean oracle-ന്റെ incomplete ownership model ആണ്.

progress 42 owners വ്യക്തമായി വേർതിരിക്കുന്നു: `Hamlet/Juliet/Romeo/Othello/Macbeth` memories stones rows `2..46` മാത്രം സൂക്ഷിക്കുന്നു; `Caliban` actual drops `2..46` forward replay മാത്രം; `Antony` dedicated drop46 six-ID forward latch മാത്രം; `Cleopatra` drops `2..46`-ന്റെ 45 full orders backward archive; `Brutus` completion-ൽ 270-ID forward order replay.

ഓരോ current full order Helena memory-ൽ position order-ൽ push ചെയ്യുന്നതിനാൽ direct pop position6..1 ആയിരിക്കും. source ആദ്യം ആ ആറു IDs `Brutus` temporary memory-ലേക്ക് reverse ചെയ്യുന്നു; തുടർന്ന് `Brutus`-ൽ നിന്ന് position1..6 ആയി pop ചെയ്ത് `Cleopatra` global backward archive-ലേക്ക് push ചെയ്യുന്നു. 45 orders കഴിഞ്ഞ് മുഴുവൻ `Cleopatra` archive `Brutus`-ലേക്ക് reverse ചെയ്യുമ്പോൾ future pop sequence കൃത്യമായി `drop2 position1..6, drop3 position1..6, ... drop46 position1..6` ആകുന്നു. structural suffix `270` ആണ്.

`bowl_phase_separated_replay_probe.spl` ഈ ownership model ഒരു ചെറിയ source witness ആയി isolate ചെയ്യുന്നു: stones, future drop, future order, dedicated drop46 latch എന്നിവ വേർതിരിച്ച memories-ൽ നിന്ന് വായിച്ചിട്ടും അടുത്ത stone row untouched ആയി തുടരുന്നു. expected outputs: `2,3,4,5,6,12,1,2,3,4,5,6,3,1,6,2,5,4,7,8,9,10,11`.

Stage 1 ഇപ്പോഴും incomplete ആണ്. അടുത്ത integration target ഈ separated replays ഉപയോഗിച്ച് drops `2..46`-ന്റെ position pours, circular-neighbor lookup, immutable committed old-bowl snapshot, six pending values, transactional commits എന്നിവ all-45 loop ആയി പൂർത്തിയാക്കുന്നതാണ്; തുടർന്ന് dedicated drop46 latch ഉപയോഗിച്ച് 12 normative post-stirs, SauceResult/askBowl, gates, years, general DP/name-unrank, മലയാള presentation resolve, generated five-field result എന്നിവ പൂർത്തിയാക്കണം.

## Stage 1 clean continuation — progress 43: remaining 45 bowl rounds integrated

progress 42-ൽ തയ്യാറാക്കിയ separated bowl-phase state ഇനി `test/sauce_foundation_actual_hidden_visible46_probe.spl`-ൽ drops `2..46` മുഴുവൻ consume ചെയ്യുന്നു. ഓരോ round-ലും stone row, actual drop, six order IDs load ചെയ്ത് committed bowl state-ന്റെ six position values ആദ്യം old snapshot ആയി വേർതിരിക്കുന്നു. അതിന് ശേഷം മാത്രം three position pours, six circular-neighbor pending formulas എന്നിവ കണക്കാക്കുന്നു.

ആറ് pending values മുഴുവൻ memory-ൽ തയ്യാറായി count `6` ആയ ശേഷം മാത്രമാണ് six archived bowl IDs-ലേക്ക് transactional commit നടക്കുന്നത്. ഇതിലൂടെ Appendix A ആവശ്യപ്പെടുന്ന same-old-state semantics source structure-ൽ explicit ആണ്. 45 rounds കഴിഞ്ഞാൽ index `47`; final six committed bowls `1..M` SAVE-domain controls pass ചെയ്യേണ്ട structural suffix `45,47,1,1,1,1,1,1` ആണ്.

`Antony` memory-യിലെ dedicated drop46 order latch ഈ loop touch ചെയ്യുന്നില്ല. അതിനാൽ അടുത്ത clean Stage 1 target 12 normative post-stirs ആണ്; അവയ്ക്കുശേഷം SauceResult/askBowl, gates, years, cutlet/month/weaving DP, distinct-name unrank, മലയാള presentation resolve, final five-field result, compliant SPL runtime GREEN എന്നിവ ഇനിയും പൂർത്തിയാക്കണം.

## Stage 1 clean continuation — progress 44: twelve normative post-stirs integrated

progress 43-ൽ drops `1..46` മുഴുവൻ transactional bowl recurrence complete ആയ committed state-ൽ നിന്ന് same integrated test-only oracle ഇപ്പോൾ Appendix A Interpretation 1A-യിലെ `12` post-stirs നടത്തുന്നു. ഓരോ stir-ന്റെ തുടക്കത്തിൽ committed bowls മാറ്റാതെ `savedBowlSum = SAVE(sum(oldBowls)+149*stir)` ഒരിക്കൽ മാത്രം കണക്കാക്കുന്നു; അതിൽ നിന്ന് one-based rank/factoradic six-ID order source-ൽ materialize ചെയ്യുന്നു.

ആ order positions-ൽ six committed bowls immutable old snapshot ആയി copy ചെയ്തശേഷം മാത്രം six pending values കണക്കാക്കുന്നു. എല്ലാ pending formulas-ും അതേ old snapshot-ും അതേ saved value-ും ഉപയോഗിക്കുന്നു: `s = current + 3*prev + 5*next + savedBowlSum + stir + position^2`, തുടർന്ന് `SAVE(s^2 + 7*prev*next)`. six pending complete ആയതിന് ശേഷം മാത്രം matching order IDs-ലേക്ക് transactional commit നടക്കുന്നു. ഈ cycle exact 12 times ആവർത്തിക്കുന്നു.

`Antony` memory-യിലെ dedicated actual-drop46 six-ID latch executable post-stir path touch ചെയ്യുന്നില്ല; അതിനാൽ പിന്നീട് `askBowl` successor lookup-നായി intact ആണ്. structural suffix `12,13,1,1,1,1,1,1`: 12 committed stirs, next-stir sentinel 13, final six bowl SAVE-domain flags.

Stage 1 ഇപ്പോഴും incomplete ആണ്. അടുത്ത clean integration target final bowl state + dedicated drop46 latch എന്നിവ `SauceResult` ownership ആയി ബന്ധിപ്പിച്ച് `nextBowlInDrop46Order`/`askBowl` exact stream നിർമ്മിക്കുന്നതാണ്; തുടർന്ന് short/wide selection, signed lazy gates, Year 5000 + adjacent-year walk, general cutlet/month/weaving DP, distinct-name unrank, മലയാള presentation resolve, exact five-field result, compliant SPL runtime GREEN എന്നിവ ബാക്കി.

## ഏറ്റവും പുതിയ Stage 1 പുരോഗതി — progress 45 SauceResult, askBowl, short/wide selection

progress 44-ന്റെ 46-drop + 12-post-stir final bowls ഇപ്പോൾ dedicated actual-drop46 `Antony` order latch-ുമായി same integrated test-only oracle path-ൽ ബന്ധിപ്പിച്ചിട്ടുണ്ട്. latch six position scalars-ലേക്ക് materialize ചെയ്യുമ്പോൾ destructive pop ഉപയോഗിച്ചാലും temporary reverse archive വഴി original forward order-ൽ ഉടൻ restore ചെയ്യുന്നു; final bowls read-only ആണ്.

അതേ path Appendix A `nextBowlInDrop46Order`, `askBowl` first/directionNumber/fixed directionStep, `N=922` exact short rejection ring, `N=M+1` exact wide `smallestPowerCount` + wide-number rejection ring എന്നിവ നിർവഹിക്കുന്നു. wide rejection പുതിയ answer digits എടുക്കുന്നില്ല.

Stage 1 ഇനിയും incomplete ആണ്. അടുത്ത blocker arbitrary target-day sauce orchestration ഉപയോഗിച്ച് signed lazy gate gaps നിർമ്മിക്കുകയാണ്; തുടർന്ന് Year 5000/adjacent walk, general DP/weaving/name unrank, മലയാള presentation resolve, exact five-field result, native SPL GREEN വേണം.
