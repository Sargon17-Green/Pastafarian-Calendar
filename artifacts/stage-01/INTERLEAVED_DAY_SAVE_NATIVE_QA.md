# Stage 1 — dayCount жана SAVE бир кыймылда аткарылган Befunge-98 өзөгү

Дата: 2026-10-08.

## Иштөө келишими жана мааниси

`src/interleaved_day_save.b98` — өз алдынча Befunge-98 программа. Киргизүүсү бир `sign magnitude` түгөйү; чыгышы **эки бүтүн сан**: биринчи `dayCount`, андан кийин `SAVE`. Эгер киргизүү canonical эмес болсо, эки маани тең `-1`.

Бул программа `src/day_count.b98` менен `src/save.b98` файлдарын сырттан чакырбайт: экөөнүн эсептери бир Funge-space ичинде жана **бир эле кайталануучу decimal-циклде** чогуу жүрөт. `SAVE` residue'су ар бир кезектеги decimal digit'ти кайра түзүүгө катышат; ошол digit учурдагы place-weight аркылуу dayCount magnitude жана modular residue үчүн колдонулат. Өзгөрүлүүчү Funge-space өзү executable control gate'ти кайра жазат. Так арифметика бир гана Befunge-98 тарабынан аткарылат; башка тилде runtime календардык функция же oracle колдонулбайт.

## Native функциялык далил

- PyFunge 0.5-rc2, `-v98 -d2 --disable-fprint --no-concurrent --no-filesystem`.
- 44 киргизүү сценарийи, 132 Befunge-98 native иштетүү: бир жаңы production программага каршы эки өз алдынча `reference/day_count.b98` жана `reference/save.b98`.
- Бардык 44 киргизүүдө эки сан тең өз алдынча native эталондорго так дал келди.
- Үлгүлөр: Foundation чеги, signed zero'ну четке кагуу, туура эмес sign, `2^127-1`, `2^127`, чоң оң жана терс magnitudes, 127ден ашкан decimal разряддар.
- QA: https://github.com/Sargon17-Green/pastafari-calendar/actions/runs/37783622456
- Production Git blob SHA: `4da7c9af6d5b52a42f3fc7679c42eec0e51fc6dc`.

QA учурунда бир тарыхый `SAVE` багы табылып оңдолду: LSB-first разряддык итерация менен forward Horner колдонуу digits'ти тескери тартипте жыйнаган. Түзөтүү: ошол эле shared place-weight менен `(residue + digit*place) mod M` чогултуу. Алгачкы катасы бар нуска **production'га өткөрүлгөн жок**.

## Native геометрия — interpreter'дин өзүнөн

Instrumented PyFunge instruction pointer'ден `step, IP, coordinate, delta, executed opcode, stack depth` жана `p` write-before жазууларын чыгарды. Modified executable gate кийин ошол жаңы opcode менен аткарылганы чийки TSV менен текшерилди. Чийки trace жана SVG artifacts:

https://github.com/Sargon17-Green/pastafari-calendar/actions/runs/37783719110

| Өлчөө | Канондук киргизүү `1 15055672` | Жараксыз киргизүү `2 10` |
|---|---:|---:|
| Executed steps | 12,262 | 4,904 |
| Unique coordinates | 3,548 | 3,516 |
| Revisits | 8,714 | 1,388 |
| Executable gate writes | 10 | 4 |
| Gates subsequently executed as modified | 10 | 4 |
| Executed `x` instructions | 370 | 148 |

Экөө тең төрт негизги багытты жана чыныгы эки өлчөмдүү динамикалык vector-лорду иштетти.

## Чектөөлөр жана кийинки иш

Бул — *Stage 1деги чектелген, ырасталган өзөк*, календардын толук `(c,t)` эсептөөсү эмес. Эки output ушул учурда бир signed input үчүн; эсептөө күнү жана суроо күнү эки аргументтен куралган толук канондук өтмөк али ишке ашырыла элек. `YEAR 5000`, бардык gates, sauce жана weaving production интеграциясы, state ownership/reentrancy, тазалоо, оркестрация жана толук функционалдык + геометриялык acceptance али pending.

Жөнөкөйлөтүү мүмкүн эместигине абсолюттук кепилдик коюлбайт; учурдагы 104 жайылган код-аймак жана жалпы dataflow — кийинки чырмалышууга баштапкы катмар гана.

`CURRENT_STAGE=1`; `LAST_COMPLETED_STAGE=0`. Stage 2 башталган жок.
