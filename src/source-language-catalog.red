Red [
    Title: "Замрзнути каталог изворног језика"
]

source-language-catalog-version: "1.0.0-stage1"
source-language-catalog-frozen?: true

cutlet-source-names: reduce [
    make object! [canonicalIndex: 1  text: "бронза"]
    make object! [canonicalIndex: 2  text: "лисица"]
    make object! [canonicalIndex: 3  text: "бубрег"]
    make object! [canonicalIndex: 4  text: "ариш"]
    make object! [canonicalIndex: 5  text: "мисао"]
    make object! [canonicalIndex: 6  text: "четири дела од девет"]
    make object! [canonicalIndex: 7  text: "Палгураш"]
    make object! [canonicalIndex: 8  text: "папирус"]
    make object! [canonicalIndex: 9  text: "грозд"]
    make object! [canonicalIndex: 10 text: "шкорпион"]
    make object! [canonicalIndex: 11 text: "пепео"]
    make object! [canonicalIndex: 12 text: "пшеница"]
    make object! [canonicalIndex: 13 text: "река"]
    make object! [canonicalIndex: 14 text: "смех"]
    make object! [canonicalIndex: 15 text: "Акад"]
    make object! [canonicalIndex: 16 text: "рог"]
    make object! [canonicalIndex: 17 text: "празан крчаг"]
]

month-source-names: reduce [
    make object! [canonicalIndex: 1  text: "глина"]
    make object! [canonicalIndex: 2  text: "нар"]
    make object! [canonicalIndex: 3  text: "лакат"]
    make object! [canonicalIndex: 4  text: "завист"]
    make object! [canonicalIndex: 5  text: "Ериду"]
    make object! [canonicalIndex: 6  text: "паста за зубе"]
    make object! [canonicalIndex: 7  text: "три дела од пет"]
    make object! [canonicalIndex: 8  text: "Каршумаб"]
    make object! [canonicalIndex: 9  text: "леопард"]
    make object! [canonicalIndex: 10 text: "калај"]
    make object! [canonicalIndex: 11 text: "магла"]
    make object! [canonicalIndex: 12 text: "тамјан"]
    make object! [canonicalIndex: 13 text: "вретено"]
    make object! [canonicalIndex: 14 text: "ребро"]
    make object! [canonicalIndex: 15 text: "рогач"]
    make object! [canonicalIndex: 16 text: "Урук"]
    make object! [canonicalIndex: 17 text: "стид"]
    make object! [canonicalIndex: 18 text: "камила"]
    make object! [canonicalIndex: 19 text: "бакар"]
    make object! [canonicalIndex: 20 text: "бунар"]
    make object! [canonicalIndex: 21 text: "жуманце"]
    make object! [canonicalIndex: 22 text: "звезда"]
    make object! [canonicalIndex: 23 text: "мед"]
    make object! [canonicalIndex: 24 text: "слезина"]
    make object! [canonicalIndex: 25 text: "кречњак"]
    make object! [canonicalIndex: 26 text: "радост"]
    make object! [canonicalIndex: 27 text: "смоква"]
    make object! [canonicalIndex: 28 text: "Нинива"]
    make object! [canonicalIndex: 29 text: "жаба"]
    make object! [canonicalIndex: 30 text: "катран"]
    make object! [canonicalIndex: 31 text: "свећа"]
    make object! [canonicalIndex: 32 text: "затворена врата"]
    make object! [canonicalIndex: 33 text: "сусам"]
    make object! [canonicalIndex: 34 text: "потиљак"]
    make object! [canonicalIndex: 35 text: "сребро"]
    make object! [canonicalIndex: 36 text: "љиљан"]
    make object! [canonicalIndex: 37 text: "олуја"]
    make object! [canonicalIndex: 38 text: "магарац"]
    make object! [canonicalIndex: 39 text: "брашно"]
    make object! [canonicalIndex: 40 text: "кајање"]
    make object! [canonicalIndex: 41 text: "Вавилон"]
    make object! [canonicalIndex: 42 text: "језик"]
    make object! [canonicalIndex: 43 text: "лан"]
    make object! [canonicalIndex: 44 text: "со"]
    make object! [canonicalIndex: 45 text: "крушка"]
    make object! [canonicalIndex: 46 text: "лук"]
    make object! [canonicalIndex: 47 text: "песак"]
]

catalog-name-at: func [catalog [block!] canonical-index [integer!]] [
    if any [canonical-index < 1 canonical-index > length? catalog] [return none]
    item: pick catalog canonical-index
    if item/canonicalIndex <> canonical-index [return none]
    item/text
]

cutlet-name-at: func [canonical-index [integer!]] [
    catalog-name-at cutlet-source-names canonical-index
]

month-name-at: func [canonical-index [integer!]] [
    catalog-name-at month-source-names canonical-index
]
