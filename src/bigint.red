Red [
    Title: "Целобројна аритметика произвољне прецизности"
]

BI_BASE: 10000

bi-new: func [sign-value digits-value /local x] [
    x: make object! [sign: 0 digits: copy []]
    x/sign: sign-value
    x/digits: copy digits-value
    bi-normalize x
]

bi-normalize: func [x /local ds] [
    ds: x/digits
    if empty? ds [append ds 0]
    while [all [(length? ds) > 1 (last ds) = 0]] [take/last ds]
    either all [(length? ds) = 1 (first ds) = 0] [
        x/sign: 0
    ][
        if x/sign = 0 [x/sign: 1]
        if x/sign > 0 [x/sign: 1]
        if x/sign < 0 [x/sign: -1]
    ]
    x
]

bi-zero: func [] [bi-new 0 [0]]
bi-one: func [] [bi-new 1 [1]]

bi-copy: func [x] [bi-new x/sign copy x/digits]

bi-from-integer: func [n [integer!] /local s v ds q r] [
    if n = -2147483648 [return bi-from-decimal "-2147483648"]
    if n = 0 [return bi-zero]
    s: either n < 0 [-1] [1]
    v: absolute n
    ds: copy []
    while [v > 0] [
        q: v / BI_BASE
        r: v // BI_BASE
        append ds r
        v: q
    ]
    bi-new s ds
]

bi-from-decimal: func [text [string!] /local s p out ch digit] [
    s: 1
    p: text
    if all [not empty? p first p = #"-"] [
        s: -1
        p: next p
    ]
    out: bi-zero
    foreach ch p [
        digit: (to integer! form ch)
        out: bi-add-small bi-mul-small out 10 digit
    ]
    if all [s = -1 out/sign <> 0] [out/sign: -1]
    out
]

bi-to-decimal: func [x /local ds i out part need] [
    if x/sign = 0 [return "0"]
    ds: x/digits
    i: length? ds
    out: copy ""
    if x/sign < 0 [append out "-"]
    append out form pick ds i
    i: i - 1
    while [i >= 1] [
        part: form pick ds i
        need: 4 - length? part
        while [need > 0] [append out "0" need: need - 1]
        append out part
        i: i - 1
    ]
    out
]

bi-zero?: func [x] [x/sign = 0]

bi-abs-compare: func [a b /local la lb i av bv] [
    la: length? a/digits
    lb: length? b/digits
    if la < lb [return -1]
    if la > lb [return 1]
    i: la
    while [i >= 1] [
        av: pick a/digits i
        bv: pick b/digits i
        if av < bv [return -1]
        if av > bv [return 1]
        i: i - 1
    ]
    0
]

bi-compare: func [a b /local c] [
    if a/sign < b/sign [return -1]
    if a/sign > b/sign [return 1]
    if a/sign = 0 [return 0]
    c: bi-abs-compare a b
    either a/sign > 0 [c] [0 - c]
]

bi-eq?: func [a b] [0 = bi-compare a b]
bi-lt?: func [a b] [(bi-compare a b) < 0]
bi-le?: func [a b] [(bi-compare a b) <= 0]
bi-gt?: func [a b] [(bi-compare a b) > 0]
bi-ge?: func [a b] [(bi-compare a b) >= 0]

bi-add-abs: func [a b /local out n i av bv carry t q r] [
    out: copy []
    n: max length? a/digits length? b/digits
    carry: 0
    i: 1
    while [i <= n] [
        av: either i <= length? a/digits [pick a/digits i] [0]
        bv: either i <= length? b/digits [pick b/digits i] [0]
        t: av + bv + carry
        q: t / BI_BASE
        r: t // BI_BASE
        append out r
        carry: q
        i: i + 1
    ]
    if carry > 0 [append out carry]
    bi-new 1 out
]

bi-sub-abs: func [a b /local out n i av bv borrow t] [
    out: copy []
    n: length? a/digits
    borrow: 0
    i: 1
    while [i <= n] [
        av: pick a/digits i
        bv: either i <= length? b/digits [pick b/digits i] [0]
        t: av - bv - borrow
        either t < 0 [
            t: t + BI_BASE
            borrow: 1
        ][
            borrow: 0
        ]
        append out t
        i: i + 1
    ]
    bi-new 1 out
]

bi-neg: func [a /local out] [
    out: bi-copy a
    out/sign: 0 - out/sign
    out
]

bi-add: func [a b /local c out] [
    if a/sign = 0 [return bi-copy b]
    if b/sign = 0 [return bi-copy a]
    if a/sign = b/sign [
        out: bi-add-abs a b
        out/sign: a/sign
        return out
    ]
    c: bi-abs-compare a b
    if c = 0 [return bi-zero]
    either c > 0 [
        out: bi-sub-abs a b
        out/sign: a/sign
    ][
        out: bi-sub-abs b a
        out/sign: b/sign
    ]
    bi-normalize out
]

bi-sub: func [a b] [bi-add a bi-neg b]

bi-add-small: func [a n [integer!]] [bi-add a bi-from-integer n]
bi-sub-small: func [a n [integer!]] [bi-sub a bi-from-integer n]

bi-mul-small: func [a n [integer!] /local s m out carry i t q r] [
    if any [a/sign = 0 n = 0] [return bi-zero]
    s: either n < 0 [0 - a/sign] [a/sign]
    m: absolute n
    out: copy []
    carry: 0
    i: 1
    while [i <= length? a/digits] [
        t: (pick a/digits i) * m + carry
        q: t / BI_BASE
        r: t // BI_BASE
        append out r
        carry: q
        i: i + 1
    ]
    while [carry > 0] [
        append out carry // BI_BASE
        carry: carry / BI_BASE
    ]
    bi-new s out
]

bi-mul: func [a b /local out total i j k carry t q r extra] [
    if any [a/sign = 0 b/sign = 0] [return bi-zero]
    out: copy []
    total: (length? a/digits) + (length? b/digits) + 1
    repeat k total [append out 0]
    i: 1
    while [i <= length? a/digits] [
        carry: 0
        j: 1
        while [j <= length? b/digits] [
            k: i + j - 1
            t: (pick out k) + ((pick a/digits i) * (pick b/digits j)) + carry
            q: t / BI_BASE
            r: t // BI_BASE
            poke out k r
            carry: q
            j: j + 1
        ]
        k: i + length? b/digits
        while [carry > 0] [
            t: (pick out k) + carry
            poke out k t // BI_BASE
            carry: t / BI_BASE
            k: k + 1
        ]
        i: i + 1
    ]
    bi-new a/sign * b/sign out
]

bi-square: func [a] [bi-mul a a]

bi-divmod-positive: func [n d /local qdigits rem pos digit lo hi mid best trial cmp prod] [
    if d/sign <= 0 [return none]
    if n/sign < 0 [return none]
    if bi-lt? n d [
        return make object! [q: bi-zero r: bi-copy n]
    ]
    qdigits: copy []
    repeat pos length? n/digits [append qdigits 0]
    rem: bi-zero
    pos: length? n/digits
    while [pos >= 1] [
        rem: bi-add-small bi-mul-small rem BI_BASE pick n/digits pos
        lo: 0
        hi: BI_BASE - 1
        best: 0
        while [lo <= hi] [
            mid: (lo + hi) / 2
            trial: bi-mul-small d mid
            cmp: bi-compare trial rem
            either cmp <= 0 [
                best: mid
                lo: mid + 1
            ][
                hi: mid - 1
            ]
        ]
        poke qdigits pos best
        if best > 0 [
            prod: bi-mul-small d best
            rem: bi-sub-abs rem prod
        ]
        pos: pos - 1
    ]
    make object! [q: bi-new 1 qdigits r: bi-normalize rem]
]

bi-divmod: func [n d /local absn absd dm q r result] [
    if d/sign = 0 [return none]
    absn: bi-copy n
    absd: bi-copy d
    if absn/sign < 0 [absn/sign: 1]
    if absd/sign < 0 [absd/sign: 1]
    dm: bi-divmod-positive absn absd
    q: dm/q
    r: dm/r
    if n/sign * d/sign < 0 [q/sign: 0 - q/sign]
    result: make object! [q: none r: none]
    result/q: bi-normalize q
    result/r: bi-normalize r
    result
]

bi-regular-mod: func [n d /local absd dm r] [
    if d/sign <= 0 [return none]
    absd: bi-copy d
    dm: bi-divmod n absd
    r: dm/r
    if n/sign >= 0 [return r]
    if r/sign = 0 [return r]
    bi-sub absd r
]

bi-floor-div-positive: func [n d /local absn dm q] [
    if d/sign <= 0 [return none]
    if n/sign >= 0 [
        dm: bi-divmod-positive n d
        return dm/q
    ]
    absn: bi-neg n
    dm: bi-divmod-positive absn d
    q: bi-neg dm/q
    if dm/r/sign <> 0 [q: bi-sub-small q 1]
    q
]

bi-mod-small: func [a d [integer!] /local i r] [
    r: 0
    i: length? a/digits
    while [i >= 1] [
        r: (r * BI_BASE + pick a/digits i) // d
        i: i - 1
    ]
    if all [a/sign < 0 r <> 0] [r: d - r]
    r
]

bi-to-small: func [a /local i v] [
    if a/sign = 0 [return 0]
    v: 0
    i: length? a/digits
    while [i >= 1] [
        if v > 200000 [return none]
        v: v * BI_BASE + pick a/digits i
        i: i - 1
    ]
    either a/sign < 0 [0 - v] [v]
]

bi-abs: func [a /local out] [
    out: bi-copy a
    if out/sign < 0 [out/sign: 1]
    out
]

bi-inc: func [a] [bi-add-small a 1]
bi-dec: func [a] [bi-sub-small a 1]

bi-sum: func [items [block!] /local out item] [
    out: bi-zero
    foreach item items [out: bi-add out item]
    out
]

bi-block-copy: func [items [block!] /local out item] [
    out: copy []
    foreach item items [append/only out bi-copy item]
    out
]
