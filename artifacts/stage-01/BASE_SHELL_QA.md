# `Stage 1` — нейтралдуу Bootstrap кабыгынын QAсы

Күн: 2026-10-07

## Түзүлгөн компоненттер

- `src/base_context.b98`
- `src/base_validator.b98`
- `src/error_wrapper.b98`
- `src/metrics_shell.b98`
- `src/logging_shell.b98`

## Статикалык аткаруу жыйынтыктары

Жөнөкөй Befunge-98 stack/control-flow модели менен төмөнкү учурлар текшерилди.

### base_context

Чыгышы:

```text
1 0 0 0
```

### base_validator

- `0 0` → `1`
- `0 5` → `1`
- `1 1` → `1`
- `1 0` → `0`
- `2 1` → `0`

### error_wrapper

- `0 42` → `42`
- `1 42` → `-1`
- `-1 42` → `-1`

### metrics/logging shell

- `42 0` → `42 1`
- `42 7` → `42 8`
- `-5 99` → `-5 100`

Биринчи токен counter'ден көз каранды эмес.

## Stage 1 тарыхый чеги

Бул компоненттер атайылап нейтралдуу:

- legacy flag жок;
- patch registry жок;
- retry/recovery policy жок;
- cache жок;
- compatibility mode жок;
- келечектеги Stage 2–53 логикасы жок.

Ошондуктан алар Stage 1ге уруксат берилген base context / dispatcher / validator / error wrapper / metrics-log shell чегинен чыкпайт.
