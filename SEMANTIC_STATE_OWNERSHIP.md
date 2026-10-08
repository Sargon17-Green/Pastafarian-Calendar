# `Stage 1` — семантикалык абалдын ээлиги

Күн: 2026-10-07

## Ээлик эрежеси

Азыркы Befunge production өзөгүндө ар бир ишке киргизүүнүн семантикалык абалы ошол ишке киргизүүнүн өзүнө гана таандык.

Ээлик кылган нерселер:

- instruction pointer;
- data stack;
- ушул process'тин input агымы;
- ошол invocation үчүн эсептелген убактылуу бүтүн сандар.

Булар башка invocation менен бөлүшүлбөйт.

## Funge-space боюнча чектөө

Азыркы `src/*.b98` production файлдары кайра сканерленди.

Төмөнкү state-mutating же тышкы I/O буйруктарынын эч бири жок:

- `p`, `g` — Funge-space жазуу/окуу;
- `i`, `o` — файлдык киргизүү/чыгаруу;
- `=` — тышкы команда;
- `t` — кошумча instruction pointer;
- `(`, `)` — fingerprint жүктөө/түшүрүү;
- `?` — кокустук багыт;
- `{`, `}`, `u` — stack-stack state.

Демек source Funge-space runtime учурунда өзгөрбөйт жана production семантикасы process аралык mutable state'ке ээ эмес.

## Контекст

`src/base_context.b98` нейтралдуу төрт токендик Bootstrap seed чыгарат:

```text
contextVersion phase status observabilityCount
1              0     0      0
```

Бул азырынча calendar semantics алып жүрбөйт. Келечектеги patch-specific state Stage 1де алдын ала кошулган жок.

## Validation жана error

`src/base_validator.b98` signed input representation үчүн канондук форманы текшерет:

- `0,m` — жарактуу;
- `1,m` — `m>0` болгондо гана жарактуу;
- `1,0` — жараксыз;
- башка sign — жараксыз.

`src/error_wrapper.b98` status `0` болгондо semantic value'ну өзгөртпөй өткөрөт; башка status үчүн `-1` deterministic error sentinel чыгарат.

## Metrics/logging

`src/metrics_shell.b98` жана `src/logging_shell.b98` эки токен окуйт:

```text
semanticValue counter
```

жана чыгарат:

```text
semanticValue counter+1
```

Биринчи токен counter маанисинен көз каранды эмес. Демек observability state семантикалык чечимге кайра кирбейт.

## Корутунду

Азыркы Stage 1 production катмары үчүн:

`SEMANTIC_STATE_OWNER_VALIDATED=YES`

Бул далил азыркы Bootstrap катмарына гана тиешелүү. Кийинки этаптарда mutable cache, snapshot, recovery же башка state пайда болсо, ownership кайра текшерилиши керек.
