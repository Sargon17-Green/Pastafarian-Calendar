module Pastafari.Stage01Suite
  ( Check
  , checks
  , allPassed
  ) where

import Prelude

import Data.Array as Array
import Data.Either (Either(..))
import Data.Foldable (foldl)
import Data.Maybe (Maybe(..))
import Pastafari.BigInteger as B
import Pastafari.Monster (bootstrapMonster)
import Pastafari.Monster.Base (MonsterStatus(..))
import Pastafari.Normative.Calendar as Calendar
import Pastafari.Normative.Combinatorics as C
import Pastafari.Normative.Reference as R
import Pastafari.SourceLanguageCatalog as Catalog
import Pastafari.Stage01Fixtures as F

type Check =
  { label :: String
  , passed :: Boolean
  }

check :: String -> Boolean -> Check
check label passed = { label, passed }

allPassed :: Array Check -> Boolean
allPassed = foldl (\ok x -> ok && x.passed) true

allCatalogIndicesResolve :: Int -> Int -> (Int -> Maybe String) -> Boolean
allCatalogIndicesResolve current last resolve
  | current > last = true
  | otherwise = case resolve current of
      Nothing -> false
      Just _ -> allCatalogIndicesResolve (current + 1) last resolve

isPermutationSix :: Array Int -> Boolean
isPermutationSix xs = Array.sort xs == [ 1, 2, 3, 4, 5, 6 ]

inSavedRange :: B.Big -> Boolean
inSavedRange x = B.compareBig x B.one /= LT && B.compareBig x R.modulusM /= GT

sameBootstrapResult :: B.Big -> B.Big -> Boolean
sameBootstrapResult c t =
  case bootstrapMonster c t, bootstrapMonster c t of
    Right a, Right b ->
      a.calculationDay == b.calculationDay
        && a.targetDay == b.targetDay
        && a.status == b.status
        && a.phase == b.phase
        && a.branchTrace == b.branchTrace
        && a.metrics == b.metrics
        && a.validationFailures == b.validationFailures
    _, _ -> false

bootstrapReady :: Boolean
bootstrapReady = case bootstrapMonster R.foundationDay R.foundationDay of
  Right ctx -> ctx.status == Ready
  Left _ -> false

checks :: Array Check
checks =
  let m = R.modulusM
      twoM = B.mul (B.fromInt 2) m
      countsSame = R.workCounts R.foundationDay R.foundationDay
      countsCross = R.workCounts (B.sub R.foundationDay (B.fromInt 2)) (B.add R.foundationDay (B.fromInt 3))
      stones = R.buildStones
      secondStone = Array.index stones 1
      hidden = R.buildHiddenDrops countsSame stones
      visible = R.buildVisibleDrops countsSame stones hidden
      sauceA = R.sauce R.foundationDay R.foundationDay
      sauceB = R.sauce R.foundationDay R.foundationDay
      positiveGap1 = Calendar.positiveGateGap B.one
      positiveGap1Again = Calendar.positiveGateGap B.one
      negativeGap1 = Calendar.negativeGateGap B.one
      fakeSauce =
        { bowls: map B.fromInt [ 1, 2, 3, 4, 5, 6 ]
        , orderAtDrop46: [ 2, 3, 4, 5, 6, 1 ]
        }
      fakeAsked = R.askBowl fakeSauce 1 1
      expectedFakeFirst = R.save
        ( B.add
          (B.mul (B.fromInt 183) (B.fromInt 183))
          (B.add (B.mul (B.fromInt 179) (B.fromInt 2)) B.one)
        )
      shortRejectStream = { first: m, directionStep: B.one }
      wideStream = { first: B.one, directionStep: B.one }
      bounded = C.boundedCompositionFamily 5 2 1 4
      requiredBoundary = C.cutletPartitionFamily 5 2 (Just 2)
      canonicalPresentation = Calendar.presentCanonicalDate
        { yearNumber: B.fromInt 5000
        , cutletCanonicalIndex: 12
        , dayInCutlet: B.fromInt 7
        , monthCanonicalIndex: 44
        , dayInMonth: B.fromInt 3
        }
  in
  [ check "BigInteger जोड सही छ" (B.add (B.fromInt 123456789) (B.fromInt 987654321) == B.fromInt 1111111110)
  , check "BigInteger घटाउ सही छ" (B.sub (B.fromInt 5) (B.fromInt 8) == B.fromInt (-3))
  , check "BigInteger गुणन सही छ" (B.mul (B.fromInt 12345) (B.fromInt 6789) == B.fromInt 83810205)
  , check "BigInteger युक्लिडीय तल भाग सही छ" (B.floorDiv (B.fromInt (-7)) (B.fromInt 3) == Just (B.fromInt (-3)))
  , check "BigInteger युक्लिडीय शेष सही छ" (B.regularMod (B.fromInt (-7)) (B.fromInt 3) == Just (B.fromInt 2))
  , check "M = 2^127 - 1 सही छ" (m == B.sub (B.pow (B.fromInt 2) 127) B.one)
  , check "SAVE(1) = 1 सही छ" (R.save B.one == B.one)
  , check "SAVE(M-1) = M-1 सही छ" (R.save (B.sub m B.one) == B.sub m B.one)
  , check "SAVE(M) = M सही छ" (R.save m == m)
  , check "SAVE(M+1) = 1 सही छ" (R.save (B.add m B.one) == B.one)
  , check "SAVE(2M) = M सही छ" (R.save twoM == m)
  , check "Tablets र Foundation बीचको दूरी सही छ" (B.sub R.tabletsDay R.foundationDay == F.expectedTabletsDistance)
  , check "Foundation को dayCount सही छ" (R.dayCount R.foundationDay == B.one)
  , check "Foundation अघिको dayCount सही छ" (R.dayCount (B.sub R.foundationDay B.one) == B.fromInt 2)
  , check "Foundation पछिको dayCount सही छ" (R.dayCount (B.add R.foundationDay B.one) == B.fromInt 3)
  , check "उही दिनको दूरी सही छ" (countsSame.distance == B.one)
  , check "उही दिनको दिशा सही छ" (countsSame.direction == B.fromInt 2)
  , check "Foundation पार गर्ने कालानुक्रमिक दूरी सही छ" (countsCross.distance == B.fromInt 6)
  , check "ढुङ्गा तालिकामा 46 पङ्क्ति छन्" (Array.length stones == 46)
  , check "दोस्रो ढुङ्गा एउटै पुरानो अवस्थाबाट बनेको छ" (secondStone == Just F.expectedSecondStone)
  , check "सात लुकेका थोपा छन्" (Array.length hidden == 7)
  , check "सबै लुकेका थोपा सुरक्षित दायरामा छन्" (foldl (\ok x -> ok && inSavedRange x) true hidden)
  , check "46 देखिने थोपा छन्" (Array.length visible == 46)
  , check "सबै देखिने थोपा सुरक्षित दायरामा छन्" (foldl (\ok x -> ok && inSavedRange x) true visible)
  , check "क्रमचयको rank 1 सही छ" (R.bowlOrderFromDrop B.one == F.expectedFirstBowlOrder)
  , check "क्रमचयको rank 720 सही छ" (R.bowlOrderFromDrop (B.fromInt 720) == F.expectedLastBowlOrder)
  , check "रोटबमा छ कचौरा छन्" (Array.length sauceA.bowls == 6)
  , check "रोटबले छ-कचौरा सोधाइ क्रम जोगाउँछ" (isPermutationSix sauceA.orderAtDrop46)
  , check "रोटबका दुई invocation एक-अर्काबाट अलग छन्" (sauceA == sauceB)
  , check "धनात्मक gate gap 42..963 भित्र छ" (B.compareBig positiveGap1 (B.fromInt 42) /= LT && B.compareBig positiveGap1 (B.fromInt 963) /= GT)
  , check "ऋणात्मक gate gap 42..963 भित्र छ" (B.compareBig negativeGap1 (B.fromInt 42) /= LT && B.compareBig negativeGap1 (B.fromInt 963) /= GT)
  , check "gate gap पुनः invocation गर्दा उही नतिजा आउँछ" (positiveGap1 == positiveGap1Again)
  , check "थोपा 46 को क्रमको अन्तिम कचौराबाट सोधाइ पहिलो कचौरामा फर्किन्छ" (fakeAsked.first == expectedFakeFirst)
  , check "छोटो छनोटले N=2 मा M अस्वीकार गरेर त्यही घेरामा अगाडि बढ्छ" (R.chooseRank shortRejectStream (B.fromInt 2) == B.one)
  , check "फराकिलो छनोट N=M+1 मा सही छ" (R.chooseRank wideStream (B.add m B.one) == B.add m B.one)
  , check "घट्दो factorial 5P3 सही छ" (C.fallingFactorial 5 3 == B.fromInt 60)
  , check "फरक नामको unrank rank 6 सही छ" (C.unrankDistinctIndices 3 2 (B.fromInt 6) == F.expectedDistinctRankSix)
  , check "सीमित composition को गणना सही छ" (bounded.count == B.fromInt 4)
  , check "सीमित composition को पहिलो rank सही छ" (bounded.unrank1 B.one == F.expectedBoundedFirst)
  , check "सीमित composition को अन्तिम rank सही छ" (bounded.unrank1 (B.fromInt 4) == F.expectedBoundedLast)
  , check "कचलेट सीमा filter को गणना सही छ" (requiredBoundary.count == B.one)
  , check "कचलेट सीमा filter को unrank सही छ" (requiredBoundary.unrank1 B.one == [ 2, 3 ])
  , check "[2,2] बुनाइको गणना सही छ" (C.countWeavings [ 2, 2 ] == B.fromInt 2)
  , check "बुनाइको rank 1 सही छ" (C.unrankWeaving [ 2, 2 ] B.one == F.expectedWeavingFirst)
  , check "बुनाइको rank 2 सही छ" (C.unrankWeaving [ 2, 2 ] (B.fromInt 2) == F.expectedWeavingSecond)
  , check "कचलेट क्याटलगमा 17 नाम छन्" (Array.length Catalog.cutletCatalog == 17)
  , check "महिना क्याटलगमा 47 नाम छन्" (Array.length Catalog.monthCatalog == 47)
  , check "कचलेट canonicalIndex क्रम सही छ" (map _.canonicalIndex Catalog.cutletCatalog == Array.range 1 17)
  , check "महिना canonicalIndex क्रम सही छ" (map _.canonicalIndex Catalog.monthCatalog == Array.range 1 47)
  , check "हरेक कचलेट canonicalIndex ले नाम दिन्छ" (allCatalogIndicesResolve 1 17 Catalog.cutletNameByCanonicalIndex)
  , check "हरेक महिना canonicalIndex ले नाम दिन्छ" (allCatalogIndicesResolve 1 47 Catalog.monthNameByCanonicalIndex)
  , check "प्रस्तुति तहले कचलेट नाम canonicalIndex बाट मात्र निकाल्छ" (canonicalPresentation.cutletName == "गहुँ")
  , check "प्रस्तुति तहले महिना नाम canonicalIndex बाट मात्र निकाल्छ" (canonicalPresentation.monthName == "नुन")
  , check "bootstrap context invocation-स्थानीय र deterministic छ" (sameBootstrapResult R.foundationDay (B.add R.foundationDay B.one))
  , check "bootstrap Ready अवस्थामा पुग्छ" bootstrapReady
  ]
