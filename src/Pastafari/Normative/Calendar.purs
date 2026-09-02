module Pastafari.Normative.Calendar
  ( CanonicalDateFive
  , PresentedDateFive
  , Year
  , YearStructure
  , calendarDateCanonical
  , presentCanonicalDate
  , initialGateBook
  , positiveGateGap
  , negativeGateGap
  ) where

import Prelude

import Data.Array as Array
import Data.Foldable (foldl)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Tuple (Tuple(..))
import Pastafari.BigInteger (Big)
import Pastafari.BigInteger as B
import Pastafari.Normative.Combinatorics as C
import Pastafari.Normative.Reference as R
import Pastafari.SourceLanguageCatalog as Catalog

type GateBook =
  { gates :: Map.Map Big Big
  , minIndex :: Big
  , maxIndex :: Big
  }

type Year =
  { number :: Big
  , openGateIndex :: Big
  , closeGateIndex :: Big
  , openGateDay :: Big
  , closeGateDay :: Big
  }

type Cutlet =
  { canonicalIndex :: Int
  , openGateIndex :: Big
  , closeGateIndex :: Big
  , firstDay :: Big
  , lastDay :: Big
  }

type YearStructure =
  { cutletCount :: Int
  , cutletPartition :: Array Int
  , cutletCanonicalIndices :: Array Int
  , cutlets :: Array Cutlet
  , monthCount :: Int
  , monthLengths :: Array Int
  , monthWeaving :: Array Int
  , monthCanonicalIndices :: Array Int
  }

type CanonicalDateFive =
  { yearNumber :: Big
  , cutletCanonicalIndex :: Int
  , dayInCutlet :: Big
  , monthCanonicalIndex :: Int
  , dayInMonth :: Big
  }

type PresentedDateFive =
  { yearNumber :: Big
  , cutletName :: String
  , dayInCutlet :: Big
  , monthName :: String
  , dayInMonth :: Big
  }

initialGateBook :: GateBook
initialGateBook =
  { gates: Map.singleton B.zero R.foundationDay
  , minIndex: B.zero
  , maxIndex: B.zero
  }

getGate :: GateBook -> Big -> Big
getGate book index = fromMaybe R.foundationDay (Map.lookup index book.gates)

positiveGateGap :: Big -> Big
positiveGateGap n =
  let sauceResult = R.sauce R.foundationDay (B.add R.foundationDay n)
      stream = R.askBowl sauceResult 1 1
      chosen = R.chooseRank stream (B.fromInt 922)
  in B.add (B.fromInt 41) chosen

negativeGateGap :: Big -> Big
negativeGateGap n =
  let sauceResult = R.sauce R.foundationDay (B.sub R.foundationDay n)
      stream = R.askBowl sauceResult 1 1
      chosen = R.chooseRank stream (B.fromInt 922)
  in B.add (B.fromInt 41) chosen

ensureGateIndex :: Big -> GateBook -> GateBook
ensureGateIndex wanted book
  | B.compareBig wanted book.maxIndex == GT = growPositive (B.add book.maxIndex B.one) book
  | B.compareBig wanted book.minIndex == LT = growNegative (B.sub book.minIndex B.one) book
  | otherwise = book
  where
  growPositive n current
    | B.compareBig n wanted == GT = current
    | otherwise =
        let previousIndex = B.sub n B.one
            previousDay = getGate current previousIndex
            nextDay = B.add previousDay (positiveGateGap n)
            updated = current { gates = Map.insert n nextDay current.gates, maxIndex = n }
        in growPositive (B.add n B.one) updated

  growNegative n current
    | B.compareBig n wanted == LT = current
    | otherwise =
        let nextIndex = B.add n B.one
            nextDay = getGate current nextIndex
            gap = negativeGateGap (B.absBig n)
            day = B.sub nextDay gap
            updated = current { gates = Map.insert n day current.gates, minIndex = n }
        in growNegative (B.sub n B.one) updated

ensureGatesCover :: Big -> Big -> GateBook -> GateBook
ensureGatesCover low high book =
  let left = growLeft book
  in growRight left
  where
  growLeft current =
    if B.compareBig (getGate current current.minIndex) low == GT then
      growLeft (ensureGateIndex (B.sub current.minIndex B.one) current)
    else current

  growRight current =
    if B.compareBig (getGate current current.maxIndex) high == LT then
      growRight (ensureGateIndex (B.add current.maxIndex B.one) current)
    else current

entries :: GateBook -> Array (Tuple Big Big)
entries book = Map.toUnfoldable book.gates

gateIndexAtOrBefore :: Big -> GateBook -> { index :: Big, book :: GateBook }
gateIndexAtOrBefore day book0 =
  let book = ensureGatesCover day day book0
      picked = foldl choose book.minIndex (entries book)
  in { index: picked, book }
  where
  choose current (Tuple idx d) =
    if B.compareBig d day /= GT && B.compareBig idx current == GT then idx else current

gateIndexAtOrAfter :: Big -> GateBook -> { index :: Big, book :: GateBook }
gateIndexAtOrAfter day book0 =
  let before = gateIndexAtOrBefore day book0
      d = getGate before.book before.index
  in if d == day then before
     else
       let nextIndex = B.add before.index B.one
           book = ensureGateIndex nextIndex before.book
       in { index: nextIndex, book }

exactGateIndex :: Big -> GateBook -> { index :: Maybe Big, book :: GateBook }
exactGateIndex day book0 =
  let before = gateIndexAtOrBefore day book0
  in if getGate before.book before.index == day then { index: Just before.index, book: before.book }
     else { index: Nothing, book: before.book }

yearLength :: GateBook -> Big -> Big -> Big
yearLength book openIndex closeIndex = B.sub (getGate book closeIndex) (getGate book openIndex)

validYearPair :: GateBook -> Big -> Big -> Boolean
validYearPair book openIndex closeIndex =
  let gapCount = B.sub closeIndex openIndex
      lengthDays = yearLength book openIndex closeIndex
  in B.compareBig gapCount (B.fromInt 6) /= LT
      && B.compareBig lengthDays (B.fromInt 252) /= LT
      && B.compareBig lengthDays (B.fromInt 5778) /= GT

type YearCandidate =
  { openIndex :: Big
  , closeIndex :: Big
  , lengthDays :: Big
  , openDay :: Big
  }

allYear5000Candidates :: Big -> GateBook -> Array YearCandidate
allYear5000Candidates calculationDay book =
  Array.concatMap fromOpen (entries book)
  where
  all = entries book
  fromOpen (Tuple i openDay) = Array.mapMaybe (fromPair i openDay) all

  fromPair i openDay (Tuple j closeDay)
    | B.compareBig j i /= GT = Nothing
    | not (validYearPair book i j) = Nothing
    | not (B.compareBig openDay calculationDay == LT && B.compareBig calculationDay closeDay /= GT) = Nothing
    | otherwise = Just { openIndex: i, closeIndex: j, lengthDays: B.sub closeDay openDay, openDay }

sortYear5000Candidates :: Array YearCandidate -> Array YearCandidate
sortYear5000Candidates = Array.sortBy compareCandidate
  where
  compareCandidate a b =
    case B.compareBig a.lengthDays b.lengthDays of
      EQ -> B.compareBig a.openDay b.openDay
      other -> other

pickArray1 :: forall a. a -> Array a -> Big -> a
pickArray1 fallback xs rank =
  let index = fromMaybe 1 (B.toIntExact rank) - 1
  in fromMaybe fallback (Array.index xs index)

year5000 :: Big -> GateBook -> { year :: Year, book :: GateBook }
year5000 calculationDay book0 =
  let book = ensureGatesCover
        (B.sub calculationDay (B.fromInt 5778))
        (B.add calculationDay (B.fromInt 5778))
        book0
      candidates = sortYear5000Candidates (allYear5000Candidates calculationDay book)
      fallback =
        { openIndex: book.minIndex
        , closeIndex: book.maxIndex
        , lengthDays: yearLength book book.minIndex book.maxIndex
        , openDay: getGate book book.minIndex
        }
      sauceResult = R.sauce calculationDay calculationDay
      stream = R.askBowl sauceResult 1 10
      rank = R.chooseRank stream (B.fromInt (Array.length candidates))
      chosen = pickArray1 fallback candidates rank
      year =
        { number: B.fromInt 5000
        , openGateIndex: chosen.openIndex
        , closeGateIndex: chosen.closeIndex
        , openGateDay: getGate book chosen.openIndex
        , closeGateDay: getGate book chosen.closeIndex
        }
  in { year, book }

nextYear :: Big -> Year -> GateBook -> { year :: Year, book :: GateBook }
nextYear calculationDay known book0 =
  let openIndex = known.closeGateIndex
      openDay = getGate book0 openIndex
      book = ensureGatesCover (getGate book0 book0.minIndex) (B.add openDay (B.fromInt 5778)) book0
      candidates = Array.mapMaybe (candidate book openIndex openDay) (entries book)
      sorted = Array.sortBy (\a b -> B.compareBig a.lengthDays b.lengthDays) candidates
      fallback = { closeIndex: B.add openIndex B.one, lengthDays: B.fromInt 252 }
      sauceResult = R.sauce calculationDay openDay
      stream = R.askBowl sauceResult 1 11
      rank = R.chooseRank stream (B.fromInt (Array.length sorted))
      chosen = pickArray1 fallback sorted rank
      closeDay = getGate book chosen.closeIndex
      year =
        { number: B.add known.number B.one
        , openGateIndex: openIndex
        , closeGateIndex: chosen.closeIndex
        , openGateDay: openDay
        , closeGateDay: closeDay
        }
  in { year, book }
  where
  candidate book openIndex openDay (Tuple j day)
    | B.compareBig j openIndex /= GT = Nothing
    | not (validYearPair book openIndex j) = Nothing
    | otherwise = Just { closeIndex: j, lengthDays: B.sub day openDay }

previousYear :: Big -> Year -> GateBook -> { year :: Year, book :: GateBook }
previousYear calculationDay known book0 =
  let closeIndex = known.openGateIndex
      closeDay = getGate book0 closeIndex
      book = ensureGatesCover (B.sub closeDay (B.fromInt 5778)) (getGate book0 book0.maxIndex) book0
      candidates = Array.mapMaybe (candidate book closeIndex closeDay) (entries book)
      sorted = Array.sortBy (\a b -> B.compareBig a.lengthDays b.lengthDays) candidates
      fallback = { openIndex: B.sub closeIndex B.one, lengthDays: B.fromInt 252 }
      sauceResult = R.sauce calculationDay closeDay
      stream = R.askBowl sauceResult 1 12
      rank = R.chooseRank stream (B.fromInt (Array.length sorted))
      chosen = pickArray1 fallback sorted rank
      openDay = getGate book chosen.openIndex
      year =
        { number: B.sub known.number B.one
        , openGateIndex: chosen.openIndex
        , closeGateIndex: closeIndex
        , openGateDay: openDay
        , closeGateDay: closeDay
        }
  in { year, book }
  where
  candidate book closeIndex closeDay (Tuple i day)
    | B.compareBig i closeIndex /= LT = Nothing
    | not (validYearPair book i closeIndex) = Nothing
    | otherwise = Just { openIndex: i, lengthDays: B.sub closeDay day }

findTargetYear :: Big -> Big -> GateBook -> { year :: Year, book :: GateBook }
findTargetYear calculationDay targetDay book0 =
  let anchor = year5000 calculationDay book0
  in walk anchor.year anchor.book
  where
  walk year book
    | B.compareBig targetDay year.closeGateDay == GT =
        let n = nextYear calculationDay year book
        in walk n.year n.book
    | B.compareBig targetDay year.openGateDay /= GT =
        let p = previousYear calculationDay year book
        in walk p.year p.book
    | otherwise = { year, book }

intFromSmallBig :: Big -> Int
intFromSmallBig = fromMaybe 0 <<< B.toIntExact

chooseCutletCount :: R.SauceResult -> Year -> Int
chooseCutletCount sauceResult year =
  let gaps = intFromSmallBig (B.sub year.closeGateIndex year.openGateIndex)
      candidates = Array.filter (_ <= gaps) (Array.range 6 17)
      stream = R.askBowl sauceResult 2 20
      rank = R.chooseRank stream (B.fromInt (Array.length candidates))
  in pickArray1 6 candidates rank

chooseCutletPartition :: Big -> R.SauceResult -> Year -> GateBook -> Int -> { partition :: Array Int, book :: GateBook }
chooseCutletPartition calculationDay sauceResult year book0 cutletCount =
  let exact = exactGateIndex calculationDay book0
      required = case exact.index of
        Just g | B.compareBig g year.openGateIndex == GT && B.compareBig g year.closeGateIndex == LT ->
          Just (intFromSmallBig (B.sub g year.openGateIndex))
        _ -> Nothing
      gaps = intFromSmallBig (B.sub year.closeGateIndex year.openGateIndex)
      family = C.cutletPartitionFamily gaps cutletCount required
      stream = R.askBowl sauceResult 2 21
      rank = R.chooseRank stream family.count
  in { partition: family.unrank1 rank, book: exact.book }

chooseDistinctNames :: R.SauceResult -> Int -> Int -> Int -> Array Int
chooseDistinctNames sauceResult bowlId seal masterSize count =
  let n = C.fallingFactorial masterSize count
      stream = R.askBowl sauceResult bowlId seal
      rank = R.chooseRank stream n
  in C.unrankDistinctIndices masterSize count rank

materializeCutlets :: Year -> GateBook -> Array Int -> Array Int -> Array Cutlet
materializeCutlets year book partition nameIndices = go year.openGateIndex 1 partition []
  where
  go cursor position remaining out =
    case Array.uncons remaining of
      Nothing -> out
      Just p ->
        let closeIndex = B.add cursor (B.fromInt p.head)
            canonicalIndex = fromMaybe 1 (Array.index nameIndices (position - 1))
            cutlet =
              { canonicalIndex
              , openGateIndex: cursor
              , closeGateIndex: closeIndex
              , firstDay: B.add (getGate book cursor) B.one
              , lastDay: getGate book closeIndex
              }
        in go closeIndex (position + 1) p.tail (Array.snoc out cutlet)

ceilDivInt :: Int -> Int -> Int
ceilDivInt a b = div (a + b - 1) b

chooseMonthCount :: R.SauceResult -> Year -> Int
chooseMonthCount sauceResult year =
  let l = intFromSmallBig (B.sub year.closeGateDay year.openGateDay)
      lo = ceilDivInt l 123
      hi = min 47 (div l 4)
      stream = R.askBowl sauceResult 3 30
      rank = R.chooseRank stream (B.fromInt (hi - lo + 1))
  in lo + intFromSmallBig rank - 1

chooseMonthLengths :: R.SauceResult -> Year -> Int -> Array Int
chooseMonthLengths sauceResult year monthCount =
  let l = intFromSmallBig (B.sub year.closeGateDay year.openGateDay)
      family = C.boundedCompositionFamily l monthCount 4 123
      stream = R.askBowl sauceResult 3 31
      rank = R.chooseRank stream family.count
  in family.unrank1 rank

chooseMonthWeaving :: R.SauceResult -> Array Int -> Array Int
chooseMonthWeaving sauceResult lengths =
  let n = C.countWeavings lengths
      stream = R.askBowl sauceResult 4 32
      rank = R.chooseRank stream n
  in C.unrankWeaving lengths rank

buildYearStructure :: Big -> Year -> GateBook -> { structure :: YearStructure, book :: GateBook }
buildYearStructure calculationDay year book0 =
  let firstDay = B.add year.openGateDay B.one
      sauceResult = R.sauce calculationDay firstDay
      cutletCount = chooseCutletCount sauceResult year
      chosenPartition = chooseCutletPartition calculationDay sauceResult year book0 cutletCount
      cutletNames = chooseDistinctNames sauceResult 5 22 17 cutletCount
      cutlets = materializeCutlets year chosenPartition.book chosenPartition.partition cutletNames
      monthCount = chooseMonthCount sauceResult year
      monthLengths = chooseMonthLengths sauceResult year monthCount
      monthWeaving = chooseMonthWeaving sauceResult monthLengths
      monthNames = chooseDistinctNames sauceResult 5 33 47 monthCount
      structure =
        { cutletCount
        , cutletPartition: chosenPartition.partition
        , cutletCanonicalIndices: cutletNames
        , cutlets
        , monthCount
        , monthLengths
        , monthWeaving
        , monthCanonicalIndices: monthNames
        }
  in { structure, book: chosenPartition.book }

findCutlet :: Big -> Array Cutlet -> Cutlet
findCutlet target cutlets =
  fromMaybe fallback (Array.find contains cutlets)
  where
  fallback =
    { canonicalIndex: 1
    , openGateIndex: B.zero
    , closeGateIndex: B.zero
    , firstDay: target
    , lastDay: target
    }
  contains c = B.compareBig c.firstDay target /= GT && B.compareBig target c.lastDay /= GT

countOccurrencesThrough :: Int -> Int -> Array Int -> Int
countOccurrencesThrough monthId position weaving = go 1 0
  where
  go p acc
    | p > position = acc
    | otherwise =
        let value = fromMaybe 0 (Array.index weaving (p - 1))
        in go (p + 1) (if value == monthId then acc + 1 else acc)

calendarDateCanonical :: Big -> Big -> CanonicalDateFive
calendarDateCanonical calculationDay targetDay =
  let found = findTargetYear calculationDay targetDay initialGateBook
      built = buildYearStructure calculationDay found.year found.book
      chosenCutlet = findCutlet targetDay built.structure.cutlets
      dayInCutlet = B.add (B.sub targetDay chosenCutlet.firstDay) B.one
      offset0 = intFromSmallBig (B.sub targetDay (B.add found.year.openGateDay B.one))
      monthId = fromMaybe 1 (Array.index built.structure.monthWeaving offset0)
      monthCanonicalIndex = fromMaybe 1 (Array.index built.structure.monthCanonicalIndices (monthId - 1))
      dayInMonth = countOccurrencesThrough monthId (offset0 + 1) built.structure.monthWeaving
  in
    { yearNumber: found.year.number
    , cutletCanonicalIndex: chosenCutlet.canonicalIndex
    , dayInCutlet
    , monthCanonicalIndex
    , dayInMonth: B.fromInt dayInMonth
    }

presentCanonicalDate :: CanonicalDateFive -> PresentedDateFive
presentCanonicalDate x =
  { yearNumber: x.yearNumber
  , cutletName: fromMaybe "" (Catalog.cutletNameByCanonicalIndex x.cutletCanonicalIndex)
  , dayInCutlet: x.dayInCutlet
  , monthName: fromMaybe "" (Catalog.monthNameByCanonicalIndex x.monthCanonicalIndex)
  , dayInMonth: x.dayInMonth
  }
