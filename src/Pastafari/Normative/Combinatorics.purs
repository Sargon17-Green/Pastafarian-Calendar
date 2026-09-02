module Pastafari.Normative.Combinatorics
  ( fallingFactorial
  , unrankDistinctIndices
  , BoundedFamily
  , boundedCompositionFamily
  , CutletPartitionFamily
  , cutletPartitionFamily
  , countWeavings
  , unrankWeaving
  ) where

import Prelude

import Data.Array as Array
import Data.Foldable (foldl)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String as String
import Data.Tuple (Tuple(..))
import Pastafari.BigInteger (Big)
import Pastafari.BigInteger as B

fallingFactorial :: Int -> Int -> Big
fallingFactorial n k = go 0 B.one
  where
  go j acc
    | j >= k = acc
    | otherwise = go (j + 1) (B.mul acc (B.fromInt (n - j)))

removeAt :: forall a. Int -> Array a -> Array a
removeAt i xs = fromMaybe xs (Array.deleteAt i xs)

unrankDistinctIndices :: Int -> Int -> Big -> Array Int
unrankDistinctIndices masterSize k rank1 = go (Array.range 1 masterSize) 1 rank1 []
  where
  go remaining position rank out
    | position > k = out
    | otherwise =
        let suffixLength = k - position
            block = fallingFactorial (Array.length remaining - 1) suffixLength
            picked = chooseCandidate remaining 0 rank block
        in go (removeAt picked.index remaining) (position + 1) picked.rank (Array.snoc out picked.value)

  chooseCandidate remaining index rank block =
    let value = fromMaybe 1 (Array.index remaining index)
    in if B.compareBig rank block == GT then
         chooseCandidate remaining (index + 1) (B.sub rank block) block
       else { index, value, rank }

type BoundedFamily =
  { count :: Big
  , unrank1 :: Big -> Array Int
  }

type CompMemo = Map.Map (Tuple Int Int) Big

countBoundedMemo :: Int -> Int -> Int -> Int -> CompMemo -> { value :: Big, memo :: CompMemo }
countBoundedMemo rem slots lo hi memo
  | slots == 0 = { value: if rem == 0 then B.one else B.zero, memo }
  | rem < slots * lo || rem > slots * hi = { value: B.zero, memo }
  | otherwise =
      let key = Tuple rem slots
      in case Map.lookup key memo of
           Just v -> { value: v, memo }
           Nothing ->
             let folded = foldX lo B.zero memo
                 memo2 = Map.insert key folded.total folded.memo
             in { value: folded.total, memo: memo2 }
  where
  foldX x total currentMemo
    | x > hi = { total, memo: currentMemo }
    | otherwise =
        let child = countBoundedMemo (rem - x) (slots - 1) lo hi currentMemo
        in foldX (x + 1) (B.add total child.value) child.memo

unrankBounded :: Int -> Int -> Int -> Int -> Big -> Array Int
unrankBounded total slots lo hi rank1 = go total slots rank1 Map.empty []
  where
  go rem left rank memo out
    | left == 0 = out
    | otherwise =
        let picked = choose lo rem left rank memo
        in go (rem - picked.x) (left - 1) picked.rank picked.memo (Array.snoc out picked.x)

  choose x rem left rank memo
    | x > hi = { x: hi, rank, memo }
    | otherwise =
        let child = countBoundedMemo (rem - x) (left - 1) lo hi memo
        in if B.compareBig rank child.value == GT then
             choose (x + 1) rem left (B.sub rank child.value) child.memo
           else { x, rank, memo: child.memo }

boundedCompositionFamily :: Int -> Int -> Int -> Int -> BoundedFamily
boundedCompositionFamily total slots lo hi =
  let c = countBoundedMemo total slots lo hi Map.empty
  in { count: c.value, unrank1: unrankBounded total slots lo hi }

type CutletPartitionFamily =
  { count :: Big
  , unrank1 :: Big -> Array Int
  }

type CutletKey = Tuple Int (Tuple Int (Tuple Int Boolean))
type CutletMemo = Map.Map CutletKey Big

countCutletMemo :: Int -> Int -> Int -> Boolean -> Maybe Int -> CutletMemo -> { value :: Big, memo :: CutletMemo }
countCutletMemo rem slots cumulative hit required memo
  | slots == 0 =
      { value:
          if rem /= 0 then B.zero
          else case required of
            Nothing -> B.one
            Just _ -> if hit then B.one else B.zero
      , memo
      }
  | rem < slots = { value: B.zero, memo }
  | otherwise =
      let key = Tuple rem (Tuple slots (Tuple cumulative hit))
      in case Map.lookup key memo of
           Just v -> { value: v, memo }
           Nothing ->
             let folded = foldX 1 B.zero memo
                 memo2 = Map.insert key folded.total folded.memo
             in { value: folded.total, memo: memo2 }
  where
  maxX = rem - (slots - 1)

  foldX x total currentMemo
    | x > maxX = { total, memo: currentMemo }
    | otherwise =
        let nextCumulative = cumulative + x
            transition = boundaryTransition nextCumulative hit required
        in if not transition.allowed then foldX (x + 1) total currentMemo
           else
             let child = countCutletMemo (rem - x) (slots - 1) nextCumulative transition.hit required currentMemo
             in foldX (x + 1) (B.add total child.value) child.memo

boundaryTransition :: Int -> Boolean -> Maybe Int -> { allowed :: Boolean, hit :: Boolean }
boundaryTransition cumulative hit required =
  case required of
    Nothing -> { allowed: true, hit }
    Just boundary ->
      if hit then { allowed: true, hit: true }
      else if cumulative == boundary then { allowed: true, hit: true }
      else if cumulative > boundary then { allowed: false, hit: false }
      else { allowed: true, hit: false }

unrankCutlet :: Int -> Int -> Maybe Int -> Big -> Array Int
unrankCutlet total slots required rank1 = go total slots 0 false rank1 Map.empty []
  where
  go rem left cumulative hit rank memo out
    | left == 0 = out
    | otherwise =
        let picked = choose 1 rem left cumulative hit rank memo
        in go (rem - picked.x) (left - 1) (cumulative + picked.x) picked.hit picked.rank picked.memo (Array.snoc out picked.x)

  choose x rem left cumulative hit rank memo =
    let maxX = rem - (left - 1)
    in if x > maxX then { x: maxX, hit, rank, memo }
       else
         let nextCumulative = cumulative + x
             transition = boundaryTransition nextCumulative hit required
         in if not transition.allowed then choose (x + 1) rem left cumulative hit rank memo
            else
              let child = countCutletMemo (rem - x) (left - 1) nextCumulative transition.hit required memo
              in if B.compareBig rank child.value == GT then
                   choose (x + 1) rem left cumulative hit (B.sub rank child.value) child.memo
                 else { x, hit: transition.hit, rank, memo: child.memo }

cutletPartitionFamily :: Int -> Int -> Maybe Int -> CutletPartitionFamily
cutletPartitionFamily total slots required =
  let c = countCutletMemo total slots 0 false required Map.empty
  in { count: c.value, unrank1: unrankCutlet total slots required }

type WeaveState =
  { remaining :: Array Int
  , openedUpTo :: Int
  , closedUpTo :: Int
  }

type WeaveMemo = Map.Map String Big

weaveKey :: WeaveState -> String
weaveKey state =
  show state.openedUpTo <> ":" <> show state.closedUpTo <> ":" <> String.joinWith "," (map show state.remaining)

remainingAt :: WeaveState -> Int -> Int
remainingAt state j = fromMaybe 0 (Array.index state.remaining (j - 1))

originalAt :: Array Int -> Int -> Int
originalAt lengths j = fromMaybe 0 (Array.index lengths (j - 1))

legalMove :: Array Int -> WeaveState -> Int -> Boolean
legalMove lengths state j =
  let rem = remainingAt state j
      original = originalAt lengths j
      alreadyOpened = rem < original
      willClose = rem == 1
      openingOkay = alreadyOpened || j == state.openedUpTo + 1
      closingOkay = not willClose || j == state.closedUpTo + 1
  in rem > 0 && openingOkay && closingOkay

applyMove :: Array Int -> WeaveState -> Int -> WeaveState
applyMove lengths state j =
  let rem = remainingAt state j
      original = originalAt lengths j
      opened = if rem == original then j else state.openedUpTo
      nextRemaining = fromMaybe state.remaining (Array.updateAt (j - 1) (rem - 1) state.remaining)
      closed = if rem == 1 then j else state.closedUpTo
  in { remaining: nextRemaining, openedUpTo: opened, closedUpTo: closed }

allZero :: Array Int -> Boolean
allZero = foldl (\acc x -> acc && x == 0) true

countWeavingsMemo :: Array Int -> WeaveState -> WeaveMemo -> { value :: Big, memo :: WeaveMemo }
countWeavingsMemo lengths state memo
  | allZero state.remaining = { value: B.one, memo }
  | otherwise =
      let key = weaveKey state
      in case Map.lookup key memo of
           Just v -> { value: v, memo }
           Nothing ->
             let folded = foldJ 1 B.zero memo
                 memo2 = Map.insert key folded.total folded.memo
             in { value: folded.total, memo: memo2 }
  where
  m = Array.length lengths
  foldJ j total currentMemo
    | j > m = { total, memo: currentMemo }
    | not (legalMove lengths state j) = foldJ (j + 1) total currentMemo
    | otherwise =
        let next = applyMove lengths state j
            child = countWeavingsMemo lengths next currentMemo
        in foldJ (j + 1) (B.add total child.value) child.memo

initialWeaveState :: Array Int -> WeaveState
initialWeaveState lengths = { remaining: lengths, openedUpTo: 0, closedUpTo: 0 }

countWeavings :: Array Int -> Big
countWeavings lengths = (countWeavingsMemo lengths (initialWeaveState lengths) Map.empty).value

unrankWeaving :: Array Int -> Big -> Array Int
unrankWeaving lengths rank1 = go (initialWeaveState lengths) rank1 Map.empty []
  where
  totalLength = foldl (+) 0 lengths
  m = Array.length lengths

  go state rank memo out
    | Array.length out >= totalLength = out
    | otherwise =
        let picked = choose 1 state rank memo
        in go picked.state picked.rank picked.memo (Array.snoc out picked.j)

  choose j state rank memo
    | j > m = { j: m, state, rank, memo }
    | not (legalMove lengths state j) = choose (j + 1) state rank memo
    | otherwise =
        let next = applyMove lengths state j
            child = countWeavingsMemo lengths next memo
        in if B.compareBig rank child.value == GT then
             choose (j + 1) state (B.sub rank child.value) child.memo
           else { j, state: next, rank, memo: child.memo }
