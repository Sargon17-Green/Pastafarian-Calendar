# Stage 1 — Native композиция жана убакыт боюнча маршрут далилдери

Дата: 2026-10-08. Репозиторий: `Sargon17-Green/Pastafarian-Calendar`.
QA бутагы: `qa-befunge98-stage1-order-isolation-20261008`.
Канондук `Befunge+Кыргызча` жана `main` бутактары бул иштерде өзгөртүлгөн жок.

## 1. Sauce → Choice: экинчи native эсеп жолу

Кошулган текшерүүчү: `qa/stage1_native_sauce_choice_composition.py`.
GitHub Actions: [37839440103](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37839440103);
job `native-sauce-choice-composition` — **PASS**.

- Жети `(calculationDay,targetDay)` жуп; Foundation, нөл, каршы белгилер, чоң бүтүн сандар.
- Ар бир жупка беш суроо `(bowl,seal,N)`.
- Эки кошумча `N=2^127` wide-selection суроосу.
- `rank_from_days` жана `sauce → rank_from_sauce` бирдей сан чыгарышы керек.
- `gate_gap_from_days` жана `sauce → gate_gap_from_sauce` бирдей сан чыгарышы керек.
- Баары болуп **95 Native Befunge программа чакыруусу**, job log'унда PASS.
- Python календардык формулаларды аткарбайт: native process иштетүү, токен өткөрүү, жыйынтыкты салыштыруу гана.

Бул иш `FULL_FUNCTIONAL_QA_PASS=YES` деген кепилдик эмес: тандалган жети input'тан башка мейкиндик жана толук production orchestration али ачык.

## 2. Native route graph жана executable-cell версиялары

Кошулган текшерүүчү: `qa/stage1_native_route_graph.py`;
GitHub Actions `native-write-audit` job, [37839112226](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/37839112226) — **PASS**.

Native `qa/sitecustomize.py` жазган `STEP`, `READ_BEFORE`,
`READ_AFTER`, `WRITE_BEFORE`, `WRITE_AFTER` окуялары гана колдонулат.
Текшерүү ар бир executed opcode'ду source-map жана ошол убакка чейин
аяктаган `p` write версиясы менен салыштырат.

Raw trace жана JSON artifact `befunge-kyrgyz-native-write-audit`.
Ар бир old/new + valid/invalid trace'ке `*.graph.json` чыгарылат.
JSON ичинде чыныгы багыттуу edge'тер, executed source map, p write
before/after жана later-executed tick сакталат. `j`, `#`,
динамикалык `x` себептүү секирик өзүнөн-өзү adjacent edge деп
жасалма эсептелбейт.

Original arithmetic'тин valid case'и
`1 15055672 1 15055670` боюнча:

| Белги | Native өлчөм |
|---|---:|
| Arithmetic STEPs | 25,982 |
| Executed arithmetic cells | 9,532 |
| Unique observed directed arithmetic edges | 9,532 |
| Runtime writes, later executed | 10 |
| Content-changing writes, later executed | 3 |
| Graph nodes with ≥2 distinct incoming and ≥2 distinct outgoing neighbors | 0 |

`graph_merge_and_fork_nodes=0` бул **аныкталган тесттеги**
өлчөм: ал бардык башка input'тарда crossing болбой турганын
математикалык түрдө далилдебейт. Бирок ушул иштелген core трасса
үчүн чыныгы merge+fork далили жок. Көп revisits өзү crossing'дин
далили болуп эсептелбейт.

Ошол себептүү `GEOMETRIC_SPAGHETTI_QA_PASS=NO` сакталышы керек.
Атап айтканда кошумча advanced route, conditional, stack-stack
операторлорунун маанилүү аткарылышы, кеңири input coverage, full
source-cell ownership жана anti-dead-code далили ачык.

## 3. Кийинки кабыл алуу

- Global `FULL_FUNCTIONAL_QA_PASS` — ачык.
- Global `GEOMETRIC_SPAGHETTI_QA_PASS` — ачык.
- All-production semantic state ownership — ачык.
- Stage 1 — OPEN, `LAST_COMPLETED_STAGE=0`.
- Stage 2 — **башталган жок**.
- QA PR #17 — draft, **merge жок**.

Мындагы ар бир PASS өзүнүн exact-head Native job scope'уна гана тиешелүү.
