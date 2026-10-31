# Stage 1 — lexical minus rejection finding (Befunge-98)

Күнү: 2026-10-08. **OPEN FUNCTIONAL DEFECT; Stage 1 бүтө элек.**

## Кайра чыгарылган факт

Native PyFunge 0.5-rc2 replay (тарыхый, туура эмес repository'де)
https://github.com/Sargon17-Green/pastafari-calendar/actions/runs/37787577988
жана job 113346187454 төмөнкүнү көрсөттү:

- raw input: `0 -1 0 1`
- expected: `-1 -1 -1 -1 -1 -1 -1`
- observed: `30111345 30111345 1 60222690 2 1 1`
- status: **FAIL**.

Туура repository'деги production `src/interleaved_work_counts.b98`
Git blob `e06d8f75d6502b2771d6a76b00397c6b6dbee543` —
ошол эле көчүрүлгөн программа; мурдагы FAIL автоматтык түрдө
туура repository'деги жаңы native test PASS эмес.

## Себеп жана так айырма

Funge-98 `&` ондук бүтүн сан окуйт, бирок терс лексикалык префиксти
transport token'унун валиддүүлүгү катары сактабайт. Бул production
Funge-space source'унда төрт `&` opcode бар, ал эми `~`
character-input opcode жок. Баштапкы киргизүү жолу `>&&&&`.
Ошондуктан төрт токендин бири терс жазылганын сандык төрт
маани даяр болгондон кийин калыбына келтирүүгө болбойт.

Мисалы `0 -1 0 1` жана `0 1 0 1` азыркы input loader үчүн
бирдей мааниге айланат. Бирок signed-magnitude transport эрежеси
биринчисин милдеттүү түрдө четке кагат.

Бул календардын математикалык формулаларына байланышкан эмес:
**лексикалык transport parser ката**.

## Сыналган QA жана оңдоого коюлган чектөө

- `qa/stage1_native_lexical_rejection.py` чыныгы interpreter'ге
  терс белгиси төрт позициянын ар биринде турган учурларды берет;
  жарактуу киргизүүлөр оң башкаруу тесттери катары текшерилет.
- `.github/workflows/befunge-kyrgyz-stage1-regression.yml`
  өзүнчө `native-lexical-contract` job'ун иштетет.
- Бул mandatory job азыркы өндүрүштүк source'то FAIL чыгарышы күтүлөт.
  Аны алып салуу, `continue-on-error` менен жашыруу же
  `&` семантикасын туура деп жарыялоо чечим эмес.
- Чыныгы оңдоо production **Befunge-98** ичинде лексикалык
  белгилерди character деңгээлинде окуп, төрт терс эмес ондук
  токенди чектөөлөрү менен текшерип, ошол эле арифметикалык
  өзөктүн баштапкы төрт маанисин түзүүгө тийиш.
  Python/native shell же reference аркылуу production fallback
  болбойт.
- Ушул оңдоо runtime self-modification, geometry, state ownership
  далилдерин кайра native QAдан өткөрүүнү талап кылат.

`CURRENT_STAGE=1`; `LAST_COMPLETED_STAGE=0`;
`LEXICAL_NEGATIVE_REJECTION=KNOWN_FAIL`.

## 2026-10-08 — Funge-98 character parser candidate

Test-only candidate: `qa/lexical_candidate.b98`, көз карандысыз
`qa/stage1_native_lexical_candidate.py` жана workflow
`native-lexical-parser-candidate`.

Бул баштапкы production'га интеграция эмес. Мурдагы төрт `&`
буйругун өзгөртпөйт. Candidate'тин өзүндө `~`, `#`, `v`,
`x`, `j`, `p/g` аркылуу символдон так 4 digit-only токен
чогултулат, андан кийин алардын сандык мааниси чыгарылат.
Терс лексикалык белги, башка символ, кем/ашык токен четке кагылат.

**Маанилүү Funge-98 тактоо:** EOF учурунда `~`
`-1` санын бербейт; interpreter `r` сыяктуу reflection
жасайт. Candidate ушул чыныгы тескери маршрутту `#v~`
көпүрөсүнө колдонуп EOF handler'ге өтөт. LF талап кылынбайт:
токендер newline менен да, EOF менен да бүтө алат.

Локалдык BigInt-safe Funge instruction simulator менен
**15/15** тандалган сценарий PASS; бул native interpreter
PASS эмес жана акыркы production'дун иштешин далилдебейт.
Native PyFunge текшерүүсү deterministic 90 valid/invalid
кезекти өзүнчө аткарат; жыйынтык дагы текшериле элек.
