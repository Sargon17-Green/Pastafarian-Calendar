# Stage 1 — Native geometry evidence ledger (QA branch, 2026-10-08)

## Кайсы далил текшерилген

Канондук repo: `Sargon17-Green/Pastafarian-Calendar`.
Булак: [Native Actions run 37835677064](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37835677064), HEAD `8002a5d959e1a4f0d0b586974ba0bdae22ad57f6`; **7/7 jobs PASS**.
Raw native trace artifact: GitHub Actions artifact ID `11575187608`, `befunge-kyrgyz-native-write-audit`.
Test-only PyFunge instrumentation: `qa/sitecustomize.py`.
Original Funge-space: `qa/interleaved_work_counts_pre_lexical_baseline.b98`.
Native-qualified QA production: `src/interleaved_work_counts.b98`.

Бул таблица **чыныгы Native PyFunge** `STEP` окуяларын гана эсептейт.
Лексикалык сканер токендерди толук окуп, баштапкы арифметикага
`(x=5, y=0, delta=(1,0))` чекитинде өткөндөн кийинки
2D trace алынган. Демек scanner'дин кошумча багыттары жана
opcode'дору бул таблицага кошулган жок.

| Native-after-handoff көрсөткүч | Valid `1 15055672 1 15055670` | Invalid `2 10 0 10` |
|---|---:|---:|
| Executed instruction steps | 25,982 | 11,902 |
| Executed distinct (x,y) cells | 9,532 | 9,408 |
| Cardinal-delta steps | 25,314 | 11,594 |
| Non-cardinal/dynamic-delta steps | 668 | 308 |
| Executed `x` dynamic-vector opcodes | 668 | 308 |
| Executed `p` writes | 128 | 56 |
| Executed `g` reads | 235 | 90 |
| Distinct coordinates visited under multiple distinct deltas | 1 | 1 |
| Native `_` and `|` conditionals | 0 | 0 |
| Native `[` `]` `r` `w` `k` `j` opcodes | 0 | 0 |
| Native `{` `}` `u` stack-stack opcodes | 0 | 0 |
| Executed min/max X | 5..1528 | 5..1530 |
| Executed min/max Y | 0..2014 | 0..1860 |

**Тастыкталган башка нерселер:** source blob `e2b39b066d1d47bcb8ce4f234b093fca94cb21d1` Native-PASS candidate менен так бирдей. Original blob `e06d8f75d6502b2771d6a76b00397c6b6dbee543` immutable baseline катары сакталган. Native post-handoff IP/delta/opcode/stack-depth жана `g`/`p` окуялары оригинал менен жаңы версияда 26,708 valid, 12,194 invalid окуя боюнча толук дал келди. Кайра аткарылган `p` gate writes valid=10, invalid=4; executable opcode өзгөргөн жана кийин аткарылган учурлар экөөндө тең үчтөн.

## Натыйжанын так чеги

Native 7/7 CI PASS — **функционалдык тесттердин** белгилүү чегинде чыныгы PASS.
Бирок эки trace бардык possible input боюнча геометриянын абсолюттук
кабыл алуусу эмес. Аткарылган source геометриясы эки өлчөмдүү
жана `x`, `p`, `g` динамикалык башкаруусу иш жүзүндө бар.
Ошентсе да ушул эки трассада кошумча advanced opcode'дор
(`_`, `|`, `w`, `r`, `k`, `j`, `[`, `]`, `{`, `}`, `u`)
**аткарылган эмес**. Бул бардык input үчүн жок экенин далилдебейт;
бирок алар үчүн acceptance далили ушул trace'терден алынбайт.

Милдеттүү кийинки иш: эки башка gate'ти өз-өзүнчө жабуу —
`FULL_FUNCTIONAL_QA_PASS` жана
`GEOMETRIC_SPAGHETTI_QA_PASS`. Геометриялык gate үчүн
так source map, маршруттун багыттуу graph'ы,
текшериле турган кесилиш/цикл, динамикалык execution-cell
version lifecycle, anti-dead-code көзөмөлү жана
көп варианттуу input coverage талап кылынат.
Мурдагыдай эле `SEMANTIC_STATE_OWNER_VALIDATED=NO_FINAL_AUDIT`;
16 explicit-reset реplay PASS жалпы бүт өзөктөр үчүн бардык
state-owner эрежелеринин далили эмес.

Жаңыланган Native structural corpus'тар
`qa/stage1_native_structural_corpus.py` жана
`qa/stage1_native_structural_properties.py` боюнча акыркы
GitHub CI дагы өзүнчө текшерилүүгө тийиш.

**Stage 1 OPEN, LAST_COMPLETED_STAGE=0, Stage 2 NOT STARTED.**
PR #17 QA only, canonical branch өзгөртүлгөн эмес.
