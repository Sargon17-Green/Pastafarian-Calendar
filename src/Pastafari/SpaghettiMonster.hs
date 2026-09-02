module Pastafari.SpaghettiMonster
  ( CalendarFive(..)
  , calendarDateSpaghetti
  ) where

import Pastafari.MonsterBase

data CalendarFive = CalendarFive
  { resultYear :: Integer
  , resultCutletCanonicalIndex :: Int
  , resultDayInCutlet :: Integer
  , resultMonthCanonicalIndex :: Int
  , resultDayInMonth :: Integer
  } deriving (Eq, Ord, Show)

calendarDateSpaghetti :: Integer -> Integer -> Either MonsterError CalendarFive
calendarDateSpaghetti cDay tDay =
  case dispatchBase (emptyContext cDay tDay) of
    Left e -> Left e
    Right _ -> Left BaseInvariantFailure
