module Pastafari.ExactInt exposing
    ( BigInt
    , absBig
    , add
    , compareBig
    , equal
    , floorDivPositive
    , fromInt
    , isNegative
    , isZero
    , mul
    , mulSmall
    , negate
    , one
    , powSmall
    , regularMod
    , square
    , sub
    , toIntMaybe
    , toString
    , zero
    )


base : Int
base =
    10000


type Sign
    = Negative
    | ZeroSign
    | Positive


type BigInt
    = BigInt Sign (List Int)


zero : BigInt
zero =
    BigInt ZeroSign []


one : BigInt
one =
    fromInt 1


isZero : BigInt -> Bool
isZero value =
    case value of
        BigInt ZeroSign _ ->
            True

        _ ->
            False


isNegative : BigInt -> Bool
isNegative value =
    case value of
        BigInt Negative _ ->
            True

        _ ->
            False


fromInt : Int -> BigInt
fromInt n =
    if n == 0 then
        zero

    else if n < 0 then
        normalize Negative (digitsFromPositive (Basics.abs n))

    else
        normalize Positive (digitsFromPositive n)


digitsFromPositive : Int -> List Int
digitsFromPositive n =
    if n == 0 then
        []

    else
        modBy base n :: digitsFromPositive (n // base)


normalize : Sign -> List Int -> BigInt
normalize sign digits =
    let
        cleaned =
            trimHighZeros digits
    in
    if List.isEmpty cleaned then
        zero

    else
        BigInt sign cleaned


trimHighZeros : List Int -> List Int
trimHighZeros digits =
    digits
        |> List.reverse
        |> dropLeadingZeros
        |> List.reverse


dropLeadingZeros : List Int -> List Int
dropLeadingZeros digits =
    case digits of
        [] ->
            []

        0 :: rest ->
            dropLeadingZeros rest

        _ ->
            digits


absBig : BigInt -> BigInt
absBig value =
    case value of
        BigInt ZeroSign _ ->
            zero

        BigInt _ digits ->
            BigInt Positive digits


negate : BigInt -> BigInt
negate value =
    case value of
        BigInt Negative digits ->
            BigInt Positive digits

        BigInt Positive digits ->
            BigInt Negative digits

        BigInt ZeroSign _ ->
            zero


compareBig : BigInt -> BigInt -> Order
compareBig a b =
    case ( a, b ) of
        ( BigInt Negative ad, BigInt Negative bd ) ->
            reverseOrder (compareAbsDigits ad bd)

        ( BigInt Negative _, _ ) ->
            LT

        ( _, BigInt Negative _ ) ->
            GT

        ( BigInt ZeroSign _, BigInt ZeroSign _ ) ->
            EQ

        ( BigInt ZeroSign _, BigInt Positive _ ) ->
            LT

        ( BigInt Positive _, BigInt ZeroSign _ ) ->
            GT

        ( BigInt Positive ad, BigInt Positive bd ) ->
            compareAbsDigits ad bd


reverseOrder : Order -> Order
reverseOrder order =
    case order of
        LT ->
            GT

        EQ ->
            EQ

        GT ->
            LT


equal : BigInt -> BigInt -> Bool
equal a b =
    compareBig a b == EQ


compareAbsDigits : List Int -> List Int -> Order
compareAbsDigits a b =
    let
        la =
            List.length a

        lb =
            List.length b
    in
    if la < lb then
        LT

    else if la > lb then
        GT

    else
        compareMostSignificant (List.reverse a) (List.reverse b)


compareMostSignificant : List Int -> List Int -> Order
compareMostSignificant a b =
    case ( a, b ) of
        ( [], [] ) ->
            EQ

        ( x :: xs, y :: ys ) ->
            if x < y then
                LT

            else if x > y then
                GT

            else
                compareMostSignificant xs ys

        ( [], _ ) ->
            LT

        ( _, [] ) ->
            GT


add : BigInt -> BigInt -> BigInt
add a b =
    case ( a, b ) of
        ( BigInt ZeroSign _, _ ) ->
            b

        ( _, BigInt ZeroSign _ ) ->
            a

        ( BigInt Positive ad, BigInt Positive bd ) ->
            normalize Positive (addAbsDigits ad bd 0)

        ( BigInt Negative ad, BigInt Negative bd ) ->
            normalize Negative (addAbsDigits ad bd 0)

        ( BigInt Positive ad, BigInt Negative bd ) ->
            subtractSigns Positive Negative ad bd

        ( BigInt Negative ad, BigInt Positive bd ) ->
            subtractSigns Negative Positive ad bd


subtractSigns : Sign -> Sign -> List Int -> List Int -> BigInt
subtractSigns signA signB ad bd =
    case compareAbsDigits ad bd of
        EQ ->
            zero

        GT ->
            normalize signA (subAbsDigits ad bd 0)

        LT ->
            normalize signB (subAbsDigits bd ad 0)


addAbsDigits : List Int -> List Int -> Int -> List Int
addAbsDigits a b carry =
    case ( a, b ) of
        ( [], [] ) ->
            if carry == 0 then
                []

            else
                [ carry ]

        ( x :: xs, [] ) ->
            let
                total =
                    x + carry
            in
            modBy base total :: addAbsDigits xs [] (total // base)

        ( [], y :: ys ) ->
            let
                total =
                    y + carry
            in
            modBy base total :: addAbsDigits [] ys (total // base)

        ( x :: xs, y :: ys ) ->
            let
                total =
                    x + y + carry
            in
            modBy base total :: addAbsDigits xs ys (total // base)


subAbsDigits : List Int -> List Int -> Int -> List Int
subAbsDigits a b borrow =
    case ( a, b ) of
        ( [], [] ) ->
            []

        ( x :: xs, [] ) ->
            let
                raw =
                    x - borrow

                digit =
                    if raw < 0 then
                        raw + base

                    else
                        raw

                nextBorrow =
                    if raw < 0 then
                        1

                    else
                        0
            in
            digit :: subAbsDigits xs [] nextBorrow

        ( x :: xs, y :: ys ) ->
            let
                raw =
                    x - y - borrow

                digit =
                    if raw < 0 then
                        raw + base

                    else
                        raw

                nextBorrow =
                    if raw < 0 then
                        1

                    else
                        0
            in
            digit :: subAbsDigits xs ys nextBorrow

        ( [], _ ) ->
            []


sub : BigInt -> BigInt -> BigInt
sub a b =
    add a (negate b)


mul : BigInt -> BigInt -> BigInt
mul a b =
    case ( a, b ) of
        ( BigInt ZeroSign _, _ ) ->
            zero

        ( _, BigInt ZeroSign _ ) ->
            zero

        ( BigInt signA ad, BigInt signB bd ) ->
            let
                sign =
                    if signA == signB then
                        Positive

                    else
                        Negative
            in
            normalize sign (mulAbsDigits ad bd)


mulAbsDigits : List Int -> List Int -> List Int
mulAbsDigits a b =
    b
        |> List.indexedMap
            (\index digit ->
                List.repeat index 0 ++ mulAbsByInt a digit 0
            )
        |> List.foldl (\part acc -> addAbsDigits acc part 0) []
        |> trimHighZeros


mulAbsByInt : List Int -> Int -> Int -> List Int
mulAbsByInt digits factor carry =
    case digits of
        [] ->
            carryDigits carry

        x :: xs ->
            let
                total =
                    x * factor + carry
            in
            modBy base total :: mulAbsByInt xs factor (total // base)


carryDigits : Int -> List Int
carryDigits carry =
    if carry == 0 then
        []

    else
        modBy base carry :: carryDigits (carry // base)


mulSmall : BigInt -> Int -> BigInt
mulSmall value factor =
    if factor == 0 || isZero value then
        zero

    else if factor < 0 then
        negate (mulSmall value (Basics.abs factor))

    else
        case value of
            BigInt sign digits ->
                normalize sign (mulAbsByInt digits factor 0)


square : BigInt -> BigInt
square value =
    mul value value


powSmall : Int -> Int -> BigInt
powSmall factor exponent =
    powLoop (fromInt factor) exponent one


powLoop : BigInt -> Int -> BigInt -> BigInt
powLoop factor exponent acc =
    if exponent <= 0 then
        acc

    else
        powLoop factor (exponent - 1) (mul acc factor)


floorDivPositive : BigInt -> BigInt -> BigInt
floorDivPositive numerator denominator =
    if isZero denominator || isNegative denominator then
        zero

    else
        let
            ( qAbs, rAbs ) =
                divModAbs (absDigits numerator) (absDigits denominator)

            qPositive =
                normalize Positive qAbs
        in
        if isNegative numerator then
            if List.isEmpty rAbs then
                negate qPositive

            else
                negate (add qPositive one)

        else
            qPositive


regularMod : BigInt -> BigInt -> BigInt
regularMod numerator denominator =
    if isZero denominator || isNegative denominator then
        zero

    else
        let
            ( _, rAbs ) =
                divModAbs (absDigits numerator) (absDigits denominator)

            r =
                normalize Positive rAbs
        in
        if isNegative numerator && not (isZero r) then
            sub denominator r

        else
            r


absDigits : BigInt -> List Int
absDigits value =
    case value of
        BigInt _ digits ->
            digits


divModAbs : List Int -> List Int -> ( List Int, List Int )
divModAbs numerator denominator =
    if List.isEmpty denominator then
        ( [], [] )

    else if compareAbsDigits numerator denominator == LT then
        ( [], numerator )

    else
        let
            step digit ( quotientBigEndian, remainder ) =
                let
                    shifted =
                        addAbsDigits (mulAbsByInt remainder base 0) [ digit ] 0

                    qDigit =
                        findQuotientDigit denominator shifted 0 (base - 1)

                    product =
                        mulAbsByInt denominator qDigit 0

                    nextRemainder =
                        trimHighZeros (subAbsDigits shifted product 0)
                in
                ( quotientBigEndian ++ [ qDigit ], nextRemainder )

            ( qBigEndian, r ) =
                List.foldl step ( [], [] ) (List.reverse numerator)
        in
        ( trimHighZeros (List.reverse qBigEndian), trimHighZeros r )


findQuotientDigit : List Int -> List Int -> Int -> Int -> Int
findQuotientDigit denominator remainder low high =
    if low > high then
        high

    else
        let
            mid =
                low + ((high - low) // 2)

            product =
                mulAbsByInt denominator mid 0
        in
        case compareAbsDigits product remainder of
            GT ->
                findQuotientDigit denominator remainder low (mid - 1)

            _ ->
                findQuotientDigit denominator remainder (mid + 1) high


toIntMaybe : BigInt -> Maybe Int
toIntMaybe value =
    case value of
        BigInt ZeroSign _ ->
            Just 0

        BigInt sign digits ->
            let
                build ds acc =
                    case ds of
                        [] ->
                            Just acc

                        x :: xs ->
                            if acc > 214747 then
                                Nothing

                            else
                                build xs (acc * base + x)
            in
            case build (List.reverse digits) 0 of
                Nothing ->
                    Nothing

                Just n ->
                    if sign == Negative then
                        Just -n

                    else
                        Just n


toString : BigInt -> String
toString value =
    case value of
        BigInt ZeroSign _ ->
            "0"

        BigInt sign digits ->
            let
                chunks =
                    List.reverse digits

                body =
                    case chunks of
                        [] ->
                            "0"

                        first :: rest ->
                            String.fromInt first ++ String.concat (List.map pad4 rest)

                prefix =
                    if sign == Negative then
                        "-"

                    else
                        ""
            in
            prefix ++ body


pad4 : Int -> String
pad4 n =
    let
        s =
            String.fromInt n

        missing =
            4 - String.length s
    in
    String.repeat missing "0" ++ s
