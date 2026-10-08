# Test-only reference — Funge-space scratch ээлиги

Күн: 2026-10-07

Бул документ `reference/` каталогундагы test-only oracle үчүн гана колдонулат. Production `src/` мындан көз каранды эмес.

## Эмне үчүн `p/g` колдонулат

`reference/work_counts.b98` Appendix Aдагы таза `workCounts` формуласын бир файлда түз эсептейт. Befunge stack'ында бир нече аралык маанини ачык сактоо үчүн локалдуу Funge-space scratch колдонулат.

## Ээси

Scratch'тын ээси — **ушул reference программасынын бир process/invocation'у гана**.

Колдонулган аймак:

```text
y = 20
x = 0..8
```

Маанилер:

- x0 — calculation day;
- x1 — target day;
- x2/x3 — убактылуу difference/negative flag;
- x4 — action dayCount;
- x5 — target dayCount;
- x6 — distance;
- x7 — connection;
- x8 — direction.

## Коопсуздук касиеттери

- файлдык `i/o` колдонулбайт;
- тышкы `=` команда колдонулбайт;
- concurrency `t` колдонулбайт;
- fingerprint колдонулбайт;
- scratch process аяктаганда жок болот;
- башка invocation менен бөлүшүлгөн registry/cache жок;
- production бул scratch'ты окубайт;
- scratch expected value булагы эмес, Appendix A формуласын эсептөөчү убактылуу сактагыч гана.

Ошондуктан test-only reference'теги `p/g` production ownership далилине каршы келбейт.


## build_stones.b98 scratch

`reference/build_stones.b98` өзүнчө scratch аймагын колдонот:

```text
y = 30
x = 0..11
```

- x0..4 — учурдагы беш таш;
- x5..9 — кийинки беш таштын pending маанилери;
- x10 — учурдагы `i`;
- x11 — `M = 2^127 - 1`.

Жаңы беш таш толугу менен x5..9 ичинде эсептелет; андан кийин гана x0..4кө commit кылынат. Бул Appendix Aдагы «баары old snapshot'тан» талабын сактайт.


## hidden_drops.b98 scratch

`reference/hidden_drops.b98` өзүнчө `y=40` scratch аймагын колдонот. Анда input counts, учурдагы таш сап, pending таш сап, hidden accumulator, loop index жана `M` сакталат.

Бул scratch да ошол reference process'ине гана таандык жана production менен бөлүшүлбөйт.


## visible_drops.b98 scratch

`reference/visible_drops.b98` бир process ичинде үч фазаны аткарат:

1. 46 таш сапты Funge-space'ка даярдайт;
2. 7 hidden drop'ту timeline'га жайгаштырат;
3. 46 visible drop'ту кезеги менен эсептейт.

Негизги локалдуу аймактар:

```text
y=50                 counts / loop / temporary cells
y=101..146, x=0..4   stone table
y=300..352, x=0      hidden+visible timeline
```

Бул аймактар reference process'инин гана менчиги; production аларды окубайт жана process аралык shared cache жок.
