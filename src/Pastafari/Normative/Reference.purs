module Pastafari.Normative.Reference
  ( foundationDay
  , tabletsDay
  , modulusM
  , save
  , dayCount
  , WorkCounts
  , workCounts
  , Stone
  , buildStones
  , buildHiddenDrops
  , buildVisibleDrops
  , bowlOrderFromDrop
  , SauceResult
  , sauce
  , AnswerStream
  , askBowl
  , answerAt
  , chooseRank
  ) where

import Prelude

import Data.Array as Array
import Data.Maybe (Maybe(..), fromMaybe)
import Pastafari.BigInteger (Big)
import Pastafari.BigInteger as B

foundationDay :: Big
foundationDay = B.fromInt (-15055671)

tabletsDay :: Big
tabletsDay = B.fromInt (-278522)

modulusM :: Big
modulusM = B.sub (B.pow (B.fromInt 2) 127) B.one

save :: Big -> Big
save x =
  let r = fromMaybe B.zero (B.regularMod (B.sub x B.one) modulusM)
  in B.add B.one r

dayCount :: Big -> Big
dayCount day =
  case B.compareBig day foundationDay of
    EQ -> B.one
    GT -> B.add (B.mul (B.fromInt 2) (B.sub day foundationDay)) B.one
    LT -> B.mul (B.fromInt 2) (B.sub foundationDay day)

type WorkCounts =
  { action :: Big
  , target :: Big
  , distance :: Big
  , connection :: Big
  , direction :: Big
  }

workCounts :: Big -> Big -> WorkCounts
workCounts calculationDay targetDay =
  let c = dayCount calculationDay
      t = dayCount targetDay
      d = B.add (B.absBig (B.sub targetDay calculationDay)) B.one
      connection = B.add c t
      direction = case B.compareBig targetDay calculationDay of
        LT -> B.fromInt 1
        EQ -> B.fromInt 2
        GT -> B.fromInt 3
  in { action: c, target: t, distance: d, connection, direction }

type Stone =
  { w :: Big
  , b :: Big
  , s :: Big
  , m :: Big
  , r :: Big
  }

initialStone :: Stone
initialStone =
  { w: B.fromInt 17
  , b: B.fromInt 29
  , s: B.fromInt 43
  , m: B.fromInt 71
  , r: B.fromInt 101
  }

nextStone :: Int -> Stone -> Stone
nextStone i old =
  { w: save (B.add (B.add (B.mul old.w old.w) (B.mul (B.fromInt 3) old.b)) (B.fromInt i))
  , b: save (B.add (B.add (B.mul old.b old.b) (B.mul (B.fromInt 5) old.s)) old.w)
  , s: save (B.add (B.add (B.mul old.s old.s) (B.mul (B.fromInt 7) old.m)) old.b)
  , m: save (B.add (B.add (B.mul old.m old.m) (B.mul (B.fromInt 11) old.r)) old.s)
  , r: save (B.add (B.add (B.mul old.r old.r) (B.mul (B.fromInt 13) old.w)) old.m)
  }

buildStones :: Array Stone
buildStones = go 2 initialStone [ initialStone ]
  where
  go i previous out
    | i > 46 = out
    | otherwise =
        let n = nextStone i previous
        in go (i + 1) n (Array.snoc out n)

at1 :: forall a. Array a -> Int -> Maybe a
at1 xs i = Array.index xs (i - 1)

mustAt1 :: forall a. a -> Array a -> Int -> a
mustAt1 fallback xs i = fromMaybe fallback (at1 xs i)

stoneValue :: Stone -> Int -> Big
stoneValue x kind = case kind of
  1 -> x.w
  2 -> x.b
  3 -> x.s
  4 -> x.m
  _ -> x.r

hiddenCoefficients :: Array { a :: Int, b :: Int, c :: Int, d :: Int }
hiddenCoefficients =
  [ { a: 3, b: 4, c: 6, d: 8 }
  , { a: 5, b: 7, c: 10, d: 12 }
  , { a: 7, b: 10, c: 14, d: 16 }
  , { a: 9, b: 13, c: 18, d: 20 }
  , { a: 11, b: 16, c: 22, d: 24 }
  , { a: 13, b: 19, c: 26, d: 28 }
  , { a: 15, b: 22, c: 30, d: 32 }
  ]

hiddenGrindKinds :: Array Int
hiddenGrindKinds = [ 1, 2, 3, 4, 5, 1, 2 ]

sumStone :: Stone -> Big
sumStone st = B.add st.w (B.add st.b (B.add st.s (B.add st.m st.r)))

buildOneHidden :: Int -> WorkCounts -> Array Stone -> Big
buildOneHidden k counts stones =
  let coeff = mustAt1 { a: 0, b: 0, c: 0, d: 0 } hiddenCoefficients k
      st = mustAt1 initialStone stones k
      x0 = save
        ( B.add counts.action
        ( B.add (B.mul (B.fromInt coeff.a) counts.target)
        ( B.add (B.mul (B.fromInt coeff.b) counts.distance)
        ( B.add (B.mul (B.fromInt coeff.c) counts.connection)
        ( B.add (B.mul (B.fromInt coeff.d) counts.direction) (sumStone st))))))
  in grind 1 x0 st
  where
  grind g x st
    | g > 7 = x
    | otherwise =
        let kind = mustAt1 1 hiddenGrindKinds g
            y = save
              ( B.add (B.mul x x)
              ( B.add (B.mul (B.fromInt 3) x)
              ( B.add (stoneValue st kind) (B.fromInt g))))
        in grind (g + 1) y st

buildHiddenDrops :: WorkCounts -> Array Stone -> Array Big
buildHiddenDrops counts stones = map (\k -> buildOneHidden k counts stones) (Array.range 1 7)

type Grind = { a :: Int, b :: Int, c :: Int, d :: Int, kind :: Int }

visibleGrinds :: Array Grind
visibleGrinds =
  [ { a: 3, b: 5, c: 7, d: 11, kind: 1 }
  , { a: 5, b: 7, c: 11, d: 13, kind: 2 }
  , { a: 7, b: 11, c: 13, d: 17, kind: 3 }
  , { a: 11, b: 13, c: 17, d: 19, kind: 4 }
  , { a: 13, b: 17, c: 19, d: 23, kind: 5 }
  , { a: 17, b: 19, c: 23, d: 29, kind: 1 }
  , { a: 19, b: 23, c: 29, d: 31, kind: 2 }
  , { a: 23, b: 29, c: 31, d: 37, kind: 3 }
  , { a: 29, b: 31, c: 37, d: 41, kind: 4 }
  , { a: 31, b: 37, c: 41, d: 43, kind: 5 }
  , { a: 37, b: 41, c: 43, d: 47, kind: 1 }
  ]

priorValue :: Array Big -> Array Big -> Int -> Int -> Big
priorValue visible hidden i back =
  let slot = i - back
  in if slot >= 1 then mustAt1 B.zero visible slot
     else mustAt1 B.zero hidden (1 - slot)

buildOneVisible :: Int -> WorkCounts -> Array Stone -> Array Big -> Array Big -> Big
buildOneVisible i counts stones hidden visible =
  let st = mustAt1 initialStone stones i
      p1 = priorValue visible hidden i 1
      p3 = priorValue visible hidden i 3
      p7 = priorValue visible hidden i 7
      x0 = save
        ( B.add (B.mul st.w counts.action)
        ( B.add (B.mul st.b counts.target)
        ( B.add (B.mul st.s counts.distance)
        ( B.add (B.mul st.m counts.connection)
        ( B.add (B.mul st.r counts.direction)
        ( B.add p1
        ( B.add (B.mul (B.fromInt 3) p3)
        ( B.add (B.mul (B.fromInt 5) p7) (B.fromInt i))))))))))
  in grind 1 x0 st p1 p3 p7
  where
  grind g x st p1 p3 p7
    | g > 11 = x
    | otherwise =
        let row = mustAt1 { a: 0, b: 0, c: 0, d: 0, kind: 1 } visibleGrinds g
            y = save
              ( B.add (B.mul x x)
              ( B.add (B.mul (B.fromInt row.a) x)
              ( B.add (B.mul (B.fromInt row.b) p1)
              ( B.add (B.mul (B.fromInt row.c) p3)
              ( B.add (B.mul (B.fromInt row.d) p7) (stoneValue st row.kind))))))
        in grind (g + 1) y st p1 p3 p7

buildVisibleDrops :: WorkCounts -> Array Stone -> Array Big -> Array Big
buildVisibleDrops counts stones hidden = go 1 []
  where
  go i visible
    | i > 46 = visible
    | otherwise =
        let d = buildOneVisible i counts stones hidden visible
        in go (i + 1) (Array.snoc visible d)

factorialInt :: Int -> Int
factorialInt n = go n 1
  where
  go k acc
    | k <= 1 = acc
    | otherwise = go (k - 1) (acc * k)

removeAtInt :: forall a. Int -> Array a -> Array a
removeAtInt i xs = fromMaybe xs (Array.deleteAt i xs)

permutationUnrank1 :: Int -> Array Int -> Array Int
permutationUnrank1 rank1 items = go (rank1 - 1) items []
  where
  go rank0 remaining out
    | Array.null remaining = out
    | otherwise =
        let slotsLeft = Array.length remaining
            block = factorialInt (slotsLeft - 1)
            q = if block == 0 then 0 else div rank0 block
            nextRank = if block == 0 then 0 else rank0 `mod` block
            picked = fromMaybe 1 (Array.index remaining q)
            nextRemaining = removeAtInt q remaining
        in go nextRank nextRemaining (Array.snoc out picked)

bowlOrderFromDrop :: Big -> Array Int
bowlOrderFromDrop dropValue =
  let r = fromMaybe B.zero (B.regularMod (B.sub dropValue B.one) (B.fromInt 720))
      rank = fromMaybe 0 (B.toIntExact r) + 1
  in permutationUnrank1 rank [ 1, 2, 3, 4, 5, 6 ]

wrap1Int :: Int -> Int -> Int
wrap1Int position size = ((position - 1) `mod` size) + 1

getBowl :: Array Big -> Int -> Big
getBowl bowls i = mustAt1 B.zero bowls i

setBowl :: Array Big -> Int -> Big -> Array Big
setBowl bowls i value = fromMaybe bowls (Array.updateAt (i - 1) value bowls)

initialBowls :: WorkCounts -> Array Big
initialBowls counts = map make [ 1, 2, 3, 4, 5, 6 ]
  where
  primes = [ 17, 19, 23, 29, 31, 37 ]
  make bowlId =
    let p = mustAt1 17 primes bowlId
        s = B.add counts.action
          ( B.add (B.mul counts.target (B.fromInt bowlId))
          ( B.add counts.distance
          ( B.add counts.connection
          ( B.add counts.direction (B.fromInt (p * p))))))
    in save (B.add (B.mul s s) (B.fromInt bowlId))

stoneKindByPosition :: Array Int
stoneKindByPosition = [ 1, 2, 3, 4, 5, 1 ]

applyOneDropToBowls :: Int -> Big -> Array Stone -> Array Big -> Array Int -> Array Big
applyOneDropToBowls i drop stones old order = foldPositions 1 old
  where
  st = mustAt1 initialStone stones i
  firstId = mustAt1 1 order 1
  secondId = mustAt1 2 order 2
  thirdId = mustAt1 3 order 3
  pours =
    [ save (B.add (B.mul drop drop) (B.add (B.mul st.w (getBowl old firstId)) (B.fromInt (3 * i))))
    , save (B.add (B.mul drop drop) (B.add (B.mul st.b (getBowl old secondId)) (B.fromInt (5 * i))))
    , save (B.add (B.mul drop drop) (B.add (B.mul st.s (getBowl old thirdId)) (B.fromInt (7 * i))))
    , B.zero, B.zero, B.zero
    ]

  foldPositions position pending
    | position > 6 = pending
    | otherwise =
        let bowlId = mustAt1 1 order position
            prevId = mustAt1 1 order (wrap1Int (position - 1) 6)
            nextId = mustAt1 1 order (wrap1Int (position + 1) 6)
            kind = mustAt1 1 stoneKindByPosition position
            pour = mustAt1 B.zero pours position
            s = B.add (getBowl old bowlId)
              ( B.add (B.mul (B.fromInt 2) (getBowl old prevId))
              ( B.add (B.mul (B.fromInt 3) (getBowl old nextId))
              ( B.add pour
              ( B.add drop (stoneValue st kind)))))
            nextValue = save
              ( B.add (B.mul s s)
              ( B.add (B.mul (B.fromInt 5) (B.mul (getBowl old prevId) (getBowl old nextId)))
                      (B.fromInt (i * position))))
        in foldPositions (position + 1) (setBowl pending bowlId nextValue)

type DropBowlResult = { bowls :: Array Big, orderAt46 :: Array Int }

applyVisibleDropsToBowls :: Array Big -> Array Big -> Array Stone -> DropBowlResult
applyVisibleDropsToBowls initial visible stones = go 1 initial []
  where
  go i bowls orderAt46
    | i > 46 = { bowls, orderAt46 }
    | otherwise =
        let d = mustAt1 B.zero visible i
            order = bowlOrderFromDrop d
            next = applyOneDropToBowls i d stones bowls order
            latch = if i == 46 then order else orderAt46
        in go (i + 1) next latch

postStir12 :: Array Big -> Array Big
postStir12 bowls0 = go 1 bowls0
  where
  go stir bowls
    | stir > 12 = bowls
    | otherwise =
        let old = bowls
            raw = foldArrayBig old
            savedSum = save (B.add raw (B.fromInt (149 * stir)))
            rankR = fromMaybe B.zero (B.regularMod (B.sub savedSum B.one) (B.fromInt 720))
            rank = fromMaybe 0 (B.toIntExact rankR) + 1
            order = permutationUnrank1 rank [ 1, 2, 3, 4, 5, 6 ]
            pending = postPositions stir savedSum old order 1 old
        in go (stir + 1) pending

  postPositions stir savedSum old order position pending
    | position > 6 = pending
    | otherwise =
        let bowlId = mustAt1 1 order position
            prevId = mustAt1 1 order (wrap1Int (position - 1) 6)
            nextId = mustAt1 1 order (wrap1Int (position + 1) 6)
            s = B.add (getBowl old bowlId)
              ( B.add (B.mul (B.fromInt 3) (getBowl old prevId))
              ( B.add (B.mul (B.fromInt 5) (getBowl old nextId))
              ( B.add savedSum
              ( B.add (B.fromInt stir) (B.fromInt (position * position))))))
            value = save (B.add (B.mul s s) (B.mul (B.fromInt 7) (B.mul (getBowl old prevId) (getBowl old nextId))))
        in postPositions stir savedSum old order (position + 1) (setBowl pending bowlId value)

  foldArrayBig xs = case Array.uncons xs of
    Nothing -> B.zero
    Just x -> B.add x.head (foldArrayBig x.tail)

type SauceResult = { bowls :: Array Big, orderAtDrop46 :: Array Int }

sauce :: Big -> Big -> SauceResult
sauce calculationDay targetDay =
  let counts = workCounts calculationDay targetDay
      stones = buildStones
      hidden = buildHiddenDrops counts stones
      visible = buildVisibleDrops counts stones hidden
      initial = initialBowls counts
      afterDrops = applyVisibleDropsToBowls initial visible stones
      finalBowls = postStir12 afterDrops.bowls
  in { bowls: finalBowls, orderAtDrop46: afterDrops.orderAt46 }

type AnswerStream = { first :: Big, directionStep :: Big }

indexOfInt :: Int -> Array Int -> Int
indexOfInt wanted xs = fromMaybe 0 (Array.findIndex (_ == wanted) xs)

askBowl :: SauceResult -> Int -> Int -> AnswerStream
askBowl result queriedBowlId seal =
  let pos0 = indexOfInt queriedBowlId result.orderAtDrop46
      nextId = fromMaybe queriedBowlId (Array.index result.orderAtDrop46 ((pos0 + 1) `mod` 6))
      q = getBowl result.bowls queriedBowlId
      n = getBowl result.bowls nextId
      b6 = getBowl result.bowls 6
      first = save
        ( B.add
          (B.mul (B.add q (B.fromInt (seal + 181))) (B.add q (B.fromInt (seal + 181))))
          (B.add (B.mul (B.fromInt 179) n) (B.fromInt seal)))
      firstPlus = B.add first (B.fromInt (seal + 194))
      directionNumber = save
        ( B.add (B.mul firstPlus firstPlus)
        ( B.add (B.mul (B.fromInt 193) first)
                (B.mul (B.fromInt 197) b6)))
      parity = fromMaybe B.zero (B.regularMod directionNumber (B.fromInt 2))
      step = if parity == B.one then B.one else B.fromInt (-1)
  in { first, directionStep: step }

answerAt :: AnswerStream -> Big -> Big
answerAt stream k =
  let shifted = B.add (B.sub stream.first B.one) (B.mul stream.directionStep k)
      r = fromMaybe B.zero (B.regularMod shifted modulusM)
  in B.add B.one r

chooseRankShort :: AnswerStream -> Big -> Big
chooseRankShort stream n =
  let q = fromMaybe B.zero (B.floorDiv modulusM n)
      limit = B.mul q n
  in loop B.zero limit
  where
  loop k limit =
    let x = answerAt stream k
    in if B.compareBig x limit /= GT then
         B.add B.one (fromMaybe B.zero (B.regularMod (B.sub x B.one) n))
       else loop (B.add k B.one) limit

smallestPowerCount :: Big -> { places :: Int, space :: Big }
smallestPowerCount n = go 1 modulusM
  where
  go places space =
    if B.compareBig space n /= LT then { places, space }
    else go (places + 1) (B.mul space modulusM)

chooseRankWide :: AnswerStream -> Big -> Big
chooseRankWide stream n =
  let power = smallestPowerCount n
      wide0 = digits 0 power.places B.one B.one
      q = fromMaybe B.zero (B.floorDiv power.space n)
      limit = B.mul q n
      accepted = advance wide0 limit power.space
  in B.add B.one (fromMaybe B.zero (B.regularMod (B.sub accepted B.one) n))
  where
  digits j places weight acc
    | j >= places = acc
    | otherwise =
        let digit = B.sub (answerAt stream (B.fromInt j)) B.one
        in digits (j + 1) places (B.mul weight modulusM) (B.add acc (B.mul digit weight))

  advance w limit space
    | B.compareBig w limit /= GT = w
    | otherwise =
        let next = B.add B.one (fromMaybe B.zero (B.regularMod (B.add (B.sub w B.one) stream.directionStep) space))
        in advance next limit space

chooseRank :: AnswerStream -> Big -> Big
chooseRank stream n =
  if B.compareBig n modulusM /= GT then chooseRankShort stream n
  else chooseRankWide stream n
