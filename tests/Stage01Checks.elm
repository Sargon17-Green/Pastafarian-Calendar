module Stage01Checks exposing (allPassed, summary)

import Array
import BootstrapFixtures as Fixtures
import Dict
import Pastafari.ExactInt as BI
import Pastafari.MonsterBase as MonsterBase
import Pastafari.SourceLanguageCatalog as Catalog
import Pastafari.Spaghetti as Spaghetti
import NormativeOracle as Oracle
import Set



type alias Check =
    { name : String
    , passed : Bool
    , expected : String
    , actual : String
    }


check : String -> Bool -> String -> String -> Check
check name passed expected actual =
    { name = name
    , passed = passed
    , expected = expected
    , actual = actual
    }


bigCheck : String -> BI.BigInt -> BI.BigInt -> Check
bigCheck name expected actual =
    check name (BI.equal expected actual) (BI.toString expected) (BI.toString actual)


listIntString : List Int -> String
listIntString values =
    "[" ++ String.join "," (List.map String.fromInt values) ++ "]"


listCheck : String -> List Int -> List Int -> Check
listCheck name expected actual =
    check name (expected == actual) (listIntString expected) (listIntString actual)


indicesExactly : Int -> List Catalog.CatalogEntry -> Bool
indicesExactly count entries =
    let
        indices =
            List.map .canonicalIndex entries
    in
    List.length entries == count
        && List.sort indices == List.range 1 count
        && List.all (\entry -> not (String.isEmpty entry.text)) entries


allUniqueStrings : List String -> Bool
allUniqueStrings values =
    Set.size (Set.fromList values) == List.length values


sameSauce : Oracle.SauceResult -> Oracle.SauceResult -> Bool
sameSauce left right =
    List.map BI.toString (Array.toList left.bowls)
        == List.map BI.toString (Array.toList right.bowls)
        && left.orderAtDrop46
        == right.orderAtDrop46




sameContext : MonsterBase.BaseContext -> MonsterBase.BaseContext -> Bool
sameContext left right =
    BI.equal left.calculationDay right.calculationDay
        && BI.equal left.targetDay right.targetDay
        && left.phase == right.phase
        && left.status == right.status
        && left.branchTrace == right.branchTrace
        && Dict.toList left.metrics == Dict.toList right.metrics
        && left.diagnostics == right.diagnostics


sameContextPair : ( MonsterBase.BaseContext, MonsterBase.BaseContext ) -> ( MonsterBase.BaseContext, MonsterBase.BaseContext ) -> Bool
sameContextPair ( leftA, leftB ) ( rightA, rightB ) =
    sameContext leftA rightA && sameContext leftB rightB


stoneSignature : Oracle.Stone -> List String
stoneSignature stone =
    [ BI.toString stone.wheat
    , BI.toString stone.barley
    , BI.toString stone.salt
    , BI.toString stone.bitter
    , BI.toString stone.red
    ]


divisionIdentity : BI.BigInt -> BI.BigInt -> Bool
divisionIdentity numerator denominator =
    let
        quotient =
            BI.floorDivPositive numerator denominator

        remainder =
            BI.regularMod numerator denominator
    in
    BI.equal numerator (BI.add (BI.mul quotient denominator) remainder)
        && BI.compareBig remainder BI.zero /= LT
        && BI.compareBig remainder denominator == LT


checks : List Check
checks =
    let
        modulus =
            Oracle.m

        foundation =
            Oracle.foundationDay

        countsSame =
            Oracle.workCounts foundation foundation

        countsCross =
            Oracle.workCounts (BI.sub foundation BI.one) (BI.add foundation BI.one)

        weaveCount =
            Oracle.countWeavingsForLengths [ 2, 2 ]

        contextA =
            MonsterBase.newContext (BI.fromInt 1) (BI.fromInt 2)

        contextB =
            MonsterBase.newContext (BI.fromInt 3) (BI.fromInt 4)

        contextAChanged =
            contextA
                |> MonsterBase.dispatch MonsterBase.neutralDispatcher
                |> MonsterBase.recordMetric "bootstrap.eignarhald.a"

        contextBExpected =
            MonsterBase.newContext (BI.fromInt 3) (BI.fromInt 4)

        sequenceAB =
            let
                a =
                    MonsterBase.newContext (BI.fromInt 11) (BI.fromInt 12)
                        |> MonsterBase.recordMetric "bootstrap.röð.a"
                        |> MonsterBase.dispatch MonsterBase.neutralDispatcher

                b =
                    MonsterBase.newContext (BI.fromInt 21) (BI.fromInt 22)
                        |> MonsterBase.recordMetric "bootstrap.röð.b"
                        |> MonsterBase.dispatch MonsterBase.neutralDispatcher
            in
            ( a, b )

        sequenceBA =
            let
                b =
                    MonsterBase.newContext (BI.fromInt 21) (BI.fromInt 22)
                        |> MonsterBase.recordMetric "bootstrap.röð.b"
                        |> MonsterBase.dispatch MonsterBase.neutralDispatcher

                a =
                    MonsterBase.newContext (BI.fromInt 11) (BI.fromInt 12)
                        |> MonsterBase.recordMetric "bootstrap.röð.a"
                        |> MonsterBase.dispatch MonsterBase.neutralDispatcher
            in
            ( a, b )

        spaghettiBootstrap =
            Spaghetti.calendarDateSpaghetti (BI.fromInt 1) (BI.fromInt 2)

        mSquared =
            BI.mul modulus modulus

        negativeSeven =
            BI.fromInt -7

        three =
            BI.fromInt 3

        divisionWitnesses =
            [ ( BI.zero, BI.one )
            , ( BI.one, three )
            , ( BI.fromInt -7, three )
            , ( modulus, BI.fromInt 97 )
            , ( BI.negate mSquared, BI.fromInt 10000 )
            , ( BI.add mSquared (BI.fromInt 12345), modulus )
            ]

        shortRejectStream =
            { first = modulus, directionStep = -1 }

        wideStream =
            { first = BI.one, directionStep = 1 }

        wideN =
            BI.add modulus BI.one

        hugeGateMagnitude =
            BI.powSmall 2 31

        hugePositiveGateGap =
            Oracle.positiveGateGap hugeGateMagnitude

        negativeFirstGateGap =
            Oracle.negativeGateGap BI.one

        stone2 =
            Array.get 1 Oracle.buildStones

        sauceA =
            Oracle.sauce foundation foundation

        sauceB =
            Oracle.sauce foundation (BI.add foundation BI.one)

        sauceAAgain =
            Oracle.sauce foundation foundation

        cutletTexts =
            List.map .text Catalog.cutletEntries

        monthTexts =
            List.map .text Catalog.monthEntries

        sourceIds =
            List.map .sourceId Catalog.cutletEntries ++ List.map .sourceId Catalog.monthEntries

        unicodeSortedCutletIndices =
            Catalog.cutletEntries
                |> List.sortBy .text
                |> List.map .canonicalIndex
    in
    [ check
        "Stóri teljarinn er nákvæmlega 2^127-1"
        (BI.toString modulus == Fixtures.modulusDecimal)
        Fixtures.modulusDecimal
        (BI.toString modulus)
    , bigCheck "Spjaldadagur er 14.777.149 dögum eftir grunndag" (BI.fromInt Fixtures.tabletsFromFoundation) (BI.sub Oracle.tabletsDay foundation)
    , check
        "Hámarkslengd árs er nákvæmlega 5778 dagar"
        (Oracle.yearMaxDays == 5778)
        "5778"
        (String.fromInt Oracle.yearMaxDays)
    , bigCheck "SAVE(1)" BI.one (Oracle.save BI.one)
    , bigCheck "SAVE(M-1)" (BI.sub modulus BI.one) (Oracle.save (BI.sub modulus BI.one))
    , bigCheck "SAVE(M)" modulus (Oracle.save modulus)
    , bigCheck "SAVE(M+1)" BI.one (Oracle.save (BI.add modulus BI.one))
    , bigCheck "SAVE(2M)" modulus (Oracle.save (BI.mulSmall modulus 2))
    , bigCheck "Nákvæm deiling M^2 með M" modulus (BI.floorDivPositive mSquared modulus)
    , bigCheck "Nákvæm leif M^2 með M" BI.zero (BI.regularMod mSquared modulus)
    , bigCheck "Gólfdeiling -7 með 3" (BI.fromInt -3) (BI.floorDivPositive negativeSeven three)
    , bigCheck "Euklíðsk leif -7 með 3" (BI.fromInt 2) (BI.regularMod negativeSeven three)
    , check
        "Gólfdeiling og euklíðsk leif uppfylla n=q*d+r á öllum Bootstrap-vitnum"
        (List.all (\( numerator, denominator ) -> divisionIdentity numerator denominator) divisionWitnesses)
        "n=q*d+r og 0<=r<d fyrir öll vitni"
        "ákveðinn listi jákvæðra og neikvæðra stórra heiltalna"
    , bigCheck "Dagatalning á grunndegi" BI.one (Oracle.dayCount foundation)
    , bigCheck "Dagatalning degi eftir grunn" (BI.fromInt 3) (Oracle.dayCount (BI.add foundation BI.one))
    , bigCheck "Dagatalning degi fyrir grunn" (BI.fromInt 2) (Oracle.dayCount (BI.sub foundation BI.one))
    , bigCheck "Fjarlægð þegar dagarnir eru jafnir" BI.one countsSame.distance
    , bigCheck "Stefna þegar dagarnir eru jafnir" (BI.fromInt 2) countsSame.direction
    , bigCheck "Fjarlægð yfir grunndag" (BI.fromInt 3) countsCross.distance
    , bigCheck "Tenging yfir grunndag" (BI.fromInt 5) countsCross.connection
    , check
        "Steinataflan inniheldur nákvæmlega 46 raðir"
        (Array.length Oracle.buildStones == 46)
        "46"
        (String.fromInt (Array.length Oracle.buildStones))
    , check
        "Önnur steinaröðin kemur öll úr sama gamla ástandi"
        (case stone2 of
            Just stone ->
                stoneSignature stone == Fixtures.secondStoneSignature

            Nothing ->
                False
        )
        ("[" ++ String.join "," Fixtures.secondStoneSignature ++ "]")
        (case stone2 of
            Just stone ->
                "[" ++ String.join "," (stoneSignature stone) ++ "]"

            Nothing ->
                "engin önnur röð"
        )
    , listCheck "Fyrsta sex skála umröðunin" [ 1, 2, 3, 4, 5, 6 ] (Oracle.permutationUnrank1 1 [ 1, 2, 3, 4, 5, 6 ])
    , listCheck "Síðasta sex skála umröðunin" [ 6, 5, 4, 3, 2, 1 ] (Oracle.permutationUnrank1 720 [ 1, 2, 3, 4, 5, 6 ])
    , bigCheck "Fallandi margfeldi 5P3" (BI.fromInt 60) (Oracle.fallingFactorial 5 3)
    , check
        "Fallandi margfeldi 47P47 fer yfir stóra teljarann án styttingar"
        (BI.compareBig (Oracle.fallingFactorial 47 47) modulus == GT)
        "stærra en M"
        (BI.toString (Oracle.fallingFactorial 47 47))
    , listCheck "Fyrsta hlutumröðun 5P3" [ 1, 2, 3 ] (Oracle.unrankDistinctIndices 5 3 BI.one)
    , listCheck "Síðasta hlutumröðun 5P3" [ 5, 4, 3 ] (Oracle.unrankDistinctIndices 5 3 (BI.fromInt 60))
    , bigCheck "Kótilettuskipting með skyldum innri mörkum hefur réttan fjölda" BI.one (Oracle.countCutletPartitionsForTest 4 2 (Just 2))
    , listCheck "Kótilettuskipting með skyldu innra marki" [ 2, 2 ] (Oracle.unrankCutletPartition 4 2 (Just 2) BI.one)
    , bigCheck "Fjöldi takmarkaðra samsetninga" (BI.fromInt 4) (Oracle.countBoundedCompositions 5 2 1 4)
    , listCheck "Þriðja takmarkaða samsetningin" [ 3, 2 ] (Oracle.unrankBoundedComposition 5 2 1 4 (BI.fromInt 3))
    , bigCheck "Fjöldi löglegra vefja fyrir [2,2]" (BI.fromInt 2) weaveCount
    , listCheck "Annar löglegi vefurinn fyrir [2,2]" [ 1, 2, 1, 2 ] (Oracle.unrankWeavingForLengths [ 2, 2 ] (BI.fromInt 2))
    , listCheck "Eini löglegi vefurinn fyrir [1,1]" [ 1, 2 ] (Oracle.unrankWeavingForLengths [ 1, 1 ] BI.one)
    , bigCheck "Svarhringur afturábak vefst frá 1 yfir í M" modulus (Oracle.answerAt { first = BI.one, directionStep = -1 } 1)
    , bigCheck "Stutt val með N=1" BI.one (Oracle.chooseRankShort wideStream BI.one)
    , bigCheck "Stutt val með N=M" modulus (Oracle.chooseRankShort { first = modulus, directionStep = 1 } modulus)
    , bigCheck "Stutt höfnun heldur áfram í sama svarhring" (BI.fromInt 10) (Oracle.chooseRankShort shortRejectStream (BI.fromInt 10))
    , bigCheck "Vítt val með N=M+1 notar samsetta breiða tölu" wideN (Oracle.chooseRankWide wideStream wideN)
    , bigCheck "Valdreifari sendir N=M+1 í víðu leiðina" wideN (Oracle.chooseRank wideStream wideN)
    , check
        "Jákvæð hliðaspurning tekur við vísitölu yfir hefðbundnu Int-sviði án styttingar"
        (BI.compareBig hugePositiveGateGap (BI.fromInt 42) /= LT
            && BI.compareBig hugePositiveGateGap (BI.fromInt 963) /= GT
        )
        "42..963"
        (BI.toString hugePositiveGateGap)
    , check
        "Neikvætt fyrsta hliðabil er innan staðlaðra marka"
        (BI.compareBig negativeFirstGateGap (BI.fromInt 42) /= LT
            && BI.compareBig negativeFirstGateGap (BI.fromInt 963) /= GT
        )
        "42..963"
        (BI.toString negativeFirstGateGap)
    , check
        "Sósan skilar sex skálum og umröðun allra sex skála"
        (Array.length sauceA.bowls == 6 && List.sort sauceA.orderAtDrop46 == List.range 1 6)
        "sex skálar og umröðun 1..6"
        (String.fromInt (Array.length sauceA.bowls) ++ " skálar; röð " ++ listIntString sauceA.orderAtDrop46)
    , check
        "Endurtekin sósa er óháð millikalli og endurnýtingu myndaðra gagna"
        (sameSauce sauceA sauceAAgain && Array.length sauceB.bowls == 6)
        "sama niðurstaða fyrir sama inntak eftir millikall"
        (if sameSauce sauceA sauceAAgain then "sama niðurstaða" else "frávik eftir millikall")
    , check
        "Sautján kótilettunöfn hafa nákvæma canonicalIndex-röð"
        (indicesExactly 17 Catalog.cutletEntries)
        "1..17, hvert gildi einu sinni"
        (String.fromInt (List.length Catalog.cutletEntries) ++ " færslur")
    , check
        "Fjörutíu og sjö mánaðanöfn hafa nákvæma canonicalIndex-röð"
        (indicesExactly 47 Catalog.monthEntries)
        "1..47, hvert gildi einu sinni"
        (String.fromInt (List.length Catalog.monthEntries) ++ " færslur")
    , check
        "Fryst kótilettuskrá hefur nákvæm íslensk heiti"
        (cutletTexts == Fixtures.cutletTexts)
        (String.join " | " Fixtures.cutletTexts)
        (String.join " | " cutletTexts)
    , check
        "Fryst mánaðaskrá hefur nákvæm íslensk heiti"
        (monthTexts == Fixtures.monthTexts)
        (String.join " | " Fixtures.monthTexts)
        (String.join " | " monthTexts)
    , check
        "Vélaauðkenni katalógsins eru ótvíræð"
        (allUniqueStrings sourceIds)
        "öll sourceId einstök"
        (String.fromInt (List.length sourceIds) ++ " auðkenni")
    , check
        "Unicode-röðun íslensku strengjanna er ekki canonicalIndex-röðin"
        (unicodeSortedCutletIndices /= List.range 1 17)
        "mismunandi raðir"
        (listIntString unicodeSortedCutletIndices)
    , check
        "Grunnsamhengi tveggja kallana deilir ekki framkvæmdarslóð"
        (contextA.branchTrace == [ "BOOTSTRAP_ENTRY" ] && contextB.branchTrace == [ "BOOTSTRAP_ENTRY" ])
        "tvær óháðar slóðir"
        "tvær sjálfstæðar færslur"
    , check
        "Breyting á mælingu og stigi í einu samhengi breytir ekki hinu"
        (sameContext contextB contextBExpected
            && BI.equal contextAChanged.calculationDay contextA.calculationDay
            && BI.equal contextAChanged.targetDay contextA.targetDay
            && Dict.get "bootstrap.eignarhald.a" contextB.metrics == Nothing
        )
        "annað samhengi ósnert og inntak þess fyrra óbreytt"
        "samhengi skoðuð eftir sjálfstæðar umbreytingar"
    , check
        "Röð sjálfstæðra samhengiútreikninga breytir ekki niðurstöðu"
        (sameContextPair sequenceAB sequenceBA)
        "sama par óháð byggingarröð"
        (if sameContextPair sequenceAB sequenceBA then "sama par" else "mismunandi par")
    , check
        "Framleiðsluskelin stöðvast vísvitandi í Bootstrap"
        (case spaghettiBootstrap of
            Err Spaghetti.BootstrapOnly ->
                True

            _ ->
                False
        )
        "BootstrapOnly"
        (case spaghettiBootstrap of
            Err Spaghetti.BootstrapOnly ->
                "BootstrapOnly"

            Err (Spaghetti.BaseValidationFailed _) ->
                "BaseValidationFailed"

            Ok _ ->
                "óvænt niðurstaða"
        )
    ]


renderCheck : Check -> String
renderCheck item =
    if item.passed then
        "PASS — " ++ item.name

    else
        "FAIL — "
            ++ item.name
            ++ " | vænt: "
            ++ item.expected
            ++ " | fékk: "
            ++ item.actual


allPassed : Bool
allPassed =
    List.all .passed checks


summary : String
summary =
    let
        passed =
            List.filter .passed checks |> List.length

        total =
            List.length checks

        state =
            if allPassed then
                "GRÆNT"

            else
                "RAUTT"
    in
    "Stage 1 prófanir: "
        ++ String.fromInt passed
        ++ "/"
        ++ String.fromInt total
        ++ " standast. Staða: "
        ++ state
        ++ "\n"
        ++ String.join "\n" (List.map renderCheck checks)
