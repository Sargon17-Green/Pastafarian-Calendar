# `Stage 1` — Befunge-98 спецификациясын текшерүү

Күн: 2026-10-07

## Текшерилген келишимдер

Funge-98 расмий спецификациясы менен азыркы баштапкы код салыштырылды.

1. `7y` Befunge үчүн өлчөмдөрдүн санын берет; талап кылынган маани — `2`.
2. `2y` бир уячага туура келген байттардын санын билдирет. Стандарт аны `-1` деп бекитпейт. Ошондуктан `2y == -1` ушул долбоордун чектелбеген тактыктагы бүтүн сан үчүн кошумча квалификациялык шарты.
3. Терс аргумент катышкан `%` жыйынтыгы Funge-98де implementation-defined.
4. Production `SAVE` мындан ары терс operand менен `%` колдонбойт. Оң сан үчүн `1 + ((m + M - 1) % M)`, терс сан үчүн `M - (m % M)` эсептелет; эки modulo dividend тең терс эмес.
5. Production `dayCount` азыркы формада `/` да, `%` да колдонбойт.
6. `&` цифрага жеткенче башка белгилерди өткөрүп жиберип, андан кийин цифралардын тизмегин окуйт. Ошондуктан тышкы signed integer үчүн `sign magnitude` форматы колдонулат.
7. Нөлдүн канондук signed формасы `0 0`; `1 0` четке кагылат.
8. `.` бүтүн санды ондук түрүндө чыгарып, артынан боштук кошот; native сыноодо сандык токен текшерилет.
9. PyFunge колдонулса `--disable-fprint --no-concurrent --no-filesystem -v98 -d2` параметрлери кошумча семантикаларды өчүрүп, Befunge-98 эки өлчөмдүү режимин ачык тандайт.

## Кодго тийгизген таасир

- `runtime_contract.b98` эми arbitrary-precision profile жана эки өлчөмдү гана текшерет;
- `bootstrap.b98` ошол эле тарылган runtime келишимин колдонот;
- `save.b98` жана `save_edges.b98` implementation-defined терс moduloдон бошотулду;
- `day_count.b98` канондук `sign/magnitude` текшерүүсү менен эки өлчөмдүү deterministic control flow'го өткөрүлдү;
- `sign_validation.b98` `1 0` negative-zero формасын да четке кагууну текшерет.

## Тышкы техникалык булактар

- Funge-98 Final Specification: https://catseye.tc/view/Funge-98/doc/funge98.markdown
- PyFunge v0.5-rc2, Supported Languages: https://pythonhosted.org/PyFunge/languages.html
- PyFunge v0.5-rc2, Invocation: https://pythonhosted.org/PyFunge/invocation.html

Бул булактар программалоо тилинин жүрүм-турумун текшерет. Алар Пастафари календарынын семантикалык булагы эмес.
