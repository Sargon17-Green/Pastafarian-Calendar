Object subclass: #PSTNormativeOracle
    instanceVariableNames: 'gate minKnownGateIndex maxKnownGateIndex stoneTable'
    classVariableNames: ''
    package: 'Pastafarian-Stage01'!

!PSTNormativeOracle class methodsFor: 'constants'!
foundationDay
    ^ -15055671
!

tabletsDay
    ^ -278522
!

m
    ^ (1 bitShift: 127) - 1
!

yearMinDays
    ^ 252
!

yearMaxDays
    ^ 5778
!
! !

!PSTNormativeOracle methodsFor: 'initialization'!
initialize
    super initialize.
    gate := Dictionary new.
    gate at: 0 put: self class foundationDay.
    minKnownGateIndex := 0.
    maxKnownGateIndex := 0.
    stoneTable := self buildStones.
    ^ self
!
! !

!PSTNormativeOracle methodsFor: 'basic arithmetic'!
regularMod: x by: d
    d < 1 ifTrue: [ self error: 'مقسوم علیہ مثبت ہونا لازم ہے' ].
    ^ x \\ d
!

save: x
    ^ 1 + (self regularMod: x - 1 by: self class m)
!

ceilDiv: a by: b
    (a < 0 or: [ b < 1 ]) ifTrue: [ self error: 'چھت تقسیم کے دلائل نامعتبر ہیں' ].
    ^ (a + b - 1) // b
!

wrap1: position size: size
    ^ 1 + (self regularMod: position - 1 by: size)
!

factorial: n
    | r |
    r := 1.
    2 to: n do: [ :i | r := r * i ].
    ^ r
!

fallingFactorial: n take: k
    | r |
    r := 1.
    0 to: k - 1 do: [ :j | r := r * (n - j) ].
    ^ r
!
! !

!PSTNormativeOracle methodsFor: 'day counts'!
dayCount: day
    day = self class foundationDay ifTrue: [ ^ 1 ].
    day > self class foundationDay ifTrue: [ ^ 2 * (day - self class foundationDay) + 1 ].
    ^ 2 * (self class foundationDay - day)
!

workCountsFor: calculationDay target: targetDay
    | c t distance connection direction d |
    c := self dayCount: calculationDay.
    t := self dayCount: targetDay.
    distance := (targetDay - calculationDay) abs + 1.
    connection := c + t.
    direction := targetDay < calculationDay
        ifTrue: [ 1 ]
        ifFalse: [ targetDay = calculationDay ifTrue: [ 2 ] ifFalse: [ 3 ] ].
    d := Dictionary new.
    d at: #action put: c.
    d at: #target put: t.
    d at: #distance put: distance.
    d at: #connection put: connection.
    d at: #direction put: direction.
    ^ d
!
! !

!PSTNormativeOracle methodsFor: 'stones'!
buildStones
    | table current old i next |
    table := Array new: 46.
    current := #(17 29 43 71 101) copy.
    table at: 1 put: current copy.
    i := 2.
    [ i <= 46 ] whileTrue: [
        old := current copy.
        next := Array new: 5.
        next at: 1 put: (self save: ((old at: 1) * (old at: 1)) + (3 * (old at: 2)) + i).
        next at: 2 put: (self save: ((old at: 2) * (old at: 2)) + (5 * (old at: 3)) + (old at: 1)).
        next at: 3 put: (self save: ((old at: 3) * (old at: 3)) + (7 * (old at: 4)) + (old at: 2)).
        next at: 4 put: (self save: ((old at: 4) * (old at: 4)) + (11 * (old at: 5)) + (old at: 3)).
        next at: 5 put: (self save: ((old at: 5) * (old at: 5)) + (13 * (old at: 1)) + (old at: 4)).
        current := next.
        table at: i put: current copy.
        i := i + 1 ].
    ^ table
!
! !

!PSTNormativeOracle methodsFor: 'hidden drops'!
hiddenCoefficients
    ^ #(
        (3 4 6 8)
        (5 7 10 12)
        (7 10 14 16)
        (9 13 18 20)
        (11 16 22 24)
        (13 19 26 28)
        (15 22 30 32)
    )
!

hiddenGrindStoneKinds
    ^ #(1 2 3 4 5 1 2)
!

buildHiddenDropsFor: counts
    | hidden k coeff x stone g oldX kind |
    hidden := Array new: 7.
    1 to: 7 do: [ :idx |
        k := idx.
        coeff := self hiddenCoefficients at: k.
        stone := stoneTable at: k.
        x := (counts at: #action)
            + ((coeff at: 1) * (counts at: #target))
            + ((coeff at: 2) * (counts at: #distance))
            + ((coeff at: 3) * (counts at: #connection))
            + ((coeff at: 4) * (counts at: #direction))
            + (stone inject: 0 into: [ :s :each | s + each ]).
        x := self save: x.
        g := 1.
        [ g <= 7 ] whileTrue: [
            oldX := x.
            kind := self hiddenGrindStoneKinds at: g.
            x := self save: (oldX * oldX) + (3 * oldX) + (stone at: kind) + g.
            g := g + 1 ].
        hidden at: k put: x ].
    ^ hidden
!
! !

!PSTNormativeOracle methodsFor: 'visible drops'!
visibleGrinds
    ^ #(
        (3 5 7 11 1)
        (5 7 11 13 2)
        (7 11 13 17 3)
        (11 13 17 19 4)
        (13 17 19 23 5)
        (17 19 23 29 1)
        (19 23 29 31 2)
        (23 29 31 37 3)
        (29 31 37 41 4)
        (31 37 41 43 5)
        (37 41 43 47 1)
    )
!

priorForVisibleIndex: i back: back dropStore: drops hidden: hidden
    | slot k |
    slot := i - back.
    slot >= 1 ifTrue: [ ^ drops at: slot ].
    k := 1 - slot.
    ^ hidden at: k
!

buildVisibleDropsFor: counts hidden: hidden
    | drops i p1 p3 p7 stone x g row oldX |
    drops := Array new: 46.
    i := 1.
    [ i <= 46 ] whileTrue: [
        p1 := self priorForVisibleIndex: i back: 1 dropStore: drops hidden: hidden.
        p3 := self priorForVisibleIndex: i back: 3 dropStore: drops hidden: hidden.
        p7 := self priorForVisibleIndex: i back: 7 dropStore: drops hidden: hidden.
        stone := stoneTable at: i.
        x := self save:
            ((stone at: 1) * (counts at: #action))
            + ((stone at: 2) * (counts at: #target))
            + ((stone at: 3) * (counts at: #distance))
            + ((stone at: 4) * (counts at: #connection))
            + ((stone at: 5) * (counts at: #direction))
            + p1 + (3 * p3) + (5 * p7) + i.
        g := 1.
        [ g <= 11 ] whileTrue: [
            row := self visibleGrinds at: g.
            oldX := x.
            x := self save:
                (oldX * oldX)
                + ((row at: 1) * oldX)
                + ((row at: 2) * p1)
                + ((row at: 3) * p3)
                + ((row at: 4) * p7)
                + (stone at: (row at: 5)).
            g := g + 1 ].
        drops at: i put: x.
        i := i + 1 ].
    ^ drops
!
! !

!PSTNormativeOracle methodsFor: 'permutations'!
permutationUnrank1: rank1 items: items
    | rank0 remaining result slotsLeft block q |
    rank0 := rank1 - 1.
    remaining := OrderedCollection withAll: items.
    result := OrderedCollection new.
    slotsLeft := remaining size.
    [ slotsLeft >= 1 ] whileTrue: [
        block := self factorial: slotsLeft - 1.
        q := rank0 // block.
        rank0 := self regularMod: rank0 by: block.
        result add: (remaining at: q + 1).
        remaining removeAt: q + 1.
        slotsLeft := slotsLeft - 1 ].
    ^ result asArray
!

bowlOrderFromNumber: orderNumber
    (orderNumber between: 1 and: 720) ifFalse: [ self error: 'پیالوں کا ترتیب نمبر نامعتبر ہے' ].
    ^ self permutationUnrank1: orderNumber items: #(1 2 3 4 5 6)
!

bowlOrderFromDrop: dropValue
    | orderNumber |
    orderNumber := (self regularMod: dropValue - 1 by: 720) + 1.
    ^ self bowlOrderFromNumber: orderNumber
!
! !

!PSTNormativeOracle methodsFor: 'bowls'!
initialBowlsFor: counts
    | bowls primes id s |
    bowls := Array new: 6.
    primes := #(17 19 23 29 31 37).
    1 to: 6 do: [ :idx |
        id := idx.
        s := (counts at: #action)
            + ((counts at: #target) * id)
            + (counts at: #distance)
            + (counts at: #connection)
            + (counts at: #direction)
            + ((primes at: id) * (primes at: id)).
        bowls at: id put: (self save: (s * s) + id) ].
    ^ bowls
!

applyVisibleDrops: visible toBowls: initialBowls
    | bowls orderAt46 i drop order old pour nextBowls first second third position id prev next kind s stoneKinds |
    bowls := initialBowls copy.
    orderAt46 := nil.
    stoneKinds := #(1 2 3 4 5 1).
    i := 1.
    [ i <= 46 ] whileTrue: [
        drop := visible at: i.
        order := self bowlOrderFromDrop: drop.
        old := bowls copy.
        pour := Array new: 6 withAll: 0.
        first := order at: 1.
        second := order at: 2.
        third := order at: 3.
        pour at: 1 put: (self save: (drop * drop) + (((stoneTable at: i) at: 1) * (old at: first)) + (3 * i)).
        pour at: 2 put: (self save: (drop * drop) + (((stoneTable at: i) at: 2) * (old at: second)) + (5 * i)).
        pour at: 3 put: (self save: (drop * drop) + (((stoneTable at: i) at: 3) * (old at: third)) + (7 * i)).
        nextBowls := Array new: 6.
        1 to: 6 do: [ :p |
            position := p.
            id := order at: position.
            prev := order at: (self wrap1: position - 1 size: 6).
            next := order at: (self wrap1: position + 1 size: 6).
            kind := stoneKinds at: position.
            s := (old at: id)
                + (2 * (old at: prev))
                + (3 * (old at: next))
                + (pour at: position)
                + drop
                + ((stoneTable at: i) at: kind).
            nextBowls at: id put: (self save: (s * s) + (5 * (old at: prev) * (old at: next)) + (i * position)) ].
        bowls := nextBowls.
        i = 46 ifTrue: [ orderAt46 := order copy ].
        i := i + 1 ].
    ^ Array with: bowls with: orderAt46
!

postStir12: inputBowls
    | bowls stir old savedBowlSum orderNumber order nextBowls position id prev next s |
    bowls := inputBowls copy.
    stir := 1.
    [ stir <= 12 ] whileTrue: [
        old := bowls copy.
        savedBowlSum := self save: (old inject: 0 into: [ :sum :each | sum + each ]) + (149 * stir).
        orderNumber := (self regularMod: savedBowlSum - 1 by: 720) + 1.
        order := self bowlOrderFromNumber: orderNumber.
        nextBowls := Array new: 6.
        1 to: 6 do: [ :p |
            position := p.
            id := order at: position.
            prev := order at: (self wrap1: position - 1 size: 6).
            next := order at: (self wrap1: position + 1 size: 6).
            s := (old at: id)
                + (3 * (old at: prev))
                + (5 * (old at: next))
                + savedBowlSum
                + stir
                + (position * position).
            nextBowls at: id put: (self save: (s * s) + (7 * (old at: prev) * (old at: next)) ) ].
        bowls := nextBowls.
        stir := stir + 1 ].
    ^ bowls
!

sauceFor: calculationDay target: targetDay
    | counts hidden visible initial afterDrops final result |
    counts := self workCountsFor: calculationDay target: targetDay.
    hidden := self buildHiddenDropsFor: counts.
    visible := self buildVisibleDropsFor: counts hidden: hidden.
    initial := self initialBowlsFor: counts.
    afterDrops := self applyVisibleDrops: visible toBowls: initial.
    final := self postStir12: (afterDrops at: 1).
    result := Dictionary new.
    result at: #bowls put: final.
    result at: #orderAtDrop46 put: (afterDrops at: 2).
    ^ result
!
! !

!PSTNormativeOracle methodsFor: 'answers'!
nextBowlInDrop46Order: sauceResult queried: queriedId
    | order p |
    order := sauceResult at: #orderAtDrop46.
    p := order indexOf: queriedId.
    p = 0 ifTrue: [ self error: 'پوچھا گیا پیالہ ترتیب میں موجود نہیں ہے' ].
    ^ order at: ((p \\ 6) + 1)
!

askBowl: sauceResult queried: queriedId seal: seal
    | nextId bowls first directionNumber step |
    nextId := self nextBowlInDrop46Order: sauceResult queried: queriedId.
    bowls := sauceResult at: #bowls.
    first := self save:
        (((bowls at: queriedId) + seal + 181) * ((bowls at: queriedId) + seal + 181))
        + (179 * (bowls at: nextId))
        + seal.
    directionNumber := self save:
        ((first + seal + 1 + 193) * (first + seal + 1 + 193))
        + (193 * first)
        + (197 * (bowls at: 6)).
    step := ((self regularMod: directionNumber by: 2) = 1) ifTrue: [ 1 ] ifFalse: [ -1 ].
    ^ Array with: first with: step
!

answerAt: stream offset: k
    ^ 1 + (self regularMod: (stream at: 1) - 1 + ((stream at: 2) * k) by: self class m)
!

chooseRankShort: stream n: n
    | limit k x |
    ((n < 1) or: [ n > self class m ]) ifTrue: [ self error: 'مختصر انتخاب کا حجم نامعتبر ہے' ].
    limit := (self class m // n) * n.
    k := 0.
    [ true ] whileTrue: [
        x := self answerAt: stream offset: k.
        x <= limit ifTrue: [ ^ (self regularMod: x - 1 by: n) + 1 ].
        k := k + 1 ]
!

chooseRankWide: stream n: n
    | places space wide weight j digit limit |
    n <= self class m ifTrue: [ self error: 'وسیع انتخاب صرف بڑے خاندان کے لیے ہے' ].
    places := 1.
    space := self class m.
    [ space < n ] whileTrue: [
        places := places + 1.
        space := space * self class m ].
    wide := 1.
    weight := 1.
    j := 0.
    [ j < places ] whileTrue: [
        digit := (self answerAt: stream offset: j) - 1.
        wide := wide + (digit * weight).
        weight := weight * self class m.
        j := j + 1 ].
    limit := (space // n) * n.
    [ wide > limit ] whileTrue: [
        wide := 1 + (self regularMod: wide - 1 + (stream at: 2) by: space) ].
    ^ (self regularMod: wide - 1 by: n) + 1
!

chooseRank: stream n: n
    n < 1 ifTrue: [ self error: 'انتخابی خاندان خالی نہیں ہو سکتا' ].
    n <= self class m ifTrue: [ ^ self chooseRankShort: stream n: n ].
    ^ self chooseRankWide: stream n: n
!
! !

!PSTNormativeOracle methodsFor: 'distinct names'!
unrankDistinctIndicesMasterSize: n take: k rank: rank1
    | remaining out r position suffixLength block candidate chosen |
    remaining := OrderedCollection withAll: (1 to: n).
    out := OrderedCollection new.
    r := rank1.
    position := 1.
    [ position <= k ] whileTrue: [
        suffixLength := k - position.
        block := self fallingFactorial: remaining size - 1 take: suffixLength.
        candidate := 1.
        chosen := false.
        [ candidate <= remaining size and: [ chosen not ] ] whileTrue: [
            r > block
                ifTrue: [ r := r - block ]
                ifFalse: [
                    out add: (remaining at: candidate).
                    remaining removeAt: candidate.
                    chosen := true ].
            candidate := candidate + 1 ].
        chosen ifFalse: [ self error: 'منفرد ناموں کا درجہ کھولا نہیں جا سکا' ].
        position := position + 1 ].
    ^ out asArray
!
! !

!PSTNormativeOracle methodsFor: 'gate gaps'!
positiveGateGap: n
    | r stream chosen |
    n < 1 ifTrue: [ self error: 'مثبت دروازہ اشاریہ لازم ہے' ].
    r := self sauceFor: self class foundationDay target: self class foundationDay + n.
    stream := self askBowl: r queried: 1 seal: 1.
    chosen := self chooseRank: stream n: 922.
    ^ 41 + chosen
!

negativeGateGap: n
    | r stream chosen |
    n < 1 ifTrue: [ self error: 'منفی دروازہ قدر مثبت ہونی چاہیے' ].
    r := self sauceFor: self class foundationDay target: self class foundationDay - n.
    stream := self askBowl: r queried: 1 seal: 1.
    chosen := self chooseRank: stream n: 922.
    ^ 41 + chosen
!

ensureGateIndex: k
    | n |
    k > maxKnownGateIndex ifTrue: [
        n := maxKnownGateIndex + 1.
        [ n <= k ] whileTrue: [
            gate at: n put: (gate at: n - 1) + (self positiveGateGap: n).
            maxKnownGateIndex := n.
            n := n + 1 ] ].
    k < minKnownGateIndex ifTrue: [
        n := minKnownGateIndex - 1.
        [ n >= k ] whileTrue: [
            gate at: n put: (gate at: n + 1) - (self negativeGateGap: n abs).
            minKnownGateIndex := n.
            n := n - 1 ] ].
    ^ gate at: k
!

ensureGatesCoverLow: lowDay high: highDay
    lowDay > highDay ifTrue: [ self error: 'دروازوں کا احاطہ الٹا ہے' ].
    [ (gate at: minKnownGateIndex) > lowDay ] whileTrue: [ self ensureGateIndex: minKnownGateIndex - 1 ].
    [ (gate at: maxKnownGateIndex) < highDay ] whileTrue: [ self ensureGateIndex: maxKnownGateIndex + 1 ].
!

gateIndexAtOrBefore: day
    | i |
    self ensureGatesCoverLow: day high: day.
    i := minKnownGateIndex.
    [ i < maxKnownGateIndex and: [ (gate at: i + 1) <= day ] ] whileTrue: [ i := i + 1 ].
    ^ i
!

gateIndexAtOrAfter: day
    | i |
    i := self gateIndexAtOrBefore: day.
    (gate at: i) = day ifTrue: [ ^ i ].
    self ensureGateIndex: i + 1.
    ^ i + 1
!

exactGateIndex: day
    | i |
    i := self gateIndexAtOrBefore: day.
    (gate at: i) = day ifTrue: [ ^ i ].
    ^ nil
!
! !

!PSTNormativeOracle methodsFor: 'years'!
yearLengthOpen: openIndex close: closeIndex
    ^ (gate at: closeIndex) - (gate at: openIndex)
!

validYearPairOpen: openIndex close: closeIndex
    | length |
    closeIndex - openIndex < 6 ifTrue: [ ^ false ].
    length := self yearLengthOpen: openIndex close: closeIndex.
    ^ (length between: self class yearMinDays and: self class yearMaxDays)
!

yearRecordNumber: number open: openIndex close: closeIndex
    | y |
    y := Dictionary new.
    y at: #number put: number.
    y at: #openGateIndex put: openIndex.
    y at: #closeGateIndex put: closeIndex.
    y at: #openGateDay put: (gate at: openIndex).
    y at: #closeGateDay put: (gate at: closeIndex).
    ^ y
!

year5000For: calculationDay
    | candidates i j sorted r stream rank pair |
    self ensureGatesCoverLow: calculationDay - self class yearMaxDays high: calculationDay + self class yearMaxDays.
    candidates := OrderedCollection new.
    i := minKnownGateIndex.
    [ i < maxKnownGateIndex ] whileTrue: [
        j := i + 1.
        [ j <= maxKnownGateIndex ] whileTrue: [
            ((self validYearPairOpen: i close: j)
                and: [ (gate at: i) < calculationDay and: [ calculationDay <= (gate at: j) ] ])
                ifTrue: [ candidates add: (Array with: i with: j) ].
            j := j + 1 ].
        i := i + 1 ].
    candidates isEmpty ifTrue: [ self error: 'سنہ 5000 کے لیے کوئی امیدوار نہیں ملا' ].
    sorted := candidates asSortedCollection: [ :a :b |
        | la lb |
        la := self yearLengthOpen: (a at: 1) close: (a at: 2).
        lb := self yearLengthOpen: (b at: 1) close: (b at: 2).
        la = lb
            ifTrue: [ (gate at: (a at: 1)) < (gate at: (b at: 1)) ]
            ifFalse: [ la < lb ] ].
    r := self sauceFor: calculationDay target: calculationDay.
    stream := self askBowl: r queried: 1 seal: 10.
    rank := self chooseRank: stream n: sorted size.
    pair := sorted at: rank.
    ^ self yearRecordNumber: 5000 open: (pair at: 1) close: (pair at: 2)
!

nextYearFor: calculationDay known: knownYear
    | openIndex closeIndex candidates sorted r stream rank chosen |
    openIndex := knownYear at: #closeGateIndex.
    self ensureGatesCoverLow: (gate at: openIndex) high: (gate at: openIndex) + self class yearMaxDays.
    candidates := OrderedCollection new.
    closeIndex := openIndex + 1.
    [
        self ensureGateIndex: closeIndex.
        (gate at: closeIndex) - (gate at: openIndex) <= self class yearMaxDays
    ] whileTrue: [
        (self validYearPairOpen: openIndex close: closeIndex) ifTrue: [ candidates add: closeIndex ].
        closeIndex := closeIndex + 1 ].
    candidates isEmpty ifTrue: [ self error: 'اگلے سال کے لیے کوئی امیدوار نہیں ملا' ].
    sorted := candidates asSortedCollection: [ :a :b |
        (self yearLengthOpen: openIndex close: a) < (self yearLengthOpen: openIndex close: b) ].
    r := self sauceFor: calculationDay target: (gate at: openIndex).
    stream := self askBowl: r queried: 1 seal: 11.
    rank := self chooseRank: stream n: sorted size.
    chosen := sorted at: rank.
    ^ self yearRecordNumber: (knownYear at: #number) + 1 open: openIndex close: chosen
!

previousYearFor: calculationDay known: knownYear
    | closeIndex openIndex candidates sorted r stream rank chosen |
    closeIndex := knownYear at: #openGateIndex.
    self ensureGatesCoverLow: (gate at: closeIndex) - self class yearMaxDays high: (gate at: closeIndex).
    candidates := OrderedCollection new.
    openIndex := closeIndex - 1.
    [
        self ensureGateIndex: openIndex.
        (gate at: closeIndex) - (gate at: openIndex) <= self class yearMaxDays
    ] whileTrue: [
        (self validYearPairOpen: openIndex close: closeIndex) ifTrue: [ candidates add: openIndex ].
        openIndex := openIndex - 1 ].
    candidates isEmpty ifTrue: [ self error: 'پچھلے سال کے لیے کوئی امیدوار نہیں ملا' ].
    sorted := candidates asSortedCollection: [ :a :b |
        (self yearLengthOpen: a close: closeIndex) < (self yearLengthOpen: b close: closeIndex) ].
    r := self sauceFor: calculationDay target: (gate at: closeIndex).
    stream := self askBowl: r queried: 1 seal: 12.
    rank := self chooseRank: stream n: sorted size.
    chosen := sorted at: rank.
    ^ self yearRecordNumber: (knownYear at: #number) - 1 open: chosen close: closeIndex
!

findTargetYearFor: calculationDay target: targetDay
    | y |
    y := self year5000For: calculationDay.
    [ targetDay > (y at: #closeGateDay) ] whileTrue: [ y := self nextYearFor: calculationDay known: y ].
    [ targetDay <= (y at: #openGateDay) ] whileTrue: [ y := self previousYearFor: calculationDay known: y ].
    ^ y
!
! !

!PSTNormativeOracle methodsFor: 'cutlets'!
chooseCutletCountWith: structureSauce year: year
    | gateGaps candidates k stream rank |
    gateGaps := (year at: #closeGateIndex) - (year at: #openGateIndex).
    candidates := OrderedCollection new.
    k := 6.
    [ k <= 17 ] whileTrue: [
        k <= gateGaps ifTrue: [ candidates add: k ].
        k := k + 1 ].
    stream := self askBowl: structureSauce queried: 2 seal: 20.
    rank := self chooseRank: stream n: candidates size.
    ^ candidates at: rank
!

chooseCutletPartitionFor: calculationDay sauce: structureSauce year: year count: cutletCount
    | totalGaps g required family stream rank |
    totalGaps := (year at: #closeGateIndex) - (year at: #openGateIndex).
    g := self exactGateIndex: calculationDay.
    required := nil.
    (g notNil and: [ (year at: #openGateIndex) < g and: [ g < (year at: #closeGateIndex) ] ]) ifTrue: [
        required := g - (year at: #openGateIndex) ].
    family := PSTCutletPartitionCounter total: totalGaps slots: cutletCount requiredBoundary: required.
    stream := self askBowl: structureSauce queried: 2 seal: 21.
    rank := self chooseRank: stream n: family count.
    ^ family unrank1: rank
!

chooseCutletNameIndicesWith: structureSauce count: cutletCount
    | n stream rank |
    n := self fallingFactorial: 17 take: cutletCount.
    stream := self askBowl: structureSauce queried: 5 seal: 22.
    rank := self chooseRank: stream n: n.
    ^ self unrankDistinctIndicesMasterSize: 17 take: cutletCount rank: rank
!

materializeCutletsFor: year partition: partition nameIndices: names
    | cursor result k openIndex closeIndex c |
    cursor := year at: #openGateIndex.
    result := OrderedCollection new.
    1 to: partition size do: [ :idx |
        k := idx.
        openIndex := cursor.
        closeIndex := cursor + (partition at: k).
        self ensureGateIndex: closeIndex.
        c := Dictionary new.
        c at: #nameIndex put: (names at: k).
        c at: #openGateIndex put: openIndex.
        c at: #closeGateIndex put: closeIndex.
        c at: #firstDay put: (gate at: openIndex) + 1.
        c at: #lastDay put: (gate at: closeIndex).
        result add: c.
        cursor := closeIndex ].
    ^ result asArray
!
! !

!PSTNormativeOracle methodsFor: 'months'!
chooseMonthCountWith: structureSauce year: year
    | length minMonths maxMonths candidates stream rank |
    length := (year at: #closeGateDay) - (year at: #openGateDay).
    minMonths := self ceilDiv: length by: 123.
    maxMonths := 47 min: (length // 4).
    candidates := (minMonths to: maxMonths) asArray.
    stream := self askBowl: structureSauce queried: 3 seal: 30.
    rank := self chooseRank: stream n: candidates size.
    ^ candidates at: rank
!

chooseMonthLengthsWith: structureSauce year: year count: monthCount
    | length family stream rank |
    length := (year at: #closeGateDay) - (year at: #openGateDay).
    family := PSTBoundedCompositionCounter total: length slots: monthCount lo: 4 hi: 123.
    stream := self askBowl: structureSauce queried: 3 seal: 31.
    rank := self chooseRank: stream n: family count.
    ^ family unrank1: rank
!

chooseMonthWeavingWith: structureSauce lengths: monthLengths
    | family stream rank |
    family := PSTWeavingCounter lengths: monthLengths.
    stream := self askBowl: structureSauce queried: 4 seal: 32.
    rank := self chooseRank: stream n: family count.
    ^ family unrank1: rank
!

chooseMonthNameIndicesWith: structureSauce count: monthCount
    | n stream rank |
    n := self fallingFactorial: 47 take: monthCount.
    stream := self askBowl: structureSauce queried: 5 seal: 33.
    rank := self chooseRank: stream n: n.
    ^ self unrankDistinctIndicesMasterSize: 47 take: monthCount rank: rank
!
! !

!PSTNormativeOracle methodsFor: 'year structure'!
buildYearStructureFor: calculationDay year: year
    | firstDay r cutletCount partition cutletNames cutlets monthCount monthLengths weave monthNames structure |
    firstDay := (year at: #openGateDay) + 1.
    r := self sauceFor: calculationDay target: firstDay.
    cutletCount := self chooseCutletCountWith: r year: year.
    partition := self chooseCutletPartitionFor: calculationDay sauce: r year: year count: cutletCount.
    cutletNames := self chooseCutletNameIndicesWith: r count: cutletCount.
    cutlets := self materializeCutletsFor: year partition: partition nameIndices: cutletNames.
    monthCount := self chooseMonthCountWith: r year: year.
    monthLengths := self chooseMonthLengthsWith: r year: year count: monthCount.
    weave := self chooseMonthWeavingWith: r lengths: monthLengths.
    monthNames := self chooseMonthNameIndicesWith: r count: monthCount.
    structure := Dictionary new.
    structure at: #year put: year.
    structure at: #yearFirstDay put: firstDay.
    structure at: #cutletCount put: cutletCount.
    structure at: #cutletPartition put: partition.
    structure at: #cutletNameIndices put: cutletNames.
    structure at: #cutlets put: cutlets.
    structure at: #monthCount put: monthCount.
    structure at: #monthLengths put: monthLengths.
    structure at: #monthWeaving put: weave.
    structure at: #monthNameIndices put: monthNames.
    ^ structure
!
! !

!PSTNormativeOracle methodsFor: 'calendar'!
calendarDateIndicesFor: calculationDay target: targetDay
    | year structure chosenCutlet dayInCutlet offset monthId dayInMonth p result |
    year := self findTargetYearFor: calculationDay target: targetDay.
    structure := self buildYearStructureFor: calculationDay year: year.
    chosenCutlet := nil.
    (structure at: #cutlets) do: [ :c |
        (chosenCutlet isNil and: [ (c at: #firstDay) <= targetDay and: [ targetDay <= (c at: #lastDay) ] ]) ifTrue: [ chosenCutlet := c ] ].
    chosenCutlet isNil ifTrue: [ self error: 'ہدف دن کسی کٹلیٹ میں نہیں ملا' ].
    dayInCutlet := targetDay - (chosenCutlet at: #firstDay) + 1.
    offset := targetDay - ((year at: #openGateDay) + 1).
    monthId := (structure at: #monthWeaving) at: offset + 1.
    dayInMonth := 0.
    p := 1.
    [ p <= offset + 1 ] whileTrue: [
        ((structure at: #monthWeaving) at: p) = monthId ifTrue: [ dayInMonth := dayInMonth + 1 ].
        p := p + 1 ].
    result := Array new: 5.
    result at: 1 put: (year at: #number).
    result at: 2 put: (chosenCutlet at: #nameIndex).
    result at: 3 put: dayInCutlet.
    result at: 4 put: ((structure at: #monthNameIndices) at: monthId).
    result at: 5 put: dayInMonth.
    ^ result
!

calendarDateFor: calculationDay target: targetDay
    | indexed result |
    indexed := self calendarDateIndicesFor: calculationDay target: targetDay.
    result := indexed copy.
    result at: 2 put: (PSTSourceLanguageCatalog cutletNameAtCanonicalIndex: (indexed at: 2)).
    result at: 4 put: (PSTSourceLanguageCatalog monthNameAtCanonicalIndex: (indexed at: 4)).
    ^ result
!
! !
