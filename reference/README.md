# Test-only нормативдик reference — Befunge-98

Бул каталог production коду эмес. Ал `Stage 1` үчүн `Appendix A — Embedded Normative Reference` сүрөттөмөсүнөн кайра түзүлгөн таза test-only reference болуп өсөт.

Production файлдары бул каталогдогу кодду runtime учурунда чакырбайт жана андан fallback албайт.

## Киргизүү келишими

Тышкы signed integer `sign magnitude` түрүндө берилет:

- `0 m` — `+m`;
- `1 m`, `m>0` — `-m`;
- `0 0` — нөл;
- башка форма — `-1` ката-сентинели.

Бул формат Funge-98 `&` командасынын тексттик минус белгисин signed integer катары канондук түрдө сактабаганы үчүн колдонулат.

Ошол эле эреже standalone signed-direction helper'лерге да колдонулат. Direction input `directionSign directionMagnitude` түрүндө берилет:

- `0 1` → `directionStep=+1`;
- `1 1` → `directionStep=-1`.

Бул transport `answer_at.b98`, `choose_rank_short.b98`, `choose_rank_wide.b98` жана `choose_rank.b98` үчүн колдонулат. Integrated `rank_from_sauce.b98` direction'ды process ичинде түз эсептейт.

## Азыркы камтуу

| Appendix A бөлүгү | Reference файлы | Абал |
|---|---|---|
| §1 туруктуулар | `constants_check.b98` | PASS статикалык |
| §2 `SAVE` | `save.b98` | IMPLEMENTED |
| §3 `dayCount` | `day_count.b98` | IMPLEMENTED |
| §3 `workCounts` | `work_counts.b98` | IMPLEMENTED |
| §4 `buildStones` | `build_stones.b98` | IMPLEMENTED |
| §5 hidden drops | `hidden_drops.b98` | IMPLEMENTED |
| §6 visible drops | `visible_drops.b98` | IMPLEMENTED |
| §7 bowl order | `bowl_order.b98` | IMPLEMENTED |
| §8.1 initial bowls | `initial_bowls.b98` | IMPLEMENTED |
| §8.2 apply visible drops to bowls | `apply_visible_to_bowls.b98` | IMPLEMENTED |
| §9 post-stir 12 | `post_stir_12.b98` | IMPLEMENTED |
| §10 sauce composition | `sauce.b98` | IMPLEMENTED |
| §11 `askBowl` | `ask_bowl.b98` | IMPLEMENTED |
| §11 `answerAt` | `answer_at.b98` | IMPLEMENTED |
| §12 short selection | `choose_rank_short.b98` | IMPLEMENTED |
| §12 smallest power | `smallest_power_count.b98` | IMPLEMENTED |
| §12 wide selection | `choose_rank_wide.b98` | IMPLEMENTED |
| §12 dispatcher | `choose_rank.b98` | IMPLEMENTED |
| §13.1 falling factorial | `falling_factorial.b98` | IMPLEMENTED |
| §13.1 distinct-name unrank | `unrank_distinct_names.b98` | IMPLEMENTED |
| §13.2 bounded composition count | `count_bounded_compositions.b98` | IMPLEMENTED |
| §13.2 bounded composition unrank | `unrank_bounded_composition.b98` | IMPLEMENTED |
| §14.1 gate gap from SauceResult | `gate_gap_from_sauce.b98` | IMPLEMENTED |
| §14.1 days→Sauce→gate gap | `gate_gap_from_days.b98` | IMPLEMENTED |
| §11–§12 days→Sauce→rank | `rank_from_days.b98` | IMPLEMENTED |
| §14.2 gate walk from validated gaps | `gate_walk.b98` | IMPLEMENTED |
| §15 year-pair validity | `valid_year_pair.b98` | IMPLEMENTED |
| §14.2 gate lookup over covered vector | `gate_lookup.b98` | IMPLEMENTED |
| §15 Year-5000 candidate selector from gates+rank | `year5000_from_gates_rank.b98` | IMPLEMENTED |
| §16 next/previous selector from gates+rank | `adjacent_year_from_gates_rank.b98` | IMPLEMENTED |
| §16.1 sequential target-year walk from gates+ranks | `find_target_year_from_gates_ranks.b98` | IMPLEMENTED |
| §14–16 Sauce/rank primitives for year selection | `rank_from_days.b98`, `gate_gap_from_days.b98`, gate/year rank selectors | IMPLEMENTED |
| §14–16 single-program gate/year orchestration | — | OPEN |
| §17–§20 seven structure ranks from one SauceResult | `structure_ranks_from_sauce.b98` | IMPLEMENTED |
| §17 cutlet count/partition/materialization helpers | `cutlet_count_from_rank.b98`, `count_cutlet_partitions.b98`, `valid_cutlet_partition.b98`, `unrank_cutlet_partition.b98`, `materialize_cutlet_lengths.b98` | PARTIAL |
| §18 month-count helpers | `month_count_bounds.b98`, `month_count_from_rank.b98` | PARTIAL |
| §19 weaving DP | `count_weavings.b98`, `unrank_weaving.b98` | IMPLEMENTED |
| §20–21 component integration / invariants | `structure_ranks_from_sauce.b98`, generic unrank helpers, `materialize_cutlet_lengths.b98`, `validate_year_structure.b98` | PARTIAL |
| §22 final-position helpers | `locate_cutlet_from_lengths.b98`, `month_locate_in_weaving.b98` | IMPLEMENTED |
| §22 five-field tuple from preselected YearStructure | `final_five_fields_from_structure.b98` | IMPLEMENTED |
| §22 full `calendarDate` orchestration | — | OPEN |

Демек бул каталог азырынча **толук oracle эмес** жана `Stage 1` аяктады деген далил боло албайт.

## Өз алдынчалык

Бул reference башка программалоо тилиндеги ишке ашыруудан, даяр тест маалыматынан, чыгарылыштан же хэштен алынган эмес. Семантика үчүн жалгыз булак — ушул линиянын Stage 1 келишиминдеги `Appendix A`.

`work_counts.b98` локалдуу test-only scratch үчүн Funge-space `p/g` колдонот; анын ээлиги `STATE_OWNERSHIP.md` ичинде өзүнчө аныкталган. Production бул scratch'ка кайрылбайт.

Кийинки файлдар да ушул эрежени сактап, бөлүк-бөлүк кошулат.


## Stage 1 кабыл алуу чеги

55-этаптык келишимдеги Bootstrap талабы production'дун толук `calendarDate` функциясын талап кылбайт. Stage 1 үчүн production жагында нейтралдуу skeleton жетиштүү; толук нормативдик эсеп test-only reference'те далилденет.

Мурда GREEN болуп жабылган Stage 1 үлгүсүндөгү кабыл алуу чеги төмөнкү домендерди камтыйт:

1. так бүтүн арифметика;
2. Sauce;
3. Short/Wide Choice;
4. комбинатордук үй-бүлөлөрдүн count/unrank логикасы;
5. month weaving;
6. gates;
7. Year 5000 тандоо.

Бул Befunge reference'те алардын баары өзүнчө модулдар менен ишке ашкан:

- арифметика: `save.b98`, `day_count.b98`, `work_counts.b98`;
- Sauce: `sauce.b98`;
- Choice: `ask_bowl.b98`, `answer_at.b98`, `choose_rank*.b98`, `rank_from_days.b98`;
- комбинаторика: `falling_factorial.b98`, distinct-name жана bounded-composition count/unrank файлдары;
- weaving: `count_weavings.b98`, `unrank_weaving.b98`;
- gates: `gate_gap_from_days.b98`, `gate_walk.b98`, `gate_lookup.b98`;
- Year 5000: `year5000_from_gates_rank.b98` жана ага rank/gate маалымат берген нормативдик модулдар.

§16–§22 боюнча кошумча reference файлдары пайдалуу кеңейтүү болуп саналат. Толук single-program `calendarDate` orchestration'ы ачык бойдон калышы мүмкүн, бирок ал Stage 1 Bootstrap'ту жабуучу кошумча gate катары эсептелбейт.

Stage 1 GREEN үчүн жогорудагы милдеттүү домендердин native Befunge replay далили дагы талап кылынат.
