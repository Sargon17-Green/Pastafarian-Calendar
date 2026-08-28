# ഘട്ടം 1 പ്രാഥമിക പരീക്ഷണ പ്രതീക്ഷകൾ

ഈ ഫയൽ test runner-നെ മാറ്റിസ്ഥാപിക്കുന്നില്ല; SPL runtime ലഭിക്കുമ്പോൾ പരിശോധിക്കേണ്ട കൃത്യ output-ുകളാണ് രേഖപ്പെടുത്തുന്നത്.

## `bootstrap_smoke.spl`

പ്രതീക്ഷിക്കുന്ന output:

`1`

## `exact_integer_probe.spl`

stdin-ൽ `127` നൽകിയാൽ പ്രതീക്ഷിക്കുന്ന output:

`170141183460469231731687303715884105727`

ഇത് `2^127 - 1` ആണ്. wrap, saturation, scientific notation, floating-point approximation എന്നിവ ഒന്നും അംഗീകരിക്കാനാവില്ല.

## `day_count_foundation_probe.spl`

stdin-ൽ ആദ്യം പരിശോധിക്കേണ്ട ദിവസം, തുടർന്ന് `FOUNDATION_DAY=-15055671` നൽകണം. നിർബന്ധിത ഉദാഹരണങ്ങൾ:

- `-15055671`, `-15055671` -> `1`
- `-15055670`, `-15055671` -> `3`
- `-15055672`, `-15055671` -> `2`
- `-15055669`, `-15055671` -> `5`
- `-15055673`, `-15055671` -> `4`

ഈ probe പൂർണ്ണ oracle അല്ല. Stage 1 GREEN ആകാൻ Appendix A മുഴുവൻ നടപ്പാക്കുന്ന test-only oracleയും end-to-end fixtures-ഉം ഇനിയും ആവശ്യമാണ്.

## `save_probe.spl`

stdin-ൽ ഒരു integer നൽകിയാൽ `SAVE(x)=1+regularMod(x-1,M)` അച്ചടിക്കണം; ഇവിടെ `M=170141183460469231731687303715884105727`.

നിർബന്ധിത ഉദാഹരണങ്ങൾ:

- `1` -> `1`
- `170141183460469231731687303715884105726` -> `170141183460469231731687303715884105726`
- `170141183460469231731687303715884105727` -> `170141183460469231731687303715884105727`
- `170141183460469231731687303715884105728` -> `1`
- `340282366920938463463374607431768211454` -> `170141183460469231731687303715884105727`
- `0` -> `170141183460469231731687303715884105727`
- `-1` -> `170141183460469231731687303715884105726`

## `oracle_primitives.spl`

ഈ test-only അരങ്ങ് മൂന്ന് integer-ുകൾ വായിക്കുന്നു: ആദ്യം operation code, തുടർന്ന് `x`, തുടർന്ന് `y`. `M`യും `FOUNDATION_DAY`യും source-ലുതന്നെ നിർമ്മിക്കുന്നു; മറ്റൊരു implementation-ന്റെ output ഉപയോഗിക്കുന്നില്ല.

operation code-ുകൾ:

- `1`: `regularMod(x,y)`; ഇവിടെ `y >= 1` ആയിരിക്കണം.
- `2`: `SAVE(x)`; `y` വായിക്കപ്പെടുന്നു, പക്ഷേ ഫലത്തിൽ ഉപയോഗിക്കില്ല.
- `3`: `dayCount(x)`; `y` വായിക്കപ്പെടുന്നു, പക്ഷേ ഫലത്തിൽ ഉപയോഗിക്കില്ല.
- `4`: `workCounts(x,y)`; അഞ്ച് വരികളിൽ `action`, `target`, `distance`, `connection`, `direction` അച്ചടിക്കും.

നിർബന്ധിത ഉദാഹരണങ്ങൾ:

- `1, -1, 10` -> `9`
- `1, 20, 7` -> `6`
- `2, 170141183460469231731687303715884105727, 0` -> `170141183460469231731687303715884105727`
- `2, 170141183460469231731687303715884105728, 0` -> `1`
- `3, -15055671, 0` -> `1`
- `3, -15055670, 0` -> `3`
- `3, -15055672, 0` -> `2`
- `4, -15055671, -15055671` -> `1`, `1`, `1`, `2`, `2`
- `4, -15055671, -15055670` -> `1`, `3`, `2`, `4`, `3`
- `4, -15055670, -15055672` -> `3`, `2`, `3`, `5`, `1`

ഈ അരങ്ങ് Appendix A-യുടെ ആദ്യ exact primitives-നെ ഒറ്റ SPL source-ൽ കൂട്ടിയതാണ്. ഇത് ഇനിയും പൂർണ്ണ calendar oracle അല്ല.

## `choose_rank_short_probe.spl`

stdin ക്രമം: `first`, `directionStep`, `N`. `1 <= first <= M`, `directionStep` `1` അല്ലെങ്കിൽ `-1`, `1 <= N <= M` ആയിരിക്കണം. probe `acceptanceLimit=floor(M/N)*N` കണക്കാക്കി, rejection വന്നാൽ പുതിയ random value ഉണ്ടാക്കാതെ അതേ answer ring-ൽ ഒരു ചുവട് മാത്രം നീങ്ങുന്നു.

നിർബന്ധിത ഉദാഹരണങ്ങൾ:

- `1, 1, 1` -> `1`
- `170141183460469231731687303715884105727, 1, 170141183460469231731687303715884105727` -> `170141183460469231731687303715884105727`
- `10, 1, 3` -> `1`
- `170141183460469231731687303715884105727, 1, 3` -> `1`
- `170141183460469231731687303715884105727, -1, 3` -> `3`

`N=3`-ൽ `M`-ന്റെ ശേഷിപ്പ് `1` ആകുന്നതിനാൽ `acceptanceLimit=M-1` ആണ്. അതുകൊണ്ട് `first=M` rejection നിർബന്ധിതമാക്കുന്നു: `+1` ദിശയിൽ ring `1`-ലേക്ക് ചുറ്റുന്നു; `-1` ദിശയിൽ `M-1`-ലേക്ക് നീങ്ങുന്നു. പുതിയ answer digits ഒന്നും ഉണ്ടാക്കുന്നില്ല.

## `choose_rank_wide_probe.spl`

stdin ക്രമം: `first`, `directionStep`, `N`. `N > M` ആയിരിക്കണം. probe `space=M^places >= N` എന്ന ഏറ്റവും ചെറിയ power space കണ്ടെത്തുന്നു; `answerAt(j)-1` digits little-endian weight-ുകളിൽ ചേർത്ത് `wide` നിർമ്മിക്കുന്നു; rejection വന്നാൽ digits വീണ്ടും ചോദിക്കാതെ wide സംഖ്യ തന്നെയാണ് `directionStep` അനുസരിച്ച് `1..space` ring-ൽ നീങ്ങുന്നത്.

ആദ്യ നിർബന്ധിത ഉദാഹരണങ്ങൾ:

- `first=1`, `directionStep=1`, `N=M+1` -> `M+1`, അതായത് `170141183460469231731687303715884105728`
- `first=1`, `directionStep=-1`, `N=M+1` -> `3`
- `first=1`, `directionStep=1`, `N=M^2` -> `M+1`

`N=M^2+1` ഉൾപ്പെടുന്ന മൂന്നാം-digit boundary fixture runtime execution ലഭിക്കുന്നതിന് മുമ്പ് source-ൽ കണക്കാക്കി കൂട്ടിച്ചേർക്കേണ്ടതാണ്. wide rejection-ന്റെ നിർണ്ണായക invariant: rejection കഴിഞ്ഞ് പുതിയ digits ഉണ്ടാക്കരുത്.

## `stack_memory_probe.spl`

ഈ probe stack LIFO semantics മാത്രം പരിശോധിക്കുന്നു. stdin ഒന്നുമില്ല. പ്രതീക്ഷിക്കുന്ന രണ്ട് output വരികൾ:

- `2`
- `1`

ഇത് വലിയ പൂർണ്ണസംഖ്യാ representation-ന്റെ അടുത്ത ഘട്ടത്തിൽ character stack-ുകൾ digit storage ആയി ഉപയോഗിക്കാമോ എന്ന അടിസ്ഥാന runtime gate ആണ്.

## `stone_step_probe.spl`

stdin ക്രമം: `i`, പഴയ `WHEAT`, `BARLEY`, `SALT`, `BITTER`, `RED`. അഞ്ചു പുതിയ കല്ലുകളും ഒരേ പഴയ snapshot-ൽ നിന്നാണ് കണക്കാക്കേണ്ടത്; ഓരോ candidate-നും `SAVE` പ്രയോഗിച്ചശേഷം അഞ്ചു വരികളായി output നൽകുന്നു.

ആദ്യ നിർബന്ധിത fixture:

- input: `2, 17, 29, 43, 71, 101`
- output: `378, 1073, 2375, 6195, 10493`

രണ്ടാം നിർബന്ധിത fixture:

- input: `3, 378, 1073, 2375, 6195, 10493`
- output: `146106, 1163582, 5685063, 38495823, 110114158`

ഈ രണ്ട് fixtures-ലും `SAVE` wrap ആവശ്യമില്ല; അതിനാൽ snapshot formula-കളുടെ നേരിട്ടുള്ള arithmetic regression ആയി ഉപയോഗിക്കാം. പിന്നീട് വലിയ row-കളിൽ `M` കടക്കുന്ന values-ക്ക് wrap fixture വേർതിരിച്ച് ചേർക്കണം.

## `hidden_drop_trace_probe.spl`

stdin ക്രമം: `k`, `action`, `target`, `distance`, `connection`, `direction`, തുടർന്ന് അതേ `k`-ലെ `WHEAT`, `BARLEY`, `SALT`, `BITTER`, `RED`. probe ആദ്യം `SAVE` ചെയ്ത seed അച്ചടിക്കും; തുടർന്ന് ഏഴ് grind-ുകളുടെ ഓരോ `SAVE` ഫലവും അച്ചടിക്കും. ആകെ എട്ട് വരികൾ.

`k=1`, Foundation-ൽ `calculationDay=targetDay` എന്നതിന് അനുയോജ്യമായ counts, stone row 1 എന്നിവ ഉപയോഗിക്കുന്ന prefix fixture:

- input: `1, 1, 1, 1, 2, 2, 17, 29, 43, 71, 101`
- seed output: `297`
- grind 1 output: `89118`
- grind 2 output: `7942285309`

ശേഷിക്കുന്ന grind output-ുകൾ SPL runtime ലഭിക്കാതെ മറ്റൊരു ഭാഷയിലോ implementation-ലോ കണക്കാക്കി expected value ആക്കരുത്. ഈ prefix fixture formula, coefficient row, ആദ്യ grind-stone mapping എന്നിവ സ്വതന്ത്രമായി ഉറപ്പിക്കുന്നു; പൂർണ്ണ എട്ട്-line fixture Stage 1 പൂർത്തിയാകുന്നതിന് മുമ്പ് SPL-only verification വഴി സ്ഥിരപ്പെടുത്തണം.

## `visible_seed_probe.spl`

stdin ക്രമം: `i`, `action`, `target`, `distance`, `connection`, `direction`, `WHEAT`, `BARLEY`, `SALT`, `BITTER`, `RED`, `prev1`, `prev3`, `prev7`.

നിർബന്ധിത നേരിട്ടുള്ള formula fixture:

- input: `1, 1, 1, 1, 2, 2, 17, 29, 43, 71, 101, 0, 0, 0`
- output: `434`

ഈ fixture യഥാർത്ഥ hidden timeline അല്ല; predecessor mapping-നെ വേർതിരിച്ച് പരിശോധിക്കാൻ മൂന്നു predecessor-ുകളും ശൂന്യമാക്കി visible seed formula മാത്രം isolate ചെയ്യുന്നു.

## `visible_grind_step_probe.spl`

stdin ക്രമം: `oldX`, `prev1`, `prev3`, `prev7`, `stoneValue`, `a`, `b`, `c`, `d`. output:

`SAVE(oldX^2 + a*oldX + b*prev1 + c*prev3 + d*prev7 + stoneValue)`

ആദ്യ visible grind row isolate ചെയ്യുന്ന fixture:

- input: `434, 0, 0, 0, 17, 3, 5, 7, 11`
- output: `189675`

ഇതിലൂടെ grind-table row 1-ന്റെ coefficient semantics full 46-drop state-ിൽ നിന്ന് വേർതിരിച്ച് പരിശോധിക്കാം.

## `answer_at_probe.spl`

stdin ക്രമം: `first`, `directionStep`, `offset`. output `1 + regularMod(first - 1 + directionStep*offset, M)` ആണ്.

നിർബന്ധിത ചെറിയ fixtures:

- `1, 1, 0` -> `1`
- `170141183460469231731687303715884105727, 1, 1` -> `1`
- `1, -1, 1` -> `170141183460469231731687303715884105727`

ഇവയിൽ direction വീണ്ടും കണക്കാക്കുന്നില്ല; ഇതിനകം stream-ൽ ഉറപ്പിച്ച ഒറ്റചുവടാണ് ഉപയോഗിക്കുന്നത്.

## `factoradic_rank6_probe.spl`

stdin: `1..720` പരിധിയിലുള്ള one-based permutation rank. output ആറു zero-based factoradic തിരഞ്ഞെടുപ്പ് സൂചികകൾ, ഓരോന്നും വേറൊരു വരിയിൽ.

അതിര് fixtures:

- `1` -> `0, 0, 0, 0, 0, 0`
- `720` -> `5, 4, 3, 2, 1, 0`

ഇത് remaining-item removal ഇനിയും ചെയ്യുന്നില്ല; `oldPermutationUnrank0`-ന് മുമ്പുള്ള exact factoradic division layer മാത്രം isolate ചെയ്യുന്നു.

## `visible_eleven_grinds_probe.spl`

stdin ആദ്യം `seed`, `prev1`, `prev3`, `prev7`; തുടർന്ന് പതിനൊന്ന് row-ുകൾക്കായി ഓരോന്നിലും `a`, `b`, `c`, `d`, `stoneValue`. ഓരോ row-വും മുൻ row-ന്റെ `x`-നെ മാത്രം പുതുക്കുന്നു; predecessor മൂന്ന് values മുഴുവൻ പതിനൊന്ന് ചുവടുകളിലും മാറ്റമില്ലാതെ തുടരുന്നു.

loop-control fixture: `seed=1`, predecessor-ുകൾ `0,0,0`; പതിനൊന്ന് row-ുകളിലും `a=b=c=d=stoneValue=0` നൽകിയാൽ അന്തിമ output `1` ആയിരിക്കണം.

ഈ fixture Appendix A-യിലെ coefficient table-ന്റെ test അല്ല; പതിനൊന്ന് തുടർച്ചയായ exact SAVE recurrence-ന്റെ control-flow gate മാത്രമാണ്.

## `year_candidate_predicate_probe.spl`

stdin: `gateGapCount`, `yearLength`. output `1` iff `gateGapCount >= 6` കൂടാതെ `252 <= yearLength <= 5778`; അല്ലെങ്കിൽ `0`.

നിർബന്ധിത അതിരുകൾ:

- `6, 252` -> `1`
- `6, 5778` -> `1`
- `5, 252` -> `0`
- `6, 251` -> `0`
- `6, 5779` -> `0`

Stage 1 oracle-ൽ `5781` legacy constant ഒന്നും ഉണ്ടാകരുത്; അത് ഭാവിയിലെ നിർബന്ധിത ചരിത്രഘട്ടത്തിൽ മാത്രമേ പ്രത്യക്ഷപ്പെടാവൂ.

## `initial_bowl_formula_probe.spl`

stdin ക്രമം: `action`, `target`, `distance`, `connection`, `direction`, `bowlId`, `prime`. output:

`SAVE((action + target*bowlId + distance + connection + direction + prime^2)^2 + bowlId)`

Foundation counts isolate ചെയ്യുന്ന fixture:

- input: `1, 1, 1, 2, 2, 1, 17`
- output: `87617`

ഈ probe ഒരൊറ്റ സ്ഥിര bowl ID-യുടെ formula isolate ചെയ്യുന്നു; ആറു കിണ്ണങ്ങളും ഒരു shared structure ആയി materialize ചെയ്യുന്നത് full oracle integration-ൽ ഇനിയും വേണം.

## `pour_triplet_probe.spl`

stdin ക്രമം: `drop`, `i`, `stoneWheat`, `stoneBarley`, `stoneSalt`, `oldAtPosition1`, `oldAtPosition2`, `oldAtPosition3`. output മൂന്ന് വരികൾ:

- `SAVE(drop^2 + stoneWheat*oldAtPosition1 + 3*i)`
- `SAVE(drop^2 + stoneBarley*oldAtPosition2 + 5*i)`
- `SAVE(drop^2 + stoneSalt*oldAtPosition3 + 7*i)`

നിർബന്ധിത ചെറിയ fixture:

- input: `10, 1, 2, 3, 5, 7, 11, 13`
- output: `117, 138, 172`

ഇവ സ്ഥിര bowl ID 1..3 അല്ല; drop order-ിലെ position 1..3-ലെ പഴയ കിണ്ണമൂല്യങ്ങളാണ് input.

## `bowl_shadow_stir_probe.spl`

stdin ക്രമം: `oldCurrent`, `oldPrev`, `oldNext`, `pour`, `drop`, `stoneValue`, `i`, `position`. output:

`SAVE((oldCurrent + 2*oldPrev + 3*oldNext + pour + drop + stoneValue)^2 + 5*oldPrev*oldNext + i*position)`

snapshot formula fixture:

- input: `7, 11, 13, 17, 19, 23, 1, 2`
- output: `16846`

ഈ probe pending scalar മാത്രം കണക്കാക്കുന്നു. ആറു positions-നും ഒരേ `old` snapshot വായിച്ച് പിന്നെ മാത്രമുള്ള simultaneous commit full oracle-ൽ ഇനിയും ബന്ധിപ്പിക്കണം.

## `post_stir_saved_sum_probe.spl`

stdin ക്രമം: ആറു പഴയ bowl values, പിന്നെ `stirNumber`. output Appendix A-യിലെ നിർബന്ധിത 1A വായന:

`SAVE(sum(oldBowls) + 149*stirNumber)`

നിർബന്ധിത fixture:

- input: `1, 2, 3, 4, 5, 6, 1`
- output: `170`

raw bowl sum-നെ വേറെയൊരു saved semantic value ആയി ഉപയോഗിക്കുന്നില്ല.

## `post_stir_bowl_probe.spl`

stdin ക്രമം: `oldCurrent`, `oldPrev`, `oldNext`, `savedBowlSum`, `stirNumber`, `position`. output:

`SAVE((oldCurrent + 3*oldPrev + 5*oldNext + savedBowlSum + stirNumber + position^2)^2 + 7*oldPrev*oldNext)`

നിർബന്ധിത fixture:

- input: `7, 11, 13, 17, 1, 2`
- output: `17130`

## `latched_order_successor_probe.spl`

stdin ക്രമം: `queriedBowlId`, തുടർന്ന് തുള്ളി 46-ൽ പൂട്ടിയ `order[1]..order[6]`. output ആ order-ിലെ വൃത്തീയമായ successor ആണ്.

നിർബന്ധിത fixtures, order `3,1,6,2,5,4`:

- query `6` -> `2`
- query `4` -> `3`

രണ്ടാമത്തെ fixture അവസാന position-ൽ നിന്ന് ഒന്നാമത്തേക്ക് wrap ചെയ്യുന്നത് പരിശോധിക്കുന്നു. post-stir order ഈ probe-ലേക്ക് input ആയി വരരുത്.

## `ask_bowl_probe.spl`

stdin ക്രമം: `queriedFinalBowl`, `nextFinalBowlInLatchedOrder`, `fixedBowl6Final`, `seal`. output രണ്ട് വരികൾ: `first`, പിന്നെ `directionStep`.

നിർബന്ധിത ചെറിയ fixture:

- input: `1, 2, 3, 1`
- first: `33848`
- directionStep: `-1`

ഈ fixture-ൽ direction number `1165459104` ആണ്; അത് ഇരട്ടയായതിനാൽ direction ഒരിക്കൽ മാത്രം `-1` ആയി നിശ്ചയിക്കുന്നു. തുടർന്ന് `answerAt` അതേ step ഉപയോഗിക്കണം; direction വീണ്ടും കണക്കാക്കരുത്.

## `select_kth_remaining_probe.spl`

stdin ക്രമം: `digit0`, തുടർന്ന് bowl ID 1..6-നുള്ള ആറു active flags. active flag positive ആണെങ്കിൽ ആ ID remaining family-ൽ ഉണ്ട്. output `digit0`-ആമത്തെ zero-based remaining bowl ID.

നിർബന്ധിത fixtures:

- `0, 1,1,1,1,1,1` -> `1`
- `5, 1,1,1,1,1,1` -> `6`
- `1, 1,0,1,1,0,1` -> `3`
- `2, 0,1,1,0,1,1` -> `5`

ഇത് factoradic digit-നെ remaining ID-യാക്കി materialize ചെയ്യുന്ന local primitive ആണ്. full permutation-ൽ ഓരോ തിരഞ്ഞെടുപ്പിനും തിരഞ്ഞെടുത്ത ID-യുടെ active flag പിന്നീട് ശൂന്യമാക്കി അടുത്ത digit പ്രയോഗിക്കണം.

## `wrap1_probe.spl`

stdin: `position`, `size`, ഇവിടെ `size >= 1`. output `1 + regularMod(position-1,size)`.

നിർബന്ധിത fixtures:

- `1, 6` -> `1`
- `6, 6` -> `6`
- `7, 6` -> `1`
- `0, 6` -> `6`
- `-1, 6` -> `5`

negative remainder ലഭിച്ചാൽ size ഒരിക്കൽ ചേർത്ത് Euclidean പരിധിയിലേക്ക് കൊണ്ടുവരണം.

## `ceil_div_probe.spl`

stdin: `a >= 0`, `b >= 1`. output `floorDiv(a+b-1,b)`.

നിർബന്ധിത fixtures:

- `0, 123` -> `0`
- `1, 123` -> `1`
- `252, 123` -> `3`
- `5778, 123` -> `47`

## `six_bowl_round_control_probe.spl`

ഇത് generic bowl round അല്ല; simultaneous control fixture ആണ്. പഴയ ആറു order-position bowl values എല്ലാം `1`, pours എല്ലാം `0`, drop `1`, stone value `1`, drop index `1` എന്ന് source-ൽ ഉറപ്പിച്ചിരിക്കുന്നു. Appendix A-യിലെ scalar recurrence ഓരോ position-ലും `13 + position` ആകുന്നു.

output ആറു വരികൾ:

- `14`
- `15`
- `16`
- `17`
- `18`
- `19`

ഈ probe position loop-ന്റെ control gate ആണ്. arbitrary old snapshot/order mapping full oracle integration-ൽ ഇനിയും വേണം.

## `month_count_bounds_probe.spl`

stdin: year length `L`. output രണ്ട് വരികൾ: `ceilDiv(L,123)`, തുടർന്ന് `min(47,floorDiv(L,4))`.

നിർബന്ധിത fixtures:

- `252` -> `3, 47`
- `492` -> `4, 47`
- `5778` -> `47, 47`

## `falling_factorial_probe.spl`

stdin: `n`, `k`. output `n*(n-1)*...*(n-k+1)` exact integer ആയി.

നിർബന്ധിത fixtures:

- `17, 0` -> `1`
- `17, 1` -> `17`
- `17, 6` -> `8910720`
- `47, 3` -> `97290`

ഇത് distinct cutlet/month name family count-ന്റെ arithmetic primitive ആണ്; lexical unranking ഇനിയും വേണം.

## `timeline_source_mux_probe.spl`

ഈ probe `slot=i-back` മാത്രം ഉപയോഗിച്ച് predecessor എവിടെ നിന്നാണ് വായിക്കേണ്ടതെന്ന് രണ്ട് വരികളിൽ അച്ചടിക്കുന്നു: ആദ്യം source class (`0` hidden, `1` visible), പിന്നെ source index.

നിർബന്ധിത ഉദാഹരണങ്ങൾ:

- `i=1, back=1` -> `0`, `1`
- `i=1, back=3` -> `0`, `3`
- `i=1, back=7` -> `0`, `7`
- `i=8, back=7` -> `1`, `1`
- `i=10, back=3` -> `1`, `7`

ഇത് Appendix A-യിലെ timeline mapping-ന്റെ indexing gate മാത്രം ആണ്; drop value കണക്കാക്കുന്നില്ല.

## `post_stir_twelve_schedule_probe.spl`

ചെറിയ `rawSum` fixture-ൽ wrap ഉണ്ടാകാത്ത പരിധിയിൽ stir number 1..12 ഓരോന്നിനും `rawSum + 149*stir` അച്ചടിക്കുന്നു. ഇത് 1A schedule-ന്റെ control probe ആണ്; full bowl mutation chain അല്ല.

`rawSum=21` നൽകിയാൽ പ്രതീക്ഷിക്കുന്ന പന്ത്രണ്ട് വരികൾ:

`170, 319, 468, 617, 766, 915, 1064, 1213, 1362, 1511, 1660, 1809`

## `year_interval_membership_probe.spl`

Appendix A-യിലെ വർഷ interval കൃത്യമായി `open < target <= close` ആണെന്ന് പരിശോധിക്കുന്നു.

- `100,101,200` -> `1`
- `100,100,200` -> `0`
- `100,200,200` -> `1`
- `100,201,200` -> `0`

## `cutlet_required_boundary_probe.spl`

`calculationDay` കൃത്യ internal gate ആണെങ്കിൽ മാത്രം `required = calculationGateIndex-openGateIndex` തിരികെ നൽകുന്നു; boundary ആവശ്യമില്ലെങ്കിൽ `0` diagnostic sentinel ആണ്.

- `open=10, calculation=13, close=20, exact=1` -> `3`
- `10,10,20,1` -> `0`
- `10,20,20,1` -> `0`
- `10,13,20,0` -> `0`

## `target_year_walk_direction_probe.spl`

ഫലം `-1` മുൻവർഷം, `0` നിലവിലെ വർഷം, `+1` അടുത്ത വർഷം എന്ന control code ആണ്.

- `open=100,target=99,close=200` -> `-1`
- `100,100,200` -> `-1`
- `100,101,200` -> `0`
- `100,200,200` -> `0`
- `100,201,200` -> `1`

## `permutation_materialize6_probe.spl`

stdin: ആറു zero-based factoradic digits. ഓരോ digit-വും ഇപ്പോഴും active ആയ ID-കളിൽ നിന്ന് lexicographic തിരഞ്ഞെടുപ്പ് നടത്തുന്നു; തിരഞ്ഞെടുത്ത ID ഉടൻ active-set-ൽ നിന്ന് നീക്കുന്നു. output ആറു വരികളിലുള്ള permutation ആണ്.

നിർബന്ധിത fixtures:

- `0,0,0,0,0,0` -> `1,2,3,4,5,6`
- `5,4,3,2,1,0` -> `6,5,4,3,2,1`
- `2,0,2,1,0,0` -> `3,1,5,4,2,6`

ഇത് `factoradic_rank6_probe.spl`-ന്റെ output-നെ actual six-ID order ആക്കുന്ന clean Stage 1 materialization gate ആണ്. future zero/one-based scar ഒന്നും ഇവിടെ ഇല്ല.

## `bounded_composition_window_probe.spl`

stdin: `rem`, `slots`, `lo`, `hi`. output inclusive candidate window:

- `minX = max(lo, rem-(slots-1)*hi)`
- `maxX = min(hi, rem-(slots-1)*lo)`

നിർബന്ധിത fixtures:

- `10,3,1,8` -> `1,8`
- `10,3,3,5` -> `3,4`
- `20,4,4,6` -> `4,6`

ഇത് bounded-composition DP-യിലെ lexicographic candidate scan-ന്റെ exact feasibility window ആണ്; count memo/unrank recursion ഇനിയും full oracle-ൽ ബന്ധിപ്പിക്കണം.

## `weave_move_legality_probe.spl`

stdin: `remaining[j]`, `originalLengths[j]`, `j`, `openedUpTo`, `closedUpTo`. output `1` iff Appendix A-യിലെ legalWeaveMove നിയമങ്ങൾ എല്ലാം പാലിക്കുന്നു.

നിർബന്ധിത fixtures:

- `3,3,1,0,0` -> `1`
- `3,3,2,0,0` -> `0`
- `2,3,2,2,0` -> `1`
- `1,3,1,3,0` -> `1`
- `1,3,2,3,0` -> `0`

remaining ശൂന്യമെങ്കിൽ output നിർബന്ധമായി `0` ആണ്.

## `weave_state_transition_probe.spl`

നിയമപരമായ move-നുള്ള `applyWeaveMove` state transition isolate ചെയ്യുന്നു. stdin: `remaining[j]`, `originalLengths[j]`, `j`, `openedUpTo`, `closedUpTo`. output: പുതിയ `remaining[j]`, പുതിയ `openedUpTo`, പുതിയ `closedUpTo`.

നിർബന്ധിത fixtures:

- `3,3,1,0,0` -> `2,1,0`
- `2,3,2,2,0` -> `1,2,0`
- `1,3,1,3,0` -> `0,3,1`

ഈ probe legality വീണ്ടും പരിശോധിക്കുന്നില്ല; caller legal move മാത്രമേ നൽകാവൂ.

## `month_occurrence_prefix6_probe.spl`

ചെറിയ ആറു-position weaving prefix-ിൽ Appendix A-യിലെ inclusive `dayInMonth` count isolate ചെയ്യുന്നു. stdin: `monthId`, `uptoPosition`, തുടർന്ന് ആറു month IDs. output ആദ്യ `uptoPosition` സ്ഥാനങ്ങളിൽ `monthId` എത്ര തവണ വരുന്നു എന്നതാണ്.

നിർബന്ധിത fixtures:

- `2,6, 2,1,2,3,2,2` -> `4`
- `2,4, 2,1,2,3,2,2` -> `2`
- `3,3, 2,1,3,3,3,3` -> `1`

ഇത് contiguous-day subtraction അല്ല; weaving prefix-ിലെ occurrence count തന്നെയാണ്.

## `permutation_rank_first_block_probe.spl`

one-based rank-നെ 120 permutation-ുകളുള്ള ആദ്യ lexicographic block ആയി വേർതിരിക്കുന്നു. output രണ്ട് വരികൾ: ആദ്യ bowl-ID ordinal, തുടർന്ന് ശേഷിക്കുന്ന one-based rank.

നിർബന്ധിത fixtures:

- `1` -> `1,1`
- `120` -> `1,120`
- `121` -> `2,1`
- `255` -> `3,15`
- `720` -> `6,120`

ഇത് `factoradic_rank6_probe.spl`-നും `permutation_materialize6_probe.spl`-നും ഇടയിലെ ആദ്യ integrated rank block ആണ്; zero/one-based future scar ഒന്നും source-ൽ ചേർത്തിട്ടില്ല.

## `gate_question_day_probe.spl`

stdin: Foundation day, signed gate step. positive step-ൽ `Foundation+n`, negative step-ൽ `Foundation-|n|` പുറത്തിടുന്നു.

നിർബന്ധിത fixtures:

- `-15055671, 1` -> `-15055670`
- `-15055671, -1` -> `-15055672`
- `-15055671, 3` -> `-15055668`
- `-15055671, -3` -> `-15055674`

Foundation constant-ന്റെ സ്വതന്ത്ര നിർമ്മാണ probe ഇതിനകം `oracle_primitives.spl`-ൽ ഉണ്ട്; ഇവിടെ signed-side semantics മാത്രം isolate ചെയ്യുന്നു.

## `gate_accumulate_three_probe.spl`

stdin: direction, known gate day, gap1, gap2, gap3. positive direction മൂന്ന് gap-ുകളും കൂട്ടുന്നു; negative direction മൂന്ന് gap-ുകളും കുറയ്ക്കുന്നു.

നിർബന്ധിത fixtures:

- `1, -15055671, 42, 50, 60` -> `-15055519`
- `-1, -15055671, 42, 50, 60` -> `-15055823`
- `1, 100, 1, 2, 3` -> `106`
- `-1, 100, 1, 2, 3` -> `94`

ഇത് lazy gate chain-ന്റെ ചെറിയ exact arithmetic gate ആണ്; sauce/selection ഉപയോഗിച്ച് gap സൃഷ്ടിക്കൽ ഇനിയും full oracle-ൽ ബന്ധിപ്പിക്കണം.

## `year5000_candidate_filter_probe.spl`

stdin: open gate day, calculation day, close gate day, gate-gap count. output `1` iff:

- gap count കുറഞ്ഞത് 6;
- length `252..5778`;
- `open < calculationDay <= close`.

നിർബന്ധിത fixtures:

- `100,101,352,6` -> `1`
- `100,100,352,6` -> `0`
- `100,352,352,6` -> `1`
- `100,353,352,6` -> `0`
- `100,200,5878,6` -> `1`
- `100,200,5879,6` -> `0`
- `100,200,352,5` -> `0`

ഇവിടെ പരമാവധി year length source-ൽ clean Appendix A മൂല്യമായ `5778` തന്നെയാണ്; future legacy ceiling ഒന്നും Stage 1-ൽ ഇല്ല.

## `distinct_name_first_choice_probe.spl`

stdin: remaining master-name count `n`, suffix length, one-based rank. block `fallingFactorial(n-1,suffixLength)` കണക്കാക്കി output രണ്ട് വരികളിൽ ആദ്യ candidate ordinal, candidate block-ിനുള്ള residual one-based rank നൽകുന്നു.

നിർബന്ധിത fixtures:

- `5,2,1` -> `1,1`
- `5,2,12` -> `1,12`
- `5,2,13` -> `2,1`
- `5,2,25` -> `3,1`
- `5,2,60` -> `5,12`
- `17,5,524161` -> `2,1`

ഇത് `unrankDistinctNames`-ന്റെ ആദ്യ position block arithmetic ആണ്. remaining canonicalIndex list-ൽ candidate നീക്കി അടുത്ത position-ിലേക്ക് ആവർത്തിക്കുന്ന full name-unrank routine ഇനിയും വേണം.

## `gate_gap_choice_probe.spl`

`chooseRank(stream,922)`-ൽ നിന്നുള്ള one-based rank-നെ Appendix A gate gap ആക്കുന്ന അവസാന scalar conversion isolate ചെയ്യുന്നു: `41 + rank`.

നിർബന്ധിത fixtures:

- `1` -> `42`
- `460` -> `501`
- `922` -> `963`

## `year5000_pair_order_probe.spl`

രണ്ട് candidate pair-ുകൾക്ക് sort order മാത്രം പരിശോധിക്കുന്നു. output `1` എന്നാൽ ആദ്യ pair മുമ്പ്, `2` എന്നാൽ രണ്ടാം pair മുമ്പ്, `0` എന്നാൽ sort key ഒരുപോലെ. ആദ്യം year length ascending; tie ആണെങ്കിൽ opening gate day ascending.

നിർബന്ധിത fixtures:

- `100,352, 100,353` -> `1`
- `100,353, 100,352` -> `2`
- `100,352, 90,342` -> `2`
- `90,342, 100,352` -> `1`
- `100,352, 100,352` -> `0`

## `cutlet_count_candidate_count_probe.spl`

`6..17`-ൽ `k <= gateGaps` ആയ candidate-ുകളുടെ എണ്ണം പുറത്തിടുന്നു.

നിർബന്ധിത fixtures:

- `5` -> `0`
- `6` -> `1`
- `10` -> `5`
- `17` -> `12`
- `20` -> `12`

## `month_count_rank_resolve_probe.spl`

`minMonths=ceilDiv(L,123)`, `maxMonths=min(47,floorDiv(L,4))`, തുടർന്ന് candidate list-ിലെ one-based rank resolve ചെയ്യുന്നു.

നിർബന്ധിത fixtures:

- `252,1` -> `3`
- `252,45` -> `47`
- `492,3` -> `6`
- `5778,1` -> `47`

## `distinct_name_two_choice_probe.spl`

`n >= k >= 2` എന്ന domain-ിൽ distinct-name lexicographic unrank-ന്റെ ആദ്യ രണ്ടു original canonicalIndex ordinal-ുകളും രണ്ടാം residual one-based rank-ഉം പുറത്തിടുന്നു.

നിർബന്ധിത fixtures:

- `5,3,1` -> `1,2,1`
- `5,3,12` -> `1,5,3`
- `5,3,13` -> `2,1,1`
- `5,3,60` -> `5,4,3`

ഇവിടെ രണ്ടാം ordinal first-choice നീക്കിയ ശേഷമുള്ള remaining list-ിൽ നിന്ന് original master list-ിലേക്ക് തിരികെ map ചെയ്യുന്നു.

## `bounded_composition_two_slot_probe.spl`

രണ്ട് slot ഉള്ള bounded-composition family-യ്ക്ക് exact countയും one-based lexicographic unrank-ഉം ഒരുമിച്ച് പരിശോധിക്കുന്നു. output മൂന്ന് വരികൾ: count, first part, second part. family ശൂന്യമെങ്കിൽ `0,0,0`.

നിർബന്ധിത fixtures:

- `10,1,8,1` -> `7,2,8`
- `10,1,8,7` -> `7,8,2`
- `8,4,4,1` -> `1,4,4`
- `3,1,2,2` -> `2,2,1`
- `20,4,6,1` -> `0,0,0`

## `weave_two_month_count_probe.spl`

രണ്ട് മാസം മാത്രം ഉള്ളപ്പോൾ first-open/last-close ordering പാലിക്കുന്ന legal weaving count `C(a+b-2,a-1)` എന്ന exact ചെറിയ sanity slice ആയി കണക്കാക്കുന്നു.

നിർബന്ധിത fixtures:

- `1,1` -> `1`
- `2,2` -> `2`
- `3,2` -> `3`
- `4,3` -> `10`
- `5,1` -> `1`

ഇത് full `CountWeavings(state)` memo-യുടെ പകരം അല്ല; ചെറിയ രണ്ട്-thread കുടുംബത്തിൽ lexicographic-family cardinality exact ആണെന്ന് പരിശോധിക്കുന്ന Stage 1 gate മാത്രമാണ്.

## `cutlet_count_rank_resolve_probe.spl`

`gateGaps`-ൽ നിന്ന് `6..min(17,gateGaps)` candidate family-യുടെ cardinalityയും one-based rank-ന്റെ K-യും ഒരുമിച്ച് resolve ചെയ്യുന്നു. output: candidate count, chosen K. family ശൂന്യമെങ്കിൽ `0,0`.

നിർബന്ധിത fixtures:

- `5,1` -> `0,0`
- `6,1` -> `1,6`
- `10,1` -> `5,6`
- `10,5` -> `5,10`
- `17,12` -> `12,17`
- `20,12` -> `12,17`

## `bounded_composition_three_slot_count_probe.spl`

മൂന്ന് slot bounded composition family-യുടെ exact cardinality ആദ്യ part ഉയരുന്ന ക്രമത്തിൽ suffix-pair feasible window-ുകൾ കൂട്ടി കണക്കാക്കുന്നു.

നിർബന്ധിത fixtures:

- `10,1,8` -> `36`
- `9,2,5` -> `10`
- `8,4,4` -> `0`
- `12,4,4` -> `1`
- `15,4,6` -> `7`

## `bounded_composition_three_slot_unrank_probe.spl`

stdin: `total,lo,hi,rank`. output: lexicographic member-ന്റെ മൂന്ന് parts. rank family-യ്ക്ക് പുറത്താണെങ്കിൽ `0,0,0` diagnostic.

നിർബന്ധിത fixtures:

- `10,1,8,1` -> `1,1,8`
- `10,1,8,8` -> `1,8,1`
- `10,1,8,9` -> `2,1,7`
- `10,1,8,36` -> `8,1,1`
- `9,2,5,5` -> `3,2,4`
- `12,4,4,1` -> `4,4,4`
- `20,4,6,1` -> `0,0,0`

ഇവ slots=2 base slice-നെ slots=3-ലേക്ക് ഉയർത്തുന്ന exact Stage 1 reference gate ആണ്; arbitrary-slot memoized counter/unrank ഇനിയും വേണം.

## `cutlet_partition_three_slot_filter_probe.spl`

മൂന്ന് positive parts ഉള്ള `G` composition family lexicographic order-ൽ scan ചെയ്യുന്നു. `required=0` ചെറിയ test convention ആയി filter ഇല്ലെന്ന് സൂചിപ്പിക്കുന്നു; `required>0` ആയാൽ `x==required` അല്ലെങ്കിൽ `x+y==required` ആയ member മാത്രം സ്വീകരിക്കുന്നു. output: filtered count, selected x,y,z.

നിർബന്ധിത fixtures:

- `G=6, required=0, rank=5` -> `10, 2,1,3`
- `G=6, required=2, rank=1` -> `4, 1,1,4`
- `G=6, required=2, rank=3` -> `4, 2,2,2`
- `G=6, required=3, rank=4` -> `4, 3,2,1`
- `G=7, required=3, rank=5` -> `5, 3,3,1`

ഇത് internal calculation-day gate partition filter-ന്റെ ചെറിയ exact family ആണ്; arbitrary K DP state `(rem,slots,cumulative,hitBoundary)` ഇനിയും full oracle-ൽ വേണം.

## `cutlet_day_resolve_three_probe.spl`

മൂന്ന് materialized closed cutlet day intervals scan ചെയ്ത് canonicalIndexയും `dayInCutlet=target-firstDay+1`-ഉം നൽകുന്നു. interval match ഇല്ലെങ്കിൽ `0,0` diagnostic.

നിർബന്ധിത fixture tree:

- intervals: `[100,102] -> 4`, `[103,105] -> 7`, `[106,110] -> 2`
- target `100` -> `4,1`
- target `105` -> `7,3`
- target `108` -> `2,3`
- target `99` -> `0,0`

## `weave_offset_select6_probe.spl`

one-based year position-ൽ നിന്ന് ആറു-position weaving-ിലെ monthId തിരഞ്ഞെടുക്കുന്നു. range `1..6`-ന് പുറത്തുള്ള position diagnostic zero നൽകുന്നു.

weave `1,2,1,3,2,3` എന്ന fixture-ൽ:

- position `1` -> `1`
- position `2` -> `2`
- position `4` -> `3`
- position `6` -> `3`
- position `0` -> `0`

ഈ probe `month_occurrence_prefix6_probe.spl`-നൊപ്പം final month resolver-ന്റെ രണ്ട് നിർബന്ധിത ഘടകങ്ങൾ — offset selection, inclusive occurrence count — വേർതിരിച്ച് ഉറപ്പിക്കുന്നു.

## `distinct_name_third_mapping_probe.spl`

ആദ്യ രണ്ടു original canonicalIndex ordinal-ുകൾ നീക്കിയ ശേഷമുള്ള third remaining-list ordinal-നെ original master-list ordinal-ിലേക്ക് map ചെയ്യുന്നു.

നിർബന്ധിത fixtures:

- `removed=2,5; remainingOrdinal=1` -> `1`
- `removed=2,5; remainingOrdinal=2` -> `3`
- `removed=2,5; remainingOrdinal=4` -> `6`
- `removed=5,2; remainingOrdinal=4` -> `6`
- `removed=1,2; remainingOrdinal=1` -> `3`
- `removed=3,4; remainingOrdinal=3` -> `5`

ഇത് `distinct_name_two_choice_probe.spl`-ന്റെ ശേഷം മൂന്നാം removal-aware mapping primitive ആണ്; arbitrary-k loop ഇനിയും blocker ആണ്.

## `bowl_order_rank6_integrated_probe.spl`

one-based rank `1..720`-നെ ആദ്യം exact factoradic digits-ആക്കി, തുടർന്ന് six-ID active set-ിൽ ഓരോ digit-നും തിരഞ്ഞെടുക്കപ്പെട്ട ID നീക്കം ചെയ്ത് പൂർണ്ണ lexicographic bowl order ഒരൊറ്റ SPL source path-ൽ നിർമ്മിക്കുന്നു.

നിർബന്ധിത fixtures:

- rank `1` -> `1,2,3,4,5,6`
- rank `120` -> `1,6,5,4,3,2`
- rank `121` -> `2,1,3,4,5,6`
- rank `255` -> `3,1,5,4,2,6`
- rank `481` -> `5,1,2,3,4,6`
- rank `720` -> `6,5,4,3,2,1`

ഇത് മുമ്പുണ്ടായിരുന്ന `factoradic_rank6_probe.spl` + `permutation_materialize6_probe.spl` വിഭജിത തെളിവുകളുടെ ഇടയിലെ integration gap അടയ്ക്കുന്നു. future zero-based legacy scar ഇതിൽ ഇല്ല; source clean one-based Appendix A path മാത്രം ആണ്.

## `gate_lookup_four_probe.spl`

നാല് കർശനമായി ഉയരുന്ന gate day-കളുള്ള ചെറിയ exact family-ൽ `at-or-before`, `at-or-after`, `exact` ordinal-ുകൾ കണ്ടെത്തുന്നു. gate ordinal ഇവിടെ 1..4; കണ്ടെത്താനില്ലെങ്കിൽ 0 diagnostic value ആണ്.

നിർബന്ധിത fixtures:

- gates `10,20,30,40`, target `5` -> `0,1,0`
- gates `10,20,30,40`, target `20` -> `2,2,2`
- gates `10,20,30,40`, target `25` -> `2,3,0`
- gates `10,20,30,40`, target `40` -> `4,4,4`
- gates `10,20,30,40`, target `50` -> `4,0,0`

ഇത് lazy gate store-ന്റെ full implementation അല്ല; exact lookup semantics-ന്റെ ചെറിയ ordered fixture ആണ്.

## `cutlet_materialize_three_probe.spl`

നാല് അനുക്രമ gate day-കളിൽ നിന്ന് മൂന്ന് cutlet day intervals materialize ചെയ്യുന്നു. ഓരോ cutlet-നും `firstDay=openGateDay+1`, `lastDay=closeGateDay` എന്ന Appendix A നിയമം നേരിട്ട് ഉപയോഗിക്കുന്നു.

നിർബന്ധിത fixture:

- gate days `100,110,125,140` -> `101,110,111,125,126,140`

## `weave_three_two_unrank_probe.spl`

month lengths `3,2` എന്ന ചെറിയ family-യുടെ മുഴുവൻ legal weaving-ുകൾ lexicographic order-ൽ rank ചെയ്യുന്നു. family കൃത്യമായി:

1. `1,1,1,2,2`
2. `1,1,2,1,2`
3. `1,2,1,1,2`

അതുകൊണ്ട് input rank `1`, `2`, `3` യഥാക്രമം മുകളിൽ പറഞ്ഞ അഞ്ചു monthId-ുകൾ നൽകണം. ഇത് arbitrary-m memoized unrank-ന്റെ പകരം അല്ല; ordering sanity gate ആണ്.

## `structure_first_day_probe.spl`

structure sauce-ന്റെ target day `year.openGateDay+1` മാത്രമാണെന്ന് source-level gate. നിർബന്ധിത fixtures:

- `100` -> `101`
- `-100` -> `-99`
- `-1` -> `0`

## `year_number_step_probe.spl`

ചെറിയ control convention: direction `1` previous, `2` unchanged, `3` next. നിർബന്ധിത fixtures:

- `5000,1` -> `4999`
- `5000,2` -> `5000`
- `5000,3` -> `5001`
- `0,1` -> `-1`
- `-1,3` -> `0`

ഇത് target-year walk-ന്റെ day-boundary തീരുമാനത്തെ മാറ്റിസ്ഥാപിക്കുന്നില്ല; വർഷ നമ്പറിന്റെ unit-step continuity മാത്രം ഉറപ്പിക്കുന്നു.

## `final_resolver_six_day_probe.spl`

ആറ് ദിവസമുള്ള ചെറിയ materialized structure-ൽ നിന്ന് **canonicalIndex-ുകൾ മാത്രം** ഉപയോഗിച്ച് exactly five fields resolve ചെയ്യുന്നു: `yearNumber`, `cutletCanonicalIndex`, `dayInCutlet`, `monthCanonicalIndex`, `dayInMonth`. localized strings ഈ probe-ന്റെ semantics-ൽ പങ്കെടുക്കുന്നില്ല.

fixture structure:

- year number `5000`
- year first day `101`
- cutlet 1 last day `103`, canonicalIndex `7`
- cutlet 2 canonicalIndex `9`
- weaving `1,2,1,2,1,2`
- month 1 canonicalIndex `11`
- month 2 canonicalIndex `22`

നിർബന്ധിത outputs:

- target `103` -> `5000,7,3,11,2`
- target `105` -> `5000,9,2,11,3`
- target `106` -> `5000,9,3,22,3`

ഇത് final resolver semantics-ന്റെ ചെറിയ integrated slice ആണ്. full calendar oracle-ിലെ year/cutlet/month structure generation ഇതിൽ ഇല്ല.

## `post_stir_order_rank_probe.spl`

stdin ക്രമം: ആറു പഴയ bowl values, പിന്നെ `stirNumber`. output രണ്ട് വരികൾ: ആദ്യം നിർബന്ധിത 1A `SAVE(sum(oldBowls)+149*stirNumber)`, തുടർന്ന് `regularMod(saved-1,720)+1` എന്ന one-based bowl-order rank.

നിർബന്ധിത fixture:

- input: `1,2,3,4,5,6,1`
- saved value: `170`
- order rank: `170`

ഈ probe post-stir order-നെ drop-46 latch ആയി തെറ്റിദ്ധരിക്കരുത്; ഇത് post-stir-ന്റെ സ്വന്തം diagnostic/authoritative internal order rank മാത്രമാണ്.

## `bounded_composition_four_slot_count_probe.spl`

stdin: `total`, `lo`, `hi`. നാല് slots-ലുള്ള എല്ലാ tuples-ഉം lexicographic outer-loop ക്രമത്തിൽ scan ചെയ്ത് exact family count മാത്രം output ചെയ്യുന്നു.

നിർബന്ധിത fixtures:

- `10,1,8` -> `84`
- `8,1,3` -> `19`

ആദ്യ fixture-ൽ upper bound binding അല്ല; positive നാല്-part compositions-ന്റെ cardinality `C(9,3)=84`. രണ്ടാം fixture bounded exclusion യഥാർത്ഥമായി പ്രവർത്തിപ്പിക്കുന്നു.

## `bounded_composition_four_slot_unrank_probe.spl`

stdin: `total`, `lo`, `hi`, `rank1`. output ആദ്യം exact count, തുടർന്ന് തിരഞ്ഞെടുത്ത നാല് parts.

നിർബന്ധിത fixtures:

- `10,1,8,1` -> `84, 1,1,1,7`
- `10,1,8,2` -> `84, 1,1,2,6`
- `10,1,8,84` -> `84, 7,1,1,1`

ഇത് materialization ചെയ്യാതെ memoized general DP ഇനിയും അല്ല; എന്നാൽ slots=4 family-യുടെ exact lexicographic semantics നേരിട്ട് ഉറപ്പിക്കുന്നു.

## `weave_two_two_one_unrank_probe.spl`

lengths `2,2,1` എന്ന ചെറിയ family-ൽ first-occurrence order-ും last-occurrence order-ും ഒരുമിച്ച് പാലിക്കുന്ന legal weavings കൃത്യമായി രണ്ട് മാത്രമാണ്.

- rank `1` -> `1,1,2,2,3`
- rank `2` -> `1,2,1,2,3`

month 3 ഒറ്റത്തവണ മാത്രമായതിനാൽ അതിന്റെ first/last occurrence അവസാനത്തായിരിക്കണം; month 1-ന്റെ അവസാന occurrence month 2-ന്റെ അവസാന occurrence-നു മുമ്പായിരിക്കണം.

## `year_transition_record_probe.spl`

stdin: `knownYearNumber`, `knownOpenIndex`, `knownCloseIndex`, `selectedOuterIndex`, `direction`, ഇവിടെ `direction=1` next year, `direction=-1` previous year.

നിർബന്ധിത fixtures:

- `5000,10,20,30,1` -> `5001,20,30`
- `5000,10,20,0,-1` -> `4999,0,10`
- `0,-5,3,9,1` -> `1,3,9`
- `0,-5,3,-12,-1` -> `-1,-12,-5`

ഇത് candidate selection ചെയ്യുന്നില്ല; തിരഞ്ഞെടുത്ത outer gate ലഭിച്ചതിന് ശേഷം shared year boundary-യും unit year-number step-ും കൃത്യമാണെന്ന് isolate ചെയ്യുന്നു.

## `gate_cover_need_probe.spl`

stdin: `knownMinGateDay`, `knownMaxGateDay`, `day`. output രണ്ട് flags: backward expansion വേണമോ, forward expansion വേണമോ.

നിർബന്ധിത fixtures:

- `100,300,50` -> `1,0`
- `100,300,100` -> `0,0`
- `100,300,200` -> `0,0`
- `100,300,300` -> `0,0`
- `100,300,350` -> `0,1`

exact endpoints ഇതിനകം covered ആണ്; അവ expansion ആവശ്യപ്പെടരുത്.

## `bowl_round_uniform_snapshot_probe.spl`

ഒരു visible-drop bowl round-ന്റെ ആറു order positions ഒരേ old snapshot മൂല്യം വായിക്കുന്ന small integration fixture. input ക്രമം: uniform old bowl value, drop, uniform stone value, drop index. pour ഈ control fixture-ൽ ശൂന്യമാണ്.

നിർബന്ധിത fixtures:

- input `1,0,0,1` -> outputs `42,43,44,45,46,47`
- input `0,1,0,2` -> outputs `3,5,7,9,11,13`

ആദ്യ fixture-ൽ ഓരോ position-നും pre-square `s=1+2+3=6`; പിന്നെ `s^2 + 5 + position = 42..47`. രണ്ടാം fixture-ൽ `s=1`, neighbor-product term ശൂന്യം, `i=2`; അതിനാൽ `1+2*position`.

## `post_stir_uniform_round_probe.spl`

ഒരു post-stir-ൽ ആറു old bowls ഒരേ test value ആണെങ്കിൽ actual permutation ID-കൾ scalar values മാറ്റുന്നില്ല; order position മാത്രം `position^2` term-ൽ പങ്കെടുക്കുന്നു. source ആദ്യം `SAVE(6*old + 149*stir)` കണക്കാക്കി, തുടർന്ന് ആറു positions-നും corrected pre-square recurrence പ്രയോഗിക്കുന്നു.

നിർബന്ധിത fixture:

- input `old=0, stir=1` -> saved value `149` internal; outputs by order position: `22801,23716,25281,27556,30625,34596`

ഈ fixture actual six-bowl ID remapping-ന്റെ പകരം അല്ല; ഒരു മുഴുവൻ post-stir scalar round-ന്റെ 1A-to-six-positions integration sanity gate ആണ്.

## `drop46_latch_twelve_post_probe.spl`

ആദ്യ input drop-46 one-based bowl-order rank ആണ്. അതിനു ശേഷം കൃത്യമായി പന്ത്രണ്ട് post-stir diagnostic ranks വായിക്കുന്നു. output ആദ്യ input തന്നെയായിരിക്കണം; post-stir reads latch overwrite ചെയ്യരുത്.

നിർബന്ധിത fixture:

- inputs `255,1,2,3,4,5,6,7,8,9,10,11,12` -> output `255`

## `cutlet_partition_four_slot_filter_probe.spl`

നാല് positive parts ഉള്ള lexicographic family-ൽ required internal gate prefix filter exact count/unrank സഹിതം scan ചെയ്യുന്നു. `required=0` test convention filter ഇല്ല എന്നതാണ്; production semantics-ൽ `NONE`-ന് തുല്യമായ fixture-only encoding.

നിർബന്ധിത fixtures:

- `G=6, required=3, rank=1` -> count `6`, member `1,1,1,3`
- `G=6, required=3, rank=2` -> count `6`, member `1,2,1,2`
- `G=6, required=3, rank=6` -> count `6`, member `3,1,1,1`

ഇത് slots=3 filtered family-യിൽ നിന്ന് slots=4-ലേക്കുള്ള clean-reference extension ആണ്; arbitrary-K memoized counter/unrank ഇനിയും blocker ആണ്.

## `distinct_name_fourth_mapping_probe.spl`

മൂന്ന് removed original canonicalIndex ordinal-ുകൾ ഒഴിവാക്കി remaining-list ordinal original master-list ordinal-ിലേക്ക് map ചെയ്യുന്നു.

നിർബന്ധിത fixtures:

- removed `2,5,7`, remaining ordinal `1` -> `1`
- removed `2,5,7`, remaining ordinal `2` -> `3`
- removed `2,5,7`, remaining ordinal `4` -> `6`
- removed `1,2,3`, remaining ordinal `1` -> `4`

ഇത് fourth-position removal-aware mapping primitive ആണ്; arbitrary-k general loop ഇനിയും വേണം.

## `gate_gap_stream_short_probe.spl`

synthetic `AnswerStream(first,step)`-നും `N`-നും മേൽ short rejection selector പ്രവർത്തിപ്പിച്ച് selected rank-ലേക്ക് `41` ചേർത്ത് gate gap output ചെയ്യുന്നു. gate fixture-ൽ `N=922` ആയിരിക്കണം.

നിർബന്ധിത fixtures:

- `first=1, step=1, N=922` -> gap `42`
- `first=922, step=1, N=922` -> gap `963`
- `first=923, step=1, N=922` -> gap `42`

ഇത് sauce/askBowl-ിൽ നിന്ന് stream സൃഷ്ടിക്കുന്ന ഭാഗം ഉൾക്കൊള്ളുന്നില്ല; എന്നാൽ short selection-ൽ നിന്ന് exact `42..963` gate-gap conversion വരെ ഒരൊറ്റ source path-ൽ ബന്ധിപ്പിക്കുന്നു.

## `rolling_predecessor_four_drop_probe.spl`

stdin ക്രമം: `hidden1..hidden7`, തുടർന്ന് ഇതിനകം commit ചെയ്ത `visible1`, `visible2`, `visible3`. output ആദ്യ നാല് visible drop-ുകൾക്കുള്ള `prev1`, `prev3`, `prev7` triples ആണ്.

ചെറിയ fixture:

- input hidden: `101,102,103,104,105,106,107`
- committed visible: `201,202,203`
- output ക്രമം: `101,103,107, 201,102,106, 202,101,105, 203,201,104`

ഇത് `timeline[1-k]=hidden[k]` എന്ന Appendix A mapping-ിൽ നിന്ന് positive visible slots-ലേക്ക് rolling transition മാത്രം isolate ചെയ്യുന്നു. visible recurrence value ഇവിടെ വീണ്ടും കണക്കാക്കുന്നില്ല.

## `bowl_identity_round_arbitrary_snapshot_probe.spl`

stdin ക്രമം: identity order-ിലുള്ള ആറു പഴയ bowl values, തുടർന്ന് visible drop index `i`. ഈ ചെറിയ no-wrap probe-ൽ pour, drop, stone contribution ശൂന്യമാണ്. ഓരോ position-നും അതേ ആറു-value old snapshot വായിച്ച്:

`pending = (current + 2*prev + 3*next)^2 + 5*prev*next + i*position`

കണക്കാക്കുന്നു.

നിർബന്ധിത fixture:

- input: `1,2,3,4,5,6,2`
- output: `423,188,407,708,1091,398`

ഇവ അടുത്ത round-ന്റെ committed state ആയി ഉപയോഗിക്കാവുന്ന ആറു വ്യത്യസ്ത values ആണ്; in-place contamination അനുവദിക്കുന്നില്ല.

## `post_stir_identity_order_no_wrap_probe.spl`

stdin ക്രമം: ആറു പഴയ bowl values, തുടർന്ന് `stirNumber`. fixture-ന്റെ `SAVE(sum(old)+149*stir)` value `720`-ൽ rank `1` ആകുന്ന സാഹചര്യത്തിനായി identity order `1,2,3,4,5,6` ഉപയോഗിച്ച് ഒരു മുഴുവൻ six-position post-stir round കണക്കാക്കുന്നു. source-ൽ ആദ്യം ഒരൊറ്റ 1A saved value നിർമ്മിച്ചശേഷം ആ value തന്നെയാണ് ആറു pre-square sums-ലും ഉപയോഗിക്കുന്നത്.

നിർബന്ധിത fixture:

- input: `95,95,95,95,96,96,1`
- raw sum: `572`
- saved value: `721`
- `regularMod(721-1,720)+1 = 1`, അതിനാൽ identity order fixture ശരിയാണ്.
- six pending outputs: `2563401,2562736,2578571,2617444,2649504,2678529`

ഈ values `M`-നെക്കാൾ വളരെ ചെറുതാണ്; അതിനാൽ ഈ fixture-ൽ `SAVE` numerically identity ആണ്. general wrap behavior വേറെയുള്ള exact probes-ൽ പരിശോധിക്കുന്നു.

## `distinct_name_fifth_mapping_probe.spl`

stdin: നാല് ഇതിനകം removed original ordinals, തുടർന്ന് remaining-list one-based ordinal. output: അടുത്ത തിരഞ്ഞെടുപ്പിന്റെ original master-list ordinal.

fixtures:

- `2,4,6,8,3` -> `5`
- `2,4,6,8,5` -> `9`

localized മലയാള strings scan/rank-ൽ പങ്കെടുക്കുന്നില്ല; ordinal/canonical identity മാത്രം ഉപയോഗിക്കുന്നു.

## `year_three_candidate_validity_probe.spl`

stdin: മൂന്ന് `(gateGapCount, yearLength)` pairs. output: candidate 1 validity, candidate 2 validity, candidate 3 validity, തുടർന്ന് valid count.

fixtures:

- `6,252, 5,252, 6,5779` -> `1,0,0,1`
- `6,5778, 7,300, 6,251` -> `1,1,0,2`

clean Stage 1 source-ൽ upper bound `5778` ആണ്; future historical `5781` value ഇവിടെ ഉണ്ടാകരുത്.

## progress 18 — rolling visible integration, non-identity bowl routing, query/selection chain

### `rolling_two_visible_full_grinds_probe.spl`

stdin ക്രമം:

1. `hidden1, hidden2, hidden3, hidden6, hidden7`;
2. `drop1Base, drop2Base` — counts/stone linear contribution predecessor terms-ും `i`-യും ചേർക്കുന്നതിന് മുമ്പുള്ള scalar ഭാഗം;
3. drop 1-നായി 11 grind rows, ഓരോ row-ക്കും `a,b,c,d,stoneValue`;
4. drop 2-നായി അതേ രീതിയിൽ 11 grind rows.

നിർബന്ധിത ലളിത fixture:

- hidden values എല്ലാം `0`;
- `drop1Base=0`;
- `drop2Base=-2`;
- ഇരുപത്തിരണ്ട് grind rows-ലും അഞ്ചു values എല്ലാം `0`.

അപ്പോൾ:

- drop 1 seed = `SAVE(0+0+3*0+5*0+1)=1`;
- പതിനൊന്ന് zero-row grinds കഴിഞ്ഞും visible 1 = `1`;
- drop 2 seed = `SAVE(-2+visible1+3*0+5*0+2)=1`;
- പതിനൊന്ന് zero-row grinds കഴിഞ്ഞും visible 2 = `1`.

expected output: `1,1`.

ഈ fixture-ന്റെ ഉദ്ദേശം വലിയ സംഖ്യ fixture ഉണ്ടാക്കൽ അല്ല; committed visible 1 രണ്ടാമത്തെ drop-ന്റെ `prev1` ആകുന്നു എന്ന rolling ownership-ും ഓരോ drop-ക്കും predecessor snapshot grind മുഴുവൻ സ്ഥിരമാണെന്നും source path-ൽ ബന്ധിപ്പിക്കുകയാണ്.

### `bowl_nonidentity_order_round_probe.spl`

stdin: `oldBowl1..oldBowl6, i`. fixed order fixture `3,1,6,2,5,4`; pour/drop/stone contribution ശൂന്യം. ഓരോ pending value-ും അതേ പഴയ six-bowl snapshot-ിൽ നിന്ന് മാത്രം വായിക്കുന്നു.

fixture:

- input: `1,2,3,4,5,6,1`
- position-order output: `217,717,209,995,486,610`

routing:

- p1: current 3, prev 4, next 1;
- p2: current 1, prev 3, next 6;
- p3: current 6, prev 1, next 2;
- p4: current 2, prev 6, next 5;
- p5: current 5, prev 2, next 4;
- p6: current 4, prev 5, next 3.

ഇത് identity-order snapshot probe-ിനെ arbitrary non-identity order routing-ിലേക്ക് വികസിപ്പിക്കുന്നു.

### `post_stir_nonidentity_order_probe.spl`

fixture:

- input old bowls: `1,2,3,4,5,91`;
- `stirNumber=1`;
- raw sum `106`;
- 1A saved value `255`;
- rank `255`-ന്റെ known lexicographic order: `3,1,5,4,2,6`;
- position-order pending outputs: `290081,87130,85877,90671,565048,163258`.

എല്ലാ ആറു pre-square sums-ലും ഒരേ saved value `255` ഉപയോഗിക്കണം. position 6-ൽ `position^2=36` നിർബന്ധമാണ്.

ഈ continuation-ൽ `post_stir_identity_order_no_wrap_probe.spl` source-ലുള്ള position-6 literal-ും audit ചെയ്തു: expected fixture നേരത്തേ തന്നെ ശരിയായ `36` അനുസരിച്ചായിരുന്നു, എന്നാൽ source expression `20` ആയി എഴുതപ്പെട്ടിരുന്നു. clean Stage 1 oracle source ഇപ്പോൾ `32+4=36` ആയി expectations-നോട് ഒത്തിരിക്കുന്നു; historical patch ഒന്നും ഇതിലൂടെ സൃഷ്ടിക്കുന്നില്ല.

### `sauce_query_short_selection_probe.spl`

stdin: `queriedBowlValue, successorBowlValue, bowl6Value, seal, N`.

fixture:

- input: `4,3,6,1,922`;
- first: `35134`;
- direction number: `1254920285`, അതിനാൽ step `+1`;
- first answer തന്നെ short acceptance region-ൽ;
- selected rank: `98`;
- gate gap: `139`.

expected output: `35134,1,98,139`.

latched-order successor lookup തന്നെയല്ല ഈ file വീണ്ടും പരീക്ഷിക്കുന്നത്; അതിന്റെ output scalar values ഇവിടെ askBowl -> short selector -> gate-gap conversion എന്ന integrated path-ലേക്ക് നൽകുന്നു.

### `distinct_name_sixth_mapping_probe.spl`

stdin: അഞ്ചു removed original canonical ordinals, തുടർന്ന് sixth-position remaining-list one-based ordinal. output original master-list ordinal.

fixtures:

- `2,4,6,8,10,6` -> `11`;
- `2,4,6,8,10,7` -> `12`.

localized string comparison ഒന്നും source-ൽ ഇല്ല.

### `weave_two_two_two_unrank_probe.spl`

lengths `2,2,2` family-യുടെ exact legal lexicographic order:

1. `112233`
2. `112323`
3. `121233`
4. `121323`
5. `123123`

rank `1..5` അതത് row പുറത്തിടണം. first-open order-ും last-close order-ും ഒരേസമയം പാലിക്കുന്ന family count `5` ആണെന്ന small-force regression ഇതോടെ source-ൽ materialize ചെയ്യുന്നു.

## progress 19 — മൂന്ന്-drop rolling ownership, two-commit post-stir chain, signed gate store, next-year ranked scan

### `rolling_three_visible_full_grinds_probe.spl`

ഈ probe ആദ്യ രണ്ടു drop integration-നെ മൂന്നാം committed visible value വരെ നീട്ടുന്നു. zero-coefficient grind fixture-ൽ hidden values എല്ലാം `0`, base contributions `0,-2,-3` ആണ്. ഓരോ drop-ക്കും പതിനൊന്ന് grind ഘട്ടങ്ങൾ നടക്കുന്നു; ഓരോ ഘട്ടവും `SAVE(x*x)` മാത്രമാണ്.

- drop 1 seed/output: `1`;
- drop 2 seed/output: `1`, അതിന്റെ `prev1` committed visible 1 ആണ്;
- drop 3 seed/output: `1`, അതിന്റെ `prev1` committed visible 2, `prev3=hidden1`, `prev7=hidden5` ആണ്.

expected output: `1,1,1`.

### `post_stir_two_committed_rounds_probe.spl`

ഇത് 1A/order തിരഞ്ഞെടുപ്പ് isolate ചെയ്യുന്നു: രണ്ടു round-ലും `savedBowlSum=1`, identity order. ആരംഭ old bowls എല്ലാം `0`; round 1 six pending values logical commit ചെയ്ത ശേഷമേ round 2 അവ വായിക്കൂ.

round 1 committed state:

`9,36,121,324,729,1444`

round 2 expected output:

`20839513,463248,3544969,19548664,83359593,13847152`

ഈ values എല്ലാം `M`-നേക്കാൾ വളരെ താഴെ ആയതിനാൽ SAVE wrap ഇല്ല; probe-ന്റെ ഉദ്ദേശം transactional ownership ആണ്.

### `gate_signed_store_five_probe.spl`

fixture:

- foundation `1000`;
- positive gaps `42,50`;
- negative gaps `60,70`.

expected signed store output `gate[-2],gate[-1],gate[0],gate[1],gate[2]`:

`870,940,1000,1042,1092`.

### `next_year_three_candidate_rank_probe.spl`

fixture:

- open day `100`;
- close days `352,600,6000`;
- gap counts `6,7,8`;
- requested rank `2`.

lengths `252,500,5900`; ആദ്യ രണ്ടു candidates മാത്രം clean bound `252..5778` പാലിക്കുന്നു. same open gate ഉള്ളതിനാൽ ascending close days length order തന്നെയാണ്.

expected output: valid count `2`, selected close day `600`.

rank `1` ഉപയോഗിച്ചാൽ selected close day `352` ആയിരിക്കണം.

### `distinct_name_seventh_mapping_probe.spl`

removed canonical ordinals `2,4,6,8,10,12` ആയപ്പോൾ remaining master order `1,3,5,7,9,11,13,...` ആണ്.

fixtures:

- remaining ordinal `7` -> original ordinal `13`;
- remaining ordinal `6` -> original ordinal `11`.

localized മലയാള strings semantic scan-ൽ പങ്കെടുക്കുന്നില്ല.

## progress 20 — drop-4 predecessor crossing, previous-year ranked scan, five-slot exact families

### `visible_drop4_predecessor_seed_probe.spl`

ഈ isolation `i=4`-ൽ predecessor ownership boundary കൃത്യമായി പരിശോധിക്കുന്നു:

- `prev1 = visible[3]`;
- `prev3 = visible[1]`;
- `prev7 = hidden[4]`.

fixture: `hidden4=7`, `visible1=11`, `visible3=13`, `base=-84`.

raw seed before SAVE:

`-84 + 13 + 3*11 + 5*7 + 4 = 1`.

expected output: `1`.

### `previous_year_three_candidate_rank_probe.spl`

fixture:

- close day `1000`;
- candidate open days `748,500,-5000`;
- gap counts `6,7,8`;
- requested rank `2`.

lengths `252,500,6000`; ആദ്യ രണ്ടു candidates മാത്രം `252..5778` bound പാലിക്കുന്നു. ഒരേ close gate ഉള്ളതിനാൽ open day descending scan length ascending order തന്നെയാണ്.

expected output: valid count `2`, selected open day `500`.

rank `1` ഉപയോഗിച്ചാൽ selected open day `748` ആയിരിക്കണം.

### `bounded_composition_five_slot_count_probe.spl`

fixture: `total=7`, `slots=5`, `lo=1`, `hi=7`.

അഞ്ചു positive parts-ന്റെ exact lexicographic family size `15` ആണ്. upper bound ഈ fixture-ൽ binding അല്ല.

expected output: `15`.

### `cutlet_partition_five_slot_filter_count_probe.spl`

fixture: total gate gaps `7`, cutlets `5`, required internal prefix boundary `3`.

എല്ലാ positive 5-part compositions-ലും ഒരു prefix sum `3` ആകുന്നവയുടെ exact count `10` ആണ്.

expected output: `10`.

### `distinct_name_eighth_mapping_probe.spl`

removed original ordinals `2,4,6,8,10,12,14` ആയാൽ remaining order `1,3,5,7,9,11,13,15,...` ആണ്.

fixtures:

- remaining ordinal `8` -> original ordinal `15`;
- remaining ordinal `7` -> original ordinal `13`.

### `weave_three_two_two_count_probe.spl`

lengths `3,2,2` small exact family count `9` ആണ്. ആദ്യ month position 1-ൽ തുറക്കുകയും month 3 അവസാന position-ൽ അടയുകയും ചെയ്യുമ്പോൾ ഏക internal month-3 occurrence-ന്റെ അഞ്ച് relative positions-നുള്ള valid binary-placement counts `0,1,2,3,3`; ആകെ `9`.

expected output: `9`.

## progress 21 — seven hidden coefficient rows, rank-1 bowl commit, forward year walk, two gate streams, 3-2-2 weaving unrank

### `hidden_seven_seed_rows_no_wrap_probe.spl`

stdin: `action,target,distance,connection,direction`, തുടർന്ന് ഏഴ് stone-row sums. ഈ probe coefficient row mapping മുഴുവൻ ഒരേ source-ൽ പരിശോധിക്കുന്നു. no-wrap fixture:

- counts എല്ലാം `1`;
- ഏഴ് stone sums എല്ലാം `0`.

expected outputs:

`22,35,48,61,74,87,100`.

ഇവ യഥാക്രമം rows `[3,4,6,8]`, `[5,7,10,12]`, `[7,10,14,16]`, `[9,13,18,20]`, `[11,16,22,24]`, `[13,19,26,28]`, `[15,22,30,32]` ഉപയോഗിച്ച raw seeds ആണ്. SAVE wrap semantics വേറെയുള്ള probes-ൽ പരിശോധിക്കുന്നു.

### `drop_rank1_identity_bowl_commit_probe.spl`

stdin: പഴയ bowl values `1..6`. fixture drop value `1`, drop index `1`, stone values `0`; അതിനാൽ order rank `1`, identity order, pours `4,6,8`.

input old snapshot:

`1,2,3,4,5,6`

expected output ആദ്യം rank, തുടർന്ന് six pending values:

`1,637,417,827,755,1149,431`.

ഓരോ pending value-ും അതേ പഴയ six-bowl snapshot മാത്രം വായിക്കണം; earlier pending value മറ്റൊന്നിന്റെ input ആകരുത്.

### `target_year_forward_two_step_probe.spl`

stdin: `targetDay,baseYearNumber,baseOpen,baseClose,nextClose,nextNextClose`.

fixtures:

- `400,5000,100,400,700,1000` -> `5000,100,400`;
- `700,5000,100,400,700,1000` -> `5001,400,700`;
- `900,5000,100,400,700,1000` -> `5002,700,1000`.

closing gate current year-ൽ ഉൾപ്പെടുന്നതിനാൽ equality-ൽ transition ഉണ്ടാകരുത്; `target > close` മാത്രമാണ് next-year condition.

### `gate_two_short_streams_accumulate_probe.spl`

stdin: `foundation,acceptedAnswer1,acceptedAnswer2`; answers `1..922` acceptance region-ൽ തന്നെയാണെന്ന precondition.

fixture:

`1000,1,922` -> `1042,2005`.

കാരണം gaps `42`യും `963`യും ആണ്; രണ്ടാം gate ആദ്യ gate-ിൽ നിന്ന് accumulate ചെയ്യണം.

### `weave_three_two_two_unrank_probe.spl`

lengths `3,2,2` family-യുടെ lexicographic rows:

1. `1112233`
2. `1112323`
3. `1121233`
4. `1121323`
5. `1123123`
6. `1211233`
7. `1211323`
8. `1213123`
9. `1231123`

ഇത് മുമ്പത്തെ exact count `9` witness-നെ complete small-family unrank witness ആയി ഉയർത്തുന്നു.

### wide selector boundary fixture

നിലവിലുള്ള `choose_rank_wide_probe.spl`-ലേക്ക് നിർബന്ധിത മൂന്നാം-power boundary fixture ചേർക്കണം/പ്രവർത്തിപ്പിക്കണം:

- `first=1`, `directionStep=1`, `N=M^2+1` -> `M-1`
- decimal expected rank: `170141183460469231731687303715884105726`.

ഇവിടെ `places=3`; initial wide accepted region-ലാണ്, അതിനാൽ rejection പുതിയ digits ഉണ്ടാക്കുന്നില്ല.

## progress 22 — full-range ownership/schedule controls, 46 bowl commits, 12 post-stir commits, backward year walk, three-candidate sort

### `rolling_46_source_ownership_counts_probe.spl`

stdin: visible count `46`.

`prev1` hidden source `i=1`-ൽ മാത്രം; visible source `i=2..46`.
`prev3` hidden source `i=1..3`; visible source `i=4..46`.
`prev7` hidden source `i=1..7`; visible source `i=8..46`.

expected output:

`1,45,3,43,7,39`.

ഈ probe value recurrence അല്ല; all-46 rolling timeline ownership boundary-കളുടെ control witness ആണ്.

### `visible_46x11_row_schedule_probe.spl`

stdin: `46,11,46`.

ഓരോ visible index `i=1..46`-ക്കും 11 grind-ുകളിലും stone row സ്ഥിരമായി `i` തന്നെയാണ്; grind coefficient row മാത്രം `g=1..11` ആയി മാറുന്നു. `wrap1(i+g,46)` എന്ന പഴയ progress-22 വ്യാഖ്യാനം തെറ്റായിരുന്നു, ഈ revision അത് തിരുത്തുന്നു.

expected:

- grind step count: `506`;
- row-index sum: `11891`.

### `bowl_46_transactional_commit_control_probe.spl`

stdin: round count `46`.

initial old bowls: `1,2,3,4,5,6`. control recurrence-ൽ round `r`-ന്റെ six pending values `old_j+r`; ആറു pending-ഉം തയ്യാറായശേഷം മാത്രമേ commit ഉണ്ടാകൂ. `1+...+46 = 1081`.

expected final committed bowls:

`1082,1083,1084,1085,1086,1087`.

ഇത് normative bowl arithmetic-ന്റെ പകരമല്ല; exactly 46 transactional commit epochs isolate ചെയ്യുന്നു.

### `post_stir_12_transactional_commit_control_probe.spl`

stdin: stir count `12`.

initial old bowls: `1,2,3,4,5,6`. ownership-control recurrence `pending_j=old_j+stir`; ആറു pending-ഉം തയ്യാറായശേഷം commit. `1+...+12=78`.

expected final committed bowls:

`79,80,81,82,83,84`.

normative 1A saved-sum/order/bowl formula വേറെയുള്ള probes-ൽ തുടരുന്നു; ഇവിടെ full 12-commit transactional boundary മാത്രം isolate ചെയ്യുന്നു.

### `target_year_backward_two_step_probe.spl`

stdin: `targetDay,baseYearNumber,baseOpen,baseClose,previousOpen,previousPreviousOpen`.

fixtures:

- `200,5000,100,400,-200,-500` -> `5000,100,400`;
- `100,5000,100,400,-200,-500` -> `4999,-200,100`;
- `-300,5000,100,400,-200,-500` -> `4998,-500,-200`.

`(open,close]` semantics കാരണം target == open current year-ൽ ഉൾപ്പെടുന്നില്ല; previous transition നിർബന്ധമാണ്.

### `year5000_three_candidate_sort_probe.spl`

valid input candidates:

- A `(open=100, close=500)`, length `400`;
- B `(open=200, close=500)`, length `300`;
- C `(open=50, close=350)`, length `300`.

Appendix A sort key `length ascending`, tie-ൽ `opening gate ascending`. അതിനാൽ exact order C, B, A.

fixtures:

- requested rank `1` -> `50,350`;
- requested rank `2` -> `200,500`;
- requested rank `3` -> `100,500`.

validity filtering ഈ probe-ന്റെ precondition ആണ്; candidate predicate വേറെയുള്ള clean probes-ൽ പരിശോധിക്കുന്നു.

## progress 23 — actual stone row, six initial bowls, position-mapped pours, latched successor, signed gates, full visible-grind table

### `stones_row2_fixed_snapshot_probe.spl`

input ഇല്ല. Appendix A row 1 `17,29,43,71,101`-ൽ നിന്ന് row index `2` simultaneous old-snapshot formulas ഉപയോഗിക്കുന്നു. raw values എല്ലാം `1..M`-ൽ ആയതിനാൽ ഈ fixture-ിൽ SAVE identity ആണ്.

expected row 2:

`378,1073,2375,6195,10493`.

പ്രത്യേകിച്ച് ഒരു പുതിയ stone value മറ്റൊരു formula-യുടെ input ആകരുത്.

### `initial_six_bowls_fixture_probe.spl`

stdin prime values:

`17,19,23,29,31,37`.

counts fixture: `action=1,target=0,distance=0,connection=0,direction=0`. അതിനാൽ ഓരോ ID-ക്കും `s=1+prime^2`, `bowl=s^2+ID`; no wrap.

expected six bowl values:

`84101,131046,280903,708968,925449,1876906`.

### `bowl_pour_nonidentity_mapping_probe.spl`

order-ന്റെ ആദ്യ മൂന്ന് IDs fixed ആയി `3,1,6`. stdin:

`drop=1,i=1,wheat=1,barley=1,salt=1,oldBowl1=1,oldBowl3=3,oldBowl6=6`.

expected pours by position:

`7,7,14`.

ഇത് fixed bowl 1/2/3 lookup അല്ല; position 1/2/3 യഥാക്രമം old bowl ID 3/1/6 വായിക്കണം.

### `order46_successor_lookup_probe.spl`

latched order fixture:

`3,1,6,2,5,4`.

query fixtures:

- queried `3` -> successor `1`;
- queried `1` -> successor `6`;
- queried `6` -> successor `2`;
- queried `4` -> successor `3` circular wrap;
- queried `7` -> diagnostic sentinel `0`.

ഈ lookup drop-46 latched order-ന്റെതാണ്; post-stir diagnostic order ഇതിന്റെ input അല്ല.

### `gate_signed_pair_accumulate_probe.spl`

stdin:

`foundation=1000,positiveRank=1,negativeRank=922`.

rank-ിൽ നിന്ന് gaps `42`യും `963`യും. expected:

`gatePlus1=1042,gateMinus1=37`.

positive side Foundation-ലേക്ക് കൂട്ടുന്നു; negative side Foundation-ൽ നിന്ന് കുറയ്ക്കുന്നു.

### `visible_grind_table_eleven_mapping_probe.spl`

stone kind machine codes: wheat=1, barley=2, salt=3, bitter=4, red=5.

expected rows `g -> a,b,c,d,kind`:

- `1 -> 3,5,7,11,1`
- `2 -> 5,7,11,13,2`
- `3 -> 7,11,13,17,3`
- `4 -> 11,13,17,19,4`
- `5 -> 13,17,19,23,5`
- `6 -> 17,19,23,29,1`
- `7 -> 19,23,29,31,2`
- `8 -> 23,29,31,37,3`
- `9 -> 29,31,37,41,4`
- `10 -> 31,37,41,43,5`
- `11 -> 37,41,43,47,1`
- invalid `0` or `12` -> `0,0,0,0,0`.

ഈ mapping full 46-drop recurrence-ൽ ഓരോ drop-ക്കും ഉപയോഗിക്കേണ്ട 11 normative grind rows-ന്റെ source witness ആണ്.

## progress 24 — large-M exact integration fixtures

### `hidden_seven_grind_modulus_lock_probe.spl`

input ഇല്ല. probe സ്വയം `M=2^127-1` നിർമ്മിക്കുന്നു. hidden-grind recurrence ആരംഭിക്കുന്നത് `x=M`; grind `g=1..7`-ൽ synthetic stone value `M-g` ഉപയോഗിക്കുന്നു.

ഓരോ grind-ലും:

`SAVE(x^2 + 3x + (M-g) + g) = M`.

അതുകൊണ്ട് ഏഴ് outputs-ും ഒരേ exact value ആയിരിക്കണം:

`170141183460469231731687303715884105727`.

ഇത് hidden seed/stone-kind selection-ന്റെ പകരമല്ല; ഏഴ് recurrence commits-ിലും exact SAVE modulus invariant പരിശോധിക്കുന്ന വലിയ-integer witness ആണ്.

### `drop_M_order_rank_probe.spl`

input ഇല്ല. `drop=M`.

expected one-based bowl order rank:

`127`.

കാരണം `1 + regularMod(M-1,720) = 127`. rank-to-six-ID materialization വേറെയുള്ള integrated permutation probe പരിശോധിക്കുന്നു.

### `bowl_round_modulus_reduction_probe.spl`

input ഇല്ല. fixture:

- `drop=M`;
- `i=1`;
- identity bowl order;
- six old bowls `M`;
- current stone row-യിലെ ഉപയോഗിക്കുന്ന stone values എല്ലാം `M`.

normative pours SAVE കഴിഞ്ഞ് position 1..3-ൽ `3,5,7` ആകുന്നു. six pending bowl outputs, bowl ID order 1..6:

`10,27,52,4,5,6`.

എല്ലാ pending reads-ും commit-ിന് മുൻപുള്ള അതേ six-`M` snapshot-ൽ നിന്നാണ്.

### `post_stir_M_snapshot_rank149_probe.spl`

input ഇല്ല. six old bowls `M`, `stir=1`.

expected first outputs:

- `savedStirSum = 149`;
- post-stir order rank `149`.

തുടർന്ന് position-order pending values:

`22801,23716,25281,27556,30625,34596`.

ഈ file order rank കണക്കാക്കുന്നു, പക്ഷേ six-ID permutation materialization വേറെയുള്ള rank-to-order source-ലാണ്; ഇവിടെ വലിയ old snapshot-ിൽ 1A saved value + full bowl arithmetic isolate ചെയ്യുന്നു.

### `wide_M2_plus1_boundary_probe.spl`

input ഇല്ല. `N=M^2+1`, AnswerStream fixture `first=1`, `directionStep=+1`.

- minimal places `3`;
- `space=M^3`;
- digits `0,1,2`;
- `wide=1+M+2M^2`;
- initial wide accepted region-ൽ തന്നെയാണ്.

expected rank:

`170141183460469231731687303715884105726` (`M-1`).

unexpected rejection path diagnostic `0` ആണ്; normative fixture അത് കൈവരിക്കരുത്.

### `ask_bowl_M_wrap_formula_probe.spl`

companion latched order fixture `3,1,6,2,5,4`; queried bowl ID `4`-ന്റെ circular successor ID `3`. arithmetic fixture:

- queried bowl value `M`;
- successor bowl value `M-1`;
- fixed-ID bowl 6 value `M`;
- seal `1`.

expected outputs:

`32946,+1`.

successor lookup-ന്റെ `4 -> 3` mapping `order46_successor_lookup_probe.spl` വേർതിരിച്ച് പരിശോധിക്കുന്നു; ഈ file അതേ wrap-successor value askBowl formula-യുമായി വലിയ exact arithmetic-ൽ ബന്ധിപ്പിക്കുന്നു.

## progress 25 — committed stone row, integrated eleven-row recurrence, two real bowl commits, sauce phase latch

### `stones_row2_to_row3_snapshot_probe.spl`

stdin row 2 snapshot:

`378,1073,2375,6195,10493`.

എല്ലാ അഞ്ച് row 3 formulas-ും അതേ old snapshot മാത്രം വായിക്കണം. ഈ fixture-ൽ SAVE identity ആണ്. expected row 3:

`146106,1163582,5685063,38495823,110114158`.

പ്രത്യേകിച്ച് wheat3 ആദ്യം കണക്കാക്കിയാലും barley3 formula wheat3 വായിക്കരുത്; അത് പഴയ wheat2 `378` തന്നെയാണ് വായിക്കേണ്ടത്.

### `visible_eleven_M_integrated_table_probe.spl`

input ഇല്ല. `x=prev1=prev3=prev7=selectedStone=M` എന്ന modulus-lock fixture. coefficient dispatch Appendix A-യിലെ 11 rows തന്നെയാണ് ഉപയോഗിക്കുന്നത്.

ഓരോ grind-നും രണ്ട് outputs: committed `x`, തുടർന്ന് stoneKind machine code. expected pairs:

- grind 1 -> `M,1`
- grind 2 -> `M,2`
- grind 3 -> `M,3`
- grind 4 -> `M,4`
- grind 5 -> `M,5`
- grind 6 -> `M,1`
- grind 7 -> `M,2`
- grind 8 -> `M,3`
- grind 9 -> `M,4`
- grind 10 -> `M,5`
- grind 11 -> `M,1`

ഇവിടെ `M = 170141183460469231731687303715884105727`.

ഈ fixture standalone table-mapping test-ന്റെ പകരമല്ല; mapping values recurrence path-ലേക്ക് യഥാർത്ഥത്തിൽ കടക്കുന്നു എന്ന integration witness ആണ്.

### `two_drop_two_bowl_commits_probe.spl`

input ഇല്ല. fixture: initial bowls എല്ലാം 0, drop1=drop2=1, identity order, stone contribution 0. ഈ fixture-ൽ SAVE identity.

round 1 pours: `4,6,8`; committed bowls:

`26,51,84,5,6,7`.

round 2 pours: `7,11,15`. round 2 എല്ലാ reads-ും മുകളിലെ committed round-1 snapshot-ൽ നിന്ന് മാത്രം. expected committed bowls:

`42188,145613,48370,39392,1629,10396`.

### `sauce_46_12_latch_phase_probe.spl`

input ഇല്ല. full-cardinality control expected outputs:

`46,12,46,12`.

ക്രമത്തിൽ: visible-drop commit count, post-stir commit count, drop-46 latch marker, അവസാന post-stir diagnostic marker. post phase latch മാറ്റാൻ പാടില്ല.

### `ask_after_poststir_uses_latch_probe.spl`

input ഇല്ല. latched order `3,1,6,2,5,4`; post-stir diagnostic order identity; queried bowl `4`.

expected outputs:

`3,5`.

ആദ്യ value authoritative circular successor from drop-46 latch ആണ്. രണ്ടാമത്തേത് diagnostic-only successor ആണ്; രണ്ടും വ്യത്യസ്തമാകുന്നത് ask path latch-നെ തന്നെ ഉപയോഗിക്കേണ്ടതിന്റെ distinguishing fixture ആണ്.

## progress 26 — full-path cardinality, hidden integration, seal-10 and closing-boundary fixtures

### `hidden_seven_full_synthetic_generation_probe.spl`

input ഇല്ല. ഇത് legal `workCounts` fixture അല്ല; hidden coefficient rows വേറെയുള്ള source-ൽ പരിശോധിക്കുന്നു. arithmetic isolation fixture:

- counts contribution = `26`;
- ഓരോ hidden `k`-ക്കും synthetic stones = `M, M-5, M-6, M-7, M-8`;
- seed: `SAVE(26 + 5M - 26) = M`;
- seven grind stone sequence: wheat, barley, salt, bitter, red, wheat, barley.

ഒരു hidden drop-ന്റെ committed x sequence:

`M -> 1 -> 1 -> 1 -> 1 -> 1 -> 10 -> 132`.

അതേ full seven-grind path hidden `k=1..7`-ൽ നടക്കുന്നു. expected outputs:

`132,132,132,132,132,132,132,7`.

അവസാന `7` generated hidden cardinality ആണ്.

### `stones_full_46_transactional_path_probe.spl`

input ഇല്ല. normative row 1 `17,29,43,71,101` മുതൽ row 46 വരെ actual five-stone formulas ഉപയോഗിക്കുന്നു. ഓരോ row-ലും അഞ്ച് pending values പഴയ snapshot മാത്രം വായിക്കുകയും എല്ലാം തയ്യാറായ ശേഷം commit ചെയ്യുകയും വേണം.

ഈ full-path control exact row values output ചെയ്യുന്നില്ല; row 2/row 3 exact fixtures വേറെയുണ്ട്. expected outputs:

`45,46`.

ആദ്യ value row1->row46 committed transitions എണ്ണം; രണ്ടാമത്തേത് അവസാന committed row index.

### `post_stir_twelve_saved_rank_schedule_probe.spl`

input ഇല്ല. ഓരോ stir-ലും six synthetic old bowls `M`; bowl state ഇവിടെ commit ചെയ്യുന്നില്ല. അതിനാൽ:

`savedBowlSum = SAVE(6M + 149*stir) = 149*stir`.

expected `(saved, rank)` pairs:

- `1 -> 149,149`
- `2 -> 298,298`
- `3 -> 447,447`
- `4 -> 596,596`
- `5 -> 745,25`
- `6 -> 894,174`
- `7 -> 1043,323`
- `8 -> 1192,472`
- `9 -> 1341,621`
- `10 -> 1490,50`
- `11 -> 1639,199`
- `12 -> 1788,348`

അവസാന completion marker `12`.

### `year_max_5778_to_5781_boundary_probe.spl`

input ഇല്ല. clean Stage 1 maximum `5778`; consecutive candidates 5778..5781. expected booleans:

`1,0,0,0`.

ഇവിടെ `5781` ഒരു legacy constant അല്ല; reject ചെയ്യപ്പെടേണ്ട test input മാത്രം.

### `final_five_field_closing_boundary_probe.spl`

input ഇല്ല. materialized fixture:

- year number `5000`;
- year first day `100`, target/closing day `105`;
- cutlet 1 last day `102`, canonical cutlet IDs `4,7`;
- weaving month IDs `1,2,1,3,2,3`;
- month ID 3 canonicalIndex `17`.

expected exactly five outputs:

`5000,7,3,17,2`.

അവസാന `2` year start മുതൽ target ഉൾപ്പെടെ month ID 3-ന്റെ occurrence count ആണ്.

### `distinct_name_general_sorted_mapping_probe.spl`

input format: `removalCount`, `remainingOrdinal`, തുടർന്ന് removed original ordinals **descending** order-ൽ. stack recall അവയെ ascending order-ൽ process ചെയ്യുന്നു.

fixtures:

- `0,4` -> `4`;
- `2,4,5,2` -> `6`;
- `3,2,5,3,1` -> `4`;
- `7,8,14,12,10,8,6,4,2` -> `15`.

localized strings ഒന്നും semantic mapping-ൽ ഉപയോഗിക്കരുത്.

### `year5000_seal10_short_rank_probe.spl`

input ഇല്ല. synthetic final bowl values queried=0, successor=0, fixed bowl6=0; **seal=10**; candidate count `N=3`.

expected outputs:

`36491,-1,2`.

`first=191^2+10=36491`; direction expression even ആയതിനാൽ step `-1`; first accepted region-ൽ തന്നെയായതിനാൽ rank `1+regularMod(36490,3)=2`.

### progress 26 correction — `distinct_name_eighth_mapping_probe.spl`

progress 20-ലെ പഴയ threshold shortcut removed ordinals input order-നോട് അനാവശ്യമായി sensitive ആയിരുന്നു. Stage 1 clean-oracle audit-ൽ അത് candidate-scan ആയി മാറ്റി. existing fixtures മാറുന്നില്ല:

- removals `2,4,6,8,10,12,14`, remaining `8` -> `15`;
- removals `2,4,6,8,10,12,14`, remaining `7` -> `13`.

ഇത് historical patch അല്ല; Stage 1 ഇനിയും incomplete ആയിരിക്കെ clean reference തന്നെ ശരിയാക്കുന്നതാണ്.

## progress 27 — legal workCounts bridge and full-46 rolling visible invariant

### `work_counts_full_probe.spl`

input: raw action day, raw target day. output ക്രമം:

`actionDayCount,targetDayCount,distance,connection,direction`.

direction mapping clean Appendix A control: target raw day പഴയത് `1`, same `2`, മുന്നിലുള്ളത് `3`.

fixtures:

- `-15055671,-15055671` -> `1,1,1,2,2`;
- `-15055670,-15055669` -> `3,5,2,8,3`;
- `-15055669,-15055670` -> `5,3,2,8,1`;
- `-15055672,-15055671` -> `2,1,2,3,3`.

ഇത് raw day axis-ിൽ നിന്ന് dayCount parity mapping, chronological distance, connection, direction എന്നിവ ഒരേ source-ൽ ബന്ധിപ്പിക്കുന്നു.

### `legal_foundation_hidden_seed_rows_probe.spl`

input ഇല്ല. legal same-Foundation workCounts fixture:

`action=1,target=1,distance=1,connection=2,direction=2`.

stone-row sums isolate ചെയ്യാൻ 0. ഏഴ് hidden coefficient rows-ന്റെ expected seeds:

`36,57,78,99,120,141,162`.

ഇവ M-നെക്കാൾ ചെറുതായതിനാൽ SAVE identity ആണ്.

### `legal_foundation_six_initial_bowls_probe.spl`

input ഇല്ല. അതേ legal same-Foundation workCounts fixture; primes:

`17,19,23,29,31,37`.

ഓരോ bowl ID-ക്കും:

`s = 1 + 1*ID + 1 + 2 + 2 + prime^2 = prime^2 + ID + 6`.

expected outputs:

`87617,136163,289447,724205,944789,1907167`.

ഈ fixture no-wrap ആണ്.

### `visible_46_full_rolling_invariant_probe.spl`

input ഇല്ല. ഇത് actual generated stone table അല്ല; 46-drop rolling-state integration isolation fixture ആണ്.

- seven predecessor slots ആദ്യം എല്ലാം `M`;
- ഓരോ visible drop `i`-ക്കും synthetic seed base `M-i`;
- seed raw = `(M-i)+M+3M+5M+i = 10M`, അതിനാൽ SAVE -> `M`;
- ഓരോ 11 grind-ലും Appendix A-യിലെ actual `(a,b,c,d)` coefficient row ഉപയോഗിക്കുന്നു;
- selected synthetic stone value `M`;
- x, prev1, prev3, prev7 എല്ലാം `M` ആയതിനാൽ ഓരോ grind raw expression-ും M-ന്റെ ഗുണിതം, SAVE -> `M`;
- commit കഴിഞ്ഞ് seven-slot rolling shift നടക്കുന്നു.

46 visible commits കഴിഞ്ഞ expected outputs:

`46,47,M,M,M`.

ക്രമം: committed count, next i, current x, rolling last1, rolling last7. ഇത് full 46 outer loop + 46*11 normative coefficient dispatch + rolling predecessor commit boundary ഒരേ source-ൽ ഉറപ്പിക്കുന്നു; actual generated stone lookupയും legal seed base-ും ഇനിയും വേറെ integration blocker ആണ്.

## progress 28 — visible stone-row indexing correction and legal row-1 integration

### clean-reference correction: `visible_46x11_row_schedule_probe.spl`

progress 22-ൽ ഈ probe `row=wrap1(i+g,46)` എന്ന് തെറ്റായി വ്യാഖ്യാനിച്ചിരുന്നു. Appendix A-യിലെ clean rule അങ്ങനെ അല്ല: visible drop `i`-ന്റെ seed-ലും എല്ലാ 11 grind-ുകളിലും stone lookup അതേ `stones[i]` row-ൽ നിന്നാണ്; grind coefficient row മാത്രം `g=1..11` ആയി മാറുന്നു. ഈ revision source തന്നെ തിരുത്തുന്നു.

stdin: `46,11`.

expected outputs:

- grind step count: `506`;
- stone-row index sum: `11891`;
- grind-row index sum: `3036`;
- final stone row: `46`;
- final grind row: `11`.

അവസാന `(46,11)` witness പഴയ wrapped interpretation-നെ നേരിട്ട് വേർതിരിക്കുന്നു.

### `visible_row1_two_grinds_legal_probe.spl`

stdin ഇല്ല.

legal same-Foundation workCounts:

`action=1,target=1,distance=1,connection=2,direction=2`.

actual stone row 1:

`WHEAT=17,BARLEY=29,SALT=43,BITTER=71,RED=101`.

predecessor fixture:

`prev1=1,prev3=1,prev7=1`, `i=1`.

expected outputs:

- visible seed after SAVE: `443`;
- grind 1 (`3,5,7,11,WHEAT`) after SAVE: `197618`;
- grind 2 (`5,7,11,13,BARLEY`) after SAVE: `39053862074`.

രണ്ട് grind-ുകളിലും stone row 1 തന്നെയാണ്; kind മാത്രമാണ് മാറുന്നത്.

### `visible_same_stone_row_kind_cycle_probe.spl`

stdin:

`17,29,43,71,101`.

11 grind kind sequence:

`WHEAT,BARLEY,SALT,BITTER,RED,WHEAT,BARLEY,SALT,BITTER,RED,WHEAT`.

expected outputs:

- selected-stone sum: `539`;
- first selected stone: `17`;
- last selected stone: `17`.

ഈ probe stone row മാറുന്നില്ലെന്ന് isolate ചെയ്യുന്നു; grind index kind selector മാത്രം മാറ്റുന്നു.

## progress 29 — full stone retention/replay, actual hidden bridge, M-to-factoradic bridge

### `stones_full_46_forward_replay_probe.spl`

stdin ഇല്ല. actual Appendix A stone row 1 മുതൽ row 46 വരെ transactional recurrence source-ൽ നിർമ്മിക്കുന്നു. ഓരോ committed row-ന്റെയും അഞ്ച് stone values അഞ്ച് archive stack-ുകളിൽ push ചെയ്യുന്നു; generation കഴിഞ്ഞ് ഓരോ archive stack-ും രണ്ടാമത്തെ stack-ിലേക്ക് reverse ചെയ്യുന്നു. അതിനാൽ replay top വീണ്ടും row 1 ആയിരിക്കണം.

expected outputs:

`45,46,46,17,29,43,71,101,378,1073,2375,6195,10493`.

ക്രമം: committed stone transitions, archived rows, reversed rows, തുടർന്ന് forward replay row 1-ന്റെ WHEAT/BARLEY/SALT/BITTER/RED. ഈ witness full 46-row values പിന്നീട് visible phase forward order-ൽ consume ചെയ്യാൻ കഴിയുന്ന storage ownership pattern source-ൽ materialize ചെയ്യുന്നു.

### `hidden1_actual_row1_first_grind_probe.spl`

stdin ഇല്ല. legal same-Foundation workCounts `1,1,1,2,2`, actual stone row 1 `17,29,43,71,101`, hidden approach 1 coefficient row എന്നിവ ഉപയോഗിക്കുന്നു. seed-നും grind-നും SAVE പ്രയോഗിക്കുന്നു.

expected outputs:

`297,89118`.

seed: `1 + 3*1 + 4*1 + 6*2 + 8*2 + 17+29+43+71+101 = 297`.

first hidden grind: `SAVE(297^2 + 3*297 + 17 + 1) = 89118`.

### `drop_M_factoradic_digits_probe.spl`

stdin ഇല്ല. `M=2^127-1` source-ൽ നിർമ്മിക്കുന്നു; drop-derived bowl order rank `1+regularMod(M-1,720)` കണക്കാക്കുന്നു; തുടർന്ന് six-item permutation-ന്റെ zero-based factoradic selection digits തുറക്കുന്നു.

expected outputs:

`127,1,0,1,0,0,0`.

ആദ്യ output one-based rank ആണ്; പിന്നാലെ block sizes `120,24,6,2,1,1`-നുള്ള selection digits. അടുത്ത integration step ഈ digits active six-ID removal materialization-ലേക്ക് നേരിട്ട് feed ചെയ്യുന്നതാണ്.

## progress 30 — sequential stone replay consumption, row-2 visible bridge, rank-derived bowl/post-stir bridge

### `stones_full_46_forward_replay_probe.spl` — replay row 2 extension

full 46-row archive/reverse witness ഇപ്പോൾ row 1 മാത്രം അല്ല, replay-ൽ അടുത്ത row 2-വും consume ചെയ്യുന്നു.

expected outputs:

`45,46,46,17,29,43,71,101,378,1073,2375,6195,10493`.

ആദ്യ മൂന്ന് control values transitions, archived rows, reversed rows ആണ്. തുടർന്ന് row 1-ന്റെ അഞ്ച് stones, പിന്നെ row 2-ന്റെ അഞ്ച് stones. ഇതോടെ reverse-to-forward stack ownership row 1-ൽ മാത്രം accidental ആയി ശരിയാകുന്നതല്ലെന്ന് distinguishing witness ലഭിക്കുന്നു.

### `visible_row2_from_snapshot_first_grind_legal_probe.spl`

input ഇല്ല. same-Foundation legal workCounts `1,1,1,2,2`; row 1 stones `17,29,43,71,101`; row 2 transactional recurrence; predecessor fixture `1,1,1`; visible index `i=2`.

row 2 after SAVE:

`378,1073,2375,6195,10493`.

visible seed:

`378 + 1073 + 2375 + 2*6195 + 2*10493 + 1 + 3 + 5 + 2 = 37213`.

first visible grind uses row 2 WHEAT and coefficient row `3,5,7,11`:

`37213^2 + 3*37213 + 5 + 7 + 11 + 378 = 1384919409`.

expected outputs:

`37213,1384919409`.

SAVE രണ്ടിടത്തും value മാറ്റുന്നില്ല, കാരണം raw values `1..M` പരിധിയിലാണ്.

### `factoradic_127_materialize_probe.spl`

input ഇല്ല. മുൻ clean bridge-ൽ rank 127-നുള്ള factoradic digits `1,0,1,0,0,0` ആണ്. active ID list `[1,2,3,4,5,6]`-ൽ zero-based removal നടത്തുമ്പോൾ expected order:

`2,1,4,3,5,6`.

### `bowl_rank127_M_snapshot_round_probe.spl`

input ഇല്ല. `drop=M`, six old bowls `M`, actual stone row 1, rank-127 order `2,1,4,3,5,6`.

ആദ്യ മൂന്ന് position pours SAVE കഴിഞ്ഞ്:

`3,5,7`.

six position results bowl-ID order `1..6`-ൽ:

`1158,401,5045,2503,10206,295`.

raw committed-candidate sum:

`19608`.

stir 1-ന്റെ 1A saved sum:

`19757`.

`1+regularMod(19757-1,720)`:

`317`.

അതുകൊണ്ട് മുഴുവൻ expected output sequence:

`1158,401,5045,2503,10206,295,19608,19757,317`.

### `factoradic_317_materialize_probe.spl`

input ഇല്ല. one-based rank 317 -> zero-based 316 -> factoradic digits `2,3,0,2,0,0`; active-ID removal expected order:

`3,5,1,6,2,4`.

ഇത് `bowl_rank127_M_snapshot_round_probe.spl`-ന്റെ post-stir-1 rank output-നെ അടുത്ത post-stir order materialization-ലേക്ക് ബന്ധിപ്പിക്കുന്ന clean source bridge ആണ്.

## progress 31 — actual seven-hidden generation from retained stones, ring index/storage control

### `hidden_seven_actual_stone_replay_probe.spl`

stdin ഇല്ല. Appendix A stone row 1..46 transactional ആയി നിർമ്മിച്ച് forward replay stack-ുകളാക്കി, replay row 1..7 same-Foundation legal workCounts contribution-നൊപ്പം consume ചെയ്യുന്നു. ഓരോ hidden index k-നും fixture contribution `21*k+15` ആണ്; അതിലേക്ക് ആ row-യിലെ അഞ്ച് actual stones ചേർത്ത് SAVE ചെയ്യുന്നു; തുടർന്ന് `WHEAT,BARLEY,SALT,BITTER,RED,WHEAT,BARLEY` ക്രമത്തിൽ ഏഴ് hidden grinds, ഓരോ grind-നും `SAVE(x^2 + 3*x + selectedStone + grind)`.

ഓരോ final hidden value backward archive-ലേക്ക് commit ചെയ്യുന്നു. അവസാനം archive top `hidden7..hidden1` pop ചെയ്ത് timeline ring slots `2,3,4,5,6,7,1` seed ചെയ്യുന്നു.

expected control outputs:

`45,46,7,7`.

ക്രമം: stone transitions, stone replay reversal count, hidden commits, timeline ring seeds. arithmetic path actual row 1..7 consume ചെയ്യുന്നു; control output numeric hidden values duplicate oracle ആയി hard-code ചെയ്യുന്നില്ല.

### `timeline_seven_slot_ring_index_probe.spl`

stdin ഇല്ല. `slot(p)=1+regularMod(p,7)` എന്ന rolling ownership mapping source-ൽ materialize ചെയ്യുന്നു. hidden negative positions-നായി equivalent non-negative representatives ഉപയോഗിക്കുന്നു.

expected outputs:

`2,1,6,2,5,4,2,5,46`.

ആദ്യ നാല് values i=1-ന്റെ `current,prev1,prev3,prev7`; അടുത്ത നാല് i=46-ന്റെ mapping; അവസാന value `currentSlot==prev7Slot` ആയ 46 iterations count. അതിനാൽ prev7 current slot overwrite ചെയ്യുന്നതിന് മുമ്പ് വായിക്കണം.

### `timeline_ring_seed_eight_commit_probe.spl`

stdin ഇല്ല. synthetic hidden values `101..107` timeline positions `0..-6`-ൽ നിന്ന് seven-slot ring-ലേക്ക് seed ചെയ്യുന്നു; visible 1..8 values `201..208` commit ചെയ്യുന്നു. predecessor output overwrite-ന് മുമ്പാണ്.

expected outputs:

`101,103,107,206,204,101,207,205,201`.

ഇവ യഥാക്രമം i=1, i=7, i=8-ന്റെ `(prev1,prev3,prev7)` triples. i=8-ൽ prev7 ആദ്യമായി hidden value-നു പകരം committed visible1 `201` വായിക്കുന്നത് seven-slot ring reuse-ന്റെ distinguishing witness ആണ്.

## progress 32 — actual seven-hidden to first two visible drops, dual stone-consumer ownership

### `hidden_actual_to_visible_two_full_probe.spl`

stdin ഇല്ല. progress 31-ലെ actual 46-row stone generation -> rows 1..7 hidden generation -> hidden backward archive -> seven-slot timeline seed path 그대로 തുടർന്നു, അതിന് പിന്നാലെ same-Foundation legal workCounts fixture ഉപയോഗിച്ച് visible drop 1-നും visible drop 2-നും ഓരോന്നായി മുഴുവൻ 11 normative grinds നടത്തുന്നു.

visible 1 predecessor snapshot:

`prev1=hidden1, prev3=hidden3, prev7=hidden7`.

visible 1-ന് actual row 1 stones `17,29,43,71,101` ഉപയോഗിക്കുന്നു. commit കഴിഞ്ഞ് value `1..M` range-ൽ ആണെന്ന് flag പരിശോധിക്കുന്നു. തുടർന്ന് row 1 snapshot-ൽ നിന്ന് row 2 transactional ആയി നിർമ്മിച്ച് commit ചെയ്യുന്നു. visible 2 predecessor snapshot:

`prev1=visible1, prev3=hidden2, prev7=hidden6`.

visible 2-ന് actual committed row 2 ഉപയോഗിക്കുന്നു; വീണ്ടും 11 normative grinds മുഴുവനായി നടത്തുന്നു. visible 2 commit-നെ `1+regularMod(drop-1,720)` വഴി bowl-order rank domain-ലേക്ക് ബന്ധിപ്പിക്കുകയും rank `1..720` range-ൽ ആണെന്ന് വേർതിരിച്ച flag പരിശോധിക്കുകയും ചെയ്യുന്നു.

progress 31 source-ൽ ഇതിനുമുമ്പ് പുറത്തുവരുന്ന control outputs:

`45,46,7,7`.

ഈ continuation-ന്റെ expected additional outputs:

`1,1,2,11,1`.

അവയുടെ ക്രമം: visible1 SAVE-range flag, visible2 SAVE-range flag, final visible index, final grind index, actual visible2-derived bowl-rank domain flag.

ഈ probe hard-coded visible numeric answer ഉപയോഗിക്കുന്നില്ല; actual generated hidden values downstream arithmetic-ൽ consume ചെയ്യപ്പെടുന്നു, while exact invariants/domain conditions are checked in SPL itself.

### `stone_dual_consumer_replay_control_probe.spl`

stdin ഇല്ല. ordered row IDs `1..46` backward archive-ൽ സൂക്ഷിച്ച ശേഷം reversal സമയത്ത് രണ്ട് സ്വതന്ത്ര forward replay stack-ുകളിലേക്ക് duplicate ചെയ്യുന്നു. hidden consumer ആദ്യ ഏഴ് rows മാത്രം consume ചെയ്യുന്നു; visible consumer hidden consumption-ൽ നിന്ന് സ്വതന്ത്രമായി മുഴുവൻ 46 rows consume ചെയ്യുന്നു.

expected outputs:

`46,7,1,7,46,1,46`.

ക്രമം: reverse count; hidden consume count, first row, last row; visible consume count, first row, last row. ഇത് actual stone value formula-യുടെ പകരമല്ല; one generated stone family-ന് രണ്ട് forward consumers ആവശ്യമുള്ള state-ownership strategy isolate ചെയ്യുന്നു.

#### progress 32 factoradic continuation

`hidden_actual_to_visible_two_full_probe.spl` committed visible 2-ന്റെ actual one-based bowl rank-നെ block sizes `120,24,6,2,1` ഉപയോഗിച്ച് six factoradic digits-ആക്കി കൂടി തുറക്കുന്നു. hard-coded rank ഉപയോഗിക്കുന്നില്ല; rank actual generated visible 2-ൽ നിന്നാണ് വരുന്നത്. digit bounds `d1<=5,d2<=4,d3<=3,d4<=2,d5<=1,d6=0` source control flag ആയി പരിശോധിക്കുന്നു.

അതുകൊണ്ട് progress 32-ന്റെ corrected additional expected outputs:

`1,1,2,11,1,1`.

അവയുടെ അവസാന രണ്ടു values യഥാക്രമം actual visible2-derived rank-domain flag, factoradic digit-domain flag ആണ്.

## progress 33 — actual five-value dual replay, full actual hidden -> visible 46 path

### `stones_full_46_dual_five_value_replay_probe.spl`

stdin ഇല്ല. Appendix A stone row 1..46 simultaneous recurrence ഉപയോഗിച്ച് അഞ്ച് backward archive families നിർമ്മിക്കുന്നു. reversal സമയത്ത് ഓരോ popped five-value row-യും രണ്ട് സ്വതന്ത്ര forward replay owners-ലേക്ക് duplicate ചെയ്യുന്നു: hidden consumer-നുള്ള `Ariel/Falstaff/Rosalind/Horatio/Polonius` memory stacks, visible consumer-നുള്ള `Hamlet/Juliet/Romeo/Othello/Macbeth` memory stacks.

hidden consumer rows `1..7` consume ചെയ്ത ശേഷവും visible consumer row `1` മുതൽ ആരംഭിച്ച് `46` rows മുഴുവൻ consume ചെയ്യണം.

expected outputs:

`46,7,17,29,43,71,101,46`.

ക്രമം: reversal count; hidden consume count; visible consumer-ന്റെ first row അഞ്ച് normative stone values; visible consume count. ഇത് row-ID ownership control-നെ actual five-value stone state-ലേക്ക് ഉയർത്തുന്നു.

### `sauce_foundation_actual_hidden_visible46_probe.spl`

stdin ഇല്ല. same-Foundation legal workCounts `action=1,target=1,distance=1,connection=2,direction=2` ഉപയോഗിക്കുന്നു. source path:

`46 actual stone rows -> dual five-value replay -> rows 1..7 actual hidden generation -> seven hidden backward archive -> rolling last1..last7 seed -> rows 1..46 actual visible generation -> 11 normative grinds per visible drop -> rolling commit -> actual drop46 bowl-order rank domain -> factoradic digits -> six active-ID removal -> forward order replay`.

visible seed ഓരോ `i`-ക്കും current actual stone row തന്നെയാണ് ഉപയോഗിക്കുന്നത്:

`SAVE(W + B + S + 2*BITTER + 2*RED + prev1 + 3*prev3 + 5*prev7 + i)`.

visible grind table പതിനൊന്ന് rows മുഴുവനും source-ൽ explicit ആണ്; ഓരോ grind-ലും current drop-ന്റെ same stone row മാത്രം ഉപയോഗിക്കുന്നു. current visible value commit ചെയ്തതിന് ശേഷമേ rolling history shift ചെയ്യൂ. അതിനാൽ `i=8` മുതൽ `prev7` committed visible history-യിൽ നിന്ന് ലഭിക്കുന്നു.

expected structural outputs:

`46,7,46,47,1,1,6,21,720,6`.

ക്രമം: stone reversal count; hidden commit count; visible commit count; next visible index; actual drop46-derived bowl rank `1..720` domain flag; ആ rank-ൽ നിന്ന് കണക്കാക്കിയ six factoradic digits-ന്റെ domain flag; active-set removal selection count 6; selected-ID sum 21; selected-ID product 720; backward-selected archive -> forward-order replay reverse count 6.

ഈ probe drop values അല്ലെങ്കിൽ drop46 rank hard-code ചെയ്യുന്നില്ല. exact values source path-ൽ generated state-ിൽ നിന്നാണ് വരുന്നത്; expected outputs state/cardinality/domain invariants മാത്രം ആണ്.

### progress 33 clean-reference control-flow correction

`hidden_seven_actual_stone_replay_probe.spl`-ലും `hidden_actual_to_visible_two_full_probe.spl`-ലും progress 31/32-ൽ hidden commit കഴിഞ്ഞ് `Act V`-ലേക്ക് മടങ്ങുമ്പോൾ `Scene I` hidden index/count വീണ്ടും `1/0` ആക്കുന്ന reset ഉണ്ടായിരുന്നു. അത് clean oracle control-flow പിഴവായിരുന്നു. ഇപ്പോൾ reversal completion-ൽ പുതിയ initialization scene ഒരിക്കൽ മാത്രം `index=1,count=0` സജ്ജമാക്കുന്നു; `Act V Scene I` reset ഇല്ലാത്ത loop entry ആണ്. subsequent hidden commits `Act V`-ലേക്ക് മടങ്ങിയാലും index/count നിലനിൽക്കും.

expected outputs മാറുന്നില്ല; source path മാത്രമാണ് intended seven-hidden progression-നോട് ഒത്തത്.

progress 34 extension: dynamic factoradic digits ഇനി same source path-ൽ six active IDs-ൽ removal-aware ആയി materialize ചെയ്യുന്നു. ഓരോ തിരഞ്ഞെടുപ്പും backward order archive-ൽ push ചെയ്യുന്നു; ആറു തിരഞ്ഞെടുപ്പുകൾക്ക് ശേഷം archive reverse ചെയ്ത് position 1 ആദ്യം ലഭിക്കുന്ന forward replay stack ഉണ്ടാക്കുന്നു. rank/drop/order values hard-code ചെയ്തിട്ടില്ല; invariant outputs `6,21,720,6` മാത്രമാണ് expected.

### `dynamic_order_three_pours_dispatch_probe.spl`

stdin:

`3,1,6,2,3,5,7,11,13,1,1,17,29,43`

ക്രമം: order positions `3,1,6`; old bowls `1..6 = 2,3,5,7,11,13`; drop `1`; visible index `1`; stones `WHEAT=17,BARLEY=29,SALT=43`.

expected outputs:

`89,64,567`.

source order ID അനുസരിച്ച് old snapshot value dynamic ആയി തിരഞ്ഞെടുക്കുന്നു; position 1/2/3-ന് യഥാക്രമം `+3*i`, `+5*i`, `+7*i` ചേർത്ത് ഓരോ pour-നും `SAVE` പ്രയോഗിക്കുന്നു. fixture values M-ൽക്കാൾ ചെറുതായതിനാൽ SAVE അവ മാറ്റുന്നില്ല; source-ൽ full `M=2^127-1` reduction path തന്നെയുണ്ട്.

### progress 34 clean-reference correction — ID 5 zero-selection

source audit-ൽ `bowl_order_rank6_integrated_probe.spl`, `factoradic_127_materialize_probe.spl`, `factoradic_317_materialize_probe.spl`, `permutation_materialize6_probe.spl` എന്നിവയിലെ active-set scan-ൽ ID 5 active ആയിരിക്കുമ്പോൾ current digit `0` ആയ path തെറ്റായി digit decrement scene-ലേക്ക് പോയിരുന്നു. ഇപ്പോൾ zero path ID 5 തിരഞ്ഞെടുക്കുകയും active-set-ൽ നിന്ന് നീക്കുകയും ചെയ്യുന്നു; positive digit path മാത്രം decrement ചെയ്ത് ID 6-ലേക്ക് നീങ്ങുന്നു. rank `481 -> 5,1,2,3,4,6` fixture ഈ branch-നെ നേരിട്ട് വേർതിരിക്കുന്നു.

## progress 35 — bowl-phase replay retention and first-drop cursor

### `sauce_foundation_actual_hidden_visible46_probe.spl` extension

progress 35-ൽ same integrated sauce fixture visible generation സമയത്ത് ഓരോ `stones[i]` five-value row-യും ഓരോ committed `visible[i]` value-യും bowl phase-നായി backward archive ചെയ്യുന്നു. visible 46 പൂർത്തിയായ ശേഷം അഞ്ച് stone archives-ും drop archive-ും 46 തവണ reverse ചെയ്ത് forward replay ആക്കുന്നു. അതിനാൽ bowl phase consumption row/drop `1` മുതൽ normative order-ൽ ആരംഭിക്കാം; drop 46 scalar latch/rank path ഇതിൽ നിന്ന് സ്വതന്ത്രമായി തുടരുന്നു.

പുതിയ full expected structural output sequence:

`46,7,46,47,46,1,1,6,21,720,6,17,29,43,71,101,1,1,1`.

പുതിയ values-ന്റെ അർത്ഥം:
- അഞ്ചാമത്തെ `46`: bowl-phase stone/drop archives forward replay-ലേക്ക് reverse ചെയ്ത count;
- `17,29,43,71,101`: bowl-phase cursor ആദ്യമായി pop ചെയ്യുന്ന actual normative stone row 1;
- അതിന് പിന്നാലെയുള്ള ആദ്യ `1`: actual visible drop 1 `1..M` domain flag;
- അവസാന രണ്ട് `1`: actual visible drop 1-ൽ നിന്ന് കണക്കാക്കിയ bowl-order rank `1..720` domain flag, factoradic digit-domain flag.

ഈ extension drop 1 value, rank, digits, order എന്നിവ hard-code ചെയ്യുന്നില്ല. visible generation-ൽ ലഭിച്ച actual value archive/replay വഴിയാണ് bowl-phase cursor-ലേക്ക് എത്തുന്നത്.

### `dynamic_order_circular_neighbors_probe.spl`

stdin fixture:

`3,1,6,2,5,4`

expected outputs:

`4,3,1,3,1,6,1,6,2,6,2,5,2,5,4,5,4,3`.

ഓരോ മൂന്ന് values-ും position `p=1..6`-ന്റെ `prevId,currentId,nextId` ആണ്. position 1-ന്റെ predecessor position 6 ആണ്; position 6-ന്റെ successor position 1 ആണ്. ഇത് subsequent dynamic six-bowl round-ൽ circular neighbor lookup-ന്റെ topology വേർതിരിച്ച് lock ചെയ്യുന്നു.

## progress 36 — legal initial bowls + direct pours, full position-stone bowl round

### `legal_initial_bowls_order316_pours_probe.spl`

stdin ഇല്ല. same-Foundation legal workCounts `1,1,1,2,2` ഉപയോഗിച്ച് six initial bowls exact formula-യിൽ കണക്കാക്കുന്നു. distinguishing order-prefix `3,1,6` ഉപയോഗിച്ച് row 1-ന്റെ `WHEAT=17`, `BARLEY=29`, `SALT=43`, `drop=1`, `i=1` എന്നിവയിൽ ആദ്യ മൂന്ന് direct pours കണക്കാക്കുന്നു. fixture values എല്ലാം `M`-ൽ താഴെയായതിനാൽ `SAVE` identity ആണ്.

expected outputs:

`87617,136163,289447,724205,944789,1907167,4920603,2540899,82008189`.

ആദ്യ ആറു values initial bowl IDs `1..6`; അവസാന മൂന്ന് values order positions `1..3`-ന്റെ direct pours ആണ്. ഇത് legal initial bowl state-നെ position-based pour semantics-ലേക്ക് same SPL source-ൽ ബന്ധിപ്പിക്കുന്നു.

### `full_bowl_round_position_stone_probe.spl`

stdin ഇല്ല. old snapshot bowl IDs `1..6 = 1,2,3,4,5,6`; order `3,1,6,2,5,4`; direct pours positions `1..3 = 7,11,13`; `drop=1`; `i=1`; position stone cycle `WHEAT,BARLEY,SALT,BITTER,RED,WHEAT = 17,29,43,71,101,17`.

ആറ് pending values എല്ലാം ഒരേ old snapshot മാത്രം വായിക്കുന്നു. positions `4..6`-ൽ direct pour `0` ആണ്. fixture no-wrap ആണ്; അതിനാൽ normative `SAVE` result raw positive result തന്നെയാണ്.

expected outputs bowl ID order `1..6`:

`4448,10355,1542,1762,15174,5054`.

ഈ fixture position stone selection, circular neighbors, first-three direct pours, `drop`, `i*position`, shared-old-snapshot ownership എന്നിവ ഒരുമിച്ച് lock ചെയ്യുന്നു.

## progress 37 — actual drop1 full order, legal initial bowls, actual first-three pours

### `sauce_foundation_actual_hidden_visible46_probe.spl` extension

stdin ഇല്ല. progress 35/36 integrated path-ന്റെ actual visible drop 1 bowl-rank factoradic digits ഇനി same source-ൽ full six-ID active-set removal വഴി materialize ചെയ്യുന്നു. selected IDs backward archive-ൽ സൂക്ഷിച്ച് reverse ചെയ്ത ശേഷം order positions 1..6 scalar state-ലേക്ക് load ചെയ്യുന്നു. materialization structural outputs:

`6,21,720,6`.

ക്രമം: selection count, selected-ID sum, selected-ID product, backward-selection archive -> forward-order replay reverse count. rank/order hard-code ചെയ്തിട്ടില്ല; actual generated visible drop 1-ൽ നിന്നുള്ള factoradic digits ആണ് consume ചെയ്യുന്നത്.

തുടർന്ന് same-Foundation legal workCounts fixture-ന്റെ ആറു initial bowls source-ൽ വീണ്ടും exact formula-യിൽ കണക്കാക്കുന്നു. expected bowl IDs `1..6`:

`87617,136163,289447,724205,944789,1907167`.

അതിനുശേഷം `M=2^127-1` source-ൽ പുനർനിർമ്മിച്ച് actual drop1 materialized order positions `1..3`-നായി old bowl value dynamic ID dispatch വഴി തിരഞ്ഞെടുക്കുന്നു. direct pours:

`pour1 = SAVE(drop1^2 + stones[1][WHEAT]  * old[order1] + 3)`

`pour2 = SAVE(drop1^2 + stones[1][BARLEY] * old[order2] + 5)`

`pour3 = SAVE(drop1^2 + stones[1][SALT]   * old[order3] + 7)`

എന്ന normative formulas source-ൽ actual generated drop1, row-1 stones `17,29,43`, legal old bowls എന്നിവ ഉപയോഗിച്ച് കണക്കാക്കുന്നു. exact pour numeric values hard-code ചെയ്യുന്നില്ല; ഓരോ SAVE result-ും `1..M` domain-ൽ ആണെന്ന് SPL control flag പരിശോധിക്കുന്നു. expected flags:

`1,1,1`.

അതുകൊണ്ട് integrated probe-ന്റെ പുതിയ full expected structural output sequence:

`46,7,46,47,46,1,1,6,21,720,6,17,29,43,71,101,1,1,1,6,21,720,6,87617,136163,289447,724205,944789,1907167,1,1,1`.

ഈ progress first actual six-bowl transactional commit ഇനിയും ചെയ്യുന്നില്ല. എന്നാൽ അതിന് വേണ്ട actual drop1 full order, legal old-bowl snapshot, row1 stones, drop1, three position-based pours എന്നിവ same integrated path-ൽ ഒരുമിച്ച് തയ്യാറാണ്.

## progress 38 — actual generated drop1 first transactional six-bowl commit

### `sauce_foundation_actual_hidden_visible46_probe.spl` extension

progress 37 വരെ same integrated source actual drop1 full order, legal initial six-bowl snapshot, actual row1 stones, actual drop1, first three direct pours എന്നിവ തയ്യാറാക്കിയിരുന്നു. ഈ progress-ൽ അതേ state ഉപയോഗിച്ച് first real bowl round പൂർത്തിയാക്കുന്നു.

ആദ്യം three direct pours വീണ്ടും exact `SAVE` formula-യിൽ കണക്കാക്കി scalar state-ൽ retain ചെയ്യുന്നു. actual order IDs positions `1..6` commit-target archive-ൽ സൂക്ഷിച്ചശേഷം ഓരോ position scalar-ും corresponding legal old-bowl value ആയി മാറ്റുന്നു. അതിനാൽ position state ഒരു immutable old snapshot representation ആകുന്നു; commit target IDs വേറിട്ട memory archive-ൽ സംരക്ഷിക്കപ്പെടുന്നു.

തുടർന്ന് positions `1..6`-ന് normative recurrence ഉപയോഗിക്കുന്നു:

`s = oldCurrent + 2*oldPrev + 3*oldNext + pour(position) + drop1 + stone(position)`

`pending = SAVE(s^2 + 5*oldPrev*oldNext + 1*position)`

stone cycle: `WHEAT,BARLEY,SALT,BITTER,RED,WHEAT`; pours positions `1..3`-ൽ മാത്രം. ആറു pending values-ും ആദ്യം Titania memory archive-ൽ സൂക്ഷിക്കുന്നു. old bowls ഒരൊന്നും pending generation സമയത്ത് mutate ചെയ്യുന്നില്ല.

എല്ലാ ആറു pending values-ും തയ്യാറായതിന് ശേഷം മാത്രം archived bowl ID + matching pending pair pop ചെയ്ത് bowl ID `1..6`-ലേക്ക് commit ചെയ്യുന്നു. commit order reverse-position ആയാലും semantics ബാധിക്കില്ല, കാരണം pending phase മുഴുവൻ പൂർത്തിയായ ശേഷമാണ് mutation തുടങ്ങുന്നത്.

പുതിയ expected suffix:

`6,1,1,1,1,1,1`

ആദ്യ `6` transactional commit count; പിന്നാലെയുള്ള ആറു `1` values committed bowl IDs `1..6` എല്ലാം `1..M` SAVE domain-ൽ തന്നെയാണെന്ന flags.

അതുകൊണ്ട് integrated probe-ന്റെ full expected structural output sequence ഇപ്പോൾ:

`46,7,46,47,46,1,1,6,21,720,6,17,29,43,71,101,1,1,1,6,21,720,6,87617,136163,289447,724205,944789,1907167,1,1,1,6,1,1,1,1,1,1`.

ഈ progress first actual generated-drop bowl commit same sauce path-ൽ പൂർത്തിയാക്കുന്നു. drops `2..46`-ന്റെ bowl rounds ഇനിയും same machinery loop-ൽ ചേർത്തിട്ടില്ല.

## progress 39 — retained actual drops 2..46 rank/factoradic scan

### `sauce_foundation_actual_hidden_visible46_probe.spl` extension

progress 38-ൽ actual generated drop1 first transactional six-bowl commit പൂർത്തിയായതിന് ശേഷം bowl state മാറ്റാതെ retained visible-drop forward replay-ന്റെ ശേഷിക്കുന്ന values `drop2..drop46` ഇപ്പോൾ consume ചെയ്യുന്നു.

ഓരോ retained actual drop-നും source exact ആയി:

1. `rank = 1 + regularMod(drop - 1, 720)`;
2. zero-based residual `rank-1`;
3. factoradic blocks `120,24,6,2,1`;
4. digits domain `0..5,0..4,0..3,0..2,0..1,0`;
5. rank domain `1..720`.

Drop 1 ഇതിനുമുമ്പ് same integrated path-ൽ factoradic decomposition ചെയ്തതിനാൽ processed counter `1`-ൽ ആരംഭിക്കുന്നു; retained replay-ൽ `2..46` consume ചെയ്ത ശേഷം structural suffix കൃത്യമായി:

`46,47,1,1`

അർത്ഥം:

- `46` — actual drops 1..46 factoradic coverage count;
- `47` — next scan index;
- `1` — final actual drop46 rank-domain flag;
- `1` — final actual drop46 factoradic-domain flag.

ഈ extension committed six-bowl state overwrite ചെയ്യുന്നില്ല. full six-ID materialization/pours/transactional bowl commit ഇനിയും drop1-ൽ മാത്രം integrated ആണ്; drops 2..46-ൽ ഈ progress rank/factoradic coverage മാത്രം ചേർക്കുന്നു.

integrated probe-ന്റെ full expected structural output sequence ഇപ്പോൾ:

`46,7,46,47,46,1,1,6,21,720,6,17,29,43,71,101,1,1,1,6,21,720,6,87617,136163,289447,724205,944789,1907167,1,1,1,6,1,1,1,1,1,1,46,47,1,1`.

## progress 40 — dedicated drop46 full-order latch + preserved actual drops 2..46 replay

### `sauce_foundation_actual_hidden_visible46_probe.spl` extension

progress 39-ലെ all-46 actual rank/factoradic scan ഇപ്പോൾ രണ്ട് state-ownership guarantees കൂടി same integrated source-ൽ നൽകുന്നു.

1. actual drop46 full six-ID materialization സമയത്ത് ഓരോ selected ID-യും working order archive-ിനൊപ്പം വേറൊരു dedicated backward latch archive-ലും copy ചെയ്യുന്നു. പിന്നീട് drop1 bowl round, first transactional commit, drops 2..46 rank/factoradic scan എന്നിവ നടന്നിട്ടും latch archive touch ചെയ്യില്ല. scan completion-ൽ latch forward order-ലേക്ക് reverse ചെയ്യുന്നു; order itself hard-code ചെയ്യാതെ structural permutation invariants മാത്രം output ചെയ്യുന്നു:

`6,21,720`

ക്രമം: latched ID count, sum, product. അതിനാൽ dedicated latch exactly six distinct IDs `1..6` ഉൾക്കൊള്ളുന്ന permutation ആണെന്ന് source-level witness ലഭിക്കുന്നു. forward latched order Juliet memory-ൽ next post-stir/askBowl integration-നായി intact ആയി നിൽക്കുന്നു.

2. drops `2..46` rank/factoradic scan ചെയ്യുമ്പോൾ ഓരോ actual generated drop-ും Hamlet memory-യിലെ വേറൊരു backward archive-ലേക്ക് preserve ചെയ്യുന്നു. scan completion-ൽ 45 values Romeo forward replay-ലേക്ക് reverse ചെയ്യുന്നു. expected replay count:

`45`.

അതിനാൽ integrated probe-ന്റെ full expected structural output sequence ഇപ്പോൾ:

`46,7,46,47,46,1,1,6,21,720,6,17,29,43,71,101,1,1,1,6,21,720,6,87617,136163,289447,724205,944789,1907167,1,1,1,6,1,1,1,1,1,1,46,47,1,1,6,21,720,45`.

ഈ progress drops 2..46 full six-ID materialization/pours/bowl commits ഇനിയും ചെയ്യുന്നില്ല; പക്ഷേ actual drop replay വീണ്ടും ലഭ്യമാക്കുകയും drop46 full order dedicated latch ആയി bowl/post-stir phase-ുകളിൽ നിന്ന് സ്വതന്ത്രമായി നിലനിർത്തുകയും ചെയ്യുന്നു.

### `drop46_full_order_latch_probe.spl`

stdin fixture:

`3,1,6,2,5,4,1,2,3,4,5,6,7,8,9,10,11,12`

ആദ്യ ആറു values drop46 full order latch ആണ്; പിന്നാലെയുള്ള പന്ത്രണ്ട് values post-stir diagnostic ranks ആണ്. diagnostic reads latch characters ഒന്നും overwrite ചെയ്യില്ല.

expected outputs:

`3,1,6,2,5,4,12`.

ഇത് rank-only latch probe-നെ full six-ID order latch വരെ ശക്തിപ്പെടുത്തുന്നു.

## progress 41 — preserved actual drops 2..46 full six-ID materialization

### `sauce_foundation_actual_hidden_visible46_probe.spl` extension

progress 40-ൽ ലഭ്യമായ 45-value actual-drop forward replay ഇപ്പോൾ വീണ്ടും consume ചെയ്യുന്നു. ഓരോ actual drop `2..46`-നും source path തന്നെ:

`drop -> one-based rank 1..720 -> factoradic digits 120/24/6/2/1 -> generic six-ID active-set removal`

നടത്തുന്നു.

ഈ generic materializer committed bowl-state scalars (`Miranda`, `Lady Macbeth`, `Beatrice`, `Benedick`, `Desdemona`, `Portia`) active flags ആയി ഉപയോഗിക്കുന്നില്ല; അതിനാൽ progress 38-ൽ commit ചെയ്ത first-round bowl state ഈ all-45 order pass മാറ്റുന്നില്ല. active-set scalar ownership വേറിട്ട characters-ലാണ്.

ഓരോ materialized order-നും source control നിർബന്ധമായി പരിശോധിക്കുന്നത്:

- selected count = `6`;
- selected ID sum = `21`;
- selected ID product = `720`.

ഈ മൂന്ന് invariants satisfy ചെയ്തതിന് ശേഷം മാത്രമേ remaining count decrement ചെയ്യൂ. selected-order temporary archive ഓരോ round-നും ആറു pop വഴി clear ചെയ്യുന്നു. actual drop value Hamlet backward archive-ലേക്ക് preserve ചെയ്യുന്നു; 45 rounds പൂർത്തിയായ ശേഷം അത് വീണ്ടും Romeo forward replay-ലേക്ക് reverse ചെയ്യുന്നു.

progress 41 ചേർക്കുന്ന structural suffix:

`0,45`

ക്രമം:

- `0` — valid full-order materialization loop കഴിഞ്ഞ ശേഷിക്കുന്ന actual drops;
- `45` — വീണ്ടും rebuild ചെയ്ത drops `2..46` forward replay count.

അതുകൊണ്ട് integrated probe-ന്റെ full expected structural output sequence ഇപ്പോൾ:

`46,7,46,47,46,1,1,6,21,720,6,17,29,43,71,101,1,1,1,6,21,720,6,87617,136163,289447,724205,944789,1907167,1,1,1,6,1,1,1,1,1,1,46,47,1,1,6,21,720,45,0,45`.

ഈ progress generic full-order coverage എല്ലാ actual drops-ലേക്കും ഉയർത്തുന്നു. drops `2..46`-ന്റെ position pours, circular-neighbor bowl formulas, six pending values, transactional commits എന്നിവ അടുത്ത integration bridge ആണ്; dedicated drop46 latch Juliet memory-ൽ മാറ്റമില്ലാതെ തുടരുന്നു.

## progress 42 — bowl-phase archive ownership separation + 270-ID order replay

### `sauce_foundation_actual_hidden_visible46_probe.spl` ownership correction and extension

progress 40/41-ൽ future bowl phase-നായി ഉപയോഗിച്ചിരുന്ന രണ്ട് memory choices semantic ownership açısından അപര്യാപ്തമാണെന്ന് audit-ൽ കണ്ടെത്തി:

- dedicated drop46 forward latch `Juliet` memory-ൽ വച്ചാൽ, അതേ memory-ൽ ശേഷിച്ച barley stone rows `2..46`-ന്റെ forward replay-നൊപ്പം stack intermix ഉണ്ടാകുന്നു;
- drops `2..46` forward replay `Romeo` memory-ൽ വച്ചാൽ, അതേ memory-ൽ ശേഷിച്ച salt stone rows `2..46`-ന്റെ forward replay-നൊപ്പം stack intermix ഉണ്ടാകുന്നു.

ഇത് historical patch അല്ല; Stage 1 clean oracle-ന്റെ incomplete ownership model തിരുത്തലാണ്. progress 42 മുതൽ owners വേർതിരിച്ചിരിക്കുന്നു:

- `Hamlet/Juliet/Romeo/Othello/Macbeth` memories — stones rows `2..46` മാത്രം;
- `Caliban` memory — actual drops `2..46` forward replay മാത്രം;
- `Antony` memory — dedicated drop46 six-ID forward latch മാത്രം;
- `Cleopatra` memory — drops `2..46` materialization സമയത്തെ 45 full orders-ന്റെ backward archive;
- `Brutus` memory — completion-ൽ 45 x 6 = `270` IDs ഉള്ള forward order replay.

ഓരോ current full order Helena memory-ൽ selection order-ൽ push ചെയ്തതിനാൽ newest-first pop `position6..position1` ആണ്. progress 42 ആദ്യം ആ ആറു IDs `Brutus` temporary memory-ലേക്ക് reverse ചെയ്യുന്നു; പിന്നെ `Brutus`-ൽ നിന്ന് `position1..position6` ആയി pop ചെയ്ത് `Cleopatra` global backward archive-ലേക്ക് push ചെയ്യുന്നു. 45 orders പൂർത്തിയായ ശേഷം മുഴുവൻ `Cleopatra` archive `Brutus`-ലേക്ക് reverse ചെയ്യുമ്പോൾ future pop sequence കൃത്യമായി:

`drop2 position1..6, drop3 position1..6, ... drop46 position1..6`.

അതോടൊപ്പം drops `2..46` rank/materialization pass-ൽ `Shylock` backward archive-ൽ preserve ചെയ്ത് completion-ൽ `Caliban` dedicated forward replay-ലേക്ക് മടക്കുന്നു; അതിനാൽ salt stone replay ഇനി drop values കൊണ്ട് മലിനമാകുന്നില്ല.

progress 42 ചേർക്കുന്ന structural suffix:

`270`

അതിനാൽ integrated probe-ന്റെ full expected structural output sequence ഇപ്പോൾ:

`46,7,46,47,46,1,1,6,21,720,6,17,29,43,71,101,1,1,1,6,21,720,6,87617,136163,289447,724205,944789,1907167,1,1,1,6,1,1,1,1,1,1,46,47,1,1,6,21,720,45,0,45,270`.

### `bowl_phase_separated_replay_probe.spl`

separate-owner stack witness. forward replays intentionally വേറിട്ട memory owners-ൽ സ്ഥാപിക്കുന്നു:

- two wheat/barley/salt/bitter/red rows;
- one future drop;
- one six-ID full order;
- one independent drop46 latch.

expected outputs:

`2,3,4,5,6,12,1,2,3,4,5,6,3,1,6,2,5,4,7,8,9,10,11`.

ആദ്യ അഞ്ച് outputs row2 stones, `12` drop2, അടുത്ത ആറു order2, അടുത്ത ആറു dedicated latch, അവസാന അഞ്ച് row3 stones. drop/order/latch reads കഴിഞ്ഞിട്ടും അഞ്ചു stone memories-ൽ row3 untouched ആയി തുടരുന്നതാണ് ഈ witness lock ചെയ്യുന്നത്.

## progress 43 — drops 2..46 full transactional six-bowl loop

### `sauce_foundation_actual_hidden_visible46_probe.spl` extension

progress 42-ൽ വേർതിരിച്ച state ഇനി actual bowl recurrence-ലേക്ക് നേരിട്ട് consume ചെയ്യുന്നു. ഓരോ `i=2..46` round-ലും source കൃത്യമായി:

1. അഞ്ച് stone replay values, actual drop, ആറു order IDs എന്നിവ load ചെയ്യുന്നു;
2. ആറു order IDs Helena memory-ൽ commit-target archive ആയി സൂക്ഷിക്കുന്നു;
3. committed six-bowl state-ൽ നിന്ന് order positions 1..6-ന്റെ old values ആറു position scalars-ലേക്ക് copy ചെയ്യുന്നു; ഈ copy കഴിഞ്ഞ് pending-complete വരെ committed bowl scalar ഒന്നും mutate ചെയ്യുന്നില്ല;
4. position 1..3-ക്ക് മാത്രം WHEAT/BARLEY/SALT direct pours `SAVE` സഹിതം കണക്കാക്കുന്നു;
5. position 1..6-ൽ circular prev/current/next values ഒരേ immutable old-position snapshot-ൽ നിന്ന് വായിച്ച് six pending values നിർമ്മിക്കുന്നു;
6. ഓരോ pending value-വും `SAVE(s² + 5*oldPrev*oldNext + i*position)` ആയി Titania memory-ൽ സൂക്ഷിക്കുന്നു;
7. pending counter കൃത്യമായി `6` ആയതിന് ശേഷം മാത്രം archived bowl ID + matching pending pair newest-first pop ചെയ്ത് six committed bowl scalars transactional ആയി update ചെയ്യുന്നു;
8. commit പൂർത്തിയായ ശേഷം മാത്രം index increment ചെയ്ത് അടുത്ത round-ലേക്ക് പോകുന്നു.

position stone cycle source-ൽ `WHEAT,BARLEY,SALT,BITTER,RED,WHEAT` ആണ്. direct pours source-ൽ `+3*i`, `+5*i`, `+7*i`; final six pending position terms യഥാക്രമം `i*1` മുതൽ `i*6` വരെ ആണ്.

`Antony` dedicated drop46 six-ID latch ഈ extension-ന്റെ executable path-ൽ പ്രവേശിക്കുന്നില്ല; അതിനാൽ drops 2..46 bowl loop അതിനെ mutate ചെയ്യുന്നില്ല.

progress 43 ചേർക്കുന്ന structural suffix:

`45,47,1,1,1,1,1,1`

ക്രമം:

- `45` — committed rounds 2..46 count;
- `47` — completion കഴിഞ്ഞ next drop index;
- അവസാന ആറു `1` — final committed bowls ഓരോന്നും normative SAVE domain `1..M`-ൽ ഉള്ളതായി source controls.

integrated probe-ന്റെ full expected structural output sequence ഇപ്പോൾ:

`46,7,46,47,46,1,1,6,21,720,6,17,29,43,71,101,1,1,1,6,21,720,6,87617,136163,289447,724205,944789,1907167,1,1,1,6,1,1,1,1,1,1,46,47,1,1,6,21,720,45,0,45,270,45,47,1,1,1,1,1,1`.

ഈ expected sequence runtime observation അല്ല; compliant local SPL runtime ലഭ്യമല്ലാത്തതിനാൽ ഇത് source-level structural expectation ആണ്. Stage 1 runtime GREEN ഇനിയും അവകാശപ്പെടുന്നില്ല.

## progress 44 — 12 normative post-stirs integrated

### `sauce_foundation_actual_hidden_visible46_probe.spl` extension

progress 43-ന്റെ committed bowls-ൽ നിന്ന് Appendix A Interpretation 1A post-stir recurrence same integrated clean-oracle path-ൽ exact `12` rounds ആയി ചേർക്കുന്നു.

ഓരോ stir `1..12`-ലും source sequence:

1. six committed bowls mutate ചെയ്യുന്നതിന് മുമ്പ് `savedBowlSum = SAVE(sum(oldBowls)+149*stir)` ഒരിക്കൽ മാത്രം കണക്കാക്കുന്നു;
2. `regularMod(savedBowlSum-1,720)+1`-ന്റെ factoradic digits blocks `120,24,6,2,1` ഉപയോഗിച്ച് source-ൽ തന്നെ നിർമ്മിക്കുന്നു;
3. six-ID active-set removal വഴി current stir order materialize ചെയ്ത് `count=6,sum=21,product=720` validate ചെയ്യുന്നു;
4. current six committed bowls ആ order-ന്റെ positions 1..6-ലേക്ക് immutable old-position snapshot ആയി copy ചെയ്യുന്നു;
5. position `p`-ൽ `s = oldCurrent + 3*oldPrev + 5*oldNext + savedBowlSum + stir + p^2` കണക്കാക്കുന്നു;
6. pending value `SAVE(s^2 + 7*oldPrev*oldNext)` ആയി Brutus memory-ൽ position order-ൽ archive ചെയ്യുന്നു;
7. six pending values complete ആയതിന് ശേഷം മാത്രം matching Helena order IDs + Brutus pending values newest-first pairwise pop ചെയ്ത് six committed bowls transactional ആയി update ചെയ്യുന്നു;
8. commit കഴിഞ്ഞ് മാത്രം completed-stir counter increment ചെയ്യുന്നു; `12` എത്തിയാൽ loop അവസാനിക്കുന്നു, അല്ലെങ്കിൽ stir number increment ചെയ്ത് അടുത്ത fresh snapshot round ആരംഭിക്കുന്നു.

`Caliban`-ലെ savedBowlSum current stir മുഴുവൻ immutable ആണ്. `Shylock`-ലെ `M = 2^127-1` post-stir arithmetic-ൽ overwrite ചെയ്യുന്നില്ല. `Antony` dedicated actual-drop46 six-ID latch പുതിയ executable segment-ൽ read/write ചെയ്യുന്നില്ല.

progress 44 structural suffix:

`12,13,1,1,1,1,1,1`

ക്രമം:

- `12` — committed post-stir rounds count;
- `13` — completion കഴിഞ്ഞ next-stir sentinel;
- അവസാന ആറു `1` — 12th commit കഴിഞ്ഞ six final bowls ഓരോന്നും SAVE domain `1..M`-ൽ ഉള്ളതായി source controls.

integrated probe-ന്റെ full expected structural output sequence ഇപ്പോൾ:

`46,7,46,47,46,1,1,6,21,720,6,17,29,43,71,101,1,1,1,6,21,720,6,87617,136163,289447,724205,944789,1907167,1,1,1,6,1,1,1,1,1,1,46,47,1,1,6,21,720,45,0,45,270,45,47,1,1,1,1,1,1,12,13,1,1,1,1,1,1`.

ഇത് source-level structural expectation മാത്രം ആണ്. compliant SPL runtime ലഭ്യമല്ലാത്തതിനാൽ runtime observation/PASS/GREEN ആയി കണക്കാക്കരുത്.

## progress 45 — SauceResult / askBowl / exact short+wide selection integrated

### `sauce_foundation_actual_hidden_visible46_probe.spl` extension

progress 44-ന്റെ final six committed bowls + dedicated actual-drop46 `Antony` latch same integrated clean-oracle path-ൽ SauceResult semantics ആയി ബന്ധിപ്പിച്ചു.

1. `Antony` forward latch six IDs pop ചെയ്ത് six position scalars-ലേക്ക് copy ചെയ്യുന്നു; same IDs temporary reverse archive വഴി `Antony`-ലേക്ക് original forward order-ൽ restore ചെയ്യുന്നു.
2. restored/materialized order structural invariants: `6,21,720`.
3. `nextBowlInDrop46Order` queried ID six positions-ൽ കണ്ടെത്തി next position return ചെയ്യുന്നു; sixth position explicit first-position wrap ഉപയോഗിക്കുന്നു.
4. first integrated query `q=1`, `seal=1`; final committed bowl values ID dispatch വഴി resolve ചെയ്യുന്നു.
5. `first = SAVE((bowl[q]+seal+181)^2 + 179*bowl[next] + seal)`.
6. `directionNumber = SAVE((first+seal+1+193)^2 + 193*first + 197*bowl[6])`.
7. parity once-only fixed `directionStep` `+1/-1` ആക്കുന്നു.
8. same stream-ൽ `N=922` short selection exact acceptanceLimit + same-ring rejection loop ഉപയോഗിക്കുന്നു.
9. same stream-ൽ wide boundary `N=M+1` `smallestPowerCount` വഴി `k=2`, `space=M^2` ആക്കി two digits നിർമ്മിക്കുന്നു; rejection wide number-നെ തന്നെ signed Euclidean wide ring-ൽ advance ചെയ്യുന്നു, digits പുതുതായി ചോദിക്കുന്നില്ല.

progress 45 structural suffix:

`6,21,720,1,1,1,1,1,1,922,1,1,2,1,1`

full expected structural output sequence:

`46,7,46,47,46,1,1,6,21,720,6,17,29,43,71,101,1,1,1,6,21,720,6,87617,136163,289447,724205,944789,1907167,1,1,1,6,1,1,1,1,1,1,46,47,1,1,6,21,720,45,0,45,270,45,47,1,1,1,1,1,1,12,13,1,1,1,1,1,1,6,21,720,1,1,1,1,1,1,922,1,1,2,1,1`.

ഇത് source-level expectation മാത്രം ആണ്; compliant SPL runtime observation അല്ല.

അടുത്ത blocker signed lazy gates-നായി arbitrary target-day sauce orchestration ആണ്.
