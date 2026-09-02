module Pastafari.NormativeOracle
  ( Day
  , WorkCounts(..)
  , Stone(..)
  , SauceResult(..)
  , AnswerStream(..)
  , Year(..)
  , Cutlet(..)
  , YearStructure(..)
  , CalendarFiveIds(..)
  , CalendarFiveText(..)
  , m
  , tabletsDay
  , foundationDay
  , regularMod
  , save
  , dayCount
  , workCounts
  , buildStones
  , buildHiddenDrops
  , buildVisibleDrops
  , bowlOrderFromDrop
  , initialBowls
  , sauce
  , askBowl
  , answerAt
  , chooseRankShort
  , chooseRankWide
  , chooseRank
  , fallingFactorial
  , unrankDistinctIndices
  , countBoundedCompositions
  , unrankBoundedComposition
  , countCutletPartitions
  , unrankCutletPartition
  , countWeavings
  , unrankWeaving
  , initialGateState
  , ensureGateIndex
  , gateIndexAtOrBefore
  , exactGateIndex
  , year5000
  , nextYear
  , previousYear
  , findTargetYear
  , buildYearStructure
  , calendarDateOracleIds
  , calendarDateOracle
  ) where

import Data.List (findIndex, foldl', sortBy)
import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)
import Data.Maybe (fromMaybe)
import Data.Ord (comparing)
import Pastafari.SourceLanguageCatalog (cutletNameByIndex, monthNameByIndex)

type Day = Integer

m :: Integer
m = 2 ^ (127 :: Int) - 1

tabletsDay :: Day
tabletsDay = -278522

foundationDay :: Day
foundationDay = -15055671

gateGapMin, gateGapMax, yearMinDays, yearMaxDays :: Integer
gateGapMin = 42
gateGapMax = 963
yearMinDays = 252
yearMaxDays = 5778

minCutlets, maxCutlets, minMonths, maxMonths, minMonthDays, maxMonthDays :: Int
minCutlets = 6
maxCutlets = 17
minMonths = 3
maxMonths = 47
minMonthDays = 4
maxMonthDays = 123

sealGateGap, sealYear5000, sealNextYear, sealPreviousYear :: Integer
sealGateGap = 1
sealYear5000 = 10
sealNextYear = 11
sealPreviousYear = 12

sealCutletCount, sealCutletPartition, sealCutletNames :: Integer
sealCutletCount = 20
sealCutletPartition = 21
sealCutletNames = 22

sealMonthCount, sealMonthLengths, sealMonthWeaving, sealMonthNames :: Integer
sealMonthCount = 30
sealMonthLengths = 31
sealMonthWeaving = 32
sealMonthNames = 33

regularMod :: Integer -> Integer -> Integer
regularMod x d
  | d < 1 = error "Dělitel musí být kladný."
  | otherwise = x `mod` d

save :: Integer -> Integer
save x = 1 + regularMod (x - 1) m

ceilDiv :: Integer -> Integer -> Integer
ceilDiv a b
  | a < 0 = error "Čitatel pro zaokrouhlení nahoru nesmí být záporný."
  | b < 1 = error "Jmenovatel pro zaokrouhlení nahoru musí být kladný."
  | otherwise = (a + b - 1) `div` b

wrap1 :: Int -> Int -> Int
wrap1 position size
  | size < 1 = error "Velikost kruhu musí být kladná."
  | otherwise = fromInteger (regularMod (fromIntegral position - 1) (fromIntegral size)) + 1

at1 :: [a] -> Int -> a
at1 xs i = xs !! (i - 1)

replaceAt1 :: Int -> a -> [a] -> [a]
replaceAt1 i value xs =
  let (prefix, rest) = splitAt (i - 1) xs
  in case rest of
       [] -> error "Index je mimo rozsah seznamu."
       (_:suffix) -> prefix ++ value : suffix

data WorkCounts = WorkCounts
  { actionCount :: Integer
  , targetCount :: Integer
  , distanceCount :: Integer
  , connectionCount :: Integer
  , directionCount :: Integer
  } deriving (Eq, Ord, Show)

dayCount :: Day -> Integer
dayCount day
  | day == foundationDay = 1
  | day > foundationDay = 2 * (day - foundationDay) + 1
  | otherwise = 2 * (foundationDay - day)

workCounts :: Day -> Day -> WorkCounts
workCounts calculationDay targetDay =
  WorkCounts
    { actionCount = dayCount calculationDay
    , targetCount = dayCount targetDay
    , distanceCount = abs (targetDay - calculationDay) + 1
    , connectionCount = dayCount calculationDay + dayCount targetDay
    , directionCount = if targetDay < calculationDay then 1 else if targetDay == calculationDay then 2 else 3
    }

data Stone = Stone
  { stoneWheat :: Integer
  , stoneBarley :: Integer
  , stoneSalt :: Integer
  , stoneBitter :: Integer
  , stoneRed :: Integer
  } deriving (Eq, Ord, Show)

data StoneKind = Wheat | Barley | Salt | Bitter | Red
  deriving (Eq, Ord, Show)

stoneValue :: StoneKind -> Stone -> Integer
stoneValue Wheat = stoneWheat
stoneValue Barley = stoneBarley
stoneValue Salt = stoneSalt
stoneValue Bitter = stoneBitter
stoneValue Red = stoneRed

nextStone :: Int -> Stone -> Stone
nextStone i old =
  Stone
    { stoneWheat = save (stoneWheat old ^ (2 :: Int) + 3 * stoneBarley old + fromIntegral i)
    , stoneBarley = save (stoneBarley old ^ (2 :: Int) + 5 * stoneSalt old + stoneWheat old)
    , stoneSalt = save (stoneSalt old ^ (2 :: Int) + 7 * stoneBitter old + stoneBarley old)
    , stoneBitter = save (stoneBitter old ^ (2 :: Int) + 11 * stoneRed old + stoneSalt old)
    , stoneRed = save (stoneRed old ^ (2 :: Int) + 13 * stoneWheat old + stoneBitter old)
    }

buildStones :: [Stone]
buildStones = take 46 (iterateWithIndex 2 (Stone 17 29 43 71 101))
  where
    iterateWithIndex :: Int -> Stone -> [Stone]
    iterateWithIndex i current = current : iterateWithIndex (i + 1) (nextStone i current)

hiddenCoefficients :: [(Integer, Integer, Integer, Integer)]
hiddenCoefficients =
  [ (3,4,6,8)
  , (5,7,10,12)
  , (7,10,14,16)
  , (9,13,18,20)
  , (11,16,22,24)
  , (13,19,26,28)
  , (15,22,30,32)
  ]

hiddenGrindStones :: [StoneKind]
hiddenGrindStones = [Wheat, Barley, Salt, Bitter, Red, Wheat, Barley]

buildHiddenDrops :: WorkCounts -> [Stone] -> [Integer]
buildHiddenDrops counts stones = map buildOne [1..7]
  where
    buildOne k =
      let (a,b,c,d) = at1 hiddenCoefficients k
          s = at1 stones k
          initial = save
            ( actionCount counts
            + a * targetCount counts
            + b * distanceCount counts
            + c * connectionCount counts
            + d * directionCount counts
            + stoneWheat s + stoneBarley s + stoneSalt s + stoneBitter s + stoneRed s
            )
      in foldl' (grind s) initial (zip [1..7] hiddenGrindStones)
    grind s x (g, kind) = save (x * x + 3 * x + stoneValue kind s + fromIntegral g)

visibleGrinds :: [(Integer, Integer, Integer, Integer, StoneKind)]
visibleGrinds =
  [ (3,5,7,11,Wheat)
  , (5,7,11,13,Barley)
  , (7,11,13,17,Salt)
  , (11,13,17,19,Bitter)
  , (13,17,19,23,Red)
  , (17,19,23,29,Wheat)
  , (19,23,29,31,Barley)
  , (23,29,31,37,Salt)
  , (29,31,37,41,Bitter)
  , (31,37,41,43,Red)
  , (37,41,43,47,Wheat)
  ]

priorVisibleOrHidden :: [Integer] -> [Integer] -> Int -> Int -> Integer
priorVisibleOrHidden visible hidden i back =
  let slot = i - back
  in if slot >= 1
       then at1 visible slot
       else at1 hidden (1 - slot)

buildVisibleDrops :: WorkCounts -> [Stone] -> [Integer] -> [Integer]
buildVisibleDrops counts stones hidden = go 1 []
  where
    go i built
      | i > 46 = built
      | otherwise =
          let p1 = priorVisibleOrHidden built hidden i 1
              p3 = priorVisibleOrHidden built hidden i 3
              p7 = priorVisibleOrHidden built hidden i 7
              s = at1 stones i
              initial = save
                ( stoneWheat s * actionCount counts
                + stoneBarley s * targetCount counts
                + stoneSalt s * distanceCount counts
                + stoneBitter s * connectionCount counts
                + stoneRed s * directionCount counts
                + p1 + 3 * p3 + 5 * p7 + fromIntegral i
                )
              final = foldl' (grind s p1 p3 p7) initial visibleGrinds
          in go (i + 1) (built ++ [final])
    grind s p1 p3 p7 x (a,b,c,d,kind) =
      save (x * x + a*x + b*p1 + c*p3 + d*p7 + stoneValue kind s)

factorial :: Int -> Integer
factorial n = product [1 .. fromIntegral n]

permutationUnrank1 :: Integer -> [Int] -> [Int]
permutationUnrank1 rank1 items
  | rank1 < 1 || rank1 > factorial (length items) = error "Pořadí permutace je mimo rozsah."
  | otherwise = go (rank1 - 1) items
  where
    go _ [] = []
    go rank0 remaining =
      let block = factorial (length remaining - 1)
          q = fromInteger (rank0 `div` block)
          nextRank = regularMod rank0 block
          chosen = remaining !! q
          rest = take q remaining ++ drop (q + 1) remaining
      in chosen : go nextRank rest

bowlOrderFromDrop :: Integer -> [Int]
bowlOrderFromDrop dropValue =
  let orderNumber = regularMod (dropValue - 1) 720 + 1
  in permutationUnrank1 orderNumber [1..6]

bowlPrimes :: [Integer]
bowlPrimes = [17,19,23,29,31,37]

initialBowls :: WorkCounts -> [Integer]
initialBowls counts = map build [1..6]
  where
    build bowlId =
      let p = at1 bowlPrimes bowlId
          s = actionCount counts
            + targetCount counts * fromIntegral bowlId
            + distanceCount counts
            + connectionCount counts
            + directionCount counts
            + p * p
      in save (s * s + fromIntegral bowlId)

stirStoneByPosition :: [StoneKind]
stirStoneByPosition = [Wheat, Barley, Salt, Bitter, Red, Wheat]

applyVisibleDropsToBowls :: [Integer] -> [Integer] -> [Stone] -> ([Integer], [Int])
applyVisibleDropsToBowls bowls0 visible stones = go 1 bowls0 []
  where
    go i bowls order46
      | i > 46 = (bowls, order46)
      | otherwise =
          let dropValue = at1 visible i
              order = bowlOrderFromDrop dropValue
              old = bowls
              firstBowl = at1 order 1
              secondBowl = at1 order 2
              thirdBowl = at1 order 3
              stone = at1 stones i
              pours =
                [ save (dropValue*dropValue + stoneWheat stone * at1 old firstBowl + 3 * fromIntegral i)
                , save (dropValue*dropValue + stoneBarley stone * at1 old secondBowl + 5 * fromIntegral i)
                , save (dropValue*dropValue + stoneSalt stone * at1 old thirdBowl + 7 * fromIntegral i)
                , 0, 0, 0
                ]
              nextBowls = foldl' (stirPosition i dropValue stone order old pours) old [1..6]
              latched = if i == 46 then order else order46
          in go (i + 1) nextBowls latched
    stirPosition i dropValue stone order old pours pending position =
      let bowlId = at1 order position
          prevId = at1 order (wrap1 (position - 1) 6)
          nextId = at1 order (wrap1 (position + 1) 6)
          kind = at1 stirStoneByPosition position
          s = at1 old bowlId
            + 2 * at1 old prevId
            + 3 * at1 old nextId
            + at1 pours position
            + dropValue
            + stoneValue kind stone
          value = save (s*s + 5 * at1 old prevId * at1 old nextId + fromIntegral i * fromIntegral position)
      in replaceAt1 bowlId value pending

postStir12 :: [Integer] -> [Integer]
postStir12 bowls0 = foldl' stir bowls0 [1..12]
  where
    stir old stirNumber =
      let savedBowlSum = save (sum old + 149 * fromIntegral stirNumber)
          orderNumber = regularMod (savedBowlSum - 1) 720 + 1
          order = permutationUnrank1 orderNumber [1..6]
      in foldl' (stirPosition old savedBowlSum order stirNumber) old [1..6]
    stirPosition old savedBowlSum order stirNumber pending position =
      let bowlId = at1 order position
          prevId = at1 order (wrap1 (position - 1) 6)
          nextId = at1 order (wrap1 (position + 1) 6)
          s = at1 old bowlId
            + 3 * at1 old prevId
            + 5 * at1 old nextId
            + savedBowlSum
            + fromIntegral stirNumber
            + fromIntegral (position * position)
          value = save (s*s + 7 * at1 old prevId * at1 old nextId)
      in replaceAt1 bowlId value pending

data SauceResult = SauceResult
  { sauceBowls :: [Integer]
  , orderAtDrop46 :: [Int]
  } deriving (Eq, Ord, Show)

sauce :: Day -> Day -> SauceResult
sauce calculationDay targetDay =
  let counts = workCounts calculationDay targetDay
      stones = buildStones
      hidden = buildHiddenDrops counts stones
      visible = buildVisibleDrops counts stones hidden
      bowls = initialBowls counts
      (afterDrops, order46) = applyVisibleDropsToBowls bowls visible stones
      finalBowls = postStir12 afterDrops
  in SauceResult finalBowls order46

data AnswerStream = AnswerStream
  { answerFirst :: Integer
  , answerDirectionStep :: Integer
  } deriving (Eq, Ord, Show)

nextBowlInDrop46Order :: SauceResult -> Int -> Int
nextBowlInDrop46Order sauceResult queriedBowlId =
  let order = orderAtDrop46 sauceResult
      pos0 = fromMaybe (error "Dotazovaná miska není v pořadí.") (findIndex (== queriedBowlId) order)
  in order !! ((pos0 + 1) `mod` 6)

askBowl :: SauceResult -> Int -> Integer -> AnswerStream
askBowl sauceResult queriedBowlId seal =
  let nextId = nextBowlInDrop46Order sauceResult queriedBowlId
      first = save
        ((at1 (sauceBowls sauceResult) queriedBowlId + seal + 181) ^ (2 :: Int)
         + 179 * at1 (sauceBowls sauceResult) nextId
         + seal)
      directionNumber = save
        ((first + seal + 1 + 193) ^ (2 :: Int)
         + 193 * first
         + 197 * at1 (sauceBowls sauceResult) 6)
      step = if regularMod directionNumber 2 == 1 then 1 else -1
  in AnswerStream first step

answerAt :: AnswerStream -> Integer -> Integer
answerAt stream k = 1 + regularMod (answerFirst stream - 1 + answerDirectionStep stream * k) m

chooseRankShort :: AnswerStream -> Integer -> Integer
chooseRankShort stream n
  | n < 1 || n > m = error "Krátký výběr vyžaduje velikost od 1 do M."
  | otherwise = go 0
  where
    acceptanceLimit = (m `div` n) * n
    go k =
      let x = answerAt stream k
      in if x <= acceptanceLimit then regularMod (x - 1) n + 1 else go (k + 1)

smallestPowerCount :: Integer -> Integer -> (Int, Integer)
smallestPowerCount base n = go 1 base
  where
    go k space
      | space >= n = (k, space)
      | otherwise = go (k + 1) (space * base)

chooseRankWide :: AnswerStream -> Integer -> Integer
chooseRankWide stream n
  | n <= m = error "Široký výběr vyžaduje velikost větší než M."
  | otherwise =
      let (places, space) = smallestPowerCount m n
          wide0 = 1 + sum
            [ (answerAt stream (fromIntegral j) - 1) * (m ^ j)
            | j <- [0 .. places - 1]
            ]
          acceptanceLimit = (space `div` n) * n
          accepted = advance space acceptanceLimit wide0
      in regularMod (accepted - 1) n + 1
  where
    advance space limit w
      | w <= limit = w
      | otherwise = advance space limit (1 + regularMod (w - 1 + answerDirectionStep stream) space)

chooseRank :: AnswerStream -> Integer -> Integer
chooseRank stream n
  | n < 1 = error "Velikost uspořádané rodiny musí být kladná."
  | n <= m = chooseRankShort stream n
  | otherwise = chooseRankWide stream n

fallingFactorial :: Int -> Int -> Integer
fallingFactorial n k
  | k < 0 || k > n = 0
  | otherwise = product [fromIntegral (n - j) | j <- [0 .. k - 1]]

unrankDistinctIndices :: Int -> Int -> Integer -> [Int]
unrankDistinctIndices masterCount k rank1
  | k < 0 || k > masterCount = error "Počet různých názvů je mimo rozsah."
  | rank1 < 1 || rank1 > fallingFactorial masterCount k = error "Pořadí názvů je mimo rozsah."
  | otherwise = go 1 rank1 [1..masterCount]
  where
    go position r remaining
      | position > k = []
      | otherwise =
          let suffixLength = k - position
              block = fallingFactorial (length remaining - 1) suffixLength
              candidateNumber = fromInteger ((r - 1) `div` block)
              chosen = remaining !! candidateNumber
              nextRank = regularMod (r - 1) block + 1
              rest = take candidateNumber remaining ++ drop (candidateNumber + 1) remaining
          in chosen : go (position + 1) nextRank rest

countBoundedCompositions :: Int -> Int -> Int -> Int -> Integer
countBoundedCompositions total slots lo hi = fst (countBoundedMemo total slots lo hi Map.empty)

countBoundedMemo :: Int -> Int -> Int -> Int -> Map (Int,Int) Integer -> (Integer, Map (Int,Int) Integer)
countBoundedMemo remTotal slots lo hi memo
  | slots == 0 = (if remTotal == 0 then 1 else 0, memo)
  | remTotal < slots * lo || remTotal > slots * hi = (0, memo)
  | Just value <- Map.lookup (remTotal, slots) memo = (value, memo)
  | otherwise =
      let step (acc, currentMemo) x =
            let (v, nextMemo) = countBoundedMemo (remTotal - x) (slots - 1) lo hi currentMemo
            in (acc + v, nextMemo)
          (totalCount, finalMemo) = foldl' step (0, memo) [lo..hi]
      in (totalCount, Map.insert (remTotal, slots) totalCount finalMemo)

unrankBoundedComposition :: Int -> Int -> Int -> Int -> Integer -> [Int]
unrankBoundedComposition total slots lo hi rank1
  | rank1 < 1 || rank1 > totalCount = error "Pořadí omezené kompozice je mimo rozsah."
  | otherwise = go total slots rank1 initialMemo
  where
    (totalCount, initialMemo) = countBoundedMemo total slots lo hi Map.empty
    go _ 0 _ _ = []
    go remTotal remainingSlots r memo = chooseX lo memo
      where
        chooseX x currentMemo
          | x > hi = error "Omezenou kompozici se nepodařilo odrankovat."
          | otherwise =
              let (block, nextMemo) = countBoundedMemo (remTotal - x) (remainingSlots - 1) lo hi currentMemo
              in if r > block
                   then chooseX (x + 1) nextMemo
                   else x : go (remTotal - x) (remainingSlots - 1) r nextMemo

countCutletPartitions :: Int -> Int -> Maybe Int -> Integer
countCutletPartitions gaps cutlets required = fst (countCutletMemo gaps cutlets 0 False required Map.empty)

type CutletMemo = Map (Int,Int,Int,Bool) Integer

countCutletMemo :: Int -> Int -> Int -> Bool -> Maybe Int -> CutletMemo -> (Integer, CutletMemo)
countCutletMemo remGaps slots cumulative hitBoundary required memo
  | slots == 0 =
      let ok = remGaps == 0 && maybe True (const hitBoundary) required
      in (if ok then 1 else 0, memo)
  | remGaps < slots = (0, memo)
  | Just value <- Map.lookup (remGaps, slots, cumulative, hitBoundary) memo = (value, memo)
  | otherwise =
      let maxX = remGaps - (slots - 1)
          step (acc, currentMemo) x =
            let nextCumulative = cumulative + x
                decision = case required of
                  Nothing -> Just hitBoundary
                  Just boundary
                    | hitBoundary -> Just True
                    | nextCumulative == boundary -> Just True
                    | nextCumulative > boundary -> Nothing
                    | otherwise -> Just False
            in case decision of
                 Nothing -> (acc, currentMemo)
                 Just nextHit ->
                   let (v, nextMemo) = countCutletMemo (remGaps - x) (slots - 1) nextCumulative nextHit required currentMemo
                   in (acc + v, nextMemo)
          (totalCount, finalMemo) = foldl' step (0, memo) [1..maxX]
          key = (remGaps, slots, cumulative, hitBoundary)
      in (totalCount, Map.insert key totalCount finalMemo)

unrankCutletPartition :: Int -> Int -> Maybe Int -> Integer -> [Int]
unrankCutletPartition gaps cutlets required rank1
  | rank1 < 1 || rank1 > totalCount = error "Pořadí dělení kotlet je mimo rozsah."
  | otherwise = go gaps cutlets 0 False rank1 initialMemo
  where
    (totalCount, initialMemo) = countCutletMemo gaps cutlets 0 False required Map.empty
    go _ 0 _ _ _ _ = []
    go remGaps slots cumulative hitBoundary r memo = chooseX 1 memo
      where
        maxX = remGaps - (slots - 1)
        chooseX x currentMemo
          | x > maxX = error "Dělení kotlet se nepodařilo odrankovat."
          | otherwise =
              let nextCumulative = cumulative + x
                  decision = case required of
                    Nothing -> Just hitBoundary
                    Just boundary
                      | hitBoundary -> Just True
                      | nextCumulative == boundary -> Just True
                      | nextCumulative > boundary -> Nothing
                      | otherwise -> Just False
              in case decision of
                   Nothing -> chooseX (x + 1) currentMemo
                   Just nextHit ->
                     let (block, nextMemo) = countCutletMemo (remGaps - x) (slots - 1) nextCumulative nextHit required currentMemo
                     in if r > block
                          then chooseX (x + 1) nextMemo
                          else x : go (remGaps - x) (slots - 1) nextCumulative nextHit r nextMemo

data WeaveState = WeaveState
  { weaveRemaining :: [Int]
  , weaveOpenedUpTo :: Int
  , weaveClosedUpTo :: Int
  } deriving (Eq, Ord, Show)

initialWeaveState :: [Int] -> WeaveState
initialWeaveState lengths = WeaveState lengths 0 0

legalWeaveMove :: [Int] -> WeaveState -> Int -> Bool
legalWeaveMove original state j =
  let remaining = at1 (weaveRemaining state) j
      originalCount = at1 original j
      alreadyOpened = remaining < originalCount
      willClose = remaining == 1
  in remaining > 0
     && (alreadyOpened || j == weaveOpenedUpTo state + 1)
     && (not willClose || j == weaveClosedUpTo state + 1)

applyWeaveMove :: [Int] -> WeaveState -> Int -> WeaveState
applyWeaveMove original state j =
  let remainingBefore = at1 (weaveRemaining state) j
      opened = if remainingBefore == at1 original j then j else weaveOpenedUpTo state
      remainingAfter = remainingBefore - 1
      remainingList = replaceAt1 j remainingAfter (weaveRemaining state)
      closed = if remainingAfter == 0 then j else weaveClosedUpTo state
  in WeaveState remainingList opened closed

type WeaveMemo = Map WeaveState Integer

countWeavingsMemo :: [Int] -> WeaveState -> WeaveMemo -> (Integer, WeaveMemo)
countWeavingsMemo lengths state memo
  | all (== 0) (weaveRemaining state) = (1, memo)
  | Just value <- Map.lookup state memo = (value, memo)
  | otherwise =
      let choices = [j | j <- [1..length lengths], legalWeaveMove lengths state j]
          step (acc, currentMemo) j =
            let next = applyWeaveMove lengths state j
                (v, nextMemo) = countWeavingsMemo lengths next currentMemo
            in (acc + v, nextMemo)
          (totalCount, finalMemo) = foldl' step (0, memo) choices
      in (totalCount, Map.insert state totalCount finalMemo)

countWeavings :: [Int] -> Integer
countWeavings lengths = fst (countWeavingsMemo lengths (initialWeaveState lengths) Map.empty)

unrankWeaving :: [Int] -> Integer -> [Int]
unrankWeaving lengths rank1
  | rank1 < 1 || rank1 > totalCount = error "Pořadí proplétání měsíců je mimo rozsah."
  | otherwise = go (initialWeaveState lengths) rank1 initialMemo
  where
    (totalCount, initialMemo) = countWeavingsMemo lengths (initialWeaveState lengths) Map.empty
    totalLength = sum lengths
    go state r memo
      | sum (weaveRemaining state) == 0 = []
      | otherwise = chooseJ 1 memo
      where
        chooseJ j currentMemo
          | j > length lengths = error "Proplétání měsíců se nepodařilo odrankovat."
          | not (legalWeaveMove lengths state j) = chooseJ (j + 1) currentMemo
          | otherwise =
              let next = applyWeaveMove lengths state j
                  (block, nextMemo) = countWeavingsMemo lengths next currentMemo
              in if r > block
                   then chooseJ (j + 1) nextMemo
                   else j : go next r nextMemo
        _unusedTotalLength = totalLength

data GateState = GateState
  { gateMap :: Map Int Day
  , minKnownGateIndex :: Int
  , maxKnownGateIndex :: Int
  } deriving (Eq, Show)

initialGateState :: GateState
initialGateState = GateState (Map.singleton 0 foundationDay) 0 0

gateAt :: GateState -> Int -> Day
gateAt state idx = fromMaybe (error "Požadovaná brána ještě není vytvořena.") (Map.lookup idx (gateMap state))

positiveGateGap :: Int -> Integer
positiveGateGap n =
  let r = sauce foundationDay (foundationDay + fromIntegral n)
      stream = askBowl r 1 sealGateGap
  in 41 + chooseRank stream 922

negativeGateGap :: Int -> Integer
negativeGateGap n =
  let r = sauce foundationDay (foundationDay - fromIntegral n)
      stream = askBowl r 1 sealGateGap
  in 41 + chooseRank stream 922

ensureGateIndex :: Int -> GateState -> GateState
ensureGateIndex k state
  | k > maxKnownGateIndex state = ensurePositive (maxKnownGateIndex state + 1) state
  | k < minKnownGateIndex state = ensureNegative (minKnownGateIndex state - 1) state
  | otherwise = state
  where
    ensurePositive n current
      | n > k = current
      | otherwise =
          let previous = gateAt current (n - 1)
              value = previous + positiveGateGap n
              next = current
                { gateMap = Map.insert n value (gateMap current)
                , maxKnownGateIndex = n
                }
          in ensurePositive (n + 1) next
    ensureNegative n current
      | n < k = current
      | otherwise =
          let nextKnown = gateAt current (n + 1)
              value = nextKnown - negativeGateGap (abs n)
              next = current
                { gateMap = Map.insert n value (gateMap current)
                , minKnownGateIndex = n
                }
          in ensureNegative (n - 1) next

ensureGatesCover :: Day -> Day -> GateState -> GateState
ensureGatesCover lowDay highDay state
  | lowDay > highDay = error "Dolní mez pokrytí bran nesmí být větší než horní mez."
  | gateAt state (minKnownGateIndex state) > lowDay =
      ensureGatesCover lowDay highDay (ensureGateIndex (minKnownGateIndex state - 1) state)
  | gateAt state (maxKnownGateIndex state) < highDay =
      ensureGatesCover lowDay highDay (ensureGateIndex (maxKnownGateIndex state + 1) state)
  | otherwise = state

gateIndexAtOrBefore :: Day -> GateState -> (Int, GateState)
gateIndexAtOrBefore day state0 =
  let state = ensureGatesCover day day state0
  in (binary (minKnownGateIndex state) (maxKnownGateIndex state) state, state)
  where
    binary lo hi state
      | lo >= hi = lo
      | otherwise =
          let mid = lo + (hi - lo + 1) `div` 2
          in if gateAt state mid <= day
               then binary mid hi state
               else binary lo (mid - 1) state

exactGateIndex :: Day -> GateState -> (Maybe Int, GateState)
exactGateIndex day state0 =
  let (idx, state) = gateIndexAtOrBefore day state0
  in (if gateAt state idx == day then Just idx else Nothing, state)

data Year = Year
  { yearNumber :: Integer
  , openGateIndex :: Int
  , closeGateIndex :: Int
  , openGateDay :: Day
  , closeGateDay :: Day
  } deriving (Eq, Ord, Show)

yearLength :: GateState -> Int -> Int -> Integer
yearLength state openIdx closeIdx = gateAt state closeIdx - gateAt state openIdx

validYearPair :: GateState -> Int -> Int -> Bool
validYearPair state openIdx closeIdx =
  closeIdx - openIdx >= 6
  && let len = yearLength state openIdx closeIdx
     in yearMinDays <= len && len <= yearMaxDays

year5000 :: Day -> GateState -> (Year, GateState)
year5000 calculationDay state0 =
  let state = ensureGatesCover (calculationDay - yearMaxDays) (calculationDay + yearMaxDays) state0
      indices = [minKnownGateIndex state .. maxKnownGateIndex state]
      candidates =
        [ (i,j)
        | i <- indices
        , j <- indices
        , i < j
        , validYearPair state i j
        , gateAt state i < calculationDay
        , calculationDay <= gateAt state j
        ]
      sorted = sortBy (comparing (\(i,j) -> (yearLength state i j, gateAt state i))) candidates
      r = sauce calculationDay calculationDay
      stream = askBowl r 1 sealYear5000
      rank = chooseRank stream (fromIntegral (length sorted))
      (i,j) = sorted !! (fromInteger rank - 1)
      year = Year 5000 i j (gateAt state i) (gateAt state j)
  in (year, state)

nextYear :: Day -> Year -> GateState -> (Year, GateState)
nextYear calculationDay known state0 =
  let openIdx = closeGateIndex known
      (candidates, state) = collect (openIdx + 1) state0 []
      sorted = sortBy (comparing (\j -> yearLength state openIdx j)) candidates
      r = sauce calculationDay (gateAt state openIdx)
      stream = askBowl r 1 sealNextYear
      rank = chooseRank stream (fromIntegral (length sorted))
      closeIdx = sorted !! (fromInteger rank - 1)
      year = Year (yearNumber known + 1) openIdx closeIdx (gateAt state openIdx) (gateAt state closeIdx)
  in (year, state)
  where
    openIdx = closeGateIndex known
    collect j current acc =
      let nextState = ensureGateIndex j current
          len = yearLength nextState openIdx j
      in if len > yearMaxDays
           then (acc, nextState)
           else collect (j + 1) nextState (if validYearPair nextState openIdx j then acc ++ [j] else acc)

previousYear :: Day -> Year -> GateState -> (Year, GateState)
previousYear calculationDay known state0 =
  let closeIdx = openGateIndex known
      (candidates, state) = collect (closeIdx - 1) state0 []
      sorted = sortBy (comparing (\i -> yearLength state i closeIdx)) candidates
      r = sauce calculationDay (gateAt state closeIdx)
      stream = askBowl r 1 sealPreviousYear
      rank = chooseRank stream (fromIntegral (length sorted))
      openIdx = sorted !! (fromInteger rank - 1)
      year = Year (yearNumber known - 1) openIdx closeIdx (gateAt state openIdx) (gateAt state closeIdx)
  in (year, state)
  where
    closeIdx = openGateIndex known
    collect i current acc =
      let nextState = ensureGateIndex i current
          len = yearLength nextState i closeIdx
      in if len > yearMaxDays
           then (acc, nextState)
           else collect (i - 1) nextState (if validYearPair nextState i closeIdx then acc ++ [i] else acc)

findTargetYear :: Day -> Day -> GateState -> (Year, GateState)
findTargetYear calculationDay targetDay state0 =
  let (anchor, state1) = year5000 calculationDay state0
  in walk anchor state1
  where
    walk year state
      | targetDay > closeGateDay year =
          let (next, nextState) = nextYear calculationDay year state
          in walk next nextState
      | targetDay <= openGateDay year =
          let (previous, nextState) = previousYear calculationDay year state
          in walk previous nextState
      | otherwise = (year, state)

data Cutlet = Cutlet
  { cutletCanonicalIndex :: Int
  , cutletOpenGateIndex :: Int
  , cutletCloseGateIndex :: Int
  , cutletFirstDay :: Day
  , cutletLastDay :: Day
  } deriving (Eq, Ord, Show)

data YearStructure = YearStructure
  { structureCutletCount :: Int
  , structureCutletPartition :: [Int]
  , structureCutletCanonicalIndices :: [Int]
  , structureCutlets :: [Cutlet]
  , structureMonthCount :: Int
  , structureMonthLengths :: [Int]
  , structureMonthWeaving :: [Int]
  , structureMonthCanonicalIndices :: [Int]
  } deriving (Eq, Ord, Show)

chooseCutletCount :: SauceResult -> Year -> Int
chooseCutletCount structureSauce year =
  let gateGaps = closeGateIndex year - openGateIndex year
      candidates = [k | k <- [minCutlets..maxCutlets], k <= gateGaps]
      stream = askBowl structureSauce 2 sealCutletCount
      rank = chooseRank stream (fromIntegral (length candidates))
  in candidates !! (fromInteger rank - 1)

chooseCutletPartition :: Day -> SauceResult -> Year -> Int -> GateState -> ([Int], GateState)
chooseCutletPartition calculationDay structureSauce year cutletCount state0 =
  let gaps = closeGateIndex year - openGateIndex year
      (maybeGate, state) = exactGateIndex calculationDay state0
      required = case maybeGate of
        Just g | openGateIndex year < g && g < closeGateIndex year -> Just (g - openGateIndex year)
        _ -> Nothing
      count = countCutletPartitions gaps cutletCount required
      stream = askBowl structureSauce 2 sealCutletPartition
      rank = chooseRank stream count
  in (unrankCutletPartition gaps cutletCount required rank, state)

chooseCutletNames :: SauceResult -> Int -> [Int]
chooseCutletNames structureSauce cutletCount =
  let n = fallingFactorial 17 cutletCount
      stream = askBowl structureSauce 5 sealCutletNames
      rank = chooseRank stream n
  in unrankDistinctIndices 17 cutletCount rank

materializeCutlets :: Year -> [Int] -> [Int] -> GateState -> [Cutlet]
materializeCutlets year partition names state = go (openGateIndex year) partition names
  where
    go _ [] [] = []
    go cursor (part:parts) (nameIdx:restNames) =
      let closeIdx = cursor + part
          current = Cutlet nameIdx cursor closeIdx (gateAt state cursor + 1) (gateAt state closeIdx)
      in current : go closeIdx parts restNames
    go _ _ _ = error "Dělení kotlet a názvy nemají stejnou délku."

chooseMonthCount :: SauceResult -> Year -> Int
chooseMonthCount structureSauce year =
  let len = closeGateDay year - openGateDay year
      low = fromInteger (ceilDiv len (fromIntegral maxMonthDays))
      high = min maxMonths (fromInteger (len `div` fromIntegral minMonthDays))
      candidates = [low..high]
      stream = askBowl structureSauce 3 sealMonthCount
      rank = chooseRank stream (fromIntegral (length candidates))
  in if low < minMonths || null candidates
       then error "Rozsah počtu měsíců porušuje normativní meze."
       else candidates !! (fromInteger rank - 1)

chooseMonthLengths :: SauceResult -> Year -> Int -> [Int]
chooseMonthLengths structureSauce year monthCount =
  let len = fromInteger (closeGateDay year - openGateDay year)
      count = countBoundedCompositions len monthCount minMonthDays maxMonthDays
      stream = askBowl structureSauce 3 sealMonthLengths
      rank = chooseRank stream count
  in unrankBoundedComposition len monthCount minMonthDays maxMonthDays rank

chooseMonthWeaving :: SauceResult -> [Int] -> [Int]
chooseMonthWeaving structureSauce lengths =
  let familyCount = countWeavings lengths
      stream = askBowl structureSauce 4 sealMonthWeaving
      rank = chooseRank stream familyCount
  in unrankWeaving lengths rank

chooseMonthNames :: SauceResult -> Int -> [Int]
chooseMonthNames structureSauce monthCount =
  let n = fallingFactorial 47 monthCount
      stream = askBowl structureSauce 5 sealMonthNames
      rank = chooseRank stream n
  in unrankDistinctIndices 47 monthCount rank

buildYearStructure :: Day -> Year -> GateState -> (YearStructure, GateState)
buildYearStructure calculationDay year state0 =
  let firstDay = openGateDay year + 1
      structureSauce = sauce calculationDay firstDay
      cutletCount = chooseCutletCount structureSauce year
      (partition, state1) = chooseCutletPartition calculationDay structureSauce year cutletCount state0
      cutletNames = chooseCutletNames structureSauce cutletCount
      cutlets = materializeCutlets year partition cutletNames state1
      monthCount = chooseMonthCount structureSauce year
      monthLengths = chooseMonthLengths structureSauce year monthCount
      monthWeaving = chooseMonthWeaving structureSauce monthLengths
      monthNames = chooseMonthNames structureSauce monthCount
  in ( YearStructure
        { structureCutletCount = cutletCount
        , structureCutletPartition = partition
        , structureCutletCanonicalIndices = cutletNames
        , structureCutlets = cutlets
        , structureMonthCount = monthCount
        , structureMonthLengths = monthLengths
        , structureMonthWeaving = monthWeaving
        , structureMonthCanonicalIndices = monthNames
        }
     , state1
     )

data CalendarFiveIds = CalendarFiveIds
  { oracleYearNumber :: Integer
  , oracleCutletCanonicalIndex :: Int
  , oracleDayInCutlet :: Integer
  , oracleMonthCanonicalIndex :: Int
  , oracleDayInMonth :: Integer
  } deriving (Eq, Ord, Show)

data CalendarFiveText = CalendarFiveText
  { oracleTextYearNumber :: Integer
  , oracleCutletName :: String
  , oracleTextDayInCutlet :: Integer
  , oracleMonthName :: String
  , oracleTextDayInMonth :: Integer
  } deriving (Eq, Ord, Show)

calendarDateOracleIds :: Day -> Day -> CalendarFiveIds
calendarDateOracleIds calculationDay targetDay =
  let (year, gateState) = findTargetYear calculationDay targetDay initialGateState
      (structure, _) = buildYearStructure calculationDay year gateState
      chosenCutlet = fromMaybe (error "Cílový den neleží v žádné kotletě.")
        (findCutlet targetDay (structureCutlets structure))
      dayInCutlet = targetDay - cutletFirstDay chosenCutlet + 1
      yearOffset0 = fromInteger (targetDay - (openGateDay year + 1))
      monthId = structureMonthWeaving structure !! yearOffset0
      monthCanonical = at1 (structureMonthCanonicalIndices structure) monthId
      dayInMonth = fromIntegral
        (length (filter (== monthId) (take (yearOffset0 + 1) (structureMonthWeaving structure))))
  in CalendarFiveIds
      { oracleYearNumber = yearNumber year
      , oracleCutletCanonicalIndex = cutletCanonicalIndex chosenCutlet
      , oracleDayInCutlet = dayInCutlet
      , oracleMonthCanonicalIndex = monthCanonical
      , oracleDayInMonth = dayInMonth
      }
  where
    findCutlet day = go
      where
        go [] = Nothing
        go (c:cs)
          | cutletFirstDay c <= day && day <= cutletLastDay c = Just c
          | otherwise = go cs

calendarDateOracle :: Day -> Day -> CalendarFiveText
calendarDateOracle calculationDay targetDay =
  let ids = calendarDateOracleIds calculationDay targetDay
      cutletName = fromMaybe (error "Chybí český název kotlety.") (cutletNameByIndex (oracleCutletCanonicalIndex ids))
      monthName = fromMaybe (error "Chybí český název měsíce.") (monthNameByIndex (oracleMonthCanonicalIndex ids))
  in CalendarFiveText
      { oracleTextYearNumber = oracleYearNumber ids
      , oracleCutletName = cutletName
      , oracleTextDayInCutlet = oracleDayInCutlet ids
      , oracleMonthName = monthName
      , oracleTextDayInMonth = oracleDayInMonth ids
      }
