# Жергиликтүү Befunge аткаруусун текшерүү

> Канондук repository: `Sargon17-Green/Pastafarian-Calendar`; branch: `Befunge+Кыргызча`. Бардык `src/`, `reference/`, `test/` жолдору branch root'уна салыштырмалуу көрсөтүлөт. 2026-10-08деги туура repo native regression: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37790547734 (421/421 PASS). Төмөндөгү `pastafari-calendar` URL'дери көчүрүүгө чейинки **тарыхый QA** гана; азыркы репонун жыйынтыктары катары колдонбоо керек.

Бул файл `Stage 1` үчүн Befunge-98 менен жергиликтүү аткаруунун минималдуу тартибин берет.

## Интерпретатор шарты

Интерпретатор `src/runtime_contract.b98` программасын ийгиликтүү өткөрүшү керек. PyFunge колдонулса кошумча семантикаларды өчүрүп иштетүү сунушталат:

```text
pyfunge --disable-fprint --no-concurrent --no-filesystem -v98 -d2 src/runtime_contract.b98
```

Күтүлгөн сандык токен: `1`.

Funge-98деги `.` бүтүн санды ондук түрүндө чыгарып, артынан боштук кошкондуктан чыныгы агымда `1 ` болуп көрүнүшү мүмкүн.

## Баштапкы ишке киргизүү

```text
pyfunge --disable-fprint --no-concurrent --no-filesystem -v98 -d2 src/bootstrap.b98
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
test/anchor_constants.b98
test/great_number.b98
test/save_edges.b98
test/reference_day_count_edges.b98
test/sign_validation.b98
test/stones_drop2.b98
test/year_bounds.b98
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
pyfunge --disable-fprint --no-concurrent --no-filesystem -v98 -d2 src/interleaved_day_save.b98
```

Input `0 0` → output `30111343 170141183460469231731687303715884105727`.

Input `1 15055672` → output `2 170141183460469231731687303715869050055`.

Input `2 10` же canonical эмес `1 0` → output `-1 -1`.

- Native Befunge reference differential: 44/44 PASS — https://github.com/Sargon17-Green/pastafari-calendar/actions/runs/37783622456
- Native IP trace and mutated executable gate verification: https://github.com/Sargon17-Green/pastafari-calendar/actions/runs/37783719110
- Толук таануу жана кабыл алуу чектөөлөрү: `artifacts/stage-01/INTERLEAVED_DAY_SAVE_NATIVE_QA.md`.

Бул pair операциясы толук CalendarDate converter эмес, Stage 1деги кеңейтилген негиз гана; Stage 2 башталган жок.


## 2026-10-08 — QA-only lexical-source promotion and acceptance gate

Бул бөлүк мурунку тарыхый run'дардын үстүнөн жаңыртылган QA статусун берет.

- Canonical \`Befunge+Кыргызча\` **өзгөргөн жок**.
- QA branch: \`qa-befunge98-stage1-order-isolation-20261008\`;
  draft PR: https://github.com/Sargon17-Green/Pastafarian-Calendar/pull/17.
- 2026-10-08деги native run:
  https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37831929988.
  Алгач 5/6 jobs PASS болгон. Жалгыз FAIL — мурдагы original
  production'дун \`-0\` белгисин четке какпаганы.
- QA гана: \`src/interleaved_work_counts.b98\` native-дa текшерилген
  parser scanner candidate'дин так байттары менен алмаштырылды:
  Git blob \`e2b39b066d1d47bcb8ce4f234b093fca94cb21d1\`.
- Эски source \`qa/interleaved_work_counts_pre_lexical_baseline.b98\`
  жолунда, Git blob
  \`e06d8f75d6502b2771d6a76b00397c6b6dbee543\`.
- Эми GitHub Actions'тагы алты job толук PASS болгону жаңы HEAD үчүн
  **далилдениши керек**. Биринчи беш job мурдагы HEAD'де PASS
  болгону жаңы HEAD үчүн автоматтык кабыл алуу эмес.
- Same-Program exact-object reset/reuse дагы өзүнчө ачык acceptance.

Бул тартип source'ту ар башка тилге которбойт жана reference
ордуна Python математикалык календарь эсептөөсүн колдонбойт.
Канондук branch'ка merge жүргүзбө; Stage 2 башталган жок.


## 2026-10-08 — Native 6/6 акыркы PASS жана жетинчи QA job

Туура repo / branch QA run:
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37833658868
(HEAD 82fc82929dc301e34041c750587aee7d6b58207f).

- native-regression: PASS, 421 targeted native invocations;
- native-write-audit: PASS, 26,708 жана 12,194 native event parity;
- native-same-interpreter-isolation: PASS, 24 fresh + 2 interleaved pairs;
- native-lexical-parser-candidate: PASS, 43 valid + 48 invalid;
- native-integrated-lexical-candidate: PASS, 123 native invocations;
- native-lexical-contract: PASS, 8 minus rejections жана old-source negative control.

\`src/interleaved_work_counts.b98\` QAда native-PASS lexical parser blob,
canonical \`Befunge+Кыргызча\` дагы өзгөргөн жок.

Жаңы \`native-exact-program-object-reset\` жетинчи job
аткарылышы керек. Ал бир эле Program объекттин Funge-space,
stack/IP, I/O абалын ачык reset кылып, ар бир жолу native
CLI'ге салыштырат. PASS чыкканча аны жабык деп эсептебегиле.
Ал кошулганы Stage 1 толук аяктаганын билдирбейт.


## 2026-10-08 — жетинчи native job биринчи FAIL, reset оңдолду

Эски run:
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37834875763.
6/7 jobs PASS; жетинчи \`native-exact-program-object-reset\`
биринчи iteration'да \`got=[]\` чыгарды (өзүнчө PyFunge CLI
жети туура сан чыгарган). Себеби QA reset code
\`program.platform\` гана алмаштырып, Python PyFunge
\`semantics.platform\` талаасын өзгөрткөн эмес.

Тууралоо QA source file
\`qa/stage1_native_same_program_reset.py\` ичинде аткарылды:
бир эле \`Program\` identity менен constructor аркылуу
толук explicit reinitialization колдонулат жана semantics,
space, IP, input/output invariants текшерилет.

**Бул fix'тин кийинки Native CI кайра иштетүүсү күтүлүүдө**;
ал өтмөйүнчө same-object reset PASS деп айтпагыла.
