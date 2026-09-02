Red [
    Title: "Испитни оквир прве етапе"
]

do %src/bigint.red
do %src/source-language-catalog.red
do %src/base-monster.red
do %test/fixtures.red
do %test/normative-oracle.red

stage01-passed: 0
stage01-failed: 0

stage01-report: func [ok [logic!] name [string!] expected actual] [
    either ok [
        stage01-passed: stage01-passed + 1
        print rejoin ["ПРОШАО — " name]
    ][
        stage01-failed: stage01-failed + 1
        print rejoin ["ПАО — " name]
        print rejoin ["  очекивано: " mold expected]
        print rejoin ["  добијено:  " mold actual]
    ]
]

stage01-check-equal: func [name [string!] expected actual] [
    stage01-report expected = actual name expected actual
]

stage01-check-bi: func [name [string!] expected-decimal [string!] actual /local actual-decimal] [
    actual-decimal: bi-to-decimal actual
    stage01-report expected-decimal = actual-decimal name expected-decimal actual-decimal
]

stage01-check-bi-block-small: func [name [string!] expected [block!] actual [block!] /local converted item] [
    converted: copy []
    foreach item actual [append converted bi-to-small item]
    stage01-report expected = converted name expected converted
]

stage01-sauce-signature: func [sauce-result /local out item] [
    out: copy []
    foreach item sauce-result/bowls [append/only out bi-to-decimal item]
    append/only out copy sauce-result/orderAtDrop46
    out
]

stage01-check-catalog: func [/local ok i item seen key catalog snapshot-a snapshot-b text-a] [
    catalog: source-language-catalog-snapshot
    ok: all [length? catalog/cutlets = 17 length? catalog/months = 47]
    seen: make map! []
    i: 1
    while [i <= length? catalog/cutlets] [
        item: pick catalog/cutlets i
        if item/canonicalIndex <> i [ok: false]
        key: form item/canonicalIndex
        if not none? select seen key [ok: false]
        put seen key true
        i: i + 1
    ]
    seen: make map! []
    i: 1
    while [i <= length? catalog/months] [
        item: pick catalog/months i
        if item/canonicalIndex <> i [ok: false]
        key: form item/canonicalIndex
        if not none? select seen key [ok: false]
        put seen key true
        i: i + 1
    ]
    stage01-report ok "Каталог има тачно 17+47 стабилних canonicalIndex вредности" true ok
    stage01-check-equal "Каталог изворног језика има замрзнуту верзију прве етапе" "1.0.0-stage1" source-language-catalog-version
    stage01-check-equal "Каталог изворног језика је означен као замрзнут" true source-language-catalog-frozen?

    snapshot-a: source-language-catalog-snapshot
    snapshot-b: source-language-catalog-snapshot
    text-a: (pick snapshot-a/cutlets 1)/text
    append text-a "-измењено"
    stage01-check-equal "Измена једног снимка каталога не мења други снимак" "бронза" (pick snapshot-b/cutlets 1)/text
    stage01-check-equal "Измена враћене ниске не мења канонски српски назив" "бронза" cutlet-name-at 1
]

stage01-check-no-future-scars: func [/local source forbidden word found] [
    source: read %src/base-monster.red
    forbidden: [
        "oldRemainder" "oldDayTag" "oldDistance" "mutateStonesWrong"
        "legacyPrior" "orderAt46Latch" "biasedLegacyPick" "oldGateQuestionDay"
        "LEGACY_YEAR_MAX" "oldJumpGuess" "VirtualLegacyList"
        "legacyChooseEachDaySeparately" "oldContiguousMonthDayGuess"
    ]
    found: false
    foreach word forbidden [if find source word [found: true]]
    stage01-report not found "Почетна производна етапа не садржи код будућих наслеђених ожиљака" false found
]

stage01-check-bigint-ownership: func [/local original cloned] [
    original: bi-from-decimal "12345678901234567890"
    cloned: bi-copy original
    poke cloned/digits 1 9999
    stage01-check-bi "Копија великог целог броја не дели низ цифара са извором" "12345678901234567890" original
    stage01-check-bi "Најмањи уграђени цео број се претвара без преливања" "-2147483648" bi-from-integer -2147483648
]

stage01-check-base-ownership: func [/local external a b seed candidate committed-after-failure retry-result first-pending retry-first nested-input nested-inner nested-text nested-context expected-nested logged-payload logged-inner logged-entry logged-copy object-seed object-context object-pending owned-map map-inner map-copy] [
    external: bi-from-integer 123
    a: make-base-context external bi-from-integer 456
    b: make-base-context external bi-from-integer 456
    poke external/digits 1 999
    stage01-check-bi "Контекст преузима сопствену копију улазног великог целог броја" "123" a/calculationDay

    nested-input: reduce [copy [1 2] copy "текст"]
    expected-nested: reduce [copy [1 2] copy "текст"]
    nested-context: make-base-context nested-input nested-input
    nested-inner: first nested-input
    append nested-inner 3
    nested-text: second nested-input
    append nested-text "-измењен"
    stage01-check-equal "Контекст дубоко копира улазне низове и угнежђене низове" expected-nested nested-context/calculationDay

    logged-payload: reduce [copy [9 8]]
    log-observation a/logs "копија-посматрања" logged-payload
    logged-inner: first logged-payload
    append logged-inner 7
    logged-entry: last a/logs
    logged-copy: second logged-entry
    stage01-check-equal "Дневник чува сопствену дубоку копију посматрачког садржаја" [9 8] first logged-copy

    append/only a/branchTrace 'само-а
    metrics-bump a/metrics "само-а"
    log-observation a/logs "само-а" [1 2 3]
    stage01-check-equal "Два производна контекста не деле низ трагова грана" 0 length? b/branchTrace
    stage01-check-equal "Два производна контекста не деле мапу метрика" none select b/metrics/counters "само-а"
    stage01-check-equal "Два производна контекста не деле низ дневника" 0 length? b/logs

    seed: reduce [copy [1 2] copy [3 4]]
    candidate: reduce [copy [5 6] copy [7 8]]
    base-semantic-seed a seed
    base-semantic-begin a candidate
    first-pending: first a/semanticPending
    append first-pending 999
    stage01-check-equal "Мутација стања на чекању не мења потврђени снимак" seed a/semanticCommitted
    stage01-check-equal "Мутација стања на чекању не мења улазног кандидата" reduce [copy [5 6] copy [7 8]] candidate
    committed-after-failure: base-semantic-rollback a
    stage01-check-equal "Неуспех и враћање снимка обнављају тачно последње потврђено стање" seed committed-after-failure
    stage01-check-equal "Враћање снимка чисти стање на чекању" none a/semanticPending
    stage01-check-equal "Враћање снимка бележи један покушај без семантичког утицаја" 1 a/retryCount

    base-semantic-begin a candidate
    retry-result: base-semantic-commit a
    stage01-check-equal "Поновни покушај истог кандидата после враћања снимка потврђује исти резултат" candidate retry-result
    retry-first: first retry-result
    append retry-first 1000
    stage01-check-equal "Враћена копија потврђеног снимка не може накнадно да измени потврђено стање" candidate a/semanticCommitted
    stage01-check-equal "Неуспех и поновни покушај у једном контексту не мењају семантичко стање другог" none b/semanticCommitted

    object-seed: make object! [nested: copy [11 12]]
    object-context: make-base-context bi-zero bi-one
    base-semantic-seed object-context object-seed
    object-pending: base-semantic-begin object-context object-seed
    append object-pending/nested 13
    stage01-check-equal "Дубока копија семантичког објекта раздваја угнежђени низ" [11 12] object-context/semanticCommitted/nested

    owned-map: make map! []
    map-inner: copy [21 22]
    put owned-map "кључ" map-inner
    map-copy: base-owned-copy owned-map
    append map-inner 23
    stage01-check-equal "Дубока копија мапе раздваја угнежђени низ" [21 22] select map-copy "кључ"
]

stage01-check-oracle-ownership: func [/local ctx sauce-a1 sauce-b sauce-a2 fresh sauce-a-fresh sig-a1 sig-a2 sig-fresh gate-a1 gate-minus gate-a1-again gate-fresh dirty clean dirty-row clean-row family-a family-b cutlet-a cutlet-b weave-a weave-b] [
    ctx: norm-make-oracle-context
    sauce-a1: norm-sauce ctx norm-foundation-day norm-foundation-day
    sauce-b: norm-sauce ctx norm-foundation-day bi-add-small norm-foundation-day 1
    sauce-a2: norm-sauce ctx norm-foundation-day norm-foundation-day
    sig-a1: stage01-sauce-signature sauce-a1
    sig-a2: stage01-sauce-signature sauce-a2
    stage01-check-equal "Нормативна референца A→B→A остаје детерминистична у истом контексту" sig-a1 sig-a2

    fresh: norm-make-oracle-context
    sauce-a-fresh: norm-sauce fresh norm-foundation-day norm-foundation-day
    sig-fresh: stage01-sauce-signature sauce-a-fresh
    stage01-check-equal "Поновљени позив нормативне референце у новом контексту даје исти резултат" sig-a1 sig-fresh

    gate-a1: norm-ensure-gate-index ctx bi-one
    gate-minus: norm-ensure-gate-index ctx bi-from-integer -1
    gate-a1-again: norm-ensure-gate-index ctx bi-one
    stage01-check-bi "Ширење кеша на супротну страну не мења већ израчунату капију" bi-to-decimal gate-a1 gate-a1-again
    fresh: norm-make-oracle-context
    gate-fresh: norm-ensure-gate-index fresh bi-one
    stage01-check-bi "Нови контекст нормативне референце не наслеђује кеш капија претходног позива" bi-to-decimal gate-a1 gate-fresh

    dirty: norm-make-oracle-context
    clean: norm-make-oracle-context
    dirty-row: pick dirty/stones 1
    poke dirty-row 1 bi-from-integer 999
    put dirty/gates/values "0" bi-from-integer 999
    clean-row: pick clean/stones 1
    stage01-check-bi "Мутација табеле каменова једног контекста нормативне референце не цури у други" "17" pick clean-row 1
    stage01-check-bi "Мутација мапе капија једног контекста нормативне референце не цури у други" "-15055671" norm-gate-get clean bi-zero

    family-a: norm-make-bounded-family 6 2 1 5
    family-b: norm-make-bounded-family 6 2 1 5
    norm-bounded-count family-a
    put family-a/memo "6:2" bi-from-integer 999
    stage01-check-bi "Мемоизација динамичког програмирања једне породице не дели мапу са другом породицом" fixture-bounded-count-6-2-1-5 norm-bounded-count family-b

    cutlet-a: norm-make-cutlet-partition-family 5 2 2
    cutlet-b: norm-make-cutlet-partition-family 5 2 2
    norm-cutlet-family-count cutlet-a
    put cutlet-a/memo "5:2:0:0" bi-from-integer 999
    stage01-check-bi "Мемоизација поделе котлета припада само својој породици" "1" norm-cutlet-family-count cutlet-b

    weave-a: norm-make-weave-family [2 2]
    weave-b: norm-make-weave-family [2 2]
    norm-weave-count weave-a
    clear weave-a/lengths
    stage01-check-bi "Стање једне породице преплитања не мења другу породицу" "2" norm-weave-count weave-b
]

stage01-run: func [/local same-counts smoke-context smoke-stones smoke-hidden smoke-visible smoke-bowls smoke-after-drops smoke-final-bowls bounded weave-family cutlet-filter-family stream-forward stream-backward rejection-stream wide-n ctx] [
    stage01-check-equal "Размак између дана таблица и дана оснивања" fixture-tablets-distance fixture-tablets-day - fixture-foundation-day
    stage01-check-bi "M је тачан" fixture-M-decimal norm-M
    stage01-check-bi "SAVE(1)=1" "1" norm-save bi-one
    stage01-check-bi "SAVE(M)=M" fixture-M-decimal norm-save norm-M
    stage01-check-bi "SAVE(2M)=M" fixture-M-decimal norm-save bi-mul-small norm-M 2
    stage01-check-bi "SAVE(3M)=M" fixture-M-decimal norm-save bi-mul-small norm-M 3
    stage01-check-bi "SAVE(0)=M" fixture-M-decimal norm-save bi-zero
    stage01-check-bi "SAVE(M+1)=1" "1" norm-save bi-add-small norm-M 1
    stage01-check-bi "SAVE(-1)=M-1" "170141183460469231731687303715884105726" norm-save bi-from-integer -1
    
    stage01-check-bi "dayCount(FOUNDATION)=1" "1" norm-day-count norm-foundation-day
    stage01-check-bi "dayCount(FOUNDATION-1)=2" "2" norm-day-count bi-sub-small norm-foundation-day 1
    stage01-check-bi "dayCount(FOUNDATION+1)=3" "3" norm-day-count bi-add-small norm-foundation-day 1
    
    same-counts: norm-work-counts norm-foundation-day norm-foundation-day
    stage01-check-bi "Када је c=t, растојање је 1" "1" same-counts/distance
    stage01-check-equal "Када је c=t, смер је 2" 2 same-counts/direction
    
    smoke-context: norm-make-oracle-context
    smoke-stones: smoke-context/stones
    smoke-hidden: norm-build-hidden-drops same-counts smoke-stones
    stage01-check-equal "Нормативна референца гради седам скривених капи" 7 length? smoke-hidden
    smoke-visible: norm-build-visible-drops same-counts smoke-stones smoke-hidden
    stage01-check-equal "Нормативна референца гради четрдесет шест видљивих капи" 46 length? smoke-visible
    smoke-bowls: norm-initial-bowls same-counts
    stage01-check-equal "Почетно стање има шест чинија" 6 length? smoke-bowls
    smoke-after-drops: norm-apply-visible-drops-to-bowls smoke-bowls smoke-visible smoke-stones
    stage01-check-equal "После капи остаје шест чинија" 6 length? smoke-after-drops/bowls
    stage01-check-equal "Редослед код 46. капи има шест идентификатора" 6 length? smoke-after-drops/orderAtDrop46
    smoke-final-bowls: norm-post-stir12 smoke-after-drops/bowls
    stage01-check-equal "После дванаест завршних мешања остаје шест чинија" 6 length? smoke-final-bowls
    
    stage01-check-bi-block-small "Први ред камења је тачан" fixture-stone-row-1 pick smoke-stones 1
    stage01-check-bi-block-small "Други ред камења користи један стари снимак стања" fixture-stone-row-2 pick smoke-stones 2
    stage01-check-equal "Пермутација ранга 1" fixture-permutation-rank-1 norm-permutation-unrank1 1 [1 2 3 4 5 6]
    stage01-check-equal "Пермутација ранга 720" fixture-permutation-rank-720 norm-permutation-unrank1 720 [1 2 3 4 5 6]
    
    stage01-check-catalog
    stage01-check-equal "Канонски индекс 12 котлета даје српску реч за пшеницу" fixture-cutlet-name-12 cutlet-name-at 12
    stage01-check-equal "Канонски индекс 6 месеца даје природан српски назив" fixture-month-name-6 month-name-at 6
    
    bounded: norm-make-bounded-family 6 2 1 5
    stage01-check-bi "Мала породица ограничених композиција има тачан број" fixture-bounded-count-6-2-1-5 norm-bounded-count bounded
    stage01-check-equal "Прва ограничена композиција је лексикографски тачна" fixture-bounded-first-6-2-1-5 norm-bounded-unrank1 bounded bi-one
    stage01-check-equal "Последња ограничена композиција је лексикографски тачна" fixture-bounded-last-6-2-1-5 norm-bounded-unrank1 bounded bi-from-integer 5
    
    weave-family: norm-make-weave-family [2 2]
    stage01-check-bi "Мала породица преплитања има тачан број" fixture-weave-count-2-2 norm-weave-count weave-family
    stage01-check-equal "Прво преплитање је лексикографски тачно" fixture-weave-first-2-2 norm-weave-unrank1 weave-family bi-one
    stage01-check-equal "Друго преплитање је лексикографски тачно" fixture-weave-second-2-2 norm-weave-unrank1 weave-family bi-from-integer 2
    
    cutlet-filter-family: norm-make-cutlet-partition-family 5 2 2
    stage01-check-bi "Филтер унутрашње капије оставља тачан број композиција" "1" norm-cutlet-family-count cutlet-filter-family
    stage01-check-equal "Филтер унутрашње капије чува лексикографски исправан члан" [2 3] norm-cutlet-family-unrank1 cutlet-filter-family bi-one
    
    stage01-check-equal "Први ранг различитих имена чува канонски ред" [1 2] norm-unrank-distinct-indices 3 2 bi-one
    stage01-check-equal "Последњи ранг различитих имена чува канонски ред" [3 2] norm-unrank-distinct-indices 3 2 bi-from-integer 6
    
    stream-forward: make object! [first: bi-one directionStep: 1]
    stream-backward: make object! [first: bi-one directionStep: -1]
    stage01-check-bi "Кружни низ одговора унапред почиње са 1" "1" norm-answer-at stream-forward 0
    stage01-check-bi "Кружни низ одговора унапред наставља са 2" "2" norm-answer-at stream-forward 1
    stage01-check-bi "Кружни низ одговора уназад после 1 даје M" fixture-M-decimal norm-answer-at stream-backward 1
    stage01-check-bi "Кратак избор за N=1 увек даје ранг 1" "1" norm-choose-rank stream-forward bi-one
    stage01-check-bi "Кратак избор за N=M и први одговор 1 даје ранг 1" "1" norm-choose-rank stream-forward norm-M
    rejection-stream: make object! [first: bi-copy norm-M directionStep: 1]
    stage01-check-bi "Кратко одбијање наставља истим кружним низом" "1" norm-choose-rank rejection-stream bi-from-integer 10
    wide-n: bi-add-small norm-M 1
    stage01-check-bi "Широк избор за N=M+1 користи широки број" bi-to-decimal wide-n norm-choose-rank stream-forward wide-n
    
    ctx: make-base-context bi-zero bi-one
    stage01-check-equal "Основни контекст припада једном позиву и прихвата оба улаза" true base-validate-input ctx
    stage01-check-equal "Производни костур у почетној етапи не враћа нормативни резултат" none calendarDateSpaghetti bi-zero bi-one
    stage01-check-bigint-ownership
    stage01-check-base-ownership
    stage01-check-oracle-ownership
    stage01-check-no-future-scars
    
    print ""
    print rejoin ["Прва етапа — успешни тестови: " stage01-passed]
    print rejoin ["Прва етапа — неуспешни тестови: " stage01-failed]
    
    either stage01-failed = 0 [
        print "STAGE_01_RESULT=GREEN"
    ][
        print "STAGE_01_RESULT=UNEXPECTED_RED"
    ]
]

stage01-run
