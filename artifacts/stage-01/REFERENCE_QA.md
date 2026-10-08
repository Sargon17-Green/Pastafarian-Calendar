# Test-only reference — учурдагы QA

Күн: 2026-10-07

## Камтуу

Азыр ишке ашкан reference бөлүктөрү:

- Appendix A §1 — негизги туруктуулар;
- Appendix A §2 — `SAVE`;
- Appendix A §3 — `dayCount`;
- Appendix A §3 — `workCounts`;
- Appendix A §4 — `buildStones`;
- Appendix A §5 — жети hidden drop;
- Appendix A §6 — 46 visible drop;
- Appendix A §7 — bowl order;
- Appendix A §8.1 — initial bowls;
- Appendix A §8.2 — 46 visible drop'ту каякка куюу жана bowl update;
- Appendix A §9 — 12 post-stir;
- Appendix A §11 — askBowl жана answerAt;
- Appendix A §12 — short/wide selection primitives;
- Appendix A §13.1 — falling factorial жана distinct-name unrank;
- Appendix A §13.2 — bounded composition count/unrank;
- Appendix A §14.1 — SauceResult'тан gate gap.

## workCounts эсептик текшерүүсү

`reference/work_counts.b98` өз алдынча Befunge Funge-space/stack модели менен Appendix Aдагы түз математикалык аныктамага салыштырылды.

Текшерилген calculation/target күндөрү төмөнкү топтомдун декарттык көбөйтмөсүнөн алынды:

- `-25..25`;
- `FOUNDATION_DAY-2 .. FOUNDATION_DAY+2`;
- `0`, `1`;
- `±10^20`;
- `±10^50`.

Жалпы: **3 844 жуп**.

Натыйжа:

```text
DIFFERENCES=0
```

Текшерилген беш талаа:

- action;
- target;
- distance;
- connection;
- direction.

Бул native Befunge PASS эмес; ал коддун stack/Funge-space логикасын Appendix A формуласынан көз карандысыз эсептик модель менен текшерген статикалык/симуляциялык QA.


## buildStones эсептик текшерүүсү

`reference/build_stones.b98` loop менен 46 × 5 = **230** таш маанисин чыгарат.

Appendix Aдагы беш simultaneous-update формуласы менен өз алдынча эсептик салыштыруу жасалды.

Натыйжа:

```text
ROWS=46
VALUES=230
DIFFERENCES=0
```

Биринчи эки сап:

```text
17 29 43 71 101
378 1073 2375 6195 10493
```

46-сап:

```text
73799454308499791987382386781055001470
147925408106533232424672641008220632365
94499522601819303005579577099149028685
108473647672201258090947028490673028834
137131922036975206684616468948804344042
```

`build_stones.b98` кийинки беш маанини pending scratch'та толук эсептеп бүткөндөн кийин гана current scratch'ка көчүрөт; ошондуктан бир эле iteration ичинде жаңы таш башка жаңы таштын input'уна айланбайт.


## Hidden drops эсептик текшерүүсү

`reference/hidden_drops.b98` беш `WorkCounts` маанисин input катары алып, Appendix Aдагы коэффициенттер жана 7 grind формуласы менен жети hidden drop чыгарат.

Төмөнкү түрдүү counts топтомдору түз математикалык reference менен салыштырылды:

- `1 1 1 2 2`;
- `30111343 30111343 1 60222686 2`;
- `2 3 2 5 3`;
- чоң (10^20) масштабындагы counts;
- (M) масштабындагы counts.

Ар бир топтомдо жети маанинин баары дал келди: `DIFFERENCES=0`.


## Кошумча reference QA

- `bowl_order.b98`: 1..720 рангдын **баары** текшерилди; айырма 0.
- `ask_bowl.b98`: 500 permutation/query комбинациясы; айырма 0.
- `answer_at.b98` жандуу helper'инде `directionStep=-1` wrap катасы табылып, бир өлчөмдүү так версия менен оңдолду; `smallest_power_count.b98` эски 2D layout'унда Lahey-space self-wrap болгон жана ал да бир өлчөмдүү версия менен оңдолду. Бул эки оңдоо `f65ad9ca4725068cb2b4171c00b74d852eab30fb` коммитинде. `choose_rank_short.b98`, `choose_rank_wide.b98` жана бирдиктүү `choose_rank.b98` Appendix Aдагы `directionStep=+1/-1` менен текшерилди.
- `choose_rank.b98`: short+wide бирдиктүү dispatcher 199 аткарылуучу чек/кабыл алуу/rejection учурларында текшерилди; айырма 0. Мыйзамсыз directionStep жана N=0 → `-1`.
- `count_bounded_compositions.b98`: total 0..14, slots 0..4 жана чакан lo/hi комбинациялары толук текшерилди; айырма 0.
- `unrank_bounded_composition.b98`: чакан үй-бүлөлөрдүн бардык текшерилген жарактуу рангы лексикографиялык explicit enumeration менен салыштырылды. §13 live helpers үчүн кошумча reconciliation өтүүсүндө `unrankDistinctNames`, bounded count жана bounded unrank боюнча 4 841 аткарылуучу чакан/exhaustive учур текшерилди; айырма 0.
- `gate_gap_from_sauce.b98`: 4 чек жана 20 кошумча күн жуптарынан алынган SauceResult менен текшерилди; ар бир жыйынтык 42..963 жана Appendix A менен дал келди.

Булардын баары native Befunge аткаруунун ордун баспайт.


## Gate walk жана year-pair QA

- `gate_walk.b98`: positive жана negative gate index үчүн жүздөгөн 42..963 gap тизмелери түз Appendix A accumulation менен салыштырылды; айырма 0.
- sign `0/1` эмес, negative-zero index жана 42ден аз/963төн чоң gap → `-1`.
- `valid_year_pair.b98`: gate-gap count кеминде 6 жана length 252..5778 болгондо гана `1`; 251, 5779 жана 5 gap четтери четке кагылат.


## Sauce composition QA

`reference/sauce.b98` §3–§10 чынжырын бир test-only Befunge программасында түз аткарат. Киргизүү: `calculationDay` жана `targetDay` үчүн эки канондук `sign magnitude` жуп. Чыгыш: алты final bowl жана `orderAtDrop46` алты идентификатору.

QAнын ушул өтүүсүндө жандуу бутактагы integrated файл кайра түз аткарылып текшерилди. Equal-day учурлары туура болгон, бирок calculation жана target ар башка болгондо реалдуу regression табылды: integrated `sauce.b98` direction count'ту тескери эсептеген.

Ката формула:

```text
direction = 2 + (calculation > target) - (target > calculation)
```

Appendix A талап кылган формула:

```text
direction = 2 + (target > calculation) - (calculation > target)
```

Бул regression модулдук `work_counts.b98` файлында болгон эмес; ал integrated sauce composition'до гана болгон. Ошондой эле `hidden_drops.b98`, `visible_drops.b98`, `initial_bowls.b98`, `apply_visible_to_bowls.b98` жана `post_stir_12.b98` өз алдынча түз Appendix A моделине дал келди.

Direction формуласы бир жерде оңдолду. Оңдоодон кийинки жандуу `sauce.b98` төмөнкү беш day-pair менен толук §3–§10 direct model'ге салыштырылды:

- Foundation / Foundation;
- Foundation−1 / Foundation+1;
- 0 / 0;
- 123456789 / −987654321;
- −10^20 / +10^20.

Ар бир учурда 12 чыгуучу талаанын баары дал келди.

```text
POST_FIX_CASES=5
OUTPUT_FIELDS_PER_CASE=12
POST_FIX_DIFFERENCES=0
PATCH_COMMIT=0e84017313de808d25b462cc44221274e71b2c5b
```

Мурдагы candidate QA сандары жандуу файл үчүн жетиштүү далил катары эсептелбейт; ушул бөлүктөгү post-fix direct execution азыркы authoritative QA болуп саналат.

`1 0` negative zero жана мыйзамсыз sign сыяктуу канондук эмес киргизүү `-1` менен четке кагылат.

Бул native Befunge PASS эмес.

## Cutlet partition QA

`binomial.b98`, `count_cutlet_partitions.b98`, `valid_cutlet_partition.b98` жана `unrank_cutlet_partition.b98` Appendix A §17.2ни жабат.

Эквиваленттүү комбинатордук эсеп:

- required boundary жок: `C(G-1,K-1)`;
- белгилүү internal boundary милдеттүү: `C(G-2,K-2)`.

Бул формула тартипти өзгөртпөйт; unrank explicit lexicographic family менен текшерилди.

```text
EXHAUSTIVE_G_MAX=10
EXHAUSTIVE_K_MAX=5
ALL_INTERNAL_BOUNDARIES=YES
ALL_VALID_RANKS=YES
DIFFERENCES=0
```

## Month weaving DP QA

`count_weavings.b98` жана `unrank_weaving.b98` §19дагы remaining-векторду mixed-radix бүтүн ачкычка коддоп, memoized DFS колдонот.

Төмөнкү үй-бүлөлөр explicit lexicographic enumeration менен салыштырылды:
`[1]`, `[2]`, `[2,2]`, `[3,2]`, `[2,2,1]`, `[2,2,2]`, `[3,2,2]`, `[3,3,2]`.

`[3,3,2]` үчүн 26/26 rank так дал келди; мыйзамсыз rank четке кагылат. Count үчүн кошумча `[3,3,3]=71`, `[4,3,2]=50` сыяктуу учурлар да текшерилди.


## Gate lookup жана year selector QA

`gate_lookup.b98` covered, strictly increasing gate vector үчүн `atOrBefore`, `atOrAfter` жана `exact` жыйынтыктарын берет. Appendix A бинардык издөө ыкмасын нормативдик деп эсептебегендиктен, бул reference монотондуу сызыктуу издөө колдонот.

```text
GATE_LOOKUP_CASES=1000
DIFFERENCES=0
```

`year5000_from_gates_rank.b98` rank алдын ала берилген учурда бардык жарактуу `i<j` жуптарын Appendix A шарттары боюнча тандайт: кеминде 6 gate gap, 252..5778 күн жана `gate[i] < calculationDay <= gate[j]`. Сорт тартиби length ascending, андан кийин opening gate ascending. 21-gate негизги вектордо биринчи/ортодогу/акыркы rank жана кошумча 167 чакан вектордук учур текшерилди; айырма 0.

`adjacent_year_from_gates_rank.b98` next/previous жыл үчүн белгилүү чекке жанаша талапкерлерди year-length ascending тартибинде тандайт. 487 rank/transition учуру, анын ичинде терс year/index маанилери текшерилди; айырма 0.

`find_target_year_from_gates_ranks.b98` target жылга **жыл сайын гана** өтөт. `target>close` болгондо next, `target<=open` болгондо previous; акыркы invariant `open < target <= close`. 97 көп-өтмөлүү сценарийде түз model менен дал келди. Opening gate өзү мурунку жылга таандык экени атайын текшерилди.

Бул төрт файл rank'ты өздөрү Sauce аркылуу чыгарбайт. Ошондуктан §14–§16 deterministic vector/rank катмары жабылды, бирок Sauce→askBowl→chooseRank orchestration али OPEN.


## §22 five-field tuple QA

`reference/final_five_fields_from_structure.b98` алдын ала тандалган YearStructure'дун канондук компоненттеринен так беш талааны чыгарат:

1. year number;
2. cutlet canonicalIndex;
3. dayInCutlet;
4. month canonicalIndex;
5. dayInMonth.

Input келишими YearStructure'га жакын: signed year үчүн `sign magnitude`, target'тын 1-based year offset'и, cutlet length массиви, cutlet-name массиви, month-name массиви жана weaving.

Текшерүүдө:

- 1 000 детерминисттик жарактуу кокустук структура;
- оң жана терс year number;
- биринчи жана акыркы cutlet күндөрү;
- month occurrence'тери үзүлүп жайгашкан weaving;
- мыйзамсыз sign;
- canonical эмес `1 0`;
- year offset 0 жана year length'тен чоң offset

камтылды.

```text
RANDOM_VALID_STRUCTURES=1000
DIFFERENCES=0
OUTPUT_FIELDS=5
```

`dayInMonth` calendar offset эмес: target позициясына чейин ошол monthId канча жолу кездешкенин **target күнүн кошуп** санайт.

QA учурунда түзүлгөн альтернативдүү interleaved serialization adapter негизги reference менен семантикалык жактан ашыкча болгондуктан репозиторийден кайра алынды. §22 үчүн жалгыз authoritative structure-to-five-fields helper — `final_five_fields_from_structure.b98`.

Бул helper `findTargetYear` же `buildYearStructure` аткарбайт. Ошондуктан толук §22 orchestration али OPEN.

## Days→Sauce→rank reconciliation QA

`rank_from_days.b98` төрт signed-day токенин жана `bowl, seal, N` параметрлерин кабыл алып, интеграцияланган Sauce→askBowl→chooseRank жыйынтыгын чыгарат.

Ал өз алдынча композиция менен салыштырылды:

```text
rank_from_sauce(sauce(calculationDay,targetDay), bowl, seal, N)
```

Камтуу:

- 8 day-pair: Foundation тегереги, Foundation'ду кесип өтүү, 0, оң/терс чоң күндөр жана өтө чоң magnitudes;
- ар бир day-pair үчүн 11 канондук суроо түрү;
- seals 1, 10, 11, 12, 20, 21, 22, 30, 31, 32, 33;
- short selection жана `N=M+1` wide selection.

```text
DAY_PAIRS=8
QUERY_TYPES_PER_PAIR=11
RANK_COMPARISONS=88
DIFFERENCES=0
```

`gate_gap_from_days.b98` ошол эле 8 day-pair үчүн `41 + rank_from_days(..., bowl=1, seal=1, N=922)` менен салыштырылды:

```text
GATE_GAP_COMPARISONS=8
DIFFERENCES=0
```

## Structure-rank orchestration QA

`structure_ranks_from_sauce.b98` бир эле SauceResult'ту жети structure суроосу үчүн кайра колдонот. Канондук `(bowl,seal)` жуптары:

```text
cutlet count      2,20
cutlet partition  2,21
cutlet names      5,22
month count       3,30
month lengths     3,31
month weaving     4,32
month names       5,33
```

250 детерминисттик SauceResult/family-size векторунун ар бири жети өз алдынча `rank_from_sauce` чакыруусу менен салыштырылды.

```text
SAUCE_RESULTS=250
QUESTIONS_PER_RESULT=7
RANK_COMPARISONS=1750
DIFFERENCES=0
```

Бул далил §17–§20 суроолорунун **бир эле structureSauce** колдонуу талабын rank деңгээлинде бекемдейт. Family unrank/materialization жана YearStructure интеграциясы өзүнчө катмар бойдон калат.

## Cutlet materialization QA

`materialize_cutlet_lengths.b98` gate аралыктарынын күндүк узундуктарын жана partition'дун gate-gap бөлүктөрүн алып, ар бир котлетанын күндүк узундугун чыгарат.

Бул `firstDay = gate[open]+1`, `lastDay = gate[close]` формуласын year-relative узундукка так кыскартат: бир котлетанын күн саны — ошол partition бөлүгүнө кирген ырааттуу gate-gap күндөрүнүн суммасы.

```text
RANDOM_STRUCTURES=2000
DIFFERENCES=0
```

Камтылган G: 1..30, K: 1..min(G,17), gate gap: 1..963. Нөл/туура эмес G, K>G, partition sum≠G жана нөл gap четке кагылат.

## YearStructure invariant QA

`validate_year_structure.b98` тандалган компоненттердин §17–§21 боюнча бир YearStructure болуп мыйзамдуу биригишин текшерет:

- cutlet length'тер оң жана year length'ке так суммаланат;
- 6..17 cutlet name canonicalIndex кайталанбайт;
- 3..47 month length 4..123 жана year length'ке так суммаланат;
- month name canonicalIndex кайталанбайт;
- weaving month ID'лери диапазондо;
- weaving'деги ар айдын саны month length'ке тең;
- first-occurrence тартиби 1..m;
- last-occurrence тартиби 1..m.

```text
RANDOM_VALID_YEAR_STRUCTURES=500
DIFFERENCES=0
```

Кошумча алты corruption классы атайын киргизилип, баары `0` менен четке кагылды: zero cutlet length, cutlet sum mismatch, duplicate cutlet name, month length<4, weaving ID out of range, duplicate month name.

Бул validator структураны **тандабайт**; ал rank/unrank/materialization helper'леринин жыйынтыгын бүтүн YearStructure катары текшерүүчү интеграция катмары.


## PyFunge native replay

2026-10-08 күнү PyFunge 0.5-rc2 менен азыркы corpus native replay'ден өткөрүлдү.

Биринчи run standalone selector helper'лерде түз тексттик `-1` direction input колдонулганын ачты. Funge-98 `&` мындай signed transport'ту сактабагандыктан direction `+1` болуп окулуп калган. Бул transport boundary катасы болгон.

Оңдоо: standalone direction input `directionSign directionMagnitude` форматына өткөрүлдү:

- `0 1` → `+1`;
- `1 1` → `-1`.

Оңдоодон кийинки native run:

```text
workflow_run=37740099311
job=113188582683
program_runs=84
failures=0
status=PASS
```

Камтуу: runtime contract, 7 smoke test, 8 dispatcher case, 48 primitive fixture жана 20 integration fixture.

Толук provenance: `NATIVE_PYFUNGE_REPLAY.md`.
