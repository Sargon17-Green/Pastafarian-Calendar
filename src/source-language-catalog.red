Red [
    Title: "Замрзнути каталог изворног језика"
]

source-language-catalog-version: "1.0.0-stage1"
source-language-catalog-frozen?: true

make-cutlet-source-names: func [/local out] [
    out: reduce [
        make object! [canonicalIndex: 1  text: copy "бронза"]
        make object! [canonicalIndex: 2  text: copy "лисица"]
        make object! [canonicalIndex: 3  text: copy "бубрег"]
        make object! [canonicalIndex: 4  text: copy "ариш"]
        make object! [canonicalIndex: 5  text: copy "мисао"]
        make object! [canonicalIndex: 6  text: copy "четири дела од девет"]
        make object! [canonicalIndex: 7  text: copy "Палгураш"]
        make object! [canonicalIndex: 8  text: copy "папирус"]
        make object! [canonicalIndex: 9  text: copy "грозд"]
        make object! [canonicalIndex: 10 text: copy "шкорпион"]
        make object! [canonicalIndex: 11 text: copy "пепео"]
        make object! [canonicalIndex: 12 text: copy "пшеница"]
        make object! [canonicalIndex: 13 text: copy "река"]
        make object! [canonicalIndex: 14 text: copy "смех"]
        make object! [canonicalIndex: 15 text: copy "Акад"]
        make object! [canonicalIndex: 16 text: copy "рог"]
        make object! [canonicalIndex: 17 text: copy "празан крчаг"]
    ]
    out
]

make-month-source-names: func [/local out] [
    out: reduce [
        make object! [canonicalIndex: 1  text: copy "глина"]
        make object! [canonicalIndex: 2  text: copy "нар"]
        make object! [canonicalIndex: 3  text: copy "лакат"]
        make object! [canonicalIndex: 4  text: copy "завист"]
        make object! [canonicalIndex: 5  text: copy "Ериду"]
        make object! [canonicalIndex: 6  text: copy "паста за зубе"]
        make object! [canonicalIndex: 7  text: copy "три дела од пет"]
        make object! [canonicalIndex: 8  text: copy "Каршумаб"]
        make object! [canonicalIndex: 9  text: copy "леопард"]
        make object! [canonicalIndex: 10 text: copy "калај"]
        make object! [canonicalIndex: 11 text: copy "магла"]
        make object! [canonicalIndex: 12 text: copy "тамјан"]
        make object! [canonicalIndex: 13 text: copy "вретено"]
        make object! [canonicalIndex: 14 text: copy "ребро"]
        make object! [canonicalIndex: 15 text: copy "рогач"]
        make object! [canonicalIndex: 16 text: copy "Урук"]
        make object! [canonicalIndex: 17 text: copy "стид"]
        make object! [canonicalIndex: 18 text: copy "камила"]
        make object! [canonicalIndex: 19 text: copy "бакар"]
        make object! [canonicalIndex: 20 text: copy "бунар"]
        make object! [canonicalIndex: 21 text: copy "жуманце"]
        make object! [canonicalIndex: 22 text: copy "звезда"]
        make object! [canonicalIndex: 23 text: copy "мед"]
        make object! [canonicalIndex: 24 text: copy "слезина"]
        make object! [canonicalIndex: 25 text: copy "кречњак"]
        make object! [canonicalIndex: 26 text: copy "радост"]
        make object! [canonicalIndex: 27 text: copy "смоква"]
        make object! [canonicalIndex: 28 text: copy "Нинива"]
        make object! [canonicalIndex: 29 text: copy "жаба"]
        make object! [canonicalIndex: 30 text: copy "катран"]
        make object! [canonicalIndex: 31 text: copy "свећа"]
        make object! [canonicalIndex: 32 text: copy "затворена врата"]
        make object! [canonicalIndex: 33 text: copy "сусам"]
        make object! [canonicalIndex: 34 text: copy "потиљак"]
        make object! [canonicalIndex: 35 text: copy "сребро"]
        make object! [canonicalIndex: 36 text: copy "љиљан"]
        make object! [canonicalIndex: 37 text: copy "олуја"]
        make object! [canonicalIndex: 38 text: copy "магарац"]
        make object! [canonicalIndex: 39 text: copy "брашно"]
        make object! [canonicalIndex: 40 text: copy "кајање"]
        make object! [canonicalIndex: 41 text: copy "Вавилон"]
        make object! [canonicalIndex: 42 text: copy "језик"]
        make object! [canonicalIndex: 43 text: copy "лан"]
        make object! [canonicalIndex: 44 text: copy "со"]
        make object! [canonicalIndex: 45 text: copy "крушка"]
        make object! [canonicalIndex: 46 text: copy "лук"]
        make object! [canonicalIndex: 47 text: copy "песак"]
    ]
    out
]

source-language-catalog-snapshot: func [/local catalog] [
    catalog: make object! [cutlets: none months: none]
    catalog/cutlets: make-cutlet-source-names
    catalog/months: make-month-source-names
    catalog
]

catalog-name-at: func [catalog [block!] canonical-index [integer!] /local item] [
    if any [canonical-index < 1 canonical-index > length? catalog] [return none]
    item: pick catalog canonical-index
    if item/canonicalIndex <> canonical-index [return none]
    copy item/text
]

cutlet-name-at: func [canonical-index [integer!] /local catalog] [
    catalog: make-cutlet-source-names
    catalog-name-at catalog canonical-index
]

month-name-at: func [canonical-index [integer!] /local catalog] [
    catalog: make-month-source-names
    catalog-name-at catalog canonical-index
]
