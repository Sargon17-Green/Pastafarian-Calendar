# Stage 1 — workCounts менен кош күндүк SAVE чыныгы чырмалган Funge-98 өзөгү

Дата: 2026-10-08. Эч кандай Python же башка тилдеги эсептөө fallback'у жок; production `src/interleaved_work_counts.b98` — толук native Befunge-98 программасы. Кыргызча тексттер түшүндүрмө жана QA метадайындары үчүн гана.

## Транспорт келишими

Киргизүү төрт бүтүн сан: `calculationSign calculationMagnitude targetSign targetMagnitude`. Чыгыш жети бүтүн сан:

1. `actionCount`
2. `targetCount`
3. `distanceCount`
4. `connectionCount`
5. `directionCount`
6. `SAVE(calculationDay)`
7. `SAVE(targetDay)`

Белги `0` же `1`, magnitude терс эмес болушу керек; `1 0` canonical эмес. Эгер жараксыз болсо бардык жети output `-1`.

## Production'дагы чыныгы dataflow байланышы

Эки күндүн decimal digit'тери **бир shared microcycle** аркылуу иштетилет. Ал циклден signed sum жана signed difference, ошондой эле ошол эки маанинин modular image абалдары бир убакта өсөт. Аткаруунун аягы ушул кош абалдан экөөнүн тең күндөрүн, `dayCount` маанилерин, аралыкты жана багытты, ошондой эле modular `SAVE` элестерин чыгарат. Бүтүн сан тактыгы PyFunge-98 native'инде текшерилген. Эки эсепти көз карандысыз процесстер катары чакыруу жок.

Код Funge-space ичинде **242 жайылган маршрут-аймакты**, иш жүзүндө аткарылган вертикалдык/горизонталдык багыттарды жана динамикалык `x` векторлорун колдонуп, runtime executable gate'терди `p` менен жазат. Чыгыш алмашуусу да runtime көз каранды.

Production blob SHA: `e06d8f75d6502b2771d6a76b00397c6b6dbee543`.

## Native функционалдык QA

`PyFunge 0.5-rc2`, `-v98 -d2 --disable-fprint --no-concurrent --no-filesystem`.

52 valid day-pair үчүн production'дун биринчи беш натыйжасы `reference/work_counts.b98` менен, акыркы эки натыйжасы тиешелүү эки көз карандысыз `reference/save.b98` native иштетүүсү менен толук дал келди. Дагы 6 жараксыз sign/negative-zero input четке кагылды. Мунун өзү 214 native program invocation (52×4 + 6×1).

Native run: https://github.com/Sargon17-Green/pastafari-calendar/actions/runs/37785952747

## Түздөн-түз native interpreter instruction-pointer трассасы

Трасса жөнөкөй визуалдык статикалык карта эмес. PyFunge'дин IP орундарын жана иштетилген opcode'дорун instrumentation менен жазып, өзгөртүлгөн executable gate'тин жаңы opcode'су кийин иштетилгенин текшердик.

Native trace run жана artifact: https://github.com/Sargon17-Green/pastafari-calendar/actions/runs/37786411374

| Native көрсөткүч | valid `1 15055672 1 15055670` | invalid `2 10 0 10` |
|---|---:|---:|
| Executed steps | 25,987 | 11,907 |
| Unique Funge-space coordinates | 9,537 | 9,413 |
| Revisits | 16,450 | 2,494 |
| Executed `p` | 128 | 56 |
| Executable gate writes | 10 | 4 |
| Later executed modified gates | 10 | 4 |
| Executed `x` | 668 | 308 |

Бул 242 аралдын геометриясы чындап аткарыларын далилдейт. Абсолюттук оңдолбой калууну же кайра модулдаштыруу практикалык жактан мүмкүн болбостугун **далилдебейт**.

## Stage 1 ачык милдеттери

Толук календардык `(calculationDay,targetDay)` оркестрациясы, Year5000/гейт/көмөч/weaving production эсептери, жаңы mutable state ownership жана процессти кайра колдонуу/reentrancy текшерүүсү, акыркы толук source reference/геометрия кабыл алуусу дагы ачык.

`CURRENT_STAGE=1`; `LAST_COMPLETED_STAGE=0`. Stage 2 башталган жок.
