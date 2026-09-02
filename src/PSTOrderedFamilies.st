Object subclass: #PSTBlockFamily
    instanceVariableNames: 'countBlock unrankBlock'
    classVariableNames: ''
    package: 'Pastafarian-Stage01'!

!PSTBlockFamily class methodsFor: 'instance creation'!
count: aCountBlock unrank: anUnrankBlock
    ^ self new initializeCount: aCountBlock unrank: anUnrankBlock
!
! !

!PSTBlockFamily methodsFor: 'initialization'!
initializeCount: aCountBlock unrank: anUnrankBlock
    countBlock := aCountBlock.
    unrankBlock := anUnrankBlock.
    ^ self
!
! !

!PSTBlockFamily methodsFor: 'accessing'!
count
    ^ countBlock value
!

unrank1: rank1
    (rank1 between: 1 and: self count) ifFalse: [ self error: 'درجہ خاندان کی حد سے باہر ہے' ].
    ^ unrankBlock value: rank1
!
! !

Object subclass: #PSTBoundedCompositionCounter
    instanceVariableNames: 'total slots lo hi memo'
    classVariableNames: ''
    package: 'Pastafarian-Stage01'!

!PSTBoundedCompositionCounter class methodsFor: 'instance creation'!
total: aTotal slots: aSlots lo: aLo hi: aHi
    ^ self new initializeTotal: aTotal slots: aSlots lo: aLo hi: aHi
!
! !

!PSTBoundedCompositionCounter methodsFor: 'initialization'!
initializeTotal: aTotal slots: aSlots lo: aLo hi: aHi
    total := aTotal.
    slots := aSlots.
    lo := aLo.
    hi := aHi.
    memo := Dictionary new.
    ^ self
!
! !

!PSTBoundedCompositionCounter methodsFor: 'counting'!
countRemaining: rem slots: k
    | key sum |
    k = 0 ifTrue: [ ^ rem = 0 ifTrue: [ 1 ] ifFalse: [ 0 ] ].
    ((rem < (k * lo)) or: [ rem > (k * hi) ]) ifTrue: [ ^ 0 ].
    key := Array with: rem with: k.
    (memo includesKey: key) ifTrue: [ ^ memo at: key ].
    sum := 0.
    lo to: hi do: [ :x | sum := sum + (self countRemaining: rem - x slots: k - 1) ].
    memo at: key put: sum.
    ^ sum
!

count
    ^ self countRemaining: total slots: slots
!
! !

!PSTBoundedCompositionCounter methodsFor: 'unranking'!
unrank1: rank1
    | r rem out position chosen x count |
    (rank1 between: 1 and: self count) ifFalse: [ self error: 'محدود ترکیب کا درجہ حد سے باہر ہے' ].
    r := rank1.
    rem := total.
    out := OrderedCollection new.
    position := 1.
    [ position <= slots ] whileTrue: [
        chosen := false.
        x := lo.
        [ x <= hi and: [ chosen not ] ] whileTrue: [
            count := self countRemaining: rem - x slots: slots - position.
            r > count
                ifTrue: [ r := r - count ]
                ifFalse: [
                    out add: x.
                    rem := rem - x.
                    chosen := true ].
            x := x + 1 ].
        chosen ifFalse: [ self error: 'محدود ترکیب کا درجہ کھولا نہیں جا سکا' ].
        position := position + 1 ].
    ^ out asArray
!
! !

Object subclass: #PSTCutletPartitionCounter
    instanceVariableNames: 'total slots required memo'
    classVariableNames: ''
    package: 'Pastafarian-Stage01'!

!PSTCutletPartitionCounter class methodsFor: 'instance creation'!
total: aTotal slots: aSlots requiredBoundary: requiredOrNil
    ^ self new initializeTotal: aTotal slots: aSlots requiredBoundary: requiredOrNil
!
! !

!PSTCutletPartitionCounter methodsFor: 'initialization'!
initializeTotal: aTotal slots: aSlots requiredBoundary: requiredOrNil
    total := aTotal.
    slots := aSlots.
    required := requiredOrNil.
    memo := Dictionary new.
    ^ self
!
! !

!PSTCutletPartitionCounter methodsFor: 'counting'!
countRemaining: rem slots: k cumulative: cumulative hit: hit
    | key sum maxX nextC nextHit |
    k = 0 ifTrue: [
        rem = 0 ifFalse: [ ^ 0 ].
        required isNil ifTrue: [ ^ 1 ].
        ^ hit ifTrue: [ 1 ] ifFalse: [ 0 ] ].
    rem < k ifTrue: [ ^ 0 ].
    key := Array with: rem with: k with: cumulative with: hit.
    (memo includesKey: key) ifTrue: [ ^ memo at: key ].
    sum := 0.
    maxX := rem - (k - 1).
    1 to: maxX do: [ :x |
        nextC := cumulative + x.
        nextHit := hit.
        (required notNil and: [ hit not ]) ifTrue: [
            nextC = required
                ifTrue: [ nextHit := true ]
                ifFalse: [ nextC > required ifTrue: [ nextHit := #skip ] ] ].
        nextHit = #skip ifFalse: [
            sum := sum + (self countRemaining: rem - x slots: k - 1 cumulative: nextC hit: nextHit) ] ].
    memo at: key put: sum.
    ^ sum
!

count
    ^ self countRemaining: total slots: slots cumulative: 0 hit: false
!
! !

!PSTCutletPartitionCounter methodsFor: 'unranking'!
unrank1: rank1
    | r rem k cumulative hit out maxX x chosen nextC nextHit block |
    (rank1 between: 1 and: self count) ifFalse: [ self error: 'کٹلیٹ تقسیم کا درجہ حد سے باہر ہے' ].
    r := rank1.
    rem := total.
    k := slots.
    cumulative := 0.
    hit := false.
    out := OrderedCollection new.
    [ k > 0 ] whileTrue: [
        maxX := rem - (k - 1).
        x := 1.
        chosen := false.
        [ x <= maxX and: [ chosen not ] ] whileTrue: [
            nextC := cumulative + x.
            nextHit := hit.
            (required notNil and: [ hit not ]) ifTrue: [
                nextC = required
                    ifTrue: [ nextHit := true ]
                    ifFalse: [ nextC > required ifTrue: [ nextHit := #skip ] ] ].
            nextHit = #skip
                ifFalse: [
                    block := self countRemaining: rem - x slots: k - 1 cumulative: nextC hit: nextHit.
                    r > block
                        ifTrue: [ r := r - block ]
                        ifFalse: [
                            out add: x.
                            rem := rem - x.
                            k := k - 1.
                            cumulative := nextC.
                            hit := nextHit.
                            chosen := true ] ].
            x := x + 1 ].
        chosen ifFalse: [ self error: 'کٹلیٹ تقسیم کا درجہ کھولا نہیں جا سکا' ] ].
    ^ out asArray
!
! !

Object subclass: #PSTWeavingCounter
    instanceVariableNames: 'lengths memo totalLength'
    classVariableNames: ''
    package: 'Pastafarian-Stage01'!

!PSTWeavingCounter class methodsFor: 'instance creation'!
lengths: anArray
    ^ self new initializeLengths: anArray
!
! !

!PSTWeavingCounter methodsFor: 'initialization'!
initializeLengths: anArray
    lengths := anArray copy.
    memo := Dictionary new.
    totalLength := lengths inject: 0 into: [ :s :each | s + each ].
    ^ self
!
! !

!PSTWeavingCounter methodsFor: 'testing'!
legalMove: j remaining: remaining openedUpTo: opened closedUpTo: closed
    | alreadyOpened willClose |
    (remaining at: j) = 0 ifTrue: [ ^ false ].
    alreadyOpened := (remaining at: j) < (lengths at: j).
    (alreadyOpened not and: [ j ~= opened + 1 ]) ifTrue: [ ^ false ].
    willClose := (remaining at: j) = 1.
    (willClose and: [ j ~= closed + 1 ]) ifTrue: [ ^ false ].
    ^ true
!

nextStateFor: j remaining: remaining openedUpTo: opened closedUpTo: closed
    | next nextOpened nextClosed |
    next := remaining copy.
    nextOpened := opened.
    nextClosed := closed.
    (next at: j) = (lengths at: j) ifTrue: [ nextOpened := j ].
    next at: j put: (next at: j) - 1.
    (next at: j) = 0 ifTrue: [ nextClosed := j ].
    ^ Array with: next with: nextOpened with: nextClosed
!
! !

!PSTWeavingCounter methodsFor: 'counting'!
countRemaining: remaining openedUpTo: opened closedUpTo: closed
    | key sum state |
    (remaining allSatisfy: [ :each | each = 0 ]) ifTrue: [ ^ 1 ].
    key := Array with: remaining copy with: opened with: closed.
    (memo includesKey: key) ifTrue: [ ^ memo at: key ].
    sum := 0.
    1 to: lengths size do: [ :j |
        (self legalMove: j remaining: remaining openedUpTo: opened closedUpTo: closed) ifTrue: [
            state := self nextStateFor: j remaining: remaining openedUpTo: opened closedUpTo: closed.
            sum := sum + (self countRemaining: (state at: 1) openedUpTo: (state at: 2) closedUpTo: (state at: 3)) ] ].
    memo at: key put: sum.
    ^ sum
!

count
    ^ self countRemaining: lengths copy openedUpTo: 0 closedUpTo: 0
!
! !

!PSTWeavingCounter methodsFor: 'unranking'!
unrank1: rank1
    | r remaining opened closed out chosen j state block |
    (rank1 between: 1 and: self count) ifFalse: [ self error: 'مہینوں کی بُنائی کا درجہ حد سے باہر ہے' ].
    r := rank1.
    remaining := lengths copy.
    opened := 0.
    closed := 0.
    out := OrderedCollection new.
    [ out size < totalLength ] whileTrue: [
        chosen := false.
        j := 1.
        [ j <= lengths size and: [ chosen not ] ] whileTrue: [
            (self legalMove: j remaining: remaining openedUpTo: opened closedUpTo: closed) ifTrue: [
                state := self nextStateFor: j remaining: remaining openedUpTo: opened closedUpTo: closed.
                block := self countRemaining: (state at: 1) openedUpTo: (state at: 2) closedUpTo: (state at: 3).
                r > block
                    ifTrue: [ r := r - block ]
                    ifFalse: [
                        out add: j.
                        remaining := state at: 1.
                        opened := state at: 2.
                        closed := state at: 3.
                        chosen := true ] ].
            j := j + 1 ].
        chosen ifFalse: [ self error: 'مہینوں کی بُنائی کا درجہ کھولا نہیں جا سکا' ] ].
    ^ out asArray
!
! !
