module Pastafari.BigInteger
  ( Big
  , zero
  , one
  , fromInt
  , toIntExact
  , add
  , sub
  , mul
  , negateBig
  , absBig
  , compareBig
  , floorDiv
  , regularMod
  , divModEuclidean
  , pow
  , isZero
  ) where

import Prelude hiding (add, sub, mul)

import Data.Array as Array
import Data.Foldable (foldl)
import Data.Maybe (Maybe(..))

base :: Int
base = 10000

data Sign = Negative | ZeroSign | Positive

derive instance eqSign :: Eq Sign

newtype Big = Big { sign :: Sign, mag :: Array Int }

instance eqBig :: Eq Big where
  eq a b = compareBig a b == EQ

instance ordBig :: Ord Big where
  compare = compareBig

zero :: Big
zero = Big { sign: ZeroSign, mag: [] }

one :: Big
one = fromInt 1

isZero :: Big -> Boolean
isZero (Big x) = x.sign == ZeroSign

normalizeMag :: Array Int -> Array Int
normalizeMag xs = Array.reverse (Array.dropWhile (_ == 0) (Array.reverse xs))

mkBig :: Sign -> Array Int -> Big
mkBig s raw =
  let m = normalizeMag raw
  in if Array.null m then zero else Big { sign: s, mag: m }

fromInt :: Int -> Big
fromInt n
  | n == 0 = zero
  | n > 0 = mkBig Positive (digits n)
  | otherwise = mkBig Negative (digits (-n))
  where
  digits :: Int -> Array Int
  digits x
    | x == 0 = []
    | otherwise = Array.cons (x `mod` base) (digits (div x base))

compareMag :: Array Int -> Array Int -> Ordering
compareMag a b =
  case compare (Array.length a) (Array.length b) of
    EQ -> compare (Array.reverse a) (Array.reverse b)
    other -> other

compareBig :: Big -> Big -> Ordering
compareBig (Big a) (Big b) =
  case a.sign, b.sign of
    Negative, Negative -> invert (compareMag a.mag b.mag)
    Negative, _ -> LT
    ZeroSign, Negative -> GT
    ZeroSign, ZeroSign -> EQ
    ZeroSign, Positive -> LT
    Positive, Positive -> compareMag a.mag b.mag
    Positive, _ -> GT
  where
  invert LT = GT
  invert GT = LT
  invert EQ = EQ

magAdd :: Array Int -> Array Int -> Array Int
magAdd a b = go a b 0
  where
  go xs ys carry =
    case Array.uncons xs, Array.uncons ys of
      Nothing, Nothing -> if carry == 0 then [] else [ carry ]
      Just xa, Nothing -> emit xa.head 0 xa.tail [] carry
      Nothing, Just yb -> emit 0 yb.head [] yb.tail carry
      Just xa, Just yb -> emit xa.head yb.head xa.tail yb.tail carry

  emit x y xt yt carry =
    let s = x + y + carry
        d = s `mod` base
        c = div s base
    in Array.cons d (go xt yt c)

magSub :: Array Int -> Array Int -> Array Int
magSub a b = normalizeMag (go a b 0)
  where
  go xs ys borrow =
    case Array.uncons xs, Array.uncons ys of
      Nothing, _ -> []
      Just xa, Nothing -> emit xa.head 0 xa.tail [] borrow
      Just xa, Just yb -> emit xa.head yb.head xa.tail yb.tail borrow

  emit x y xt yt borrow =
    let raw = x - y - borrow
        d = if raw < 0 then raw + base else raw
        nextBorrow = if raw < 0 then 1 else 0
    in Array.cons d (go xt yt nextBorrow)

add :: Big -> Big -> Big
add (Big a) (Big b) =
  case a.sign, b.sign of
    ZeroSign, _ -> Big b
    _, ZeroSign -> Big a
    Positive, Positive -> mkBig Positive (magAdd a.mag b.mag)
    Negative, Negative -> mkBig Negative (magAdd a.mag b.mag)
    Positive, Negative -> mixed Positive Negative a.mag b.mag
    Negative, Positive -> mixed Negative Positive a.mag b.mag
  where
  mixed sa sb ma mb =
    case compareMag ma mb of
      EQ -> zero
      GT -> mkBig sa (magSub ma mb)
      LT -> mkBig sb (magSub mb ma)

negateBig :: Big -> Big
negateBig (Big a) =
  case a.sign of
    ZeroSign -> zero
    Positive -> Big { sign: Negative, mag: a.mag }
    Negative -> Big { sign: Positive, mag: a.mag }

sub :: Big -> Big -> Big
sub a b = add a (negateBig b)

absBig :: Big -> Big
absBig (Big a) =
  case a.sign of
    Negative -> Big { sign: Positive, mag: a.mag }
    _ -> Big a

mulSmallMag :: Array Int -> Int -> Array Int
mulSmallMag a k
  | k == 0 = []
  | otherwise = normalizeMag (go a 0)
  where
  go xs carry =
    case Array.uncons xs of
      Nothing -> carryDigits carry
      Just x ->
        let p = x.head * k + carry
            d = p `mod` base
            c = div p base
        in Array.cons d (go x.tail c)

  carryDigits n
    | n == 0 = []
    | otherwise = Array.cons (n `mod` base) (carryDigits (div n base))

shiftMag :: Int -> Array Int -> Array Int
shiftMag n m = Array.replicate n 0 <> m

magMul :: Array Int -> Array Int -> Array Int
magMul a b = go b 0 []
  where
  go ys shift acc =
    case Array.uncons ys of
      Nothing -> normalizeMag acc
      Just y ->
        let partial = shiftMag shift (mulSmallMag a y.head)
        in go y.tail (shift + 1) (magAdd acc partial)

mul :: Big -> Big -> Big
mul (Big a) (Big b)
  | a.sign == ZeroSign || b.sign == ZeroSign = zero
  | otherwise =
      let s = if a.sign == b.sign then Positive else Negative
      in mkBig s (magMul a.mag b.mag)

findDigit :: Array Int -> Array Int -> Int
findDigit divisor remainder = search 0 (base - 1)
  where
  search lo hi
    | lo >= hi = lo
    | otherwise =
        let mid = lo + (div (hi - lo + 1) 2)
            p = mulSmallMag divisor mid
        in case compareMag p remainder of
             GT -> search lo (mid - 1)
             _ -> search mid hi

magDivMod :: Array Int -> Array Int -> Maybe { q :: Array Int, r :: Array Int }
magDivMod numerator divisor
  | Array.null divisor = Nothing
  | compareMag numerator divisor == LT = Just { q: [], r: numerator }
  | otherwise = Just (finish (go (Array.reverse numerator) [] []))
  where
  go digits remMag qBigEndian =
    case Array.uncons digits of
      Nothing -> { qbe: qBigEndian, rmag: normalizeMag remMag }
      Just d ->
        let rem2 = normalizeMag (Array.cons d.head remMag)
            qd = findDigit divisor rem2
            rem3 = if qd == 0 then rem2 else magSub rem2 (mulSmallMag divisor qd)
        in go d.tail rem3 (Array.snoc qBigEndian qd)

  finish x = { q: normalizeMag (Array.reverse x.qbe), r: x.rmag }

incMag :: Array Int -> Array Int
incMag m = magAdd m [ 1 ]

divModEuclidean :: Big -> Big -> Maybe { q :: Big, r :: Big }
divModEuclidean (Big a) (Big b)
  | b.sign /= Positive = Nothing
  | a.sign == ZeroSign = Just { q: zero, r: zero }
  | otherwise = do
      raw <- magDivMod a.mag b.mag
      case a.sign of
        Positive -> pure { q: mkBig Positive raw.q, r: mkBig Positive raw.r }
        Negative ->
          if Array.null raw.r then
            pure { q: mkBig Negative raw.q, r: zero }
          else
            pure
              { q: mkBig Negative (incMag raw.q)
              , r: mkBig Positive (magSub b.mag raw.r)
              }
        ZeroSign -> pure { q: zero, r: zero }

floorDiv :: Big -> Big -> Maybe Big
floorDiv a b = _.q <$> divModEuclidean a b

regularMod :: Big -> Big -> Maybe Big
regularMod a b = _.r <$> divModEuclidean a b

pow :: Big -> Int -> Big
pow a n
  | n <= 0 = one
  | otherwise = go a n one
  where
  go baseValue exponent acc
    | exponent == 0 = acc
    | exponent `mod` 2 == 1 = go (mul baseValue baseValue) (div exponent 2) (mul acc baseValue)
    | otherwise = go (mul baseValue baseValue) (div exponent 2) acc

toIntExact :: Big -> Maybe Int
toIntExact (Big a) = do
  magnitude <- foldMChecked 0 (Array.reverse a.mag)
  case a.sign of
    ZeroSign -> pure 0
    Positive -> pure magnitude
    Negative -> pure (-magnitude)
  where
  foldMChecked acc digits =
    case Array.uncons digits of
      Nothing -> Just acc
      Just d ->
        if acc > div (2147483647 - d.head) base then Nothing
        else foldMChecked (acc * base + d.head) d.tail
