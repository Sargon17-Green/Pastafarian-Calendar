module NormativeOracle exposing
    ( AnswerStream
    , CalendarDate
    , CanonicalCalendarDate
    , GateState
    , SauceResult
    , Stone
    , WorkCounts
    , answerAt
    , buildStones
    , calendarDate
    , calendarDateCanonical
    , chooseRank
    , chooseRankShort
    , chooseRankWide
    , countBoundedCompositions
    , countCutletPartitionsForTest
    , countWeavingsForLengths
    , dayCount
    , fallingFactorial
    , foundationDay
    , initialGateState
    , m
    , negativeGateGap
    , permutationUnrank1
    , positiveGateGap
    , save
    , sauce
    , tabletsDay
    , yearMaxDays
    , unrankBoundedComposition
    , unrankCutletPartition
    , unrankDistinctIndices
    , unrankWeavingForLengths
    , workCounts
    )

import Array exposing (Array)
import Dict exposing (Dict)
import Pastafari.ExactInt as BI exposing (BigInt)
import Pastafari.SourceLanguageCatalog as Catalog


m : BigInt
m =
    BI.sub (BI.powSmall 2 127) BI.one


tabletsDay : BigInt
tabletsDay =
    BI.fromInt -278522


foundationDay : BigInt
foundationDay =
    BI.fromInt -15055671


yearMinDays : Int
yearMinDays =
    252


yearMaxDays : Int
yearMaxDays =
    5778


type alias WorkCounts =
    { action : BigInt
    , target : BigInt
    , distance : BigInt
    , connection : BigInt
    , direction : BigInt
    }


type StoneKind
    = Wheat
    | Barley
    | Salt
    | Bitter
    | Red


type alias Stone =
    { wheat : BigInt
    , barley : BigInt
    , salt : BigInt
    , bitter : BigInt
    , red : BigInt
    }


type alias HiddenCoeff =
    { a : Int
    , b : Int
    , c : Int
    , d : Int
    }


type alias VisibleGrind =
    { a : Int
    , b : Int
    , c : Int
    , d : Int
    , kind : StoneKind
    }


type alias SauceResult =
    { bowls : Array BigInt
    , orderAtDrop46 : List Int
    }


type alias AnswerStream =
    { first : BigInt
    , directionStep : Int
    }


type alias GateState =
    { gates : Dict String BigInt
    , minKnown : BigInt
    , maxKnown : BigInt
    }


type alias Year =
    { number : BigInt
    , openGateIndex : BigInt
    , closeGateIndex : BigInt
    , openGateDay : BigInt
    , closeGateDay : BigInt
    }


type alias Cutlet =
    { canonicalIndex : Int
    , firstDay : BigInt
    , lastDay : BigInt
    }


type alias YearStructure =
    { cutlets : List Cutlet
    , monthWeaving : List Int
    , monthCanonicalIndices : List Int
    }


type alias CanonicalCalendarDate =
    { yearNumber : BigInt
    , cutletCanonicalIndex : Int
    , dayInCutlet : BigInt
    , monthCanonicalIndex : Int
    , dayInMonth : Int
    }


type alias CalendarDate =
    { yearNumber : BigInt
    , cutletName : String
    , dayInCutlet : BigInt
    , monthName : String
    , dayInMonth : Int
    }


expectMaybe : String -> Maybe a -> a
expectMaybe message maybeValue =
    case maybeValue of
        Just value ->
            value

        Nothing ->
            Debug.todo message


save : BigInt -> BigInt
save x =
    BI.add BI.one (BI.regularMod (BI.sub x BI.one) m)


dayCount : BigInt -> BigInt
dayCount day =
    case BI.compareBig day foundationDay of
        EQ ->
            BI.one

        GT ->
            BI.add (BI.mulSmall (BI.sub day foundationDay) 2) BI.one

        LT ->
            BI.mulSmall (BI.sub foundationDay day) 2


workCounts : BigInt -> BigInt -> WorkCounts
workCounts calculationDay targetDay =
    let
        c =
            dayCount calculationDay

        t =
            dayCount targetDay

        chronological =
            BI.absBig (BI.sub targetDay calculationDay)

        direction =
            case BI.compareBig targetDay calculationDay of
                LT ->
                    BI.one

                EQ ->
                    BI.fromInt 2

                GT ->
                    BI.fromInt 3
    in
    { action = c
    , target = t
    , distance = BI.add chronological BI.one
    , connection = BI.add c t
    , direction = direction
    }


initialStone : Stone
initialStone =
    { wheat = BI.fromInt 17
    , barley = BI.fromInt 29
    , salt = BI.fromInt 43
    , bitter = BI.fromInt 71
    , red = BI.fromInt 101
    }


buildStones : Array Stone
buildStones =
    let
        loop i current reversed =
            if i > 46 then
                Array.fromList (List.reverse reversed)

            else
                let
                    old =
                        current

                    next =
                        { wheat = save (BI.add (BI.add (BI.square old.wheat) (BI.mulSmall old.barley 3)) (BI.fromInt i))
                        , barley = save (BI.add (BI.add (BI.square old.barley) (BI.mulSmall old.salt 5)) old.wheat)
                        , salt = save (BI.add (BI.add (BI.square old.salt) (BI.mulSmall old.bitter 7)) old.barley)
                        , bitter = save (BI.add (BI.add (BI.square old.bitter) (BI.mulSmall old.red 11)) old.salt)
                        , red = save (BI.add (BI.add (BI.square old.red) (BI.mulSmall old.wheat 13)) old.bitter)
                        }
                in
                loop (i + 1) next (next :: reversed)
    in
    loop 2 initialStone [ initialStone ]


stoneAt : Array Stone -> Int -> Stone
stoneAt stones index =
    Array.get (index - 1) stones
        |> expectMaybe "Steinavísitala er utan leyfilegs sviðs."


stoneValue : StoneKind -> Stone -> BigInt
stoneValue kind stone =
    case kind of
        Wheat ->
            stone.wheat

        Barley ->
            stone.barley

        Salt ->
            stone.salt

        Bitter ->
            stone.bitter

        Red ->
            stone.red


sumStone : Stone -> BigInt
sumStone stone =
    BI.add stone.wheat stone.barley
        |> BI.add stone.salt
        |> BI.add stone.bitter
        |> BI.add stone.red


hiddenCoeff : Int -> HiddenCoeff
hiddenCoeff k =
    case k of
        1 ->
            { a = 3, b = 4, c = 6, d = 8 }

        2 ->
            { a = 5, b = 7, c = 10, d = 12 }

        3 ->
            { a = 7, b = 10, c = 14, d = 16 }

        4 ->
            { a = 9, b = 13, c = 18, d = 20 }

        5 ->
            { a = 11, b = 16, c = 22, d = 24 }

        6 ->
            { a = 13, b = 19, c = 26, d = 28 }

        _ ->
            { a = 15, b = 22, c = 30, d = 32 }


hiddenStoneKind : Int -> StoneKind
hiddenStoneKind grind =
    case grind of
        1 ->
            Wheat

        2 ->
            Barley

        3 ->
            Salt

        4 ->
            Bitter

        5 ->
            Red

        6 ->
            Wheat

        _ ->
            Barley


buildHiddenDrops : WorkCounts -> Array Stone -> Array BigInt
buildHiddenDrops counts stones =
    List.range 1 7
        |> List.map
            (\k ->
                let
                    coeff =
                        hiddenCoeff k

                    stone =
                        stoneAt stones k

                    start =
                        counts.action
                            |> BI.add (BI.mulSmall counts.target coeff.a)
                            |> BI.add (BI.mulSmall counts.distance coeff.b)
                            |> BI.add (BI.mulSmall counts.connection coeff.c)
                            |> BI.add (BI.mulSmall counts.direction coeff.d)
                            |> BI.add (sumStone stone)
                            |> save

                    grind g x =
                        if g > 7 then
                            x

                        else
                            let
                                next =
                                    BI.square x
                                        |> BI.add (BI.mulSmall x 3)
                                        |> BI.add (stoneValue (hiddenStoneKind g) stone)
                                        |> BI.add (BI.fromInt g)
                                        |> save
                            in
                            grind (g + 1) next
                in
                grind 1 start
            )
        |> Array.fromList


visibleGrind : Int -> VisibleGrind
visibleGrind grind =
    case grind of
        1 ->
            { a = 3, b = 5, c = 7, d = 11, kind = Wheat }

        2 ->
            { a = 5, b = 7, c = 11, d = 13, kind = Barley }

        3 ->
            { a = 7, b = 11, c = 13, d = 17, kind = Salt }

        4 ->
            { a = 11, b = 13, c = 17, d = 19, kind = Bitter }

        5 ->
            { a = 13, b = 17, c = 19, d = 23, kind = Red }

        6 ->
            { a = 17, b = 19, c = 23, d = 29, kind = Wheat }

        7 ->
            { a = 19, b = 23, c = 29, d = 31, kind = Barley }

        8 ->
            { a = 23, b = 29, c = 31, d = 37, kind = Salt }

        9 ->
            { a = 29, b = 31, c = 37, d = 41, kind = Bitter }

        10 ->
            { a = 31, b = 37, c = 41, d = 43, kind = Red }

        _ ->
            { a = 37, b = 41, c = 43, d = 47, kind = Wheat }


arrayGetBig : Array BigInt -> Int -> BigInt
arrayGetBig values index =
    Array.get index values
        |> expectMaybe "Fylkisvísitala er utan leyfilegs sviðs."


priorValue : Array BigInt -> Array BigInt -> Int -> Int -> BigInt
priorValue visible hidden i back =
    let
        slot =
            i - back
    in
    if slot >= 1 then
        arrayGetBig visible (slot - 1)

    else
        let
            k =
                1 - slot
        in
        arrayGetBig hidden (k - 1)


buildVisibleDrops : WorkCounts -> Array Stone -> Array BigInt -> Array BigInt
buildVisibleDrops counts stones hidden =
    let
        loop i visible =
            if i > 46 then
                visible

            else
                let
                    p1 =
                        priorValue visible hidden i 1

                    p3 =
                        priorValue visible hidden i 3

                    p7 =
                        priorValue visible hidden i 7

                    stone =
                        stoneAt stones i

                    start =
                        BI.mul stone.wheat counts.action
                            |> BI.add (BI.mul stone.barley counts.target)
                            |> BI.add (BI.mul stone.salt counts.distance)
                            |> BI.add (BI.mul stone.bitter counts.connection)
                            |> BI.add (BI.mul stone.red counts.direction)
                            |> BI.add p1
                            |> BI.add (BI.mulSmall p3 3)
                            |> BI.add (BI.mulSmall p7 5)
                            |> BI.add (BI.fromInt i)
                            |> save

                    grind g x =
                        if g > 11 then
                            x

                        else
                            let
                                row =
                                    visibleGrind g

                                next =
                                    BI.square x
                                        |> BI.add (BI.mulSmall x row.a)
                                        |> BI.add (BI.mulSmall p1 row.b)
                                        |> BI.add (BI.mulSmall p3 row.c)
                                        |> BI.add (BI.mulSmall p7 row.d)
                                        |> BI.add (stoneValue row.kind stone)
                                        |> save
                            in
                            grind (g + 1) next

                    drop =
                        grind 1 start
                in
                loop (i + 1) (Array.push drop visible)
    in
    loop 1 Array.empty


factorial : Int -> Int
factorial n =
    if n <= 1 then
        1

    else
        n * factorial (n - 1)


removeAt : Int -> List a -> List a
removeAt index items =
    List.take index items ++ List.drop (index + 1) items


permutationUnrank1 : Int -> List Int -> List Int
permutationUnrank1 rank1 itemsAscending =
    let
        loop rank0 remaining result =
            case remaining of
                [] ->
                    result

                _ ->
                    let
                        slotsLeft =
                            List.length remaining

                        block =
                            factorial (slotsLeft - 1)

                        q =
                            rank0 // block

                        nextRank =
                            modBy block rank0

                        chosen =
                            List.drop q remaining
                                |> List.head
                                |> expectMaybe "Umröðunarröð gaf ógilda sæti."
                    in
                    loop nextRank (removeAt q remaining) (result ++ [ chosen ])
    in
    loop (rank1 - 1) itemsAscending []


smallMod : BigInt -> Int -> Int
smallMod value divisor =
    BI.regularMod value (BI.fromInt divisor)
        |> BI.toIntMaybe
        |> expectMaybe "Lítil leif komst ekki í Elm Int þótt deilirinn sé lítill."


bowlOrderFromDrop : BigInt -> List Int
bowlOrderFromDrop dropValue =
    let
        orderNumber =
            smallMod (BI.sub dropValue BI.one) 720 + 1
    in
    permutationUnrank1 orderNumber [ 1, 2, 3, 4, 5, 6 ]


initialBowls : WorkCounts -> Array BigInt
initialBowls counts =
    let
        primes =
            Array.fromList [ 17, 19, 23, 29, 31, 37 ]
    in
    List.range 1 6
        |> List.map
            (\bowlId ->
                let
                    prime =
                        Array.get (bowlId - 1) primes
                            |> expectMaybe "Skálavísitala fann ekki frumtölu."

                    s =
                        counts.action
                            |> BI.add (BI.mulSmall counts.target bowlId)
                            |> BI.add counts.distance
                            |> BI.add counts.connection
                            |> BI.add counts.direction
                            |> BI.add (BI.fromInt (prime * prime))
                in
                save (BI.add (BI.square s) (BI.fromInt bowlId))
            )
        |> Array.fromList


wrap1 : Int -> Int -> Int
wrap1 position size =
    modBy size (position - 1) + 1


orderAt : List Int -> Int -> Int
orderAt order position =
    List.drop (position - 1) order
        |> List.head
        |> expectMaybe "Skálaröð vantar umbeðið sæti."


applyVisibleDropsToBowls : Array BigInt -> Array BigInt -> Array Stone -> ( Array BigInt, List Int )
applyVisibleDropsToBowls initial visible stones =
    let
        stoneByPosition position =
            case position of
                1 ->
                    Wheat

                2 ->
                    Barley

                3 ->
                    Salt

                4 ->
                    Bitter

                5 ->
                    Red

                _ ->
                    Wheat

        loop i bowls latched =
            if i > 46 then
                ( bowls, latched )

            else
                let
                    drop =
                        arrayGetBig visible (i - 1)

                    order =
                        bowlOrderFromDrop drop

                    old =
                        bowls

                    firstBowl =
                        orderAt order 1

                    secondBowl =
                        orderAt order 2

                    thirdBowl =
                        orderAt order 3

                    stone =
                        stoneAt stones i

                    pours =
                        Array.fromList
                            [ save (BI.square drop |> BI.add (BI.mul stone.wheat (arrayGetBig old (firstBowl - 1))) |> BI.add (BI.fromInt (3 * i)))
                            , save (BI.square drop |> BI.add (BI.mul stone.barley (arrayGetBig old (secondBowl - 1))) |> BI.add (BI.fromInt (5 * i)))
                            , save (BI.square drop |> BI.add (BI.mul stone.salt (arrayGetBig old (thirdBowl - 1))) |> BI.add (BI.fromInt (7 * i)))
                            , BI.zero
                            , BI.zero
                            , BI.zero
                            ]

                    nextBowls =
                        List.range 1 6
                            |> List.foldl
                                (\position pending ->
                                    let
                                        bowlId =
                                            orderAt order position

                                        prevId =
                                            orderAt order (wrap1 (position - 1) 6)

                                        nextId =
                                            orderAt order (wrap1 (position + 1) 6)

                                        s =
                                            arrayGetBig old (bowlId - 1)
                                                |> BI.add (BI.mulSmall (arrayGetBig old (prevId - 1)) 2)
                                                |> BI.add (BI.mulSmall (arrayGetBig old (nextId - 1)) 3)
                                                |> BI.add (arrayGetBig pours (position - 1))
                                                |> BI.add drop
                                                |> BI.add (stoneValue (stoneByPosition position) stone)

                                        value =
                                            BI.square s
                                                |> BI.add (BI.mulSmall (BI.mul (arrayGetBig old (prevId - 1)) (arrayGetBig old (nextId - 1))) 5)
                                                |> BI.add (BI.fromInt (i * position))
                                                |> save
                                    in
                                    Array.set (bowlId - 1) value pending
                                )
                                old

                    nextLatched =
                        if i == 46 then
                            order

                        else
                            latched
                in
                loop (i + 1) nextBowls nextLatched
    in
    loop 1 initial []


sumBowls : Array BigInt -> BigInt
sumBowls bowls =
    List.range 0 5
        |> List.foldl (\index acc -> BI.add acc (arrayGetBig bowls index)) BI.zero


postStir12 : Array BigInt -> Array BigInt
postStir12 initial =
    let
        loop stir bowls =
            if stir > 12 then
                bowls

            else
                let
                    old =
                        bowls

                    savedBowlSum =
                        save (BI.add (sumBowls old) (BI.fromInt (149 * stir)))

                    orderNumber =
                        smallMod (BI.sub savedBowlSum BI.one) 720 + 1

                    order =
                        permutationUnrank1 orderNumber [ 1, 2, 3, 4, 5, 6 ]

                    nextBowls =
                        List.range 1 6
                            |> List.foldl
                                (\position pending ->
                                    let
                                        bowlId =
                                            orderAt order position

                                        prevId =
                                            orderAt order (wrap1 (position - 1) 6)

                                        nextId =
                                            orderAt order (wrap1 (position + 1) 6)

                                        s =
                                            arrayGetBig old (bowlId - 1)
                                                |> BI.add (BI.mulSmall (arrayGetBig old (prevId - 1)) 3)
                                                |> BI.add (BI.mulSmall (arrayGetBig old (nextId - 1)) 5)
                                                |> BI.add savedBowlSum
                                                |> BI.add (BI.fromInt stir)
                                                |> BI.add (BI.fromInt (position * position))

                                        value =
                                            BI.square s
                                                |> BI.add (BI.mulSmall (BI.mul (arrayGetBig old (prevId - 1)) (arrayGetBig old (nextId - 1))) 7)
                                                |> save
                                    in
                                    Array.set (bowlId - 1) value pending
                                )
                                old
                in
                loop (stir + 1) nextBowls
    in
    loop 1 initial


sauce : BigInt -> BigInt -> SauceResult
sauce calculationDay targetDay =
    let
        counts =
            workCounts calculationDay targetDay

        stones =
            buildStones

        hidden =
            buildHiddenDrops counts stones

        visible =
            buildVisibleDrops counts stones hidden

        bowls =
            initialBowls counts

        ( afterDrops, orderAtDrop46 ) =
            applyVisibleDropsToBowls bowls visible stones
    in
    { bowls = postStir12 afterDrops
    , orderAtDrop46 = orderAtDrop46
    }


indexOf : Int -> List Int -> Int
indexOf wanted items =
    let
        loop position rest =
            case rest of
                [] ->
                    Debug.todo "Spurður skál fannst ekki í röð dropa 46."

                x :: xs ->
                    if x == wanted then
                        position

                    else
                        loop (position + 1) xs
    in
    loop 1 items


askBowl : SauceResult -> Int -> Int -> AnswerStream
askBowl sauceResult queriedBowlId seal =
    let
        position =
            indexOf queriedBowlId sauceResult.orderAtDrop46

        nextId =
            orderAt sauceResult.orderAtDrop46 (wrap1 (position + 1) 6)

        queried =
            arrayGetBig sauceResult.bowls (queriedBowlId - 1)

        nextBowl =
            arrayGetBig sauceResult.bowls (nextId - 1)

        first =
            BI.add queried (BI.fromInt (seal + 181))
                |> BI.square
                |> BI.add (BI.mulSmall nextBowl 179)
                |> BI.add (BI.fromInt seal)
                |> save

        directionNumber =
            BI.add first (BI.fromInt (seal + 194))
                |> BI.square
                |> BI.add (BI.mulSmall first 193)
                |> BI.add (BI.mulSmall (arrayGetBig sauceResult.bowls 5) 197)
                |> save

        step =
            if smallMod directionNumber 2 == 1 then
                1

            else
                -1
    in
    { first = first, directionStep = step }


answerAtBigOffset : AnswerStream -> BigInt -> BigInt
answerAtBigOffset stream offset =
    let
        signedOffset =
            BI.mulSmall offset stream.directionStep

        shifted =
            BI.add (BI.sub stream.first BI.one) signedOffset
    in
    BI.add (BI.regularMod shifted m) BI.one


answerAt : AnswerStream -> Int -> BigInt
answerAt stream k =
    answerAtBigOffset stream (BI.fromInt k)


chooseRankShort : AnswerStream -> BigInt -> BigInt
chooseRankShort stream n =
    let
        acceptanceLimit =
            BI.mul (BI.floorDivPositive m n) n

        loop offset =
            let
                x =
                    answerAtBigOffset stream offset
            in
            if BI.compareBig x acceptanceLimit /= GT then
                BI.add (BI.regularMod (BI.sub x BI.one) n) BI.one

            else
                loop (BI.add offset BI.one)
    in
    loop BI.zero


smallestPowerCount : BigInt -> ( Int, BigInt )
smallestPowerCount n =
    let
        loop k space =
            if BI.compareBig space n /= LT then
                ( k, space )

            else
                loop (k + 1) (BI.mul space m)
    in
    loop 1 m


chooseRankWide : AnswerStream -> BigInt -> BigInt
chooseRankWide stream n =
    let
        ( places, space ) =
            smallestPowerCount n

        build j weight wide =
            if j >= places then
                wide

            else
                let
                    digit =
                        BI.sub (answerAt stream j) BI.one
                in
                build (j + 1) (BI.mul weight m) (BI.add wide (BI.mul digit weight))

        wide0 =
            build 0 BI.one BI.one

        acceptanceLimit =
            BI.mul (BI.floorDivPositive space n) n

        move wide =
            if BI.compareBig wide acceptanceLimit /= GT then
                wide

            else
                let
                    shifted =
                        BI.add (BI.sub wide BI.one) (BI.fromInt stream.directionStep)
                in
                move (BI.add (BI.regularMod shifted space) BI.one)

        accepted =
            move wide0
    in
    BI.add (BI.regularMod (BI.sub accepted BI.one) n) BI.one


chooseRank : AnswerStream -> BigInt -> BigInt
chooseRank stream n =
    if BI.compareBig n m /= GT then
        chooseRankShort stream n

    else
        chooseRankWide stream n


fallingFactorial : Int -> Int -> BigInt
fallingFactorial n k =
    let
        loop j acc =
            if j >= k then
                acc

            else
                loop (j + 1) (BI.mulSmall acc (n - j))
    in
    loop 0 BI.one


unrankDistinctIndices : Int -> Int -> BigInt -> List Int
unrankDistinctIndices masterSize k rank1 =
    let
        chooseCandidate remaining block r candidatePosition =
            case List.drop candidatePosition remaining |> List.head of
                Nothing ->
                    Debug.todo "Nafnavalröð fór út fyrir hlutumraðanafjölskylduna."

                Just candidate ->
                    if BI.compareBig r block == GT then
                        chooseCandidate remaining block (BI.sub r block) (candidatePosition + 1)

                    else
                        ( candidate, r, candidatePosition )

        loop position remaining r out =
            if position > k then
                out

            else
                let
                    suffixLength =
                        k - position

                    block =
                        fallingFactorial (List.length remaining - 1) suffixLength

                    ( chosen, nextRank, chosenPosition ) =
                        chooseCandidate remaining block r 0
                in
                loop (position + 1) (removeAt chosenPosition remaining) nextRank (out ++ [ chosen ])
    in
    loop 1 (List.range 1 masterSize) rank1 []


boundedKey : Int -> Int -> String
boundedKey rem slots =
    String.fromInt rem ++ ":" ++ String.fromInt slots


countBoundedMemo : Int -> Int -> Int -> Int -> Dict String BigInt -> ( BigInt, Dict String BigInt )
countBoundedMemo rem slots lo hi memo =
    if slots == 0 then
        ( if rem == 0 then BI.one else BI.zero, memo )

    else if rem < slots * lo || rem > slots * hi then
        ( BI.zero, memo )

    else
        let
            key =
                boundedKey rem slots
        in
        case Dict.get key memo of
            Just value ->
                ( value, memo )

            Nothing ->
                let
                    scan x acc currentMemo =
                        if x > hi then
                            ( acc, Dict.insert key acc currentMemo )

                        else
                            let
                                ( count, nextMemo ) =
                                    countBoundedMemo (rem - x) (slots - 1) lo hi currentMemo
                            in
                            scan (x + 1) (BI.add acc count) nextMemo
                in
                scan lo BI.zero memo


countBoundedCompositions : Int -> Int -> Int -> Int -> BigInt
countBoundedCompositions total slots lo hi =
    countBoundedMemo total slots lo hi Dict.empty |> Tuple.first


unrankBoundedComposition : Int -> Int -> Int -> Int -> BigInt -> List Int
unrankBoundedComposition total slots lo hi rank1 =
    let
        chooseX x rem slotsLeft r memo =
            if x > hi then
                Debug.todo "Röð takmarkaðrar samsetningar fór út fyrir fjölskylduna."

            else
                let
                    ( block, nextMemo ) =
                        countBoundedMemo (rem - x) (slotsLeft - 1) lo hi memo
                in
                if BI.compareBig r block == GT then
                    chooseX (x + 1) rem slotsLeft (BI.sub r block) nextMemo

                else
                    ( x, r, nextMemo )

        loop position rem r memo out =
            if position > slots then
                out

            else
                let
                    slotsLeft =
                        slots - position + 1

                    ( chosen, nextRank, nextMemo ) =
                        chooseX lo rem slotsLeft r memo
                in
                loop (position + 1) (rem - chosen) nextRank nextMemo (out ++ [ chosen ])
    in
    loop 1 total rank1 Dict.empty []


type alias WeaveState =
    { remaining : List Int
    , openedUpTo : Int
    , closedUpTo : Int
    }


listAt : List Int -> Int -> Int
listAt values oneBasedIndex =
    List.drop (oneBasedIndex - 1) values
        |> List.head
        |> expectMaybe "Listavísitala er utan leyfilegs sviðs."


setListAt : Int -> Int -> List Int -> List Int
setListAt oneBasedIndex value values =
    List.indexedMap
        (\index old ->
            if index == oneBasedIndex - 1 then
                value

            else
                old
        )
        values


weaveKey : WeaveState -> String
weaveKey state =
    String.join "," (List.map String.fromInt state.remaining)
        ++ "|"
        ++ String.fromInt state.openedUpTo
        ++ "|"
        ++ String.fromInt state.closedUpTo


legalWeaveMove : List Int -> WeaveState -> Int -> Bool
legalWeaveMove lengths state j =
    let
        remaining =
            listAt state.remaining j

        original =
            listAt lengths j

        alreadyOpened =
            remaining < original

        willClose =
            remaining == 1
    in
    remaining > 0
        && (alreadyOpened || j == state.openedUpTo + 1)
        && (not willClose || j == state.closedUpTo + 1)


applyWeaveMove : List Int -> WeaveState -> Int -> WeaveState
applyWeaveMove lengths state j =
    let
        remainingBefore =
            listAt state.remaining j

        original =
            listAt lengths j

        opened =
            if remainingBefore == original then
                j

            else
                state.openedUpTo

        remainingAfter =
            remainingBefore - 1

        closed =
            if remainingAfter == 0 then
                j

            else
                state.closedUpTo
    in
    { remaining = setListAt j remainingAfter state.remaining
    , openedUpTo = opened
    , closedUpTo = closed
    }


countWeavingsMemo : List Int -> WeaveState -> Dict String BigInt -> ( BigInt, Dict String BigInt )
countWeavingsMemo lengths state memo =
    if List.all ((==) 0) state.remaining then
        ( BI.one, memo )

    else
        let
            key =
                weaveKey state
        in
        case Dict.get key memo of
            Just value ->
                ( value, memo )

            Nothing ->
                let
                    mCount =
                        List.length lengths

                    scan j acc currentMemo =
                        if j > mCount then
                            ( acc, Dict.insert key acc currentMemo )

                        else if legalWeaveMove lengths state j then
                            let
                                next =
                                    applyWeaveMove lengths state j

                                ( block, nextMemo ) =
                                    countWeavingsMemo lengths next currentMemo
                            in
                            scan (j + 1) (BI.add acc block) nextMemo

                        else
                            scan (j + 1) acc currentMemo
                in
                scan 1 BI.zero memo


countWeavingsForLengths : List Int -> BigInt
countWeavingsForLengths lengths =
    countWeavingsMemo lengths { remaining = lengths, openedUpTo = 0, closedUpTo = 0 } Dict.empty
        |> Tuple.first


unrankWeavingForLengths : List Int -> BigInt -> List Int
unrankWeavingForLengths lengths rank1 =
    let
        totalLength =
            List.sum lengths

        chooseMove state j r memo =
            if j > List.length lengths then
                Debug.todo "Röð mánaðarvefjar fór út fyrir löglegu vefjafjölskylduna."

            else if not (legalWeaveMove lengths state j) then
                chooseMove state (j + 1) r memo

            else
                let
                    next =
                        applyWeaveMove lengths state j

                    ( block, nextMemo ) =
                        countWeavingsMemo lengths next memo
                in
                if BI.compareBig r block == GT then
                    chooseMove state (j + 1) (BI.sub r block) nextMemo

                else
                    ( j, r, nextMemo )

        loop state position r memo out =
            if position >= totalLength then
                out

            else
                let
                    ( chosen, nextRank, nextMemo ) =
                        chooseMove state 1 r memo

                    nextState =
                        applyWeaveMove lengths state chosen
                in
                loop nextState (position + 1) nextRank nextMemo (out ++ [ chosen ])
    in
    loop { remaining = lengths, openedUpTo = 0, closedUpTo = 0 } 0 rank1 Dict.empty []


initialGateState : GateState
initialGateState =
    { gates = Dict.singleton (gateKey BI.zero) foundationDay
    , minKnown = BI.zero
    , maxKnown = BI.zero
    }


gateKey : BigInt -> String
gateKey index =
    BI.toString index


gateAt : GateState -> BigInt -> BigInt
gateAt state index =
    Dict.get (gateKey index) state.gates
        |> expectMaybe "Hliðavísitala var ekki mynduð áður en hún var lesin."


positiveGateGap : BigInt -> BigInt
positiveGateGap n =
    let
        target =
            BI.add foundationDay n

        result =
            sauce foundationDay target

        stream =
            askBowl result 1 1

        chosen =
            chooseRank stream (BI.fromInt 922)
    in
    BI.add (BI.fromInt 41) chosen


negativeGateGap : BigInt -> BigInt
negativeGateGap n =
    let
        target =
            BI.sub foundationDay n

        result =
            sauce foundationDay target

        stream =
            askBowl result 1 1

        chosen =
            chooseRank stream (BI.fromInt 922)
    in
    BI.add (BI.fromInt 41) chosen


ensureGateIndex : BigInt -> GateState -> ( BigInt, GateState )
ensureGateIndex wanted state =
    if BI.compareBig wanted state.maxKnown == GT then
        let
            nextIndex =
                BI.add state.maxKnown BI.one

            nextDay =
                BI.add (gateAt state state.maxKnown) (positiveGateGap nextIndex)

            nextState =
                { state
                    | gates = Dict.insert (gateKey nextIndex) nextDay state.gates
                    , maxKnown = nextIndex
                }
        in
        ensureGateIndex wanted nextState

    else if BI.compareBig wanted state.minKnown == LT then
        let
            nextIndex =
                BI.sub state.minKnown BI.one

            magnitude =
                BI.absBig nextIndex

            nextDay =
                BI.sub (gateAt state state.minKnown) (negativeGateGap magnitude)

            nextState =
                { state
                    | gates = Dict.insert (gateKey nextIndex) nextDay state.gates
                    , minKnown = nextIndex
                }
        in
        ensureGateIndex wanted nextState

    else
        ( gateAt state wanted, state )


ensureGatesCover : BigInt -> BigInt -> GateState -> GateState
ensureGatesCover lowDay highDay state =
    if BI.compareBig (gateAt state state.minKnown) lowDay == GT then
        ensureGateIndex (BI.sub state.minKnown BI.one) state
            |> Tuple.second
            |> ensureGatesCover lowDay highDay

    else if BI.compareBig (gateAt state state.maxKnown) highDay == LT then
        ensureGateIndex (BI.add state.maxKnown BI.one) state
            |> Tuple.second
            |> ensureGatesCover lowDay highDay

    else
        state


binaryGateAtOrBefore : BigInt -> GateState -> BigInt -> BigInt -> BigInt
binaryGateAtOrBefore day state lo hi =
    if BI.compareBig lo hi /= LT then
        lo

    else
        let
            width =
                BI.add (BI.sub hi lo) BI.one

            half =
                BI.floorDivPositive width (BI.fromInt 2)

            mid =
                BI.add lo half
        in
        if BI.compareBig (gateAt state mid) day /= GT then
            binaryGateAtOrBefore day state mid hi

        else
            binaryGateAtOrBefore day state lo (BI.sub mid BI.one)


gateIndexAtOrBefore : BigInt -> GateState -> ( BigInt, GateState )
gateIndexAtOrBefore day state =
    let
        covered =
            ensureGatesCover day day state
    in
    ( binaryGateAtOrBefore day covered covered.minKnown covered.maxKnown, covered )


exactGateIndex : BigInt -> GateState -> ( Maybe BigInt, GateState )
exactGateIndex day state =
    let
        ( index, covered ) =
            gateIndexAtOrBefore day state
    in
    if BI.equal (gateAt covered index) day then
        ( Just index, covered )

    else
        ( Nothing, covered )


yearLength : GateState -> BigInt -> BigInt -> BigInt
yearLength state openIndex closeIndex =
    BI.sub (gateAt state closeIndex) (gateAt state openIndex)


localGateGapCount : BigInt -> BigInt -> Int
localGateGapCount openIndex closeIndex =
    BI.sub closeIndex openIndex
        |> BI.toIntMaybe
        |> expectMaybe "Staðbundinn fjöldi hliðabila komst ekki í Elm Int."


validYearPair : GateState -> BigInt -> BigInt -> Bool
validYearPair state openIndex closeIndex =
    let
        lengthDays =
            yearLength state openIndex closeIndex
    in
    BI.compareBig (BI.sub closeIndex openIndex) (BI.fromInt 6) /= LT
        && BI.compareBig lengthDays (BI.fromInt yearMinDays) /= LT
        && BI.compareBig lengthDays (BI.fromInt yearMaxDays) /= GT


compareYearPair : GateState -> ( BigInt, BigInt ) -> ( BigInt, BigInt ) -> Order
compareYearPair state ( i1, j1 ) ( i2, j2 ) =
    case BI.compareBig (yearLength state i1 j1) (yearLength state i2 j2) of
        EQ ->
            BI.compareBig (gateAt state i1) (gateAt state i2)

        other ->
            other


makeYear : BigInt -> GateState -> BigInt -> BigInt -> Year
makeYear number state openIndex closeIndex =
    { number = number
    , openGateIndex = openIndex
    , closeGateIndex = closeIndex
    , openGateDay = gateAt state openIndex
    , closeGateDay = gateAt state closeIndex
    }


rankToInt : BigInt -> Int
rankToInt rank =
    BI.toIntMaybe rank
        |> expectMaybe "Staðbundin valröð komst ekki í Elm Int."


bigRangeInclusive : BigInt -> BigInt -> List BigInt
bigRangeInclusive first last =
    let
        loop current reversed =
            if BI.compareBig current last == GT then
                List.reverse reversed

            else
                loop (BI.add current BI.one) (current :: reversed)
    in
    loop first []


year5000 : BigInt -> GateState -> ( Year, GateState )
year5000 calculationDay state =
    let
        lowDay =
            BI.sub calculationDay (BI.fromInt yearMaxDays)

        highDay =
            BI.add calculationDay (BI.fromInt yearMaxDays)

        covered0 =
            ensureGatesCover lowDay highDay state

        ( lowIndex, covered1 ) =
            gateIndexAtOrBefore lowDay covered0

        ( highIndex, covered ) =
            gateIndexAtOrBefore highDay covered1

        indices =
            bigRangeInclusive lowIndex highIndex

        candidates =
            indices
                |> List.concatMap
                    (\i ->
                        indices
                            |> List.filter
                                (\j ->
                                    BI.compareBig j i == GT
                                        && validYearPair covered i j
                                        && BI.compareBig (gateAt covered i) calculationDay == LT
                                        && BI.compareBig calculationDay (gateAt covered j) /= GT
                                )
                            |> List.map (\j -> ( i, j ))
                    )
                |> List.sortWith (compareYearPair covered)

        result =
            sauce calculationDay calculationDay

        stream =
            askBowl result 1 10

        rank =
            chooseRank stream (BI.fromInt (List.length candidates)) |> rankToInt

        chosen =
            List.drop (rank - 1) candidates
                |> List.head
                |> expectMaybe "Ár 5000 hafði engan gildan frambjóðanda."
    in
    ( makeYear (BI.fromInt 5000) covered (Tuple.first chosen) (Tuple.second chosen), covered )


nextYear : BigInt -> Year -> GateState -> ( Year, GateState )
nextYear calculationDay knownYear state =
    let
        openIndex =
            knownYear.closeGateIndex

        openDay =
            gateAt state openIndex

        covered =
            ensureGatesCover openDay (BI.add openDay (BI.fromInt yearMaxDays)) state

        scan index out =
            if BI.compareBig index covered.maxKnown == GT then
                out

            else
                let
                    lengthDays =
                        yearLength covered openIndex index
                in
                if BI.compareBig lengthDays (BI.fromInt yearMaxDays) == GT then
                    out

                else if validYearPair covered openIndex index then
                    scan (BI.add index BI.one) (out ++ [ index ])

                else
                    scan (BI.add index BI.one) out

        candidates =
            scan (BI.add openIndex BI.one) []
                |> List.sortWith
                    (\a b -> BI.compareBig (yearLength covered openIndex a) (yearLength covered openIndex b))

        result =
            sauce calculationDay openDay

        stream =
            askBowl result 1 11

        rank =
            chooseRank stream (BI.fromInt (List.length candidates)) |> rankToInt

        closeIndex =
            List.drop (rank - 1) candidates
                |> List.head
                |> expectMaybe "Næsta ár hafði engan gildan lokahliðsframbjóðanda."
    in
    ( makeYear (BI.add knownYear.number BI.one) covered openIndex closeIndex, covered )


previousYear : BigInt -> Year -> GateState -> ( Year, GateState )
previousYear calculationDay knownYear state =
    let
        closeIndex =
            knownYear.openGateIndex

        closeDay =
            gateAt state closeIndex

        covered =
            ensureGatesCover (BI.sub closeDay (BI.fromInt yearMaxDays)) closeDay state

        scan index out =
            if BI.compareBig index covered.minKnown == LT then
                out

            else
                let
                    lengthDays =
                        yearLength covered index closeIndex
                in
                if BI.compareBig lengthDays (BI.fromInt yearMaxDays) == GT then
                    out

                else if validYearPair covered index closeIndex then
                    scan (BI.sub index BI.one) (out ++ [ index ])

                else
                    scan (BI.sub index BI.one) out

        candidates =
            scan (BI.sub closeIndex BI.one) []
                |> List.sortWith
                    (\a b -> BI.compareBig (yearLength covered a closeIndex) (yearLength covered b closeIndex))

        result =
            sauce calculationDay closeDay

        stream =
            askBowl result 1 12

        rank =
            chooseRank stream (BI.fromInt (List.length candidates)) |> rankToInt

        openIndex =
            List.drop (rank - 1) candidates
                |> List.head
                |> expectMaybe "Fyrra ár hafði engan gildan opnunarhliðsframbjóðanda."
    in
    ( makeYear (BI.sub knownYear.number BI.one) covered openIndex closeIndex, covered )


findTargetYear : BigInt -> BigInt -> GateState -> ( Year, GateState )
findTargetYear calculationDay targetDay state =
    let
        ( anchor, anchorState ) =
            year5000 calculationDay state

        forward year currentState =
            if BI.compareBig targetDay year.closeGateDay == GT then
                let
                    ( next, nextState ) =
                        nextYear calculationDay year currentState
                in
                forward next nextState

            else
                ( year, currentState )

        backward year currentState =
            if BI.compareBig targetDay year.openGateDay /= GT then
                let
                    ( previous, previousState ) =
                        previousYear calculationDay year currentState
                in
                backward previous previousState

            else
                ( year, currentState )

        ( forwardYear, forwardState ) =
            forward anchor anchorState
    in
    backward forwardYear forwardState


cutletMemoKey : Int -> Int -> Int -> Bool -> String
cutletMemoKey rem slots cumulative hit =
    String.fromInt rem
        ++ ":"
        ++ String.fromInt slots
        ++ ":"
        ++ String.fromInt cumulative
        ++ ":"
        ++ (if hit then "1" else "0")


countCutletPartitionsMemo : Int -> Int -> Maybe Int -> Int -> Bool -> Dict String BigInt -> ( BigInt, Dict String BigInt )
countCutletPartitionsMemo rem slots required cumulative hit memo =
    if slots == 0 then
        if rem /= 0 then
            ( BI.zero, memo )

        else
            case required of
                Nothing ->
                    ( BI.one, memo )

                Just _ ->
                    ( if hit then BI.one else BI.zero, memo )

    else if rem < slots then
        ( BI.zero, memo )

    else
        let
            key =
                cutletMemoKey rem slots cumulative hit
        in
        case Dict.get key memo of
            Just value ->
                ( value, memo )

            Nothing ->
                let
                    maxX =
                        rem - (slots - 1)

                    scan x acc currentMemo =
                        if x > maxX then
                            ( acc, Dict.insert key acc currentMemo )

                        else
                            let
                                nextCumulative =
                                    cumulative + x

                                decision =
                                    case required of
                                        Nothing ->
                                            Just hit

                                        Just boundary ->
                                            if hit then
                                                Just True

                                            else if nextCumulative == boundary then
                                                Just True

                                            else if nextCumulative > boundary then
                                                Nothing

                                            else
                                                Just False
                            in
                            case decision of
                                Nothing ->
                                    scan (x + 1) acc currentMemo

                                Just nextHit ->
                                    let
                                        ( block, nextMemo ) =
                                            countCutletPartitionsMemo (rem - x) (slots - 1) required nextCumulative nextHit currentMemo
                                    in
                                    scan (x + 1) (BI.add acc block) nextMemo
                in
                scan 1 BI.zero memo


countCutletPartitionsForTest : Int -> Int -> Maybe Int -> BigInt
countCutletPartitionsForTest total slots required =
    countCutletPartitionsMemo total slots required 0 False Dict.empty
        |> Tuple.first


unrankCutletPartition : Int -> Int -> Maybe Int -> BigInt -> List Int
unrankCutletPartition total slots required rank1 =
    let
        chooseX x rem slotsLeft cumulative hit r memo =
            let
                maxX =
                    rem - (slotsLeft - 1)
            in
            if x > maxX then
                Debug.todo "Röð kótilettuskiptingar fór út fyrir löglegu fjölskylduna."

            else
                let
                    nextCumulative =
                        cumulative + x

                    decision =
                        case required of
                            Nothing ->
                                Just hit

                            Just boundary ->
                                if hit then
                                    Just True

                                else if nextCumulative == boundary then
                                    Just True

                                else if nextCumulative > boundary then
                                    Nothing

                                else
                                    Just False
                in
                case decision of
                    Nothing ->
                        chooseX (x + 1) rem slotsLeft cumulative hit r memo

                    Just nextHit ->
                        let
                            ( block, nextMemo ) =
                                countCutletPartitionsMemo (rem - x) (slotsLeft - 1) required nextCumulative nextHit memo
                        in
                        if BI.compareBig r block == GT then
                            chooseX (x + 1) rem slotsLeft cumulative hit (BI.sub r block) nextMemo

                        else
                            { chosen = x
                            , cumulative = nextCumulative
                            , hit = nextHit
                            , rank = r
                            , memo = nextMemo
                            }

        loop position rem cumulative hit r memo out =
            if position > slots then
                out

            else
                let
                    slotsLeft =
                        slots - position + 1

                    choice =
                        chooseX 1 rem slotsLeft cumulative hit r memo
                in
                loop
                    (position + 1)
                    (rem - choice.chosen)
                    choice.cumulative
                    choice.hit
                    choice.rank
                    choice.memo
                    (out ++ [ choice.chosen ])
    in
    loop 1 total 0 False rank1 Dict.empty []


chooseCutletCount : SauceResult -> Year -> Int
chooseCutletCount structureSauce year =
    let
        gaps =
            localGateGapCount year.openGateIndex year.closeGateIndex

        candidates =
            List.range 6 17 |> List.filter (\k -> k <= gaps)

        stream =
            askBowl structureSauce 2 20

        rank =
            chooseRank stream (BI.fromInt (List.length candidates)) |> rankToInt
    in
    List.drop (rank - 1) candidates
        |> List.head
        |> expectMaybe "Kótilettufjöldi hafði engan gildan frambjóðanda."


chooseCutletPartition : BigInt -> SauceResult -> Year -> GateState -> Int -> ( List Int, GateState )
chooseCutletPartition calculationDay structureSauce year state cutletCount =
    let
        gaps =
            localGateGapCount year.openGateIndex year.closeGateIndex

        ( exact, covered ) =
            exactGateIndex calculationDay state

        required =
            case exact of
                Just gateIndex ->
                    if BI.compareBig gateIndex year.openGateIndex == GT
                        && BI.compareBig gateIndex year.closeGateIndex == LT
                    then
                        Just
                            (BI.sub gateIndex year.openGateIndex
                                |> BI.toIntMaybe
                                |> expectMaybe "Innra hliðabil komst ekki í Elm Int."
                            )

                    else
                        Nothing

                Nothing ->
                    Nothing

        ( count, _ ) =
            countCutletPartitionsMemo gaps cutletCount required 0 False Dict.empty

        stream =
            askBowl structureSauce 2 21

        rank =
            chooseRank stream count
    in
    ( unrankCutletPartition gaps cutletCount required rank, covered )


chooseCutletNames : SauceResult -> Int -> List Int
chooseCutletNames structureSauce cutletCount =
    let
        n =
            fallingFactorial 17 cutletCount

        stream =
            askBowl structureSauce 5 22

        rank =
            chooseRank stream n
    in
    unrankDistinctIndices 17 cutletCount rank


materializeCutlets : Year -> GateState -> List Int -> List Int -> List Cutlet
materializeCutlets year state partition names =
    let
        loop cursor parts remainingNames out =
            case ( parts, remainingNames ) of
                ( gapCount :: moreParts, canonicalIndex :: moreNames ) ->
                    let
                        closeIndex =
                            BI.add cursor (BI.fromInt gapCount)

                        cutlet =
                            { canonicalIndex = canonicalIndex
                            , firstDay = BI.add (gateAt state cursor) BI.one
                            , lastDay = gateAt state closeIndex
                            }
                    in
                    loop closeIndex moreParts moreNames (out ++ [ cutlet ])

                _ ->
                    out
    in
    loop year.openGateIndex partition names []


ceilDivInt : Int -> Int -> Int
ceilDivInt a b =
    (a + b - 1) // b


chooseMonthCount : SauceResult -> Year -> Int
chooseMonthCount structureSauce year =
    let
        lengthDays =
            BI.sub year.closeGateDay year.openGateDay
                |> BI.toIntMaybe
                |> expectMaybe "Árslengd komst ekki í Elm Int þrátt fyrir 5778 daga hámark."

        low =
            ceilDivInt lengthDays 123

        high =
            Basics.min 47 (lengthDays // 4)

        stream =
            askBowl structureSauce 3 30

        rank =
            chooseRank stream (BI.fromInt (high - low + 1)) |> rankToInt
    in
    low + rank - 1


chooseMonthLengths : SauceResult -> Year -> Int -> List Int
chooseMonthLengths structureSauce year monthCount =
    let
        lengthDays =
            BI.sub year.closeGateDay year.openGateDay
                |> BI.toIntMaybe
                |> expectMaybe "Árslengd komst ekki í Elm Int þrátt fyrir 5778 daga hámark."

        count =
            countBoundedCompositions lengthDays monthCount 4 123

        stream =
            askBowl structureSauce 3 31

        rank =
            chooseRank stream count
    in
    unrankBoundedComposition lengthDays monthCount 4 123 rank


chooseMonthWeaving : SauceResult -> List Int -> List Int
chooseMonthWeaving structureSauce monthLengths =
    let
        count =
            countWeavingsForLengths monthLengths

        stream =
            askBowl structureSauce 4 32

        rank =
            chooseRank stream count
    in
    unrankWeavingForLengths monthLengths rank


chooseMonthNames : SauceResult -> Int -> List Int
chooseMonthNames structureSauce monthCount =
    let
        count =
            fallingFactorial 47 monthCount

        stream =
            askBowl structureSauce 5 33

        rank =
            chooseRank stream count
    in
    unrankDistinctIndices 47 monthCount rank


buildYearStructure : BigInt -> Year -> GateState -> ( YearStructure, GateState )
buildYearStructure calculationDay year state =
    let
        firstDay =
            BI.add year.openGateDay BI.one

        structureSauce =
            sauce calculationDay firstDay

        cutletCount =
            chooseCutletCount structureSauce year

        ( partition, covered ) =
            chooseCutletPartition calculationDay structureSauce year state cutletCount

        cutletNames =
            chooseCutletNames structureSauce cutletCount

        cutlets =
            materializeCutlets year covered partition cutletNames

        monthCount =
            chooseMonthCount structureSauce year

        monthLengths =
            chooseMonthLengths structureSauce year monthCount

        weaving =
            chooseMonthWeaving structureSauce monthLengths

        monthNames =
            chooseMonthNames structureSauce monthCount
    in
    ( { cutlets = cutlets
      , monthWeaving = weaving
      , monthCanonicalIndices = monthNames
      }
    , covered
    )


findCutlet : BigInt -> List Cutlet -> Cutlet
findCutlet targetDay cutlets =
    cutlets
        |> List.filter
            (\cutlet ->
                BI.compareBig cutlet.firstDay targetDay /= GT
                    && BI.compareBig targetDay cutlet.lastDay /= GT
            )
        |> List.head
        |> expectMaybe "Markdagurinn fannst ekki í neinni kótilettu."


countOccurrencesThrough : Int -> Int -> List Int -> Int
countOccurrencesThrough wanted lastOneBased weaving =
    weaving
        |> List.take lastOneBased
        |> List.filter ((==) wanted)
        |> List.length


calendarDateCanonical : BigInt -> BigInt -> CanonicalCalendarDate
calendarDateCanonical calculationDay targetDay =
    let
        ( year, gateState ) =
            findTargetYear calculationDay targetDay initialGateState

        ( structure, _ ) =
            buildYearStructure calculationDay year gateState

        cutlet =
            findCutlet targetDay structure.cutlets

        dayInCutlet =
            BI.add (BI.sub targetDay cutlet.firstDay) BI.one

        offset =
            BI.sub targetDay (BI.add year.openGateDay BI.one)
                |> BI.toIntMaybe
                |> expectMaybe "Dagshliðrun innan árs komst ekki í Elm Int."

        monthId =
            listAt structure.monthWeaving (offset + 1)

        monthCanonicalIndex =
            listAt structure.monthCanonicalIndices monthId

        dayInMonth =
            countOccurrencesThrough monthId (offset + 1) structure.monthWeaving
    in
    { yearNumber = year.number
    , cutletCanonicalIndex = cutlet.canonicalIndex
    , dayInCutlet = dayInCutlet
    , monthCanonicalIndex = monthCanonicalIndex
    , dayInMonth = dayInMonth
    }


calendarDate : BigInt -> BigInt -> CalendarDate
calendarDate calculationDay targetDay =
    let
        canonical =
            calendarDateCanonical calculationDay targetDay
    in
    { yearNumber = canonical.yearNumber
    , cutletName =
        Catalog.cutletName canonical.cutletCanonicalIndex
            |> expectMaybe "Kótilettuvísitala vantar í frysta íslenska katalóginn."
    , dayInCutlet = canonical.dayInCutlet
    , monthName =
        Catalog.monthName canonical.monthCanonicalIndex
            |> expectMaybe "Mánaðarvísitala vantar í frysta íslenska katalóginn."
    , dayInMonth = canonical.dayInMonth
    }
