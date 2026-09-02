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
        print rejoin ["PASS — " name]
    ][
        stage01-failed: stage01-failed + 1
        print rejoin ["FAIL — " name]
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

stage01-check-catalog: func [/local ok i item seen key] [
    ok: all [length? cutlet-source-names = 17 length? month-source-names = 47]
    seen: make map! []
    i: 1
    while [i <= length? cutlet-source-names] [
        item: pick cutlet-source-names i
        if item/canonicalIndex <> i [ok: false]
        key: form item/canonicalIndex
        if not none? select seen key [ok: false]
        put seen key true
        i: i + 1
    ]
    seen: make map! []
    i: 1
    while [i <= length? month-source-names] [
        item: pick month-source-names i
        if item/canonicalIndex <> i [ok: false]
        key: form item/canonicalIndex
        if not none? select seen key [ok: false]
        put seen key true
        i: i + 1
    ]
    stage01-report ok "Каталог има тачно 17+47 стабилних canonicalIndex вредности" true ok
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

smoke-hidden: norm-build-hidden-drops same-counts norm-stones
stage01-check-equal "Нормативна референца гради седам скривених капи" 7 length? smoke-hidden
smoke-visible: norm-build-visible-drops same-counts norm-stones smoke-hidden
stage01-check-equal "Нормативна референца гради четрдесет шест видљивих капи" 46 length? smoke-visible
smoke-bowls: norm-initial-bowls same-counts
stage01-check-equal "Почетно стање има шест чинија" 6 length? smoke-bowls
smoke-after-drops: norm-apply-visible-drops-to-bowls smoke-bowls smoke-visible norm-stones
stage01-check-equal "После капи остаје шест чинија" 6 length? smoke-after-drops/bowls
stage01-check-equal "Редослед код 46. капи има шест идентификатора" 6 length? smoke-after-drops/orderAtDrop46
smoke-final-bowls: norm-post-stir12 smoke-after-drops/bowls
stage01-check-equal "После дванаест завршних мешања остаје шест чинија" 6 length? smoke-final-bowls

stage01-check-bi-block-small "Први ред камења је тачан" fixture-stone-row-1 pick norm-stones 1
stage01-check-bi-block-small "Други ред камења користи један стари снимак стања" fixture-stone-row-2 pick norm-stones 2
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
stage01-check-no-future-scars

print ""
print rejoin ["Прва етапа — успешни тестови: " stage01-passed]
print rejoin ["Прва етапа — неуспешни тестови: " stage01-failed]

either stage01-failed = 0 [
    print "STAGE_01_RESULT=GREEN"
][
    print "STAGE_01_RESULT=UNEXPECTED_RED"
]
