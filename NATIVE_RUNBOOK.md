# Жергиликтүү Befunge аткаруусун текшерүү

Бул файл `Stage 1` үчүн Befunge-98 менен жергиликтүү аткаруунун минималдуу тартибин берет.

## Интерпретатор шарты

Интерпретатор `src/runtime_contract.b98` программасын ийгиликтүү өткөрүшү керек. PyFunge колдонулса кошумча семантикаларды өчүрүп иштетүү сунушталат:

```text
pyfunge --disable-fprint --no-concurrent --no-filesystem -v98 -d2 implementations/befunge-kyrgyz/src/runtime_contract.b98
```

Күтүлгөн сандык токен: `1`.

Funge-98деги `.` бүтүн санды ондук түрүндө чыгарып, артынан боштук кошкондуктан чыныгы агымда `1 ` болуп көрүнүшү мүмкүн.

## Баштапкы ишке киргизүү

```text
pyfunge --disable-fprint --no-concurrent --no-filesystem -v98 -d2 implementations/befunge-kyrgyz/src/bootstrap.b98
```

Киргизүү `0`; күтүлгөн сандык токен `1`.

## Нейтралдуу Bootstrap shell

`src/base_context.b98` күтүлгөн токендер: `1 0 0 0`.

`src/base_validator.b98`:
- `0 0` → `1`
- `1 1` → `1`
- `1 0` → `0`
- `2 1` → `0`

`src/error_wrapper.b98`:
- `0 42` → `42`
- `1 42` → `-1`

`src/metrics_shell.b98` жана `src/logging_shell.b98`:
- `42 7` → `42 8`

## Азыркы өз алдынча сыноолор

Төмөнкү файлдардын ар бири `1` сандык токенин чыгарышы керек:

```text
implementations/befunge-kyrgyz/test/anchor_constants.b98
implementations/befunge-kyrgyz/test/great_number.b98
implementations/befunge-kyrgyz/test/save_edges.b98
implementations/befunge-kyrgyz/test/reference_day_count_edges.b98
implementations/befunge-kyrgyz/test/sign_validation.b98
implementations/befunge-kyrgyz/test/stones_drop2.b98
implementations/befunge-kyrgyz/test/year_bounds.b98
```

Ар бир файлды ушул үлгү менен иштетүү керек:

```text
pyfunge --disable-fprint --no-concurrent --no-filesystem -v98 -d2 FILE.b98
```

## Өзөк операцияларынын мисалдары

`src/day_count.b98` эки сан окуйт: `sign magnitude`.

- `1 15055672` → `2`
- `1 15055671` → `1`
- `0 0` → `30111343`
- `2 10` → `-1`
- `1 0` → `-1` (канондук эмес negative zero)

`src/save.b98` да ошол форматты окуйт:

- `1 1` → `170141183460469231731687303715884105726`
- `0 0` → `170141183460469231731687303715884105727`
- `1 0` → `-1`
- `2 10` → `-1`

## Signed direction standalone helper'лери

Funge-98 `&` тексттик минус белгисин signed input катары канондук сактабагандыктан standalone direction input да `sign magnitude` менен берилет:

- `0 1` → `+1`;
- `1 1` → `-1`.

Мисалдар:

```text
choose_rank_short.b98:
170141183460469231731687303715884105727 0 1 922
=> 1

170141183460469231731687303715884105727 1 1 922
=> 922
```

2026-10-08 native replay ушул transport менен 84/84 программаны өткөрдү. Толук далил: `artifacts/stage-01/NATIVE_PYFUNGE_REPLAY.md`.

## `Stage 1` бүтүрүү шарты

Азыркы corpus PyFunge 0.5-rc2 менен native replay'ден өттү. Бирок `Stage 1` толук бүттү деп белгилөө үчүн test-only нормативдик reference толук бүтүп, full-oracle fixtures кошулуп, ошол акыркы corpus кайра native replay'ден өтүүгө тийиш.

## Биргелешкен `dayCount` + `SAVE` — Stage 1 native аракет

`src/interleaved_day_save.b98` эки өз алдынча program'ды external `=` аркылуу чакырбайт: signed input'ту **бир эле эсептик циклде** иштетип, эки натыйжаны ирети менен чыгарат:

```text
pyfunge --disable-fprint --no-concurrent --no-filesystem -v98 -d2 implementations/befunge-kyrgyz/src/interleaved_day_save.b98
```

Input `0 0` → output `30111343 170141183460469231731687303715884105727`.

Input `1 15055672` → output `2 170141183460469231731687303715869050055`.

Input `2 10` же canonical эмес `1 0` → output `-1 -1`.

- Native Befunge reference differential: 44/44 PASS — https://github.com/Sargon17-Green/pastafari-calendar/actions/runs/37783622456
- Native IP trace and mutated executable gate verification: https://github.com/Sargon17-Green/pastafari-calendar/actions/runs/37783719110
- Толук таануу жана кабыл алуу чектөөлөрү: `artifacts/stage-01/INTERLEAVED_DAY_SAVE_NATIVE_QA.md`.

Бул pair операциясы толук CalendarDate converter эмес, Stage 1деги кеңейтилген негиз гана; Stage 2 башталган жок.
