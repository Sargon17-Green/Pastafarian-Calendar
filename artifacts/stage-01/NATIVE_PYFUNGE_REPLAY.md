# Stage 1 — PyFunge native replay далили

Күн: 2026-10-08

## Максат

Бул далил Befunge + Кыргызча линиясынын азыркы `Stage 1` corpus'ун өзүнчө Funge-98 интерпретатору менен аткарууну каттайт.

Бул **Stage 1 толук бүттү** дегенди билдирбейт: test-only reference азырынча толук `calendarDate` orchestration'га жеткен жок жана кийин кошулган reference/test файлдары кайра native replay'ден өтүшү керек.

## Аткаруу чөйрөсү

- интерпретатор: `PyFunge 0.5-rc2`;
- Python: `2.7.18`;
- PyFunge source archive SHA-256:
  `e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac`;
- контейнер: `python:2.7-slim`;
- native run'да алынган image digest:
  `sha256:6c1ffdff499e29ea663e6e67c9b6b9a3b401d554d2c9f061f9a45344e3992363`;
- PyFunge параметрлери:
  `--disable-fprint --no-concurrent --no-filesystem -v98 -d2`.

## Алгачкы native finding

Биринчи native replay:

- workflow run: `37739250526`;
- job: `113185886824`;
- жыйынтык: **FAIL**.

Runtime contract жана бардык жети smoke test PASS болгон. Биринчи айырма standalone `choose_rank_short.b98` үчүн directionStep `-1` input'унда табылды.

Бул алгоритм катасы эмес, transport катасы болуп чыкты. Funge-98 `&` командасы тексттик минус белгисин signed integer катары канондук түрдө сактабайт. Ошондуктан fixture'деги түз `-1` PyFunge тарабынан `1` катары окулган.

Оңдоо: standalone signed-direction helper'лер тышкы direction'ды да `sign magnitude` менен кабыл алат:

- `0 1` → `+1`;
- `1 1` → `-1`.

Тийген файлдар:

- `reference/answer_at.b98`;
- `reference/choose_rank_short.b98`;
- `reference/choose_rank_wide.b98`;
- `reference/choose_rank.b98`;
- `fixtures/REFERENCE_PRIMITIVE_FIXTURES.tsv`.

Integrated `rank_from_sauce.b98` жана `rank_from_days.b98` direction'ды тексттик signed input'тан окубайт; алар `askBowl` жыйынтыгынан process ичинде түз эсептейт. Ошондуктан алардын алгоритмдик семантикасы өзгөргөн жок.

## Оңдоодон кийинки native replay

QA branch commit:

`776169dcb503d170731b898b8c908efe30a0b7f2`

Workflow run:

`37740099311`

Native replay job:

`113188582683`

Жыйынтык:

```text
NATIVE_REPLAY_PASS total_program_runs=84 failures=0
```

84 аткаруу төмөнкүдөй бөлүнөт:

- runtime contract: 1;
- өз алдынча smoke test: 7;
- `choose_rank.b98` dispatcher direction/short/wide чек учурлары: 8;
- `REFERENCE_PRIMITIVE_FIXTURES.tsv`: 48;
- `REFERENCE_INTEGRATION_FIXTURES.tsv`: 20.

## Target branch менен байлоо

Оңдолгон беш semantic/fixture файл QA branch'тан `Befunge+Кыргызча` target branch'ына byte-for-byte өткөрүлдү.

Target жана native-QA branch blob SHA'лары тең экени түз текшерилди:

- `answer_at.b98`: `eb1408867ba91c19cb0b9daf63a98b20306f6e37`;
- `choose_rank_short.b98`: `1dfbe9e8e986b4562878e34acf50b8e3fa4a1c6e`;
- `choose_rank_wide.b98`: `fedcf70f1d2ce7202111f0fab104238fff3d93df`;
- `choose_rank.b98`: `44dbd6570a44ce5fa29fd9e26fcee0ba26e10f2d`;
- `REFERENCE_PRIMITIVE_FIXTURES.tsv`: `f7c7a1468ef172189448471c56075c568bae9706`.

## Repo-wide CI эскертүүсү

Native QAга чейинки target commit `5af43af9b02dfd9ca1a0e1aaa621740b1e828892` үчүн:

- `implementations`: SUCCESS;
- `visual`: SUCCESS;
- `benchmark`: SUCCESS;
- `test`: FAILURE.

`test` workflow'дагы эки failure Befunge линиясына тиешелүү эмес:

1. Hebrew about-page deep-link contract;
2. PWA `index.html` icon revision query.

Branch base менен target diff'и текшерилгенде 188 commit өзгөрткөн **86 файлдын баары** `implementations/befunge-kyrgyz/` астында экени аныкталды. About/PWA файлдары бул линия тарабынан өзгөртүлгөн эмес.

## Статус

`CURRENT_NATIVE_CORPUS_REPLAY=PASS`

`CURRENT_NATIVE_PROGRAM_RUNS=84`

`CURRENT_NATIVE_FAILURES=0`

`STAGE_1_COMPLETE=NO`

Толук reference жана кийинки кошулган fixtures бүткөндөн кийин native replay кайра жүргүзүлүүгө тийиш.
