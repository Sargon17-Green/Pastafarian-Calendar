# Stage 1 — dayCount'тун чыныгы Funge-98 аткаруу далили

Күн: 2026-10-08. Бул документ эсептин жөнөкөйлөштүрүлгөн production эквивалентин, код куруучу генераторду же тармактардын калыбына келтирүү картасын камтыбайт. Test-only эталон өз алдынча сакталып турат.

## Далилденген нерселер

- Production: `src/day_count.b98`; blob `4f25f514f7b6362105dfff77db6f36769efe36c3`; canonical promote commit `480e7c1a55bf2f051ef10851521baa8706028aed`.
- Диалект: Befunge-98, PyFunge 0.5-rc2, `-v98 -d2 --disable-fprint --no-concurrent --no-filesystem`.
- Native математикалык differential: **36/36 PASS**, бул линиянын өз алдынча Befunge `reference/day_count.b98` эталону менен байттык сан-токендердин салыштыруусу. Чектер, терс жактагы нөлдү четке кагуу, туура эмес sign жана 79-сандык даражалар камтылган.
- QA run: https://github.com/Sargon17-Green/pastafari-calendar/actions/runs/37780243225
- Native IP (instruction pointer) чыныгы трассасы PyFunge `Program.execute_step`тин бир invocation үчүн инструменттелген жолу менен алынган; ал жөнөкөй эмулятордун трассасы эмес. Трасса `step, ip_id, x, y, dx, dy, opcode, stack_depth` талааларын, ошондой эле `p` алдындагы жазуу маалыматтарын камтыйт. Чыныгы клетка өзгөрүшүнүн кийин аткарылганы runtime окулган opcode аркылуу далилденген.
- Geometry/trace run (чийки TSV, SVG жана metrics JSON artifact): https://github.com/Sargon17-Green/pastafari-calendar/actions/runs/37781237833

## Native ченөөлөр

| Параметр | `1 15055672` -> `2` | `2 10` -> `-1` |
|---|---:|---:|
| Аткарылган instruction | 10,490 | 4,396 |
| Ар башка Funge-space координата | 3,084 | 3,068 |
| Мурун аткарылган координатага кайра келүү | 7,406 | 1,328 |
| Аткарылган `p` | 43 | 19 |
| Executable gate write | 10 | 4 |
| Кийин аткарылган өзгөртүлгөн gate | 10 | 4 |
| Аткарылган `x` | 385 | 163 |
| Аткарылган cardinal багыттар | Төртөө тең | Төртөө тең |

Чийки аткаруу трассасы GitHub Actions artifact катары 30 күн сакталат; бул жердеги сандар artifact'тен көз карандысыз туруктуу фактыларды документтештирет.

## Эмне **далилдене элек**

- Бул тек гана `dayCount` функциясынын local функционалдык жана геометриялык текшерүүсү. Толук Appendix A календардык алгоритми, Year 5000, Gate/Weaving жана 55 этаптын жалпы критерийи боюнча **PASS жок**.
- Алгоритмге байланышкан башка production `.b98` модулдары азырынча кайра курулууда.
- Native trace бир process invocation үчүн гана. Funge-space reuse, көп IP, stack-stack ownership жана кайра чакыруулардагы толук reentrancy өзүнчө текшерилет.
- Геометрия өзү келечекте абсолюттук түрдө жөнөкөйлөштүрүүгө мүмкүн эмес экенин далилдебейт. Дагы чыныгы семантикалык өз ара байланышты өстүрүү талап кылынат.
- `LAST_COMPLETED_STAGE=0`; `CURRENT_STAGE=1`; Stage 2 башталган жок.
