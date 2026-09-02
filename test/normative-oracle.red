Red [
    Title: "Чиста нормативна референца за тестове"
]

norm-M: bi-from-decimal "170141183460469231731687303715884105727"
norm-tablets-day: bi-from-integer -278522
norm-foundation-day: bi-from-integer -15055671

norm-gate-gap-min: 42
norm-gate-gap-max: 963
norm-year-min-days: 252
norm-year-max-days: 5778
norm-min-cutlets: 6
norm-max-cutlets: 17
norm-min-months: 3
norm-max-months: 47
norm-min-month-days: 4
norm-max-month-days: 123

norm-seal-gate-gap: 1
norm-seal-year-5000: 10
norm-seal-next-year: 11
norm-seal-previous-year: 12
norm-seal-cutlet-count: 20
norm-seal-cutlet-partition: 21
norm-seal-cutlet-names: 22
norm-seal-month-count: 30
norm-seal-month-lengths: 31
norm-seal-month-weaving: 32
norm-seal-month-names: 33

norm-wheat: 1
norm-barley: 2
norm-salt: 3
norm-bitter: 4
norm-red: 5

norm-save: func [x /local r] [
    r: bi-regular-mod x norm-M
    either bi-zero? r [bi-copy norm-M] [r]
]

norm-wrap1: func [position [integer!] size [integer!]] [
    ((position - 1) // size) + 1
]

norm-ceil-div-small: func [a [integer!] b [integer!]] [
    (a + b - 1) / b
]

norm-day-count: func [day /local cmp d] [
    cmp: bi-compare day norm-foundation-day
    if cmp = 0 [return bi-one]
    d: bi-abs bi-sub day norm-foundation-day
    d: bi-mul-small d 2
    if cmp > 0 [d: bi-add-small d 1]
    d
]

norm-work-counts: func [calculation-day target-day /local c t distance connection direction result] [
    c: norm-day-count calculation-day
    t: norm-day-count target-day
    distance: bi-add-small bi-abs bi-sub target-day calculation-day 1
    connection: bi-add c t
    direction: 2
    if bi-lt? target-day calculation-day [direction: 1]
    if bi-gt? target-day calculation-day [direction: 3]
    result: make object! [action: none target: none distance: none connection: none direction: 0]
    result/action: c
    result/target: t
    result/distance: distance
    result/connection: connection
    result/direction: direction
    result
]

norm-stone-row: func [w b s m r] [reduce [w b s m r]]

norm-build-stones: func [/local table old i nw nb ns nm nr] [
    table: copy []
    append/only table norm-stone-row
        bi-from-integer 17
        bi-from-integer 29
        bi-from-integer 43
        bi-from-integer 71
        bi-from-integer 101
    i: 2
    while [i <= 46] [
        old: pick table i - 1
        nw: norm-save bi-sum reduce [
            bi-square pick old norm-wheat
            bi-mul-small pick old norm-barley 3
            bi-from-integer i
        ]
        nb: norm-save bi-sum reduce [
            bi-square pick old norm-barley
            bi-mul-small pick old norm-salt 5
            bi-copy pick old norm-wheat
        ]
        ns: norm-save bi-sum reduce [
            bi-square pick old norm-salt
            bi-mul-small pick old norm-bitter 7
            bi-copy pick old norm-barley
        ]
        nm: norm-save bi-sum reduce [
            bi-square pick old norm-bitter
            bi-mul-small pick old norm-red 11
            bi-copy pick old norm-salt
        ]
        nr: norm-save bi-sum reduce [
            bi-square pick old norm-red
            bi-mul-small pick old norm-wheat 13
            bi-copy pick old norm-bitter
        ]
        append/only table norm-stone-row nw nb ns nm nr
        i: i + 1
    ]
    table
]

norm-stones: norm-build-stones

norm-hidden-coeff: [
    [3 4 6 8]
    [5 7 10 12]
    [7 10 14 16]
    [9 13 18 20]
    [11 16 22 24]
    [13 19 26 28]
    [15 22 30 32]
]

norm-hidden-grind-stone: reduce [norm-wheat norm-barley norm-salt norm-bitter norm-red norm-wheat norm-barley]

norm-build-hidden-drops: func [counts stones /local hidden k coeff x grind oldx stone-row stone-kind] [
    hidden: copy []
    k: 1
    while [k <= 7] [
        coeff: pick norm-hidden-coeff k
        stone-row: pick stones k
        x: bi-sum reduce [
            bi-copy counts/action
            bi-mul-small counts/target pick coeff 1
            bi-mul-small counts/distance pick coeff 2
            bi-mul-small counts/connection pick coeff 3
            bi-mul-small bi-from-integer counts/direction pick coeff 4
            bi-copy pick stone-row norm-wheat
            bi-copy pick stone-row norm-barley
            bi-copy pick stone-row norm-salt
            bi-copy pick stone-row norm-bitter
            bi-copy pick stone-row norm-red
        ]
        x: norm-save x
        grind: 1
        while [grind <= 7] [
            oldx: x
            stone-kind: pick norm-hidden-grind-stone grind
            x: norm-save bi-sum reduce [
                bi-square oldx
                bi-mul-small oldx 3
                bi-copy pick stone-row stone-kind
                bi-from-integer grind
            ]
            grind: grind + 1
        ]
        append/only hidden x
        k: k + 1
    ]
    hidden
]

norm-visible-grinds: reduce [
    reduce [3 5 7 11 norm-wheat]
    reduce [5 7 11 13 norm-barley]
    reduce [7 11 13 17 norm-salt]
    reduce [11 13 17 19 norm-bitter]
    reduce [13 17 19 23 norm-red]
    reduce [17 19 23 29 norm-wheat]
    reduce [19 23 29 31 norm-barley]
    reduce [23 29 31 37 norm-salt]
    reduce [29 31 37 41 norm-bitter]
    reduce [31 37 41 43 norm-red]
    reduce [37 41 43 47 norm-wheat]
]

norm-prior-drop: func [visible hidden i [integer!] back [integer!] /local slot k] [
    slot: i - back
    if slot >= 1 [return bi-copy pick visible slot]
    k: 1 - slot
    bi-copy pick hidden k
]

norm-build-visible-drops: func [counts stones hidden /local visible i p1 p3 p7 row stone-row x grind oldx] [
    visible: copy []
    i: 1
    while [i <= 46] [
        p1: norm-prior-drop visible hidden i 1
        p3: norm-prior-drop visible hidden i 3
        p7: norm-prior-drop visible hidden i 7
        stone-row: pick stones i
        x: norm-save bi-sum reduce [
            bi-mul pick stone-row norm-wheat counts/action
            bi-mul pick stone-row norm-barley counts/target
            bi-mul pick stone-row norm-salt counts/distance
            bi-mul pick stone-row norm-bitter counts/connection
            bi-mul-small pick stone-row norm-red counts/direction
            p1
            bi-mul-small p3 3
            bi-mul-small p7 5
            bi-from-integer i
        ]
        grind: 1
        while [grind <= 11] [
            row: pick norm-visible-grinds grind
            oldx: x
            x: norm-save bi-sum reduce [
                bi-square oldx
                bi-mul-small oldx pick row 1
                bi-mul-small p1 pick row 2
                bi-mul-small p3 pick row 3
                bi-mul-small p7 pick row 4
                bi-copy pick stone-row pick row 5
            ]
            grind: grind + 1
        ]
        append/only visible x
        i: i + 1
    ]
    visible
]

norm-factorial-small: func [n [integer!] /local r i] [
    r: 1
    i: 2
    while [i <= n] [r: r * i i: i + 1]
    r
]

norm-permutation-unrank1: func [rank1 [integer!] items [block!] /local rank0 remaining result slots-left block-size q chosen] [
    rank0: rank1 - 1
    remaining: copy items
    result: copy []
    slots-left: length? remaining
    while [slots-left >= 1] [
        block-size: norm-factorial-small slots-left - 1
        q: rank0 / block-size
        rank0: rank0 // block-size
        chosen: pick remaining q + 1
        append result chosen
        remove at remaining q + 1
        slots-left: slots-left - 1
    ]
    result
]

norm-bowl-order-from-drop: func [drop /local order-number] [
    order-number: bi-mod-small bi-sub-small drop 1 720
    order-number: order-number + 1
    norm-permutation-unrank1 order-number [1 2 3 4 5 6]
]

norm-initial-bowls: func [counts /local primes bowls id s] [
    primes: [17 19 23 29 31 37]
    bowls: copy []
    id: 1
    while [id <= 6] [
        s: bi-sum reduce [
            bi-copy counts/action
            bi-mul-small counts/target id
            bi-copy counts/distance
            bi-copy counts/connection
            bi-from-integer counts/direction
            bi-from-integer ((pick primes id) * (pick primes id))
        ]
        append/only bowls norm-save bi-add-small bi-square s id
        id: id + 1
    ]
    bowls
]

norm-stir-stone-by-position: reduce [norm-wheat norm-barley norm-salt norm-bitter norm-red norm-wheat]

norm-apply-visible-drops-to-bowls: func [bowls visible stones /local i drop order old first-bowl second-bowl third-bowl pour position bowl-id prev-id next-id stone-kind s next-bowls order46 stone-row result] [
    order46: none
    i: 1
    while [i <= 46] [
        drop: pick visible i
        order: norm-bowl-order-from-drop drop
        old: bi-block-copy bowls
        first-bowl: pick order 1
        second-bowl: pick order 2
        third-bowl: pick order 3
        stone-row: pick stones i
        pour: reduce [
            norm-save bi-sum reduce [bi-square drop bi-mul pick stone-row norm-wheat pick old first-bowl bi-from-integer 3 * i]
            norm-save bi-sum reduce [bi-square drop bi-mul pick stone-row norm-barley pick old second-bowl bi-from-integer 5 * i]
            norm-save bi-sum reduce [bi-square drop bi-mul pick stone-row norm-salt pick old third-bowl bi-from-integer 7 * i]
            bi-zero
            bi-zero
            bi-zero
        ]
        next-bowls: copy []
        repeat position 6 [append/only next-bowls bi-zero]
        position: 1
        while [position <= 6] [
            bowl-id: pick order position
            prev-id: pick order norm-wrap1 position - 1 6
            next-id: pick order norm-wrap1 position + 1 6
            stone-kind: pick norm-stir-stone-by-position position
            s: bi-sum reduce [
                bi-copy pick old bowl-id
                bi-mul-small pick old prev-id 2
                bi-mul-small pick old next-id 3
                bi-copy pick pour position
                bi-copy drop
                bi-copy pick stone-row stone-kind
            ]
            poke next-bowls bowl-id norm-save bi-sum reduce [
                bi-square s
                bi-mul-small bi-mul pick old prev-id pick old next-id 5
                bi-from-integer i * position
            ]
            position: position + 1
        ]
        bowls: next-bowls
        if i = 46 [order46: copy order]
        i: i + 1
    ]
    result: make object! [bowls: none orderAtDrop46: none]
    result/bowls: bowls
    result/orderAtDrop46: order46
    result
]

norm-post-stir12: func [bowls /local stir old saved-sum order-number order position bowl-id prev-id next-id s next-bowls] [
    stir: 1
    while [stir <= 12] [
        old: bi-block-copy bowls
        saved-sum: norm-save bi-add-small bi-sum old 149 * stir
        order-number: (bi-mod-small bi-sub-small saved-sum 1 720) + 1
        order: norm-permutation-unrank1 order-number [1 2 3 4 5 6]
        next-bowls: copy []
        repeat position 6 [append/only next-bowls bi-zero]
        position: 1
        while [position <= 6] [
            bowl-id: pick order position
            prev-id: pick order norm-wrap1 position - 1 6
            next-id: pick order norm-wrap1 position + 1 6
            s: bi-sum reduce [
                bi-copy pick old bowl-id
                bi-mul-small pick old prev-id 3
                bi-mul-small pick old next-id 5
                bi-copy saved-sum
                bi-from-integer stir
                bi-from-integer position * position
            ]
            poke next-bowls bowl-id norm-save bi-sum reduce [
                bi-square s
                bi-mul-small bi-mul pick old prev-id pick old next-id 7
            ]
            position: position + 1
        ]
        bowls: next-bowls
        stir: stir + 1
    ]
    bowls
]

norm-sauce: func [calculation-day target-day /local counts hidden visible bowls after-drops final-bowls] [
    counts: norm-work-counts calculation-day target-day
    hidden: norm-build-hidden-drops counts norm-stones
    visible: norm-build-visible-drops counts norm-stones hidden
    bowls: norm-initial-bowls counts
    after-drops: norm-apply-visible-drops-to-bowls bowls visible norm-stones
    final-bowls: norm-post-stir12 after-drops/bowls
    make object! [
        bowls: final-bowls
        orderAtDrop46: after-drops/orderAtDrop46
    ]
]

norm-next-bowl-in-drop46-order: func [sauce-result queried-bowl-id [integer!] /local order p] [
    order: sauce-result/orderAtDrop46
    p: index? find order queried-bowl-id
    pick order norm-wrap1 p + 1 6
]

norm-ask-bowl: func [sauce-result queried-bowl-id [integer!] seal [integer!] /local next-id first-value direction-number step] [
    next-id: norm-next-bowl-in-drop46-order sauce-result queried-bowl-id
    first-value: norm-save bi-sum reduce [
        bi-square bi-add-small bi-add-small pick sauce-result/bowls queried-bowl-id seal 181
        bi-mul-small pick sauce-result/bowls next-id 179
        bi-from-integer seal
    ]
    direction-number: norm-save bi-sum reduce [
        bi-square bi-add-small bi-add-small bi-add-small first-value seal 1 193
        bi-mul-small first-value 193
        bi-mul-small pick sauce-result/bowls 6 197
    ]
    step: either (bi-mod-small direction-number 2) = 1 [1] [-1]
    make object! [first: first-value directionStep: step]
]

norm-answer-at: func [stream k /local offset delta] [
    offset: either integer? k [bi-from-integer k] [bi-copy k]
    delta: bi-mul-small offset stream/directionStep
    bi-add-small bi-regular-mod bi-add (bi-sub-small stream/first 1) delta norm-M 1
]

norm-choose-rank-short: func [stream n /local acceptance-limit dm k x] [
    dm: bi-divmod-positive norm-M n
    acceptance-limit: bi-mul dm/q n
    k: bi-zero
    while [true] [
        x: norm-answer-at stream k
        if bi-le? x acceptance-limit [
            return bi-add-small bi-regular-mod bi-sub-small x 1 n 1
        ]
        k: bi-inc k
    ]
]

norm-smallest-power-count: func [base n /local k space result] [
    k: 1
    space: bi-copy base
    while [bi-lt? space n] [k: k + 1 space: bi-mul space base]
    result: make object! [places: 0 space: none]
    result/places: k
    result/space: space
    result
]

norm-choose-rank-wide: func [stream n /local info places space wide weight j digit acceptance-limit dm w] [
    info: norm-smallest-power-count norm-M n
    places: info/places
    space: info/space
    wide: bi-one
    weight: bi-one
    j: 0
    while [j < places] [
        digit: bi-sub-small norm-answer-at stream j 1
        wide: bi-add wide bi-mul digit weight
        weight: bi-mul weight norm-M
        j: j + 1
    ]
    dm: bi-divmod-positive space n
    acceptance-limit: bi-mul dm/q n
    w: wide
    while [bi-gt? w acceptance-limit] [
        w: bi-add-small bi-regular-mod bi-add-small bi-sub-small w 1 stream/directionStep space 1
    ]
    bi-add-small bi-regular-mod bi-sub-small w 1 n 1
]

norm-choose-rank: func [stream n] [
    either bi-le? n norm-M [norm-choose-rank-short stream n] [norm-choose-rank-wide stream n]
]

norm-falling-factorial: func [n [integer!] k [integer!] /local r j] [
    r: bi-one
    j: 0
    while [j < k] [r: bi-mul-small r n - j j: j + 1]
    r
]

norm-unrank-distinct-indices: func [master-count [integer!] k [integer!] rank1 /local remaining out r position suffix-length block candidate-index chosen] [
    remaining: copy []
    repeat candidate-index master-count [append remaining candidate-index]
    out: copy []
    r: bi-copy rank1
    position: 1
    while [position <= k] [
        suffix-length: k - position
        block: norm-falling-factorial (length? remaining) - 1 suffix-length
        candidate-index: 1
        while [candidate-index <= length? remaining] [
            either bi-gt? r block [
                r: bi-sub r block
                candidate-index: candidate-index + 1
            ][
                chosen: pick remaining candidate-index
                append out chosen
                remove at remaining candidate-index
                candidate-index: (length? remaining) + 1
            ]
        ]
        position: position + 1
    ]
    out
]

norm-bounded-key: func [rem [integer!] slots [integer!]] [rejoin [rem ":" slots]]

norm-bounded-count-state: func [family rem [integer!] slots [integer!] /local key cached total x] [
    if slots = 0 [return either rem = 0 [bi-one] [bi-zero]]
    if any [rem < slots * family/lo rem > slots * family/hi] [return bi-zero]
    key: norm-bounded-key rem slots
    cached: select family/memo key
    if not none? cached [return bi-copy cached]
    total: bi-zero
    x: family/lo
    while [x <= family/hi] [
        total: bi-add total norm-bounded-count-state family rem - x slots - 1
        x: x + 1
    ]
    put family/memo key bi-copy total
    total
]

norm-make-bounded-family: func [total [integer!] slots [integer!] lo [integer!] hi [integer!] /local family] [
    family: make object! [total: 0 slots: 0 lo: 0 hi: 0 memo: none]
    family/total: total
    family/slots: slots
    family/lo: lo
    family/hi: hi
    family/memo: make map! []
    family
]

norm-bounded-count: func [family] [
    norm-bounded-count-state family family/total family/slots
]

norm-bounded-unrank1: func [family rank1 /local r rem slots position x count out chosen] [
    r: bi-copy rank1
    rem: family/total
    slots: family/slots
    out: copy []
    position: 1
    while [position <= family/slots] [
        x: family/lo
        chosen: false
        while [all [x <= family/hi not chosen]] [
            count: norm-bounded-count-state family rem - x slots - 1
            either bi-gt? r count [
                r: bi-sub r count
                x: x + 1
            ][
                append out x
                rem: rem - x
                slots: slots - 1
                chosen: true
            ]
        ]
        position: position + 1
    ]
    out
]

norm-cutlet-key: func [rem slots cumulative hit] [
    rejoin [rem ":" slots ":" cumulative ":" either hit ["1"] ["0"]]
]

norm-cutlet-count-state: func [family rem [integer!] slots [integer!] cumulative [integer!] hit [logic!] /local key cached total max-x x next-cumulative next-hit] [
    if slots = 0 [
        if rem <> 0 [return bi-zero]
        if none? family/required [return bi-one]
        return either hit [bi-one] [bi-zero]
    ]
    if rem < slots [return bi-zero]
    key: norm-cutlet-key rem slots cumulative hit
    cached: select family/memo key
    if not none? cached [return bi-copy cached]
    total: bi-zero
    max-x: rem - (slots - 1)
    x: 1
    while [x <= max-x] [
        next-cumulative: cumulative + x
        next-hit: hit
        if all [not none? family/required not hit] [
            either next-cumulative = family/required [
                next-hit: true
            ][
                if next-cumulative > family/required [
                    x: x + 1
                    continue
                ]
            ]
        ]
        total: bi-add total norm-cutlet-count-state family rem - x slots - 1 next-cumulative next-hit
        x: x + 1
    ]
    put family/memo key bi-copy total
    total
]

norm-make-cutlet-partition-family: func [g [integer!] k [integer!] required /local family] [
    family: make object! [g: 0 k: 0 required: none memo: none]
    family/g: g
    family/k: k
    family/required: required
    family/memo: make map! []
    family
]

norm-cutlet-family-count: func [family] [
    norm-cutlet-count-state family family/g family/k 0 false
]

norm-cutlet-family-unrank1: func [family rank1 /local r rem slots cumulative hit out max-x x next-cumulative next-hit block chosen] [
    r: bi-copy rank1
    rem: family/g
    slots: family/k
    cumulative: 0
    hit: false
    out: copy []
    while [slots > 0] [
        max-x: rem - (slots - 1)
        x: 1
        chosen: false
        while [all [x <= max-x not chosen]] [
            next-cumulative: cumulative + x
            next-hit: hit
            if all [not none? family/required not hit] [
                either next-cumulative = family/required [
                    next-hit: true
                ][
                    if next-cumulative > family/required [
                        x: x + 1
                        continue
                    ]
                ]
            ]
            block: norm-cutlet-count-state family rem - x slots - 1 next-cumulative next-hit
            either bi-gt? r block [
                r: bi-sub r block
                x: x + 1
            ][
                append out x
                rem: rem - x
                slots: slots - 1
                cumulative: next-cumulative
                hit: next-hit
                chosen: true
            ]
        ]
    ]
    out
]

norm-weave-key: func [remaining [block!] opened [integer!] closed [integer!] /local out v] [
    out: rejoin [opened ":" closed ":"]
    foreach v remaining [append out rejoin [v ","]]
    out
]

norm-weave-legal?: func [family remaining opened closed j [integer!] /local left already-opened will-close] [
    left: pick remaining j
    if left = 0 [return false]
    already-opened: left < pick family/lengths j
    if all [not already-opened j <> opened + 1] [return false]
    will-close: left = 1
    if all [will-close j <> closed + 1] [return false]
    true
]

norm-weave-next: func [family remaining opened closed j [integer!] /local next-rem next-opened next-closed] [
    next-rem: copy remaining
    next-opened: opened
    next-closed: closed
    if (pick next-rem j) = (pick family/lengths j) [next-opened: j]
    poke next-rem j (pick next-rem j) - 1
    if (pick next-rem j) = 0 [next-closed: j]
    make object! [remaining: next-rem opened: next-opened closed: next-closed]
]

norm-weave-count-state: func [family remaining [block!] opened [integer!] closed [integer!] /local done key cached total j next-state value] [
    done: true
    foreach value remaining [if value <> 0 [done: false]]
    if done [return bi-one]
    key: norm-weave-key remaining opened closed
    cached: select family/memo key
    if not none? cached [return bi-copy cached]
    total: bi-zero
    j: 1
    while [j <= length? remaining] [
        if norm-weave-legal? family remaining opened closed j [
            next-state: norm-weave-next family remaining opened closed j
            total: bi-add total norm-weave-count-state family next-state/remaining next-state/opened next-state/closed
        ]
        j: j + 1
    ]
    put family/memo key bi-copy total
    total
]

norm-make-weave-family: func [lengths [block!] /local family] [
    family: make object! [lengths: none memo: none]
    family/lengths: copy lengths
    family/memo: make map! []
    family
]

norm-weave-count: func [family] [
    norm-weave-count-state family copy family/lengths 0 0
]

norm-weave-unrank1: func [family rank1 /local remaining opened closed r out total-days position j next-state block chosen value] [
    remaining: copy family/lengths
    opened: 0
    closed: 0
    r: bi-copy rank1
    out: copy []
    total-days: 0
    foreach value family/lengths [total-days: total-days + value]
    position: 1
    while [position <= total-days] [
        j: 1
        chosen: false
        while [all [j <= length? remaining not chosen]] [
            if norm-weave-legal? family remaining opened closed j [
                next-state: norm-weave-next family remaining opened closed j
                block: norm-weave-count-state family next-state/remaining next-state/opened next-state/closed
                either bi-gt? r block [
                    r: bi-sub r block
                ][
                    append out j
                    remaining: next-state/remaining
                    opened: next-state/opened
                    closed: next-state/closed
                    chosen: true
                ]
            ]
            if not chosen [j: j + 1]
        ]
        position: position + 1
    ]
    out
]

norm-make-gate-cache: func [/local cache] [
    cache: make object! [
        values: make map! []
        minKnown: none
        maxKnown: none
    ]
    cache/minKnown: bi-zero
    cache/maxKnown: bi-zero
    put cache/values "0" bi-copy norm-foundation-day
    cache
]

norm-gates: norm-make-gate-cache

norm-reset-gates: func [] [norm-gates: norm-make-gate-cache]

norm-gate-key: func [index] [bi-to-decimal index]

norm-gate-get: func [index /local value] [
    value: select norm-gates/values norm-gate-key index
    either none? value [none] [bi-copy value]
]

norm-positive-gate-gap: func [n /local r stream chosen] [
    r: norm-sauce norm-foundation-day bi-add norm-foundation-day n
    stream: norm-ask-bowl r 1 norm-seal-gate-gap
    chosen: norm-choose-rank stream bi-from-integer 922
    bi-add-small chosen 41
]

norm-negative-gate-gap: func [n /local r stream chosen] [
    r: norm-sauce norm-foundation-day bi-sub norm-foundation-day n
    stream: norm-ask-bowl r 1 norm-seal-gate-gap
    chosen: norm-choose-rank stream bi-from-integer 922
    bi-add-small chosen 41
]

norm-ensure-gate-index: func [k /local n prev next-value gap current] [
    if bi-gt? k norm-gates/maxKnown [
        n: bi-inc norm-gates/maxKnown
        while [bi-le? n k] [
            prev: norm-gate-get bi-dec n
            gap: norm-positive-gate-gap n
            current: bi-add prev gap
            put norm-gates/values norm-gate-key n current
            norm-gates/maxKnown: bi-copy n
            n: bi-inc n
        ]
    ]
    if bi-lt? k norm-gates/minKnown [
        n: bi-dec norm-gates/minKnown
        while [bi-ge? n k] [
            next-value: norm-gate-get bi-inc n
            gap: norm-negative-gate-gap bi-abs n
            current: bi-sub next-value gap
            put norm-gates/values norm-gate-key n current
            norm-gates/minKnown: bi-copy n
            n: bi-dec n
        ]
    ]
    norm-gate-get k
]

norm-ensure-gates-cover: func [low-day high-day /local current] [
    while [bi-gt? norm-gate-get norm-gates/minKnown low-day] [
        norm-ensure-gate-index bi-dec norm-gates/minKnown
    ]
    while [bi-lt? norm-gate-get norm-gates/maxKnown high-day] [
        norm-ensure-gate-index bi-inc norm-gates/maxKnown
    ]
    true
]

norm-gate-index-at-or-before: func [day /local lo hi sum mid gate-mid] [
    norm-ensure-gates-cover day day
    lo: bi-copy norm-gates/minKnown
    hi: bi-copy norm-gates/maxKnown
    while [bi-lt? lo hi] [
        sum: bi-add-small bi-add lo hi 1
        mid: bi-floor-div-positive sum bi-from-integer 2
        gate-mid: norm-gate-get mid
        either bi-le? gate-mid day [lo: mid] [hi: bi-dec mid]
    ]
    lo
]

norm-gate-index-at-or-after: func [day /local i g] [
    i: norm-gate-index-at-or-before day
    g: norm-gate-get i
    if bi-eq? g day [return i]
    norm-ensure-gate-index bi-inc i
    bi-inc i
]

norm-exact-gate-index: func [day /local i g] [
    i: norm-gate-index-at-or-before day
    g: norm-gate-get i
    either bi-eq? g day [i] [none]
]

norm-year-length: func [open-index close-index] [
    bi-sub norm-gate-get close-index norm-gate-get open-index
]

norm-valid-year-pair?: func [open-index close-index /local gaps length-value] [
    gaps: bi-sub close-index open-index
    if bi-lt? gaps bi-from-integer 6 [return false]
    length-value: norm-year-length open-index close-index
    all [
        bi-ge? length-value bi-from-integer norm-year-min-days
        bi-le? length-value bi-from-integer norm-year-max-days
    ]
]

norm-make-year: func [number open-index close-index /local y] [
    y: make object! [
        number: none
        openGateIndex: none
        closeGateIndex: none
        openGateDay: none
        closeGateDay: none
    ]
    y/number: bi-copy number
    y/openGateIndex: bi-copy open-index
    y/closeGateIndex: bi-copy close-index
    y/openGateDay: norm-gate-get open-index
    y/closeGateDay: norm-gate-get close-index
    y
]

norm-year-pair-before?: func [a b /local c] [
    c: bi-compare a/lengthValue b/lengthValue
    if c < 0 [return true]
    if c > 0 [return false]
    bi-lt? a/openDay b/openDay
]

norm-stable-insert-year-pair: func [sorted item /local out inserted pos existing] [
    out: copy []
    inserted: false
    pos: 1
    while [pos <= length? sorted] [
        existing: pick sorted pos
        if all [not inserted norm-year-pair-before? item existing] [
            append/only out item
            inserted: true
        ]
        append/only out existing
        pos: pos + 1
    ]
    if not inserted [append/only out item]
    out
]

norm-sort-year-pairs: func [items /local out item] [
    out: copy []
    foreach item items [out: norm-stable-insert-year-pair out item]
    out
]

norm-year5000: func [calculation-day /local low-day high-day low-index high-index i j candidates open-day close-day length-value item sorted r stream rank-small chosen] [
    low-day: bi-sub-small calculation-day norm-year-max-days
    high-day: bi-add-small calculation-day norm-year-max-days
    norm-ensure-gates-cover low-day high-day
    low-index: norm-gate-index-at-or-after low-day
    high-index: norm-gate-index-at-or-before high-day
    candidates: copy []
    i: bi-copy low-index
    while [bi-lt? i high-index] [
        j: bi-inc i
        while [bi-le? j high-index] [
            if norm-valid-year-pair? i j [
                open-day: norm-gate-get i
                close-day: norm-gate-get j
                if all [bi-lt? open-day calculation-day bi-le? calculation-day close-day] [
                    length-value: bi-sub close-day open-day
                    item: make object! [openIndex: none closeIndex: none openDay: none lengthValue: none]
                    item/openIndex: bi-copy i
                    item/closeIndex: bi-copy j
                    item/openDay: open-day
                    item/lengthValue: length-value
                    append/only candidates item
                ]
            ]
            j: bi-inc j
        ]
        i: bi-inc i
    ]
    sorted: norm-sort-year-pairs candidates
    r: norm-sauce calculation-day calculation-day
    stream: norm-ask-bowl r 1 norm-seal-year-5000
    rank-small: bi-to-small norm-choose-rank stream bi-from-integer length? sorted
    chosen: pick sorted rank-small
    norm-make-year bi-from-integer 5000 chosen/openIndex chosen/closeIndex
]

norm-index-candidate-before?: func [a b] [bi-lt? a/lengthValue b/lengthValue]

norm-stable-insert-index-candidate: func [sorted item /local out inserted pos existing] [
    out: copy []
    inserted: false
    pos: 1
    while [pos <= length? sorted] [
        existing: pick sorted pos
        if all [not inserted norm-index-candidate-before? item existing] [
            append/only out item
            inserted: true
        ]
        append/only out existing
        pos: pos + 1
    ]
    if not inserted [append/only out item]
    out
]

norm-sort-index-candidates: func [items /local out item] [
    out: copy []
    foreach item items [out: norm-stable-insert-index-candidate out item]
    out
]

norm-next-year: func [calculation-day known-year /local open-index max-day candidates close-index length-value item sorted r stream rank-small chosen] [
    open-index: bi-copy known-year/closeGateIndex
    max-day: bi-add-small norm-gate-get open-index norm-year-max-days
    norm-ensure-gates-cover norm-gate-get open-index max-day
    candidates: copy []
    close-index: bi-inc open-index
    while [true] [
        norm-ensure-gate-index close-index
        length-value: norm-year-length open-index close-index
        if bi-gt? length-value bi-from-integer norm-year-max-days [break]
        if norm-valid-year-pair? open-index close-index [
            item: make object! [index: none lengthValue: none]
            item/index: bi-copy close-index
            item/lengthValue: length-value
            append/only candidates item
        ]
        close-index: bi-inc close-index
    ]
    sorted: norm-sort-index-candidates candidates
    r: norm-sauce calculation-day norm-gate-get open-index
    stream: norm-ask-bowl r 1 norm-seal-next-year
    rank-small: bi-to-small norm-choose-rank stream bi-from-integer length? sorted
    chosen: pick sorted rank-small
    norm-make-year bi-inc known-year/number open-index chosen/index
]

norm-previous-year: func [calculation-day known-year /local close-index min-day candidates open-index length-value item sorted r stream rank-small chosen] [
    close-index: bi-copy known-year/openGateIndex
    min-day: bi-sub-small norm-gate-get close-index norm-year-max-days
    norm-ensure-gates-cover min-day norm-gate-get close-index
    candidates: copy []
    open-index: bi-dec close-index
    while [true] [
        norm-ensure-gate-index open-index
        length-value: norm-year-length open-index close-index
        if bi-gt? length-value bi-from-integer norm-year-max-days [break]
        if norm-valid-year-pair? open-index close-index [
            item: make object! [index: none lengthValue: none]
            item/index: bi-copy open-index
            item/lengthValue: length-value
            append/only candidates item
        ]
        open-index: bi-dec open-index
    ]
    sorted: norm-sort-index-candidates candidates
    r: norm-sauce calculation-day norm-gate-get close-index
    stream: norm-ask-bowl r 1 norm-seal-previous-year
    rank-small: bi-to-small norm-choose-rank stream bi-from-integer length? sorted
    chosen: pick sorted rank-small
    norm-make-year bi-dec known-year/number chosen/index close-index
]

norm-find-target-year: func [calculation-day target-day /local y] [
    y: norm-year5000 calculation-day
    while [bi-gt? target-day y/closeGateDay] [y: norm-next-year calculation-day y]
    while [bi-le? target-day y/openGateDay] [y: norm-previous-year calculation-day y]
    y
]

norm-choose-small-list-item: func [stream items [block!] /local rank-small] [
    rank-small: bi-to-small norm-choose-rank stream bi-from-integer length? items
    pick items rank-small
]

norm-choose-cutlet-count: func [structure-sauce year /local gate-gaps candidates k stream] [
    gate-gaps: bi-to-small bi-sub year/closeGateIndex year/openGateIndex
    candidates: copy []
    k: norm-min-cutlets
    while [k <= norm-max-cutlets] [
        if k <= gate-gaps [append candidates k]
        k: k + 1
    ]
    stream: norm-ask-bowl structure-sauce 2 norm-seal-cutlet-count
    norm-choose-small-list-item stream candidates
]

norm-choose-cutlet-partition: func [calculation-day structure-sauce year cutlet-count [integer!] /local g required gap-count family stream rank] [
    gap-count: bi-to-small bi-sub year/closeGateIndex year/openGateIndex
    required: none
    g: norm-exact-gate-index calculation-day
    if not none? g [
        if all [bi-gt? g year/openGateIndex bi-lt? g year/closeGateIndex] [
            required: bi-to-small bi-sub g year/openGateIndex
        ]
    ]
    family: norm-make-cutlet-partition-family gap-count cutlet-count required
    stream: norm-ask-bowl structure-sauce 2 norm-seal-cutlet-partition
    rank: norm-choose-rank stream norm-cutlet-family-count family
    norm-cutlet-family-unrank1 family rank
]

norm-choose-cutlet-name-indices: func [structure-sauce cutlet-count [integer!] /local n stream rank] [
    n: norm-falling-factorial 17 cutlet-count
    stream: norm-ask-bowl structure-sauce 5 norm-seal-cutlet-names
    rank: norm-choose-rank stream n
    norm-unrank-distinct-indices 17 cutlet-count rank
]

norm-materialize-cutlets: func [year partition [block!] name-indices [block!] /local cursor k open-index close-index c out] [
    cursor: bi-copy year/openGateIndex
    out: copy []
    k: 1
    while [k <= length? partition] [
        open-index: bi-copy cursor
        close-index: bi-add-small cursor pick partition k
        c: make object! [
            nameIndex: 0
            openGateIndex: none
            closeGateIndex: none
            firstDay: none
            lastDay: none
        ]
        c/nameIndex: pick name-indices k
        c/openGateIndex: open-index
        c/closeGateIndex: close-index
        c/firstDay: bi-add-small norm-gate-get open-index 1
        c/lastDay: norm-gate-get close-index
        append/only out c
        cursor: close-index
        k: k + 1
    ]
    out
]

norm-choose-month-count: func [structure-sauce year /local length-small min-months max-months candidates k stream] [
    length-small: bi-to-small bi-sub year/closeGateDay year/openGateDay
    min-months: norm-ceil-div-small length-small norm-max-month-days
    max-months: min norm-max-months length-small / norm-min-month-days
    candidates: copy []
    k: min-months
    while [k <= max-months] [append candidates k k: k + 1]
    stream: norm-ask-bowl structure-sauce 3 norm-seal-month-count
    norm-choose-small-list-item stream candidates
]

norm-choose-month-lengths: func [structure-sauce year month-count [integer!] /local length-small family stream rank] [
    length-small: bi-to-small bi-sub year/closeGateDay year/openGateDay
    family: norm-make-bounded-family length-small month-count norm-min-month-days norm-max-month-days
    stream: norm-ask-bowl structure-sauce 3 norm-seal-month-lengths
    rank: norm-choose-rank stream norm-bounded-count family
    norm-bounded-unrank1 family rank
]

norm-choose-month-weaving: func [structure-sauce month-lengths [block!] /local family count stream rank] [
    family: norm-make-weave-family month-lengths
    count: norm-weave-count family
    stream: norm-ask-bowl structure-sauce 4 norm-seal-month-weaving
    rank: norm-choose-rank stream count
    norm-weave-unrank1 family rank
]

norm-choose-month-name-indices: func [structure-sauce month-count [integer!] /local n stream rank] [
    n: norm-falling-factorial 47 month-count
    stream: norm-ask-bowl structure-sauce 5 norm-seal-month-names
    rank: norm-choose-rank stream n
    norm-unrank-distinct-indices 47 month-count rank
]

norm-build-year-structure: func [calculation-day year /local first-day r cutlet-count cutlet-partition cutlet-name-indices cutlets month-count month-lengths month-weaving month-name-indices s] [
    first-day: bi-add-small year/openGateDay 1
    r: norm-sauce calculation-day first-day
    cutlet-count: norm-choose-cutlet-count r year
    cutlet-partition: norm-choose-cutlet-partition calculation-day r year cutlet-count
    cutlet-name-indices: norm-choose-cutlet-name-indices r cutlet-count
    cutlets: norm-materialize-cutlets year cutlet-partition cutlet-name-indices
    month-count: norm-choose-month-count r year
    month-lengths: norm-choose-month-lengths r year month-count
    month-weaving: norm-choose-month-weaving r month-lengths
    month-name-indices: norm-choose-month-name-indices r month-count
    s: make object! [
        year: none
        cutletCount: 0
        cutletPartition: none
        cutletNameIndices: none
        cutlets: none
        monthCount: 0
        monthLengths: none
        monthWeaving: none
        monthNameIndices: none
    ]
    s/year: year
    s/cutletCount: cutlet-count
    s/cutletPartition: cutlet-partition
    s/cutletNameIndices: cutlet-name-indices
    s/cutlets: cutlets
    s/monthCount: month-count
    s/monthLengths: month-lengths
    s/monthWeaving: month-weaving
    s/monthNameIndices: month-name-indices
    s
]

norm-calendar-date: func [calculation-day target-day /local cday tday year structure chosen-cutlet cutlet-id i day-in-cutlet year-offset0-small month-id day-in-month p result] [
    cday: either integer? calculation-day [bi-from-integer calculation-day] [bi-copy calculation-day]
    tday: either integer? target-day [bi-from-integer target-day] [bi-copy target-day]
    year: norm-find-target-year cday tday
    structure: norm-build-year-structure cday year
    chosen-cutlet: none
    cutlet-id: 0
    i: 1
    while [i <= length? structure/cutlets] [
        if none? chosen-cutlet [
            if all [
                bi-ge? tday (pick structure/cutlets i)/firstDay
                bi-le? tday (pick structure/cutlets i)/lastDay
            ] [
                chosen-cutlet: pick structure/cutlets i
                cutlet-id: i
            ]
        ]
        i: i + 1
    ]
    if none? chosen-cutlet [return none]
    day-in-cutlet: bi-add-small bi-sub tday chosen-cutlet/firstDay 1
    year-offset0-small: bi-to-small bi-sub tday bi-add-small year/openGateDay 1
    month-id: pick structure/monthWeaving year-offset0-small + 1
    day-in-month: 0
    p: 1
    while [p <= year-offset0-small + 1] [
        if (pick structure/monthWeaving p) = month-id [day-in-month: day-in-month + 1]
        p: p + 1
    ]
    result: reduce [
        bi-copy year/number
        cutlet-name-at chosen-cutlet/nameIndex
        day-in-cutlet
        month-name-at pick structure/monthNameIndices month-id
        bi-from-integer day-in-month
    ]
    result
]

norm-local-instant-to-discrete-day: func [instant geographic-location ephemeris-model] [
    'not-defined-by-scroll-alone
]
