module Pastafari.Stage01Fixtures
  ( expectedTabletsDistance
  , expectedSecondStone
  , expectedFirstBowlOrder
  , expectedLastBowlOrder
  , expectedDistinctRankSix
  , expectedBoundedFirst
  , expectedBoundedLast
  , expectedWeavingFirst
  , expectedWeavingSecond
  ) where

import Pastafari.BigInteger (Big)
import Pastafari.BigInteger as B
import Pastafari.Normative.Reference (Stone)

expectedTabletsDistance :: Big
expectedTabletsDistance = B.fromInt 14777149

expectedSecondStone :: Stone
expectedSecondStone =
  { w: B.fromInt 378
  , b: B.fromInt 1073
  , s: B.fromInt 2375
  , m: B.fromInt 6195
  , r: B.fromInt 10493
  }

expectedFirstBowlOrder :: Array Int
expectedFirstBowlOrder = [ 1, 2, 3, 4, 5, 6 ]

expectedLastBowlOrder :: Array Int
expectedLastBowlOrder = [ 6, 5, 4, 3, 2, 1 ]

expectedDistinctRankSix :: Array Int
expectedDistinctRankSix = [ 3, 2 ]

expectedBoundedFirst :: Array Int
expectedBoundedFirst = [ 1, 4 ]

expectedBoundedLast :: Array Int
expectedBoundedLast = [ 4, 1 ]

expectedWeavingFirst :: Array Int
expectedWeavingFirst = [ 1, 1, 2, 2 ]

expectedWeavingSecond :: Array Int
expectedWeavingSecond = [ 1, 2, 1, 2 ]
